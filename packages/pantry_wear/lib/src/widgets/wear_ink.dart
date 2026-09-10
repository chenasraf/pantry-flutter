import 'package:flutter/material.dart';

/// The livery of something that went wrong, wherever the watch says so.
///
/// The transient notice, the sign-out warning and the rejected-credential note
/// are one family — a wearer should recognise the second from having seen the
/// first — so they are drawn from one pair rather than three copies of the same
/// two hex values.
const wearNoticeInk = Color(0xFFE0A0A0);
const wearNoticeGround = Color(0xFF2A1D1D);

/// The lower of the watch's two planes, and what the rail is filled with so
/// the list scrolls under it rather than through it.
const wearGround = Color(0xFF0B0B0C);

/// Whether the wearer's own work has reached the server yet. The rail says it
/// in a dot and the account page in words, and they have to be the same two
/// colours or the page reads as answering a different question from the dot
/// that sent the wearer to it.
const wearSyncedInk = Color(0xFF7FB77E);
const wearQueuedInk = Color(0xFFE0C07A);
