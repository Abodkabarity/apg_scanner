import 'package:apg_scanner/presentation/login_page/login_block/login_bloc.dart';
import 'package:apg_scanner/presentation/login_page/login_block/login_event.dart';
import 'package:apg_scanner/presentation/login_page/widgets/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../add_project/add_project_page.dart';
import 'login_block/login_state.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.isLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(child: CircularProgressIndicator()),
            );
          }

          if (state.error != null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }

          if (state.isSuccess) {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => AddProjectPage()),
            );
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/background.png",
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 200.h),
                width: 350.w,
                height: 400.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.r),
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    return LogInWidget(
                      title: " APG Stock Taking",
                      emailController: emailController,
                      passwordController: passwordController,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<LoginBloc>().add(
                            LoginSubmitted(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            ),
                          );
                        }
                      },

                      error: state.error,
                      formKey: _formKey,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
