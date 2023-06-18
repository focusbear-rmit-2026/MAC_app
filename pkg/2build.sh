#!/bin/bash

# Name of the package.
NAME="Late No More"

# Once installed the identifier is used as the filename for a receipt files in /var/db/receipts/.
IDENTIFIER="com.focusbear.latenomore"

# Package version number.
VERSION="1.0"

productbuild --distribution Distribution.xml --package-path "$NAME-$VERSION.pkg"  --resources resources "Late No More.pkg" --sign "Developer ID Installer: Jeremy Nagel (TCUD568B3U)"
 
# Sign the final pkg
codesign -f -s "Developer ID Application: Jeremy Nagel (TCUD568B3U)" -v "Late No More.pkg"

#Verify Sign
codesign -vvv --deep --strict "Late No More.pkg"

xcrun notarytool submit "Late No More.pkg" --wait --apple-id "vishnu.wtl@gmail.com" --password "mmnz-xeky-xmrt-eqgb" --team-id TCUD568B3U

xcrun stapler staple "Late No More.pkg"

spctl --assess -vv --type install "Late No More.pkg"
