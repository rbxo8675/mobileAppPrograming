/*
- 컨테이너를 사용하여서 여백, 패딩을 설정
- 테두리는 decoration 속성을 사용 + 섬세한 박스 설정
- decoration 속성을 선언할 때에는 외부에서 다른 색상등을 설정 못함
*/

return MaterialApp(//실제로 코딩이 이루어지는 공간
        home: Scaffold(
          appBar: AppBar(//상단 바
            backgroundColor: Colors.blue,
              title: Text("앱임",
              style: TextStyle(color: Colors.white),)
          ),
          body: Container(
            width: 150, height: 50,

              margin: EdgeInsets.fromLTRB(0,20,0,0),//일부 여백을 넣는 법
              // margin: EdgeInsets.all(20), //모든 방향에 여백을 넣는 법
              // padding: EdgeInsets.all(20),

            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 5), //테두리 색상과 두께
            ),
            child: Text("dddd"),
          )

        ),

    );

    /*
    정렬하는 법 ( topCenter).
    유효한 정도의 창까지 무한으로 늘리는 법

    */
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