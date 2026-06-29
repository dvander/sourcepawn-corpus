#define PLUGIN_VERSION "1.2"

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <geoip>

#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[ANY] Vote server restart",
	author = "Dragokas",
	description = "Vote for server restarting",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
};

ConVar g_hCvarTimeout;
ConVar g_hCvarAnnounceDelay;
ConVar g_hCvarAccessFlag;
ConVar g_ConVarMethod;
ConVar g_hCvarLog;
ConVar g_hCvarUnloadExtNum;
ConVar g_hCvarActionDelay;
ConVar g_ConVarHibernate;

char g_sLog[PLATFORM_MAX_PATH];

bool g_bVeto;
bool g_bVotepass;
bool g_bVoteInProgress;
bool g_bVoteDisplayed;

EngineVersion g_Engine;
Handle hPluginMe;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Engine = GetEngineVersion();
	hPluginMe = myself;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_voterestart.phrases");
	
	CreateConVar("l4d_voterestart_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hCvarAccessFlag = CreateConVar(		"sm_voterestart_accessflag",		"z",				"Admin flag(s) required to start the vote", CVAR_FLAGS );
	g_ConVarMethod = CreateConVar(			"sm_voterestart_method", 			"2", 				"Restart method (1 - _restart, 2 - crash)", CVAR_FLAGS);
	g_hCvarLog = CreateConVar(				"sm_voterestart_log",				"1",				"Use logging? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarUnloadExtNum = CreateConVar(		"sm_voterestart_unload_ext_num", 	"0", 				"If you have Accelerator extension, you need specify here order number of this extension in the list: sm exts list", CVAR_FLAGS);
	g_hCvarAnnounceDelay = CreateConVar(	"sm_voterestart_announcedelay",		"5.0",				"Delay (in sec.) between announce and vote menu appearing", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(			"sm_voterestart_timeout",			"10",				"How long (in sec.) does the vote last", CVAR_FLAGS );
	g_hCvarActionDelay = CreateConVar(		"sm_voterestart_actiondelay",		"5",				"Delay (in sec.) before actual restarting, after displaying restart message", CVAR_FLAGS );
	
	AutoExecConfig(true,				"sm_voterestart");
	
	g_ConVarHibernate = FindConVar("sv_hibernate_when_empty");
	
	RegConsoleCmd("sm_restart", 	CmdVoteMenu,	"Start the vote with access check");
	RegConsoleCmd("sm_voterestart", CmdVoteMenu,	"-||-");
	
	RegAdminCmd("sm_veto", 			Command_Veto, 		ADMFLAG_BAN, 	"Allow admin to veto current vote.");
	RegAdminCmd("sm_votepass", 		Command_Votepass, 	ADMFLAG_ROOT, 	"Allow admin to bypass current vote.");
	
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/vote_restart.log");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

public void OnMapStart()
{
	g_bVoteInProgress = false; // just in case
}

public Action CmdVoteMenu(int client, int args)
{
	if( client != 0 ) VoteStart(client);
	return Plugin_Handled;
}

public Action Command_Veto(int client, int args)
{
	if( g_bVoteInProgress ) { // IsVoteInProgress() is not working here, sm bug?
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if( g_bVoteInProgress ) {
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

void VoteStart(int client)
{
	LogVoteAction(client, "[TRY] Vote Restart by");
	
	if( IsVoteInProgress() || g_bVoteInProgress ) {
		CPrintToChat(client, "%t", "other_vote");
		LogVoteAction(client, "[DENY] Vote Restart. Reason: another vote is in progress.");
		return;
	}
	
	if( !HasVoteAccess(client) ) {
		CPrintToChat(client, "%t", "access_denied");
		LogVoteAction(client, "[DENY] Vote Restart. Reason: client has no sufficient access flags.");
		return;
	}
	
	LogVoteAction(client, "[STARTED] Vote Restart by");
	
	CPrintToChatAll("%t", "vote_started", client); // %N is started vote for restart the server
	PrintToServer("%N started the vote for restart the server.", client);
	CPrintToConsoleAll("%N started the vote for restart the server.", client);
	
	Menu menu = new Menu(Handle_VoteRestart, MenuAction_DisplayItem | MenuAction_Display);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	FreezeAll();
	CreateTimer(g_hCvarAnnounceDelay.FloatValue, Timer_VoteDelayed, menu);
	CPrintHintTextToAll("%t", "vote_started_announce");
}

Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if( g_bVotepass || g_bVeto ) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if( !IsVoteInProgress() ) {
			g_bVoteInProgress = true;
			menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
			g_bVoteDisplayed = true;
		}
		else {
			UnFreezeAll();
			delete menu;
		}
	}
}

public int Handle_VoteRestart(Menu menu, MenuAction action, int param1, int param2)
{
	char display[64], buffer[255];
	
	switch( action )
	{
		case MenuAction_End: {
			if( g_bVoteInProgress && g_bVotepass ) { // in case vote is passed with CancelVote(), so MenuAction_VoteEnd is not called.
				Handler_PostVoteAction(true);
			}
			g_bVoteInProgress = false;
			delete menu;
		}
		case MenuAction_VoteEnd: // 0=yes, 1=no
		{
			if( (param1 == 0 || g_bVotepass) && !g_bVeto ) {
				Handler_PostVoteAction(true);
			}
			else {
				Handler_PostVoteAction(false);
			}
			g_bVoteInProgress = false;
		}
		case MenuAction_VoteCancel:
		{
			Handler_PostVoteAction(false);
		}
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			Format(buffer, sizeof(buffer), "%T", display, param1);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			Format(buffer, sizeof(buffer), "%T", "vote_started_announce", param1);
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if( bVoteSuccess ) {
		LogVoteAction(0, "[ACCEPTED] Vote Restart");
		CPrintToChatAll("%t", "vote_success");
		PreRestartActions();
		CreateTimer(1.0, Timer_FinishRestart, _, TIMER_REPEAT);
	}
	else {
		UnFreezeAll();
		LogVoteAction(0, "[NOT ACCEPTED] Vote Restart.");
		CPrintToChatAll("%t", "vote_failed");
	}
	g_bVoteInProgress = false;
}

void MsgRestart(int sec)
{
	CPrintHintTextToAll("%t", "Restart_Msg_Hint", sec);
	CPrintToChatAll("%t", "Restart_Msg_Chat");
	CPrintToConsoleAll("%t", "Restart_Msg_Console");
}

Action Timer_RestartActions(Handle timer)
{
	RestartActions();
}

public void RestartActions()
{
	switch( g_ConVarMethod.IntValue )
	{
		case 1: ExecuteCheatCommand("_restart");
		case 2: ExecuteCheatCommand("crash");
	}
}

Action Timer_FinishRestart(Handle timer)
{
	static int sec = 4;
	MsgRestart(sec);
	if( sec == 0 )
	{
		KickAll();
		CreateTimer(0.1, Timer_RestartActions); // allow kick to happen before reboot
		return Plugin_Stop;
	}
	sec--;
	return Plugin_Continue;
}

void PreRestartActions()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsFakeClient(i) )
		{
			KickClient(i);
		}
	}
	
	FreezeAll();
	UnloadAccelerator();
	UnloadPluginsExcludeMe();
	
	MsgRestart(g_hCvarActionDelay.IntValue);
}

void KickAll()
{
	g_ConVarHibernate.SetInt(0);
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			KickClient(i, "%t", "Kick_Msg");
		}
	}
}

void FreezeAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if (IsClientInGame(i) && GetClientTeam(i) != 1)
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}
	if( g_Engine == Engine_Left4Dead || g_Engine == Engine_Left4Dead2 )
	{
		ExecuteCheatCommand("director_stop");
		ExecuteCheatCommand("sb_hold_position", "1");
	}
}

void UnFreezeAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) != 1 )
		{
			SetEntityMoveType(i, MOVETYPE_WALK);
		}
	}
	if( g_Engine == Engine_Left4Dead || g_Engine == Engine_Left4Dead2 )
	{
		ExecuteCheatCommand("director_start");
		ExecuteCheatCommand("sb_hold_position", "0");
	}
}

void UnloadPluginsExcludeMe()
{
	char buffer[64];
	Handle pl;
	Handle iter = GetPluginIterator();
	
	if( iter )
	{
		while( MorePlugins(iter) )
		{
			pl = ReadPlugin(iter);
			
			if( pl != hPluginMe )
			{
				GetPluginFilename(pl, buffer, sizeof(buffer));
				ServerCommand("sm plugins unload \"%s\"", buffer);
				ServerExecute();
			}
		}
		CloseHandle(iter);
	}
}

void UnloadAccelerator()
{
	if( g_hCvarUnloadExtNum.IntValue )
	{
		ServerCommand("sm exts unload %i 0", g_hCvarUnloadExtNum.IntValue);
	}
}

bool HasVoteAccess(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	
	static char sSteam[64];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
	
	char sReq[32];
	g_hCvarAccessFlag.GetString(sReq, sizeof(sReq));
	if( sReq[0] == 0 ) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return( iUserFlag & iReqFlags != 0 );
}

void LogVoteAction(int client, const char[] format, any ...)
{
	if( !g_hCvarLog.BoolValue )
		return;
	
	static char sSteam[64];
	static char sIP[32];
	static char sCountry[4];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if( client ) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		GeoipCode3(sIP, sCountry);
		LogToFileEx(g_sLog, "%s %s (%s | [%s] %s)", buffer, sName, sSteam, sCountry, sIP);
	}
	else {
		LogToFileEx(g_sLog, buffer);
	}
}

stock char[] Translate(int client, const char[] format, any ...)
{
	static char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    static char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintToConsoleAll(const char[] format, any ...)
{
    static char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToConsole(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
    static char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

void ExecuteCheatCommand(const char[] command, const char[] value = "")
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	ServerCommand("%s %s", command, value);
	ServerExecute();
	SetCommandFlags(command, flags | GetCommandFlags(command));
}