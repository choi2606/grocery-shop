import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/providers/products_provider.dart';
import 'package:app/models/products_model.dart';

class RecommendationService {
  static const String baseUrl = "http://10.0.2.2:6969";

  static Future<List<ProductModel>> getRecommended(String userId) async {
    final url = Uri.parse("$baseUrl/recommend?user_id=$userId&num=6");

    final response = await http.get(url);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final ids = List<String>.from(data["product_ids"] ?? []);

    final productsProvider = ProductsProvider();
    await productsProvider.fetchProducts();

    return ids.map((id) => productsProvider.findProById(id)).toList();
  }

  static Future<List<ProductModel>> getRelatedProducts(
    String productId,
    ProductsProvider productsProvider,
  ) async {
    final url = Uri.parse("$baseUrl/recommend/related?product_id=$productId");

    final response = await http.get(url);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final ids = List<String>.from(data["product_ids"] ?? []);

    // Không fetch lại sản phẩm (đã load ở Home từ trước)
    return ids
        .map((id) => productsProvider.findProById(id))
        .where((item) => item != null)
        .cast<ProductModel>()
        .toList();
  }
}
