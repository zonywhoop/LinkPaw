#!/bin/bash

# Exit on error
set -e

# Project configuration
PROJECT_NAME="LinkPaw.xcodeproj"
SCHEME="LinkPaw"
BUNDLE_ID="com.zonywhoop.LinkPaw"
EXPORT_OPTIONS="scripts/ExportOptions.plist"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/LinkPaw.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Export"
INFO_PLIST="LinkPaw/Info.plist"

# Function to get version from Info.plist
get_version() {
    /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${INFO_PLIST}"
}

# Function to get build number from Info.plist
get_build_number() {
    /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${INFO_PLIST}"
}

# 1. Handle Version Argument
if [ -n "$1" ]; then
    NEW_VERSION=$1
    echo "Updating version to ${NEW_VERSION}..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" "${INFO_PLIST}"
    
    # Optional: Increment build number
    CURRENT_BUILD=$(get_build_number)
    NEW_BUILD=$((CURRENT_BUILD + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" "${INFO_PLIST}"
    
    echo "Committing version changes..."
    git add "${INFO_PLIST}"
    git commit -m "Bump version to ${NEW_VERSION} (build ${NEW_BUILD})"
    
    RELEASE_TAG="v${NEW_VERSION}.${NEW_BUILD}"
    echo "Creating tag ${RELEASE_TAG}..."
    git tag -a "${RELEASE_TAG}" -m "Release ${RELEASE_TAG}"
else
    echo "No version provided. Using current version from Info.plist..."
    VERSION=$(get_version)
    BUILD_NUMBER=$(get_build_number)
    RELEASE_TAG="v${VERSION}.${BUILD_NUMBER}"
fi

DMG_NAME="LinkPaw-${RELEASE_TAG}.dmg"
ZIP_NAME="LinkPaw-${RELEASE_TAG}.zip"

echo "Releasing ${RELEASE_TAG}..."

# 2. Clean and Archive
echo "Cleaning and archiving..."
xcodebuild clean archive \
    -project "${PROJECT_NAME}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    -allowProvisioningUpdates

# 3. Export Archive
echo "Exporting archive..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS}" \
    -exportPath "${EXPORT_PATH}" \
    -allowProvisioningUpdates

APP_PATH="${EXPORT_PATH}/LinkPaw.app"

# 4. Create ZIP
echo "Creating ZIP..."
rm -f "${ZIP_NAME}"
(cd "${EXPORT_PATH}" && zip -r "../../${ZIP_NAME}" "LinkPaw.app")

# 5. Create DMG
echo "Creating DMG..."
rm -f "${DMG_NAME}"
DMG_TMP_DIR="build/dmg_tmp"
rm -rf "${DMG_TMP_DIR}"
mkdir -p "${DMG_TMP_DIR}"
cp -R "${APP_PATH}" "${DMG_TMP_DIR}/"
ln -s /Applications "${DMG_TMP_DIR}/Applications"

hdiutil create -volname "LinkPaw" -srcfolder "${DMG_TMP_DIR}" -ov -format UDZO "${DMG_NAME}"

# 6. GitHub Release
echo "Uploading to GitHub..."
# Push tag first
git push origin "${RELEASE_TAG}"

if gh release view "${RELEASE_TAG}" >/dev/null 2>&1; then
    echo "Release ${RELEASE_TAG} already exists. Updating..."
    gh release upload "${RELEASE_TAG}" "${DMG_NAME}" "${ZIP_NAME}" --clobber
else
    echo "Creating new release ${RELEASE_TAG}..."
    gh release create "${RELEASE_TAG}" "${DMG_NAME}" "${ZIP_NAME}" --title "Release ${RELEASE_TAG}" --notes "Automatically generated release for ${RELEASE_TAG}"
fi

echo "Done! Release ${RELEASE_TAG} uploaded to GitHub."
