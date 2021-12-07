//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// This plugin allows players to change their model!


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.104SM"
#define MAXMODELS 35

new String: g_modelname[][] = {
	"models/player/american_support.mdl",
	"models/player/german_support.mdl",
	"models/props_foliage/shrub_01a.mdl",
	"models/props_foliage/flower_barrel.mdl",
	"models/props_furniture/table1.mdl",
	"models/props_crates/static_crate_64.mdl",
	"models/props_crates/woodbarrel001.mdl",
	"models/props_italian/wagon.mdl",
	"models/props_urban/phonepole1.mdl",
	"models/props_foliage/pot_big.mdl",
	"models/props_fortifications/sandbags_corner1.mdl",
	"models/props_fortifications/dragonsteeth_large.mdl",
	"models/props_foliage/hedge_small.mdl",
	"models/props_misc/well-1.mdl",
	"models/props_crates/tnt_dump.mdl",
	"models/props_foliage/rock_coast02c.mdl",
	"models/props_foliage/rock_riverbed02c.mdl",
	"models/props_foliage/tree_pine_01.mdl",
	"models/props_furniture/chairantique.mdl",
	"models/props_normandy/haybale.mdl",
	"models/props_misc/claypot02.mdl",
	"models/props_foliage/cattails.mdl",
	"models/props_foliage/shrub_small.mdl",
	"models/props_fortifications/hedgehog_small1.mdl",
	"models/props_furniture/dresser1.mdl",
	"models/props_vehicles/sherman_tank.mdl",
	"models/props_vehicles/kubelwagen.mdl",
	"models/props_urban/bench_wood.mdl",
	"models/props_foliage/tree_deciduous_01a.mdl",
	"models/props_italian/boat_wooden03a.mdl",
	"models/props_italian/anzio_market_table1.mdl",
	"models/props_italian/anzio_fountain.mdl",
	"models/props_fortifications/sandbags_line2_tall.mdl",
	"models/props_vehicles/tiger_tank.mdl",
	"models/props_vehicles/222.mdl"
	}
 
new String:g_modeltext[][] = {
	"Allies soldier",
	"Axis soldier",
	"Shrub",
	"Flower barrel",
	"Table",
	"Crate",
	"Wooden barrel",
	"Wagon",
	"Phone pole",
	"Big flower pot",
	"Sandbags curved",
	"Concrete block",
	"Hedge",
	"Well",
	"TNT dump",
	"Rock",
	"Group of rocks",
	"Pine tree",
	"Chair",
	"Hay bale",
	"Pot",
	"Cattails",
	"Small shrub",
	"Hedgehog",
	"Dresser",
	"Sherman tank",
	"Kubelwagen",
	"Bench",
	"Deciduous tree",
	"Boat",
	"Market table",
	"Fountain",
	"Sandbags straight",
	"Tiger tank",
	"Armored car"
	}
	
new g_modelindex[MAXMODELS + 1]
new third[33]
new g_amount[33]

new Handle:g_Menu
new Handle:g_Cvar_ForceThird = INVALID_HANDLE
new Handle:g_Cvar_EnableThirdCmd = INVALID_HANDLE
new Handle:g_Cvar_CamoEnabled = INVALID_HANDLE
new Handle:g_Cvar_CamoAmount = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "DoDS Fun Camo",
	author = "<eVa>Dog",
	description = "Change into a different model!",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_camo_version", PLUGIN_VERSION, "Version of sm_dod_camo", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegConsoleCmd("sm_3rd", ThirdPerson, " -  Changes player's view to Third person")
	RegConsoleCmd("sm_camo", Command_Camo, " -  Changes player's model via a menu")
	RegConsoleCmd("sm_nocamo", Command_NoCamo, " -  Changes player's model back to normal")
	
	g_Cvar_ForceThird = CreateConVar("sm_camo_forcethird", "0", " When enabled, forces all player to thirdperson when they change camo", FCVAR_PLUGIN)
	g_Cvar_EnableThirdCmd = CreateConVar("sm_camo_thirdperson", "1", " When enabled, allows players to use the third person command", FCVAR_PLUGIN)
	g_Cvar_CamoEnabled = CreateConVar("sm_camo_enabled", "1", " When enabled, the camo plugin is available", FCVAR_PLUGIN)
	g_Cvar_CamoAmount = CreateConVar("sm_camo_amount", "10", " The number of times between lives that a player can change their camo", FCVAR_PLUGIN)
	
	HookConVarChange(g_Cvar_CamoEnabled, RevertNormal)
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre)
	HookEvent("player_spawn", Event_PlayerSpawn)
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", Event_PlayerSpawn)
	UnhookEvent("player_hurt", Event_PlayerHurt)
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (GetConVarInt(g_Cvar_CamoEnabled))
	{
		g_amount[client] = GetConVarInt(g_Cvar_CamoAmount)
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new team = GetClientTeam(client)
				
	new offset = FindSendPropOffs("CBaseEntity", "m_nModelIndex")
	
	if (team == 2)
		SetEntData(client, offset, g_modelindex[0], 4, true)
	if (team == 3)
		SetEntData(client, offset, g_modelindex[1], 4, true)
		
	SetEntityRenderColor(client, 255, 255, 255, 255)
	return Plugin_Continue
}

