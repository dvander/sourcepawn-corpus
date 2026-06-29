#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include  <tf2_stocks>

#tryinclude <jenkins>

#define VERSION "1.5a"

#if !defined BUILD
#define BUILD "0"
#endif

#define JOIN_MESSAGE "Player %N has joined the game"
#define QUIT_MESSAGE "Player %N left the game (Disconnected by user.)"
#define STEALTHTEAM 0

//Cvars and etc
new bool:g_bIsInvisible[MAXPLAYERS+1];
new g_iSpectateTarget[MAXPLAYERS+1];
new Float:g_fLastSpecChange[MAXPLAYERS+1];
new g_iOldTeam[MAXPLAYERS+1];
new Handle:g_hHostname;

public Plugin:myinfo = 
{
	name = "Admin Stealth",
	author = "necavi and Naydef(fixes)",
	description = "Allows administrators to become nearly completely invisible.",
	version = VERSION,
	url = "http://necavi.org/"
}

public OnPluginStart()
{
	CreateConVar("sm_adminstealth_version", VERSION, "AdminStealth version cvar", FCVAR_NOTIFY|FCVAR_SPONLY);
	CreateConVar("sm_adminstealth_build", BUILD, "Build number", FCVAR_NOTIFY|FCVAR_SPONLY);
	RegAdminCmd("sm_stealth", Command_Stealth, ADMFLAG_CUSTOM3, "Allows an administrator to toggle complete invisibility on themselves.");
	g_hHostname = FindConVar("hostname");
	AddCommandListener(Command_JoinTeam, "jointeam"); 
	AddCommandListener(Command_Status, "status");
	AddNormalSoundHook(Hook_Sound);
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKHook(i, SDKHook_SetTransmit, Hook_Transmit);
		}
	}
	new TF2PManager=FindEntityByClassname(-1, "tf_player_manager");
	if(IsValidEntity(TF2PManager)) // Why SDKHook doesn't have a native to test if the entity is already hooked?
	{
		SDKHook(TF2PManager, SDKHook_ThinkPost, Hook_ThinkPost);
	}	
}

public APLRes:AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(!IsTF2())
	{
		strcopy(error, err_max, "This version of the plugin is currently only for Team Fortress 2! Remove the plugin!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_SetTransmit, Hook_Transmit);
	g_bIsInvisible[client]=false;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_Transmit);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "tf_player_manager", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_SpawnPost);
	}
}

public Hook_SpawnPost(entity)
{
	if(IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_ThinkPost, Hook_ThinkPost);
	}
}

public Hook_ThinkPost(entity)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			SetEntProp(entity, Prop_Send, "m_bConnected", 0, _, i);
		}
	}
}

// I don't know what is this for!
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(g_bIsInvisible[client] && buttons & IN_JUMP && GetGameTime() > g_fLastSpecChange[client] + 1.0)
	{
		new current_target = GetClientOfUserId(g_iSpectateTarget[client]);
		new new_target;
		for(new i = current_target + 1; i <= MaxClients + current_target; i++)
		{
			new_target = (i >= MaxClients) ? i % MaxClients : i;
			PrintToChat(client, "current_target: %d new_target = %d", current_target, new_target);
			if(new_target != client && ValidPlayer(new_target) && IsPlayerAlive(new_target))
			{
				g_iSpectateTarget[client] = GetClientUserId(new_target);
				new Float:target_origin[3];
				new Float:target_angles[3];
				GetClientAbsOrigin(new_target, target_origin);
				GetClientEyeAngles(new_target, target_angles);
				TeleportEntity(client, target_origin, target_angles, NULL_VECTOR);
				g_fLastSpecChange[client] = GetGameTime();
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_JoinTeam(client, const String:command[], args)  
{ 
	if(g_bIsInvisible[client])
	{
		PrintToChat(client, "[SM] Can not join team when in stealth mode!");
		return Plugin_Handled; 
	}
	else 
	{ 
		return Plugin_Continue; 
	} 
}

public Action:Command_Status(client, const String:command[], args)
{
	if(CheckCommandAccess(client, "sm_stealth", 0))
	{
		return Plugin_Continue;
	}
	new String:buffer[128];
	GetConVarString(g_hHostname, buffer, sizeof(buffer));
	PrintToConsole(client,"hostname: %s",buffer);
	PrintToConsole(client,"version : 1909615/24 1909615 secure");
	GetCurrentMap(buffer,sizeof(buffer));
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	PrintToConsole(client,"map     : %s at: %.0f x, %.0f y, %.0f z", buffer, vec[0], vec[1], vec[2]);
	PrintToConsole(client,"players : %d (%d max)", GetClientCount() - GetInvisCount(), MaxClients);
	PrintToConsole(client,"# userid name                uniqueid            connected ping loss state");
	new String:name[MAX_NAME_LENGTH];
	new String:steamID[24];
	new String:time[9];
	for(new i; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if(!g_bIsInvisible[i])
			{
				Format(name,sizeof(name),"\"%N\"",i);
				GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));
				if(!IsFakeClient(i))
				{
					FormatShortTime(RoundToFloor(GetClientTime(i)), time, sizeof(time));
					PrintToConsole(client,"# %6d %-19s %19s %9s %4d %4d active", GetClientUserId(i), 
					name, steamID, time, RoundToFloor(GetClientAvgLatency(i,NetFlow_Both) * 1000.0), 
					RoundToFloor(GetClientAvgLoss(i,NetFlow_Both) * 100.0));
				} 
				else 
				{
					PrintToConsole(client,"# %6d %-19s %19s                     active", GetClientUserId(i), name, steamID);
				}
			}
		}
	}
	return Plugin_Stop;
}

public Action:Command_Stealth(client, args)
{
	ToggleInvis(client);
	LogAction(client, -1, "%N has toggled stealth mode.", client);
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

InvisOff(client, announce=true)
{
	g_bIsInvisible[client] = false;
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, g_iOldTeam[client]);
	SetEntityMoveType(client, MOVETYPE_ISOMETRIC); // Let's test this
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	if(announce)
	{
		PrintToChatAll(JOIN_MESSAGE, client);
	}
	PrintToChat(client, "You are no longer in stealth mode.");

}

InvisOn(client, announce=true)
{
	TF2_RemoveAllWeapons(client);
	g_bIsInvisible[client]=true;
	g_iOldTeam[client]=GetEntProp(client, Prop_Send, "m_iTeamNum");
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, STEALTHTEAM);
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	SetEntProp(client, Prop_Data, "m_takedamage", 0);		
	if(announce)
	{
		PrintToChatAll(QUIT_MESSAGE, client);
	}
	PrintToChat(client, "You are now in stealth mode.");

}

public Action:Hook_Transmit(entity, client)
{
	if(ValidPlayer(entity) && g_bIsInvisible[entity] && entity != client)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
	
}

public Action:Hook_Sound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(ValidPlayer(entity) && g_bIsInvisible[entity])
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

bool:ValidPlayer(client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
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

bool:IsTF2()
{
	return (GetEngineVersion()==Engine_TF2) ?  true : false;
}