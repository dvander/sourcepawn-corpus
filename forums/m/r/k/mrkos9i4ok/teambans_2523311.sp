/*

	- Add native for unban
	- Add native for offline ban
	- Add native for offline unban
	
	- (TODO: Need test) Sollte ein Spieler von ein Team gebannt worden sein, und dann vom anderen Team ebenfalls gebannt wird, so wird der letzte Ban in ein Server Ban verwandelt

*/

#pragma semicolon 1

// Core
#include <sourcemod>
#include <cstrike>
#include <adminmenu>
#include <topmenus>

#pragma newdecls required

// Includes
#include <multicolors>
#include <teambans>

// Include all .sp-files from teambans-folder
#include "teambans/globals.sp"
#include "teambans/log.sp"
#include "teambans/cvars.sp"
#include "teambans/stocks.sp"
#include "teambans/commands.sp"
#include "teambans/functions.sp"
#include "teambans/timer.sp"
#include "teambans/callbacks.sp"
#include "teambans/sql.sp"
#include "teambans/adminmenu.sp"
#include "teambans/natives.sp"

public Plugin myinfo =
{
	name = TEAMBANS_PLUGIN_NAME,
	author = TEAMBANS_PLUGIN_AUTHOR,
	version = TEAMBANS_PLUGIN_VERSION,
	description = TEAMBANS_PLUGIN_DESCRIPTION,
	url = TEAMBANS_PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("teambans");
	
	CreateNatives();
	CreateForwards();
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		TB_LogFile(ERROR, "Only CS:GO support");
		SetFailState("Only CS:GO support");
		return;
	}
	
	BuildPath(Path_SM, g_sReasonsPath, sizeof(g_sReasonsPath), "configs/teambans/reasons.cfg");
	CheckReasonsFile();
	
	BuildPath(Path_SM, g_sLengthPath, sizeof(g_sLengthPath), "configs/teambans/length.cfg");
	CheckLengthFile();
	
	SQL_OnPluginStart();
	Cvar_OnPluginStart();
	
	RegConsoleCmd("sm_teambans", Command_TeamBans);
	
	
	RegAdminCmd("sm_ctban", Command_Ban, ADMFLAG_BAN, "Online");
	RegAdminCmd("sm_ctoban",  Command_OBan,  ADMFLAG_BAN, "Offline");
	
	RegAdminCmd("sm_ctunban", Command_UnBan, ADMFLAG_UNBAN, "Online");
	RegAdminCmd("sm_ctounban", Command_OUnBan, ADMFLAG_UNBAN, "Offline");
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	LoadTranslations("teambans.phrases");

	LoadTranslations("common.phrases");
	
	CheckAllClients();
	
}

public void OnMapStart()
{
	CheckReasonsFile();
	CheckLengthFile();
}

public void OnClientConnected(int client)
{
	ResetVars(client);
}

public void OnClientDisconnect(int client)
{
	ResetVars(client);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	g_iPlayer[client][clientAuth] = true;
	g_iPlayer[client][clientID] = client;
	
	if (g_dDB == null)
		return;
	
	CheckTeamBans(client);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsClientValid(client) || !g_iPlayer[client][clientReady])
		return;
	
	IsAndMoveClient(client, TeamBans_GetClientTeam(client));
}
