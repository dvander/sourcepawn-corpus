#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
public Plugin:myinfo = 
{
	name = "Ammo Locker",
	author = "Kilandor",
	description = "Enables/Disables ammo lockers via command or round starts",
	version = PLUGIN_VERSION,
	url = "http://www.lankillers.com/"
};

//CVars
new Handle:g_Cvar_AmmoLockerEnabled, Handle:g_Cvar_AmmoLockerRoundStart;

public OnPluginStart()
{
	//Commands
	RegAdminCmd("sm_ammolocker", Command_AmmoLocker, ADMFLAG_GENERIC, "[1/0] - Enables/Disables Ammo Lockers");
	
	//Cvars
	CreateConVar("sm_ammolocker_version", PLUGIN_VERSION, "[TF2]Ammo Locker version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_AmmoLockerEnabled = CreateConVar("sm_ammolocker_enable", "1", "Enables the Ammo Locker Plugin", 0, false, 0.0, false, 0.0);
	g_Cvar_AmmoLockerRoundStart = CreateConVar("sm_ammolocker_roundstart", "1", "Disables Ammo Lockers on round starts", 0, false, 0.0, false, 0.0);
	
	//Hooks
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("teamplay_round_active", Event_TeamplayRoundActive);
}

public Event_ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_Cvar_AmmoLockerRoundStart))
	{
		return;
	}
	AmmoLockerDisabler();
}

public Event_TeamplayRoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_Cvar_AmmoLockerRoundStart))
	{
		return;
	}
	AmmoLockerDisabler();
}

public Action:Command_AmmoLocker(client, args)
{
	if(!GetConVarBool(g_Cvar_AmmoLockerEnabled))
	{
		PrintToChat(client, "\x04[\x03AmmoLocker\x04]\x01 Ammo Lockers Plugin is disabled.");
		return Plugin_Handled;
	}
	new String:ammolocker_args[64];
	GetCmdArg(1, ammolocker_args, sizeof(ammolocker_args));
	if(strcmp(ammolocker_args, "1", false) == 0)
	{
		AmmoLockerDisabler(1);
		PrintToChatAll("\x04[\x03AmmoLocker\x04]\x01 Ammo Lockers have been Enabled.");
	}
	else
	{
		AmmoLockerDisabler();
		PrintToChatAll("\x04[\x03AmmoLocker\x04]\x01 Ammo Lockers have been Disabled.");
	}
	return Plugin_Handled;
}
AmmoLockerDisabler(ammolocker_enable=0)
{
	if(GetConVarBool(g_Cvar_AmmoLockerEnabled))
	{
		new ammolocker_ent = -1;
		while ((ammolocker_ent = FindEntityByClassname(ammolocker_ent, "func_regenerate")) != -1)
		{
			if(!ammolocker_enable)
			{
				AcceptEntityInput(ammolocker_ent, "Disable", -1, -1, 0);
			}
			else
			{
				AcceptEntityInput(ammolocker_ent, "Enable", -1, -1, 0);
			}
		}
	}
}