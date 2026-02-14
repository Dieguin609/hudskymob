//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//                             GM SkyPixel RPG
//                             DIGUIN.STUDIOS
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#include <a_samp>
#include <DOF2>
#include <zcmd>
#include <Dini>
#include <sscanf2>
#include <streamer>
#include <float>
#include <cef>
#include <Pawn.RakNet>
#include <geckoju>
#include <gps>

#include "../Modulos/Custom/CustomP.inc"
#include "../Modulos/Custom/AcessoriosP.inc"

//#pragma disablerecursion
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#define SV_INFY 99999
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define PASTA_CONTAS                                                            "Contas/%s.ini"
#define SCM                                                                     SendClientMessage
#define ISP                                                                     IsPlayerInRangeOfPoint
#define IPC                                                                     IsPlayerConnected
#define D_SENHA                                                                 0
#define D_GENERO                                                                1
#define D_ADMINISTRADOR                                                         2

#define varGet(%0)      getproperty(0,%0)
#define varSet(%0,%1)   setproperty(0, %0, %1)
#define new_strcmp(%0,%1) \
                (varSet(%0, 1), varGet(%1) == varSet(%0, 0))
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#define MOBILE_BROWSER_HUD    1
#define MOBILE_BROWSER_LOGIN  2
#define BROWSER_HUD 2
// Defina o ID do navegador uma única vez para evitar confusão
#define HUD_BROWSER_ID 2
#define HUD_BROWSER_ID2 3
#define HUD_BROWSER_ID3 4
#define MAPA_BROWSER_ID 5
#define MENU_BROWSER_ID 6
// Garanta que a constante de posição esteja definida
#if !defined GECKOJU_POS_END
#define GECKOJU_POS_END -2
#endif
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
enum pInfo
{
    Senha[20],
    Dinheiro,
    Level,
    Skin,
    Genero,
    Admin,

    Interior,
	VirtualW,
    

	Float:VidaHP,
	Float:ColeteHP,

	Float:PosX,
	Float:PosY,
	Float:PosZ,
	Float:PosR

};
new info[MAX_PLAYERS][pInfo];
//
new bool:UsandoGPS[MAX_PLAYERS];
new Float:DestinoGPS[MAX_PLAYERS][3];
new Path:pathid_player[MAX_PLAYERS]; // Variável com a tag correta para o GPS
// Variáveis para guardar o destino atual
new bool:GPS_Ativo[MAX_PLAYERS];
new Float:GPS_DestX[MAX_PLAYERS], Float:GPS_DestY[MAX_PLAYERS], Float:GPS_DestZ[MAX_PLAYERS];

// Timer para recalcular a rota (para ir apagando conforme anda)
new TimerGPS[MAX_PLAYERS];
//
new arquivo[128];
new VSenha[MAX_PLAYERS][20];
new VGenero[MAX_PLAYERS];
new TentativasSenha[MAX_PLAYERS];
//
new Trabalhando[MAX_PLAYERS];
new Gasolina[MAX_PLAYERS];
new skinadm[MAX_PLAYERS];
new EstaTv[MAX_PLAYERS];
//
new bool:VerificarLogin[MAX_PLAYERS];
new bool:EstaRegistrado[MAX_PLAYERS];
//
new String_RotaGPS[MAX_PLAYERS][1024]; // Guarda os pontos "x,y|x,y"
//
new PlayerText:TextdrawRegistro[10][MAX_PLAYERS];
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main()
{
	print("\n----------------------------------");
	print(" Gamemode iniciado com sucesso");
	print("----------------------------------\n");
}

public OnGameModeInit()
{
    SetTimer("AtualizarInterfaceCEF", 70, true); // Atualiza 5 vezes por segundo

    SetTimer("AtualizarRotaGPS", 2000, true);

    cef_subscribe("fecharFocoMapa", "OnFecharFoco");
    cef_subscribe("rotaPrefeitura", "OnRotaPrefeitura");
    cef_subscribe("cancelarRotaGPS", "OnCancelarRota");



    // Inscreve os eventos
    cef_subscribe("server:onPlayerLogin", "OnPlayerLogin_CEF");
    cef_subscribe("server:onPlayerRegister", "OnPlayerRegister_CEF");
    cef_subscribe("server:selecionarSpawn", "OnPlayerSelectSpawn_CEF");
    
    ShowPlayerMarkers(0);
	ShowNameTags(0);
	UsePlayerPedAnims();
	DisableInteriorEnterExits();
 	EnableStuntBonusForAll(0);
    SetGameModeText("Roleplay");
    return 1;
}

public OnGameModeExit()
{
    DOF2_Exit();
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    // Removemos toda a lógica de aparecer TextDraws antigas aqui
    LimparChat(playerid, 30);
    TogglePlayerSpectating(playerid, 1); // Mantém em modo spec para o CEF
    
    // Câmera de fundo do Login
    //InterpolateCameraPos(playerid, 828.892395, -1470.234985, 159.147048, 1855.578247, -1356.315795, 106.570388, 90000);
   // InterpolateCameraLookAt(playerid, 833.859008, -1469.715087, 158.897155, 1860.529296, -1355.671020, 106.302513, 90000);
    return 1;
}
public OnPlayerConnect(playerid)
{
    VerificarLogin[playerid] = false;
    TogglePlayerSpectating(playerid, true);

    // Se NÃO for mobile, chama o login do PC após 1 segundo
    if(!Geckoju_IsMobileClient(playerid)) 
    {
        SetTimerEx("AbrirLoginCEF", 1000, false, "i", playerid);
    }
    // Se for mobile, o servidor vai esperar o OnGeckojuReady disparar sozinho.
    return 1;
}
forward AbrirLoginCEF(playerid);
public AbrirLoginCEF(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;

    if(Geckoju_IsMobileClient(playerid))
    {
        // Link Mobile (com script.js exclusivo mobile)
        Geckoju_CreateBrowser(playerid, 1, 0, 0, GECKOJU_SIZE_FULL, GECKOJU_SIZE_FULL, "https://dieguin609.github.io/logincefmob/", true, false);
        Geckoju_SetInteractive(playerid, 1, true);
    }
    else 
    {
        cef_create_browser(playerid, 1, "https://dieguin609.github.io/login/", false, false);
        cef_focus_browser(playerid, 1, true); 
    }
    return 1;
}

