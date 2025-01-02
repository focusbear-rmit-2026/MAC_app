#!/bin/bash
 
# Sign the final dmg
codesign -f -s "Developer ID Application: Jeremy Nagel (TCUD568B3U)" -v "Focus Bear.dmg"

#Verify Sign
codesign -vvv --deep --strict "Focus Bear.dmg"

xcrun notarytool submit "Focus Bear.dmg" --wait --apple-id "vishnu.wtl@gmail.com" --password "mmnz-xeky-xmrt-eqgb" --team-id TCUD568B3U

xcrun stapler staple "Focus Bear.dmg"

spctl --assess -vv --type install "Focus Bear.dmg"

