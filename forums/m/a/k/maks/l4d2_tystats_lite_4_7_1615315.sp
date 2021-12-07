/**
 *
 * =============================================================================
 * L4D2 Coop Stats
 * Copyright 2011 - 2016 steamcommunity.com/profiles/76561198025355822/
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
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

#pragma semicolon 1
#include <sourcemod>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

char sg_buf[40];
Database hg_db = null;
int ig_pointsC[MAXPLAYERS+1] = {0, ...};
int ig_rankC[MAXPLAYERS+1] = {1000, ...};
int ig_autoBalance = 0;
int ig_callVote = 0;
int ig_points = 0;

public Plugin myinfo =
{
	name = "l4d2_tystats",
	author = "MAKS",
	description = "L4D2 Coop Stats",
	version = "4.7 lite",
	url = "forums.alliedmods.net/showthread.php?t=174289"
};

public void OnPluginStart()
{
	HookEvent("round_start",          Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death",         Event_PlayerDeath);
	HookEvent("player_hurt",          Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("heal_success",         Event_HealSuccess);
	HookEvent("defibrillator_used",   Event_DefibrillatorUsed);
	HookEvent("revive_success",       Event_ReviveSuccess);

	RegConsoleCmd("callvote",         CMD_callvote, "");
	RegConsoleCmd("sm_rank",          CMD_rank, "");
	RegConsoleCmd("sm_top",           CMD_top, "");
	ConnectDB();
}

public void TyDBerrorCheck(Handle owner, Handle hndl, const char [] error, any data)
{
	if (hndl != null)
	{
		if (error[0] != '\0')
		{
			LogError("SQL Error: %s", error);
		}
	}
}

public void ConnectDB()
{
	if (SQL_CheckConfig("tystats"))
	{
		char sError[80];
		hg_db = SQL_Connect("tystats", true, sError, sizeof(sError)-1);
		if (hg_db != null)
		{
			SQL_TQuery(hg_db, TyDBerrorCheck, "SET NAMES 'utf8'", 0);
		}
		else
		{
			LogError("Failed connect to database: %s", sError);
		}
	}
	else
	{
		LogError("databases.cfg missing 'tystats' entry!");
	}
}

public bool TyColorC(int client)
{
	if (GetClientTeam(client) == 2)
	{
		if (IsPlayerAlive(client))
		{
			ig_autoBalance += 2;

			if (ig_pointsC[client] > 230000)
			{
				ig_autoBalance += 4;
				SetEntityRenderColor(client, 0, 0, 0, 252);
				return true;
			}

			if (ig_pointsC[client] > 180000)
			{
				ig_autoBalance += 3;
				SetEntityRenderColor(client, 255, 51, 204, 255);
				return true;
			}

			if (ig_pointsC[client] > 120000)
			{
				ig_autoBalance += 3;
				SetEntityRenderColor(client, 164, 79, 25, 255);
				return true;
			}

			if (ig_pointsC[client] > 70000)
			{
				ig_autoBalance += 2;
				SetEntityRenderColor(client, 0, 153, 51, 255);
				return true;
			}

			if (ig_pointsC[client] > 30000)
			{
				ig_autoBalance += 2;
				SetEntityRenderColor(client, 0, 51, 255, 255);
				return true;
			}

			if (ig_pointsC[client] > 10000)
			{
				ig_autoBalance += 2;
				SetEntityRenderColor(client, 0, 204, 255, 255);
				return true;
			}

			if (ig_pointsC[client] > 0)
			{
				ig_autoBalance += 1;
				return true;
			}
		}
	}
	return false;
}

public bool TyRoundS()
{
	ig_autoBalance = 0;
	ig_points = 0;

	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				TyColorC(i);
			}
		}
		i += 1;
	}

	if (ig_autoBalance > 66)
	{
		ig_points = 7;
		return true;
	}

	if (ig_autoBalance > 61)
	{
		ig_points = 6;
		return true;
	}

	if (ig_autoBalance > 48)
	{
		ig_points = 5;
		return true;
	}

	if (ig_autoBalance > 36)
	{
		ig_points = 4;
		return true;
	}

	if (ig_autoBalance > 25)
	{
		ig_points = 3;
		return true;
	}

	if (ig_autoBalance > 18)
	{
		ig_points = 2;
		return true;
	}

	if (ig_autoBalance > 13)
	{
		ig_points = 1;
		return true;
	}

	return false;
}

public void TyDBrankC(Handle owner, Handle hndl, const char [] error, any client)
{
	if (client > 0)
	{
		if (hndl != null)
		{
			while (SQL_FetchRow(hndl))
			{
				ig_rankC[client] = SQL_FetchInt(hndl, 0);
			}
		}
	}
}

public Action TyTimerGetSQLrankC(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (hg_db != null)
			{
				char sQuery[80];
				Format(sQuery, sizeof(sQuery)-1, "SELECT COUNT(*) FROM `tystatsplayers` WHERE `points` >=%i", ig_pointsC[client]);
				SQL_TQuery(hg_db, TyDBrankC, sQuery, client);
			}
		}
	}
	return Plugin_Stop;
}

public void TySetSQLplayer(int client)
{		/* Записать в базу данных время посещения и имя. Узнать ранг */
	if (hg_db != null)
	{
		char sQuery[160];
		char sName[32];
		char sTeamID[24];

		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
		GetClientName(client, sName, sizeof(sName)-8);

		ReplaceString(sName, sizeof(sName)-8, "<", "", false);
		ReplaceString(sName, sizeof(sName)-8, ">", "", false);
		ReplaceString(sName, sizeof(sName)-8, "?", "", false);
		ReplaceString(sName, sizeof(sName)-8, ";", "", false);
		ReplaceString(sName, sizeof(sName)-8, "`", "", false);
		ReplaceString(sName, sizeof(sName)-8, "'", "", false);
		ReplaceString(sName, sizeof(sName)-8, "/", "", false);
		ReplaceString(sName, sizeof(sName)-8, "$", "", false);
		ReplaceString(sName, sizeof(sName)-8, "%", "", false);
		ReplaceString(sName, sizeof(sName)-8, "&", "", false);

		Format(sQuery, sizeof(sQuery)-1, "UPDATE `tystatsplayers` SET `lastontime` = %i, `name` = '%s' WHERE `steamid` = '%s'", GetTime(), sName, sTeamID);
		SQL_TQuery(hg_db, TyDBerrorCheck, sQuery, 0);
		CreateTimer(0.6, TyTimerGetSQLrankC, client);
	}
}

