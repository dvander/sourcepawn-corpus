/************************************************************************
*************************************************************************
gScramble menu settings 
Description:
	Menu coding for the gscramble addon
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
$Id: gscramble_menu_settings.sp 112 2011-01-29 01:48:55Z brutalgoergectf $
$Author: brutalgoergectf $
$Revision: 112 $
$Date: 2011-01-28 18:48:55 -0700 (Fri, 28 Jan 2011) $
$LastChangedBy: brutalgoergectf $
$LastChangedDate: 2011-01-28 18:48:55 -0700 (Fri, 28 Jan 2011) $
$URL: https://tf2tmng.googlecode.com/svn/trunk/gscramble/addons/sourcemod/scripting/gscramble/gscramble_menu_settings.sp $
$Copyright: (c) Tf2Tmng 2009-2011$
*************************************************************************
*************************************************************************
*/

public OnAdminMenuReady(Handle:topmenu)
{
	if (!GetConVarBool(cvar_MenuIntegrate))
		return;
	
	if (topmenu == g_hAdminMenu)
		return;
	g_hAdminMenu = topmenu;
	new TopMenuObject:menu_category = FindTopMenuCategory(topmenu, ADMINMENU_SERVERCOMMANDS);
	
	if (menu_category != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hAdminMenu, "gScramble", TopMenuObject_Item, Handle_Category, menu_category);
	}
}

public Handle_Category(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "gScramble Commands");
		case TopMenuAction_SelectOption:
		{
			Format(buffer, maxlength, "Select a Function");
			decl String:sBuffer[33];
			new Handle:hScrambleOptionsMenu = CreateMenu(Handle_ScrambleFunctionMenu);
			SetMenuTitle(hScrambleOptionsMenu, "Choose A Function");
			SetMenuExitButton(hScrambleOptionsMenu, true);
			SetMenuExitBackButton(hScrambleOptionsMenu, true);
			if (CheckCommandAccess(param, "sm_scrambleround", ADMFLAG_BAN))
			{
				AddMenuItem(hScrambleOptionsMenu, "0", "Start a Scramble");
			}
			if (CheckCommandAccess(param, "sm_scramblevote", ADMFLAG_BAN))
			{
				AddMenuItem(hScrambleOptionsMenu, "1", "Start a Vote");
				Format(sBuffer, sizeof(sBuffer), "Reset %i Vote(s)", g_iVotes);
				AddMenuItem(hScrambleOptionsMenu, "2", sBuffer);
			}
			if (CheckCommandAccess(param, "sm_forcebalance", ADMFLAG_BAN))
			{
				AddMenuItem(hScrambleOptionsMenu, "3", "Force Team Balance");
			}
			if (CheckCommandAccess(param, "sm_cancel", ADMFLAG_BAN))
			{
				if (g_bScrambleNextRound || g_hScrambleDelay != INVALID_HANDLE)
				{
					Format( sBuffer, sizeof(sBuffer), "Cancel (Pending Scramble)");
					AddMenuItem(hScrambleOptionsMenu, "4", sBuffer);
				}					
				else if (g_bAutoScramble && g_RoundState == bonusRound)
				{
					Format( sBuffer, sizeof(sBuffer), "Cancel (Auto-Scramble Check)");
					AddMenuItem(hScrambleOptionsMenu, "4", sBuffer);
				}
			}
			DisplayMenu(hScrambleOptionsMenu, param, MENU_TIME_FOREVER);
		}
	}
}

/*******************************************
			tedious menu stuff
********************************************/

ShowScrambleVoteMenu(client)
{
	new Handle:scrambleVoteMenu = INVALID_HANDLE;
	scrambleVoteMenu = CreateMenu(Handle_ScrambleVote);
	
	SetMenuTitle(scrambleVoteMenu, "Choose a Method");
	SetMenuExitButton(scrambleVoteMenu, true);
	SetMenuExitBackButton(scrambleVoteMenu, true);
	AddMenuItem(scrambleVoteMenu, "round", "Vote for End-of-Round Scramble");
	AddMenuItem(scrambleVoteMenu, "now", "Vote for Scramble Now");
	DisplayMenu(scrambleVoteMenu, client, MENU_TIME_FOREVER);
}

ShowScrambleSelectionMenu(client)
{
	new Handle:scrambleMenu = INVALID_HANDLE;
	scrambleMenu = CreateMenu(Handle_Scramble);
	
	SetMenuTitle(scrambleMenu, "Choose a Method");
	SetMenuExitButton(scrambleMenu, true);
	SetMenuExitBackButton(scrambleMenu, true);
	AddMenuItem(scrambleMenu, "round", "Scramble Next Round");
	if (CheckCommandAccess(client, "sm_scramble", ADMFLAG_BAN))
		AddMenuItem(scrambleMenu, "now", "Scramble Teams Now");
	DisplayMenu(scrambleMenu, client, MENU_TIME_FOREVER);
}

