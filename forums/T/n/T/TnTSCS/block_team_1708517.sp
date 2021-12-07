#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define		PLUGIN_VERSION			"0.0.1.1"
#define		CS_TEAM_AUTOASSIGN		0

new Handle:ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new String:BlockedTeam[8];

new bool:CTBlocked = false;
new bool:TBlocked = false;

public Plugin:myinfo = 
{
	name = "Block Team",
	author = "TnTSCS aka ClarkKent",
	description = "Blocks player's ability to join blocked team",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	// Create this plugins CVars
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_blockteam_version", PLUGIN_VERSION, 
	"Version of 'Block Team'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	RegAdminCmd("sm_blockteam", Cmd_BlockTeam, ADMFLAG_GENERIC, "Allows you to toggle block player's ability to join the defined blocked team");
	RegAdminCmd("sm_closeCT", Cmd_CloseCT, ADMFLAG_GENERIC, "Allows you to toggle block player's ability to join the CT team - requested command");
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		ClearTimer(ClientTimer[client]);
	}
}

public Action:Cmd_CloseCT(client, args)
{	
	if (client == 0)
	{
		ReplyToCommand(client, "In-Game command only");
		return Plugin_Handled;
	}
	
	if (!CTBlocked)
	{
		CTBlocked = true;
		ReplyToCommand(client, "CT Team has been closed");
	}
	else
	{
		CTBlocked = false;
		ReplyToCommand(client, "CT Team has been opened");
	}
	
	return Plugin_Handled;
}

public Action:Cmd_BlockTeam(client, args)
{	
	if (client == 0)
	{
		ReplyToCommand(client, "In-Game command only");
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_blockteam <T/CT/ALL/NONE>");
		return Plugin_Handled;
	}
	
	BlockedTeam[0] = '\0';
	
	GetCmdArg(1, BlockedTeam, sizeof(BlockedTeam));
	
	if (StrEqual(BlockedTeam, "T", false))
	{
		if (!TBlocked)
		{
			TBlocked = true;
			ReplyToCommand(client, "Terrorists team blocked");
		}
		else
		{
			TBlocked = false;
			ReplyToCommand(client, "Terrorists team unblocked");
		}
	}
	else if (StrEqual(BlockedTeam, "CT", false))
	{
		if (!CTBlocked)
		{
			CTBlocked = true;
			ReplyToCommand(client, "CT team blocked");
		}
		else
		{
			CTBlocked = false;
			ReplyToCommand(client, "CT team unblocked");
		}
	}
	else if (StrEqual(BlockedTeam, "ALL", false))
	{
		TBlocked = true;
		CTBlocked = true;
		ReplyToCommand(client, "Terrorists and CT teams both blocked");
	}
	else if (StrEqual(BlockedTeam, "NONE", false))
	{
		TBlocked = false;
		CTBlocked = false;
		ReplyToCommand(client, "Terrorists and CT teams both unblocked");
	}
	
	return Plugin_Handled;
}

public Action:Command_JoinTeam(client, const String:command[], argc)
{
	if(!client || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	// Figure out what team they player is trying to join
	decl String:TeamNum[2];
	TeamNum[0] = '\0';
	
	GetCmdArg(1, TeamNum, sizeof(TeamNum));
	
	new team = StringToInt(TeamNum);
	
	if(team < 0 || team > 3)
	{
		return Plugin_Continue;
	}
	
	if (TBlocked && CTBlocked)
	{
		PrintToChat(client, "Admin has blocked your ability to join ANY team.  You've been switched to Spectate");
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		return Plugin_Handled;
	}
	
	switch(team)
	{
		case CS_TEAM_AUTOASSIGN:
		{
			ClearTimer(ClientTimer[client]);
			ClientTimer[client] = CreateTimer(0.1, Timer_CheckTeam, client);
		}
		
		case CS_TEAM_T:
		{
			if (TBlocked && !CheckCommandAccess(client, "allow_jointeam_bypass", ADMFLAG_GENERIC, false))
			{
				PrintToChat(client, "Admin has blocked your ability to join the Terrorists, you were switched to CT");
				
				if (GetClientTeam(client) == CS_TEAM_CT)
				{
					return Plugin_Handled;
				}
				
				ChangeClientTeam(client, CS_TEAM_CT);
				
				return Plugin_Handled;
			}
		}
		
		case CS_TEAM_CT:
		{
			if (CTBlocked && !CheckCommandAccess(client, "allow_jointeam_bypass", ADMFLAG_GENERIC, false))
			{
				PrintToChat(client, "Admin has blocked your ability to join the CTs, you were switched to Terrorist");
				
				if (GetClientTeam(client) == CS_TEAM_T)
				{
					return Plugin_Handled;
				}
				
				ChangeClientTeam(client, CS_TEAM_T);
				
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_CheckTeam(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	if (!IsClientInGame(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
	{
		return;
	}
	
	if (TBlocked && CTBlocked)
	{
		PrintToChat(client, "Admin has blocked your ability to join ANY team.  You've been switched to Spectate");
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		return;
	}
	
	new team = GetClientTeam(client);
	
	switch(team)
	{
		case CS_TEAM_T:
		{
			if (TBlocked && !CheckCommandAccess(client, "allow_jointeam_bypass", ADMFLAG_GENERIC, false))
			{
				PrintToChat(client, "Admin has blocked your ability to join the Terrorists, you were switched to CT");
				CS_SwitchTeam(client, CS_TEAM_CT);
			}
		}
		
		case CS_TEAM_CT:
		{
			if (CTBlocked && !CheckCommandAccess(client, "allow_jointeam_bypass", ADMFLAG_GENERIC, false))
			{
				PrintToChat(client, "Admin has blocked your ability to join the CTs, you were switched to Terrorist");
				CS_SwitchTeam(client, CS_TEAM_T);
			}
		}
	}
	
	if(IsPlayerAlive(client))
	{
		CS_RespawnPlayer(client);
	}
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================
public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}