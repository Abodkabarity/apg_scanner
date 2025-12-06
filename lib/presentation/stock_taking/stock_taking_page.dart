import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/barcode_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StockTakingPage extends StatelessWidget {
  StockTakingPage({super.key});
  final List<String> type = ["Box", "Strip"];
  final TextEditingController scanController = TextEditingController();

  String? selectItem;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset("assets/images/logo.png", fit: BoxFit.cover),
        ),
        title: Text(
          "Stock Taking App",
          style: TextStyle(
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.secondaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColor.primaryColor,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background2.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.r),
                    color: Color(0x1a4eb0de),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: TextField(
                      controller: scanController,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        labelText: "Scan Area",
                        labelStyle: TextStyle(color: AppColor.secondaryColor),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.r),
                          borderSide: BorderSide(color: AppColor.primaryColor),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.scanner,
                            color: AppColor.secondaryColor,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BarcodeScannerPage(),
                              ),
                            );

                            if (result != null) {
                              scanController.text = result;
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColor.primaryColor),
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.r),
                    color: Color(0x1a4eb0de),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            labelText: "Name",
                            labelStyle: TextStyle(
                              color: AppColor.secondaryColor,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.r),
                              borderSide: BorderSide(
                                color: AppColor.primaryColor,
                              ),
                            ),

                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColor.primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 30.h),
                        Row(
                          children: [
                            Expanded(flex: 2, child: _dropDownType()),
                            SizedBox(width: 10.w),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                  labelText: "Quantity",
                                  labelStyle: TextStyle(
                                    color: AppColor.secondaryColor,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                    borderSide: BorderSide(
                                      color: AppColor.primaryColor,
                                    ),
                                  ),

                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColor.primaryColor,
                                    ),
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25.h),
                        Row(
                          children: [
                            Expanded(
                              child: SubmitButton(
                                label: "Approve",
                                onPressed: () {},
                                icon: Icons.done,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: SubmitButton(
                                label: 'Delete',
                                onPressed: () {},
                                icon: Icons.delete,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 100.h, left: 50.w, right: 50.w),
                  child: SizedBox(
                    height: 60.h,
                    child: SubmitButton(
                      label: "Submit & Share",
                      onPressed: () {},
                      icon: Icons.save_alt,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DecoratedBox _dropDownType() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: BoxBorder.all(color: AppColor.secondaryColor),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: DropdownButton<String>(
          value: selectItem,
          isExpanded: true,
          focusColor: AppColor.primaryColor,
          underline: SizedBox(),
          hint: Text("Type", style: TextStyle(color: AppColor.secondaryColor)),
          selectedItemBuilder: (context) {
            return type.map((e) {
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      e,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_drop_down, color: Colors.black),
                  ],
                ),
              );
            }).toList();
          },

          iconSize: 25,
          items: type.map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
          }).toList(),

          onChanged: (value) {},
        ),
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final void Function()? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primaryColor,
        foregroundColor: AppColor.secondaryColor,
        shadowColor: AppColor.primaryColor,
        elevation: 10,
        side: BorderSide(color: AppColor.secondaryColor),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Text(label, style: TextStyle(fontSize: 18.sp)),
            ),
          ),
          Expanded(child: Icon(icon, color: AppColor.secondaryColor, size: 25)),
        ],
      ),
    );
  }
}
