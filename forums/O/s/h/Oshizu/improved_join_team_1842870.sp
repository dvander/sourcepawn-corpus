#pragma semicolon 1 

// ====[ INCLUDES ]============================================================ 
#include <sourcemod> 
#include <morecolors> 

// ====[ DEFINES ]============================================================= 
#define PLUGIN_VERSION "1.3.0.2" 

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
    name = "[Any] Improved Join Team Messages", 
    author = "Oshizu and ReFlexPoison (Helped many times with plugin)", 
    description = "Improves messages that appear when player joins team", 
    version = PLUGIN_VERSION, 
    url = "http://www.sourcemod.net", 
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

    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre); 

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
                    case 0: CPrintToChatAll("Player {gray}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {gray}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {gray}%N{default} joined team {red}RED", iClient); 
                    case 3: CPrintToChatAll("Player {gray}%N{default} joined team {blue}BLU", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {red}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {red}%N{default} joined team {gray}Spectators", iClient);
                    case 2: CPrintToChatAll("Player {red}%N{default} joined team {red}RED", iClient); 
                    case 3: CPrintToChatAll("Player {red}%N{default} joined team {blue}BLU", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {blue}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {blue}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {blue}%N{default} joined team {red}RED", iClient); 
                    case 3: CPrintToChatAll("Player {blue}%N{default} joined team {blue}BLU", iClient); 
                } 
            } 
        } 
    } 
    //Counter-Strike 
    //2 = Terrorists (Red) 
    //3 = Counter-Terrorists (Blue) 
    else if(StrEqual(g_strGame, "cstrike")) 
    { 
        switch(iOldTeam) 
        { 
            case 0, 1: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {gray}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {gray}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {gray}%N{default} joined team {red}Terrorists", iClient); 
                    case 3: CPrintToChatAll("Player {gray}%N{default} joined team {blue}Counter-Terrorists", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {red}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {red}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {red}%N{default} joined team {red}Terrorists", iClient); 
                    case 3: CPrintToChatAll("Player {red}%N{default} joined team {blue}Counter-Terrorists", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {blue}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {blue}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {blue}%N{default} joined team {red}Terrorists", iClient); 
                    case 3: CPrintToChatAll("Player {blue}%N{default} joined team {blue}Counter-Terrorists", iClient); 
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
                    case 0: CPrintToChatAll("Player {gray}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {gray}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {gray}%N{default} joined team {allies}Allies", iClient); 
                    case 3: CPrintToChatAll("Player {gray}%N{default} joined team {axis}Axis", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {blue}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {blue}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {blue}%N{default} joined team {allies}Allies", iClient); 
                    case 3: CPrintToChatAll("Player {blue}%N{default} joined team {axis}Axis", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {red}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {red}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {red}%N{default} joined team {blue}Allies", iClient); 
                    case 3: CPrintToChatAll("Player {red}%N{default} joined team {red}Axis", iClient); 
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
                    case 0: CPrintToChatAll("Player {gray}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {gray}%N{default} joined team {gray}Spectators", iClient);
                    case 2: CPrintToChatAll("Player {gray}%N{default} joined team {blue}Combine", iClient); 
                    case 3: CPrintToChatAll("Player {gray}%N{default} joined team {red}Rebels", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {red}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {red}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {red}%N{default} joined team {blue}Combine", iClient); 
                    case 3: CPrintToChatAll("Player {red}%N{default} joined team {red}Rebels", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {blue}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {blue}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {blue}%N{default} joined team {blue}Combine", iClient); 
                    case 3: CPrintToChatAll("Player {blue}%N{default} joined team {red}Rebels", iClient); 
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
                    case 0: CPrintToChatAll("Player {gray}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {gray}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {gray}%N{default} joined team {blue}Survivors", iClient); 
                    case 3: CPrintToChatAll("Player {gray}%N{default} joined team {red}Infected", iClient); 
                } 
            } 
            case 2: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {blue}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {blue}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {blue}%N{default} joined team {blue}Survivors", iClient); 
                    case 3: CPrintToChatAll("Player {blue}%N{default} joined team {red}Infected", iClient); 
                } 
            } 
            case 3: 
            { 
                switch(iNewTeam) 
                { 
                    case 0: CPrintToChatAll("Player {red}%N joined team {gray}Unassigned", iClient); 
                    case 1: CPrintToChatAll("Player {red}%N{default} joined team {gray}Spectators", iClient); 
                    case 2: CPrintToChatAll("Player {red}%N{default} joined team {blue}Survivors", iClient); 
                    case 3: CPrintToChatAll("Player {red}%N{default} joined team {red}Infected", iClient); 
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
