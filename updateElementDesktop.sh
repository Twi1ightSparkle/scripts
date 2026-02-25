#!/bin/bash

# A simple script to download and install/upgrade Element Desktop using the
# tarballs published at packages.element.io

### Options

# Copy all options into a file in the same directory as the script named
# updateElementDesktop.env to change

if [[ -f "$(dirname "$0")/updateElementDesktop.env" ]]; then
    # shellcheck disable=SC1091
    source "$(dirname "$0")/updateElementDesktop.env"
else

    elementLocation="$HOME/.local/bin/element-desktop"
    downloadLocation="$elementLocation/downloads"
    symlinkLocation="$elementLocation/element"

    # Which logo to use in the Application Launcher
    # Note this is only downloaded once for the Application launcher. To replace the
    # icon, delete $elementLocation/element.png before running the script.

    # Normal green
    # logoURL="https://raw.githubusercontent.com/element-hq/logos/refs/heads/master/element/Element%20Logomark%20%20-%20Transparent%20-%20256px.png"

    # Monochrome white
    logoURL="https://raw.githubusercontent.com/element-hq/logos/refs/heads/master/element/Secondary/Element%20Logomark%20-%20White%20-%20Transparent%20-%20256px.png"

    # Monochrome black
    # logoURL="https://raw.githubusercontent.com/element-hq/logos/refs/heads/master/element/Secondary/Element%20Logomark%20-%20Black%20-%20Transparent%20-%20256px.png"

    # Replace the default green task manager icon with the above selected icon?
    # Requires ffmpeg installed to convert the png to ico. Note if you selected the
    # "Normal green" logo above this is unnecessary.
    replaceIcon=true

fi

###

if [[ -n "$1" ]]; then
    elementVersion="$1"
else
    read -rp "Element version to download: v" elementVersion
fi

downloadURL="https://packages.element.io/desktop/install/linux/glibc-x86-64/element-desktop-$elementVersion.tar.gz"
unTarPath="$downloadLocation/element-desktop-$elementVersion"
tarPath="$unTarPath.tar.gz"

# Check valid version
if ! curl --head --silent "$downloadURL" | grep "200 OK" > /dev/null; then
    echo "Invalid Element Desktop version \"v$elementVersion\""
    exit 1
fi

# Crete the ED directories if needed
if [[ ! -d "$elementLocation" ]]; then
    if ! mkdir -p "$elementLocation"; then
        echo "Failed to create the directory $elementLocation"
        exit 1
    fi
fi
if [[ ! -d "$downloadLocation" ]]; then
    if ! mkdir -p "$downloadLocation"; then
        echo "Failed to create the directory $downloadLocation"
        exit 1
    fi
fi

# Download new version
if [[ -d "$unTarPath" ]]; then
    echo "Requested version already exist at $unTarPath"
else
    echo "Downloading Element Desktop version v$elementVersion"
    if ! curl --output "$tarPath" "$downloadURL"; then
        echo "Failed to download version v$elementVersion"
        exit 1
    fi

    # Unpack
    if [[ -d "$unTarPath" ]]; then
        echo "Target path $unTarPath already exists"
    else
        tar --extract --file "$tarPath" --directory "$downloadLocation"
    fi

    # Delete archive
    rm "$tarPath"

    # Read and delete old symlinks if it exists
    if [[ -L "$symlinkLocation" ]]; then
        oldVersion="$(realpath "$symlinkLocation")"
        rm "$symlinkLocation"
    fi

    # Delete old version if one existed
    if [[ -n "$oldVersion" ]]; then
        rm -r "$oldVersion"
    fi

    # Symlink
    ln -s "$unTarPath" "$symlinkLocation"

    # Replace App icon
    if [[ "$replaceIcon" == "true" ]]; then
        logoDir="$unTarPath/resources/build"
        rm "$logoDir/icon.png"
        rm "$logoDir/icon.ico"
        echo "Downloading Element logo"
        if ! curl --silent --output "$logoDir/icon.png" "$logoURL"; then
            echo "Failed to download the logo"
            exit 1
        fi
        echo "Converting the logo png to ico using ffmpeg"
        if ! ffmpeg -loglevel quiet -i "$logoDir/icon.png" "$logoDir/icon.ico"; then
            echo "Failed to convert the logo png to ico using ffmpeg"
            exit 1
        fi
    fi
fi

# Download logo and create Applications entry if they don't exist
logoLocation="$elementLocation/element.png"
if [[ ! -f "$logoLocation" ]]; then
    echo "Downloading Element logo"
    if ! curl --silent --output "$logoLocation" "$logoURL"; then
        echo "Failed to download the logo"
        exit 1
    fi
fi

if [[ ! -f "$HOME/.local/share/applications/element-desktop.desktop" ]]; then
    mkdir -p "$HOME/.local/share/applications/"
    cat > "$HOME/.local/share/applications/element-desktop.desktop" << EOF
[Desktop Entry]
Name=Element Desktop
Comment=Element Matrix Client
Exec=$symlinkLocation/element-desktop %u
Terminal=false
Type=Application
Icon=$logoLocation
Categories=Network;InstantMessaging;
MimeType=x-scheme-handler/io.element.desktop;
EOF

    update-desktop-database "$HOME/.local/share/applications"
fi
