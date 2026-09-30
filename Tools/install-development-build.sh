#!/bin/sh
set -eu

source_app="${BUILT_PRODUCTS_DIR:?Missing build products directory}/Tucker.app"
destination_app="/Applications/Tucker.app"
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist")
test "$bundle_id" = "com.quarks.tucker"
if test -e "$destination_app"; then
    installed_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$destination_app/Contents/Info.plist")
    if test "$installed_id" != "$bundle_id"; then
        echo 'Refusing to replace a different application at /Applications/Tucker.app' >&2
        exit 1
    fi
fi
/usr/bin/ditto "$source_app" "$destination_app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$destination_app"
