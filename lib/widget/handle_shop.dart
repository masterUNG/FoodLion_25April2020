import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HandleShop extends StatefulWidget {
  @override
  _HandleShopState createState() => _HandleShopState();
}

class _HandleShopState extends State<HandleShop> {

  

  @override
  void initState() { 
    super.initState();
    readOrder();
  }

  Future<Null> readOrder()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String idShop = preferences.getString('id');
    
    String url = 'http://movehubs.com/app/getOrderWhereIdShop.php?isAdd=true&idShop=$idShop';
    await Dio().get(url).then((value) {
      var result = value.data;
      for (var map in result) {
        
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Handle Shop'
    );
  }
}