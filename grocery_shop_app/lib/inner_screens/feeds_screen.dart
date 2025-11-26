import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/products_model.dart';
import 'package:app/providers/products_provider.dart';
import 'package:app/widgets/feed_items.dart';
import 'package:app/widgets/back_widget.dart';
import 'package:app/widgets/empty_products_widget.dart';
import 'package:app/widgets/text_widget.dart';
import '../services/utils.dart';

class FeedsScreen extends StatefulWidget {
  static const routeName = "/FeedsScreenState";

  final List<ProductModel>? initialProducts;

  const FeedsScreen({this.initialProducts, Key? key}) : super(key: key);

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<ProductModel> listProductSearch = [];

  @override
  void dispose() {
    _searchTextController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final size = Utils(context).getScreenSize;

    final productProvider = Provider.of<ProductsProvider>(context);
    final List<ProductModel> allProducts =
        widget.initialProducts ?? productProvider.getProducts;

    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: TextWidget(
          text: "All Products",
          color: color,
          textSize: 20,
          isTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// SEARCH BOX
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                height: kBottomNavigationBarHeight,
                child: TextField(
                  focusNode: _searchFocus,
                  controller: _searchTextController,
                  onChanged: (value) {
                    setState(() {
                      listProductSearch = productProvider.searchQuery(value);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "What’s in your mind?",
                    prefixIcon: const Icon(Icons.search),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.greenAccent,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.greenAccent,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: _searchFocus.hasFocus ? Colors.red : color,
                      ),
                      onPressed: () {
                        _searchTextController.clear();
                        _searchFocus.unfocus();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            ),

            /// NO RESULT
            if (_searchTextController.text.isNotEmpty &&
                listProductSearch.isEmpty)
              const EmptyProdWidget(text: "No Products Found!")

            /// GRID VIEW
            else
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.zero,
                  childAspectRatio: size.width / (size.height * 0.54),
                  children: List.generate(
                    _searchTextController.text.isNotEmpty
                        ? listProductSearch.length
                        : allProducts.length,
                    (index) {
                      final product = _searchTextController.text.isNotEmpty
                          ? listProductSearch[index]
                          : allProducts[index];

                      return ChangeNotifierProvider.value(
                        value: product,
                        child: const FeedsWidget(),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
