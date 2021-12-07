// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <tf2attributes>

// ---- Defines ----------------------------------------------------------------
#define NFD_VERSION "0.1.0"

// ---- Plugin's Information ---------------------------------------------------
public Plugin:myinfo =
{
	name	= "[TF2] No Fall Damage",
	author	= "Classic",
	description	= "Disables the fall damage",
	version	= NFD_VERSION,
	url	= "http://www.clangs.com.ar"
};

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client))
	{
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	}
}