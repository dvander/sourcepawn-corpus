#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

/* Global Definitions */

#define PLUGIN_VERSION "1.1.1"

/* Global Handles */

new Handle:Version;
new Handle:cvarEnabled;
new Handle:cvarLogs;
new Handle:cvarJoin;
new Handle:cvarJoinSize;

/* Global Variables */

new bool:Enabled;
new bool:Logs;
new Float:g_HeadScale[MAXPLAYERS + 1] = 1.0;

public Plugin:myinfo =
{
	name = "[TF2] Resize Heads",
	author = "Tak + ReFlexPoison",
	description = "LOL!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	Version = CreateConVar("sm_resizehead_version", PLUGIN_VERSION, "Version of Resize Heads", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvarEnabled = CreateConVar("sm_resizehead_enabled", "1", "Enable Resize Heads", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarLogs = CreateConVar("sm_resizehead_logs", "1", "Enable logs of head resizes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarJoin = CreateConVar("sm_resizehead_join", "0", "Should we resize your head when player spawns? Off = 0 Public = 1 Admins = 2", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvarJoinSize = CreateConVar("sm_resizehead_joinsize", "1.0", "What should the default size be?");

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarLogs, CVarChange);
	HookConVarChange(Version, CVarChange);

	RegAdminCmd("sm_resizehead", ResizeHead, ADMFLAG_GENERIC, "Resizes players' heads");
	RegAdminCmd("sm_resizemyhead", ResizeMyHead, ADMFLAG_GENERIC, "Resizes your head");

	HookEvent("player_spawn", Player_Spawn);

	AutoExecConfig(true, "resizehead");
	LoadTranslations("common.phrases");

	for(new i = 0; i <= MaxClients; i++)
	{
		if(!IsValidClient(i)) continue;
		{
			g_HeadScale[i] = 1.0;
			SetEntPropFloat(i, Prop_Send, "m_flHeadScale", 1.0);
		}
	}
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Version) SetConVarString(Version, PLUGIN_VERSION);
	if(convar == cvarEnabled)
	{
		if(GetConVarBool(cvarEnabled)) Enabled = true;
		else Enabled = false;
	}
	if(convar == cvarLogs)
	{
		if(GetConVarBool(cvarLogs)) Logs = true;
		else Logs = false;
	}
}

public OnConfigsExecuted()
{
	if(GetConVarBool(cvarEnabled)) Enabled = true;
	else Enabled = false;
}

public OnClientPostAdminCheck(client)
{
	if(!IsValidClient(client)) return;
	g_HeadScale[client] = 1.0;
}

public OnGameFrame()
{
	if(!Enabled) return;

	for(new i = 0; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || g_HeadScale[i] == 1.0) continue;
		{
			SetEntPropFloat(i, Prop_Send, "m_flHeadScale", g_HeadScale[i]);
		}
	}
}

public Action:Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new i = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(i) && IsClientAuthorized(i))
	{
		if(Enabled && (GetConVarInt(cvarJoin) == 1 || GetConVarInt(cvarJoin) == 2 && GetUserFlagBits(i) & ADMFLAG_GENERIC))
		{
			g_HeadScale[i] = 1.0;
			new Float:scale = GetConVarFloat(cvarJoinSize);

			if(scale <= 0.0) scale = 0.1;
			if(scale > 3.0) scale = 3.0;

			g_HeadScale[i] = scale;
		}
	}
}
public Action:ResizeHead(client, args)
{
	if(!Enabled || !IsValidClient(client)) return Plugin_Continue;

	if(args < 2)
	{
		ReplyToCommand(client, "Usage: sm_resizehead <#userid|name> <size>");
		return Plugin_Handled;
	}

	decl String:arg1[65], String:arg2[65], Float:scale;
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	scale = StringToFloat(arg2);
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if(scale <= 0.0) scale = 0.1;
	if(scale > 3.0) scale = 3.0;

	for(new i = 0; i < target_count; i++)
	{
		if(IsValidClient(target_list[i]))
		{
			g_HeadScale[target_list[i]] = scale;
			if(Logs) LogAction(client, target_list[i], "\"%L\" resized head of \"%L\"", client, target_list[i]);
		}
	}
	ShowActivity2(client, "[SM] ", "%N resized head of %s to %f.", client, target_name, scale);
	return Plugin_Handled;
}

public Action:ResizeMyHead(client, args)
{
	if(!Enabled || !IsValidClient(client)) return Plugin_Continue;

	decl String:arg1[65], Float:scale;
	GetCmdArg(1, arg1, sizeof(arg1));
	scale = StringToFloat(arg1);

	if(args == 0)
	{
		scale = 1.0;
		g_HeadScale[client] = scale;
		PrintToChat(client, "[SM] Your head size has been reset.");
		return Plugin_Handled;
	}
	else if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_resizemyhead <size>");
		return Plugin_Handled;
	}

	if(scale <= 0.0) scale = 0.1;
	if(scale > 3.0) scale = 3.0;

	g_HeadScale[client] = scale;
	PrintToChat(client, "[SM] Head size set to %f.", scale);
	return Plugin_Handled;
}

stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}