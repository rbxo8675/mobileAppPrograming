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
            title: Text("앱임"),
          ),
          body: SizedBox(
            child: Text('안녕하세요', //텍스트 위젯),
              style: TextStyle(
                fontSize: 30, //폰트 크기
                color: Color.from, //폰트 색상
              ),
            ),
          )
        )

        );



  }
}

