#!/usr/bin/env bash
set -e

TMPFILE_PATH="/etc/tmpfiles.d/powercap.conf"
UDEV_RULE_PATH="/etc/udev/rules.d/99-powercap.rules"

echo "Creating boot permission configuration..."

# 1. Systemd tmpfiles rule for reliable startup permissions
echo "Z /sys/class/powercap/intel-rapl* 0755 root root - -" > "$TMPFILE_PATH"

# 2. Udev rule fallback
echo 'SUBSYSTEM=="powercap", ACTION=="add", RUN+="/bin/chmod -R a+rX /sys/class/powercap/intel-rapl*"' > "$UDEV_RULE_PATH"

echo "Applying permissions to active sysfs nodes immediately..."
chmod -R a+rX /sys/class/powercap/intel-rapl* 2>/dev/null || true

echo "Reloading udev and tmpfiles rules..."
udevadm control --reload-rules && udevadm trigger
systemd-tmpfiles --create "$TMPFILE_PATH" 2>/dev/null || true

echo "RAPL powercap permissions set up successfully!"
