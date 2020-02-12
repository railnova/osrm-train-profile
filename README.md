# OSRM Lua profile for trains

This repo contains a profile for routing (mostly freight) trains with [OSRM](http://project-osrm.org/). This enables you to find the shortest path by train between 2 points and also do map matching with OSRM.

*Note:* travel time estimations are way too optimistic due to the red lights, stations and traffic not taken into account

Right now, it contains, 2 profiles :

## `basic.lua`
A basic/naive profile that works quite well.

## `freight.lua`
A profile optimized for freight trains:

* Default speed is 130 km/h
* Highspeed lines are de-prioritized
* Has flags to completely exclude highspeed lines and/or non electrified segments
* Rejects all gauges that are not 1435mm

Possible improvements that we might one day include :

* Preferred left-hand driving even where OSM does not specify it (if you know how to implement it, please be in touch !)
* Better turn restrictions/penalties
* Speed limitation in curves
* Time penalty for traffic lights or when passing trough stations

![screenshot of the demo](.screenshot.png)


Inspiration for the code taken from [an old russian blog](https://web.archive.org/web/20170608052036/http://flexnst.ru/2015/11/20/osrm-railway-profile/) and [the car profile](https://github.com/Project-OSRM/osrm-backend/blob/master/profiles/car.lua)

# How to run this?

First, you will need to install the Docker daemon and osmium (`osmium-tool` on Ubuntu) on your machine.
Then, run `make` to download the OSM data, filter and combine it and finally compute the routing graph.

Last, run `make serve` to serve the OSRM server locally on port `5000`

# License

This code is under the 2-Clause BSD License.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
