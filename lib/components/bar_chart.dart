import 'package:flutter/material.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

class BarChart extends StatelessWidget {
  const BarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        title: ChartTitle(text: 'Election yearly analysis'),
        // Enable legend
        // legend: const Legend(isVisible: true),
        series: <LineSeries<ElectionData, String>>[
          LineSeries<ElectionData, String>(
              color: MVAColors.primaryColor,
              legendIconType: LegendIconType.pentagon,
              dataSource: <ElectionData>[
                ElectionData(1, 'Worthy'),
                ElectionData(2, 'Jiggy'),
                ElectionData(2, 'Manny'),
                ElectionData(8, 'Prince'),
                ElectionData(8, 'Lince'),
                ElectionData(4, 'Chris'),
                ElectionData(5, 'Barka'),
                ElectionData(12, 'Yarka'),
              ],
              dataLabelSettings: const DataLabelSettings(isVisible: true),
              xValueMapper: (ElectionData candidate, _) => candidate.candidate,
              yValueMapper: (ElectionData candidate, _) => candidate.votes),
        ],
      ),
    );
  }
}

class ElectionData {
  ElectionData(this.votes, this.candidate);
  final int votes;
  final String candidate;
}
