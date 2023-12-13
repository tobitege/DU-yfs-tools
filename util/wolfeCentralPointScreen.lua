vec2 = vec2 or require('cpml.vec2')
vec3 = vec3 or require('cpml.vec3')

--------------------------------------
-- Configuration
--------------------------------------

-- Pulls upstream config
local config = data.config or {}

-- How large each dot is
local dot_size = 2

-- How many meters from center to screen edge
local screen_radius = config.screen_radius or 3000

-- The grid circles
local grid_size = config.grid_size or 500

-- Colors to be used
local colors = {
  background = { 0.1, 0.1, 0.1 },
  overlay = { 0, 0, 0, 0.5 },
  guides = {
    main = { 0, 0.5, 1.5, 0.2 },
    secondary = { 0, 0.5, 1.5, 0.15 },
  },
  center = { 0, 2, 1 },
  points = { 0, 2, 2 },
  messages = { 0.6, 0.6, 0.6 },
}

-- Spacing
local spacing = { 8, 8 }

-- Font to be used
local fonts = {
  title = loadFont('Oxanium', 30),
  main = loadFont('Oxanium', 24),
  sub = loadFont('Oxanium', 15),
}

--------------------------------------
-- Helpers
--------------------------------------

local screen_width, screen_height = getResolution()
local cursor = vec2(getCursor())

-- How close to detect hover
local proximity_distance = 0.02 * screen_height

-- Helper function to convert color tables
local function rgba(color)
  return color[1], color[2], color[3], color[4] or 1
end

-- Draws a small dot
local function draw_dot(layer, x, y, color, hover_handler, click_handler)
  setNextFillColor(layer, rgba(color))
  addCircle(layer, x, y, dot_size)

  local is_hovering = (vec2(x, y) - cursor):len() <= proximity_distance

  if hover_handler and is_hovering then
    hover_handler()
  end

  if click_handler and is_hovering and getCursorReleased() then
    click_handler()
  end
end

-- Draws a circle
local function draw_circle(layer, x, y, radius, color)
  setNextStrokeWidth(layer, 1)
  setNextStrokeColor(layer, rgba(color))
  setNextFillColor(layer, rgba({ 0, 0, 0, 0 }))
  addCircle(layer, x, y, radius)
end

-- Draws line
local function draw_line(layer, x1, y1, x2, y2, color)
  setNextStrokeColor(layer, rgba(color))
  addLine(layer, x1, y1, x2, y2)
end

-- Draws an overlay
local function draw_overlay(layer)
  setNextFillColor(layer, rgba(colors.overlay))
  addBox(layer, 0, 0, screen_width, screen_height)
end

-- Draws info box
local function draw_info_box(layer, x, y, title, rows, color)
  draw_line(layer, x, y, x + 150, y, color)

  if title then
    setNextFillColor(layer, rgba(color))
    setNextTextAlign(layer, AlignH_Left, AlignV_Bottom)
    addText(layer, fonts.sub, tostring(title), x + spacing[1], y - spacing[1])
  end

  local next_x = x + spacing[1]
  local next_y = y + spacing[2]
  for _, row in pairs(rows) do
    local text = row
    local font = fonts.main
    if 'table' == type(row) then
      font = fonts[row[1]]
      text = row[2]
    end
    local font_size = getFontSize(font)

    setNextFillColor(layer, rgba(color))
    setNextTextAlign(layer, AlignH_Left, AlignV_Top)
    addText(layer, font, tostring(text), next_x, next_y)
    next_y = next_y + font_size
  end
end

-- Draws cursor
local function draw_cursor(layer)
  local cursor_size = 16
  local x, y = cursor:unpack()

  if x and y and x + y > 0 then
    setNextShadow(layer, 0.25 * cursor_size, 0, 0, 0, 1)
    setNextFillColor(layer, 1, 1, 1, 1)
    addQuad(
      layer, 
      x, y, 
      x + cursor_size, y + 0.5 * cursor_size,
      x + 0.5 * cursor_size, y + 0.5 * cursor_size,
      x + 0.5 * cursor_size, y + cursor_size
    )
  end
end

--------------------------------------
-- Main render logic
--------------------------------------

setBackgroundColor(rgba(colors.background))

