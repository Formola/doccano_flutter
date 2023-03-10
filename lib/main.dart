import 'package:doccano_flutter/components/span_to_validate.dart';
import 'package:doccano_flutter/components/user_data.dart';
import 'package:doccano_flutter/models/label.dart';
import 'package:doccano_flutter/models/span.dart';
import 'package:doccano_flutter/views/annotation_view.dart';
import 'package:doccano_flutter/constants/routes.dart';
import 'package:doccano_flutter/get_started_page.dart';
import 'package:doccano_flutter/globals.dart';
import 'package:doccano_flutter/login_page.dart';
import 'package:doccano_flutter/projects_selection_page.dart';
import 'package:doccano_flutter/views/validation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Hive.registerAdapter<UserData>(UserDataAdapter());
  Hive.registerAdapter<SpanToValidate>(SpanToValidateAdapter());
  Hive.registerAdapter<Label>(LabelAdapter());
  Hive.registerAdapter<Span>(SpanAdapter());

  await Hive.initFlutter();
  await dotenv.load(fileName: ".env");
  await initGlobals();
  await initSession();
  runApp(const DoccanoFlutter());
}

class DoccanoFlutter extends StatefulWidget {
  const DoccanoFlutter({super.key});

  @override
  State<DoccanoFlutter> createState() => _DoccanoFlutterState();
}

class _DoccanoFlutterState extends State<DoccanoFlutter> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Doccano Futter',
        initialRoute: (dotenv.get("ENV") == "development" ||
                sessionBox.get("key") != null)
            ? projectsRoute
            : getStartedRoute,
        routes: {
          getStartedRoute: (context) => const GetStartedPage(),
          loginRoute: (context) => const LoginPage(),
          annotationRoute: (context) => const AnnotationView(),
          validationRoute: (context) => const ValidationView(),
          projectsRoute: (context) => const ProjectsPage(),
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ));
  }
}