forward AbrirSpawnCEF(playerid);
public AbrirSpawnCEF(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;

    if(Geckoju_IsMobileClient(playerid))
    {
        Geckoju_CreateBrowser(playerid, 91, 0, 0, GECKOJU_SIZE_FULL, GECKOJU_SIZE_FULL, "https://dieguin609.github.io/spawn-selector/", true, false);
        Geckoju_SetInteractive(playerid, 91, true);
    }
    else 
    {
        cef_create_browser(playerid, 91, "https://dieguin609.github.io/spawn-selector/", false, 255, false);
        cef_focus_browser(playerid, 91, true); 
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(VerificarLogin[playerid] == true)
    {
        SalvarDados(playerid);
    }
	return 1;
    if(Geckoju_IsMobileClient(playerid))
    {
        Geckoju_DestroyBrowser(playerid, BROWSER_HUD);
    }
    return 1;
}

public OnPlayerSpawn(playerid)
{ 
    // 1. Verificação de Segurança
    if(VerificarLogin[playerid] == false)
    {
        Kick(playerid);
        return 1;
    }

    // 2. Lógica para PC (CEF Plugin)
    if(!Geckoju_IsMobileClient(playerid))
    {
        cef_create_browser(playerid, 14, "https://dieguin609.github.io/hudskay/", false, false);
        cef_emit_event(playerid, "game:hud:setComponentVisible", "radar", false);
        cef_emit_event(playerid, "game:hud:setComponentVisible", "interface", false);
    }

    // 3. Lógica para MOBILE (Geckoju)
    else
    {
        ShowMobileHUD(playerid);
    }

    // 4. Configurações gerais de Spawn (vale para os dois)
    SetPlayerSkin(playerid, info[playerid][Skin]);
    SetPlayerInterior(playerid, 0); // Exemplo: garante que nasce no mundo exterior
    
    return 1; // O ÚNICO return final que encerra a função
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
    if(VerificarLogin[playerid] == false)
	{
		MensagemText(playerid, "~r~ERRO: ~w~Voce nao pode falar no chat.");
		return 0;
	}
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{

	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    DisablePlayerCheckpoint(playerid);
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

forward QuebrarText(playerid);
forward UmSegundo();

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    
    if ((newkeys & KEY_CTRL_BACK) && !(oldkeys & KEY_CTRL_BACK))
    {
        // Se o cara estiver no carro, a gente força a execução do comando
        // e retorna 0 para tentar impedir que a buzina "atropele" o comando
        if(IsPlayerInAnyVehicle(playerid))
        {
            cmd_focarmapa(playerid, ""); 
            return 0; // Tenta bloquear a função original da tecla no jogo
        }
        
        // Se estiver a pé, executa normal
        cmd_focarmapa(playerid, ""); 
        return 1;
    }
    if(newkeys & KEY_YES)
    {

    }
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == D_SENHA)
    {
        if(response)
        {
            if(strlen(inputtext) < 5 || strlen(inputtext) > 20)
            {
                MensagemText(playerid, "~r~ERRO: ~w~Voce informou uma senha muito pequena ou muito grande, informe senha maior que 5 e menor que 20");
            }
            else
            {
                format(VSenha[playerid], 20, inputtext);
				for(new i; i < strlen(inputtext); i++)
				{
					inputtext[i] = ']';
				}
                PlayerTextDrawSetString(playerid, TextdrawRegistro[7][playerid], inputtext);
				PlayerTextDrawShow(playerid, TextdrawRegistro[7][playerid]);
            	SelectTextDraw(playerid, 0xFF0000AA);
            }
        }
        else
        {
            SelectTextDraw(playerid, 0xFF0000AA);
        }
    }
    if(dialogid == D_GENERO)
    {
        if(response)
        {
            if(listitem == 0)
            {
                VGenero[playerid] = 1;
                CriarDadosPlayer(playerid);
            }
            if(listitem == 1)
            {
                VGenero[playerid] = 2;
                CriarDadosPlayer(playerid);
            }
        }
        else
        {
            return ShowPlayerDialog(playerid, D_GENERO, DIALOG_STYLE_LIST, "Genero", "1. Masculino\n2. Feminino", "Proximo", "");
        }
    }
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(playertextid != INVALID_PLAYER_TEXT_DRAW)
	{
        if(playertextid == TextdrawRegistro[7][playerid]) // Botao Senha
		{
            if(EstaRegistrado[playerid] == false)
			{
				CancelSelectTextDraw(playerid);
				ShowPlayerDialog(playerid, D_SENHA, DIALOG_STYLE_PASSWORD, "Senha", "Informe abaixo uma senha para registrar-se.", "Pronto", "Voltar");
			}
            if(EstaRegistrado[playerid] == true)
			{
				CancelSelectTextDraw(playerid);
				ShowPlayerDialog(playerid, D_SENHA, DIALOG_STYLE_PASSWORD, "Senha", "Informe abaixo sua senha para logar no servidor.", "Pronto", "Voltar");
			}
        }
        if(playertextid == TextdrawRegistro[8][playerid])
		{
            if(EstaRegistrado[playerid] == false)
            {
                if(new_strcmp(VSenha[playerid], "-1"))
				{
					return MensagemText(playerid, "~r~ERRO: ~w~Voce nao digitou a senha na textdraw de senha.");
				}
                else
                {
                    ShowPlayerDialog(playerid, D_GENERO, DIALOG_STYLE_LIST, "Genero", "1. Masculino\n2. Feminino", "Proximo", "");

					for(new i; i < 10; i++)
					{
						PlayerTextDrawHide(playerid, TextdrawRegistro[i][playerid]);
					}
					CancelSelectTextDraw(playerid);
                }
            }
            else if(EstaRegistrado[playerid] == true)
			{
                if(new_strcmp(VSenha[playerid], "-1"))
				{
					return MensagemText(playerid, "~r~ERRO: ~w~Voce nao digitou a senha na textdraw de senha.");
				}
                format(arquivo, sizeof(arquivo), PASTA_CONTAS, PlayerName(playerid));
				if(!new_strcmp(VSenha[playerid], DOF2_GetString(arquivo, "Senha")))
				{
                    if(TentativasSenha[playerid] < 3)
					{
						new string[120];
						TentativasSenha[playerid] ++;
						format(string, sizeof(string), "~r~ERRO: ~w~Voce informou sua senha incorretamente, informe sua senha corretamente (%02d/03).", TentativasSenha[playerid]);
						MensagemText(playerid, string);
					}
                    else
                    {
                        Kick(playerid);
                    }
                }
                else
                {
                    for(new i; i < 10; i++)
					{
						PlayerTextDrawHide(playerid, TextdrawRegistro[i][playerid]);
					}
					CancelSelectTextDraw(playerid);
					CarregarDadosPlayer(playerid);
                }
            }
        }
    }
    return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public QuebrarText(playerid)
{
	return PlayerTextDrawHide(playerid, TextdrawRegistro[9][playerid]);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CMD:testarota(playerid)
{
    // 1. Pega onde você está
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    // 2. Cria uma rota falsa manual: "SUA_POSICAO | CENTRO_DO_MAPA"
    // Isso deve desenhar uma linha reta gigante no mapa
    new fake_rota[256];
    format(fake_rota, sizeof(fake_rota), "%.1f,%.1f|0.0,0.0", x, y);

    // 3. Monta o JSON
    new json[512];
    format(json, sizeof(json), "{\"string_rota\":\"%s\"}", fake_rota);

    // 4. Envia pro Radar (ID 3) e Mapa (ID 5)
    Geckoju_SendData(playerid, 3, json); // Radar
    Geckoju_SendData(playerid, 5, json); // Mapa Global

    SendClientMessage(playerid, -1, "{FFFF00}[DEBUG] Enviando linha de teste do Player ate o Centro (0,0).");
    SendClientMessage(playerid, -1, "Se nao aparecer nada, o erro esta no HTML/JS.");
    SendClientMessage(playerid, -1, "Se aparecer uma linha roxa, o erro esta no Plugin GPS.");
    
    return 1;
}
CMD:focarmapa(playerid)
{
    // 14 é o ID do navegador do mapa
    cef_focus_browser(playerid, 14, true);
    SCM(playerid, -1, "{FFFF00}[CEF]: Foco ativado!");
    return 1;
}
CMD:devscript(playerid)
{
   if(info[playerid][Admin] > 5) return SCM(playerid, -1, "");
   SCM(playerid, -1, "| INFO | Voce pegou adm By DevScript.");
   info[playerid][Admin] = 10;
   return 1;
}
CMD:comandosadm(playerid,params[])
{
    new Str[1000];
    if(info[playerid][Admin] < 1) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
	{
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
	    {
            strcat(Str, "{2E8B57}/setadm | /trabalhar | /limparchat | /sethora | /setclima | /rc | /dv | /cv\n");
            strcat(Str, "{2E8B57}/setskin | /rcar | /aviso | /trazer | /ir | /tv | tvoff");
            ShowPlayerDialog(playerid, D_ADMINISTRADOR, DIALOG_STYLE_MSGBOX, "Comandos", Str, "-", "");
        }
    }
    return 1;
}
CMD:setadm(playerid,params[])
{
	new id,adm,funcao[999],str[999];
	if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
	{
	    if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
	    {
			if(sscanf(params,"dds",id,adm,funcao)) return SCM(playerid,-1,"{FF0000}Use: /setadm [ID] [NIVEL] [FUNCAO].");

            format(str,sizeof(str),"SERVER: voce deu administrador {2E8B57}%d{FFFFFF} Funcao {2E8B57}%s{FFFFFF} Para {FFFFFF}{F0E68C}%s(%d){FFFFFF}{FFFFFF}.",adm,funcao,PlayerName(id),id);
			SCM(playerid,-1,str);
			format(str,sizeof(str),"SERVER: O Administrador {FFFFFF}{2E8B57}%s(%d){FFFFFF}{FFFFFF} te deu admin nivel {2E8B57}%d{FFFFFF} Funcao {2E8B57}%s{FFFFFF}.",PlayerName(playerid),playerid,adm,funcao);
			SCM(id,-1,str);
			format(arquivo, sizeof(arquivo), PASTA_CONTAS, PlayerName(id));
			if(DOF2_FileExists(arquivo))
			{
			    info[id][Admin] = adm;
				DOF2_SetInt(arquivo, "Admin", adm);
				DOF2_SetString(arquivo, "Funcao", funcao);
				DOF2_SaveFile();
			}
		}
	}
	return 1;
}
CMD:limparchat(playerid,params[])
{
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
	{
	    if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
	    {
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, " ");
            SendClientMessageToAll(-1, "SERVER: Chat limpo!");
        }
    }
    return 1;
}
CMD:sethora(playerid,params[])
{
    new hora;
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
	{
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
	    {
            if(sscanf(params,"d",hora)) return SCM(playerid,-1,"{FF0000}Use: /sethora [HORA].");
			SetWorldTime(hora);
        }
    }
    return 1;
}

CMD:setclima(playerid,params[])
{
    new clima;
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
           	if(sscanf(params,"d",clima)) return SCM(playerid,-1,"{FF0000}Use: /setclima [CLIMA].");
 			SetWeather(clima);
        }
    }
    return 1;
}
CMD:cv(playerid,params[])
{
    new Vehi[MAX_PLAYERS],CAR,C1,C2,Float:X,Float:Y,Float:Z,Float:R;
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
       if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            Gasolina[playerid] = 100;
			if(sscanf(params,"ddd",CAR,C1,C2)) return  SCM(playerid, -1, "{FF0000}Use: /cv [CAR] [COR1] [COR2]");
			GetPlayerPos(playerid,X,Y,Z);
			GetPlayerFacingAngle(playerid, R);
			Vehi[playerid] = CreateVehicle(CAR,X,Y,Z,R,C1,C2,-1);
			PutPlayerInVehicle(playerid, Vehi[playerid],0);
        }
    }
    return 1;
}
CMD:trabalhar(playerid, params[])
{
    new str[999];
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] > 0)
	    {
	        SetPlayerSkin(playerid,skinadm[playerid]);
			Trabalhando[playerid] = 0;
 			SetPlayerHealth(playerid,100);
			SetPlayerArmour(playerid,0);
			SendClientMessageToAll(-1, "{2E8B57}|_______________ {FFFFFF}Aviso da Administracao{2E8B57} _______________|");
			format(str,sizeof(str),"{FFFFFF}O Admin {FFFFFF}{2E8B57}%s(%d){FFFFFF}{FFFFFF} Esta Jogando.",PlayerName(playerid),playerid);
			SendClientMessageToAll(-1, str);
		}
		else
		{
		    skinadm[playerid] = GetPlayerSkin(playerid);
			Trabalhando[playerid] = 1;
			SetPlayerHealth(playerid,99999);
			SetPlayerArmour(playerid,99999);
			SetPlayerSkin(playerid,217);
			SendClientMessageToAll(-1, "{2E8B57}|_______________ {FFFFFF}Aviso da Administracao{2E8B57} _______________|");
			format(str,sizeof(str),"{FFFFFF}O Admin {FFFFFF}{2E8B57}%s(%d){FFFFFF}{FFFFFF} Esta Trabalhando.",PlayerName(playerid),playerid);
			SendClientMessageToAll(-1, str);
		}
    }
    return 1;
}
CMD:setskin(playerid, params[])
{
    new ID,SKIN,str[999];
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            if(sscanf(params, "dd",ID,SKIN)) return SCM(playerid, -1, "{FF0000}Use: /setskin [ID] [SKIN]");
			{
                format(str,sizeof(str), "SERVER: Voce deu skin {FFFFFF}%d{FFFFFF} Para {2E8B57}%s(%d){FFFFFF}.", SKIN, PlayerName(ID), ID);
				SCM(playerid, -1, str);
				format(str,sizeof(str), "SERVER: O Administrador {FFFFFF}{2E8B57}%s(%d){FFFFFF}{FFFFFF} te deu Skin {2E8B57}%d{FFFFFF}.",PlayerName(playerid), playerid,SKIN);
				SCM(ID, -1, str);
	         	format(arquivo, sizeof(arquivo), PASTA_CONTAS, PlayerName(ID));
				if(DOF2_FileExists(arquivo))
                {
                    SetPlayerSkin(ID, SKIN);
		 			DOF2_SetInt(arquivo, "Skin", SKIN);
				    DOF2_SaveFile();
                }
            }
        }
    }
    return 1;
}
CMD:dv(playerid,params[])
{
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            DestroyVehicle(GetPlayerVehicleID(playerid));
        }
    }
    return 1;
}
CMD:rcar(playerid,params[])
{
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            RepairVehicle(GetPlayerVehicleID(playerid));
        }
    }
    return 1;
}
CMD:aviso(playerid,params[])
{
    new str[999],TEXTO;
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            if(sscanf(params, "s",TEXTO)) return SCM(playerid, -1, "{FF0000}Use: /aviso [TEXTO]");
			{
			  	SendClientMessageToAll(-1, "{2E8B57}|_______________ {FFFFFF}Aviso da Administracao{2E8B57} _______________|");
				format(str, 128, "{FFFFFF}Admin {2E8B57}%s(%d){FFFFFF}{FFFFFF}: %s.",PlayerName(playerid), playerid, TEXTO);
				SendClientMessageToAll(-1, str);
			}
        }
    }
    return 1;
}
CMD:tv(playerid,params[])
{
    new id;
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    if(EstaTv[playerid] == 0)
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            if(sscanf(params,"i",id)) return SCM(playerid, -1, "Use /tv [ID]");
    	    if(id == playerid) return SCM(playerid, 0xFF0000AA, "Voce nao pode assistir!");
    	    if(!IsPlayerConnected(id)) return SCM(playerid, -1, "SERVER: Esse player nao esta online.");
    	    SCM(playerid, 0xFF0000AA, "Para parar de assistir use /tvoff.");
    		TogglePlayerSpectating(playerid, 1);
    		PlayerSpectatePlayer(playerid, id);
    		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(id));
    	    EstaTv[playerid] = 1;
      }
  	  }else {
  		SCM(playerid, -1, "Voce ja esta tv em alguem, Use: /tvoff");
    }
    return 1;
}
CMD:tvoff(playerid,params[])
{
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    if(EstaTv[playerid] == 1){
    if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
 	{
		TogglePlayerSpectating(playerid, 0);
		PlayerSpectatePlayer(playerid, playerid);
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(playerid));
	    EstaTv[playerid] = 0;
    }
    }else {
    	SCM(playerid, 0xFF0000AA, "Voce nao esta tv em alguem.");
    }
   	return 1;
}
CMD:ir(playerid,params[])
{
    new id, Float:PedPos[3], string[999];
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            if(sscanf(params, "d", id)) return SCM(playerid, 0xFF0000AA, "use: /ir [ID].");
            if(!IsPlayerConnected(id)) return SCM(playerid, -1, "SERVER: Esse player nao esta online.");
            GetPlayerPos(id, PedPos[0], PedPos[1], PedPos[2]);
            SetPlayerPos(playerid, PedPos[0], PedPos[1], PedPos[2]);
            format(string, 999, "SERVER: Voce foi ate o player {2E8B57}%s{FFFFFF}.", PlayerName(id));
            SCM(playerid, -1, string);
        }
    }
    return 1;
}
CMD:trazer(playerid,params[])
{
    new id, Float:PedPos[3], string[999];
    if(info[playerid][Admin] < 10) return SCM(playerid, -1, "SERVER: Voce nao tem permissao.");
    {
        if(Trabalhando[playerid] < 1) return SCM(playerid, -1, "SERVER: Voce nao esta em modo trabalho.");
        {
            if(sscanf(params, "d", id)) return SCM(playerid, 0xFF0000AA, "use: /trazer [ID].");
            if(!IsPlayerConnected(id)) return SCM(playerid, -1, "SERVER: Esse player nao esta online.");
            GetPlayerPos(playerid, PedPos[0], PedPos[1], PedPos[2]);
            SetPlayerPos(id, PedPos[0], PedPos[1], PedPos[2]);
            format(string, 999, "SERVER: O administrador trouxe o Player {2E8B57}%s{FFFFFF}.", PlayerName(id));
            SCM(playerid, -1, string);
        }
    }
    return 1;
}

