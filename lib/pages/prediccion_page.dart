import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// Diccionario de traducciones
const Map<String, String> traducciones = {
  'Pepper__bell___Bacterial_spot': 'Pimiento morrón con mancha bacteriana',
  'Pepper__bell___healthy': 'Pimiento morrón sano',
  'Potato___Early_blight': 'Papa con tizón temprano',
  'Potato___Late_blight': 'Papa con tizón tardío',
  'Potato___healthy': 'Papa sana',
  'Tomato_Bacterial_spot': 'Tomate con mancha bacteriana',
  'Tomato_Early_blight': 'Tomate con tizón temprano',
  'Tomato_Late_blight': 'Tomate con tizón tardío',
  'Tomato_Leaf_Mold': 'Tomate con moho en la hoja',
  'Tomato_Septoria_leaf_spot': 'Tomate con mancha de Septoria',
  'Tomato_Spider_mites_Two_spotted_spider_mite': 'Tomate con ácaros',
  'Tomato__Target_Spot': 'Tomate con mancha diana',
  'Tomato__Tomato_YellowLeaf__Curl_Virus': 'Tomate con virus del rizado amarillo',
  'Tomato__Tomato_mosaic_virus': 'Tomate con virus del mosaico',
  'Tomato_healthy': 'Tomate sano',
};

class PrediccionPage extends StatefulWidget {
  @override
  _PrediccionPageState createState() => _PrediccionPageState();
}

class _PrediccionPageState extends State<PrediccionPage> {
  File? _image;
  String? _output = "";
  Interpreter? _interpreter;
  List<String>? _labels;

  final int imgSize = 128; // Debe coincidir con el tamaño usado al entrenar

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, loadModelAndLabels);
  }

  Future<void> loadModelAndLabels() async {
    _interpreter = await Interpreter.fromAsset('assets/models/modelo_transfer.tflite');
    // Cargar labels usando DefaultAssetBundle y contexto
    String rawLabels = await DefaultAssetBundle.of(context).loadString('assets/models/labels.txt');
    setState(() {
      _labels = rawLabels.split('\n').where((l) => l.isNotEmpty).toList();
    });
  }

  Future<void> classifyImage(File imageFile) async {
    setState(() {
      _output = "Procesando...";
    });

    // Leer y redimensionar la imagen
    final bytes = await imageFile.readAsBytes();
    img.Image? oriImage = img.decodeImage(bytes);
    img.Image resizedImage = img.copyResize(oriImage!, width: imgSize, height: imgSize);

    // Normaliza la imagen
    var input = List.generate(imgSize, (y) =>
      List.generate(imgSize, (x) {
        var pixel = resizedImage.getPixel(x, y);
        return [
          pixel.rNormalized,
          pixel.gNormalized,
          pixel.bNormalized,
        ];
      })
    );

    var inputTensor = [input];
    var outputTensor = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);

    _interpreter!.run(inputTensor, outputTensor);

    double maxScore = 0;
    int maxIndex = 0;
    for (int i = 0; i < _labels!.length; i++) {
      if (outputTensor[0][i] > maxScore) {
        maxScore = outputTensor[0][i];
        maxIndex = i;
      }
    }

    String etiquetaOriginal = _labels![maxIndex].trim();
    String etiquetaTraducida = traducciones[etiquetaOriginal] ?? etiquetaOriginal;

    setState(() {
      _output = "$etiquetaTraducida: ${(maxScore * 100).toStringAsFixed(2)}%";
    });
  }

  pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _image = File(pickedFile.path);
      _output = "";
    });
    await classifyImage(_image!);
  }

  captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    setState(() {
      _image = File(pickedFile.path);
      _output = "";
    });
    await classifyImage(_image!);
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reconocimiento de Plagas')),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            _image == null
                ? Text('Selecciona o toma una imagen')
                : Image.file(_image!, height: 300),
            SizedBox(height: 20),
            _output != null && _output != "" ? Text(_output!, style: TextStyle(fontSize: 20)) : Container(),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.photo),
                  label: Text('Galería'),
                  onPressed: pickImage,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.camera),
                  label: Text('Cámara'),
                  onPressed: captureImage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

