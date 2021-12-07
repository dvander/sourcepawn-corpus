#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Cp Vote",
	author = "Sheepdude",
	description = "Enable or disable Cp by vote",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

// Convar handles
new Handle:h_cvarVersion;
new Handle:h_cvarEnable;
new Handle:h_cvarLimit;
new Handle:h_cvarAdminOnly;
new Handle:h_cvarRoundVote;

// Convar variables
new bool:g_cvarEnable;
new g_cvarLimit;
new bool:g_cvarAdminOnly;
new bool:g_cvarRoundVote;

// Plugin variables
new g_CalledVote[MAXPLAYERS+1];
new bool:g_HookedRoundStart;
new bool:g_HookedTF2RoundStart;

/******
 *Load*
*******/

public OnPluginStart()
{
	// Load translation files
	LoadTranslations("basevotes.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	// Create plugin convars
	h_cvarVersion = CreateConVar("sm_cpvote_version", PLUGIN_VERSION, "Cp Vote version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	h_cvarEnable = CreateConVar("sm_cpvote_enable", "1", "Enable (1) or Disable (0) Cp Vote", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarLimit = CreateConVar("sm_cpvote_limit", "0", "Number of times per map that a player can call a Cp Vote (0 - disable)", FCVAR_NOTIFY, true, 0.0);
	h_cvarAdminOnly = CreateConVar("sm_cpvote_adminonly", "0", "Only admins can call a vote (1 - admin only, 0 - everyone)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarRoundVote = CreateConVar("sm_cpvote_roundvote", "1", "Call a Cp Vote every round start (1 - enable, 0 - disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// Convar hooks
	if(h_cvarVersion != INVALID_HANDLE)
		HookConVarChange(h_cvarVersion, OnConvarChanged);
	if(h_cvarEnable != INVALID_HANDLE)
		HookConVarChange(h_cvarEnable, OnConvarChanged);
	if(h_cvarLimit != INVALID_HANDLE)
		HookConVarChange(h_cvarLimit, OnConvarChanged);
	if(h_cvarAdminOnly != INVALID_HANDLE)
		HookConVarChange(h_cvarAdminOnly, OnConvarChanged);
	if(h_cvarRoundVote != INVALID_HANDLE)
		HookConVarChange(h_cvarRoundVote, OnConvarChanged);
	
	// Event hooks
	g_HookedRoundStart = HookEventEx("round_start", OnRoundStart);
	g_HookedTF2RoundStart = HookEventEx("teamplay_round_start", OnRoundStart);
	if(!(g_HookedRoundStart || g_HookedTF2RoundStart))
		SetFailState("Unable to hook round start.");
	
	// Console commands
	RegConsoleCmd("sm_cpvote", CpVoteCmd);
	
	// Execute configuration file
	AutoExecConfig(true, "cpvote");
	
	// Instantiate plugin variables
	UpdateAllConvars();
}

/*********
 *Globals*
**********/

public OnConfigsExecuted()
{
	UpdateAllConvars();
}

/**********
 *Commands*
***********/

public Action:CpVoteCmd(client, args)
{
	if(!g_cvarEnable || !IsValidClient(client))
		return Plugin_Handled;
	
	if(IsVoteInProgress())
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "Vote in Progress");
	else if(g_cvarAdminOnly)
	{
		if(CheckCommandAccess(client, "sm_cpvote", ADMFLAG_GENERIC, true))
		{
			if(g_cvarLimit == 0 || g_CalledVote[client] < g_cvarLimit)
			{
				g_CalledVote[client]++;
				DoCpVote();
			}
			else
				ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 You may only vote %i times per map. You have already voted %i times.", g_cvarLimit, g_CalledVote[client]);
		}
		else
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "No Access");
	}
	else
	{
		if(g_cvarLimit == 0 || g_CalledVote[client] < g_cvarLimit)
		{
			g_CalledVote[client]++;
			DoCpVote();
		}
		else
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 You may only vote %i times per map. You have already voted %i times.", g_cvarLimit, g_CalledVote[client]);
	}
	
	return Plugin_Handled;		
}

/********
 *Events*
*********/

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_cvarEnable && g_cvarRoundVote && !IsVoteInProgress())
		DoCpVote();
}

/********
 *Plugin*
*********/

DoCpVote()
{
	new Handle:menu = CreateMenu(VoteMenuHandler);
	SetMenuTitle(menu, "Enable Cp?");
	AddMenuItem(menu, "Enable", "Enable");
	AddMenuItem(menu, "Disable", "Disable");
	VoteMenuToAll(menu, 20);
}

public VoteMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
	if(action == MenuAction_End) 
		CloseHandle(menu);
	else if(action == MenuAction_VoteEnd)
	{
		new votes;
		new totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		new Float:percent = FloatDiv(float(votes), float(totalVotes));
		if(param1 == 0)
		{
			ServerCommand("sm_enablecp");
			PrintToChatAll("\x01\x0B\x04[SM]\05 [Cp Enabled]\x01 %t", "Vote Successful", RoundToNearest(100.0 * percent), totalVotes);
		}
		else
		{
			ServerCommand("sm_disablecp");
			PrintToChatAll("\x01\x0B\x04[SM]\05 [Cp Disabled]\x01 %t", "Vote Successful", RoundToNearest(100.0 * percent), totalVotes);
		}
	}
}

/*********
 *Convars*
**********/

UpdateAllConvars()
{
	ResetConVar(h_cvarVersion);
	g_cvarEnable = GetConVarBool(h_cvarEnable);
	g_cvarLimit = GetConVarInt(h_cvarLimit);
	g_cvarAdminOnly = GetConVarBool(h_cvarAdminOnly);
	g_cvarRoundVote = GetConVarBool(h_cvarRoundVote);
}

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateAllConvars();
	if(cvar == h_cvarRoundVote)
	{
		if(g_cvarRoundVote)
		{
			g_HookedRoundStart = HookEventEx("round_start", OnRoundStart);
			g_HookedTF2RoundStart = HookEventEx("teamplay_round_start", OnRoundStart);
			if(!(g_HookedRoundStart || g_HookedTF2RoundStart))
				SetFailState("Unable to hook round start.");
		}
		else
		{
			if(g_HookedRoundStart)
			{
				UnhookEvent("round_start", OnRoundStart);
				g_HookedRoundStart = false;
			}
			if(g_HookedTF2RoundStart)
			{
				UnhookEvent("teamplay_round_start", OnRoundStart);
				g_HookedTF2RoundStart = false;
			}
		}
	}
}

/********
 *Stocks*
*********/

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client))
		return true;
	return false;
}