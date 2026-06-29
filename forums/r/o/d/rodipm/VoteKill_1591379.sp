#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Vote Kill",
	author = "rodipm",
	description = "Creates a vote to kill/slay a player",
	version = "1.0",
	url = "sourcemod.net"
}

new bool:b_VoteInProgress;
new VoteTarget;

public OnPluginStart()
{
	LoadTranslations("VoteKill.phrases");
	RegAdminCmd("votekill_cancel", AdminCancel, ADMFLAG_BAN);
	RegAdminCmd("voteslay_cancel", AdminCancel, ADMFLAG_BAN);
	RegConsoleCmd("votekill", CommandVote);
	RegConsoleCmd("voteslay", CommandVote);
	RegConsoleCmd("say", PlayerSay);
	RegConsoleCmd("say_team", PlayerSay);
	HookEvent("player_death", Death);
}

public Action:AdminCancel(client, args)
{
	if(b_VoteInProgress && IsValidClient(VoteTarget))
	{
		CancelVoteKill();
		PrintToChatAll("\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "AdminCancel");
	}
}

public Action:Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		if(b_VoteInProgress && VoteTarget == client)
		{
			CancelVoteKill();
			PrintToChatAll("\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "CDeath");
		}
	}
}

public OnClientDisconnect(client)
{
	if(IsValidClient(client))
	{
		if(b_VoteInProgress && VoteTarget == client)
		{
			CancelVoteKill();
			PrintToChatAll("\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "CDisconnect");
		}
	}
}

public Action:PlayerSay(client, args)
{
	decl String:arg1[50];
	GetCmdArgString(arg1, sizeof(arg1));

	if(StrContains(arg1, "votekill", false) != -1 && StrContains(arg1, "_cancel", false) == -1 || StrContains(arg1, "voteslay", false) != -1 && StrContains(arg1, "_cancel", false) == -1)
	{
		if(b_VoteInProgress)
		{
			PrintToChat(client, "\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "VoteIsInProgress");
			return;
		}

		
		new Handle:menu = CreateMenu(PlayerSelectMenuCallback);
		
		decl String:buffer[128];
		Format(buffer, sizeof(buffer), "--Vote Kill--\n %T", "MenuPlayers", LANG_SERVER);
		
		SetMenuTitle(menu, buffer);
		new String:clientname[255];
		
		SetMenuPagination(menu, 8);
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		for(new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i)) 
			{
				Format(clientname, sizeof(clientname), "%N", i);
				decl String:sUserID[10];
				new UserID = GetClientUserId(i);
				IntToString(UserID,sUserID,sizeof(sUserID));
				AddMenuItem(menu,sUserID,clientname);
			}
		}
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}

public Action:CommandVote(client, args)
{
	if(b_VoteInProgress)
	{
		PrintToChat(client, "\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "VoteIsInProgress");
		return;
	}

	if(args == 1)
	{
		decl String:sz_Arg[70];
		GetCmdArgString(sz_Arg, sizeof(sz_Arg));	
		
		new i_Target = FindTarget(client, sz_Arg)
		
		if(IsValidClient(i_Target) && IsPlayerAlive(i_Target))
			StartVote(client, i_Target);
		else
		{
			PrintToChat(client, "\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "PlayerIsDeadOrInvalid");
			return;
		}
	}
	else
	{
		new Handle:menu = CreateMenu(PlayerSelectMenuCallback);
		
		decl String:buffer[128];
		Format(buffer, sizeof(buffer), "--Vote Kill--\n %T", "MenuPlayers", LANG_SERVER);		
		new String:clientname[255];
		
		SetMenuTitle(menu, buffer)
		SetMenuPagination(menu, 8);
		
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		for(new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i)) 
			{
				Format(clientname, sizeof(clientname), "%N", i);
				decl String:sUserID[10];
				new UserID = GetClientUserId(i);
				IntToString(UserID,sUserID,sizeof(sUserID));
				AddMenuItem(menu,sUserID,clientname);
			}
		}
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}

public PlayerSelectMenuCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:menu_item_title[50];
		GetMenuItem(menu, param2, menu_item_title, sizeof(menu_item_title));
		new UserID = StringToInt(menu_item_title);
		new client = GetClientOfUserId(UserID);
		
		if(client == 0)
			return;
		StartVote(param1, client);
	}
}

stock StartVote(client, target)
{
	if(b_VoteInProgress)
		return;

	b_VoteInProgress = true;
	VoteTarget = target;
	
	decl String:name1[MAX_NAME_LENGTH];
	decl String:name2[MAX_NAME_LENGTH];
	GetClientName(client, name1, sizeof(name1));
	GetClientName(target, name2, sizeof(name2));
	
	PrintToChatAll("\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "StartedVote", name1, name2);
	
	decl String:szTarget[50];
	IntToString(target, szTarget, sizeof(szTarget));
	
	decl String:buffer[128];
	Format(buffer, sizeof(buffer), "%t", "MenuVote", name2);
	
	decl String:buffer2[128];
	Format(buffer2, sizeof(buffer2), "%t", "MenuVoteYes");
	
	decl String:buffer3[128];
	Format(buffer3, sizeof(buffer3), "%t", "MenuVoteNo");
	
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, buffer);
	AddMenuItem(menu, szTarget, buffer2);
	AddMenuItem(menu, "no", buffer3);
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 20);
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteEnd)
	{
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		
		if (param1 == 0)
		{
			decl String:sz_target[50];
			GetMenuItem(menu, param1, sz_target, sizeof(sz_target));
			
			new iTarget = StringToInt(sz_target);
			ForcePlayerSuicide(iTarget);
			
			PrintToChatAll("\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "VoteSucces", votes, totalVotes);
		}
		else
			PrintToChatAll("\x04[Vote Kill \x01By.:RpM\x04]\x03 %t", "VoteFailed", votes, totalVotes);
			
		b_VoteInProgress = false;
		VoteTarget = -1;
	}
}

stock IsValidClient(client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		return true;
	
	return false;
}

stock CancelVoteKill()
{
	CancelVote();
	b_VoteInProgress = false;
	VoteTarget = -1;
}