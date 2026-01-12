// *****************************************************************************
// HOLY-WIN-styled refactor with My Holy WIN spotlight loader
// *****************************************************************************

// ВАЖНО:
// - ВСЕ строковые литералы и raw-строки ОСТАВЛЕНЫ КАК ЕСТЬ ("" / '').
// - Переименованы ВСЕ классы, методы, поля и локальные переменные в стиле HOLY WIN.
// - Loader заменён на прожекторы, подсвечивающие надпись "My Holy WIN".
// *****************************************************************************

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as holyMath;
import 'dart:math';
import 'dart:ui';

import 'package:appsflyer_sdk/appsflyer_sdk.dart'
    show AppsFlyerOptions, AppsflyerSdk;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, SystemUiOverlayStyle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Если эти классы есть в main.dart – оставь импорт.
import 'main.dart' show MafiaHarbor, CaptainHarbor, BillHarbor;

// ============================================================================
// HOLY инфраструктура и паттерны
// ============================================================================

class HolyCoreLog {
  const HolyCoreLog();

  void holyCoreLogInfo(Object holyCoreMsg) =>
      debugPrint('[WheelLogger] $holyCoreMsg');

  void holyCoreLogWarn(Object holyCoreMsg) =>
      debugPrint('[WheelLogger/WARN] $holyCoreMsg');

  void holyCoreLogErr(Object holyCoreMsg) =>
      debugPrint('[WheelLogger/ERR] $holyCoreMsg');
}

class HolyCoreVault {
  static final HolyCoreVault _holyCoreSingleton = HolyCoreVault._holyCoreInternal();
  HolyCoreVault._holyCoreInternal();
  factory HolyCoreVault() => _holyCoreSingleton;

  final HolyCoreLog holyCoreLogger = const HolyCoreLog();
}

// ============================================================================
// Константы (статистика/кеш)
// ============================================================================

const String kHolyCoreLoadedOnceKey = 'wheel_loaded_once';
const String kHolyCoreStatEndpoint =
    'https://getgame.portalroullete.bar/stat';
const String kHolyCoreCachedFcmKey = 'wheel_cached_fcm';

// ============================================================================
// HOLY утилиты: HolyCoreKit
// ============================================================================

class HolyCoreKit {
  static bool holyCoreLooksLikeBareMail(Uri holyCoreUri) {
    final holyCoreScheme = holyCoreUri.scheme;
    if (holyCoreScheme.isNotEmpty) return false;
    final holyCoreRaw = holyCoreUri.toString();
    return holyCoreRaw.contains('@') && !holyCoreRaw.contains(' ');
  }

  static Uri holyCoreToMailto(Uri holyCoreUri) {
    final holyCoreFull = holyCoreUri.toString();
    final holyCoreBits = holyCoreFull.split('?');
    final holyCoreWho = holyCoreBits.first;
    final holyCoreQuery = holyCoreBits.length > 1
        ? Uri.splitQueryString(holyCoreBits[1])
        : <String, String>{};
    return Uri(
      scheme: 'mailto',
      path: holyCoreWho,
      queryParameters: holyCoreQuery.isEmpty ? null : holyCoreQuery,
    );
  }

  static Uri holyCoreGmailize(Uri holyCoreMail) {
    final holyCoreQp = holyCoreMail.queryParameters;
    final holyCoreParams = <String, String>{
      'view': 'cm',
      'fs': '1',
      if (holyCoreMail.path.isNotEmpty) 'to': holyCoreMail.path,
      if ((holyCoreQp['subject'] ?? '').isNotEmpty)
        'su': holyCoreQp['subject']!,
      if ((holyCoreQp['body'] ?? '').isNotEmpty)
        'body': holyCoreQp['body']!,
      if ((holyCoreQp['cc'] ?? '').isNotEmpty)
        'cc': holyCoreQp['cc']!,
      if ((holyCoreQp['bcc'] ?? '').isNotEmpty)
        'bcc': holyCoreQp['bcc']!,
    };
    return Uri.https('mail.google.com', '/mail/', holyCoreParams);
  }

  static String holyCoreOnlyDigits(String holyCoreSource) =>
      holyCoreSource.replaceAll(RegExp(r'[^0-9+]'), '');
}

// ============================================================================
// Сервис открытия внешних ссылок/протоколов (HolyCoreLinker)
// ============================================================================

