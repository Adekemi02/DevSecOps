#!/bin/sh

DC_VERSION="latest"
DC_DIRECTORY=$PWD/OWASP-Dependency-Check
DC_PROJECT="django.nV"
REPORT_DIRECYORY= "$PWD/reports"
DATA_DIRECTORY="$DC_DIRECTORY/data"
CACHE_DIRECTORY="$DC_DIRECTORY/data/cache"
NVD_API_KEY="<NVD_API_KEY>"

if [ ! -d "$DATA_DIRECTORY" ]; then
    echo "Initially creating persistent directory: $DATA_DIRECTORY"
    mkdir -p "$DATA_DIRECTORY"
    chmod -R 777 "$DATA_DIRECTORY"
    mkdir -p "$REPORT_DIRECTORY"
    chmod -R 777 "$REPORT_DIRECTORY"
fi
if [ ! -d "$CACHE_DIRECTORY" ]; then
    echo "Initially creating persistent directory: $CACHE_DIRECTORY"
    mkdir -p "$CACHE_DIRECTORY"
fi

# Make sure we are using the latest version
docker pull owasp/dependency-check:$DC_VERSION


    
docker run --rm \
    -e user=$USER \
    -u $(id -u ${USER}):$(id -g ${USER}) \
    --volume $(pwd):/src \
    --volume "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    --volume $REPORT_DIRECTORY:/reports \
    hysec/dependency-check:$DC_VERSION \
    # owasp/dependency-check:$DC_VERSION \
    --scan /src \
    --format "JSON" \
    --project "$DC_PROJECT" \
    --out /reports \
    --nvdApiKey "$NVD_API_KEY"
    # Use suppression like this: (where /src == $pwd)
    # --suppression "/src/security/dependency-check-suppression.xml"