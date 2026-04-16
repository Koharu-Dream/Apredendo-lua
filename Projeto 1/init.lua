-- === PINOS (GPIO) ===
local BTN_PIN          = 16  -- D0
local LED_CARRO_VERM   = 13  -- D7
local LED_CARRO_VERD   = 12  -- D6
local LED_CARRO_AZUL   = 14  -- D5
local LED_PED_VERM     = 15  -- D8
local LED_PED_VERD     = 4   -- D2
local SERVO_PIN        = 5   -- D1
local TM_CLK           = 0   -- D3
local TM_DIO           = 2   -- D4

-- === CONSTANTES ===
local TEMPO_VERDE_CARRO    = 30
local TEMPO_ATENCAO        = 5
local TEMPO_VERDE_PED_BASE = 20
local TEMPO_EXTRA_BTN      = 10
local TEMPO_VERDE_PED_MAX  = 60
local TEMPO_SERVO          = 20
local TEMPO_RESET_BTN      = 3000
local SERVO_ABERTO         = 90
local SERVO_FECHADO        = 0

-- === ESTADO GLOBAL ===
local tempoPedestre    = TEMPO_VERDE_PED_BASE
local btnSegurando     = false
local resetFeito       = false
local btnSegurouInicio = 0

-- ================================================
-- TM1637
-- ================================================
local SEGMENTOS = {
  [0]=0x3F,[1]=0x06,[2]=0x5B,[3]=0x4F,
  [4]=0x66,[5]=0x6D,[6]=0x7D,[7]=0x07,
  [8]=0x7F,[9]=0x6F
}

local function tm_start()
  gpio.write(TM_DIO, gpio.HIGH)
  gpio.write(TM_CLK, gpio.HIGH)
  gpio.write(TM_DIO, gpio.LOW)
  gpio.write(TM_CLK, gpio.LOW)
end

local function tm_stop()
  gpio.write(TM_CLK, gpio.LOW)
  gpio.write(TM_DIO, gpio.LOW)
  gpio.write(TM_CLK, gpio.HIGH)
  gpio.write(TM_DIO, gpio.HIGH)
end

local function tm_writeByte(byte)
  for i = 0, 7 do
    gpio.write(TM_CLK, gpio.LOW)
    if bit.band(byte, 1) == 1 then
      gpio.write(TM_DIO, gpio.HIGH)
    else
      gpio.write(TM_DIO, gpio.LOW)
    end
    byte = bit.rshift(byte, 1)
    gpio.write(TM_CLK, gpio.HIGH)
  end
  gpio.write(TM_CLK, gpio.LOW)
  gpio.mode(TM_DIO, gpio.INPUT)
  gpio.write(TM_CLK, gpio.HIGH)
  gpio.write(TM_CLK, gpio.LOW)
  gpio.mode(TM_DIO, gpio.OUTPUT)
end

local function displayNumero(num)
  if num < 0 then num = 0 end
  local d1 = math.floor(num / 100) % 10
  local d2 = math.floor(num / 10)  % 10
  local d3 = num % 10
  tm_start()
  tm_writeByte(0x40)
  tm_stop()
  tm_start()
  tm_writeByte(0xC0)
  tm_writeByte(0x00)
  if d1 > 0 then
    tm_writeByte(SEGMENTOS[d1])
  else
    tm_writeByte(0x00)
  end
  tm_writeByte(SEGMENTOS[d2])
  tm_writeByte(SEGMENTOS[d3])
  tm_stop()
  tm_start()
  tm_writeByte(0x8F)
  tm_stop()
end

local function displayOff()
  tm_start()
  tm_writeByte(0x40)
  tm_stop()
  tm_start()
  tm_writeByte(0xC0)
  for i = 1, 4 do tm_writeByte(0x00) end
  tm_stop()
end

-- ================================================
-- SERVO
-- ================================================
local function servoEscrever(graus)
  local pulso = 500 + math.floor(graus * 2000 / 180)
  gpio.write(SERVO_PIN, gpio.HIGH)
  tmr.delay(pulso)
  gpio.write(SERVO_PIN, gpio.LOW)
  tmr.delay(20000 - pulso)
end

local function servoAbrir()
  for i = 1, 20 do
    servoEscrever(SERVO_ABERTO)
  end
end

local function servoFechar()
  for i = 1, 20 do
    servoEscrever(SERVO_FECHADO)
  end
end

-- ================================================
-- LEDS
-- ================================================
local function todosLedsOff()
  gpio.write(LED_CARRO_VERM, gpio.LOW)
  gpio.write(LED_CARRO_VERD, gpio.LOW)
  gpio.write(LED_CARRO_AZUL, gpio.LOW)
  gpio.write(LED_PED_VERM,   gpio.LOW)
  gpio.write(LED_PED_VERD,   gpio.LOW)
end

-- ================================================
-- BOTAO
-- ================================================
local function arredondarDezenaAcima(valor)
  return (math.floor(valor / 10) + 1) * 10
end

local function lerBotao()
  local pressionado = (gpio.read(BTN_PIN) == 1)

  if pressionado and not btnSegurando then
    btnSegurando     = true
    resetFeito       = false
    btnSegurouInicio = tmr.now() / 1000
    return 0
  end

  if pressionado and btnSegurando then
    local agora = tmr.now() / 1000
    if not resetFeito and (agora - btnSegurouInicio) >= TEMPO_RESET_BTN then
      resetFeito = true
      return 2
    end
    return 0
  end

  if not pressionado and btnSegurando then
    btnSegurando = false
    if not resetFeito then
      return 1
    end
  end

  return 0
