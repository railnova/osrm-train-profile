-- Copyright 2017-2019 Railnova SA <support@railnova.eu>, Nikita Marchant <nikita.marchant@gmail.com>
-- Code under the 2-clause BSD license

api_version = 4

Set = require('lib/set')
Sequence = require('lib/sequence')

function setup()
  return {
    properties = {
      max_speed_for_map_matching     = 220/3.6, -- speed conversion to m/s
      weight_name                    = 'duration',
      left_hand_driving              = true,
      continue_straight_at_waypoint  = false,
      max_angle                      = 30,

      secondary_speed                = 30,
      speed                          = 130,
    },

    default_mode              = mode.train,
    default_speed             = 120,


    -- classes to support for exclude flags
    excludable = Sequence {
        Set {'highspeed'},
        Set {'notelectric'},
    },
}

end


function ternary ( cond , T , F )
    if cond then return T else return F end
end


function process_node(profile, node, result, relations)
    local railway = node:get_value_by_key("railway")

    -- refuse railway nodes that we cannot go through
    result.barrier = (
        railway == "buffer_stop" or
        railway == "derail"
    )
    result.traffic_lights = false
end

function process_way(profile, way, result, relations)
    local data = {
        railway = way:get_value_by_key("railway"),
        service = way:get_value_by_key("service"),
        usage = way:get_value_by_key("usage"),
        name = way:get_value_by_key("name"),
        ref = way:get_value_by_key("ref"),
        maxspeed = way:get_value_by_key("maxspeed"),
        gauge = way:get_value_by_key("gauge"),

        oneway = way:get_value_by_key("oneway"),
        preferred = way:get_value_by_key("railway:preferred_direction"),

        highspeed = way:get_value_by_key("highspeed") == "yes",
        electrified = way:get_value_by_key("electrified"),
        trafic_mode = way:get_value_by_key("railway:traffic_mode"),
    }

    -- Remove everything that is not railway
    if not data.railway then
        return
    -- Remove everything that is not a rail, a turntable, a traverser
    elseif (
        data.railway ~= 'rail' and
        data.railway ~= 'turntable' and
        data.railway ~= 'traverser'
    ) then
        return
    -- Remove military and tourism rails
    elseif (
        data.usage == "military" or
        data.usage == "tourism"
    ) then
        return
    -- Keep only most common gauges (and undefined)
    -- uses .find() as some gauges are specified like "1668;1435"
    elseif (
        data.gauge ~= nil and
        data.gauge ~= 1000 and not string.find(data.gauge, "1000") and
        data.gauge ~= 1435 and not string.find(data.gauge, "1435") and
        data.gauge ~= 1520 and not string.find(data.gauge, "1520") and
        data.gauge ~= 1524 and not string.find(data.gauge, "1524") and
        data.gauge ~= 1600 and not string.find(data.gauge, "1600") and
        data.gauge ~= 1668 and not string.find(data.gauge, "1668")
    ) then
        return
    end

    local is_secondary = (
        data.service == "siding" or
        data.service == "spur" or
        data.service == "yard" or
        data.usage == "industrial"
    )

    -- by default, use 30km/h for secondary rails, else 130
    local default_speed = ternary(is_secondary, profile.properties.secondary_speed, profile.properties.speed)
    -- but is OSM specifies a maxspeed, use the one from OSM
    local speed = ternary(data.maxspeed, data.maxspeed, default_speed)

   -- fix speed for mph issue
    speed = tostring(speed)
    if speed:find(" mph") or speed:find("mph") then
      speed = speed:gsub(" mph", "")
      speed = speed:gsub("mph", "")
        speed = tonumber (speed)
        if speed == nil then speed = 20 end
	speed = speed * 1.609344
    else
     speed = tonumber (speed)
    end
    -- fix speed for mph issue end

    result.forward_speed = speed
    result.backward_speed = speed
    --
    result.forward_mode = mode.train
    result.backward_mode = mode.train
    --
    result.forward_rate = 1
    result.backward_rate = 1
    --
    if data.oneway == "no" or data.oneway == "0" or data.oneway == "false" then
        -- both ways are ok, nothing to do
    elseif data.oneway == "-1" then
        -- opposite direction
        result.forward_mode = mode.inaccessible
    elseif data.oneway == "yes" or data.oneway == "1" or data.oneway == "true" then
        -- oneway
        result.backward_mode = mode.inaccessible
    end

    if data.preferred == "forward" then
        result.backward_rate = result.backward_rate - 0.3
    elseif data.preferred == "backward" then
        result.forward_rate = result.forward_rate - 0.3
    end

    -- Take the name of the rail, else the reference
    -- in most cases, both are not specified so this is not very good
    -- TODO: it might be usefull to look at the relation name
    result.name = ternary(data.name, data.name, data.ref)

    -- Slightly decrease the preference on highspeed rails to avoid them if possible
    if data.highspeed then
        result.forward_classes["highspeed"] = true
        result.backward_classes["highspeed"] = true
        result.forward_rate = result.forward_rate - 0.2
        result.backward_rate = result.backward_rate - 0.2
        result.forward_speed = 5
        result.backward_speed = 5
    end

    if data.is_secondary then
        result.forward_rate = result.forward_rate - 0.1
        result.backward_rate = result.backward_rate - 0.1
    end

    if (
        data.electrified == "no" or
        data.electrified == "rail"
    ) then
        result.forward_classes["notelectric"] = true
        result.backward_classes["notelectric"] = true
    end

    -- possible values for trafic_mode : freight, passenger or mixed
    -- Slightly increase the preference on freight and slightly decrease it for passenger
    if data.trafic_mode == "freight" then
        result.forward_rate = result.forward_rate + 0.1
        result.forward_rate = result.backward_rate + 0.1
    elseif data.trafic_mode == "passenger" then
        result.forward_rate = result.forward_rate - 0.1
        result.forward_rate = result.backward_rate - 0.1
    end

    -- Restrict secondary to be used only at start or end
    -- result.forward_restricted = is_secondary
    -- result.backward_restricted = is_secondary


end

function process_turn(profile, turn)
    local angle = math.abs(turn.angle)
    if angle > 60 then
        if turn.is_u_turn or angle > 90 then -- any u-turns are switch reversals, add 5 mins penalty
            turn.duration = turn.duration + 3000
        else
            turn.duration = turn.duration + 50
        end
    else
        turn.duration = turn.duration + 50
    end
end

return {
  setup = setup,
  process_way = process_way,
  process_node = process_node,
  process_turn = process_turn
}
