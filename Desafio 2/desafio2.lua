-- PINOS
local PIN_BTN   = 1
local PIN_RED   = 5
local PIN_GREEN = 6

-- ESTADO
local activeMode    = 0
local pendingMode   = 0
local mode2Lit      = false
local mode3State    = false
local mode3Timer    = 0
local sosStep       = 0
local sosTimer      = 0

-- BOTÃO
local btnLast       = 0
local pressStart    = 0
local holdSeconds   = 0
local lastTick      = 0
local clickCount    = 0
local lastRelease   = 0
local DCLICK_WIN    = 700

-- TIMERS
local mode1Timer     = nil
local mode3LoopTimer = nil
local sosLoopTimer   = nil
local blinkGreenTimer = nil
local holdBlinkTimer  = nil
local mainLoopTimer   = nil

-- SOS: {duracao_unidades, ligado}
local SOS = {
    {1,1},{1,0},{1,1},{1,0},{1,1},
    {3,0},
    {3,1},{1,0},{3,1},{1,0},{3,1},
    {3,0},
    {1,1},{1,0},{1,1},{1,0},{1,1},
    {7,0}
}
local SOS_UNIT = 200

local function setRed(s)
    gpio.write(PIN_RED, s and gpio.HIGH or gpio.LOW)
end

local function setGreen(s)
    gpio.write(PIN_GREEN, s and gpio.HIGH or gpio.LOW)
end

local function stopModeTimers()
    if mode1Timer then
        mode1Timer:unregister()
        mode1Timer = nil
    end
    if mode3LoopTimer then
        mode3LoopTimer:unregister()
        mode3LoopTimer = nil
    end
    if sosLoopTimer then
        sosLoopTimer:unregister()
        sosLoopTimer = nil
    end
end

local function blinkGreen()
    setGreen(true)
    if blinkGreenTimer then
        blinkGreenTimer:unregister()
        blinkGreenTimer = nil
    end
    blinkGreenTimer = tmr.create()
    blinkGreenTimer:alarm(300, tmr.ALARM_SINGLE, function()
        if activeMode == 0 then
            setGreen(false)
        end
        blinkGreenTimer = nil
    end)
end

local function stopAll()
    stopModeTimers()
    activeMode  = 0
    pendingMode = 0
    mode2Lit    = false
    mode3State  = false
    sosStep     = 1
    setRed(false)
    if blinkGreenTimer then
        blinkGreenTimer:unregister()
        blinkGreenTimer = nil
    end
    if holdBlinkTimer then
        holdBlinkTimer:unregister()
        holdBlinkTimer = nil
    end
    setGreen(false)
end

-- Inicia pisca verde durante o segurar
local function startHoldBlink()
    if holdBlinkTimer then return end
    setGreen(false)
    holdBlinkTimer = tmr.create()
    holdBlinkTimer:alarm(1000, tmr.ALARM_AUTO, function()
        if holdBlinkTimer then
            setGreen(true)
            tmr.create():alarm(150, tmr.ALARM_SINGLE, function()
                setGreen(false)
            end)
        end
    end)
    print("[BLINK] Pisca verde iniciado")
end

-- Modo 1: pulso vermelho de 400ms
local function startMode1()
    print("[MODO 1] Pulso vermelho")
    setRed(true)
    mode1Timer = tmr.create()
    mode1Timer:alarm(400, tmr.ALARM_SINGLE, function()
        setRed(false)
        activeMode = 0
        setGreen(false)
        print("[MODO 1] Concluido")
        mode1Timer = nil
    end)
end

-- Modo 2: toggle do vermelho
local function startMode2()
    mode2Lit = not mode2Lit
    setRed(mode2Lit)
    if mode2Lit then
        print("[MODO 2] LED vermelho LIGADO (toggle)")
    else
        print("[MODO 2] LED vermelho DESLIGADO (toggle)")
        activeMode = 0
        setGreen(false)
        return
    end
    setGreen(true)
end

-- Modo 3: pisca contínuo (1s)
local function startMode3()
    mode3State = false
    mode3Timer = 0
    print("[MODO 3] Pisca continuo iniciado")
    setGreen(true)

    mode3LoopTimer = tmr.create()
    mode3LoopTimer:alarm(1000, tmr.ALARM_AUTO, function()
        if activeMode == 3 then
            mode3State = not mode3State
            setRed(mode3State)
            print("[MODO 3] LED vermelho: " .. (mode3State and "ON" or "OFF"))
        else
            mode3LoopTimer:unregister()
            mode3LoopTimer = nil
        end
    end)
end

