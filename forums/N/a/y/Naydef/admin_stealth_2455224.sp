#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.4e1 css:go"
#define PLAYER_MANAGER "cs_player_manager"


#define STEALTHTEAM 1
#define JOIN_MESSAGE "Player %N has joined the game"
#define QUIT_MESSAGE "Player %N left the game (Disconnected by user.)"

public Plugin:myinfo = 
{
	name = "Admin Stealth",
	author = "necavi and Naydef (new developer)",
	description = "Allows administrators to become nearly completely invisible.",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net/"
}

new bool:g_bIsInvisible[MAXPLAYERS + 1] = {false, ...};
new g_iOldTeam[MAXPLAYERS+1];
new Float:nextPing[MAXPLAYERS+1];
new Handle:g_hHostname;
new EngineVersion:EngineGame;
new serverVer;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(!IsCSSGen())
	{
		strcopy(error, err_max, "This version of the plugin is currently only for Counter Strike: Source and CS:GO! Remove the plugin!");
		return APLRes_Failure;
	}
	EngineGame=GetEngineVersion();
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_adminstealth_version", PLUGIN_VERSION, "Admin-Stealth version cvar", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_stealth", Command_Stealth, ADMFLAG_CUSTOM3, "Allows an administrator to toggle complete invisibility on themselves.");
	g_hHostname = FindConVar("hostname");
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_JoinTeam, "autoteam");
	AddCommandListener(Command_Status, "status");
	AddCommandListener(Command_Ping, "ping");
	serverVer=GetSteamINFNum();
	HookEventEx("player_disconnect", Event_HandlePlayerDisconnect, EventHookMode_Pre);
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKHook(i, SDKHook_SetTransmit, Hook_Transmit);
		}
	}
	new PlayerManager=FindEntityByClassname(-1, PLAYER_MANAGER);
	if(IsValidEntity(PlayerManager)) // Why SDKHook doesn't have a native to test if the entity is already hooked?
	{
		SDKHook(PlayerManager, SDKHook_ThinkPost, Hook_PlayerManagetThinkPost);
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, Event_WeaponCanUse);
	SDKHook(client, SDKHook_SetTransmit, Hook_Transmit);
}


public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, Event_WeaponCanUse);
	SDKUnhook(client, SDKHook_SetTransmit, Hook_Transmit);
	g_bIsInvisible[client]=false;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, PLAYER_MANAGER, false))
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_SpawnPost);
	}
}

public Action:Hook_SpawnPost(entity)
{
	if(IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_ThinkPost, Hook_PlayerManagetThinkPost);
	}
	return Plugin_Continue;
}

public Hook_PlayerManagetThinkPost(entity)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			SetEntProp(entity, Prop_Send, "m_bConnected", false, _, i);
		}
	}
}

public Action:Command_JoinTeam(client, const String:command[], args)  
{ 
	if(g_bIsInvisible[client])
	{
		if(EngineGame==Engine_CSGO)
		{
			PrintToChat(client, " \x01\x0B\x04[STEALTH]\x01 Can not join team when in invisible mode!");
		}
		else
		{
			PrintToChat(client, "\x03[STEALTH]\x01 Can not join team when in invisible mode!");
		}
		return Plugin_Handled; 
	}
	else 
	{ 
		return Plugin_Continue; 
	} 
}

public Action:Event_HandlePlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(ValidPlayer(client) && g_bIsInvisible[client]) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_WeaponCanUse(client, weapon)
{
	if(g_bIsInvisible[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Status(client, const String:command[], args)
{
	if(CheckCommandAccess(client, "sm_stealth", 0))
	{
		return Plugin_Continue;
	}
	new String:buffer[64];
	GetConVarString(g_hHostname, buffer, sizeof(buffer));
	PrintToConsole(client, "hostname: %s", buffer);
	PrintToConsole(client, "version : %i/24 %i secure", serverVer, serverVer);
	GetCurrentMap(buffer, sizeof(buffer));
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	if(EngineGame!=Engine_CSGO)
	{
		PrintToConsole(client,"map     : %s at: %.0f x, %.0f y, %.0f z", buffer, vec[0], vec[1], vec[2]);
	}
	else
	{
		PrintToConsole(client,"map     : %s", buffer);
	}
	PrintToConsole(client,"players : %d (%d max)", GetClientCount() - GetInvisCount(), MaxClients);
	PrintToConsole(client,"# userid name                uniqueid            connected ping loss state");
	new String:name[MAX_NAME_LENGTH];
	new String:steamID[21];
	new String:time[10];
	for(new i; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if(!g_bIsInvisible[i])
			{
				Format(name, sizeof(name), "\"%N\"", i);
				GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));
				if(!IsFakeClient(i))
				{
					FormatShortTime(RoundToFloor(GetClientTime(i)), time,sizeof(time));
					PrintToConsole(client,"# %6d %-19s %19s %9s %4d %4d active", GetClientUserId(i), 
					name, steamID, time, RoundToFloor(GetClientAvgLatency(i,NetFlow_Both) * 1000.0), 
					RoundToFloor(GetClientAvgLoss(i, NetFlow_Both) * 100.0));
				} 
				else 
				{
					PrintToConsole(client, "# %6d %-19s %19s                     active", GetClientUserId(i), name, steamID);
				}
			}
		}
	}
	if(EngineGame==Engine_CSGO)
	{
		PrintToConsole(client, "#end");
	}
	return Plugin_Stop;
}

