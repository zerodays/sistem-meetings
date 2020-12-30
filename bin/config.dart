import 'dart:io' as io;

final env = io.Platform.environment;

class Config {
  static dynamic getValue(String key, var defaultValue) {
    if (env.containsKey(key)) {
      return env[key];
    }
    return defaultValue;
  }

  static final hostname = getValue('SISTEM_MEETINGS_HOSTNAME', '0.0.0.0'),
      port = int.parse(getValue('SISTEM_MEETINGS_PORT', '8083'));

  static final databaseUrl =
          getValue('SISTEM_MEETINGS_DATABASE_HOST', 'localhost'),
      databasePort = int.parse(getValue('SISTEM_MEETINGS_DATABASE_PORT', '5432'));

  static final databaseName =
      getValue('SISTEM_MEETINGS_DATABASE_NAME', 'sistem_meetings');

  static final databaseUsername =
          getValue('SISTEM_MEETINGS_DATABASE_USER', null),
      databasePassword = getValue('SISTEM_MEETINGS_DATABASE_PASSWORD', null);

  static final projectsMicroserviceUrl =
          getValue('SISTEM_PROJECTS_MICROSERVICE_URL', 'http://localhost:8082/api/v1');
}