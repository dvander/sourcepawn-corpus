/**
 * =============================================================================
 * SourceMod Communication Plugin Extension
 * Provides fucntionality for controlling communication on the server
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * and <eVa>StrontiumDog http://www.theville.org
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 1
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
 */
//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// Allows players to vote mute a player

// Voting adapted from AlliedModders' basevotes system
// basevotes.sp, basekick.sp
//


#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.106P" 

new Handle:g_Cvar_Limits;
new Handle:g_hVoteMenu = INVALID_HANDLE;


#define VOTE_CLIENTID	0
#define VOTE_USERID		1
#define VOTE_NAME		0
#define VOTE_NO 		"###no###"
#define VOTE_YES 		"###yes###"

new g_voteClient[2];
new String:g_voteInfo[3][65];
new String:GameName[64];

new g_votetype = 0;

new bool:g_Gagged[65];

public Plugin:myinfo =
{
	name = "Vote Mute/Vote Silence",
	author = "<eVa>Dog/AlliedModders LLC",
	description = "Vote Muting and Silencing",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_votemute_version", PLUGIN_VERSION, "Version of votemute/votesilence", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Limits = CreateConVar("sm_votemute_limit", "0.30", "percent required for successful mute vote or mute silence.")
		
	//Allowed for ALL players
	RegAdminCmd("sm_votemute", Command_Votemute, ADMFLAG_VOTE, "sm_votemute <player> ")  
	RegAdminCmd("sm_votesilence", Command_Votesilence, ADMFLAG_VOTE, "sm_votesilence <player> ")  
	RegAdminCmd("sm_votegag", Command_Votegag, ADMFLAG_VOTE, "sm_votegag <player> ") 
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("voicemenu", Command_VoiceMenu);
	
	LoadTranslations("common.phrases");
	
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "dod"))
	{
		RegConsoleCmd("voice_areaclear", Command_VoiceMenu);
		RegConsoleCmd("voice_attack", Command_VoiceMenu);
		RegConsoleCmd("voice_backup", Command_VoiceMenu);
		RegConsoleCmd("voice_bazookaspotted", Command_VoiceMenu);
		RegConsoleCmd("voice_ceasefire", Command_VoiceMenu);
		RegConsoleCmd("voice_cover", Command_VoiceMenu);
		RegConsoleCmd("voice_coverflanks", Command_VoiceMenu);
		RegConsoleCmd("voice_displace", Command_VoiceMenu);
		RegConsoleCmd("voice_dropweapons", Command_VoiceMenu);
		RegConsoleCmd("voice_enemyahead", Command_VoiceMenu);
		RegConsoleCmd("voice_enemybehind", Command_VoiceMenu);
		RegConsoleCmd("voice_gogogo", Command_VoiceMenu);
		RegConsoleCmd("voice_grenade", Command_VoiceMenu);
		RegConsoleCmd("voice_fallback", Command_VoiceMenu);
		RegConsoleCmd("voice_fireleft", Command_VoiceMenu);
		RegConsoleCmd("voice_fireinhole", Command_VoiceMenu);
		RegConsoleCmd("voice_fireright", Command_VoiceMenu);
		RegConsoleCmd("voice_hold", Command_VoiceMenu);
		RegConsoleCmd("voice_left", Command_VoiceMenu);
		RegConsoleCmd("voice_medic", Command_VoiceMenu);
		RegConsoleCmd("voice_mgahead", Command_VoiceMenu);
		RegConsoleCmd("voice_moveupmg", Command_VoiceMenu);
		RegConsoleCmd("voice_needammo", Command_VoiceMenu);
		RegConsoleCmd("voice_negative", Command_VoiceMenu);
		RegConsoleCmd("voice_niceshot", Command_VoiceMenu);
		RegConsoleCmd("voice_right", Command_VoiceMenu);
		RegConsoleCmd("voice_sniper", Command_VoiceMenu);
		RegConsoleCmd("voice_sticktogether", Command_VoiceMenu);
		RegConsoleCmd("voice_takeammo", Command_VoiceMenu);
		RegConsoleCmd("voice_thanks", Command_VoiceMenu);
		RegConsoleCmd("voice_usebazooka", Command_VoiceMenu);
		RegConsoleCmd("voice_usegrens", Command_VoiceMenu);
		RegConsoleCmd("voice_usesmoke", Command_VoiceMenu);
		RegConsoleCmd("voice_wegothim", Command_VoiceMenu);
		RegConsoleCmd("voice_wtf", Command_VoiceMenu);
		RegConsoleCmd("voice_yessir", Command_VoiceMenu);
	}
	
	if (StrEqual(GameName, "cstrike"))
	{
		RegConsoleCmd("coverme", Command_VoiceMenu);
		RegConsoleCmd("enemydown", Command_VoiceMenu);
		RegConsoleCmd("enemyspot", Command_VoiceMenu);
		RegConsoleCmd("fallback", Command_VoiceMenu);
		RegConsoleCmd("followme", Command_VoiceMenu);
		RegConsoleCmd("getinpos", Command_VoiceMenu);
		RegConsoleCmd("getout", Command_VoiceMenu);
		RegConsoleCmd("go", Command_VoiceMenu);
		RegConsoleCmd("holdpos", Command_VoiceMenu);
		RegConsoleCmd("inposition", Command_VoiceMenu);
		RegConsoleCmd("needbackup", Command_VoiceMenu);
		RegConsoleCmd("negative", Command_VoiceMenu);
		RegConsoleCmd("regroup", Command_VoiceMenu);
		RegConsoleCmd("report", Command_VoiceMenu);
		RegConsoleCmd("reportingin", Command_VoiceMenu);
		RegConsoleCmd("roger", Command_VoiceMenu);
		RegConsoleCmd("sticktog", Command_VoiceMenu);
		RegConsoleCmd("takepoint", Command_VoiceMenu);
		RegConsoleCmd("takingfire", Command_VoiceMenu);
		RegConsoleCmd("sectorclear", Command_VoiceMenu);
		RegConsoleCmd("stormfront", Command_VoiceMenu);
	}
	
	if (StrEqual(GameName, "insurgency"))
	{
		RegConsoleCmd("say2", Command_Say);
	}
}

