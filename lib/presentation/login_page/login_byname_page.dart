import 'package:apg_scanner/presentation/login_page/login_block/login_bloc.dart';
import 'package:apg_scanner/presentation/login_page/widgets/auth_gate_widget.dart';
import 'package:apg_scanner/presentation/login_page/widgets/login_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_color/app_color.dart';
import '../../core/di/injection.dart';
import '../../data/services/products_sync_service.dart';
import '../widgets/top_snackbar.dart';
import 'login_block/login_event.dart';
import 'login_block/login_state.dart';

class LoginByNamePage extends StatelessWidget {
  LoginByNamePage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state.status == LoginStatus.failure && state.error != null) {
              showTopSnackBar(
                context,
                message: state.error!,
                backgroundColor: Colors.red.shade700,
                icon: Icons.error_outline,
              );
            }
            if (state.status == LoginStatus.success) {
              getIt<ProductsSyncService>().initialSync();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (_) => false,
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
                      return Column(
                        children: [
                          LoginTextField(
                            label: 'Enter Your Name',
                            isObscure: false,
                            controller: emailController,
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email is required";
                              }
                              return null;
                            },
                            errorText: state.error,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(30.r),
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,

                                colors: [
                                  AppColor.primaryColor,
                                  AppColor.secondaryColor,
                                ],
                              ),
                            ),
                            child: MaterialButton(
                              minWidth: 300.w,
                              height: 50.h,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              onPressed: () {
                                final name = emailController.text.trim();
                                if (name.isEmpty) return;

                                context.read<LoginBloc>().add(
                                  NameLoginSubmitted(name),
                                );
                              },

                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 25.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  if (!state.isLoading) return const SizedBox();

                  return Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20.h),
                          Text(
                            state.message ?? "Loading...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
