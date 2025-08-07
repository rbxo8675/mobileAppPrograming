/*
퍼센트로 크기를 지정할 수 있는 위젯은 Flexible 위젯입니다.
*/

return MaterialApp(
  home: Scaffold(
    appBar: AppBar(),
    body: Row(
      children: [
        // 3: 7 , 5: 5는 절반
        Flexible(child: Container(), flex : 3),
        Flexible(child: Container()flex : 7),
      ],
    ),
    ),
);

return MaterialApp(
  home: Scaffold(
    appBar: AppBar(),
    body: Row(
      children: [
        // 3: 7 , 5: 5는 절반
        Expanded(child: Container()), // flex : 1 가진 flexible 위젯
        Container(child: Container()),
      ],
    ),
    ),
);

// 박스 사이즈, 포지션 확인하기 
/* 
미리보기 -> DevTools -> Flutter Inspector 확인하기
*/

//숙제 : 당근 마켓 그리기
return MaterialApp(
  home: Scaffold(
    appBar: AppBar(),
    body: Container(
        height: 150, // 높이 지정
        padding : EdgeInsets.all(20), // 패딩 지정
        child : Row(
            children : [
                Image.asset('assets/camera.jpg',width : 150,),
                Container(
                    width: 300, // 너비 지정 -> 퍼센트로 지정하면 다른 기기를 사용해도 비율을 일정하게 할 수 있지 않을까?
                    
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                        children: [
                            Text('카메라 팝니다', style : TextStyle()),
                            Text('금호동 3가'),
                            Text('7000원'),
                            Row (
                                mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 정렬
                                children: [
                                    Icon(Icons.favorite),
                                    Text(' 4'),
                                ]
                            )
                        ]
                    )
                )
            ]
        )
    )
    ),
);