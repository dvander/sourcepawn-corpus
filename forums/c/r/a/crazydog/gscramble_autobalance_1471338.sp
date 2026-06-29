/************************************************************************
*************************************************************************
gScramble autobalance logic
Description:
	Autobalance logic for the gscramble addon
*************************************************************************
*************************************************************************

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: gscramble_autobalance.sp 135 2011-02-25 06:23:32Z brutalgoergectf $
$Author: brutalgoergectf $
$Revision: 135 $
$Date: 2011-02-24 23:23:32 -0700 (Thu, 24 Feb 2011) $
$LastChangedBy: brutalgoergectf $
$LastChangedDate: 2011-02-24 23:23:32 -0700 (Thu, 24 Feb 2011) $
$URL: https://tf2tmng.googlecode.com/svn/trunk/gscramble/addons/sourcemod/scripting/gscramble/gscramble_autobalance.sp $
$Copyright: (c) Tf2Tmng 2009-2011$
*************************************************************************
*************************************************************************
*/

stock GetLargerTeam()
{
	if (GetTeamClientCount(TEAM_RED) > GetTeamClientCount(TEAM_BLUE))
	{
		return TEAM_RED;
	}
	return TEAM_BLUE;
}

stock GetSmallerTeam()
{
	return GetLargerTeam() == TEAM_RED ? TEAM_BLUE:TEAM_RED;
}

public Action:timer_StartBalanceCheck(Handle:timer, any:client)
{
	if (g_aTeams[bImbalanced] && BalancePlayer(client))
		CheckBalance(true);
	return Plugin_Handled;
}

bool:BalancePlayer(client)
{
	if (!TeamsUnbalanced(false))
	{
		return true;
	}
	
	new team, bool:overrider = false, iTime = GetTime();
	new big = GetLargerTeam();
	team = big == TEAM_RED?TEAM_BLUE:TEAM_RED;
	
	/**
	checks for preferences to override the client so 
	*/
	if (GetConVarBool(cvar_Preference))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == big && g_aPlayers[client][iTeamPreference] == team)
			{
				overrider = true;
				client = i;
				break;
			}
		}
	}
	
	if (!overrider)
	{
		if (!IsValidTarget(client, balance) || GetPlayerPriority(client) < 0)
			return false;	
	}
	else if (IsPlayerAlive(client))
		CreateTimer(0.5, Timer_BalanceSpawn, GetClientUserId(client));
	new String:sName[MAX_NAME_LENGTH + 1], String:sTeam[32];
	GetClientName(client, sName, 32);
	team == TEAM_RED ? (sTeam = "RED") : (sTeam = "BLU");
	g_bBlockDeath = true;
	ChangeClientTeam(client, team);
	g_bBlockDeath = false;
	g_aPlayers[client][iBalanceTime] = iTime + (GetConVarInt(cvar_BalanceTime) * 60);
	if (!IsFakeClient(client))
	{
		new Handle:event = CreateEvent("teamplay_teambalanced_player");
		SetEventInt(event, "player", client);
		SetEventInt(event, "team", team);
		SetupTeamSwapBlock(client);
		FireEvent(event);
	}
	LogAction(client, -1, "\"%L\" has been auto-balanced to %s.", client, sTeam);
	PrintToChatAll("\x01\x04[SM]\x01 %t", "TeamChangedAll", sName, sTeam);
	g_aTeams[bImbalanced]=false;
	return true;
}

stock StartForceTimer()
{
	if (g_bBlockDeath)
	{
		return;
	}
	if (g_hForceBalanceTimer != INVALID_HANDLE)
	{
		KillTimer(g_hForceBalanceTimer);
		g_hForceBalanceTimer = INVALID_HANDLE;
	}
	new Float:fDelay;
	if (1 > (fDelay = GetConVarFloat(cvar_MaxUnbalanceTime)))
	{
		return;
	}
	g_hForceBalanceTimer = CreateTimer(fDelay, Timer_ForceBalance);
}

/**
	forces balance if teams stay unbalacned too long
*/
public Action:Timer_ForceBalance(Handle:timer)
{
	g_hForceBalanceTimer = INVALID_HANDLE;
	if (TeamsUnbalanced(false))
	{
		BalanceTeams(true);
	}
	g_aTeams[bImbalanced] = false;
	return Plugin_Handled;
}

CheckBalance(bool:post=false)
{
	if (!g_bHooked)
		return;
	if (g_hCheckTimer != INVALID_HANDLE)
		return;
	if (!g_bAutoBalance)
		return;
	if (g_bBlockDeath)
	{
		return;
	}
		
	if (post)
	{
		g_hCheckTimer = CreateTimer(0.1, timer_CheckBalance);
		return;
	}
	if (TeamsUnbalanced())
	{
		if (IsOkToBalance() && !g_aTeams[bImbalanced] && g_hBalanceFlagTimer == INVALID_HANDLE)
		{
			new delay = GetConVarInt(cvar_BalanceActionDelay);
			if (!g_bSilent && delay > 1)
			{
				PrintToChatAll("\x01\x04[SM]\x01 %t", "FlagBalance", delay);
			}
			g_hBalanceFlagTimer = CreateTimer(float(delay), timer_BalanceFlag);			
		}
		if (g_RoundState == preGame || g_RoundState == bonusRound || g_RoundState == suddenDeath)
		{
			if (g_hBalanceFlagTimer != INVALID_HANDLE)
			{
				KillTimer(g_hBalanceFlagTimer);
				g_hBalanceFlagTimer = INVALID_HANDLE;
			}
			g_aTeams[bImbalanced] = true;
		}
	}
	else
	{
		g_aTeams[bImbalanced] = false;
		if (g_hBalanceFlagTimer != INVALID_HANDLE)
		{
			KillTimer(g_hBalanceFlagTimer);
			g_hBalanceFlagTimer = INVALID_HANDLE;
		}
		
	}
}

