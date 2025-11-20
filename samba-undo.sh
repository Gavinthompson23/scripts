#!/bin/bash


# Samba Cleanup
SAMBA_USER="orion"
SHARE_PATH="/srv/samba/secure_share"
SMB_CONF="/etc/samba/smb.conf"
SMB_CONF_BAK="$SMB_CONF.bak"


# --- End Configuration ---

# Must be run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi


## SECTION 3: Samba Server Cleanup
echo "### 3. Reverting Samba and User Configuration ###"

# 3.1 Restore smb.conf from backup or remove custom section
if [ -f "$SMB_CONF_BAK" ]; then
    cp "$SMB_CONF_BAK" "$SMB_CONF"
    echo "Restored smb.conf from backup."
else
    echo "No smb.conf backup found. Manually removing [$SHARE_NAME] section..."
    # This uses a sed trick to remove all lines from the line matching the share name
    # until the next empty line or EOF. Not perfect, but a reasonable effort.
    sed -i "/\[$SHARE_NAME\]/,/^$/d" "$SMB_CONF"
fi

# 3.2 Remove shared directory
if [ -d "$SHARE_PATH" ]; then
    rm -rf "$SHARE_PATH"
    echo "Removed shared directory: $SHARE_PATH"
fi

# 3.3 Remove Samba user
if id "$SAMBA_USER" &>/dev/null; then
    # Delete system user and remove associated home directory (-r) just in case
    userdel -r "$SAMBA_USER"
    echo "Removed system user '$SAMBA_USER'."
fi
# Remove user from Samba internal database
pdbedit -x "$SAMBA_USER" 2>/dev/null

# 3.4 Remove UFW rule and restart Samba
echo "Removing UFW rule for Samba..."
ufw delete allow samba 2>/dev/null
systemctl restart smbd nmbd
echo "Samba cleanup complete."