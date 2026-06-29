#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

// Team indices
#define TEAM_1    2
#define TEAM_2    3
#define TEAM_SPEC 1
#define SPECTATOR_TEAM 0

#define SWAPTEAM_VERSION	"1.2.7"
#define TEAMSWITCH_ADMINFLAG	ADMFLAG_KICK
#define TEAMSWITCH_ARRAY_SIZE 64

new bool:g_TF2Arena = false;
new bool:TF2 = false;
new bool:CSS = false;
new bool:CSGO = false;

public Plugin:myinfo = {
	name = "SwapTeam",
	author = "Rogue - Originally by MistaGee",
	description = "Switch people to spec or the other team immediately, at round end, on death",
	version = SWAPTEAM_VERSION,
	url = "http://www.sourcemod.net/"
};

new	Handle:hAdminMenu = INVALID_HANDLE,
bool:onRoundEndPossible = false,
bool:cstrikeExtAvail = false,
String:teamName1[2],
String:teamName2[3],
bool:switchOnRoundEnd[TEAMSWITCH_ARRAY_SIZE],
bool:switchOnDeath[TEAMSWITCH_ARRAY_SIZE];

enum TeamSwitchEvent
{
	SwapTeamEvent_Immediately = 0,
	SwapTeamEvent_OnDeath = 1,
	SwapTeamEvent_OnRoundEnd = 2,
	SwapTeamEvent_ToSpec = 3
};

public OnPluginStart()
{
	CreateConVar("swapteam_version", SWAPTEAM_VERSION, "SwapTeam Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_swapteam", Command_SwitchImmed, TEAMSWITCH_ADMINFLAG);
	RegAdminCmd("sm_swapteam_death", Command_SwitchDeath, TEAMSWITCH_ADMINFLAG);
	RegAdminCmd("sm_swapteam_d", Command_SwitchRend, TEAMSWITCH_ADMINFLAG);
	RegAdminCmd("sm_spec", Command_SwitchSpec, TEAMSWITCH_ADMINFLAG);
	RegAdminCmd("sm_team", Command_Team, TEAMSWITCH_ADMINFLAG);
	
	HookEvent("player_death", Event_PlayerDeath);
	
	// Hook game specific round end events - if none found, round end is not shown in menu
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	
	PrintToServer("[SM] Hooking round end events for game: %s", theFolder);
	
	if(StrEqual(theFolder, "dod"))
	{
		HookEvent("dod_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
		onRoundEndPossible = true;
	}
	else if(StrEqual(theFolder, "tf"))
	{
		decl String:mapname[128];
		GetCurrentMap(mapname, sizeof(mapname));
		HookEvent("teamplay_round_win",	Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_stalemate",	Event_RoundEnd, EventHookMode_PostNoCopy);
		onRoundEndPossible = true;
		TF2 = true;
		if (strncmp(mapname, "arena_", 6, false) == 0 || strncmp(mapname, "vsh_", 4, false) == 0)
		{
			g_TF2Arena = true;
		}
	}
	else if(StrEqual(theFolder, "cstrike"))
	{
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		onRoundEndPossible = true;
		CSS = true;
	}
	else if(StrEqual(theFolder, "csgo"))
	{
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		onRoundEndPossible = true;
		CSGO = true;
	}
	
	new Handle:topmenu;
	if(LibraryExists("adminmenu") && (( topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	// Check for cstrike extension - if available, CS_SwitchTeam is used
	cstrikeExtAvail = (GetExtensionFileStatus("game.cstrike.ext") == 1);
	
	LoadTranslations("common.phrases");
	LoadTranslations("swapteam.phrases");
}

public OnMapStart()
{
	GetTeamName(2, teamName1, sizeof(teamName1));
	GetTeamName(3, teamName2, sizeof(teamName2));
	
	if (CSGO)
	{
		PrecacheModel("models/player/tm_leet_varianta.mdl");
		PrecacheModel("models/player/ctm_sas.mdl");
	}
	
	PrintToServer("[SM] Team Names: %s %s - OnRoundEnd available: %s", teamName1, teamName2, (onRoundEndPossible ? "yes" : "no"));
}

public Action:Command_Team(client, args)
{
	if (args < 2)
	{
		if (cstrikeExtAvail)
		{
			ReplyToCommand(client, "[SM] %t", "team usage css");
		}
		else if (TF2)
		{
			ReplyToCommand(client, "[SM] %t", "team usage tf2");
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "team usage other");
		}
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	decl String:teamarg[65];
	decl teamargBuffer;
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, teamarg, sizeof(teamarg));
	teamargBuffer = StringToInt(teamarg);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (teamargBuffer == 0)
		{
			if (g_TF2Arena)
			{
				PerformSwitchToSpec(client, target_list[i]);
			}
			else
			{			
				ChangeClientTeam(target_list[i], TEAM_SPEC);
			}
			
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to spec", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to spec", "_s", target_name);
			}
		}
		else if (teamargBuffer == 1)
		{
			if (g_TF2Arena)
			{
				PerformSwitchToSpec(client, target_list[i]);
			}
			else
			{			
				ChangeClientTeam(target_list[i], TEAM_SPEC);
			}
			
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to spec", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to spec", "_s", target_name);
			}
		}
		else if (teamargBuffer == 2)
		{
			ChangeClientTeam(target_list[i], TEAM_1);
			
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to team1", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to team1", "_s", target_name);
			}
		}
		else if (teamargBuffer == 3)
		{
			ChangeClientTeam(target_list[i], TEAM_2);
			
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to team2", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "Moved to team2", "_s", target_name);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_SwitchImmed(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] %t", "swapteam usage");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
    PerformSwitch(target_list[i]);
    LogAction(client, target_list[i], "\"%L\" moved (to opposite team) \"%L\"", client, target_list[i]);
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "switch by admin", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "switch by admin", "_s", target_name);
	}

	return Plugin_Handled;
}

