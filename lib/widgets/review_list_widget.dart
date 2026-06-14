import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_config.dart';
import '../screens/product/product_detail_page.dart';

class ReviewListWidget extends StatelessWidget {
  final List<dynamic> reviews;

  const ReviewListWidget({super.key, required this.reviews});

  Widget _buildStars(int rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} bulan lalu';
      if (diff.inDays > 0) return '${diff.inDays} hari lalu';
      if (diff.inHours > 0) return '${diff.inHours} jam lalu';
      if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
      return 'Baru saja';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    double avgRating = 0.0;
    int reviewCount = reviews.length;
    Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    if (reviewCount > 0) {
      double totalStars = 0.0;
      for (var r in reviews) {
        final rating = r['rating'] as int? ?? 5;
        totalStars += rating;
        starCounts[rating] = (starCounts[rating] ?? 0) + 1;
      }
      avgRating = totalStars / reviewCount;
    } else {
      avgRating = 0.0;
      reviewCount = 0;
      starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    }

    final formattedAvg = avgRating.toStringAsFixed(1);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Top Rating Aggregate Card
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Score block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formattedAvg,
                          style: GoogleFonts.inter(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star,
                          color: Color(0xFF74070E),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$reviewCount ulasan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),

                // Rating distribution bars
                Expanded(
                  child: Column(
                    children: List.generate(5, (idx) {
                      final star = 5 - idx;
                      final count = starCounts[star] ?? 0;
                      final percentage = reviewCount > 0
                          ? count / reviewCount
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Text(
                              '$star',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 4,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF74070E),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),

          // Vertical list of reviews
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Belum ada ulasan untuk toko ini.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                bottom: 100,
                left: 16,
                right: 16,
                top: 16,
              ),
              itemCount: reviews.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final review = reviews[index];
                final reviewer = review['reviewer'] ?? {};
                final reviewerName =
                    reviewer['full_name'] ?? reviewer['username'] ?? 'User';
                final product = review['product'];

                // Get product image
                String productThumbnailUrl = '';
                if (product != null) {
                  final List<dynamic> images = product['image_paths'] is String
                      ? jsonDecode(product['image_paths'])
                      : (product['image_paths'] ?? []);
                  if (images.isNotEmpty) {
                    productThumbnailUrl = '${ApiConfig.host}${images[0]}';
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left / Main Content of Review
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildStars(review['rating'] ?? 5),
                                const SizedBox(width: 8),
                                Text(
                                  _formatRelativeTime(review['created_at']),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              review['comment'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(
                                    0xFF74070E,
                                  ).withOpacity(0.08),
                                  backgroundImage:
                                      reviewer['profile_picture'] != null
                                      ? NetworkImage(
                                          '${ApiConfig.host}/uploads/profiles/${reviewer['profile_picture']}',
                                        )
                                      : null,
                                  child: reviewer['profile_picture'] == null
                                      ? Text(
                                          reviewerName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF74070E),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 8,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  reviewerName,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right Thumbnail Image (Requirement: Click to navigate back to product detail)
                      if (product != null &&
                          productThumbnailUrl.isNotEmpty) ...[
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailPage(product: product),
                              ),
                            );
                          },
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.network(
                                productThumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.black26,
                                      size: 18,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
