import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:ui' as ui;

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Заголовок",
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 34, 34, 255)),
        ),
        home: const MyHomePage(title: 'Заголовок'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? controller;
  int cameraNum = 1;
  String imagePath = "";
  img.Image? alteredImage;
  ui.Image? alteredUiImage;
  String someText = "";
  int posX = 350;
  int posY = 700;
  int angle = 0;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras![1], ResolutionPreset.max);
    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  void applyTatoo() async {
    final tatooFile = await rootBundle.load('assets/images/tatoo-1.png');
    img.Image tattoo = img.decodePng(tatooFile.buffer
        .asUint8List(tatooFile.offsetInBytes, tatooFile.lengthInBytes))!;

    if (angle != 0) {
      tattoo = img.copyRotate(tattoo, angle: angle);
    }

    final bytes = await File(imagePath).readAsBytes();
    final img.Image photo = img.decodeImage(bytes)!;
    alteredImage = img.compositeImage(photo, tattoo, dstX: posX, dstY: posY);

    alteredUiImage = (await convertImageToFlutterUi(alteredImage!));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Тестовий заголовок')),
        body: Container(
            padding: const EdgeInsets.only(left: 30, top: 10),
            child: Row(children: [
              Column(children: [
                Row(children: [
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          final image = await controller!.takePicture();
                          alteredUiImage = null;
                          imagePath = image.path;
                          setState(() {});
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: const Text("Зробити фото")),
                  ElevatedButton(
                      onPressed: () async {
                        cameraNum = 1 - cameraNum;
                        controller = CameraController(
                            cameras![cameraNum], ResolutionPreset.max);
                        controller?.initialize().then((_) {
                          if (!mounted) {
                            return;
                          }
                          setState(() {});
                        });
                        setState(() {});
                      },
                      child: const Text("Змінити камеру"))
                ]),
                Row(children: [
                  SizedBox(
                      width: 180,
                      height: 300,
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: CameraPreview(controller!),
                      )),
                  if (alteredUiImage != null)
                    SizedBox(
                        width: 200,
                        height: 300,
                        child: RawImage(image: alteredUiImage!))
                  else if (imagePath != "")
                    SizedBox(
                        width: 200,
                        height: 300,
                        child: Image.file(
                          File(imagePath),
                        ))
                ]),
                Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: ElevatedButton(
                        onPressed: applyTatoo,
                        child: const Text("Накласти тату"))),
                Row(children: [
                  ElevatedButton(
                      onPressed: () {
                        posX -= 50;
                        applyTatoo();
                      },
                      child: const Text("<<")),
                  Column(children: [
                    ElevatedButton(
                        onPressed: () {
                          posY -= 50;
                          applyTatoo();
                        },
                        child: const Text("Вгору")),
                    ElevatedButton(
                        onPressed: () {
                          posY += 50;
                          applyTatoo();
                        },
                        child: const Text("Вниз"))
                  ]),
                  ElevatedButton(
                      onPressed: () {
                        posX += 50;
                        applyTatoo();
                      },
                      child: const Text(">>")),
                ]),
                ElevatedButton(
                    onPressed: () {
                      angle += 10;
                      applyTatoo();
                    },
                    child: const Text("Повернути"))
              ])
            ])));
  }
}

Future<ui.Image> convertImageToFlutterUi(img.Image image) async {
  if (image.format != img.Format.uint8 || image.numChannels != 4) {
    final cmd = img.Command()
      ..image(image)
      ..convert(format: img.Format.uint8, numChannels: 4);
    final rgba8 = await cmd.getImageThread();
    if (rgba8 != null) {
      image = rgba8;
    }
  }

  ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

  ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
      height: image.height,
      width: image.width,
      pixelFormat: ui.PixelFormat.rgba8888);

  ui.Codec codec = await id.instantiateCodec(
      targetHeight: image.height, targetWidth: image.width);

  ui.FrameInfo fi = await codec.getNextFrame();
  ui.Image uiImage = fi.image;

  return uiImage;
}
