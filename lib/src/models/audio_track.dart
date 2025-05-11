class AudioTrack {
  final String id;
  final String title;
  final String subtitle;
  final String audioUrl;
  final String imageUrl;
  final Duration duration;
  final String? description;

  AudioTrack(
      {required this.id,
      required this.title,
      required this.subtitle,
      required this.audioUrl,
      required this.imageUrl,
      required this.duration,
      this.description});

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
  id: json['id'].toString(),
      title: json['title'] ?? json['name'] ?? '',
      subtitle: json['subtitle'] ?? json['duration'] ?? '',
      audioUrl: json['audioUrl'] ?? json['location_url'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      duration: _parseDuration(json['duration'] ?? '0:00'),
      description: json['description'],
    );
  }

  static Duration _parseDuration(String duration) {
    final parts = duration.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    } else if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
    return Duration.zero;
  }
}
