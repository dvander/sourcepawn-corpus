#include <sourcemod>

Handle game_spam_block_teamchange;
Handle game_spam_block_namechange;
Handle game_spam_block_switch;
Handle game_spam_block_model;
Handle game_spam_block_joined;
Handle game_spam_block_svtags;
Handle game_spam_block_pausable;

public Plugin:myinfo = 
{
	name = "Block game chat spam",
	author = "Alienmario",
	description = "Modified tidy chat by linux_lover for HL2DM",
	version = "1.1",
	url = "http://bouncyball.eu"
}

public OnPluginStart()
{
	game_spam_block_teamchange = CreateConVar("game_spam_block_teamchange", "1", "Block team change messages", _, true, 0.0, true, 1.0);
	game_spam_block_namechange = CreateConVar("game_spam_block_namechange", "1", "Block name change messages", _, true, 0.0, true, 1.0);
	game_spam_block_switch = CreateConVar("game_spam_block_switch", "1", "Block 'more seconds before trying to switch' messages", _, true, 0.0, true, 1.0);
	game_spam_block_model = CreateConVar("game_spam_block_model", "1", "Block 'Your player model is' messages", _, true, 0.0, true, 1.0);
	game_spam_block_joined = CreateConVar("game_spam_block_joined", "1", "Block 'joined the game' messages", _, true, 0.0, true, 1.0);
	game_spam_block_svtags = CreateConVar("game_spam_block_svtags", "1", "Block 'sv_tags changed' messages", _, true, 0.0, true, 1.0);
	game_spam_block_pausable = CreateConVar("game_spam_block_pausable", "1", "Block 'sv_pausable changed' messages", _, true, 0.0, true, 1.0);
	AutoExecConfig()
	
	HookEvent("player_team", Event_Team, EventHookMode_Pre);	
	HookEvent("player_changename", Event_Name, EventHookMode_Pre);
	HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("TextMsg"), HookChatMSG, true);
}

public Action:Event_Team (Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarBool(game_spam_block_teamchange)){
		SetEventBool(event, "silent", true);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action Event_Name(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarBool(game_spam_block_namechange))
		event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarBool(game_spam_block_joined))
		event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action Event_Cvar(Event event, const char[] name, bool dontBroadcast)
{
	char cvar[128];
	event.GetString("cvarname", cvar, sizeof(cvar))
	
	if(GetConVarBool(game_spam_block_svtags) && StrEqual(cvar, "sv_tags")
		|| GetConVarBool(game_spam_block_pausable) && StrEqual(cvar, "sv_pausable")
	)
		event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action:HookChatMSG(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{
	char strMessage[70];
	BfReadString(bf, strMessage, sizeof(strMessage), true);
	if(StrContains(strMessage, "more seconds before trying to switch")!=-1 && GetConVarBool(game_spam_block_switch)){
		return Plugin_Handled;
	}
	if(StrContains(strMessage, "Your player model is")!=-1 && GetConVarBool(game_spam_block_model)){
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}