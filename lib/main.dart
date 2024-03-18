import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_voting_application/screens/wrapper.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Voting App',
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
        primaryColor: CustomColors.primaryColor,
        hintColor: CustomColors.accentColor,
        // textTheme:
        //     const TextTheme(bodyLarge: TextStyle(color: CustomColors.textColor)
        //         //Define more textstyles if needed
        //         ),
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: CustomColors.backgroundColor),
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