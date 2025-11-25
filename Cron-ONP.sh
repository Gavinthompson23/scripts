#!/bin/bash

# --- Configuration ---
# The URL of the JPEG image to download
IMAGE_URL="https://www.nps.gov/webcams-olym/southcam.jpg"

# The directory inside the user's home folder where images will be saved
SAVE_DIR="webcam_images"

# Path for the helper script that performs the download (placed in user's home)
# Note: Using the current user's home directory ensures the cron job has permission.
USER_HOME=$(eval echo "~$USER")
FETCHER_SCRIPT_PATH="$USER_HOME/.$SAVE_DIR/image_fetcher.sh"

# --- End Configuration ---

echo "--- Starting Scheduled Image Download Setup ---"

# 1. Determine the user and set permissions
CURRENT_USER=$(whoami)
echo "Setting up cron job for user: $CURRENT_USER"

# 2. Create the destination directory
TARGET_DIR="$USER_HOME/$SAVE_DIR"
mkdir -p "$TARGET_DIR"
echo "[1/4] Created image storage directory: $TARGET_DIR"

# 3. Create a hidden directory for the cron helper script
mkdir -p "$USER_HOME/.$SAVE_DIR"

# 4. Create the image fetching helper script
echo "[2/4] Creating image fetcher helper script..."
cat << EOF > "$FETCHER_SCRIPT_PATH"
#!/bin/bash

# Define variables for the cron environment
URL="$IMAGE_URL"
OUTPUT_DIR="$TARGET_DIR"

# 1. Generate timestamp for the filename (e.g., 20231027_143000)
TIMESTAMP=\$(date +\%Y\%m\%d_\%H\%M\%S)
FILENAME="\$TIMESTAMP.jpeg"

# 2. Download the image.
# -q: quiet mode
# -O: output to a specific file
wget -q "\$URL" -O "\$OUTPUT_DIR/\$FILENAME"

# 3. Basic error check
if [ \$? -eq 0 ]; then
    echo "[\$(date)] Successfully downloaded \$FILENAME" >> "\$OUTPUT_DIR/download.log"
else
    echo "[\$(date)] ERROR: Failed to download image from \$URL" >> "\$OUTPUT_DIR/download.log"
fi

EOF

# Make the helper script executable
chmod +x "$FETCHER_SCRIPT_PATH"

# 5. Install the cron job
echo "[3/4] Installing cron job to run every 10 minutes..."

# Cron entry format: */10 * * * * /path/to/script
CRON_JOB="*/10 * * * * $FETCHER_SCRIPT_PATH"

# Check if job already exists before adding
if crontab -l 2>/dev/null | grep -F "$FETCHER_SCRIPT_PATH" > /dev/null; then
    echo "Cron job already exists. Skipping installation."
else
    # Add the new job using 'crontab -l' to read existing jobs and piping to 'crontab -'
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Installed new cron job: $CRON_JOB"
fi

# 6. Final message
echo "[4/4] Setup complete."
echo "----------------------------------------------------------------"
echo "The image will be downloaded every 10 minutes and saved to:"
echo "    $TARGET_DIR"
echo "Check the log file for status updates:"
echo "    $TARGET_DIR/download.log"
echo ""
