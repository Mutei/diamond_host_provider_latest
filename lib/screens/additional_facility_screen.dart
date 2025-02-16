// ignore_for_file: non_constant_identifier_names

import 'package:daimond_host_provider/constants/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../utils/additional_facility.dart';
import '../utils/rooms.dart';
import '../widgets/birthday_textform_field.dart';
import 'add_image_screen.dart';
import 'date_booking_screen.dart';

class AdditionalFacility extends StatefulWidget {
  String CheckState;
  String IDEstate;
  Map estate;
  bool CheckIsBooking;
  List<Rooms>? Lstroom;
  AdditionalFacility(
      {required this.CheckState,
      required this.CheckIsBooking,
      required this.estate,
      required this.IDEstate,
      this.Lstroom});
  @override
  _State createState() =>
      new _State(CheckState, CheckIsBooking, IDEstate, Lstroom, estate);
}

class _State extends State<AdditionalFacility> {
  final GlobalKey<ScaffoldState> _scaffoldKey1 = new GlobalKey<ScaffoldState>();
  String CheckState;
  bool CheckIsBooking;
  int? FasiltyID;
  String IDEstate;
  List<Rooms>? Lstroom;
  Map estate;

  DatabaseReference ref =
      FirebaseDatabase.instance.ref("App").child("Fasilty ");
  List<Additional> LstAdditional = [];
  List<Additional> LstAdditionalTmp = [];

  List<Additional> LstAdditionalSelected = [];

  TextEditingController EnName_Controller = TextEditingController();
  TextEditingController Name_Controller = TextEditingController();
  TextEditingController Price_Controller = TextEditingController();
  int i = 0;
  _State(this.CheckState, this.CheckIsBooking, this.IDEstate, this.Lstroom,
      this.estate);
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey1,
        appBar: AppBar(
          iconTheme: kIconTheme,
          actions: [],
        ),
        body: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            // ignore: prefer_const_constructors

