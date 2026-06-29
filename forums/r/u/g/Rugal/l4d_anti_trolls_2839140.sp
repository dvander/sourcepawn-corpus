#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define L4D2_TEAM_NONE      0
#define L4D2_TEAM_SPECTATOR 1
#define L4D2_TEAM_SURVIVOR  2
#define L4D2_TEAM_INFECTED  3

// Sourcebans++ Native.
native Function SBPP_BanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason);

ConVar g_cvPluginEnabled;
ConVar g_cvBanUsingSourcebans;
ConVar g_cvBanTimeMinutes;
ConVar g_cvTrollTimeWindow;

bool g_bSourcebansAvailable = false;

int g_iLastInfectedAttacker[MAXPLAYERS + 1];
float g_fLastInfectedDamage[MAXPLAYERS + 1];
float g_fPlayerTakeoverTime[MAXPLAYERS + 1];

bool g_bPlayerWaitingForRecovery[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "L4D(2) - Anti Trolls",
	author = "Ferks-FK",
	description = "Kick or ban trolls who try to sabotage the game",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
    HookEvent("bot_player_replace", Event_PlayerTakesBot, EventHookMode_Post);
    HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Post);

    HookEvent("revive_success", Event_PlayerRevived, EventHookMode_Post);
    HookEvent("player_ledge_release", Event_PlayerReleasedLedge, EventHookMode_Post);

    HookEvent("pounce_end", Event_PlayerUnpinned, EventHookMode_Post);
    HookEvent("tongue_release", Event_PlayerUnpinned, EventHookMode_Post);
    HookEvent("charger_pummel_end", Event_PlayerUnpinned, EventHookMode_Post);
    HookEvent("jockey_ride_end", Event_PlayerUnpinned, EventHookMode_Post);
    
    g_cvPluginEnabled = CreateConVar("l4d_anti_trolls_enabled", "1", "Enable or disable the anti-trolls plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
    g_cvBanUsingSourcebans = CreateConVar("l4d_anti_trolls_use_sourcebans", "0", "Use SourceBans to ban players (if available)", FCVAR_NOTIFY|FCVAR_SPONLY);
    g_cvBanTimeMinutes = CreateConVar("l4d_anti_trolls_ban_time", "3600", "Time (in minutes) to ban a player for anti-troll actions. 0 = Permanent.", FCVAR_NOTIFY|FCVAR_SPONLY);
    g_cvTrollTimeWindow = CreateConVar("l4d_anti_trolls_troll_time_window", "60", "Time window (in seconds) to track player takeover of bots.", FCVAR_NOTIFY|FCVAR_SPONLY);

    AutoExecConfig(true, "l4d_anti_trolls");
}

public void OnAllPluginsLoaded()
{
    CheckSourcebansAvailability();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("SBPP_BanPlayer");
    return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "sourcebans++"))
    {
        g_bSourcebansAvailable = true;
        LogMessage("SourceBans++ detected and available for use.");
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if(StrEqual(name, "sourcebans++"))
    {
        g_bSourcebansAvailable = false;
        LogMessage("SourceBans++ was unloaded, falling back to BaseBans.");
    }
}

public void L4D2_OnEndVersusModeRound_Post()
{
    LogMessage("[DEBUG] Fim do mapa, resetando dados de rastreamento de jogadores sobreviventes.");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != L4D2_TEAM_SURVIVOR)
            continue;

        // Reset player tracking data
        g_fPlayerTakeoverTime[i] = 0.0;
        g_fLastInfectedDamage[i] = 0.0;
        g_iLastInfectedAttacker[i] = 0;
        g_bPlayerWaitingForRecovery[i] = false;
    }
}

void CheckSourcebansAvailability()
{
    g_bSourcebansAvailable = LibraryExists("sourcebans++");
    
    if(g_cvBanUsingSourcebans.BoolValue && !g_bSourcebansAvailable)
    {
        LogMessage("SourceBans++ is not available, using BaseBans instead.");
    }
    else if(g_bSourcebansAvailable)
    {
        LogMessage("SourceBans++ is available for use.");
    }
}

