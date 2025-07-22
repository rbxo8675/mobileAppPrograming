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
  const MyApp ({Key? key}) : super(key : key);
  @override
  Widget build(BuildContext context) {

    return MaterialApp(//실제로 코딩이 이루어지는 공간
        home: Text('안녕')//test 위젯
    );

    return MaterialApp(//실제로 코딩이 이루어지는 공간
        home: Icon(Icons.star)//아이콘 위젯
    );

    return MaterialApp(//실제로 코딩이 이루어지는 공간
        home: Image.asset('assets/이미지 경로')//test 위젯
    );
    assets 이름의 파일로 이미지를 추가해야함
    pupspec.yaml 파일 수정

    return MaterialApp(//실제로 코딩이 이루어지는 공간
        home: Center( //자식의 기준점을 정중앙으로 설정
          child : Container(width : 50, height : 50, color : Colors.blue)// 네모박스 위젯
        ) // home: SizedBox()
    );

  }
}