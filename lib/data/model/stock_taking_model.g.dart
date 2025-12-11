// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_taking_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockItemModelAdapter extends TypeAdapter<StockItemModel> {
  @override
  final int typeId = 5;

  @override
  StockItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockItemModel(
      id: fields[0] as String,
      projectId: fields[1] as String,
      branchName: fields[2] as String,
      itemId: fields[3] as String,
      itemCode: fields[4] as String,
      itemName: fields[5] as String,
      unit: fields[6] as String,
      subUnit: fields[7] as String,
      quantity: fields[8] as int,
      subQuantity: fields[9] as num,
      barcode: fields[10] as String,
      isDeleted: fields[11] as bool,
      isSynced: fields[12] as bool,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StockItemModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.branchName)
      ..writeByte(3)
      ..write(obj.itemId)
      ..writeByte(4)
      ..write(obj.itemCode)
      ..writeByte(5)
      ..write(obj.itemName)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.subUnit)
      ..writeByte(8)
      ..write(obj.quantity)
      ..writeByte(9)
      ..write(obj.subQuantity)
      ..writeByte(10)
      ..write(obj.barcode)
      ..writeByte(11)
      ..write(obj.isDeleted)
      ..writeByte(12)
      ..write(obj.isSynced)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
