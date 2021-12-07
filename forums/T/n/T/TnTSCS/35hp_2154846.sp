/* 35 HP on Spawn
* 
* 	Plugin made on request - https://forums.alliedmods.net/showthread.php?t=242432
* 	Requestor: Ejziponken
* 	Profile URL: https://forums.alliedmods.net/member.php?u=36879
* 
* 	******************************************************************************
* 	Hi. Would like to have a plugin that gives all players 35 HP when they spawn.
* 	Im not finding any working plugin that does this.
*	
* 	Not working for CSGO:
* 	https://forums.alliedmods.net/showthread.php?t=233971&highlight=health
* 
* 	Does not have the spawn function:
* 	https://forums.alliedmods.net/showthread.php?p=650481
* 	******************************************************************************
* 
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Release
* 
* 	KNOWN ISSUES
* 		None that I could find during my testing
* 
* 	REQUESTS
* 		Suggest something
* 
* 
*/

#pragma semicolon 1

#include <sourcemod>
#include <autoexecconfig>

#define 	PLUGIN_VERSION 		"0.0.1.0"

new g_iClientHP;
new bool:g_bApplyOnBots;
new bool:g_bEnabled;
new g_iNotifyPlayers;

public Plugin:myinfo = 
{
	name = "35HP Gamemode",
	author = "TnTSCS aka ClarkKent",
	description = "Sets player's health to 35 on spawn for 35HP games",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	// Create this plugins CVars
	new bool:appended;
	new Handle:hRandom; // KyleS HATES handles
	
	// Set the file for the include
	AutoExecConfig_SetFile("plugin.35hp");
	
	HookConVarChange((hRandom = CreateConVar("sm_35hp_version", PLUGIN_VERSION, 
	"Version of \"35 HP\"", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_35hp_health", "35", 
	"Health to set players to on spawn", _, true, 1.0)), OnHealthChanged);
	g_iClientHP = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_35hp_bots", "1", 
	"Set spawn health on bots\n0 = NO\n1 = YES", _, true, 0.0, true, 1.0)), OnBotsChanged);
	g_bApplyOnBots = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_35hp_enabled", "1", 
	"Plugin enabled?\n0 = NO\n1 = YES", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	g_bEnabled = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_35hp_notify", "1", 
	"Notify players their health was set to something other than default?\nAdd up the values, 1 will show in hint box only, 5 will show in hint box and chat window.\n0 = NO\n1 = Hint Box\n2 = CenterHud\n4 = Chat window\n8 = Console window", _, true, 0.0, true, 15.0)), OnNotifyChanged);
	g_iNotifyPlayers = GetConVarInt(hRandom);
	SetAppend(appended);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AutoExecConfig(true, "plugin.35hp");
	
	// Cleaning is an expensive operation and should be done at the end
	if (appended)
	{
		AutoExecConfig_CleanFile();
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client) && !g_bApplyOnBots)
	{
		return;
	}
	
	CreateTimer(0.1, Timer_SetClientHealth, GetClientSerial(client));
}

public Action:Timer_SetClientHealth(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	SetEntProp(client, Prop_Data, "m_iHealth", g_iClientHP);
	
	if (g_iNotifyPlayers > 0)
	{
		NotifyPlayer(client);
	}
	
	return Plugin_Handled;
}

NotifyPlayer(client)
{
	if (g_iNotifyPlayers & 1)
	{
		PrintHintText(client, "Your HP was set to %i", g_iClientHP);
	}
	
	if (g_iNotifyPlayers & 2)
	{
		PrintCenterText(client, "Your HP was set to %i", g_iClientHP);
	}
	
	if (g_iNotifyPlayers & 4)
	{
		PrintToChat(client, "Your HP was set to %i", g_iClientHP);
	}
	
	if (g_iNotifyPlayers & 8)
	{
		PrintToConsole(client, "Your HP was set to %i", g_iClientHP);
	}
}

SetAppend(&appended)
{
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
	{
		appended = true;
	}
}

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnHealthChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iClientHP = GetConVarInt(cvar);
}

public OnBotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bApplyOnBots = GetConVarBool(cvar);
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = GetConVarBool(cvar);
}

public OnNotifyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iNotifyPlayers = GetConVarInt(cvar);
}
