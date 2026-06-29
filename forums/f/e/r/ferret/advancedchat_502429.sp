/**
 * advancedchat.sp
 * Provides mute, gag, deadtalk, and other communication features
 *
 * Changelog:
 *
 * Version 1.0
 * - Release
 *
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Advanced Chat",
	author = "ferret",
	description = "Provides mute, gag, deadtalk, and other communication features",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define LIFE_ALIVE 0
new g_iLifeState = -1;

new bool:g_Muted[MAXPLAYERS+1];
new bool:g_Gagged[MAXPLAYERS+1];

new Handle:g_Cvar_Deadtalk = INVALID_HANDLE;
new Handle:g_Cvar_Alltalk = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.advancedchat");
	
	CreateConVar("sm_advancedchat_version", PLUGIN_VERSION, "Advanced Chat Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_Deadtalk = CreateConVar("sm_deadtalk", "0", "Sets the deadtalk mode.", 0, true, 0.0, true, 1.0);
	g_Cvar_Alltalk = FindConVar("sv_alltalk");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegAdminCmd("sm_mute", Command_Mute, ADMFLAG_CHAT, "sm_mute <player> - Removes a player's ability to use voice.");
	RegAdminCmd("sm_gag", Command_Gag, ADMFLAG_CHAT, "sm_gag <player> - Removes a player's ability to use chat.");
	RegAdminCmd("sm_silence", Command_Silence, ADMFLAG_CHAT, "sm_silence <player> - Removes a player's ability to use voice or chat.");
	
	RegAdminCmd("sm_unmute", Command_Unmute, ADMFLAG_CHAT, "sm_unmute <player> - Restores a player's ability to use voice.");
	RegAdminCmd("sm_ungag", Command_Ungag, ADMFLAG_CHAT, "sm_ungag <player> - Restores a player's ability to use chat.");
	RegAdminCmd("sm_unsilence", Command_Unsilence, ADMFLAG_CHAT, "sm_unsilence <player> - Restores a player's ability to use voice and chat.");	
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	g_iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState");
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) // When a player connects...
{
	g_Gagged[client] = false;
	g_Muted[client] = false;
	
	return true;
}

public Action:Command_Say(client, args)
{
	if (client)
	{
		if (g_Gagged[client])
			return Plugin_Handled;		
	}
	
	return Plugin_Continue;
}

public Action:Command_Mute(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mute <player>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if (target == -1)
		return Plugin_Handled; // FindTarget sends messages.

	if (g_Muted[target])
	{
		ReplyToCommand(client, "%t", "Already Muted");
		return Plugin_Handled;		
	}
		
	g_Muted[target] = true;
	SetClientListeningFlags(target, VOICE_MUTED);
	
	decl String:name[64];
	GetClientName(target, name, sizeof(name));

	ShowActivity(client, "%t", "Player Muted", name);
	ReplyToCommand(client, "%t", "Player Muted", name);
	
	return Plugin_Handled;	
}

public Action:Command_Gag(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gag <player>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if (target == -1)
		return Plugin_Handled; // FindTarget sends messages.

	if (g_Gagged[target])
	{
		ReplyToCommand(client, "%t", "Already Gagged");
		return Plugin_Handled;		
	}
		
	g_Gagged[target] = true;
	
	decl String:name[64];
	GetClientName(target, name, sizeof(name));

	ShowActivity(client, "%t", "Player Gagged", name);
	ReplyToCommand(client, "%t", "Player Gagged", name);
	
	return Plugin_Handled;	
}

public Action:Command_Silence(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silence <player>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if (target == -1)
		return Plugin_Handled; // FindTarget sends messages.

	if (g_Gagged[target] && g_Muted[target])
	{
		ReplyToCommand(client, "%t", "Already Silenced");
		return Plugin_Handled;		
	}

	decl String:name[64];
	GetClientName(target, name, sizeof(name));
	
	if (!g_Gagged[target])
	{
		g_Gagged[target] = true;

		ShowActivity(client, "%t", "Player Gagged", name);
		ReplyToCommand(client, "%t", "Player Gagged", name);
	}
	
	if (!g_Muted[target])
	{
		g_Muted[target] = true;
		SetClientListeningFlags(target, VOICE_MUTED);
	
		ShowActivity(client, "%t", "Player Muted", name);
		ReplyToCommand(client, "%t", "Player Muted", name);		
	}
	
	return Plugin_Handled;	
}

public Action:Command_Unmute(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unmute <player>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if (target == -1)
		return Plugin_Handled; // FindTarget sends messages.

	if (!g_Muted[target])
	{
		ReplyToCommand(client, "%t", "Player Not Muted");
		return Plugin_Handled;		
	}
		
	g_Muted[target] = false;
	if (GetConVarInt(g_Cvar_Deadtalk) && !IsAlive(target))
		SetClientListeningFlags(target, VOICE_LISTENALL);
	else
		SetClientListeningFlags(target, VOICE_NORMAL);

	
	decl String:name[64];
	GetClientName(target, name, sizeof(name));

	ShowActivity(client, "%t", "Player Unmuted", name);
	ReplyToCommand(client, "%t", "Player Unmuted", name);
	
	return Plugin_Handled;	
}

public Action:Command_Ungag(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ungag <player>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if (target == -1)
		return Plugin_Handled; // FindTarget sends messages.

	if (!g_Gagged[target])
	{
		ReplyToCommand(client, "%t", "Player Not Gagged");
		return Plugin_Handled;		
	}
		
	g_Gagged[target] = false;
	
	decl String:name[64];
	GetClientName(target, name, sizeof(name));

	ShowActivity(client, "%t", "Player Ungagged", name);
	ReplyToCommand(client, "%t", "Player Ungagged", name);
	
	return Plugin_Handled;	
}

public Action:Command_Unsilence(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unsilence <player>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if (target == -1)
		return Plugin_Handled; // FindTarget sends messages.

	if (!g_Gagged[target] && !g_Muted[target])
	{
		ReplyToCommand(client, "%t", "Player Not Silenced");
		return Plugin_Handled;		
	}
	
	decl String:name[64];
	GetClientName(target, name, sizeof(name));
	
	if (g_Gagged[target])
	{
		g_Gagged[target] = false;
		
		ShowActivity(client, "%t", "Player Ungagged", name);
		ReplyToCommand(client, "%t", "Player Ungagged", name);		
	}
	
	if (g_Muted[target])
	{
		g_Muted[target] = false;
		
		if (GetConVarInt(g_Cvar_Deadtalk) && !IsAlive(target))
			SetClientListeningFlags(target, VOICE_LISTENALL);
		else
			SetClientListeningFlags(target, VOICE_NORMAL);
		
		ShowActivity(client, "%t", "Player Unmuted", name);
		ReplyToCommand(client, "%t", "Player Unmuted", name);				
		
	}
	
	return Plugin_Handled;	
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_Muted[client])
		SetClientListeningFlags(client, VOICE_MUTED);
	else
		SetClientListeningFlags(client, VOICE_NORMAL);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(g_Cvar_Deadtalk))
		return;	
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_Muted[client])
	{
		SetClientListeningFlags(client, VOICE_MUTED);
		return;
	}
	
	if (GetConVarBool(g_Cvar_Alltalk))
	{
		SetClientListeningFlags(client, VOICE_NORMAL);
		return;
	}
	
	SetClientListeningFlags(client, VOICE_LISTENALL);
}

bool:IsAlive(client)
{
    if (g_iLifeState != -1 && GetEntData(client, g_iLifeState, 1) == LIFE_ALIVE)
        return true;
 
    return false;
}