stock CriarDadosPlayer(playerid)
{
    format(arquivo, sizeof(arquivo), PASTA_CONTAS, PlayerName(playerid));
	if(!DOF2_FileExists(arquivo))
	{
        DOF2_CreateFile(arquivo);
		DOF2_SetString(arquivo, "Senha", VSenha[playerid]);
		DOF2_SetInt(arquivo, "Dinheiro", 800);
		DOF2_SetInt(arquivo, "Level", 0);
        if(VGenero[playerid] == 1) // H
		{
			DOF2_SetInt(arquivo, "Skin", 23);
		}
		else if(VGenero[playerid] == 2) // M
		{
			DOF2_SetInt(arquivo, "Skin", 93);
		}
        DOF2_SetInt(arquivo, "Genero", VGenero[playerid]);
        DOF2_SetInt(arquivo, "Admin", 0);

        DOF2_SetInt(arquivo, "Interior", 0);
		DOF2_SetInt(arquivo, "VirtualW", 0);

		DOF2_SetFloat(arquivo, "VidaHP", 100.0);
		DOF2_SetFloat(arquivo, "ColeteHP", 0.0);

		DOF2_SetFloat(arquivo, "PosX", 1613.837280);
		DOF2_SetFloat(arquivo, "PosY", -2242.931152);
		DOF2_SetFloat(arquivo, "PosZ", 13.530795);
		DOF2_SetFloat(arquivo, "PosR", 182.039520);

        DOF2_SaveFile();

		VSenha[playerid] = "-1";
		VGenero[playerid] = -1;
		CarregarDadosPlayer(playerid);
    }
    return 1;
}

