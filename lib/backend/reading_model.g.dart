// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingEntryAdapter extends TypeAdapter<ReadingEntry> {
  @override
  final int typeId = 0;

  @override
  ReadingEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingEntry(
      surah: fields[0] as int,
      verse: fields[1] as int,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.surah)
      ..writeByte(1)
      ..write(obj.verse)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
