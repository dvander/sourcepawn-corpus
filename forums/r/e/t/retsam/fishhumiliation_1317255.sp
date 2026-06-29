/************************************************************************************************
* [TF2] Fish Humiliation 
* Author(s): retsam
* File: fishhumiliation.sp
* Description: Displays a random public humiliation chat msg when players are killed with a fish.
**************************************************************************************************
* 
* 0.2 - Reverted back to older version due to valve fixing mackerel death issue. 
*     - Using updated deadringer flag bit now.
*     - Slightly altered the messages.     
*
* 0.1 - Initial Release
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.2"

new Handle:Cvar_Fish_Enabled = INVALID_HANDLE;

new bool:g_bIsEnabled = true;

public Plugin:myinfo = {
	name = "Fish Humiliation",
	author = "retsam",
	description = "Displays a random public humiliation chat msg when players are killed with a fish.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1317255"
};


public OnPluginStart() 
{ 

	CreateConVar("sm_fishhumiliation_version", PLUGIN_VERSION, "Version of Fish Humiliation", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Fish_Enabled = CreateConVar("sm_fishhumiliation_enabled", "1", "Enable fish humiliation plugin?(1/0 = yes/no)");

	HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
	
	HookConVarChange(Cvar_Fish_Enabled, Cvars_Changed);
	
	//AutoExecConfig(true, "plugin.fishhumiliation");
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Fish_Enabled);
}

public Hook_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new deathflags = GetEventInt(event, "death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER) return;

	//PrintToChatAll("\x011\x022\x033\x044\x055\x066");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new weaponId = GetEventInt(event, "weaponid");
	//new customkill = GetEventInt(event, "customkill");

	//PrintToChatAll("WeaponID is: %i", weaponId);
	if(weaponId == TF_WEAPON_BAT_FISH)
	{
		//PrintToChatAll("Player died by mackerel!");
		RandomMessage(client);
	}
}

public RandomMessage(client)
{
	decl String:message[200];
	new rand = GetRandomInt(0, 4);
	switch(rand)
	{
	case 0:
		{
			Format(message, sizeof(message), "\x01\x05>> \x01Ha! \x03%N \x01was killed with a \x04Fish\x01!", client);
		}
	case 1:
		{
			Format(message, sizeof(message), "\x01\x05>> \x03%N \x01got slapped around with a \x04Mackerel\x01!", client);
		}
	case 2:
		{
			Format(message, sizeof(message), "\x01\x05>> \x01Oh Noes! \x03%N \x01was killed with a \x04Fish\x01! How humiliating!", client);
		}
	case 3:
		{
			Format(message, sizeof(message), "\x01\x05>> \x03%N \x01was humiliated with a \x04Fish\x01!", client);
		}
	case 4:
		{
			Format(message, sizeof(message), "\x01\x05>> \x03%N \x01was beaten to a pulp with a \x04Mackerel\x01!", client);
		}
	}

	SayText2All(client, message);
}    

stock SayText2All(author_index , const String:message[])
{
	new Handle:buffer = StartMessageAll("SayText2");
	if (buffer != INVALID_HANDLE)
  {
		BfWriteByte(buffer, author_index);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Fish_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
}
