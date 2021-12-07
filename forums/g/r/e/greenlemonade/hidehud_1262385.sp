#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.2"

new Handle:Enable;
new Handle:Modes;

public Plugin:myinfo = 
{
	name = "[L4D & L4D2] Hud Hider",
	author = "greenlemonade/Edited by McFlurry",
	description = "Removes HUD of players.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	CreateConVar("l4d2_hudhider_version", PLUGIN_VERSION, "Hud Hider version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	Enable = CreateConVar("l4d2_hudhider_enable", "1", "Hud Hider enable?", FCVAR_PLUGIN);
	Modes = CreateConVar("l4d2_hudhider_modes", "realism,teamversus,coop,mutation 8,mutation 12", "Which game modes to enable Hud Hider", FCVAR_PLUGIN);
	AutoExecConfig(true, "hidehud");
}

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(Modes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}	

public OnClientAuthorized(client)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && !IsFakeClient(client))
	{
		CreateTimer(5.0, Enforce, client, TIMER_REPEAT);
	}	
}

public Action:Enforce(Handle:Timer, any:client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && GetConVarInt(Enable) == 1 && IsAllowedGameMode() && IsValidEntity(client))
		SetEntProp(client, Prop_Send, "m_iHideHUD", 64);
	if(IsClientInGame(client) && GetClientTeam(client) == 3)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	if(IsClientInGame(client) && GetClientTeam(client) == 1)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);	
}	