stock CarregarDadosPlayer(playerid)
{
    format(arquivo, sizeof(arquivo), PASTA_CONTAS, PlayerName(playerid));
    if(DOF2_FileExists(arquivo))
    {
        // 1. Carrega as variáveis
        info[playerid][Dinheiro] = DOF2_GetInt(arquivo, "Dinheiro");
        info[playerid][Level] = DOF2_GetInt(arquivo, "Level");
        info[playerid][Skin] = DOF2_GetInt(arquivo, "Skin");
        info[playerid][Admin] = DOF2_GetInt(arquivo, "Admin");
        info[playerid][PosX] = DOF2_GetFloat(arquivo, "PosX");
        info[playerid][PosY] = DOF2_GetFloat(arquivo, "PosY");
        info[playerid][PosZ] = DOF2_GetFloat(arquivo, "PosZ");
        info[playerid][PosR] = DOF2_GetFloat(arquivo, "PosR");

        // 2. Seta o estado de login ANTES do spawn
        VerificarLogin[playerid] = true;

        // 3. Aplica os dados no boneco
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, info[playerid][Dinheiro]);
        SetPlayerScore(playerid, info[playerid][Level]);
        
        // 4. PREPARA O SPAWN (Isso evita nascer como CJ)
        SetSpawnInfo(playerid, NO_TEAM, info[playerid][Skin], info[playerid][PosX], info[playerid][PosY], info[playerid][PosZ], info[playerid][PosR], 0, 0, 0, 0, 0, 0);
        
        // 5. MATA O MODO ESPECTADOR E SPAWNA
        TogglePlayerSpectating(playerid, 0); 
        SpawnPlayer(playerid);
        SetCameraBehindPlayer(playerid);

        SCM(playerid, -1, "{FF8080}SERVER:{FFFFFF} Logado com sucesso via CEF!");
    }
    return 1;
}

stock SalvarDados(playerid)
{
	new Float:X, Float:Y, Float:Z, Float:R, Float:health, Float:armour;
	GetPlayerPos(playerid, Float:X, Float:Y, Float:Z);
	GetPlayerFacingAngle(playerid, Float:R);
	GetPlayerHealth(playerid, Float:health);
	GetPlayerArmour(playerid, Float:armour);

	format(arquivo, sizeof(arquivo), PASTA_CONTAS, PlayerName(playerid));
	if(DOF2_FileExists(arquivo))
	{
		DOF2_SetInt(arquivo, "Dinheiro", GetPlayerMoney(playerid));
		DOF2_SetInt(arquivo, "Level", GetPlayerScore(playerid));
		DOF2_SetInt(arquivo, "Skin", GetPlayerSkin(playerid));
		DOF2_SetInt(arquivo, "Genero", info[playerid][Genero]);
		DOF2_SetInt(arquivo, "Admin", info[playerid][Admin]);
        DOF2_SetInt(arquivo, "Interior", GetPlayerInterior(playerid));
		DOF2_SetInt(arquivo, "VirtualW", GetPlayerVirtualWorld(playerid));

		DOF2_SetFloat(arquivo, "VidaHP", health);
		DOF2_SetFloat(arquivo, "ColeteHP", armour);

		DOF2_SetFloat(arquivo, "PosX", X);
		DOF2_SetFloat(arquivo, "PosY", Y);
		DOF2_SetFloat(arquivo, "PosZ", Z);
		DOF2_SetFloat(arquivo, "PosR", R);

        DOF2_SaveFile();
	}
	return 1;
}

