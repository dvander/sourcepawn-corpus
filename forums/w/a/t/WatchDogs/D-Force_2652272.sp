#pragma semicolon 1

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "2.0.0"

#include <sourcemod>

#pragma newdecls required

ConVar g_cImmuneAdmins;
ConVar g_cKickFailed;
ConVar g_cPunishMode;
ConVar g_cPunishInterval;
ConVar g_cPunishKickAfter;
ConVar g_cDownloadFilter;
ConVar g_cAllowUpload;
ConVar g_cAllowDownload;

char sDownloadFilter[32];
char sAllowUpload[8];
char sAllowDownload[8];

int iPunishMode = 1;
float fPunishInterval = 5.0;
float fPunishKickAfter = 120.0;

bool bKickFailed = false;
bool bImmuneAdmins = true;

float fClientTime[MAXPLAYERS + 1];

bool bJoinTeam_DF[MAXPLAYERS + 1];
bool bJoinTeam_AU[MAXPLAYERS + 1];
bool bJoinTeam_AD[MAXPLAYERS + 1];

Handle g_hClientTimer[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[ANY] D-Force (Download Enforcer)", 
	author = PLUGIN_AUTHOR, 
	description = "Forces players to download all download-table files before entering game", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?p=2652272"
};

public void OnPluginStart()
{
	AddCommandListener(CMD_JoinTeam, "jointeam");
	
	g_cImmuneAdmins = CreateConVar("dforce_immune_admins", "1", "Enable/Disable admin immunity for forcing downloads", _, true, 0.0, true, 1.0);
	g_cKickFailed = CreateConVar("dforce_kick_failed", "0", "Enable/Disable kicking the player if convar query failed", _, true, 0.0, true, 1.0);
	g_cPunishMode = CreateConVar("dforce_punish_mode", "1", "| 1 = Kick on connect \n| 2 = Send message every X seconds, Kick after Y minutes \n| 3 = Not allowed to join a team", _, true, 0.0, true, 3.0);
	g_cPunishInterval = CreateConVar("dforce_punish_interval", "5.0", "(Works only if dforce_punish_mode = 2) - Interval between messages in seconds", _, true, 1.0);
	g_cPunishKickAfter = CreateConVar("dforce_punish_kickafter", "120", "(Works only if dforce_punish_mode = 2) - The time in seconds to kick the player with wrong cvar value", _, true, 2.0);
	g_cDownloadFilter = CreateConVar("dforce_cl_downloadfilter", "all,nosounds", "Value(s) that the player is allowed to set for cl_downloadfilter ('all' or 'mapsonly' or 'nosounds' or 'none) - Separate with comma for multiple allowed values");
	g_cAllowUpload = CreateConVar("dforce_sv_allowupload", "1", "Value(s) that the player is allowed to set for sv_allowupload (0 or 1) - Separate with comma for multiple allowed values");
	g_cAllowDownload = CreateConVar("dforce_cl_allowdownload", "1", "Value(s) that the player is allowed to set for cl_allowdownload (0 or 1) - Separate with comma for multiple allowed values");
	
	HookConVarChange(g_cImmuneAdmins, ConVar_Changed);
	HookConVarChange(g_cKickFailed, ConVar_Changed);
	HookConVarChange(g_cPunishMode, ConVar_Changed);
	HookConVarChange(g_cPunishInterval, ConVar_Changed);
	HookConVarChange(g_cPunishKickAfter, ConVar_Changed);
	HookConVarChange(g_cDownloadFilter, ConVar_Changed);
	HookConVarChange(g_cAllowDownload, ConVar_Changed);
	HookConVarChange(g_cAllowUpload, ConVar_Changed);
	
	AutoExecConfig(true, "D-Force");
	UpdateAllConVars();
}

public void OnAllPluginsLoaded()
{
	PrintToServer("D-Force (Download Enforcer) - %s by [W]atch [D]ogs has been loaded.", PLUGIN_VERSION);
}

public void ConVar_Changed(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	UpdateAllConVars();
}


