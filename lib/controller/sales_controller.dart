import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/sales_model.dart';

class VentasController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<VentaModel>> getVentas({DateTime? desde, DateTime? hasta}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    var query = _firestore
        .collection('ventas')
        .where('uid', isEqualTo: uid)
        .orderBy('fecha', descending: true);

    if (desde != null && hasta != null) {
      query = query
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(desde.year, desde.month, desde.day)))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59)));
    } else {
      query = query.limit(50);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => VentaModel.fromMap(doc.data())).toList());
  }

  Future<String?> registrarVenta(VentaModel venta) async {
    final user = _auth.currentUser;
    if (user == null) return 'Debe iniciar sesión para registrar ventas';
    if (venta.uid != user.uid) return 'Usuario no autorizado';

    // Verificar si IMEI ya existe
    final imeiQuery = await _firestore
        .collection('ventas')
        .where('imei', isEqualTo: venta.imei)
        .limit(1)
        .get();

    if (imeiQuery.docs.isNotEmpty) {
      return 'Este IMEI ya está registrado.';
    }

    // Verificar si factura existe (si no está vacía)
    if (venta.factura.isNotEmpty) {
      final facturaQuery = await _firestore
          .collection('ventas')
          .where('factura', isEqualTo: venta.factura)
          .limit(1)
          .get();

      if (facturaQuery.docs.isNotEmpty) {
        return 'Esta factura ya fue registrada.';
      }
    }

    try {
      await _firestore.collection('ventas').add(venta.toMap());
      return null;
    } catch (e) {
      return 'Error al guardar la venta: $e';
    }
  }
}
