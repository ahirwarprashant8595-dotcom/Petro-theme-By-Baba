#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ui.sh
source "$base/scripts/ui.sh"
# shellcheck source=scripts/platform.sh
source "$base/scripts/platform.sh"
panel=/var/www/pterodactyl
version=1.15.2
panel_hash=572aacdf896e2dbce3df4c42f055e77a1e419598b224b7d6ebf3bf41462af8cf
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'HELP'
BABA HOST installer
  bash install.sh         # Open the 6-option menu
  bash install.sh panel   # Official Panel only
  bash install.sh wings   # Official Wings
  bash install.sh fresh   # Panel + theme
  bash install.sh remove-theme [panel-path]
  bash install.sh theme [panel-path] [--check|--keep-branding]
  bash install.sh verify [panel-path]
Fresh installation supports Ubuntu 22.04/24.04 and Debian 12/13 with systemd.
Requires a dedicated fresh VPS, domain DNS and root. Wings/nodes are configured separately.
HELP
}
mode="${1:-menu}"
if [[ "$mode" == menu ]]; then
  while true; do
    ui_menu
    read -r -p 'Choose [1-6]: ' choice || exit 0
    case "$choice" in
      1) exec bash "$base/install.sh" panel ;;
      2) exec bash "$base/install.sh" wings ;;
      3) exec bash "$base/install.sh" theme ;;
      4) exec bash "$base/install.sh" remove-theme ;;
      5) exit 0 ;;
      6) exec bash "$base/install.sh" fresh ;;
      *) printf 'Please choose a number from 1 to 6.\n' ;;
    esac
  done
