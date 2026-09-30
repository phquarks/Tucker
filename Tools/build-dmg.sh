#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 [--adhoc]" >&2
    echo "Without --adhoc, TUCKER_SIGNING_IDENTITY and TUCKER_NOTARY_PROFILE are required." >&2
}

mode="release"
if test "${1:-}" = "--adhoc" || test "${1:-}" = "--local"; then
    mode="adhoc"
elif test "$#" -ne 0; then
    usage
    exit 2
fi

project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
work_dir=$(/usr/bin/mktemp -d /tmp/tucker-release.XXXXXX)
trap '/bin/rm -rf "$work_dir"' EXIT
derived_data="$work_dir/DerivedData"
output_dir="$project_dir/dist"

if test "$mode" = "release"; then
    signing_identity="${TUCKER_SIGNING_IDENTITY:-}"
    notary_profile="${TUCKER_NOTARY_PROFILE:-}"
    if test -z "$signing_identity" || test -z "$notary_profile"; then
        usage
        exit 2
    fi
    case "$signing_identity" in
        "Developer ID Application:"*) ;;
        *) echo "TUCKER_SIGNING_IDENTITY must start with 'Developer ID Application:'." >&2; exit 2 ;;
    esac
    /usr/bin/security find-identity -v -p codesigning | /usr/bin/grep -Fq "\"${signing_identity}\"" || {
        echo "Signing identity not found in the keychain: $signing_identity" >&2
        exit 1
    }
fi

/usr/bin/xcodebuild \
    -project "$project_dir/Tucker.xcodeproj" \
    -target Tucker \
    -configuration Release \
    SYMROOT="$derived_data/Build/Products" \
    OBJROOT="$derived_data/Build/Intermediates.noindex" \
    SHARED_PRECOMPS_DIR="$derived_data/Build/Intermediates.noindex/PrecompiledHeaders" \
    CLANG_MODULE_CACHE_PATH="$derived_data/ModuleCache.noindex" \
    CODE_SIGNING_ALLOWED=NO \
    clean build

app="$derived_data/Build/Products/Release/Tucker.app"
test -d "$app"
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist")
build_number=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$app/Contents/Info.plist")

if test "$mode" = "release"; then
    /usr/bin/codesign --force --deep --options runtime --timestamp \
        --sign "$signing_identity" \
        --identifier com.quarks.tucker \
        --entitlements "$project_dir/Tucker/Tucker.entitlements" \
        "$app"
    /usr/bin/codesign --verify --deep --strict --verbose=2 "$app"
    dmg_name="Tucker-${version}-${build_number}.dmg"
else
    /usr/bin/codesign --force --deep --options runtime --sign - \
        --identifier com.quarks.tucker \
        --entitlements "$project_dir/Tucker/Tucker.entitlements" \
        "$app"
    /usr/bin/codesign --verify --deep --strict --verbose=2 "$app"
    dmg_name="Tucker-${version}-${build_number}-ADHOC.dmg"
fi

/bin/mkdir -p "$output_dir"
dmg="$output_dir/$dmg_name"
background="$work_dir/dmg-background.tiff"
/usr/bin/sips -s format tiff "$project_dir/Tools/dmg-background.png" --out "$background" >/dev/null
/bin/rm -f "$dmg"
PYTHONPATH="$project_dir/Tools/dmg-python" /usr/bin/python3 -m dmgbuild \
    -s "$project_dir/Tools/dmg-settings.py" \
    -D "app=$app" \
    -D "guide=$project_dir/Tools/ADHOC-INSTALL.txt" \
    -D "background=$background" \
    "Tucker" "$dmg"
/usr/bin/hdiutil verify "$dmg"

if test "$mode" = "release"; then
    /usr/bin/codesign --force --timestamp --sign "$signing_identity" "$dmg"
    /usr/bin/xcrun notarytool submit "$dmg" --keychain-profile "$notary_profile" --wait
    /usr/bin/xcrun stapler staple "$dmg"
    /usr/bin/xcrun stapler validate "$dmg"
    /usr/sbin/spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg"
fi

/usr/bin/shasum -a 256 "$dmg"
echo "Created: $dmg"
