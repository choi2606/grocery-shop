import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:grocery_admin_panel/services/cloudinary_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_admin_panel/controllers/MenuControllerr.dart';
import 'package:grocery_admin_panel/screens/loading_manager.dart';
import 'package:grocery_admin_panel/services/utils.dart';
import 'package:grocery_admin_panel/widgets/buttons.dart';
import 'package:grocery_admin_panel/widgets/header.dart';
import 'package:grocery_admin_panel/widgets/side_menu.dart';
import 'package:grocery_admin_panel/widgets/text_widget.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../responsive.dart';
import '../services/global_method.dart';

class UploadProductForm extends StatefulWidget {
  static const routeName = '/UploadProductForm';

  const UploadProductForm({Key? key}) : super(key: key);

  @override
  _UploadProductFormState createState() => _UploadProductFormState();
}

class _UploadProductFormState extends State<UploadProductForm> {
  final _formKey = GlobalKey<FormState>();
  String _catValue = 'Vegetables';
  late final TextEditingController _titleController, _priceController;
  int _groupValue = 1;
  bool isPiece = false;
  File? _pickedImage;
  Uint8List webImage = Uint8List(8);
  String? imageUrl;
  @override
  void initState() {
    _priceController = TextEditingController();
    _titleController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  void _uploadForm() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();

      // Better image validation for both web and mobile
      bool hasValidImage = false;
      if (kIsWeb) {
        hasValidImage = webImage.length > 8; // Default Uint8List(8) is empty
      } else {
        hasValidImage = _pickedImage != null;
      }

      if (!hasValidImage) {
        GlobalMethods.errorDialog(
            subtitle: 'Please pick up an image', context: context);
        return;
      }

      final _uuid = const Uuid().v4();
      try {
        setState(() {
          _isLoading = true;
        });

        print('=== Starting product upload ===');
        print('Product ID: $_uuid');
        print('Title: ${_titleController.text}');
        print('Price: ${_priceController.text}');
        print('Category: $_catValue');

        // Step 1: Upload image to Cloudinary
        print('[1/2] Starting image upload to Cloudinary...');
        try {
          imageUrl = await CloudinaryService.uploadProductImage(
            fileName: _uuid,
            webImageBytes: kIsWeb ? webImage : null,
            file: kIsWeb ? null : _pickedImage,
          );
          print('[1/2] ✓ Image uploaded to Cloudinary: $imageUrl');
        } catch (e) {
          print('[1/2] ✗ Image upload failed: $e');
          rethrow;
        }

        // Step 2: Save to Firestore
        print('[2/2] Saving product to Firestore...');
        try {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(_uuid)
              .set({
            'id': _uuid,
            'title': _titleController.text,
            'price': _priceController.text,
            'salePrice': 0.1,
            'imageUrl': imageUrl,
            'productCategoryName': _catValue,
            'isOnSale': false,
            'isPiece': isPiece,
            'createdAt': Timestamp.now(),
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore write timed out');
            },
          );
          print('[2/2] ✓ Product saved to Firestore successfully!');
        } catch (e) {
          print('[3/3] ✗ Failed to save to Firestore: $e');
          rethrow;
        }

        print('=== Product upload completed successfully ===');
        _clearForm();
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          Fluttertoast.showToast(
            msg: "Product uploaded successfully",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
          );
        }
      } on FirebaseException catch (error) {
        print('FirebaseException: ${error.code} - ${error.message}');
        print('Stack trace: ${error.stackTrace}');
        if (mounted) {
          GlobalMethods.errorDialog(
              subtitle:
                  'Firebase Error: ${error.code}\n${error.message ?? "Unknown error"}\n\nCommon causes:\n- Firebase Security Rules blocking writes\n- Network connectivity issues\n- Insufficient permissions',
              context: context);
        }
        setState(() {
          _isLoading = false;
        });
      } catch (error, stackTrace) {
        print('General Error: $error');
        print('Stack trace: $stackTrace');
        if (mounted) {
          GlobalMethods.errorDialog(
              subtitle: 'Error: $error', context: context);
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    isPiece = false;
    _groupValue = 1;
    _priceController.clear();
    _titleController.clear();
    setState(() {
      _pickedImage = null;
      webImage = Uint8List(8);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final _scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    Size size = Utils(context).getScreenSize;

    var inputDecoration = InputDecoration(
      filled: true,
      fillColor: _scaffoldColor,
      border: InputBorder.none,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 1.0,
        ),
      ),
    );
    return Scaffold(
      key: context.read<MenuControllerr>().getAddProductscaffoldKey,
      drawer: const SideMenu(),
      body: LoadingManager(
        isLoading: _isLoading,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              const Expanded(
                child: SideMenu(),
              ),
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 25,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Header(
                          fct: () {
                            context
                                .read<MenuControllerr>()
                                .controlAddProductsMenu();
                          },
                          title: 'Add product',
                          showTexField: false),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      width: size.width > 650 ? 650 : size.width,
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            TextWidget(
                              text: 'Product title*',
                              color: color,
                              isTitle: true,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            TextFormField(
                              controller: _titleController,
                              key: const ValueKey('Title'),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter a Title';
                                }
                                return null;
                              },
                              decoration: inputDecoration,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: FittedBox(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        TextWidget(
                                          text: 'Price in \$*',
                                          color: color,
                                          isTitle: true,
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: TextFormField(
                                            controller: _priceController,
                                            key: const ValueKey('Price \$'),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Price is missed';
                                              }
                                              return null;
                                            },
                                            inputFormatters: <TextInputFormatter>[
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'[0-9.]')),
                                            ],
                                            decoration: inputDecoration,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        TextWidget(
                                          text: 'Porduct category*',
                                          color: color,
                                          isTitle: true,
                                        ),
                                        const SizedBox(height: 10),
                                        // Drop down menu code here
                                        _categoryDropDown(),

                                        const SizedBox(
                                          height: 20,
                                        ),
                                        TextWidget(
                                          text: 'Measure unit*',
                                          color: color,
                                          isTitle: true,
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        // Radio button code here
                                        Row(
                                          children: [
                                            TextWidget(
                                              text: 'KG',
                                              color: color,
                                            ),
                                            Radio(
                                              value: 1,
                                              groupValue: _groupValue,
                                              onChanged: (valuee) {
                                                setState(() {
                                                  _groupValue = 1;
                                                  isPiece = false;
                                                });
                                              },
                                              activeColor: Colors.green,
                                            ),
                                            TextWidget(
                                              text: 'Piece',
                                              color: color,
                                            ),
                                            Radio(
                                              value: 2,
                                              groupValue: _groupValue,
                                              onChanged: (valuee) {
                                                setState(() {
                                                  _groupValue = 2;
                                                  isPiece = true;
                                                });
                                              },
                                              activeColor: Colors.green,
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                // Image to be picked code is here
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                        height: size.width > 650
                                            ? 350
                                            : size.width * 0.45,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: _pickedImage == null
                                            ? dottedBorder(color: color)
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: kIsWeb
                                                    ? Image.memory(webImage,
                                                        fit: BoxFit.fill)
                                                    : Image.file(_pickedImage!,
                                                        fit: BoxFit.fill),
                                              )),
                                  ),
                                ),
                                Expanded(
                                    flex: 1,
                                    child: FittedBox(
                                      child: Column(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _pickedImage = null;
                                                webImage = Uint8List(8);
                                              });
                                            },
                                            child: TextWidget(
                                              text: 'Clear',
                                              color: Colors.red,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {},
                                            child: TextWidget(
                                              text: 'Update image',
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  ButtonsWidget(
                                    onPressed: _clearForm,
                                    text: 'Clear form',
                                    icon: IconlyBold.danger,
                                    backgroundColor: Colors.red.shade300,
                                  ),
                                  ButtonsWidget(
                                    onPressed: () {
                                      _uploadForm();
                                    },
                                    text: 'Upload',
                                    icon: IconlyBold.upload,
                                    backgroundColor: Colors.blue,
                                  ),
                                ],
                              ),
                            )
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

  Future<void> _pickImage() async {
    if (!kIsWeb) {
      final ImagePicker _picker = ImagePicker();
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        var selected = File(image.path);
        setState(() {
          _pickedImage = selected;
        });
      } else {
        print('No image has been picked');
      }
    } else if (kIsWeb) {
      final ImagePicker _picker = ImagePicker();
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        var f = await image.readAsBytes();
        setState(() {
          webImage = f;
          _pickedImage = File('a');
        });
      } else {
        print('No image has been picked');
      }
    } else {
      print('Something went wrong');
    }
  }

