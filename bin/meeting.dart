import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import 'config.dart';

// CREATE TABLE meetings (
//   id SERIAL PRIMARY KEY,
//   project_id INT NOT NULL,
//   scheduled TIMESTAMP NOT NULL,
//   description TEXT NOT NULL,
//   files JSON NOT NULL
// );

// INSERT INTO meetings (project_id, scheduled, description, files) VALUES (
//   	2,
// 	CURRENT_TIMESTAMP,
//   	'First meeting',
//     '["filea", "fileb"]'
// );

class Service {
  final PostgreSQLConnection connection;

  Service()
      : connection = PostgreSQLConnection(
            Config.databaseUrl, Config.databasePort, Config.databaseName,
            username: Config.databaseUsername,
            password: Config.databasePassword);

  Future<void> init() async {
    await connection.open();
  }

  static Map<String, dynamic> meetingToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'project_id': row[1],
      'scheduled': (row[2] as DateTime).toIso8601String(),
      'description': row[3],
      'files': jsonDecode(row[4])
    };
  }

  Handler get handler {
    final router = Router();

    // list all meetings for all projects
    // if there is parameter project_id, then list only meetings for that project
    router.get('/meetings', (Request request) async {
      final projectId = request.url.queryParameters['project_id'];
      List<List<dynamic>> results;

      if (projectId == null) {
        results = await connection.query(
            'SELECT id, project_id, scheduled, description, files FROM meetings');
      } else {
        results = await connection.query(
            'SELECT id, project_id, scheduled, description, files FROM meetings WHERE project_id=@projectId',
            substitutionValues: {'projectId': int.parse(projectId)});
      }

      return Response.ok(jsonEncode(results.map(meetingToMap).toList()));
    });

    // new meeting
    router.post('/meetings', (Request request) async {
      Map<String, dynamic> data = jsonDecode(await request.readAsString());

      // TODO check if given project exists
      int projectId = data['project_id'];
      DateTime scheduled = DateTime.parse(data['scheduled']);
      String desc = data['description'];
      String files = jsonEncode((data['files'] as List).cast<String>());

      await connection.query(
          'INSERT INTO meetings (project_id, scheduled, description, files) VALUES (@projectId, @scheduled, @desc, @files)',
          substitutionValues: {
            'projectId': projectId,
            'scheduled': scheduled,
            'desc': desc,
            'files': files
          });

      return Response.ok(null);
    });

    // edit meeting
    router.put('/meetings/<meetingIdStr|[0-9]+>',
        (Request request, String meetingIdStr) async {
      int meetingId = int.parse(meetingIdStr);

      Map<String, dynamic> data = jsonDecode(await request.readAsString());

      // TODO check if given project exists
      int projectId = data['project_id'];
      DateTime scheduled = DateTime.parse(data['scheduled']);
      String desc = data['description'];
      String files = jsonEncode((data['files'] as List).cast<String>());

      await connection.query(
          'UPDATE meetings SET project_id=@projectId, scheduled=@scheduled, description=@desc, files=@files WHERE id=@meetingId',
          substitutionValues: {
            'projectId': projectId,
            'scheduled': scheduled,
            'desc': desc,
            'files': files,
            'meetingId': meetingId
          });

      return Response.ok(null);
    });

    // list all meetings by project
    // (call projects microservice first to list all projects)
    router.get('/meetings/by_project', (Request request) async {
      var response =
          await http.get('${Config.projectsMicroserviceUrl}/projects');
      List<Map<String, dynamic>> projects =
          jsonDecode(response.body).cast<Map<String, dynamic>>();

      var grouped = [];

      for (var project in projects) {
        // add query results to project
        List<List<dynamic>> results = await connection.query(
            'SELECT id, project_id, scheduled, description, files FROM meetings WHERE project_id=@projectId',
            substitutionValues: {'projectId': project['id']});

        project['meetings'] = results.map(meetingToMap).toList();
        grouped.add(project);
      }

      return Response.ok(jsonEncode(grouped));
    });

    // error 404
    router.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found');
    });

    return router;
  }
}
