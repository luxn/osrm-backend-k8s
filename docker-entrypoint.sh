#!/bin/bash

if [ "$OSRM_MODE" != "CREATE" ] && [ "$OSRM_MODE" != "RESTORE" ]; then
    # Default to CREATE
    OSRM_MODE="CREATE"
fi

# Defaults
OSRM_DATA_PATH=${OSRM_DATA_PATH:="/osrm-data"}
OSRM_DATA_LABEL=${OSRM_DATA_LABEL:="data"}
OSRM_GRAPH_PROFILE=${OSRM_GRAPH_PROFILE:="car"}
OSRM_PBF_URL=${OSRM_PBF_URL:="http://download.geofabrik.de/asia/maldives-latest.osm.pbf"}

# AWS variables
OSRM_AWS_ACCESS_KEY_ID=${OSRM_AWS_ACCESS_KEY_ID:=""}
OSRM_AWS_SECRET_ACCESS_KEY=${OSRM_AWS_SECRET_ACCESS_KEY:=""}
OSRM_AWS_DEFAULT_REGION=${OSRM_AWS_DEFAULT_REGION:=""}
OSRM_AWS_S3_BUCKET=${OSRM_AWS_S3_BUCKET:=""}
OSRM_MAX_TABLE_SIZE=${OSRM_MAX_TABLE_SIZE:="8000"}

export AWS_ACCESS_KEY_ID=$OSRM_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$OSRM_AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$OSRM_AWS_DEFAULT_REGION

_sig() {
  kill -TERM $child 2>/dev/null
}
trap _sig SIGKILL SIGTERM SIGHUP SIGINT EXIT


if [ "$OSRM_MODE" == "CREATE" ]; then    
    # Retrieve the PBF file
    curl -L $OSRM_PBF_URL --create-dirs -o $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osm.pbf
    
    # Build the graph
    osrm-extract $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osm.pbf -p /osrm-profiles/$OSRM_GRAPH_PROFILE.lua
    osrm-contract $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osrm

    if [ ! -z "$OSRM_AWS_ACCESS_KEY_ID" ] && [ ! -z "$OSRM_AWS_SECRET_ACCESS_KEY" ] && [ ! -z "$OSRM_AWS_S3_BUCKET" ] && [ ! -z "$OSRM_AWS_S3_BUCKET" ]; then    
        # Copy the graph to storage
        awscli s3 cp -m cp $OSRM_DATA_PATH/ $OSRM_AWS_S3_BUCKET/$OSRM_DATA_LABEL --exclude="*" --include="*.osrm*"
    fi    
else
    if [ ! -z "$OSRM_AWS_ACCESS_KEY_ID" ] && [ ! -z "$OSRM_AWS_SECRET_ACCESS_KEY" ] && [ ! -z "$OSRM_AWS_S3_BUCKET" ] && [ ! -z "$OSRM_AWS_S3_BUCKET" ]; then
        # Copy the graph from storage
        awscli s3 cp -m cp $OSRM_AWS_S3_BUCKET/$OSRM_DATA_LABEL/ $OSRM_DATA_PATH --exclude="*" --include="*.osrm*"
    fi    
fi

# Start serving requests
osrm-routed $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osrm --max-table-size $OSRM_MAX_TABLE_SIZE &
child=$!
wait "$child"
