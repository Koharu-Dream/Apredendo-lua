local btn = 1
local buzzer = 2

gpio.mode(btn, gpio.INPUT)

tmr.create():alarm(50, tmr.ALARM_AUTO, function()

    if gpio.read(btn) == 1 then

        pwm.setup(buzzer, 293, 700)
        pwm.start(buzzer)
        print("Ré")
    else

        pwm.stop(buzzer)

    end

end)