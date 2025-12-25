// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'near_expiry_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NearExpiryItemModelAdapter extends TypeAdapter<NearExpiryItemModel> {
  @override
  final int typeId = 6;

  @override
  NearExpiryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NearExpiryItemModel(
      id: fields[0] as String,
      projectId: fields[1] as String,
      projectName: fields[2] as String,
      branchName: fields[3] as String,
      barcode: fields[4] as String,
      itemCode: fields[5] as String,
      itemName: fields[6] as String,
      unitType: fields[7] as String,
      quantity: fields[8] as int,
      nearExpiry: fields[9] as DateTime,
      isDeleted: fields[10] as bool,
      isSynced: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NearExpiryItemModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.projectName)
      ..writeByte(3)
      ..write(obj.branchName)
      ..writeByte(4)
      ..write(obj.barcode)
      ..writeByte(5)
      ..write(obj.itemCode)
      ..writeByte(6)
      ..write(obj.itemName)
      ..writeByte(7)
      ..write(obj.unitType)
      ..writeByte(8)
      ..write(obj.quantity)
      ..writeByte(9)
      ..write(obj.nearExpiry)
      ..writeByte(10)
      ..write(obj.isDeleted)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearExpiryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