public Handle_ScrambleFunctionMenu(Handle:functionMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:sOption[2];
			GetMenuItem(functionMenu, param2, sOption, sizeof(sOption));
			switch (StringToInt(sOption))
			{
				case 0:
					ShowScrambleSelectionMenu(client);
				case 1:
					ShowScrambleVoteMenu(client);
				case 2:
					PerformVoteReset(client);
				case 3:
					PerformBalance(client);
				case 4: 
					PerformCancel(client);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack )
				RedisplayAdminMenu(g_hAdminMenu, client);
		}		
		case MenuAction_End:
			CloseHandle(functionMenu);
	}
}

public Handle_ScrambleVote(Handle:scrambleVoteMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:method[6], ScrambleTime:iMethod;
			GetMenuItem(scrambleVoteMenu, param2, method, sizeof(method));
			if (StrEqual(method, "round", true))
				iMethod = Scramble_Round;			
			else
				iMethod = Scramble_Now;
			PerformVote(client, iMethod);			
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack )
				RedisplayAdminMenu(g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(scrambleVoteMenu);	
	}
}

public Handle_Scramble(Handle:scrambleMenu, MenuAction:action, client, param2 )
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!param2)
				SetupRoundScramble(client);
			else
			{
				new Handle:scrambleNowMenu = INVALID_HANDLE;
				scrambleNowMenu = CreateMenu(Handle_ScrambleNow);
				
				SetMenuTitle(scrambleNowMenu, "Choose a Method");
				SetMenuExitButton(scrambleNowMenu, true);
				SetMenuExitBackButton(scrambleNowMenu, true);
				AddMenuItem(scrambleNowMenu, "5", "Delay 5 seconds");
				AddMenuItem(scrambleNowMenu, "15", "Delay 15 seconds");
				AddMenuItem(scrambleNowMenu, "30", "Delay 30 seconds");
				AddMenuItem(scrambleNowMenu, "60", "Delay 60 seconds");
				DisplayMenu(scrambleNowMenu, client, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack )
				RedisplayAdminMenu(g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(scrambleMenu);	
	}
}

public Handle_ScrambleNow(Handle:scrambleNowMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new Handle:respawnSelectMenu = INVALID_HANDLE;
			respawnSelectMenu = CreateMenu(Handle_RespawnMenu);
		
			if (g_hScrambleNowPack != INVALID_HANDLE)
				CloseHandle(g_hScrambleNowPack);
			g_hScrambleNowPack= CreateDataPack();
		
			SetMenuTitle(respawnSelectMenu, "Respawn Players After Scramble?");
			SetMenuExitButton(respawnSelectMenu, true);
			SetMenuExitBackButton(respawnSelectMenu, true);
		
			AddMenuItem(respawnSelectMenu, "Yep", "Yes");
			AddMenuItem(respawnSelectMenu, "Noep", "No");
			DisplayMenu(respawnSelectMenu, client, MENU_TIME_FOREVER);
			new String:delay[3];
			GetMenuItem(scrambleNowMenu, param2, delay, sizeof(delay));		
			WritePackFloat(g_hScrambleNowPack, StringToFloat(delay));
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack )
				RedisplayAdminMenu( g_hAdminMenu, client );
		}
	
		case MenuAction_End:
			CloseHandle(scrambleNowMenu);
	}
}

public Handle_RespawnMenu(Handle:scrambleResetMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new respawn = !param2 ? 1 : 0 ;
			WritePackCell(g_hScrambleNowPack, respawn);
			
			new Handle:modeSelectMenu = INVALID_HANDLE;
			modeSelectMenu = CreateMenu(Handle_ModeMenu);
			
			SetMenuTitle(modeSelectMenu, "Select a scramble sort mode");
			SetMenuExitButton(modeSelectMenu, true);
			SetMenuExitBackButton(modeSelectMenu, true);
			
			AddMenuItem(modeSelectMenu, "1", "Random");
			AddMenuItem(modeSelectMenu, "2", "Player-Score");
			AddMenuItem(modeSelectMenu, "3", "Player-Score^2/Connect time (in minutes)");
			AddMenuItem(modeSelectMenu, "4", "Player kill-Death ratios");
			AddMenuItem(modeSelectMenu, "5", "Swap the top players on each team");
			
			if (g_bUseGameMe)
			{
				AddMenuItem(modeSelectMenu, "6", "Use GameME Rank");
				AddMenuItem(modeSelectMenu, "7", "Use GameME Skill");
				AddMenuItem(modeSelectMenu, "8", "Use GameME Global Rank");
				AddMenuItem(modeSelectMenu, "9", "Use GameME Global Skill");
				AddMenuItem(modeSelectMenu, "10", "Use GameME Session Skill Change");
			}
			if (g_bUseHlxCe)
			{
				AddMenuItem(modeSelectMenu, "11", "Use HlxCe Rank");
				AddMenuItem(modeSelectMenu, "12", "Use HlxCe Skill");
			}
			AddMenuItem(modeSelectMenu, "13", "Sort By Player Classes");
			AddMenuItem(modeSelectMenu, "14", "Random Sort-Mode");
			DisplayMenu(modeSelectMenu, client, MENU_TIME_FOREVER);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				RedisplayAdminMenu( g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(scrambleResetMenu);
			
	}
}

