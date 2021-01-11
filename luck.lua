-- luck
--
-- seven nodes to grant you 
-- good fortune
--
-- E1: mode
-- E2: 
-- E3: set value

MusicUtil = require "musicutil"

--local screen_dirty = true

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
local probs = {
    {7, 7, 7, 7, 7, 7, 7},
    {7, 7, 7, 7, 7, 7, 7},
    {7, 7, 7, 7, 7, 7, 7},
    {7, 7, 7, 7, 7, 7, 7},
    {7, 7, 7, 7, 7, 7, 7},
    {7, 7, 7, 7, 7, 7, 7},
    {7, 7, 7, 7, 7, 7, 7}
}


function enc(n, delta)
    -- Changing modes
    if n == 1 then
        mode_index = util.clamp(mode_index + delta, 1, 2)

    -- Changing nodes
    elseif n == 2 then
        node_index = (node_index + delta - 1) % 7 + 1
        -- Update respective mode indices
        if mode_index == 1 then
            pitch_index = node_index
        elseif mode_index == 2 then
            vel_index = node_index
        end

    -- Changing values
    else
        if mode_index == 1 then  -- Update current pitch
            local old_val = pitches[pitch_index]
            pitches[pitch_index] = util.clamp(old_val + delta, 0, 127)
        elseif mode_index == 2 then
            local old_val = vels[vel_index]
            vels[vel_index] = util.clamp(old_val + delta, 0, 127)
        end
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
        prob_mode = z
    end

    redraw()
end

-- DRAWING
local function node_draw(index, level, line_width)
    local theta = (2 * math.pi / 7) * (index);
    theta = theta + math.pi;  -- Rotate 180 degrees
    local full_rad = 22  -- Looks nice with this radius
    local node_rad = 8

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
    -- local 

    for i = 1, 7 do

        screen.level(probs[index][i] * 2)
        if i == index then

        else
        
        end
    end


    -- Write the text
    screen.font_size(8)
    screen.move(0, 60)
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
            l, w = 8, 2
        else
            l, w = 1, 1
        end
        node_draw(i, l, w)
    end

    screen.update()
end