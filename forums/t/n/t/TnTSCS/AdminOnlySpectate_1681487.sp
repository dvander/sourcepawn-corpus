#pragma semicolon 1

#include <sourcemod>

#define SPECMODE_NONE				0
#define SPECMODE_FIRSTPERSON		4
#define SPECMODE_3RDPERSON			5
#define SPECMODE_FREELOOK			6

#define PLUGIN_VERSION				"1.00"

new bool:SpecAny[MAXPLAYERS+1] 			= 	{false, ...};
new Handle:ClientTimer[MAXPLAYERS+1] 	= 	{INVALID_HANDLE, ...};
new Handle:ClientTimer2[MAXPLAYERS+1] 	= 	{INVALID_HANDLE, ...};

new Handle:mp_forcecamera = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Admin ONLY Spectate",
	author = "TnTSCS aka ClarkKent",
	description = "Allows only Admins (or VIPs with flag) to spectate all players",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_aos_version", PLUGIN_VERSION, "Version of Admin Only Spectate", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	
	HookEvent("player_death", Event_Death);
	HookEvent("round_end", Event_RoundEnd);
	
	AddCommandListener(Command_SpecNext, "spec_next");
	AddCommandListener(Command_SpecPrev, "spec_prev");
	AddCommandListener(Command_SpecMode, "spec_mode");
	
	if ((mp_forcecamera = FindConVar("mp_forcecamera")) == INVALID_HANDLE)
	{
		SetFailState("Convar mp_forcecamera not found");
	}
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (CheckCommandAccess(client, "allow_spectate_all", ADMFLAG_CHEATS))
	{
		SpecAny[client] = true;
		SendConVarValue(client, mp_forcecamera, "0");
	}
	else
	{
		SpecAny[client] = false;
		SendConVarValue(client, mp_forcecamera, "1");
	}
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		ClearTimer(ClientTimer[client]);
		ClearTimer(ClientTimer2[client]);
		
		SpecAny[client] = false;
		
		SendConVarValue(client, mp_forcecamera, "0");
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new target;
	
	// Check all players spectating this player and make them spectate the next player on their team, if available
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !SpecAny[i] && !IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client))
		{
			target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			// This client (i) is spectating the player that just died - let's change them to the next available player, or set their spectator mode to 0
			if (target == client)
			{
				ClearTimer(ClientTimer2[i]);
				
				ClientTimer2[i] = CreateTimer(0.75, Timer_ChangeSpec, i);
			}
		}
	}
	
	if (IsFakeClient(client) || SpecAny[client])
	{
		return;
	}
	
	ClearTimer(ClientTimer[client]);
	
	ClientTimer[client] = CreateTimer(6.0, Timer_DiedSpec, client);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new target;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && GetClientTeam(i) > 1 && ClientTimer[i] == INVALID_HANDLE && ClientTimer2[i] == INVALID_HANDLE)
		{
			target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			if (CheckSpec(i, target))
			{
				FindNextSpec(i);
			}
		}
	}
}

public Action:Timer_DiedSpec(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	if (CheckSpec(client, target))
	{
		FindNextSpec(client);
	}
}

public Action:Timer_ChangeSpec(Handle:timer, any:client)
{
	ClientTimer2[client] = INVALID_HANDLE;
	
	FindNextSpec(client);
}

public CheckSpec(client, target)
{
	if ((target < 1 || target > MaxClients) || GetClientTeam(client) != GetClientTeam(target))
	{
		return true;
	}
	
	return false;
}

public Action:Command_SpecMode(client, const String:command[], argc) 
{
	if (client == 0 || IsFakeClient(client) || SpecAny[client])
	{
		return Plugin_Continue;
	}
	
	SetEntPropEnt(client, Prop_Send, "m_iObserverMode", SPECMODE_FIRSTPERSON);
	
	return Plugin_Changed;
}

public Action:Command_SpecNext(client, const String:command[], argc) 
{
	if (client == 0 || IsFakeClient(client) || SpecAny[client])
	{
		return Plugin_Continue;
	}
	
	FindNextSpec(client);
	
	return Plugin_Handled;
}

public Action:Command_SpecPrev(client, const String:command[], argc) 
{
	if (client == 0 || IsFakeClient(client) || SpecAny[client])
	{
		return Plugin_Continue;
	}
	
	FindPrevSpec(client);
	
	return Plugin_Handled;
}

public FindNextSpec(client)
{
	new client_team = GetClientTeam(client);
	
	new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	new bool:found = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && client_team == GetClientTeam(i) && i > target && client != target)
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", i);
			
			found = true;
			
			return;
		}
	}
	
	if(!found)
	{
		new temp = MaxClients + 1;
		new count = 0;
		
		for (new i = MaxClients; i >= 1; i--)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && client_team == GetClientTeam(i))
			{
				count++;
				
				if (IsValidEntity(i) && i < target && client != target)
				{
					if (i < temp)
					{
						temp = i;
					}
				}
			}
		}
		
		if (temp > 0 && temp <= MaxClients)
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", temp);
		}
		
		if (count == 1)
		{
			return;
		}
		
		if (temp == MaxClients+1 || count == 0)
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", temp);
			SetEntPropEnt(client, Prop_Send, "m_iObserverMode", SPECMODE_NONE);
			
			return;
		}
	}
}

public FindPrevSpec(client)
{
	new client_team = GetClientTeam(client);
	new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	new bool:found = false;
	
	for (new i = MaxClients; i >= 1; i--)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && client_team == GetClientTeam(i) && i < target && client != target)
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", i);
			
			found = true;
			return;
		}
	}
	
	if(!found)
	{
		new temp = 0;
		new count = 0;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && client_team == GetClientTeam(i))
			{
				count++;
				
				if (IsValidEntity(i) && i > target && client != target)
				{
					if(i > temp)
					{
						temp = i;
					}
				}
			}
		}
		
		if (temp > 0 && temp <= MaxClients)
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", temp);
		}
		
		if (count == 1)
		{
			return;
		}
		
		if(temp == 0)
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", temp);
			SetEntPropEnt(client, Prop_Send, "m_iObserverMode", SPECMODE_NONE);
			
			return;
		}
	}
}

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}