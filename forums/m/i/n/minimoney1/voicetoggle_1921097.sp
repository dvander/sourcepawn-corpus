#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.3"

new bool:g_bPublicVoice[MAXPLAYERS + 1],
	bool:g_bDefSetting,
	bool:g_bGlobalOnDeath;

public Plugin:myinfo =
{
	name = "Voice Toggle",
	author = "Sky, Mini",
	description = "Allows players to toggle between team only voice chat and global voice chat (with players allowing the feature)",
	version = PLUGIN_VERSION,
	url = "steamcommunity.com/groups/skyrpg"
}

public OnPluginStart()
{
	CreateConVar("voicetoggle_version", PLUGIN_VERSION, "The version of voice toggle.", FCVAR_NOTIFY | FCVAR_PLUGIN);

	new Handle:conVar;
	conVar = CreateConVar("voicetoggle_default_setting", "1", "Do we enable public voice chat by default?");
	g_bDefSetting = GetConVarBool(conVar);
	HookConVarChange(conVar, OnDefSettingChanged);


	conVar = CreateConVar("voicetoggle_global_ondeath", "1", "Do we make voice chat global when a player dies?");
	g_bGlobalOnDeath = GetConVarBool(conVar);
	HookConVarChange(conVar, OnGlobalOnDeathChanged);

	RegConsoleCmd("sm_voice", Command_ToggleVoice);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	LoadTranslations("common.phrases");
	LoadTranslations("voicetoggle.phrases");
}

public OnDefSettingChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	g_bDefSetting = bool:StringToInt(newVal);
}

public OnGlobalOnDeathChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	g_bGlobalOnDeath = bool:StringToInt(newVal);
}

public OnClientPostAdminCheck(client)
{
	if (IsClientConnected(client) && !IsClientInGame(client))
	{
		CreateTimer(1.0, Timer_ClientIsInGame, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (IsClientConnected(client) && IsClientInGame(client))
	{
		ChangeClientDefSetting(client);
	}
}

public Action:Timer_ClientIsInGame(Handle:timer, any:client)
{
	if (!IsClientConnected(client))
	{
		return Plugin_Stop;
	}
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		ChangeClientDefSetting(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Command_ToggleVoice(client, args)
{
	if ((client) && IsPlayerAlive(client))
	{
		ToggleVoiceChat(client);
	}

	return Plugin_Handled;
}

stock ChangeClientDefSetting(client)
{
	g_bPublicVoice[client] = !g_bDefSetting;
	ToggleVoiceChat(client);
}

stock ToggleVoiceChat(client, bool:changeVal = true)
{
	if (changeVal)
	{
		decl String:translation[32];
		g_bPublicVoice[client] = !g_bPublicVoice[client];
		FormatEx(translation, sizeof(translation), "Public Voice %s", g_bPublicVoice[client] ? "Enabled" : "Disabled");
		PrintToChat(client, "%T", translation, client);
	}
	
	for (new i = 1; i <= MaxClients, i != client; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			if (g_bPublicVoice[client] && g_bPublicVoice[i] || GetClientTeam(client) == GetClientTeam(i))
			{
				SetListenOverride(client, i, Listen_Yes);
				SetListenOverride(i, client, Listen_Yes);
			}
			else if ((!g_bPublicVoice[client] || !g_bPublicVoice[i]) && GetClientTeam(client) != GetClientTeam(i))
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			}
		}
	}
}

public Event_PlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientInGame(client) && !IsFakeClient(client) && g_bGlobalOnDeath)
	{
		if (!g_bPublicVoice[client]) 
		{ 
			ToggleVoiceChat(client, false);
		}
	}
}

public Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		ToggleVoiceChat(client, false);
	}
}

