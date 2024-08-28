import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pollusafe_app/src/constant/constant.dart';
import 'package:pollusafe_app/src/constant/themes/sizes.dart';
import 'package:pollusafe_app/src/core/screen/auth/signup/signup.dart';
import 'package:pollusafe_app/src/core/screen/data/fetch/fetch_map.dart';
import 'package:pollusafe_app/src/core/screen/data/permission/location_permission_handler.dart';
import 'package:pollusafe_app/src/shared/geolocator_provider.dart';
import 'package:pollusafe_app/src/widgets/button/button_app.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  TextEditingController searchController = TextEditingController();
  double defaultLang = 107.62816;
  double defaultLat = -6.969282;
  GoogleMapController? _mapController;

  void makeSugestion() {
    // AIzaSyB5kbEyTfJO4R2cQQSd2lZ1Gw4HUmMHCL8
  }

  // Membuat TileOverlay dengan TileProvider kustom
  TileOverlay _createTileOverlay() {
    return TileOverlay(
      tileOverlayId: const TileOverlayId('aqiTileOverlay'),
      tileProvider: AQITileProvider(),
    );
  }

  void _updateCameraPosition(double lat, double lng) {
    final newPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 10.0, // Sesuaikan dengan tingkat zoom yang diinginkan
    );

    _mapController?.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorApp.green,
                Color.fromARGB(255, 10, 88, 68),
              ],
            ),
          ),
        ),
        title: Text(
          "Maps",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(defaultLat, defaultLang),
            zoom: 10,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          tileOverlays: {_createTileOverlay()},
        ),
        SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Find your area",
                            hintStyle: const TextStyle(
                                color: ColorApp.darkGrey, fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: ColorApp.darkBlue),
                            labelStyle: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.red,
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 238, 240, 244),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          onChanged: (String value) {
                            setState(() {});
                          },
                        ),
                      ),
                      Gap.w12,
                      IconButton(
                          onPressed: () {
                            if (searchController.text == "") {
                              showDialog(
                                  context: context,
                                  builder: (context) => const AlertDialogApp(
                                      title: "Cannot find empty city!",
                                      description:
                                          " Please enter a valid city name."));
                            } else {
                              if (FetchMap.fetchGeo(searchController.text)!
                                          .lat !=
                                      0 &&
                                  FetchMap.fetchGeo(searchController.text)!
                                          .long !=
                                      0) {
                                _updateCameraPosition(
                                    FetchMap.fetchGeo(searchController.text)!
                                        .lat,
                                    FetchMap.fetchGeo(searchController.text)!
                                        .long);
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (context) => const AlertDialogApp(
                                        title: "City Not Found!",
                                        description:
                                            "Please enter a valid city name."));
                              }
                            }
                          },
                          icon: const Icon(Icons.search))
                    ],
                  ),
                  Gap.h12,
                  ButtonApp(
                    onPressed: () {
                      determinePosition().then((value) {
                        final newLat = value.latitude;
                        final newLng = value.longitude;

                        // Update posisi geolocator provider
                        ref.read(geolocatorLangProvider.notifier).state =
                            newLng;
                        ref.read(geolocatorLatProvider.notifier).state = newLat;

                        // Pindahkan kamera ke posisi yang baru
                        _updateCameraPosition(newLat, newLng);
                      }).onError((error, stackTrace) {
                        print("ERROR $error");
                      });
                    },
                    text: "Current Location",
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class AQITileProvider implements TileProvider {
  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    // URL dari tile dengan token yang sudah digantikan
    final url =
        'https://tiles.waqi.info/tiles/usepa-aqi/$zoom/$x/$y.png?token=15a6f6d5bcf8d0e0ce2885d4efaf64388d32d860';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Mengembalikan Tile dari bytes gambar
        return Tile(256, 256, response.bodyBytes);
      } else {
        // Mengembalikan Tile kosong jika tidak berhasil memuat
        return Tile(256, 256, Uint8List(0));
      }
    } catch (e) {
      print('Error loading tile: $e');
      // Mengembalikan Tile kosong jika terjadi kesalahan
      return Tile(256, 256, Uint8List(0));
    }
  }
}
