#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

new Handle:g_hVoteMenu = INVALID_HANDLE;
new Handle:g_Cvar_Limit = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Extend Map Vote",
	author = "AlliedModders LLC, mess by Bacardi",
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");

	RegAdminCmd("sm_voteextend", Command_vote_extend, ADMFLAG_CHANGEMAP);
	g_Cvar_Limit = CreateConVar("sm_vote_extend", "0.60", "percent required for successful extend vote.", 0, true, 0.05, true, 1.0);
}

public Action:Command_vote_extend(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_voteextend <minutes>");
		return Plugin_Handled;
	}

	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}

	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}

	decl value, String:text[256];
	GetCmdArg(1, text, sizeof(text));
	value = StringToInt(text);

	if(value <= 0)
	{
		ReplyToCommand(client, "[SM] Invalid value, use 1 or greater");
		return Plugin_Handled;
	}

	LogAction(client, -1, "\"%L\" initiated a extend vote %i min.", client, value);
	ShowActivity2(client, "[SM] ", "initiated a extend vote %i min", value);

	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "Extented map %i min?", value);

	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");

	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);

	return Plugin_Handled;
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	/*else if (action == MenuAction_Display)
	{
	 	if (g_voteType != voteType:question)
	 	{
			decl String:title[64];
			GetMenuTitle(menu, title, sizeof(title));

	 		decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%T", title, param1, g_voteInfo[VOTE_NAME]);

			new Handle:panel = Handle:param2;
			SetPanelTitle(panel, buffer);
		}
	}*/
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));

	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%T", display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	/* else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}*/
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %t", "No Votes Cast");
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

		limit = GetConVarFloat(g_Cvar_Limit);
		//strcopy(item, sizeof(item), display);
		/* :TODO: g_voteClient[userid] needs to be checked */

		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			/* :TODO: g_voteClient[userid] should be used here and set to -1 if not applicable.
			 */
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("[SM] %t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			GetMenuTitle(menu, item, sizeof(item));
			ReplaceString(item, sizeof(item), "?", ".");
			LogAction(-1, -1, "%s", item);
			PrintToChatAll("[SM] %s", item);

			new Handle:timelimit = FindConVar("mp_timelimit");

			if(timelimit != INVALID_HANDLE)
			{
				new value = GetConVarInt(timelimit)+StringToInt(item[13]);
				
				SetConVarInt(timelimit, value, false, false); // It still notify cvar change...
				//CloseHandle(timelimit);
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
			ReplyToCommand(client, "[SM] %t", "Vote Delay Minutes", delay % 60);
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "Vote Delay Seconds", delay);
		}

		return false;
	}

	return true;
}