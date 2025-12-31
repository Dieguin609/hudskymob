let selectedGender = null;
const audio = document.getElementById('myAudio');
const musicIcon = document.getElementById('musicIcon');

// --- 1. CONTROLE DE MÚSICA (Original Mantido) ---
function togglePlay() {
    if (audio.paused) {
        audio.play();
        musicIcon.classList.remove('fa-play');
        musicIcon.classList.add('fa-pause');
    } else {
        audio.pause();
        musicIcon.classList.remove('fa-pause');
        musicIcon.classList.add('fa-play');
    }
}

window.onload = () => {
    audio.play().catch(() => {
        musicIcon.classList.remove('fa-pause');
        musicIcon.classList.add('fa-play');
    });
};

// --- 2. NAVEGAÇÃO E GÊNERO (Original Mantido) ---
function toggleForm(type) {
    if(type === 'reg') {
        document.getElementById('login-box').style.display = 'none';
        document.getElementById('register-box').style.display = 'block';
    } else {
        document.getElementById('register-box').style.display = 'none';
        document.getElementById('login-box').style.display = 'block';
    }
}

function selectGender(gender) {
    selectedGender = gender;
    document.getElementById('m-btn').classList.remove('active');
    document.getElementById('f-btn').classList.remove('active');
    if(gender === 'M') document.getElementById('m-btn').classList.add('active');
    else document.getElementById('f-btn').classList.add('active');
}

// --- 3. FUNÇÕES DE ENVIO PARA O SERVIDOR (CORRIGIDAS PARA O PAWN) ---
// --- 3. ENVIO DE DADOS PARA O SERVIDOR (CORRIGIDO) ---
function login() {
    const pass = document.getElementById('login-pass').value;
    if (pass.length > 0) {
        if (window.geckoju) {
            // No Mobile Geckoju, enviamos uma string formatada que o sscanf vai ler
            window.geckoju.send("login:" + pass);
        } else {
            // Caso esteja testando no PC por erro
            console.log("Geckoju Mobile não detectado");
        }
    } else {
        showError("Digite sua senha!");
    }
}

function register() {
    const pass = document.getElementById('reg-pass').value;
    if (pass.length > 0 && selectedGender) {
        if (window.geckoju) {
            window.geckoju.send("register:" + pass + ":" + selectedGender);
        }
    } else {
        showError("Senha ou Gênero faltando!");
    }
}

// --- 4. FUNÇÃO DE ERRO (Visual Mantido) ---
function showError(msg) {
    const inputGroup = document.querySelector('.input-group');
    const input = document.getElementById('login-pass');
    
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

// --- 5. PONTE DE RECEBIMENTO (Pawn -> JS) ---
window.geckoju.onData = function(data) {
    try {
        const obj = JSON.parse(data);
        if(obj.action === "error") {
            showError(obj.msg);
        }
    } catch(e) {
        console.log("Erro ao processar dados do servidor: " + e);
    }
};