  Widget dottedBorder({
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DottedBorder(
          dashPattern: const [6.7],
          borderType: BorderType.RRect,
          color: color,
          radius: const Radius.circular(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  color: color,
                  size: 50,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextButton(
                    onPressed: (() {
                      _pickImage();
                    }),
                    child: TextWidget(
                      text: 'Choose an image',
                      color: Colors.blue,
                    ))
              ],
            ),
          )),
    );
  }

  Widget _categoryDropDown() {
    final color = Utils(context).color;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          value: _catValue,
          onChanged: (value) {
            setState(() {
              _catValue = value!;
            });
            print(_catValue);
          },
          hint: const Text('Select a category'),
          items: const [
            DropdownMenuItem(
              child: Text(
                'Vegetables',
              ),
              value: 'Vegetables',
            ),
            DropdownMenuItem(
              child: Text(
                'Fruits',
              ),
              value: 'Fruits',
            ),
            DropdownMenuItem(
              child: Text(
                'Grains',
              ),
              value: 'Grains',
            ),
            DropdownMenuItem(
              child: Text(
                'Nuts',
              ),
              value: 'Nuts',
            ),
            DropdownMenuItem(
              child: Text(
                'Herbs',
              ),
              value: 'Herbs',
            ),
            DropdownMenuItem(
              child: Text(
                'Spices',
              ),
              value: 'Spices',
            )
          ],
        )),
      ),
    );
  }
}