public OnClientDisconnect(client)
{
	if (client != 0)
	{
		g_Gagged[client] = false;
		SetClientListeningFlags(client, VOICE_NORMAL);
	}
}

public Action:Command_Say(client, args)
{
	if (client)
	{
		if (g_Gagged[client])
		{
			return Plugin_Handled;		
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_VoiceMenu(client, args)
{
	if (client)
	{
		if (g_Gagged[client])
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

	
public Action:Command_Votemute(client, args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		g_votetype = 0;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		new String:arg[64];
		GetCmdArg(1, arg, 64);
		
		new target = FindTarget(client, arg);

		if (target == -1)
		{
			return Plugin_Handled;
		}
		
		g_votetype = 0;
		DisplayVoteMuteMenu(client, target);
	}
	
	return Plugin_Handled
}

public Action:Command_Votesilence(client, args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		g_votetype = 1;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		new String:arg[64];
		GetCmdArg(1, arg, 64);
		
		new target = FindTarget(client, arg);

		if (target == -1)
		{
			return Plugin_Handled;
		}
		
		g_votetype = 1;
		DisplayVoteMuteMenu(client, target);
	}
	return Plugin_Handled
}

public Action:Command_Votegag(client, args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		g_votetype = 2;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		new String:arg[64];
		GetCmdArg(1, arg, 64);
		
		new target = FindTarget(client, arg);

		if (target == -1)
		{
			return Plugin_Handled;
		}
		
		g_votetype = 2;
		DisplayVoteMuteMenu(client, target);
	}
	return Plugin_Handled;
}

//########################### MENUS ########################################

DisplayVoteTargetMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Vote);
	
	decl String:title[100];
	Format(title, sizeof(title), "%s", "Choose player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public MenuHandler_Vote(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32], String:name[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target");
		}
		else
		{
			DisplayVoteMuteMenu(param1, target);
		}
	}
}

DisplayVoteMuteMenu(client, target)
{
	g_voteClient[VOTE_CLIENTID] = target;
	g_voteClient[VOTE_USERID] = GetClientUserId(target);

	GetClientName(target, g_voteInfo[VOTE_NAME], sizeof(g_voteInfo[]));

	if (g_votetype == 0)
	{
		LogAction(client, target, "\"%L\" initiated a mute vote against \"%L\"", client, target);
		ShowActivity(client, "%s", "Initiated Vote Mute", g_voteInfo[VOTE_NAME]);
		
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "Mute Player:");
	}
	else if (g_votetype == 1)
	{
		LogAction(client, target, "\"%L\" initiated a silence vote against \"%L\"", client, target);
		ShowActivity(client, "%s", "Initiated Vote Silence", g_voteInfo[VOTE_NAME]);
		
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "Silence Player:");
	}
	else 
	{
		LogAction(client, target, "\"%L\" initiated a gag vote against \"%L\"", client, target);
		ShowActivity(client, "%s", "Initiated Vote Gag", g_voteInfo[VOTE_NAME]);
		
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "Gag Player:");
	}
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}


public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
		decl String:title[64];
		GetMenuTitle(menu, title, sizeof(title));
		
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%s %s", title, g_voteInfo[VOTE_NAME]);

		new Handle:panel = Handle:param2;
		SetPanelTitle(panel, buffer);
	}
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%s", display);

			return RedrawMenuItem(buffer);
		}
	}
	/* else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}*/
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %s", "No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		decl String:item[64], String:display[64];
		new Float:percent, Float:limit, votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = GetVotePercent(votes, totalVotes);
		
		limit = GetConVarFloat(g_Cvar_Limits);
		
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("[SM] %s", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("[SM] %s", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);			
			if (g_votetype == 0)
			{
				PrintToChatAll("[SM] %s", "Muted target", "_s", g_voteInfo[VOTE_NAME]);
				LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote mute successful, muted \"%L\" ", g_voteClient[VOTE_CLIENTID]);
				SetClientListeningFlags( g_voteClient[VOTE_CLIENTID], VOICE_MUTED);					
			}
			else if (g_votetype == 1)
			{
				PrintToChatAll("[SM] %s", "Silenced target", "_s", g_voteInfo[VOTE_NAME]);	
				LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote silence successful, silenced \"%L\" ", g_voteClient[VOTE_CLIENTID]);
				SetClientListeningFlags( g_voteClient[VOTE_CLIENTID], VOICE_MUTED);
				g_Gagged[g_voteClient[VOTE_CLIENTID]] = true;
			}		
			else 
			{
				PrintToChatAll("[SM] %s", "Gagged target", "_s", g_voteInfo[VOTE_NAME]);	
				LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote gag successful, gagged \"%L\" ", g_voteClient[VOTE_CLIENTID]);
				g_Gagged[g_voteClient[VOTE_CLIENTID]] = true;
			}	
		}
	}
	return 0;
}

VoteMenuClose()
{
	CloseHandle(g_hVoteMenu);
	g_hVoteMenu = INVALID_HANDLE;
}

Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}

bool:TestVoteDelay(client)
{
 	new delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			ReplyToCommand(client, "[SM] Vote delay: %i mins", delay % 60);
 		}
 		else
 		{
 			ReplyToCommand(client, "[SM] Vote delay: %i secs", delay);
 		}
 		
 		return false;
 	}
 	
	return true;
}