#include <sourcemod>
#include <sdktools>

new Handle:Damage[MAXPLAYERS+1] = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Show Attacker",
	author = "Jonny",
	description = "",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return Plugin_Continue;

	if (client == target)
		return Plugin_Continue;

	decl String:ClientSteamID[16];
	decl String:TargetSteamID[16];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");
	PrintToChatAll("\x01%N [\x05%d\x01] attacked %N", client, Damage[client], target);

	return Plugin_Continue;
}

public Action:Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return Plugin_Continue;
	if (client == target)
		return Plugin_Continue;

	decl String:ClientSteamID[16];
	decl String:TargetSteamID[16];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");
	PrintToChatAll("\x04%N [\x05%d\x04] attacked %N", client, Damage[client], target);

	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		Damage[client] = 0;
	}
}

//public OnClientDisconnect(client)
//{
//	if (!IsFakeClient(client))
//	{
//		Damage[client] = 0;
//	}
//}