public OnMapStart()
{
	for (new i = 0; i < MAXMODELS; i++)
	{
		g_modelindex[i] = PrecacheModel(g_modelname[i], true)
		PrintToServer("Cached: %s with number %i", g_modelname[i], g_modelindex[i])
	}
	
	g_Menu = BuildMapMenu()
}

public OnMapEnd()
{
	if (g_Menu != INVALID_HANDLE)
	{
		CloseHandle(g_Menu)
		g_Menu = INVALID_HANDLE
	}
}

public Action:Command_Camo(client, args)
{
	if (GetConVarInt(g_Cvar_CamoEnabled))
	{
		if (g_amount[client] > 0)
		{
			g_amount[client]--
			if (g_Menu == INVALID_HANDLE)
			{
				PrintToConsole(client, "Unable to make menu...")
				return Plugin_Handled
			}	
			DisplayMenu(g_Menu, client, MENU_TIME_FOREVER)
		}
		else
		{
			PrintToChat(client, "[SM]You have run out of camouflage")
		}
	}
	else
	{
		PrintToChat(client, "[SM]Camo plugin disabled")
	}
	return Plugin_Handled
}


public Action:Command_NoCamo(client, args)
{
	if (GetConVarInt(g_Cvar_CamoEnabled))
	{
		if (client)
		{
			if (IsPlayerAlive(client))
			{
				new team = GetClientTeam(client)
				
				new offset = FindSendPropOffs("CBaseEntity", "m_nModelIndex")
				
				if (team == 2)
					SetEntData(client, offset, g_modelindex[0], 4, true)
				if (team == 3)
					SetEntData(client, offset, g_modelindex[1], 4, true)
					
				SetEntityRenderColor(client, 255, 255, 255, 255)
				PrintToChat(client,"\x01You are back to normal")
				
				SwitchView(client, 0)
				third[client] = 0
			}
		} 
	}
	else
	{
		PrintToChat(client, "[SM]Camo plugin disabled")
	}
	return Plugin_Handled
}

public Action:ThirdPerson(client, args)
{
	if (GetConVarInt(g_Cvar_CamoEnabled))
	{
		if (GetConVarInt(g_Cvar_EnableThirdCmd) == 1)
		{
			if (client)
			{
				if (IsPlayerAlive(client))
				{
					if (!third[client])
					{
						SwitchView(client, 1)
						third[client] = 1
					}
					else
					{
						SwitchView(client, 0)
						third[client] = 0
					}
				}
			}
		}
		else
		{
			PrintToChat(client, "[SM] Command has been disabled")
		}
	}
	else
	{
		PrintToChat(client, "[SM]Camo plugin disabled")
	}
	
	return Plugin_Handled
}

public Camo(client, choice)
{
	if (client)
	{
		if (IsPlayerAlive(client))
		{
			if (choice > MAXMODELS)
				choice = MAXMODELS
			
			new offset = FindSendPropOffs("CBaseEntity", "m_nModelIndex")
			SetEntData(client, offset, g_modelindex[choice], 4, true)
			SetEntityRenderColor(client, 255, 255, 255, 255)
			PrintToChat(client,"\x01You are now a \x04%s\x01!", g_modeltext[choice])
			
			// Force player into thirdperson if they are not already
			if (GetConVarInt(g_Cvar_ForceThird) == 1)
			{
					SwitchView(client, 1)
					third[client] = 1
			}
		}
	}
}

SwitchView(target, viewstate)
{
	if (target)
	{
		if (IsPlayerAlive(target))
		{
			if (viewstate == 1)
			{
				SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", 0)
				SetEntProp(target, Prop_Send, "m_iObserverMode", 1)
				SetEntProp(target, Prop_Send, "m_bDrawViewmodel", 0)
				SetEntProp(target, Prop_Send, "m_iFOV", 120)			
			}
			else
			{
				SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", -1)
				SetEntProp(target, Prop_Send, "m_iObserverMode", 0)
				SetEntProp(target, Prop_Send, "m_bDrawViewmodel", 1)
				SetEntProp(target, Prop_Send, "m_iFOV", 90)			
			}
		}
	}
}

Handle:BuildMapMenu()
{
	new Handle:menu = CreateMenu(Menu_Camo)

	for (new camo = 0; camo < MAXMODELS; camo++)
	{
		AddMenuItem(menu, g_modeltext[camo], g_modeltext[camo])
	}
	SetMenuTitle(menu, "Please select camouflage:")
 
	return menu
}
 
public Menu_Camo(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{ 
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))
		Camo(param1, param2)
	}
}
 
public RevertNormal(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
    {
		for (new client=1; client <= GetMaxClients(); client++)
		{
			if (IsClientInGame(client))
			{
				if (IsPlayerAlive(client))
				{
					new team = GetClientTeam(client)
					
					new offset = FindSendPropOffs("CBaseEntity", "m_nModelIndex")
					
					if (team == 2)
						SetEntData(client, offset, g_modelindex[0], 4, true)
					if (team == 3)
						SetEntData(client, offset, g_modelindex[1], 4, true)
						
					SetEntityRenderColor(client, 255, 255, 255, 255)
					PrintToChat(client,"\x01You are back to normal")
					
					SwitchView(client, 0)
					third[client] = 0
				}
			}
		}
	}
}