--Pinos
local ledVermelho = 5
local ledVerde = 6
local btn = 1

--Setup
gpio.mode(ledVermelho, gpio.OUTPUT)
gpio.mode(ledVerde, gpio.OUTPUT)
gpio.mode(btn, gpio.INPUT)

--Funções
local function setled(led, state)
    gpio.write(led, state and gpio.HIGH or gpio.LOW)
end

--Execução
tmr.create():alarm(100, tmr.ALARM_AUTO, function()

    if gpio.read(btn) == 0 then

        setled(ledVermelho, true)
        setled(ledVerde, false)

    else

        setled(ledVerde, true)
        setled(ledVermelho, false)

    end

end)