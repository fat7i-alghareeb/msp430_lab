import 'package:flutter/material.dart';
import 'app_icon_source.dart';

class AppAffixes {
  const AppAffixes({
    this.prefixIcon,
    this.suffixIcon,
    this.onPrefixTap,
    this.onSuffixTap,
  });

  final IconSource? prefixIcon;
  final IconSource? suffixIcon;
  final VoidCallback? onPrefixTap;
  final VoidCallback? onSuffixTap;
}
