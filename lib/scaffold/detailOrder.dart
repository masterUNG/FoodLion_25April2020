import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/order_user_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/scaffold/rider_success.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailOrder extends StatefulWidget {
  final OrderUserModel orderUserModel;
  final String nameShop;
  final int distance;
  final int transport;
  DetailOrder(
      {Key key,
      this.orderUserModel,
      this.nameShop,
      this.distance,
      this.transport})
      : super(key: key);
  @override
  _DetailOrderState createState() => _DetailOrderState();
}

class _DetailOrderState extends State<DetailOrder> {
  // Field
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

  @override
  void initState() {
    super.initState();

    setState(() {
      orderUserModel = widget.orderUserModel;
      nameShop = widget.nameShop;
      distance = widget.distance;
      transport = widget.transport;

      findDetailShopAnUser();
      findOrder();
      findAmound();
      findSum();
    });
  }

  Future<Null> findSum() async {
    String idShop = orderUserModel.idShop;
    String idFoods = orderUserModel.idFoods;
    String amounes = orderUserModel.amountFoods;

    print('idShop ==> $idShop, idFoods ==> $idFoods, amounts ==> $amounes');

    List<int> amountIntFoods = changeToArray(amounes);
    List<int> idFoodInt = changeToArray(idFoods);
    // List<int> priceIntFoods = List();

    int i = 0;
    for (var idFood in idFoodInt) {
      FoodModel foodModel =
          await MyAPI().findDetailFoodWhereId(idFood.toString());

      setState(() {
        sumPrice =
            sumPrice + (int.parse(foodModel.priceFood)) * amountIntFoods[1];
        // print('sumPrice ==>> $sumPrice');
      });
      i++;
    }
  }

