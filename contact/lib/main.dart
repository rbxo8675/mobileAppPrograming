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
            backgroundColor: Colors.white, //상단 바 배경색
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1.0),
              child: Container(
                color: Colors.grey[300],
                height: 1.0,
              ),
            ),
              title:
            Row(
              children: [
                Text("금호동 3가"),
                IconButton(
                    icon: Icon(Icons.keyboard_arrow_down),
                        onPressed: (){},
                ),
              ],
            ),

            actions: <Widget>[
              IconButton(
                icon:Icon(Icons.search), //검색 아이콘
                onPressed: (){},
              ),
              IconButton(
                icon:Icon(Icons.menu_sharp), //채팅 아이콘
                onPressed: (){},
              ),
              IconButton(
              icon:Icon(Icons.notifications), //검색 아이콘
              onPressed: (){},
              ),



            ],
             //알림 아이콘
          ),

          body:
          Container(
            child: Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  margin: EdgeInsets.all(10.0), //컨테이너 밖에 여

                  width: 100,
                  height: 100,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/canonCamera.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          Column(
            children: [
              Text("캐논 DSLR 100D (단렌즈, 충전기 16R기가SD 포함)"),
              Text("성동구 행당동  . 끌올 10분 전"),
              Text("210,000원"),

              Container(
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.grey),
                    Text("4", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
                ),

              ],

            ),
          )
        )

    );



  }
}

