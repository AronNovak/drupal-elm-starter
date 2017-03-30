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

# Simple Docker run to execute Behat.
if [ -z ${BUILD_WEBDRIVERIO+x} ]; then
  docker run -it -e "BUILD_WEBDRIVERIO=0" -p 8080:80 server
  exit $?
fi

VIDEO_DIR=/tmp/videos

# Execute our server container alongside with Selenium container for WDIO.
mkdir -p $VIDEO_DIR
cd ci-scripts/docker_files
docker-compose up &
sleep 5
NUM_CONTAINERS=$(docker ps --no-trunc -q | wc -l)

COUNT=0
while [ $NUM_CONTAINERS -gt 1 ]; do
  NUM_CONTAINERS=$(docker ps --no-trunc -q | wc -l)
  ((COUNT++)) && ((COUNT==240)) && break
  sleep 5
done;

# For a maximum of 150 seconds, we wait for the video completion.
COUNT=0
while !(ls $VIDEO_DIR/*mp4 1> /dev/null 2>&1); do
  ((COUNT++)) && ((COUNT==30)) && break
  sleep 5
done;

docker stop $(docker ps -a -q)

# Docker-compose up won't return with non-zero exit code if one of the
# containers failed, we need to inspect it like this.
# from http://blog.ministryofprogramming.com/docker-compose-and-exit-codes/
docker ps -q -a | xargs docker inspect -f '{{ .State.ExitCode }}' | while read code; do
  if [ ! "$code" = "0" || true ]; then
    cd /tmp
    wget https://github.com/prasmussen/gdrive/files/879060/gdrive-linux-x64.zip
    unzip gdrive-linux-x64.zip
    chmod +x ./gdrive
    mkdir ~/.gdrive
    cp $TRAVIS_BUILD_DIR/gdrive-service-account.json ~/.gdrive/
    for VIDEO_FILE in $VIDEO_DIR/*mp4
    do
      echo "Uploading $VIDEO_FILE"
      ID=$(/tmp/gdrive upload --service-account gdrive-service-account.json $VIDEO_FILE | tail -n1 | cut -d ' ' -f 2)
      /tmp/gdrive share --service-account gdrive-service-account.json $ID
      URL=$(/tmp/gdrive info --service-account gdrive-service-account.json $ID  | grep ViewUrl | sed s/ViewUrl\:\ //)
      echo "The video of the failed test case is available from $URL"

      # Todo: post to Github issue as a comment
    done;
    exit $code
  fi
done
exit 0
