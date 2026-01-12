import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, HttpHeaders, HttpClient, HttpClientRequest, HttpClientResponse;
import 'dart:math' as holyMath;
import 'dart:math';
import 'dart:ui';
import 'package:appsflyer_sdk/appsflyer_sdk.dart' as afCore;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, SystemChrome, SystemUiOverlayStyle, MethodCall;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

import 'package:package_info_plus/package_info_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tzZone;

import 'Pholy.dart';
import 'holywin.dart';

// ============================================================================
// Константы
// ============================================================================

const String holyLoadedOnceKey = 'loaded_once';
const String holyStatEndpoint = 'https://api.saleclearens.store/stat';
const String holyCachedFcmKey = 'cached_fcm';

// ============================================================================
// Лёгкие сервисы
// ============================================================================

class HolyLogChalice {
  static final HolyLogChalice holyInstance = HolyLogChalice._internal();

  HolyLogChalice._internal();

  factory HolyLogChalice() => holyInstance;

  final Connectivity holyConnectivity = Connectivity();

  void holyInfo(Object holyMessage) => debugPrint('[I] $holyMessage');
  void holyWarn(Object holyMessage) => debugPrint('[W] $holyMessage');
  void holyError(Object holyMessage) => debugPrint('[E] $holyMessage');
}

// ============================================================================
// Сеть/данные
// ============================================================================

class HolyNetwork {
  final HolyLogChalice _holyLogChalice = HolyLogChalice();

  Future<bool> isHolyOnline() async {
    final ConnectivityResult holyConnectivityResult =
    await _holyLogChalice.holyConnectivity.checkConnectivity();
    return holyConnectivityResult != ConnectivityResult.none;
  }

  Future<void> postHolyJson(
      String holyUrl,
      Map<String, dynamic> holyData,
      ) async {
    try {
      await http.post(
        Uri.parse(holyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(holyData),
      );
    } catch (holyError) {
      _holyLogChalice.holyError('postGlowJson error: $holyError');
    }
  }
}

// ============================================================================
// Досье устройства
// ============================================================================

class HolyDeviceScroll {
  String? holyDeviceId;
  String? holySessionId = 'roulette-one-off';
  String? holyPlatformName; // android/ios
  String? holyOsVersion;
  String? holyAppVersion;
  String? holyLang;
  String? holyTimezoneName;
  bool holyPushEnabled = true;

  Future<void> initHolyDeviceScroll() async {
    final DeviceInfoPlugin holyDeviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo holyAndroidInfo =
      await holyDeviceInfoPlugin.androidInfo;
      holyDeviceId = holyAndroidInfo.id;
      holyPlatformName = 'android';
      holyOsVersion = holyAndroidInfo.version.release;
    } else if (Platform.isIOS) {
      final IosDeviceInfo holyIosInfo = await holyDeviceInfoPlugin.iosInfo;
      holyDeviceId = holyIosInfo.identifierForVendor;
      holyPlatformName = 'ios';
      holyOsVersion = holyIosInfo.systemVersion;
    }

    final PackageInfo holyPackageInfo = await PackageInfo.fromPlatform();
    holyAppVersion = holyPackageInfo.version;
    holyLang = Platform.localeName.split('_').first;
    holyTimezoneName = tzZone.local.name;
    holySessionId = 'roulette-${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> asHolyMap({String? holyFcm}) => {
    'fcm_token': holyFcm ?? 'missing_token',
    'device_id': holyDeviceId ?? 'missing_id',
    'app_name': 'holwin',
    'instance_id': holySessionId ?? 'missing_session',
    'platform': holyPlatformName ?? 'missing_system',
    'os_version': holyOsVersion ?? 'missing_build',
    'app_version': holyAppVersion ?? 'missing_app',
    'language': holyLang ?? 'en',
    'timezone': holyTimezoneName ?? 'UTC',
    'push_enabled': holyPushEnabled,
  };
}

// ============================================================================
// AppsFlyer
// ============================================================================

class HolyTracker {
  afCore.AppsFlyerOptions? holyOptions;
  afCore.AppsflyerSdk? holySdk;

  String holyAfUid = '';
  String holyAfData = '';

  void startHolyTracker({VoidCallback? onHolyUpdate}) {
    final afCore.AppsFlyerOptions holyConfig = afCore.AppsFlyerOptions(
      afDevKey: 'qsBLmy7dAXDQhowM8V3ca4',
      appId: '6757708473',
      showDebug: true,
      timeToWaitForATTUserAuthorization: 0,
    );

    holyOptions = holyConfig;
    holySdk = afCore.AppsflyerSdk(holyConfig);

    holySdk?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    holySdk?.startSDK(
      onSuccess: () => HolyLogChalice().holyInfo('NeonCinemaSpy started'),
      onError: (holyCode, holyMsg) =>
          HolyLogChalice().holyError('NeonCinemaSpy error $holyCode: $holyMsg'),
    );

    holySdk?.onInstallConversionData((holyValue) {
      holyAfData = holyValue.toString();
      onHolyUpdate?.call();
    });

    holySdk?.getAppsFlyerUID().then((holyValue) {
      holyAfUid = holyValue.toString();
      onHolyUpdate?.call();
    });
  }
}

// ============================================================================
// Новый loader: прожекторы на "My Holy WIN"
// ============================================================================

class HolySpotlightLoader extends StatefulWidget {
  const HolySpotlightLoader({Key? key}) : super(key: key);

  @override
  State<HolySpotlightLoader> createState() => _HolySpotlightLoaderState();
}

