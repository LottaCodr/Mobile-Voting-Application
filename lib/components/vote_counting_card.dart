import 'package:flutter/material.dart';

import '../utilities/colors.dart';

class VoteCountingCard extends StatelessWidget {
  const VoteCountingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.all(10),
      height: 240,
      decoration: BoxDecoration(
          color: MVAColors.accentColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadiusDirectional.circular(50)),
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    '2 days : 40hrs Left',
                    style: TextStyle(
                        color: MVAColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              //add the live below
              Container(
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadiusDirectional.circular(5)),
                width: 60,
                height: 25,
                child: const Center(
                  child: Text(
                    'Live',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),
          //ADDING THE WIDGETS FOR VOTE COUNTING HERE
          const Text(
            '33,000+ Votes',
            style: TextStyle(
                color: MVAColors.textColor,
                fontSize: 32,
                fontWeight: FontWeight.w900),
          ),
          const Text(
            'Comp. Sci Presidential',
            style: TextStyle(
                color: MVAColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 29,
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
                decoration: BoxDecoration(
                    color: MVAColors.primaryColor,
                    borderRadius: BorderRadiusDirectional.circular(100)),
                width: 200,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Monitor Election',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Icon(
                      Icons.arrow_forward_outlined,
                      color: Colors.white,
                    )
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
