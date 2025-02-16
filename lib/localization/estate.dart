import 'dart:convert';
import 'dart:ui';
import '../utils/additional_facility.dart';
import '../utils/rooms.dart';

class Estate {
  late String id, name, nameEn, type, bio, bioEn, image, country, city, state;
  List<Rooms> listRooms = [];
  List<Image> listImage = [];
  List<Additional> listAdditional = [];
  Estate(
      {required this.id, //
        required this.name, //
        required this.nameEn, //
        required this.type, //
        required this.bio, //
        required this.bioEn, //
        required this.image,
        required this.country, //
        required this.city, //
        required this.listRooms,
        required this.listAdditional,
        required this.state}); //

  factory Estate.fromJson(Map<dynamic, dynamic> json) {
    return Estate(
      bio: json['BioAr'] as String,
      bioEn: json['BioEn'] as String,
      city: json['City'] as String,
      country: json['Country'] as String,
      name: json['NameAr'] as String,
      nameEn: json['NameEn'] as String,
      type: json['Type'] as String,
      state: json['State'] as String,
      id: json['ID'] as String,
      listAdditional: json['LstAdditional'],
      listRooms: json['LstRooms'],
      image: '',
    );
  }
  static List<Estate> parseEstate(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Estate>((json) => Estate.fromJson(json)).toList();
  }
}