            child: ListView(
              children: [
                // ignore: prefer_const_constructors
                Container(
                  margin: const EdgeInsets.only(top: 30, left: 15, right: 15),
                  child: Text(
                    getTranslated(context, "additional services"),
                    // ignore: prefer_const_constructors
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  child: CheckIsBooking
                      ? SizedBox(
                          child: FirebaseAnimatedList(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            defaultChild: const Center(
                              child: CircularProgressIndicator(),
                            ),
                            itemBuilder: (context, snapshot, animation, index) {
                              Map map = snapshot.value as Map;
                              map['Key'] = snapshot.key;
                              int i = 0;
                              if (map['Name'].toString().toLowerCase() !=
                                  "name") {
                                LstAdditionalTmp.add(Additional(
                                    id: map['ID'],
                                    name: map['Name'],
                                    price: map['Price'],
                                    nameEn: map['Name'],
                                    isBool: false,
                                    color: Colors.white));
                                return Container(
                                  height: 70,
                                  color: LstAdditionalTmp[index].color,
                                  margin: const EdgeInsets.all(15),
                                  // color: Colors.amberAccent,
                                  child: ListTile(
                                    onTap: () {
                                      int indx =
                                          LstAdditionalSelected.indexWhere(
                                              (element) =>
                                                  element.id == map['ID']);

                                      if (indx == -1) {
                                        LstAdditionalSelected.add(Additional(
                                            id: map['ID'],
                                            name: map['Name'],
                                            price: map['Price'],
                                            nameEn: map['NameEn'],
                                            isBool: false,
                                            color: Colors.white));
                                        setState(() {
                                          LstAdditionalTmp[index].color =
                                              Colors.amberAccent;
                                        });
                                      } else {
                                        LstAdditionalSelected.removeAt(indx);
                                        setState(() {
                                          LstAdditionalTmp[index].color =
                                              Colors.white;
                                        });
                                      }
                                      print(LstAdditionalSelected.length);
                                    },
                                    title: Text(LstAdditionalTmp[index].name),
                                    subtitle:
                                        Text(LstAdditionalTmp[index].price),
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                            query: FirebaseDatabase.instance
                                .ref("App")
                                .child("Fasilty ")
                                .child(IDEstate),
                          ),
                        )
                      : CheckState == "add"
                          ? PageAdd()
                          : PageUpdate(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    child: Container(
                      width: 150.w,
                      height: 6.h,
                      margin: const EdgeInsets.only(
                          right: 40, left: 40, bottom: 20),
                      decoration: BoxDecoration(
                        color: kPurpleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // ignore: prefer_const_constructors
                      child: Center(
                        child: Text(
                          getTranslated(context, "Next"),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    onTap: () async {
                      if (CheckIsBooking) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => DateBooking(
                                  Estate: estate,
                                  LstAdditional: LstAdditionalSelected,
                                  LstRooms: Lstroom!,
                                )));
                      } else {
                        if (CheckState == "Edit") {
                          await ref.child(IDEstate).remove();
                          for (int i = 0; LstAdditional.length > 0; i++) {
                            if (LstAdditional[i].isBool) {
                              // false update
                            }
                          }
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AddImage(
                                    IDEstate: IDEstate,
                                    typeEstate: 'Hottel',
                                  )));
                        } else {
                          // ignore: unnecessary_new
                          Additional additional = new Additional(
                              id: "",
                              name: "Name",
                              nameEn: "NameEn",
                              price: "Price",
                              isBool: false,
                              color: Colors.white);
                          Save(additional);

                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AddImage(
                                    IDEstate: IDEstate,
                                    typeEstate: 'Hottel',
                                  )));
                        }
                      }
                    },
                  ),
                ),
              ],
            )));
  }

  Element(Additional obj) {
    return Card(
      // ignore: sort_child_properties_last
      child: ListTile(
        title: Text(
          obj.name,
        ),
        subtitle: Text(obj.price),
        trailing: Checkbox(
          checkColor: Colors.white,
          value: obj.isBool,
          onChanged: (bool? value) {
            setState(() {
              obj.isBool = value!;
            });
          },
        ),
      ),
      elevation: 5,
    );
  }

  PageAdd() {
    return Container(
      child: Wrap(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "Name",
                // ignore: prefer_const_constructors
                icon: Icon(
                  Icons.person,
                  color: kPurpleColor,
                ),
                control: Name_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "NameEN",
                // ignore: prefer_const_constructors
                icon: Icon(
                  Icons.person,
                  color: kPurpleColor,
                ),
                control: EnName_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: TextFormFieldStyle(
                      context: context,
                      hint: "Price",
                      // ignore: prefer_const_constructors
                      icon: Icon(
                        Icons.person,
                        color: kPurpleColor,
                      ),
                      control: Price_Controller,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.number),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    child: Container(
                      height: 6.5.h,
                      width: 150.w,
                      margin: const EdgeInsets.only(right: 40, top: 10),
                      padding: const EdgeInsets.only(left: 10, right: 10),

                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // ignore: prefer_const_constructors
                      child: Center(
                        child: Text(
                          getTranslated(context, "Save"),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    onTap: () async {
                      i++;
                      // ignore: unnecessary_new
                      Additional x = new Additional(
                          id: i.toString(),
                          name: Name_Controller.text,
                          price: Price_Controller.text,
                          nameEn: EnName_Controller.text,
                          isBool: false,
                          color: Colors.white);
                      setState(() {
                        LstAdditionalTmp.add(x);
                      });
                      Save(x);
                    },
                  ),
                ),
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.only(
              bottom: 20,
            ),
            // ignore: sort_child_properties_last
            child: ListView.builder(
                itemCount: LstAdditionalTmp.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    child: ListTile(title: Text(LstAdditionalTmp[index].name)),
                  );
                }),
            height: 250,
          ),
        ],
      ),
    );
  }

  PageUpdate() {
    return Container(
      child: Wrap(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "Name",
                // ignore: prefer_const_constructors
                icon: Icon(
                  Icons.person,
                  color: kPurpleColor,
                ),
                control: Name_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "NameEN",
                // ignore: prefer_const_constructors
                icon: Icon(
                  Icons.person,
                  color: kPurpleColor,
                ),
                control: EnName_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: TextFormFieldStyle(
                      context: context,
                      hint: "Price",
                      // ignore: prefer_const_constructors
                      icon: Icon(
                        Icons.person,
                        color: kPurpleColor,
                      ),
                      control: Price_Controller,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.number),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    child: Container(
                      height: 6.5.h,
                      width: 150.w,
                      margin: const EdgeInsets.only(right: 40, top: 10),
                      padding: const EdgeInsets.only(left: 10, right: 10),

                      decoration: BoxDecoration(
                        color: kPurpleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // ignore: prefer_const_constructors
                      child: Center(
                        child: Text(getTranslated(context, "Save")),
                      ),
                    ),
                    onTap: () async {
                      i++;
                      // ignore: unnecessary_new
                      Additional x = new Additional(
                          id: i.toString(),
                          name: Name_Controller.text,
                          price: Price_Controller.text,
                          nameEn: EnName_Controller.text,
                          isBool: false,
                          color: Colors.white);
                      setState(() {
                        LstAdditionalTmp.add(x);
                      });
                      SaveUpdate(x);
                    },
                  ),
                ),
              )
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 40, top: 10),
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: FirebaseAnimatedList(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              defaultChild: const Center(
                child: CircularProgressIndicator(),
              ),
              itemBuilder: (context, snapshot, animation, index) {
                Map map = snapshot.value as Map;
                map['Key'] = snapshot.key;
                LstAdditionalTmp.add(Additional(
                    id: map['ID'],
                    name: map['Name'],
                    price: map['Price'],
                    nameEn: map['NameEn'],
                    isBool: false,
                    color: Colors.white));
                return Container(
                  height: 50,
                  child: ListTile(
                    title: Text(map['Name']),
                    subtitle: Text(map['Price']),
                    onTap: () {
                      setState(() {
                        Name_Controller.text = map['Name'];
                        EnName_Controller.text = map['NameEn'];
                        Price_Controller.text = map['Price'];
                      });
                    },
                  ),
                );
              },
              query: FirebaseDatabase.instance
                  .ref("App")
                  .child("Fasilty ")
                  .child(IDEstate),
            ),
          )
        ],
      ),
    );
  }

  Save(Additional obj) async {
    if (obj.nameEn.toLowerCase() != "NameEn".toLowerCase()) {
      await ref.child(IDEstate).child(obj.name).set({
        "ID": obj.id,
        "Name": obj.name,
        "NameEn": obj.nameEn,
        "Price": obj.price,
      });
    }

    setState(() {
      Name_Controller.text = "";
      EnName_Controller.text = "";
      Price_Controller.text = "";
    });
  }

  SaveUpdate(Additional obj) async {
    ref.child(IDEstate).child(obj.name).remove();
    await ref.child(IDEstate).child(obj.name).set({
      "ID": obj.id,
      "Name": obj.name,
      "NameEn": obj.nameEn,
      "Price": obj.price,
    });
  }
}
