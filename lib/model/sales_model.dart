import 'package:cloud_firestore/cloud_firestore.dart';

class VentaModel {
  final String imei;
  final String factura;
  final String tienda;
  final double precio;
  final String moneda;
  final DateTime fecha;
  final String uid;

  VentaModel({
    required this.imei,
    required this.factura,
    required this.tienda,
    required this.precio,
    required this.moneda,
    required this.fecha,
    required this.uid,
  });

  factory VentaModel.fromMap(Map<String, dynamic> data) {
    return VentaModel(
      imei: data['imei'] ?? '',
      factura: data['factura'] ?? '',
      tienda: data['tienda'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      moneda: data['moneda'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      uid: data['uid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imei': imei,
      'factura': factura,
      'tienda': tienda,
      'precio': precio,
      'moneda': moneda,
      'fecha': fecha,
      'uid': uid,
      'creadoEn': FieldValue.serverTimestamp(),
    };
  }
}
