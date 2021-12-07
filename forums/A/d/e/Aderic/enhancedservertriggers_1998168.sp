#include <sourcemod>
#include <sdktools> 

#define MAX_BUFF 	512
#define MAX_ARGS  3
#define MAX_ARGSIZE  32
#define MAX_LIFETIME_TRIGGERS	128

new Handle:pluginEnabled;
new Handle:pluginLogging;
// This array holds the triggers that have been triggered by the player, on death it is cleared.
new triggerList[MAXPLAYERS+1][MAX_LIFETIME_TRIGGERS];

public Plugin:myinfo = 
{
	name = "Enhanced Triggers",
	author = "Aderic",
	description = "Allows the execution of player-target server commands to be executed through triggers.",
	version = "2.0"
}

public OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath)
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre); 
	HookEntityOutput("trigger_multiple", "OnTrigger", OnTrigger);
	
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (!(StrContains(tags, "enhancedtriggers", false)>-1))
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, "enhancedtriggers");
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	CloseHandle(hTags);
	
	pluginEnabled = CreateConVar("sm_enhancedtriggers", "1", "Enables or disables enhanced server triggers."); 
	pluginLogging = CreateConVar("sm_enhancedtriggerslogging", "0", "Enables or disables server output.");
	PrintToServer("Enhanced Triggers has been loaded.");
}

public OnTrigger(const String:output[], caller, activator, Float:delay)
{
	if (GetConVarBool(pluginEnabled) && IsValidEntity(activator) && IsClientInGame(activator))
	{
		// Get the command to run from the trigger's name field.
		new String:triggerName[MAX_BUFF];
		GetEntPropString(caller, Prop_Data, "m_iName", triggerName, sizeof(triggerName));
		
		decl String:args[3][32];		
		ExplodeString(triggerName, " ", args, MAX_ARGS, MAX_ARGSIZE);
		
		new String:triggerCommand[MAX_BUFF];
		
		if (StrEqual(args[0], "run")) { // Specifies if this trigger should use enhanced server triggers.
			// If the next section of the name (separated by space) is lifetime... act as a lifetime trigger.
			if (StrEqual(args[1], "lifetime")) {		
				// If this trigger was already ran on this player in his current life...
				if (triggerList[activator][StringToInt(args[2])] == 1)
					return; // Do nothing!
				else 
				{ 	// If this trigger was not used in the player's lifetime...
					triggerList[activator][StringToInt(args[2])] = 1; // Flag the trigger by index as stored.
					
					// Strip the trigger information required by this plugin, to ready us for executing this command.
					strcopy(triggerCommand, sizeof(triggerCommand), triggerName[strlen(args[2]) + 13]); //args[2] contains the ID of the trigger, 13 is the length of "run lifetime ".
				}
			}
			else if (StrEqual(args[1], "constant")) { //No ID should be used with this parameter, 13 is the length of "run lifetime ", strip it from our command..
				strcopy(triggerCommand, sizeof(triggerCommand), triggerName[13]); // Strip the part of the plugin out of the server command.
			}
			
			// Get player name.
			new String:playerName[MAX_NAME_LENGTH];
			GetClientName(activator, playerName, sizeof(playerName));	
			
			// Get player steamid.
			new String:playerSteamID[18];
			GetClientAuthString(activator, playerSteamID, sizeof(playerSteamID));
							
			if (StrContains(triggerCommand, "%activator%", true))
				ReplaceString(triggerCommand, sizeof(triggerCommand), "%activator%", playerName, true);
					
			if (StrContains(triggerCommand, "%activatorsteamid%", true))
				ReplaceString(triggerCommand, sizeof(triggerCommand), "%activatorsteamid%", playerSteamID, true);
							
			if (StrContains(triggerCommand, "%activatorclientid%", true))
			{   // Get client id.
				new String:playerID[8];
				IntToString(activator, playerID, sizeof(playerID));
				ReplaceString(triggerCommand, sizeof(triggerCommand), "%activatorclientid%", playerID, true);
			}
				
			if (GetConVarBool(pluginLogging)) {
				PrintToServer("Enhanced Triggers (%s, %s) triggered command: %s", playerName, playerSteamID, triggerCommand);				
			}
			
			ServerCommand(triggerCommand);
		}
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetLifetimeTriggers(GetEventInt(event, "userid"));
}

public OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetLifetimeTriggers(GetEventInt(event, "userid"));
}

public ResetLifetimeTriggers(userid) 
{
	new clientID = GetClientOfUserId(userid);
	
	for (new I = 0; I < MAX_LIFETIME_TRIGGERS; I++) {
		triggerList[clientID][I] = 0;
	}
}