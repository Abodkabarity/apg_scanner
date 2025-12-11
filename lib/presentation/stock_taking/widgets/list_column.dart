import 'package:flutter/material.dart';

class ListColumn extends StatelessWidget {
  const ListColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      /* children: state.filteredItems
          .map(
            (e) => Card(
          child: ListTile(
            title: Text(
              e.itemName,
              style: TextStyle(
                color: AppColor.secondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
            leading: Text(
              e.unit,
              style: TextStyle(
                color: AppColor.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Text(
              "Qty ${e.quantity}",
              style: TextStyle(
                color: AppColor.secondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
          ),
        ),
      )
          .toList(),
    ),;*/
    );
  }
}
