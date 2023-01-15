import 'package:doccano_flutter/constants/routes.dart';
import 'package:flutter/material.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  margin: const EdgeInsets.only(right: 25),
                  child:
                      Center(child: Image.asset('images/exoticdoccano.png'))),
              const SizedBox(
                height: 150,
              ),
              const Text(
                'Mobile Client for Doccano!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 45,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, loginRoute);
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.all(16.0),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                child: const Text(
                  'Start using Doccano!!',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
