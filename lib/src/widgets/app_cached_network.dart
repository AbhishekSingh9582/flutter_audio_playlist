import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_audio_playlist/src/widgets/rectagular_shimmer.dart';

class AppCachedNetworkImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit? fit;

  const AppCachedNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fit: fit ?? BoxFit.fill,
      imageUrl: url,
      height: height,
      width: width,
      placeholder: (context, url) => RectangularShimmer(
        height: height ?? 171,
        width: width ?? 171,
      ),
      errorWidget: (context, url, error) => const SizedBox(
        height: 171,
        width: 171,
        child: Icon(Icons.error),
      ),
    );
  }
}
