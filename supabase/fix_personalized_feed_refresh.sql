-- ============================================================================
-- DAK SOCIAL NETWORK - PERSONALIZED FEED REFRESH BUG FIX
-- Run this script in your Supabase SQL Editor to ensure Pull-To-Refresh ALWAYS fetches new posts immediately.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_personalized_feed(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS SETOF public.threads AS $$
#variable_conflict use_column
DECLARE
    v_cache_count INTEGER;
    v_last_cached TIMESTAMP WITH TIME ZONE;
BEGIN
    -- CRITICAL FIX: If requesting page 0 (offset=0, pull-to-refresh), 
    -- ALWAYS delete old feed cache so fresh new posts are calculated immediately.
    IF p_offset = 0 THEN
        DELETE FROM public.user_feed_cache WHERE user_id = p_user_id;
    ELSE
        -- For pagination (offset > 0), check if feed cache is still valid (< 10 mins)
        SELECT COUNT(*), MAX(cached_at) INTO v_cache_count, v_last_cached 
        FROM public.user_feed_cache 
        WHERE user_id = p_user_id;

        IF v_cache_count > 0 AND v_last_cached > (now() - INTERVAL '10 minutes') THEN
            RETURN QUERY
            SELECT t.*
            FROM public.threads t
            JOIN public.user_feed_cache c ON t.id = c.thread_id
            WHERE c.user_id = p_user_id
            ORDER BY c.score DESC
            LIMIT p_limit
            OFFSET p_offset;
            RETURN;
        END IF;
    END IF;

    -- REBUILD FEED CACHE FOR FRESH CONTENT
    -- A. Exclude blocked, muted users, and posts already hidden or reported by user
    WITH excluded_users AS (
        SELECT blocked_id AS ex_user_id FROM public.blocks WHERE blocker_id = p_user_id
        UNION
        SELECT blocker_id AS ex_user_id FROM public.blocks WHERE blocked_id = p_user_id
        UNION
        SELECT muted_id AS ex_user_id FROM public.mutes WHERE muter_id = p_user_id
    ),
    excluded_threads AS (
        SELECT thread_id AS ex_thread_id FROM public.thread_hides WHERE user_id = p_user_id
        UNION
        SELECT thread_id AS ex_thread_id FROM public.reports WHERE user_id = p_user_id AND thread_id IS NOT NULL
    ),
    not_followed_private_users AS (
        SELECT id AS pr_user_id FROM public.profiles 
        WHERE is_private = true 
          AND id != p_user_id 
          AND id NOT IN (SELECT following_id FROM public.follows WHERE follower_id = p_user_id)
    ),
    
    -- B. Compute User's Category Scores from Interactions (last 7 days)
    user_category_weights AS (
        SELECT category, SUM(score) AS interest_score
        FROM public.user_interactions
        WHERE user_id = p_user_id AND created_at > (now() - INTERVAL '7 days')
        GROUP BY category
    ),

    -- C. Retrieve Candidates from Pools
    -- Pool 1: Interest Pool (Matches user's top categories)
    interest_pool AS (
        SELECT t.id AS thread_id, 'interest'::text AS pool_source
        FROM public.threads t
        JOIN user_category_weights w ON t.category = w.category
        WHERE t.created_at > (now() - INTERVAL '7 days')
          AND (t.community_id IS NULL OR EXISTS (SELECT 1 FROM public.community_members cm WHERE cm.community_id = t.community_id AND cm.user_id = p_user_id))
          AND t.user_id != p_user_id
          AND t.user_id NOT IN (SELECT ex_user_id FROM excluded_users)
          AND t.user_id NOT IN (SELECT pr_user_id FROM not_followed_private_users)
          AND t.id NOT IN (SELECT ex_thread_id FROM excluded_threads)
        ORDER BY w.interest_score DESC
        LIMIT 100
    ),

    -- Pool 2: Relationship Pool (Followed, Friends, Chat Partners)
    relationship_pool AS (
        SELECT t.id AS thread_id, 'relationship'::text AS pool_source
        FROM public.threads t
        WHERE t.created_at > (now() - INTERVAL '7 days')
          AND (t.community_id IS NULL OR EXISTS (SELECT 1 FROM public.community_members cm WHERE cm.community_id = t.community_id AND cm.user_id = p_user_id))
          AND t.user_id NOT IN (SELECT ex_user_id FROM excluded_users)
          AND t.id NOT IN (SELECT ex_thread_id FROM excluded_threads)
          AND (
             t.user_id IN (SELECT following_id FROM public.follows WHERE follower_id = p_user_id) OR
             t.user_id IN (SELECT friend_id FROM public.friends_view WHERE user_id = p_user_id) OR
             t.user_id IN (SELECT contact_id FROM public.frequent_chats_view WHERE user_id = p_user_id)
          )
        LIMIT 100
    ),

    -- Pool 3: Trending Pool (Highly liked/replied in last 48 hours)
    trending_pool AS (
        SELECT t.id AS thread_id, 'trending'::text AS pool_source
        FROM public.threads t
        WHERE t.created_at > (now() - INTERVAL '48 hours')
          AND (t.community_id IS NULL OR EXISTS (SELECT 1 FROM public.community_members cm WHERE cm.community_id = t.community_id AND cm.user_id = p_user_id))
          AND t.user_id != p_user_id
          AND t.user_id NOT IN (SELECT ex_user_id FROM excluded_users)
          AND t.user_id NOT IN (SELECT pr_user_id FROM not_followed_private_users)
          AND t.id NOT IN (SELECT ex_thread_id FROM excluded_threads)
          AND (t.likes_count + t.replies_count) > 0
        ORDER BY (t.likes_count * 2.0 + t.replies_count * 5.0) DESC
        LIMIT 100
    ),

    -- Pool 4: Recent Fresh Posts Pool (Brand new posts created in last 24h)
    fresh_posts_pool AS (
        SELECT t.id AS thread_id, 'fresh'::text AS pool_source
        FROM public.threads t
        WHERE t.created_at > (now() - INTERVAL '24 hours')
          AND (t.community_id IS NULL OR EXISTS (SELECT 1 FROM public.community_members cm WHERE cm.community_id = t.community_id AND cm.user_id = p_user_id))
          AND t.user_id NOT IN (SELECT ex_user_id FROM excluded_users)
          AND t.user_id NOT IN (SELECT pr_user_id FROM not_followed_private_users)
          AND t.id NOT IN (SELECT ex_thread_id FROM excluded_threads)
        ORDER BY t.created_at DESC
        LIMIT 100
    ),

    -- D. Merge all unique candidates
    merged_candidates AS (
        SELECT thread_id, MAX(pool_source) AS pool_source
        FROM (
            SELECT thread_id, pool_source FROM interest_pool
            UNION ALL
            SELECT thread_id, pool_source FROM relationship_pool
            UNION ALL
            SELECT thread_id, pool_source FROM trending_pool
            UNION ALL
            SELECT thread_id, pool_source FROM fresh_posts_pool
            UNION ALL
            SELECT id AS thread_id, 'self'::text AS pool_source
            FROM public.threads t
            WHERE (t.user_id = p_user_id OR t.user_id IN (SELECT following_id FROM public.follows WHERE follower_id = p_user_id))
              AND (t.community_id IS NULL OR EXISTS (SELECT 1 FROM public.community_members cm WHERE cm.community_id = t.community_id AND cm.user_id = p_user_id))
              AND t.id NOT IN (SELECT ex_thread_id FROM excluded_threads)
              AND t.user_id NOT IN (SELECT ex_user_id FROM excluded_users)
            LIMIT 50
        ) subquery
        GROUP BY thread_id
    )

    -- E. Compute and Cache Personalized Scores
    INSERT INTO public.user_feed_cache (user_id, thread_id, score, pool_source, cached_at)
    SELECT 
        p_user_id AS user_id,
        mc.thread_id,
        (
            -- Base Engagement Score
            (COALESCE(t.likes_count, 0) * 2.0 + COALESCE(t.replies_count, 0) * 5.0 + COALESCE(t.reposts_count, 0) * 4.0 + COALESCE(t.views_count, 0) * 0.1 + 1.0)
            
            -- Relationship Boost
            * (1.0 + CASE 
                WHEN t.user_id = p_user_id THEN 4.0
                WHEN EXISTS (SELECT 1 FROM public.friends_view WHERE user_id = p_user_id AND friend_id = t.user_id) THEN 3.0
                WHEN EXISTS (SELECT 1 FROM public.follows WHERE follower_id = p_user_id AND following_id = t.user_id) THEN 2.0
                ELSE 0.0 
              END
            )

            -- Category Interest Boost
            * (1.0 + COALESCE((SELECT LEAST(interest_score * 0.05, 3.0) FROM user_category_weights WHERE category = t.category), 0.0))

            -- Spam Penalty
            - (COALESCE(t.spam_score, 0.0) * 10.0)
        )
        / 
        -- Gravity Freshness Decay (Decays gracefully over hours)
        ( (EXTRACT(EPOCH FROM (now() - t.created_at)) / 3600.0 + 2.0) ^ 1.5 ) AS score,
        mc.pool_source,
        now() AS cached_at
    FROM merged_candidates mc
    JOIN public.threads t ON mc.thread_id = t.id
    ON CONFLICT (user_id, thread_id) DO UPDATE 
    SET score = EXCLUDED.score,
        pool_source = EXCLUDED.pool_source,
        cached_at = EXCLUDED.cached_at;

    -- Return the freshly ranked list
    RETURN QUERY
    SELECT t.*
    FROM public.threads t
    JOIN public.user_feed_cache c ON t.id = c.thread_id
    WHERE c.user_id = p_user_id
    ORDER BY c.score DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
