import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siparis_app/constants.dart';
import 'package:siparis_app/edit_order_page.dart';
import 'package:siparis_app/theme.dart';
import 'add_order.dart';
import 'package:provider/provider.dart';
import 'package:siparis_app/theme_provider.dart';
import 'package:siparis_app/services/api_service.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController? _pageController;
  bool isFemaleEntrepreneur = false;
  List<dynamic> orders = [];
  String username = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);

    checkLoginStatus();
    loadUserInfo();
    fetchOrders();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController?.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
      isFemaleEntrepreneur = prefs.getBool('is_woman_entrepreneur') ?? false;
    });
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _refreshProfileInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null) {
        final response = await ApiService().get(
          '${ApiConstants.baseUrl}/api/user/profile',
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'profile_image_url',
            data['profile_image_url'] ?? '',
          );
        }
      }
    } catch (e) {
      print('Profil bilgisi yüklenirken hata: $e');
    } finally {
      await loadUserInfo();
    }
  }

  Future<void> fetchOrders() async {
    // API service, siparişleri fetchOrders rotasından çekiyor
    final response = await ApiService().get(ApiConstants.orders);

    if (response.statusCode == 200) {
      setState(() {
        // Backend'den gelen yanıt, doğrudan listeye dönüştürülür
        orders = json.decode(response.body);
      });
    } else {
      print('Siparişleri alma başarısız: ${response.body}');
      // Hata durumunda boş liste gösterilir
      setState(() {
        orders = [];
      });
    }
  }

  Future<void> confirmDeleteOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi Sil'),
        content: const Text('Bu siparişi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteOrder(orderId);
    }
  }

  // OrderListPage.dart içinde _OrderListPageState sınıfı

  Future<void> deleteOrder(int orderId) async {
    // ⚠️ DÜZELTME: Artık ApiService'ın delete metodunu kullanıyoruz.
    // Bu metot, token'ı otomatik ekler ve yenileme dener.

    try {
      // Backend endpoint'i: orders/:id (örneğin orders/123)
      final response = await ApiService().delete('api/orders/$orderId');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sipariş başarıyla silindi')),
          );
          fetchOrders(); // Listeyi yenile
        }
      } else if (response.statusCode == 401) {
        // Token yenileme başarısız olduysa, ApiService zaten logout yapmıştır.
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // Backend'den gelen 403 (Yetki) veya 500 (Sunucu) hatalarını yakala
        String errorMessage = 'Silme hatası.';
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
        } catch (_) {
          // Yanıt JSON değilse (genellikle route hatası veya global sunucu hatası)
          errorMessage = 'Sunucudan beklenmedik yanıt: ${response.statusCode}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme hatası: $errorMessage')),
          );
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

  List<dynamic> get filteredOrders {
    final selectedTab = _tabController.index;
    final now = DateTime.now();

    return orders.where((order) {
      final createdAt = order['created_at'];
      final createdDate = DateTime.tryParse(createdAt ?? '');
      if (createdDate == null) return false;

      final difference = now.difference(createdDate).inDays;
      final isToday = difference < 2;
      // Backend'de 'status' alanı var. Teslim edilmemiş olanları bekleyen sayıyoruz.
      final isPending = (order['status']?.toLowerCase() != 'teslim edildi');

      final nameMatch = order['customer_name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      if (selectedTab == 0) return isToday && nameMatch; // Bugün
      if (selectedTab == 1)
        return isPending && !isToday && nameMatch; // Bekleyen
      return nameMatch; // Tümü (index 2)
    }).toList();
  }

  List<dynamic> getFilteredOrdersForTab(int tabIndex) {
    final now = DateTime.now();

    return orders.where((order) {
      final createdAt = order['created_at'];
      final createdDate = DateTime.tryParse(createdAt ?? '');
      if (createdDate == null) return false;

      final difference = now.difference(createdDate).inDays;
      final isToday = difference < 2;
      final isOld = difference >= 2;

      final nameMatch = order['customer_name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery);

      if (tabIndex == 0) return isToday && nameMatch; // Bugün
      if (tabIndex == 1) return isOld && nameMatch; // Bekleyen
      return nameMatch; // Tümü (index 2)
    }).toList();
  }

  Widget buildOrderList(int tabIndex) {
    final filtered = getFilteredOrdersForTab(tabIndex);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: ListView.builder(
        key: ValueKey<int>(filtered.length + tabIndex), // farklı key
        padding: const EdgeInsets.only(top: 12),
        itemCount: filtered.length,
        itemBuilder: (context, index) => buildOrderCard(filtered[index]),
      ),
    );
  }

  Color getStatusColor(String? status) {
    final lower = status?.toLowerCase() ?? '';
    switch (lower) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return const Color.fromARGB(255, 216, 89, 167);
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Veritabanı ENUM değerlerini Türkçeye çeviren yardımcı metot
  String _getTurkishStatus(String status) {
    switch (status.toLowerCase()) {
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

  Widget _buildAnimatedList(List<dynamic> orders) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.1, 0), // sağdan hafif kayma
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: ListView.builder(
        key: ValueKey<int>(orders.length), // liste değişince animasyon çalışsın
        padding: const EdgeInsets.only(top: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) => buildOrderCard(orders[index]),
      ),
    );
  }

  Widget buildOrderCard(dynamic order) {
    final createdAt = order['created_at'] ?? '';
    final dateTime = DateTime.tryParse(createdAt);
    final formattedDate = dateTime != null
        ? '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}'
        : 'Tarih yok';
    final formattedTime = dateTime != null
        ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
        : 'Saat yok';

    final totalAmount = order['total_amount'];
    final formattedAmount = totalAmount != null
        ? '${double.parse(totalAmount.toString()).toStringAsFixed(2)} TL'
        : 'Tutar Belirtilmemiş';

    final status = order['status'] ?? 'Durum yok';
    final statusColor = getStatusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order['customer_name'] ?? 'Müşteri Adı Belirtilmemiş',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditOrderPage(order: order),
                      ),
                    );
                    if (result == true) fetchOrders();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => confirmDeleteOrder(order['id']),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Müşteri adı ve durum
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['description'] ?? 'Müşteri bilgisi yok',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  formattedAmount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary, // Farklı bir renkle vurgulanabilir
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _getTurkishStatus(status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: getStatusColor(
                      status,
                    ), // bu özel renk zaten tema dışı olabilir
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tarih ve saat bilgisi
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int get todayOrderCount {
    final now = DateTime.now();
    return orders.where((order) {
      final createdAt = order['created_at'];
      final createdDate = DateTime.tryParse(createdAt ?? '');
      if (createdDate == null) return false;
      return now.difference(createdDate).inDays < 2;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Text(
                  'Menü',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.list_alt,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  'Siparişlerim',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.woman,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  'Hedef Takibi',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/women_in_challenge');
                },
              ),
              if (isFemaleEntrepreneur)
                ListTile(
                  leading: Icon(
                    Icons.map,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    'Başarılı Kadınlar Haritası',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, 'api/women-map');
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.groups,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  'Topluluk',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, 'api/community');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.chat_bubble,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  'Dahlia Asistanı',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/chatbot');
                },
              ),

              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SwitchListTile(
                    title: Text(
                      'Koyu Tema',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Theme.of(context).primaryColor,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  'Çıkış Yap',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sol ikon
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(
                          Icons.menu,
                          size: 28,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),

                    // Ortadaki logo (responsive ama ikonları bozmadan)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.7),
                            blurRadius: 25,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        "assets/images/logo.png",

                        height: (MediaQuery.of(context).size.width * 0.18)
                            .clamp(65.0, 100.0),
                        // min 65px, max 100px
                      ),
                    ),

                    // Sağ ikon
                    IconButton(
                      icon: Icon(
                        Icons.person,
                        size: 28,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/profile',
                        );
                        if (result == true) {
                          await _refreshProfileInfo();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Sipariş Ara...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode
                        ? const Color.fromARGB(221, 166, 187, 166)
                        : Colors.black54,
                  ),
                  fillColor: isDarkMode
                      ? const Color(0xFF424242)
                      : Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white24
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white24
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bugün $todayOrderCount siparişin var!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textColor,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Siparişlerim',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkMode
                          ? const Color.fromARGB(235, 255, 255, 255)
                          : AppTheme.textColor,

                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            // TabBar
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.hintColor,
              labelStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.normal,
              ),
              onTap: (index) {
                // Tab'a tıklayınca sayfayı da kaydır
                _pageController?.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              tabs: const [
                Tab(text: 'Bugün'),
                Tab(text: 'Bekleyen'),
                Tab(text: 'Tümü'),
              ],
            ),

            // TabBarView + Animasyonlu Listeler
            Expanded(
              child: PageView(
                controller: _pageController!,
                onPageChanged: (index) {
                  // Sayfa kaydırılınca tab değişsin
                  _tabController.animateTo(index);
                },
                children: [
                  buildOrderList(0),
                  buildOrderList(1),
                  buildOrderList(2),
                ],
              ),
            ),
          ],
        ),
      ),

      resizeToAvoidBottomInset: false,
      // FAB Stack ile iki buton:
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        children: [
          // Sol alt köşedeki Chatbot butonu
          Positioned(
            bottom: 32,
            left: 24,
            child: FloatingActionButton(
              heroTag: "chatbotBtn",
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.chat_bubble, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/chatbot');
              },
            ),
          ),
          // Sağ alt köşedeki Sipariş Ekle butonu
          Positioned(
            bottom: 32,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddOrderPage()),
                );
                if (result == true) fetchOrders();
              },
            ),
          ),
        ],
      ),
    );
  }
}