public Action:Command_SwitchDeath(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] %t", "swapteam death usage");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
    switchOnDeath[target_list[i]] = !switchOnDeath[target_list[i]];
    LogAction(client, target_list[i], "\"%L\" executed sm_swapteam_death on \"%L\"", client, target_list[i]);
    
    if(switchOnDeath[target_list[i]])
  	{
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "swap death", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "swap death", "_s", target_name);
			}
		}
		else
		{
  		if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "dont swap death", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "dont swap death", "_s", target_name);
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_SwitchRend(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] %t", "swapteam rend usage");
		return Plugin_Handled;
	}
	
	if(!onRoundEndPossible)
	{
		ReplyToCommand(client, "[SM] %t", "swapteam rend error");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
    switchOnRoundEnd[target_list[i]] = !switchOnRoundEnd[target_list[i]];
    LogAction(client, target_list[i], "\"%L\" executed sm_swapteam_d on \"%L\"", client, target_list[i]);

    if(switchOnRoundEnd[target_list[i]])
  	{
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "swap rend", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "swap rend", "_s", target_name);
			}
		}
		else
		{
  		if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "%t", "dont swap rend", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "%t", "dont swap rend", "_s", target_name);
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_SwitchSpec(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] %t", "swapteam spec usage");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
    PerformSwitchToSpec(client, target_list[i]);
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "moved to spec", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "moved to spec", "_s", target_name);
	}

	return Plugin_Handled;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(switchOnDeath[client])
	{
		PerformTimedSwitch(client);
		switchOnDeath[client] = false;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!onRoundEndPossible)
		return;
	
	for(new i = 0; i < TEAMSWITCH_ARRAY_SIZE; i++)
	{
		if(switchOnRoundEnd[i])
		{
			PerformTimedSwitch(i);
			switchOnRoundEnd[i] = false;
		}
	}
}


/******************************************************************************************
*                                   ADMIN MENU HANDLERS                                  *
******************************************************************************************/

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	// ?????????? ?????? ???? ??????
	if(topmenu == hAdminMenu)
	{
		return;
	}
	hAdminMenu = topmenu;
	
	// Now add stuff to the menu: My very own category *yay*
	new TopMenuObject:menu_category = AddToTopMenu(
	hAdminMenu,		// Menu
	"commands",		// Name
	TopMenuObject_Category,	// Type
	Handle_Category,	// Callback
	INVALID_TOPMENUOBJECT	// Parent
	);
	
	if(menu_category == INVALID_TOPMENUOBJECT)
	{
		// Error... lame...
		return;
	}
	
	// Now add items to it
	AddToTopMenu(
	hAdminMenu,			// Menu
	"immed",			// Name
	TopMenuObject_Item,		// Type
	Handle_ModeImmed,		// Callback
	menu_category,			// Parent
	"immed",			// cmdName
	TEAMSWITCH_ADMINFLAG		// Admin flag
	);
	
	AddToTopMenu(
	hAdminMenu,			// Menu
	"on_death",			// Name
	TopMenuObject_Item,		// Type
	Handle_ModeDeath,		// Callback
	menu_category,			// Parent
	"on_death",			// cmdName
	TEAMSWITCH_ADMINFLAG		// Admin flag
	);
	
	if(onRoundEndPossible)
	{
		AddToTopMenu(
		hAdminMenu,			// Menu
		"on_rend",			// Name
		TopMenuObject_Item,		// Type
		Handle_ModeRend,		// Callback
		menu_category,			// Parent
		"on_rend",			// cmdName
		TEAMSWITCH_ADMINFLAG		// Admin flag
		);
	}
	
	AddToTopMenu(
	hAdminMenu,			// Menu
	"o_spec",			// Name
	TopMenuObject_Item,		// Type
	Handle_ModeSpec,		// Callback
	menu_category,			// Parent
	"to_spec",			// cmdName
	TEAMSWITCH_ADMINFLAG		// Admin flag
	);
	
}

