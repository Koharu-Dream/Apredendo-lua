-- Configuração dos pinos
local led_pin = 5  -- D5 (GPIO4)
local botao_pin = 1 -- D1 (GPIO5)

-- Inicializa os pinos
gpio.mode(led_pin, gpio.OUTPUT)
gpio.mode(botao_pin, gpio.INPUT)

-- Estado inicial do LED (desligado)
gpio.write(led_pin, gpio.LOW)

-- Função que verifica o botão
function verificar_botao()
    -- Se o botão for pressionado (nível LOW devido ao pull-up)
    if gpio.read(botao_pin) == 0 then
        gpio.write(led_pin, gpio.HIGH) -- Liga o LED
        print("LED ligado!")
        
        -- Aguarda o botão ser solto
        while gpio.read(botao_pin) == 0 do
            tmr.delay(10000) -- 10ms
        end
        
        gpio.write(led_pin, gpio.LOW) -- Desliga o LED
        print("LED desligado!")
    end
end

-- Cria um temporizador dinâmico
local timer = tmr.create()
timer:alarm(50, tmr.ALARM_AUTO, verificar_botao)

print("Sistema pronto! Pressione o botão no pino D1")