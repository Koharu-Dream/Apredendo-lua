LED = 13
BTN = 16
modo = 0

gpio.mode(LED, gpio.OUTPUT)
gpio.mode(BTN, gpio.INPUT)
gpio.write(LED, gpio.LOW)

function piscaUma()
  gpio.write(LED, gpio.HIGH)
  tmr.delay(300000)
  gpio.write(LED, gpio.LOW)
end

function sos()
  local p = {300000,300000,300000,900000,900000,900000,300000,300000,300000}
  for i=1,#p do
    gpio.write(LED, gpio.HIGH)
    tmr.delay(p[i])
    gpio.write(LED, gpio.LOW)
    tmr.delay(300000)
  end
  tmr.delay(600000)
end

function apertar()
  modo = modo + 1
  if modo > 3 then modo = 1 end
end

while true do
  if gpio.read(BTN) == 1 then
    apertar()
    tmr.delay(300000)
    while gpio.read(BTN) == 1 do end
    tmr.delay(50000)
  end

  if modo == 1 then
    piscaUma()
    modo = 0
  elseif modo == 2 then
    gpio.write(LED, gpio.HIGH)
  elseif modo == 3 then
    sos()
  else
    gpio.write(LED, gpio.LOW)
  end

  tmr.wdclr()
  tmr.delay(50000)
end
