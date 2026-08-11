-- Definimos J com a dimensão horizontal da peça, e I com a dimensão vertical da peça

function calcularDimensoes(peca)
    local altura = 0
    local larguraEsquerda = 0
    local larguraDireita = 0
    for i = 1, #peca do
        for j = 1, #peca[i] do
            if peca[i][j] == 1 then
                if i > altura then
                    altura = i
                end
                if j < larguraEsquerda or larguraEsquerda == 0 then
                    larguraEsquerda = j
                end
                if j > larguraDireita then
                    larguraDireita = j
                end
            end
        end
    end
    return altura, larguraEsquerda, larguraDireita
end

function love.load()
    --Rendimensionado a janela
    love.window.setMode(500, 620)
    --Timer para controlar a velocidade de queda das peças
    timer = 0
    --Verificar se o jogo terminou
    gameOver = false
    --Recuo para centralizar o tabuleiro
    offsetX = 20
    offsetY = 20
    
    tabuleiro = {} --Inicializa o tabuleiro do jogo, que é uma matriz 20X10
    for i = 1, 20 do
        tabuleiro[i] = {}
        for j = 1, 10 do
            tabuleiro[i][j] = 0
        end
    end

    pecaAtual = {
    coordenadas = {
        x = 3,
        y = 1
    },
    cor = nil,
    tipo = nil
    }

    --tipos de peças

    peca = {
    {0,1,0},
    {0,1,1}
}

    pecas = {

    I = {
        matriz = {
            {1,1,1,1}
        },
        cor = {0, 1, 1}
    },

    O = {
        matriz = {
            {1,1},
            {1,1}
        },
        cor = {1, 1, 0}
    },

    T = {
        matriz = {
            {1,1,1},
            {0,1,0}
        },
        cor = {0.6, 0, 1}
    },

    L = {
        matriz = {
            {1,0},
            {1,0},
            {1,1}
        },
        cor = {1, 0.5, 0}
    },

    J = {
        matriz = {
            {0,1},
            {0,1},
            {1,1}
        },
        cor = {0, 0, 1}
    },

    S = {
        matriz = {
            {0,1,1},
            {1,1,0}
        },
        cor = {0, 1, 0}
    },

    Z = {
        matriz = {
            {1,1,0},
            {0,1,1}
        },
        cor = {1, 0, 0}
    }
}
    
    altura, larguraEsquerda, larguraDireita = calcularDimensoes(peca)

    score = 0

    pecaArmazenada = {}
    estadoHold = 0 -- 0 para nenhuma peça armazenada, 1 para peça armazenada e pronta para ser usada, 2 para peça liberada para uso

end

function podeMoverPecaBaixo()
    movimentoValido = true
    for i = 1, #peca do
        for j = 1, #peca[i] do
            if peca[i][j] == 1 then
                if pecaAtual.coordenadas.y + altura - 1 >= 20 or tabuleiro[pecaAtual.coordenadas.y + i][pecaAtual.coordenadas.x + j] == 1 then
                    movimentoValido = false
                end
            end
        end
    end
    return movimentoValido
end

function podeMoverPecaEsquerda()
    movimentoValido = true
    for i = 1, #peca do
        for j = 1, #peca[i] do
            if peca[i][j] == 1 then
                if pecaAtual.coordenadas.x + j - 1 < 1 or tabuleiro[pecaAtual.coordenadas.y + i - 1][pecaAtual.coordenadas.x + j - 1] == 1 then
                    movimentoValido = false
                end
            end
        end
    end
    return movimentoValido
end

function podeMoverPecaDireita()
    movimentoValido = true
    for i = 1, #peca do
        for j = 1, #peca[i] do
            if peca[i][j] == 1 then
                if pecaAtual.coordenadas.x + j >= 10 or tabuleiro[pecaAtual.coordenadas.y + i - 1][pecaAtual.coordenadas.x + j + 1] == 1 then
                    movimentoValido = false
                end
            end
        end
    end
    return movimentoValido
end

