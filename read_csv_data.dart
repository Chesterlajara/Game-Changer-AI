import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';

void main() async {
  try {
    final file = File('data/team_data.csv');
    if (await file.exists()) {
      final String csvString = await file.readAsString();
      final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvString, eol: '\n');
      
      // Print headers
      if (rowsAsListOfValues.isNotEmpty) {
        print('Headers:');
        print(rowsAsListOfValues[0]);
        print('\n');
      }
      
      // Print first few rows of data
      if (rowsAsListOfValues.length > 1) {
        print('First 3 rows of data:');
        for (int i = 1; i < 4 && i < rowsAsListOfValues.length; i++) {
          print('Row $i:');
          print(rowsAsListOfValues[i]);
          print('\n');
        }
      }
      
      print('Total rows: ${rowsAsListOfValues.length}');
    } else {
      print('CSV file not found');
    }
  } catch (e) {
    print('Error reading CSV: $e');
  }
}
