collectgarbage()

local buzzer = 2
local ocupado = false

wifi.setmode(wifi.SOFTAP)
wifi.ap.config({
    ssid = "ESPPIANO",
    pwd = "ntcl2205"
})

pwm.setup(buzzer, 440, 512)
pwm.stop(buzzer)

local CHUNK = 1024

local function enviar_html(client)
    local f = file.open("index.html", "r")
    if not f then
        client:send("HTTP/1.1 200 OK\r\nContent-Type:text/html\r\nConnection:close\r\n\r\n<h1>erro</h1>")
        client:close()
        return
    end
    client:send("HTTP/1.1 200 OK\r\nContent-Type:text/html\r\nConnection:close\r\n\r\n")
    local function proximo_chunk()
        local chunk = f:read(CHUNK)
        if chunk then
            client:send(chunk)
        else
            f:close()
            f = nil
            collectgarbage()
            client:close()
        end
    end
    client:on("sent", proximo_chunk)
    proximo_chunk()
end

srv = net.createServer(net.TCP)
srv:listen(80, function(conn)

    conn:on("receive", function(client, request)
        collectgarbage()

        if request:find("/do2") then
            pwm.setclock(buzzer, 523) pwm.start(buzzer)
        elseif request:find("/do") then
            pwm.setclock(buzzer, 262) pwm.start(buzzer)
        elseif request:find("/re") then
            pwm.setclock(buzzer, 294) pwm.start(buzzer)
        elseif request:find("/mi") then
            pwm.setclock(buzzer, 330) pwm.start(buzzer)
        elseif request:find("/fa") then
            pwm.setclock(buzzer, 349) pwm.start(buzzer)
        elseif request:find("/sol") then
            pwm.setclock(buzzer, 392) pwm.start(buzzer)
        elseif request:find("/la") then
            pwm.setclock(buzzer, 440) pwm.start(buzzer)
        elseif request:find("/si") then
            pwm.setclock(buzzer, 494) pwm.start(buzzer)
        elseif request:find("/stop") then
            pwm.stop(buzzer)
        else
            -- só carrega HTML na rota raiz
            request = nil
            collectgarbage()
            enviar_html(client)
            return
        end

        -- notas: fecha conexão na hora, sem enviar nada
        request = nil
        client:close()
        collectgarbage()
    end)

    conn:on("disconnection", function()
        collectgarbage()
    end)
end)

print("Servidor iniciado")
print(wifi.ap.getip())