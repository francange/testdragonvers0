import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'sales_dashboard_view.dart';

class SalesRegistrationView extends StatefulWidget {
  const SalesRegistrationView({super.key});

  @override
  State<SalesRegistrationView> createState() => _SalesRegistrationViewState();
}

class _SalesRegistrationViewState extends State<SalesRegistrationView> {
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color borderColor = Colors.black26;
  static const Color iconColor = primaryColor;
  static const Color errorColor = Colors.red;
  static const Color hintTextColor = Colors.black45;

  final _imeiController = TextEditingController();
  final _facturaController = TextEditingController();
  final _storeController = TextEditingController();
  final _precioController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'LOC';
  final List<String> _monedas = ['LOC', 'DOLLAR'];

  String? _imeiError;
  bool _isCheckingImei = false;
  Timer? _debounceImeiTimer;

  String? _facturaError;
  bool _isCheckingFactura = false;
  Timer? _debounceFacturaTimer;

  String? _storeError;
  String? _precioError;

  @override
  void initState() {
    super.initState();
    _imeiController.addListener(_validarImeiEnVivo);
    _facturaController.addListener(_validarFacturaEnVivo);
    _storeController.addListener(_validarTiendaEnVivo);
    _precioController.addListener(_validarPrecioEnVivo);
  }

