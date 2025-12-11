import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../data/model/stock_taking_model.dart';

class ShowItemsList extends StatelessWidget {
  const ShowItemsList({super.key, required this.onItemSelected});
  final Function(StockItemModel) onItemSelected;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBloc, StockState>(
      builder: (context, state) {
        return Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: const Color(0x1a4eb0de),
          ),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  context.read<StockBloc>().add(SearchScannedItemsEvent(value));
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  labelText: "Search Product Scanning",
                ),
              ),
              SizedBox(height: 10.h),

              SizedBox(
                height: 350.h,
                child: ListView.builder(
                  itemCount: state.filteredItems.length,
                  itemBuilder: (context, i) {
                    final items = state.filteredItems[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: state.selectedIndex == i
                              ? AppColor.secondaryColor
                              : Colors.white,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          items.itemName,
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        leading: Text(
                          items.unit,
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          "Qty ${items.quantity}",
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        onTap: () {
                          context.read<StockBloc>().add(
                            ChangeSelectedIndexEvent(i),
                          );

                          onItemSelected(items);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
