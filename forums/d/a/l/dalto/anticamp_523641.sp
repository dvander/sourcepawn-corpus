/*
anticamp.sp

Description:
	Stops players from camping

Versions:
	0.8
		* Initial Release
		
	0.9
		* Added an annoying sound to accompany the beacon
		* Added a cvar to allow camping after the bomb has been planted
		* Added a cvar to allow camping if health is lower than sm_anticamp_low_health_level
		* Added a cvar to control the radius that camping is checked
		* Added a cvar to allow the admin to define the number of total polls
		* Added a cvar to allow an admin to define the number of polls needed
		* Added a cvar to allow the admin to define the polling interval
		* Added a cvar to allow the camping beacon to be forgiven if the player moves
		* Added a cvar to control the sound to play
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.9"

#define NON_CAMPER_DELAY 5.0
#define BEACON_DELAY 1.2
#define MAX_FILE_LEN 80

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Anti-camp",
	author = "dalto",
	description = "Detects camping players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Float:g_lastPos[MAXPLAYERS + 1][3];
new Handle:g_hTimerList[MAXPLAYERS + 1];
new Handle:g_hBeaconList[MAXPLAYERS + 1];
new g_timerCount[MAXPLAYERS + 1];
new g_caughtCount[MAXPLAYERS + 1];
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarBombPlanted = INVALID_HANDLE;
new Handle:g_CvarLowHealth = INVALID_HANDLE;
new Handle:g_CvarRadius = INVALID_HANDLE;
new Handle:g_CvarPollCount = INVALID_HANDLE;
new Handle:g_CvarPollsNeeded = INVALID_HANDLE;
new Handle:g_CvarPollTime = INVALID_HANDLE;
new Handle:g_CvarForgive = INVALID_HANDLE;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];
new g_beamSprite;
new g_haloSprite;

public OnPluginStart()
{
	CreateConVar("sm_anticamp_version", PLUGIN_VERSION, "Anti-camp Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnable = CreateConVar("sm_anticamp_enable", "1", "Set to 0 to disable anti-camp");
	g_CvarBombPlanted = CreateConVar("sm_anticamp_bomb_plant", "1", "Set to 0 if you want the anti-camp function enabled even after the bomb is planted");
	g_CvarLowHealth = CreateConVar("sm_anticamp_low_health_level", "25", "Set to the health level below which camping is OK");
	g_CvarRadius = CreateConVar("sm_anticamp_radius", "250", "The radius to check for camping");
	g_CvarPollCount = CreateConVar("sm_anticamp_poll_count", "20", "the amount of times a suspected camper is checked for");
	g_CvarPollsNeeded = CreateConVar("sm_anticamp_polls_needed", "10", "The number of times he is found within the radius to be a camper");
	g_CvarPollTime = CreateConVar("sm_anticamp_poll_time", "0.5", "The polling interval");
	g_CvarForgive = CreateConVar("sm_anticamp_forgive", "1", "This determines if players should be beacon should go away if they stop camping");
	g_CvarSoundName = CreateConVar("sm_anticamp_sound", "ambient/misc/brass_bell_c.wav", "The sound to play for the beacon");
	
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	decl String:buffer[MAX_FILE_LEN];
	GetConVarString(g_CvarSoundName, g_soundName, sizeof(g_soundName));
	if(strcmp(g_soundName, ""))
	{
		PrecacheSound(g_soundName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}
	g_beamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public Action:EventBombPlanted(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarBombPlanted))
	{
		return Plugin_Continue;
	}
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsValidHandle(g_hTimerList[i]))
		{
			CloseHandle(g_hTimerList[i]);
		}
		if(IsValidHandle(g_hBeaconList[i]))
		{
			CloseHandle(g_hBeaconList[i]);
		}
	}
	
	return Plugin_Continue;
}
public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check to see if there is an outstanding handle from last round
	if(IsValidHandle(g_hTimerList[client]))
	{
		CloseHandle(g_hTimerList[client]);
	}

	if(IsValidHandle(g_hBeaconList[client]))
	{
		CloseHandle(g_hBeaconList[client]);
	}

	if(!GetConVarBool(g_CvarEnable))
	{
		return Plugin_Continue;
	}

	// get the players position and start the timing cycle	
	GetClientAbsOrigin(client, g_lastPos[client]);
	g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client);
	
	return Plugin_Continue;
}

public Action:CheckCamperTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected
	if(!IsClientConnected(client))
	{
		return Plugin_Handled;
	}

	new Float:currentPos[3];	
	GetClientAbsOrigin(client, currentPos);
	if(IsCamping(client, g_lastPos[client], currentPos))
	{
		// it looks like this person may be camping, time to get serious
		g_caughtCount[client] = 0;
		g_timerCount[client] = 1;
		g_hTimerList[client] = CreateTimer(GetConVarFloat(g_CvarPollTime), CaughtCampingTimer, client);
	}
	else {
		g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client);
	}
	g_lastPos[client] = currentPos;
	return Plugin_Handled;
}

public bool:IsCamping(client, Float:vec1[3], Float:vec2[3])
{
	if(GetVectorDistance(vec1, vec2) < GetConVarInt(g_CvarRadius) && GetConVarInt(g_CvarLowHealth) <= GetClientHealth(client))
	{
		return true;
	}
	return false;
}

public Action:CaughtCampingTimer(Handle:timer, any:client)
{
	if(!IsClientConnected(client))
	{
		return Plugin_Handled;
	}

	new Float:currentPos[3];	
	GetClientAbsOrigin(client, currentPos);
	if(g_timerCount[client] < GetConVarInt(g_CvarPollCount))
	{
		if(IsPlayerAlive(client) && IsCamping(client, g_lastPos[client], currentPos))
		{
			g_caughtCount[client]++;
		}
		g_timerCount[client]++;
		g_hTimerList[client] = CreateTimer(1.0, CaughtCampingTimer, client);
	} else {
		if(g_caughtCount[client] >= GetConVarInt(g_CvarPollsNeeded) && IsPlayerAlive(client) && IsCamping(client, g_lastPos[client], currentPos))
		{
			decl String:name[30];
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("Anti-camp has caught %s camping!!!", name);
			PrintCenterText(client, "Anti-camp is activating beacon");
			g_hBeaconList[client] = CreateTimer(BEACON_DELAY, BeaconTimer, client);
			if(GetConVarBool(g_CvarForgive))
			{
				g_caughtCount[client] = 0;
				g_timerCount[client] = 1;
				g_hTimerList[client] = CreateTimer(GetConVarFloat(g_CvarPollTime), CaughtCampingTimer, client);
			}
				
		} else {
			if(IsValidHandle(g_hBeaconList[client]))
			{
				CloseHandle(g_hBeaconList[client]);
			}
			g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client);
			g_lastPos[client] = currentPos;
		}
	}
	
	return Plugin_Handled;
}

public Action:BeaconTimer(Handle:timer, any:client)
{
	new color[] = {150, 0, 0, 255};
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	// create a beam effect and the anathor one immediately after
	BeamRing(client, color);
	CreateTimer(0.2, BeaconTimer2, client);
	if(strcmp(g_soundName, ""))
	{
		new Float:vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_soundName, vec, SOUND_FROM_WORLD, SNDLEVEL_ROCKET);
	}
	g_hBeaconList[client] = CreateTimer(BEACON_DELAY, BeaconTimer, client);
	return Plugin_Handled;
}

public Action:BeaconTimer2(Handle:timer, any:client)
{
	new color[] = {255, 0, 0, 255};
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	BeamRing(client, color);
	
	return Plugin_Handled;
}

public BeamRing(client, color[4])
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 5;

	TE_Start("BeamRingPoint");
	TE_WriteVector("m_vecCenter", vec);
	TE_WriteFloat("m_flStartRadius", 20.0);
	TE_WriteFloat("m_flEndRadius", 400.0);
	TE_WriteNum("m_nModelIndex", g_beamSprite);
	TE_WriteNum("m_nHaloIndex", g_haloSprite);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 0);
	TE_WriteFloat("m_fLife", 1.0);
	TE_WriteFloat("m_fWidth", 3.0);
	TE_WriteFloat("m_fEndWidth", 3.0);
	TE_WriteFloat("m_fAmplitude", 0.0);
	TE_WriteNum("r", color[0]);
	TE_WriteNum("g", color[1]);
	TE_WriteNum("b", color[2]);
	TE_WriteNum("a", color[3]);
	TE_WriteNum("m_nSpeed", 50);
	TE_WriteNum("m_nFlags", 0);
	TE_WriteNum("m_nFadeLength", 0);
	TE_SendToAll();
}