function rotacionarPeca()
    local novaPeca = {}
    for i = 1, #peca do
        novaPeca[i] = {}
        for j = 1, #peca[i] do
            novaPeca[i][j] = peca[#peca - j + 1][i]
        end
    end
    peca = novaPeca
    altura, larguraEsquerda, larguraDireita = calcularDimensoes(peca)
end

--function hold()


function pecaGravidade(dt)
    timer = timer + dt
    acelerador = 1
    bonusAceleracao = 0
    
    if love.keyboard.isDown("down") then
        acelerador = 0.1
        bonusAceleracao = 2
        
    end
        if timer > acelerador then
            if podeMoverPecaBaixo() then
            pecaAtual.coordenadas.y = pecaAtual.coordenadas.y + 1
            score = score + bonusAceleracao
            
                else
                    for i = 1, #peca do
                        for j = 1, #peca[i] do
                            if peca[i][j] == 1 then
                                tabuleiro[pecaAtual.coordenadas.y+i-1][pecaAtual.coordenadas.x+j] = 1
                                if pecaAtual.coordenadas.y + i - 1 <= 1 then
                                    gameOver = true -- Verifica se a peça atingiu o topo do tabuleiro, se sim, ativa o game over
                                end
                            end
                        end
                    end                
            pecaAtual.coordenadas.y = 1
            score = score + 10
            end
        timer = 0
        end
end

function verificarLinhasCompletas()
    for i = 1, 20 do
        local linhaCompleta = true
        for j = 1, 10 do
            if tabuleiro[i][j] == 0 then
                linhaCompleta = false
                break
            end
        end
        if linhaCompleta then
            table.remove(tabuleiro, i)
            local novaLinha = {}
            for k = 1, 10 do
                novaLinha[k] = 0
            end
            table.insert(tabuleiro, 1, novaLinha)
                score = score + 100
        end
    end
end

function love.update(dt)
    if not gameOver then
    pecaGravidade(dt)
    verificarLinhasCompletas()  
end
end

function love.keypressed(key)
if key == "left" then
    if podeMoverPecaEsquerda() then
        pecaAtual.coordenadas.x = pecaAtual.coordenadas.x - 1
    end
end

if key == "right" then
    if podeMoverPecaDireita() then
        pecaAtual.coordenadas.x = pecaAtual.coordenadas.x + 1
    end
end

if key == "down" then
    if podeMoverPecaBaixo() then
        pecaAtual.coordenadas.y = pecaAtual.coordenadas.y + 1
    end
end

if key == "up" then
    rotacionarPeca()
end

if gameOver then

    if key == "r" then
        love.load()
    end

    if key == "q" then
        love.event.quit()
    end
end
end

function desenhartabuleiro()
    love.graphics.setColor(0.3, 0.3, 0.3)
    for i = 1, 20 do
        for j = 1, 10 do
            if tabuleiro[i][j] == 1 then
                love.graphics.setColor(1,0,0)
                love.graphics.rectangle("fill", (j-1)*30+offsetX, (i-1)*30+offsetY, 31, 31)
                else
                    love.graphics.setColor(0.3, 0.3, 0.3)
                    love.graphics.rectangle("line", (j-1)*30+offsetX, (i-1)*30+offsetY, 30, 30)    
            end
        end
    end
end

function desenharpeca()
    for i = 1, #peca do
        for j = 1, #peca[i] do
            love.graphics.setColor(1, 0, 0)
            if peca[i][j] == 1 then
                love.graphics.rectangle("fill", (pecaAtual.coordenadas.x + j - 1) * 30 + offsetX, (pecaAtual.coordenadas.y + i - 2) * 30 + offsetY, 30, 30)
            end
        end
    end
end

function love.draw()
    desenhartabuleiro()
    desenharpeca()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 380, 580, 0, 1.5, 1.5)

    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 500, 620)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Game Over", 200, 300, 0, 2, 2)
        love.graphics.print("Pressione R para reiniciar", 150, 350, 0, 1.5, 1.5)
        love.graphics.print("Pressione Q para sair", 150, 400, 0, 1.5, 1.5)
    end
end