#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "TrapKill",
	author = "[poni] Shutterfly",
	description = "Allows players to 'own' and receive kill credit from trigger_hurt map brushes.",
	version = "1.0",
	url = "forums.alliedmods.net"
}


#define DAMAGEBITS_SAWBLADE 65536

new Handle:triggerOwner = INVALID_HANDLE; // Trie to lookup trigger/client ownership
new Handle:clientTriggers[MAXPLAYERS+1] = {INVALID_HANDLE, ...}; // Array of adt_array, defiens the triggers a client owns
new Handle:activeTriggers[MAXPLAYERS+1] = {INVALID_HANDLE, ...}; // Array of adt_array, defines the triggers a client is touching

// Start up
public OnMapStart()
{
	// Initialize Globals
	triggerOwner = CreateTrie();
	for(new i=0; i<MAXPLAYERS+1; i++)
	{
		clientTriggers[i] = CreateArray();
		activeTriggers[i] = CreateArray();
	}
	
	// Hook on to trigger_hurt brushes
	HookEntityOutput("trigger_hurt", "OnUser1", Event_OnUser1); // Set|Replace ownership
	HookEntityOutput("trigger_hurt", "OnUser2", Event_OnUser2); // Set vacant ownership
	HookEntityOutput("trigger_hurt", "OnUser3", Event_OnUser3); // Remove ownership
	HookEntityOutput("trigger_hurt", "OnKill", Event_OnUser3); // fires when the brush is removed from the world - remove the owner
	
	HookEntityOutput("trigger_hurt", "OnStartTouch", Event_OnStartTouch); // player starts touching this trigger
	HookEntityOutput("trigger_hurt", "OnEndTouch", Event_OnEndTouch); // player stops touching this trigger
	
	// Hook on to game events
	HookEvent("player_disconnect", Event_OnPlayerDisconnect, EventHookMode_Pre); // Capture player_disconnect events
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre); // Capture player_death events
}

// Clean up
public OnMapEnd()
{
	UnhookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	UnhookEvent("player_disconnect", Event_OnPlayerDisconnect, EventHookMode_Pre); 

	UnhookEntityOutput("trigger_hurt", "OnEndTouch", Event_OnEndTouch); 
	UnhookEntityOutput("trigger_hurt", "OnStartTouch", Event_OnStartTouch); 

	UnhookEntityOutput("trigger_hurt", "OnKill", Event_OnUser3); 
	UnhookEntityOutput("trigger_hurt", "OnUser3", Event_OnUser3); 
	UnhookEntityOutput("trigger_hurt", "OnUser2", Event_OnUser2); 
	UnhookEntityOutput("trigger_hurt", "OnUser1", Event_OnUser1); 
	
	for(new i=0; i<MAXPLAYERS+1; i++)
	{
		ClearArray(clientTriggers[i]);
		ClearArray(activeTriggers[i]);
		CloseHandle(clientTriggers[i]);
		CloseHandle(activeTriggers[i]);
	}
	
	ClearTrie(triggerOwner);
	CloseHandle(triggerOwner);
}

// Kick-Start this plugin
public OnPluginStart()
{
	OnMapStart();
}

// Stock to check valid clients
bool:IsValidClient(client, bool:alive=false)
{	
	if((client > -1) && (client <= MaxClients)  && IsValidEntity(client) && IsClientInGame(client))
		if(alive) 
			return IsPlayerAlive(client);
		else	
			return true;			
	
	return false;
}

// Stock routine to remove a trigger's owner
RemoveTriggerOwner(trigger)
{
	decl String:strigger[32];
	IntToString(trigger, strigger, sizeof(strigger));
		
	new client;
	if(GetTrieValue(triggerOwner, strigger, client) != false)
	{
		new index = FindValueInArray(clientTriggers[client], trigger);
		if(index > -1)
			RemoveFromArray(clientTriggers[client], index);
			
		RemoveFromTrie(triggerOwner, strigger);
	}
}

