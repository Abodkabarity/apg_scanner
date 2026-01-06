enum ProjectType { stockTaking, nearExpiry, stockBatch }

extension ProjectTypeX on ProjectType {
  String get label {
    switch (this) {
      case ProjectType.stockTaking:
        return 'Stock Taking';
      case ProjectType.nearExpiry:
        return 'Near Expiry';
      case ProjectType.stockBatch:
        return 'Stock Batch';
    }
  }

  String get dbValue {
    switch (this) {
      case ProjectType.stockTaking:
        return 'stock_taking';
      case ProjectType.nearExpiry:
        return 'near_expiry';
      case ProjectType.stockBatch:
        return 'products_with_batch';
    }
  }
}
