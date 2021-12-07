#define PLUGIN_VERSION "1.3"

#pragma semicolon 1
#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <adminmenu>
#include <autoexecconfig>

new Handle:hTopMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "TOGs Jump Stats v1.3",
	author = "That One Guy",
	description = "Player bhop method detection.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"	
}

//General variables
new aiJumps[MAXPLAYERS+1] = {0, ...};
new Float:afAvgJumps[MAXPLAYERS+1] = {1.0, ...};
new Float:afAvgSpeed[MAXPLAYERS+1] = {250.0, ...};
new Float:avVEL[MAXPLAYERS+1][3];
new aiPattern[MAXPLAYERS+1] = {0, ...};
new aiPatternhits[MAXPLAYERS+1] = {0, ...};
new Float:avLastPos[MAXPLAYERS+1][3];
new aiAutojumps[MAXPLAYERS+1] = {0, ...};
new aaiLastJumps[MAXPLAYERS+1][30];
new Float:afAvgPerfJumps[MAXPLAYERS+1] = {0.3333, ...};
new iTickCount = 1;
new aiIgnoreCount[MAXPLAYERS+1];
new String:hyppath[PLATFORM_MAX_PATH];
new String:hackspath[PLATFORM_MAX_PATH];
new String:patpath[PLATFORM_MAX_PATH];
new bool:bFlagged[MAXPLAYERS+1];
new bool:bFlagHypCurrentRound[MAXPLAYERS+1];
new bool:bFlagHypLastRound[MAXPLAYERS+1];
new bool:bFlagHypTwoRoundsAgo[MAXPLAYERS+1];
new bool:bSurfCheck[MAXPLAYERS+1];
new aiLastPos[MAXPLAYERS+1] = {0, ...};
new iDisableAdminMsgs = 0;
new iNumberJumpsAbove[MAXPLAYERS+1];
new bool:bNotificationsPaused[MAXPLAYERS+1] = {false, ...};

new Handle:hPauseTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new	Handle:hEnableAdmNotifications = INVALID_HANDLE;
new iEnableAdmNotifications;

new	Handle:hEnableLogs = INVALID_HANDLE;
new iEnableLogs;

new	Handle:hReqMultRoundsHyp = INVALID_HANDLE;
new iReqMultRoundsHyp;

new	Handle:hAboveNumber = INVALID_HANDLE;
new iAboveNumber;

new	Handle:hAboveNumberFlags = INVALID_HANDLE;
new iAboveNumberFlags;

new	Handle:hHypPerf = INVALID_HANDLE;
new Float:fHypPerf;

new	Handle:hHacksPerf = INVALID_HANDLE;
new Float:fHacksPerf;

new	Handle:hCooldown = INVALID_HANDLE;
new Float:fCooldown;

