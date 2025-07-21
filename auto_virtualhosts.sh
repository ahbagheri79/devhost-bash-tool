#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$SCRIPT_DIR/settings.txt"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "ERROR: settings.txt not found. Create it with ROOT_DIR=/path/to/folder"
    exit 1
fi

# Read ROOT_DIR from settings.txt
source "$SETTINGS_FILE"
BASE_DIR="$ROOT_DIR"
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"
DOMAIN_LIST_FILE="$BASE_DIR/domains.txt"

mkdir -p "$BASE_DIR"
[ ! -f "$DOMAIN_LIST_FILE" ] && touch "$DOMAIN_LIST_FILE"

# ----------------------------
# REMOVE MODE
# ----------------------------
if [[ "$1" == --remove:* ]]; then
    folder_name="${1#--remove:}"
    domain_name="$folder_name.test"
    config_file="$APACHE_SITES_AVAILABLE/$domain_name.conf"

    echo ">> Removing domain $domain_name ..."

    if [ -f "$config_file" ]; then
        sudo a2dissite "$domain_name.conf" 2>/dev/null
        sudo rm -f "$config_file" "$APACHE_SITES_ENABLED/$domain_name.conf"
        echo "✅ Apache config removed."
    fi

    sudo sed -i "/$domain_name/d" /etc/hosts
    sed -i "/$domain_name/d" "$DOMAIN_LIST_FILE"

    sudo systemctl reload apache2
    echo "✅ Apache reloaded."
    exit 0
fi

# ----------------------------
# FIX-PERMISSIONS MODE
# ----------------------------
if [[ "$1" == --fix-permissions:* ]]; then
    folder_name="${1#--fix-permissions:}"
    full_path="$BASE_DIR/$folder_name"

    echo ">> Fixing permissions for $folder_name"

    sudo chown -R www-data:www-data "$full_path/storage" "$full_path/bootstrap/cache" 2>/dev/null
    sudo chmod -R 775 "$full_path/storage" "$full_path/bootstrap/cache" 2>/dev/null
    sudo chmod o+x "$BASE_DIR" "${BASE_DIR}/${folder_name}" "${BASE_DIR}/${folder_name}/public" 2>/dev/null

    echo "✅ Permissions fixed for $folder_name"
    exit 0
fi

# ----------------------------
# STATUS MODE
# ----------------------------
if [[ "$1" == --status:* ]]; then
    folder_name="${1#--status:}"
    domain_name="$folder_name.test"
    config_file="$APACHE_SITES_AVAILABLE/$domain_name.conf"

    echo "===== STATUS for $domain_name ====="

    if [ -f "$config_file" ]; then
        echo "✅ Apache config exists: $config_file"
    else
        echo "❌ Apache config does NOT exist."
    fi

    if grep -q "$domain_name" /etc/hosts; then
        echo "✅ Found in /etc/hosts"
    else
        echo "❌ NOT found in /etc/hosts"
    fi

    if grep -Fxq "$domain_name" "$DOMAIN_LIST_FILE"; then
        echo "✅ Found in domains.txt"
    else
        echo "❌ NOT found in domains.txt"
    fi

    echo "==============================="
    exit 0
fi


# ----------------------------
# CREATE MODE
# ----------------------------
for folder in "$BASE_DIR"/*; do
    [ -d "$folder" ] || continue

    domain_name="$(basename "$folder").test"
    config_file="$APACHE_SITES_AVAILABLE/$domain_name.conf"

    public_route_file="$folder/public-route.txt"
    if [ -f "$public_route_file" ] && [ -s "$public_route_file" ]; then
        custom_route=$(grep -v '^\s*$' "$public_route_file" | head -n 1 | xargs)
        if [ -d "$folder/$custom_route" ]; then
            document_root="$folder/$custom_route"
            echo ">> $domain_name: Using custom DocumentRoot → $document_root"
        else
            document_root="$folder"
            echo "⚠️ $domain_name: custom route invalid, fallback to $document_root"
        fi
    else
        document_root="$folder"
        echo ">> $domain_name: No public-route.txt, using default: $document_root"
    fi

    if grep -Fxq "$domain_name" "$DOMAIN_LIST_FILE"; then
        echo "⚠️ $domain_name already exists, skipping..."
        continue
    fi

    echo "<VirtualHost *:80>
    ServerName $domain_name
    DocumentRoot $document_root
    <Directory $document_root>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>" | sudo tee "$config_file"

    sudo ln -s "$config_file" "$APACHE_SITES_ENABLED/" 2>/dev/null
    echo "127.0.0.1 $domain_name" | sudo tee -a /etc/hosts

    echo "$domain_name" >> "$DOMAIN_LIST_FILE"
    echo "✅ $domain_name created"
done

sudo systemctl reload apache2
echo "✅ Apache reloaded."


