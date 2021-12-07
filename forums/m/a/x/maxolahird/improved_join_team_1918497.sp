#pragma semicolon 1 

// ====[ INCLUDES ]============================================================ 
#include <sourcemod> 
#include <morecolors> 

// ====[ DEFINES ]============================================================= 
#define PLUGIN_VERSION "1" 

// ====[ HANDLES | CVARS ]===================================================== 
new Handle:cvarEnabled; 
new Handle:cvarBots; 
new Handle:cvarTeamplay; 

// ====[ VARIABLES ]=========================================================== 
new bool:g_bEnabled; 
new bool:g_bBots; 
new bool:g_bTeamplay; 
new String:g_strGame[12]; 

// ====[ PLUGIN ]============================================================== 
public Plugin:myinfo = 
{ 
    name = "MSG Troca de Time Sirr John", 
    author = "Sirr John", 
    description = "Melhora mensagem que aparece ao mudar de time.", 
    version = PLUGIN_VERSION, 
    url = "http://forum.impactcss.com", 
} 

// ====[ FUNCTIONS ]=========================================================== 
public OnPluginStart() 
{ 
    CreateConVar("sm_jointeam_version", PLUGIN_VERSION, "Improved Join Team Messages Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY); 

    cvarEnabled = CreateConVar("sm_jointeam_enabled", "1", "Enable Improved Join Team Messages\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0); 
    cvarBots = CreateConVar("sm_jointeam_bots", "0", "Enable notifications of bot team changes\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0); 
    cvarTeamplay = FindConVar("mp_teamplay"); 

    g_bEnabled = GetConVarBool(cvarEnabled); 
    g_bBots = GetConVarBool(cvarBots); 
    g_bTeamplay = GetConVarBool(cvarTeamplay); 

    AutoExecConfig(true, "plugin.improvedjoinmessages"); 

    HookConVarChange(cvarEnabled, CVarChange); 
    HookConVarChange(cvarBots, CVarChange); 
    HookConVarChange(cvarTeamplay, CVarChange); 

    HookEvent("Jogador_team", Event_PlayerTeam, EventHookMode_Pre); 

    GetGameFolderName(g_strGame, sizeof(g_strGame)); 
} 

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[]) 
{ 
    if(hConvar == cvarEnabled) 
        g_bEnabled = GetConVarBool(cvarEnabled); 
    if(hConvar == cvarBots) 
        g_bBots = GetConVarBool(cvarBots); 
    if(hConvar == cvarTeamplay) 
        g_bTeamplay = GetConVarBool(cvarTeamplay); 
} 

public Action:Event_PlayerTeam(Handle:hEvent, const String:strName[], bool:bDontBroadcast) 
{ 
    if(!g_bEnabled) 
        return Plugin_Continue; 

    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
    if(!IsValidClient(iClient)) 
        return Plugin_Continue; 

    if(!g_bBots && IsFakeClient(iClient)) 
        return Plugin_Continue; 

    new iOldTeam = GetEventInt(hEvent, "oldteam"); 
    new iNewTeam = GetEventInt(hEvent, "team"); 

    SetEventBroadcast(hEvent, true); 

    //Team Fortress 2 
    //2 = RED (Red) 
    //3 = BLU (Blue) 
    if(StrEqual(g_strGame, "tf")) 
    { 
        switch(iOldTeam) 
        { 
            case 0, 1: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {gray}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {red}RED", iClient); 
                    case 3: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {blue}BLU", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {red}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {red}%N{default} entrou no time {gray}Espectadores", iClient);
                    case 2: CPrintToChatAll("Jogador {red}%N{default} entrou no time {red}RED", iClient); 
                    case 3: CPrintToChatAll("Jogador {red}%N{default} entrou no time {blue}BLU", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {blue}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {red}RED", iClient); 
                    case 3: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {blue}BLU", iClient); 
                } 
            } 
        } 
    } 
    //Counter-Strike 
    //2 = Terroristas (Red) 
    //3 = Contra-Terroristas (Blue) 
    else if(StrEqual(g_strGame, "cstrike")) 
    { 
        switch(iOldTeam) 
        { 
            case 0, 1: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {gray}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {red}Terroristas", iClient); 
                    case 3: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {blue}Contra-Terroristas", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {red}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {red}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {red}%N{default} entrou no time {red}Terroristas", iClient); 
                    case 3: CPrintToChatAll("Jogador {red}%N{default} entrou no time {blue}Contra-Terroristas", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {blue}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {red}Terroristas", iClient); 
                    case 3: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {blue}Contra-Terroristas", iClient); 
                } 
            } 
        } 
    } 
    //Day of Defeat: Source 
    //2 = Allies (Blue) 
    //3 = Axis (Red) 
    else if(StrEqual(g_strGame, "dod")) 
    { 
        switch(iOldTeam) 
        { 
            case 0, 1: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {gray}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {allies}Allies", iClient); 
                    case 3: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {axis}Axis", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {blue}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {allies}Allies", iClient); 
                    case 3: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {axis}Axis", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {red}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {red}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {red}%N{default} entrou no time {blue}Allies", iClient); 
                    case 3: CPrintToChatAll("Jogador {red}%N{default} entrou no time {red}Axis", iClient); 
                } 
            } 
        } 
    } 
    //Half-Life 2: Deathmatch 
    //2 = Rebels (Blue) 
    //3 = Combine (Red) 
    else if(StrEqual(g_strGame, "hl2mp") && g_bTeamplay) 
    { 
        switch(iOldTeam) 
        { 
            case 0, 1: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {gray}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {red}Rebels", iClient); 
                    case 3: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {blue}Combine", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {red}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {red}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {red}%N{default} entrou no time {red}Rebels", iClient); 
                    case 3: CPrintToChatAll("Jogador {red}%N{default} entrou no time {blue}Combine", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {blue}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {red}Rebels", iClient); 
                    case 3: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {blue}Combine", iClient); 
                } 
            } 
        } 
    } 
    //Left 4 Dead 
    //2 = Survivors (Blue) 
    //3 = Infected (Red) 
    else if(StrEqual(g_strGame, "left4dead")) 
    { 
        switch(iOldTeam) 
        { 
            case 0, 1: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {gray}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {blue}Sobreviventes", iClient); 
                    case 3: CPrintToChatAll("Jogador {gray}%N{default} entrou no time {red}Infectados", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {blue}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {blue}Sobreviventes", iClient); 
                    case 3: CPrintToChatAll("Jogador {blue}%N{default} entrou no time {red}Infectados", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Jogador {red}%N entrou no time {gray}Indefinido", iClient); 
                    case 1: CPrintToChatAll("Jogador {red}%N{default} entrou no time {gray}Espectadores", iClient); 
                    case 2: CPrintToChatAll("Jogador {red}%N{default} entrou no time {blue}Sobreviventes", iClient); 
                    case 3: CPrintToChatAll("Jogador {red}%N{default} entrou no time {red}Infectados", iClient); 
                } 
            } 
        } 
    } 
    return Plugin_Continue; 
} 

// ====[ STOCKS ]============================================================== 
stock bool:IsValidClient(iClient, bool:bReplay = true) 
{ 
    if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) 
        return false; 
    if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient))) 
        return false; 
    return true; 
}  
