import 'package:flutter/material.dart';

//앱을 구동하는 함수
/*
플러터에서 앱 디자인을 넣는 법 : 위젯 짜깁기
*/

void main() {
  runApp(const MyApp()); //실제 구동하는 메인페이지
}
//stless 타입하고 tap : 코드 구조 생성
class  MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key : key);
  @override
  Widget build(BuildContext context) {

    return MaterialApp(//실제로 코딩이 이루어지는 공간
        home: Scaffold(
          appBar: AppBar(//상단 바
            backgroundColor: Colors.blue,
              title: Text("앱임",
              style: TextStyle(color: Colors.white),)
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity, height: 50,

                margin: EdgeInsets.fromLTRB(0,20,0,0),//일부 여백을 넣는 법
                // margin: EdgeInsets.all(20), //모든 방향에 여백을 넣는 법
                // padding: EdgeInsets.all(20),

              decoration: BoxDecoration(
                border: Border.all(color: Colors.black), //테두리 색상과 두께
              ),
              child: Text("dddd"),
            ),
          )

        ),

    );

  }
}

