// By Neatek, less code... i hate any configuration and menus...
#pragma semicolon 1
#include <sourcemod>
#define CHAT_PREFIX "[GameVoting]"
new bool:g_PluginEnabled = true;
new countOfVkAndVb[2][MAXPLAYERS+1]; // countOfVkAndVb[0] is votekick, countOfVkAndVb[1] is voteban
new memoryOfVkAndVb[2][MAXPLAYERS+1];
new Handle:g_GameVotingNeeded = INVALID_HANDLE;
new Handle:g_VotekickEnable = INVALID_HANDLE;
new Handle:g_VotebanEnable = INVALID_HANDLE;
new Handle:g_VotebanPercent = INVALID_HANDLE;
new Handle:g_VotekickPercent = INVALID_HANDLE;
new Handle:g_VotebanReason = INVALID_HANDLE;
new Handle:g_VotebanTime = INVALID_HANDLE;
new Handle:g_Deactivate = INVALID_HANDLE;
new Handle:g_HideAdmins = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("phrases.GameVoting");
	CreateConVar("sm_gamevoting_version", "1.3rc", "Version of GameVoting plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_GameVotingNeeded = CreateConVar("gv_need_players", "4", "Needed count of players for enable plugin");
	g_Deactivate = CreateConVar("gv_deactivate_admin_on_server", "0", "Disable plugin when admin on server");
	g_VotekickEnable = CreateConVar("gv_votekick_enable", "1", "Enable or disable votekick");
	g_VotebanEnable = CreateConVar("gv_voteban_enable", "1", "Enable or disable voteban");
	g_VotekickPercent = CreateConVar("gv_votekick_percent", "60", "How much percent of players needed for kick");
	g_VotebanPercent = CreateConVar("gv_voteban_percent", "60", "How much percent of players needed for ban");
	g_VotebanReason = CreateConVar("gv_voteban_reason", "Banned by voteban", "Reason of ban for voteban");
	g_VotebanTime = CreateConVar("gv_voteban_time", "120", "Time of ban for voteban");
	g_HideAdmins = CreateConVar("gv_hide_admins", "1", "Hide admins from votekick and voteban");
	AddCommandListener(Listener, "say");
	AddCommandListener(Listener);
	AddCommandListener(Listener, "say_team");
	AutoExecConfig(true);
}

public OnMapStart()
{
	g_PluginEnabled=true;
}

public Action:Listener(client, const String:command[], argc)
{
	if(!vclient(client) || !g_PluginEnabled) return Plugin_Continue;
	new String:arg[128];
	GetCmdArgString(arg, sizeof(arg)); // get first arg
	StripQuotes(arg); // strip
	if(strcmp(arg, "voteban") == 0) { VoteInit(client, true); return Plugin_Handled; }
	else if(strcmp(arg, "votekick") == 0) { VoteInit(client, false); return Plugin_Handled; }
	else if(strcmp(arg, "!votekick") == 0) { VoteInit(client, false); return Plugin_Handled; }
	else if(strcmp(arg, "!voteban") == 0) { VoteInit(client, true); return Plugin_Handled; }
	return Plugin_Continue;
}

stock Votefor(victim, client, bool:voteban=false)
{
	if(client < 1 || victim < 1 || !vclient(victim)) return;
	new method = 0; if(voteban) method = 1;
	countOfVkAndVb[method][victim]++; // add vote
	memoryOfVkAndVb[method][client]=victim; // remember who vote
}

stock resetVote(client, bool:voteban=false)
{
	if(client < 1) return;
	new method = 0; if(voteban) method = 1;
	if(memoryOfVkAndVb[method][client]==0) return; // nothing to reset
	countOfVkAndVb[method][memoryOfVkAndVb[method][client]]--; // del vote
	memoryOfVkAndVb[method][client]=0; // delete memory
}

stock ResetAll(client)
{
	resetVote(client, false); resetVote(client, true);
}

stock vclient(x)
{
	if(x > 0 && IsClientConnected(x) && IsClientInGame(x) && !IsClientSourceTV(x) && !IsFakeClient(x)) return true;
	return false;
}

stock GetPlayerNum()
{
	new z = 0;
	for(new x=1;x<=MaxClients;x++) if(vclient(x)) z++; else ResetAll(x);
	return z;
}

stock GetPercent(bool:vb_percent)
{
	new percent = 0;
	for(new x=1;x<=MaxClients;x++) if(vclient(x)) percent++;
	if(vb_percent) return percent*GetConVarInt(g_VotebanPercent)/100; // voteban Percent
	else return percent*GetConVarInt(g_VotekickPercent)/100; // votekick Percent
}

public OnClientPostAdminCheck(client)
{
	ResetAll(client); // Reset voteban and votekick
}

public OnClientDisconnect(client)
{
	ResetAll(client); // Reset voteban and votekick
	if(GetConVarInt(g_Deactivate) > 0)
		if(CheckAdminCount() < 1) {g_PluginEnabled=true;} else {g_PluginEnabled=false;} 
}