public Action:Command_Ping(client, const String:command[], args)
{
	if(!ValidPlayer(client) || CheckCommandAccess(client, "sm_stealth", 0)) // Console will now work!!!
	{
		return Plugin_Continue;
	}
	if(nextPing[client]<=GetGameTime())
	{
		PrintToConsole(client, "Client ping times:");
		for(new i=1; i<=MaxClients; i++)
		{
			if(ValidPlayer(i) && !g_bIsInvisible[i] && !IsFakeClient(i))
			{
				PrintToConsole(client, " %i ms : %N", RoundToFloor(GetClientAvgLatency(i, NetFlow_Both) * 1000.0), i);
			}
		}
		nextPing[client]=GetGameTime()+0.2;
	}
	return Plugin_Handled;
}

public Action:Hook_Transmit(entity, client)
{
	if(ValidPlayer(entity) && g_bIsInvisible[entity] && entity != client)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
	
}

public Action:Command_Stealth(client, args)
{
	ToggleInvis(client);
	return Plugin_Handled;
}

ToggleInvis(client)
{
	if(g_bIsInvisible[client]) 
	{
		InvisOff(client);
	} 
	else 
	{
		InvisOn(client);
	}
}

InvisOff(client)
{
	g_bIsInvisible[client] = false;
	ChangeClientTeam(client, g_iOldTeam[client]);
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	SetEntityMoveType(client, MOVETYPE_NONE);	
	PrintToChatAll(JOIN_MESSAGE, client);
	if(EngineGame==Engine_CSGO)
	{
		PrintToChat(client, " \x01\x0B\x04[STEALTH]\x01 You are no longer in stealth mode!");
	}
	else
	{
		PrintToChat(client, "\x03[STEALTH]\x01  You are no longer in stealth mode!");
	}

}

InvisOn(client)
{
	g_bIsInvisible[client] = true;
	g_iOldTeam[client] = GetEntProp(client, Prop_Send, "m_iTeamNum");
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, STEALTHTEAM);
	SetEntProp(client, Prop_Data, "m_takedamage",0);	
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	RemoveAllWeapons(client);
	PrintToChatAll(QUIT_MESSAGE, client);
	if(EngineGame==Engine_CSGO)
	{
		PrintToChat(client, " \x01\x0B\x04[STEALTH]\x01 You are now in stealth mode!");
	}
	else
	{
		PrintToChat(client, "\x03[STEALTH]\x01 You are now in stealth mode!");
	}

}

RemoveAllWeapons(client)
{
	new weaponIndex;
	for (new i = 0; i <= 5; i++)
	{
		while((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
		}
	}
}

bool:ValidPlayer(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

FormatShortTime(time, String:outTime[], size)
{
	new temp;
	temp = time % 60;
	Format(outTime, size,"%02d",temp);
	temp = (time % 3600) / 60;
	Format(outTime, size,"%02d:%s", temp, outTime);
	temp = (time % 86400) / 3600;
	if(temp > 0)
	{
		Format(outTime, size, "%d%:s", temp, outTime);

	}
}

GetInvisCount()
{
	new count = 0;
	for(new i; i <= MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			count++;
		}
	}
	return count;
}

//To-do: Use the new fake event function in Sourcemod 1.8
/*
bool:PrintConDisMessg(client, bool:connect)
{
	if(!ValidPlayer(client))
	{
		return false;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	if(connect)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(!ValidPlayer(i))
			{
				continue;
			}
			new Handle:bf = StartMessageOne("TextMsg", i, USERMSG_RELIABLE); 
			if(bf!=INVALID_HANDLE)
			{
				BfWriteByte(bf, 3); 
				BfWriteString(bf, "#game_player_joined_game"); 
				BfWriteString(bf, name);
				EndMessage();
			}
		}
	}
	else
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(!ValidPlayer(i))
			{
				continue;
			}
			new Handle:bf = StartMessageOne("TextMsg", i, USERMSG_RELIABLE); 
			if(bf!=INVALID_HANDLE)
			{
				BfWriteByte(bf, 3);
				BfWriteString(bf, "#game_player_left_game"); 
				BfWriteString(bf, name);
				BfWriteString(bf, QUIT_REASON);
				EndMessage(); 
			}
		}
	}
	return true;
}
*/

bool:IsCSSGen()
{
	return (GetEngineVersion()==Engine_CSS || GetEngineVersion()==Engine_CSGO) ?  true : false;
}

//Credit: pilger
stock GetSteamINFNum(String:search[]="ServerVersion")
{
	new String:file[16]="./steam.inf", String:inf_buffer[64]; //It's not worth using decl
	new Handle:file_h=OpenFile(file, "r");
	
	do
	{
		if(!ReadFileLine(file_h, inf_buffer, sizeof(inf_buffer)))
		{
			return -1;
		}
		TrimString(inf_buffer);
	}
	while(StrContains(inf_buffer, search, false) < 0);
	CloseHandle(file_h);

	return StringToInt(inf_buffer[strlen(search)+1]);
}