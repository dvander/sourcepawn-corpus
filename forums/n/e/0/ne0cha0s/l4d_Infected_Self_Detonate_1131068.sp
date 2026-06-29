#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "0.9"
#define TEAM_INFECTED 3
#define ZOMBIECLASS_COUNT 9

// Global variables
new Handle:g_hConVar_DisplayDetonationOn;
new Handle:g_hConVar_DetonateButton;
// Ignore index 0 and 7
new Handle:g_hConVar_DetonateOn[ZOMBIECLASS_COUNT];

// Plugin info
public Plugin:myinfo =
{
    name = "Infected Self Detonation",
    author = "ne0cha0s",
    description = "Allows an infected player to detonate themselves by pressing a specified button (currently supports all infected classes)",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=1131068"
};

// Plugin start
public OnPluginStart()
{
    // Requires that plugin will only work on Left 4 Dead or Left 4 Dead 2
    decl String:game_name[64];
    GetGameFolderName(game_name, sizeof(game_name));
    
    if (StrContains(game_name, "left4dead") == -1) SetFailState("This plugin will only work on Left 4 Dead or Left 4 Dead 2.");
    
    // Cvars
    g_hConVar_DetonateOn[1] = CreateConVar("l4d_smoker_detonate_on", "0", "Smoker detonate is enabled or disabled. 1 = enabled", CVAR_FLAGS);
    g_hConVar_DetonateOn[2] = CreateConVar("l4d_boomer_detonate_on", "1", "Boomer detonate is enabled or disabled. 1 = enabled", CVAR_FLAGS);
    g_hConVar_DetonateOn[3] = CreateConVar("l4d_hunter_detonate_on", "0", "Hunter detonate is enabled or disabled. 1 = enabled", CVAR_FLAGS);
    g_hConVar_DetonateOn[4] = CreateConVar("l4d2_spitter_detonate_on", "1", "Spitter detonate enabled or disabled. 1 = enabled", CVAR_FLAGS);
    g_hConVar_DetonateOn[5] = CreateConVar("l4d2_jockey_detonate_on", "0", "Jockey detonate is enabled or disabled. 1 = enabled", CVAR_FLAGS);
    g_hConVar_DetonateOn[6] = CreateConVar("l4d2_charger_detonate_on", "0", "Charger detonate is enabled or disabled. 1 = enabled", CVAR_FLAGS);
    g_hConVar_DetonateOn[8] = CreateConVar("l4d2_tank_detonate_on", "0", "Tank detonate is enabled or disabled. 1 = enabled", CVAR_FLAGS);
    
    g_hConVar_DisplayDetonationOn = CreateConVar("l4d_display_detonation", "0", "Displaying a player's detonation is enabled or disabled. 1 = enabled", CVAR_FLAGS);
	g_hConVar_DetonateButton = CreateConVar("l4d_detonate_button", "1", "Specifies infected self-detonation button. 0 = no self-detonation, 1 = ZOOM, 2 = RELOAD, 3 = MELEE", CVAR_FLAGS);
	
    CreateConVar("l4d_infected_self_detonate_version", PLUGIN_VERSION, " Infected Self Detonate Version ", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
    
    AutoExecConfig(true, "l4d_infected_self_detonate");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    // Is client human, ingame, infected, alive, not a ghost and pressing the button?
    if (client == 0) return Plugin_Continue;
    if (!IsClientInGame(client)) return Plugin_Continue;
    if (IsFakeClient(client)) return Plugin_Continue;
    if (GetClientTeam(client) != TEAM_INFECTED) return Plugin_Continue;
    if (!IsPlayerAlive(client)) return Plugin_Continue;
    if (GetEntProp(client, Prop_Send, "m_isGhost") != 0) return Plugin_Continue;
    // Get Zombieclass
    new zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    // This class enabled?
    if (!GetConVarBool(g_hConVar_DetonateOn[zombieClass])) return Plugin_Continue;
    // Get detonation button
	if (GetConVarInt(g_hConVar_DetonateButton) == 1)
	{
		if (!(buttons & IN_ZOOM)) return Plugin_Continue;
	    // Self detonation
		SetEntityHealth(client, 1);
		IgniteEntity(client, 2.0);
        // Message enabled?
		if (GetConVarBool(g_hConVar_DisplayDetonationOn)) PrintToChatAll("%N self-detonated!", client);
	}
	else if (GetConVarInt(g_hConVar_DetonateButton) == 2)
	{
		if (!(buttons & IN_RELOAD)) return Plugin_Continue;
	    // Self detonation
		SetEntityHealth(client, 1);
		IgniteEntity(client, 2.0);
        // Message enabled?
		if (GetConVarBool(g_hConVar_DisplayDetonationOn)) PrintToChatAll("%N self-detonated!", client);
    }
	else if (GetConVarInt(g_hConVar_DetonateButton) == 3)
	{
		if (!(buttons & IN_ATTACK2)) return Plugin_Continue;
	    // Self detonation
		SetEntityHealth(client, 1);
		IgniteEntity(client, 2.0);
        // Message enabled?
		if (GetConVarBool(g_hConVar_DisplayDetonationOn)) PrintToChatAll("%N self-detonated!", client);
	}
	else
	return Plugin_Continue;
	
	return Plugin_Continue;
}