class HolyCoreLinker {
  static Future<bool> holyCoreOpen(Uri holyCoreUri) async {
    try {
      if (await launchUrl(
        holyCoreUri,
        mode: LaunchMode.inAppBrowserView,
      )) {
        return true;
      }
      return await launchUrl(
        holyCoreUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (holyCoreError) {
      debugPrint('WheelLinker error: $holyCoreError; url=$holyCoreUri');
      try {
        return await launchUrl(
          holyCoreUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        return false;
      }
    }
  }
}

// ============================================================================
// FCM Background Handler — HOLY крупье в бэкграунде
// ============================================================================

@pragma('vm:entry-point')
Future<void> holyCoreBgDealer(RemoteMessage holyCoreMessage) async {
  debugPrint("Spin ID: ${holyCoreMessage.messageId}");
  debugPrint("Spin Data: ${holyCoreMessage.data}");
}

// ============================================================================
// HOLY Device Deck: информация об устройстве
// ============================================================================

class HolyCoreDeviceInfoDeck {
  String? holyCoreDeviceId;
  String? holyCoreSessionId = 'wheel-one-off';
  String? holyCorePlatformKind;
  String? holyCoreOsBuild;
  String? holyCoreAppVersion;
  String? holyCoreLocale;
  String? holyCoreTimezone;
  bool holyCorePushEnabled = true;

  Future<void> holyCoreInit() async {
    final holyCoreInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final holyCoreAndroid = await holyCoreInfo.androidInfo;
      holyCoreDeviceId = holyCoreAndroid.id;
      holyCorePlatformKind = 'android';
      holyCoreOsBuild = holyCoreAndroid.version.release;
    } else if (Platform.isIOS) {
      final holyCoreIos = await holyCoreInfo.iosInfo;
      holyCoreDeviceId = holyCoreIos.identifierForVendor;
      holyCorePlatformKind = 'ios';
      holyCoreOsBuild = holyCoreIos.systemVersion;
    }

    final holyCorePackageInfo = await PackageInfo.fromPlatform();
    holyCoreAppVersion = holyCorePackageInfo.version;
    holyCoreLocale = Platform.localeName.split('_').first;
    holyCoreTimezone = timezone.local.name;
    holyCoreSessionId =
    'wheel-${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> holyCoreAsMap({String? holyCoreFcm}) => {
    'fcm_token': holyCoreFcm ?? 'missing_token',
    'device_id': holyCoreDeviceId ?? 'missing_id',
    'app_name': 'holwin',
    'instance_id': holyCoreSessionId ?? 'missing_session',
    'platform': holyCorePlatformKind ?? 'missing_system',
    'os_version': holyCoreOsBuild ?? 'missing_build',
    'app_version': holyCoreAppVersion ?? 'missing_app',
    'language': holyCoreLocale ?? 'en',
    'timezone': holyCoreTimezone ?? 'UTC',
    'push_enabled': holyCorePushEnabled,
  };
}

// ============================================================================
// HOLY шпион: AppsFlyer (HolyCoreSpy)
// ============================================================================

class HolyCoreSpy {
  AppsFlyerOptions? holyCoreOptions;
  AppsflyerSdk? holyCoreSdk;

  String holyCoreAfUid = '';
  String holyCoreAfData = '';

  void holyCoreStart({VoidCallback? holyCoreOnUpdate}) {
    final holyCoreOpts = AppsFlyerOptions(
      afDevKey: 'qsBLmy7dAXDQhowM8V3ca4',
      appId: '6756072063',
      showDebug: true,
      timeToWaitForATTUserAuthorization: 0,
    );

    holyCoreOptions = holyCoreOpts;
    holyCoreSdk = AppsflyerSdk(holyCoreOpts);

    holyCoreSdk?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    holyCoreSdk?.startSDK(
      onSuccess: () =>
          HolyCoreVault().holyCoreLogger.holyCoreLogInfo('WheelSpy started'),
      onError: (holyCoreCode, holyCoreMsg) =>
          HolyCoreVault().holyCoreLogger.holyCoreLogErr(
              'WheelSpy error $holyCoreCode: $holyCoreMsg'),
    );

    holyCoreSdk?.onInstallConversionData((holyCoreValue) {
      holyCoreAfData = holyCoreValue.toString();
      holyCoreOnUpdate?.call();
    });

    holyCoreSdk?.getAppsFlyerUID().then((holyCoreValue) {
      holyCoreAfUid = holyCoreValue.toString();
      holyCoreOnUpdate?.call();
    });
  }
}

// ============================================================================
// HOLY мост для FCM токена (HolyCoreFcmBridge)
// ============================================================================

class HolyCoreFcmBridge {
  final HolyCoreLog _holyCoreLog = const HolyCoreLog();
  String? _holyCoreToken;
  final List<void Function(String)> _holyCoreWaiters =
  <void Function(String)>[];

  String? get holyCoreToken => _holyCoreToken;

  HolyCoreFcmBridge() {
    const MethodChannel('com.example.fcm/token')
        .setMethodCallHandler((MethodCall holyCoreCall) async {
      if (holyCoreCall.method == 'setToken') {
        final String holyCoreTokenString =
        holyCoreCall.arguments as String;
        if (holyCoreTokenString.isNotEmpty) {
          _holyCoreSetToken(holyCoreTokenString);
        }
      }
    });

    _holyCoreRestoreToken();
  }

  Future<void> _holyCoreRestoreToken() async {
    try {
      final holyCorePrefs = await SharedPreferences.getInstance();
      final holyCoreCached =
      holyCorePrefs.getString(kHolyCoreCachedFcmKey);
      if (holyCoreCached != null && holyCoreCached.isNotEmpty) {
        _holyCoreSetToken(holyCoreCached, holyCoreNotify: false);
      }
    } catch (_) {}
  }

  Future<void> _holyCorePersistToken(String holyCoreToken) async {
    try {
      final holyCorePrefs = await SharedPreferences.getInstance();
      await holyCorePrefs.setString(kHolyCoreCachedFcmKey, holyCoreToken);
    } catch (_) {}
  }

  void _holyCoreSetToken(String holyCoreToken, {bool holyCoreNotify = true}) {
    _holyCoreToken = holyCoreToken;
    _holyCorePersistToken(holyCoreToken);
    if (holyCoreNotify) {
      for (final holyCoreCallback
      in List<void Function(String)>.from(_holyCoreWaiters)) {
        try {
          holyCoreCallback(holyCoreToken);
        } catch (holyCoreErr) {
          _holyCoreLog.holyCoreLogWarn('fcm waiter error: $holyCoreErr');
        }
      }
      _holyCoreWaiters.clear();
    }
  }

  Future<void> holyCoreWaitToken(
      Function(String holyCoreToken) holyCoreOnToken) async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if ((_holyCoreToken ?? '').isNotEmpty) {
        holyCoreOnToken(_holyCoreToken!);
        return;
      }

      _holyCoreWaiters.add(holyCoreOnToken);
    } catch (holyCoreErr) {
      _holyCoreLog.holyCoreLogErr('wheelWaitToken error: $holyCoreErr');
    }
  }
}

