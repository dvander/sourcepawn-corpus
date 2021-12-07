/**
 * Anticamp - SourceMod plugin to detect camping players
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define YELLOW       "\x01"
#define TEAMCOLOR	   "\x03"
#define GREEN				 "\x04"

#define PLUGIN_VERSION "1.0.9.1a"

#define NON_CAMPER_DELAY 4.0
#define BEACON_DELAY 5.0

#define CS_TEAM_NONE		0
#define CS_TEAM_T 			2
#define CS_TEAM_CT			3
#define CS_TEAM_SPECTATOR	1

#define MAX_WEAPONS	29

new String:ConfigFile[PLATFORM_MAX_PATH];

// Plugin definitions
public Plugin:myinfo =
{
	name = "Anticamp Source",
	author = "Blade",
	description = "Detects camping players",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new String:g_sWeaponList[MAX_WEAPONS][] = 
{
	"glock","usp","p228","deagle","elite","fiveseven","m3",
	"xm1014","galil","ak47","scout","sg552","awp","g3sg1",
	"famas","m4a1","aug","sg550","mac10","tmp","mp5navy",
	"ump45","p90","m249","flashbang","hegrenade","smokegrenade","c4","knife"
};

// Offsets
new g_iOffsLastPlaceName = -1;
new g_iOffsEyeAngle = -1;

// Stores camp time for each weapon from config file
new g_iWeaponCampTime[MAX_WEAPONS];

// Last position of the clients
new Float:g_fLastPos[MAXPLAYERS + 1][3];
// Eye angle of clients for afk check
new Float:g_fSpawnEyeAng[MAXPLAYERS + 1][3];

new g_iCampCount[MAXPLAYERS + 1];

new bool:g_bIsCtMap = false;
new bool:g_bIsTMap = false;
new bool:g_bWeaponCfg = false;
new bool:g_bIsAfk[MAXPLAYERS + 1];

// Stores client timers
new Handle:g_hCampTimer[MAXPLAYERS + 1];
new Handle:g_hBeaconTimer[MAXPLAYERS + 1];

// Cvar handles
new Handle:g_CvarBeacon = INVALID_HANDLE;
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarSlap = INVALID_HANDLE;
new Handle:g_CvarLowHealth = INVALID_HANDLE;
new Handle:g_CvarRadius = INVALID_HANDLE;
new Handle:g_CvarCampTime = INVALID_HANDLE;
new Handle:g_CvarAllowTCamp = INVALID_HANDLE;
new Handle:g_CvarAllowCtCamp = INVALID_HANDLE;

// Stores model index after precaching
new g_beamSprite;
new g_haloSprite;

public OnPluginStart()
{
	CreateConVar("anticamp_version", PLUGIN_VERSION, "anticamp_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_CvarEnable 			= CreateConVar("sm_anticamp_enable", "1", "Set to 0 to disable anticamp", 0, true, 0.0, true, 1.0);
	g_CvarBeacon 			= CreateConVar("sm_anticamp_beacon", "1", "Set to 0 to disable beacons", 0, true, 0.0, true, 1.0);
	g_CvarSlap 				= CreateConVar("sm_anticamp_slap", "5", "Amount of health decrease during camping every 2 sec.", 0, true, 0.0, true, 50.0);
	g_CvarLowHealth 	= CreateConVar("sm_anticamp_health", "15", "Set to the health level below where camping is allowed", 0, true, 0.0, true, 100.0);
	g_CvarRadius 			= CreateConVar("sm_anticamp_radius", "200", "The radius to check for camping", 0, true, 50.0, true, 500.0);
	g_CvarCampTime 		= CreateConVar("sm_anticamp_camptime", "30", "The amount of times a suspected camper is checked for", 0, true, 5.0, true, 60.0);
	g_CvarAllowTCamp 	= CreateConVar("sm_anticamp_t_camp", "1", "Set to 1 to allow camping for t on cs maps. Set to 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCamp = CreateConVar("sm_anticamp_ct_camp", "1", "Set to 1 to allow camping for ct on de maps. Set to 0 to disable", 0, true, 0.0, true, 1.0);

	// Hook events
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_PostNoCopy);
	HookEvent("bomb_dropped", EventBombDropped, EventHookMode_PostNoCopy);
	HookEvent("bomb_pickup", 	EventBombPickup, EventHookMode_PostNoCopy);

	// Find offsets
	g_iOffsEyeAngle = FindSendPropOffs("CCSPlayer","m_angEyeAngles[0]");
	g_iOffsLastPlaceName = FindSendPropOffs("CBasePlayer", "m_szLastPlaceName");

	LoadTranslations("anticamp.phrases");

	// Auto-generate config file
	AutoExecConfig(true,"anticamp", "sourcemod");
}

public OnMapStart()
{
	// Beacon sound
	PrecacheSound("buttons/button17.wav",true);

	// Slap sounds
	PrecacheSound("player/damage1.wav",true);
	PrecacheSound("player/damage2.wav",true);
	PrecacheSound("player/damage3.wav",true);

	g_beamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt");

	// Check map class
	g_bIsCtMap = g_bIsTMap = false;
	if(FindEntityByClassname(-1, "func_hostage_rescue") != -1)
		g_bIsCtMap = true;
	else if(FindEntityByClassname(-1, "func_bomb_target") != -1)
		g_bIsTMap = true;

	g_bWeaponCfg = false;
	
	ParseConfig();
}

ParseConfig()
{
	BuildPath(Path_SM,ConfigFile,sizeof(ConfigFile),"configs/anticamp.txt");
	if(!FileExists(ConfigFile)) {
		LogMessage("anticamp.txt not parsed...file doesn't exist! Using sm_anticamp_camptime");
	}else{
		new Handle:filehandle = OpenFile(ConfigFile, "r");

		decl String:buffer[32];

		while(!IsEndOfFile(filehandle))
		{
			ReadFileLine(filehandle, buffer, sizeof(buffer));
			TrimString(buffer);

			if(buffer[0] == '/' || buffer[0] == '\0') continue;

			for(new i=0;i<MAX_WEAPONS;i++)
			{
				if(StrContains(buffer, g_sWeaponList[i], false) != -1)
				{
					ReplaceString(buffer, sizeof(buffer), g_sWeaponList[i], "");
					ReplaceString(buffer, sizeof(buffer), " ", "");

					if(StringToInt(buffer))
					{
						g_bWeaponCfg = true;
						g_iWeaponCampTime[i] = StringToInt(buffer);
					}
					else
					{
						g_iWeaponCampTime[i] = 0;
					}
				}
			}
		}
		CloseHandle(filehandle);
	}
}

public Action:EventBombPickup(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarAllowCtCamp))
		return Plugin_Continue;

	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && g_hCampTimer[i] != INVALID_HANDLE)
			ResetTimer(i);
	}

	return Plugin_Continue;
}

public Action:EventBombDropped(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarAllowCtCamp))
		return Plugin_Continue;

	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && g_hCampTimer[i] == INVALID_HANDLE)
		{
			GetClientAbsOrigin(i, g_fLastPos[i]);
			g_hCampTimer[i] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, i, TIMER_REPEAT);
		}
	}

	return Plugin_Continue;
}

public Action:EventBombPlanted(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarAllowCtCamp))
		return Plugin_Continue;

	new teamindex;

	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			teamindex = GetClientTeam(i);
			if(teamindex == CS_TEAM_T)
			{
				ResetTimer(i);
			}
			else if(teamindex == CS_TEAM_CT && g_hCampTimer[i] == INVALID_HANDLE)
			{
				GetClientAbsOrigin(i, g_fLastPos[i]);
				g_hCampTimer[i] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, i, TIMER_REPEAT);
			}
		}
	}
	return Plugin_Handled;
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
  // Return if anticamp is disabled
	if(!GetConVarBool(g_CvarEnable))
	{
		return Plugin_Continue;
	}

	// Get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Get the client team
	new clientteam = GetClientTeam(client);

	// Return if new client
	if(clientteam == CS_TEAM_NONE)
	{
		return Plugin_Continue;
	}

	// Reset caught timer
	g_iCampCount[client] = 0;

	// Reset player eye angle
	g_fSpawnEyeAng[client][1] = 0.0;

	// Check if there is an outstanding handle from last round
	ResetTimer(client);

	// Allow camping for t on cs maps
	if(g_bIsCtMap && clientteam == CS_TEAM_T && GetConVarBool(g_CvarAllowTCamp))
	{
		return Plugin_Continue;
	}

	// Allow camping for ct on de maps
	if(g_bIsTMap && clientteam == CS_TEAM_CT && GetConVarBool(g_CvarAllowCtCamp))
	{
		return Plugin_Continue;
	}

	// Get the players position and start the timing cycle
	GetClientAbsOrigin(client, g_fLastPos[client]);
	g_hCampTimer[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);

	return Plugin_Continue;
}

GetWeaponCampTime(client)
{
	if(!g_bWeaponCfg) return GetConVarInt(g_CvarCampTime);

	// Get weapon name
	decl String:weapon[20];
	GetClientWeapon(client,weapon,20);
	ReplaceString(weapon, 20, "weapon_", "");

	for(new i=0;i<MAX_WEAPONS;i++)
	{
		if(StrEqual(g_sWeaponList[i], weapon, false) && g_iWeaponCampTime[i])
			return g_iWeaponCampTime[i];
	}

	return	GetConVarInt(g_CvarCampTime);
}

bool:IsCamping(client)
{
	new Float:CurrentPos[3];
	GetClientAbsOrigin(client, CurrentPos);

	if(GetVectorDistance(g_fLastPos[client], CurrentPos) < GetConVarInt(g_CvarRadius) && GetClientHealth(client) > GetConVarInt(g_CvarLowHealth))
	{
		if(!g_bIsAfk[client])
			return true;
	}
	else if(g_bIsAfk[client]) g_bIsAfk[client] = false;

	g_fLastPos[client] = CurrentPos;
	return false;
}

public Action:CheckCamperTimer(Handle:timer, any:client)
{
	// Check to make sure the client is still connected
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// Store client's eye angle for afk check
	if(g_fSpawnEyeAng[client][1] == 0.0)
	{
		g_bIsAfk[client] = true;
		GetEntDataVector(client, g_iOffsEyeAngle, g_fSpawnEyeAng[client]);
	}
	else
	{
		new Float:ClientEyeAng[3];
		GetEntDataVector(client, g_iOffsEyeAngle, ClientEyeAng);

		if(FloatAbs(g_fSpawnEyeAng[client][1] - ClientEyeAng[1]) > 15.0)
		g_bIsAfk[client] = false;
	}

	if(IsCamping(client))
	{
		// It looks like this person may be camping, time to get serious
		KillTimer(g_hCampTimer[client]);
		g_hCampTimer[client] = CreateTimer(1.0, CaughtCampingTimer, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action:CaughtCampingTimer(Handle:timer, any:client)
{
	// Check to make sure the client is still connected
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// Get clients weapon camp time
	if(g_iCampCount[client] < GetWeaponCampTime(client))
	{
		if(IsCamping(client))
		{
			g_iCampCount[client]++;
			return Plugin_Handled;
		}
		else
		{
			ResetTimer(client);
			g_iCampCount[client] = 0;

			g_hCampTimer[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);
			return Plugin_Handled;
		}
	}
	else
	{
		// Get client name
		decl String:name[32];
		GetClientName(client, name, sizeof(name));

		// Get weapon name
		decl String:weapon[20];
		GetClientWeapon(client,weapon,20);
		ReplaceString(weapon, 20, "weapon_", "");

		// Get place name
		new String:place[24];
		GetEntDataString(client, g_iOffsLastPlaceName, place, sizeof(place));

		new bool:isLocation = StrEqual(place, "", false);

		// Show camp message to all
		decl String:Saytext[192];

		Format(Saytext, 192, "%t", "Player camping", "%s1",weapon,place,YELLOW,TEAMCOLOR,YELLOW,GREEN,YELLOW,GREEN);

		if(isLocation)
			ReplaceString(Saytext, 192, "@", "");

		SayText2(client, true, Saytext, name);

		// Reset camp counter
		g_iCampCount[client] = 0;

		// Start beacon timer; punish timer
		g_hBeaconTimer[client] = CreateTimer(BEACON_DELAY, BeaconTimer, client, TIMER_REPEAT);

		// Start camp timer
		KillTimer(g_hCampTimer[client]);
		g_hCampTimer[client] = CreateTimer(1.0, CamperTimer, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action:CamperTimer(Handle:timer, any:client)
{
	// Check to make sure the client is still connected
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// Check if still camping
	if(!IsCamping(client))
	{
		ResetTimer(client);
		g_hCampTimer[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);
	}

	return Plugin_Handled;
}

public Action:BeaconTimer(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// Create a beam effect and another one after
	if(GetConVarBool(g_CvarBeacon))
	{
		BeamRing(client);
		CreateTimer(0.2, BeaconTimer2, client);

		new Float:vecPos[3];
		GetClientAbsOrigin(client, vecPos);
		EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
	}

	// Punish
	SlapCamper(client);

	return Plugin_Handled;
}

public Action:BeaconTimer2(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);

		return Plugin_Handled;
	}
	// Create beamring on client
	BeamRing(client);

	return Plugin_Handled;
}

// Slap the camp
SlapCamper(client)
{
	// Slap player
	new ClientHealth = GetClientHealth(client);
	new LowHealth = GetConVarInt(g_CvarLowHealth);
	new SlapDmg = GetConVarInt(g_CvarSlap);

	if(SlapDmg > 0 && ClientHealth > LowHealth)
	{
		ClientHealth -= SlapDmg;
		if(ClientHealth > LowHealth)
		{
			SetEntityHealth(client, ClientHealth);
		}
		else
		{
			ResetTimer(client);
			SetEntityHealth(client, LowHealth);
		}
		// Emit slap sound from player
		new Float:vecPos[3];
		GetClientAbsOrigin(client, vecPos);

		decl String:SlapSound[24];
		Format(SlapSound, 64, "player/damage%i.wav", GetRandomInt(1, 3));
		EmitSoundToAll(SlapSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
	}
}

// Create beam ring effect
BeamRing(client)
{
	new color[] = {255, 0, 0, 255};

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);

	vec[2] += 5;

	TE_Start("BeamRingPoint");
	TE_WriteVector("m_vecCenter", vec);
	TE_WriteFloat("m_flStartRadius", 20.0);
	TE_WriteFloat("m_flEndRadius", 440.0);
	TE_WriteNum("m_nModelIndex", g_beamSprite);
	TE_WriteNum("m_nHaloIndex", g_haloSprite);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 0);
	TE_WriteFloat("m_fLife", 1.0);
	TE_WriteFloat("m_fWidth", 6.0);
	TE_WriteFloat("m_fEndWidth", 6.0);
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

// Send colored chat message
SayText2(from, bool:chat, const String:param1[], const String:param2[])
{
	new Handle:hBf = StartMessageAll("SayText2");

	if(hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, chat);
		BfWriteString(hBf, param1);
		BfWriteString(hBf, param2);
		EndMessage();
	}
}

// Reset all timers
ResetTimer(client)
{
	if(g_hBeaconTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hBeaconTimer[client]);
		g_hBeaconTimer[client] = INVALID_HANDLE;
	}

	if(g_hCampTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hCampTimer[client]);
		g_hCampTimer[client] = INVALID_HANDLE;
	}
}