  @override
  void dispose() {
    _debounceImeiTimer?.cancel();
    _debounceFacturaTimer?.cancel();
    _imeiController.removeListener(_validarImeiEnVivo);
    _facturaController.removeListener(_validarFacturaEnVivo);
    _storeController.removeListener(_validarTiendaEnVivo);
    _precioController.removeListener(_validarPrecioEnVivo);
    _imeiController.dispose();
    _facturaController.dispose();
    _storeController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  bool _esImeiValido(String imei) {
    final regex = RegExp(r'^\d{15}$');
    return regex.hasMatch(imei.trim());
  }

  void _validarImeiEnVivo() {
    final imei = _imeiController.text.trim();
    _debounceImeiTimer?.cancel();

    if (imei.length < 15) {
      setState(() {
        _imeiError = 'El IMEI debe tener exactamente 15 dígitos';
        _isCheckingImei = false;
      });
      return;
    } else if (imei.length == 15) {
      setState(() {
        _imeiError = null;
        _isCheckingImei = true;
      });

      _debounceImeiTimer = Timer(const Duration(milliseconds: 500), () async {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('ventas')
            .where('imei', isEqualTo: imei)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _imeiError = 'Este IMEI ya está registrado';
            _isCheckingImei = false;
          });
        } else {
          setState(() {
            _imeiError = null;
            _isCheckingImei = false;
          });
        }
      });
    } else {
      setState(() {
        _imeiError = 'El IMEI debe tener exactamente 15 dígitos';
        _isCheckingImei = false;
      });
    }
  }

  void _validarFacturaEnVivo() {
    final factura = _facturaController.text.trim();
    _debounceFacturaTimer?.cancel();

    if (factura.isEmpty) {
      setState(() {
        _facturaError = null;
        _isCheckingFactura = false;
      });
      return;
    }

    if (factura.length != 5) {
      setState(() {
        _facturaError = 'La Factura debe tener exactamente 5 caracteres';
        _isCheckingFactura = false;
      });
      return;
    }

    setState(() {
      _facturaError = null;
      _isCheckingFactura = true;
    });

    _debounceFacturaTimer = Timer(const Duration(milliseconds: 500), () async {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ventas')
          .where('factura', isEqualTo: factura)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _facturaError = 'Esta factura ya fue registrada';
          _isCheckingFactura = false;
        });
      } else {
        setState(() {
          _facturaError = null;
          _isCheckingFactura = false;
        });
      }
    });
  }

  void _validarTiendaEnVivo() {
    final tienda = _storeController.text.trim();
    setState(() {
      _storeError = tienda.isEmpty ? 'La tienda no puede estar vacía' : null;
    });
  }

  void _validarPrecioEnVivo() {
    final precioTexto = _precioController.text.trim();
    final precio = double.tryParse(precioTexto) ?? 0.0;
    setState(() {
      _precioError = (precio <= 0) ? 'El precio debe ser mayor que cero' : null;
    });
  }

  Future<void> _guardarVenta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión para guardar ventas')),
      );
      return;
    }

    final imei = _imeiController.text.trim();
    final factura = _facturaController.text.trim();
    final tienda = _storeController.text.trim();
    final precioTexto = _precioController.text.trim();
    final precio = double.tryParse(precioTexto) ?? 0.0;

    setState(() {
      _storeError = tienda.isEmpty ? 'La tienda no puede estar vacía' : null;
      _precioError = (precio <= 0) ? 'El precio debe ser mayor que cero' : null;
    });

    if (!_esImeiValido(imei)) {
      setState(() {
        _imeiError = 'El IMEI debe ser numérico y tener exactamente 15 dígitos.';
      });
      return;
    }

    if (factura.isNotEmpty && factura.length != 5) {
      setState(() {
        _facturaError = 'La Factura debe tener exactamente 5 caracteres';
      });
      return;
    }

    // Si hay errores en campos no permitir guardar
    if (_imeiError != null ||
        _facturaError != null ||
        _storeError != null ||
        _precioError != null) return;

    if (factura.isNotEmpty) {
      final existingFacturaQuery = await FirebaseFirestore.instance
          .collection('ventas')
          .where('factura', isEqualTo: factura)
          .limit(1)
          .get();

      if (existingFacturaQuery.docs.isNotEmpty) {
        setState(() {
          _facturaError = 'Esta factura ya fue registrada.';
        });
        return;
      }
    }

    final venta = {
      'imei': imei,
      'factura': factura,
      'tienda': tienda,
      'fecha': _selectedDate,
      'precio': precio,
      'moneda': _selectedCurrency,
      'creadoEn': FieldValue.serverTimestamp(),
      'uid': user.uid,
    };

    try {
      await FirebaseFirestore.instance.collection('ventas').add(venta);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta guardada exitosamente')),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SalesDashboardView()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: backgroundColor,
              onSurface: textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildInputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    bool showLoading = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: errorText != null ? errorColor : borderColor,
          width: errorText != null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: errorText != null ? errorColor : iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: hintTextColor),
                border: InputBorder.none,
                errorText: errorText,
              ),
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(color: textColor),
              cursorColor: primaryColor,
            ),
          ),
          if (showLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: iconColor),
            const SizedBox(width: 12),
            Text(
              DateFormat('yyyy-MM-dd').format(_selectedDate),
              style: const TextStyle(fontSize: 16, color: textColor),
            ),
            const Spacer(),
            const Icon(Icons.edit, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
          title: const Text('Información de Venta'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          elevation: 1,
          centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para validación y asignación de puntos ingrese el Código IMEI. '
                  'Puede usar el escáner automático asegurándose que sea el único capturado.',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            _buildInputField(
              icon: Icons.qr_code_scanner,
              hint: 'IMEI',
              controller: _imeiController,
              keyboardType: TextInputType.number,
              errorText: _imeiError,
              showLoading: _isCheckingImei,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            const Text(
              'Para efectos de alguna validación necesaria, favor ingrese imagen y número de Factura.',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            _buildInputField(
              icon: Icons.camera_alt_outlined,
              hint: 'Factura',
              controller: _facturaController,
              errorText: _facturaError,
              showLoading: _isCheckingFactura,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            const Text(
              'Favor indique el nombre de la Tienda o Puesto de Venta.',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            _buildInputField(
              icon: Icons.store,
              hint: 'Tienda/Puesto de Venta',
              controller: _storeController,
              errorText: _storeError,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seleccione la fecha de la venta:',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            _buildDateField(),
            const SizedBox(height: 8),
            const Text(
              'Favor indique el precio de venta y moneda Local/Dólar',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInputField(
                    icon: Icons.attach_money,
                    hint: 'Precio',
                    controller: _precioController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    errorText: _precioError,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        icon: Icon(Icons.arrow_drop_down, color: iconColor),
                        items: _monedas
                            .map(
                              (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCurrency = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarVenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: backgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.4),
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Salir',
                  style: TextStyle(fontSize: 18, color: errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
