import 'package:flutter/material.dart';

/// PROTOTYPE — stand-in photo board data.
///
/// No bytes reach this page from anywhere: the mirror carries none, and the
/// prototype has no server. A tile stands in for an image with a gradient and
/// a synthetic pattern that is a texture at fit and legible only when zoomed,
/// which is what makes "does zoom earn its gesture" a question the wrist can
/// answer.

@immutable
class ProtoPhoto {
  final int id;
  final String caption;
  final String uploadedBy;
  final String when;

  /// Null for a photo at the root of the board, mirroring `Photo.folderId`.
  final int? folderId;

  /// Whether the bytes are on disk. Under the load-on-demand policy the cached
  /// set is exactly the photos the wearer has already opened, so an offline
  /// board is a mix rather than all-or-nothing.
  final bool cached;

  final Color a;
  final Color b;

  const ProtoPhoto({
    required this.id,
    required this.caption,
    required this.uploadedBy,
    required this.when,
    required this.a,
    required this.b,
    this.folderId,
    this.cached = true,
  });
}

@immutable
class ProtoPhotoFolder {
  final int id;
  final String name;

  const ProtoPhotoFolder(this.id, this.name);
}

const protoPhotoFolders = <ProtoPhotoFolder>[
  ProtoPhotoFolder(1, 'House'),
  ProtoPhotoFolder(2, 'Receipts'),
  ProtoPhotoFolder(3, 'מתכונים'),
];

/// Enough photos to scroll well past a screen, spread across the root and the
/// folders, with a right-to-left caption and an odd count in one folder so the
/// half-empty last row is on screen rather than imagined.
const protoPhotos = <ProtoPhoto>[
  ProtoPhoto(
    id: 1,
    caption: 'Fridge shelf',
    uploadedBy: 'Dana',
    when: 'Tuesday',
    a: Color(0xFF3A6EA5),
    b: Color(0xFF1B3A5C),
  ),
  ProtoPhoto(
    id: 2,
    caption: 'Spare key',
    uploadedBy: 'You',
    when: 'Last week',
    a: Color(0xFF3A7A7A),
    b: Color(0xFF1C3B3B),
  ),
  ProtoPhoto(
    id: 3,
    caption: 'Bike lock code',
    uploadedBy: 'Dana',
    when: '3 Sep',
    a: Color(0xFF9A5A3A),
    b: Color(0xFF4A2A1B),
    cached: false,
  ),
  ProtoPhoto(
    id: 4,
    caption: 'Parking bay',
    uploadedBy: 'You',
    when: '1 Sep',
    a: Color(0xFF5A5A8E),
    b: Color(0xFF2A2A46),
    cached: false,
  ),
  ProtoPhoto(
    id: 5,
    caption: 'Boiler dial',
    uploadedBy: 'Ari',
    when: 'August',
    folderId: 1,
    a: Color(0xFF7A4A6E),
    b: Color(0xFF3A2434),
  ),
  ProtoPhoto(
    id: 6,
    caption: 'Paint colour',
    uploadedBy: 'Dana',
    when: 'August',
    folderId: 1,
    a: Color(0xFF4B7F52),
    b: Color(0xFF223A26),
  ),
  ProtoPhoto(
    id: 7,
    caption: 'Meter reading',
    uploadedBy: 'You',
    when: 'August',
    folderId: 1,
    a: Color(0xFF6E6E3A),
    b: Color(0xFF34341C),
    cached: false,
  ),
  ProtoPhoto(
    id: 8,
    caption: 'Filter size',
    uploadedBy: 'Ari',
    when: 'July',
    folderId: 1,
    a: Color(0xFF3A5A6E),
    b: Color(0xFF1C2C36),
  ),
  ProtoPhoto(
    id: 9,
    caption: 'Plumber',
    uploadedBy: 'Dana',
    when: 'July',
    folderId: 1,
    a: Color(0xFF8E4A4A),
    b: Color(0xFF442222),
    cached: false,
  ),
  ProtoPhoto(
    id: 10,
    caption: 'Hardware shop',
    uploadedBy: 'You',
    when: 'Monday',
    folderId: 2,
    a: Color(0xFF8E6A3A),
    b: Color(0xFF4A3620),
  ),
  ProtoPhoto(
    id: 11,
    caption: 'Pharmacy',
    uploadedBy: 'Dana',
    when: 'Monday',
    folderId: 2,
    a: Color(0xFF7A7A4A),
    b: Color(0xFF3A3A22),
    cached: false,
  ),
  ProtoPhoto(
    id: 12,
    caption: 'סופרמרקט',
    uploadedBy: 'Ari',
    when: '2 Sep',
    folderId: 2,
    a: Color(0xFF4A6E8E),
    b: Color(0xFF223444),
  ),
  ProtoPhoto(
    id: 13,
    caption: 'חלה',
    uploadedBy: 'Dana',
    when: 'Friday',
    folderId: 3,
    a: Color(0xFF8E7A4A),
    b: Color(0xFF443A22),
  ),
];

Iterable<ProtoPhoto> protoPhotosIn(int? folderId) =>
    protoPhotos.where((p) => p.folderId == folderId);

int protoFolderCount(int folderId) => protoPhotosIn(folderId).length;
