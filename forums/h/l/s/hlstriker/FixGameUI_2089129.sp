#include <sourcemod>
#include <sdktools_entoutput>
#include <sdktools_entinput>
#include <sdktools_engine>

#pragma semicolon 1

new const String:PLUGIN_NAME[] = "Fix game_ui entity";
new const String:PLUGIN_VERSION[] = "1.0";

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "hlstriker",
	description = "Fixes the game_ui entity bug.",
	version = PLUGIN_VERSION,
	url = "www.swoobles.com"
}

new g_iAttachedGameUI[MAXPLAYERS+1];


public OnPluginStart()
{
	CreateConVar("fix_gameui_entity_ver", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	HookEntityOutput("game_ui", "PlayerOn", GameUI_PlayerOn);
	HookEntityOutput("game_ui", "PlayerOff", GameUI_PlayerOff);
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	RemoveFromGameUI(iClient);
	SetClientViewEntity(iClient, iClient);
	
	new iFlags = GetEntityFlags(iClient);
	iFlags &= ~FL_ONTRAIN;
	iFlags &= ~FL_FROZEN;
	iFlags &= ~FL_ATCONTROLS;
	SetEntityFlags(iClient, iFlags);
}

public OnClientDisconnect(iClient)
{
	RemoveFromGameUI(iClient);
}

public GameUI_PlayerOn(const String:szOutput[], iCaller, iActivator, Float:fDelay)
{
	if(!(1 <= iActivator <= MaxClients))
		return;
	
	g_iAttachedGameUI[iActivator] = EntIndexToEntRef(iCaller);
}

public GameUI_PlayerOff(const String:szOutput[], iCaller, iActivator, Float:fDelay)
{
	if(!(1 <= iActivator <= MaxClients))
		return;
	
	g_iAttachedGameUI[iActivator] = 0;
}

RemoveFromGameUI(iClient)
{
	if(!g_iAttachedGameUI[iClient])
		return;
	
	new iEnt = EntRefToEntIndex(g_iAttachedGameUI[iClient]);
	if(iEnt == INVALID_ENT_REFERENCE)
		return;
	
	AcceptEntityInput(iEnt, "Deactivate", iClient, iEnt);
}