public Handle_ModeMenu(Handle:modeMenu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			ResetPack(g_hScrambleNowPack);
			new e_ScrambleModes:mode,
				Float:delay = ReadPackFloat(g_hScrambleNowPack),
				bool:respawn = ReadPackCell(g_hScrambleNowPack) ? true : false;
			mode = e_ScrambleModes:(param2+1);
			CloseHandle(g_hScrambleNowPack);
			g_hScrambleNowPack = INVALID_HANDLE;
			PerformScrambleNow(client, delay, respawn, mode);		
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				RedisplayAdminMenu( g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(modeMenu);
	}
}

	/**
	find anyone who was recently teamswapped as a result of our reconnecting person
	and ask if they want to get put back on their old team
	*/	
RestoreMenuCheck(rejoinClient, team)
{
/**
find out who was the last one swapped
*/
	new client, iTemp;
	for (new i = 1; i<= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if (g_aPlayers[i][iBalanceTime] > GetTime() && g_aPlayers[i][iBalanceTime] > iTemp)
			{
				client = i;
				iTemp = g_aPlayers[i][iBalanceTime];
			}
		}
	}
	if (!client)
		return;
	decl String:name[MAX_NAME_LENGTH+1];
	GetClientName(rejoinClient, name, sizeof(name));
	
	PrintToChat(client, "\x01\x04[SM]\x01 %t", "RestoreInnocentTeam", name);
	
	new Handle:RestoreMenu = INVALID_HANDLE;
	RestoreMenu = CreateMenu(Handle_RestoreMenu);
	
	SetMenuTitle(RestoreMenu, "Retore your old team?");
	AddMenuItem(RestoreMenu, "yes", "Yes");
	AddMenuItem(RestoreMenu, "no", "No");
	DisplayMenu(RestoreMenu, client, 20);
}

AddBuddy(client, buddy)
{
	if (!client || !buddy || !IsClientInGame(client) || !IsClientInGame(buddy) || client == buddy)
		return;
	if (g_aPlayers[buddy][iBuddy])
	{
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "AlreadyHasABuddy");
		return;
	}
	new String:clientName[MAX_NAME_LENGTH],
		String:buddyName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(buddy, buddyName, sizeof(buddyName));
	
	if (g_aPlayers[client][iBuddy])
		PrintToChat(g_aPlayers[client][iBuddy], "\x01\x04[SM]\x01 %t", "ChoseANewBuddy", clientName);
	
	g_aPlayers[client][iBuddy] = buddy;
	PrintToChat(buddy, "\x01\x04[SM]\x01 %t", "SomeoneAddedYou", clientName);
	PrintToChat(client, "\x01\x04[SM]\x01 %t", "AddedBuddy", buddyName);
}

ShowBuddyMenu(client)
{
	new Handle:menu = INVALID_HANDLE;
	menu = CreateMenu(BuddyMenuCallback);
	AddTargetsToMenu(menu,0);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BuddyMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:selection[10];
			GetMenuItem(menu, param2, selection, sizeof(selection));
			AddBuddy(client, GetClientOfUserId(StringToInt(selection)));			
		}
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

/**
 ask a client if they want to rejoin their old team when they get balanced due to a disconnecting player
 and that player reconnects and gets forced back to his old team
*/
public Handle_RestoreMenu(Handle:RestoreMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!param2)
			{
				decl String:name[MAX_NAME_LENGTH+1];
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x01\x04[SM]\x01 %t", "RejoinMessage", name);
				g_bBlockDeath = true;
				CreateTimer(0.1, Timer_BalanceSpawn, GetClientUserId(client));
				ChangeClientTeam(client, GetClientTeam(client) == TEAM_RED ? TEAM_BLUE : TEAM_RED);
				g_bBlockDeath = false;
				g_aPlayers[client][iBalanceTime] = GetTime();
			}
		}
	
		case MenuAction_End:
			CloseHandle(RestoreMenu);
	}
}