public void Event_PlayerTakesBot(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));
    
    if (player <= 0 || !IsClientInGame(player) || GetClientTeam(player) == L4D2_TEAM_INFECTED || IsFakeClient(player))
        return;
        
    if (bot <= 0 || !IsClientInGame(bot))
        return;

    // Clear old states.
    g_fPlayerTakeoverTime[player] = 0.0;
    g_fLastInfectedDamage[player] = 0.0;
    g_iLastInfectedAttacker[player] = 0;
    g_bPlayerWaitingForRecovery[player] = false;

    // VALIDAÇÕES: Só rastrear se bot estava em condições normais
    
    // 1. Player está morto?
    if (!IsPlayerAlive(player))
    {
        g_bPlayerWaitingForRecovery[player] = true;
        LogMessage("DEBUG: %N assumiu bot MORTO - não rastreando", player);
        return;
    }

    // 2. Player está sendo atacado ou incapacitado?
    if (IsInBadState(player))
    {
        g_bPlayerWaitingForRecovery[player] = true;
        LogMessage("DEBUG: %N assumiu bot sendo ATACADO/INCAPACITADO - não rastreando", player);

        return;
    }
    
    // ✅ Bot estava em condições normais - começar rastreamento
    StartTracking(player);
    
    LogMessage("DEBUG: %N assumiu bot SAUDÁVEL - rastreando por %.0f segundos", 
                   player, g_cvTrollTimeWindow.FloatValue);
}

void Event_PlayerRevived(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("subject"));
    
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
        return;

    // é TRUE quando o jogador assume um BOT que estava incapacitado.
    if (g_bPlayerWaitingForRecovery[client])
    {
        StartTracking(client);
    }

    LogMessage("DEBUG: %N foi REVIVIDO", client);
}

void Event_PlayerReleasedLedge(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
        return;

    if (g_bPlayerWaitingForRecovery[client])
    {
        StartTracking(client);
    }

    LogMessage("DEBUG: %N soltou a ledge", client);
}

void Event_PlayerUnpinned(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));

    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != L4D2_TEAM_SURVIVOR)
        return;
    
    if (g_bPlayerWaitingForRecovery[client])
    {
        StartTracking(client);
    }

    LogMessage("DEBUG: %N está sendo atacado.", client);
}

void PlayerHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
    if (!g_cvPluginEnabled.BoolValue)
        return;

    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    bool attackerIsBot = GetEventBool(event, "attackerisbot");

    char weapon[64], attackerName[64];
    GetEventString(event, "attackername", attackerName, sizeof(attackerName));
    GetEventString(event, "weapon", weapon, sizeof(weapon));

    if (
        victim <= 0 ||
        attacker == 0 ||
        !IsClientInGame(victim) ||
        GetClientTeam(victim) != L4D2_TEAM_SURVIVOR ||
        IsFakeClient(victim) ||
        (ClientIsIncapacitated(victim) && !IsInfectedWeapon(weapon))
    )
    {
        return;
    }

    LoggerToAdmin("=== DANO DEBUG ===");
    LoggerToAdmin("Vítima: %N", victim);
    LoggerToAdmin("Atacante: %N", attacker);
    LoggerToAdmin("Arma: %s", weapon);
    LoggerToAdmin("Attacker Name: %s", attackerName);
    LoggerToAdmin("Atacante é Bot: %s", attackerIsBot ? "Sim" : "Não");
    LoggerToAdmin("=== FIM DANO DEBUG ===");

    float timeSinceLastUpdate = GetGameTime() - g_fLastInfectedDamage[victim];

    if (IsClientInGame(attacker) && GetClientTeam(attacker) == L4D2_TEAM_INFECTED && timeSinceLastUpdate > 1.0)
    {
        g_fLastInfectedDamage[victim] = GetGameTime();
        g_iLastInfectedAttacker[victim] = attacker;

        LoggerToAdmin("Último dano infectado registrado para %N por %N", victim, attacker);
    }
}

void PlayerDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
    if (!g_cvPluginEnabled.BoolValue)
        return;

    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int attackerEntId = GetEventInt(event, "attackerentid");
    bool attackerIsBot = GetEventBool(event, "attackerisbot");
    
    char attackerName[64], weapon[64];
    GetEventString(event, "attackername", attackerName, sizeof(attackerName));
    GetEventString(event, "weapon", weapon, sizeof(weapon));

    // if (victim <= 0 || !IsClientInGame(victim) || IsFakeClient(victim) || GetClientTeam(victim) != L4D2_TEAM_SURVIVOR || !IsInfectedWeapon(weapon))
    //     return;
    
    if (victim <= 0 || !IsClientInGame(victim) || IsFakeClient(victim) || GetClientTeam(victim) != L4D2_TEAM_SURVIVOR)
        return;

    // Debug completo
    LoggerToAdmin("=== MORTE DEBUG ===");
    LoggerToAdmin("Vítima: %N", victim);
    LoggerToAdmin("Attacker ID: %d", attacker);
    LoggerToAdmin("Attacker Ent ID: %d", attackerEntId);
    LoggerToAdmin("Attacker Name: %s", attackerName);
    LoggerToAdmin("Weapon: %s", weapon);
    LoggerToAdmin("Attacker is Bot: %s", attackerIsBot ? "Sim" : "Não");
    LoggerToAdmin("=== FIM MORTE DEBUG ===");

    /*
        CASO 1: O JOGADOR ENTROU, TOMOU CONTROLE DE UM BOT, CORREU E SE JOGOU DO PRECIPÍCIO.
        Dano Recente: SEM DANO.
        Tipo de morte: trigger_hurt
        É um TROLL: SIM.

        CASO 2: O JOGADOR TOMOU ALGUM DANO, DE QUALQUER ORIGEM, E LOGO EM SEGUIDA MORREU.
        Dano Recente: SIM (Exemplo: 2 segundos atrás).
        Tipo de morte: trigger_hurt
        É um TROLL: NÃO, pois o dano foi muito recente.

        CASO 3: O JOGADOR TOMOU ALGUM DANO, DE QUALQUER ORIGEM, E LOGO EM SEGUIDA MORREU.
        Dano Recente: NÃO (Exemplo: 6 segundos atrás).
        Tipo de morte: trigger_hurt
        É um TROLL: SIM, pois o dano não já não é tão recente.

        CASO 4: O JOGADOR TOMOU ALGUM DANO, DE QUALQUER ORIGEM, APÓS 30 SEGUNDOS, ELE MORREU (JOGO PERDIDO, OU VOTAÇÃO PARA PROXIMO MAPA).
        Dano Recente: NÃO (Exemplo: 30 segundos atrás).
        Tipo de morte: trigger_hurt
        É um TROLL: NÃO, pois o último dano registado é muito antigo.

        CASO 5: O JOGADOR ASSUMIU UM BOT QUE ESTAVA INCAPACITADO OU PENDURADO, RECEBENDO DANO APENAS DO MUNDO (infectado comum, ou perda de sangue).
        Dano Recente: SEM DANO.
        Tipo de morte: worldspawn
        É um TROLL: NÃO.
    */

    if (PlayerIsTroll(victim) && IsWorldDamage(weapon))
    {
        LoggerToAdmin("\x04[Anti-Troll]\x01 %N É um TROLL!", victim);
    }
    else
    {
        LoggerToAdmin("\x04[Anti-Troll]\x01 %N NÃO é um TROLL!", victim);
    }

    // ===== VERIFICAÇÃO 1: QUICK TROLLING (Tempo após takeover) =====
    // if (g_fPlayerTakeoverTime[victim] > 0.0)
    // {
    //     float timeSinceTakeover = GetGameTime() - g_fPlayerTakeoverTime[victim];
    //     float timeWindow = g_cvTrollTimeWindow.FloatValue;
        
    //     if (timeSinceTakeover <= timeWindow)
    //     {
    //         PrintToChatAll("⏰ QUICK TROLL: %N morreu %.1fs após assumir/recuperar bot!", victim, timeSinceTakeover);
    //     }
    //     else
    //     {
    //         PrintToChatAll("⏰ NÃO É TROLL: %N morreu %.1fs após assumir/recuperar bot!", victim, timeSinceTakeover);
    //     }
        
    //     // Limpar após usar
    //     g_fPlayerTakeoverTime[victim] = 0.0;
    //     g_bPlayerWaitingForRecovery[victim] = true;
    // }

    // if (GetClientTeam(client) == L4D2_TEAM_SURVIVOR && PlayerIsTroll(client, attacker, weapon))
    // {
    //     // If a survivor kills themselves, we consider it a troll action
    //     if (IsClientInGame(client) && !IsFakeClient(client))
    //     {
    //         if (IsPlayerSabotagingGame(client))
    //         {
    //             PrintToChatAll("\x04[Anti-Troll]\x01 %N foi banido por suicídio trolling!", client);

    //             BanPlayer(client, "Trolling: Suicide to sabotage team");
    //         }
    //     }
    // }
}

stock bool PlayerIsTroll(int client)
{
    // Sofreu dano recente? Calcular...
    if (g_fLastInfectedDamage[client] > 0.0) {
        float timeSinceInfectedDamage = GetGameTime() - g_fLastInfectedDamage[client];

        LoggerToAdmin("\x04[Anti-Troll]\x01 Tempo desde o último dano, evento DEAD: %.2f segundos", timeSinceInfectedDamage);

        // Dano foi causado a 5 segundos ou menos?
        // Não consideramos troll por que pode ter sido causado por um infectado.
        if (timeSinceInfectedDamage <= 5.0 || timeSinceInfectedDamage >= 10.0)
        {
            LoggerToAdmin("\x04[Anti-Troll]\x01 %N não é troll - morreu á (%.2fs atrás)", 
                        client, timeSinceInfectedDamage);

            return false;
        }

        LoggerToAdmin("\x04[Anti-Troll]\x01 %N é um troll - sem dano infectado recente (%.2fs).", 
                client, timeSinceInfectedDamage);

        return true;
    }

    if (!g_bPlayerWaitingForRecovery[client]) {
        LoggerToAdmin("\x04[Anti-Troll]\x01 %N é um troll - sem dano infectado registrado.", client);

        return true;
    }

    return false;
}