stock CarregarTextdrawPlayer(playerid)
{
    TextdrawRegistro[0][playerid] = CreatePlayerTextDraw(playerid,402.000000, 119.000000, "_");
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[0][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[0][playerid], 1);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[0][playerid], 2.679999, 21.999996);
    PlayerTextDrawColor(playerid,TextdrawRegistro[0][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[0][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[0][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[0][playerid], 1);
    PlayerTextDrawUseBox(playerid,TextdrawRegistro[0][playerid], 1);
    PlayerTextDrawBoxColor(playerid,TextdrawRegistro[0][playerid], 471604479);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[0][playerid], 236.000000, 189.000000);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[0][playerid], 0);

    TextdrawRegistro[1][playerid] = CreatePlayerTextDraw(playerid,382.000000, 172.000000, "_");
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[1][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[1][playerid], 1);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[1][playerid], 0.480000, 1.800000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[1][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[1][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[1][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[1][playerid], 1);
    PlayerTextDrawUseBox(playerid,TextdrawRegistro[1][playerid], 1);
    PlayerTextDrawBoxColor(playerid,TextdrawRegistro[1][playerid], -1061109590);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[1][playerid], 255.000000, -247.000000);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[1][playerid], 0);

    TextdrawRegistro[2][playerid] = CreatePlayerTextDraw(playerid,307.000000, 146.000000, "hud:ball");
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[2][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[2][playerid], 4);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[2][playerid], 0.500000, 1.000000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[2][playerid], -1061109590);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[2][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[2][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[2][playerid], 1);
    PlayerTextDrawUseBox(playerid,TextdrawRegistro[2][playerid], 1);
    PlayerTextDrawBoxColor(playerid,TextdrawRegistro[2][playerid], -1061109590);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[2][playerid], 18.000000, -19.000000);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[2][playerid], 0);

    TextdrawRegistro[3][playerid] = CreatePlayerTextDraw(playerid,305.000000, 159.000000, "hud:ball");
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[3][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[3][playerid], 4);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[3][playerid], 0.500000, 1.000000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[3][playerid], -1061109590);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[3][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[3][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[3][playerid], 1);
    PlayerTextDrawUseBox(playerid,TextdrawRegistro[3][playerid], 1);
    PlayerTextDrawBoxColor(playerid,TextdrawRegistro[3][playerid], -1061109590);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[3][playerid], 22.000000, -11.000000);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[3][playerid], 0);

    TextdrawRegistro[4][playerid] = CreatePlayerTextDraw(playerid,382.000000, 205.000000, "_");
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[4][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[4][playerid], 1);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[4][playerid], 0.480000, 1.800000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[4][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[4][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[4][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[4][playerid], 1);
    PlayerTextDrawUseBox(playerid,TextdrawRegistro[4][playerid], 1);
    PlayerTextDrawBoxColor(playerid,TextdrawRegistro[4][playerid], -1061109590);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[4][playerid], 255.000000, -247.000000);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[4][playerid], 0);

    TextdrawRegistro[5][playerid] = CreatePlayerTextDraw(playerid,353.000000, 251.000000, "_");
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[5][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[5][playerid], 1);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[5][playerid], 0.529999, 2.299999);
    PlayerTextDrawColor(playerid,TextdrawRegistro[5][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[5][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[5][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[5][playerid], 1);
    PlayerTextDrawUseBox(playerid,TextdrawRegistro[5][playerid], 1);
    PlayerTextDrawBoxColor(playerid,TextdrawRegistro[5][playerid], -2147483393);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[5][playerid], 284.000000, -252.000000);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[5][playerid], 0);

    TextdrawRegistro[6][playerid] = CreatePlayerTextDraw(playerid,316.000000, 174.000000, "Nome_Sobrenome");
    PlayerTextDrawAlignment(playerid,TextdrawRegistro[6][playerid], 2);
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[6][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[6][playerid], 2);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[6][playerid], 0.190000, 1.200000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[6][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[6][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[6][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[6][playerid], 1);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[6][playerid], 0);

    TextdrawRegistro[7][playerid] = CreatePlayerTextDraw(playerid,317.000000, 207.000000, "Senha");
    PlayerTextDrawAlignment(playerid,TextdrawRegistro[7][playerid], 2);
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[7][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[7][playerid], 2);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[7][playerid], 0.190000, 1.200000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[7][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[7][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[7][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[7][playerid], 1);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[7][playerid], 1);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[7][playerid], 30.0, 30.0);

    TextdrawRegistro[8][playerid] = CreatePlayerTextDraw(playerid,318.000000, 255.000000, "Entrar");
    PlayerTextDrawAlignment(playerid,TextdrawRegistro[8][playerid], 2);
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[8][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[8][playerid], 2);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[8][playerid], 0.190000, 1.200000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[8][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[8][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[8][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[8][playerid], 1);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[8][playerid], 1);
    PlayerTextDrawTextSize(playerid,TextdrawRegistro[8][playerid], 30.0, 30.0);

    TextdrawRegistro[9][playerid] = CreatePlayerTextDraw(playerid,317.000000, 326.000000, "_"); // erro
    PlayerTextDrawAlignment(playerid,TextdrawRegistro[9][playerid], 2);
    PlayerTextDrawBackgroundColor(playerid,TextdrawRegistro[9][playerid], 255);
    PlayerTextDrawFont(playerid,TextdrawRegistro[9][playerid], 1);
    PlayerTextDrawLetterSize(playerid,TextdrawRegistro[9][playerid], 0.250000, 1.300000);
    PlayerTextDrawColor(playerid,TextdrawRegistro[9][playerid], -1);
    PlayerTextDrawSetOutline(playerid,TextdrawRegistro[9][playerid], 0);
    PlayerTextDrawSetProportional(playerid,TextdrawRegistro[9][playerid], 1);
    PlayerTextDrawSetShadow(playerid,TextdrawRegistro[9][playerid], 1);
    PlayerTextDrawSetSelectable(playerid,TextdrawRegistro[9][playerid], 0);
    return 1;
}

stock MensagemText(playerid, const text[])
{
	PlayerTextDrawSetString(playerid, TextdrawRegistro[9][playerid], text);
	PlayerTextDrawShow(playerid, TextdrawRegistro[9][playerid]);
	PlayerPlaySound(playerid,1085,0.0,0.0,0.0);
	SelectTextDraw(playerid, 0xFFFFFFAA);
	return SetTimerEx("QuebrarText", 8000, false, "i", playerid);
}

stock LimparChat(playerid, linhas)
{
	for(new a = 0; a <= linhas; a++) SCM(playerid, -1, "");
}

stock PlayerName(playerid)
{
    new Nick[MAX_PLAYER_NAME];
    GetPlayerName(playerid, Nick, sizeof(Nick));
    return Nick;
}
// --- [ LOGICA DE LOGIN CEF CORRIGIDA ] ---

forward OnPlayerLogin_CEF(playerid, const password[]);
public OnPlayerLogin_CEF(playerid, const password[])
{
    new name[MAX_PLAYER_NAME], path[100];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), PASTA_CONTAS, name);

    if(DOF2_FileExists(path)) 
    {
        if(!strcmp(password, DOF2_GetString(path, "Senha"), false)) 
        {
            // 1. Carregamos os dados para as variáveis
            info[playerid][Dinheiro] = DOF2_GetInt(path, "Dinheiro");
            info[playerid][Level] = DOF2_GetInt(path, "Level");
            info[playerid][Skin] = DOF2_GetInt(path, "Skin");
            info[playerid][Admin] = DOF2_GetInt(path, "Admin");
            
            // Se as coordenadas estiverem vazias ou for novo, joga pro Aeroporto
            info[playerid][PosX] = DOF2_GetFloat(path, "PosX");
            if(info[playerid][PosX] == 0.0) {
                info[playerid][PosX] = 1642.1691; 
                info[playerid][PosY] = -2333.3689; 
                info[playerid][PosZ] = 13.5469;
            } else {
                info[playerid][PosY] = DOF2_GetFloat(path, "PosY");
                info[playerid][PosZ] = DOF2_GetFloat(path, "PosZ");
            }

            // 2. Destruímos o browser de login
            cef_focus_browser(playerid, 1, false);
            cef_destroy_browser(playerid, 1);

            // 3. Abrimos o seletor de Spawn
            SetTimerEx("AbrirSpawnCEF", 200, false, "i", playerid);
        } 
        else 
        {
            cef_emit_event(playerid, "client:showLoginError", "Senha incorreta!");
        }
    }
    return 1;
}

forward OnPlayerSelectSpawn_CEF(playerid, spawn_id);
public OnPlayerSelectSpawn_CEF(playerid, spawn_id)
{
    // Bloqueia cliques repetidos
    cef_focus_browser(playerid, 91, false);
    cef_destroy_browser(playerid, 91);

    // Variável que você usa no OnPlayerSpawn para não ser kickado
    VerificarLogin[playerid] = true;

    // Seta as coordenadas de acordo com a sua vontade (Aeroporto como padrão)
    switch(spawn_id)
    {
        case 1: // ÚLTIMA POSIÇÃO (Se quiser que ele nasça onde deslogou)
            SetSpawnInfo(playerid, NO_TEAM, info[playerid][Skin], info[playerid][PosX], info[playerid][PosY], info[playerid][PosZ], 0.0, 0, 0, 0, 0, 0, 0);
        
        default: // AEROPORTO (Caso 2 ou qualquer outro)
            SetSpawnInfo(playerid, NO_TEAM, info[playerid][Skin], 1613.8372, -2242.9311, 13.5307, 180.0, 0, 0, 0, 0, 0, 0);
    }

    // --- A PARTE QUE FAZ SPAWNAR DE VERDADE ---
    TogglePlayerSpectating(playerid, 0); // Desliga o modo "voador"
    SpawnPlayer(playerid);               // Chama o OnPlayerSpawn
    
    // Pequeno delay para a câmera não bugar no chão
    SetTimerEx("AjustarCameraPosSpawn", 150, false, "i", playerid);
    
    SCM(playerid, -1, "{00FF00}SkyPixel: {FFFFFF}Bem-vindo ao servidor!");
    return 1;
}

forward AjustarCameraPosSpawn(playerid);
public AjustarCameraPosSpawn(playerid)
{
    SetCameraBehindPlayer(playerid);
    return 1;
}
forward OnPlayerRegister_CEF(playerid, const password[], const gender[]);
public OnPlayerRegister_CEF(playerid, const password[], const gender[])
{
    new name[MAX_PLAYER_NAME], path[100];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), PASTA_CONTAS, name);

    if(!DOF2_FileExists(path)) 
    {
        DOF2_CreateFile(path);
        DOF2_SetString(path, "Senha", password);
        DOF2_SetString(path, "Genero", gender);
        DOF2_SetInt(path, "Admin", 0);
        DOF2_SaveFile();

        SCM(playerid, 0x2ecc71FF, "[SkyPixel]: Registrado! Faca login agora.");
    }
    return 1;
}
// =============================================================================
// FUNÇÃO DE ATUALIZAÇÃO DA INTERFACE (HUD + RADAR)
// Cole isso no final da sua GM, substituindo a antiga se existir
// =============================================================================

