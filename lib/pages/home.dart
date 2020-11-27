import 'dart:io';

import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:band_names/models/bands.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    Band(id: '1', name: 'RATT', votes: 4),
    Band(id: '2', name: 'WHASP', votes: 5),
    Band(id: '3', name: 'GNR', votes: 2),
    Band(id: '4', name: 'PETER', votes: 4),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((e) => Band.fromMap(e)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.off('active-bands');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(
          'Bandas',
          style: TextStyle(color: Colors.black87),
        )),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(margin: EdgeInsets.only(right: 30), child: buildIcon())
        ],
      ),
      body: Column(
        children: <Widget>[
          _showGraph(),
          Expanded(
            child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (context, i) => _buildListTile(bands[i])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add), elevation: 1, onPressed: addNewBand),
    );
  }

  Widget _buildListTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('del-band', {'id': band.id}),
      background: Container(
        padding: EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            )),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: TextStyle(fontSize: 20)),
        onTap: () => vote(band),
      ),
    );
  }

  addNewBand() {
    final tec = TextEditingController();

    if (Platform.isAndroid) {
      dialogAndroid(tec);
    } else if (Platform.isIOS) {
      dialogIOS(tec);
    }
  }

  Future dialogIOS(TextEditingController tec) {
    return showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text('Nueva banda'),
            content: TextField(
              controller: tec,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('Agregar'),
                  onPressed: () {
                    addBandToList(tec.text);
                  }),
              CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.pop(context);
                  })
            ],
          );
        });
  }

  Future dialogAndroid(TextEditingController tec) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Nueva banda'),
              content: TextField(
                controller: tec,
              ),
              actions: <Widget>[
                MaterialButton(
                    child: Text('Agregar'),
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () {
                      addBandToList(tec.text);
                    })
              ],
            ));
  }

  void addBandToList(String nombre) {
    if (nombre.trim().length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': nombre});
    }

    Navigator.pop(context);
  }

  buildIcon() {
    final socketService = Provider.of<SocketService>(context);

    if (socketService.serverStatus == ServerStatus.Online)
      return Icon(Icons.check_circle, color: Colors.green[300]);
    else if (socketService.serverStatus == ServerStatus.Offline)
      return Icon(Icons.offline_bolt, color: Colors.red[300]);
    else if (socketService.serverStatus == ServerStatus.Connecting)
      return Icon(Icons.satellite, color: Colors.yellow[300]);
  }

  vote(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit('vote-band', {'id': band.id});
  }

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();

    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return Container(
      padding: EdgeInsets.only(top: 10),
      width: double.infinity,
      height: 200,
      child: 
        PieChart(
          dataMap: dataMap,
          animationDuration: Duration(milliseconds: 800),
          chartLegendSpacing: 32,
          initialAngleInDegree: 0,
          chartType: ChartType.ring,
          legendOptions: LegendOptions(
            showLegendsInRow: false,
            legendPosition: LegendPosition.right,
            showLegends: true,
            legendTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          chartValuesOptions: ChartValuesOptions(
            showChartValueBackground: true,
            showChartValues: true,
            showChartValuesInPercentage: false,
            showChartValuesOutside: false,
          ),
      )
    );
  }
}
