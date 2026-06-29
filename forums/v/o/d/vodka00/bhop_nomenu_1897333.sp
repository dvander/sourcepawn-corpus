#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION "1.2b"
#define PREFIX "Bhop"
#define DMG_FALL   (1 << 5)

new autobhop_player[MAXPLAYERS+1];
new nbr_scout[MAXPLAYERS+1];
new tele_saved[MAXPLAYERS+1];
new Float:checkpoint[MAXPLAYERS+1][3];

new Handle:sm_bhop_enabled				= INVALID_HANDLE;
new bhop_enabled = 0;
new Handle:sm_bhop_noblock				= INVALID_HANDLE;
new bhop_noblock = 0;
new Handle:sm_bhop_msg_show				= INVALID_HANDLE;
new bhop_msg_show = 0;
new Handle:sm_bhop_landslowdown			= INVALID_HANDLE;
new bhop_landslowdown = 0;
new Handle:sm_bhop_damageslowdown		= INVALID_HANDLE;
new bhop_damageslowdown = 0;
new Handle:sm_bhop_autobhop				= INVALID_HANDLE;
new bhop_autobhop = 0;
new Handle:sm_bhop_gravity				= INVALID_HANDLE;
new bhop_gravity = 0;
new Handle:sm_bhop_gravity_value        = INVALID_HANDLE;
new Float:bhop_gravity_value = 0.0;
new Handle:sm_bhop_max_scout			= INVALID_HANDLE;
new bhop_max_scout = 0;
new Handle:sm_version_bhop				= INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Bhop",
	author = "Dragonfly",
	description = "Plugin with lots of features for BunnyHop's servers. (Thanks to blodia)",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=157374"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("bhop.phrases");
	
	sm_bhop_enabled = CreateConVar("sm_bhop_enabled", "1", "If enabled, this plugin will be activated. Useful for server which use other maps than bhop. (1: enable, 0: disable)");
	bhop_enabled = GetConVarInt(sm_bhop_enabled);
	HookConVarChange(sm_bhop_enabled, BhopSettingChanged);
	sm_bhop_noblock = CreateConVar("sm_bhop_noblock", "1", "If enabled, this will set your server in noblock (1: enable, 0: disable)");
	bhop_noblock = GetConVarInt(sm_bhop_noblock);
	HookConVarChange(sm_bhop_noblock, BhopSettingChanged);
	sm_bhop_msg_show = CreateConVar("sm_bhop_msg_show", "1", "If enabled, the plugin will show a message on connection/deconnection of players (1: enable, 0: disable)");
	bhop_msg_show = GetConVarInt(sm_bhop_msg_show);
	HookConVarChange(sm_bhop_msg_show, BhopSettingChanged);
	sm_bhop_landslowdown = CreateConVar("sm_bhop_landslowdown", "1", "If enabled, this will remove slowdown caused by landing from a jump (1: enable, 0: disable)");
	bhop_landslowdown = GetConVarInt(sm_bhop_landslowdown);
	HookConVarChange(sm_bhop_landslowdown, BhopSettingChanged);
	sm_bhop_damageslowdown = CreateConVar("sm_bhop_damageslowdown", "1", "If enabled, this will remove slowdown caused by damage (1: enable, 0: disable)");
	bhop_damageslowdown = GetConVarInt(sm_bhop_damageslowdown);
	HookConVarChange(sm_bhop_damageslowdown, BhopSettingChanged);
	sm_bhop_autobhop = CreateConVar("sm_bhop_autobhop", "1", "If enabled, Auto Bunny will be activated on the server (1: enable, 0: disable)");
	bhop_autobhop = GetConVarInt(sm_bhop_autobhop);
	HookConVarChange(sm_bhop_autobhop, BhopSettingChanged);
	sm_bhop_gravity = CreateConVar("sm_bhop_gravity", "1", "If enabled, this will activate the lowgrav command on your server (1: enable, 0: disable)");
	bhop_gravity = GetConVarInt(sm_bhop_gravity);
	HookConVarChange(sm_bhop_gravity, BhopSettingChanged);
	sm_bhop_gravity_value = CreateConVar("sm_bhop_gravity_value", "0.6", "Set the multiplier of gravity you want on your server\nIf 1, players will have normal gravity\nIf 0.5, players will have half gravity\netc...");
	bhop_gravity_value = GetConVarFloat(sm_bhop_gravity_value);
	HookConVarChange(sm_bhop_gravity_value, BhopSettingChanged);
	sm_bhop_max_scout = CreateConVar("sm_bhop_max_scout", "2", "Set the number of scouts a player can receive per rounds");
	bhop_max_scout = GetConVarInt(sm_bhop_max_scout);
	HookConVarChange(sm_bhop_max_scout, BhopSettingChanged);
	sm_version_bhop = CreateConVar("sm_version_bhop", PLUGIN_VERSION, "Version of Bhop's plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(sm_version_bhop, BhopSettingChanged);
	
	RegConsoleCmd("sm_scout", Cmd_scout, "Command to take a scout");
	RegConsoleCmd("sm_s", Cmd_save, "Command to save a checkpoint");
	RegConsoleCmd("sm_t", Cmd_tele, "Command to be teleport in your checkpoint");
	RegConsoleCmd("sm_lowgrav", Cmd_lowgrav, "Command to have a lower gravity");
	RegConsoleCmd("sm_normal", Cmd_normal, "Command to have a normal gravity again");
	RegConsoleCmd("sm_autobhop", Cmd_autobhop, "Command to activate Easy Bunny on ourselves");

	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_jump", Event_player_jump);
	HookEvent("player_disconnect", Event_player_disconnect);
	HookEvent("player_hurt", Event_player_hurt);
	
	AutoExecConfig(true, "bhop.plugin");
}

public BhopSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == sm_bhop_enabled)
	{
		bhop_enabled = GetConVarInt(sm_bhop_enabled);
	}
	else if (convar == sm_bhop_noblock)
	{
		bhop_noblock = GetConVarInt(sm_bhop_noblock);
	}
	else if (convar == sm_bhop_msg_show)
	{
		bhop_msg_show = GetConVarInt(sm_bhop_msg_show);
	}
	else if (convar == sm_bhop_landslowdown)
	{
		bhop_landslowdown = GetConVarInt(sm_bhop_landslowdown);
	}
	else if (convar == sm_bhop_damageslowdown)
	{
		bhop_damageslowdown = GetConVarInt(sm_bhop_damageslowdown);
	}
	else if (convar == sm_bhop_autobhop)
	{
		bhop_autobhop = GetConVarInt(sm_bhop_autobhop);
	}
	else if (convar == sm_bhop_gravity)
	{
		bhop_gravity = GetConVarInt(sm_bhop_gravity);
	}
	else if (convar == sm_bhop_gravity_value)
	{
		bhop_gravity_value = GetConVarFloat(sm_bhop_gravity_value);
	}
	else if (convar == sm_bhop_max_scout)
	{
		bhop_max_scout = GetConVarInt(sm_bhop_max_scout);
	}
	else if (convar == sm_version_bhop)
	{
		SetConVarString(convar, PLUGIN_VERSION);
	}
}

public OnClientAuthorized(client)
{
	if (bhop_enabled == 1)
	{
		Keys_create(client);
	
		if (bhop_msg_show == 1)
		{
			new String:name[32];
			new String:steamid[35];
			GetClientName(client, name, sizeof(name));
			GetClientAuthString(client, steamid, sizeof(steamid));
			CPrintToChatAll("\x04[%s]: \x01%t", PREFIX, "client_connected", name, steamid);
		}
	}
}

public OnClientPutInServer(client)
{
	if (bhop_enabled == 1)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype & DMG_FALL)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_player_disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (bhop_enabled == 1)
	{
		if (bhop_msg_show == 1)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new String:client_name[32];
			new String:steamid[35];
			GetClientName(client, client_name, sizeof(client_name));
			GetClientAuthString(client, steamid, sizeof(steamid));
			CPrintToChatAll("\x04[%s]: \x01%t", PREFIX, "client_disconnected", client_name, steamid);
		}
	}
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (bhop_enabled == 1)
	{
		nbr_scout[client] = 0;
	
		if (bhop_noblock == 1)
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
		}
	}
	return Plugin_Continue;
}

public Action:Event_player_jump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (bhop_enabled == 1)
	{
		if (bhop_landslowdown == 1)
		{
			SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
		}
	}
	return Plugin_Continue;
}

public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (bhop_enabled == 1)
	{
		if (bhop_damageslowdown == 2)
		{
			SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", 1.0);
		}
	}
	return Plugin_Continue;
}

Keys_create(client)
{
	nbr_scout[client] = 0;
	tele_saved[client] = 0;
	autobhop_player[client] = 1;
	checkpoint[client][0] = 0.0;
	checkpoint[client][1] = 0.0;
	checkpoint[client][2] = 0.0;
}

