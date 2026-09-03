/// The distinct metadata chips a checklist item row can render. Each maps to a
/// stable [key] persisted in [PrefsService.hiddenItemChips] so the user can
/// choose which chips appear on item rows. All chips are visible by default.
enum ItemChipKind {
  category('category'),
  store('store'),
  label('label'),
  quantity('quantity'),
  price('price'),
  note('note'),
  oneTime('one_time'),
  recurring('recurring'),
  list('list_badge');

  const ItemChipKind(this.key);

  final String key;
}
