-- Razer DeathAdder Essential
--
-- MOUSE4 + wheel:          macOS system volume
-- MOUSE5 + wheel:          Spotify volume
-- MOUSE4 + MOUSE5 + wheel: macOS full-screen zoom
-- MOUSE4 + wheel click:    macOS system mute/unmute
-- MOUSE5 + wheel click:    Spotify play/pause
-- Both buttons + wheel click: no action
-- Wheel alone:             normal scrolling
--
-- Accessibility > Zoom:
-- Enable "Use keyboard shortcuts to zoom"
-- Set Zoom style to "Full Screen"

local event = hs.eventtap.event
local types = event.types
local props = event.properties

local MIDDLE_BUTTON_NUMBER = 2
local MOUSE4_BUTTON_NUMBER = 3
local MOUSE5_BUTTON_NUMBER = 4
local SPOTIFY_VOLUME_STEP_PERCENT = 5
local REVERSE_SCROLL = false

local held = {
  [MOUSE4_BUTTON_NUMBER] = false,
  [MOUSE5_BUTTON_NUMBER] = false,
}
local middleClickIntercepted = false

-- Spotify overlay

local OVERLAY_WIDTH_PT = 304
local OVERLAY_HEIGHT_PT = 78
local OVERLAY_MARGIN_PT = 16
local IDLE_DURATION_SEC = 3.0
local OVERLAY_FADE_DURATION_SEC = 0.15
local SLIDER_X_PT = 38
local SLIDER_Y_PT = 48
local SLIDER_WIDTH_PT = 218

local overlay = hs.canvas.new({
      x = 0,
      y = 0,
      w = OVERLAY_WIDTH_PT,
      h = OVERLAY_HEIGHT_PT,
    }):level("floating")
    :behavior({ "canJoinAllSpaces", "fullScreenAuxiliary" })

overlay:replaceElements(
  {
    type = "rectangle",
    action = "strokeAndFill",
    frame = { x = 6, y = 6, w = 292, h = 64 },
    roundedRectRadii = { xRadius = 24, yRadius = 24 },
    -- Layered translucency approximates the system HUD's glass finish.
    fillGradient = "linear",
    fillGradientAngle = 90,
    fillGradientColors = {
      { white = 0.68, alpha = 0.88 },
      { white = 0.78, alpha = 0.80 },
    },
    strokeColor = { white = 1, alpha = 0.45 },
    strokeWidth = 1,
    withShadow = true,
    shadow = {
      blurRadius = 5,
      color = { white = 0, alpha = 0.20 },
      offset = { w = 0, h = -2 },
    },
  },
  {
    id = "title",
    type = "text",
    text = "Spotify · ⏸︎",
    frame = { x = 22, y = 16, w = 256, h = 22 },
    textFont = hs.styledtext.defaultFonts.boldSystem.name,
    textSize = 14,
    textColor = { white = 1 },
    textAlignment = "left",
  },
  {
    type = "rectangle",
    action = "fill",
    frame = { x = SLIDER_X_PT, y = SLIDER_Y_PT - 2, w = SLIDER_WIDTH_PT, h = 4 },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = { white = 1, alpha = 0.22 },
  },
  {
    id = "volumeFill",
    type = "rectangle",
    action = "fill",
    frame = { x = SLIDER_X_PT, y = SLIDER_Y_PT - 2, w = 0, h = 4 },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = { white = 1 },
  }
)

local function appendSpeaker(xPt, waveCount)
  overlay:appendElements({
    type = "segments",
    action = "fill",
    closed = true,
    coordinates = {
      { x = xPt,     y = SLIDER_Y_PT - 2 },
      { x = xPt + 3, y = SLIDER_Y_PT - 2 },
      { x = xPt + 7, y = SLIDER_Y_PT - 6 },
      { x = xPt + 7, y = SLIDER_Y_PT + 6 },
      { x = xPt + 3, y = SLIDER_Y_PT + 2 },
      { x = xPt,     y = SLIDER_Y_PT + 2 },
    },
    fillColor = { white = 1 },
  })

  for waveIndex = 1, waveCount do
    overlay:appendElements({
      type = "arc",
      action = "stroke",
      center = { x = xPt + 7, y = SLIDER_Y_PT },
      radius = 2 + waveIndex * 3,
      startAngle = 50,
      endAngle = 130,
      arcRadii = false,
      strokeColor = { white = 1 },
      strokeWidth = 1,
      strokeCapStyle = "round",
    })
  end
end

appendSpeaker(22, 0)
appendSpeaker(266, 3)

