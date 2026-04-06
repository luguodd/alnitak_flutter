import 'package:shared_preferences/shared_preferences.dart';

/// API 配置
/// 统一管理 API 地址，支持默认值 + SharedPreferences 覆盖（便于环境/调试切换）
class ApiConfig {
  ApiConfig._();

  static const String _httpsEnabledKey = 'https_enabled';
  static const String _hostOverrideKey = 'api_host_override';
  static const String _portOverrideKey = 'api_port_override';

  /// 默认服务器域名（已改为你的公网 IP）
  static const String defaultHost = '43.255.120.226';
  
  /// 官方 Docker 默认后端端口
  static const int defaultPortHttp = 9000;
  
  /// 除非你配置了 Nginx SSL 证书，否则此端口在 Docker 默认部署中不可用
  static const int defaultPortHttps = 9001; 

  /// 分享域名（通常指向你的前端 9010 端口或域名）
  static const String defaultShareHost = '43.255.120.226';
  static const int defaultSharePort = 9010; 

  // --- 修改重点：默认初始状态设为 false，以匹配 Docker 默认的 HTTP 环境 ---
  static bool _httpsEnabled = false; 
  
  static String? _hostOverride;
  static int? _portOverride;

  /// 当前生效的服务器域名
  static String get host => _hostOverride ?? defaultHost;
  
  /// 当前生效的 API 端口
  static int get port => _portOverride ?? (_httpsEnabled ? defaultPortHttps : defaultPortHttp);
  
  static String get shareHost => defaultShareHost;
  static String get sharePortStr => (sharePort == 80 || sharePort == 443) ? '' : ':$sharePort';
  static int get sharePort => defaultSharePort;

  static bool get httpsEnabled => _httpsEnabled;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // --- 修改重点：?? 后面的默认值必须改为 false ---
    // 这样当用户第一次打开 APP 时，会默认走 http://IP:9000
    _httpsEnabled = prefs.getBool(_httpsEnabledKey) ?? false;
    
    final savedHost = prefs.getString(_hostOverrideKey);
    _hostOverride = (savedHost != null && savedHost.isNotEmpty) ? savedHost : null;
    final savedPort = prefs.getInt(_portOverrideKey);
    _portOverride = (savedPort != null && savedPort > 0) ? savedPort : null;
  }

  /// 设置 API 主机/端口覆盖
  static Future<void> setHostPortOverride({String? host, int? port}) async {
    final prefs = await SharedPreferences.getInstance();
    if (host != null) {
      _hostOverride = host.isEmpty ? null : host;
      if (_hostOverride == null) {
        await prefs.remove(_hostOverrideKey);
      } else {
        await prefs.setString(_hostOverrideKey, _hostOverride!);
      }
    }
    if (port != null) {
      _portOverride = port <= 0 ? null : port;
      if (_portOverride == null) {
        await prefs.remove(_portOverrideKey);
      } else {
        await prefs.setInt(_portOverrideKey, _portOverride!);
      }
    }
  }

  /// 设置 HTTPS 启用状态
  static Future<void> setHttpsEnabled(bool enabled) async {
    _httpsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_httpsEnabledKey, enabled);
  }

  /// 获取当前使用的协议
  static String get _protocol => _httpsEnabled ? 'https' : 'http';

  static String get baseUrl => '$_protocol://$host:$port';
  static String get httpsBaseUrl => 'https://$host:$port';
  static String get httpBaseUrl => 'http://$host:$port';
  static String get webUrl => '$_protocol://$host';

  static String getShareUrl(String path) {
    return '$_protocol://$shareHost$sharePortStr/$path';
  }
}
