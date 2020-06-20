import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/order_user_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/utility/find_token.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderShop extends StatefulWidget {
  @override
  _OrderShopState createState() => _OrderShopState();
}

class _OrderShopState extends State<OrderShop> {
  // Field
  String idShop;
  List<OrderUserModel> orderUserModels = List();
  List<String> nameUsers = List();
  List<List<FoodModel>> listFoodModels = List();
  List<List<String>> listAmounts = List();
  List<int> totals = List();

  // Method
  @override
  void initState() {
    super.initState();

    aboutNotification();
    updateToken();
    readOrder();
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
        normalToast('มี รายการอาหารสั่งเข้ามา คะ');
        readOrder();
      },
      onResume: (message) {
        // ปิดเครื่อง หรือ หน้าจอ
        print('onResume ==> $message');
        readOrder();
      },
      // onBackgroundMessage: (message) {
      //   // print('onBackgroundMessage ==> $message');
      // },
    );
  }

  Future<Null> updateToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    idShop = preferences.getString('id');
    String token = await findToken();

    String url =
        'http://movehubs.com/app/editTokenShopWhereId.php?isAdd=true&id=$idShop&Token=$token';
    Response response = await Dio().get(url);
    if (response.toString() == 'true') {
      normalToast('อัพเดทตำแหน่งใหม่ สำเร็จ');
    }
  }

  Future<Null> readOrder() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    idShop = preferences.getString('id');

    if (orderUserModels.length != 0) {
      orderUserModels.clear();
      nameUsers.clear();
      listFoodModels.clear();
      listAmounts.clear();
      totals.clear();
    }

    String urlOrder =
        'http://movehubs.com/app/getOrderWhereIdShopSuccess0.php?isAdd=true&idShop=$idShop';
    try {
      Response response = await Dio().get(urlOrder);
      // print('res on readOrder ##########################==> $response');
      // print(
      //     'lenagth =================================>>>>>> ${orderUserModels.length}');
      var result = json.decode(response.data);

      for (var map in result) {
        OrderUserModel orderUserModel = OrderUserModel.fromJson(map);
        UserModel userModel =
            await MyAPI().findDetailUserWhereId(orderUserModel.idUser);

        String idFoodString = orderUserModel.idFoods;
        idFoodString = idFoodString.substring(1, idFoodString.length - 1);
        List<String> listFood = idFoodString.split(',');
        List<FoodModel> foodModels = List();
        List<int> priceInts = List();
        for (var idFood in listFood) {
          FoodModel foodModel =
              await MyAPI().findDetailFoodWhereId(idFood.trim());
          foodModels.add(foodModel);
          priceInts.add(int.parse(foodModel.priceFood));
        }

        String amountString = orderUserModel.amountFoods;
        amountString = amountString.substring(1, amountString.length - 1);
        List<String> amounts = amountString.split(',');
        int total = 0;
        int i = 0;
        for (var amount in amounts) {
          total = total + (priceInts[i] * int.parse(amount.trim()));
          i++;
        }
        totals.add(total);
        listAmounts.add(amounts);

        setState(() {
          orderUserModels.add(orderUserModel);
          nameUsers.add(userModel.name);
          listFoodModels.add(foodModels);
        });
      } // for 1

    } catch (e) {}
  }

  Widget waitOrder() {
    return Container(
      alignment: Alignment(0, -0.6),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        child: Card(
          color: MyStyle().primaryColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MyStyle().mySizeBox(),
              Container(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Image.asset('images/wait2.png'),
              ),
              MyStyle().mySizeBox(),
              Text(
                'โปรดรอ สักครู่คะ ยังไม่มี รายการสั่ง',
                style: MyStyle().h2StyleWhite,
              ),
              MyStyle().mySizeBox(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return orderUserModels.length == 0 ? waitOrder() : showListOrder();
  }

  String phone;

  Future<Null> phoneForm() async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('กรุณากรอบ เบอร์ติดต่อ เพื่อสะดวกต่อ คนส่งของ'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 150,
                child: TextField(onChanged: (value) => phone = value.trim(),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'เบอร์ติดต่อ :',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 200.0,
                child: RaisedButton.icon(
                  onPressed: () {
                    if (phone == null || phone.isEmpty) {
                      normalToast('เบอร์ติดต่อห้ามว่างเปล่า');
                    }else if (phone.length == 10) {
                     MyAPI().addPhoneThread(idShop, 'Shop', phone);
                     Navigator.pop(context);
                    } else {
                      normalToast('กรุณากรอกเบอร์ ให้ครบ ห้ามมีช่องว่าง ');
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text('บันทึก'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  ListView showListOrder() {
    return ListView.builder(
      padding: EdgeInsets.all(10.0),
      itemCount: orderUserModels.length,
      itemBuilder: (context, index1) => GestureDetector(
        onTap: () async{
          String phone = await MyAPI().findPhone(idShop, 'Shop');
          print('phone = $phone');
          if (phone == 'null') {
            phoneForm();
          } else {
            showConfirmFinish(index1);
          }
        },
        child: Column(
          children: <Widget>[
            MyStyle().showTitle('รายการอาหาร คุณ ${nameUsers[index1]}'),
            Row(
              children: <Widget>[
                Text(orderUserModels[index1].dateTime),
              ],
            ),
            Container(
              decoration: BoxDecoration(color: Colors.orange.shade100),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Text(
                      'รายการอาหาร',
                      style: MyStyle().h3StyleDark,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'ราคา',
                      style: MyStyle().h3StyleDark,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'จำนวน',
                      style: MyStyle().h3StyleDark,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'ผลรวม',
                      style: MyStyle().h3StyleDark,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: ScrollPhysics(),
              itemCount: listFoodModels[index1].length,
              itemBuilder: (context, index2) => Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Text(
                      listFoodModels[index1][index2].nameFood,
                      style: MyStyle().h2NormalStyle,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      listFoodModels[index1][index2].priceFood,
                      style: MyStyle().h2Style,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      listAmounts[index1][index2].trim(),
                      style: MyStyle().h2Style,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${int.parse(listFoodModels[index1][index2].priceFood) * int.parse(listAmounts[index1][index2].trim())}',
                      style: MyStyle().h2Style,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'Total :',
                        style: MyStyle().h2StylePrimary,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(color: MyStyle().primaryColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          totals[index1].toString(),
                          style: MyStyle().h2StyleWhite,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ), 
          ],
        ),
      ),
    );
  }

  Future<Null> showConfirmFinish(int index) async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('รับ Order ของคุณ ${nameUsers[index]} ใช่ไหม ?'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              confirmButton(index),
              MyStyle().mySizeBox(),
              cancelButton(index),
            ],
          ),
          waitButton(),
        ],
      ),
    );
  }

  OutlineButton confirmButton(int index) {
    return OutlineButton.icon(
      onPressed: () {
        editStatusByShop(index, 'ShopOrder');
        Navigator.pop(context);
      },
      icon: Icon(
        Icons.check,
        color: Colors.green,
      ),
      label: Text('รับทำ Order'),
    );
  }

  Future<Null> editStatusByShop(int index, String success) async {
    String idOrder = orderUserModels[index].id;
    print('idOrder = $idOrder, Success = $success');
    String url =
        'http://movehubs.com/app/editStatusShopOrderWhereId.php?isAdd=true&id=$idOrder&Success=$success';

    await Dio().get(url).then(
      (value) {
        print('value ##########>>> $value');

        if (value.statusCode == 200) {
          //Sent Notification All Rider
          MyAPI().notiToRider();

          //Sent Notification to User
          // sentNotiToUser(index);

          MaterialPageRoute route = MaterialPageRoute(
            builder: (context) => Home(),
          );
          Navigator.pushAndRemoveUntil(context, route, (route) => false);
          // readOrder();
        } else {
          normalToast('กรุณา ลองใหม่ ระบบขัดข้อง คะ');
        }
      },
    );
  }

  OutlineButton cancelButton(int index) {
    return OutlineButton.icon(
      onPressed: () {
        editStatusByShop(index, 'ShopCancel');
        Navigator.pop(context);
      },
      icon: Icon(
        Icons.clear,
        color: Colors.red,
      ),
      label: Text('ไม่สะดวกรับ order'),
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

  Future<Null> sentNotiToUser(int index) async {
    UserModel userModel =
        await MyAPI().findDetailUserWhereId(orderUserModels[index].idUser);
    MyAPI().notificationAPI(userModel.token, 'Rider กำลังไปรับอาหาร',
        'Rider กำลังไปรับ อาหารที่ร้านค้า คะ รอแป้ป');
  }
}
