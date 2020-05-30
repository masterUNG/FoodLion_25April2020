import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:foodlion/models/delivery_model.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/models/user_shop_model.dart';

import 'normal_toast.dart';

class MyAPI {


  

  Future<Null> notificationAPI(String token, String title, String body) async {
    String url =
        'http://movehubs.com/app/apiNotification.php?isAdd=true&token=$token&title=$title&body=$body';
    try {
      Response response = await Dio().get(url);
      print('resNoti ===>> $response');
    } catch (e) {}
  }

  Future<Null> notiToRider() async {
    String urlGetAllOrderStatus0 = 'http://movehubs.com/app/getAllRider.php';
    Response response = await Dio().get(urlGetAllOrderStatus0);

    var result = json.decode(response.data);
    for (var map in result) {
      DelivaryModel delivaryModel = DelivaryModel.fromJson(map);

      if (delivaryModel.token.isNotEmpty) {
        // print('Sent Token to in aaaaa ===>> ${delivaryModel.token}');
        MyAPI().notificationAPI(delivaryModel.token,
            'มีรายการสั่งอาหารจาก Send', 'ลูกค้า Send สั่งอาหารครับ พี่ Rider');
      }
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
      },
      onBackgroundMessage: (message) {
        print('onBackgroundMessage ==> $message');
      },
    );
  }

// นีคือ Function ในการคำนวนค่าส่งอาหาร
  int checkTransport(int distance) {
    int transport = 0;
    if (distance <= 5) {
      transport = 25;
      return transport;
    } else {
      transport = 25 + ((distance - 5) * 5);
      return transport;
    }
  }

  Future<String> findNameShopWhere(String idShop) async {
    String string = '';
    String url =
        'http://movehubs.com/app/getShopWhereId.php?isAdd=true&id=$idShop';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      string = map['Name'];
    }
    return string;
  }

  Future<FoodModel> findDetailFoodWhereId(String idFood) async {
    FoodModel foodModel;
    String url =
        'http://movehubs.com/app/getFoodWhereId.php?isAdd=true&id=$idFood';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      foodModel = FoodModel.fromJson(map);
    }
    return foodModel;
  }

  Future<Map<String, dynamic>> findLocationShopWhere(String idShop) async {
    Map<String, dynamic> myMap = Map();
    String url =
        'http://movehubs.com/app/getShopWhereId.php?isAdd=true&id=$idShop';
    Response response = await Dio().get(url);
    // print('res find ==> $response');
    var result = json.decode(response.data);
    for (var map in result) {
      myMap = map;
    }
    return myMap;
  }

  Future<UserModel> findDetailUserWhereId(String id) async {
    UserModel userModel;
    String url = 'http://movehubs.com/app/getUserWhereId.php?isAdd=true&id=$id';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      userModel = UserModel.fromJson(map);
    }
    return userModel;
  }

  Future<UserShopModel> findDetailShopWhereId(String idShop) async {
    UserShopModel userShopModel;
    String url =
        'http://movehubs.com/app/getUserShopWhereId.php?isAdd=true&id=$idShop';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      userShopModel = UserShopModel.fromJson(map);
    }
    return userShopModel;
  }

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    double distance = 0;

    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lng2 - lng1) * p)) / 2;
    distance = 12742 * asin(sqrt(a));

    return distance;
  }

  MyAPI();
}