  List<int> changeToArray(String string) {
    List<int> list = List();
    string = string.substring(1, string.length - 1);
    List<String> listStrings = string.split(',');

    for (var string in listStrings) {
      list.add(int.parse(string.trim()));
    }
    return list;
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

  Future<void> findDetailShopAnUser() async {
    UserShopModel userShopModel =
        await MyAPI().findDetailShopWhereId(orderUserModel.idShop);

    UserModel userModel =
        await MyAPI().findDetailUserWhereId(orderUserModel.idUser);

    setState(() {
      shopLatLng = LatLng(double.parse(userShopModel.lat.trim()),
          double.parse(userShopModel.lng.trim()));

      nameUser = userModel.name;
      tokenUser = userModel.token;
      userLatLng = LatLng(double.parse(userModel.lat.trim()),
          double.parse(userModel.lng.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: stateStatus ? acceptJob() : successJob(),
      appBar: AppBar(
        title: Text('รายการอาหาร $nameShop'),
      ),
      body: ListView(
        children: <Widget>[
          showTitleNameShop(),
          showMap(shopLatLng, nameShop, 'ร้านค้าที่ไปรับอาหาร', 100.0),
          MyStyle().showTitle('รายการอาหารที่สั่ง'),
          showListOrder(),
          showSumFood(),
          showSumDistance(),
          showNameUser(),
          showMap(userLatLng, nameUser, 'สถานที่ส่งอาหาร', 310.0),
        ],
      ),
    );
  }

  Widget successJob() => FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: null,
        child: Icon(Icons.android),
      );

  FloatingActionButton acceptJob() => FloatingActionButton(
        child: Icon(Icons.directions_bike),
        backgroundColor: orderUserModel.idDelivery.isEmpty
            ? MyStyle().primaryColor
            : Colors.green,
        onPressed: () =>
            orderUserModel.idDelivery.isEmpty ? confirmAccepp() : nearSuccess(),
      );

  Future<Null> nearSuccess() async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: MyStyle().showTitle('ติดตามสินค้า'),
        children: <Widget>[
          MyStyle().showTitleH2Primary('ส่งของให้ลูกค้า สำเร็จแล้วใช่ไหม ?'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              successRider(),
              MyStyle().mySizeBox(),
              cancel('ยังไม่สำเร็จ'),
            ],
          ),
        ],
      ),
    );
  }

  OutlineButton successRider() {
    return OutlineButton.icon(
      onPressed: () {
        clearSuccess();
      },
      icon: Icon(
        Icons.check,
        color: Colors.green,
      ),
      label: Text('สำเร็จ'),
    );
  }

  Future<Null> clearSuccess() async {
    String idOrder = orderUserModel.id;
    String url =
        'http://movehubs.com/app/editOrderWhereIdRider.php?isAdd=true&id=$idOrder&Success=Success';
    Response response = await Dio().get(url);
    if (response.toString() == 'true') {
      MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => Home(),
      );
      Navigator.pushAndRemoveUntil(context, route, (route) => false);
    }
  }

  Future<Null> confirmAccepp() async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: MyStyle().showTitle('ยื่นยันการรับงาน'),
        children: <Widget>[
          MyStyle().showTitleH2Primary('Rider ยื่นยันการรับงาน คะ'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              confirm(),
              MyStyle().mySizeBox(),
              cancel('ไม่รับงานนี คะ'),
            ],
          ),
          // waitButton(),
        ],
      ),
    );
  }

  Widget waitButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 250.0,
          child: OutlineButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.question_answer,
              color: Colors.red,
            ),
            label: Text('ยังไม่ตััดสินใจ'),
          ),
        ),
      ],
    );
  }

  OutlineButton confirm() {
    return OutlineButton.icon(
      onPressed: () {
        acceptJobThread();
        Navigator.pop(context);
      },
      icon: Icon(
        Icons.check,
        color: Colors.green,
      ),
      label: Text('ยืนยันการรับงาน'),
    );
  }

  OutlineButton cancel(String string) {
    return OutlineButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: Icon(
        Icons.clear,
        color: Colors.red,
      ),
      label: Text(string),
    );
  }

  Future<Null> acceptJobThread() async {
    String idOrder = orderUserModel.id;

    SharedPreferences preferences = await SharedPreferences.getInstance();
    String idRider = preferences.getString('id');
    preferences.setInt('distance', distance);
    preferences.setInt('transport', transport);

    print('idOrder ==> $idOrder, idRider ==> $idRider');

    String url2 =
        'http://movehubs.com/app/editIdRiderWhereIdOrder.php?isAdd=true&id=$idOrder&idDelivery=$idRider';
    await Dio().get(url2);

    String url =
        'http://movehubs.com/app/editOrderWhereIdRider.php?isAdd=true&id=$idOrder&Success=RiderOrder';
    Response response = await Dio().get(url);
    print('resAcceptOrder ==>> $response');

    //Send Notification to User
    MyAPI().notificationAPI(
        tokenUser, 'Rider รับ Order', 'คนส่งอาหาร กำลังไปรับอาหาร คะ');

    //Send Notification to Shop
    UserShopModel userShopModel = await MyAPI().findDetailShopWhereId(orderUserModel.idShop);
    String tokenShop = userShopModel.token;
    MyAPI().notificationAPI(tokenShop, 'Rider กำลังไปรับอาหาร', 'Rider กำลังไปที่ ร้านเพื่อรับอาหาร');

    MaterialPageRoute route = MaterialPageRoute(
      builder: (context) => RiderSuccess(
        orderUserModel: orderUserModel,
      ),
    );
    Navigator.pushAndRemoveUntil(context, route, (route) => false);

    // setState(() {
    //   stateStatus = false;
    // });

    // if (response.toString() == 'true') {
    //   MaterialPageRoute route = MaterialPageRoute(
    //     builder: (context) => Home(
    //       orderUserModel: orderUserModel,
    //       nameShop: nameShop,
    //       distance: distance,
    //       transport: transport,
    //     ),
    //   );
    //   Navigator.pushAndRemoveUntil(context, route, (route) => false);
    // }
  }

  Widget showSumFood() => Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  'ผลรวมอาหาร   ',
                  style: MyStyle().h2StylePrimary,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.only(right: 5.0),
              decoration: BoxDecoration(color: MyStyle().primaryColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '${orderUserModel.totalPrice} บาท',
                    style: MyStyle().h2StyleWhite,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget showSumDistance() => Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  'ผลรวมระยะทาง และ ค่าขนส่ง   ',
                  style: MyStyle().h2StylePrimary,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.only(right: 5.0),
              decoration: BoxDecoration(color: MyStyle().dartColor),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    distance == 0 ? '1 กิโลเมตร' : '$distance กิโลเมตร',
                    style: MyStyle().h2StyleWhite,
                  ),
                  Text(
                    '$transport บาท',
                    style: MyStyle().h2StyleWhite,
                  )
                ],
              ),
            ),
          ),
        ],
      );

  Widget showNameUser() {
    return nameUser == null
        ? MyStyle().showTitle('ผู้สั่งอาหาร ')
        : MyStyle().showTitle('ผู้สั่งอาหาร $nameUser');
  }

  Set<Marker> createMarker(
      LatLng latLng, String title, String subTitle, double hue) {
    Random random = Random();
    int i = random.nextInt(100);
    return <Marker>[
      Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        markerId: MarkerId('id$i'),
        position: latLng,
        infoWindow: InfoWindow(
          title: title,
          snippet: subTitle,
        ),
      )
    ].toSet();
  }

  Widget showMap(LatLng latLng, String title, String subTitle, double hue) {
    CameraPosition cameraPosition;
    if (latLng != null) {
      cameraPosition = CameraPosition(
        target: latLng,
        zoom: 16,
      );
    }
    return Container(
      height: 200.0,
      child: latLng == null
          ? MyStyle().showProgress()
          : GoogleMap(
              initialCameraPosition: cameraPosition,
              onMapCreated: (controller) {},
              markers: createMarker(latLng, title, subTitle, hue),
            ),
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

  String showSumPrice(int amount, int price) {
    int sumPrice = amount * price;
    setState(() {
      sumFood = sumFood + sumPrice;
      print('sumFood = $sumFood');
    });
    return sumPrice.toString();
  }

  Widget showTitleNameShop() => MyStyle().showTitle('ร้าน $nameShop');
}
