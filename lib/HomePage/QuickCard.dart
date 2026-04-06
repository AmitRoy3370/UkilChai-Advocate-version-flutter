import 'package:flutter/material.dart';

class QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    // মোবাইলের জন্য responsive ফন্ট সাইজ
    final double baseScale = screenWidth / 375; // 375 হল রেফারেন্স (ছোট মোবাইল)

    // বিভিন্ন স্ক্রিনের জন্য ফন্ট সাইজ ক্যালকুলেশন
    final double iconSize = isDesktop ? 48 : (screenWidth < 375 ? 28 : 32);
    final double titleSize = isDesktop ? 24 : (screenWidth < 375 ? 16 : 18);
    final double subtitleSize = isDesktop ? 15 : (screenWidth < 375 ? 11 : 12);
    final double padding = isDesktop ? 24 : (screenWidth < 375 ? 12 : 14);
    final double iconContainerPadding = screenWidth < 375 ? 8 : 10;

    // ডায়নামিক হাইট লাইন (মোবাইলের জন্য আরও কম্প্যাক্ট)
    final double titleHeight = isDesktop ? 1.3 : 1.2;
    final double subtitleHeight = isDesktop ? 1.4 : 1.35;

    // রেস্পন্সিভ স্পেসিং
    final double iconTitleSpacing = screenWidth < 375 ? 10 : 12;
    final double titleSubtitleSpacing = screenWidth < 375 ? 4 : 5;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.green.withOpacity(0.2),
        highlightColor: Colors.green.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: iconTitleSpacing),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: titleHeight,
                  // ছোট স্ক্রিনে টেক্সট ওভারফ্লো রোধ
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
              SizedBox(height: titleSubtitleSpacing),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey.shade700,
                  height: subtitleHeight,
                  letterSpacing: screenWidth < 375 ? 0.2 : 0.3, // ছোট স্ক্রিনে আরও রিডেবল
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}