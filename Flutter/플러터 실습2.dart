/*
MaterialApp () 
구글에서 제공하는 위젯 & 커스텀 위젯
디자인 뿐만아니라 세팅같은 기능도 가능능

CupertinoApp ()
애플에서 제공하는 위젯

Scaffold ()
화면을 구성하는 위젯
상,중,하단 3개의 영역으로 구성

*/

 return MaterialApp(//실제로 코딩이 이루어지는 공간
        home: Scaffold(
          
          body: Row(
            // mainAxisAlignment: MainAxisAlignment.center,//가운데 정렬 & main 축에 대해서 정렬
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            // crossAxisAlignment: ,//main 역축에 대해서 정렬 -> 상,하 폭이 필요함 -> container로 둘러싸야함
            children : [

            Icon(Icons.star),
            Icon(Icons.star),
            Icon(Icons.star),
            ],
          ),
    ),
        
    );