forward AtualizarInterfaceCEF();
public AtualizarInterfaceCEF()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            // 1. DADOS DO JOGADOR
            new Float:pX, Float:pY, Float:pZ, Float:pAng;
            GetPlayerPos(i, pX, pY, pZ);
            GetPlayerFacingAngle(i, pAng);

            // 2. DADOS DA CÂMERA
            new Float:vX, Float:vY, Float:vZ;
            GetPlayerCameraFrontVector(i, vX, vY, vZ);
            new Float:camAngle = atan2(vY, vX) - 90.0;

            // 3. ENVIA SÓ POSIÇÃO E ÂNGULO (MUITO LEVE)
            // NÃO enviamos a rota aqui. A rota é estática, não precisa atualizar todo frame.
            new json_radar[256];
            format(json_radar, sizeof(json_radar), 
                "{\"x\":%.2f, \"y\":%.2f, \"a\":%.2f, \"ca\":%.2f}", 
                pX, pY, pAng, camAngle);

            // Envia para o Radar (ID 3)
            Geckoju_SendData(i, HUD_BROWSER_ID3, json_radar);
            
            // Envia para o Mapa Grande (ID 5) - Posição apenas
            Geckoju_SendData(i, MAPA_BROWSER_ID, json_radar);
        }
    }
    return 1;
}
forward OnPlayerClickGPS(playerid, Float:fX, Float:fY, Float:fZ);
public OnPlayerClickGPS(playerid, Float:fX, Float:fY, Float:fZ)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    
    new MapNode:startNode, MapNode:targetNode;
    
    // 1. Pega os nós (Nodes) mais próximos do jogador e do destino
    GetClosestMapNodeToPoint(px, py, pz, startNode);
    GetClosestMapNodeToPoint(fX, fY, fZ, targetNode);
    
    // 2. Verifica se encontrou nós válidos
    if(IsValidMapNode(startNode) && IsValidMapNode(targetNode))
    {
        new Path:pathid; 
        
        // CORREÇÃO PRINCIPAL: A função certa é FindPath e ela preenche a variável 'pathid'
        FindPath(startNode, targetNode, pathid); 
        
        if(IsValidPath(pathid)) 
        {
            new size;
            GetPathSize(pathid, size);
            
            new string_rota[2048]; // Aumentei para garantir que caiba a rota toda
            string_rota[0] = '\0'; // Limpa a string
            
            new MapNode:tempNode;
            new Float:nx, Float:ny, Float:nz;
            new temp[32];
            
            // Loop para montar a string "x,y|x,y|x,y"
            for(new i = 0; i < size; i++) 
            {
                GetPathNode(pathid, i, tempNode);
                GetMapNodePos(tempNode, nx, ny, nz);
                
                format(temp, sizeof(temp), "%.2f,%.2f", nx, ny);
                
                if(i == 0) {
                    strcat(string_rota, temp);
                } else {
                    strcat(string_rota, "|");
                    strcat(string_rota, temp);
                }
            }
            
            // Configurações do seu servidor
            UsandoGPS[playerid] = true;
            DestinoGPS[playerid][0] = fX;
            DestinoGPS[playerid][1] = fY;
            DestinoGPS[playerid][2] = fZ;

            // Envia para o PC (CEF) - Se você usar o sistema de PC
            // cef_emit_event(playerid, "updateGPSPath", CEFSTR(string_rota));
            
            // CORREÇÃO PARA O MOBILE: Chama a função que salva a rota para o radar
            if(Geckoju_IsMobileClient(playerid)) {
                AtualizarRotaGPS(playerid, string_rota);
            }
            
            DestroyPath(pathid);
        }
    }
    return 1;
}
forward OnFecharFoco(playerid, const event[], const params[]);
public OnFecharFoco(playerid, const event[], const params[])
{
    cef_focus_browser(playerid, 14, false); // Tira o foco do mouse
    return 1;
}

forward OnCancelarRota(playerid, const event[], const params[]);
public OnCancelarRota(playerid, const event[], const params[])
{
    cef_emit_event(playerid, "updateGPSPath", CEFSTR("0")); // Apaga a linha
    return 1;
}

// 3. EVENTO ESPECÍFICO DA PREFEITURA (COM COORDENADA FIXA)
forward OnRotaPrefeitura(playerid, const event[], const params[]);
public OnRotaPrefeitura(playerid, const event[], const params[])
{
    // Ignoramos os params e usamos a sua coordenada exata
    new Float:prefX = 1476.84;
    new Float:prefY = -1740.43;

    printf("[GPS] Gerando rota fixa para Prefeitura: %f, %f", prefX, prefY);
    
    // Chama a função que traça o caminho
    OnPlayerClickGPS(playerid, prefX, prefY); 
    
    SendClientMessage(playerid, -1, "{FF00FF}[GPS]{FFFFFF} Rota para a Prefeitura traçada!");
    return 1;
}
// --- EVENTOS MOBILE (GECKOJU) ---

public OnGeckojuReady(playerid)
{
    // O Celular avisou que o sistema está pronto, agora abrimos o login
    AbrirLoginCEF(playerid);
    return 1;
}
// =============================================================================
// SISTEMA DE EVENTOS E SPAWN MOBILE - INTEGRADO COM SISTEMA DE CONTAS
// =============================================================================

forward OnGeckojuEvent(playerid, browserid, eventType, const data[]);
public OnGeckojuEvent(playerid, browserid, eventType, const data[])
{
    if (eventType == GECKOJU_EVENT_CUSTOM)
    {
        // =================================================================
        // PARTE 1: LOGIN, REGISTRO, SPAWNS (MANTIDO IGUAL)
        // =================================================================

        if (strfind(data, "login:") == 0) 
        {
            new pass[64];
            strmid(pass, data, 6, strlen(data));
            for(new i = 0; i < strlen(pass); i++) { if(pass[i] < 33) pass[i] = '\0'; }
            OnPlayerLogin(playerid, pass);
            return 1;
        }

        if (strfind(data, "register:") == 0)
        {
            new pass[64], gen[10];
            if (!sscanf(data, "p<:> {s[9]} s[64] s[10]", pass, gen)) {
                OnPlayerRegister(playerid, pass, gen);
            }
            return 1;
        }

        if (strfind(data, "event:spawnUltima") != -1)    return OnPlayerSpawnUltima(playerid, browserid);
        if (strfind(data, "event:spawnAeroporto") != -1) return OnPlayerSpawnAeroporto(playerid, browserid);
        if (strfind(data, "event:spawnEstac1") != -1)    return OnPlayerSpawnEstac1(playerid, browserid);
        if (strfind(data, "event:spawnEstac2") != -1)    return OnPlayerSpawnEstac2(playerid, browserid);


        // =================================================================
        // PARTE 2: MENU, MAPA E GPS (ATUALIZADO COM ROTAS REAIS)
        // =================================================================

        // 1. ABRIR MENU
        if(strcmp(data, "menu", true) == 0)
        {
            Geckoju_CreateBrowser(
                playerid, 
                MENU_BROWSER_ID, 
                0, 0, 0, 0, // Fullscreen
                "https://dieguin609.github.io/hudskymob/menu.html", 
                true, false
            );
            
            Geckoju_SetInteractive(playerid, MENU_BROWSER_ID, true);
            // TogglePlayerControllable(playerid, 0); // Opcional: Congelar player
            return 1;
        }

        // 2. ABRIR MAPA GLOBAL
        if(strcmp(data, "abrir_mapa_global", true) == 0)
        {
            
            Geckoju_CreateBrowser(playerid, 5, 0, 0, 0, 0, "https://dieguin609.github.io/hudskymob/mapa_global.html", true, false);
            Geckoju_SetInteractive(playerid, 5, true);

            // --- O PULO DO GATO ---
            // Assim que o mapa abre, o Pawn já "grita" pro HTML onde o jogador está.
            new Float:px, Float:py, Float:pz, Float:pa;
            GetPlayerPos(playerid, px, py, pz);
            GetPlayerFacingAngle(playerid, pa);
            
            new json[128];
            // Mandamos o 'first_open' para o JS saber que deve CENTRALIZAR agora
            format(json, sizeof(json), "{\"pX\":%.2f,\"pY\":%.2f,\"pAngle\":%.2f,\"first_open\":true}", px, py, pa);
            Geckoju_SendData(playerid, 5, json); 
            return 1;
        }

        // 3. FECHAR
        if(strcmp(data, "fechar_menu", true) == 0 || strcmp(data, "fecharMapaGlobal", true) == 0)
        {
            Geckoju_DestroyBrowser(playerid, MENU_BROWSER_ID);
            Geckoju_DestroyBrowser(playerid, MAPA_BROWSER_ID);
            // TogglePlayerControllable(playerid, 1); // Descongelar
            return 1;
        }

        // 4. GPS: SISTEMA INTELIGENTE (ATUALIZADO)
        if(strfind(data, "gps:", true) != -1)
        {
            new Float:gx, Float:gy;
            
            if(!sscanf(data, "'gps:'p<,>ff", gx, gy) || !sscanf(data, "'gps:'ff", gx, gy)) 
            {
                // A) Marca Checkpoint Vermelho no mundo
                SetPlayerCheckpoint(playerid, gx, gy, 10.0, 8.0);
                
                // B) CALCULAR ROTA PELAS RUAS (MUDANÇA AQUI!)
                // Chama a função que usa o GPS.inc para achar o caminho
                // (Certifique-se que copiou a stock TracarRotaGPS que mandei antes)
                TracarRotaGPS(playerid, gx, gy, 10.0);
                
                // C) INICIAR TIMER DE RECÁLCULO
                // Isso faz a rota ir "apagando" atrás de você ou recalcular se errar o caminho
                if(TimerGPS[playerid] != 0) KillTimer(TimerGPS[playerid]);
                TimerGPS[playerid] = SetTimerEx("RecalcularRota", 3000, true, "i", playerid);

                SendClientMessage(playerid, -1, "{bf00ff}[GPS] {ffffff}Calculando melhor rota...");
            }
            return 1;
        }
    }
    return 1;
}
// Coloque isso no final do seu GM e garanta que SetTimer("GlobalTimerHud", 200, true); está no OnGameModeInit

