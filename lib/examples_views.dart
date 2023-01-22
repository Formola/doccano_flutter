import 'package:doccano_flutter/components/circular_progress_indicator_with_text.dart';
import 'package:doccano_flutter/homepage.dart';
import 'package:doccano_flutter/models/examples.dart';
import 'package:doccano_flutter/single_example_page.dart';
import 'package:doccano_flutter/utils/doccano_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants/get_rows_for_page.dart';

class ExampleView extends StatefulWidget {
  const ExampleView({super.key});

  @override
  State<ExampleView> createState() => _ExampleViewState();
}

class _ExampleViewState extends State<ExampleView> {
  late Future<List<Example?>?> _future;
  late int offset;

  Future<List<Example?>?> getData() async {
    if (dotenv.get("ENV") == "development") {
      await login(dotenv.get("USERNAME"), dotenv.get("PASSWORD"));
    }

    List<Example?>? examples = await getExamples('', 0);

    return examples;
  }

  @override
  void initState() {
    super.initState();
    _future = getData();
    offset = 50;
  }

  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dataset')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Example?>? examples = snapshot.data;

            return LayoutBuilder(builder: (context, constraint) {
              return Container(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Center(
                    child: PaginatedDataTable(
                      onPageChanged: (value) async {
                        scrollController.jumpTo(0.0);

                        List<Example?>? fetchedExamples =
                            await getExamples('', offset);
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
                ),
              );
            });
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
              examples![index]!.id.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 160,
            child: ClipRect(
              child: Text(
                examples![index]!.text!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
        DataCell(TextButton(
          onPressed: () {
            print(examples![index]!.id!);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Homepage(
                  example: examples![index]!
                ),
              ),
            );
          },
          child: const Text(
            'Annotate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )),
      ],
    );
  }
}