public OnPluginStart()
{   
	LoadTranslations("common.phrases");
	
	AutoExecConfig_SetFile("togsjumpstats");
	AutoExecConfig_CreateConVar("tjs_version", PLUGIN_VERSION, "TOGs Jump Stats Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	hCooldown = AutoExecConfig_CreateConVar("tjs_cooldown", "75", "Cooldown time between chat notifications to admins for any given clients that is flagged.", FCVAR_NONE, true, 0.0);
	HookConVarChange(hCooldown, OnCVarChange);
	fCooldown = float(GetConVarInt(hCooldown));
	
	hEnableAdmNotifications = AutoExecConfig_CreateConVar("tjs_admin_notifications", "1", "Enable admin chat notifications when a player is flagged (0 = Disabled, 1 = Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableAdmNotifications, OnCVarChange);
	iEnableAdmNotifications = GetConVarInt(hEnableAdmNotifications);
	
	hEnableLogs = AutoExecConfig_CreateConVar("tjs_log", "1", "Enable logging player jump stats if a player is flagged (0 = Disabled, 1 = Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableLogs, OnCVarChange);
	iEnableLogs = GetConVarInt(hEnableLogs);
	
	hReqMultRoundsHyp = AutoExecConfig_CreateConVar("tjs_mult_rounds_hyp", "1", "Clients will not be flagged (in logs and admin notifications) for hyperscrolling until they are noted 4 rounds in a row (0 = Disabled, 1 = Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hReqMultRoundsHyp, OnCVarChange);
	iReqMultRoundsHyp = GetConVarInt(hReqMultRoundsHyp);
	
	hAboveNumber = AutoExecConfig_CreateConVar("tjs_numjumps", "14", "Number of jump commands to use as a threshold for flagging hyperscrollers.", FCVAR_NONE, true, 1.0);
	HookConVarChange(hAboveNumber, OnCVarChange);
	iAboveNumber = GetConVarInt(hAboveNumber);

	hAboveNumberFlags = AutoExecConfig_CreateConVar("tjs_numflags", "13", "Out of the last 30 jumps, the number of jumps that must be above tjs_numjumps to flag player for hyperscrolling.", FCVAR_NONE, true, 1.0);
	HookConVarChange(hAboveNumberFlags, OnCVarChange);
	iAboveNumberFlags = GetConVarInt(hAboveNumberFlags);

	hHacksPerf = AutoExecConfig_CreateConVar("tjs_perf", "0.9", "Above this perf ratio (between 0.0 - 1.0), players will be flagged for hacks.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hHacksPerf, OnCVarChange);
	fHacksPerf = GetConVarFloat(hHacksPerf);
	
	hHypPerf = AutoExecConfig_CreateConVar("tjs_hyp_perf", "0.4", "Above this perf ratio (in combination with the other hyperscroll cvars), players will be flagged for hyperscrolling.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hHypPerf, OnCVarChange);
	fHypPerf = GetConVarFloat(hHypPerf);
	
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
	
	BuildPath(Path_SM, hyppath, sizeof(hyppath), "logs/togsjumpstats/hyperscrollers.log");
	BuildPath(Path_SM, hackspath, sizeof(hackspath), "logs/togsjumpstats/hacks.log");
	BuildPath(Path_SM, patpath, sizeof(patpath), "logs/togsjumpstats/patterns.log");

	RegAdminCmd("sm_jumps", Command_Jumps, ADMFLAG_BAN, "Gives statistics for player jumps.");
	RegAdminCmd("sm_jumpsall", Command_JumpsAll, ADMFLAG_BAN, "Gives statistics for all players jumps.");
	RegAdminCmd("sm_stopmsgs", Command_StopAdminMsgs, ADMFLAG_BAN, "Stops admin chat notifications when players are flagged for current map.");
	RegAdminCmd("sm_enablemsgs", Command_EnableAdminMsgs, ADMFLAG_BAN, "Re-enables admin chat notifications when players are flagged.");
	RegAdminCmd("sm_msgstatus", Command_MsgStatus, ADMFLAG_BAN, "Check enabled/disabled status of admin chat notifications.");
	RegAdminCmd("sm_resetjumps", Command_ResetJumps, ADMFLAG_BAN, "Reset statistics for a player.");
	RegAdminCmd("sm_resetjumpsall", Command_ResetJumpsAll, ADMFLAG_BAN, "Reset statistics for a player.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
		hTopMenu = INVALID_HANDLE;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(iReqMultRoundsHyp)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(bFlagHypLastRound[i])
			{
				bFlagHypTwoRoundsAgo[i] = true;
			}
			else
			{
				bFlagHypTwoRoundsAgo[i] = false;
			}
			
			if(bFlagHypCurrentRound[i])
			{
				bFlagHypLastRound[i] = true;
			}
			else
			{
				bFlagHypLastRound[i] = false;
			}
			
			bFlagHypCurrentRound[i] = false;
		}
	}
}

public OnClientPutInServer(client)
{
	bNotificationsPaused[client] = false;
	bFlagged[client] = false;
}

public Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	afAvgJumps[client] = ( afAvgJumps[client] * 9.0 + float(aiJumps[client]) ) / 10.0;
	
	decl Float:vec_vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_vel);
	vec_vel[2] = 0.0;
	new Float:speed = GetVectorLength(vec_vel);
	afAvgSpeed[client] = (afAvgSpeed[client] * 9.0 + speed) / 10.0;
	
	aaiLastJumps[client][aiLastPos[client]] = aiJumps[client];
	aiLastPos[client]++;
	if (aiLastPos[client] == 30)
	{
		aiLastPos[client] = 0;
	}
	
	if (afAvgJumps[client] > 15.0)
	{
		if ((aiPatternhits[client] > 0) && (aiJumps[client] == aiPattern[client]))
		{
			aiPatternhits[client]++;
			if (aiPatternhits[client] > 15)
			{
				if(!bNotificationsPaused[client])
				{
					if(!bFlagged[client])
					{
						LogFlag(client, "pattern jumps");
					}
					if(!iDisableAdminMsgs && iEnableAdmNotifications)
					{
						NotifyAdmins(client, "Pattern Jumps");
					}
				}
			}
		}
		else if ((aiPatternhits[client] > 0) && (aiJumps[client] != aiPattern[client]))
		{
			aiPatternhits[client] -= 2;
		}
		else
		{
			aiPattern[client] = aiJumps[client];
			aiPatternhits[client] = 2;
		}
	}
	
	if(afAvgJumps[client] > 14.0)
	{
		//check if more than 8 of the last 30 jumps were above 12
		iNumberJumpsAbove[client] = 0;
		
		for (new i = 0; i < 29; i++)	//count
		{
			if((aaiLastJumps[client][i]) > (iAboveNumber - 1))	//threshhold for # jump commands
			{
				iNumberJumpsAbove[client]++;
			}
		}
		if((iNumberJumpsAbove[client] > (iAboveNumberFlags - 1)) && (afAvgPerfJumps[client] >= fHypPerf))	//if more than #
		{
			if(!bNotificationsPaused[client])
			{
				if(iReqMultRoundsHyp)
				{
					if(bFlagHypTwoRoundsAgo[client] && bFlagHypLastRound[client])
					{
						if(!bFlagged[client])
						{
							LogFlag(client, "hyperscroll (3 rounds in a row)");
						}
						if(!iDisableAdminMsgs && iEnableAdmNotifications)
						{
							NotifyAdmins(client, "Hyperscroll (3 rounds in a row)");
						}
					}
					else
					{
						bFlagHypCurrentRound[client] = true;
					}	
				}
				else
				{
					if(!bFlagged[client])
					{
						LogFlag(client, "hyperscroll");
					}
					if(!iDisableAdminMsgs && iEnableAdmNotifications)
					{
						NotifyAdmins(client, "Hyperscroll");
					}
				}
			}
		}
	}
	else if(aiJumps[client] > 1)
	{
		aiAutojumps[client] = 0;
	}

	aiJumps[client] = 0;
	new Float:tempvec[3];
	tempvec = avLastPos[client];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", avLastPos[client]);
	
	new Float:len = GetVectorDistance(avLastPos[client], tempvec, true);
	if (len < 30.0)
	{   
		aiIgnoreCount[client] = 2;
	}
	
	if (afAvgPerfJumps[client] >= fHacksPerf)
	{
		if(!bNotificationsPaused[client])
		{
			if(!bFlagged[client])
			{
				LogFlag(client, "hacks");
			}
			if(!iDisableAdminMsgs && iEnableAdmNotifications)
			{
				NotifyAdmins(client, "Hacks");
			}
		}
	}
}

public Action:Command_StopAdminMsgs(client, args)
{
	StopMsgs(client);
	
	return Plugin_Handled;
}

public Action:Command_MsgStatus(client, args)
{
	if(iDisableAdminMsgs)
	{
		ReplyToCommand(client, "Admin chat notifications for flagged players is currently disabled!");
	}
	else
	{
		ReplyToCommand(client, "Admin chat notifications for flagged players is currently enabled.");
	}
	
	return Plugin_Handled;
}

StopMsgs(any:client)
{
	iDisableAdminMsgs = 1;
	decl String:sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "sm_ban", ADMFLAG_BAN, true) && !IsFakeClient(i))
		{
			if(i > 0)
			{
				CPrintToChat(i, "\x07FF0000%s \x07FF6600has disabled admin notices for bhop cheats until map changes!", sName);
			}
		}
	}
}

