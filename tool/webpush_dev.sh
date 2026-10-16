#!/usr/bin/env bash
# Drives Nextcloud web push on a local nextcloud-docker-dev stack, for testing
# UnifiedPush delivery end to end.
#
#   tool/webpush_dev.sh enable              turn web push on (exposes the capability)
#   tool/webpush_dev.sh disable             turn it off again
#   tool/webpush_dev.sh status              show whether web push is on
#   tool/webpush_dev.sh send USER [HOUSE]   push a Pantry "item added" notification to USER
#   tool/webpush_dev.sh clear USER          dismiss the test notifications (exercises delete pushes)
#   tool/webpush_dev.sh log                 follow the server log, filtered to push activity
#
# NC_CONTAINER names the Nextcloud container (default nextcloud-nextcloud-1).
# The server delivers through the distributor's push server, so the stack needs
# to reach it: ntfy.sh works out of the box, NextPush needs the UnifiedPush
# Provider app on the server. While Pantry is in the foreground a push refreshes
# its notifications list instead of posting to the tray.
set -euo pipefail

C=${NC_CONTAINER:-nextcloud-nextcloud-1}
occ() { docker exec -u www-data "$C" php occ --no-warnings "$@" 2>&1 | grep -v '^Profiler output'; }

php_eval() {
  docker exec -u www-data -i "$C" php -d display_errors=stderr /dev/stdin "$@" 2>&1 | grep -v '^Profiler output'
}

case "${1:-}" in
  enable)
    occ config:app:set notifications webpush_enabled --value=1 --type=boolean
    ;;
  disable)
    occ config:app:set notifications webpush_enabled --value=0 --type=boolean
    ;;
  status)
    echo -n "webpush_enabled: "
    occ config:app:get notifications webpush_enabled || echo "(unset)"
    ;;
  send)
    user=${2:?usage: send USER [HOUSE_ID]}
    house=${3:-0}
    php_eval "$user" "$house" <<'PHP'
<?php
require '/var/www/html/lib/base.php';
\OC_App::loadApps();
[, $user, $house] = $argv;
$m = \OCP\Server::get(\OCP\Notification\IManager::class);
$n = $m->createNotification();
$stamp = date('H:i:s');
$n->setApp('pantry')
  ->setUser($user)
  ->setDateTime(new \DateTime())
  ->setObject('item', 'webpush-test-' . bin2hex(random_bytes(4)))
  ->setSubject('item_added', [
    'userId' => 'webpush-test',
    'userDisplayName' => 'Push test',
    'houseId' => (int)$house,
    'houseName' => 'Test house',
    'itemName' => "Milk ($stamp)",
    'listName' => 'Groceries',
  ])
  ->setLink(\OCP\Server::get(\OCP\IURLGenerator::class)->linkToRouteAbsolute('pantry.page.index'));
$m->notify($n);
echo "sent to $user at $stamp\n";
PHP
    ;;
  clear)
    user=${2:?usage: clear USER}
    php_eval "$user" <<'PHP'
<?php
require '/var/www/html/lib/base.php';
\OC_App::loadApps();
[, $user] = $argv;
$m = \OCP\Server::get(\OCP\Notification\IManager::class);
$h = \OCP\Server::get(\OCA\Notifications\Handler::class);
$n = $m->createNotification();
$n->setApp('pantry')->setUser($user);
$ids = [];
foreach ($h->get($n) as $id => $found) {
  if (str_starts_with($found->getObjectId(), 'webpush-test-')) {
    $m->markProcessed($found);
    $ids[] = $id;
  }
}
echo 'dismissed ' . count($ids) . " test notification(s)\n";
PHP
    ;;
  log)
    docker exec "$C" sh -c 'tail -F "$(php -r "require \"/var/www/html/config/config.php\"; echo (\$CONFIG[\"datadirectory\"] ?? \"/var/www/html/data\") . \"/nextcloud.log\";")"' \
      | grep --line-buffered -i -E 'push|notif'
    ;;
  *)
    sed -n '2,16p' "$0"
    exit 1
    ;;
esac