public Action:Cmd_scout(client, args)
{
	if (bhop_enabled == 1)
	{
		if (IsPlayerAlive(client))
		{
			if (nbr_scout[client] < bhop_max_scout)
			{
				GivePlayerItem(client, "weapon_scout");
				FakeClientCommand(client, "use weapon_scout");
				nbr_scout[client]++;
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "receive_scout");
			}
			else
			{
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "too_much_scout");
			}
		}
		else
		{
			CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "mustbe_alive");
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_save(client, args)
{
	if (bhop_enabled == 1)
	{
		if (IsPlayerAlive(client))
		{
			if (GetEntDataEnt2(client, FindSendPropOffs("CBasePlayer", "m_hGroundEntity")) != -1)
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", checkpoint[client]);
				tele_saved[client] = 1;
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "checkpoint_save");
			}
			else
			{
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "mustbe_on_ground");
			}
		}
		else
		{
			CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "mustbe_alive");
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_tele(client, args)
{
	if (bhop_enabled == 1)
	{
		if (IsPlayerAlive(client))
		{
			if (tele_saved[client] == 1)
			{
				TeleportEntity(client, checkpoint[client], NULL_VECTOR, NULL_VECTOR);
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "checkpoint_tele");
			}
			else
			{
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "must_save");
			}
		}
		else
		{
			CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "mustbe_alive");
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_lowgrav(client, args)
{
	if (bhop_enabled == 1)
	{
		if (bhop_gravity == 1)
		{
			if (IsPlayerAlive(client))
			{
				SetEntityGravity(client, bhop_gravity_value);
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "lowgrav");
			}
			else
			{
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "mustbe_alive");
			}
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_normal(client, args)
{
	if (bhop_enabled == 1)
	{
		if (bhop_gravity == 1)
		{
			SetEntityGravity(client, 1.0);
			CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "normalgrav");
		}
	}
	return Plugin_Handled;
}
public Action:Cmd_autobhop(client, args)
{
	if (bhop_enabled == 1)
	{
		if (bhop_autobhop == 1)
		{
			if (autobhop_player[client] == 1)
			{
				autobhop_player[client] = 0;
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "autobhop_deactivated");
			}
			else if (autobhop_player[client] == 0)
			{
				autobhop_player[client] = 1;
				CPrintToChat(client, "\x04[%s]: \x01%t", PREFIX, "autobhop_activated");
			}
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_help(client, args)
{
	if (bhop_enabled == 1)
	{
		SendMenuHelp(client);
	}
 	return Plugin_Handled;
}

SendMenuHelp(client)
{
	new Handle:menu = CreateMenu(MenuHelp);
	SetMenuTitle(menu, "  - Bhop Help Menu -  \n ");
	AddMenuItem(menu, "info_scout", "!scout");
	AddMenuItem(menu, "info_s", "!s");
	AddMenuItem(menu, "info_t", "!t");
	if (bhop_gravity == 1)
	{
		AddMenuItem(menu, "info_lowgrav", "!lowgrav");
		AddMenuItem(menu, "info_normal", "!normal");
	}
	if (bhop_autobhop == 1)
	{
		AddMenuItem(menu, "info_autobhop", "!autobhop");
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}


public MenuHelp(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_scout", bhop_max_scout);
			SendMenuHelp(param1);
		}
		else if (param2 == 1)
		{
			CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_s");
			SendMenuHelp(param1);
		}
		else if (param2 == 2)
		{
			CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_t");
			SendMenuHelp(param1);
		}
		if (bhop_gravity == 1 && bhop_autobhop == 0)
		{
			if (param2 == 3)
			{
				CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_lowgrav");
				SendMenuHelp(param1);
			}
			else if (param2 == 4)
			{
				CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_normal");
				SendMenuHelp(param1);
			}
		}
		else if (bhop_gravity == 0 && bhop_autobhop == 1)
		{
			if (param2 == 3)
			{
				CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_autobhop");
				SendMenuHelp(param1);
			}
		}
		else if (bhop_gravity == 1 && bhop_autobhop == 1)
		{
			if (param2 == 3)
			{
				CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_lowgrav");
				SendMenuHelp(param1);
			}
			else if (param2 == 4)
			{
				CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_normal");
				SendMenuHelp(param1);
			}
			else if (param2 == 5)
			{
				CPrintToChat(param1, "\x04[%s]: \x01%t", PREFIX, "info_autobhop");
				SendMenuHelp(param1);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (bhop_enabled == 1)
	{
		if (bhop_autobhop == 1)
		{
			if (autobhop_player[client] == 1 && IsPlayerAlive(client))
			{
				if (buttons & IN_JUMP)
				{
					if (!(GetEntityFlags(client) & FL_ONGROUND))
					{
						if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
						{
							new iType = GetEntProp(client, Prop_Data, "m_nWaterLevel");
							if (iType <= 1)
							{
								buttons &= ~IN_JUMP;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}