#!/bin/bash

# --- Configuration ---
SAMBA_USER="orion"
SAMBA_PASS="foo3000"
SHARE_NAME="SecuredShare"
SHARE_PATH="/srv/samba/secure_share"
SMB_CONF="/etc/samba/smb.conf"

# --- End Configuration ---

# Must be run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting Samba Server Setup ---"

# 1. Install Samba
echo "[1/6] Installing Samba..."
apt-get update
apt-get install -y samba

# 2. Configure Firewall (UFW)
echo "[2/6] Configuring firewall to allow Samba..."
ufw allow samba
ufw reload

# 3. Create Shared Directory
echo "[3/6] Creating shared directory at $SHARE_PATH..."
mkdir -p "$SHARE_PATH"

# Set permissions:
# Owner: root, Group: sambashare
# Permissions: 2770 (Group ID bit set, so new files inherit the group)
chown root:sambashare "$SHARE_PATH"
chmod 2770 "$SHARE_PATH"

# 4. Create the User 'orion'
echo "[4/6] Setting up user '$SAMBA_USER'..."

# Check if user exists, if not create them.
# We create a system account (-M for no home dir necessary if just for sharing)
# but standard useradd is fine. We use /sbin/nologin for security if they don't need SSH.
if id "$SAMBA_USER" &>/dev/null; then
    echo "User $SAMBA_USER already exists."
else
    useradd -M -s /sbin/nologin "$SAMBA_USER"
    # Add user to sambashare group so they can write to the folder
    usermod -aG sambashare "$SAMBA_USER"
    echo "User $SAMBA_USER created."
fi

# Set the Samba password
# smbpasswd -a adds the user to samba
# -s reads password from stdin
echo "[4/6] Setting Samba password for '$SAMBA_USER'..."
(echo "$SAMBA_PASS"; echo "$SAMBA_PASS") | smbpasswd -a -s "$SAMBA_USER"
smbpasswd -e "$SAMBA_USER"

# 5. Configure smb.conf
echo "[5/6] Configuring $SMB_CONF..."

# Backup original config
if [ ! -f "$SMB_CONF.bak" ]; then
    cp "$SMB_CONF" "$SMB_CONF.bak"
    echo "Backup of smb.conf created."
fi

# Append the share configuration to the end of the file
# We use valid users to restrict access to our authenticated user
cat << EOF >> "$SMB_CONF"

[$SHARE_NAME]
   comment = Secured File Share
   path = $SHARE_PATH
   read only = no
   browsable = yes
   valid users = $SAMBA_USER
   create mask = 0660
   directory mask = 0770
   force group = sambashare
EOF

# 6. Restart Samba
echo "[6/6] Restarting Samba services..."
systemctl restart smbd
systemctl restart nmbd

# --- FINAL INSTRUCTIONS ---
echo "----------------------------------------------------------------"
echo "--- SAMBA SETUP COMPLETE ---"
echo "----------------------------------------------------------------"
echo "Server IP: $(hostname -I | cut -d' ' -f1)"
echo "Share Name: $SHARE_NAME"
echo "User: $SAMBA_USER"
echo "Password: $SAMBA_PASS"
echo ""
echo "To connect:"
echo "  Windows: \\\\$(hostname -I | cut -d' ' -f1)\\$SHARE_NAME"
echo "  Mac/Linux: smb://$(hostname -I | cut -d' ' -f1)/$SHARE_NAME"
echo ""
echo "Script finished."