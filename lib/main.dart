import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mobile_voting_application/view/wrapper.dart';
import 'package:mobile_voting_application/utilities/colors.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Voting App',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        primaryColor: MVAColors.primaryColor,
        hintColor: MVAColors.accentColor,
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)
            //         //Define more textstyles if needed
            ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: MVAColors.backgroundColor),
      ),
      home: const Wrapper(),
    );
  }
}




//use later

// int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }
// Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'You have voted the strings of times:',
//                 ),
//                 const SizedBox(
//                   width: 5,
//                 ),
//                 Text(
//                   '$_counter',
//                   style: Theme.of(context).textTheme.headlineMedium,
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),

// floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),