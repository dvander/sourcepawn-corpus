#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

static const char PLUGIN_VERSION[] = "2.0.2";

bool g_cursed[MAXPLAYERS+1] = { false, ... };

ConVar g_cvar_strafe = null;
ConVar g_cvar_walk = null;
ConVar g_cvar_vote_curse = null;

TopMenu g_topmenu = null;

int g_vote_target_list_userid[MAXPLAYERS];
int g_vote_target_count;
char g_vote_target_name[MAX_TARGET_LENGTH];

public Plugin myinfo = {
	name = "sm_curse",
	author = "Farbror Godis",
	description = "Allows admins to invert the movement of selected players.",
	version = PLUGIN_VERSION,
	url = "sm.alliedmods.net"
};

public void OnPluginStart() {
	CreateConVar("sm_curse_version", PLUGIN_VERSION, "Current sm_curse version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_cvar_strafe = CreateConVar("sm_curse_invert_strafe", "1.0", "Invert movement while strafing (left & right)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_walk = CreateConVar("sm_curse_invert_walk", "1.0", "Invert movement while walking (forwards & backwards)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_vote_curse = CreateConVar("sm_vote_curse", "0.60", "Percentage of votes required for a successful curse vote", FCVAR_NONE, true, 0.01, true, 1.0);

	LoadTranslations("sm_curse.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");

	RegAdminCmd("sm_curse", ConCmd_Curse, ADMFLAG_SLAY, "sm_curse <#userid|name> [0/1]");
	RegAdminCmd("sm_votecurse", ConCmd_VoteCurse, ADMFLAG_SLAY|ADMFLAG_VOTE, "sm_votecurse <#userid|name>");

	TopMenu topmenu = GetAdminTopMenu();
	if(LibraryExists("adminmenu") && topmenu != null) {
		OnAdminMenuReady(topmenu);
	}

	AutoExecConfig(true);
}

public void OnAdminMenuReady(Handle topmenu) {
	TopMenu temp = TopMenu.FromHandle(topmenu);
	if(temp == g_topmenu) {
		return;
	}

	g_topmenu = temp;

	TopMenuObject player_commands = g_topmenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	TopMenuObject voting_commands = g_topmenu.FindCategory(ADMINMENU_VOTINGCOMMANDS);

	if(player_commands != INVALID_TOPMENUOBJECT) {
		g_topmenu.AddItem("sm_curse", AdminMenu_Curse, player_commands, "sm_curse", ADMFLAG_SLAY);
		g_topmenu.AddItem("sm_votecurse", AdminMenu_VoteCurse, voting_commands, "sm_votecurse", ADMFLAG_SLAY|ADMFLAG_VOTE);
	}
}

public void OnClientPutInServer(int client) {
	g_cursed[client] = false;
}

public void OnClientDisconnect(int client) {
	g_cursed[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon) {
	if(!g_cursed[client]) {
		return Plugin_Continue;
	}

	if(g_cvar_strafe.BoolValue) {
		velocity[1] = -velocity[1];
		
		if(buttons & IN_MOVELEFT) {
			buttons &= ~IN_MOVELEFT;
			buttons |= IN_MOVERIGHT;
		} else if(buttons & IN_MOVERIGHT) {
			buttons &= ~IN_MOVERIGHT;
			buttons |= IN_MOVELEFT;
		}
	}

	if(g_cvar_walk.BoolValue) {
		velocity[0] = -velocity[0];

		if(buttons & IN_FORWARD) {
			buttons &= ~IN_FORWARD;
			buttons |= IN_BACK;
		} else if(buttons & IN_BACK) {
			buttons &= ~IN_BACK;
			buttons |= IN_FORWARD;
		}
	}

	return Plugin_Changed;
}

public Action ConCmd_Curse(int client, int args) {
	if(args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_curse <#userid|name> [0/1]");
		return Plugin_Handled;
	}

	char arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));

	int toggle = 2;
	if(args > 1) {
		char arg2[32];
		GetCmdArg(2, arg2, sizeof(arg2));

		toggle = StringToInt(arg2) ? 1 : 0;
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++) {
		PerformCurse(client, target_list[i], toggle);
	}

	if(tn_is_ml) {
		ShowActivity2(client, "[SM] ", "%t", "Toggled curse on target", target_name);
	} else {
		ShowActivity2(client, "[SM] ", "%t", "Toggled curse on target", "_s", target_name);
	}

	return Plugin_Handled;
}

public Action ConCmd_VoteCurse(int client, int args) {
	if(args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_votecurse <#userid|name>");
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	if(IsVoteInProgress()) {
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}

	int vote_delay = CheckVoteDelay();
	if(vote_delay > 0) {
		if(vote_delay > 60) {
			ReplyToCommand(client, "[SM] %t", "Vote Delay Minutes", vote_delay % 60);
		} else {
			ReplyToCommand(client, "[SM] %t", "Vote Delay Seconds", vote_delay);
		}

		return Plugin_Handled;
	}

	bool tn_is_ml;
	int target_list[MAXPLAYERS];
	if((g_vote_target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			0,
			g_vote_target_name,
			sizeof(g_vote_target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, g_vote_target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < g_vote_target_count; i++) {
		g_vote_target_list_userid[i] = GetClientUserId(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" initiated a curse vote on \"%L\"", client, target_list[i]);
	}

	if(tn_is_ml) {
		ShowActivity2(client, "[SM] ", "%t", "Initiated a curse vote", g_vote_target_name);
	} else {
		ShowActivity2(client, "[SM] ", "%t", "Initiated a curse vote", "_s", g_vote_target_name);
	}

	DisplayVoteCurseMenu(tn_is_ml);

	return Plugin_Handled;
}

public void AdminMenu_Curse(Handle topmenu,
							TopMenuAction action,
							TopMenuObject object_id,
							int param,
							char[] buffer,
							int maxlen)
{
	if(action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlen, "%T", "Curse player", param);
	} else if(action == TopMenuAction_SelectOption) {
		DisplayCurseTargetMenu(param);
	}
}

public void AdminMenu_VoteCurse(Handle topmenu,
							TopMenuAction action,
							TopMenuObject object_id,
							int param,
							char[] buffer,
							int maxlen)
{
	if(action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlen, "%T", "Curse vote", param);
	} else if(action == TopMenuAction_SelectOption) {
		DisplayVoteCurseTargetMenu(param);
	} else if(action == TopMenuAction_DrawOption) {
		buffer[0] = IsNewVoteAllowed() ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
	}
}

public int MenuHandler_CurseTarget(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_Select) {
		char info[32];
		menu.GetItem(param2, info, sizeof(info));

		int target, userid = StringToInt(info);
		if((target = GetClientOfUserId(userid)) == 0) {
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		} else if(!CanUserTarget(param1, target)) {
			PrintToChat(param1, "[SM] %t", "Unable to target");
		} else {
			char target_name[MAX_NAME_LENGTH];
			GetClientName(target, target_name, sizeof(target_name));

			PerformCurse(param1, target, 2);
			ShowActivity2(param1, "[SM] ", "%t", "Toggled curse on target", "_s", target_name);
		}

		if(IsClientInGame(param1) && !IsClientInKickQueue(param1)) {
			DisplayCurseTargetMenu(param1);
		}
	} else if(action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack && (g_topmenu != null)) {
			g_topmenu.Display(param1, TopMenuPosition_LastCategory);
		}
	} else if(action == MenuAction_End) {
		delete menu;
	}

	return 0;
}

