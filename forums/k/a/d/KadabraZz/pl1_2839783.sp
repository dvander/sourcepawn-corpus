#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo =
{
    name = "Ataque Forçado (Comando Único)",
    author = "Malibu",
    description = "Envia uma única ordem de ataque aos bots.",
    version = "15.0",
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_bots_atacar_alvo", Command_StartAttack, ADMFLAG_ROOT, "Dá uma ordem única para os bots atacarem quem digitou o comando.");
    RegAdminCmd("sm_bots_parar_ataque", Command_StopAttack, ADMFLAG_ROOT, "Envia uma ordem para os bots pararem os comandos especiais.");
}

// --- Comando para INICIAR o ataque ---
public Action Command_StartAttack(int client, int args)
{
    // Verifica se quem digitou o comando é um alvo válido
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        PrintToChat(client, "Você precisa de estar vivo no jogo para ser um alvo.");
        return Plugin_Handled;
    }

    char sName[MAX_TARGET_LENGTH];
    GetClientName(client, sName, sizeof(sName));
    PrintToChatAll("\x04[Ordem de Ataque]\x01 Bots receberam ordem para atacar \x05%s\x01.", sName);

    // Loop por todos os bots
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
        {
            // Envia a ordem de ataque única
            L4D2_CommandABot(i, client, BOT_CMD_ATTACK);
        }
    }
    
    return Plugin_Handled;
}

// --- Comando para PARAR o ataque ---
public Action Command_StopAttack(int client, int args)
{
    PrintToChatAll("\x04[Ordem de Ataque]\x01 Enviando ordem para cancelar ataques forçados.");

    // Loop por todos os bots
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i))
        {
            // Envia a ordem de reset
            L4D2_CommandABot(i, -1, BOT_CMD_RESET);
        }
    }

    return Plugin_Handled;
}