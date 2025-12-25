import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../near_expiry_bloc/near_expiry_bloc.dart';
import '../near_expiry_bloc/near_expiry_event.dart';
import '../near_expiry_bloc/near_expiry_state.dart';

class NearExpiryDropDownUnitType extends StatelessWidget {
  const NearExpiryDropDownUnitType({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearExpiryBloc, NearExpiryState>(
      buildWhen: (prev, curr) =>
          prev.units != curr.units || prev.selectedUnit != curr.selectedUnit,
      builder: (context, state) {
        final List<String> baseUnits = state.units;

        final String? selectedUnit = state.selectedUnit;

        final List<String> units = baseUnits.isNotEmpty
            ? baseUnits
            : (selectedUnit != null ? [selectedUnit] : <String>[]);

        final String? selected =
            (selectedUnit != null && units.contains(selectedUnit))
            ? selectedUnit
            : null;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColor.secondaryColor),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text(
                "Unit Type",
                style: TextStyle(color: AppColor.secondaryColor),
              ),
              items: units.map((unit) {
                return DropdownMenuItem<String>(value: unit, child: Text(unit));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  context.read<NearExpiryBloc>().add(ChangeUnitEvent(value));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