-- Modo 4: SOS
local function startMode4()
    sosStep = 1
    setRed(SOS[1][2] == 1)
    print("[MODO 4] SOS iniciado")
    setGreen(true)

    local function stepSOS()
        if activeMode ~= 4 then
            if sosLoopTimer then
                sosLoopTimer:unregister()
                sosLoopTimer = nil
            end
            return
        end

        local stepMs = SOS[sosStep][1] * SOS_UNIT
        sosTimer = stepMs

        sosLoopTimer = tmr.create()
        sosLoopTimer:alarm(stepMs, tmr.ALARM_SINGLE, function()
            if activeMode == 4 then
                sosStep = (sosStep % #SOS) + 1
                setRed(SOS[sosStep][2] == 1)
                print("[MODO 4] SOS step " .. sosStep .. " - LED: " .. (SOS[sosStep][2] == 1 and "ON" or "OFF"))
                stepSOS()
            end
            sosLoopTimer = nil
        end)
    end

    stepSOS()
end

local function activateMode(mode)
    stopAll()
    activeMode = mode

    if mode == 0 then
        return
    elseif mode == 1 then
        startMode1()
    elseif mode == 2 then
        startMode2()
    elseif mode == 3 then
        startMode3()
    elseif mode == 4 then
        startMode4()
    end
end

-- Setup
gpio.mode(PIN_BTN,   gpio.INPUT)
gpio.mode(PIN_RED,   gpio.OUTPUT)
gpio.mode(PIN_GREEN, gpio.OUTPUT)
setRed(false)
setGreen(false)
print("[SISTEMA] Iniciado")

local lastNowMs = 0
local function getNowMs()
    local us = tmr.now()
    local ms = us / 1000
    if us < 1000 and lastNowMs > 2000000000 then
        ms = ms + 4294967.296
    end
    lastNowMs = ms
    return ms
end

-- Loop principal (10ms)
mainLoopTimer = tmr.create()
mainLoopTimer:alarm(10, tmr.ALARM_AUTO, function()
    local now    = getNowMs()
    local btnNow = gpio.read(PIN_BTN)

    -- BORDA DE SUBIDA (pressionou)
    if btnNow == 1 and btnLast == 0 and (now - pressStart) > 200 then
        pressStart  = now
        lastTick    = now
        holdSeconds = 0
        pendingMode = 0
        print("[BOTAO] Pressionado")
        local wasMode2 = (activeMode == 2)
        stopAll()
        if wasMode2 then
            pendingMode = 2
        end
    end

    -- BORDA DE DESCIDA (soltou)
    if btnNow == 0 and btnLast == 1 and (now - pressStart) > 100 then
        local held = now - pressStart

        -- Para o pisca verde sempre que soltar
        if holdBlinkTimer then
            holdBlinkTimer:unregister()
            holdBlinkTimer = nil
        end

        if pendingMode ~= 0 then
            -- Última piscada → ativa modo
            setGreen(true)
            tmr.create():alarm(300, tmr.ALARM_SINGLE, function()
                setGreen(false)
                tmr.create():alarm(100, tmr.ALARM_SINGLE, function()
                    activateMode(pendingMode)
                end)
            end)
            clickCount = 0
        else
            -- Clique normal (sem modo pendente)
            setGreen(false)
            if held < 1500 then
                clickCount  = clickCount + 1
                lastRelease = now
                print("[BOTAO] Clique #" .. clickCount)
            end
            print("[BOTAO] Solto - " .. held .. "ms")
        end
    end

    -- SEGURANDO (contagem de segundos)
    if btnNow == 1 then
        if holdSeconds == 0 and (now - pressStart) > 200 then
            startHoldBlink()
        end

        if (now - lastTick) >= 1000 then
            lastTick    = now
            holdSeconds = holdSeconds + 1
            print("[BOTAO] Segurando: " .. holdSeconds .. "s")

            if holdSeconds == 4  then
                pendingMode = 1
                print("[BOTAO] Modo 1 pendente (4s)")
            end
            if holdSeconds == 8  then
                pendingMode = 2
                print("[BOTAO] Modo 2 pendente (8s)")
            end
            if holdSeconds == 12 then
                pendingMode = 3
                print("[BOTAO] Modo 3 pendente (12s)")
            end
        end
    end

    -- DUPLO CLIQUE
    if btnNow == 0 then
        if clickCount == 1 and (now - lastRelease) > DCLICK_WIN then
            print("[BOTAO] Clique simples - timeout duplo clique")
            clickCount = 0
        end
        if clickCount >= 2 then
            print("[BOTAO] Duplo clique detectado - ativando modo 4")
            clickCount = 0
            activateMode(4)
        end
    end

    btnLast = btnNow
end)

print("[SISTEMA] Loop principal iniciado - pronto para uso")