// lib/views/sales_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/sales_controller.dart';
import '../model/sales_model.dart';
import 'sales_registration_view.dart';

class SalesDashboardView extends StatefulWidget {
  const SalesDashboardView({super.key});

  @override
  State<SalesDashboardView> createState() => _SalesDashboardViewState();
}

class _SalesDashboardViewState extends State<SalesDashboardView> {
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color cardBackgroundColor = Colors.white;
  static const Color iconColor = primaryColor;
  static const Color fabTextColor = Colors.white;

  final VentasController _ventasController = VentasController();

  DateTime? _fromDate;
  DateTime? _toDate;
  int _currentPage = 0;
  static const int _pageSize = 5;

  Future<void> _pickRange() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
            onPrimary: backgroundColor,
            onSurface: textColor,
          ),
        ),
        child: child!,
      ),
    );
    if (rango != null) {
      setState(() {
        _fromDate = rango.start;
        _toDate = rango.end;
        _currentPage = 0;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  String _formatFecha(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard de Ventas'),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirmar cierre de sesión'),
                  content: const Text('¿Seguro que quieres cerrar sesión?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión')),
                  ],
                ),
              );
              if (ok == true) _signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: fabTextColor,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesRegistrationView()));
          setState(() {});
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  label: Text(
                    _fromDate != null && _toDate != null
                        ? 'Filtrar: ${_formatFecha(_fromDate!)} - ${_formatFecha(_toDate!)}'
                        : 'Filtrar por fecha',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_fromDate != null && _toDate != null)
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _fromDate = null;
                    _toDate = null;
                    _currentPage = 0;
                  }),
                  icon: const Icon(Icons.clear, color: Colors.white),
                  label: const Text('Quitar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<VentaModel>>(
                stream: _ventasController.getVentas(desde: _fromDate, hasta: _toDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryColor));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  final ventas = snapshot.data ?? [];
                  if (ventas.isEmpty) {
                    return const Center(child: Text('No hay ventas.', style: TextStyle(fontSize: 18, color: Colors.black54)));
                  }

                  final totalPages = (ventas.length / _pageSize).ceil();
                  if (_currentPage >= totalPages) _currentPage = 0;

                  final start = _currentPage * _pageSize;
                  final end = (start + _pageSize) > ventas.length ? ventas.length : (start + _pageSize);
                  final currentVentas = ventas.sublist(start, end);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentVentas.length,
                          itemBuilder: (context, index) {
                            final venta = currentVentas[index];
                            return Card(
                              color: cardBackgroundColor,
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.receipt_long, color: iconColor, size: 32),
                                title: Text('IMEI: ${venta.imei}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                subtitle: Text(
                                  'Fecha: ${_formatFecha(venta.fecha)}\n'
                                      'Tienda: ${venta.tienda}\n'
                                      'Precio: ${venta.precio} ${venta.moneda}',
                                  style: const TextStyle(height: 1.4, color: textColor),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: _currentPage == 0 ? Colors.grey : primaryColor,
                            onPressed: _currentPage == 0
                                ? null
                                : () => setState(() => _currentPage--),
                          ),
                          Text('Página ${_currentPage + 1} de $totalPages'),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            color: _currentPage + 1 == totalPages ? Colors.grey : primaryColor,
                            onPressed: _currentPage + 1 == totalPages
                                ? null
                                : () => setState(() => _currentPage++),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
