class Env {
  const Env._();
  static const bool isDev = true;
  static const String baseApiUrl     = isDev ? _apiDevUrl          : _apiUrl;
  static const String socketCluster  = isDev ? _testSocketCluster  : _socketClusterUrl;

  static const String _apiUrl             = String.fromEnvironment('API_URL',             defaultValue: 'https://stations.wetaxi.ma');
  static const String _apiDevUrl          = String.fromEnvironment('API_DEV_URL',         defaultValue: 'https://stations.wetaxi.ma');
  static const String _socketClusterUrl   = String.fromEnvironment('SOCKET_CLUSTER_URL',  defaultValue: 'wss://stations.wetaxi.ma/socketcluster/');
  static const String _testSocketCluster  = String.fromEnvironment('TEST_SOCKET_CLUSTER_URL', defaultValue: 'wss://stations.wetaxi.ma/socketcluster/');
}
