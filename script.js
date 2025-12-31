/**
 * ============================================================
 * SKYPIXEL RPG - SCRIPT CORE (HUD + MAPA + GPS)
 * VERSÃO MOBILE (GECKOJU) - PARTE 1
 * ============================================================
 */

// CONFIGURAÇÕES DE ESCALA (GTA -> Pixels)
const MAP_SIZE = 6000; 
const IMG_SIZE = 2500; 
const SCALE = IMG_SIZE / MAP_SIZE;

// Variáveis de Controle do Mapa
let zoom = 1.0; 
let isDragging = false;
let startX, startY, mapX = 0, mapY = 0;

// Dados de Posição do Jogador
let playerPosX = 0;
let playerPosY = 0;
let playerAngle = 0;
let currentRotation = 0;      
let currentArrowRotation = 0; 

let marcadorDestino = null; 

// Seleção de Elementos do DOM
const mapLayer = document.getElementById('big-map-layer');
const mapImg = document.getElementById('map-img');
const miniMapArrow = document.getElementById('minimap-arrow');
const gpsLineMini = document.getElementById('gps-line-mini');
const gpsLineBig = document.getElementById('gps-line-big');

// --- 1. COMUNICAÇÃO GECKOJU (MANDAR DADOS PRO PAWN) ---
function sendToServer(event, ...args) {
    if (window.geckoju) {
        // Formato: "evento:arg1:arg2" para o sscanf do seu Pawn
        const data = event + ":" + args.join(":");
        window.geckoju.send(data);
    }
}

// Ocultar HUD nativa do GTA (Mobile)
function hideOriginalHud() {
    // No Geckoju, enviamos o comando para o servidor processar
    sendToServer("client:hideRadar");
}

// Relógio da HUD
function updateClock() {
    const now = new Date();
    const timeStr = now.getHours().toString().padStart(2, '0') + ":" + 
                    now.getMinutes().toString().padStart(2, '0');
    const clockEl = document.getElementById("clock");
    if (clockEl) clockEl.innerText = timeStr;
}
setInterval(updateClock, 1000);
// ============================================================
// 2. RECEBIMENTO DE DADOS (SERVIDOR -> MOBILE)
// ============================================================

if (window.geckoju) {
    // Esta função é chamada toda vez que o servidor usa Geckoju_SendData
    window.geckoju.onData = function(data) {
        try {
            const obj = JSON.parse(data);

            // Ação: Atualizar HUD (Dinheiro e Banco)
            if (obj.action === "updateHud") {
                const hand = document.getElementById("money-hand");
                const bk = document.getElementById("money-bank");
                
                // Formata o número para padrão brasileiro (Ex: 1.000)
                if (hand) hand.innerText = obj.money.toLocaleString('pt-BR');
                if (bk) bk.innerText = obj.bank.toLocaleString('pt-BR');
            }

            // Ação: Atualizar Posição do Jogador (X, Y, Ângulo)
            if (obj.action === "updatePos") {
                playerPosX = obj.x;
                playerPosY = obj.y;
                playerAngle = obj.angle; 
                
                // Se o mapa grande estiver aberto, renderiza os blips
                if (mapLayer && mapLayer.style.display === 'block') {
                    renderizarBlipsNoMapa();
                }
            }

            // Ação: GPS (Recebe a rota calculada)
            if (obj.action === "updateGPSPath") {
                atualizarLinhaGPS(obj.pathData);
            }

            // Ação: Mostrar/Esconder o Mapa Grande
            if (obj.action === "toggleMap") {
                toggleMap();
            }

            // Ação: Mostrar erro na tela (ex: senha incorreta)
            if (obj.action === "error") {
                showError(obj.msg);
            }

        } catch (e) {
            console.error("Erro ao processar JSON do Geckoju:", e);
        }
    };
}

// Função para mostrar erro visual (ajustado do seu original)
function showError(msg) {
    const inputGroup = document.querySelector('.input-group');
    const input = document.getElementById('login-pass');
    
    if (input && inputGroup) {
        input.value = "";
        input.placeholder = msg;
        inputGroup.style.borderColor = "#ff4444";
        inputGroup.style.boxShadow = "0 0 10px rgba(255, 68, 68, 0.2)";

        setTimeout(() => {
            input.placeholder = "SUA SENHA";
            inputGroup.style.borderColor = "rgba(255, 255, 255, 0.1)";
            inputGroup.style.boxShadow = "none";
        }, 3000);
    }
}
// ============================================================
// 3. LÓGICA DO MINIMAPA (MOVIMENTAÇÃO E ROTAÇÃO)
// ============================================================

