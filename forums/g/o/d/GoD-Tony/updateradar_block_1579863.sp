#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_NAME 	"UpdateRadar Block"
#define PLUGIN_VERSION 	"block"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Blocks UpdateRadar console spam on large servers",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_updateradar_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookUserMessage(GetUserMessageId("UpdateRadar"), Hook_UpdateRadar, true);
}

public Action:Hook_UpdateRadar(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (BfGetNumBytesLeft(bf) > 253)
	{
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}
