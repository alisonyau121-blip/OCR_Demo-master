// // import 'package:flutter/material.dart';
// // import 'package:id_ocr_kit/id_ocr_kit.dart';

// // void main() {
// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   // This widget is the root of your application.
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Library Test',
// //       theme: ThemeData(
      
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //       ),
// //       home: const MyHomePage(title: 'Test OCR'),
// //               onPressed: () async {
// //               final ocr = IdRecognitionService(MlKitOcrAdapter());
// //                             final result = await ocr.recognizeId(Uint8List(0));

// //               print(result);
// //             },
// //     );
// //   }
// // }

// // class MyHomePage extends StatefulWidget {
// //   const MyHomePage({super.key, required this.title});

 

// //   final String title;

// //   @override
// //   State<MyHomePage> createState() => _MyHomePageState();
// // }

// // class _MyHomePageState extends State<MyHomePage> {
// //   int _counter = 0;

// //   void _incrementCounter() {
// //     setState(() {
      
// //       _counter++;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
    
// //     return Scaffold(
// //       appBar: AppBar(
        
// //         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        
// //         title: Text(widget.title),
// //       ),
// //       body: Center(
       
// //         child: Column(
         
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: <Widget>[
// //             const Text('You have pushed the button this many times:'),
// //             Text(
// //               '$_counter',
// //               style: Theme.of(context).textTheme.headlineMedium,
// //             ),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _incrementCounter,
// //         tooltip: 'Increment',
// //         child: const Icon(Icons.add),
// //       ), // This trailing comma makes auto-formatting nicer for build methods.
// //     );
// //   }
// // }

// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:id_ocr_kit/id_ocr_kit.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Library Test',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Test OCR'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   String output = "Press the button to test OCR";

//   Future<void> _testOcr() async {
//   final ocr = IdRecognitionService(
//     ocrProvider: MlKitOcrAdapter(),  
//   );
//     final result = await ocr.recognizeId(Uint8List(0));

//     setState(() {
//       output = result.toString();
//     });

//     print(result);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Text(
//           output,
//           textAlign: TextAlign.center,
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _testOcr,
//         tooltip: 'Test OCR',
//         child: const Icon(Icons.camera_alt),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ID OCR Kit Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ID OCR Kit Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String output = "Tap the camera button to scan an ID document";
  bool isLoading = false;
  File? selectedImage;

  // Create OCR service with ML Kit adapter
  late final IdRecognitionService _ocrService;

  @override
  void initState() {
    super.initState();
    _ocrService = IdRecognitionService(
      ocrProvider: MlKitOcrAdapter(),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndScanImage() async {
    try {
      setState(() {
        isLoading = true;
        output = "Picking image...";
      });

      // Pick image from gallery or camera
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, // Change to .camera for camera
        imageQuality: 100,
      );

      if (image == null) {
        setState(() {
          output = "No image selected";
          isLoading = false;
        });
        return;
      }

      final File imageFile = File(image.path);
      
      setState(() {
        selectedImage = imageFile;
        output = "Processing image...";
      });

      // Perform OCR
      final result = await _ocrService.recognizeId(imageFile);

      // Display results
      if (result.isSuccess && result.hasIds) {
        final buffer = StringBuffer();
        buffer.writeln('✅ Found ${result.idCount} ID(s):');
        buffer.writeln();
        
        for (final id in result.parsedIds!) {
          buffer.writeln('📄 ${id.type}');
          buffer.writeln('Valid: ${id.isValid ? "✓" : "✗"}');
          buffer.writeln();
          
          id.fields.forEach((key, value) {
            buffer.writeln('  $key: $value');
          });
          buffer.writeln('---');
        }
        
        setState(() {
          output = buffer.toString();
          isLoading = false;
        });
      } else if (result.isSuccess && !result.hasIds) {
        setState(() {
          output = "✓ OCR completed\n\nNo ID documents found in image.\n\nRaw text:\n${result.rawText ?? '(empty)'}";
          isLoading = false;
        });
      } else {
        setState(() {
          output = "❌ Error: ${result.error}\nType: ${result.errorType}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        output = "❌ Unexpected error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  selectedImage!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isLoading
                    ? const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing...'),
                        ],
                      )
                    : SelectableText(
                        output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : _pickAndScanImage,
        tooltip: 'Pick and scan ID',
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan ID'),
      ),
    );
  }
}
