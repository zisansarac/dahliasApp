import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/api_service.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  _AddOrderPageState createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _customerPhone = TextEditingController();
  final TextEditingController _totalAmount = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String _selectedStatus = 'pending';
  DateTime? _scheduledDate;

  // Backend'e gönderilecek durumlar (API'nizdeki varsayılan 'pending' dahil)
  final List<String> _statusOptions = [
    'pending', // Hazırlanıyor / Beklemede
    'shipped', // Kargoya Verildi
    'delivered', // Teslim Edildi
    'cancelled', // İptal Edildi (Bu da bir durum olabilir)
  ];

  // Kullanıcının göreceği Türkçe karşılıkları
  String _getTurkishStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Hazırlanıyor';
      case 'shipped':
        return 'Kargoya Verildi';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Seçilmedi';
    }
  }

  Future<void> submitOrder() async {
    if (!_formKey.currentState!.validate()) return; // Form doğrulaması eklendi
    try {
      final response = await ApiService().post(ApiConstants.orders, {
        "customer_name": _customerName.text,
        "customer_phone": _customerPhone.text,
        // Backend'de `total_amount` null ise 0 olarak ayarlanıyor, bu iyi.
        "total_amount": double.tryParse(_totalAmount.text) ?? 0,
        "description": _description.text,
        // Backend'de `status` null ise 'pending' olarak ayarlanıyor, bu iyi.
        "status": _selectedStatus,
        // Backend'in beklediği yeni alan: scheduled_at
        // Eğer kullanıcıdan bir tarih alınıyorsa bu kullanılmalı.
        // Tarih yoksa `null` göndermek için `toISOString()` kullanıyoruz.
        "scheduled_at": _scheduledDate?.toIso8601String(),
        // ⚠️ 'date' ve 'time' **KALDIRILDI** });,
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sipariş eklendi')));
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Hata oluştu')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  InputDecoration buildInputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          'Yeni Sipariş',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _customerName,
                decoration: buildInputDecoration(context, 'Müşteri Adı'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Müşteri adı zorunludur'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerPhone,
                decoration: buildInputDecoration(context, 'Müşteri Telefonu'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalAmount,
                decoration: buildInputDecoration(context, 'Toplam Tutar'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                decoration: buildInputDecoration(context, 'Ürün Açıklaması'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Açıklama zorunludur'
                    : null,
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: buildInputDecoration(context, 'Kargo Durumu'),
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(_getTurkishStatus(status)), // Türkçe gösterim
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue ?? 'pending';
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Durum seçimi zorunludur'
                    : null,
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitOrder,
                  child: Text(
                    'Siparişi Ekle',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
