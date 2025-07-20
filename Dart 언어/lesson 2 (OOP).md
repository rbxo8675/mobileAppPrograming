# OOP (Object Oriented Programming)
> 객체 지향 프로그래밍
- 클래스를 가지고 프로그래밍을 하는 것

## Class 정의
[class정의](/Dart%20언어/인스턴스.png)
> Idol 이라는 클래스 안에 여러가지의 정의가 되어 있음
> 여러개의 인스턴스를 만들 수 있음
- 설계서를 만드는 것 : 클래스 정의
- 실제로 결과물을 만드는 것 : 인스턴스


### 클래스 정의하기

```dart
//name (이름)
//membr
//sayHello
//introduce
class Idol{
    String name = '블랙핑크';
    List<String> members = ['지수', '제니','리사', '로제'];

    void sayHello(){
        print('안녕하세요 블랙핑크크입니다.');
    }

    void introduce(){
        print('저희 멤버는 지수, 제니, 리사, 로제가 있습니다.');
    }
}


```
### 인스턴스 사용하기
> 현재는 블랙핑크만 인스턴스로 사용가능 

``` dart
void main(){
    Idol blackPink = Idol();
    
    print(blackPink.name);
    print(blakcPink.members);
    blackPink.sayHello();
    blackPink.introduce();
}
```

### constructor ( 생성자 )

```dart
//name (이름)
//membr
//sayHello
//introduce
class Idol{
    String name;
    List<String> members;

    Idol(String name , List<String> members) : this.name = name, this. members = members);//생성자
    //이름과 멤버를 바꾸고 싶을 떄
    //외부에서 이름과 멤버를 받아서 클래스를 변경함


    void sayHello(){
        print('안녕하세요 ${this.name}입니다.');
    }

    void introduce(){
        print('저희 멤버는 ${this.members}가 있습니다.');
    }
}


```

``` dart
void main(){
    Idol blackPink = Idol('블랙핑크', ['지수', '제니','리사', '로제']);
    
    print(blackPink.name);
    print(blakcPink.members);
    blackPink.sayHello();
    blackPink.introduce();


    Idol bts = Idol('BTS', ['RM','진', '슈가', '제이홉', '지민', '뷔', '정국']);
    print(bts.name);
    print(bts.members);
    bts.sayHello();
    bts.introduce();
}
```

### 더 간결하게 프로그래밍 하는 법
```dart
//name (이름)
//membr
//sayHello
//introduce
class Idol{
    String name;
    List<String> members;

    Idol(this.name, this. members);//생성자
    //이름과 멤버를 바꾸고 싶을 떄
    //외부에서 이름과 멤버를 받아서 클래스를 변경함


    void sayHello(){
        print('안녕하세요 ${this.name}입니다.');
    }

    void introduce(){
        print('저희 멤버는 ${this.members}가 있습니다.');
    }
}

```

### 네임드 생성자 (named constructor)

```dart

class Idol{
    String name;
    List<String> members;

    Idol(this.name, this. members);//생성자
    //이름과 멤버를 바꾸고 싶을 떄
    //외부에서 이름과 멤버를 받아서 클래스를 변경함

    Idol.fromList(List values) : this.group = values[0], 
                                this.name = valuse[1];


    void sayHello(){
        print('안녕하세요 ${this.name}입니다.');
    }

    void introduce(){
        print('저희 멤버는 ${this.members}가 있습니다.');
    }
}

```

``` dart
void main(){
    Idol blackPink = Idol('블랙핑크', ['지수', '제니','리사', '로제']);
    
    print(blackPink.name);
    print(blakcPink.members);
    blackPink.sayHello();
    blackPink.introduce();


    Idol bts = Idol.fromList(
        [
            ['RM','진', '슈가', '제이홉', '지민', '뷔', '정국'], 
            'BTS'
        ]
    );

    print(bts.name);
    print(bts.members);
    bts.sayHello();
    bts.introduce();
}
```
 
### Immutable programming
>한 번 값을 지정하면(선언하면) 변경할 수 없도록 프로그래밍을 하는 것

```dart

class Idol{
    //버그 방지를 할 수 있음음
    final String name;
    final List<String> members;

    const Idol(this.name, this. members);//생성자
    //이름과 멤버를 바꾸고 싶을 떄
    //외부에서 이름과 멤버를 받아서 클래스를 변경함

    Idol.fromList(List values) : this.group = values[0], 
                                this.name = valuse[1];


    void sayHello(){
        print('안녕하세요 ${this.name}입니다.');
    }

    void introduce(){
        print('저희 멤버는 ${this.members}가 있습니다.');
    }
}

```
### const 예제

``` dart
void main(){
    Idol blackPink = Idol(
        '블랙핑크', 
        ['지수', '제니','리사', '로제']
    );

    Idol blackPink2 = Idol(
        '블랙핑크', 
        ['지수', '제니','리사', '로제']
    );
    
    /*사람이 보기에는 blackPink와 blackPink2가 같다고 생각하지만 프로그램 입장에서는 두개는 완전히 다른 값*/

    print(blackPink == blackPink2);
    //false

```


``` dart
void main(){
    Idol blackPink = const Idol(
        '블랙핑크', 
        ['지수', '제니','리사', '로제']
    );

    Idol blackPink2 = const Idol(
        '블랙핑크', 
        ['지수', '제니','리사', '로제']
    );
    
    print(blackPink == blackPink2);
    //true
    //같은 인스턴스로 구분되게 된다다

```

### Getter & Setter
