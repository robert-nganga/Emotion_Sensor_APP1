import "package:app/models/sensor_data.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";

class GrsChart extends StatelessWidget {
  const GrsChart({
    super.key,
    required this.sensorDataList,
    this.windowSize = 10,
  });
  final List<SensorData> sensorDataList;
  final double windowSize;

  @override
  Widget build(BuildContext context) {
    final validData =
        sensorDataList
            .where(
              (data) =>
                  data.timeStamp != null &&
                  data.grs != null &&
                  data.timeStamp!.isFinite &&
                  data.grs!.isFinite,
            )
            .toList();

    List<FlSpot> spots = [];

    if (validData.isNotEmpty) {
      final latestTimeStamp = sensorDataList.last.timeStamp!;
      final oldestTimeStamp = sensorDataList.first.timeStamp!;
      final timeStampRage = latestTimeStamp - oldestTimeStamp;

      for (int i = 0; i < validData.length; i++) {
        final e = validData[i];
        final relativeTimeStamp =
            (e.timeStamp! - oldestTimeStamp) / timeStampRage * windowSize;
        spots.add(FlSpot(relativeTimeStamp, e.grs!));
      }
    }

    double minY = 0.0;
    double maxY = 10.0;

    if (spots.isNotEmpty) {
      minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxY = spots
          .map((e) => e.y)
          .reduce((a, b) => a > b ? a : b); //=> means return
    }

    return Card(
      elevation: 5.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
             Text(
                'GRS',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
        
                ),
              ),
            Expanded(
              child: LineChart(
                duration: Duration(microseconds: 100),
                LineChartData(
                  minX: 0.0,
                  maxX: windowSize,
                  maxY: maxY,
                  minY: minY,
                  borderData: FlBorderData(
                    show: false,
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                      left: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: windowSize / 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)}s',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: ((maxY - minY) /2) == 0 ? 1 : (maxY - minY) /2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxY - minY) /2) == 0 ? 1 : (maxY - minY) /2,
                    //verticalInterval: (maxY - minY)/2
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      dotData: FlDotData(show: false),
                      barWidth: 2,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
