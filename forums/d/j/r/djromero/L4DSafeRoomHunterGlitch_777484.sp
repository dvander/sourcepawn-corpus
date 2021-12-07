/********************************************************************************************
* Plugin	: L4DSafeRoomHunterGlitch
* Version	: 1.0
* Game		: Left 4 Dead 
* Author	: djromero (SkyDavid, David)
* Testers	: Myself
* Website	: www.sky.zebgames.com
* A
* Purpose	: This plugin prevents the Hunter/Safe Room glitch, or any other that involves
* 			   infected entering the safe room while the door is closed.
* 			  NOTE: If infected enters before the door is closed, he won't be killed after
* 					it is.
********************************************************************************************/

#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

new offsetIsGhost;
new bool:SafeRoomDoorClosed = false;


public Plugin:myinfo = 
{
	name = "[L4D] Safe Room Hunter Glitch Blocker",
	author = "djromero (skyDavid)",
	description = "Prevents hunters from entering a locked safe room",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public OnPluginStart()
{
	// We find some offsets
	offsetIsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	

	// We register the version cvar
	CreateConVar("l4d_saferoomhunterglitch_version", PLUGIN_VERSION, "Version of the plguin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	
	// Hook general events
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	
	RegisterEvents();
}

public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	// We mark the safe room door as open
	SafeRoomDoorClosed = false;
	
	return Plugin_Continue;
}

public Action:Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
}


public Action:Event_DoorOpen (Handle:event, const String:name[], bool:dontBroadcast)
{
	// if the door was a checkpoint door ...
	new bool:checkpointdoor  = GetEventBool(event, "checkpoint");
	
	if (checkpointdoor == true)
	{
		SafeRoomDoorClosed = false;
	}
	
	return Plugin_Continue;
}

public Action:Event_DoorClose(Handle:event, const String:name[], bool:dontBroadcast)
{
	// if the door was a checkpoint door ...
	new bool:checkpointdoor  = GetEventBool(event, "checkpoint");
	
	if (checkpointdoor == true)
	{
		SafeRoomDoorClosed = true;
	}
	
	return Plugin_Continue;
}

bool:IsPlayerGhost (client)
{
	new isghost;
	isghost = GetEntData(client, offsetIsGhost, 1);
	
	if (isghost == 1)
		return true;
	else
	return false;
}


public Action:Event_EnterCheckpoint (Handle:event, const String:name[], bool:dontBroadcast)
{
	// gets the id
	new id = GetClientOfUserId(GetEventInt(event, "userid"));
	
	
	// If checkpoint door is closed ...
	if (SafeRoomDoorClosed)
	{
		
		// If is a valid player
		if ((id > 0) && (id <= GetMaxClients()) && (IsClientConnected(id)) && (IsClientInGame(id)))
		{
			// If player is on infected's team and is alive and is not in ghost mode 
			if ((GetClientTeam(id) == 3) && (IsPlayerAlive(id)) && (!IsPlayerGhost(id)))
			{
				
				
				// We kill the player
				ForcePlayerSuicide(id);
				
				new String:PlayerName[200];
				GetClientName(id, PlayerName, sizeof(PlayerName));
				
				// We show it to all...
				PrintToChatAll ("\x01\x04[SM] \x03%s \x01was killed for attemping the Hunter/Safe Room glitch.", PlayerName);
			}
		}
	}
	
	return Plugin_Continue;
}


RegisterEvents ()
{
	HookEvent("door_open", Event_DoorOpen, EventHookMode_Post);
	HookEvent("door_close", Event_DoorClose, EventHookMode_Post);
	HookEvent("player_entered_checkpoint", Event_EnterCheckpoint, EventHookMode_Post);
}

///////////////////////