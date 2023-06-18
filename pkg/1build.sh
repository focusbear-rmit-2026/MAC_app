#!/bin/bash

# Name of the package.
NAME="Late No More"

# Once installed the identifier is used as the filename for a receipt files in /var/db/receipts/.
IDENTIFIER="com.focusbear.latenomore"

# Package version number.
VERSION="1.0"

# The location to copy the contents of files.
INSTALL_LOCATION="/"


# Remove any unwanted .DS_Store files.
find files/ -name '*.DS_Store' -type f -delete

# Set full read, write, execute permissions for owner and just read and execute permissions for group and other.
/bin/chmod -R 755 files

# Remove any extended attributes (ACEs).
/usr/bin/xattr -rc files

# Build package.
/usr/bin/pkgbuild \
--root files/ \
--install-location "$INSTALL_LOCATION" \
--scripts scripts/ \
--identifier "$IDENTIFIER" \
--version "$VERSION" \
"$NAME-$VERSION.pkg" \

#--sign "${IDENTITY}" \

#Manish:commenting the below line as we are using the hard code distribution.xml
#productbuild --synthesize --package ./"$NAME-$VERSION.pkg" distribution.xml

#Manish: change distribution. xml now
#Manish: Fire 2build.sh now

