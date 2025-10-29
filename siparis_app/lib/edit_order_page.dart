import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:siparis_app/theme.dart';
import 'package:siparis_app/services/api_service.dart';

class EditOrderPage extends StatefulWidget {
  final dynamic order;

  const EditOrderPage({super.key, required this.order});

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final _formKey = GlobalKey<FormState>();

  // Sadece backend'in istediği controller'ları tutuyoruz
  late TextEditingController _customerNameController;
  late TextEditingController
  _descriptionController; // Yeni: Ürün Adı yerine Açıklama
  late TextEditingController
  _totalAmountController; // Yeni: Fiyat yerine Toplam Tutar

  // Dropdown için status değişkeni
  late String _status;

  // Yeni backend durumları ve Türkçe karşılıkları
  final List<String> _statusOptions = [
    'pending',
    'shipped',
    'delivered',
    'cancelled',
  ];

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
        return 'Seçilmedi'; // Varsayılan
    }
  }

  // initState'de backend'den gelen değerlere göre controller'ları başlatma
  @override
  void initState() {
    super.initState();

    _customerNameController = TextEditingController(
      text: widget.order['customer_name']?.toString() ?? '',
    );
    // ⚠️ Değişiklik: Ürün Adı yerine Description (Ürün Açıklaması)
    _descriptionController = TextEditingController(
      text: widget.order['description']?.toString() ?? '',
    );
    // ⚠️ Değişiklik: Price yerine Total Amount (Toplam Tutar)
    _totalAmountController = TextEditingController(
      text: widget.order['total_amount']?.toString() ?? '',
    );

    // Kargo Durumunu doğru şekilde başlatma
    final gelenDurum =
        widget.order['status']?.toString().toLowerCase() ?? 'pending';

    // Dropdown için İngilizce değeri sakla, böylece backend'e uygun gönderilir
    _status = _statusOptions.contains(gelenDurum) ? gelenDurum : 'pending';
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  // API Service'ı kullandığımız için token yenileme mantığını ApiService yönetecek.
  // Bu sayfadan token kontrolü kaldırıldı ve basitleştirildi.
  Future<void> updateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final orderId = widget.order['id'];
    final body = {
      'customer_name': _customerNameController.text.trim(),
      'customer_phone': widget.order['customer_phone']?.toString() ?? '',
      'description': _descriptionController.text.trim(),
      'total_amount': double.tryParse(_totalAmountController.text.trim()) ?? 0,
      'status': _status,
      'scheduled_at': widget.order['scheduled_at']?.toString() ?? null,
    };

    try {
      // ApiService, token yönetimi ve URL birleştirmesini hallediyor
      final response = await ApiService().put('api/orders/$orderId', body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sipariş başarıyla güncellendi 🚀')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // ⚠️ Hata yanıtını işleme (JSON Decode Hata Yönetimi Güçlendirildi)
        String errorMessage =
            'Güncelleme başarısız (Durum: ${response.statusCode}).';

        // Yanıtı JSON olarak çözmeyi dene
        try {
          final data = jsonDecode(response.body);
          // Backend'den gelen spesifik hata mesajını kullan
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
        } catch (e) {
          // Yanıt JSON formatında değilse (unexpected character/token hatasının sebebi)
          // Kullanıcıya daha bilgilendirici bir mesaj göster.
          if (response.body.toLowerCase().contains('html') ||
              response.body.length > 50) {
            errorMessage =
                'Sunucuya ulaşıldı ancak bir sorun oluştu (Genellikle API Route veya Sunucu Hatası).';
          } else {
            // Çok kısa bir yanıt geldiyse (bazen tek bir karakter)
            errorMessage =
                'Beklenmedik Sunucu Yanıtı. Lütfen API endpointlerini kontrol edin.';
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ağ bağlantı hatası: Sunucuya ulaşılamıyor. $e'),
          ),
        );
      }
    }
  }

  // Tekrar kullanılabilir, küçük bir yardımcı fonksiyon
  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool requiredField = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      // ... (Stil ayarları aynı kalacak)
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white70 : theme.hintColor,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(
            color: theme.inputDecorationTheme.enabledBorder!.borderSide.color,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (requiredField && (value == null || value.trim().isEmpty)) {
          return 'Bu alan zorunlu';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundColor
          : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Siparişi Düzenle",
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ⚠️ Ürün Adı yerine Ürün Açıklaması kullanıldı
                  buildTextField(
                    controller: _descriptionController,
                    label: 'Ürün Açıklaması',
                    requiredField: true,
                  ),
                  const SizedBox(height: 16),

                  // Müşteri Adı
                  buildTextField(
                    controller: _customerNameController,
                    label: 'Müşteri Adı',
                    requiredField: true,
                  ),
                  const SizedBox(height: 16),

                  // ⚠️ Fiyat yerine Toplam Tutar kullanıldı
                  buildTextField(
                    controller: _totalAmountController,
                    label: 'Toplam Tutar',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // ❌ KALDIRILDI: Adres, Kargo Firması, Takip Numarası
                  // (Backend'inizde bu alanlar yok)

                  // Dropdown (Durum)
                  DropdownButtonFormField2<String>(
                    value: _status,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Durum',
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                      // ... (Diğer dekorasyon stilleri aynı kalacak)
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        borderSide: BorderSide(
                          color: theme
                              .inputDecorationTheme
                              .enabledBorder!
                              .borderSide
                              .color,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        color: isDark ? Colors.grey[850] : theme.cardColor,
                        // ... (Shadows aynı kalacak)
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      height: 50,
                    ),
                    iconStyleData: IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: theme.primaryColor,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: _statusOptions.map((durum) {
                      return DropdownMenuItem<String>(
                        value: durum,
                        child: Text(
                          _getTurkishStatus(durum), // Türkçe gösterim
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _status = newValue!;
                      });
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Durum seçmelisiniz'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Kaydet Butonu
                  ElevatedButton(
                    onPressed: () {
                      final isValid =
                          _formKey.currentState?.validate() ?? false;
                      if (isValid) {
                        updateOrder();
                      }
                    },
                    child: const Text('Kaydet'),
                    // ... (Stil ayarları aynı kalacak)
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          return AppTheme.primaryColor.withOpacity(0.8);
                        }
                        return AppTheme.primaryColor;
                      }),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                      textStyle: WidgetStateProperty.all(
                        theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      elevation: WidgetStateProperty.resolveWith<double>(
                        (states) =>
                            states.contains(WidgetState.hovered) ? 6 : 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
