/*

	Version history
	---------------
	1.11	- Minor code optimization and FCVAR_NOTIFY added to convars
	1.1		- Almost rewritten from scratch with cvar-support and colorful chat messages
	1.05	- Added auto-detection of the ZombieMod addon with help of a cvar (removed NAME_COUNTERS & NAME_TERRORS therefore)
	1.04	- Fixed bug were AdminId wasn't set while finding a free slot
	1.03	- Replaced MAX_PLAYERS with GetMaxClients() because the server-side upper client index were out of bounds and caused an error
	1.02	- Minor code optimization
	1.01	- Fixed bug where the three loops for #all, #ct, #t where limited to MAX_SLOTS instead of MAX_PLAYERS
	1.0		- Initial release	

*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME					"i3D-Teleport"
#define PLUGIN_AUTHOR				"Tony G."
#define PLUGIN_DESCRIPTION	"SourceMod replacement for the Mani teleport functionality"
#define PLUGIN_VERSION			"1.11"
#define PLUGIN_URL					"http://www.i3d.net/"

new Handle:g_hCvar_ChatPrefix;
new Handle:g_hCvar_LogEnabled;
new Handle:g_hCvar_DetectZombieMod;

new AdminId:g_AdminSlots[MAXPLAYERS];
new Float:g_LocationSlots[MAXPLAYERS][3];

new String:g_Cvar_ChatPrefix[32];
new g_Cvar_LogEnabled;
new g_Cvar_DetectZombieMod;

new String:g_TeamNames[2][32] = {"counter-terrorists", "terrorists"};

public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL};

public OnPluginStart()
{

	LoadTranslations("common.phrases");

	RegAdminCmd("sm_saveloc", SaveLocation, ADMFLAG_KICK, "Saves the current location for teleport commands");
	RegAdminCmd("sm_teleport", Teleport, ADMFLAG_KICK, "sm_teleport <#id|name>");
	
	g_hCvar_ChatPrefix = CreateConVar("sm_teleport_chat_prefix", "[i3D-Teleport]", "Prefix for chat messages", FCVAR_NOTIFY);
	g_hCvar_DetectZombieMod = CreateConVar("sm_teleport_detect_zm", "1", "Whether to auto-detect ZombieMod addon or not", FCVAR_NOTIFY);
	g_hCvar_LogEnabled = CreateConVar("sm_teleport_log_enabled", "1", "Whether to write actions into server log or not", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "teleport");

	HookConVarChange(g_hCvar_ChatPrefix, ConVarChanged);
	HookConVarChange(g_hCvar_DetectZombieMod, ConVarChanged);	
	HookConVarChange(g_hCvar_LogEnabled, ConVarChanged);

}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LoadSettings();
}

public OnConfigsExecuted()
{
	LoadSettings();
	ResetPlugin();
}

public OnMapStart()
{
	ResetPlugin();
}

LoadSettings()
{

	GetConVarString(g_hCvar_ChatPrefix, g_Cvar_ChatPrefix, sizeof(g_Cvar_ChatPrefix));
	
	for (new i = 0; i < sizeof(g_Cvar_ChatPrefix); i++)
	{
		if (i == 0 && g_Cvar_ChatPrefix[i] == 0)
		{
			break;
		}
		else if (g_Cvar_ChatPrefix[i] == 0)
		{
			g_Cvar_ChatPrefix[i] = ' ';
			g_Cvar_ChatPrefix[i + 1] = 0;
			break;
		}
	}
	
	g_Cvar_LogEnabled = GetConVarInt(g_hCvar_LogEnabled);
	g_Cvar_DetectZombieMod = GetConVarInt(g_hCvar_DetectZombieMod);

	if (g_Cvar_DetectZombieMod)
	{
		if (FindConVar("zombie_health") != INVALID_HANDLE)
		{
			g_TeamNames[0] = "humans";
			g_TeamNames[1] = "zombies";
		}
	}
	else
	{
		g_TeamNames[0] = "counter-terrorists";
		g_TeamNames[1] = "terrorists";
	}

}

ResetPlugin()
{

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		g_AdminSlots[i] = INVALID_ADMIN_ID;
		g_LocationSlots[i][0] = 0.0;
		g_LocationSlots[i][1] = 0.0;
		g_LocationSlots[i][2] = 0.0;
	}

}

GetSlot(client)
{

	new AdminId:admin_id = GetUserAdmin(client);

	if (admin_id != INVALID_ADMIN_ID)
	{
	
		for (new slot = 0; slot < MAXPLAYERS; slot++)
		{
			if (g_AdminSlots[slot] == admin_id)
			{
				return slot;
			}
		}
	
		for (new slot = 0; slot < MAXPLAYERS; slot++)
		{
			if (g_AdminSlots[slot] == INVALID_ADMIN_ID)
			{
				g_AdminSlots[slot] = admin_id;
				return slot;
			}
		}	
	
	}

	return -1;

}

public HasSavedLocation(slot)
{
	return (g_LocationSlots[slot][0] != 0.0 && g_LocationSlots[slot][1] != 0.0 && g_LocationSlots[slot][2] != 0.0);
}

public Action:SaveLocation(client, args)
{

	new slot = GetSlot(client);

	if (slot == -1)
	{
		return Plugin_Handled;
	}
	
	GetClientAbsOrigin(client, g_LocationSlots[slot]);
	
	PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "Current position saved");
	
	return Plugin_Handled;

}

public Action:Teleport(client, args)
{

	if (args < 1)
	{
		PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "No target defined - use: sm_teleport <#id|name>");
		return Plugin_Handled;
	}

	new slot = GetSlot(client);
	
	if (slot == -1)
	{
		return Plugin_Handled;
	}
	
	if (!HasSavedLocation(slot))
	{
		PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "Please save a location first");
		return Plugin_Handled;
	}
	
	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target_list[MAXPLAYERS];	
	new String:target_name[MAX_TARGET_LENGTH];
	new bool:target_ml;
	new target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), target_ml);
	
	if (target_count > 0)
	{

		for (new i = 0; i < target_count; i++)
		{
			TeleportEntity(target_list[i], g_LocationSlots[slot], NULL_VECTOR, NULL_VECTOR);
		}
	
		new String:admin_name[MAX_NAME_LENGTH];
		GetClientName(client, admin_name, sizeof(admin_name));
		
		new String:admin_auth[21];
		GetClientAuthString(client, admin_auth, sizeof(admin_auth));
		
		if (strcmp(arg, "@all") == 0)
		{
			PrintToChatAll("\x04%s\x03%s%s\x01%s", g_Cvar_ChatPrefix, "(ADMIN) ", admin_name, " teleported all players");
			if (g_Cvar_LogEnabled)
			{
				LogAction(client, -1, "%s%s%s%s%d%s%f%s%f%s%f%s", admin_name, " (", admin_auth, ") teleported all players (count: ", target_count, ", location: ", g_LocationSlots[slot][0], " ", g_LocationSlots[slot][1], " ", g_LocationSlots[slot][2], ")");
			}
		}
		else if (strcmp(arg, "@ct") == 0)
		{
			PrintToChatAll("\x04%s\x03%s%s\x01%s%s", g_Cvar_ChatPrefix, "(ADMIN) ", admin_name, " teleported all ", g_TeamNames[0]);
			if (g_Cvar_LogEnabled)
			{
				LogAction(client, -1, "%s%s%s%s%d%s%f%s%f%s%f%s", admin_name, " (", admin_auth, ") teleported all ct's (count: ", target_count, ", location: ", g_LocationSlots[slot][0], " ", g_LocationSlots[slot][1], " ", g_LocationSlots[slot][2], ")");
			}
		}
		else if (strcmp(arg, "@t") == 0)
		{
			PrintToChatAll("\x04%s\x03%s%s\x01%s%s", g_Cvar_ChatPrefix, "(ADMIN) ", admin_name, " teleported all ", g_TeamNames[1]);
			if (g_Cvar_LogEnabled)
			{
				LogAction(client, -1, "%s%s%s%s%d%s%f%s%f%s%f%s", admin_name, " (", admin_auth, ") teleported all t's (count: ", target_count, ", location: ", g_LocationSlots[slot][0], " ", g_LocationSlots[slot][1], " ", g_LocationSlots[slot][2], ")");
			}
		}
		else
		{
			if (strcmp(admin_name, target_name) == 0)
			{
				PrintToChatAll("\x04%s\x03%s%s\x01%s", g_Cvar_ChatPrefix, "(ADMIN) ", admin_name, " teleported himself/herself");
				if (g_Cvar_LogEnabled)
				{
					LogAction(client, -1, "%s%s%s%s%f%s%f%s%f%s", admin_name, " (", admin_auth, ") teleported himself/herself (location: ", g_LocationSlots[slot][0], " ", g_LocationSlots[slot][1], " ", g_LocationSlots[slot][2], ")");
				}
			}
			else
			{
				GetClientName(target_list[0], target_name, sizeof(target_name));
				PrintToChatAll("\x04%s\x03%s%s\x01%s\x03%s", g_Cvar_ChatPrefix, "(ADMIN) ", admin_name, " teleported player ", target_name);
				if (g_Cvar_LogEnabled)
				{
					new String:target_auth[21];
					GetClientAuthString(target_list[0], target_auth, sizeof(target_auth));
					LogAction(client, target_list[0], "%s%s%s%s%s%s%s%s%f%s%f%s%f%s", admin_name, " (", admin_auth, ") teleported player ", target_name, " (", target_auth, ") (location: ", g_LocationSlots[slot][0], " ", g_LocationSlots[slot][1], " ", g_LocationSlots[slot][2], ")");
				}
			}
		}
	
	}
	else if (target_count == COMMAND_TARGET_NONE)
	{
		PrintToChat(client, "\x04%s\x01%s\x03%s\x01%s", g_Cvar_ChatPrefix, "Couldn't find any player named ", arg, " (disconnected?)");
	}
	else if (target_count == COMMAND_TARGET_NOT_ALIVE || target_count == COMMAND_TARGET_NOT_IN_GAME)
	{
		target_list[0] = FindTarget(client, arg);
		if (target_list[0] == client)
		{
			PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "You're not alive/in-game");	
		}
		else
		{
			GetClientName(target_list[0], target_name, sizeof(target_name));
			PrintToChat(client, "\x04%s\x01%s\x03%s\x01%s", g_Cvar_ChatPrefix, "Player ", target_name, " is not alive/in-game");		
		}
	}
	else if (target_count == COMMAND_TARGET_EMPTY_FILTER)
	{
		PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "No matching players found");
	}

	return Plugin_Handled;
	
}