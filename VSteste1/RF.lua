configuracao = {
    { id = 1, valor = 1.00 },
    { id = 2, valor = 2.00 },
    { id = 3, valor = 5.00 }
}
function acharID(configuracao) -- true mesmo valor, false valores diferentes
    for i = configuracao.id, #configuracao do
        if (configuracao[i].id == ideEscolhida) then
            return configuracao[i].id
        end
    end
    

function adicionarCredito(numPulso, valorPulso)
    TotalValorCredito = 0
    sair = true

    if (compararValorPulso(valorPulso) == false) then
        TotalValorCredito = valorPulso * numPulso
    else
        for i = 1, numPulso do
            print("Valor do pulso:" .. valorPulso)
            TotalValorCredito = TotalValorCredito + valorPulso
        end
    end
    print("Total de creditos adicionados: " .. TotalValorCredito)
end

TodosMesmoValor = false
adicionarCredito(5, 10)

--Formatação
function log(tipo, mensagem)
    print("[" .. tipo .. "] " .. mensagem)
end