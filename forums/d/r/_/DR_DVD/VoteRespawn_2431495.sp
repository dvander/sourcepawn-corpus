#include <sourcemod>
#include <nativevotes>

ConVar g_respawnTimesDisabled;
ConVar g_voteRespawnEnabled;
ConVar g_voteRespawnCooldown;
bool g_VoteAllowed = true;
bool g_NativeVotes;
new Handle:g_hVoteMenu = INVALID_HANDLE;

#define VOTE_NAME	0
#define VOTE_AUTHID	1
#define	VOTE_IP		2
new String:g_voteInfo[3][65];	/* Holds the target's name, authid, and IP */

#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

public Plugin myinfo =
{
	name = "Vote Respawn Times",
	author = "DR.DVD",
	description = "Allow players to vote whether to enable/disable default respawn times.",
	version = "1.0",
	url = "http://www.rebelgamersclan.es/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	LoadTranslations("voterespawn.phrases");
	g_respawnTimesDisabled = FindConVar("mp_disable_respawn_times");
	g_voteRespawnEnabled = CreateConVar("sm_voterespawn_enabled", "1", "Sets whether the plugin is enabled.");
	g_voteRespawnCooldown = CreateConVar("sm_voterespawn_cooldown", "300", "Sets the default cooldown time, in seconds, before another vote can take place.");
	RegConsoleCmd("voterespawn", Command_voterespawn);
}

public OnAllPluginsLoaded()
{
	g_NativeVotes = LibraryExists("nativevotes") && NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_YesNo);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "nativevotes") && NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_YesNo))
	{
		g_NativeVotes = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "nativevotes"))
	{
		g_NativeVotes = false;
	}
}

public Action Command_voterespawn(int client, int args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
	if (!g_VoteAllowed) {
		ReplyToCommand(client, "[SM] %t", "Wait before vote again");
		return Plugin_Handled;
	}
	if (g_NativeVotes)
	{
		g_hVoteMenu = NativeVotes_Create(Handler_NativeVoteCallback, NativeVotesType_Custom_YesNo, MenuAction:MENU_ACTIONS_ALL);
		if (GetConVarBool(g_respawnTimesDisabled))
		{
			NativeVotes_SetTitle(g_hVoteMenu, "Vote enable respawn times");
		}
		else
		{
			NativeVotes_SetTitle(g_hVoteMenu, "Vote disable respawn times");
		}
		NativeVotes_DisplayToAll(g_hVoteMenu, 20);
	}
	else {
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		if (GetConVarBool(g_respawnTimesDisabled))
		{
			SetMenuTitle(g_hVoteMenu, "Vote enable respawn times");
		}
		else
		{
			SetMenuTitle(g_hVoteMenu, "Vote disable respawn times");
		}
		AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
		AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);
	}
	return Plugin_Handled;
}

public int Handler_VoteCallback(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char title[64];
			GetMenuTitle(menu, title, sizeof(title));
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", title, param1, g_voteInfo[VOTE_NAME]);
			Panel panel = Panel:param2;
			panel.SetTitle(buffer);
		}
		case MenuAction_DisplayItem:
		{
			char display[64];
			GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
			if (strcmp(display, VOTE_NO) == 0 || strcmp(display, VOTE_YES) == 0)
			{
				char buffer[255];
				Format(buffer, sizeof(buffer), "%T", display, param1);
				return RedrawMenuItem(buffer);
			}
		}
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes) {
				PrintToChatAll("[SM] %t", "No Votes Cast");
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_VoteEnd:
		{
			g_VoteAllowed = false;
			char item[64], buffer[128];
			float percent, otherPercent, time;
			int votes, totalVotes;
			GetConVarString(g_voteRespawnCooldown, buffer, sizeof(buffer));
			time = StringToFloat(buffer);
			GetMenuVoteInfo(param2, votes, totalVotes);
			GetMenuItem(menu, param1, item, sizeof(item));
			percent = FloatDiv(float(votes),float(totalVotes));
			otherPercent = 1.0 - percent;
			if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
			{
				LogAction(-1, -1, "Vote failed.");
				PrintToChatAll("[SM] %t", "Voted not change respawntimes", RoundToNearest(100.0*otherPercent), RoundToNearest(100.0*percent), totalVotes);
			} else if (strcmp(item, VOTE_YES) == 0 && param1 == 0) {
				PrintToChatAll("[SM] %t", "Voted change respawntimes", RoundToNearest(100.0*percent), RoundToNearest(100.0*otherPercent), totalVotes);
				g_respawnTimesDisabled.BoolValue = !g_respawnTimesDisabled.BoolValue;
			} else {
				PrintToChatAll("[SM] %t", "Not enough people voted respawntimes")
			}
			if (GetConVarBool(g_respawnTimesDisabled)) {
				PrintToChatAll("[SM] %t", "Respawn times disabled");
			} else {
				PrintToChatAll("[SM] %t", "Respawn times enabled");
			}
			CreateTimer(time, Timer_RespawnVoteTimer);
		}
	}
	return 0;
}

