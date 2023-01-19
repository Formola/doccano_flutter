import 'package:doccano_flutter/globals.dart';
import 'package:doccano_flutter/models/projects.dart';
import 'package:doccano_flutter/project_menu_page.dart';
import 'package:doccano_flutter/utils/doccano_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'components/circular_progress_indicator_with_text.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late Future<List<Project?>?> _future;

  Future<List<Project?>?> getData() async {
    if (dotenv.get("ENV") == "development") {
      await login(dotenv.get("USERNAME"), dotenv.get("PASSWORD"));
    }
    List<Project?>? projects = await getProjects();

    return projects;
  }

  @override
  void initState() {
    super.initState();
    _future = getData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Project?>? projects = snapshot.data;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Your Projects'),
            ),
            body: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(children: [
                Expanded(
                    child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: projects!.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(70),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minHeight: 100, maxHeight: 200),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Card(
                                  shadowColor: Colors.blue[700],
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                      colors: [
                                        Colors.blue,
                                        Color.fromRGBO(32, 109, 225, 0.985)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    projects[index]!
                                                        .name!
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'ID: ${projects[index]!.id!}',
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'Type: ${projects[index]!.projectType}',
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    projects[index]!
                                                        .description
                                                        .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                ),
                                              ]),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await prefs.setInt('PROJECT_ID',
                                                projects[index]!.id!);
                                            // ignore: use_build_context_synchronously
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    settings: RouteSettings(
                                                      name: '/projectMenu/',
                                                      arguments:
                                                          projects[index],
                                                    ),
                                                    builder: (context) =>
                                                        ProjectMenuPage(
                                                            passedProject:
                                                                projects[
                                                                    index])));
                                          },
                                          child: const Text(
                                            'Select',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }))
              ]),
            ),
          );
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicatorWithText("Fetching Projects..."),
          ),
        );
      },
    );
  }
}
