import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'meeting.dart';

void main(List<String> args) async {
  var service = Service();

  await service.init();

  var router = Router();
  router.mount('/api/v1/', service.handler);

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  var server = await io.serve(handler, Config.hostname, Config.port);

  print('Serving at http://${server.address.host}:${server.port}');
}