local spotifyTargetVolumePercent
local spotifyVolumeTask
local spotifyTargetState
local spotifyStateTask
local idleTimer = hs.timer.delayed.new(IDLE_DURATION_SEC, function()
  overlay:hide(OVERLAY_FADE_DURATION_SEC)
  if not spotifyVolumeTask then spotifyTargetVolumePercent = nil end
  if not spotifyStateTask then spotifyTargetState = nil end
end)

local function showOverlay(volumePercent, title)
  local screen = hs.mouse.getCurrentScreen()
      or hs.screen.mainScreen()
  local screenFramePt = screen:frame()

  overlay:frame({
    x = screenFramePt.x + screenFramePt.w - OVERLAY_WIDTH_PT - OVERLAY_MARGIN_PT,
    y = screenFramePt.y + 8,
    w = OVERLAY_WIDTH_PT,
    h = OVERLAY_HEIGHT_PT,
  })

  overlay.volumeFill.frame.w = SLIDER_WIDTH_PT * volumePercent / 100
  overlay.title.text = title
  overlay:show()
  idleTimer:start()
end

local function checkSpotifyRunning()
  if #hs.application.applicationsForBundleID("com.spotify.client") > 0 then return true end

  spotifyTargetVolumePercent = nil
  if not spotifyStateTask then spotifyTargetState = nil end
  showOverlay(0, "Spotify · not running")
  return false
end

local function spotifyStateError(err)
  spotifyTargetState = nil
  if not checkSpotifyRunning() then return end

  overlay:hide(OVERLAY_FADE_DURATION_SEC)
  print("Spotify playback error: " .. err)
end

local function getSpotifyTargetState()
  if spotifyTargetState == nil then
    spotifyTargetState = hs.spotify.getPlaybackState()
    if spotifyTargetState == nil then spotifyStateError("could not read playback state") end
  end
  return spotifyTargetState
end

local function getSpotifyPlaybackTitle()
  local playing = spotifyTargetState == hs.spotify.state_playing
  return "Spotify · " .. (playing and "▶︎" or "⏸︎")
end

local function showVolume(volumePercent)
  if not getSpotifyTargetState() then return end
  showOverlay(volumePercent, getSpotifyPlaybackTitle())
end

-- macOS system volume

local function systemVolume(directionSign)
  local key = directionSign > 0 and "SOUND_UP" or "SOUND_DOWN"
  event.newSystemKeyEvent(key, true):post()
  event.newSystemKeyEvent(key, false):post()
end

local function systemMute()
  event.newSystemKeyEvent("MUTE", true):post()
  event.newSystemKeyEvent("MUTE", false):post()
end

-- Spotify volume

local function spotifyVolumeError(err)
  spotifyTargetVolumePercent = nil
  if not checkSpotifyRunning() then return end

  idleTimer:stop()
  if not spotifyStateTask then spotifyTargetState = nil end
  overlay:hide(OVERLAY_FADE_DURATION_SEC)
  print("Spotify volume error: " .. err)
end

local function sendSpotifyVolume()
  local spotifySentVolumePercent = spotifyTargetVolumePercent
  local script = string.format([[
    if application "Spotify" is not running then error "Spotify is not running"
    tell application "Spotify" to set sound volume to %d
  ]], spotifySentVolumePercent)

  -- Keep input responsive while Spotify applies this snapshot of the target.
  spotifyVolumeTask = hs.task.new("/usr/bin/osascript", function(exitCode, _, err)
    spotifyVolumeTask = nil
    if exitCode ~= 0 then
      spotifyVolumeError(err)
      return
    end

    if spotifyTargetVolumePercent and spotifyTargetVolumePercent ~= spotifySentVolumePercent then
      sendSpotifyVolume()
    elseif not idleTimer:running() then
      -- The idle timer may have expired while the final write was running.
      spotifyTargetVolumePercent = nil
    end
  end, { "-e", script })

  if not spotifyVolumeTask or not spotifyVolumeTask:start() then
    spotifyVolumeTask = nil
    spotifyVolumeError("could not start osascript")
  end
end

local function spotifyVolume(directionSign)
  if not checkSpotifyRunning() then return end

  if spotifyTargetVolumePercent == nil then
    spotifyTargetVolumePercent = hs.spotify.getVolume()
    if spotifyTargetVolumePercent == nil then
      spotifyVolumeError("could not read volume")
      return
    end
  end

  local targetVolumePercent = math.max(
    0,
    math.min(100, spotifyTargetVolumePercent + directionSign * SPOTIFY_VOLUME_STEP_PERCENT)
  )
  local changed = targetVolumePercent ~= spotifyTargetVolumePercent
  spotifyTargetVolumePercent = targetVolumePercent
  showVolume(targetVolumePercent)

  if changed and not spotifyVolumeTask then sendSpotifyVolume() end
