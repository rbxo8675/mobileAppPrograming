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