// Loop principal de atualização visual (roda a 60 FPS aprox.)
function renderLoop() {
    atualizarMinimapa();
    requestAnimationFrame(renderLoop);
}

function atualizarMinimapa() {
    // 1. Converte a posição atual do jogador para pixels no mapa de 2500px
    const pos = gtaToPos(playerPosX, playerPosY);

    // 2. Cálculo de Suavização da Rotação (Interpolação simples)
    // Faz o mapa girar suavemente em vez de dar saltos
    let diff = (playerAngle - currentRotation);
    while (diff < -180) diff += 360;
    while (diff > 180) diff -= 360;
    currentRotation += diff * 0.1; // 0.1 é a velocidade da suavização

    // 3. Aplica a transformação na imagem do mapa
    // O mapa se move para o lado oposto do jogador e gira contra a câmera
    if (mapImg) {
        mapImg.style.transform = `
            translate(${-pos.x + 105}px, ${-pos.y + 105}px) 
            rotate(${-currentRotation}deg)
        `;
        // Nota: 105px é metade do tamanho do container do minimapa (centro)
    }

    // 4. Mantém a seta do jogador sempre apontando para o norte relativo ao mapa
    if (miniMapArrow) {
        // A seta gira para compensar a rotação do mapa, mantendo a direção real
        let arrowDiff = (playerAngle - currentArrowRotation);
        while (arrowDiff < -180) arrowDiff += 360;
        while (arrowDiff > 180) arrowDiff -= 360;
        currentArrowRotation += arrowDiff * 0.2;
        
        miniMapArrow.style.transform = `rotate(${currentArrowRotation - currentRotation}deg)`;
    }
    
    // 5. Atualiza a linha do GPS no minimapa (se existir rota)
    if (gpsLineMini) {
        gpsLineMini.style.transform = `
            translate(${-pos.x + 105}px, ${-pos.y + 105}px) 
            rotate(${-currentRotation}deg)
        `;
    }
}

// Inicia o loop de renderização
renderLoop();

// ============================================================
// FUNÇÕES DE UTILIDADE PARA O MAPA
// ============================================================

// Abre/Fecha o Mapa Grande (enviando sinal para o servidor se necessário)
function toggleMap() {
    if (!mapLayer) return;

    if (mapLayer.style.display === 'none' || mapLayer.style.display === '') {
        mapLayer.style.display = 'block';
        renderizarBlipsNoMapa(); // Atualiza ícones ao abrir
        sendToServer("client:mapOpened"); // Avisa o servidor para congelar o player ou liberar o mouse
    } else {
        mapLayer.style.display = 'none';
        sendToServer("client:mapClosed");
    }
}
// ============================================================
// 4. MAPA GRANDE INTERATIVO (ARRASTE E ZOOM)
// ============================================================

// Iniciar Arraste (Touch/Mouse)
if (mapImg) {
    mapImg.addEventListener('mousedown', (e) => {
        isDragging = true;
        startX = e.clientX - mapX;
        startY = e.clientY - mapY;
    });

    // Marcar Destino Livre (Clique no Mapa)
    mapImg.addEventListener('contextmenu', (e) => {
        e.preventDefault(); // Bloqueia menu do navegador
        
        const rect = mapImg.getBoundingClientRect();
        const offsetX = (e.clientX - rect.left) / zoom;
        const offsetY = (e.clientY - rect.top) / zoom;

        // Converte pixels de volta para coordenadas GTA
        const gtaX = (offsetX / SCALE) - 3000;
        const gtaY = 3000 - (offsetY / SCALE);

        // Define o marcador visual
        marcarDestinoVisual(offsetX, offsetY);
        
        // Envia para o servidor processar a rota GPS
        sendToServer("client:setGPS", gtaX, gtaY);
    });
}

window.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    mapX = e.clientX - startX;
    mapY = e.clientY - startY;
    aplicarTransformMapa();
});

