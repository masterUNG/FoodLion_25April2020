import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/banner_model.dart';
import 'package:foodlion/models/order_model.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/scaffold/show_cart.dart';
import 'package:foodlion/utility/find_token.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_constant.dart';
import 'package:foodlion/utility/my_search.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_dialog.dart';
import 'package:foodlion/utility/normal_toast.dart';
import 'package:foodlion/utility/sqlite_helper.dart';
import 'package:foodlion/widget/my_food.dart';
import 'package:foodlion/widget/show_order_user.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainHome extends StatefulWidget {
  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  // Field
  List<UserShopModel> userShopModels = List();
  List<Widget> showWidgets = List();
  List<BannerModel> bannerModels = List();
  List<Widget> showBanners = List();
  String idUser, nameLogin;
  int amount = 0;
  double lat, lng;
  bool statusShowCard = false;


  // Method
  @override
  void initState() {
    super.initState();

    aboutNotification();
    editToken();
    findLatLng();
  }

  Future<Null> findLatLng() async {
    LocationData locationData = await findLocationData();

    setState(() {

      lat = locationData.latitude;
      lng = locationData.longitude;

      readBanner();
      readShopThread();
      checkAmount();
      findUser();
    });
  }

  Future<LocationData> findLocationData() async {
    Location location = Location();
    try {
      return location.getLocation();
    } catch (e) {
      return null;
    }
  }

  Future<Null> aboutNotification() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();
    firebaseMessaging.configure(
      onLaunch: (message) {
        print('onLaunch ==> $message');
      },
      onMessage: (message) {
        // ขณะเปิดแอพอยู่
        print('onMessage ==> $message');
        normalToast('มี Notification คะ');
      },
      onResume: (message) {
        // ปิดเครื่อง หรือ หน้าจอ
        print('onResume ==> $message');
        routeToShowOrder();
      },
      onBackgroundMessage: (message) {
        print('onBackgroundMessage ==> $message');
      },
    );
  }

  Future<Null> findUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      nameLogin = preferences.getString('Name');
    });
  }

  Future<void> checkAmount() async {
    print('checkAmount Work');
    try {
      List<OrderModel> list = await SQLiteHelper().readDatabase();
      setState(() {
        amount = list.length;
      });
    } catch (e) {}
  }

  Future<Null> editToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    idUser = preferences.getString('id');

    if (idUser != null) {
      String token = await findToken();
      print('idUser = $idUser, token = $token');

      String url =
          'http://movehubs.com/app/editTokenUserWhereId.php?isAdd=true&id=$idUser&Token=$token';
      Response response = await Dio().get(url);
      if (response.toString() == 'true') {
        normalToast('อัพเดทตำแหน่งใหม่ สำเร็จ');
      }
    }
  }

  Future<void> readBanner() async {
    String url = MyConstant().urlGetAllBanner;
    try {
      Response response = await Dio().get(url);
      var result = json.decode(response.data);
      for (var map in result) {
        BannerModel model = BannerModel.fromJson(map);
        Widget bannerWieget = createBanner(model);
        setState(() {
          bannerModels.add(model);
          showBanners.add(bannerWieget);
        });
      }
    } catch (e) {}
  }

  Widget createBanner(BannerModel model) {
    return CachedNetworkImage(imageUrl: model.pathImage);
  }

  Future<void> readShopThread() async {
    String url = MyConstant().urlGetAllShop;

    try {
      Response response = await Dio().get(url);
      var result = json.decode(response.data);
      // print('result ===>>> $result');

      for (var map in result) {
        UserShopModel model = UserShopModel.fromJson(map);

 double distance = MyAPI().calculateDistance(
          lat,
          lng,
          double.parse(model.lat.trim()),
          double.parse(model.lng.trim()),
        );

        var myFormat = NumberFormat('##0.0#', 'en_US');

        setState(() {
          userShopModels.add(model);
          if (distance <= 30.0) {
            showWidgets.add(createCard(model, '${myFormat.format(distance)}'));
            statusShowCard = true;
          }
          
        });
      }
    } catch (e) {}
  }

  Widget showImageShop(UserShopModel model) {
    return Container(
      width: 80.0,
      height: 80.0,
      child: CircleAvatar(
        backgroundImage: NetworkImage(model.urlShop),
      ),
    );
  }

  Widget testListView() {
    return Expanded(
      child: ListView.builder(
        itemCount: showWidgets.length,
        itemBuilder: (BuildContext context, int index) {
          return Text('Test');
        },
      ),
    );
  }

  Widget createCard(UserShopModel model, String distance) {
    return GestureDetector(
      onTap: () {
       
        if (MyAPI().checkTimeShop()) {
          MaterialPageRoute route = MaterialPageRoute(
          builder: (value) => MyFood(idShop: model.id),
        );
        Navigator.of(context).push(route).then((value) => checkAmount());
        } else {
          normalDialog(context, 'ร้านปิดแล้ว', 'ต้องขอ อภัยมากๆ ครับ ร้านเปิดบริการ 8.00- 18.00');
        }

      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            showImageShop(model),
            showName(model),
            showDistance(distance),
          ],
        ),
      ),
    );
  }

   Widget showDistance(String distance) {
    return Text('$distance Km.');
  }

  Text showName(UserShopModel model) => Text(
        model.name,
        style: TextStyle(
          fontSize: 18.0,
        ),
      );

  Widget showShop() {
    return showWidgets.length == 0
        ? MyStyle().showProgress()
        : Expanded(
            child: GridView.extent(
              mainAxisSpacing: 3.0,
              crossAxisSpacing: 3.0,
              maxCrossAxisExtent: 260.0,
              children: showWidgets,
            ),
          );
  }

  Widget showBanner() {
    return showBanners.length == 0
        ? MyStyle().showProgress()
        : CarouselSlider(
            items: showBanners,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            pauseAutoPlayOnTouch: Duration(seconds: 3),
            autoPlay: true,
            autoPlayAnimationDuration: Duration(seconds: 3),
          );
  }

  Widget showCart() {
    return GestureDetector(
      onTap: () {
        if (lat == null) {
          findLatLng();
          normalToast('โปรดรอสักครู่ กำลังหาพิกัด');
        } else {
          routeToShowCart();
        }
      },
      child: MyStyle().showMyCart(amount),
    );
  }

  void routeToShowCart() {
    if (lat == null) {
      normalToast('กรุณาลองใหม่ กำลังหาพิกัดคะ');
    } else {
      MaterialPageRoute materialPageRoute =
        MaterialPageRoute(builder: (value) => ShowCart(lat: lat,lng: lng,));
    Navigator.of(context)
        .push(materialPageRoute)
        .then((value) => checkAmount());
    }
  }

  ListView userList() {
    return ListView(
      children: <Widget>[
        showHeadUser(),
        menuHome(),
        menuShowCart(),
        menuUserOrder(),
        menuSignOut(),
      ],
    );
  }

  Future<void> signOutProcess() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.clear();

      // exit(0);

      MaterialPageRoute route = MaterialPageRoute(builder: (value) => Home());
      Navigator.of(context).pushAndRemoveUntil(route, (value) => false);
    } catch (e) {}
  }

  Widget menuSignOut() {
    return ListTile(
      leading: Icon(
        Icons.exit_to_app,
        color: MyStyle().dartColor,
        size: 36.0,
      ),
      title: Text(
        'ออกจากระบบ',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'กดที่นี่ เพื่อออกจากระบบ',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        Navigator.of(context).pop();
        signOutProcess();
      },
    );
  }

  Widget menuUserOrder() {
    return ListTile(
      leading: Icon(
        Icons.directions_bike,
        size: 36.0,
        color: MyStyle().dartColor,
      ),
      title: Text(
        'รายการสั่งอาหาร',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'รายการสั่งอาหาร ที่รอส่ง',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        Navigator.of(context).pop();
        routeToShowOrder();
      },
    );
  }

  void routeToShowOrder() {
    MaterialPageRoute materialPageRoute = MaterialPageRoute(
      builder: (context) => ShowOrderUser(),
    );
    Navigator.push(context, materialPageRoute);
  }

  Widget menuShowCart() {
    return ListTile(
      leading: Icon(
        Icons.shopping_cart,
        size: 36.0,
        color: MyStyle().dartColor,
      ),
      title: Text(
        'ตะกร้า',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'แสดงรายการสินค้า ที่มีใน ตะกร้า',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        Navigator.of(context).pop();
        routeToShowCart();
      },
    );
  }

  Widget menuHome() {
    return ListTile(
      leading: Icon(
        Icons.fastfood,
        size: 36.0,
        color: MyStyle().dartColor,
      ),
      title: Text(
        'หน้าแรก',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'วันนี้กินอะไรดี',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        setState(() {
          Navigator.of(context).pop();
          // cuttentWidget = MainHome();
        });
      },
    );
  }

  Widget showHeadUser() {
    // print('nameLogin ==>>> $nameLogin');
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage('images/bic3.png'), fit: BoxFit.cover),
      ),
      currentAccountPicture: showLogo(),
      accountName: Text(
        nameLogin,
        style: MyStyle().h2StyleWhite,
      ),
      accountEmail: Text('Login'),
    );
  }

  void routeToShowSearch() {
    MaterialPageRoute materialPageRoute =
        MaterialPageRoute(builder: (value) => MySearch());
    Navigator.of(context)
        .push(materialPageRoute);
  }

  @override
  Widget build(BuildContext context) {
    // return showShop();

    return Scaffold(
      drawer: Drawer(
        child: userList(),
      ),
      appBar: AppBar(
        title: Text('เลือกร้านค้าจ๊า'),
        actions: <Widget>[IconButton(icon: Icon(Icons.search), onPressed: (){
          routeToShowSearch();
        }), showCart()],
      ),
      body: Column(
        children: <Widget>[
          showBanner(),
          MyStyle().showTitle('ร้านอาหารใกล้คุณ'),
          statusShowCard ? showShop() : Center(child: MyStyle().showTitleH2Dark('ขออภัยคะ ไม่มี ร้านอาหารใกล้คุณเลย คะ'),),
        ],
      ),
    );
  }

  showLogo() {}
}
