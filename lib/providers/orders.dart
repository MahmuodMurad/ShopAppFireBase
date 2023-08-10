import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cart.dart';

class OrderItem {
  final String id;
  final double amuont;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amuont,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  String authToken='';
  String userId='';

  getData(String aToken, String uId, List<OrderItem> order) {
    authToken = aToken;
    userId = uId;
    _orders = order;
    notifyListeners();
  }

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final url =
        "https://shop-e63db-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken";
    try {
      final res = await http.get(Uri.parse(url));
      final extractedData = json.decode(res.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      final List<OrderItem> loadedOrders = [];
      extractedData.forEach((orderId, orderData) {
        loadedOrders.add(
          OrderItem(
            id: orderId,
            amuont: orderData['amount'],
            dateTime: DateTime.parse(orderData['dateTime']),
            products: (orderData['products'] as List<dynamic>)
                .map((item) => CartItem(
                      id: item['id'],
                      title: item['title'],
                      quantity: item['quantity'],
                      price: item['price'],
                    ))
                .toList(),
          ),
        );
      });
      _orders = loadedOrders.reversed.toList();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> addOrders(List<CartItem> cartProduct, double total) async {
    final url =
        "https://shop-e63db-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken";

    try {
      final timestamp = DateTime.now();
      final res = await http.post(Uri.parse(url),
          body: json.encode({
            'amount': total,
            'dateTime': timestamp.toIso8601String(),
            'products': cartProduct
                .map((cp) => {
                      'id': cp.id,
                      'price': cp.price,
                      'title': cp.title,
                      'quantity': cp.quantity,
                    })
                .toList(),
          }));
      _orders.insert(
          0,
          OrderItem(
            id: json.decode(res.body)['name'],
            amuont: total,
            products: cartProduct,
            dateTime: timestamp,
          ));
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}
