import 'package:flutter/widgets.dart';

class KeepAliveWrapper extends StatefulWidget {
  const KeepAliveWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