public void TyDBselestClient(Handle owner, Handle hndl, const char [] error, any data)
{
	int client = data;
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (hndl != null)
			{
				if (!SQL_GetRowCount(hndl))
				{
					char sQuery[88];
					char sTeamID[24];

					GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
					Format(sQuery, sizeof(sQuery)-1, "INSERT IGNORE INTO `tystatsplayers` SET `steamid` = '%s'", sTeamID);
					SQL_TQuery(hg_db, TyDBerrorCheck, sQuery, 0);
				}

				while (SQL_FetchRow(hndl))
				{
					ig_pointsC[client] = SQL_FetchInt(hndl, 0);
				}

				if (IsClientInGame(client))
				{
					TySetSQLplayer(client);
				}
			}
		}
	}
}

public void TySQLconnectC(int client)
{		/* Проверить в базе данных наличие игрока. Узнать о нем и при необходимости добавить игрока */
	if (!IsFakeClient(client))
	{
		if (hg_db != null)
		{
			char sQuery[120];
			char sTeamID[24];

			GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
			Format(sQuery, sizeof(sQuery)-1, "SELECT `points` FROM `tystatsplayers` WHERE `steamid` = '%s'", sTeamID);
			SQL_TQuery(hg_db, TyDBselestClient, sQuery, client);
		}
	}
}

public Action TyTimerRankPrint(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			char sName[32];
			GetClientName(client, sName, sizeof(sName)-8);
			PrintToChat(client, "\x04%d \x05Rank.  \x04%d \x05Points.  \x04%s.\n", ig_rankC[client], ig_pointsC[client], sName);
		}
	}
	return Plugin_Stop;
}

public Action TyTimerConnectC(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (hg_db != null)
		{
			TySQLconnectC(client);
			CreateTimer(4.0, TyTimerRankPrint, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		ig_pointsC[client] = 0;
		ig_rankC[client] = 1000;
		CreateTimer(1.0, TyTimerConnectC, client);
	}
}

public void TyRoundDB()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			TySQLconnectC(i);
		}
		i += 1;
	}
}

public Action TyTimerRoundS(Handle timer)
{
	TyRoundS();
	return Plugin_Stop;
}

