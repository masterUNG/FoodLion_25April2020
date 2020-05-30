import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/order_user_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class RiderSuccess extends StatefulWidget {
  final OrderUserModel orderUserModel;
  RiderSuccess({Key key, this.orderUserModel}) : super(key: key);

  @override
  _RiderSuccessState createState() => _RiderSuccessState();
}

class _RiderSuccessState extends State<RiderSuccess> {
  OrderUserModel orderUserModel;
  String nameShop, nameUser, tokenUser;
  int distance, transport, sumFood = 0;
  LatLng shopLatLng, userLatLng;
  IconData shopMarkerIcon;
  List<String> nameFoods = List();
  List<int> amounts = List();
  List<int> prices = List();
  List<int> sums = List();
  int sumPrice = 0;
  bool stateStatus = true;
  double lat, lng;

  @override
  void initState() {
    super.initState();
    orderUserModel = widget.orderUserModel;
    findDetailShopAnUser();
    findOrder();
    findAmound();
    findLocation();
  }

  Future<void> findLocation() async {
    LocationData myData = await locationData();
    setState(() {
      lat = myData.latitude;
      lng = myData.longitude;
    });
  }

  Future<LocationData> locationData() async {
    var location = Location();

    try {
      return await location.getLocation();
    } catch (e) {
      return null;
    }
  }

  Future<void> findDetailShopAnUser() async {
    UserShopModel userShopModel =
        await MyAPI().findDetailShopWhereId(orderUserModel.idShop);

    UserModel userModel =
        await MyAPI().findDetailUserWhereId(orderUserModel.idUser);

    setState(() {
      nameShop = userShopModel.name;
      shopLatLng = LatLng(double.parse(userShopModel.lat.trim()),
          double.parse(userShopModel.lng.trim()));

      nameUser = userModel.name;
      tokenUser = userModel.token;
      userLatLng = LatLng(double.parse(userModel.lat.trim()),
          double.parse(userModel.lng.trim()));
    });
  }

  Future<void> findAmound() async {
    String string = orderUserModel.amountFoods;
    string = string.substring(1, string.length - 1);
    List<String> strings = string.split(',');

    // int i = 0;
    for (var string in strings) {
      setState(() {
        amounts.add(int.parse(string.trim()));
      });
      // i++;
    }
  }

  Future<void> findOrder() async {
    String string = orderUserModel.idFoods;
    string = string.substring(1, string.length - 1);
    List<String> strings = string.split(',');

    for (var string in strings) {
      FoodModel foodModel = await MyAPI().findDetailFoodWhereId(string.trim());
      setState(() {
        nameFoods.add(foodModel.nameFood);
        prices.add(int.parse(foodModel.priceFood));
      });
    }
  }

  Widget successJob() => FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => confirmSuccessDialog(),
        child: Icon(Icons.android),
      );

  Future<Null> confirmSuccessDialog() async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('ส่งอาหารถึง ลูกค้าแล้ว ?'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              OutlineButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  editOrderSuccess();
                },
                icon: Icon(
                  Icons.check,
                  color: Colors.green,
                ),
                label: Text('ส่งเรียบร้อย'),
              ),
              OutlineButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.clear,
                  color: Colors.red,
                ),
                label: Text('ยังไม่ถึง กำลังไป'),
              )
            ],
          )
        ],
      ),
    );
  }

  Future<Null> editOrderSuccess() async {
    String url =
        'http://movehubs.com/app/editOrderWhereIdRider.php?isAdd=true&id=${orderUserModel.id}&Success=Success';
    await Dio().get(url).then((value) {
      if (value.toString() == 'true') {

        MyAPI().notificationAPI(tokenUser, 'รับอาหารจากร้าน', 'Rider รับอาหารจากร้านแล้ว ครับ กำลังไปส่ง');

        MaterialPageRoute route = MaterialPageRoute(
          builder: (context) => Home(),
        );
        Navigator.pushAndRemoveUntil(context, route, (route) => false);
      } else {
        normalDialog(context, 'มีความผิดปกติ', 'กรุณาลองใหม่');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: successJob(),
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          MyStyle().showTitle(nameShop == null ? '' : nameShop),
          // Text('${orderUserModel.idShop}'),
          showListOrder(),
          Expanded(
            child: Container(
              child: lat == null || shopLatLng == null || userLatLng == null
                  ? MyStyle().showProgress()
                  : showMap(),
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Marker shopMarker() {
    return Marker(
      markerId: MarkerId('shopID'),
      icon: BitmapDescriptor.defaultMarkerWithHue(100.0),
      position: shopLatLng,
      infoWindow: InfoWindow(
        title: 'ร้านที่ต้องไปรับอาหาร',
        snippet: nameShop,
      ),
    );
  }

  Marker userMarker() {
    return Marker(
      markerId: MarkerId('userID'),
      icon: BitmapDescriptor.defaultMarkerWithHue(310.0),
      position: userLatLng,
      infoWindow: InfoWindow(
        title: 'สถานที่ส่งอาหาร',
        snippet: nameUser,
      ),
    );
  }

  Set<Marker> myMarker() {
    return <Marker>[shopMarker(), userMarker()].toSet();
  }

  GoogleMap showMap() {
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 16.0,
    );
    return GoogleMap(
      myLocationEnabled: true,
      initialCameraPosition: cameraPosition,
      mapType: MapType.normal,
      onMapCreated: (controller) {},
      markers: myMarker(),
    );
  }

  Widget showListOrder() => ListView.builder(
        shrinkWrap: true,
        physics: ScrollPhysics(),
        itemCount: nameFoods.length,
        itemBuilder: (value, index) => Container(
          padding: EdgeInsets.only(left: 16.0),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(
                  nameFoods[index],
                  style: MyStyle().h3StylePrimary,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  amounts[index].toString(),
                  style: MyStyle().h3StyleDark,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  prices[index].toString(),
                  style: MyStyle().h3StyleDark,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${amounts[index] * prices[index]}',
                  style: MyStyle().h3StyleDark,
                ),
              ),
            ],
          ),
        ),
      );
}
