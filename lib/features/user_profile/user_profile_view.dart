import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/user_profile/user_details_view.dart';
import 'package:frontend/features/user_profile/user_registration_view.dart';

import 'registration_provider.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ProfileViewState();
  }
}
class _ProfileViewState extends ConsumerState<ProfileView> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final authState = ref.watch(registrationProvider);

    print("authState $authState");

    return Scaffold(
        appBar: AppBar(title: Text('AIDY-Profile'),),
        body:  authState.when(
            data: ( authResponse) {
              if(authResponse != null) {
                return UserDetailsView();
              }
              else {
                return UserRegistrationView();
              }
            },
            error: (err, stack){

            },
            loading: () {
              return Center(child: CircularProgressIndicator(),);
            }
        )

      // body:
    );
  }
}