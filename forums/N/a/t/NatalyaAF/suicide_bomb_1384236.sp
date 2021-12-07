//	Natalya's Suicide Bomber Script
//	Script by Lady Natalya
//
//	This script will allow players to buy and then detonate a suicide bomb.
//
//	www.lady-natalya.info
//	www.s-low.info
//	www.4chan.org

// Includes
#include <sourcemod>
#include <sdktools>

// Definitions
#define BOMB_VERSION	"1.01"

// CVAR Handles
new Handle:g_Cvar_Enable		= INVALID_HANDLE;
new Handle:g_Cvar_Enabled_T		= INVALID_HANDLE;
new Handle:g_Cvar_Enabled_CT	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb1Price	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb1Damage	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb1Radius	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb1Time		= INVALID_HANDLE;
new Handle:g_Cvar_Bomb2Price	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb2Damage	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb2Radius	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb2Time		= INVALID_HANDLE;
new Handle:g_Cvar_Bomb3Price	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb3Damage	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb3Radius	= INVALID_HANDLE;
new Handle:g_Cvar_Bomb3Time		= INVALID_HANDLE;
new Handle:g_Cvar_DamageExpl	= INVALID_HANDLE;

// Player Arrays
new player_bomb_type[MAXPLAYERS+1];
new player_bomb_time_left[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Suicide Bomb",
	author = "Natalya",
	description = "Suicide Bomb Plugin",
	version = BOMB_VERSION,
	url = "http://www.lady-natalya.info/"
}



// ########################
// Plugin and Player Events
// ########################



public OnPluginStart()
{
	// Load Plugin Requirements
	LoadTranslations("plugin.suicide_bomb");
	
	// Commands
	RegConsoleCmd("sm_bomb", Bomb_Menu, "Open the Bomb Menu.");
	RegConsoleCmd("sm_detonate", Command_Detonate, "Detonate the Bomb.");
	RegConsoleCmd("sm_boom", Command_Detonate, "Detonate the Bomb.");
	
	// CVARs
	g_Cvar_Enable		= CreateConVar("bomb_plugin_enabled", "1", "Enable/Disable the Suicide Bomb plugin", FCVAR_PLUGIN);
	g_Cvar_Enabled_T	= CreateConVar("bomb_enabled_t", "1", "Can Terrorists buy the bomb? 0 or 1", FCVAR_PLUGIN);
	g_Cvar_Enabled_CT	= CreateConVar("bomb_enabled_ct", "0", "Can CTs buy the bomb? 0 or 1", FCVAR_PLUGIN);
	g_Cvar_Bomb1Price	= CreateConVar("bomb_1_price", "5000", "Set the price of bomb 1.  -1 means disabled.", FCVAR_PLUGIN);
	g_Cvar_Bomb1Damage	= CreateConVar("bomb_1_damage", "500", "Set the damage for bomb 1.", FCVAR_PLUGIN);
	g_Cvar_Bomb1Radius	= CreateConVar("bomb_1_radius", "128", "Set the radius for bomb 1 in inches.", FCVAR_PLUGIN);
	g_Cvar_Bomb1Time	= CreateConVar("bomb_1_time", "20.0", "Set the timer for bomb 1 in seconds.", FCVAR_PLUGIN);
	g_Cvar_Bomb2Price	= CreateConVar("bomb_2_price", "7500", "Set the price of bomb 2.  -1 means disabled.", FCVAR_PLUGIN);
	g_Cvar_Bomb2Damage	= CreateConVar("bomb_2_damage", "1000", "Set the damage for bomb 2.", FCVAR_PLUGIN);
	g_Cvar_Bomb2Radius	= CreateConVar("bomb_2_radius", "256", "Set the radius for bomb 2 in inches.", FCVAR_PLUGIN);
	g_Cvar_Bomb2Time	= CreateConVar("bomb_2_time", "15.0", "Set the timer for bomb 2 in seconds.", FCVAR_PLUGIN);
	g_Cvar_Bomb3Price	= CreateConVar("bomb_3_price", "10000", "Set the price of bomb 3.  -1 means disabled.", FCVAR_PLUGIN);
	g_Cvar_Bomb3Damage	= CreateConVar("bomb_3_damage", "2000", "Set the damage for bomb 3.", FCVAR_PLUGIN);
	g_Cvar_Bomb3Radius	= CreateConVar("bomb_3_radius", "512", "Set the radius for bomb 3 in inches.", FCVAR_PLUGIN);
	g_Cvar_Bomb3Time	= CreateConVar("bomb_3_time", "10.0", "Set the timer for bomb 3 in seconds.", FCVAR_PLUGIN);
	g_Cvar_DamageExpl	= CreateConVar("bomb_damage_explode", "0", "If 1, you detonate if shot while you have a bomb.", FCVAR_PLUGIN);
	
	// Hook Events
	HookEvent("player_hurt", Event_player_hurt, EventHookMode_Pre);
	
	// Precache Bomb Tick
	PrecacheSound("buttons/button17.wav", false);
	PrecacheSound( "ambient/explosions/explode_8.wav", true);
}
public OnClientPutInServer(client)
{
	player_bomb_type[client] = 0;
	player_bomb_time_left[client] = -1;
}
public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		PrintToChat(client, "\x04 [Bomb] %T", "Welcome_Msg", client);
	}
}
public OnClientDisconnect(client)
{
	player_bomb_type[client] = 0;
	player_bomb_time_left[client] = -1;
}
public OnMapStart()
{
	HookEvent("player_spawn", PlayerSpawnEvent);
	PrecacheSound("buttons/button17.wav", false);
	PrecacheSound( "ambient/explosions/explode_8.wav", true);
}
public OnMapEnd()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent);
}
public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		player_bomb_time_left[client] = -1;
	}
}
public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	if ((victimId != 0) && (attackerId != 0))
    {
		new victim = GetClientOfUserId(victimId);
		new attacker = GetClientOfUserId(attackerId);
		if (IsClientInGame(victim))
		{
			if (IsClientInGame(attacker))
			{
				if(GetConVarInt(g_Cvar_DamageExpl))
				{
					if ((GetClientTeam(victim) == 2) && (GetClientTeam(attacker) == 3))
					{
						if (player_bomb_type[victim] > 0)
						{
							explode(victim);
						}
					}
					else if ((GetClientTeam(victim) == 3) && (GetClientTeam(attacker) == 2))
					{
						if (player_bomb_type[victim] > 0)
						{
							explode(victim);
						}
					}
				}
			}
		}
	}
}


