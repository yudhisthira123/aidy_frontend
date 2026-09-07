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
            return RefreshIndicator(
              onRefresh: () => ref.read(requestsProvider.notifier).getRequests(),
              child: data == null ?
              Text("Failed to load")
              : ListView.separated(
                itemCount: data.length,
                separatorBuilder: (_, _) => Divider(
                  color: Colors.red,
                ),
                itemBuilder: (context, index) {
                  // final item = data[index];
                  return Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text(data[index].description)));
                },
              )
            );
          },
          error: (error, stack){
            return Text("Failed to load data");
          },
          loading: (){
            return Text("Loading");
          }
      )
    );
  }
}