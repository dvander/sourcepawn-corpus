#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new bool:RoundEnd;

// Functions
public Plugin:myinfo =
{
	name = "DeadChat",
	author = "bl4nk",
	description = "Alive players can see the chat of dead players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_deadchat_version", PLUGIN_VERSION, "DeadChat Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_round_start", Event_RoundStart);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
	RoundEnd = true;

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	RoundEnd = false;

public Action:Command_Say(client, args)
{
	if (!GetConVarBool(FindConVar("sv_alltalk")))
		return Plugin_Continue;

	if (!client || IsPlayerAlive(client))
		return Plugin_Continue;

	if (RoundEnd)
		return Plugin_Continue;

	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;

		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}

	if (text[startidx] == '@')
		return Plugin_Continue;

	if (IsChatTrigger() && text[startidx] == '/')
		return Plugin_Handled;

	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
		  SayText2(i, client, text[startidx]);
	}

	return Plugin_Continue;
}

public Action:Command_SayTeam(client, args)
{
	if (!GetConVarBool(FindConVar("sv_alltalk")))
		return Plugin_Continue;

	if (!client || IsPlayerAlive(client))
		return Plugin_Continue;

	if (RoundEnd)
		return Plugin_Continue;

	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;

		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}

	if (text[startidx] == '@')
		return Plugin_Continue;

	if (IsChatTrigger() && text[startidx] == '/')
		return Plugin_Handled;

	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client))
		  SayText2(i, client, text[startidx], true);
	}

	return Plugin_Continue;
}

stock SayText2(client, index, const String:Msg[], bool:teamOnly=false)
{
	if (strlen(Msg) > 191)
	{
		LogError("szMsg (%i) > 191", strlen(Msg));
		return;
	}

	new Handle:hBf;
	if (!client)
		hBf = StartMessageAll("SayText2");
	else
		hBf = StartMessageOne("SayText2", client);

	if (hBf != INVALID_HANDLE)
	{
		decl String:playerName[32];
		GetClientName(index, playerName, sizeof(playerName));

		BfWriteByte(hBf, index);
		BfWriteByte(hBf, true);

		if (!teamOnly)
			BfWriteString(hBf, "\x01*DEAD* \x03%s1 \x01:  %s2");
		else
			BfWriteString(hBf, "\x01*DEAD*(TEAM) \x03%s1 \x01:  %s2");

		BfWriteString(hBf, playerName);
		BfWriteString(hBf, Msg);

		EndMessage();
	}
}