-- ============================================================
-- PROJETO: Controle de LEDs com botão (NodeMCU ESP8266)
-- ============================================================

-- --- PINOS (GPIO) ---
PIN_RED   = 3   -- D3 (ajuste se quiser)
PIN_GREEN = 4   -- D4
PIN_BTN   = 1   -- D1

gpio.mode(PIN_RED, gpio.OUTPUT)
gpio.mode(PIN_GREEN, gpio.OUTPUT)
gpio.mode(PIN_BTN, gpio.INPUT)

-- --- ESTADOS ---
activeMode  = 0
pendingMode = 0

btnLastState = false
pressStart   = 0
holdSeconds  = 0
lastTickTime = 0

-- --- DEBOUNCE ---
btnStableState = false
lastReading = false
lastDebounceTime = 0
debounceDelay = 50

-- --- CLIQUES ---
clickCount = 0
lastReleaseTime = 0
DOUBLE_CLICK_WINDOW = 700

-- --- MODO 2 ---
mode2Lit = false

-- --- MODO 3 ---
mode3State = false
mode3Timer = 0

-- --- MODO SOS ---
SOS = {
  {1,1},{1,0},{1,1},{1,0},{1,1},
  {3,0},
  {3,1},{1,0},{3,1},{1,0},{3,1},
  {3,0},
  {1,1},{1,0},{1,1},{1,0},{1,1},
  {7,0}
}
SOS_LEN = #SOS
SOS_UNIT = 200
sosStep = 1
sosTimer = 0

-- --- LED VERDE ---
greenTickActive = false
greenTickTimer = 0
GREEN_TICK_MS = 150

-- ============================================================
function setRed(s)
  gpio.write(PIN_RED, s and gpio.HIGH or gpio.LOW)
end

function setGreen(s)
  gpio.write(PIN_GREEN, s and gpio.HIGH or gpio.LOW)
end

-- ============================================================
function stopAll()
  activeMode  = 0
  pendingMode = 0
  mode2Lit    = false
  mode3State  = false
  sosStep     = 1
  setRed(false)
  setGreen(false)
end

-- ============================================================
function activateMode(mode)
  stopAll()
  activeMode = mode

  if mode == 0 then return end

  if mode == 1 then
    setRed(true)
    tmr.create():alarm(400, tmr.ALARM_SINGLE, function()
      setRed(false)
      activeMode = 0
    end)
    return
  end

  if mode == 2 then
    mode2Lit = not mode2Lit
    setRed(mode2Lit)
    if not mode2Lit then
      activeMode = 0
      return
    end
  end

  if mode == 3 then
    mode3State = false
    mode3Timer = tmr.now() / 1000
  end

  if mode == 4 then
    sosStep = 1
    sosTimer = tmr.now() / 1000
    setRed(SOS[sosStep][2] == 1)
  end

  setGreen(activeMode ~= 0)
end

-- ============================================================
-- LOOP (timer principal)
-- ============================================================

tmr.create():alarm(10, tmr.ALARM_AUTO, function()
  local now = tmr.now() / 1000  -- ms

  -- ================== DEBOUNCE ==================
  local reading = (gpio.read(PIN_BTN) == gpio.HIGH)

  if reading ~= lastReading then
    lastDebounceTime = now
  end

  if (now - lastDebounceTime) > debounceDelay then
    btnStableState = reading
  end

  lastReading = reading
  local btnNow = btnStableState

  -- ============================================================
  -- PRESSIONADO
  -- ============================================================
  if btnNow and not btnLastState and (now - pressStart > 200) then
    pressStart   = now
    lastTickTime = now
    holdSeconds  = 0
    pendingMode  = 0
    greenTickActive = false

    local wasMode2 = (activeMode == 2)
    stopAll()
    if wasMode2 then
      pendingMode = 2
    end
  end

  -- ============================================================
  -- SOLTO
  -- ============================================================
  if not btnNow and btnLastState and (now - pressStart > 100) then
    local heldMs = now - pressStart

    if heldMs < 1500 and pendingMode == 0 then
      clickCount = clickCount + 1
      lastReleaseTime = now
      print("Clique #" .. clickCount)
    end

    if pendingMode ~= 0 then
      activateMode(pendingMode)
      clickCount = 0
    end

    greenTickActive = false
    setGreen(activeMode ~= 0)
  end

  -- ============================================================
  -- SEGURANDO
  -- ============================================================
  if btnNow then
    if (now - lastTickTime) >= 1000 then
      lastTickTime = now
      holdSeconds = holdSeconds + 1
      print("Segurando: " .. holdSeconds .. "s")

      if holdSeconds == 4  then pendingMode = 1 end
      if holdSeconds == 8  then pendingMode = 2 end
      if holdSeconds == 12 then pendingMode = 3 end

      setGreen(true)
      greenTickActive = true
      greenTickTimer = now
    end

    if greenTickActive and (now - greenTickTimer >= GREEN_TICK_MS) then
      setGreen(false)
      greenTickActive = false
    end
  end

  -- ============================================================
  -- DUPLO CLIQUE
  -- ============================================================
  if not btnNow then
    if clickCount == 1 and (now - lastReleaseTime > DOUBLE_CLICK_WINDOW) then
      clickCount = 0
    end

    if clickCount >= 2 then
      clickCount = 0
      activateMode(4)
    end
  end

  -- ============================================================
  -- MODOS
  -- ============================================================
  if not btnNow then

    if activeMode == 3 then
      if (now - mode3Timer) >= 1000 then
        mode3Timer = now
        mode3State = not mode3State
        setRed(mode3State)
      end
    end

    if activeMode == 4 then
      local stepDuration = SOS[sosStep][1] * SOS_UNIT

      if (now - sosTimer) >= stepDuration then
        sosTimer = now
        sosStep = sosStep + 1
        if sosStep > SOS_LEN then sosStep = 1 end
        setRed(SOS[sosStep][2] == 1)
      end
    end
  end

  btnLastState = btnNow
end)
