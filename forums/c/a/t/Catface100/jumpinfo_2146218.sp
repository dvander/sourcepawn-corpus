#pragma semicolon 1
#include <sourcemod>

// CVars
new Handle:g_cvarClass = INVALID_HANDLE;
new Handle:g_cvarEnable = INVALID_HANDLE;

// Setting Plugin Info
public Plugin:myinfo =
{
	name = "Jump Info",
	author = "Catface",
	description = "Tells user on join what the map is intended for",
	version = "1.0",
	url = "http://steamcommunity.com/groups/CatfaceJumping"
};

// Creating class cvar
public OnPluginStart() {
	g_cvarClass = CreateConVar("sm_jumpinfo_class", "1", "Displays which class - 1 Soldier, 2 Demo, 3 Either", FCVAR_PLUGIN);
	g_cvarEnable = CreateConVar("sm_jumpinfo_enable", "1", "Enables or disables the plugin", FCVAR_PLUGIN);
}

// Begins timer until message is printed once the client is in game
public OnClientPutInServer(client) {
	if (GetConVarBool(g_cvarEnable))
		CreateTimer(30.0, Timer_JoinMessage, GetClientUserId(client));
}

// Determines what to print to client based on cvar
public Action:Timer_JoinMessage(Handle:timer, any:client) {
	if (IsClientInGame(client) && !IsFakeClient(client))
		if (GetConVarInt(g_cvarClass) == 1)
		{
			PrintToChat(client, "\x01[SM] This map is intended for \x04soldier");
		}
		else if (GetConVarInt(g_cvarClass) == 2)
		{
			PrintToChat(client, "\x01[SM] This map is intended for \x04demoman");
		}
		else if (GetConVarInt(g_cvarClass) == 3)
		{
			PrintToChat(client, "\x01[SM] This map is intended for \x04soldier \x01or \x04demoman");
		}
}