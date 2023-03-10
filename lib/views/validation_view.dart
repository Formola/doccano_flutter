import 'package:doccano_flutter/constants/bottom_navbar_height.dart';
import 'package:doccano_flutter/globals.dart';
import 'package:doccano_flutter/widget/circular_progress_indicator_with_text.dart';
import 'package:doccano_flutter/models/examples.dart';
import 'package:doccano_flutter/validation_page.dart';
import 'package:doccano_flutter/utils/doccano_api.dart';
import 'package:flutter/material.dart';

import '../constants/get_rows_for_page.dart';

class ValidationView extends StatefulWidget {
  const ValidationView({super.key});

  @override
  State<ValidationView> createState() => _ValidationView();
}

class _ValidationView extends State<ValidationView> {
  late Future<List<Example?>?> _future;
  late int offset;

  Future<List<Example?>?> getData() async {
    String? roleSearchParameter;
    var userData = await getLoggedUserRole();
    String loggedUserRole = "";
    if (userData != null) {
      loggedUserRole = userData["rolename"];
    }

    if (loggedUserRole == "annotation_approver") {
      roleSearchParameter = "annotator";
    }
    List<Example?>? examples = await getExamples('true', 0,
        annotationApproverRole: roleSearchParameter);

    return examples;
  }

  @override
  void initState() {
    _future = getData().then((examples) {
      setState(() {
        
      });
      return examples;
    })
    ;
    offset = 50;
    super.initState();
  }

  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    prefs.setBool("DELETE_SPAN", false);

    final appBar = AppBar(
      title: const Text('Dataset Ready for Validation'),
      automaticallyImplyLeading: false,
    );

    return Scaffold(
      appBar: appBar,
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Example?>? examples = snapshot.data;

            return RefreshIndicator(
              onRefresh: () {
                return Future.delayed(const Duration(seconds: 1), () {
                  setState(() {
                    _future = getData();
                  });
                });
              },
              child: LayoutBuilder(builder: (context, constraint) {
                return (examples?.length ?? 0) > 0
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          controller: scrollController,
                          child: PaginatedDataTable(
                            onPageChanged: (value) async {
                              scrollController.jumpTo(0.0);

                              List<Example?>? fetchedExamples =
                                  await getExamples('true', offset);
                              for (var example in fetchedExamples) {
                                examples!.add(example);
                              }
                              setState(() {
                                offset += 50;
                              });
                            },
                            dataRowHeight: 90,
                            columnSpacing: 30,
                            horizontalMargin: 10,
                            showCheckboxColumn: false,
                            rowsPerPage: getRowsForPage(constraint),
                            sortColumnIndex: 1,
                            sortAscending: true,
                            columns: const [
                              DataColumn(
                                  label: Text(
                                'ID',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              )),
                              DataColumn(
                                  label: Text(
                                'Text',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              )),
                              DataColumn(
                                  label: Text(
                                'Action',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              )),
                            ],
                            source: MyDataSource(examples, context),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height -
                              (appBar.preferredSize.height) -
                              bottomNavbarHeigth,
                          child: const Center(
                            child: Text(
                              'No examples to validate',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                        ),
                      );
              }),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
            }
            
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicatorWithText(
                  "Fetching labels and examples..."),
            ),
          );
        },
      ),
    );
  }
}

class MyDataSource extends DataTableSource {
  final List<Example?>? examples;
  final BuildContext context;

  MyDataSource(this.examples, this.context);

  @override
  int get rowCount => examples?.length ?? 0;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int index) {
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              examples?[index]!.id.toString() ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 160,
            child: ClipRect(
              child: Text(
                examples?[index]!.text ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
        DataCell(TextButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ValidationPage(passedExample: examples![index]!)));
          },
          child: const Text(
            'Validate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )),
      ],
    );
  }
}