public int MenuHandler_CurseVoteTarget(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_Select) {
		char info[32];
		menu.GetItem(param2, info, sizeof(info));

		int userid = StringToInt(info);
		int target = GetClientOfUserId(userid);
		if(target == 0) {
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		} else if(!CanUserTarget(param1, target)) {
			PrintToChat(param1, "[SM] %t", "Unable to target");
		} else {
			GetClientName(target, g_vote_target_name, sizeof(g_vote_target_name));
			g_vote_target_list_userid[0] = userid;
			g_vote_target_count = 1;

			ShowActivity2(param1, "[SM] ", "%t", "Initiated a curse vote", "_s", g_vote_target_name);
			LogAction(param1, target, "\"%L\" initiated a curse vote on \"%L\"", param1, target);

			DisplayVoteCurseMenu(false);
		}
	} else if(action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack && (g_topmenu != null)) {
			g_topmenu.Display(param1, TopMenuPosition_LastCategory);
		}
	} else if(action == MenuAction_End) {
		delete menu;
	}

	return 0;
}

void PerformCurse(int client, int target, int toggle) {
	if(toggle == 2) {
		toggle = (g_cursed[target] ? 0 : 1);
	}

	if(toggle == 0 && g_cursed[target]) {
		if(g_cursed[target]) {
			g_cursed[target] = false;
			LogAction(client, target, "\"%L\" removed the curse on \"%L\"", client, target);
		}
	} else if(toggle == 1 && !g_cursed[target]) {
		if(!g_cursed[target]) {
			g_cursed[target] = true;
			LogAction(client, target, "\"%L\" put a curse on \"%L\"", client, target);
		}
	}
}

void DisplayCurseTargetMenu(int client) {
	Menu menu = new Menu(MenuHandler_CurseTarget);
	menu.SetTitle("%T:", "Curse player", client);

	AddTargetsToMenu(menu, client, true, false);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayVoteCurseTargetMenu(int client) {
	Menu menu = new Menu(MenuHandler_CurseVoteTarget);
	menu.SetTitle("%T:", "Curse vote", client);

	AddTargetsToMenu(menu, client, true, false);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayVoteCurseMenu(bool tn_is_ml) {
	Menu menu = new Menu(MenuHandler_CurseVote, MENU_ACTIONS_ALL);

	char title[64];
	if(tn_is_ml) {
		Format(title, sizeof(title), "%t", "Curse vote target", g_vote_target_name);
	} else {
		Format(title, sizeof(title), "%t", "Curse vote target", "_s", g_vote_target_name);
	}
	menu.SetTitle(title);

	char buffer[32];

	Format(buffer, sizeof(buffer), "%t", "Yes");
	menu.AddItem("0", buffer);

	Format(buffer, sizeof(buffer), "%t", "No");
	menu.AddItem("1", buffer);

	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

public int MenuHandler_CurseVote(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_VoteEnd) {
		int votes, total_votes;
		GetMenuVoteInfo(param2, votes, total_votes);

		float percent = FloatDiv(float(votes), float(total_votes));
		float limit = g_cvar_vote_curse.FloatValue;

		if(param1 == 0 && FloatCompare(percent, limit) > 0) {
			PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0 * percent), total_votes);

			for(int i = 0; i < g_vote_target_count; i++) {
				int client = GetClientOfUserId(g_vote_target_list_userid[i]);
				if(client > 0 && client <= MaxClients && IsClientInGame(client)) {
					LogAction(-1, client, "Vote curse successful, cursing \"%L\"", client);
					g_cursed[client] = true;
				}
			}
		} else {
			LogAction(-1, -1, "Vote curse failed");
			PrintToChatAll("[SM] %t", "Vote Failed", RoundToNearest(100.0 * limit), RoundToNearest(100.0 * percent), total_votes);
		}

	} else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes) {
		PrintToChatAll("[SM] %t", "No Votes Cast");
	} else if(action == MenuAction_End) {
		delete menu;
	}

	return 0;
}
