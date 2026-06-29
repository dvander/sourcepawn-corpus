#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "2.1"
#define SOUND_THUNDER "ambient/explosions/explode_9.wav"

public Plugin:myinfo = 
{
	name = "Admin Smite",
	author = "Hipster",
	description = "Slay players with a lightning bolt effect",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=118534"
};

new Handle:hTopMenu = INVALID_HANDLE;

new g_SmokeSprite;
new g_LightningSprite;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("adminsmite.phrases");
	
	CreateConVar("sm_adminsmite_version", PLUGIN_VERSION, "Admin Smite Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_smite", Command_Smite, ADMFLAG_SLAY, "sm_smite <#userid|name> - Slay with a lightning bolt effect.");
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	PrecacheSound(SOUND_THUNDER, true);
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
}

PerformSmite(client, target)
{
	LogAction(client, target, "\"%L\" smote \"%L\"", client, target);
	
	// define where the lightning strike ends
	new Float:clientpos[3];
	GetClientAbsOrigin(target, clientpos);
	clientpos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground
	
	// get random numbers for the x and y starting positions
	new randomx = GetRandomInt(-500, 500);
	new randomy = GetRandomInt(-500, 500);
	
	// define where the lightning strike starts
	new Float:startpos[3];
	startpos[0] = clientpos[0] + randomx;
	startpos[1] = clientpos[1] + randomy;
	startpos[2] = clientpos[2] + 800;
	
	// define the color of the strike
	new color[4] = {255, 255, 255, 255};
	
	// define the direction of the sparks
	new Float:dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(startpos, clientpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(clientpos, g_SmokeSprite, 5.0, 10);
	TE_SendToAll();
	
	EmitAmbientSound(SOUND_THUNDER, startpos, client, SNDLEVEL_RAIDSIREN);
	
	ForcePlayerSuicide(target);
}

public Action:Command_Smite(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_smite <#userid|name>");
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
		new target = target_list[i];
		PerformSmite(client, target);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Smote target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Smote target", "_s", target_name);
	}

	return Plugin_Handled;
}

DisplaySmiteMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Smite);
	
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Smite player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AdminMenu_Smite(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Smite player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplaySmiteMenu(param);
	}
}

public MenuHandler_Smite(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else if (!IsPlayerAlive(target))
		{
			ReplyToCommand(param1, "[SM] %t", "Player has since died");
		}
		else
		{
			decl String:name[32];
			GetClientName(target, name, sizeof(name));
			PerformSmite(param1, target);
			ShowActivity2(param1, "[SM] ", "%t", "Smote target", "_s", name);
		}
		
		DisplaySmiteMenu(param1);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"sm_smite",
			TopMenuObject_Item,
			AdminMenu_Smite,
			player_commands,
			"sm_smite",
			ADMFLAG_SLAY);
	}
}