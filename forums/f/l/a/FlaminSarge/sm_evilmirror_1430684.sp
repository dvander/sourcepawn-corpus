#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new bool:enable[MAXPLAYERS+1];
new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:hCvar_MirrorDmg = INVALID_HANDLE;
new Float:cvar_mirrordmg;

#define PLUGIN_VERSION "1.0.3"

public Plugin:myinfo =
{
	name		= "Evil Admin - Mirror Damage",
	author		= "<eVa>Dog (modified by Bacardi, FlaminSarge)",
	description	= "Make a player do mirror damage",
	version		= PLUGIN_VERSION,
	url			= "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_evilmirror_version", PLUGIN_VERSION, " Evil Mirror Damage Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	hCvar_MirrorDmg = CreateConVar("sm_evilmirrordmg_amount", "1.0", " Amount of damage to inflict each time a player hurts another player", FCVAR_PLUGIN);
	cvar_mirrordmg = GetConVarFloat(hCvar_MirrorDmg);
	HookConVarChange(hCvar_MirrorDmg, cvhook_mirrordmg);
	RegAdminCmd("sm_evilmirrordmg", Command_EvilMirror, ADMFLAG_SLAY, "sm_evilmirrordmg <#userid|name> [0|1]");

	LoadTranslations("common.phrases");
	for (new client = 1; client <= MaxClients; client++)
	{
		enable[client] = false;
		if (IsClientInGame(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}
public cvhook_mirrordmg(Handle:convar, const String:oldValue[], const String:newValue[]) cvar_mirrordmg = GetConVarFloat(convar); 

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	enable[client] = false;
}

public OnClientDisconnect_Post(client)
{
	enable[client] = false;
}

public Action:Command_EvilMirror(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilmirrordmg <#userid|name> [0|1]");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new bool:on = true;

	if (args > 1)
	{
		decl String:value[2];
		GetCmdArg(2, value, sizeof(value));
//		PrintToServer("%s", value);
		on = bool:StringToInt(value);
	}

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
		PerformEvilMirrorDmg(client, target_list[i], on);
	}

	if (tn_is_ml)	// Didn't understand..
	{
		ShowActivity2(client, "[SM]", "%s mirror damage on %t", on ? "enabled" : "disabled", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM]", "%s mirror damage on %s", on ? "enabled" : "disabled", target_name);
	}

	return Plugin_Handled;
}

PerformEvilMirrorDmg(client, target, bool:value)
{
	enable[target] = value;	// Give "curse" to targets
	LogAction(client, target, "\"%L\" Set Evil: Mirror Damage \"%L\" to %i", client, target, value);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker == victim) return Plugin_Continue;
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker)) return Plugin_Continue;
	if (!enable[attacker]) return Plugin_Continue;
	new Float:damage2 = damage * cvar_mirrordmg;
	SDKHooks_TakeDamage(attacker, inflictor, victim, damage2, damageType, weapon, damageForce, damagePosition);
	damage *= 0.0;
	return Plugin_Changed;
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
			PerformEvilMirrorDmg(param1, target, !enable[target]);
			ShowActivity2(param1, "[SM]", "%s mirror damage on %N", enable[target] ? "enabled" : "disabled", target);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