// ###############
// Player Commands
// ###############



public Action:Bomb_Menu(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new player_team = GetClientTeam(client);
		
		if (player_team < 2)
		{
			PrintToChat(client, "\x04 [Bomb] %T", "Youre_Dead", client);
			return Plugin_Handled;
		}
		if (player_team == 2)
		{
			if(GetConVarInt(g_Cvar_Enabled_T))
			{
				if (player_bomb_type[client] == 0)
				{
					/* Create the menu Handle */
					new Handle:bomb_menu = CreateMenu(Menu_Bomb);

					decl String:title_str[32], String:bomb1_str[32], String:bomb2_str[32], String:bomb3_str[32];
					new price1 = GetConVarInt(g_Cvar_Bomb1Price);
					new price2 = GetConVarInt(g_Cvar_Bomb2Price);
					new price3 = GetConVarInt(g_Cvar_Bomb3Price);
					
					Format(title_str, sizeof(title_str), "%T", "Bomb_Menu", client);
			
					if (price1 > -1)
					{
						Format(bomb1_str, sizeof(bomb1_str), "Small Bomb ($%i)", price1);
						AddMenuItem(bomb_menu, "0", bomb1_str);
					}
					if (price2 > -1)
					{
						Format(bomb2_str, sizeof(bomb2_str), "Medium Bomb ($%i)", price2);
						AddMenuItem(bomb_menu, "0", bomb2_str);
					}
					if (price3 > -1)
					{
						Format(bomb3_str, sizeof(bomb3_str), "Large Bomb ($%i)", price3);
						AddMenuItem(bomb_menu, "0", bomb3_str);
					}

					SetMenuTitle(bomb_menu, title_str);
					DisplayMenu(bomb_menu, client, MENU_TIME_FOREVER);
					return Plugin_Handled;
				}
				else PrintToChat(client, "\x04 [Bomb] %T", "Have_Bomb_Already", client);
				return Plugin_Handled;
			}
			else PrintToChat(client, "\x04 [Bomb] %T", "Disabled_Team", client, "Terrorists");
			return Plugin_Handled;
		}
		if (player_team == 3)
		{
			if(GetConVarInt(g_Cvar_Enabled_CT))
			{
				if (player_bomb_type[client] == 0)
				{
					/* Create the menu Handle */
					new Handle:bomb_menu = CreateMenu(Menu_Bomb);

					decl String:title_str[32], String:bomb1_str[32], String:bomb2_str[32], String:bomb3_str[32];
					new price1 = GetConVarInt(g_Cvar_Bomb1Price);
					new price2 = GetConVarInt(g_Cvar_Bomb2Price);
					new price3 = GetConVarInt(g_Cvar_Bomb3Price);
			
					if (price1 > -1)
					{
						Format(bomb1_str, sizeof(bomb1_str), "Small Bomb ($%i)", price1);
						AddMenuItem(bomb_menu, "0", bomb1_str);
					}
					if (price2 > -1)
					{
						Format(bomb2_str, sizeof(bomb1_str), "Medium Bomb ($%i)", price2);
						AddMenuItem(bomb_menu, "1", bomb1_str);
					}
					if (price3 > -1)
					{
						Format(bomb3_str, sizeof(bomb1_str), "Large Bomb ($%i)", price3);
						AddMenuItem(bomb_menu, "2", bomb1_str);
					}

					SetMenuTitle(bomb_menu, title_str);
					DisplayMenu(bomb_menu, client, MENU_TIME_FOREVER);
					return Plugin_Handled;
				}
				else PrintToChat(client, "\x04 [Bomb] %T", "Have_Bomb_Already", client);
				return Plugin_Handled;
			}
			else PrintToChat(client, "\x04 [Bomb] %T", "Disabled_Team", client, "Counter-Terrorists");
			return Plugin_Handled;
		}
	}
	else PrintToChat(client, "\x04 [Bomb] %T", "Disabled", client);
	return Plugin_Handled;
}
public Menu_Bomb(Handle:bomb_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		return;
	}
	else if (action == MenuAction_Select)
	{
		// They chose a bomb.  Let's see if we give it to them or not.
		if (player_bomb_type[param1] == 0)
		{
			if (param2 == 0)
			{
				// They chose bomb 1.
				
				// Why is it like this?  I have no idea.
				new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
				new money = GetEntData(param1, MoneyOffset);
				new price1 = GetConVarInt(g_Cvar_Bomb1Price);
				
				if (money >= price1)
				{
					money -= price1;
					SetEntData(param1, MoneyOffset, money, 4, true);
					
					player_bomb_type[param1] = 1;
					
					PrintToChat(param1, "\x04 [Bomb] %T", "Bought_C", param1, "Small Bomb");
					return;
				}
				else PrintToChat(param1, "\x04 [Bomb] %T", "Expensive", param1, price1);
				return;
			}
			if (param2 == 1)
			{
				// They chose bomb 2.
				
				// Why is it like this?  I have no idea.
				new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
				new money = GetEntData(param1, MoneyOffset);
				new price2 = GetConVarInt(g_Cvar_Bomb2Price);
				
				if (money >= price2)
				{
					money -= price2;
					SetEntData(param1, MoneyOffset, money, 4, true);
					
					player_bomb_type[param1] = 2;
					
					PrintToChat(param1, "\x04 [Bomb] %T", "Bought_C", param1, "Medium Bomb");
					return;
				}
				else PrintToChat(param1, "\x04 [Bomb] %T", "Expensive", param1, price2);
				return;
			}
			if (param2 == 2)
			{
				// They chose bomb 3.
				
				// Why is it like this?  I have no idea.
				new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
				new money = GetEntData(param1, MoneyOffset);
				new price3 = GetConVarInt(g_Cvar_Bomb3Price);
				
				if (money >= price3)
				{
					money -= price3;
					SetEntData(param1, MoneyOffset, money, 4, true);
					
					player_bomb_type[param1] = 3;
					
					PrintToChat(param1, "\x04 [Bomb] %T", "Bought_C", param1, "Large Bomb");
					return;
				}
				else PrintToChat(param1, "\x04 [Bomb] %T", "Expensive", param1, price3);
				return;
			}
		}
		else PrintToChat(param1, "\x04 [Bomb] %T", "Have_Bomb_Already", param1);
		return;
	}
	return;
}
public Action:Command_Detonate(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (player_bomb_type[client] > 0)
		{
			if (!IsPlayerAlive(client))
			{
				PrintToChat(client, "\x04[Bomb] %T", "Youre_Dead", client);
			}
			else
			{
				if (player_bomb_type[client] == 1)
				{
					new Float:time1;
					time1 = GetConVarFloat(g_Cvar_Bomb1Time);
					player_bomb_time_left[client] = RoundFloat(time1);
					if (player_bomb_time_left[client] > 0)
					{
						CreateTimer(1.0, Bomb_Time, client);
						EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);						
					}
					else
					{
						explode(client);
					}
					return Plugin_Handled;
				}
				if (player_bomb_type[client] == 2)
				{
					new Float:time2;
					time2 = GetConVarFloat(g_Cvar_Bomb2Time);
					player_bomb_time_left[client] = RoundFloat(time2);
					if (player_bomb_time_left[client] > 0)
					{
						CreateTimer(1.0, Bomb_Time, client);
						EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
					}
					else
					{
						explode(client);
					}					
					return Plugin_Handled;
				}
				if (player_bomb_type[client] == 3)
				{
					new Float:time3;
					time3 = GetConVarFloat(g_Cvar_Bomb3Time);
					player_bomb_time_left[client] = RoundFloat(time3);
					if (player_bomb_time_left[client] > 0)
					{
						CreateTimer(1.0, Bomb_Time, client);
						EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
					}
					else
					{
						explode(client);
					}	
					return Plugin_Handled;
				}				
			}
		}
		else PrintToChat(client, "\x04 [Bomb] %T", "No_Bomb", client);
	}
	else PrintToChat(client, "\x04 [Bomb] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Bomb_Time(Handle:timer, any:client)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			if (player_bomb_type[client] < 1)
			{
				return;
			}
			if (player_bomb_time_left[client] < 0)
			{
				return;
			}
			if (player_bomb_time_left[client] == 0)
			{
				// Zero Time -- BOOM!!
				explode(client);
			}
			else if (player_bomb_time_left[client] > 0)
			{
				player_bomb_time_left[client] -= 1;
				CreateTimer(1.0, Bomb_Time, client);
				EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
				return;
			}
		}
	}
	return;
}
stock explode(client)
{
	new explosion = CreateEntityByName("env_explosion");
	if (explosion != -1)
	{
		// Stuff we will need
		decl Float:vector[3];
		new damage = 500;
		new radius = 128;
		new team = GetEntProp(client, Prop_Send, "m_iTeamNum");
					
		// We're going to use eye level because the blast can be clipped by almost anything.
		// This way there's no chance that a small street curb will clip the blast.
		GetClientEyePosition(client, vector);
					
		if (player_bomb_type[client] == 1)
		{
			damage = GetConVarInt(g_Cvar_Bomb1Damage);
			radius = GetConVarInt(g_Cvar_Bomb1Radius);
		}
		else if (player_bomb_type[client] == 2)
		{
			damage = GetConVarInt(g_Cvar_Bomb2Damage);
			radius = GetConVarInt(g_Cvar_Bomb2Radius);
		}
		else if (player_bomb_type[client] == 3)
		{
			damage = GetConVarInt(g_Cvar_Bomb3Damage);
			radius = GetConVarInt(g_Cvar_Bomb3Radius);
		}
					
		SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
		SetEntProp(explosion, Prop_Data, "m_spawnflags", 264);
		SetEntProp(explosion, Prop_Data, "m_iMagnitude", damage);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", radius);
		DispatchKeyValue(explosion, "rendermode", "5");
					
		DispatchSpawn(explosion);
		ActivateEntity(explosion);
					
		TeleportEntity(explosion, vector, NULL_VECTOR, NULL_VECTOR);					
		EmitSoundToAll("weapons/hegrenade/explode5.wav", explosion, 1, 90);					
		AcceptEntityInput(explosion, "Explode");
					
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
					
		EmitSoundToAll("ambient/explosions/explode_8.wav", explosion, 1, 90);						
					
		// Bomb detonated.  Let's clean up now.
		player_bomb_type[client] = 0;
		player_bomb_time_left[client] = -1;
	}
}
			