-- Pre-calculate center of screen
local screen_center_x, screen_center_y = 0.5 * screen_width, 0.5 * screen_height

-- Check if we have data
if not data.is_activated then
  -- Offline mode
  local layer = createLayer()

  setNextTextAlign(layer, AlignH_Center, AlignV_Bottom)
  setNextFillColor(layer, rgba(colors.messages))
  addText(layer, fonts.title, 'SCRIPT OFFLINE', screen_center_x, screen_center_y - 0.5 * spacing[2])

  setNextTextAlign(layer, AlignH_Center, AlignV_Top)
  setNextFillColor(layer, rgba(colors.messages))
  addText(layer, fonts.sub, 'activate programming board to start', screen_center_x, screen_center_y + 0.5 * spacing[2])
elseif not data.waypoints then
  -- Waiting on input
  local layer = createLayer()

  setNextTextAlign(layer, AlignH_Center, AlignV_Bottom)
  setNextFillColor(layer, rgba(colors.messages))
  addText(layer, fonts.title, 'AWAITING INPUT', screen_center_x, screen_center_y - 0.5 * spacing[2])

  setNextTextAlign(layer, AlignH_Center, AlignV_Top)
  setNextFillColor(layer, rgba(colors.messages))
  addText(layer, fonts.sub, 'input your first coordinate in the Lua chat to start', screen_center_x, screen_center_y + 0.5 * spacing[2])
else
  -- Normal operation
  local center_body, center_world = data.center.body, vec3(data.center.world)

  -- Intializes render script
  local layer_background, layer_data, layer_overlay, layer_info, layer_cursor = createLayer(), createLayer(), createLayer(), createLayer(), createLayer()

  -- Cursor
  draw_cursor(layer_cursor)

  -- Half screen size
  local screen_radius_pixels = screen_center_y

  -- Renders guides
  for radius = grid_size, screen_radius, grid_size do
    local pixel_radius = screen_radius_pixels * radius / screen_radius
    local color = colors.guides.secondary
    if radius % 1000 == 0 then
      color = colors.guides.main
    end

    draw_circle(layer_background, screen_center_x, screen_center_y, pixel_radius, color)

    setNextFillColor(layer_background, rgba(color))
    setNextTextAlign(layer_background, AlignH_Center, AlignV_Top)
    addText(layer_background, fonts.sub, radius .. 'm', screen_center_x, screen_center_y + pixel_radius + 0.5 * spacing[2])
  end

  -- Renders center dot
  draw_dot(layer_data, screen_center_x, screen_center_y, colors.center, function()
    draw_circle(layer_info, screen_center_x, screen_center_y, proximity_distance, colors.center)
    draw_overlay(layer_overlay)
    draw_info_box(layer_info, screen_center_x + proximity_distance, screen_center_y, nil, {
      'center point',
      { 'sub', 'click to set waypoint' },
    }, colors.center)
  end, function()
    -- Sets waypoint on click
    setOutput(('{%s,%s,%s}'):format(center_world:unpack()))
  end)

  -- Renders waypoints
  for _, waypoint in pairs(data.waypoints or {}) do
    local lat, lng = waypoint.body.lat - center_body.lat, waypoint.body.lng - center_body.lng

    local offset = vec2(lng, lat * -1)
    local distance = (vec3(waypoint.world) - center_world):len()

    -- Don't render anything outside screen
    if distance <= screen_radius then
      -- Calculates pixel position
      local pixel = vec2(0.5 * screen_width, 0.5 * screen_height) + offset:normalize() * screen_radius_pixels * distance / screen_radius

      -- Draws point on "map"
      draw_dot(layer_data, pixel.x, pixel.y, colors.points, function()
        -- Draws extra info on hover
        draw_circle(layer_info, pixel.x, pixel.y, proximity_distance, colors.points)
        draw_overlay(layer_overlay)
        draw_info_box(layer_info, pixel.x + proximity_distance, pixel.y, waypoint.label, {
          ('%.2fm'):format(distance),
          { 'sub', 'click to set waypoint' },
        }, colors.points)
      end, function()
        -- Sets waypoint on click
        setOutput(('{%s,%s,%s}'):format(vec3(waypoint.world):unpack()))
      end)
    end
  end

  requestAnimationFrame(1)
end