EnableMsgs(any:client)
{
	iDisableAdminMsgs = 0;
	decl String:sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "sm_ban", ADMFLAG_BAN, true) && !IsFakeClient(i))
		{
			if(i > 0)
			{
				CPrintToChat(i, "\x07FF0000%s \x07FF6600has re-enabled admin notices for bhop cheats!", sName);
			}
		}
	}
}

public Action:Command_EnableAdminMsgs(client, args)
{
	EnableMsgs(client);
	
	return Plugin_Handled;
}

public Action:Command_JumpsAll(client, args)
{
	StatsAll(client);
	
	return Plugin_Handled;
}

StatsAll(client)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(!IsFakeClient(i))
			{
				PerformStats(client, i);
			}
		}
	}
	
	if(client > 0)
	{
		PrintToChat(client, "[TOGs Jump Stats] Check console for output!");
	}
}

public OnMapStart()
{
	iDisableAdminMsgs = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			bNotificationsPaused[i] = false;
			bFlagHypCurrentRound[i] = false;
			bFlagHypLastRound[i] = false;
			bFlagHypTwoRoundsAgo[i] = false;
		}
	}
}

NotifyAdmins(any:client, String:string[])
{
	decl String:sName[32];
	GetClientName(client, sName, sizeof(sName));
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "sm_ban", ADMFLAG_KICK, true) && !IsFakeClient(i))
		{
			if(i > 0)
			{
				CPrintToChat(i, "[TOGs Jump Stats] \x07FF0000'%s' \x07FF6600has been flagged for '%s'! Please check their jump stats!", sName, string);
			}
		}
	}
	
	bNotificationsPaused[client] = true;
	hPauseTimer[client] = CreateTimer(fCooldown, UnPause_TimerMonitor, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:UnPause_TimerMonitor(Handle:timer, any:client)
{
	hPauseTimer[client] = INVALID_HANDLE;
	bNotificationsPaused[client] = false;
	
	return Plugin_Continue;
}

public OnMapEnd()
{
	KillAllTimers();
}

public OnPluginEnd()
{
	KillAllTimers();
}

KillAllTimers()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(hPauseTimer[i] != INVALID_HANDLE)
		{
			KillTimer(hPauseTimer[i]);
			hPauseTimer[i] = INVALID_HANDLE;
		}
	}
}

