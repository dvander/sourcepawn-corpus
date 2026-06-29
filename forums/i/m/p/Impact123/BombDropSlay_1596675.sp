#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo = 
{
	name = "Drop Bomb Slay",
	author = "TnTSCS & Impact",
	description = "Slays a player if they drop the bomb while alive",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_dropbombslay_version", PLUGIN_VERSION, "Drop Bomb Slay Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("bomb_dropped", OnBombDropped);
	LoadTranslations("BombDropSlay.phrases");
}

public OnBombDropped(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientHealth(client) > 0)
	{
		/* Choose you defined method...
		   ForcePlayerSuicide(client);
		   FakeClientCommand(client, "kill");
		*/
		SlapPlayer(client, 100, false);
		PrintToChat(client, "%t", "Player_Slayed");
	}
}
