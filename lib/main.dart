import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}


class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera SQLite App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageListScreen(cameras: cameras),
    );
  }
}

class ImageListScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ImageListScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final images = await _databaseHelper.getImages();
    setState(() {
      _images = images;
    });
  }

  Future<void> _navigateToCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(cameras: widget.cameras),
      ),
    );

    if (result != null) {
      await _databaseHelper.insertImage(result);
      _loadImages(); // Reload images after inserting
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Imágenes'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: _navigateToCamera,
          ),
        ],
      ),
      body: _images.isEmpty
          ? Center(child: Text('No hay imágenes disponibles.'))
          : ListView.builder(
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                return Card(
                  child: ListTile(
                    leading: Image.file(
                      File(image['url']),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(image['url']),
                  ),
                );
              },
            ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      return image.path;
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final imagePath = await _takePicture();
          Navigator.pop(context, imagePath); // Regresar la ruta de la imagen
        },
        tooltip: 'Tomar Foto',
        child: Icon(Icons.camera),
      ),
    );
  }
}