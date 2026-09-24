import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/app_theme.dart';

class InAppBrowserScreen extends StatefulWidget {
  final String url;
  final String? title;

  const InAppBrowserScreen({
    super.key,
    required this.url,
    this.title,
  });

  static Future<void> open(BuildContext context, String url, {String? title}) {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppBrowserScreen(
          url: formattedUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  String _pageTitle = '';
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _pageTitle = widget.title ?? _extractDomain(widget.url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _pageTitle = _extractDomain(url);
              });
            }
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            final title = await _controller.getTitle();
            final canBack = await _controller.canGoBack();
            final canForward = await _controller.canGoForward();
            if (mounted) {
              setState(() {
                _currentUrl = url;
                if (title != null && title.isNotEmpty) {
                  _pageTitle = title;
                }
                _canGoBack = canBack;
                _canGoForward = canForward;
                _loadingProgress = 100;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[InAppBrowser] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(Icons.copy_rounded, color: context.textPrimary, size: 20),
                title: Text(
                  'Copy Link',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: _currentUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Link copied to clipboard'),
                      backgroundColor: context.primaryAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.refresh_rounded, color: context.textPrimary, size: 20),
                title: Text(
                  'Reload Page',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _controller.reload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSecure = _currentUrl.startsWith('https://');

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _canGoBack) {
          await _controller.goBack();
          final canBack = await _controller.canGoBack();
          final canForward = await _controller.canGoForward();
          if (mounted) {
            setState(() {
              _canGoBack = canBack;
              _canGoForward = canForward;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.scaffoldBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: context.textPrimary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _pageTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSecure) ...[
                    Icon(Icons.lock_outline_rounded, size: 11, color: Colors.green[400]),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      _extractDomain(_currentUrl),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: context.textPrimary, size: 20),
              onPressed: _showMoreMenu,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: _loadingProgress < 100
                ? LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: context.primaryAccent,
                  )
                : Container(color: context.border, height: 1),
          ),
        ),
        body: WebViewWidget(controller: _controller),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              border: Border(top: BorderSide(color: context.border, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _canGoBack ? context.textPrimary : context.textMuted.withValues(alpha: 0.4)),
                  onPressed: _canGoBack ? () => _controller.goBack() : null,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: _canGoForward ? context.textPrimary : context.textMuted.withValues(alpha: 0.4)),
                  onPressed: _canGoForward ? () => _controller.goForward() : null,
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 22, color: context.textPrimary),
                  onPressed: () => _controller.reload(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
