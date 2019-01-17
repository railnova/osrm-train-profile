.PRECIOUS: %.pbf

filtered/%.osm.pbf: world/%.osm.pbf filter.params
	osmium tags-filter --expressions=filter.params $< -o $@ --overwrite

output/filtered.osm.pbf: $(patsubst world/%.osm.pbf,filtered/%.osm.pbf,$(wildcard world/*.osm.pbf))
	osmium merge $^ -o $@ --overwrite

debug:
	echo "$(patsubst world/%-latest.osm.pbf,filtered/%.osm.pbf,$(wildcard world/*.osm.pbf))"


output/filtered.osrm: output/filtered.osm.pbf freight.lua
	docker run -t -v $(shell pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-extract -p /opt/host/freight.lua /opt/host/$<

	docker run -t -v $(shell pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-partition /opt/host/$<
	docker run -t -v $(shell pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-customize /opt/host/$<


# data/small.geojson: output/filtered.osrm
# 	docker run -t -v $(shell pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-components /opt/host/output/filtered.osrm /opt/host/data/small.geojson
#
# data/small.mbtiles: data/small.geojson
# 	tippecanoe -o data/small.mbtiles -zg --drop-densest-as-needed data/small.geojson


serve: output/filtered.osrm freight.lua
	docker run -t -i -p 5000:5000 -v $(shell pwd):/opt/host osrm/osrm-backend:v5.20.0 osrm-routed --algorithm mld /opt/host/$<
