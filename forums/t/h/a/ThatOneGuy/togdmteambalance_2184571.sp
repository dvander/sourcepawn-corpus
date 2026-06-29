#pragma semicolon 1
#define PLUGIN_VERSION "1.2a"
#include <sourcemod>
#include <autoexecconfig>
#include <sdktools>

//cvars and their integers
new	Handle:g_hEnabled = INVALID_HANDLE;
new g_iEnabled;
new	Handle:g_hImmuneFlag = INVALID_HANDLE;
new String:g_sImmuneFlag[30];
new	Handle:g_hCheckTime = INVALID_HANDLE;
new g_iCheckTime;
new	Handle:g_hBalanceDifference = INVALID_HANDLE;
new g_iBalanceDifference;
new	Handle:g_hCooldownPlayerCount = INVALID_HANDLE;
new g_iCooldownPlayerCount;
new	Handle:g_hCooldownTime = INVALID_HANDLE;
new Float:g_fCooldownTime;

new bool:g_iUnbalanced = false;
new bool:g_bMovable[MAXPLAYERS + 1];
new bool:g_bInCooldown[MAXPLAYERS + 1] = {false, ...};

new g_iNumT = 0;
new g_iNumCT = 0;
new g_iTeamWithMore;

public Plugin:myinfo =
{
	name = "TOGs Deathmatch Team Balancer v1.2",
	author = "That One Guy",
	description = "Balances Teams for Death Match Servers",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togdmteambalance");
	AutoExecConfig_CreateConVar("tdmtb_version", PLUGIN_VERSION, "TOGs Deathmatch Team Balancer Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hEnabled = AutoExecConfig_CreateConVar("tdmtb_enable", "1", "Enable plugin (0 = Disabled, 1 = Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_iEnabled = GetConVarInt(g_hEnabled);
	
	g_hImmuneFlag = AutoExecConfig_CreateConVar("tdmtb_immuneflag", "a", "Flag to check for when balancing. Players with this flag will not be moved.");
	HookConVarChange(g_hImmuneFlag, OnCVarChange);
	GetConVarString(g_hImmuneFlag, g_sImmuneFlag, sizeof(g_sImmuneFlag));
	
	g_hCheckTime = AutoExecConfig_CreateConVar("tdmtb_checktime", "20", "Repeating time interval to check for unbalanced teams.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hCheckTime, OnCVarChange);
	g_iCheckTime = GetConVarInt(g_hCheckTime);
	
	g_hBalanceDifference = AutoExecConfig_CreateConVar("tdmtb_difference", "2", "How many more players a team must have to be considered unbalanced.", FCVAR_NONE, true, 2.0);
	HookConVarChange(g_hBalanceDifference, OnCVarChange);
	g_iBalanceDifference = GetConVarInt(g_hBalanceDifference);
	
	g_hCooldownPlayerCount = AutoExecConfig_CreateConVar("tdmtb_cooldown_playercount", "8", "How many players must be playing (on a team) before players cannot be moved until after a cooldown time.", FCVAR_NONE, true, 1.0, true, 64.0);
	HookConVarChange(g_hCooldownPlayerCount, OnCVarChange);
	g_iCooldownPlayerCount = GetConVarInt(g_hCooldownPlayerCount);
	
	g_hCooldownTime = AutoExecConfig_CreateConVar("tdmtb_cooldown_time", "60", "Time after a player is moved during which they cannot be moved again (set to 0 to disable cooldown).", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hCooldownTime, OnCVarChange);
	g_fCooldownTime = GetConVarFloat(g_hCooldownTime);
	
	RegAdminCmd("sm_chkbal", Command_ChkBal, ADMFLAG_BAN, "Checks Team Balance.");
	
	RegAdminCmd("sm_chkimm", Command_ChkImm, ADMFLAG_BAN, "Checks who has immunity to Team Balance.");
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public Action:Command_ChkImm(client, args)
{
	new iImmuneFound = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		g_bMovable[i] = false;
		
		if(IsClientInGame(i))
		{
			if(!IsFakeClient(i))
			{
				if(HasFlags(g_sImmuneFlag, i))
				{
					g_bMovable[i] = true;
					decl String:sName[40];
					GetClientName(i, sName, sizeof(sName));
					if(client == 0)
					{
						PrintToServer("Player \"%s\" is immune to Team Balance.", sName);
					}
					else
					{
						PrintToConsole(client, "Player \"%s\" is immune to Team Balance.", sName);
					}
					iImmuneFound = 1;
				}
				
				continue;
			}
		}
		
		continue;
	}
	
	if(iImmuneFound == 0)
	{
		ReplyToCommand(client, "Did not find any players with immunity to Team Balance.");
		return Plugin_Handled;
	}
	
	if(client != 0)
	{
		PrintToChat(client, "Check console for players with immunity!");
	}
	return Plugin_Handled;
}

public Action:Command_ChkBal(client, args)
{
	CheckTeams();
	ReplyToCommand(client, "Team Balances are being checked!");
	ReplyToCommand(client, "Number of Ts: %i, Number of CTs: %i", g_iNumT, g_iNumCT);
	return Plugin_Handled;
}

CheckTeams()		//count players and check for unbalance
{
	//reset counts
	g_iNumT = 0;
	g_iNumCT = 0;
	g_iTeamWithMore = 0;
	
	//count players on each team
	for(new i = 1; i <= MaxClients; i++)
	{	
		if(IsClientInGame(i))
		{
			if(!IsFakeClient(i))
			{
				if(GetClientTeam(i) == 2)
				{
					g_iNumT++;
				}
				else if(GetClientTeam(i) == 3)
				{
					g_iNumCT++;
				}
			}
		}
		continue;
	}
	
	//check if unbalanced
	new Float:fDifference = float(g_iNumCT - g_iNumT);
	fDifference = FloatAbs(fDifference);
	if((fDifference +1) > g_iBalanceDifference)
	{
		g_iUnbalanced = true;
		
		if(g_iNumCT > g_iNumT)
		{
			g_iTeamWithMore = 3;
		}
		else
		{
			g_iTeamWithMore = 2;
		}
	}
	else
	{
		g_iUnbalanced = false;
	}
}

public OnMapStart()
{
	if(g_iEnabled)
	{
		new Float:Time = float(g_iCheckTime);
		CreateTimer(Time, Timer_Monitor, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		//check each player for if they are movable
		for(new i = 1; i <= MaxClients; i++)
		{
			g_bMovable[i] = false;
			
			if(IsClientInGame(i))
			{
				if(!IsFakeClient(i))
				{
					if(HasFlags(g_sImmuneFlag, i))
					{
						continue;
					}
					else
					{
						g_bMovable[i] = true;
						continue;
					}
				}
				else
					continue;
			}
			else
			{
				continue;
			}
		}
	}
}

bool:HasFlags(String:sFlag[], client)
{
	new AdminId:id = GetUserAdmin(client);
	
	if (id != INVALID_ADMIN_ID)
	{
		new count, found, flags = ReadFlagString(sFlag);
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				count++;

				if (GetAdminFlag(id, AdminFlag:i))
				{
					found++;
				}
			}
		}

		if (count == found)
		{
			return true;
		}
	}

	return false;
}

public OnClientPostAdminCheck(client)		//check players for if they are movable
{
	g_bMovable[client] = false;
	
	if(IsClientInGame(client))
	{
		if(!IsFakeClient(client))
		{
			if(HasFlags(g_sImmuneFlag, client))
			{
				return;
			}
			else
			{
				g_bMovable[client] = true;
				return;
			}
		}
	}
	else
	{
		return;
	}
}

public OnClientDisconnect(client)
{
	g_bMovable[client] = false;
	g_bInCooldown[client] = false;
}

public Action:Timer_Monitor(Handle:timer)
{
	CheckTeams();
	return Plugin_Continue;
}

public Action:Timer_Cooldown(Handle:timer, any:client)
{
	g_bInCooldown[client] = false;
	return Plugin_Continue;
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		if(g_iUnbalanced)	//if teams are unbalanced
		{
			new clientid = GetEventInt(event, "userid");
			new client = GetClientOfUserId(clientid);
			
			if(g_bMovable[client] == true)		//checks if client is valid and if they are not immune
			{
				if(GetClientTeam(client) == g_iTeamWithMore)
				{
					if(((g_iNumCT + g_iNumT) >= g_iCooldownPlayerCount) && (g_fCooldownTime > 0))			//if player count is above or equal to set cooldown player count, and cooldown isnt set to disabled
					{
						if(g_bInCooldown[client] == false)	//check if player is in cooldown
						{
							ChangeTeam(client);
							g_iUnbalanced = false;	//assume teams are balanced until checked again
							g_bInCooldown[client] = true;
							CreateTimer(g_fCooldownTime, Timer_Cooldown, client, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					else	//no cooldown check
					{
						ChangeTeam(client);
						g_iUnbalanced = false;	//assume teams are balanced until checked again
						if(g_fCooldownTime > 0)	//if cooldowns are set to disabled, then dont bother with timer.
						{
							g_bInCooldown[client] = true;
							CreateTimer(g_fCooldownTime, Timer_Cooldown, client, TIMER_FLAG_NO_MAPCHANGE);		//still create the timer in case player count reaches g_iCooldownPlayerCount
						}
					}
				}
			}
		}
	}
}

ChangeTeam(client)
{
	decl String:sName[40];
	GetClientName(client, sName, sizeof(sName));
	
	PrintToChat(client, "\x03You are being switched to balance teams!!!");
	PrintToChatAll("\x03Player %s is being switched to balance teams!", sName);
	PrintToServer("Player %s is being switched to balance teams!", sName);
	
	CreateTimer(1.0, Timer_MoveToSpec, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_MoveToSpec(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	else
	{
		if(GetClientTeam(client) == 2)
		{
			ChangeClientTeam(client, 1);
		
			CreateTimer(3.0, Timer_ChangeTeamToCT, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(GetClientTeam(client) == 3)
		{
			ChangeClientTeam(client, 1);
		
			CreateTimer(3.0, Timer_ChangeTeamToT, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			return;
	}
	return;
}

public Action:Timer_ChangeTeamToCT(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
	{
		return;
	}
	else
	{
		ChangeClientTeam(client, 3);
	}
	
	CreateTimer(8.0, Timer_RecheckTeams, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ChangeTeamToT(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
	{
		return;
	}
	else
	{
		ChangeClientTeam(client, 2);
	}
	
	CreateTimer(8.0, Timer_RecheckTeams, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_RecheckTeams(Handle:timer)
{
	CheckTeams();
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_iEnabled = StringToInt(newvalue);
	}
	else if(cvar == g_hImmuneFlag)
	{
		GetConVarString(g_hImmuneFlag, g_sImmuneFlag, sizeof(g_sImmuneFlag));
	}
	else if(cvar == g_hCheckTime)
	{
		g_iCheckTime = StringToInt(newvalue);
	}
	else if(cvar == g_hBalanceDifference)
	{
		g_iBalanceDifference = StringToInt(newvalue);
	}
	else if(cvar == g_hCooldownPlayerCount)
	{
		g_iCooldownPlayerCount = StringToInt(newvalue);
	}
	else if(cvar == g_hCooldownTime)
	{
		g_fCooldownTime = GetConVarFloat(g_hCooldownTime);
	}
}