end

local function sendSpotifyState()
  local spotifySentState = spotifyTargetState
  local command = spotifySentState == hs.spotify.state_playing and "play" or "pause"
  local script = string.format([[
    if application "Spotify" is not running then error "Spotify is not running"
    tell application "Spotify" to %s
  ]], command)

  spotifyStateTask = hs.task.new("/usr/bin/osascript", function(exitCode, _, err)
    spotifyStateTask = nil
    if exitCode ~= 0 then
      spotifyStateError(err)
      return
    end

    if spotifyTargetState and spotifyTargetState ~= spotifySentState then
      sendSpotifyState()
    elseif not idleTimer:running() then
      spotifyTargetState = nil
    end
  end, { "-e", script })

  if not spotifyStateTask or not spotifyStateTask:start() then
    spotifyStateTask = nil
    spotifyStateError("could not start osascript")
  end
end

local function spotifyPlayPause()
  if not checkSpotifyRunning() then return end

  local state = getSpotifyTargetState()
  if not state then return end
  spotifyTargetState = state == hs.spotify.state_playing
      and hs.spotify.state_paused or hs.spotify.state_playing
  overlay.title.text = getSpotifyPlaybackTitle()

  spotifyTargetVolumePercent = spotifyTargetVolumePercent or hs.spotify.getVolume()
  if spotifyTargetVolumePercent then showVolume(spotifyTargetVolumePercent) end

  if not spotifyStateTask then sendSpotifyState() end
end

-- macOS full-screen zoom via Accessibility shortcuts

local function screenZoom(directionSign)
  -- Option + Command + Equal/Minus
  -- Uses the system's built-in accessibility zoom.
  local key = directionSign > 0 and "0" or "-"
  hs.eventtap.keyStroke({ "alt", "cmd" }, key, 0)
end

-- Track thumb buttons and intercept modified wheel clicks

volumeButtons = hs.eventtap.new({
  types.otherMouseDown,
  types.otherMouseUp,
  types.otherMouseDragged,
}, function(e)
  local buttonNumber = e:getProperty(props.mouseEventButtonNumber)
  local eventType = e:getType()

  if buttonNumber == MIDDLE_BUTTON_NUMBER then
    if eventType == types.otherMouseDown then
      local mouse4Held = held[MOUSE4_BUTTON_NUMBER]
      local mouse5Held = held[MOUSE5_BUTTON_NUMBER]
      local action
      if mouse4Held and not mouse5Held then
        action = systemMute
      elseif mouse5Held and not mouse4Held then
        action = spotifyPlayPause
      end

      middleClickIntercepted = mouse4Held or mouse5Held
      if action then hs.timer.doAfter(0, action) end
    elseif eventType == types.otherMouseUp then
      local intercepted = middleClickIntercepted
      middleClickIntercepted = false
      return intercepted
    end

    return middleClickIntercepted
  end

  if held[buttonNumber] == nil then
    return false
  end

  if eventType == types.otherMouseDown then
    held[buttonNumber] = true
  elseif eventType == types.otherMouseUp then
    held[buttonNumber] = false
  end

  return true
end):start()

-- Intercept wheel while thumb buttons are held

volumeWheel = hs.eventtap.new({
  types.scrollWheel,
}, function(e)
  local mouse4Held = held[MOUSE4_BUTTON_NUMBER]
  local mouse5Held = held[MOUSE5_BUTTON_NUMBER]

  if not mouse4Held and not mouse5Held then
    return false -- Normal scrolling
  end

  local scrollDeltaLines = e:getProperty(props.scrollWheelEventDeltaAxis1)

  -- Suppress wheel events while buttons are held,
  -- including events with no vertical movement.
  if scrollDeltaLines == 0 then return true end

  local directionSign = scrollDeltaLines > 0 and 1 or -1
  if REVERSE_SCROLL then directionSign = -directionSign end

  -- Both buttons: screen zoom takes priority
  local action
  if mouse4Held and mouse5Held then
    action = screenZoom
  elseif mouse4Held then
    action = systemVolume
  else
    action = spotifyVolume
  end

  hs.timer.doAfter(0, function()
    action(directionSign)
  end)

  return true
end):start()
