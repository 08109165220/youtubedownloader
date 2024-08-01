import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
class BookmarksPage extends StatefulWidget {
  final List<String> bookmarkedVideos;

  const BookmarksPage({Key? key, required this.bookmarkedVideos}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks'),
      ),
      body: ListView.builder(
        itemCount: widget.bookmarkedVideos.length,
        itemBuilder: (context, index) {
          final url = widget.bookmarkedVideos[index];
          return ListTile(
            title: Text(url), // Consider fetching video titles from YouTube API
            onTap: () => _launchVideo(url),
          );
        },
      ),
    );
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
}
