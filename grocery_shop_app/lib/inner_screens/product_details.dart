import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:app/consts/firebase_const.dart';
import 'package:app/providers/cart_provider.dart';
import 'package:app/providers/products_provider.dart';
import 'package:app/providers/viewed_prod_provider.dart';
import 'package:app/providers/wishlist_provider.dart';
import 'package:app/services/global_methods.dart';
import 'package:app/services/logger_service.dart';
import 'package:app/services/recommendation_service.dart';
import 'package:app/widgets/heart_btn.dart';
import 'package:app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../models/products_model.dart';
import '../services/utils.dart';
import '../widgets/feed_items.dart'; // FeedsWidget

class ProductDetails extends StatefulWidget {
  static const routeName = '/ProductDetails';

  const ProductDetails({Key? key}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final _quantityTextController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Utils(context).getScreenSize;
    final color = Utils(context).color;

    final productId = ModalRoute.of(context)!.settings.arguments as String;
    final productsProvider = Provider.of<ProductsProvider>(context);
    final getCurrentProduct = productsProvider.findProById(productId);

    final usedPrice = getCurrentProduct.isOnSale
        ? getCurrentProduct.salePrice
        : getCurrentProduct.price;

    final totalPrice = usedPrice * int.parse(_quantityTextController.text);

    final cartProvider = Provider.of<CartProvider>(context);
    final bool isInCart =
        cartProvider.getCartItems.containsKey(getCurrentProduct.id);

    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final bool isInWishlist =
        wishlistProvider.getWishlistItems.containsKey(getCurrentProduct.id);

    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        viewedProdProvider.addProductToHistory(productId: productId);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                Navigator.canPop(context) ? Navigator.pop(context) : null,
            child: Icon(IconlyLight.arrowLeft2, color: color, size: 24),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Column(
          children: [
            // ==================== ẢNH SẢN PHẨM ====================
            SizedBox(
              height: size.height * 0.38,
              width: double.infinity,
              child: FancyShimmerImage(
                imageUrl: getCurrentProduct.imageUrl,
                boxFit: BoxFit.contain,
              ),
            ),

            // ==================== NỘI DUNG CHI TIẾT ====================
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    // Nội dung cuộn được
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          bottom: 110), // chừa chỗ cho thanh bottom
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề + Heart
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: TextWidget(
                                    text: getCurrentProduct.title,
                                    color: color,
                                    textSize: 24,
                                    isTitle: true,
                                    maxLines: 2,
                                  ),
                                ),
                                HeartBTN(
                                  productId: getCurrentProduct.id,
                                  isInWishlist: isInWishlist,
                                ),
                              ],
                            ),
                          ),

                          // Giá + Free delivery
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 20),
                            child: Row(
                              children: [
                                TextWidget(
                                  text: '\$${usedPrice.toStringAsFixed(2)}/',
                                  color: Colors.green,
                                  textSize: 24,
                                  isTitle: true,
                                ),
                                TextWidget(
                                  text: getCurrentProduct.isPiece
                                      ? 'Piece'
                                      : 'Kg',
                                  color: color,
                                  textSize: 14,
                                ),
                                const SizedBox(width: 10),
                                Visibility(
                                  visible: getCurrentProduct.isOnSale,
                                  child: Text(
                                    '\$${getCurrentProduct.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: color,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromRGBO(63, 200, 101, 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextWidget(
                                    text: 'Free delivery',
                                    color: Colors.white,
                                    textSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Nút tăng giảm số lượng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              quantityControl(
                                fct: () {
                                  if (_quantityTextController.text == '1')
                                    return;
                                  setState(() {
                                    _quantityTextController.text = (int.parse(
                                                _quantityTextController.text) -
                                            1)
                                        .toString();
                                  });
                                },
                                icon: CupertinoIcons.minus,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _quantityTextController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  style: const TextStyle(fontSize: 18),
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (v) {
                                    if (v.isEmpty)
                                      _quantityTextController.text = '1';
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              quantityControl(
                                fct: () {
                                  setState(() {
                                    _quantityTextController.text = (int.parse(
                                                _quantityTextController.text) +
                                            1)
                                        .toString();
                                  });
                                },
                                icon: CupertinoIcons.plus,
                                color: Colors.green,
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // "Được mua cùng với"
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: TextWidget(
                              text: "Được mua cùng với",
                              color: color,
                              textSize: 22,
                              isTitle: true,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Danh sách sản phẩm gợi ý
                          SizedBox(
                            height: 211,
                            child: FutureBuilder<List<ProductModel>>(
                              future: RecommendationService.getRelatedProducts(
                                getCurrentProduct.id,
                                productsProvider,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text("Không có sản phẩm gợi ý"));
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (ctx, i) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: SizedBox(
                                      width: 140,
                                      child: ChangeNotifierProvider.value(
                                        value: snapshot.data![i],
                                        child: const FeedsWidget(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                              height:
                                  140), // để thanh bottom không che nội dung
                        ],
                      ),
                    ),

                    // ==================== THANH TOTAL + ADD TO CART (cố định dưới cùng) ====================
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 30),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Total',
                                    color: Colors.red.shade300,
                                    textSize: 20,
                                    isTitle: true,
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    child: TextWidget(
                                      text:
                                          '\$${totalPrice.toStringAsFixed(2)} (${_quantityTextController.text}${getCurrentProduct.isPiece ? ' Piece' : ' Kg'})',
                                      color: color,
                                      textSize: 22,
                                      isTitle: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isInCart
                                    ? null
                                    : () async {
                                        final User? user =
                                            authInstance.currentUser;
                                        if (user == null) {
                                          GlobalMethods.errorDialog(
                                            subtitle:
                                                'Vui lòng đăng nhập trước!',
                                            context: context,
                                          );
                                          return;
                                        }

                                        await GlobalMethods.addToCart(
                                          productId: getCurrentProduct.id,
                                          quantity: int.parse(
                                              _quantityTextController.text),
                                          context: context,
                                        );

                                        await LoggerService.addImpression(
                                          eventType: "add_to_cart",
                                          productId: getCurrentProduct.id,
                                        );

                                        await cartProvider.fetchCart();
                                        setState(
                                            () {}); // để cập nhật nút "In Cart"
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 30),
                                  child: TextWidget(
                                    text: isInCart ? 'In Cart' : 'Add To Cart',
                                    color: Colors.white,
                                    textSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget quantityControl({
    required VoidCallback fct,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: fct,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