public Action TimerRoundDB(Handle timer)
{
	TyRoundDB();
	return Plugin_Stop;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ig_callVote = 0;
	CreateTimer(17.0, TyTimerRoundS, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(35.0, TimerRoundDB, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(40.0, TyTimerRoundS, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(85.0, TyTimerRoundS, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public void TySQLpoints(int iClient, int iPoints)
{		/* Запись поинтов в базу данных */
	if (iPoints)
	{
		if (hg_db != null)
		{
			char sQuery[120];
			char sTeamID[24];

			GetClientAuthId(iClient, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
			Format(sQuery, sizeof(sQuery)-1, "UPDATE `tystatsplayers` SET points = points + %d WHERE `steamid` = '%s'", iPoints, sTeamID);
			SQL_TQuery(hg_db, TyDBerrorCheck, sQuery, 0);

			if (iPoints > 0)
			{
				PrintToChat(iClient, "\x05+%d", iPoints);
			}
			else
			{
				PrintToChat(iClient, "\x04%d", iPoints);
			}
		}
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));	/* User ID который убил */
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));	/* User ID который умер */
		if (iAttacker != iUserid)
		{
			if (!IsFakeClient(iAttacker))
			{
				sg_buf[0] = '\0';
				GetEventString(event, "victimname", sg_buf, sizeof(sg_buf)-1);

				if (sg_buf[0] == 'B')
				{	/* Boomer */
					int iPoints = 2 + ig_points;
					TySQLpoints(iAttacker, iPoints);
					return Plugin_Continue;
				}

				if (sg_buf[0] == 'J')
				{	/* Jockey */
					int iPoints = 3 + ig_points;
					TySQLpoints(iAttacker, iPoints);
					return Plugin_Continue;
				}

				if (sg_buf[0] == 'S')
				{	/* Smoker */
					int iPoints = 2 + ig_points;
					TySQLpoints(iAttacker, iPoints);
					return Plugin_Continue;
				}

				if (sg_buf[0] == 'H')
				{	/* Hunter */
					int iPoints = 2 + ig_points;
					TySQLpoints(iAttacker, iPoints);
					return Plugin_Continue;
				}

				if (sg_buf[0] == 'S')
				{	/* Spitter */
					int iPoints = 4 + ig_points;
					TySQLpoints(iAttacker, iPoints);
					return Plugin_Continue;
				}

				if (sg_buf[0] == 'C')
				{	/* Charger */
					int iPoints = 5 + ig_points;
					TySQLpoints(iAttacker, iPoints);
					return Plugin_Continue;
				}

				if (sg_buf[0] == 'T')
				{	/* Tank */
					int iPoints = (2 + ig_points) * 3;
					TySQLpoints(iAttacker, iPoints);
					return Plugin_Continue;
				}

				if (sg_buf[0] == 'W')
				{	/* Witch */
					int iPoints = 3 + ig_points;
					TySQLpoints(iAttacker, iPoints);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));	/* User который нанес урон */
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));	/* User который получил урон */
		if (iAttacker != iUserid)
		{
			if (!IsFakeClient(iAttacker))
			{
				if (!IsFakeClient(iUserid))
				{
					if (GetClientTeam(iAttacker) == 2)
					{
						if (GetClientTeam(iUserid) == 2)
						{
							int iTk = GetEventInt(event, "dmg_health");
							if (iTk < 2)
							{
								iTk = -1;
							}
							else
							{
								iTk = -5;
							}

							TySQLpoints(iAttacker, iTk);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));	/* Игрок, который вывел из строя */
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));	/* Игрок, которого вывели из строя */
		if (iAttacker != iUserid)
		{
			if (!IsFakeClient(iAttacker))
			{
				if (!IsFakeClient(iUserid))
				{
					if (GetClientTeam(iAttacker) == 2)
					{
						if (GetClientTeam(iUserid) == 2)
						{
							TySQLpoints(iAttacker, -10);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(GetEventInt(event, "subject"));	/* Игрок которого лечат */
	int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));		/* Игрок который начал лечение */

	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				TySQLpoints(iUserid, 3);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(GetEventInt(event, "subject"));	/* Игрок, которого спасают */
	int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));

	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				TySQLpoints(iUserid, 3);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{		/* Спасение или поднятие успешно завершено */
	int iSubject = GetClientOfUserId(GetEventInt(event, "subject"));	/* Игрок, которого спасают */
	int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));		/* Игрок, начавший спасение */

	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				TySQLpoints(iUserid, 1);
			}
		}
	}
	return Plugin_Continue;
}

