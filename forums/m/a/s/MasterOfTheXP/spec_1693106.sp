#include <sourcemod>
#include <adminmenu>
#define PLUGIN_VERSION  "1.1b"

public Plugin:myinfo = {
	name = "Quick Spectate",
	author = "MasterOfTheXP",
	description = "Easily target players for spectating.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

/*

1.1
* Added admin menu support
* Added sm_spec_ex command -- targeting someone with this causes you to automatically spectate them every time they spawn. "sm_spec_ex 0" to stop spectating them.
* Added the ability to disable sm_spec for non-admins (sm_spec_players 0)


*/

/* CVARS (1) */
new Handle:cvarCanPlayersUse;

/* CVARS (2) */
new bool:CanPlayersUse = true;

new String:gameName[10];
new Handle:hTopMenu = INVALID_HANDLE;
new specTarget[MAXPLAYERS + 1] = 0;

public OnPluginStart()
{
	RegConsoleCmd("sm_spec", Command_spec, "sm_spec <target> - Spectates a player.");
	RegConsoleCmd("sm_spec_ex", Command_spec_ex, "sm_spec_ex <target> - Constantly spectates a player. sm_spec_ex 0 to reset.");
	LoadTranslations("common.phrases");
	GetGameFolderName(gameName, 10);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	
	/* CVARS (3) */
	cvarCanPlayersUse = CreateConVar("sm_spec_players","1","If on, non-admins can use sm_spec.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	/* CVARS (4) */
	HookConVarChange(cvarCanPlayersUse, CvarChange);
}

public Action:Command_spec(client, args)
{
	if (client == 0) PrintToServer("[SM] %t", "Command is in-game only");
	if (client == 0) return Plugin_Handled;
	if (!CheckCommandAccess(client, "sm_slay", ADMFLAG_SLAY) && !CanPlayersUse)
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spec <target> - Spectates a player.");
		return Plugin_Handled;
	}
	if (args == 1)
	{
		new String:arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));
		
		new target = FindTarget(client, arg1)
		if (target == -1) return Plugin_Handled;
		if (IsClientInGame(target))
		{
			if (!IsPlayerAlive(target))
			{
				ReplyToCommand(client, "[SM] %t", "Target must be alive");
				return Plugin_Handled;
			}
			if (StrEqual(gameName, "tf", false))
			{
				if (GetClientTeam(client) != 1 && GetClientTeam(client) != GetClientTeam(target)) SetClientTeam(client, 1);
				if (GetClientTeam(client) != 1 && GetClientTeam(client) == GetClientTeam(target) && IsPlayerAlive(client)) SetClientTeam(client, 1);
			}
			FakeClientCommand(client, "spec_player \"%N\"", target);
		}
		if (!IsClientInGame(target)) ReplyToCommand(client, "[SM] %t", "Target is not in game");
	}
	return Plugin_Handled;
}

public Action:Command_spec_ex(client, args)
{
	if (client == 0) PrintToServer("[SM] %t", "Command is in-game only");
	if (client == 0) return Plugin_Handled;
	if (!CheckCommandAccess(client, "sm_slay", ADMFLAG_SLAY) && !CanPlayersUse)
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spec_ex <target> - Constantly spectates a player. sm_spec_ex 0 to reset.");
		return Plugin_Handled;
	}
	if (args == 1)
	{
		new String:arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));
		
		if (StrEqual(arg1,"0",false) && specTarget[client] != 0)
		{
			specTarget[client] = 0;
			ReplyToCommand(client, "[SM] Cleared your spectate target.");
			return Plugin_Handled;
		}
		new target = FindTarget(client, arg1)
		if (target == -1) return Plugin_Handled;
		if (IsClientInGame(target))
		{
			specTarget[client] = target;
			if (StrEqual(gameName, "tf", false))
			{
				if (GetClientTeam(client) != 1 && GetClientTeam(client) != GetClientTeam(target)) SetClientTeam(client, 1);
				if (GetClientTeam(client) != 1 && GetClientTeam(client) == GetClientTeam(target) && IsPlayerAlive(client)) SetClientTeam(client, 1);
			}
			FakeClientCommand(client, "spec_player \"%N\"", target);
		}
		if (!IsClientInGame(target)) ReplyToCommand(client, "[SM] %t", "Target is not in game");
	}
	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (specTarget[z] == client) FakeClientCommand(z, "sm_spec #%i", GetClientUserId(client));
	}
	return Plugin_Continue;
}

public Action:SetClientTeam(client, team)
{
	if (team == 1) FakeClientCommand(client, "jointeam spectator");
	if (team == 2) FakeClientCommand(client, "jointeam red");
	if (team == 3) FakeClientCommand(client, "jointeam blue");
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	/* CVARS (5) */
	if (convar == cvarCanPlayersUse) CanPlayersUse = bool:StringToInt(newValue);
}

SpecMenu(client)
{
	new Handle:smMenu = CreateMenu(SpecMenuHandler);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Spectate player:", client);
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu(smMenu, client, true, false);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

public AdminMenu_Spec(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption) Format(buffer, maxlength, "Spectate player", param);
	else if (action == TopMenuAction_SelectOption) SpecMenu(param);
}

public SpecMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0) PrintToChat(client, "[SM] %t", "Player no longer available");
		else
		{
			new UID = GetClientUserId(target);
			FakeClientCommand(client, "sm_spec #%i", UID);
		}
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu) return;
	hTopMenu = topmenu;
	new TopMenuObject:playerCommands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (playerCommands != INVALID_TOPMENUOBJECT) AddToTopMenu(hTopMenu, "sm_spec", TopMenuObject_Item, AdminMenu_Spec, playerCommands, "sm_spec", ADMFLAG_SLAY);
}