public Handle_Category(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
		Format(buffer, maxlength, "%t", "when move");
		case TopMenuAction_DisplayOption:
		Format(buffer, maxlength, "%t", "commands");
	}
}

public Handle_ModeImmed(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "immediately");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		ShowPlayerSelectionMenu(param, SwapTeamEvent_Immediately);
	}
}

public Handle_ModeDeath(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "on death");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		ShowPlayerSelectionMenu(param, SwapTeamEvent_OnDeath);
	}
}

public Handle_ModeRend(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "on rend");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		ShowPlayerSelectionMenu(param, SwapTeamEvent_OnRoundEnd);
	}
}

public Handle_ModeSpec(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "to spec");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		ShowPlayerSelectionMenu(param, SwapTeamEvent_ToSpec);
	}
}


/******************************************************************************************
*                           PLAYER SELECTION MENU HANDLERS                               *
******************************************************************************************/

void:ShowPlayerSelectionMenu(client, TeamSwitchEvent:event, item = 0)
{
	new Handle:playerMenu = INVALID_HANDLE;
	
	// Create Menu with the correct Handler, so I don't have to store which player chose
	// which action...
	switch(event)
	{
		case SwapTeamEvent_Immediately:
		playerMenu = CreateMenu(Handle_SwitchImmed);
		case SwapTeamEvent_OnDeath:
		playerMenu = CreateMenu(Handle_SwitchDeath);
		case SwapTeamEvent_OnRoundEnd:
		playerMenu = CreateMenu(Handle_SwitchRend);
		case SwapTeamEvent_ToSpec:
		playerMenu = CreateMenu(Handle_SwitchSpec);
	}
	
	SetMenuTitle(playerMenu, "%t", "select player");
	SetMenuExitButton(playerMenu, true);
	SetMenuExitBackButton(playerMenu, true);
	
	// Now add players to it
	// I'm aware there is a function AddTargetsToMenu in the SourceMod API, but I don't
	// use that one because it does not display the team the clients are in.
	new cTeam = 0,
	mc = GetMaxClients();
	
	decl String:cName[45],
	String:buffer[50],
	String:cBuffer[5];
	
	for(new i = 1; i < mc; i++)
	{
		if(IsClientInGame(i) && (CanUserTarget(client, i)))
		{
			cTeam = GetClientTeam(i);
			if(cTeam < 2)
				continue;
			
			GetClientName(i, cName, sizeof(cName));
			
			switch(event)
			{
				case SwapTeamEvent_Immediately,
				SwapTeamEvent_ToSpec:
				Format(buffer, sizeof(buffer),
				"[%s] %s", 
				(cTeam == 2 ? teamName1 : teamName2),
				cName
				);
				case SwapTeamEvent_OnDeath:
				{
					Format(buffer, sizeof(buffer),
					"[%s] [%s] %s",
					(switchOnDeath[i] ? 'x' : ' '),
					(cTeam == 2 ? teamName1 : teamName2),
					cName
				);
				}
				case SwapTeamEvent_OnRoundEnd:
				{
					Format(buffer, sizeof(buffer),
					"[%s] [%s] %s",
					(switchOnRoundEnd[i] ? 'x' : ' '),
					(cTeam == 2 ? teamName1 : teamName2),
					cName
				);
				}
			}
			
			IntToString(i, cBuffer, sizeof(cBuffer));
			
			AddMenuItem(playerMenu, cBuffer, buffer);
		}
	}
	
	// ????????? ???? ??? ????? ???????
	if(item == 0)
		DisplayMenu(playerMenu, client, 30);
	else	DisplayMenuAtItem(playerMenu, client, item-1, 30);
}

public Handle_SwitchImmed(Handle:playerMenu, MenuAction:action, client, target)
{
	Handle_Switch(SwapTeamEvent_Immediately, playerMenu, action, client, target);
}

public Handle_SwitchDeath(Handle:playerMenu, MenuAction:action, client, target)
{
	Handle_Switch(SwapTeamEvent_OnDeath, playerMenu, action, client, target);
}

public Handle_SwitchRend(Handle:playerMenu, MenuAction:action, client, target)
{
	Handle_Switch(SwapTeamEvent_OnRoundEnd, playerMenu, action, client, target);
}

public Handle_SwitchSpec(Handle:playerMenu, MenuAction:action, client, target)
{
	Handle_Switch(SwapTeamEvent_ToSpec, playerMenu, action, client, target);
}

