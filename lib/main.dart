import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'BOOKMARK.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences? prefs;

  const MyApp({Key? key,  this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Video Companion',
      theme: ThemeData(
        primarySwatch: Colors.red, // Adjust theme colors as desired
      ),
      home: MyHomePage(prefs: prefs),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final SharedPreferences? prefs;

  const MyHomePage({Key? key,  this.prefs}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _url = '';
  String _title = '';
  String _thumbnailUrl = '';
  List<String> _bookmarkedVideos = []; // List to store bookmarked URLs
  String _errorMessage = '';

  static const String _youtubeApiUrl = 'https://www.googleapis.com/youtube/v3/videos';

  Future<void> _fetchVideoInfo(String url) async {
    try {
      final response = await http.get(Uri.parse(
          '<span class="math-inline">\_youtubeApiUrl?part\=snippet&id\=</span>{getUrlId(url)}&key=YOUR_API_KEY'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        if (items.isNotEmpty) {
          final videoData = items[0];
          setState(() {
            _title = videoData['snippet']['title'] as String;
            _thumbnailUrl =
            videoData['snippet']['thumbnails']['default']['url'] as String;
            _errorMessage = ''; // Clear previous error
          });
        } else {
          setState(() {
            _errorMessage = 'Video not found or API key invalid.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error fetching video information.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error: $error';
      });
    }
  }

  String getUrlId(String url) {
    final uri = Uri.parse(url);
    final queryParameters = uri.queryParameters;
    return queryParameters['v'] ?? ''; // Extract video ID from URL
  }

  void _launchVideo(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch YouTube app'),
        ),
      );
    }
  }

  void _toggleBookmark(String url) async {
    final prefs = widget.prefs;
    final bookmarkedVideos = prefs?.getStringList('bookmarkedVideos') ?? [];
    if (bookmarkedVideos.contains(url)) {
      bookmarkedVideos.remove(url);
    } else {
      bookmarkedVideos.add(url);
    }
    await prefs?.setStringList('bookmarkedVideos', bookmarkedVideos);
    _updateBookmarkedVideos();
  }

  void _updateBookmarkedVideos() async {
    final prefs = widget.prefs;
    final bookmarkedVideos = prefs?.getStringList('bookmarkedVideos') ?? [];
    setState(() {
      _bookmarkedVideos = bookmarkedVideos;
    });
  }

  @override
  void initState() {
    super.initState();
    _updateBookmarkedVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YouTube Video Companion'),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                      BookmarksPage(bookmarkedVideos: _bookmarkedVideos)),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView( // Ensures content scrolls on smaller screens
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Left-align content
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter YouTube Video URL',
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
              onChanged: (value) => setState(() => _url = value),
              textInputAction: TextInputAction.done, // Hide keyboard on "Done"
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () => _fetchVideoInfo(_url),
              child: Text('Find Video'),
            ),
            if (_title.isNotEmpty)
              SizedBox(height: 10.0),
            if (_title.isNotEmpty)
              Text(
                _title,
                style: TextStyle(fontSize: 18.0),
              ),
            if (_thumbnailUrl.isNotEmpty)
              SizedBox(height: 10.0),
            if (_thumbnailUrl.isNotEmpty)
              Image.network(_thumbnailUrl),
            if (_errorMessage.isEmpty)
              SizedBox(height: 10.0),
            if (_errorMessage.isEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchVideo(_url),
                    child: Text('Open on YouTube'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}