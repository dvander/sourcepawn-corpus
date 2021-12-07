#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "0.5"

public Plugin:myinfo =
{
	name = "Colour Code Cleanup",
	author = "CmptrWz & TripleThreat",
	description = "Remove Quake/COD style colour codes from names",
	version = VERSION,
	url = "http://www.alliedmods.net"
};

new Handle:cvarAllowedCodes = INVALID_HANDLE;
new g_allowedCodes = 1;
new Float:lastNameCheck[MAXPLAYERS+1];
new Handle:timerHandles[MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar("sm_colorcodecleanup_version", VERSION, "Color Code Cleanup Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarAllowedCodes = CreateConVar("sm_colorcodecleanup_threshold", "1", "Max color codes before strip");
	HookConVarChange(cvarAllowedCodes, AllowedCodesChanged);
	HookEvent("player_changename", PlayerChangeName);
}

public AllowedCodesChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	OnMapStart();
}

public OnMapStart()
{
	// Mainly for late loading
	g_allowedCodes = GetConVarInt(cvarAllowedCodes);
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			CheckName(i);
	}

public OnClientDisconnect(client)
{
	if(timerHandles[client] != INVALID_HANDLE)
	{
		KillTimer(timerHandles[client]);
		timerHandles[client] = INVALID_HANDLE;
	}
	lastNameCheck[client] = 0.0;
}

public OnMapEnd()
{
	// Cleanup
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		lastNameCheck[i] = 0.0;
		timerHandles[i] = INVALID_HANDLE;
	}
}

public OnClientPutInServer(client)
{
	if(client == 0)
		return;
	CheckName(client, true); // We claim callback at this point.
}

public PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:newName[MAX_NAME_LENGTH];
	if(client == 0)
		return;
	GetEventString(event, "newname", newName, MAX_NAME_LENGTH);
	CheckName(client, false, newName); // No claiming callback here.
}
public Action:CheckNameTimer(Handle:timer, any:data)
{
	if(IsClientInGame(data))
		CheckName(data, true);
	return Plugin_Stop;
}

CheckName(client, bool:isTimerCall = false, String:eventName[] = "")
{
	new Float:gameTime = GetGameTime();
	if(isTimerCall)
	{
		timerHandles[client] = INVALID_HANDLE;
	}
	else if (gameTime < lastNameCheck[client] + 10 || timerHandles[client] != INVALID_HANDLE)
	{
		if(timerHandles[client] == INVALID_HANDLE)
			timerHandles[client] = CreateTimer(10.0, CheckNameTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	lastNameCheck[client] = gameTime;
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:newName[MAX_NAME_LENGTH];
	new j = 0;
	new foundCodes = 0;
	if(eventName[0] != 0) // Event passed name?
		strcopy(clientName, MAX_NAME_LENGTH, eventName);
	else if(!GetClientName(client, clientName, MAX_NAME_LENGTH))
		return;
	new nameLen = strlen(clientName);
	new curchar, nextchar;
	for(new i = 0; i < nameLen; i++)
	{
		curchar = clientName[i];
		nextchar = clientName[i+1];
		if(curchar == '^' && nextchar >= '0' && nextchar <= '9')
		{
			foundCodes++;
			i++;
		}
		else
		{
			newName[j++] = curchar;
		}
	}
	newName[j] = 0;
	if(foundCodes > g_allowedCodes)
	{
		if(isTimerCall) // If we change too quickly (at least in TF2) we run into issues. Only change on a timer callback.
		{
			if(newName[0] == 0) // Null, like empty name?
				strcopy(newName, MAX_NAME_LENGTH, "Unnamed");
			ShowActivityEx(client, "[NameChange] ", "%s was stripped of colour codes to leave %s", clientName, newName);
			CS_SetClientName(client, newName);
		}
		else // Otherwise, make a timer to call back with
		{
			timerHandles[client] = CreateTimer(6.0, CheckNameTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}


//Thanks GoD-Tony https://forums.alliedmods.net/showthread.php?t=161025
stock CS_SetClientName(client, const String:name[], bool:silent=false)
{
	decl String:oldname[MAX_NAME_LENGTH];
	GetClientName(client, oldname, sizeof(oldname));
	
	SetClientInfo(client, "name", name);
	SetEntPropString(client, Prop_Data, "m_szNetname", name);
	
	new Handle:event = CreateEvent("player_changename");
	
	if (event != INVALID_HANDLE)
	{
		SetEventInt(event, "userid", GetClientUserId(client));
		SetEventString(event, "oldname", oldname);
		SetEventString(event, "newname", name);
		FireEvent(event);
	}
	
	if (silent)
		return;
	
	new Handle:msg = StartMessageAll("SayText2");
	
	if (msg != INVALID_HANDLE)
	{
		BfWriteByte(msg, client);
		BfWriteByte(msg, true);
		BfWriteString(msg, "Cstrike_Name_Change");
		BfWriteString(msg, oldname);
		BfWriteString(msg, name);
		EndMessage();
	}
}