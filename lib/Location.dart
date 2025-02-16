import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controller/location_permission_handler.dart';




class LocationPage extends StatefulWidget {
  LocationPage({super.key}); 
  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {


  TextEditingController searchPlaceController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
      ),
      backgroundColor: Color(0xffFFEBCD),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left:  20, right: 20),
        child: Column(
          children: [
            TextField(
              controller: searchPlaceController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm địa điểm'
              ),
              onChanged: (String value){
                print(value.toString());
                setState(() {
                  
                });
              },
            ),
            Visibility(
              visible: searchPlaceController.text.isEmpty?false:true,
              child: Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  shrinkWrap: true,
                  itemBuilder: (context,index){
                    return ListTile(
                      onTap: (){

                      },
                      leading: const Icon(Icons.location_on),
                      title: Text('Địa điểm'),
                    );
                  },
                ),
              ),
            ),
            Visibility(
              visible: searchPlaceController.text.isEmpty?true:false,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                child: ElevatedButton(onPressed: (){
              //   determinePosition().then((value) {
              //     Navigator.push(context, MaterialPageRoute(builder: (context)=>
              //     GoogleMapScreen(lat: value.latitude,lng:value.longitude)
              //     ))
              // }).onError((error, stackTrace){
              //   print('Lỗi địa điểm: ${(error.toString())}');
              // });
                }, 
                child: Row(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Icon(Icons.my_location, color: Colors.green,),
                    SizedBox(width: 5,),
                    Text('Địa điểm hiện tại')
                  ],
                ))
              ),
            )
          ]
        ),
      ),
    );
  }


}
