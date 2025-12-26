import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../stock_taking_bloc/stock_taking_bloc.dart';
import '../stock_taking_bloc/stock_taking_event.dart';
import '../stock_taking_bloc/stock_taking_state.dart';

class DropDownUnitType extends StatelessWidget {
  const DropDownUnitType({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBloc, StockState>(
      builder: (context, state) {
        final baseUnits = state.units;
        final String? selectedUnit = state.selectedUnit;

        final List<String> units = baseUnits.isNotEmpty
            ? baseUnits
            : (selectedUnit != null ? [selectedUnit] : <String>[]);

        final String? selected =
            (selectedUnit != null && units.contains(selectedUnit))
            ? selectedUnit
            : null;

        return DropdownButtonFormField2<String>(
          value: selected,
          isExpanded: true,

          items: units
              .map(
                (u) => DropdownMenuItem<String>(
                  value: u,
                  child: Text(
                    u,
                    style: TextStyle(color: AppColor.secondaryColor),
                  ),
                ),
              )
              .toList(),

          onChanged: (value) {
            if (value != null) {
              context.read<StockBloc>().add(ChangeUnitEvent(value));
            }
          },

          dropdownStyleData: DropdownStyleData(
            width: 160.w,
            maxHeight: 220.h,
            elevation: 6,
            offset: const Offset(0, -6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),

          menuItemStyleData: MenuItemStyleData(
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
          ),

          decoration: InputDecoration(
            labelText: "Unit Type",
            labelStyle: TextStyle(
              color: AppColor.secondaryColor,
              fontWeight: FontWeight.w500,
            ),

            filled: true,
            fillColor: Colors.white,

            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 14.h,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: AppColor.secondaryColor,
                width: 1.2,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColor.primaryColor, width: 1.8),
            ),
          ),
        );
      },
    );
  }
}