public Action CMD_callvote(int client, int args)
{
	if (client)
	{
		if (IsPlayerAlive(client))
		{
			if (ig_pointsC[client] > 10000)
			{
				if (ig_callVote <= 3)
				{
					ig_callVote += 1;
					if (ig_pointsC[client] > 70000)
					{
						TySQLpoints(client, -30);
					}
					else
					{
						TySQLpoints(client, -80);
					}
/*					LogMessage("callvote(%N) %d", client, ig_callVote); */
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Handled;
}

public void TyDBpointsC(Handle owner, Handle hndl, const char [] error, any client)
{
	if (client > 0)
	{
		if (hndl != null)
		{
			while (SQL_FetchRow(hndl))
			{
				ig_pointsC[client] = SQL_FetchInt(hndl, 0);
			}
		}
	}
}

public void TySQLrankC(int client)
{		/* Узнать у игрока поинты и ранг */
	if (!IsFakeClient(client))
	{
		if (hg_db != null)
		{
			char sQuery[104];
			char sTeamID[24];

			GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
			Format(sQuery, sizeof(sQuery)-1, "SELECT points FROM `tystatsplayers` WHERE `steamid` = '%s'", sTeamID);
			SQL_TQuery(hg_db, TyDBpointsC, sQuery, client);
			CreateTimer(0.6, TyTimerGetSQLrankC, client);
		}
	}
}

public int RankPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

public void TyDBdisplayRank(Handle owner, Handle hndl, const char [] error, any client)
{
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			if (hndl != null)
			{
				char sBuffer[64];
				int iPoints;

				while (SQL_FetchRow(hndl))
				{
					iPoints = SQL_FetchInt(hndl, 0);
				}

				Panel hPanel = new Panel();
				Format(sBuffer, sizeof(sBuffer)-1, "%d Rank.  %d Points.", ig_rankC[client], ig_pointsC[client]);
				hPanel.DrawText(sBuffer);

				if (ig_rankC[client] != 1)
				{
					Format(sBuffer, sizeof(sBuffer)-1, "%d Points (next rank).", iPoints - ig_pointsC[client]);
					hPanel.DrawText(sBuffer);
				}

				hPanel.DrawItem("Close");
				hPanel.Send(client, RankPanelHandler, 20);
				delete hPanel;
			}
			else
			{
				PrintToChat(client, "SQL error.");
				LogError("TyDBdisplayRank %s", error);
			}
		}
	}
}

public Action TyTimerSQLnextRank(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (hg_db != null)
			{
				char sQuery[112];
				Format(sQuery, sizeof(sQuery)-1, "SELECT `points` FROM `tystatsplayers` WHERE `points` > %d ORDER BY `points` ASC LIMIT 1", ig_pointsC[client]);
				SQL_TQuery(hg_db, TyDBdisplayRank, sQuery, client);
			}
		}
	}
	return Plugin_Stop;
}

public Action CMD_rank(int client, int args)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (hg_db != null)
			{
				TySQLrankC(client);
				CreateTimer(1.0, TyTimerSQLnextRank, client);
			}
			else
			{
				PrintToChat(client, "Connection error.");
			}
		}
	}
	return Plugin_Handled;
}

public void DisplayTop10(Handle owner, Handle hndl, const char [] error, any client)
{
	if (client)
	{
		if (hndl != null)
		{
			char sBuffer[64];
			char sName[32];
			int iPoints = 0;
			int iNumber = 0;

			Panel hPanel = new Panel();
			hPanel.SetTitle("Top 10 Players");

			while (SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, sName, sizeof(sName)-8);
				iPoints = SQL_FetchInt(hndl, 1);

				iNumber += 1;
				Format(sBuffer, sizeof(sBuffer)-1, "%i_ %s  %i Points", iNumber, sName, iPoints);
				hPanel.DrawText(sBuffer);
			}

			hPanel.DrawItem("Close");
			hPanel.Send(client, RankPanelHandler, 30);
			delete hPanel;
		}
	}
}

public Action CMD_top(int client, int args)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (hg_db != null)
			{
				char sQuery[104];
				Format(sQuery, sizeof(sQuery)-1, "SELECT name, points FROM tystatsplayers ORDER BY points DESC LIMIT 10");
				SQL_TQuery(hg_db, DisplayTop10, sQuery, client, DBPrio_Low);
			}
			else
			{
				PrintToChat(client, "Connection error.");
			}
		}
	}
	return Plugin_Handled;
}

