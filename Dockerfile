FROM scratch AS downloader
ADD  https://download.geofabrik.de/europe/austria-latest.osm.pbf .
ADD  https://download.geofabrik.de/europe/belgium-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/croatia-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/czech-republic-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/denmark-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/france-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/germany-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/greece-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/hungary-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/italy-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/luxembourg-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/netherlands-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/poland-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/portugal-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/slovakia-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/slovenia-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/spain-latest.osm.pbf .
ADD https://download.geofabrik.de/europe/switzerland-latest.osm.pbf .

FROM docker.railnova.eu/software/osmium:v0.0.1 AS merger
ADD filter.params .
RUN mkdir /pbf_data_in
RUN mkdir /pbf_data_out
COPY --from=downloader / /pbf_data_in/

WORKDIR /pbf_data_in
RUN for filename in *.osm.pbf; do osmium tags-filter --expressions=../filter.params /pbf_data_in/$filename -o /pbf_data_out/$filename --overwrite; done

RUN osmium merge /pbf_data_out/*.osm.pbf -o /pbf_data_out/filtered.osm.pbf --overwrite

FROM osrm/osrm-backend:v5.20.0

RUN mkdir -p /opt/host/output
COPY --from=merger /pbf_data_out/filtered.osm.pbf /opt/host/output/.
ADD freight.lua /opt/host/freight.lua
RUN osrm-extract -p /opt/host/freight.lua /opt/host/output/filtered.osm.pbf
RUN osrm-partition /opt/host/output/filtered.osm.pbf
RUN osrm-customize /opt/host/output/filtered.osm.pbf
RUN rm /opt/host/output/filtered.osm.pbf
RUN mv /opt/host/output /osrm-files