void:Handle_Switch(TeamSwitchEvent:event, Handle:playerMenu, MenuAction:action, client, param)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:info[5];
			GetMenuItem(playerMenu, param, info, sizeof(info));
			new target = StringToInt(info);
			
			switch(event)
			{
				case SwapTeamEvent_Immediately:
				{
					PerformSwitch(target);
					decl String:name[50];
					GetClientName(target, name, sizeof(name));
					ShowActivity(client, "%t", "switch by admin2", name);
				}
				case SwapTeamEvent_OnDeath:
				{
					// If alive: player must be listed in OnDeath array
					if(IsPlayerAlive(target))
					{
						// If alive, toggle status
						switchOnDeath[target] = !switchOnDeath[target];
					}
					else	// Switch right away
					PerformSwitch(target);
					if(switchOnDeath[target])
					{
						decl String:name[50];
						GetClientName(target, name, sizeof(name));
						ShowActivity(client, "%t", "swap death2", name);
						LogAction(client, target, "\"%L\" requested to change client team on death \"%L\"", client, target);
		 			}
					else
					{
						decl String:name[50];
						GetClientName(target, name, sizeof(name));
						ShowActivity(client, "%t", "dont swap death2", name);
						LogAction(client, target, "\"%L\" removed the request to change client team on death \"%L\"", client, target);
					}
				}
				case SwapTeamEvent_OnRoundEnd:
				{
					// Toggle status
					switchOnRoundEnd[target] = !switchOnRoundEnd[target];
					LogAction(client, target, "\"%L\" executed sm_swapteam_d on \"%L\"", client, target);
					
					if(switchOnRoundEnd[target])
					{
						decl String:name[50];
						GetClientName(target, name, sizeof(name));
						ShowActivity(client, "%t", "swap rend2", name);
						LogAction(client, target, "\"%L\" requested to change client team on round end \"%L\"", client, target);
		 			}
					else
					{
						decl String:name[50];
						GetClientName(target, name, sizeof(name));
						ShowActivity(client, "%t", "dont swap rend2", name);
						LogAction(client, target, "\"%L\" removed the request to change client team on round end \"%L\"", client, target);
					}
				}
				case SwapTeamEvent_ToSpec:
				{
					PerformSwitchToSpec(client, target);
					PerformSwitch(target);
					decl String:name[50];
					GetClientName(target, name, sizeof(name));
					ShowActivity(client, "%t", "moved to spec2", name);
				}
			}
			// Now display the menu again
			ShowPlayerSelectionMenu(client, event, target);
		}
		
		case MenuAction_Cancel:
		// param gives us the reason why the menu was cancelled
		if(param == MenuCancel_ExitBack)
			RedisplayAdminMenu(hAdminMenu, client);
		
		case MenuAction_End:
		CloseHandle(playerMenu);
	}
}


void:PerformTimedSwitch(client)
{
	CreateTimer(0.5, Timer_TeamSwitch, client);
}

public Action:Timer_TeamSwitch(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		PerformSwitch(client);
	return Plugin_Stop;
}

void:PerformSwitch(client, bool:toSpec = false)
{
	new cTeam = GetClientTeam(client),
	toTeam = (toSpec ? TEAM_SPEC : TEAM_1 + TEAM_2 - cTeam);
	
	if (cstrikeExtAvail && !toSpec)
	{
		CS_SwitchTeam(client, toTeam);
		
		if (CSS)
		{
			if (cTeam == TEAM_2)
			{
				SetEntityModel(client, "models/player/t_leet.mdl");
			}
			else
			{
				SetEntityModel(client, "models/player/ct_sas.mdl");
			}
		}
		
		if (CSGO)
		{
			if (cTeam == TEAM_2)
			{
				SetEntityModel(client, "models/player/tm_leet_varianta.mdl");
			}
			else
			{
				SetEntityModel(client, "models/player/ctm_sas.mdl");
			}
		}
		
		if (GetPlayerWeaponSlot(client, CS_SLOT_C4) != -1)
		{
			new ent;
			if ((ent = GetPlayerWeaponSlot(client, CS_SLOT_C4)) != -1)
			SDKHooks_DropWeapon(client, ent);
		}
	}
	
	else
		ChangeClientTeam(client, toTeam);
}

PerformSwitchToSpec(client, target)
{
	LogAction(client, target, "\"%L\" moved (to spectate) \"%L\"", client, target);
	
	if (TF2)
	{
		if (g_TF2Arena && GetConVarInt(FindConVar("tf_arena_use_queue")) == 1)
		{
			// Arena Spectator Fix by Rothgar
			SetEntProp(target, Prop_Send, "m_nNextThinkTick", -1);
			SetEntProp(target, Prop_Send, "m_iDesiredPlayerClass", 0);
			SetEntProp(target, Prop_Send, "m_bArenaSpectator", 1);
		}
		ChangeClientTeam(target, TEAM_SPEC);
	}
	else
	{
		ChangeClientTeam(target, TEAM_SPEC);
	}
}
