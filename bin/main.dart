// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Returns the URL for fetching a given video's metadata.
String _getMetadataUrl(String videoId) =>
    'https://api.twitch.tv/kraken/videos/$videoId';

/// Returns the URL for fetching 30 seconds of chat transcript of the given
/// video starting from the given timestamp.
String _getTranscriptUrl(String videoId, int timestamp) =>
    'https://rechat.twitch.tv/rechat-messages?start=$timestamp&video_id=$videoId';

/// Fetches and parses JSON data from the given URL.
Future<dynamic> _getJson(String url) async =>
    JSON.decode((await http.get(url)).body);

main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: fetch_transcript <video_id>');
    exit(314);
  }
  final videoId = args[0];

  // Get the video's metadata to know its start time and total length.
  final metadata = await _getJson(_getMetadataUrl(videoId));
  final startData = metadata['recorded_at'];
  final lengthSeconds = metadata['length'];
  final startTimestamp = (DateTime.parse(startData).millisecondsSinceEpoch /
          Duration.MILLISECONDS_PER_SECOND)
      .round();
  final endTimestamp = startTimestamp + lengthSeconds;

  // Fetch and print transcript by chunks of 30 seconds.
  int timestamp = startTimestamp;
  while (timestamp < endTimestamp) {
    final json = await _getJson(_getTranscriptUrl(videoId, timestamp));
    final List<Map> data = json['data'];
    if (data != null && data.isNotEmpty) {
      data.map((message) => message['attributes']).forEach((Map attributes) {
        final date =
            new DateTime.fromMillisecondsSinceEpoch(attributes['timestamp']);
        final from = attributes['from'];
        final message = attributes['message'];
        print('$date $from: $message');
      });
    }
    timestamp += 30;
  }
}
