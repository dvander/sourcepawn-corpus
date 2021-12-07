#include	<sourcemod>
#pragma		semicolon 1
#pragma		newdecls required
#define		PLUGIN_VERSION "0.4.2"
ConVar		SuppressTeams;
ConVar		SuppressConnect;
ConVar		SuppressDisconnect;
ConVar		SuppressKillfeed;
ConVar		SuppressWinPanel;
ConVar		SuppressAchievement;
ConVar		SuppressAnnotation;
ConVar		SuppressNameChange;
ConVar		SuppressVoiceSubTitles;
ConVar		SuppressCvar;

public	Plugin myinfo	=
{
	name		=	"[ANY] Suppress Manager",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Blocks specific messages & outputs from showing.",
	version		=	PLUGIN_VERSION,
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public	void OnPluginStart()
{
	CreateConVar("sm_suppress_version",	PLUGIN_VERSION,	"Suppress Manager Version");
	SuppressTeams		=	CreateConVar("sm_suppress_teams",		"0",	"Block Player Joined Team Message? \n0 = Allow Player Joined Team Message \n1 = Block Player Joined Team Message",																		_, true, 0.0, true, 1.0);
	SuppressConnect		=	CreateConVar("sm_suppress_connect",		"0",	"Block Player Connected Message? \n0 = Allow Connect Message \n1 = Block Connect Message \n2 = Block Only Bot Connect Message \n3 = Block Only Player Connect Message",					_, true, 0.0, true, 3.0);
	SuppressDisconnect	=	CreateConVar("sm_suppress_disconnect",	"0",	"Block Player Disconnect Message? \n0 = Allow Disconnect Message \n1 = Block Disconnect Message \n2 = Block Only Bot Disconnect Message \n3 = Block Only Player Disconnect Message",	_, true, 0.0, true, 3.0);
	SuppressKillfeed	=	CreateConVar("sm_suppress_killfeed",	"0",	"Block Player Killfeed? \n0 = Allow Killfeed \n1 = Block Killfeed",																														_, true, 0.0, true, 1.0);
	SuppressNameChange	=	CreateConVar("sm_suppress_namechange",	"0",	"Block Player Name Change Message? \n0 = Allow Player Name Change Message \n1 = Block Player Name Change Message",																		_, true, 0.0, true, 1.0);
	SuppressAchievement	=	CreateConVar("sm_suppress_achievement",	"0",	"Block Player Achievement Get Message? \n0 = Allow Player Achievement Get Message \n1 = Block Player Achievement Get Message",															_, true, 0.0, true, 1.0);
	SuppressCvar		=	CreateConVar("sm_suppress_cvar",		"0",	"Block Cvar Has Changed To Message? \n0 = Allow Cvar Has Changed To Message \n1 = Block Cvar Has Changed To Message",																	_, true, 0.0, true, 1.0);
	HookUserMessage(GetUserMessageId("SayText2"), suppress_NameChange, true);
	HookEvent("player_team",				suppress_Teams,			EventHookMode_Pre);
	HookEvent("player_connect",				suppress_Connect,		EventHookMode_Pre);
	HookEvent("player_disconnect",			suppress_Disconnect,	EventHookMode_Pre);
	HookEvent("player_death",				suppress_Killfeed,		EventHookMode_Pre);
	HookEvent("achievement_earned",			suppress_Achievement,	EventHookMode_Pre);
	HookEvent("server_cvar",				suppress_Cvar,			EventHookMode_Pre);
	//Check game version
	switch (GetEngineVersion())
	{
		case Engine_CSS: //Counter-Strike: Source
		{
			HookEvent("player_connect_client",		suppress_Connect,		EventHookMode_Pre);
			HookEvent("achievement_event",			suppress_Achievement,	EventHookMode_Pre);
		}
		case Engine_TF2: //Team Fortress 2
		{
			HookEvent("player_connect_client",	suppress_Connect,		EventHookMode_Pre);
			HookEvent("achievement_event",		suppress_Achievement,	EventHookMode_Pre);
			HookEvent("teamplay_win_panel",		suppress_WinPanel,		EventHookMode_Pre);
			HookEvent("show_annotation",		suppress_Annotation,	EventHookMode_Pre);
			HookUserMessage(GetUserMessageId("VoiceSubtitle"), suppress_VoiceSubTitles, true); 
		
			SuppressWinPanel		=	CreateConVar("sm_suppress_winpanel",		"0",	"Block Player Winpanel From Showing on Win?",		_, true, 0.0, true, 1.0);
			SuppressAnnotation		=	CreateConVar("sm_suppress_annotation",		"0",	"Block Player Annotation Message From Showing?",	_, true, 0.0, true, 1.0);
			SuppressVoiceSubTitles	=	CreateConVar("sm_suppress_voicesubtitles",	"0",	"Block Player Voice Subtitles?",					_, true, 0.0, true, 1.0);
		}
	}
	AutoExecConfig(true, "sm_suppress_manager");
}

//Cvar has changed to Event
public Action suppress_Cvar(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressCvar.BoolValue) SetEventBroadcast(event, true);
}
//Player has joined team Event
public Action suppress_Teams(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressTeams.BoolValue) SetEventBroadcast(event, true);
}
//Connect Event
public Action suppress_Connect(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressConnect.IntValue == 1 || 
	SuppressConnect.IntValue == 2 || 
	SuppressConnect.IntValue == 3)
		SetEventBroadcast(event, true);
}
public void OnClientAuthorized(int client)
{
	if(!IsValidClient(client))
		return;

	if (SuppressConnect.IntValue == 2 && !IsFakeClient(client))
		PrintToChatAll("%N has joined the game", client);
	
	else if (SuppressConnect.IntValue == 3 && IsFakeClient(client))
		PrintToChatAll("%N has joined the game", client);
}
//Disconnect Event
public Action suppress_Disconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return Plugin_Continue;

	char reason[1024];
	GetEventString(event,"reason",reason,sizeof(reason));
	
	if (SuppressDisconnect.IntValue == 1) SetEventBroadcast(event, true);
	else if (SuppressDisconnect.IntValue == 2 && !IsFakeClient(client))
	{
		SetEventBroadcast(event, true);
		PrintToChatAll("%N has left the game (%s)", client, reason);
	}
	else if (SuppressDisconnect.IntValue == 3 && IsFakeClient(client))
	{
		SetEventBroadcast(event, true);
		PrintToChatAll("%N has left the game (%s)", client, reason);
	}
	return Plugin_Handled;
}
//Killfeed Event
public Action suppress_Killfeed(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressKillfeed.BoolValue) SetEventBroadcast(event, true);
}
//Winpanel Event
public Action suppress_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressWinPanel.BoolValue) SetEventBroadcast(event, true);
}
//Achievement get Event
public Action suppress_Achievement(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressAchievement.BoolValue) SetEventBroadcast(event, true);
}
//Annotation Event
public Action suppress_Annotation(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressAnnotation.BoolValue) SetEventBroadcast(event, true);
}
//Voice subtitles Event
//Credits Bacardi
public Action suppress_NameChange(UserMsg msg_id, Handle bf, players[], int playersNum, bool reliable, bool init)
{
	if (SuppressNameChange.BoolValue)
	{
		if(!reliable) return Plugin_Continue;
		char buffer[25];
		if(GetUserMessageType() == UM_Protobuf) // CSGO
		{
			PbReadString(bf, "msg_name", buffer, sizeof(buffer));
			if(StrEqual(buffer, "#Cstrike_Name_Change")) return Plugin_Handled;	//CSGO
		}
		else
		{
			BfReadChar(bf);
			BfReadChar(bf);
			BfReadString(bf, buffer, sizeof(buffer));

			if(StrEqual(buffer, "#Cstrike_Name_Change")) return Plugin_Handled;	//CSS
			if(StrEqual(buffer, "#TF_Name_Change")) return Plugin_Handled;	//TF2
		}
	}
	return Plugin_Continue;
}
//Name change Event
//Credits GORRageBoy
public Action suppress_VoiceSubTitles(UserMsg msg_id, Handle bf, const players[], int playersNum, bool reliable, bool init)
{
	int clientid = BfReadByte(bf);
	int voicemenu1 = BfReadByte(bf);
	int voicemenu2 = BfReadByte(bf);
	if (SuppressVoiceSubTitles.BoolValue)
	{
		if (IsPlayerAlive(clientid) && IsClientInGame(clientid))
		{	
			if (voicemenu1 == 0)
			{
				switch (voicemenu2)
				{
					case 0: return Plugin_Handled;
					case 1: return Plugin_Handled;
					case 2: return Plugin_Handled;
					case 3: return Plugin_Handled;
					case 4: return Plugin_Handled;
					case 5: return Plugin_Handled;
					case 6: return Plugin_Handled;
					case 7: return Plugin_Handled;
				}
			}
			if (voicemenu1 == 1)
			{
				switch (voicemenu2)
				{
					case 0: return Plugin_Handled;
					case 1: return Plugin_Handled;
					case 2: return Plugin_Handled;
					case 6: return Plugin_Handled;
				}
			}
			if((voicemenu1 == 2) && (voicemenu2 == 0)) return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (IsClient(client) && IsClientConnected(client) && IsClientInGame(client));
}

stock bool IsClient(int client)
{
	return (client > 0 && client < MaxClients + 1);
}
