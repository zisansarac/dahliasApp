import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:siparis_app/theme.dart';
import 'package:siparis_app/constants.dart';

class WomenMapPage extends StatefulWidget {
  const WomenMapPage({super.key});

  @override
  State<WomenMapPage> createState() => _WomenMapPageState();
}

class _WomenMapPageState extends State<WomenMapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchEntrepreneurs();
  }

  // Hafif rastgele offset eklemek için
  double _randomOffset() {
    final random = Random();
    return (random.nextDouble() - 0.5) * 0.01; // ±0.005 derece
  }

  Future<void> _fetchEntrepreneurs() async {
    final response = await http.get(Uri.parse(ApiConstants.womenMap));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      Set<Marker> loadedMarkers = data.map((item) {
        final id =
            item['id']?.toString() ?? Random().nextInt(100000).toString();
        final name = item['name'] ?? 'İsimsiz';
        final city = item['city'] ?? 'Bilinmiyor';
        final description = item['description'] ?? 'Açıklama yok';

        double lat = (item['lat'] as num?)?.toDouble() ?? 0.0;
        double lng = (item['lng'] as num?)?.toDouble() ?? 0.0;

        return Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: name,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => DraggableScrollableSheet(
                  expand: false,
                  builder: (_, controller) => SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Şehir: $city',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 12),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toSet();

      setState(() {
        _markers = loadedMarkers;
      });
    } else {
      print("Veri alınamadı: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Başarılı Kadınlar Haritası",
          style: textTheme.titleLarge?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ⚡ Bilgilendirme banner'ı
          Container(
            width: double.infinity,
            color: AppTheme.primaryColor.withOpacity(0.1), // hafif arka plan
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "İsimlerin üzerine basarak detaylı bilgiye ulaşabilirsiniz.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Harita
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(39.925533, 32.866287),
                zoom: 5.5,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }
}
