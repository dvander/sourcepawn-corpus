/*
 *
 * =============================================================================
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#include <sourcemod>
#include <sdktools_functions>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.06"

new Handle:Cv_Enabled, Handle:Cv_Time, Handle:Cv_IgnoreWounded, Handle:Cv_LosingPlayersPanel, Handle:Cv_NumMVPs
new Float:g_fRoundStartTime, Float:g_fRoundEndTime
new g_iInitialPlayerScore[MAXPLAYERS], g_iPlayerScore[MAXPLAYERS], g_iNumMVPs, g_iRedKilled, g_iBluKilled, g_iCRTime, g_iOffsetPlayerScore, g_iOffsetClass, g_iEntPlayerManager
new bool:g_bEnabled, bool:g_bIgnoreWounded, bool:g_bLosingPlayersPanel

public Plugin:myinfo = 
{

	name = "Team Fortress 2 Casualty Report",
	author = "simoneaolson, Reflex",
	description = "Displays a casualty report on round end",
	version = PLUGIN_VERSION,
	url = "http://http://www.sourcemod.net/plugins.php?search=1&author=simoneaolson"
	
}

public OnPluginStart()
{
	
	AutoExecConfig(true, "tf_casualtyreport")
	LoadTranslations("casualtyreport.phrases")
	
	//Prepare offsets
	g_iOffsetPlayerScore = FindSendPropOffs("CTFPlayerResource", "m_iTotalScore")
	g_iOffsetClass = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass")
	
	CreateConVar("tf_casualtyreport_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	Cv_Enabled = CreateConVar("tf_casualtyreport_enabled", "1", "Enable/Disable TF2 Casualty Reporting (bool)", _, true, 0.0, true, 1.0)
	Cv_Time = CreateConVar("tf_casualtyreport_time", "14", "Seconds to display casualty report menu (int)", _, true, 7.0, true, 30.0)
	Cv_IgnoreWounded = CreateConVar("tf_casualtyreport_ignorewounded", "0", "Ignore wounded players on the panel (players who are alive when the round ends)(bool)", _, true, 0.0, true, 1.0)
	Cv_LosingPlayersPanel = CreateConVar("tf_casualtyreport_losingpanel", "0", "Show top players on the losing team on the panel (bool)", _, true, 0.0, true, 1.0)
	Cv_NumMVPs = CreateConVar("tf_casualtyreport_mvps", "3", "Number of MVPs to show on the losing team panel (int)", _, true, 2.0, true, 8.0)
	
	HookEventEx("teamplay_round_start", RoundStart, EventHookMode_Post)
	HookEventEx("teamplay_round_win", RoundWon, EventHookMode_Post)
	HookEventEx("player_death", PlayerDeath, EventHookMode_Pre)

}


public OnMapStart()
{

	if ((g_iEntPlayerManager = FindEntityByClassname(-1, "tf_player_manager")) == -1)
		SetFailState("Cant find tf_player_manager entity!")

}


public OnConfigsExecuted()
{

	g_bEnabled = GetConVarBool(Cv_Enabled)
	g_iCRTime = GetConVarInt(Cv_Time)
	g_iNumMVPs = GetConVarInt(Cv_NumMVPs)
	g_bIgnoreWounded = GetConVarBool(Cv_IgnoreWounded)
	g_bLosingPlayersPanel = GetConVarBool(Cv_LosingPlayersPanel)
	
	HookConVarChange(Cv_Enabled, cvEnabled)
	HookConVarChange(Cv_Time, cvTime)
	HookConVarChange(Cv_IgnoreWounded, cvIgnoreWounded)
	HookConVarChange(Cv_LosingPlayersPanel, cvLosingPlayersPanel)
	HookConVarChange(Cv_NumMVPs, cvNumMVPs)

}

public cvEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = GetConVarBool(Cv_Enabled)
}

public cvTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCRTime = GetConVarInt(Cv_Time)
}

public cvIgnoreWounded(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bIgnoreWounded = GetConVarBool(Cv_IgnoreWounded)
}

public cvLosingPlayersPanel(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bLosingPlayersPanel = GetConVarBool(Cv_LosingPlayersPanel)
}

public cvNumMVPs(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iNumMVPs = GetConVarInt(Cv_NumMVPs)
}


public Action:RoundStart(const Handle:event, const String:name[], const bool:dontBroadcast)
{

	g_fRoundStartTime = GetEngineTime()
	g_iRedKilled = 0
	g_iBluKilled = 0
	
	//Set client's initial score
	for (new i = 1; i < 1+MaxClients; ++i)
	{
		g_iInitialPlayerScore[i] = GetClientScore(i)
	}

}


public Action:PlayerDeath(const Handle:event, const String:name[], const bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new team = GetClientTeam(client)
	
	if (team == 2)
		++g_iRedKilled
	else if (team == 3)
		++g_iBluKilled

}


public Action:RoundWon(const Handle:event, const String:name[], const bool:dontBroadcast)
{

	if (g_bEnabled)
	{
		g_fRoundEndTime = GetEngineTime()
		decl winningTeam
		new losingTeam = 3, RowCount = 0
		if ((winningTeam = GetEventInt(event, "team")) == 3) losingTeam = 2
		
		new Handle:CasualtyPanel = CreatePanel()
		new Handle:CasualtyPanelLosing = CreatePanel()
		
		AddPanelTitle(CasualtyPanel)
		AddWinningTeamToPanel(CasualtyPanel, winningTeam)
		AddCasualtiesAndWoundedToPanel(CasualtyPanel)
		AddRoundLengthToPanel(CasualtyPanel)
		AddGenericEndingPanelItems(CasualtyPanel)
		
		//If the server would like to show the losing team MVPs, prepare the panel
		if (g_bLosingPlayersPanel)
		{
			AddPanelTitle(CasualtyPanelLosing)
			AddWinningTeamToPanel(CasualtyPanelLosing, winningTeam)
			AddCasualtiesAndWoundedToPanel(CasualtyPanelLosing)
			AddRoundLengthToPanel(CasualtyPanelLosing)
			RowCount = AddLosingTeamMVPsToPanel(CasualtyPanelLosing, losingTeam)
			AddGenericEndingPanelItems(CasualtyPanelLosing)
		}
		
		PrintToChatAll("RowCount == %i", RowCount)
		
		//Send generic panel to winning team
		SendPanelToTeam(CasualtyPanel, winningTeam)
		
		//Send MVP panel to losing team
		if (g_bLosingPlayersPanel && RowCount > 0)
			SendPanelToTeam(CasualtyPanelLosing, losingTeam)
		else
			SendPanelToTeam(CasualtyPanel, losingTeam)

		CloseHandle(CasualtyPanel)
		CloseHandle(CasualtyPanelLosing)
	}

}


public Action:SendPanelToTeam(const Handle:panel, const teamSending)
{

	for (new i = 1; i < 1+MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == teamSending)
		{
			SendPanelToClient(panel, i, Handle_CasualtyReport, g_iCRTime)
		}
	}

}


public Action:Draw_PanelHeader(Handle:handle, const team)
{

	decl String:teamX[6]
	decl String:panelTitle[128]
	decl String:panelFirstRow[128]
	
	Format(teamX, sizeof(teamX), "team%i", team)
	Format(panelTitle, sizeof(panelTitle), "%T", teamX, team)
	Format(panelFirstRow, sizeof(panelFirstRow), "%T", "header", team)
	
	DrawPanelText(handle, panelTitle)
	DrawPanelText(handle, panelFirstRow)

}


public Action:Draw_PanelPlayer(Handle:handle, const score, const client)
{

	decl String:panelTopPlayerRow[256]
	decl String:playerName[MAX_NAME_LENGTH]
	decl String:playerScore[13]
	decl String:playerClass[128]
	decl String:classX[7]
	
	// Format player name
	GetClientName(client, playerName, MAX_NAME_LENGTH)
	
	// Format player score
	if (score < 10)
		Format(playerScore, sizeof(playerScore), " %i       ", score)
	else if (score < 100)
		Format(playerScore, sizeof(playerScore), " %i     ", score)
	else
		Format(playerScore, sizeof(playerScore), " %i   ", score)
		
	// Format player class
	Format(classX, sizeof(classX), "class%i", GetClientClass(client))
	Format(playerClass, sizeof(playerClass), "%T", classX, client)
	
	// Format player row
	Format(panelTopPlayerRow, sizeof(panelTopPlayerRow), "%s%s%s", playerScore, playerClass, playerName)
	
	DrawPanelItem(handle, panelTopPlayerRow)

}


public Action:AddPanelTitle(Handle:panel)
{

	//Prepare panel title (eg. SIEGE OF HOODOO)
	decl String:mapName[64]
	new String:temp[64]
	GetCurrentMap(mapName, 64)
	Format(mapName, 64, "%s", CutStr(mapName, 1 + FindCharInString(mapName, '_', false)))
	
	new pos = FindCharInString(mapName, '_', false)
	if (pos != -1)	SplitString(mapName, "_", mapName, 64)
	
	StringToUpper(temp, mapName)
	Format(mapName, 64, "%t", "Menu Title", temp)
	DrawPanelText(panel, mapName)

}


public Action:AddWinningTeamToPanel(Handle:panel, const winningTeam)
{

	new String:temp[65]
	
	//Prepare to display which team won the round (eg. BLU TRIUMPHS OVER RED)
	if (winningTeam == 2)
		Format(temp, 64, "%t", "Team Title", "RED", "BLU")
	else
		Format(temp, 64, "%t", "Team Title", "BLU", "RED")
	
	DrawPanelText(panel, temp)

}


public Action:AddCasualtiesAndWoundedToPanel(Handle:panel)
{

	new String:temp[65]
	
	DrawPanelText(panel, "")
	Format(temp, sizeof(temp), "%t: %i", "Red Casualties", g_iRedKilled)
	DrawPanelText(panel, temp)
	
	//Do not display wounded if the Cvar is set to "true"
	if (!g_bIgnoreWounded)
	{
		Format(temp, sizeof(temp), "%t: %i", "Red Wounded", GetWounded(2))
		DrawPanelText(panel, temp)
	}
	
	DrawPanelText(panel, "")
	Format(temp, sizeof(temp), "%t: %i", "Blu Casualties", g_iBluKilled)
	DrawPanelText(panel, temp)
	
	//Do not display wounded if the Cvar is set to "true"
	if (!g_bIgnoreWounded)
	{
		Format(temp, sizeof(temp), "%t: %i", "Blu Wounded", GetWounded(3))
		DrawPanelText(panel, temp)
	}

}


public Action:AddRoundLengthToPanel(Handle:panel)
{

	new String:temp[65]
	new Secs = RoundToFloor((g_fRoundEndTime - g_fRoundStartTime))%60
	new Mins = RoundToFloor((g_fRoundEndTime - g_fRoundStartTime)/60.0)
	
	if (Mins == 0)
		Format(temp, 64, "%t: %i Seconds", "Time", Secs)
	else
	{
		if (Secs < 10)
			Format(temp, 64, "%t: %i:0%i Mins", "Time", Mins, Secs)
		else
			Format(temp, 64, "%t: %i:%i Mins", "Time", Mins, Secs)
	}
	
	DrawPanelText(panel, "")
	DrawPanelText(panel, temp)

}


public AddLosingTeamMVPsToPanel(Handle:panel, const losingTeam)
{

	DrawPanelText(panel, "")
	
	decl client
	new SortedScoreArray[MaxClients][2]
	
	for (new i = 0; i < MaxClients; ++i)
	{
		SortedScoreArray[i][0] = (client = i + 1)
		
		if (IsClientInGame(client) && GetClientTeam(client) == losingTeam)
			SortedScoreArray[i][1] = GetClientScore(client) - g_iInitialPlayerScore[client]
		else
			SortedScoreArray[i][1] = -1
	}
	
	SortCustom2D(SortedScoreArray, MaxClients, SortScoreDesc)
	
	Draw_PanelHeader(panel, losingTeam)
	
	new RowCount = 0
	//Draw three top players
	for (new n = 0; n < g_iNumMVPs; ++n)
	{
		if (SortedScoreArray[n][1] > 0)
		{
			Draw_PanelPlayer(panel, SortedScoreArray[n][1], SortedScoreArray[n][0])
			++RowCount
		}
	}
	
	return RowCount
	
}


public Action:AddGenericEndingPanelItems(Handle:panel)
{

	DrawPanelText(panel, "")
	SetPanelCurrentKey(panel, 10)
	DrawPanelItem(panel, "Close", ITEMDRAW_CONTROL)

}


public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{

	g_iPlayerScore[client] = 0
	return true

}


public GetWounded(const team)
{

	new wounded = 0
	
	for (new i = 1; i < 1+MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
		{
			++wounded
		}
	}
	
	return wounded

}


public GetClientClass(const client)
{
	if (IsClientConnected(client))
		return GetEntData(g_iEntPlayerManager, g_iOffsetClass + (client * 4), 4)
	return 1
}


public GetClientScore(const client)
{

	if (IsClientInGame(client)) return GetEntData(g_iEntPlayerManager, g_iOffsetPlayerScore + (client * 4), 4)
	return -1

}


stock String:CutStr(const String:map[], const start)
{

	new String:newStr[64]
	Format(newStr, 64, "%s%s", newStr, map[start])
	return newStr

}


//Converts a string to uppercase
public Action:StringToUpper(String:target[], const String:source[])
{

	new end = strlen(source)
	for (new i = 0; i < end; ++i)
	{
		target[i] = CharToUpper(source[i])
	}

}


public SortScoreDesc(x[], y[], array[][], Handle:data)
{
	if (x[1] > y[1])
		return -1
	else if (x[1] < y[1])
		return 1
	return 0
}


public Handle_CasualtyReport(Handle:menu, MenuAction:action, param1, param2)
{
	//If you're trying to figure out what this does, don't. I dont even know myself.
}