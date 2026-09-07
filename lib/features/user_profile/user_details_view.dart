import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/location/providers/location_provider.dart';

class UserDetailsView extends ConsumerWidget{
  const UserDetailsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final locationProvider = ref.watch(locationAsyncNotifierProvider);

    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              ref.read(locationAsyncNotifierProvider.notifier).startLocationTracking();
            },
            child: Text('Start Location')
          ),
          locationProvider.when(
              data: (location){
                return Text("startMonitoring: longitude = ${location.length} and latitude = ${location.length}");
              },
              error: (error, stack){
                return Text('Failed to load location');
              },
              loading: () => Center(child: CircularProgressIndicator(),)
          )
        ],
      ),
    );
  }

}