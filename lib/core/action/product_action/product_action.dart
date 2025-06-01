import 'package:pos/data/api/item_data.dart' as item_data;
import 'package:pos/data/models/item_model.dart';

class ItemActions {
  static Future<List<Item>> getItemData(int limit, int start, String filters,
      String warehouse, String priceListGroup,
      {bool searchByCode = false, bool allowStock = true}) async {
    try {
      final response = await item_data.getItemData(limit, start, filters,
          searchByCode, warehouse, allowStock, priceListGroup);

      if (response == null || response['data'] == null) {
        return [];
      }
      final List<dynamic> itemsJson = response['data'];
      return itemsJson.map((json) => Item.fromJson(json)).toList();
    } catch (error) {
      print('Error: $error');
      throw Exception('Error fetching items: $error');
    }
  }
}
