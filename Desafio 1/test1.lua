PIN_RED = 3    -- D3 (LED Vermelho)
PIN_GREEN = 4  -- D4 (LED Verde)
PIN_BTN = 2    -- D2 (Botao)

gpio.mode(PIN_RED, gpio.OUTPUT)
gpio.mode(PIN_GREEN, gpio.OUTPUT)
gpio.mode(PIN_BTN, gpio.INPUT, gpio.PULLUP)

gpio.write(PIN_RED, gpio.LOW)
gpio.write(PIN_GREEN, gpio.HIGH)

tmr.create():alarm(100, tmr.ALARM_AUTO, function()
    if gpio.read(PIN_BTN) == 0 then
        gpio.write(PIN_RED, gpio.HIGH)
        gpio.write(PIN_GREEN, gpio.LOW)
    else
        gpio.write(PIN_RED, gpio.LOW)
        gpio.write(PIN_GREEN, gpio.HIGH)
    end
end)

print("SISTEMA PRONTO! LED Verde = aguardando, LED Vermelho = botao pressionado")