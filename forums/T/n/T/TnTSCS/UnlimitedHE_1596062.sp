/**
PLUGIN REQUEST URL - http://forums.alliedmods.net/showthread.php?t=171942
PLUGIN REQUEST USER - Da_maniaC (http://forums.alliedmods.net/member.php?u=149246)

REQUEST:
	I am looking for a plugin/script that will give players 1 HEGrenade when they spawn. 
	Then if they use it they will get a new grenade after 'n' amount of time.
	
**/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new bool:PlayerHasGrenade[MAXPLAYERS+1] = false;
new bool:HE_Enabled = true;

new Float:HE_Timer;

public Plugin:myinfo = 
{
	name = "Unlimited HE",
	author = "TnTSCS aKa ClarkKent",
	description = "This plugin will give players a nade at spawn and new one X seconds after detonation",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	// Create Plugin ConVars
	CreateConVar("sm_unlimitedhe_version_build", SOURCEMOD_VERSION, "The version of SourceMod that 'Unlimited HE' was compiled with.", FCVAR_PLUGIN);
	CreateConVar("sm_unlimitedhe_version", PLUGIN_VERSION, "The version of 'Unlimited HE'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	new Handle:hRandom;// KyleS Hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_unlimitedhe_delay", "15", 
	"Number of seconds to wait after HE detonation to give player a new hegrenade", _, true, 0.1, true, 300.0)), HE_TimerChanged);
	HE_Timer = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_unlimitedhe_enabled", "1", 
	"1=enabled, 0=disabled", _, true, 0.0, true, 1.0)), HE_EnabledChanged);
	HE_Enabled = GetConVarBool(hRandom);
	
	CloseHandle(hRandom);// KyleS Hates handles
	
	// Hook all needed events for this plugin
	HookEvent("hegrenade_detonate", Event_OnGrenadeExplode);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("item_pickup", Event_OnItemPickup);
	HookEvent("weapon_fire", Event_OnGrenadeThrow);
	
	// Create admin command so admins can turn this plugin on or off
	RegAdminCmd("sm_unlimitedhe", Command_UnlimitedHE, ADMFLAG_GENERIC, "Change the status of the UnlimitedHE.  1=enabled, 0=disabled");
	
	// Execute the config file
	AutoExecConfig(true, "UnlimtedHE.plugin");	
}

public HE_TimerChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	HE_Timer = GetConVarFloat(cvar);
}
	
public HE_EnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	HE_Enabled = GetConVarBool(cvar);
}

public Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get Client of this event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Get string of this event for "item"
	new String:weapon[32];
	GetEventString(event, "item", weapon, sizeof(weapon));
	
	// If item picked up was an hegrenade
	if(StrEqual(weapon, "hegrenade", false))
	{
		// If a timer is running for this client, kill it since they already have an hegrenade
		if(g_ClientTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_ClientTimer[client]);
			g_ClientTimer[client] = INVALID_HANDLE;
		}
		
		// Player has hegrenade
		PlayerHasGrenade[client] = true;
	}
}
	
public Event_OnGrenadeThrow(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	// Get string of this event for "weapon"
	new String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	// If weapon used was an hegrenade
	if(StrEqual(weapon, "hegrenade", false))
	{
		// Client no longer has an hegrenade
		PlayerHasGrenade[client] = false;
	}
}

public Event_OnGrenadeExplode(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	// Make sure plugin is enabled, client is in game and alive and that the player hasn't picked up another hegrenade
	if(HE_Enabled && IsClientInGame(client) && IsPlayerAlive(client) && !PlayerHasGrenade[client] && g_ClientTimer[client] == INVALID_HANDLE)
	{
		// Create timer to give player another hegrenade
		g_ClientTimer[client] = CreateTimer(HE_Timer, t_GiveHE, client);
	}
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Give player an hegrenade if they have proper access (can be overriden to allow all players)
	if(CheckCommandAccess(client, "give_unlimitedhe_allow", ADMFLAG_CUSTOM1))
	{
		// Equip player with an hegrenade
		GivePlayerItem(client, "weapon_hegrenade");
		PlayerHasGrenade[client] = true;
	}
}


public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Clean up client variables and timers
	if(IsClientInGame(client))
	{
		if(g_ClientTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_ClientTimer[client]);
			g_ClientTimer[client] = INVALID_HANDLE;
		}
		
		PlayerHasGrenade[client] = false;
	}
}

public Action:t_GiveHE(Handle:timer, any:client)
{
	// Make sure the timer hasn't been cancelled prior to firing
	if(IsClientConnected(client) && IsClientInGame(client) && g_ClientTimer[client] != INVALID_HANDLE)
	{
		g_ClientTimer[client] = INVALID_HANDLE;
		
		// Only give player hegrenade if they dont have one
		if(HE_Enabled && !PlayerHasGrenade[client])
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}
}

public OnClientDisconnect(client)
{
	// Clean up client variables and timers
	if(IsClientInGame(client))
	{
		if(g_ClientTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_ClientTimer[client]);
			g_ClientTimer[client] = INVALID_HANDLE;
		}
		
		PlayerHasGrenade[client] = false;
	}	
}

public Action:Command_UnlimitedHE(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "\x04[SM] Usage: sm_unlimitedhe <1/0>");
		return Plugin_Handled;
	}
	
	new String:arg[2];
	GetCmdArg(1, arg, sizeof(arg));
	
	new OnOff = StringToInt(arg);

	switch(OnOff)
	{
		case 0:
		{
			if(!HE_Enabled)
				return Plugin_Handled;
			
			HE_Enabled = false;
			PrintToChatAll("\x04Unlimited HEGrendades -[\x03deactivated\x04]-");
			LogMessage("[UnlimitedHE] DeActivated");		
		}
		
		case 1:
		{
			if(HE_Enabled)
				return Plugin_Handled;
			
			HE_Enabled = true;
			PrintToChatAll("\x04Unlimited HEGrenades -[\x03active\x04]-");
			LogMessage("[UnlimitedHE] Activated");
		}
		
		default:
		{
			ReplyToCommand(client, "\x04[SM] Usage: sm_unlimitedhe <1/0>");
		}
	}
	return Plugin_Continue;
}