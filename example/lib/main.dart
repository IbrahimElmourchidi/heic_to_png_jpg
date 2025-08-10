import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  Uint8List? _heicData;
  Uint8List? _convertedData;
  String _status = 'Pick a HEIC file to start';
  bool _busy = false;
  int _quality = 80;
  int? _maxWidth;

  Future<void> _pickHeic() async {
    setState(() {
      _busy = true;
      _status = 'Picking file...';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['heic', 'heif'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        _heicData = result.files.single.bytes!;
        _convertedData = null;
        _status =
            'Loaded HEIC (${(_heicData!.length / (1024 * 1024)).toStringAsFixed(2)} MB)';
      } else {
        _status = 'No file selected';
      }
    } catch (e) {
      _status = 'Error picking file: $e';
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _convertToPng() async {
    if (_heicData == null) {
      setState(() {
        _status = 'Please pick a HEIC first';
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Converting to PNG...';
    });
    try {
      final output = await HeicConverter.convertToPNG(
          heicData: _heicData!, maxWidth: _maxWidth);
      setState(() {
        _convertedData = output;
        _status =
            'Converted to PNG (${(output.length / (1024 * 1024)).toStringAsFixed(2)} MB)';
      });
    } catch (e) {
      setState(() {
        _status = 'Conversion error: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _convertToJpg() async {
    if (_heicData == null) {
      setState(() {
        _status = 'Please pick a HEIC first';
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Converting to JPG...';
    });
    try {
      final output = await HeicConverter.convertToJPG(
        heicData: _heicData!,
        quality: _quality,
        maxWidth: _maxWidth,
      );
      setState(() {
        _convertedData = output;
        _status =
            'Converted to JPG (${(output.length / (1024 * 1024)).toStringAsFixed(2)} MB)';
      });
    } catch (e) {
      setState(() {
        _status = 'Conversion error: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    final image = _convertedData ?? _heicData;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _pickHeic,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pick HEIC'),
                ),
                ElevatedButton.icon(
                  onPressed: _busy || _heicData == null ? null : _convertToPng,
                  icon: const Icon(Icons.image),
                  label: const Text('Convert to PNG'),
                ),
                ElevatedButton.icon(
                  onPressed: _busy || _heicData == null ? null : _convertToJpg,
                  icon: const Icon(Icons.photo),
                  label: const Text('Convert to JPG'),
                ),

                // optional quality
                SizedBox(
                  width: 200,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Quality (only for JPG) ${_quality.toStringAsFixed(0)}%'),
                      Slider(
                        value: _quality.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: (value) {
                          setState(() {
                            _quality = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // optional max width
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Max Width'),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      setState(() {
                        _maxWidth = int.tryParse(value);
                        if (_maxWidth == 0) {
                          _maxWidth = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300)),
                child: image == null
                    ? const Center(child: Text('No image loaded'))
                    : Image.memory(image, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