window.addEventListener('mouseup', () => {
    isDragging = false;
});

// Controle de Zoom
window.addEventListener('wheel', (e) => {
    if (mapLayer && mapLayer.style.display === 'block') {
        if (e.deltaY < 0) zoom = Math.min(zoom + 0.1, 3.0);
        else zoom = Math.max(zoom - 0.1, 0.5);
        aplicarTransformMapa();
    }
});

function aplicarTransformMapa() {
    if (mapImg) {
        mapImg.style.transform = `translate(${mapX}px, ${mapY}px) scale(${zoom})`;
    }
    // A linha do GPS no mapa grande deve seguir a mesma transformação
    if (gpsLineBig) {
        gpsLineBig.style.transform = `translate(${mapX}px, ${mapY}px) scale(${zoom})`;
    }
}

// Criar ou mover a "cruzinha" de destino
function marcarDestinoVisual(x, y) {
    let cross = document.getElementById('gps-cross');
    if (!cross) {
        cross = document.createElement('div');
        cross.id = 'gps-cross';
        cross.innerHTML = '📍'; // Ícone de destino
        cross.style.position = 'absolute';
        cross.style.fontSize = '24px';
        cross.style.pointerEvents = 'none';
        mapImg.parentElement.appendChild(cross);
    }
    cross.style.left = x + 'px';
    cross.style.top = y + 'px';
}
// ============================================================
// 5. SISTEMA DE GPS, ROTAS E INICIALIZAÇÃO FINAL
// ============================================================

/**
 * Atualiza o desenho da linha do GPS tanto no Minimapa quanto no Mapa Grande
 * @param {string} pathData - String de pontos enviada pelo servidor (x,y|x,y...)
 */
function atualizarLinhaGPS(pathData) {
    if (!pathData || pathData === "") {
        if (gpsLineBig) gpsLineBig.setAttribute('d', '');
        if (gpsLineMini) gpsLineMini.setAttribute('d', '');
        return;
    }

    // Transforma a string de coordenadas em pontos de pixel para o SVG
    const points = pathData.split('|').map(p => {
        const [gx, gy] = p.split(',').map(Number);
        const pos = gtaToPos(gx, gy);
        return `${pos.x},${pos.y}`;
    });

    if (points.length < 2) return;

    // Cria o comando "d" para o path do SVG (Ex: M 10,10 L 20,20...)
    const d = `M ${points.join(' L ')}`;

    if (gpsLineBig) gpsLineBig.setAttribute('d', d);
    if (gpsLineMini) gpsLineMini.setAttribute('d', d);
}

/**
 * Traça rota para locais pré-definidos (Prefeitura, DP, etc)
 * Chamada pelos botões onclick no index.html
 */
function gpsParaLocal(x, y, nome) {
    // No Mobile, enviamos o comando para o servidor processar o cálculo da rota
    sendToServer("client:setGPS", x, y);
    
    // Feedback visual opcional
    console.log(`GPS: Rota traçada para ${nome}`);
    
    // Se o mapa estiver aberto, podemos fechá-lo ou mostrar o destino
    const pos = gtaToPos(x, y);
    marcarDestinoVisual(pos.x, pos.y);
}

// Evento de carregamento final do Browser
window.addEventListener('load', () => {
    console.log("[Geckoju] Interface SkyPixel Mobile carregada.");
    
    // Esconde a HUD original com um pequeno atraso para garantir que o cliente está pronto
    setTimeout(hideOriginalHud, 1000);
    
    // Inicia o relógio imediatamente
    updateClock();

    // Avisa o servidor que o browser está pronto para receber dados (Dinheiro, Pos, etc)
    sendToServer("client:browserReady");
});

// Tratamento de teclas (Caso o jogador use teclado no Mobile/Tablet)
window.addEventListener('keydown', (e) => {
    // Tecla 'M' ou 'H' para abrir o mapa
    if (e.key.toLowerCase() === 'm' || e.key.toLowerCase() === 'h') {
        toggleMap();
    }
    
    // Tecla ESC para fechar o mapa
    if (e.key === 'Escape' && mapLayer && mapLayer.style.display === 'block') {
        toggleMap();
    }
});

/**
 * FINAL DO ARQUIVO script.js
 * SkyPixel RPG - Desenvolvido para Geckoju Mobile
 */