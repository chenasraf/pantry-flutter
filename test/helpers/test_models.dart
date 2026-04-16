import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/models/notification.dart';
import 'package:pantry/models/photo.dart';

const _now = 1700000000;

Photo makePhoto({
  int id = 1,
  int houseId = 1,
  int? folderId,
  int fileId = 100,
  String? caption = 'sample photo',
  String uploadedBy = 'alice',
  int sortOrder = 0,
  int? createdAt,
  int? updatedAt,
}) => Photo(
  id: id,
  houseId: houseId,
  folderId: folderId,
  fileId: fileId,
  caption: caption,
  uploadedBy: uploadedBy,
  sortOrder: sortOrder,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _now,
);

PhotoFolder makePhotoFolder({
  int id = 10,
  int houseId = 1,
  String name = 'Folder',
  int sortOrder = 0,
  int? createdAt,
  int? updatedAt,
}) => PhotoFolder(
  id: id,
  houseId: houseId,
  name: name,
  sortOrder: sortOrder,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _now,
);

Note makeNote({
  int id = 1,
  int houseId = 1,
  String title = 'Sample note',
  String? content = 'hello world',
  String? color = '#ffffaa',
  String createdBy = 'alice',
  int sortOrder = 0,
  int? createdAt,
  int? updatedAt,
}) => Note(
  id: id,
  houseId: houseId,
  title: title,
  content: content,
  color: color,
  createdBy: createdBy,
  sortOrder: sortOrder,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _now,
);

Category makeCategory({
  int id = 1,
  int houseId = 1,
  String name = 'Food',
  String icon = 'food',
  String color = '#ef4444',
  int sortOrder = 0,
  int? createdAt,
  int? updatedAt,
}) => Category(
  id: id,
  houseId: houseId,
  name: name,
  icon: icon,
  color: color,
  sortOrder: sortOrder,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _now,
);

House makeHouse({
  int id = 1,
  String name = 'My House',
  String? description = 'A test house',
  String ownerUid = 'alice',
  String role = 'owner',
  int? createdAt,
  int? updatedAt,
}) => House(
  id: id,
  name: name,
  description: description,
  ownerUid: ownerUid,
  role: role,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _now,
);

ChecklistList makeChecklistList({
  int id = 1,
  int houseId = 1,
  String name = 'Groceries',
  String? description = 'weekly',
  String icon = 'cart',
  int sortOrder = 0,
  int? createdAt,
  int? updatedAt,
}) => ChecklistList(
  id: id,
  houseId: houseId,
  name: name,
  description: description,
  icon: icon,
  sortOrder: sortOrder,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _now,
);

NcNotification makeNotification({
  int notificationId = 1,
  String app = 'pantry',
  String user = 'alice',
  String subject = 'alice added an item',
  String message = '',
  String? datetime,
  String objectType = 'item',
  String objectId = '1',
  String? icon,
  String? link,
}) => NcNotification(
  notificationId: notificationId,
  app: app,
  user: user,
  subject: subject,
  message: message,
  datetime: datetime ?? '2026-04-11T12:00:00+00:00',
  objectType: objectType,
  objectId: objectId,
  icon: icon,
  link: link,
);

ListItem makeListItem({
  int id = 1,
  int listId = 1,
  String name = 'Milk',
  String? description,
  int? categoryId,
  String? quantity,
  bool done = false,
  int? doneAt,
  String? doneBy,
  String? rrule,
  bool repeatFromCompletion = false,
  bool deleteOnDone = false,
  int? nextDueAt,
  int? imageFileId,
  String? imageUploadedBy,
  int sortOrder = 0,
  int? createdAt,
  int? updatedAt,
}) => ListItem(
  id: id,
  listId: listId,
  name: name,
  description: description,
  categoryId: categoryId,
  quantity: quantity,
  done: done,
  doneAt: doneAt,
  doneBy: doneBy,
  rrule: rrule,
  repeatFromCompletion: repeatFromCompletion,
  deleteOnDone: deleteOnDone,
  nextDueAt: nextDueAt,
  imageFileId: imageFileId,
  imageUploadedBy: imageUploadedBy,
  sortOrder: sortOrder,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _now,
);
