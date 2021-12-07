#include <sourcemod>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:Cvar_GlowMe = INVALID_HANDLE
new Handle:Cvar_GlowMeNoSpy = INVALID_HANDLE

new g_Target[MAXPLAYERS+1]
new g_Ent[MAXPLAYERS+1]
new g_noglow[MAXPLAYERS+1]

#define PLUGIN_VERSION "1.0.107"


// Functions
public Plugin:myinfo =
{
	name = "Evil Admin - Glow",
	author = "<eVa>Dog",
	description = "Make a player stand out in the crowd",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_evilglow_version", PLUGIN_VERSION, " Evil Glow Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_GlowMe      = CreateConVar("sm_glowme_enabled", "0", " Allow players to glow themselves", FCVAR_PLUGIN)
	Cvar_GlowMeNoSpy = CreateConVar("sm_glowme_nospy", "0", " Prevent spies from using GlowMe", FCVAR_PLUGIN)
	
	RegAdminCmd("sm_evilglow", Command_ApplyGlow, ADMFLAG_SLAY, "sm_evilglow <#userid|name>")
	RegConsoleCmd("sm_glowme", Command_GlowMe, " glow yourself...")
		
	LoadTranslations("common.phrases")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnMapStart()
{
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookEvent("player_death", PlayerDeathEvent)
	HookEvent("player_disconnect", PlayerDisconnectEvent)
	HookEvent("player_changeclass", ChangeClassEvent, EventHookMode_Pre)
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_death", PlayerDeathEvent)
	UnhookEvent("player_disconnect", PlayerDisconnectEvent)
	UnhookEvent("player_changeclass", ChangeClassEvent)
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (client > 0)
	{
		if ((g_Target[client] == 1) && (g_Ent[client] == 0))
		{
			new team
			team = GetClientTeam(client)
								
			if (team == 3)
			{
				AttachParticle(client, "teleporter_blue_entrance_level3")
				SetEntityRenderMode(client, RENDER_TRANSCOLOR)
				SetEntityRenderColor(client, 0, 0, 255, 255)
			}
			if (team == 2)
			{
				AttachParticle(client, "teleporter_red_entrance_level3")
				SetEntityRenderMode(client, RENDER_TRANSCOLOR)
				SetEntityRenderColor(client, 255, 0, 0, 255)
			}
		}
	}
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if ((IsClientInGame(client)) && g_Ent[client] != 0)
	{
		DeleteParticle(g_Ent[client])
		g_Ent[client] = 0
		SetEntityRenderMode(client, RENDER_TRANSCOLOR)
		SetEntityRenderColor(client, 255, 255, 255, 255)
	}
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (g_Ent[client] != 0)
	{
		DeleteParticle(g_Ent[client])
		g_Target[client] = 0
		g_Ent[client] = 0
	}
}

public Action:ChangeClassEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Cvar_GlowMeNoSpy))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		new class  = GetEventInt(event, "class")
		
		if (class == 8)
		{
			g_noglow[client] = 1
		}
		else
			g_noglow[client] = 0
	}
	return Plugin_Continue
}

public Action:Command_ApplyGlow(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilglow <#userid|name>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	
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
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		PerformEvilGlow(client, target_list[i])
	}
	return Plugin_Handled
}

PerformEvilGlow(client, target)
{
	if (IsClientInGame(target) && IsPlayerAlive(target))
	{
		if (g_Target[target] == 0 && g_Ent[target] == 0)
		{
			new team = GetClientTeam(target)
			
			if (team == 3)
			{
				AttachParticle(target, "teleporter_blue_entrance_level3")
				SetEntityRenderMode(target, RENDER_TRANSCOLOR)
				SetEntityRenderColor(target, 0, 0, 255, 255)
			}
			if (team == 2)
			{
				AttachParticle(target, "teleporter_red_entrance_level3")
				SetEntityRenderMode(target, RENDER_TRANSCOLOR)
				SetEntityRenderColor(target, 255, 0, 0, 255)
			}
			
			if (client != -1)
			{
				LogAction(client, target, "\"%L\" added an evil glow to \"%L\"", client, target)
				ShowActivity(client, "set an Evil glow on %N", target)
			}
		}
		else
		{
			DeleteParticle(g_Ent[target])
			g_Target[target] = 0
			g_Ent[target] = 0
			
			if (client != -1)
			{
				LogAction(client, target, "\"%L\" removed an evil glow from \"%L\"", client, target)
				ShowActivity(client, "removed an Evil glow from %N", target)
			}
			
			SetEntityRenderMode(target, RENDER_TRANSCOLOR)
			SetEntityRenderColor(target, 255, 255, 255, 255)
		}
	}
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system")
	
	new String:tName[128]
	if (IsValidEdict(particle))
	{
		new Float:pos[3] 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos)
		pos[2] += 10
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR)
		
		Format(tName, sizeof(tName), "target%i", ent)
		DispatchKeyValue(ent, "targetname", tName)
		
		DispatchKeyValue(particle, "targetname", "tf2particle")
		DispatchKeyValue(particle, "parentname", tName)
		DispatchKeyValue(particle, "effect_name", particleType)
		DispatchSpawn(particle)
		SetVariantString(tName)
		AcceptEntityInput(particle, "SetParent", particle, particle, 0)
		SetVariantString("head")
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0)
		ActivateEntity(particle)
		AcceptEntityInput(particle, "start")
		
		g_Ent[ent] = particle
		g_Target[ent] = 1
	}
}

DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[256]
        GetEdictClassname(particle, classname, sizeof(classname))
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle)
        }
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
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_evilglow",
			TopMenuObject_Item,
			AdminMenu_Particles, 
			player_commands,
			"sm_evilglow",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_Particles( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Glow")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param)
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players)
	
	decl String:title[100]
	Format(title, sizeof(title), "Choose Player:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddTargetsToMenu(menu, client, true, true)
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
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
		decl String:info[32]
		new userid, target
		
		GetMenuItem(menu, param2, info, sizeof(info))
		userid = StringToInt(info)

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available")
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target")
		}
		else
		{			
			PerformEvilGlow(param1, target)
			
			/* Re-draw the menu if they're still valid */
			if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
			{
				DisplayPlayerMenu(param1)
			}
			
		}
	}
}

public Action:Command_GlowMe(client, args)
{
	if (g_noglow[client] == 0)
	{
		new flags = GetUserFlagBits(client)
			
		if (flags & ADMFLAG_ROOT || flags & ADMFLAG_VOTE )
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (g_Target[client] == 0 && g_Ent[client] == 0)
				{
					PerformEvilGlow(-1, client)
					
					//Make the glow disappear on death
					g_Target[client] = 0
					
					PrintToChatAll("[SM] %N is now glowing", client)
				}
			}
		}
		else if (GetConVarInt(Cvar_GlowMe))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (g_Target[client] == 0 && g_Ent[client] == 0)
				{
					PerformEvilGlow(-1, client)
					
					//Make the glow disappear on death
					g_Target[client] = 0
					
					PrintToChatAll("[SM] %N is now glowing", client)
				}
			}
		}
		else
		{	
			PrintToChat(client, "[SM] GlowMe is not enabled")
		}
	}
	else
	{	
		PrintToChat(client, "[SM] GlowMe is not enabled for spies")
	}
	
	return Plugin_Handled
}
