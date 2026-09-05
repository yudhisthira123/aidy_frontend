import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/requests/requests_provider.dart';

class RequestsView extends ConsumerStatefulWidget {
  const RequestsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _RequestsViewState();
  }
}
class _RequestsViewState extends ConsumerState<RequestsView> {
  @override
  Widget build(BuildContext context) {

    final requestState = ref.watch(requestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('AIDY'),),
      body: requestState.when(
          data: (data){
            return Text("DATA");
          },
          error: (error, stack){
            return Text("Error");
          },
          loading: (){
            return Text("Loading");
          }
      )
    );
  }
}