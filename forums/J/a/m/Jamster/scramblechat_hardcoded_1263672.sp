#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#pragma semicolon 1

new Handle:hTopMenu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Hardcoded scramble chat vote",
	author = "Jamster",
	description = "Quick RTV modification to support scramble",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

new bool:b_Arena;
new bool:g_CanRTV;		
new bool:g_RTVAllowed;	
new g_Voters;				
new g_Votes;				
new g_VotesNeeded;			
new bool:g_Voted[MAXPLAYERS+1];
new MapTimeLimit;

new Handle:g_Cvar_Arena;

public OnPluginStart()
{	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	g_Cvar_Arena = FindConVar("tf_gamemode_arena");
	RegAdminCmd("sm_scramble", Scramble_Teams, ADMFLAG_BAN);
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	hTopMenu = topmenu;
	
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"sm_scramble",
			TopMenuObject_Item,
			AdminMenu_Scramble,
			server_commands,
			"sm_scramble",
			ADMFLAG_BAN);
	}
}

public AdminMenu_Scramble(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Scramble teams", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayScrambleConfirmation(param);
	}
	else if (action == TopMenuAction_DrawOption)
	{
		if (b_Arena)
			buffer[0] = ITEMDRAW_DISABLED;
	}
}

DisplayScrambleConfirmation(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Scramble);
	SetMenuTitle(menu, "Scramble teams?");
	AddMenuItem(menu, "1", "Yes");
	AddMenuItem(menu, "0", "No");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Scramble(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:result[8];
		GetMenuItem(menu, param2, result, sizeof(result));
		if (StringToInt(result))
			Scramble_Teams(param1, 0);
		else
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
}

public Action:Scramble_Teams(client, args)
{
	if (b_Arena)
	{
		ReplyToCommand(client, "[SM] Cannot scramble the teams on arena.");
		return Plugin_Handled;
	}
	ShowActivity(client, "Scrambled the teams");
	LogAction(client, -1, "\"%L\" scrambled the teams", client);
	ServerCommand("mp_scrambleteams");
	new TimeLeft;
	GetMapTimeLeft(TimeLeft);
	CreateTimer(10.0, Timer_ResetTime, TimeLeft, TIMER_FLAG_NO_MAPCHANGE);
	ResetRTV();
	return Plugin_Handled;
}

public OnMapStart()
{
	b_Arena = false;
	if (GetConVarInt(g_Cvar_Arena))
	{
		b_Arena = true;
	}
	
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	
	/* Handle late load */
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public OnMapEnd()
{
	g_CanRTV = false;	
	g_RTVAllowed = false;
}

public OnConfigsExecuted()
{	
	g_CanRTV = true;
	g_RTVAllowed = false;
	CreateTimer(30.0, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	MapTimeLimit = 0;
	GetMapTimeLimit(MapTimeLimit);
	MapTimeLimit = MapTimeLimit*60;
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * 0.5);
	
	return;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * 0.5);
	
	if (!g_CanRTV)
	{
		return;	
	}
	
	if (g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded && 
		g_RTVAllowed ) 
	{
		StartRTV();
	}	
}

public Action:Command_RTV(client, args)
{
	if (!g_CanRTV || !client)
	{
		return Plugin_Continue;
	}
	
	AttemptRTV(client);
	
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	if (!g_CanRTV || !client)
	{
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "scramble", false) == 0 || strcmp(text[startidx], "votescramble", false) == 0)
	{
		AttemptRTV(client);
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

AttemptRTV(client)
{
	if (!g_RTVAllowed)
	{
		ReplyToCommand(client, "[SM] Scramble teams vote is not allowed yet.");
		return;
	}
	
	if (b_Arena)
	{
		ReplyToCommand(client, "[SM] Cannot scramble the teams on arena.");
		return;
	}
	
	if (GetClientCount(true) < 4)
	{
		ReplyToCommand(client, "[SM] The minimal number of players required has not been met.");
		return;			
	}
	
	if (g_Voted[client])
	{
		ReplyToCommand(client, "[SM] You have already voted to scramble teams. (%d/%d)", g_Votes, g_VotesNeeded);
		return;
	}	
	
	g_Votes++;
	g_Voted[client] = true;
	
	PrintToChatAll("[SM] %N wants to scramble the teams. (%d/%d)", client, g_Votes, g_VotesNeeded);
	
	if (g_Votes >= g_VotesNeeded)
	{
		StartRTV();
	}	
}

public Action:Timer_DelayRTV(Handle:timer)
{
	g_RTVAllowed = true;
}

StartRTV()
{
	LogMessage("Scrambled teams");
	PrintToChatAll("[SM] Scrambling teams, please wait...");
	ServerCommand("mp_scrambleteams");
	new TimeLeft;
	GetMapTimeLeft(TimeLeft);
	CreateTimer(10.0, Timer_ResetTime, TimeLeft, TIMER_FLAG_NO_MAPCHANGE);
	ResetRTV();
}

public Action:Timer_ResetTime(Handle:timer, any:timeleft)
{
	if (timeleft <= 0)
	{
		decl String:map[64];
		GetNextMap(map, sizeof(map));
		ForceChangeLevel(map, "Scrambled when there was no time left");
	}
	else
	{
		new fulltime;
		GetMapTimeLeft(fulltime);
		ExtendMapTimeLimit(-(fulltime-timeleft));
	}
	return Plugin_Stop;
}

ResetRTV()
{
	g_Votes = 0;
			
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
	
	OnMapStart();
	OnConfigsExecuted();
}