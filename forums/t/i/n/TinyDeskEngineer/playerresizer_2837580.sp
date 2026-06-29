#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Tiny Desk Engineer"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <entity>
#include <admin>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Simple Player Resizer",
	author = PLUGIN_AUTHOR,
	description = "Allows players to resize themselves to arbitrary scales, within a set range.",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar g_cvMinSize;
ConVar g_cvMaxSize;
ConVar g_cvAdminBypass;

float g_fClientSizes[MAXPLAYERS];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_cvMinSize = CreateConVar("sm_resize_min", "0.5", "The minimum size that can be set by the player resizer.", FCVAR_ARCHIVE | FCVAR_NOTIFY);
	g_cvMaxSize = CreateConVar("sm_resize_max", "2", "The maximum size that can be set by the player resizer.", FCVAR_ARCHIVE | FCVAR_NOTIFY);
	g_cvAdminBypass = CreateConVar("sm_resize_adminbypass", "1", "Allow admins to bypass the configured size limits.", FCVAR_ARCHIVE | FCVAR_NOTIFY);
	RegAdminCmd("sm_resize", Command_Resize, ADMFLAG_GENERIC, "Resize any player");
	RegConsoleCmd("sm_resizeme", Command_ResizeMe, "Resize yourself");
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void OnClientConnected(int client)
{
	g_fClientSizes[client - 1] = 1.0;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	ResetPlayerSize(client);
	return Plugin_Continue;
}

public Action Command_Resize(int client, int args)
{
	float size = 1.0;
	
	char arg[32];
	char targetName[MAX_NAME_LENGTH];
	int targets[MAXPLAYERS], targetCount;
	bool isML;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Command syntax: sm_resize <target> [size]");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg, sizeof(arg));
	targetCount = ProcessTargetString(
		arg,
		client,
		targets,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		targetName,
		sizeof(targetName),
		isML
	);
	
	if (targetCount < 1)
	{
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
	}
	
	if (args >= 2)
	{
		GetCmdArg(2, arg, sizeof(arg));
		size = StringToFloat(arg);
		AdjustSize(client, size);
		ReplyToCommand(client, "[SM] Setting size for %i targets to %fx their normal size.", targetCount, size);
	}
	else
	{
		ReplyToCommand(client, "[SM] Resetting size for %i targets back to default.", targetCount);
	}
	
	for (int i = 0; i < targetCount; i++)
	{
		ResizePlayer(targets[i], size);
	}
	
	return Plugin_Handled;
}

public Action Command_ResizeMe(int client, int args)
{
	float size = 1.0;
	
	char arg[32];
	
	if (args >= 1)
	{
		GetCmdArg(1, arg, sizeof(arg));
		size = StringToFloat(arg);
		AdjustSize(client, size);
		ReplyToCommand(client, "[SM] Your size has been set to %fx your normal size.", size);
	}
	else
	{
		ReplyToCommand(client, "[SM] Your size has beeen reset to default.");
	}
	
	ResizePlayer(client, size);
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] You will respawn with the newly set size.");
	}
	return Plugin_Handled;
}

public void ResizePlayer(int client, float size)
{
	g_fClientSizes[client - 1] = size;
	ResetPlayerSize(client);
}

public void ResetPlayerSize(int client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	float size = g_fClientSizes[client - 1];
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", size);
	SetEntPropFloat(client, Prop_Send, "m_flStepSize", size * 18.0);
}

public void AdjustSize(int client, float &size)
{
	if (CheckCommandAccess(client, "resize_adminbypass", ADMFLAG_GENERIC, true) && g_cvAdminBypass.BoolValue)
	{
		return;
	}
	
	float min = g_cvMinSize.FloatValue;
	float max = g_cvMaxSize.FloatValue;
	
	size = size < min ? min : size > max ? max : size;
}