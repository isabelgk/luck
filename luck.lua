-- luck
--
-- seven nodes to grant you 
-- good fortune
--
--
-- @iggylabs 2021
--
-- E1: mode
-- E2: select node 
-- E3: set value
-- K2: start/stop
-- K3: hold down for probability 
--     mode


engine.name = "PolyPerc"
MusicUtil = require "musicutil"

notes_off_metro = metro.init()
play = false

local node_index = 1

local node_to_play = 1

local mode_index = 1
local mode_names = {"pitch", "vel"}

local pitch_index = 1
local pitches = {48, 50, 52, 53, 55, 57, 59}

local vel_index = 1
local vels = {100, 100, 100, 100, 100, 100, 100}

local prob_mode = false
local prob_mode_node = 1
local probs = {
    {0, 7, 0, 0, 0, 0, 0},
    {0, 0, 7, 0, 0, 0, 0},
    {0, 0, 0, 7, 0, 0, 0},
    {0, 0, 0, 0, 7, 0, 0},
    {0, 0, 0, 0, 0, 7, 0},
    {0, 0, 0, 0, 0, 0, 7},
    {7, 0, 0, 0, 0, 0, 0}
}


-- =====
-- SETUP
-- =====
function init()
    params:add_number("tempo", "tempo", 20, 240, 88)
    counter = metro.init(tick, 0.25, -1)
    counter:stop()
end

-- ===========
-- TIME + PLAY
-- ===========
local function get_next_node(current_node)
    local ps = probs[current_node]  -- Probabilities for current node
    local weighted_list = {}

    -- For each probability (0-7), insert that number of elements (the
    -- value of the node index) into the weighted list
    for i = 1, 7 do  -- Each node index
        local p = probs[current_node][i]  -- Probability for currently editing node
        if p > 0 then
            for j = 1, p do
                table.insert(weighted_list, i)  -- Add that many times into weighted list
            end
        end
    end

    -- Now pick randomly from the weighted list and get back the index of the next node
    return weighted_list[math.random(#weighted_list)]
end

local function midi_to_hz(note)
    return (440 / 32) * (2 ^ ((note - 9) / 12))
end

function tick(c)
    -- Get next node from the last played one
    node_to_play = get_next_node(node_to_play)

    -- Play note
    engine.amp(vels[node_to_play] / 127)
    engine.hz(midi_to_hz(pitches[node_to_play]))

    -- Redraw the screen
    redraw()
end


-- ========
-- INTERACT
-- ========
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
    if n == 2 and z == 1 then
        if play then
            play = false
            counter:stop()
        else
            play = true
            counter:start()
        end
    elseif n == 3 then
        if z == 1 then
            prob_mode = true
        else
            prob_mode = false
            prob_mode_node = node_index
        end
    end

    redraw()
end

-- ========
-- DRAWING
-- =========
local full_rad = 21  -- Looks nice with this radius
local node_rad = 7
local left_margin = 64
local top_margin = 32

function indicator_draw(index)
    local theta = (2 * math.pi / 7) * index
    theta = theta + math.pi  -- Rotate 180 degrees

    -- To Cartesian:
    local x = (full_rad + node_rad + 3) * math.cos(theta) + left_margin  -- Centered horizontally
    local y = (full_rad + node_rad + 3) * math.sin(theta) + top_margin  -- Centered vertically

    -- Make any of the previous movement invisible
    -- screen.level(0)
    -- screen.stroke()
    
    -- Draw the circle
    screen.line_width(1)
    screen.level(8)
    screen.circle(x, y, 2)
    screen.fill()
    screen.stroke()
end

local function node_draw(index, level, line_width)
    local theta = (2 * math.pi / 7) * index
    theta = theta + math.pi  -- Rotate 180 degrees

    -- To Cartesian:
    local x = full_rad * math.cos(theta) + left_margin  -- Centered horizontally
    local y = full_rad * math.sin(theta) + top_margin  -- Centered vertically

    -- Make any of the previous movement invisible
    screen.level(0)
    screen.stroke()
    
    -- Draw the circle
    screen.line_width(line_width)
    screen.circle(x, y, node_rad)
    screen.level(level)
    screen.stroke()

    -- Draw the probability connections
    local center_x = left_margin
    local center_y = top_margin
    local from_x = (full_rad - node_rad) * math.cos(theta) + left_margin
    local from_y = (full_rad - node_rad) * math.sin(theta) + top_margin

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
end

local function mode_info_text_draw(i)
    screen.font_size(8)
    screen.move(0, 60)
    screen.level(4)
    if mode_index == 1 then  -- pitch
        screen.text(MusicUtil.note_num_to_name(pitches[i], true))
    elseif mode_index == 2 then  -- velocity
        screen.text(tostring(vels[i]))
    end
end

local function prob_text_draw(index)
    local theta = (2 * math.pi / 7) * index
    theta = theta + math.pi  -- Rotate 180 degrees

    -- To Cartesian:
    local x = full_rad * math.cos(theta) + left_margin  -- Centered horizontally
    local y = full_rad * math.sin(theta) + top_margin  -- Centered vertically
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

    if prob_mode then
        mode_info_text_draw(prob_mode_node)
    else
        mode_info_text_draw(node_index)
    end

    -- draw node
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
        prob_text_draw(i)
        if i == node_to_play and play then
            indicator_draw(i)
        end
    end

    screen.update()
end