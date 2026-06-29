/*
* Freeze All 
* Author(s): retsam
* File: sm_freezeall.sp
* Description: Allows admins to freeze all players on server and give immunity to selected players.
*
*
* 0.3 - Few small adjustments made. No longer getting movement type in freeze functions.
* 0.2 - Added admin menu so you can give immunity to specific players after everyone is frozen.
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "0.3"

#define SOUND_FREEZE "physics/glass/glass_impact_bullet4.wav"

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:Cvar_Freeze_Enabled = INVALID_HANDLE;

new g_FreezeSprite;

new bool:g_bIsEnabled = true;
new bool:g_bSetAllFrozen = false;
new bool:g_bPlayerIsFrozen[MAXPLAYERS+1] = { false, ... };

public Plugin:myinfo = 
{
	name = "Freeze All",
	author = "retsam",
	description = "Allows admins to freeze all players on server and give immunity to selected players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=142494"
}

public OnPluginStart()
{
	CreateConVar("sm_freezeall_version", PLUGIN_VERSION, "Version of Freeze All", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Freeze_Enabled = CreateConVar("sm_freezeall_enabled", "1", "Enable freezeall all plugin?(1/0 = yes/no)");
	
	HookEvent("player_spawn", Hook_PlayerSpawn, EventHookMode_Post);
	
	HookConVarChange(Cvar_Freeze_Enabled, Cvars_Changed);
	
	RegAdminCmd("sm_freezeall", Command_FreezeAll, ADMFLAG_BAN, "Admin command to freeze all players.");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	//AutoExecConfig(true, "plugin.freezeall");
}

public OnClientPostAdminCheck(client)
{
	if(g_bSetAllFrozen)
	{
		g_bPlayerIsFrozen[client] = true;
	}
	else
	{
		g_bPlayerIsFrozen[client] = false;
	}
}

public OnClientDisconnect(client)
{
  g_bPlayerIsFrozen[client] = false;
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Freeze_Enabled);
}

public OnMapStart()
{
	g_bSetAllFrozen = false;
  
  PrecacheSound(SOUND_FREEZE, true);
	g_FreezeSprite = PrecacheModel("sprites/blueglow2.vmt");
}

public OnMapEnd()
{
	if(g_bSetAllFrozen)
	{
		g_bSetAllFrozen = false;
	}
}


public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled || !g_bSetAllFrozen)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client < 1 || !IsPlayerAlive(client))
	return;

	if(g_bPlayerIsFrozen[client])
	{
		CreateTimer(0.05, Timer_FreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_FreezePlayer(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	return;

	FreezePlayer(client);
	PrintToChat(client, "\x04All players have been Frozen, you are unable to move at this time!");
}

public Action:Command_FreezeAll(client, args)
{
	if(client < 1 || !IsClientInGame(client))
	return Plugin_Handled;

	if(!g_bIsEnabled)
	{
		ReplyToCommand(client, "[SM] Sorry, this plugin has been disabled by the server.");
		return Plugin_Handled;
	}

	if(!g_bSetAllFrozen)
	{
		//PrintToChatAll("[SM] ADMIN has Frozen all players in place.");
		ShowActivity(client, "has Frozen all players in place.");
		FreezeAllPlayers(client);
		g_bSetAllFrozen = true;
	}
	else
	{
		//PrintToChatAll("[SM] ADMIN has Unfrozen all players.");
		ShowActivity(client, "has Unfrozen all players.");
		UnfreezeAllPlayers(client);
		g_bSetAllFrozen = false;
	}
	
	return Plugin_Handled;
}

public FreezeAllPlayers(client)
{
	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x) || x == client)
		{
			continue;
		}
		
		if(!IsPlayerAlive(x))
		{
			g_bPlayerIsFrozen[x] = true;
			continue;
		}
			
		g_bPlayerIsFrozen[x] = true;
		FreezePlayer(x);
	}
}

public UnfreezeAllPlayers(client)
{
	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x))
		{
			continue;
		}
		
		if(!IsPlayerAlive(x))
		{
			g_bPlayerIsFrozen[x] = false;
			continue;
		}
		
		//new MoveType:movetype = GetEntityMoveType(x);
		//if(movetype == MOVETYPE_NONE)
		if(g_bPlayerIsFrozen[x])
    {
			g_bPlayerIsFrozen[x] = false;
			FreezePlayer(x);
		}
	}
}

stock FreezePlayer(client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client);

	if(!g_bPlayerIsFrozen[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	else
	{
		TE_SetupGlowSprite(vec, g_FreezeSprite, 0.95, 1.5, 50);
		TE_SendToAll();
		SetEntityMoveType(client, MOVETYPE_NONE);
	}
}

ToggleFreezeImmunity(client, target)
{
	if(!IsPlayerAlive(target))
	{
		if(g_bPlayerIsFrozen[target])
		{
			g_bPlayerIsFrozen[target] = false;
			ShowActivity(client, "has granted %N Immunity to being frozen.", target);
			PrintToChat(target, "\x04[SM] Admin has granted you Immunity to being frozen.");
		}
		else
		{
			g_bPlayerIsFrozen[target] = true;
			ShowActivity(client, "has revoked %N's freeze Immunity.", target);
			PrintToChat(target, "\x04[SM] Admin revoked your freeze Immunity.");
		}
	}
	else
	{
		if(g_bPlayerIsFrozen[target])
		{
			g_bPlayerIsFrozen[target] = false;
			FreezePlayer(target);
			
			ShowActivity(client, "has granted %N Immunity to being frozen.", target);
			PrintToChat(target, "\x04[SM] An admin has granted you Immunity to being frozen.");
		}
		else
		{
			g_bPlayerIsFrozen[target] = true;
			FreezePlayer(target);
			ShowActivity(client, "has revoked %N's freeze Immunity.", target);
			PrintToChat(target, "\x04[SM] An admin revoked your freeze Immunity and re-froze you.");
		}
	}
}

public OnLibraryRemoved(const String:name[])
{
	//PrintToChatAll("OnLibraryRemoved is: %s", name);
	if(StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
		"sm_freezeall",
		TopMenuObject_Item,
		AdminMenu_FreezeAll, 
		player_commands,
		"sm_freezeall",
		ADMFLAG_BAN);
	}
}

public AdminMenu_FreezeAll(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "FreezeAll");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayFreezeOptions(param);
	}
}

DisplayFreezeOptions(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Options);
	
	decl String:title[100];
	Format(title, sizeof(title), "FreezeAll Options:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	if(g_bIsEnabled)
	{
		if(!g_bSetAllFrozen)
		{
			AddMenuItem(menu, "freezeall", "<Freeze All>");
			AddMenuItem(menu, "freezeimmune", "Player Immunity", ITEMDRAW_DISABLED);
		}
		else
		{
			AddMenuItem(menu, "freezeall", "<Unfreeze All>");
			AddMenuItem(menu, "freezeimmune", "Player Immunity");
		}
	}
	else
	{
		AddMenuItem(menu, "disabled", "[Plugin Disabled]", ITEMDRAW_DISABLED);
	}

	DisplayMenu(menu, client, 30);
}

public MenuHandler_Options(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		
		if(StrEqual(sSelection, "freezeall", false))
		{
			if(!g_bSetAllFrozen)
			{
				ShowActivity(param1, "has Frozen all players in place.");
				FreezeAllPlayers(param1);
				g_bSetAllFrozen = true;
			}
			else
			{
				//PrintToChatAll("[SM] ADMIN has Unfrozen all players.");
				ShowActivity(param1, "has Unfrozen all players.");
				UnfreezeAllPlayers(param1);
				g_bSetAllFrozen = false;
			}
			
			DisplayFreezeOptions(param1);
		}
		else if(StrEqual(sSelection, "freezeimmune", false))
    {
      DisplayPlayerMenu(param1);
    }
	}
}

DisplayPlayerMenu(client)
{
  new Handle:menu = CreateMenu(MenuHandler_Players);
  
  decl String:title[100];
  Format(title, sizeof(title), "Choose Player For Immunity:");
  SetMenuTitle(menu, title);
  SetMenuExitBackButton(menu, true);
  AddTargetsToMenu(menu, client, true, true);
  DisplayMenu(menu, client, 45);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayFreezeOptions(param1);
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
			PrintToChat(param1, "[SM] %s", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target");
		}
		else
		{					
			ToggleFreezeImmunity(param1, target);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Freeze_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
}