public OnClientDisconnect(client)
{
	aiJumps[client] = 0;
	afAvgJumps[client] = 5.0;
	afAvgSpeed[client] = 250.0;
	afAvgPerfJumps[client] = 0.3333;
	aiPattern[client] = 0;
	aiPatternhits[client] = 0;
	aiAutojumps[client] = 0;
	aiIgnoreCount[client] = 0;
	bFlagged[client] = false;
	avVEL[client][2] = 0.0;
	new i;
	while (i < 30)
	{
		aaiLastJumps[client][i] = 0;
		i++;
	}
}

public OnGameFrame()
{
	if (iTickCount > 1*MaxClients)
	{
		iTickCount = 1;
	}
	else
	{
		if (iTickCount % 1 == 0)
		{
			new index = iTickCount / 1;
			if (bSurfCheck[index] && IsClientInGame(index) && IsPlayerAlive(index))
			{	
				GetEntPropVector(index, Prop_Data, "m_vecVelocity", avVEL[index]);
				if (avVEL[index][2] < -290)
				{
					aiIgnoreCount[index] = 2;
				}
				
			}
		}
		iTickCount++;
	}
}

LogFlag(client, const String:type[])
{
	new String:uid[64];
	GetClientAuthString(client, uid, sizeof(uid));
	new String:playerstats[256];
	GetClientStats(client, playerstats, sizeof(playerstats));
	if(iEnableLogs)
	{
		if(StrEqual(type, "hacks", false))
		{
			LogToFileEx(hackspath, "%s %s", playerstats, type);
		}
		else if(StrEqual(type, "pattern jumps", false))
		{
			LogToFileEx(patpath, "%s %s", playerstats, type);
		}
		else if(StrEqual(type, "hyperscroll", false) || StrEqual(type, "hyperscroll (3 rounds in a row)", false))
		{
			LogToFileEx(hyppath, "%s %s", playerstats, type);
		}
	}
	bFlagged[client] = true;
}