stock CheckAdminCount()
{
	new i = 0;
	new AdminId:admin;
	for(new x=1;x<=MaxClients;x++) if(vclient(x) && admin != INVALID_ADMIN_ID) i++;
	return i;
}

VoteInit(client, bool:voteban=false)
{
	if(GetPlayerNum() >= GetConVarInt(g_GameVotingNeeded))
	{
		if(voteban)
		{
			if(GetConVarInt(g_VotebanEnable) < 1)
			{
				PrintToChat(client, "%T", "GameVoting_Voteban_Disabled", client);
				return;
			}
		}
		else
		{
			if(GetConVarInt(g_VotekickEnable) < 1)
			{
				PrintToChat(client, "%T", "GameVoting_Votekick_Disabled", client);
				return;
			}
		}
	}
	else
	{
		PrintToChat(client, "%T", "GameVoting_NeedMorePlayers", client);
		return;
	}

	new Handle:menu;
	if(voteban) {  menu = CreateMenu(MenuHandler_VoteBan, MenuAction:MENU_NO_PAGINATION); }
	else { menu = CreateMenu(MenuHandler_VoteKick, MenuAction:MENU_NO_PAGINATION); }
	
	decl String:translate_buffer[128];
	
	if(voteban)
	{
		Format(translate_buffer, sizeof(translate_buffer), "%T", "Voteban_Menu_Title", client);
		SetMenuTitle(menu, translate_buffer);
	}
	else
	{
		Format(translate_buffer, sizeof(translate_buffer), "%T", "Votekick_Menu_Title", client);
		SetMenuTitle(menu, translate_buffer);
	}

	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_Reset_Vote", client);
	AddMenuItem(menu, "0", translate_buffer, ITEMDRAW_DEFAULT); // Reset vote line
	decl String:buffer2[16], // buffer for num
	String:buffer[32]; // buffer for names
	new AdminId:admin; // admin detect
	for(new x=1;x<=MaxClients;x++)
	{
		if(vclient(x))
		{
			IntToString(x, buffer2, sizeof(buffer2));
			GetClientName(x, buffer, sizeof(buffer));
			if(GetConVarInt(g_HideAdmins) > 0)
			{
				admin = GetUserAdmin(x);
				if(x != client && admin == INVALID_ADMIN_ID)
				{
					AddMenuItem(menu, buffer2, buffer, ITEMDRAW_DEFAULT);
				}
			} 
			else
			{
				if(x != client)
				{
					AddMenuItem(menu, buffer2, buffer, ITEMDRAW_DEFAULT);
				}
			}
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 12);
}

public MenuHandler_VoteKick(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Select) 
	{
		decl String:info[16];
		GetMenuItem(menu, param2, info, sizeof(info));
		new target = StringToInt(info);
		if(target == 0)
		{
			resetVote(param1, false);
			PrintToChat(param1, "%T", "GameVoting_Vote_Reseted", param1);
		}
		else if(vclient(target))
		{
			new percent = GetPercent(false);
			resetVote(param1, false);
			Votefor(target, param1, false);
			decl String:CName[64], String:TName[64];
			GetClientName(param1, CName, sizeof(CName));
			GetClientName(target, TName, sizeof(TName));
			for(new x=1;x<=MaxClients;x++)
			if(vclient(x)) PrintToChat(x, "%T", "GameVoting_Votekick", x, CName, TName, countOfVkAndVb[0][target], percent); // with translation support
			if(countOfVkAndVb[0][target] >= percent) 
			{
				LogMessage("{GV} Player %s kicked by votekick.", TName);
				KickClient(target, "Voted for kick");
			}
		}
	}
}

public MenuHandler_VoteBan(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Select) 
	{
		decl String:info[16];
		GetMenuItem(menu, param2, info, sizeof(info));
		new target = StringToInt(info);
		if(target == 0)
		{
			resetVote(param1, true);
			PrintToChat(param1, "%T", "GameVoting_Vote_Reseted", param1);
		}
		else if(vclient(target))
		{
			new percent = GetPercent(true);
			resetVote(param1, true);
			Votefor(target, param1, true);
			decl String:CName[64], String:TName[64];
			GetClientName(param1, CName, sizeof(CName));
			GetClientName(target, TName, sizeof(TName));
			for(new x=1;x<=MaxClients;x++)
			if(vclient(x))
			PrintToChat(x, "%T", "GameVoting_Voteban", x, CName, TName, countOfVkAndVb[1][target], percent); // with translation support
			if(countOfVkAndVb[1][target] >= percent)
			{
				decl String:reason[64];
				GetConVarString(g_VotebanReason, reason, sizeof(reason));
				LogMessage("{GV} Player %s banned. (%s)", TName, reason);
				ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(target), GetConVarInt(g_VotebanTime), reason);
			}
		}
	}
}