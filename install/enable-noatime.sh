#!/bin/bash

DEST="/Library/LaunchDaemons/com.nullvision.noatime.plist"

OPTS_FORCE=0

if [ "$1" -eq "-f" ]; then
    OPTS_FORCE=1
fi

if [ $OPTS_FORCE -neq 1 -a -f "$DEST" ];
then
    echo "File already exists: $DEST" >&2
    echo "Remove file or use -f to overwrite." >&2
    exit 1
fi


cat << EOF | sudo tee "$DEST" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.nullvision.noatime</string>
        <key>ProgramArguments</key>
        <array>
            <string>mount</string>
            <string>-vuwo</string>
            <string>noatime</string>
            <string>/</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
</plist>
EOF

sudo chown root:wheel "$DEST"

echo "Installed $DEST"
echo "Reboot to activate."

exit 0
