#!/bin/sh
set -e

# ---------------------------------------------------------------------------- #
#
# Run the Behat/WebDriverIO tests.
#
# ---------------------------------------------------------------------------- #

# Check the current build.
if [ -z ${BUILD_SERVER+x} ] || [ "$BUILD_SERVER" -ne 1 ]; then
 exit 0;
fi

docker run -it -p 8080:80 server -e BUILD_WEBDRIVERIO=$BUILD_WEBDRIVERIO
