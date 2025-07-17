# 🧑‍💻 Dart 기본기 (1강)

## 👋 Hello World

```dart
void main() {
  print('Hello World');
}
```

---

## 📌 변수 선언 (Variable)

```dart
var name; // 변수 선언
print(name);
```

### ❌ 안되는 예시

```dart
var name = '코드팩토리';
var name = '팩토리2'; // 같은 이름의 변수 재선언 불가
```

---

## 🔢 변수 타입

### 📍 정수 (int)

```dart
int number1 = 10;
int number2 = 20;

print(number1 + number2);//더하기
print(number1 - number2);//빼기
print(number1 / number2);//나누기
print(number1 * number2);//곱하기
```

### 📍 실수 (double)

```dart
double number1 = 4.0;
double number2 = 1.5;

print(number1 + number2);//더하기
print(number1 - number2);//빼기
print(number1 / number2);//나누기
print(number1 * number2);//곱하기
```

### 📍 불리언 (boolean)

```dart
bool isTrue = true;
bool isFalse = false;

print(isTrue);
print(isFalse);
```

### 📍 문자열 (String)

```dart
String name1 = '홍길동';
var name2 = '홍길동'; // 타입 추론
// 우측에 있는 타입을 추측하여서 선언함

print(name1);
print(name2);

print(name2.runtimeType);
//string으로 선언 되어있는 것을 확인할 수 있음음
```

> var는 값이 고정되면 타입도 고정됨
> 가독성을 위해 명시적 타입 사용 권장

```dart
String name1 = '홍길동';
var name2 = '안녕하세요'; 

print(name1 + name2);
print(name1 + ' ' + name2);
//string의 덧셈셈

```


```dart
String name1 = '홍길동';
var name2 = '안녕하세요'; 

print('$name1 + ' ' + $name2');
print('${name1} ${name2.runtimeType}');
//string 안에 변수를 불러오는 것이 가능
```

### 📍 dynamic

```dart
dynamic name = '홍길동';
name = 1234; // 가능
```

> `var`는 값의 타입이 고정되지만, `dynamic`은 언제든 바뀔 수 있음

---

## ❓ Null Safety
- nullable : null이 될 수 있음
- non - nullable : null이 될 수 없음

```dart
String? name;     // null 가능
String name2;     // null 불가
String? name3 = null;
print(name3!);    // null 아님을 보장
```

---

## 🔒 final & const

* `final`: 한 번 설정된 값을 변경 불가, 빌드 타임 필요 없음
* `const`: final과 유사하나 **빌드 타임에 값이 확정**되어야 함

```dart
final DateTime now = DateTime.now(); // 가능
const DateTime now = DateTime.now(); // ❌ 오류
```

---

## 🧮 연산

```dart
double number = 4.0;
number += 1; //원하는 만큼 증가시킬 수 있음음
number++; //1씩만 증가
```

### Null 조건 연산자

```dart
double? number = null;
number ??= 3.0; // null이면 3.0 할당
```

---

## 🔘 Boolean & 논리 연산자

```dart
int number1 = 1;
int number2 = 2;

print(number1 > number2); //false
print(number1 < number2); //true
print(number1 >= number2); //false
print(number1 <= number2); //true
print(number1 == number2); //false
print(number1 != number2); //true
```

```dart
int number1 = 1;

print(number1 is int); //true
print(number1 is String); //false
print(number1 is! int); //false
print(number1 is! String); //true
```

* `&&` : AND
* `||` : OR
* `!` : NOT

```dart
bool isTrue = true;
bool isFalse = false;

print(isTrue && isFalse); // false
print(isTrue || isFalse); // true
print(!isTrue);           // false
```

---

## 📃 List

```dart
List<String> blackpink = ['지수', '제니', '로제', '리사'];

print(blackpink);
```

* 접근: `blackpink[0]`
* 길이: `blackpink.length`
* 추가: `blackpink.add('코드팩토리')`
* 삭제: `blackpink.remove('코드팩토리')`
* 찾기: `blackpink.indexOf('로제')`

---

## 🗺 Map

* key와 value를 갖게 됨

```dart
Map<String, String> dictionary = {
  'apple': '사과',
  'banana': '바나나',
};
```
* 값 추가: `dictionary.addAll({'orange': '오렌지'});`
* 값 접근: `dictionary['apple']` 키에 대해서 검색함
* 삭제: `dictionary.remove('apple')`
* 모든 키: `dictionary.keys`
* 모든 값: `dictionary.values`

---

## 🟢 Set

```dart
Set<String> names = {'홍길동', '이순신', '엄복동'};
```

* 중복 제거됨
* 추가: `.add()`
* 삭제: `.remove()`
* 포함 여부: `.contains()`

---

## 🧩 조건문

### if 문

```dart
if (조건) {
  // 실행 코드
} else if (조건) {
  // 실행 코드
} else {
  // 기본 실행 코드
}
```

### switch 문

```dart
switch (값) {
  case 'A':
    print('A');
    break;
  default:
    print('기본값');
}
```

