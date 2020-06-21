import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/order_user_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HandleShop extends StatefulWidget {
  @override
  _HandleShopState createState() => _HandleShopState();
}

class _HandleShopState extends State<HandleShop> {
  List<OrderUserModel> orderUserModels = List();
  List<UserModel> userModels = List();
  List<List<FoodModel>> listFoodModels = List();
  List<List<String>> listAmounts = List();
  List<List<String>> listSums = List();
  List<List<String>> listStatuss = List();

  @override
  void initState() {
    super.initState();
    readOrder();
  }

  Future<Null> readOrder() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String idShop = preferences.getString('id');

    String url =
        'http://movehubs.com/app/getOrderWhereIdShop.php?isAdd=true&idShop=$idShop';
    await Dio().get(url).then((value) async {
      var result = json.decode(value.data);
      for (var map in result) {
        // print('map ==>> ${map.toString()}');
        OrderUserModel orderUserModel = OrderUserModel.fromJson(map);

        String amount = orderUserModel.amountFoods;
        amount = amount.substring(1, amount.length - 1);
        List<String> amounts = amount.split(',');
        listAmounts.add(amounts);

        String foodId = orderUserModel.idFoods;
        foodId = foodId.substring(1, foodId.length - 1);
        List<String> foods = foodId.split(',');
        List<FoodModel> foodModels = List();
        for (var id in foods) {
          FoodModel foodModel = await MyAPI().findDetailFoodWhereId(id);
          foodModels.add(foodModel);
        }

        UserModel userModel =
            await MyAPI().findDetailUserWhereId(orderUserModel.idUser);
        if (orderUserModel.success != '0') {
          setState(() {
            orderUserModels.add(orderUserModel);
            userModels.add(userModel);
            listFoodModels.add(foodModels);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return orderUserModels.length == 0
        ? Center(
            child: Text('ยังไม่มีข้อมูล คะ'),
          )
        : ListView.builder(
            itemCount: orderUserModels.length,
            itemBuilder: (context, index) => Column(
              children: <Widget>[
                MyStyle().showTitleH2DartBold(
                    'เจ้าของ Order ==> ${userModels[index].name}'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(orderUserModels[index].dateTime),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: MyStyle().showTitleH2DartBold('รายการอาหาร'),
                    ),
                    Expanded(
                      flex: 1,
                      child: MyStyle().showTitleH2Dark('ราคา'),
                    ),
                    Expanded(
                      flex: 1,
                      child: MyStyle().showTitleH2Dark('จำนวน'),
                    ),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  itemCount: listFoodModels[index].length,
                  itemBuilder: (context, index2) => Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Text(listFoodModels[index][index2].nameFood),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(listFoodModels[index][index2].priceFood),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(listAmounts[index][index2].trim()),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    MyStyle().showTitleH2Primary(
                        'ราคารวม = ${orderUserModels[index].totalPrice} บาท'),
                    MyStyle().mySizeBox(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    MyStyle().showTitleH2DartBold(
                        'สถานะ => ${orderUserModels[index].success}'),
                    MyStyle().mySizeBox(),
                  ],
                )
              ],
            ),
          );
  }
}