public Action:Command_Jumps(client, args)
{
	new target;

	if (args == 1)
	{
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		
		if(StrEqual(arg, "@all", false))
		{
			StatsAll(client);
			return Plugin_Handled;
		}
		else
		{
			target = FindTarget(client, arg, true, false);
			if(target == -1)
			{
				ReplyToCommand(client, "[TOGs Jump Stats] Target not found!");
				return Plugin_Handled;
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[TOGs Jump Stats] Usage: sm_jumps <#userid|name|@all>");
		return Plugin_Handled;
	}
	
	if(IsClientInGame(target))
	{
		if(!IsFakeClient(target))
		{
			PerformStats(client, target);
		}
	}

	if(client > 0)
	{
		PrintToChat(client, "[TOGs Jump Stats] Check console for output!");
	}

	return Plugin_Handled;
}

public Action:Command_ResetJumps(client, args)
{
	new target;

	if (args == 1)
	{
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		
		if(StrEqual(arg, "@all", false))
		{
			ResetJumpsAll();
			return Plugin_Handled;
		}
		else
		{
			target = FindTarget(client, arg, true, false);
			if(target == -1)
			{
				ReplyToCommand(client, "[TOGs Jump Stats] Target not found!");
				return Plugin_Handled;
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[TOGs Jump Stats] Usage: sm_resetjumps <#userid|name|@all>");
		return Plugin_Handled;
	}
	
	if(IsClientInGame(target))
	{
		if(!IsFakeClient(target))
		{
			ResetJumps(target);
		}
	}
	
	decl String:sName[MAX_NAME_LENGTH];
	GetClientName(target, sName, sizeof(sName));

	if(client > 0)
	{
		PrintToChat(client, "[TOGs Jump Stats] Stats are now reset for player '%s'.", sName);
	}
	else
	{
		PrintToServer("[TOGs Jump Stats] Stats are now reset for player '%s'.", sName);
	}

	return Plugin_Handled;
}

public Action:Command_ResetJumpsAll(client, args)
{
	ResetJumpsAll();

	if(client > 0)
	{
		PrintToChat(client, "[TOGs Jump Stats] Stats are now reset for all players!");
	}
	else
	{
		PrintToServer("[TOGs Jump Stats] Stats are now reset for all players!");
	}

	return Plugin_Handled;
}

ResetJumps(target)
{
	for (new i = 0; i < 29; i++)
	{
		aaiLastJumps[target][i] = 0;
	}
}

ResetJumpsAll()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(!IsFakeClient(i))
			{
				for (new j = 0; j < 29; j++)
				{
					aaiLastJumps[i][j] = 0;
				}
			}
		}
	}
}

PerformStats(client, target)
{
	new String:playerstats[300];
	GetClientStats(target, playerstats, sizeof(playerstats));
	PrintToConsole(client, "Flagged: %d || %s", bFlagged[target], playerstats);
}

GetClientStats(client, String:string[], length)
{
	new Float:origin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
	new String:map[128];
	GetCurrentMap(map, sizeof(map));
	Format(string, length, "Perf: %f || Avg: %f/%f || %L || Map: %s || Last: %i %i %i",
	afAvgPerfJumps[client],
	afAvgJumps[client],
	afAvgSpeed[client], client,
	map,
	aaiLastJumps[client][0],
	aaiLastJumps[client][1],
	aaiLastJumps[client][2]);
	Format(string, length, "%s %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	string,
	aaiLastJumps[client][3],
	aaiLastJumps[client][4],
	aaiLastJumps[client][5],
	aaiLastJumps[client][6],
	aaiLastJumps[client][7],
	aaiLastJumps[client][8],
	aaiLastJumps[client][9],
	aaiLastJumps[client][10],
	aaiLastJumps[client][11],
	aaiLastJumps[client][12],
	aaiLastJumps[client][13],
	aaiLastJumps[client][14],
	aaiLastJumps[client][15],
	aaiLastJumps[client][16],
	aaiLastJumps[client][17],
	aaiLastJumps[client][18],
	aaiLastJumps[client][19],
	aaiLastJumps[client][20],
	aaiLastJumps[client][21],
	aaiLastJumps[client][22],
	aaiLastJumps[client][23],
	aaiLastJumps[client][24],
	aaiLastJumps[client][25],
	aaiLastJumps[client][26],
	aaiLastJumps[client][27],
	aaiLastJumps[client][28],
	aaiLastJumps[client][29]);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsPlayerAlive(client))
	{
		static bool:bHoldingJump[MAXPLAYERS + 1];
		static bLastOnGround[MAXPLAYERS + 1];
		if(buttons & IN_JUMP)
		{
			if(!bHoldingJump[client])
			{
				bHoldingJump[client] = true;//started pressing +jump
				aiJumps[client]++;
				if (bLastOnGround[client] && (GetEntityFlags(client) & FL_ONGROUND))
				{
					afAvgPerfJumps[client] = ( afAvgPerfJumps[client] * 9.0 + 0 ) / 10.0;
				   
				}
				else if (!bLastOnGround[client] && (GetEntityFlags(client) & FL_ONGROUND))
				{
					afAvgPerfJumps[client] = ( afAvgPerfJumps[client] * 9.0 + 1 ) / 10.0;
				}
			}
		}
		else if(bHoldingJump[client]) 
		{
			bHoldingJump[client] = false;//released (-jump)
			
		}
		bLastOnGround[client] = GetEntityFlags(client) & FL_ONGROUND;  
	}
	
	return Plugin_Continue;
}

