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
            title:
            Row(
              children: [
                Text("금호동 3가"),
                Icon(Icons.keyboard_arrow_down),
              ],
            ),

            actions: <Widget>[
              IconButton(
                icon:Icon(Icons.search), //검색 아이콘
                onPressed: (){},
              ),
              IconButton(
              icon:Icon(Icons.notifications), //검색 아이콘
              onPressed: (){},
              ),
              IconButton(
                icon:Icon(Icons.menu_sharp), //채팅 아이콘
                onPressed: (){},
              ),


            ]
             //알림 아이콘
          ),

          body:
          Container(
            child: Row(
              children: [
                Image.asset(
                  "assets/images/1.png", //이미지 경로
                  width: 100, //너비
                  height: 100, //높이
                ),
                Column( //열
                  children: [
                    Text("캐논 DSLR 100D (단렌즈, 충전기 16R기가SD 포함)"),
                    Text("성동구 행당동  . 끌올 10분 전"),
                    Text("210,000원"),
                    Icon(Icons.favorite_border), //하트 아이콘
                  ],
                ),


              ],

            ),
          )
        )

        );



  }
}

