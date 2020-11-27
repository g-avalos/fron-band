import 'dart:io';

import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:band_names/models/bands.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    // Band(id: '1', name: 'RATT', votes: 4),
    // Band(id: '2', name: 'WHASP', votes: 5),
    // Band(id: '3', name: 'GNR', votes: 2),
    // Band(id: '4', name: 'PETER', votes: 4),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', (payload) {
      this.bands = (payload as List).map((e) => Band.fromMap(e)).toList();
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.off('active-bands');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
  
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text('Bandas', style: TextStyle(color: Colors.black87),
          )),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 30), 
            child: buildIcon(socketService)
          )
        ],
      ),
      body: ListView.builder(
          itemCount: bands.length,
          itemBuilder: (context, i) => _buildListTile(bands[i])),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add), 
            elevation: 1, 
            onPressed: addNewBand
          ),
    );
  }

  Widget _buildListTile(Band band) {
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {},
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
        onTap: () {
          band.votes++;
          setState(() {});
        },
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
      this
          .bands
          .add(Band(id: DateTime.now().toString(), name: nombre, votes: 0));
      setState(() {});
    }

    Navigator.pop(context);
  }

  buildIcon(socketService) {
    if (socketService.serverStatus == ServerStatus.Online) 
      return Icon(Icons.check_circle, color: Colors.green[300]);
    else if (socketService.serverStatus == ServerStatus.Offline) 
      return Icon(Icons.offline_bolt, color: Colors.red[300]);
    else if (socketService.serverStatus == ServerStatus.Connecting) 
      return Icon(Icons.satellite, color: Colors.yellow[300]);
  }
}
