import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/screens/authenticate/sign_in.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 70,
                ),
                Text(
                  'Full Name here',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text('Voters ID Number'),
                SizedBox(
                  height: 50,
                ),
                ProfileFeaturesCard(
                  icon: Icons.person,
                  title: "Personal Info",
                  subtitle: "Edit your profile",
                ),
                SizedBox(
                  height: 3,
                ),
                ProfileFeaturesCard(
                  icon: Icons.how_to_vote,
                  title: "Voting History",
                  subtitle: "Check your votes",
                ),
                SizedBox(
                  height: 3,
                ),
                ProfileFeaturesCard(
                  icon: Icons.settings,
                  title: "Settings",
                  subtitle: "Customize your app",
                ),
                SizedBox(
                  height: 90,
                ),
                FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: 250,
                          child: Center(
                            child: Button(
                                text: "Sign Out",
                                color: MVAColors.primaryColor,
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (contex) => SignIn()),
                                      (route) => false);
                                }),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          width: 250,
                          child: Center(
                            child: Button(
                                text: "Delete Account",
                                color: Colors.red,
                                onPressed: () {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileFeaturesCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const ProfileFeaturesCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {},
        child: Container(
          child: ListTile(
            //titleTextStyle: TextStyle(fontWeight: FontWeight.normal),
            leading: Icon(
              icon,
              color: MVAColors.primaryColor,
            ),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            selectedColor: MVAColors.accentColor,
            trailing: TextButton(
                onPressed: () {},
                child: Icon(
                  Icons.arrow_forward,
                  color: MVAColors.primaryColor,
                )),
          ),
        ));
  }
}
