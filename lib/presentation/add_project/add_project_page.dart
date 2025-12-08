import 'package:apg_scanner/presentation/stock_taking/stock_taking_page.dart';
import 'package:apg_scanner/presentation/widgets/background_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_color/app_color.dart';
import '../../core/app_images/app_images.dart';

class AddProjectPage extends StatelessWidget {
  const AddProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Projects",
          style: TextStyle(
            color: AppColor.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset(AppImages.logo, fit: BoxFit.cover),
        ),
        backgroundColor: AppColor.primaryColor,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          BackGroundWidget(),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          "Project1",
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: Text(
                          "1",
                          style: TextStyle(color: AppColor.secondaryColor),
                        ),
                        trailing: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.delete,
                            color: AppColor.secondaryColor,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StockTakingPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 200.h),
                child: MaterialButton(
                  onPressed: () {},
                  minWidth: 200.w,
                  height: 50.h,
                  color: AppColor.primaryColor,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColor.secondaryColor),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Add Project",
                        style: TextStyle(
                          color: AppColor.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(Icons.add, size: 25),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