/**
flags the teams as being unbalanced
*/
public Action:timer_BalanceFlag(Handle:timer)
{
	g_hBalanceFlagTimer = INVALID_HANDLE;
	if (TeamsUnbalanced())
	{
		StartForceTimer();
		g_aTeams[bImbalanced] = true;
	}
	return Plugin_Handled;
}

public Action:timer_CheckBalance(Handle:timer)
{
	g_hCheckTimer = INVALID_HANDLE;
	CheckBalance();
	return Plugin_Handled;
}

stock bool:TeamsUnbalanced(bool:force=true)
{
	new iDiff = GetAbsValue(GetTeamClientCount(TEAM_RED), GetTeamClientCount(TEAM_BLUE));
	new iForceLimit = GetConVarInt(cvar_ForceBalanceTrigger);
	new iBalanceLimit = GetConVarInt(cvar_BalanceLimit);
	
	if (iDiff >= iBalanceLimit)
	{
		if (g_RoundState == normal && force && iForceLimit > 1 && iDiff >= iForceLimit)
		{
			BalanceTeams(true);

			if (g_hBalanceFlagTimer != INVALID_HANDLE)
			{
				KillTimer(g_hBalanceFlagTimer);
				g_hBalanceFlagTimer = INVALID_HANDLE;
			}
			return false;
		}
		return true;
	}
	return false;
}

stock BalanceTeams(bool:respawn=true)
{
	if (!TeamsUnbalanced(false) || g_bBlockDeath)
	{
		return;
	}
	
	new team = GetLargerTeam(), counter,
		smallTeam = GetSmallerTeam(),
		swaps = GetAbsValue(GetTeamClientCount(TEAM_RED), GetTeamClientCount(TEAM_BLUE)) / 2,
		iTeamSize = GetTeamClientCount(team);
	new iFatTeam[iTeamSize][2];
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i))
			continue;
        if (IsFakeClient(i))
            continue;
		if (IsValidSpectator(i))
		{
			iFatTeam[counter][0] = i;
			iFatTeam[counter][1] = 90;
			counter++;
		}
		else if (GetClientTeam(i) == team) 
		{
			if (GetConVarBool(cvar_Preference) && g_aPlayers[i][iTeamPreference] == smallTeam && !TF2_IsClientUbered(i))
			{
				iFatTeam[counter][1] = 3;
			}
			else if (IsValidTarget(i, balance))
			{
				iFatTeam[counter][1] = GetPlayerPriority(i);
			}
			else
			{
				iFatTeam[counter][1] = -5;
			}
			iFatTeam[counter][0] = i;
			counter++;
		}
	}	
	SortCustom2D(iFatTeam, iTeamSize, SortIntsDesc); // sort the array so low prio players are on the bottom
	g_bBlockDeath = true;	
	for (new i = 0; swaps-- > 0 && i < counter; i++)
	{
		if (iFatTeam[i][0])
		{	
			new bWasSpec = false;			
			if (GetClientTeam(iFatTeam[i][0]) == 1)
			{
				bWasSpec = true;
			}
			new String:clientName[MAX_NAME_LENGTH + 1], String:sTeam[4];
			GetClientName(iFatTeam[i][0], clientName, 32);
			if (team == TEAM_RED)
				sTeam = "Blu";
			else
				sTeam = "Red";				
			ChangeClientTeam(iFatTeam[i][0], team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE);
			if (bWasSpec)
			{
				TF2_SetPlayerClass(iFatTeam[i][0], TFClass_Scout);
			}
			PrintToChatAll("\x01\x04[SM]\x01 %t", "TeamChangedAll", clientName, sTeam);
			SetupTeamSwapBlock(iFatTeam[i][0]);
			LogAction(iFatTeam[i][0], -1, "\"%L\" has been force-balanced to %s.", iFatTeam[i][0], sTeam);			
			if (respawn)
				CreateTimer(0.5, Timer_BalanceSpawn, GetClientUserId(iFatTeam[i][0]), TIMER_FLAG_NO_MAPCHANGE);
			if (!IsFakeClient(iFatTeam[i][0]))
			{				
				new Handle:event = CreateEvent("teamplay_teambalanced_player");
				SetEventInt(event, "player", iFatTeam[i][0]);
				g_aPlayers[iFatTeam[i][0]][iBalanceTime] = GetTime() + (GetConVarInt(cvar_BalanceTime) * 60);
				SetEventInt(event, "team", team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE);
				FireEvent(event);
			}
		}
	}
	g_bBlockDeath = false;
	g_aTeams[bImbalanced] = false;
	return;
}

stock bool:IsOkToBalance()
{
	if (g_RoundState == normal)
	{
		new iBalanceTimeLimit = GetConVarInt(cvar_BalanceTimeLimit);
		if (iBalanceTimeLimit && g_iRoundTimer)
		{
			if (g_iRoundTimer < iBalanceTimeLimit)
			{
				return false;
			}
		}
		return true;
	}
	switch (g_RoundState)
	{
		case suddenDeath:
		{
			return false;
		}
		case preGame:
		{
			return false;
		}
		case setup:
		{
			return false;
		}
		case bonusRound:
		{
			return false;
		}
	}
	return true;
}

public Action:Timer_BalanceSpawn(Handle:timer, any:id)
{
	new client;
	if ((client = (GetClientOfUserId(id))))
	{
		if (!IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(client);
		}
	}
	return Plugin_Handled;
}
