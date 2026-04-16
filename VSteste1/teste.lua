
-- INICIALIZAÇÃO

math.randomseed(os.time())

-- controle do "timer"
rodando = false
ultimoTempo = 0
intervalo = 3 -- segundos

-- DADOS (sensores)

sensores = {
    { id = 0, modelo = "HC-SR04", pino = 0, tipoLeitura = "analogico", Defeituoso = false },
    { id = 1, modelo = "DHT11",   pino = 0, tipoLeitura = "analogico", Defeituoso = true },
    { id = 2, modelo = "LDR",     pino = 0, tipoLeitura = "analogico", Defeituoso = true },
    { id = 3, modelo = "Botao",   pino = 3, tipoLeitura = "digital",   Defeituoso = false },
    { id = 4, modelo = "LED",     pino = 4, tipoLeitura = "digital",   Defeituoso = false },
}

-- UTILITÁRIOS

function log(tipo, msg)
    print("[" .. tipo .. "] " .. msg)
end

function formatarTexto(opcao, inicio)
    if inicio then
        print("\n===== OPCAO " .. opcao .. " =====")
        print("[INFO] Executando...")
    else
        print("-----------------------------")
    end
end


-- FUNÇÕES

function setarPinosZero(lista)
    for i = 1, #lista do
        lista[i].pino = 0
    end
end

function setarPinos(lista)
    for i = 1, #lista do
        print("Digite o pino para " .. lista[i].modelo .. ":")
        local pino = tonumber(io.read())
        lista[i].pino = pino
    end
end

function mostrarComponentes(lista)
    print("=====================================")
    print("ID  | Modelo   | Pino | Tipo")
    print("=====================================")

    for i = 1, #lista do
        local s = lista[i]

        print(string.format(
            "%-3d | %-8s | %-4d | %-10s",
            s.id,
            s.modelo,
            s.pino,
            s.tipoLeitura
        ))
    end
    print("=====================================")
end

function lerSensores(lista)
    for i = 1, #lista do
        local sensor = lista[i]

        if sensor.Defeituoso then
            log("ERRO", sensor.modelo .. " com falha")
        else
            local valor

            if sensor.tipoLeitura == "digital" then
                valor = math.random(0,1)
            else
                valor = math.random(0,100)
            end

            log("INFO", sensor.modelo .. " = " .. valor)
        end
    end
end

function simularDefeito(lista)
    for i = 1, #lista do
        lista[i].Defeituoso = math.random() < 0.3
    end
end

function verificarDefeitos(lista)
    local contador = 0

    for i = 1, #lista do
        if lista[i].Defeituoso then
            log("ERRO", lista[i].modelo .. " defeituoso")
            contador = contador + 1
        end
    end

    log("INFO", "Total defeituosos: " .. contador)
    return contador
end

function corrigirDefeitos(lista)
    for i = 1, #lista do
        if lista[i].Defeituoso then
            lista[i].Defeituoso = false
            log("INFO", lista[i].modelo .. " corrigido")
        end
    end
end

-- LÓGICA DO SISTEMA

function alertaSistema(lista)
    local total = verificarDefeitos(lista)

    if total >= 2 then
        log("ALERTA", "Sistema em estado crítico!")
    end
end

function cicloSistema(lista)
    log("INFO", "Executando ciclo do sistema")
    simularDefeito(lista)
    lerSensores(lista)
    alertaSistema(lista)
    print("-----")
end

-- "TIMER" SIMULADO

function iniciarRotina(lista)
    if rodando then
        log("INFO", "Rotina já está rodando")
        return
    end

    rodando = true
    ultimoTempo = os.time()

    log("INFO", "Rotina iniciada")
end

function pararRotina()
    if rodando then
        rodando = false
        log("INFO", "Rotina parada")
    else
        log("INFO", "Nenhuma rotina ativa")
    end
end

function atualizarSistema(lista)
    if rodando then
        local agora = os.time()

        if agora - ultimoTempo >= intervalo then
            ultimoTempo = agora
            cicloSistema(lista)
        end
    end
end

-- MENU

function menu(lista)
    setarPinosZero(lista)

    local opcao

    repeat
        atualizarSistema(lista)

        print("\nMENU:")
        print("1 - Mostrar componentes")
        print("2 - Setar pinos")
        print("3 - Simular defeitos")
        print("4 - Verificar defeitos")
        print("5 - Corrigir defeitos")
        print("6 - Iniciar rotina")
        print("7 - Parar rotina")
        print("8 - Sair")

        io.write("Escolha: ")
        opcao = tonumber(io.read())

        if opcao == 1 then
            formatarTexto(opcao, true)
            mostrarComponentes(lista)
            formatarTexto(opcao, false)

        elseif opcao == 2 then
            formatarTexto(opcao, true)
            setarPinos(lista)
            formatarTexto(opcao, false)

        elseif opcao == 3 then
            formatarTexto(opcao, true)
            simularDefeito(lista)
            formatarTexto(opcao, false)

        elseif opcao == 4 then
            formatarTexto(opcao, true)
            verificarDefeitos(lista)
            formatarTexto(opcao, false)

        elseif opcao == 5 then
            formatarTexto(opcao, true)
            corrigirDefeitos(lista)
            formatarTexto(opcao, false)

        elseif opcao == 6 then
            formatarTexto(opcao, true)
            iniciarRotina(lista)
            formatarTexto(opcao, false)

        elseif opcao == 7 then
            formatarTexto(opcao, true)
            pararRotina()
            formatarTexto(opcao, false)

        elseif opcao == 8 then
            log("INFO", "Saindo...")
        else
            log("ERRO", "Opcao invalida")
        end

    until opcao == 8
end

-- EXECUÇÃO

menu(sensores)