public Action CMD_JoinTeam(int client, const char[] command, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (!bJoinTeam_DF[client])
		{
			PrintToChat(client, "\x04[D-Force] \x03You can't join the game! You are using wrong cvar value \x04(cl_downloadfilter)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", sDownloadFilter);
			return Plugin_Handled;
		}
		if (!bJoinTeam_AU[client])
		{
			PrintToChat(client, "\x04[D-Force] \x03You can't join the game! You are using wrong cvar value \x04(sv_allowupload)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", sAllowUpload);
			return Plugin_Handled;
		}
		if (!bJoinTeam_AD[client])
		{
			PrintToChat(client, "\x04[D-Force] \x03You can't join the game! You are using wrong cvar value \x04(cl_allowdownload)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", sAllowDownload);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


public void OnClientPostAdminCheck(int client)
{
	fClientTime[client] = 0.0;
	bJoinTeam_DF[client] = true;
	bJoinTeam_AU[client] = true;
	bJoinTeam_AD[client] = true;
	g_hClientTimer[client] = INVALID_HANDLE;
	
	if (!IsFakeClient(client))
	{
		if (bImmuneAdmins && GetUserAdmin(client) != INVALID_ADMIN_ID)
			return;
		
		QueryClientConVar(client, "sv_allowupload", OnQueryFinished, GetClientSerial(client));
		QueryClientConVar(client, "cl_allowdownload", OnQueryFinished, GetClientSerial(client));
		QueryClientConVar(client, "cl_downloadfilter", OnQueryFinished, GetClientSerial(client));
	}
}

public void OnClientDisconnect(int client)
{
	fClientTime[client] = 0.0;
	bJoinTeam_DF[client] = true;
	bJoinTeam_AU[client] = true;
	bJoinTeam_AD[client] = true;
	g_hClientTimer[client] = INVALID_HANDLE;
}

public int OnQueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any serial)
{
	if (GetClientFromSerial(serial) == client && IsClientInGame(client))
	{
		if (result == ConVarQuery_Okay)
		{
			if (iPunishMode == 1) // Kick The Client
			{
				if (StrEqual(cvarName, "cl_allowdownload") && StrContains(sAllowDownload, cvarValue, false) == -1)
				{
					KickClient(client, "[D-Force] Sorry, You are using wrong cvar value (cl_allowdownload %s). Allowed value(s): %s", cvarValue, sAllowDownload);
				}
				if (StrEqual(cvarName, "sv_allowupload") && StrContains(sAllowUpload, cvarValue, false) == -1)
				{
					KickClient(client, "[D-Force] Sorry, You are using wrong cvar value (sv_allowupload %s). Allowed value(s): %s", cvarValue, sAllowUpload);
				}
				if (StrEqual(cvarName, "cl_downloadfilter") && StrContains(sDownloadFilter, cvarValue, false) == -1)
				{
					KickClient(client, "[D-Force] Sorry, You are using wrong cvar value (cl_downloadfilter %s). Allowed value(s): %s", cvarValue, sDownloadFilter);
				}
			}
			if (iPunishMode == 2) // Send Message Every X Seconds, Then kick after Y seconds
			{
				if (StrEqual(cvarName, "cl_allowdownload") && StrContains(sAllowDownload, cvarValue, false) == -1)
				{
					PrintToChat(client, "\x04[D-Force] \x03WARNING! You are using wrong cvar value \x04(cl_allowdownload %s)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", cvarValue, sAllowDownload);
					if (g_hClientTimer[client] == INVALID_HANDLE)
					{
						DataPack hPack;
						g_hClientTimer[client] = CreateDataTimer(fPunishInterval, Timer_RepeatMessage, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
						WritePackCell(hPack, GetClientUserId(client));
						WritePackString(hPack, cvarName);
						WritePackString(hPack, cvarValue);
						
					}
				}
				if (StrEqual(cvarName, "sv_allowupload") && StrContains(sAllowUpload, cvarValue, false) == -1)
				{
					PrintToChat(client, "\x04[D-Force] \x03WARNING! You are using wrong cvar value \x04(sv_allowupload %s)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", cvarValue, sAllowUpload);
					if (g_hClientTimer[client] == INVALID_HANDLE)
					{
						DataPack hPack;
						g_hClientTimer[client] = CreateDataTimer(fPunishInterval, Timer_RepeatMessage, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
						WritePackCell(hPack, GetClientUserId(client));
						WritePackString(hPack, cvarName);
						WritePackString(hPack, cvarValue);
					}
				}
				if (StrEqual(cvarName, "cl_downloadfilter") && StrContains(sDownloadFilter, cvarValue, false) == -1)
				{
					PrintToChat(client, "\x04[D-Force] \x03WARNING! You are using wrong cvar value \x04(cl_downloadfilter %s)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", cvarValue, sDownloadFilter);
					if (g_hClientTimer[client] == INVALID_HANDLE)
					{
						DataPack hPack;
						g_hClientTimer[client] = CreateDataTimer(fPunishInterval, Timer_RepeatMessage, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
						WritePackCell(hPack, GetClientUserId(client));
						WritePackString(hPack, cvarName);
						WritePackString(hPack, cvarValue);
					}
				}
			}
			if (iPunishMode == 3) // Not allowed to join team
			{
				if (StrEqual(cvarName, "cl_allowdownload") && StrContains(sAllowDownload, cvarValue, false) == -1)
				{
					bJoinTeam_AD[client] = false;
					PrintToChat(client, "\x04[D-Force] \x03You can't join the game! You are using wrong cvar value \x04(cl_allowdownload %s)\x03. Allowed value(s): \x04%s \x03(Set & ReJoin)", cvarValue, sAllowDownload);
				}
				if (StrEqual(cvarName, "sv_allowupload") && StrContains(sAllowUpload, cvarValue, false) == -1)
				{
					bJoinTeam_AU[client] = false;
					PrintToChat(client, "\x04[D-Force] \x03You can't join the game! You are using wrong cvar value \x04(sv_allowupload %s)\x03. Allowed value(s): \x04%s \x03(Set & ReJoin)", cvarValue, sAllowUpload);
				}
				if (StrEqual(cvarName, "cl_downloadfilter") && StrContains(sDownloadFilter, cvarValue, false) == -1)
				{
					bJoinTeam_DF[client] = false;
					PrintToChat(client, "\x04[D-Force] \x03You can't join the game! You are using wrong cvar value \x04(cl_downloadfilter %s)\x03. Allowed value(s): \x04%s \x03(Set & ReJoin)", cvarValue, sDownloadFilter);
				}
			}
		}
		else if (bKickFailed)
			KickClient(client, "[D-Force] Sorry, Your client doesn't respond to queries. Please try restarting game and rejoin.");
	}
}


public Action Timer_RepeatMessage(Handle timer, any hPack)
{
	ResetPack(hPack);
	
	int userid = ReadPackCell(hPack);
	
	char cvarName[32];
	char cvarValue[32];
	ReadPackString(hPack, cvarName, sizeof(cvarName));
	ReadPackString(hPack, cvarValue, sizeof(cvarValue));

	int client = GetClientOfUserId(userid);
	if (client < 1 || !IsClientInGame(client))
		return Plugin_Stop;
	
	fClientTime[client] += fPunishInterval;
	
	if (StrEqual(cvarName, "cl_allowdownload"))
	{
		PrintToChat(client, "\x04[D-Force] \x03WARNING! You are using wrong cvar value \x04(cl_allowdownload %s)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", cvarValue, sAllowDownload);
	}
	if (StrEqual(cvarName, "sv_allowupload"))
	{
		PrintToChat(client, "\x04[D-Force] \x03WARNING! You are using wrong cvar value \x04(sv_allowupload %s)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", cvarValue, sAllowUpload);
	}
	if (StrEqual(cvarName, "cl_downloadfilter"))
	{
		PrintToChat(client, "\x04[D-Force] \x03WARNING! You are using wrong cvar value \x04(cl_downloadfilter %s)\x03. Allowed value(s): \x04%s \x03(Please set and rejoin)", cvarValue, sDownloadFilter);
	}
	
	if (fClientTime[client] >= fPunishKickAfter)
	{
		if (StrEqual(cvarName, "cl_allowdownload"))
		{
			KickClient(client, "[D-Force] Sorry, You are using wrong (cl_allowdownload %s) cvar value. Allowed value(s): %s", cvarValue, sAllowDownload);
		}
		if (StrEqual(cvarName, "sv_allowupload"))
		{
			KickClient(client, "[D-Force] Sorry, You are using wrong (sv_allowupload %s) cvar value. Allowed value(s): %s", cvarValue, sAllowUpload);
		}
		if (StrEqual(cvarName, "cl_downloadfilter"))
		{
			KickClient(client, "[D-Force] Sorry, You are using wrong (cl_downloadfilter %s) cvar value. Allowed value(s): %s", cvarValue, sDownloadFilter);
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}


stock void UpdateAllConVars()
{
	GetConVarString(g_cDownloadFilter, sDownloadFilter, sizeof(sDownloadFilter));
	GetConVarString(g_cAllowDownload, sAllowDownload, sizeof(sAllowDownload));
	GetConVarString(g_cAllowUpload, sAllowUpload, sizeof(sAllowUpload));
	iPunishMode = GetConVarInt(g_cPunishMode);
	bKickFailed = GetConVarBool(g_cKickFailed);
	bImmuneAdmins = GetConVarBool(g_cImmuneAdmins);
	fPunishKickAfter = GetConVarFloat(g_cPunishKickAfter);
	fPunishInterval = GetConVarFloat(g_cPunishInterval);
}
