enum ProjectType { stockTaking, nearExpiry }

extension ProjectTypeX on ProjectType {
  String get label {
    switch (this) {
      case ProjectType.stockTaking:
        return 'Stock Taking';
      case ProjectType.nearExpiry:
        return 'Near Expiry';
    }
  }

  String get dbValue {
    switch (this) {
      case ProjectType.stockTaking:
        return 'stock_taking';
      case ProjectType.nearExpiry:
        return 'near_expiry';
    }
  }
}
