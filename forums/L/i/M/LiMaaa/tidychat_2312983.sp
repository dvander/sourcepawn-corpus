#include <sourcemod>

#define PLUGIN_VERSION "0.4"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hVoice = INVALID_HANDLE;
new Handle:g_hConnect = INVALID_HANDLE;
new Handle:g_hDisconnect = INVALID_HANDLE;
new Handle:g_hChangeClass = INVALID_HANDLE;
new Handle:g_hTeam = INVALID_HANDLE;
new Handle:g_hArena = INVALID_HANDLE;
new Handle:g_hMaxStreak = INVALID_HANDLE;
new Handle:g_hCvar = INVALID_HANDLE;
new Handle:g_hAllText = INVALID_HANDLE;
new bool:bTF2 = false;

public Plugin:myinfo = 
{
	name = "Tidy Chat",
	author = "linux_lover",
	description = "Cleans up the chat area.",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_tidychat_version", PLUGIN_VERSION, "Tidy Chat Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hEnabled = CreateConVar("sm_tidychat_on", "1", "0/1 On/off");
	g_hVoice = CreateConVar("sm_tidychat_voice", "1", "0/1 Tidy (Voice) messages");
	g_hConnect = CreateConVar("sm_tidychat_connect", "0", "0/1 Tidy connect messages");
	g_hDisconnect = CreateConVar("sm_tidychat_disconnect", "0", "0/1 Tidy disconnect messsages");
	g_hChangeClass = CreateConVar("sm_tidychat_class", "1", "0/1 Tidy class change messages");
	g_hTeam = CreateConVar("sm_tidychat_team", "1", "0/1 Tidy team join messages");
	g_hArena = CreateConVar("sm_tidychat_arena", "1", "0/1 Tidy arena team resize messages");
	g_hMaxStreak = CreateConVar("sm_tidychat_streak", "1", "0/1 Tidy (arena) team scramble messages");
	g_hCvar = CreateConVar("sm_tidychat_cvar", "1", "0/1 Tidy cvar messages");
	g_hAllText = CreateConVar("sm_tidychat_alltext", "0", "0/1 Tidy all chat messages from plugins");
	
	// Mod independant hooks
	HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Class, true);
	
	// TF2 dependant hooks
	new String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(strcmp(strGame, "tf") == 0)
	{
		bTF2 = true;
		HookUserMessage(GetUserMessageId("VoiceSubtitle"), UserMessageHook, true);
		HookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
		HookEvent("arena_match_maxstreak", Event_MaxStreak, EventHookMode_Pre);
	}	
}

public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hConnect))
	{
		SetEventBroadcast(event, true);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hDisconnect))
	{
		SetEventBroadcast(event, true);
	}
	
	return Plugin_Continue;
}

public Action:Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hChangeClass))
	{
		SetEventBroadcast(event, true);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hTeam))
	{
		if(!GetEventBool(event, "silent"))
		{
			SetEventBroadcast(event, true);
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_MaxStreak(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hMaxStreak))
	{
		SetEventBroadcast(event, true);
	}
	
	return Plugin_Continue;
}

public Action:Event_Cvar(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hCvar))
	{
		SetEventBroadcast(event, true);
	}
	
	return Plugin_Continue;
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hVoice))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:UserMessageHook_Class(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{
	if(GetConVarInt(g_hEnabled))
	{
		if(GetConVarInt(g_hAllText)) return Plugin_Handled;
		
		if(bTF2)
		{
			new String:strMessage[50];
			BfReadString(bf, strMessage, sizeof(strMessage), true);
			
			// Looks like a translation text from the game.
			if(GetConVarInt(g_hTeam) && StrContains(strMessage, "#game_") == 1)
			{
				return Plugin_Handled;
			}
			
			if(GetConVarInt(g_hArena) && StrContains(strMessage, "#TF_Arena_Team") == 1)
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}