-- Definimos J com a dimensão horizontal da peça,
-- e I com a dimensão vertical da peça.

function calcularDimensoes(peca)
    local altura = #peca
    local larguraEsquerda = 0
    local larguraDireita = 0

    for i = 1, #peca do
        for j = 1, #peca[i] do
            if peca[i][j] == 1 then
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
    love.window.setMode(500, 620)

    timer = 0
    gameOver = false

    offsetX = 20
    offsetY = 20

    -- Tabuleiro 20 x 10
    tabuleiro = {}

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

    -- Tipos de peças

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

    -- Peça usada atualmente.

    peca = pecas.Z.matriz

    altura, larguraEsquerda, larguraDireita = calcularDimensoes(peca)

    score = 0

    pecaArmazenada = {}
    estadoHold = 0
end


-- Verifica se a peça pode ficar em uma determinada posição.

-- x = coluna inicial da peça
-- y = linha inicial da peça

-- Retorna true se puder colocar.
-- Retorna false se sair do tabuleiro ou bater em outra peça.

function podeColocarPeca(matriz, x, y)

    for i = 1, #matriz do

        for j = 1, #matriz[i] do

            if matriz[i][j] == 1 then

                local linha = y + i - 1
                local coluna = x + j - 1

                -- Verifica se saiu do tabuleiro.

                if coluna < 1 or coluna > 10 then
                    return false
                end

                if linha < 1 or linha > 20 then
                    return false
                end

                -- Verifica se existe uma peça fixa nessa posição.

                if tabuleiro[linha][coluna] == 1 then
                    return false
                end
            end
        end
    end

    return true
end


function podeMoverPecaBaixo()

    if podeColocarPeca(
        peca,
        pecaAtual.coordenadas.x,
        pecaAtual.coordenadas.y + 1
    ) then

        return true
    end

    return false
end


function podeMoverPecaEsquerda()

    if podeColocarPeca(
        peca,
        pecaAtual.coordenadas.x - 1,
        pecaAtual.coordenadas.y
    ) then

        return true
    end

    return false
end


function podeMoverPecaDireita()

    if podeColocarPeca(
        peca,
        pecaAtual.coordenadas.x + 1,
        pecaAtual.coordenadas.y
    ) then

        return true
    end

    return false
end


function rotacionarPeca()

    local novaPeca = {}

    -- Quantidade de linhas e colunas da peça antes da rotação.

    local linhas = #peca
    local colunas = #peca[1]


    for i = 1, colunas do

        novaPeca[i] = {}

        for j = 1, linhas do

            novaPeca[i][j] = peca[linhas - j + 1][i]

        end
    end

    if podeColocarPeca(
        novaPeca,
        pecaAtual.coordenadas.x,
        pecaAtual.coordenadas.y
    ) then

        peca = novaPeca

        altura, larguraEsquerda, larguraDireita =
            calcularDimensoes(peca)

        return
    end


    -- Se não coube exatamente no lugar atual,
    -- tentamos pequenos deslocamentos.

    local tentativas = {
        { -1, 0 },
        { 1, 0 },
        { -2, 0 },
        { 2, 0 },
        { 0, -1 },
        { 0, -2 }
    }


    for i = 1, #tentativas do

        local novoX =
            pecaAtual.coordenadas.x + tentativas[i][1]

        local novoY =
            pecaAtual.coordenadas.y + tentativas[i][2]


        if podeColocarPeca(
            novaPeca,
            novoX,
            novoY
        ) then

            -- Encontramos uma posição segura.

            pecaAtual.coordenadas.x = novoX
            pecaAtual.coordenadas.y = novoY

            peca = novaPeca

            altura, larguraEsquerda, larguraDireita =
                calcularDimensoes(peca)

            return
        end
    end
end


function fixarPecaNoTabuleiro()

    for i = 1, #peca do

        for j = 1, #peca[i] do

            if peca[i][j] == 1 then

                local linha =
                    pecaAtual.coordenadas.y + i - 1

                local coluna =
                    pecaAtual.coordenadas.x + j - 1


                tabuleiro[linha][coluna] = 1
            end
        end
    end
end


function pecaGravidade(dt)

    timer = timer + dt

    local acelerador = 1
    local bonusAceleracao = 0


    if love.keyboard.isDown("down") then

        acelerador = 0.1
        bonusAceleracao = 2

    end


    if timer > acelerador then

        if podeMoverPecaBaixo() then

            pecaAtual.coordenadas.y =
                pecaAtual.coordenadas.y + 1

            score = score + bonusAceleracao

        else

            -- A peça não consegue mais descer.
            -- Então ela vira uma peça fixa do tabuleiro.

            fixarPecaNoTabuleiro()

            pecaAtual.coordenadas.x = 3
            pecaAtual.coordenadas.y = 1


            -- Se nem a posição inicial estiver livre,
            -- o jogo termina.

            if not podeColocarPeca(
                peca,
                pecaAtual.coordenadas.x,
                pecaAtual.coordenadas.y
            ) then

                gameOver = true
            end

            score = score + 10
        end


        timer = 0
    end
end


function verificarLinhasCompletas()

    for i = 20, 1, -1 do

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

            for j = 1, 10 do
                novaLinha[j] = 0
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

            pecaAtual.coordenadas.x =
                pecaAtual.coordenadas.x - 1
        end
    end


    if key == "right" then

        if podeMoverPecaDireita() then

            pecaAtual.coordenadas.x =
                pecaAtual.coordenadas.x + 1
        end
    end


    if key == "down" then

        if podeMoverPecaBaixo() then

            pecaAtual.coordenadas.y =
                pecaAtual.coordenadas.y + 1
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

                love.graphics.setColor(1, 0, 0)

                love.graphics.rectangle(
                    "fill",
                    (j - 1) * 30 + offsetX,
                    (i - 1) * 30 + offsetY,
                    31,
                    31
                )

            else

                love.graphics.setColor(0.3, 0.3, 0.3)

                love.graphics.rectangle(
                    "line",
                    (j - 1) * 30 + offsetX,
                    (i - 1) * 30 + offsetY,
                    30,
                    30
                )
            end
        end
    end
end


function desenharpeca()

    for i = 1, #peca do

        for j = 1, #peca[i] do

            if peca[i][j] == 1 then

                love.graphics.setColor(1, 0, 0)

                love.graphics.rectangle(
                    "fill",
                    (pecaAtual.coordenadas.x + j - 2) * 30
                        + offsetX,

                    (pecaAtual.coordenadas.y + i - 2) * 30
                        + offsetY,

                    30,
                    30
                )
            end
        end
    end
end


function love.draw()

    desenhartabuleiro()

    desenharpeca()


    love.graphics.setColor(1, 1, 1)

    love.graphics.print(
        "Score: " .. score,
        380,
        580,
        0,
        1.5,
        1.5
    )


    if gameOver then

        love.graphics.setColor(0, 0, 0, 0.7)

        love.graphics.rectangle(
            "fill",
            0,
            0,
            500,
            620
        )


        love.graphics.setColor(1, 1, 1)

        love.graphics.print(
            "Game Over",
            200,
            300,
            0,
            2,
            2
        )


        love.graphics.print(
            "Pressione R para reiniciar",
            150,
            350,
            0,
            1.5,
            1.5
        )


        love.graphics.print(
            "Pressione Q para sair",
            150,
            400,
            0,
            1.5,
            1.5
        )
    end
end