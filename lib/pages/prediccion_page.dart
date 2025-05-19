import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// Diccionario de traducciones
const Map<String, String> traducciones = {
  "healthy": "Hoja sana",
  "early_blight": "Tizón temprano",
  "late_blight": "Tizón tardío",
  "bacterial_spot": "Mancha bacteriana",
  "mosaic_virus": "Virus mosaico",
  "yellowleaf_curl_virus": "Virus de enrollamiento y amarilleo",
  "leaf_mold": "Moho de la hoja",
  "septoria_leaf_spot": "Mancha foliar de Septoria",
  "spider_mites": "Ácaros (araña roja)",
  "target_spot": "Mancha de diana",
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
    _interpreter = await Interpreter.fromAsset('assets/models/modelo_general.tflite');
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

    String etiquetaOriginal = (_labels != null && _labels!.isNotEmpty)
        ? _labels![maxIndex].trim()
        : "desconocido";
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