// Stock routine to remove all triggers from a client
RemoveClientTriggers(client)
{
	if(IsValidClient(client))
	{
		ClearArray(activeTriggers[client]); // no longer touching anything

		while(GetArraySize(clientTriggers[client]) > 0)
			RemoveTriggerOwner(GetArrayCell(clientTriggers[client], 0));
		
	}
}


// Stock routine to set (optionally replace) a trigger's owner
SetTriggerOwner(trigger, client, bool:replace)
{
	if(IsValidClient(client))
	{
		decl String:strigger[32];
		IntToString(trigger, strigger, sizeof(strigger));
		
		new dummy;
		if(replace == true || (replace == false && GetTrieValue(triggerOwner, strigger, dummy) == false))
		{
			RemoveTriggerOwner(trigger);
		
			//if(FindValueInArray(clientTriggers[client], trigger) == -1)
			PushArrayCell(clientTriggers[client], trigger);
		
			SetTrieValue(triggerOwner, strigger, client, true);			
		}
	}
}

// Event hook, Set/Replace a trigger's owner
public Event_OnUser1(const String:output[], caller, activator, Float:delay)
{
	//PrintToChatAll("dbg: trigger %d now belongs to client %d", caller, activator);
	SetTriggerOwner(caller, activator, true);
}

// Event hook, Set (no replace) a trigger's owner
public Event_OnUser2(const String:output[], caller, activator, Float:delay)
{
	SetTriggerOwner(caller, activator, false);
}

// Event hook, Remove a trigger's owner
public Event_OnUser3(const String:output[], caller, activator, Float:delay)
{
	RemoveTriggerOwner(caller);
}

// Event hook, Player is touching a trigger_hurt - Keep track of that.
public Event_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if(IsValidClient(activator, true))
	{		
		if(FindValueInArray(activeTriggers[activator], caller) == -1)
			PushArrayCell(activeTriggers[activator], caller);		
	
	}
}

// Event hook, Player stopped touching a trigger_hurt - Keep track of that too.
public Event_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if(IsValidClient(activator))
	{		
		new index = FindValueInArray(activeTriggers[activator], caller);
		if(index != -1)
			RemoveFromArray(activeTriggers[activator], index);
	}
}

// Event hook, Player disconnected. - This is important cuz they should no longer be touching or owning any triggers.
public Action:Event_OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveClientTriggers(client);
	return Plugin_Continue;
}

// Event hook, Player died. Here we check if the player died from a trigger and take appropriate action.
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// who died?
	new victimId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimId);	
	
	if(IsValidClient(victim))
	{

		// what was the weapon that killed them?
		decl String:weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));		
		
		// was it a trigger_hurt brush?
		if(StrEqual(weapon, "trigger_hurt"))
		{
		
			// ...what was the last known trigger_hurt the victim was touching?
			new index = GetArraySize(activeTriggers[victim]) - 1;
			if(index > -1)
			{
				// which brush was this?
				new brush = GetArrayCell(activeTriggers[victim], index);
				new String:sbrush[32];
				IntToString(brush, sbrush, sizeof(sbrush));
				
				// who owned that brush?
				new attacker;
				GetTrieValue(triggerOwner, sbrush, attacker);

				if(IsValidClient(attacker))
				{
					decl String:svictim[64];
					GetClientName(victim, svictim, sizeof(svictim));
				
					decl String:sattacker[64];
					GetClientName(attacker, sattacker, sizeof(sattacker));				
				
					// can't attack yourself...
					if(attacker != victim)
					{
						// Pluck the player to death for score reasons
						SDKHooks_TakeDamage(victim, 0, attacker, 1.0, DMG_PREVENT_PHYSICS_FORCE|DMG_ALWAYSGIB|DAMAGEBITS_SAWBLADE);
						return Plugin_Changed; // but this death event never happened.
					}				
				}
			}
		}		
		
		// well, the victim is dead so they're not touching anything anymore...
		ClearArray(activeTriggers[victim]);
	}

	// normal operation, carry on.
	return Plugin_Continue;
}