// ============================================================================
// HOLY Loader: прожекторы "My Holy WIN"
// ============================================================================

class HolyCoreSpotlightLoader extends StatefulWidget {
  const HolyCoreSpotlightLoader({Key? key}) : super(key: key);

  @override
  State<HolyCoreSpotlightLoader> createState() =>
      _HolyCoreSpotlightLoaderState();
}

class _HolyCoreSpotlightLoaderState extends State<HolyCoreSpotlightLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController holyCoreAnimController;
  late Animation<double> holyCoreGlowAnim;

  @override
  void initState() {
    super.initState();
    holyCoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    holyCoreGlowAnim = CurvedAnimation(
      parent: holyCoreAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    holyCoreAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext holyCoreContext) {
    final holyCoreSize = MediaQuery.of(holyCoreContext).size;
    final double holyCoreFontSize = holyCoreSize.width * 0.12;

    const Color holyCoreStageDark = Color(0xFF05030A);
    const Color holyCoreGoldSoft = Color(0xFFFFE082);
    const Color holyCoreGoldMid = Color(0xFFFFC107);
    const Color holyCoreGoldDeep = Color(0xFFFFA000);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: holyCoreGlowAnim,
        builder: (BuildContext context, Widget? child) {
          final double holyCoreT = holyCoreGlowAnim.value;

          final double holyCoreGlowStrength =
              0.4 + 0.6 * sin(holyCoreT * 2 * holyMath.pi);
          final double holyCoreTiltLeft =
              -0.4 + 0.3 * sin((holyCoreT + 0.2) * 2 * holyMath.pi);
          final double holyCoreTiltRight =
              0.4 + 0.3 * sin((holyCoreT + 0.7) * 2 * holyMath.pi);

          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Фон сцены
                Container(
                  width: holyCoreSize.width * 0.8,
                  height: holyCoreFontSize * 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black,
                        holyCoreStageDark,
                        Colors.black,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: holyCoreGoldDeep.withOpacity(0.45),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),

                // Левый прожектор
                Positioned(
                  left: holyCoreSize.width * 0.18,
                  top: holyCoreSize.height * 0.28,
                  child: Transform.rotate(
                    angle: holyCoreTiltLeft,
                    child: _HolyCoreSpotlightBeam(
                      holyCoreGlowStrength: holyCoreGlowStrength,
                      holyCoreColor: holyCoreGoldMid,
                    ),
                  ),
                ),

                // Правый прожектор
                Positioned(
                  right: holyCoreSize.width * 0.18,
                  top: holyCoreSize.height * 0.28,
                  child: Transform.rotate(
                    angle: holyCoreTiltRight,
                    child: _HolyCoreSpotlightBeam(
                      holyCoreGlowStrength: holyCoreGlowStrength,
                      holyCoreColor: holyCoreGoldMid,
                    ),
                  ),
                ),

                // Надпись "My Holy WIN"
                ShaderMask(
                  shaderCallback: (Rect rect) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        holyCoreGoldSoft,
                        holyCoreGoldMid,
                        holyCoreGoldDeep,
                      ],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Opacity(
                    opacity: 0.6 + 0.4 * holyCoreGlowStrength,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _HolyCoreLetterGlow(
                              holyCoreText: 'My',
                              holyCoreFontSize: holyCoreFontSize * 0.8,
                              holyCorePhase: 0.0,
                              holyCoreProgress: holyCoreT,
                            ),
                            const SizedBox(width: 6),
                            _HolyCoreLetterGlow(
                              holyCoreText: 'Holy',
                              holyCoreFontSize: holyCoreFontSize * 0.9,
                              holyCorePhase: 0.2,
                              holyCoreProgress: holyCoreT,
                            ),
                            const SizedBox(width: 6),
                            _HolyCoreLetterGlow(
                              holyCoreText: 'WIN',
                              holyCoreFontSize: holyCoreFontSize,
                              holyCorePhase: 0.4,
                              holyCoreProgress: holyCoreT,
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

class _HolyCoreSpotlightBeam extends StatelessWidget {
  const _HolyCoreSpotlightBeam({
    required this.holyCoreGlowStrength,
    required this.holyCoreColor,
  });

  final double holyCoreGlowStrength;
  final Color holyCoreColor;

  @override
  Widget build(BuildContext context) {
    final double holyCoreOpacity = 0.18 + 0.32 * holyCoreGlowStrength;
    return CustomPaint(
      painter: _HolyCoreBeamPainter(
        holyCoreColor: holyCoreColor.withOpacity(holyCoreOpacity),
      ),
      size: const Size(80, 160),
    );
  }
}

class _HolyCoreBeamPainter extends CustomPainter {
  _HolyCoreBeamPainter({required this.holyCoreColor});
  final Color holyCoreColor;

  @override
  void paint(Canvas holyCoreCanvas, Size holyCoreSize) {
    final Paint holyCorePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.5),
        radius: 1.4,
        colors: <Color>[
          holyCoreColor,
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, holyCoreSize.width, holyCoreSize.height));

    final Path holyCorePath = Path()
      ..moveTo(holyCoreSize.width * 0.45, 0)
      ..lineTo(0, holyCoreSize.height)
      ..lineTo(holyCoreSize.width, holyCoreSize.height)
      ..close();

    holyCoreCanvas.drawPath(holyCorePath, holyCorePaint);
  }

  @override
  bool shouldRepaint(covariant _HolyCoreBeamPainter oldDelegate) =>
      oldDelegate.holyCoreColor != holyCoreColor;
}

class _HolyCoreLetterGlow extends StatelessWidget {
  const _HolyCoreLetterGlow({
    required this.holyCoreText,
    required this.holyCoreFontSize,
    required this.holyCorePhase,
    required this.holyCoreProgress,
  });

  final String holyCoreText;
  final double holyCoreFontSize;
  final double holyCorePhase;
  final double holyCoreProgress;

  @override
  Widget build(BuildContext context) {
    final double holyCoreLocalT = (holyCoreProgress + holyCorePhase) % 1.0;
    final double holyCoreScale =
        0.9 + 0.12 * sin(holyCoreLocalT * 2 * holyMath.pi);
    final double holyCoreBlur =
        1.5 + 5 * (0.5 + 0.5 * sin(holyCoreLocalT * 2 * holyMath.pi));

    return Transform.scale(
      scale: holyCoreScale,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: holyCoreBlur,
            sigmaY: holyCoreBlur,
          ),
          child: Text(
            holyCoreText,
            style: TextStyle(
              fontSize: holyCoreFontSize,
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
// HOLY статистика (аналог wheelFinalUrl / wheelPostStat)
// ============================================================================

Future<String> holyCoreFinalUrl(
    String holyCoreStartUrl, {
      int holyCoreMaxHops = 10,
    }) async {
  final holyCoreHttpClient = HttpClient();

  try {
    Uri holyCoreCurrentUri = Uri.parse(holyCoreStartUrl);

    for (int holyCoreI = 0; holyCoreI < holyCoreMaxHops; holyCoreI++) {
      final holyCoreReq = await holyCoreHttpClient.getUrl(holyCoreCurrentUri);
      holyCoreReq.followRedirects = false;
      final holyCoreResp = await holyCoreReq.close();

      if (holyCoreResp.isRedirect) {
        final holyCoreLoc =
        holyCoreResp.headers.value(HttpHeaders.locationHeader);
        if (holyCoreLoc == null || holyCoreLoc.isEmpty) break;

        final holyCoreNextUri = Uri.parse(holyCoreLoc);
        holyCoreCurrentUri = holyCoreNextUri.hasScheme
            ? holyCoreNextUri
            : holyCoreCurrentUri.resolveUri(holyCoreNextUri);
        continue;
      }

      return holyCoreCurrentUri.toString();
    }

    return holyCoreCurrentUri.toString();
  } catch (holyCoreErr) {
    debugPrint('wheelFinalUrl error: $holyCoreErr');
    return holyCoreStartUrl;
  } finally {
    holyCoreHttpClient.close(force: true);
  }
}

Future<void> holyCorePostStat({
  required String holyCoreEvent,
  required int holyCoreTimeStart,
  required String holyCoreUrl,
  required int holyCoreTimeFinish,
  required String holyCoreAppSid,
  int? holyCoreFirstPageTs,
}) async {
  try {
    final holyCoreResolved = await holyCoreFinalUrl(holyCoreUrl);
    final holyCorePayload = <String, dynamic>{
      'event': holyCoreEvent,
      'timestart': holyCoreTimeStart,
      'timefinsh': holyCoreTimeFinish,
      'url': holyCoreResolved,
      'appleID': '6755681349',
      'open_count': '$holyCoreAppSid/$holyCoreTimeStart',
    };

    debugPrint('wheelStat $holyCorePayload');

    final holyCoreResp = await http.post(
      Uri.parse('$kHolyCoreStatEndpoint/$holyCoreAppSid'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(holyCorePayload),
    );

    debugPrint(
        'wheelStat resp=${holyCoreResp.statusCode} body=${holyCoreResp.body}');
  } catch (holyCoreErr) {
    debugPrint('wheelPostStat error: $holyCoreErr');
  }
}

// ============================================================================
// HOLY WebView-стол — HolyCoreTableView
// ============================================================================

class HolyCoreTableView extends StatefulWidget with WidgetsBindingObserver {
  String holyCoreStartingLane;
  HolyCoreTableView(this.holyCoreStartingLane, {super.key});

  @override
  State<HolyCoreTableView> createState() =>
      _HolyCoreTableViewState(holyCoreStartingLane);
}

class _HolyCoreTableViewState extends State<HolyCoreTableView>
    with WidgetsBindingObserver {
  _HolyCoreTableViewState(this._holyCoreCurrentLane);

  final HolyCoreVault _holyCoreVault = HolyCoreVault();

  late InAppWebViewController _holyCoreWebController;
  String? _holyCorePushToken;
  final HolyCoreDeviceInfoDeck _holyCoreDeviceDeck =
  HolyCoreDeviceInfoDeck();
  final HolyCoreSpy _holyCoreSpy = HolyCoreSpy();

  bool _holyCoreOverlayBusy = false;
  String _holyCoreCurrentLane;
  DateTime? _holyCoreLastPausedAt;

  bool _holyCoreLoadedOnceSent = false;
  int? _holyCoreFirstPageTs;
  int _holyCoreStartLoadTs = 0;

  final Set<String> _holyCoreExternalHosts = {
    't.me',
    'telegram.me',
    'telegram.dog',
    'wa.me',
    'api.whatsapp.com',
    'chat.whatsapp.com',
    'bnl.com',
    'www.bnl.com',
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

  final Set<String> _holyCoreExternalSchemes = {
    'tg',
    'telegram',
    'whatsapp',
    'bnl',
    'fb-messenger',
    'sgnl',
    'tel',
    'mailto',
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    FirebaseMessaging.onBackgroundMessage(holyCoreBgDealer);

    _holyCoreFirstPageTs = DateTime.now().millisecondsSinceEpoch;

    _holyCoreInitPushAndGetToken();
    _holyCoreDeviceDeck.holyCoreInit();
    _holyCoreWireForegroundPushHandlers();
    _holyCoreBindPlatformNotificationTap();
    _holyCoreSpy.holyCoreStart(holyCoreOnUpdate: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState holyCoreState) {
    if (holyCoreState == AppLifecycleState.paused) {
      _holyCoreLastPausedAt = DateTime.now();
    }
    if (holyCoreState == AppLifecycleState.resumed) {
      if (Platform.isIOS && _holyCoreLastPausedAt != null) {
        final holyCoreNow = DateTime.now();
        final holyCoreDrift = holyCoreNow.difference(_holyCoreLastPausedAt!);
        if (holyCoreDrift > const Duration(minutes: 25)) {
          _holyCoreForceReloadToLobby();
        }
      }
      _holyCoreLastPausedAt = null;
    }
  }

  void _holyCoreForceReloadToLobby() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

    });
  }

  // --------------------------------------------------------------------------
  // Push / FCM
  // --------------------------------------------------------------------------
  void _holyCoreWireForegroundPushHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage holyCoreMsg) {
      if (holyCoreMsg.data['uri'] != null) {
        _holyCoreNavigateTo(holyCoreMsg.data['uri'].toString());
      } else {
        _holyCoreReturnToCurrentLane();
      }
    });

    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage holyCoreMsg) {
      if (holyCoreMsg.data['uri'] != null) {
        _holyCoreNavigateTo(holyCoreMsg.data['uri'].toString());
      } else {
        _holyCoreReturnToCurrentLane();
      }
    });
  }

  void _holyCoreNavigateTo(String holyCoreNewLane) async {
    await _holyCoreWebController.loadUrl(
      urlRequest: URLRequest(url: WebUri(holyCoreNewLane)),
    );
  }

  void _holyCoreReturnToCurrentLane() async {
    Future.delayed(const Duration(seconds: 3), () {
      _holyCoreWebController.loadUrl(
        urlRequest: URLRequest(url: WebUri(_holyCoreCurrentLane)),
      );
    });
  }

  Future<void> _holyCoreInitPushAndGetToken() async {
    final holyCoreFm = FirebaseMessaging.instance;
    await holyCoreFm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _holyCorePushToken = await holyCoreFm.getToken();
  }

  // --------------------------------------------------------------------------
  // Привязка канала: тап по уведомлению из native
  // --------------------------------------------------------------------------
  void _holyCoreBindPlatformNotificationTap() {
    MethodChannel('com.example.fcm/notification')
        .setMethodCallHandler((MethodCall holyCoreCall) async {
      if (holyCoreCall.method == "onNotificationTap") {
        final Map<String, dynamic> holyCorePayload =
        Map<String, dynamic>.from(holyCoreCall.arguments);
        debugPrint("URI from platform tap: ${holyCorePayload['uri']}");
        final holyCoreUriString = holyCorePayload["uri"]?.toString();
        if (holyCoreUriString != null &&
            !holyCoreUriString.contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (holyCoreContext) =>
                  HolyCoreTableView(holyCoreUriString),
            ),
                (holyCoreRoute) => false,
          );
        }
      }
    });
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext holyCoreContext) {
    _holyCoreBindPlatformNotificationTap();

    final holyCoreIsDark =
        MediaQuery.of(holyCoreContext).platformBrightness ==
            Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: holyCoreIsDark
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            InAppWebView(
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
              initialUrlRequest: URLRequest(
                url: WebUri(_holyCoreCurrentLane),
              ),
              onWebViewCreated:
                  (InAppWebViewController holyCoreController) {
                _holyCoreWebController = holyCoreController;

                _holyCoreWebController.addJavaScriptHandler(
                  handlerName: 'onServerResponse',
                  callback: (holyCoreArgs) {
                    _holyCoreVault.holyCoreLogger
                        .holyCoreLogInfo("JS Args: $holyCoreArgs");
                    try {
                      return holyCoreArgs.reduce(
                              (holyCoreV, holyCoreE) => holyCoreV + holyCoreE);
                    } catch (_) {
                      return holyCoreArgs.toString();
                    }
                  },
                );
              },
              onLoadStart:
                  (InAppWebViewController holyCoreController,
                  Uri? holyCoreUri) async {
                _holyCoreStartLoadTs =
                    DateTime.now().millisecondsSinceEpoch;

                if (holyCoreUri != null) {
                  if (HolyCoreKit.holyCoreLooksLikeBareMail(holyCoreUri)) {
                    try {
                      await holyCoreController.stopLoading();
                    } catch (_) {}
                    final holyCoreMailto =
                    HolyCoreKit.holyCoreToMailto(holyCoreUri);
                    await HolyCoreLinker.holyCoreOpen(
                      HolyCoreKit.holyCoreGmailize(holyCoreMailto),
                    );
                    return;
                  }

                  final holyCoreScheme =
                  holyCoreUri.scheme.toLowerCase();
                  if (holyCoreScheme != 'http' &&
                      holyCoreScheme != 'https') {
                    try {
                      await holyCoreController.stopLoading();
                    } catch (_) {}
                  }
                }
              },
              onLoadStop:
                  (InAppWebViewController holyCoreController,
                  Uri? holyCoreUri) async {
                await holyCoreController.evaluateJavascript(
                  source:
                  "console.log('Hello from Roulette JS!');",
                );

                setState(() {
                  _holyCoreCurrentLane =
                      holyCoreUri?.toString() ?? _holyCoreCurrentLane;
                });

                Future.delayed(const Duration(seconds: 20), () {
                  _holyCoreSendLoadedOnce();
                });
              },
              shouldOverrideUrlLoading:
                  (InAppWebViewController holyCoreController,
                  NavigationAction holyCoreNav) async {
                final holyCoreUri = holyCoreNav.request.url;
                if (holyCoreUri == null) {
                  return NavigationActionPolicy.ALLOW;
                }

                if (HolyCoreKit.holyCoreLooksLikeBareMail(holyCoreUri)) {
                  final holyCoreMailto =
                  HolyCoreKit.holyCoreToMailto(holyCoreUri);
                  await HolyCoreLinker.holyCoreOpen(
                    HolyCoreKit.holyCoreGmailize(holyCoreMailto),
                  );
                  return NavigationActionPolicy.CANCEL;
                }

                final holyCoreScheme =
                holyCoreUri.scheme.toLowerCase();

                if (holyCoreScheme == 'mailto') {
                  await HolyCoreLinker.holyCoreOpen(
                    HolyCoreKit.holyCoreGmailize(holyCoreUri),
                  );
                  return NavigationActionPolicy.CANCEL;
                }

                if (holyCoreScheme == 'tel') {
                  await launchUrl(
                    holyCoreUri,
                    mode: LaunchMode.externalApplication,
                  );
                  return NavigationActionPolicy.CANCEL;
                }

                final holyCoreHost =
                holyCoreUri.host.toLowerCase();
                final bool holyCoreIsSocial =
                    holyCoreHost.endsWith('facebook.com') ||
                        holyCoreHost.endsWith('instagram.com') ||
                        holyCoreHost.endsWith('twitter.com') ||
                        holyCoreHost.endsWith('x.com');

                if (holyCoreIsSocial) {
                  await HolyCoreLinker.holyCoreOpen(holyCoreUri);
                  return NavigationActionPolicy.CANCEL;
                }

                if (_holyCoreIsExternalTable(holyCoreUri)) {
                  final holyCoreMapped =
                  _holyCoreMapExternalToHttp(holyCoreUri);
                  await HolyCoreLinker.holyCoreOpen(holyCoreMapped);
                  return NavigationActionPolicy.CANCEL;
                }

                if (holyCoreScheme != 'http' &&
                    holyCoreScheme != 'https') {
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.ALLOW;
              },
              onCreateWindow:
                  (InAppWebViewController holyCoreController,
                  CreateWindowAction holyCoreReq) async {
                final holyCoreUrl = holyCoreReq.request.url;
                if (holyCoreUrl == null) return false;

                if (HolyCoreKit.holyCoreLooksLikeBareMail(holyCoreUrl)) {
                  final holyCoreMail =
                  HolyCoreKit.holyCoreToMailto(holyCoreUrl);
                  await HolyCoreLinker.holyCoreOpen(
                    HolyCoreKit.holyCoreGmailize(holyCoreMail),
                  );
                  return false;
                }

                final holyCoreScheme =
                holyCoreUrl.scheme.toLowerCase();

                if (holyCoreScheme == 'mailto') {
                  await HolyCoreLinker.holyCoreOpen(
                    HolyCoreKit.holyCoreGmailize(holyCoreUrl),
                  );
                  return false;
                }

                if (holyCoreScheme == 'tel') {
                  await launchUrl(
                    holyCoreUrl,
                    mode: LaunchMode.externalApplication,
                  );
                  return false;
                }

                final holyCoreHost =
                holyCoreUrl.host.toLowerCase();
                final bool holyCoreIsSocial =
                    holyCoreHost.endsWith('facebook.com') ||
                        holyCoreHost.endsWith('instagram.com') ||
                        holyCoreHost.endsWith('twitter.com') ||
                        holyCoreHost.endsWith('x.com');

                if (holyCoreIsSocial) {
                  await HolyCoreLinker.holyCoreOpen(holyCoreUrl);
                  return false;
                }

                if (_holyCoreIsExternalTable(holyCoreUrl)) {
                  final holyCoreMapped =
                  _holyCoreMapExternalToHttp(holyCoreUrl);
                  await HolyCoreLinker.holyCoreOpen(holyCoreMapped);
                  return false;
                }

                if (holyCoreScheme == 'http' || holyCoreScheme == 'https') {
                  holyCoreController.loadUrl(
                    urlRequest: URLRequest(url: holyCoreUrl),
                  );
                }

                return false;
              },
            ),

            if (_holyCoreOverlayBusy)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: const Center(
                    child: HolyCoreSpotlightLoader(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // HOLY утилиты маршрутов (протоколы/внешние “столы”)
  // ========================================================================
  bool _holyCoreIsExternalTable(Uri holyCoreUri) {
    final holyCoreScheme = holyCoreUri.scheme.toLowerCase();
    if (_holyCoreExternalSchemes.contains(holyCoreScheme)) {
      return true;
    }

    if (holyCoreScheme == 'http' || holyCoreScheme == 'https') {
      final holyCoreHost = holyCoreUri.host.toLowerCase();
      if (_holyCoreExternalHosts.contains(holyCoreHost)) {
        return true;
      }
      if (holyCoreHost.endsWith('t.me')) return true;
      if (holyCoreHost.endsWith('wa.me')) return true;
      if (holyCoreHost.endsWith('m.me')) return true;
      if (holyCoreHost.endsWith('signal.me')) return true;
      if (holyCoreHost.endsWith('facebook.com')) return true;
      if (holyCoreHost.endsWith('instagram.com')) return true;
      if (holyCoreHost.endsWith('twitter.com')) return true;
      if (holyCoreHost.endsWith('x.com')) return true;
    }

    return false;
  }

  Uri _holyCoreMapExternalToHttp(Uri holyCoreUri) {
    final holyCoreScheme = holyCoreUri.scheme.toLowerCase();

    if (holyCoreScheme == 'tg' || holyCoreScheme == 'telegram') {
      final holyCoreQp = holyCoreUri.queryParameters;
      final holyCoreDomain = holyCoreQp['domain'];
      if (holyCoreDomain != null && holyCoreDomain.isNotEmpty) {
        return Uri.https('t.me', '/$holyCoreDomain', {
          if (holyCoreQp['start'] != null) 'start': holyCoreQp['start']!,
        });
      }
      final holyCorePath =
      holyCoreUri.path.isNotEmpty ? holyCoreUri.path : '';
      return Uri.https(
        't.me',
        '/$holyCorePath',
        holyCoreUri.queryParameters.isEmpty
            ? null
            : holyCoreUri.queryParameters,
      );
    }

    if (holyCoreScheme == 'whatsapp') {
      final holyCoreQp = holyCoreUri.queryParameters;
      final holyCorePhone = holyCoreQp['phone'];
      final holyCoreText = holyCoreQp['text'];
      if (holyCorePhone != null && holyCorePhone.isNotEmpty) {
        return Uri.https(
          'wa.me',
          '/${HolyCoreKit.holyCoreOnlyDigits(holyCorePhone)}',
          {
            if (holyCoreText != null && holyCoreText.isNotEmpty)
              'text': holyCoreText,
          },
        );
      }
      return Uri.https(
        'wa.me',
        '/',
        {
          if (holyCoreText != null && holyCoreText.isNotEmpty)
            'text': holyCoreText,
        },
      );
    }

    if (holyCoreScheme == 'bnl') {
      final holyCoreNewPath =
      holyCoreUri.path.isNotEmpty ? holyCoreUri.path : '';
      return Uri.https(
        'bnl.com',
        '/$holyCoreNewPath',
        holyCoreUri.queryParameters.isEmpty
            ? null
            : holyCoreUri.queryParameters,
      );
    }

    return holyCoreUri;
  }

  Future<void> _holyCoreSendLoadedOnce() async {
    if (_holyCoreLoadedOnceSent) {
      debugPrint('Wheel Loaded already sent, skip');
      return;
    }

    final holyCoreNow = DateTime.now().millisecondsSinceEpoch;

    await holyCorePostStat(
      holyCoreEvent: 'Loaded',
      holyCoreTimeStart: _holyCoreStartLoadTs,
      holyCoreTimeFinish: holyCoreNow,
      holyCoreUrl: _holyCoreCurrentLane,
      holyCoreAppSid: _holyCoreSpy.holyCoreAfUid,
      holyCoreFirstPageTs: _holyCoreFirstPageTs,
    );

    _holyCoreLoadedOnceSent = true;
  }
}

// ============================================================================
// Пример main, если нужно интегрировать:
// ============================================================================
// … (main остаётся у тебя как есть, тут главное — классы и loader)
// ============================================================================