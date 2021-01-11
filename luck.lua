-- luck
--
-- seven nodes to grant you 
-- good fortune
--
-- E1: mode
-- E2: 
-- E3: set value

MusicUtil = require "musicutil"

notes_off_metro = metro.init()
play = false

local node_index = 1

local mode_index = 1
local mode_names = {"pitch", "vel"}

local pitch_index = 1
local pitches = {44, 45, 46, 47, 48, 49, 50}

local vel_index = 1
local vels = {100, 100, 100, 0, 100, 100, 0}

local prob_mode = false
local prob_mode_node = 1
local probs = {
    {1, 7, 1, 1, 1, 1, 1},
    {1, 1, 7, 1, 1, 1, 1},
    {1, 1, 1, 7, 1, 1, 1},
    {1, 1, 1, 1, 7, 1, 1},
    {1, 1, 1, 1, 1, 7, 1},
    {1, 1, 1, 1, 1, 1, 7},
    {7, 1, 1, 1, 1, 1, 1}
}


function enc(n, delta)
    -- Changing modes
    if n == 1 and prob_mode == false then
        mode_index = util.clamp(mode_index + delta, 1, 2)

    -- Changing nodes
    elseif n == 2 and prob_mode == false then
        node_index = (node_index + delta - 1) % 7 + 1
        prob_mode_node = node_index
        -- Update respective mode indices
        if mode_index == 1 then
            pitch_index = node_index
        elseif mode_index == 2 then
            vel_index = node_index
        end
    elseif n == 2 and prob_mode == true then
        prob_mode_node = (prob_mode_node + delta - 1) % 7 + 1
    
    -- Changing values
    elseif n == 3 and prob_mode == false then
        if mode_index == 1 then  -- Update current pitch
            local old_val = pitches[pitch_index]
            pitches[pitch_index] = util.clamp(old_val + delta, 0, 127)
        elseif mode_index == 2 then
            local old_val = vels[vel_index]
            vels[vel_index] = util.clamp(old_val + delta, 0, 127)
        end
    elseif n == 3 and prob_mode == true then
        local old_val = probs[node_index][prob_mode_node]
        probs[node_index][prob_mode_node] = util.clamp(old_val + delta, 0, 7)
    end

    redraw()
end

function key(n, z)
    if n == 2 then
        if play then
            play = false
        else
            play = true
        end
    elseif n == 3 then
        if z == 1 then
            prob_mode = true
        else
            prob_mode = false
        end
    end

    redraw()
end

-- DRAWING
local full_rad = 22  -- Looks nice with this radius
local node_rad = 8

local function node_draw(index, level, line_width)
    local theta = (2 * math.pi / 7) * index
    theta = theta + math.pi  -- Rotate 180 degrees

    -- To Cartesian:
    local x = full_rad * math.cos(theta) + 64  -- Centered horizontally
    local y = full_rad * math.sin(theta) + 32  -- Centered vertically

    -- Make any of the previous movement invisible
    screen.level(0)
    screen.stroke()
    
    -- Draw the circle
    screen.line_width(line_width)
    screen.circle(x, y, node_rad)
    screen.level(level)
    screen.stroke()

    -- Draw the probability connections
    local center_x = 64
    local center_y = 32
    local from_x = (full_rad - node_rad) * math.cos(theta) + 64
    local from_y = (full_rad - node_rad) * math.sin(theta) + 32

    if index == node_index then
        for i = 1, 7 do
            local to_theta = (2 * math.pi / 7) * i + math.pi
            local to_x = (full_rad - node_rad) * math.cos(to_theta) + 64
            local to_y = (full_rad - node_rad) * math.sin(to_theta) + 32

            screen.line_width(1)
            screen.level(probs[index][i] * 2)
            screen.curve(from_x, from_y, center_x, center_y, to_x, to_y)
            screen.stroke()
        end
    end

    -- Write the mode text
    screen.font_size(8)
    screen.move(0, 60)
    screen.level(4)
    if mode_index == 1 and index == node_index then  -- pitch
        if pitches[index] then
            screen.text(MusicUtil.note_num_to_name(pitches[index], true))
        else
            print(tostring(index))
        end
    elseif mode_index == 2 and index == node_index then  -- velocity
        if vels[index] then
            screen.text(tostring(vels[index]))
        end
    end
end

local function prob_text_draw(index)
    local theta = (2 * math.pi / 7) * index
    theta = theta + math.pi  -- Rotate 180 degrees

    -- To Cartesian:
    local x = full_rad * math.cos(theta) + 64  -- Centered horizontally
    local y = full_rad * math.sin(theta) + 32  -- Centered vertically
    screen.level(4)
    screen.font_size(8)
    screen.move(x - 1, y + 2)
    screen.text(probs[node_index][index])
    screen.stroke()
end

function redraw()
    screen.clear()

    -- draw mode text
    screen.level(4)
    screen.move(0, 10)
    screen.text(mode_names[mode_index])

    -- draw boxes
    for i = 1, 7 do
        local l, w
        if i == node_index then
            w = 2
        else
            w = 1
        end

        if (i == prob_mode_node and prob_mode == true) or (i == node_index and prob_mode == false) then
            l = 8
        else
            l = 1
        end

        node_draw(i, l, w)

        if prob_mode == true then
            prob_text_draw(i)
        end
    end

    screen.update()
end