class _HolySpotlightLoaderState extends State<HolySpotlightLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController holyAnimationController;
  late Animation<double> holyProgressAnimation;

  @override
  void initState() {
    super.initState();
    holyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    holyProgressAnimation =
        CurvedAnimation(parent: holyAnimationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    holyAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size holySize = MediaQuery.of(context).size;
    final double holyFontSize = holySize.width * 0.12;

    const Color holyStageDark = Color(0xFF05030A);
    const Color holyGoldSoft = Color(0xFFFFE082);
    const Color holyGoldMid = Color(0xFFFFC107);
    const Color holyGoldDeep = Color(0xFFFFA000);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: holyProgressAnimation,
        builder: (BuildContext context, Widget? child) {
          final double holyT = holyProgressAnimation.value;

          final double holyGlowStrength =
              0.4 + 0.6 * sin(holyT * 2 * holyMath.pi); // 0..1
          final double holyTiltLeft =
              -0.4 + 0.3 * sin((holyT + 0.2) * 2 * holyMath.pi);
          final double holyTiltRight =
              0.4 + 0.3 * sin((holyT + 0.7) * 2 * holyMath.pi);

          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Фон сцены
                Container(
                  width: holySize.width * 0.8,
                  height: holyFontSize * 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black,
                        holyStageDark,
                        Colors.black,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: holyGoldDeep.withOpacity(0.45),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),

                // Левый прожектор
                Positioned(
                  left: holySize.width * 0.18,
                  top: holySize.height * 0.28,
                  child: Transform.rotate(
                    angle: holyTiltLeft,
                    child: _HolySpotlightBeam(
                      holyGlowStrength: holyGlowStrength,
                      holyColor: holyGoldMid,
                    ),
                  ),
                ),

                // Правый прожектор
                Positioned(
                  right: holySize.width * 0.18,
                  top: holySize.height * 0.28,
                  child: Transform.rotate(
                    angle: holyTiltRight,
                    child: _HolySpotlightBeam(
                      holyGlowStrength: holyGlowStrength,
                      holyColor: holyGoldMid,
                    ),
                  ),
                ),

                // Надпись My Holy WIN
                ShaderMask(
                  shaderCallback: (Rect rect) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        holyGoldSoft,
                        holyGoldMid,
                        holyGoldDeep,
                      ],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Opacity(
                    opacity: 0.6 + 0.4 * holyGlowStrength,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _HolyLetterGlow(
                              holyText: 'My',
                              holyFontSize: holyFontSize * 0.8,
                              holyPhase: 0.0,
                              holyProgress: holyT,
                            ),
                            const SizedBox(width: 6),
                            _HolyLetterGlow(
                              holyText: 'Holy',
                              holyFontSize: holyFontSize * 0.9,
                              holyPhase: 0.2,
                              holyProgress: holyT,
                            ),
                            const SizedBox(width: 6),
                            _HolyLetterGlow(
                              holyText: 'WIN',
                              holyFontSize: holyFontSize,
                              holyPhase: 0.4,
                              holyProgress: holyT,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HolySpotlightBeam extends StatelessWidget {
  const _HolySpotlightBeam({
    required this.holyGlowStrength,
    required this.holyColor,
  });

  final double holyGlowStrength;
  final Color holyColor;

  @override
  Widget build(BuildContext context) {
    final double holyOpacity = 0.18 + 0.32 * holyGlowStrength;
    return CustomPaint(
      painter: _HolyBeamPainter(
        holyColor: holyColor.withOpacity(holyOpacity),
      ),
      size: const Size(80, 160),
    );
  }
}

class _HolyBeamPainter extends CustomPainter {
  _HolyBeamPainter({required this.holyColor});
  final Color holyColor;

  @override
  void paint(Canvas holyCanvas, Size holySize) {
    final Paint holyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.5),
        radius: 1.4,
        colors: <Color>[
          holyColor,
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, holySize.width, holySize.height));

    final Path holyPath = Path()
      ..moveTo(holySize.width * 0.45, 0)
      ..lineTo(0, holySize.height)
      ..lineTo(holySize.width, holySize.height)
      ..close();

    holyCanvas.drawPath(holyPath, holyPaint);
  }

  @override
  bool shouldRepaint(covariant _HolyBeamPainter oldDelegate) =>
      oldDelegate.holyColor != holyColor;
}

class _HolyLetterGlow extends StatelessWidget {
  const _HolyLetterGlow({
    required this.holyText,
    required this.holyFontSize,
    required this.holyPhase,
    required this.holyProgress,
  });

  final String holyText;
  final double holyFontSize;
  final double holyPhase;
  final double holyProgress;

  @override
  Widget build(BuildContext context) {
    final double holyLocalT = (holyProgress + holyPhase) % 1.0;
    final double holyScale = 0.9 + 0.12 * sin(holyLocalT * 2 * holyMath.pi);
    final double holyBlur =
        1.5 + 5 * (0.5 + 0.5 * sin(holyLocalT * 2 * holyMath.pi));

    return Transform.scale(
      scale: holyScale,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: holyBlur, sigmaY: holyBlur),
          child: Text(
            holyText,
            style: TextStyle(
              fontSize: holyFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FCM фоновые крики
// ============================================================================

@pragma('vm:entry-point')
Future<void> holyFcmBackgroundHandler(RemoteMessage holyMessage) async {
  HolyLogChalice().holyInfo('bg-fcm: ${holyMessage.messageId}');
  HolyLogChalice().holyInfo('bg-data: ${holyMessage.data}');
}

// ============================================================================
// FCM Bridge
// ============================================================================

class HolyFcmBridge {
  final HolyLogChalice _holyLogChalice = HolyLogChalice();
  String? _holyToken;
  final List<void Function(String)> _holyWaiters = <void Function(String)>[];

  String? get holyToken => _holyToken;

  HolyFcmBridge() {
    const MethodChannel('com.example.fcm/token')
        .setMethodCallHandler((MethodCall holyCall) async {
      if (holyCall.method == 'setToken') {
        final String holyTokenString = holyCall.arguments as String;
        if (holyTokenString.isNotEmpty) {
          _setHolyToken(holyTokenString);
        }
      }
    });

    _restoreHolyToken();
  }

  Future<void> _restoreHolyToken() async {
    try {
      final SharedPreferences holyPrefs =
      await SharedPreferences.getInstance();
      final String? holyCachedToken = holyPrefs.getString(holyCachedFcmKey);
      if (holyCachedToken != null && holyCachedToken.isNotEmpty) {
        _setHolyToken(holyCachedToken, notify: false);
      }
    } catch (_) {}
  }

  Future<void> _persistHolyToken(String holyNewToken) async {
    try {
      final SharedPreferences holyPrefs =
      await SharedPreferences.getInstance();
      await holyPrefs.setString(holyCachedFcmKey, holyNewToken);
    } catch (_) {}
  }

  void _setHolyToken(String holyNewToken, {bool notify = true}) {
    _holyToken = holyNewToken;
    _persistHolyToken(holyNewToken);
    if (notify) {
      for (final void Function(String) holyCallback
      in List<void Function(String)>.from(_holyWaiters)) {
        try {
          holyCallback(holyNewToken);
        } catch (holyError) {
          _holyLogChalice.holyWarn('fcm waiter error: $holyError');
        }
      }
      _holyWaiters.clear();
    }
  }

  Future<void> waitHolyToken(
      Function(String holyToken) onHolyToken,
      ) async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if ((_holyToken ?? '').isNotEmpty) {
        onHolyToken(_holyToken!);
        return;
      }

      _holyWaiters.add(onHolyToken);
    } catch (holyError) {
      _holyLogChalice.holyError('waitGlowToken error: $holyError');
    }
  }
}

// ============================================================================
// Splash / Hall
// ============================================================================

class HolyHall extends StatefulWidget {
  const HolyHall({Key? key}) : super(key: key);

  @override
  State<HolyHall> createState() => _HolyHallState();
}

class _HolyHallState extends State<HolyHall> {
  final HolyFcmBridge holyFcmBridge = HolyFcmBridge();
  bool holyNavigatedOnce = false;
  Timer? holyFallbackTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    holyFcmBridge.waitHolyToken((String holyTokenValue) {
      _goHolyHarbor(holyTokenValue);
    });

    holyFallbackTimer =
        Timer(const Duration(seconds: 8), () => _goHolyHarbor(''));
  }

  void _goHolyHarbor(String holySignal) {
    if (holyNavigatedOnce) return;
    holyNavigatedOnce = true;
    holyFallbackTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<Widget>(
        builder: (BuildContext holyContext) =>
            HolyHarbor(holySignal: holySignal),
      ),
    );
  }

  @override
  void dispose() {
    holyFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: HolySpotlightLoader(),
      ),
    );
  }
}

// ============================================================================
// ViewModel + Courier
// ============================================================================

class HolyBosun {
  final HolyDeviceScroll holyDeviceScroll;
  final HolyTracker holyTracker;

  HolyBosun({
    required this.holyDeviceScroll,
    required this.holyTracker,
  });

  Map<String, dynamic> holyDeviceMap(String? holyToken) =>
      holyDeviceScroll.asHolyMap(holyFcm: holyToken);

  Map<String, dynamic> holyAfMap(String? holyToken) => {
    'content': {
      'af_data': holyTracker.holyAfData,
      'af_id': holyTracker.holyAfUid,
      'fb_app_name': 'holwin',
      'app_name': 'holwin',
      'deep': null,
      'bundle_identifier': 'com.hholly.myholy.myholywin',
      'app_version': '1.0.0',
      'apple_id': '6757708473',
      'fcm_token': holyToken ?? 'no_token',
      'device_id': holyDeviceScroll.holyDeviceId ?? 'no_device',
      'instance_id': holyDeviceScroll.holySessionId ?? 'no_instance',
      'platform': holyDeviceScroll.holyPlatformName ?? 'no_type',
      'os_version': holyDeviceScroll.holyOsVersion ?? 'no_os',
      'app_version': holyDeviceScroll.holyAppVersion ?? 'no_app',
      'language': holyDeviceScroll.holyLang ?? 'en',
      'timezone': holyDeviceScroll.holyTimezoneName ?? 'UTC',
      'push_enabled': holyDeviceScroll.holyPushEnabled,
      'useruid': holyTracker.holyAfUid,
    },
  };
}

class HolyCourier {
  final HolyBosun holyBosun;
  final InAppWebViewController Function() getHolyWebView;

  HolyCourier({
    required this.holyBosun,
    required this.getHolyWebView,
  });

  Future<void> putHolyDeviceToLocalStorage(String? holyToken) async {
    final Map<String, dynamic> holyMap = holyBosun.holyDeviceMap(holyToken);
    await getHolyWebView().evaluateJavascript(
      source: '''
localStorage.setItem('app_data', JSON.stringify(${jsonEncode(holyMap)}));
''',
    );
  }

  Future<void> sendHolyRawToPage(String? holyToken) async {
    final Map<String, dynamic> holyPayload = holyBosun.holyAfMap(holyToken);
    final String holyJsonString = jsonEncode(holyPayload);

    print('load stry$holyJsonString');
    HolyLogChalice().holyInfo('SendGlowRawData: $holyJsonString');

    await getHolyWebView().evaluateJavascript(
      source: 'sendRawData(${jsonEncode(holyJsonString)});',
    );
  }
}

// ============================================================================
// Переходы/статистика
// ============================================================================

Future<String> holyFinalUrl(
    String holyStartUrl, {
      int holyMaxHops = 10,
    }) async {
  final HttpClient holyHttpClient = HttpClient();

  try {
    Uri holyCurrentUri = Uri.parse(holyStartUrl);

    for (int holyIndex = 0; holyIndex < holyMaxHops; holyIndex++) {
      final HttpClientRequest holyRequest =
      await holyHttpClient.getUrl(holyCurrentUri);
      holyRequest.followRedirects = false;
      final HttpClientResponse holyResponse = await holyRequest.close();

      if (holyResponse.isRedirect) {
        final String? holyLocationHeader =
        holyResponse.headers.value(HttpHeaders.locationHeader);
        if (holyLocationHeader == null || holyLocationHeader.isEmpty) {
          break;
        }

        final Uri holyNextUri = Uri.parse(holyLocationHeader);
        holyCurrentUri = holyNextUri.hasScheme
            ? holyNextUri
            : holyCurrentUri.resolveUri(holyNextUri);
        continue;
      }

      return holyCurrentUri.toString();
    }

    return holyCurrentUri.toString();
  } catch (holyError) {
    debugPrint('neonCinemaFinalUrl error: $holyError');
    return holyStartUrl;
  } finally {
    holyHttpClient.close(force: true);
  }
}

Future<void> holyPostStat({
  required String holyEvent,
  required int holyTimeStart,
  required String holyUrl,
  required int holyTimeFinish,
  required String holyAppSid,
  int? holyFirstPageLoadTs,
}) async {
  try {
    final String holyResolvedUrl = await holyFinalUrl(holyUrl);

    final Map<String, dynamic> holyPayload = <String, dynamic>{
      'event': holyEvent,
      'timestart': holyTimeStart,
      'timefinsh': holyTimeFinish,
      'url': holyResolvedUrl,
      'appleID': '6756072063',
      'open_count': '$holyAppSid/$holyTimeStart',
    };

    debugPrint('neonCinemaStat $holyPayload');

    final http.Response holyResponse = await http.post(
      Uri.parse('$holyStatEndpoint/$holyAppSid'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(holyPayload),
    );

    debugPrint(
        'neonCinemaStat resp=${holyResponse.statusCode} body=${holyResponse.body}');
  } catch (holyError) {
    debugPrint('neonCinemaPostStat error: $holyError');
  }
}

// ============================================================================
// Главный WebView — Harbor
// ============================================================================

class HolyHarbor extends StatefulWidget {
  final String? holySignal;

  const HolyHarbor({super.key, required this.holySignal});

  @override
  State<HolyHarbor> createState() => _HolyHarborState();
}

class _HolyHarborState extends State<HolyHarbor> with WidgetsBindingObserver {
  late InAppWebViewController holyWebViewController;
  final String holyHomeUrl = 'https://api.saleclearens.store/';

  int holyHatchCounter = 0;
  DateTime? holySleepAt;
  bool holyVeilVisible = false;
  double holyWarmProgress = 0.0;
  late Timer holyWarmTimer;
  final int holyWarmSeconds = 6;
  bool holyCoverVisible = true;

  bool holyLoadedOnceSent = false;
  int? holyFirstPageTimestamp;

  HolyCourier? holyCourier;
  HolyBosun? holyBosun;

  String holyCurrentUrl = '';
  int holyStartLoadTimestamp = 0;

  final HolyDeviceScroll holyDeviceScroll = HolyDeviceScroll();
  final HolyTracker holyTracker = HolyTracker();
  bool holyUseSafeArea = false;
  final Set<String> holySchemes = <String>{
    'tg',
    'telegram',
    'whatsapp',
    'viber',
    'skype',
    'fb-messenger',
    'sgnl',
    'tel',
    'mailto',
    'bnl',
  };

  final Set<String> holyExternalHosts = <String>{
    't.me',
    'telegram.me',
    'telegram.dog',
    'wa.me',
    'api.whatsapp.com',
    'chat.whatsapp.com',
    'm.me',
    'signal.me',
    'bnl.com',
    'www.bnl.com',
    // Новые соцсети
    'facebook.com',
    'www.facebook.com',
    'm.facebook.com',
    'instagram.com',
    'www.instagram.com',
    'twitter.com',
    'www.twitter.com',
    'x.com',
    'www.x.com',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    holyFirstPageTimestamp = DateTime.now().millisecondsSinceEpoch;

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          holyCoverVisible = false;
        });
      }
    });

    Future<void>.delayed(const Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() {
        holyVeilVisible = true;
      });
    });

    _bootHoly();
  }

  Future<void> _loadHolyLoadedFlag() async {
    final SharedPreferences holyPrefs =
    await SharedPreferences.getInstance();
    holyLoadedOnceSent = holyPrefs.getBool(holyLoadedOnceKey) ?? false;
  }

  Future<void> _saveHolyLoadedFlag() async {
    final SharedPreferences holyPrefs =
    await SharedPreferences.getInstance();
    await holyPrefs.setBool(holyLoadedOnceKey, true);
    holyLoadedOnceSent = true;
  }

  Future<void> sendHolyLoadedOnce({
    required String holyUrl,
    required int holyTimestart,
  }) async {
    if (holyLoadedOnceSent) {
      debugPrint('Loaded already sent, skip');
      return;
    }

    final int holyNow = DateTime.now().millisecondsSinceEpoch;

    await holyPostStat(
      holyEvent: 'Loaded',
      holyTimeStart: holyTimestart,
      holyTimeFinish: holyNow,
      holyUrl: holyUrl,
      holyAppSid: holyTracker.holyAfUid,
      holyFirstPageLoadTs: holyFirstPageTimestamp,
    );

    await _saveHolyLoadedFlag();
  }

  void _bootHoly() {
    _startHolyWarmProgress();
    _wireHolyFcm();
    holyTracker.startHolyTracker(
      onHolyUpdate: () => setState(() {}),
    );
    _bindHolyNotificationTap();
    _prepareHolyDeck();

    Future<void>.delayed(const Duration(seconds: 6), () async {
      await _pushHolyDevice();
      await _pushHolyAfData();
    });
  }

  void _wireHolyFcm() {
    FirebaseMessaging.onMessage.listen((RemoteMessage holyMessage) {
      final dynamic holyLink = holyMessage.data['uri'];
      if (holyLink != null) {
        _navigateHoly(holyLink.toString());
      } else {
        _resetHolyHome();
      }
    });

    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage holyMessage) {
      final dynamic holyLink = holyMessage.data['uri'];
      if (holyLink != null) {
        _navigateHoly(holyLink.toString());
      } else {
        _resetHolyHome();
      }
    });
  }

  void _bindHolyNotificationTap() {
    MethodChannel('com.example.fcm/notification')
        .setMethodCallHandler((MethodCall holyCall) async {
      if (holyCall.method == 'onNotificationTap') {
        final Map<String, dynamic> holyPayload =
        Map<String, dynamic>.from(holyCall.arguments);
        if (holyPayload['uri'] != null &&
            !holyPayload['uri'].toString().contains('Нет URI')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<Widget>(
              builder: (BuildContext holyContext) =>
                  HolyCoreTableView(holyPayload['uri'].toString()),
            ),
                (Route<dynamic> holyRoute) => false,
          );
        }
      }
    });
  }

  Future<void> _prepareHolyDeck() async {
    try {
      await holyDeviceScroll.initHolyDeviceScroll();
      await _askHolyPushPermissions();

      holyBosun = HolyBosun(
        holyDeviceScroll: holyDeviceScroll,
        holyTracker: holyTracker,
      );

      holyCourier = HolyCourier(
        holyBosun: holyBosun!,
        getHolyWebView: () => holyWebViewController,
      );

      await _loadHolyLoadedFlag();
    } catch (holyError) {
      HolyLogChalice().holyError('prepare fail: $holyError');
    }
  }

  Future<void> _askHolyPushPermissions() async {
    final FirebaseMessaging holyMessaging = FirebaseMessaging.instance;
    await holyMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _navigateHoly(String holyLink) async {
    try {
      await holyWebViewController.loadUrl(
        urlRequest: URLRequest(url: WebUri(holyLink)),
      );
    } catch (holyError) {
      HolyLogChalice().holyError('navigate error: $holyError');
    }
  }

  void _resetHolyHome() {
    Future<void>.delayed(const Duration(seconds: 3), () {
      try {
        holyWebViewController.loadUrl(
          urlRequest: URLRequest(url: WebUri(holyHomeUrl)),
        );
      } catch (_) {}
    });
  }

  Future<void> _pushHolyDevice() async {
    HolyLogChalice().holyInfo('TOKEN ship ${widget.holySignal}');
    try {
      await holyCourier?.putHolyDeviceToLocalStorage(widget.holySignal);
    } catch (holyError) {
      HolyLogChalice().holyError('pushGlowDevice error: $holyError');
    }
  }

  Future<void> _pushHolyAfData() async {
    try {
      await holyCourier?.sendHolyRawToPage(widget.holySignal);
    } catch (holyError) {
      HolyLogChalice().holyError('pushGlowAf error: $holyError');
    }
  }

  void _startHolyWarmProgress() {
    int holyTick = 0;
    holyWarmProgress = 0.0;

    holyWarmTimer =
        Timer.periodic(const Duration(milliseconds: 100), (Timer holyTimer) {
          if (!mounted) return;

          setState(() {
            holyTick++;
            holyWarmProgress = holyTick / (holyWarmSeconds * 10);

            if (holyWarmProgress >= 1.0) {
              holyWarmProgress = 1.0;
              holyWarmTimer.cancel();
            }
          });
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState holyState) {
    if (holyState == AppLifecycleState.paused) {
      holySleepAt = DateTime.now();
    }

    if (holyState == AppLifecycleState.resumed) {
      if (Platform.isIOS && holySleepAt != null) {
        final DateTime holyNow = DateTime.now();
        final Duration holyDrift = holyNow.difference(holySleepAt!);

        if (holyDrift > const Duration(minutes: 25)) {
          reboardHoly();
        }
      }
      holySleepAt = null;
    }
  }

  void reboardHoly() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<Widget>(
          builder: (BuildContext holyContext) =>
              HolyHarbor(holySignal: widget.holySignal),
        ),
            (Route<dynamic> holyRoute) => false,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    holyWarmTimer.cancel();
    super.dispose();
  }

  // ================== URL helpers ==================

  bool _isHolyBareEmail(Uri holyUri) {
    final String holyScheme = holyUri.scheme;
    if (holyScheme.isNotEmpty) return false;
    final String holyRaw = holyUri.toString();
    return holyRaw.contains('@') && !holyRaw.contains(' ');
  }

  Uri _toHolyMailto(Uri holyUri) {
    final String holyFull = holyUri.toString();
    final List<String> holyParts = holyFull.split('?');
    final String holyEmail = holyParts.first;
    final Map<String, String> holyQueryParams = holyParts.length > 1
        ? Uri.splitQueryString(holyParts[1])
        : <String, String>{};

    return Uri(
      scheme: 'mailto',
      path: holyEmail,
      queryParameters:
      holyQueryParams.isEmpty ? null : holyQueryParams,
    );
  }

  bool _isHolyPlatformish(Uri holyUri) {
    final String holyScheme = holyUri.scheme.toLowerCase();
    if (holySchemes.contains(holyScheme)) {
      return true;
    }

    if (holyScheme == 'http' || holyScheme == 'https') {
      final String holyHost = holyUri.host.toLowerCase();

      if (holyExternalHosts.contains(holyHost)) {
        return true;
      }

      if (holyHost.endsWith('t.me')) return true;
      if (holyHost.endsWith('wa.me')) return true;
      if (holyHost.endsWith('m.me')) return true;
      if (holyHost.endsWith('signal.me')) return true;
      if (holyHost.endsWith('facebook.com')) return true;
      if (holyHost.endsWith('instagram.com')) return true;
      if (holyHost.endsWith('twitter.com')) return true;
      if (holyHost.endsWith('x.com')) return true;
    }

    return false;
  }

  String _holyDigitsOnly(String holySource) =>
      holySource.replaceAll(RegExp(r'[^0-9+]'), '');

  Uri _holyHttpize(Uri holyUri) {
    final String holyScheme = holyUri.scheme.toLowerCase();

    if (holyScheme == 'tg' || holyScheme == 'telegram') {
      final Map<String, String> holyQp = holyUri.queryParameters;
      final String? holyDomain = holyQp['domain'];

      if (holyDomain != null && holyDomain.isNotEmpty) {
        return Uri.https(
          't.me',
          '/$holyDomain',
          <String, String>{
            if (holyQp['start'] != null) 'start': holyQp['start']!,
          },
        );
      }

      final String holyPath =
      holyUri.path.isNotEmpty ? holyUri.path : '';

      return Uri.https(
        't.me',
        '/$holyPath',
        holyUri.queryParameters.isEmpty
            ? null
            : holyUri.queryParameters,
      );
    }

    if ((holyScheme == 'http' || holyScheme == 'https') &&
        holyUri.host.toLowerCase().endsWith('t.me')) {
      return holyUri;
    }

    if (holyScheme == 'viber') {
      return holyUri;
    }

    if (holyScheme == 'whatsapp') {
      final Map<String, String> holyQp = holyUri.queryParameters;
      final String? holyPhone = holyQp['phone'];
      final String? holyText = holyQp['text'];

      if (holyPhone != null && holyPhone.isNotEmpty) {
        return Uri.https(
          'wa.me',
          '/${_holyDigitsOnly(holyPhone)}',
          <String, String>{
            if (holyText != null && holyText.isNotEmpty)
              'text': holyText,
          },
        );
      }

      return Uri.https(
        'wa.me',
        '/',
        <String, String>{
          if (holyText != null && holyText.isNotEmpty)
            'text': holyText,
        },
      );
    }

    if ((holyScheme == 'http' || holyScheme == 'https') &&
        (holyUri.host.toLowerCase().endsWith('wa.me') ||
            holyUri.host.toLowerCase().endsWith('whatsapp.com'))) {
      return holyUri;
    }

    if (holyScheme == 'skype') {
      return holyUri;
    }

    if (holyScheme == 'fb-messenger') {
      final String holyPath = holyUri.pathSegments.isNotEmpty
          ? holyUri.pathSegments.join('/')
          : '';
      final Map<String, String> holyQp = holyUri.queryParameters;

      final String holyId =
          holyQp['id'] ?? holyQp['user'] ?? holyPath;

      if (holyId.isNotEmpty) {
        return Uri.https(
          'm.me',
          '/$holyId',
          holyUri.queryParameters.isEmpty
              ? null
              : holyUri.queryParameters,
        );
      }

      return Uri.https(
        'm.me',
        '/',
        holyUri.queryParameters.isEmpty
            ? null
            : holyUri.queryParameters,
      );
    }

    if (holyScheme == 'sgnl') {
      final Map<String, String> holyQp = holyUri.queryParameters;
      final String? holyPhone = holyQp['phone'];
      final String? holyUsername = holyQp['username'];

      if (holyPhone != null && holyPhone.isNotEmpty) {
        return Uri.https(
          'signal.me',
          '/#p/${_holyDigitsOnly(holyPhone)}',
        );
      }

      if (holyUsername != null && holyUsername.isNotEmpty) {
        return Uri.https(
          'signal.me',
          '/#u/$holyUsername',
        );
      }

      final String holyPath = holyUri.pathSegments.join('/');
      if (holyPath.isNotEmpty) {
        return Uri.https(
          'signal.me',
          '/$holyPath',
          holyUri.queryParameters.isEmpty
              ? null
              : holyUri.queryParameters,
        );
      }

      return holyUri;
    }

    if (holyScheme == 'tel') {
      return Uri.parse('tel:${_holyDigitsOnly(holyUri.path)}');
    }

    if (holyScheme == 'mailto') {
      return holyUri;
    }

    if (holyScheme == 'bnl') {
      final String holyNewPath =
      holyUri.path.isNotEmpty ? holyUri.path : '';
      return Uri.https(
        'bnl.com',
        '/$holyNewPath',
        holyUri.queryParameters.isEmpty
            ? null
            : holyUri.queryParameters,
      );
    }

    return holyUri;
  }

  Future<bool> _openHolyMailWeb(Uri holyMailto) async {
    final Uri holyGmailUri = _holyGmailize(holyMailto);
    return await _openHolyWeb(holyGmailUri);
  }

  Uri _holyGmailize(Uri holyMailUri) {
    final Map<String, String> holyQueryParams =
        holyMailUri.queryParameters;

    final Map<String, String> holyParams = <String, String>{
      'view': 'cm',
      'fs': '1',
      if (holyMailUri.path.isNotEmpty) 'to': holyMailUri.path,
      if ((holyQueryParams['subject'] ?? '').isNotEmpty)
        'su': holyQueryParams['subject']!,
      if ((holyQueryParams['body'] ?? '').isNotEmpty)
        'body': holyQueryParams['body']!,
      if ((holyQueryParams['cc'] ?? '').isNotEmpty)
        'cc': holyQueryParams['cc']!,
      if ((holyQueryParams['bcc'] ?? '').isNotEmpty)
        'bcc': holyQueryParams['bcc']!,
    };

    return Uri.https('mail.google.com', '/mail/', holyParams);
  }

  Future<bool> _openHolyWeb(Uri holyUri) async {
    try {
      if (await launchUrl(
        holyUri,
        mode: LaunchMode.inAppBrowserView,
      )) {
        return true;
      }

      return await launchUrl(
        holyUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (holyError) {
      debugPrint('openInAppBrowser error: $holyError; url=$holyUri');
      try {
        return await launchUrl(
          holyUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> _openHolyExternal(Uri holyUri) async {
    try {
      return await launchUrl(
        holyUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (holyError) {
      debugPrint('openExternal error: $holyError; url=$holyUri');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _bindHolyNotificationTap(); // повторная привязка

    Widget holyContent = Stack(
      children: <Widget>[
        if (holyCoverVisible)
          const HolySpotlightLoader()
        else
          Container(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                InAppWebView(
                  key: ValueKey<int>(holyHatchCounter),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    disableDefaultErrorPage: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    allowsPictureInPictureMediaPlayback: true,
                    useOnDownloadStart: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    useShouldOverrideUrlLoading: true,
                    supportMultipleWindows: true,
                    transparentBackground: true,
                  ),
                  initialUrlRequest: URLRequest(
                    url: WebUri(holyHomeUrl),
                  ),
                  onWebViewCreated:
                      (InAppWebViewController holyController) {
                    holyWebViewController = holyController;

                    holyBosun ??= HolyBosun(
                      holyDeviceScroll: holyDeviceScroll,
                      holyTracker: holyTracker,
                    );

                    holyCourier ??= HolyCourier(
                      holyBosun: holyBosun!,
                      getHolyWebView: () => holyWebViewController,
                    );

                    holyWebViewController.addJavaScriptHandler(
                      handlerName: 'onServerResponse',
                      callback: (List<dynamic> holyArgs) {
                        try {
                          if (holyArgs.isNotEmpty &&
                              holyArgs[0] is Map) {
                            final dynamic holyRaw =
                            holyArgs[0]['savedata'];
                            final String holySavedata =
                                holyRaw?.toString() ?? '';

                            print("Server response: $holyRaw");

                            // savedata == "false" → ВКЛЮЧИТЬ SafeArea
                            // savedata == "true"  → ВЫКЛЮЧИТЬ SafeArea
                            if (holySavedata == "false") {
                              setState(() {
                                holyUseSafeArea = true;
                              });

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => HelpLite()),
                                    (route) => false,
                              );
                            } else if (holySavedata == "true") {
                              setState(() {
                                holyUseSafeArea = false;
                              });
                            }
                          }
                        } catch (_) {}

                        if (holyArgs.isEmpty) {
                          return null;
                        }

                        try {
                          return holyArgs.reduce(
                                (dynamic current, dynamic next) =>
                            current + next,
                          );
                        } catch (_) {
                          return holyArgs.first;
                        }
                      },
                    );
                  },
                  onLoadStart: (InAppWebViewController holyC,
                      Uri? holyUri) async {
                    setState(() {
                      holyStartLoadTimestamp =
                          DateTime.now().millisecondsSinceEpoch;
                    });

                    final Uri? holyViewUri = holyUri;
                    if (holyViewUri != null) {
                      if (_isHolyBareEmail(holyViewUri)) {
                        try {
                          await holyC.stopLoading();
                        } catch (_) {}
                        final Uri holyMailto =
                        _toHolyMailto(holyViewUri);
                        await _openHolyMailWeb(holyMailto);
                        return;
                      }

                      final String holyScheme =
                      holyViewUri.scheme.toLowerCase();
                      if (holyScheme != 'http' &&
                          holyScheme != 'https') {
                        try {
                          await holyC.stopLoading();
                        } catch (_) {}
                      }
                    }
                  },
                  onLoadError: (
                      InAppWebViewController holyController,
                      Uri? holyUrl,
                      int holyCode,
                      String holyMessage,
                      ) async {
                    final int holyNow =
                        DateTime.now().millisecondsSinceEpoch;
                    final String holyEvent =
                        'InAppWebViewError(code=$holyCode, message=$holyMessage)';

                    await holyPostStat(
                      holyEvent: holyEvent,
                      holyTimeStart: holyNow,
                      holyTimeFinish: holyNow,
                      holyUrl: holyUrl?.toString() ?? '',
                      holyAppSid: holyTracker.holyAfUid,
                      holyFirstPageLoadTs: holyFirstPageTimestamp,
                    );
                  },
                  onReceivedError: (
                      InAppWebViewController holyController,
                      WebResourceRequest holyRequest,
                      WebResourceError holyError,
                      ) async {
                    final int holyNow =
                        DateTime.now().millisecondsSinceEpoch;
                    final String holyDescription =
                    (holyError.description ?? '').toString();
                    final String holyEvent =
                        'WebResourceError(code=$holyError, message=$holyDescription)';

                    await holyPostStat(
                      holyEvent: holyEvent,
                      holyTimeStart: holyNow,
                      holyTimeFinish: holyNow,
                      holyUrl: holyRequest.url?.toString() ?? '',
                      holyAppSid: holyTracker.holyAfUid,
                      holyFirstPageLoadTs: holyFirstPageTimestamp,
                    );
                  },
                  onLoadStop: (InAppWebViewController holyC,
                      Uri? holyUri) async {
                    await holyC.evaluateJavascript(
                      source: 'console.log(\'NeonCinema harbor up!\');',
                    );

                    await _pushHolyDevice();
                    await _pushHolyAfData();

                    setState(() {
                      holyCurrentUrl = holyUri.toString();
                    });

                    Future<void>.delayed(
                      const Duration(seconds: 20),
                          () {
                        sendHolyLoadedOnce(
                          holyUrl: holyCurrentUrl.toString(),
                          holyTimestart: holyStartLoadTimestamp,
                        );
                      },
                    );
                  },
                  shouldOverrideUrlLoading: (
                      InAppWebViewController holyC,
                      NavigationAction holyAction,
                      ) async {
                    final Uri? holyUri = holyAction.request.url;
                    if (holyUri == null) {
                      return NavigationActionPolicy.ALLOW;
                    }

                    if (_isHolyBareEmail(holyUri)) {
                      final Uri holyMailto =
                      _toHolyMailto(holyUri);
                      await _openHolyMailWeb(holyMailto);
                      return NavigationActionPolicy.CANCEL;
                    }

                    final String holyScheme =
                    holyUri.scheme.toLowerCase();

                    if (holyScheme == 'mailto') {
                      await _openHolyMailWeb(holyUri);
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (holyScheme == 'tel') {
                      await launchUrl(
                        holyUri,
                        mode: LaunchMode.externalApplication,
                      );
                      return NavigationActionPolicy.CANCEL;
                    }

                    final String holyHost =
                    holyUri.host.toLowerCase();
                    final bool holyIsSocial =
                        holyHost.endsWith('facebook.com') ||
                            holyHost.endsWith('instagram.com') ||
                            holyHost.endsWith('twitter.com') ||
                            holyHost.endsWith('x.com');

                    if (holyIsSocial) {
                      await _openHolyExternal(holyUri);
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (_isHolyPlatformish(holyUri)) {
                      final Uri holyWebUri = _holyHttpize(holyUri);
                      await _openHolyExternal(holyWebUri);
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (holyScheme != 'http' &&
                        holyScheme != 'https') {
                      return NavigationActionPolicy.CANCEL;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onCreateWindow: (
                      InAppWebViewController holyC,
                      CreateWindowAction holyRequest,
                      ) async {
                    final Uri? holyUri = holyRequest.request.url;
                    if (holyUri == null) {
                      return false;
                    }

                    if (_isHolyBareEmail(holyUri)) {
                      final Uri holyMailto =
                      _toHolyMailto(holyUri);
                      await _openHolyMailWeb(holyMailto);
                      return false;
                    }

                    final String holyScheme =
                    holyUri.scheme.toLowerCase();

                    if (holyScheme == 'mailto') {
                      await _openHolyMailWeb(holyUri);
                      return false;
                    }

                    if (holyScheme == 'tel') {
                      await launchUrl(
                        holyUri,
                        mode: LaunchMode.externalApplication,
                      );
                      return false;
                    }

                    final String holyHost =
                    holyUri.host.toLowerCase();
                    final bool holyIsSocial =
                        holyHost.endsWith('facebook.com') ||
                            holyHost.endsWith('instagram.com') ||
                            holyHost.endsWith('twitter.com') ||
                            holyHost.endsWith('x.com');

                    if (holyIsSocial) {
                      await _openHolyExternal(holyUri);
                      return false;
                    }

                    if (_isHolyPlatformish(holyUri)) {
                      final Uri holyWebUri = _holyHttpize(holyUri);
                      await _openHolyExternal(holyWebUri);
                      return false;
                    }

                    if (holyScheme == 'http' ||
                        holyScheme == 'https') {
                      holyC.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(holyUri.toString()),
                        ),
                      );
                    }

                    return false;
                  },
                  onDownloadStartRequest: (
                      InAppWebViewController holyC,
                      DownloadStartRequest holyReq,
                      ) async {
                    await _openHolyExternal(holyReq.url);
                  },
                ),
                Visibility(
                  visible: !holyVeilVisible,
                  child: const HolySpotlightLoader(),
                ),
              ],
            ),
          ),
      ],
    );



    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: holyContent,
      ),
    );
  }
}

// ============================================================================
// Отдельный WebView для внешней ссылки (из уведомлений)
// ============================================================================

class HolyExternalScreen extends StatefulWidget with WidgetsBindingObserver {
  final String holyLane;

  const HolyExternalScreen(this.holyLane, {super.key});

  @override
  State<HolyExternalScreen> createState() => _HolyExternalScreenState();
}

class _HolyExternalScreenState extends State<HolyExternalScreen>
    with WidgetsBindingObserver {
  late InAppWebViewController holyExternalWebView;

  @override
  Widget build(BuildContext context) {
    final bool holyIsDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: holyIsDark
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            disableDefaultErrorPage: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            allowsPictureInPictureMediaPlayback: true,
            useOnDownloadStart: true,
            javaScriptCanOpenWindowsAutomatically: true,
            useShouldOverrideUrlLoading: true,
            supportMultipleWindows: true,
          ),
          initialUrlRequest:
          URLRequest(url: WebUri(widget.holyLane)),
          onWebViewCreated:
              (InAppWebViewController holyC) {
            holyExternalWebView = holyC;
          },
        ),
      ),
    );
  }
}

// ============================================================================
// main()
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(holyFcmBackgroundHandler);

  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  tzData.initializeTimeZones();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HolyHall(),
    ),
  );
}