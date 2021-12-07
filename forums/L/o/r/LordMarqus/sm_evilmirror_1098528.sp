#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:Cvar_MirrorDmg = INVALID_HANDLE;

new g_Target[MAXPLAYERS+1];
new playerhealth[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.0.103"

// Functions
public Plugin:myinfo =
{
	name = "Evil Admin - Mirror Damage",
	author = "<eVa>Dog",
	description = "Make a player do mirror damage",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
};

public OnPluginStart()
{
	CreateConVar("sm_evilmirror_version", PLUGIN_VERSION, " Evil Mirror Damage Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_MirrorDmg = CreateConVar("sm_evilmirrordmg_amount", "1.0", " Amount of damage to inflict each time a player hurts another player", FCVAR_PLUGIN);
	RegAdminCmd("sm_evilmirrordmg", Command_EvilMirror, ADMFLAG_SLAY, "sm_evilmirrordmg <#userid|name>");
	
	HookEvent("player_hurt", PlayerHurtEvent);
	HookEvent("player_spawn", PlayerSpawnEvent);
	
	LoadTranslations("common.phrases");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnClientPostAdminCheck(client)
{
	g_Target[client] = 0;
}

public OnClientDisconnect(client)
{
	g_Target[client] = 0;
}

public OnEventShutdown()
{
	UnhookEvent("player_hurt", PlayerHurtEvent);
	UnhookEvent("player_spawn", PlayerSpawnEvent);
}

public Action:PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)   
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, GetPlayerHealth, client);
}

public Action:GetPlayerHealth(Handle:timer, any:client) 
{
	if (IsClientInGame(client))
	{
		playerhealth[client] = GetClientHealth(client);
	}
}

public Action:PlayerHurtEvent(Handle:event,  const String:name[], bool:dontBroadcast)   
{
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new health   = GetEventInt(event, "health");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (g_Target[attacker] == 1)
	{
		if ((victim > 0) && (IsClientInGame(victim)) && (IsPlayerAlive(victim)) && (attacker != victim))
		{		
			new damage = playerhealth[victim] - health;
			
			playerhealth[victim]  = health + damage;
			SetEntityHealth(victim, playerhealth[victim]);
		}
		
		if (attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker))
		{
			new Float:multiplier = GetConVarFloat(Cvar_MirrorDmg);
			
			new damage = playerhealth[victim] - health;
			
			playerhealth[attacker]  = playerhealth[attacker] - RoundFloat(damage * multiplier);
			if (playerhealth[attacker] >= 1)
			{
				SetEntityHealth(attacker, playerhealth[attacker]);
			}
			else if (playerhealth[attacker] <= 0)
			{
				ForcePlayerSuicide(attacker);
			}
		}
	}
	
}

public Action:Command_EvilMirror(client, args)
{
	decl String:target[65];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilmirrordmg <#userid|name>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, target, sizeof(target));
	
	if ((target_count = ProcessTargetString(
	target,
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
	
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
		{
			PerformEvilMirror(client, target_list[i]);
		}
	}
	return Plugin_Handled;
}

PerformEvilMirror(client, target)
{
	if (g_Target[target] == 0)
	{
		g_Target[target] = 1;
		LogAction(client, target, "\"%L\" enabled mirror damage on \"%L\"", client, target);
		ShowActivity(client, " enabled mirror damage on %N", target);
	}
	else
	{
		g_Target[target] = 0;
		LogAction(client, target, "\"%L\" disabled mirror damage on \"%L\"", client, target);
		ShowActivity(client, " disabled mirror damage on %N", target);
	}			
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
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
		"sm_evilmirrordmg",
		TopMenuObject_Item,
		AdminMenu_Mirror, 
		player_commands,
		"sm_evilmirrordmg",
		ADMFLAG_SLAY);
	}
}

public AdminMenu_Mirror( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Mirror Damage");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param);
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose Player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
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
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
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
			PerformEvilMirror(param1, target);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}