end

-- ================================================
-- FASES
-- ================================================
local function faseVerdeCarro()
  print("FASE: Verde carro")
  todosLedsOff()
  gpio.write(LED_CARRO_VERD, gpio.HIGH)
  gpio.write(LED_PED_VERM,   gpio.HIGH)
  gpio.write(SERVO_PIN,      gpio.LOW)

  for i = TEMPO_VERDE_CARRO, 1, -1 do
    displayNumero(i)
    for j = 1, 10 do
      local btn = lerBotao()
      if btn == 1 then
        tempoPedestre = tempoPedestre + TEMPO_EXTRA_BTN
        if tempoPedestre > TEMPO_VERDE_PED_MAX then
          tempoPedestre = TEMPO_VERDE_PED_MAX
        end
        print("Botao: +10s | Tempo pedestre: " .. tempoPedestre)
      elseif btn == 2 then
        tempoPedestre = TEMPO_VERDE_PED_BASE
        print("Botao: RESET | Tempo pedestre voltou para 20s")
      end
      tmr.delay(100000)
    end
  end
end

local function faseAtencao()
  print("FASE: Atencao")
  todosLedsOff()
  gpio.write(LED_CARRO_AZUL, gpio.HIGH)
  gpio.write(LED_PED_VERM,   gpio.HIGH)
  gpio.write(SERVO_PIN,      gpio.LOW)

  for i = TEMPO_ATENCAO, 1, -1 do
    displayNumero(i)
    for j = 1, 10 do
      local btn = lerBotao()
      if btn == 1 then
        tempoPedestre = tempoPedestre + TEMPO_EXTRA_BTN
        if tempoPedestre > TEMPO_VERDE_PED_MAX then
          tempoPedestre = TEMPO_VERDE_PED_MAX
        end
        print("Botao: +10s | Tempo pedestre: " .. tempoPedestre)
      elseif btn == 2 then
        tempoPedestre = TEMPO_VERDE_PED_BASE
        print("Botao: RESET | Tempo pedestre voltou para 20s")
      end
      tmr.delay(100000)
    end
  end
end

local function faseVermelhoCarro()
  print("FASE: Vermelho carro | Tempo: " .. tempoPedestre)
  todosLedsOff()
  gpio.write(LED_CARRO_VERM, gpio.HIGH)
  gpio.write(LED_PED_VERD,   gpio.HIGH)
  servoAbrir()

  local usosBotao       = 0
  local velocidadeDupla = false
  local i               = tempoPedestre
  local servoAberto     = true

  local ultimoSegundo   = tmr.now() / 1000
  local ultimoPiscar    = tmr.now() / 1000
  local servoInicio     = tmr.now() / 1000
  local ledPedState     = true

  while i > 0 do
    local agora = tmr.now() / 1000

    if servoAberto and (agora - servoInicio) >= TEMPO_SERVO * 1000 then
      servoFechar()
      servoAberto = false
      print("Servo fechou (20s)")
    end

    local btn = lerBotao()

    if btn == 2 then
      tempoPedestre = TEMPO_VERDE_PED_BASE
      print("Botao: RESET | Tempo pedestre voltou para 20s")
    end

    if btn == 1 and usosBotao < 2 then
      local novoTempo = arredondarDezenaAcima(i)
      if novoTempo > TEMPO_VERDE_PED_MAX then
        novoTempo = TEMPO_VERDE_PED_MAX
      end
      if novoTempo > i then
        print("Botao fase vermelha: " .. i .. "s -> " .. novoTempo .. "s")
        i = novoTempo
        displayNumero(i)
        velocidadeDupla = true
        usosBotao = usosBotao + 1
        print("Usos restantes: " .. (2 - usosBotao))
      end
    end

    local piscarDelay = 500
    if velocidadeDupla then piscarDelay = 250 end

    if i <= 5 then
      if (agora - ultimoPiscar) >= piscarDelay then
        ultimoPiscar = agora
        ledPedState  = not ledPedState
        if ledPedState then
          gpio.write(LED_PED_VERD, gpio.HIGH)
        else
          gpio.write(LED_PED_VERD, gpio.LOW)
        end
      end
    else
      gpio.write(LED_PED_VERD, gpio.HIGH)
    end

    if (agora - ultimoSegundo) >= 1000 then
      ultimoSegundo = agora
      i = i - 1
      displayNumero(i)
    end

    tmr.delay(10000)
  end

  servoFechar()
  tempoPedestre = TEMPO_VERDE_PED_BASE
  todosLedsOff()
  tmr.delay(500000)
end

-- ================================================
-- INICIALIZACAO
-- ================================================
gpio.mode(LED_CARRO_VERM, gpio.OUTPUT)
gpio.mode(LED_CARRO_VERD, gpio.OUTPUT)
gpio.mode(LED_CARRO_AZUL, gpio.OUTPUT)
gpio.mode(LED_PED_VERM,   gpio.OUTPUT)
gpio.mode(LED_PED_VERD,   gpio.OUTPUT)
gpio.mode(BTN_PIN,        gpio.INPUT)
gpio.mode(TM_CLK,         gpio.OUTPUT)
gpio.mode(TM_DIO,         gpio.OUTPUT)
gpio.mode(SERVO_PIN,      gpio.OUTPUT)

gpio.write(SERVO_PIN, gpio.LOW)
displayOff()
todosLedsOff()
print("Sistema iniciado!")

-- ================================================
-- LOOP PRINCIPAL
-- ================================================
while true do
  tmr.wdclr()
  faseVerdeCarro()
  faseAtencao()
  faseVermelhoCarro()
end
