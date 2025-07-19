import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver Monitoring App',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: DriverMonitorApp(),
    ),
  );
}

class DriverMonitorApp extends StatefulWidget {
  @override
  _DriverMonitorAppState createState() => _DriverMonitorAppState();
}

class _DriverMonitorAppState extends State<DriverMonitorApp> {
  File? _videoFile;
  String _resultMessage = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<bool> _requestPermissions() async {
    var cameraStatus = await Permission.camera.status;
    var storageStatus = await Permission.storage.status;

    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    if (!storageStatus.isGranted) {
      storageStatus = await Permission.storage.request();
    }

    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  Future<void> _pickVideo(ImageSource source) async {
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      setState(() {
        _resultMessage = 'Permissions not granted';
      });
      return;
    }

    final pickedFile = await _picker.pickVideo(source: source);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _resultMessage = '';
      });
      await _sendVideoToModel(_videoFile!);
    } else {
      setState(() {
        _resultMessage = 'No video selected';
      });
    }
  }

  Future<void> _sendVideoToModel(File video) async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.105.153:5000/api/predict'),
      );
      request.files.add(await http.MultipartFile.fromPath('video', video.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(respStr);
        bool distracted = jsonResponse['distracted'];

        setState(() {
          _resultMessage =
              distracted
                  ? 'Driver is Distracted!'
                  : 'Driver is Driving Normally.';
        });
      } else {
        setState(() {
          _resultMessage =
              'Failed to process video. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(text, style: TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(title: Text('Driver Monitoring'), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Icon(Icons.car_crash, size: 80, color: Colors.indigo),
                SizedBox(height: 10),
                Text(
                  'Analyze Driver Alertness',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),

                _buildActionButton(
                  'Record Video',
                  Icons.videocam,
                  () => _pickVideo(ImageSource.camera),
                ),
                SizedBox(height: 16),
                _buildActionButton(
                  'Upload from Gallery',
                  Icons.video_library,
                  () => _pickVideo(ImageSource.gallery),
                ),

                SizedBox(height: 30),

                if (_videoFile != null)
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            'Selected Video:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            _videoFile!.path,
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 20),

                if (_isLoading)
                  CircularProgressIndicator()
                else if (_resultMessage.isNotEmpty)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _resultMessage.contains('Distracted')
                              ? Colors.red[100]
                              : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _resultMessage,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            _resultMessage.contains('Distracted')
                                ? Colors.red[800]
                                : Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