stock bool IsWorldDamage(char weapon[64])
{
    return StrEqual(weapon, "worldspawn") || StrEqual(weapon, "world") || StrEqual(weapon, "trigger_hurt");
}

void StartTracking(int client)
{
    g_fPlayerTakeoverTime[client] = GetGameTime();
    g_bPlayerWaitingForRecovery[client] = false;
}

void BanPlayer(int client, const char[] reason)
{
    if(!IsClientInGame(client))
        return;

    int banTime = g_cvBanTimeMinutes.IntValue;
    bool useSourcebans = g_cvBanUsingSourcebans.BoolValue && g_bSourcebansAvailable;
    
    char clientName[64], clientSteamID[32];
    GetClientName(client, clientName, sizeof(clientName));
    GetClientAuthId(client, AuthId_Steam2, clientSteamID, sizeof(clientSteamID));
    
    if(useSourcebans)
    {
        // O primeiro parâmetro é o admin (0 = console), depois target, tempo em minutos, razão
        SBPP_BanPlayer(0, client, banTime, reason);
        
        LogMessage("Player %s (%s) banned via SourceBans for %d minutes. Reason: %s", 
                   clientName, clientSteamID, banTime, reason);
    }
    else
    {
        BanClient(client, banTime, BANFLAG_AUTO, reason, reason, "Anti-Troll System");
        
        LogMessage("Player %s (%s) banned via BaseBans for %d minutes. Reason: %s", 
                   clientName, clientSteamID, banTime, reason);
    }
}

int IsSecondHalfOfRound()
{
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

stock bool IsInfectedWeapon(const char weapon[64])
{
    if (StrEqual(weapon, "boomer_claw") ||
        StrEqual(weapon, "hunter_claw") ||
        StrEqual(weapon, "charger_claw") ||
        StrEqual(weapon, "smoker_claw") ||
        StrEqual(weapon, "spitter_claw") ||
        StrEqual(weapon, "insect_swarm") || // Spitter Primary Attack
        StrEqual(weapon, "jockey_claw") ||
        StrEqual(weapon, "tank_claw") ||
        StrEqual(weapon, "tank_rock") ||
        StrEqual(weapon, "infected"))
    {
        return true;
    }

    return false;
}

stock bool IsInBadState(int client)
{
    // return (ClientIsIncapacitated(client) ||
    //         L4D_GetAttackerCarry(client) != 0 || 
    //         L4D_GetAttackerCharger(client) != 0 || 
    //         L4D_GetAttackerJockey(client) != 0 || 
    //         L4D_GetAttackerSmoker(client) != 0 ||
    //         L4D_GetAttackerHunter(client) != 0);

    return (ClientIsIncapacitated(client) || L4D_GetPinnedSurvivor(client) != 0);
}

stock bool IsPlayerSabotagingGame(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return false;

    

    // Check if the player has been connected long enough
    // if (GetClientTime(client) < GetConVarFloat(g_cvPlayerTimeConnected))
    // {
    //     PrintToChatAll("\x04[Anti-Troll]\x01 %N não foi banido porque não está conectado há tempo suficiente.", client);
    //     return false;
    // }
    // else
    // {
    //     PrintToConsoleAll("\x04[Anti-Troll]\x01 %N foi banido por sabotagem.", client);
    // }

    // bool SurvivorsDeadOrIncapacitated = AllSurvivorsAreDeadOrIncapacitated();

    // if (!SurvivorsDeadOrIncapacitated)
    // {
    //     LogMessage("\x04[Anti-Troll]\x01 %N não foi banido porque ainda há sobreviventes vivos.", client);

    //     return false;
    // }
    // else if (SurvivorsDeadOrIncapacitated && L4D2_IsTankInPlay())
    //     return false;

    return true;
}

stock bool ClientIsIncapacitated(int client)
{
	//return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;

    return L4D_IsPlayerIncapacitated(client) || L4D_IsPlayerHangingFromLedge(client);
}

stock bool AllSurvivorsAreDeadOrIncapacitated()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == L4D2_TEAM_SURVIVOR)
        {
            // Se o jogador está VIVO E NÃO incapacitado = está OK
            if (IsPlayerAlive(i) && !ClientIsIncapacitated(i))
                return false; // Encontrou um sobrevivente OK
        }
    }
    
    return true; // Todos estão mortos ou incapacitados
}

void LoggerToAdmin(const char[] format, any ...)
{
    char buffer[256];
    VFormat(buffer, sizeof(buffer), format, 2);
    
    bool finded = false;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
        {
            PrintToChat(i, buffer);

            finded = true;
            break;
        }
    }

    if (!finded)
        PrintToServer(buffer);
}