#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION   "1.0"

#define HIDE (0x0001 | 0x0010)
#define SHOW (0x0002)

new Handle:g_fadeToBlackEna = INVALID_HANDLE;
new Handle:g_fadeToBlack;

public Plugin:myinfo = {
    name = "mp_fadetoblack",
    author = "iDragon",
    description = "mp_fadetoblack fix",
    version = PLUGIN_VERSION,
    url = "http://www.pro-css.co.il/"
};

public OnPluginStart() {

	g_fadeToBlackEna = CreateConVar("sm_fadeToBlack_enabled", "1", "Enable mp_fadetoblack?");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	g_fadeToBlack = FindConVar("mp_fadetoblack");
	HookConVarChange(g_fadeToBlack, fadeToBlackConVar);
	
	PrintToChatAll("\x04mp_fadetoblack Fix\x03 Loaded.");
}

public OnPluginEnd()
{
	for (new i = 1; i <= GetMaxClients(); i++ )
		UnBlindClient(i);
	PrintToChatAll("\x04mp_fadetoblack Fix\x03 Un-Loaded.");
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_fadeToBlackEna))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		new team = GetClientTeam(client);
		if (team == 3)
			BlindClient(client);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new team = GetClientTeam(client);
	if (team == 3)
		UnBlindClient(client);
}

public fadeToBlackConVar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal))
		PrintToChatAll("\x04mp_fadetoblack Fix\x03 Enabled.");
	else
	{
		PrintToChatAll("\x04mp_fadetoblack Fix\x03 Dissabled.");
		for (new i = 1; i <= GetMaxClients(); i++ )
			UnBlindClient(i);
	}
}

public BlindClient(client)
{
	new Handle:msg;
		
	msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, 50);
	BfWriteShort(msg, 0); // Duration
	BfWriteShort(msg, SHOW);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 255);
	EndMessage();
}

public UnBlindClient(client)
{
	new Handle:msg;
		
	msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, 100);
	BfWriteShort(msg, 0); // Duration
	BfWriteShort(msg, HIDE);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 255);
	EndMessage();
}