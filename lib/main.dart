import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const PhotonExodusApp());
}

class PhotonExodusApp extends StatelessWidget {
  const PhotonExodusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Loom',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Deep black
      ),
      home: const LoomInterface(),
    );
  }
}

class LoomInterface extends StatefulWidget {
  const LoomInterface({super.key});

  @override
  State<LoomInterface> createState() => _LoomInterfaceState();
}

class _LoomInterfaceState extends State<LoomInterface> {
  String statusMessage = "Upload an architectural drawing to begin.";
  String extractedSheet = "";
  bool isProcessing = false;

  // REPLACE THIS with your specific Railway URL from Phase 1, Step 4
  final String railwayUrl = 'https://loom-brain-python-production-8d9d.up.railway.app';

  Future<void> processDrawing() async {
    // 1. Pick the PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Necessary for web uploads
    );

    if (result != null) {
      setState(() {
        isProcessing = true;
        statusMessage = "Analyzing title block...";
        extractedSheet = "";
      });

      try {
        // 2. Prepare the request to your Python "Brain"
        var request = http.MultipartRequest('POST', Uri.parse(railwayUrl));
        
        // Add the file bytes
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          result.files.first.bytes!,
          filename: result.files.first.name,
        ));

        // 3. Send and wait for the result
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (response.statusCode == 200) {
          setState(() {
            extractedSheet = jsonResponse['extracted_sheet'];
            statusMessage = "Analysis Complete.";
          });
        } else {
          setState(() => statusMessage = "Error: Brain could not read file.");
        }
      } catch (e) {
        setState(() => statusMessage = "Connection failed. Check Railway status.");
      } finally {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "PHOTON EXODUS",
                style: TextStyle(fontSize: 12, letterSpacing: 4, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 10),
              const Text(
                "PROJECT LOOM",
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              if (isProcessing) 
                const CircularProgressIndicator(color: Colors.cyanAccent)
              else
                ElevatedButton(
                  onPressed: processDrawing,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("UPLOAD DRAWING", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 30),
              Text(statusMessage, style: const TextStyle(color: Colors.white70)),
              if (extractedSheet.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("IDENTIFIED SHEET:", style: TextStyle(fontSize: 14, color: Colors.cyanAccent)),
                Text(
                  extractedSheet,
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
