--Pinos
local btn = 1
local buzzeranonimo = 2

--Setup
gpio.mode(btn, gpio.INPUT)
gpio.mode(buzzeranonimo, gpio.OUTPUT)

--Funções
local function setbuzzer(state)
    gpio.write(buzzeranonimo, state and gpio.HIGH or gpio.LOW)
end

--Execução
tmr.create():alarm(100, tmr.ALARM_AUTO, function()

    if gpio.read(btn) == 0 then

        setbuzzer(true)

    else

        setbuzzer(false)

    end

end)