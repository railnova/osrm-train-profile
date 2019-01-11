#!/bin/bash
set -e

docker run -t -v $(pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-extract -p /opt/host/new.lua /opt/host/data/belgium-latest.osm.pbf

docker run -t -v $(pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-partition /opt/host/data/belgium-latest.osrm
docker run -t -v $(pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-customize /opt/host/data/belgium-latest.osrm

docker run -t -i -p 5000:5000 -v $(pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-routed --algorithm mld /opt/host/data/belgium-latest.osrm