fi
with_theme=0
case "$mode" in
  --help|-h) usage; exit 0 ;;
  wings) (cd "$base" && sha256sum --check --quiet PACKAGE.sha256); exec bash "$base/scripts/install-wings.sh" ;;
  remove-theme) (cd "$base" && sha256sum --check --quiet PACKAGE.sha256); exec bash "$base/scripts/remove-theme.sh" "${2:-$panel}" ;;
  theme) exec bash "$base/setup.sh" "${2:-$panel}" "${3:-}" ;;
  verify)
    cd "$base"
    sha256sum --check --quiet PACKAGE.sha256
    [[ -d "$base/Theme-By-Baba-1.4.0" ]] || tar -xzf "$base/Theme-By-Baba-1.4.0.tar.gz" -C "$base"
    exec php "$base/Theme-By-Baba-1.4.0/verify.php" "${2:-$panel}"
    ;;
  fresh|panel) [[ $# -eq 1 ]] || die 'This mode takes no arguments; prompts collect settings.'; [[ "$mode" != fresh ]] || with_theme=1 ;;
  *) usage; exit 1 ;;
esac
ui_banner
[[ $EUID -eq 0 ]] || die 'Run as root.'
[[ -f /etc/os-release ]] || die 'Cannot detect Linux distribution.'
# shellcheck source=/dev/null
source /etc/os-release
php_version="$(platform_php_version "$ID" "$VERSION_ID")" || die 'Supported: Ubuntu 22.04/24.04 or Debian 12/13.'
[[ -d /run/systemd/system ]] || die 'A VPS booted with systemd is required.'
[[ ! -L "$panel" ]] || die 'Panel path must not be a symlink.'
if [[ -d "$panel" ]] && [[ -n "$(find "$panel" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  die 'Panel directory is not empty. Use theme mode for an existing installation.'
fi
for file in /etc/nginx/sites-available/baba-panel.conf /etc/systemd/system/pteroq.service /etc/cron.d/baba-pterodactyl; do
  [[ ! -e "$file" && ! -L "$file" ]] || die "Existing configuration: $file"
done
if [[ -d /etc/nginx/sites-enabled ]]; then
  while IFS= read -r site; do
    [[ "$(basename "$site")" == default ]] || die 'Other NGINX sites exist; use a dedicated fresh VPS.'
  done < <(find /etc/nginx/sites-enabled -mindepth 1 -maxdepth 1 -print)
fi
[[ -t 0 ]] || die 'Run from an interactive terminal (download the script first, do not pipe into bash).'
printf 'Install official Pterodactyl %s on this fresh VPS.\n' "$version"
[[ $with_theme -eq 0 ]] || printf 'BABA HOST theme will be installed afterwards.\n'
read -r -p 'Panel domain (example panel.example.com): ' domain
domain="${domain,,}"
[[ ${#domain} -le 253 && "$domain" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || die 'Enter a domain only, without http://, paths or spaces.'
read -r -p 'Administrator email: ' email
[[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] || die 'Invalid email.'
read -r -p 'Administrator username [admin]: ' username; username="${username:-admin}"
[[ "$username" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]{2,31}$ ]] || die 'Username must be 3-32 letters/numbers, dots, underscores or hyphens.'
read -r -p 'Timezone [Asia/Kolkata]: ' timezone; timezone="${timezone:-Asia/Kolkata}"
[[ "$timezone" =~ ^[A-Za-z_]+/[A-Za-z_+-]+(/[A-Za-z_+-]+)?$ && -f "/usr/share/zoneinfo/$timezone" ]] || die 'Invalid timezone.'
read -r -s -p 'Admin password (12+ chars, upper/lower case and number): ' admin_password; printf '\n'
[[ ${#admin_password} -ge 12 && "$admin_password" =~ [A-Z] && "$admin_password" =~ [a-z] && "$admin_password" =~ [0-9] ]] || die 'Password does not meet requirements.'
read -r -s -p 'Repeat password: ' repeat_password; printf '\n'
[[ "$admin_password" == "$repeat_password" ]] || die 'Passwords differ.'
unset repeat_password
read -r -p 'Request free HTTPS certificate? DNS must point here and ports 80/443 be open [Y/n]: ' tls
tls="${tls:-y}"; [[ "$tls" =~ ^[YyNn]$ ]] || die 'Enter y or n.'
read -r -p 'Type INSTALL to begin the selected installation: ' confirm
[[ "$confirm" == INSTALL ]] || die 'Cancelled.'
cd "$base"
sha256sum --check --quiet PACKAGE.sha256
[[ -d "$base/Theme-By-Baba-1.4.0" ]] || tar -xzf "$base/Theme-By-Baba-1.4.0.tar.gz" -C "$base"
ui_stage "1 / 6  System dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg unzip tar git openssl cron nginx mariadb-server redis-server
install_php_repository "$ID" "$VERSION_ID"
apt-get install -y "php$php_version" "php$php_version-cli" "php$php_version-common" "php$php_version-gd" "php$php_version-mysql" "php$php_version-mbstring" "php$php_version-bcmath" "php$php_version-xml" "php$php_version-fpm" "php$php_version-curl" "php$php_version-zip"
phpbin="/usr/bin/php$php_version"
update-alternatives --set php "$phpbin"
"$phpbin" "$base/Theme-By-Baba-1.4.0/verify.php" --package
work="$(mktemp -d /var/tmp/baba-installer.XXXXXXXX)"
trap 'unset admin_password db_password; printf "Installer stopped at line %s. Existing partial files are preserved for inspection.\n" "$LINENO" >&2' ERR
ui_stage "2 / 6  Official Panel release"
ui_run "Download Pterodactyl $version" curl --fail --silent --show-error --location --retry 3 "https://github.com/pterodactyl/panel/releases/download/v$version/panel.tar.gz" -o "$work/panel.tar.gz"
printf '%s  %s\n' "$panel_hash" "$work/panel.tar.gz" | sha256sum --check --status
curl --fail --silent --show-error --location --retry 3 https://getcomposer.org/installer -o "$work/composer-setup.php"
composer_expected="$(curl --fail --silent --show-error https://composer.github.io/installer.sig)"
[[ "$(sha384sum "$work/composer-setup.php" | cut -d ' ' -f1)" == "$composer_expected" ]] || die 'Composer installer signature mismatch.'
"$phpbin" "$work/composer-setup.php" --install-dir="$work" --filename=composer
mkdir -p "$panel"
tar -xzf "$work/panel.tar.gz" -C "$panel"
cd "$panel"
COMPOSER_ALLOW_SUPERUSER=1 "$phpbin" "$work/composer" install --no-dev --optimize-autoloader --no-interaction
ui_stage "3 / 6  Database and administrator"
systemctl enable --now mariadb redis-server "php$php_version-fpm" cron
[[ "$(mariadb -Nse "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='baba_panel'")" == 0 ]] || die 'baba_panel database already exists; refusing to reuse it.'
[[ "$(mariadb -Nse "SELECT COUNT(*) FROM mysql.user WHERE User='baba_panel'")" == 0 ]] || die 'baba_panel database user already exists; refusing to reuse it.'
db_password="$(openssl rand -hex 32)"
mariadb <<SQL
CREATE DATABASE baba_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'baba_panel'@'127.0.0.1' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON baba_panel.* TO 'baba_panel'@'127.0.0.1';
SQL
scheme=http; [[ "$tls" =~ ^[Yy]$ ]] && scheme=https
BABA_APP_URL="$scheme://$domain" BABA_TIMEZONE="$timezone" BABA_EMAIL="$email" BABA_DB_PASSWORD="$db_password" "$phpbin" "$base/scripts/configure-panel.php" environment "$panel"
unset db_password
"$phpbin" artisan key:generate --force --no-interaction
"$phpbin" artisan migrate --seed --force --no-interaction
BABA_ADMIN_PASSWORD="$admin_password" BABA_EMAIL="$email" BABA_USERNAME="$username" "$phpbin" "$base/scripts/configure-panel.php" admin "$panel"
unset admin_password
chown -R www-data:www-data "$panel"
chmod 640 "$panel/.env"
ui_stage "4 / 6  Selected appearance"
if [[ $with_theme -eq 1 ]]; then bash "$base/setup.sh" "$panel"; fi
ui_stage "5 / 6  Web server, HTTPS and queue"
cat > /etc/nginx/sites-available/baba-panel.conf <<NGINX
server {
    listen 80;
    server_name $domain;
    root $panel/public;
    index index.php;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php$php_version-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_read_timeout 300;
    }
    location ~ /\. { deny all; }
}
NGINX
ln -s /etc/nginx/sites-available/baba-panel.conf /etc/nginx/sites-enabled/baba-panel.conf
nginx -t
systemctl enable --now nginx
systemctl reload nginx
if [[ "$tls" =~ ^[Yy]$ ]]; then
  apt-get install -y certbot python3-certbot-nginx
  certbot --nginx -d "$domain" --email "$email" --agree-tos --non-interactive --redirect
fi
cat > /etc/systemd/system/pteroq.service <<SERVICE
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service mariadb.service
[Service]
User=www-data
Group=www-data
Restart=always
RestartSec=5s
ExecStart=$phpbin $panel/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
[Install]
WantedBy=multi-user.target
SERVICE
printf '* * * * * www-data %s %s/artisan schedule:run > /dev/null 2>&1\n' "$phpbin" "$panel" > /etc/cron.d/baba-pterodactyl
chmod 644 /etc/cron.d/baba-pterodactyl /etc/systemd/system/pteroq.service /etc/nginx/sites-available/baba-panel.conf
systemctl daemon-reload
systemctl enable --now pteroq.service
runuser -u www-data -- "$phpbin" "$panel/artisan" optimize:clear
runuser -u www-data -- "$phpbin" "$panel/artisan" view:cache
if [[ $with_theme -eq 1 ]]; then "$phpbin" "$base/Theme-By-Baba-1.4.0/verify.php" "$panel"; fi
ui_stage "6 / 6  Application and service verification"
systemctl is-active --quiet nginx mariadb redis-server "php$php_version-fpm" pteroq
http_code="$(curl --silent --show-error --output "$work/login.html" --write-out '%{http_code}' --resolve "$domain:80:127.0.0.1" --resolve "$domain:443:127.0.0.1" "$scheme://$domain/auth/login")"
[[ "$http_code" == 200 ]] || die "Login HTTP check failed: $http_code"
if [[ $with_theme -eq 1 ]]; then grep -q 'BABA HOST' "$work/login.html" || die 'Rendered branding check failed.'; fi
trap - ERR
printf '\nPanel installed and checks passed: %s://%s\nAdmin: %s\n' "$scheme" "$domain" "$email"
printf 'Configure SMTP in Administration > Settings before sending real emails.\nInstall Wings and create a node/allocation separately to host game servers.\nBack up the panel .env and database securely; do not publish them.\n'