---

## 🔁 반복문 (Loop)

### for

```dart
for (int i = 0; i < 5; i++) {
  print(i);
}
```

### for-in

```dart
for (var name in blackpink) {
  print(name);
}
```

### while

```dart
int i = 0;
while (i < 5) {
  print(i);
  i++;
}
```

### do-while

```dart
int i = 0;
do {
  print(i);
  i++;
} while (i < 5);
```

### break / continue

```dart
for (int i = 0; i < 5; i++) {
  if (i == 2) continue;
  if (i == 4) break;
  print(i);
}
```
* break : loop을 탈출
* continue : 현재 룸만 스킵킵

---

## 🎯 enum

* 조건의 범위가 확실할 때, 오타를 방지할 때 사용용

```dart
enum Status { approved, pending, rejected }

void main() {
  Status status = Status.approved;

  if(status == Status.approved){
    print('승인입니다.');
  }else if (status == Status.pending){
    print('대기입니다.');
  }else{
    print('거절입니다.');
  }
}
```

---

## 🔧 함수 (Function)

* 재활용 가능
* 실행은 main 함수 안에서서

```dart
void main(){
    addNumbers();
}

addNumbers(){
    int x = 10;
    int y = 20;
    int z = 30;

    int sum = x + y+ z;

    print ('x : $x');
    print ('y : $y');
    print ('z : $z');

    if(sum % 2 == 0){
        print('짝수입니다.');
    }else{
        print('홀수입니다.');
    }

}
```

### 파라미터 사용

* positional parameter
```dart
void main(){
    addNumbers(10,20,30);
}

addNumbers(int x, int y, int z){
    int sum = x + y+ z;

    print ('x : $x');
    print ('y : $y');
    print ('z : $z');

    if(sum % 2 == 0){
        print('짝수입니다.');
    }else{
        print('홀수입니다.');
    }

}
```

### Optional Parameter

* 기본 값이 없어서 sum 부분에서 에러가 남
```dart
void main(){
    addNumbers(10);
}

addNumbers(int x, [int? y, int? z]){
    int sum = x + y+ z;

    print ('x : $x');
    print ('y : $y');
    print ('z : $z');

    if(sum % 2 == 0){
        print('짝수입니다.');
    }else{
        print('홀수입니다.');
    }

}
```

* 수정본
```dart
void main(){
    addNumbers(10);
}

addNumbers(int x, [int y=20, int z=30]){
    int sum = x + y+ z;

    print ('x : $x');
    print ('y : $y');
    print ('z : $z');

    if(sum % 2 == 0){
        print('짝수입니다.');
    }else{
        print('홀수입니다.');
    }

}
```

### Named Parameter

```dart
void main(){
    addNumbers(x : 10, y : 20, z : 30);
}

addNumbers({
    required int x,
    requried int y,
    requried int z,
}){
    int sum = x + y+ z;

    print ('x : $x');
    print ('y : $y');
    print ('z : $z');

    if(sum % 2 == 0){
        print('짝수입니다.');
    }else{
        print('홀수입니다.');
    }

}
```
* Named parameter 안에서 optional parameter
```dart
void main(){
    addNumbers(x : 10, y : 20);
}

addNumbers({
    required int x,
    requried int y,
    int z = 30, //기본값 지정
}){
    int sum = x + y+ z;

    print ('x : $x');
    print ('y : $y');
    print ('z : $z');

    if(sum % 2 == 0){
        print('짝수입니다.');
    }else{
        print('홀수입니다.');
    }

}
```

---

## 🌀 반환 타입

```dart
void main(){
    int result = addNumbers(x : 10, y : 20);

    print('result : $result');
}

int addNumbers({
    required int x,
    requried int y,
    int z = 30, //기본값 지정
}){
    int sum = x + y+ z;

    print ('x : $x');
    print ('y : $y');
    print ('z : $z');

    if(sum % 2 == 0){
        print('짝수입니다.');
    }else{
        print('홀수입니다.');
    }

    return sum;

}
```

---

## ➡️ 화살표 함수 (Arrow Function)

```dart
void main(){
    int result = addNumbers(x : 10, y : 20);

    print('result : $result');
}

int addNumbers(int x,{
    requried int y,
    int z = 30, //기본값 지정
}) => x + y + z;
```

---

## 📌 typedef

```dart
void main(){
    Operation operation = add;

    int result = operation(10,20,30);

    print(result);

    operation = subtract;

    int result2 = operation(10,20,30);

    print(result2);

    int result3 = calculate(30,40,50,add);

    print(result3);

    int result4 = salculate(30,40,50,subtract);

    print(result4);
}

typedef Operation = int Function(int x, int y, int z);

int add(int x, int y , int z) => x + y + z;

int subtract(int x, int y , int z) => x - y - z;

int calculate(int x, int y, int z , Operation operation){
    return operation(x,y,z);
}

```

> 이 정리 내용은 코드팩토리님의 강의 수강을 하면서 개인적으로 필기한 내용을 정리한 것임을 밝힙니다.

