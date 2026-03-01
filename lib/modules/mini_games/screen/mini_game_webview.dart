import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

class MiniGameWebViewScreen extends StatefulWidget {
  final String name;
  final String playUrl;

  const MiniGameWebViewScreen({
    super.key,
    required this.name,
    required this.playUrl,
  });

  @override
  State<MiniGameWebViewScreen> createState() => _MiniGameWebViewScreenState();
}

class _MiniGameWebViewScreenState extends State<MiniGameWebViewScreen> {
  bool _isLoading = true;

  late final List<ContentBlocker> _contentBlockers;

  @override
  void initState() {
    super.initState();
    _contentBlockers = _buildContentBlockers();
    AudioService().pause();
    // Enter immersive mode — hides system navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI bars
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    AudioService().resume();
    super.dispose();
  }

  List<ContentBlocker> _buildContentBlockers() {
    const adDomains = [
      // Google Ads
      '.*googlesyndication\\.com.*',
      '.*googleadservices\\.com.*',
      '.*doubleclick\\.net.*',
      '.*google-analytics\\.com.*',
      '.*googletagmanager\\.com.*',
      '.*googletagservices\\.com.*',
      '.*pagead2\\.googlesyndication\\.com.*',
      '.*adservice\\.google\\.com.*',
      '.*adsense\\.google\\.com.*',

      // Facebook / Meta
      '.*facebook\\.net.*',
      '.*facebook\\.com/tr.*',
      '.*fbcdn\\.net.*',
      '.*connect\\.facebook\\.net.*',

      // Amazon Ads
      '.*amazon-adsystem\\.com.*',
      '.*aax\\.amazon-adsystem\\.com.*',

      // Common ad networks
      '.*adnxs\\.com.*',
      '.*adsrvr\\.org.*',
      '.*adform\\.net.*',
      '.*adcolony\\.com.*',
      '.*admob\\.com.*',
      '.*ads-twitter\\.com.*',
      '.*advertising\\.com.*',
      '.*adbrite\\.com.*',
      '.*adbureau\\.net.*',
      '.*adgear\\.com.*',
      '.*adhigh\\.net.*',
      '.*adition\\.com.*',
      '.*adjug\\.com.*',
      '.*adleads\\.com.*',
      '.*adlegend\\.com.*',
      '.*adlightning\\.com.*',
      '.*adloox\\.com.*',
      '.*admarvel\\.com.*',
      '.*admixer\\.net.*',
      '.*adnium\\.com.*',
      '.*adroll\\.com.*',
      '.*adskeeper\\.com.*',
      '.*adsterra\\.com.*',
      '.*adswizz\\.com.*',
      '.*adtechus\\.com.*',
      '.*adtilt\\.com.*',
      '.*adverline\\.com.*',
      '.*aerserv\\.com.*',

      // Tracking & analytics
      '.*scorecardresearch\\.com.*',
      '.*quantserve\\.com.*',
      '.*mixpanel\\.com.*',
      '.*hotjar\\.com.*',
      '.*segment\\.io.*',
      '.*segment\\.com.*',
      '.*amplitude\\.com.*',
      '.*newrelic\\.com.*',
      '.*crazyegg\\.com.*',
      '.*optimizely\\.com.*',
      '.*fullstory\\.com.*',
      '.*mouseflow\\.com.*',
      '.*heapanalytics\\.com.*',
      '.*chartbeat\\.com.*',

      // Popup / clickbait
      '.*popads\\.net.*',
      '.*popcash\\.net.*',
      '.*propellerads\\.com.*',
      '.*juicyads\\.com.*',
      '.*exoclick\\.com.*',
      '.*trafficjunky\\.com.*',
      '.*clickadu\\.com.*',
      '.*hilltopads\\.com.*',
      '.*evadav\\.com.*',
      '.*pushprofit\\.net.*',

      // Video ads
      '.*innovid\\.com.*',
      '.*spotxchange\\.com.*',
      '.*springserve\\.com.*',
      '.*teads\\.tv.*',
      '.*vidoomy\\.com.*',

      // Other major ad/tracker domains
      '.*outbrain\\.com.*',
      '.*taboola\\.com.*',
      '.*mgid\\.com.*',
      '.*revcontent\\.com.*',
      '.*criteo\\.com.*',
      '.*criteo\\.net.*',
      '.*rubiconproject\\.com.*',
      '.*pubmatic\\.com.*',
      '.*openx\\.net.*',
      '.*indexexchange\\.com.*',
      '.*casalemedia\\.com.*',
      '.*media\\.net.*',
      '.*smartadserver\\.com.*',
      '.*smaato\\.net.*',
      '.*inmobi\\.com.*',
      '.*unity3d\\.com/ads.*',
      '.*unityads\\.unity3d\\.com.*',
      '.*applovin\\.com.*',
      '.*mopub\\.com.*',
      '.*vungle\\.com.*',
      '.*ironsrc\\.com.*',
      '.*is\\.com/ads.*',
      '.*chartboost\\.com.*',
      '.*tapjoy\\.com.*',
      '.*fyber\\.com.*',

      // Malware / suspicious
      '.*malware-check\\.disconnect\\.me.*',
      '.*tracking\\.disconnect\\.me.*',
    ];

    return adDomains
        .map(
          (domain) => ContentBlocker(
            trigger: ContentBlockerTrigger(urlFilter: domain),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.h),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              children: [
                GamingImageButton(
                  width: 0.12.sw,
                  imagePath: Assets.imagesCrossIcon,
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 18.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 0.12.sw),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black,
      // Remove bottom safe area so WebView fills to the edge
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.playUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  cacheEnabled: true,
                  cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
                  contentBlockers: _contentBlockers,
                ),
                onLoadStart: (_, _) {
                  if (mounted) setState(() => _isLoading = true);
                },
                onLoadStop: (_, _) {
                  if (mounted) setState(() => _isLoading = false);
                },
                onReceivedError: (_, _, _) {
                  if (mounted) setState(() => _isLoading = false);
                },
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(height: 83.h, color: Colors.black),
            ), // Top safe area background
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
          ],
        ),
      ),
    );
  }
}
