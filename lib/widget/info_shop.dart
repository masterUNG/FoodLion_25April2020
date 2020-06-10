import 'package:flutter/material.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoShop extends StatefulWidget {
  @override
  _InfoShopState createState() => _InfoShopState();
}

class _InfoShopState extends State<InfoShop> {
  UserShopModel userShopModel;

  @override
  void initState() {
    super.initState();
    findShop();
  }

  Future<Null> findShop() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String idShop = preferences.getString('id');
    print('idShop = $idShop');

    try {
      var object = await MyAPI().findDetailShopWhereId(idShop);
      setState(() {
        userShopModel = object;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 250.0,
      child: userShopModel == null
          ? MyStyle().showProgress()
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  MyStyle().showTitle(userShopModel.name),
                  showImage(),
                  showMap()
                ],
              ),
            ),
    );
  }

  Marker yourLocation() {
    return Marker(
      markerId: MarkerId('myLoaction'),
      position: LatLng(
        double.parse(userShopModel.lat),
        double.parse(userShopModel.lng),
      ),infoWindow: InfoWindow(title: userShopModel.name)
    );
  }

  Set<Marker> myMarker() {
    return <Marker>[yourLocation()].toSet();
  }

  Container showMap() {
    LatLng latLng = LatLng(
        double.parse(userShopModel.lat), double.parse(userShopModel.lng));
    CameraPosition position = CameraPosition(target: latLng, zoom: 16);
    return Container(
      width: 250.0,
      height: 250.0,
      child: GoogleMap(
        initialCameraPosition: position,
        onMapCreated: (controller) {},markers: myMarker(),
      ),
    );
  }

  Container showImage() {
    return Container(
      width: 250.0,
      height: 250.0,
      child: Image.network(userShopModel.urlShop),
    );
  }
}
