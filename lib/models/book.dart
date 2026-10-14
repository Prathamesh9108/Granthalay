import 'package:flutter/material.dart';

class Book {
  final String id;
  final String bookCode;
  final String titleMr;
  final String titleEn;
  final String authorMr;
  final String authorEn;
  final String category;
  final String isbn;
  final String publisher;
  final int publicationYear;
  final int totalCopies;
  final int availableCopies;

  const Book({
    required this.id,
    required this.bookCode,
    this.titleMr = '',
    this.titleEn = '',
    this.authorMr = '',
    this.authorEn = '',
    required this.category,
    this.isbn = '',
    this.publisher = '',
    this.publicationYear = 0,
    required this.totalCopies,
    required this.availableCopies,
  });

  bool get isAvailable => availableCopies > 0;

  int get issuedCopies => (totalCopies - availableCopies).clamp(0, totalCopies);

  String displayTitle(Locale locale) {
    final isEnDigits = RegExp(r'^\d+$').hasMatch(titleEn.trim());
    if (locale.languageCode == 'mr') {
      return titleMr.isNotEmpty ? titleMr : (isEnDigits ? '' : titleEn);
    } else {
      if (titleEn.isNotEmpty && !isEnDigits) {
        return titleEn;
      }
      return titleMr.isNotEmpty ? titleMr : titleEn;
    }
  }

  String displayAuthor(Locale locale) {
    if (locale.languageCode == 'mr') {
      return authorMr.isNotEmpty ? authorMr : authorEn;
    } else {
      return authorEn.isNotEmpty ? authorEn : authorMr;
    }
  }

  Book copyWith({
    String? id,
    String? bookCode,
    String? titleMr,
    String? titleEn,
    String? authorMr,
    String? authorEn,
    String? category,
    String? isbn,
    String? publisher,
    int? publicationYear,
    int? totalCopies,
    int? availableCopies,
  }) {
    return Book(
      id: id ?? this.id,
      bookCode: bookCode ?? this.bookCode,
      titleMr: titleMr ?? this.titleMr,
      titleEn: titleEn ?? this.titleEn,
      authorMr: authorMr ?? this.authorMr,
      authorEn: authorEn ?? this.authorEn,
      category: category ?? this.category,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publicationYear: publicationYear ?? this.publicationYear,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final tMr = (json['titleMr'] as String? ?? '').trim();
    final tEn = (json['titleEn'] as String? ?? '').trim();
    final singleTitle = (json['title'] as String? ?? '').trim();
    final isEnDigits = RegExp(r'^\d+$').hasMatch(tEn);

    // If tEn is purely digits and tMr is present, use tMr as the primary title
    final effectiveTitle = (tMr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(tMr))
        ? tMr
        : (tEn.isNotEmpty && !isEnDigits
            ? tEn
            : (singleTitle.isNotEmpty ? singleTitle : (tMr.isNotEmpty ? tMr : tEn)));

    final aMr = (json['authorMr'] as String? ?? '').trim();
    final aEn = (json['authorEn'] as String? ?? '').trim();
    final singleAuthor = (json['author'] as String? ?? '').trim();
    final effectiveAuthor = aMr.isNotEmpty ? aMr : (aEn.isNotEmpty ? aEn : singleAuthor);

    return Book(
      id: json['id']?.toString() ?? '',
      bookCode: json['bookCode'] as String? ?? json['code'] as String? ?? '',
      titleMr: tMr.isNotEmpty ? tMr : effectiveTitle,
      titleEn: (tEn.isNotEmpty && !isEnDigits) ? tEn : effectiveTitle,
      authorMr: aMr.isNotEmpty ? aMr : effectiveAuthor,
      authorEn: aEn.isNotEmpty ? aEn : effectiveAuthor,
      category: json['category'] as String? ?? 'General',
      isbn: json['isbn'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      publicationYear: (json['publicationYear'] as num?)?.toInt() ?? 0,
      totalCopies: (json['totalCopies'] as num?)?.toInt() ?? 1,
      availableCopies: (json['availableCopies'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveTitle = titleMr.isNotEmpty ? titleMr : titleEn;
    final effectiveAuthor = authorMr.isNotEmpty ? authorMr : authorEn;
    return {
      'id': id,
      'bookCode': bookCode,
      'title': effectiveTitle,
      'titleMr': titleMr.isNotEmpty ? titleMr : effectiveTitle,
      'titleEn': titleEn.isNotEmpty ? titleEn : effectiveTitle,
      'author': effectiveAuthor,
      'authorMr': authorMr.isNotEmpty ? authorMr : effectiveAuthor,
      'authorEn': authorEn.isNotEmpty ? authorEn : effectiveAuthor,
      'category': category,
      'isbn': isbn,
      'publisher': publisher,
      'publicationYear': publicationYear,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
    };
  }
}
