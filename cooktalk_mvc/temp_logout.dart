import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  await FirebaseAuth.instance.signOut();
  print('Logged out successfully');
}