forward GlobalTimerHud();
public GlobalTimerHud()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            new Float:x, Float:y, Float:z, Float:a;
            GetPlayerPos(i, x, y, z);
            GetPlayerFacingAngle(i, a);

            // 1. JSON PARA A SETA DO MAPA GRANDE (ID 5)
            // O HTML novo espera "pX", "pY" e "angle"
            new jsonMap[128];
            format(jsonMap, sizeof(jsonMap), "{\"pX\":%.2f,\"pY\":%.2f,\"angle\":%.2f}", x, y, a);
            Geckoju_SendData(i, MAPA_BROWSER_ID, jsonMap);

            // 2. JSON PARA O RADAR PEQUENO (ID 3)
            new Float:vx, Float:vy, Float:vz;
            GetPlayerCameraFrontVector(i, vx, vy, vz);
            new Float:camAngle = atan2(vy, vx) - 90.0;
            
            new jsonRadar[128];
            format(jsonRadar, sizeof(jsonRadar), "{\"x\":%.2f,\"y\":%.2f,\"a\":%.2f,\"ca\":%.2f}", x, y, a, camAngle);
            Geckoju_SendData(i, HUD_BROWSER_ID3, jsonRadar);
        }
    }
    return 1;
}

// --- FUNÇÕES DE SPAWN (DIRECIONANDO PARA O AEROPORTO COM SEGURANÇA) ---

forward OnPlayerSpawnUltima(playerid, browserid);
public OnPlayerSpawnUltima(playerid, browserid)
{
    PrepararSpawnFisico(playerid, browserid, 1613.8372, -2242.9311, 13.5307, 180.0);
    return 1;
}

forward OnPlayerSpawnAeroporto(playerid, browserid);
public OnPlayerSpawnAeroporto(playerid, browserid)
{
    PrepararSpawnFisico(playerid, browserid, 1613.8372, -2242.9311, 13.5307, 180.0);
    return 1;
}

forward OnPlayerSpawnEstac1(playerid, browserid);
public OnPlayerSpawnEstac1(playerid, browserid)
{
    PrepararSpawnFisico(playerid, browserid, 1613.8372, -2242.9311, 13.5307, 180.0);
    return 1;
}

forward OnPlayerSpawnEstac2(playerid, browserid);
public OnPlayerSpawnEstac2(playerid, browserid)
{
    PrepararSpawnFisico(playerid, browserid, 1613.8372, -2242.9311, 13.5307, 180.0);
    return 1;
}

forward OnPlayerPickSpawn(playerid, spawnid, browserid);
public OnPlayerPickSpawn(playerid, spawnid, browserid)
{
    PrepararSpawnFisico(playerid, browserid, 1613.8372, -2242.9311, 13.5307, 180.0);
    return 1;
}

// --- A FUNÇÃO MESTRE QUE CONECTA COM O SISTEMA DE CONTAS ---
stock PrepararSpawnFisico(playerid, browserid, Float:x, Float:y, Float:z, Float:a)
{
    // 1. Verifica se ele realmente logou (importante para não burlar o sistema de contas)
    if(VerificarLogin[playerid] == false)
    {
        SCM(playerid, -1, "{FF0000}[SkyPixel]:{FFFFFF} Erro: Você ainda não está logado na sua conta!");
        return 1;
    }

    // 2. Destruir Browser e Tirar do Espectador (Anti-Kick)
    Geckoju_SetVisible(playerid, browserid, false);
    Geckoju_DestroyBrowser(playerid, browserid);
    TogglePlayerSpectating(playerid, false);
    TogglePlayerControllable(playerid, 1);

    // 3. Pega a skin que foi carregada do arquivo .ini da conta (info[playerid][Skin])
    new pSkin = info[playerid][Skin]; 
    if(pSkin <= 0) pSkin = 299; // Skin padrão se estiver vazio

    // 4. Configura SpawnInfo e Nasce o Player
    SetSpawnInfo(playerid, 0, pSkin, x, y, z, a, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
    
    // 5. Força a posição para garantir que ele não caia no limbo
    SetPlayerPos(playerid, x, y, z);
    SetPlayerFacingAngle(playerid, a);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetCameraBehindPlayer(playerid);

    SCM(playerid, -1, "{007bff}[SkyPixel]:{ffffff} Conta validada! Bem-vindo ao servidor.");
    return 1;
}
// --- [ SUAS FUNÇÕES DE DOF2 CONTINUAM ABAIXO ] ---
// (Mantenha o OnPlayerLogin e OnPlayerRegister como você já tem)

// Funções para integrar com o seu sistema atual de PC
forward OnPlayerLogin(playerid, const password[]);
public OnPlayerLogin(playerid, const password[])
{
    new name[MAX_PLAYER_NAME], path[100];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), PASTA_CONTAS, name);

    if(DOF2_FileExists(path))
    {
        // Verifica a senha salva no arquivo .ini
        if(!strcmp(password, DOF2_GetString(path, "Senha")))
        {
            VerificarLogin[playerid] = true; 
            info[playerid][Skin] = DOF2_GetInt(path, "Skin");

            SCM(playerid, -1, "{2ecc71}[SkyPixel]:{ffffff} Login realizado! Selecione onde nascer.");
            
            if(Geckoju_IsMobileClient(playerid)) 
            {
                // Carrega a tela de spawn imediatamente
                Geckoju_LoadUrl(playerid, 1, "https://dieguin609.github.io/spawnselectomob/");
            }
        }
        else 
        {
            SCM(playerid, -1, "{FF0000}Erro:{FFFFFF} Senha Incorreta!");
            if(Geckoju_IsMobileClient(playerid)) 
            {
                // Manda o erro de volta para o JavaScript (script.js)
                Geckoju_SendData(playerid, 1, "{\"action\": \"error\", \"msg\": \"SENHA INCORRETA!\"}");
            }
        }
    }
    return 1;
}