public int Handler_NativeVoteCallback(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			new NativeVotesType:nVoteType = NativeVotes_GetType(menu);
			if (nVoteType == NativeVotesType_Custom_YesNo || nVoteType == NativeVotesType_Custom_Mult)
			{
				char title[64];
				NativeVotes_GetTitle(menu, title, sizeof(title));
				char buffer[255];
				Format(buffer, sizeof(buffer), "%T", title, param1, g_voteInfo[VOTE_NAME]);
				return _:NativeVotes_RedrawVoteTitle(buffer);
			}
		}
		case MenuAction_DisplayItem:
		{
			char display[64];
			NativeVotes_GetItem(menu, param2, display, sizeof(display));
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", display, param1);
			return _:NativeVotes_RedrawVoteItem(buffer);
		}
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
				PrintToChatAll("[SM] %t", "No Votes Cast");
			}
			else
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Generic);
			}
		}
		case MenuAction_End:
		{
			NativeVotes_Close(menu);
		}
		case MenuAction_VoteEnd:
		{
			new NativeVotesType:nVoteType = NativeVotes_GetType(menu);
			g_VoteAllowed = false;
			char item[64], buffer[128];
			float percent, otherPercent, time;
			int votes, totalVotes;
			GetConVarString(g_voteRespawnCooldown, buffer, sizeof(buffer));
			time = StringToFloat(buffer);
			NativeVotes_GetInfo(param2, votes, totalVotes);
			NativeVotes_GetItem(menu, param1, item, sizeof(item));
			if (nVoteType == NativeVotesType_Custom_YesNo && param1 == NATIVEVOTES_VOTE_NO)
			{
				votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
			}
			percent = FloatDiv(float(votes),float(totalVotes));
			otherPercent = 1.0 - percent;
			if ((nVoteType != NativeVotesType_NextLevelMult && nVoteType != NativeVotesType_Custom_Mult) && ((param1 == NATIVEVOTES_VOTE_NO)))
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Loses);
				LogAction(-1, -1, "Vote failed.");
				PrintToChatAll("[SM] %t", "Voted not change respawntimes", RoundToNearest(100.0*percent), RoundToNearest(100.0*otherPercent), totalVotes);
			} else {
				PrintToChatAll("[SM] %t", "Voted change respawntimes", RoundToNearest(100.0*percent), RoundToNearest(100.0*otherPercent), totalVotes);
				g_respawnTimesDisabled.BoolValue = !g_respawnTimesDisabled.BoolValue;
				NativeVotes_DisplayPassCustom(menu, "%t", (GetConVarBool(g_respawnTimesDisabled) ? "Respawn times will be disabled" : "Respawn times will be enabled"));
			}
			if (GetConVarBool(g_respawnTimesDisabled)) {
				PrintToChatAll("[SM] %t", "Respawn times disabled");
			} else {
				PrintToChatAll("[SM] %t", "Respawn times enabled");
			}
			CreateTimer(time, Timer_RespawnVoteTimer);
		}
	}
	return 0;
}

public Action Timer_RespawnVoteTimer(Handle timer)
{
	g_VoteAllowed = true;
}
