import 'package:flutter/material.dart';
import 'package:app/services/utils.dart';
import 'package:app/widgets/categories_widget.dart';
import 'package:app/widgets/text_widget.dart';

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({Key? key}) : super(key: key);

  List<Color> gridColors = [
    const Color(0xff53B175),
    const Color(0xffF8A44C),
    const Color(0xffF7A593),
    const Color(0xffD3B0E0),
    const Color(0xffFDE598),
    const Color(0xffB7DFF5),
  ];

  List<Map<String, dynamic>> catInfo = [
    {
      'imgPath': 'assets/images/cat/anlien.png',
      'catText': 'anlien',
      'catTitle': 'Th.Phẩm Ăn Liền',
    },
    {
      'imgPath': 'assets/images/cat/chebien.png',
      'catText': 'chebien',
      'catTitle': 'Th.Phẩm Chế Biến',
    },
    {
      'imgPath': 'assets/images/cat/donglanh.png',
      'catText': 'donglanh',
      'catTitle': 'Th.Phẩm Đông Lạnh',
    },
    {
      'imgPath': 'assets/images/cat/giavi.png',
      'catText': 'giavi',
      'catTitle': 'Gia Vị',
    },
    {
      'imgPath': 'assets/images/cat/raucu.png',
      'catText': 'raucu',
      'catTitle': 'Rau Củ Quả',
    },
    {
      'imgPath': 'assets/images/cat/trungdauhu.png',
      'catText': 'trungdauhu',
      'catTitle': 'Trứng - Đậu Hủ',
    },
  ];
  @override
  Widget build(BuildContext context) {
    final utils = Utils(context);
    Color color = utils.color;
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: TextWidget(
            text: 'Categories',
            color: color,
            textSize: 24,
            isTitle: true,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 240 / 250,
            crossAxisSpacing: 10, // Vertical spacing
            mainAxisSpacing: 10, // Horizontal spacing
            children: List.generate(6, (index) {
              return CategoriesWidget(
                catText: catInfo[index]['catText'],
                catTitle: catInfo[index]['catTitle'],
                imgPath: catInfo[index]['imgPath'],
                passedColor: gridColors[index],
              );
            }),
          ),
        ));
  }
}