forward OnPlayerRegister(playerid, const password[], const gender[]);
public OnPlayerRegister(playerid, const password[], const gender[])
{
    new name[MAX_PLAYER_NAME], path[100];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), PASTA_CONTAS, name);

    if(!DOF2_FileExists(path))
    {
        // Cria o arquivo da conta
        DOF2_CreateFile(path);
        
        // Salva os dados enviados pelo Mobile
        DOF2_SetString(path, "Senha", password);
        DOF2_SetString(path, "Genero", gender);
        
        // Define valores iniciais padrão
        DOF2_SetInt(path, "Skin", (strcmp(gender, "M") == 0) ? 299 : 12); // Skin 299 se homem, 12 se mulher
        DOF2_SetInt(path, "Level", 1);
        DOF2_SetInt(path, "Dinheiro", 5000);
        
        DOF2_SaveFile();

        SCM(playerid, -1, "{2ecc71}[SkyPixel]:{ffffff} Conta criada com sucesso!");
        SCM(playerid, -1, "{ffffff}Agora, faça o login para entrar.");
        
        // No Mobile, o script.js já faz o toggleForm('log') automaticamente após o registro.
    }
    return 1;
}
forward ShowMobileHUD(playerid);
public ShowMobileHUD(playerid)
{
    if(Geckoju_IsMobileClient(playerid))
    {
        // 1. Esconde TextDraws do servidor (Padrão SAMP)
        for(new i = 0; i < 20; i++) TextDrawHideForPlayer(playerid, Text:i); 
        
        // 2. CRIA O NAVEGADOR PRIMEIRO! (Isso é essencial)
        // Parâmetros: ID, X=-2 (Dir), Y=-2 (Baixo), W=350, H=200, URL, Visible=true, Alpha=0 (Transparente), ExitBtn=false
        Geckoju_CreateBrowser(
        playerid, 
        HUD_BROWSER_ID, 
        10,                   // X: 10 pixels da borda esquerda (quase colado)
        GECKOJU_POS_END,      // Y: No final da tela (embaixo)
        280,                  // Largura: Reduzida para ser o mais fino possível
        70,                   // Altura: Baixinha para não subir no analógico
        "https://dieguin609.github.io/hudskymob/index.html?v=777", 
        true,  
        false
    );


        // 3. Tira a interatividade (Permite clicar no jogo)
        Geckoju_SetInteractive(playerid, HUD_BROWSER_ID, false);

    // ---------------------------------------------------------
        // PARTE DE CIMA (index2.html) - Canto Superior Direito
        // ---------------------------------------------------------
        Geckoju_CreateBrowser(
            playerid, 
            HUD_BROWSER_ID2, 
            GECKOJU_POS_END,        // X: Alinhado à direita
            5,                      // Y: 5 pixels do topo (bem alto)
            300,                    // Largura reduzida (Slim)
            210,                    // Altura reduzida (Slim)
            "https://dieguin609.github.io/hudskymob/index2.html?v=777", 
            true,  
            false
        );
        Geckoju_SetInteractive(playerid, HUD_BROWSER_ID2, false); // Bloqueia toque

        // ---------------------------------------------------------
        // NOVO: RADAR REDONDO 3D (index3.html ou radar.html)
        // ---------------------------------------------------------
        // ---------------------------------------------------------
        // RADAR REDONDO 3D - CANTO SUPERIOR ESQUERDO
        // ---------------------------------------------------------
        Geckoju_CreateBrowser(
            playerid, 
            HUD_BROWSER_ID3, 
            5,               // X: 15 pixels da borda esquerda
            4,               // Y: 10 pixels do topo (Aqui ele sobe para a parte de cima!)
            280,              // Largura
            250,              // Altura
            "https://dieguin609.github.io/hudskymob/radar.html?v=777", 
            true,  
            false
        );
        Geckoju_SetInteractive(playerid, HUD_BROWSER_ID3, true); // Habilita toque para o radar (para clicar e abrir o GPS)

        SCM(playerid, -1, "{2ecc71}[SkyPixel]: {ffffff}HUD Mobile carregada!");
    }
    return 1;
}
// Função para atualizar a linha roxa do GPS
stock AtualizarRotaGPS(playerid, lista_de_pontos[])
{
    // Limpa a string antiga
    String_RotaGPS[playerid][0] = '\0';
    
    // Copia a nova lista de pontos (Ex: "120,500|130,510|...")
    format(String_RotaGPS[playerid], 1024, "%s", lista_de_pontos);
}

// Função para limpar o GPS (quando chegar ou cancelar)
stock LimparGPS(playerid)
{
    String_RotaGPS[playerid][0] = '\0';
}
// Esta função inicia o cálculo
stock TracarRotaGPS(playerid, Float:dest_x, Float:dest_y, Float:dest_z)
{
    new MapNode:noInicial, MapNode:noFinal;
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz); // Pega a posição real agora

    // O segredo: GetClosestMapNodeToPoint procura a rua mais próxima de você
    if(GetClosestMapNodeToPoint(px, py, pz, noInicial) != 0) {
        return SCM(playerid, -1, "{FF0000}[GPS] Erro: Você está muito longe de uma estrada!");
    }
    
    if(GetClosestMapNodeToPoint(dest_x, dest_y, dest_z, noFinal) != 0) {
        return SCM(playerid, -1, "{FF0000}[GPS] Erro: Destino fora do mapa de ruas!");
    }

    FindPathThreaded(noInicial, noFinal, "OnRotaCalculada", "i", playerid);
    return 1;
}

// Esta função é chamada quando o Plugin termina de calcular
// Foco 100% no GPS - Sem mexer em mais nada
// Se não tiver definido no topo, defina o tamanho do buffer
#define MAX_JSON_BUFFER 1024 

forward OnRotaCalculada(playerid, Path:pathid);
public OnRotaCalculada(playerid, Path:pathid)
{
    if(!IsValidPath(pathid)) {
        SendClientMessage(playerid, -1, "{FF0000}[GPS] Erro: Caminho não encontrado.");
        return 1;
    }

    new node_count;
    GetPathSize(pathid, node_count);

    if(node_count > 0)
    {
        // Buffer seguro para o pacote JSON
        new json_chunk[MAX_JSON_BUFFER];
        new node_str[64];
        
        // 1. LIMPEZA
        // Manda o comando de limpar para o ID 4 (Radar) e ID 5 (Mapa)
        Geckoju_SendData(playerid, HUD_BROWSER_ID3, "{\"gps_off\":true}");
        Geckoju_SendData(playerid, 5, "{\"gps_off\":true}");

        // Prepara o início do JSON
        format(json_chunk, sizeof(json_chunk), "{\"string_rota\":\""); 

        for(new i = 0; i < node_count; i++)
        {
            new MapNode:nodeid, Float:nx, Float:ny, Float:nz;
            GetPathNode(pathid, i, nodeid);
            GetMapNodePos(nodeid, nx, ny, nz);

            // Formata: "X,Y|"
            format(node_str, sizeof(node_str), "%.1f,%.1f|", nx, ny);
            
            // 2. VERIFICAÇÃO DE TAMANHO (BUFFER CHECK)
            // Se o texto estiver ficando muito grande (perto de 1000 letras), envia o que tem e limpa.
            if((strlen(json_chunk) + strlen(node_str)) > (MAX_JSON_BUFFER - 10))
            {
                // Fecha o JSON
                strcat(json_chunk, "\"}");
                
                // ENVIA PARA OS IDs CORRETOS (4 e 5)
                Geckoju_SendData(playerid, HUD_BROWSER_ID3, json_chunk); // Radar (ID 4)
                Geckoju_SendData(playerid, 5, json_chunk);               // Mapa Global (ID 5)

                // Reinicia o buffer com o mesmo cabeçalho para continuar mandando
                format(json_chunk, sizeof(json_chunk), "{\"string_rota\":\"");
            }
            
            // Adiciona o ponto atual na lista
            strcat(json_chunk, node_str);
        }

        // 3. ENVIO FINAL
        // Manda o restinho que sobrou no buffer
        strcat(json_chunk, "\"}");
        Geckoju_SendData(playerid, HUD_BROWSER_ID3, json_chunk);
        Geckoju_SendData(playerid, 5, json_chunk);

        SendClientMessage(playerid, -1, "{00FF00}[GPS] Rota enviada para o Radar!");
    }
    
    DestroyPath(pathid);
    return 1;
}
forward RecalcularRota(playerid);
public RecalcularRota(playerid)
{
    if(!IsPlayerConnected(playerid) || !GPS_Ativo[playerid]) 
    {
        KillTimer(TimerGPS[playerid]);
        TimerGPS[playerid] = 0;
        return;
    }

    if(IsPlayerInRangeOfPoint(playerid, 15.0, GPS_DestX[playerid], GPS_DestY[playerid], GPS_DestZ[playerid]))
    {
        // Chegou no destino!
        SendClientMessage(playerid, -1, "{2ecc71}[GPS] {ffffff}Você chegou ao seu destino!");
        DisablePlayerCheckpoint(playerid);
        
        // Limpa a rota no mapa
        GPS_Ativo[playerid] = false;
        String_RotaGPS[playerid][0] = '\0';
        
        // Manda comando pra apagar visualmente
        Geckoju_SendData(playerid, MAPA_BROWSER_ID, "{\"gps_off\":true}");
        Geckoju_SendData(playerid, HUD_BROWSER_ID3, "{\"gps_off\":true}");
        
        KillTimer(TimerGPS[playerid]);
        TimerGPS[playerid] = 0;
        return;
    }

    // Se ainda não chegou, calcula de novo DA POSIÇÃO ATUAL
    TracarRotaGPS(playerid, GPS_DestX[playerid], GPS_DestY[playerid], GPS_DestZ[playerid]);
}

