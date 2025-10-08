import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../../db_helper.dart';

class SFormRiverManualDataLog extends StatefulWidget {
  _SFormRiverManualDataLog createState() => _SFormRiverManualDataLog();
}

class _SFormRiverManualDataLog extends State<SFormRiverManualDataLog> {

  late String _type = '';
  late int _selectedItem = 0;
  bool connectionStatus = true;

  Item? selectedItem;

  List<Item> items = [
    Item(id: 1, categoryName: 'Sampling Data'),
  ];

  final db = DBHelper();

  @override
  void initState() {
    super.initState();
    _checkInternet();
  }

  Future<void> _checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        connectionStatus = false;
      });
      return;
    }

    // Check actual internet access
    try {
      final result = await http.get(Uri.parse('https://google.com')).timeout(Duration(seconds: 5));
      if (result.statusCode == 200) {
        setState(() {
          connectionStatus = true;
        });
      } else {
        setState(() {
          connectionStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        connectionStatus = false;
      });
    }
  }

  List<dynamic> dataList = [];
  bool isLoading = true;

  Future<List<Map<String, dynamic>>> fetchDataRiverSampleFromServer() async {

    final response = await http.get(Uri.parse('https://mmsv2.pstw.com.my/api/river/api-get-river.php?action=display-log-manual-sample'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load data');
    }

  }

  Future<List<Map<String, dynamic>>> fetchDataRiverSampleFromLocal() async {
    final db = await DBHelper.initDb();
    final result = await db.rawQuery('''
    SELECT tbl_river_manual_sampling.stationID,tbl_river_manual_sampling.timestamp,
    tbl_river_manual_sampling.stationName
    FROM tbl_river_manual_sampling
      INNER JOIN tbl_river_station ON tbl_river_manual_sampling.stationID = tbl_river_station.stationID
        ORDER BY tbl_river_manual_sampling.timestamp DESC
  ''');
    return result;
  }


  Widget buildFromServerRiverSample() {
    return SizedBox(
      height: 500,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDataRiverSampleFromServer(),
        builder: (context,snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No data found'));

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['stationID'] +" - "+ item['riverName']),
                    SizedBox(height: 5.0,),
                    Text(item['timestamp'].toString(),style: TextStyle(fontWeight: FontWeight.bold),),
                    SizedBox(height: 5.0,),
                    Row(
                      children: [
                        Text('Status :'),
                        Text('Submitted to Server',
                          style: TextStyle(fontWeight: FontWeight.bold),),
                      ],
                    ),
                    SizedBox(height: 10.0,),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildFromLocalRiverSample() {
    return SizedBox(
      height: 500,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDataRiverSampleFromLocal(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No data found'));

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['stationID'] +" - "+ item['stationName']),
                    SizedBox(height: 5.0,),
                    Text(item['timestamp'].toString(),style: TextStyle(fontWeight: FontWeight.bold),),
                    SizedBox(height: 5.0,),
                    Row(
                      children: [
                        Text('Status :'),
                        Text('Submitted to Local',
                          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red),),
                      ],
                    ),
                    SizedBox(height: 10.0,),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DATA LOG STATUS',
            style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          SizedBox(height: 10.0,),

          Text('Keywords',style: TextStyle(fontSize: 15),),
          SizedBox(height: 5.0,),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Search...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
            ),
          ),
          SizedBox(height: 10.0,),

          Text('Category list'),
          SizedBox(height: 5.0,),
          DropdownButtonFormField<Item>(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
            ),
            items: items.map((item) {
              return DropdownMenuItem<Item>(
                value: item,
                child: Text(item.categoryName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedItem = value;
                _selectedItem = selectedItem!.id;
                print('Selected ID: ${selectedItem!.id}');
                print('Selected Name: ${selectedItem!.categoryName}');

              });
            },
            validator: (value) => value == null ? 'Please select an category' : null,
          ),
          SizedBox(height: 10.0,),
          Text('Searching Result...',
            style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),

          Divider(),
          if (_selectedItem == 1) ... [
            connectionStatus ? buildFromServerRiverSample() : buildFromLocalRiverSample(),
          ]


        ],
      ),
    );
  }

}

class Item {
  final int id;
  final String categoryName;

  Item({required this.id, required this.categoryName});

  @override
  String toString() => categoryName; // Optional: for debugging or display
}