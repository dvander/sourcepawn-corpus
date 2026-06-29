#include <sourcemod>
#include <sdktools>

new NumberOfRemoves[MAXPLAYERS+1]
new MaxRemoves
new Handle:MaxRemovesVar = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Remove Weapon on Floor",
	author = "Impact",
	description = "Let Ct's remove weapon by aiming on it",
	version = "0.1",
	url = "non"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_rw", Command_RemoveWeapon, "Removes a Weapon...")
	MaxRemovesVar = CreateConVar("sm_rw_max_weapons", "3", "Max Weapons a Ct can remove")
	MaxRemoves = GetConVarInt(MaxRemovesVar)
	
	HookEvent("round_start", Event_RoundStart)
	HookConVarChange(Handle:MaxRemovesVar, MaxRemovesChange)
}

public MaxRemovesChange(Handle:convar, String:oldValue[], const String:newValue[])
{
	MaxRemoves = GetConVarInt(MaxRemovesVar)
}


public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	// Reset the number Removes a client has made
	for(new i = 0; i < MaxClients; i++)
	{
		NumberOfRemoves[i] = 0
	}
}


public Action:Command_RemoveWeapon(client, args)
{
	if(client && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3 ) // If Client is connected and a CT
	{
		if(NumberOfRemoves[client] < MaxRemoves) // If Client has not reached maximum removes
		{
			new Target = GetClientAimTarget(client, false) // Gets the Target
			
			if(IsValidEntity(Target)) // If entity is valid
			{
				new String:EntName[32]
				GetEntityClassname(Target, EntName, sizeof(EntName)) // Gets the Entityname
				if(StrContains(EntName, "weapon_", true) != -1) // If Entity is a weapon, contains weapon_
				{
					if(GetEntPropEnt(Target, Prop_Send, "m_hOwner") == -1) // Entity has now owner, stick to a client?
					{
						NumberOfRemoves[client] = NumberOfRemoves[client] +1 // Increase the removements
						AcceptEntityInput(Target, "Kill") // Remove the Weapon
						PrintToChat(client, "\x03You have removed %s, [%d/%d]", EntName, NumberOfRemoves[client], MaxRemoves) // Print to Client
					}
				}
			}
		}
		else // If Client has reached Maximum removes
		{
			PrintToChat(client, "\x03You have reached the maximum of %d removes for this round", MaxRemoves) // Print to Client
		}
	}
	
	
	return Plugin_Handled
	
}
