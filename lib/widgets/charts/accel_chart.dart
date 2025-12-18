import "package:app/models/sensor_data.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";

class AccelerometerChart extends StatelessWidget {
  const AccelerometerChart({
    super.key,
    required this.sensorDataList,
    this.windowSize = 10,
  });
  final List<SensorData> sensorDataList;
  final double windowSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validData = sensorDataList
        .where(
          (data) =>
      data.timeStamp != null &&
          data.accelX != null &&
          data.timeStamp!.isFinite &&
          data.accelX!.isFinite,
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
        spots.add(FlSpot(relativeTimeStamp, e.accelX!));
      }
    }

    double minY = 0.0;
    double maxY = 10.0;

    if (spots.isNotEmpty) {
      minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

      // Add padding to Y axis for better visualization
      final range = maxY - minY;
      minY -= range * 0.1;
      maxY += range * 0.1;
    }

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Accel (X-axis)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (spots.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${spots.length} samples',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: spots.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ac_unit,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No accelerometer data available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
                  : LineChart(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                LineChartData(
                  minX: 0.0,
                  maxX: windowSize,
                  maxY: maxY,
                  minY: minY,
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.grey.shade300, width: 1.5),
                      left: BorderSide(
                          color: Colors.grey.shade300, width: 1.5),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text(
                          'Time (s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: windowSize / 4,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              value.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          'm/s²',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: ((maxY - minY) / 2) == 0
                            ? 1
                            : (maxY - minY) / 2,
                        getTitlesWidget: (value, meta) {
                          String formatNumber(double val) {
                            if (val.abs() >= 1000000) {
                              return '${(val / 1000000).toStringAsFixed(1)}M';
                            } else if (val.abs() >= 1000) {
                              return '${(val / 1000).toStringAsFixed(1)}k';
                            } else {
                              return val.toStringAsFixed(1);
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              formatNumber(value),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: ((maxY - minY) / 2) == 0
                        ? 1
                        : (maxY - minY) / 2,
                    verticalInterval: windowSize / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      dotData: const FlDotData(show: false),
                      barWidth: 2.5,
                      color: Colors.blue,
                      isStrokeCapRound: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                      shadow: Shadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                      ),
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