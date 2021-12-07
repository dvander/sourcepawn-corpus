#include <sourcemod>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:Cvar_Particle = INVALID_HANDLE
new Handle:Cvar_ParticleMe = INVALID_HANDLE

new g_Target[MAXPLAYERS+1]
new g_Ent[MAXPLAYERS+1]

#define PLUGIN_VERSION "1.0.104"

// Functions
public Plugin:myinfo =
{
	name = "Evil Admin - Trails",
	author = "<eVa>Dog",
	description = "Apply a trail to a player",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_eviltrail_version", PLUGIN_VERSION, " Evil Particles Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_Particle = CreateConVar("sm_eviltrail_particle", "rockettrail_!", " The particle to be used for the trail", FCVAR_PLUGIN)
	Cvar_ParticleMe = CreateConVar("sm_trailme_enabled", "0", " Allow players to use their own trails", FCVAR_PLUGIN)
	
	RegAdminCmd("sm_eviltrail", Command_ApplyParticles, ADMFLAG_SLAY, "sm_eviltrail <#userid|name>")
	RegConsoleCmd("sm_trailme", Command_ParticleMe, " get a trail!")
	
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
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_death", PlayerDeathEvent)
	UnhookEvent("player_disconnect", PlayerDisconnectEvent)
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
			
			decl String:particlename[256]
			GetConVarString(Cvar_Particle, particlename, sizeof(particlename))
					
			if (team == 3)
				AttachParticle(client, particlename)
			if (team == 2)
				AttachParticle(client, particlename)
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

public Action:Command_ApplyParticles(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_eviltrail <#userid|name>");
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
	
	decl String:particlename[256]
	GetConVarString(Cvar_Particle, particlename, sizeof(particlename))
	new team
	
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
		{
			if (g_Target[target_list[i]] == 0)
			{
				team = GetClientTeam(target_list[i])
				
				if (team == 3)
					AttachParticle(target_list[i], particlename)
				if (team == 2)
					AttachParticle(target_list[i], particlename)
				
				LogAction(client, target_list[i], "\"%L\" added an evil trail to \"%L\"", client, target_list[i])
				ShowActivity(client, "set an Evil Trail on %N", target_list[i])
			}
			else
			{
				DeleteParticle(g_Ent[target_list[i]])
				g_Target[target_list[i]] = 0
				g_Ent[target_list[i]] = 0
				LogAction(client, target_list[i], "\"%L\" removed an evil trail from \"%L\"", client, target_list[i])
				ShowActivity(client, "removed an Evil Trail from %N", target_list[i])
			}
		}
	}
	return Plugin_Handled
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
		SetVariantString("flag")
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
			"sm_evilparticles",
			TopMenuObject_Item,
			AdminMenu_Particles, 
			player_commands,
			"sm_evilparticles",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_Particles( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Trails")
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
			decl String:particlename[256]
			GetConVarString(Cvar_Particle, particlename, sizeof(particlename))
			
			if (g_Target[target] == 0)
			{
				new team
				team = GetClientTeam(target)
					
				if (team == 3)
					AttachParticle(target, particlename)
				if (team == 2)
					AttachParticle(target, particlename)
					
				LogAction(param1, target, "\"%L\" added an evil trail to \"%L\"", param1, target)
				ShowActivity(param1, "set an Evil Trail on %N", target)
			}
			else
			{
				DeleteParticle(g_Ent[target])
				g_Ent[target] = 0
				g_Target[target] = 0
				
				LogAction(param1, target, "\"%L\" removed an evil trail from \"%L\"", param1, target)
				ShowActivity(param1, "removed an Evil Trail from %N", target)
			}
			
			/* Re-draw the menu if they're still valid */
			if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
			{
				DisplayPlayerMenu(param1)
			}
			
		}
	}
}

public Action:Command_ParticleMe(client, args)
{
	if (GetConVarInt(Cvar_ParticleMe))
	{	
		if ((g_Target[client] == 0) && (g_Ent[client] == 0))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				new team
				team = GetClientTeam(client)
				
				decl String:particlename[256]
				GetConVarString(Cvar_Particle, particlename, sizeof(particlename))
					
				if (team == 3)
					AttachParticle(client, particlename)
				if (team == 2)
					AttachParticle(client, particlename)
					
				g_Target[client] = 0
				
				PrintToChatAll("[SM] %N is now wearing a trail", client)
			}
		}
	}
	else
	{	
		PrintToChat(client, "[SM] TrailMe is not enabled")
	}
}