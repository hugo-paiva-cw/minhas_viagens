import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  late String? idTrip;

  MapScreen({this.idTrip, Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapState();
}

class _MapState extends State<MapScreen> {

  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  CameraPosition _cameraPosition = const CameraPosition(
      target: LatLng(-23.562436, -45.655005),
      zoom: 18
  );
  FirebaseFirestore db = FirebaseFirestore.instance;


  _onMapCreated( GoogleMapController controller ) {
    _controller.complete( controller );
  }

  _addMarker( LatLng latLng ) async {
    List<Placemark> addressesList = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    if ( addressesList.isNotEmpty ) {
      Placemark address = addressesList[0];
      String street = address.thoroughfare ?? 'Rua sem nome';
      Marker marker = Marker(
          markerId: MarkerId('marcador ${latLng.latitude}-${latLng.longitude}'),
          position: latLng,
          infoWindow: InfoWindow(
              title: street
          )
      );

      setState(() {
        _markers.add( marker );

        //Save on Firebase
        Map<String, dynamic> trip = {};

        trip['title'] = street;
        trip['latitude'] = latLng.latitude;
        trip['longitude'] = latLng.longitude;

        db.collection('trips')
        .add(trip);
      });
    }

  }

  _moveCamera() async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        _cameraPosition
      )
    );
  }

  _addListenerLocation() {

    const locationSettings = LocationSettings(
      distanceFilter: 10,
      accuracy: LocationAccuracy.high,
    );
    Geolocator.getPositionStream(
        locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _cameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
          zoom: 18
        );
        _moveCamera();
      });
    });
  }

  _getTripByID(String idTrip) async {

    if ( idTrip != null ) {
      DocumentSnapshot documentSnapshot = await db.collection('trips').doc(idTrip).get();

      var data = jsonEncode(documentSnapshot.data());
      Map<String, dynamic> valueData = jsonDecode(data);

      String title = valueData['title'];
      LatLng latLng = LatLng(valueData['latitude'], valueData['longitude']);

      setState(() {
        Marker marker = Marker(
            markerId: MarkerId('marcador ${latLng.latitude}-${latLng.longitude}'),
            position: latLng,
            infoWindow: InfoWindow(
                title: title
            )
        );

        _markers.add( marker );
        _cameraPosition = CameraPosition(
            target: latLng,
          zoom: 18
        );
        _moveCamera();

      });

    } else {
      _addListenerLocation();
    }
  }

  @override
  initState() {
    super.initState();

    _getTripByID(widget.idTrip.toString());

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _cameraPosition,
        onMapCreated: _onMapCreated,
        onLongPress: _addMarker,
        markers: _markers,
        myLocationEnabled: true,
      ),
    );
  }
}
