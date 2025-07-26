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
          body: Text("안녕"),
          bottomNavigationBar: BottomAppBar(//하단 바
            child : SizedBox(//row 위젯을 사용하기 위해서 컨테이너로 감싸줌
              //컨테이너 위젯에 린트가 뜨는 이유 : 컨테이너는 무겁기 때문에 SizedBox를 사용
              height: 100, //높이 설정
              child: Row( //가로로 배치

                mainAxisAlignment: MainAxisAlignment.spaceEvenly,//정렬
                children: [
                Icon(Icons.phone),
                Icon(Icons.message),
                Icon(Icons.contact_page),
                ],
              ),
            )
          ),
        ),

    );

  }
}