//admin menu
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	new TopMenuObject:MenuObject = AddToTopMenu(hTopMenu, "togs_jumps", TopMenuObject_Category, Handle_Commands, INVALID_TOPMENUOBJECT);
	if(MenuObject != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "sm_jumps", TopMenuObject_Item, AdminMenu_PlayerCommand, MenuObject, "sm_jumps", ADMFLAG_BAN);
		AddToTopMenu(hTopMenu, "sm_resetjumps", TopMenuObject_Item, AdminMenu_PlayerCommand2, MenuObject, "sm_resetjumps", ADMFLAG_BAN);
		AddToTopMenu(hTopMenu, "sm_jumpsall", TopMenuObject_Item, AdminMenu_JumpsAllCommand, MenuObject, "sm_jumpsall", ADMFLAG_BAN);
		AddToTopMenu(hTopMenu, "sm_resetjumpsall", TopMenuObject_Item, AdminMenu_ResetJumpsAllCommand, MenuObject, "sm_resetjumpsall", ADMFLAG_BAN);
		AddToTopMenu(hTopMenu, "sm_stopmsgs", TopMenuObject_Item, AdminMenu_StopCommand, MenuObject, "sm_stopmsgs", ADMFLAG_BAN);
		AddToTopMenu(hTopMenu, "sm_msgstatus", TopMenuObject_Item, AdminMenu_MsgStatus, MenuObject, "sm_msgstatus", ADMFLAG_BAN);
	}
}

public Handle_Commands(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "TOGs Jump Stats");
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "TOGs Jump Stats");
	}
}

public AdminMenu_StopCommand(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		if(iDisableAdminMsgs)
		{
			Format(buffer, maxlength, "Re-enable chat notifications");
		}
		else
		{
			Format(buffer, maxlength, "Stop chat messages for current map");
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if(iDisableAdminMsgs)
		{
			EnableMsgs(param);
		}
		else
		{
			StopMsgs(param);
		}
		
		RedisplayAdminMenu(topmenu, param);
	}
}

public AdminMenu_JumpsAllCommand(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Get jump stats for all players");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		StatsAll(param);
		
		RedisplayAdminMenu(topmenu, param);
	}
}

public AdminMenu_ResetJumpsAllCommand(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reset jump stats for all players");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ResetJumpsAll();

		if(param > 0)
		{
			PrintToChat(param, "[TOGs Jump Stats] Stats are now reset for all players!");
		}
		else
		{
			PrintToServer("[TOGs Jump Stats] Stats are now reset for all players!");
		}
		
		RedisplayAdminMenu(topmenu, param);
	}
}

public AdminMenu_MsgStatus(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Check admin notifications status");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		FakeClientCommand(param, "sm_msgstatus");
		
		RedisplayAdminMenu(topmenu, param);
	}
}

public AdminMenu_PlayerCommand(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Get jump stats for player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		PlayerSelectMenu(param);
	}
}

public AdminMenu_PlayerCommand2(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reset jump stats for a player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		PlayerSelectMenu2(param);
	}
}

PlayerSelectMenu(client)
{
	new Handle:smMenu = CreateMenu(PlayerSelectMenuHandler);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Get jump stats for player:", client);
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu(smMenu, client, true, false);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

PlayerSelectMenu2(client)
{
	new Handle:smMenu = CreateMenu(PlayerSelectMenuHandler2);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Reset jump stats for player:", client);
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu(smMenu, client, true, false);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

public PlayerSelectMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			if(client > 0)
			{
				PrintToChat(client, "[SM] %t", "Player no longer available");
			}
		}
		else
		{
			new UID = GetClientUserId(target);
			FakeClientCommand(client, "sm_jumps #%i", UID);
		}
	}
}

public PlayerSelectMenuHandler2(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			if(client > 0)
			{
				PrintToChat(client, "[SM] %t", "Player no longer available");
			}
		}
		else
		{
			new UID = GetClientUserId(target);
			FakeClientCommand(client, "sm_resetjumps #%i", UID);
		}
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == hCooldown)
	{
		fCooldown = float(StringToInt(newvalue));
	}
	if(cvar == hEnableAdmNotifications)
	{
		iEnableAdmNotifications = StringToInt(newvalue);
	}
	if(cvar == hEnableLogs)
	{
		iEnableLogs = StringToInt(newvalue);
	}
	if(cvar == hReqMultRoundsHyp)
	{
		iReqMultRoundsHyp = StringToInt(newvalue);
	}
	if(cvar == hAboveNumber)
	{
		iAboveNumber = StringToInt(newvalue);
	}
	if(cvar == hAboveNumberFlags)
	{
		iAboveNumberFlags = StringToInt(newvalue);
	}
	if(cvar == hHacksPerf)
	{
		fHacksPerf = StringToFloat(newvalue);
	}
	if(cvar == hHypPerf)
	{
		fHypPerf = StringToFloat(newvalue);
	}
}