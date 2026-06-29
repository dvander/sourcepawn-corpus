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

#define YELLOW               "\x01"
#define TEAMCOLOR	     	 "\x03"
#define GREEN				 "\x04"

#define PLUGIN_VERSION "1.0.8.4"

#define NON_CAMPER_DELAY 5.0
#define BEACON_DELAY 2.0

// Plugin definitions
public Plugin:myinfo =
{
	name = "Anticamp Source",
	author = "dalto, Blade",
	description = "Detects camping players",
	version = PLUGIN_VERSION,
	url = "http://www.germanskifferstuebchen.de/"
};

new g_iOffsetHealth = -1;
new g_iLastPlaceName = -1;
new g_iOffsEyeAngle = -1;

new Float:g_fLastPos[MAXPLAYERS + 1][3];
new Float:g_fSpawnEyeAng[MAXPLAYERS + 1][3];

new g_timerCount[MAXPLAYERS + 1];
new g_caughtCount[MAXPLAYERS + 1];

new bool:g_bIsAfk[MAXPLAYERS + 1];
new bool:g_bIsCsMap = false;

new Handle:g_hTimerList[MAXPLAYERS + 1];
new Handle:g_hBeaconList[MAXPLAYERS + 1];

new Handle:g_CvarBeacon = INVALID_HANDLE;
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarSlap = INVALID_HANDLE;
new Handle:g_CvarLowHealth = INVALID_HANDLE;
new Handle:g_CvarRadius = INVALID_HANDLE;
new Handle:g_CvarPollCount = INVALID_HANDLE;
new Handle:g_CvarPollsNeeded = INVALID_HANDLE;
new Handle:g_CvarAllowTCamp = INVALID_HANDLE;
new Handle:g_CvarAllowCtCamp = INVALID_HANDLE;

new g_beamSprite;
new g_haloSprite;

// sets a player's health
stock SetClientHealth(client, amount)
{
	SetEntData(client, g_iOffsetHealth, amount, _, true);
}

public OnPluginStart()
{
	CreateConVar("anticamp_version", PLUGIN_VERSION, "anticamp_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_CvarEnable = CreateConVar("sm_anticamp_enable", "1", "Set to 0 to disable anticamp", 0, true, 0.0, true, 1.0);
	g_CvarBeacon = CreateConVar("sm_anticamp_beacon", "1", "Set to 0 to disable beacons", 0, true, 0.0, true, 1.0);
	g_CvarSlap = CreateConVar("sm_anticamp_slap", "150", "Amount of health decrease during camping every 2 sec.", 0, true, 0.0, true, 50.0);
	g_CvarLowHealth = CreateConVar("sm_anticamp_health_level", "0", "Set to the health level below where camping is allowed", 0, true, 0.0, true, 100.0);
	g_CvarRadius = CreateConVar("sm_anticamp_radius", "200", "The radius to check for camping", 0, true, 50.0, true, 500.0);
	g_CvarPollCount = CreateConVar("sm_anticamp_poll_count", "35", "The amount of times a suspected camper is checked for", 0, true, 5.0, true, 60.0);
	g_CvarPollsNeeded = CreateConVar("sm_anticamp_polls_needed", "10", "The number of times he is found within the radius to be a camper", 0, true, 1.0, true, 20.0);
	g_CvarAllowTCamp = CreateConVar("sm_anticamp_t_camp", "1", "Set to 1 to allow camping for t on cs maps. Set to 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCamp = CreateConVar("sm_anticamp_ct_camp", "1", "Set to 1 to allow camping for ct on de maps if bomb is dropped. Set to 0 to disable", 0, true, 0.0, true, 1.0);

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_PostNoCopy);

	g_iLastPlaceName = FindSendPropOffs("CBasePlayer", "m_szLastPlaceName");
	g_iOffsetHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	g_iOffsEyeAngle = FindSendPropOffs("CCSPlayer","m_angEyeAngles[0]");

	LoadTranslations("anticamp.phrases");
}

public OnMapStart()
{
	// beacon sound
	PrecacheSound("buttons/button17.wav",true);

	// slap sounds
	PrecacheSound("player/damage1.wav",true);
	PrecacheSound("player/damage2.wav",true);
	PrecacheSound("player/damage3.wav",true);

	g_beamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt");

	// Check if de map
	if(FindEntityByClassname(-1, "func_hostage_rescue") != -1)
		g_bIsCsMap = true;
	else
		g_bIsCsMap = false;
}

bool:IsCamping(client, Float:vec1[3], Float:vec2[3])
{
	if(g_bIsAfk[client])
	{
		new Float:ClientEyeAng[3];
		GetEntDataVector(client, g_iOffsEyeAngle, ClientEyeAng);

		if(FloatAbs(g_fSpawnEyeAng[client][1] - ClientEyeAng[1]) > 15.0)
		g_bIsAfk[client] = false;
	}

	if(!g_bIsAfk[client] && GetVectorDistance(vec1, vec2) < GetConVarInt(g_CvarRadius) && GetClientHealth(client) > GetConVarInt(g_CvarLowHealth))
	{
		return true;
	}
	return false;
}

public Action:EventBombPlanted(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarAllowTCamp))
	{
		return Plugin_Continue;
	}

	new teamindex;
	new MaxClients = GetMaxClients();
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			teamindex = GetClientTeam(i);
			if(teamindex == 2)
			{
				if(g_hTimerList[i] != INVALID_HANDLE)
				{
					KillTimer(g_hTimerList[i]);
					g_hTimerList[i] = INVALID_HANDLE;
				}
				if(g_hBeaconList[i] != INVALID_HANDLE)
				{
					KillTimer(g_hBeaconList[i]);
					g_hBeaconList[i] = INVALID_HANDLE;
				}
			}
			else if(teamindex == 3 && g_hTimerList[i] == INVALID_HANDLE)
			{
				GetClientAbsOrigin(i, g_fLastPos[i]);
				g_hTimerList[i] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, i, TIMER_REPEAT);
			}
		}
	}
	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// get the client team
	new clientteam = GetClientTeam(client);

	// return if client spawns first time
	if(clientteam == 0)
	{
		return Plugin_Continue;
	}

	// reset player eye angle
	g_fSpawnEyeAng[client][1] = 0.0;

	// check to see if there is an outstanding handle from last round
	if(g_hTimerList[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = INVALID_HANDLE;
	}

	if(g_hBeaconList[client] != INVALID_HANDLE)
	{
		KillTimer(g_hBeaconList[client]);
		g_hBeaconList[client] = INVALID_HANDLE;
	}

	if(!GetConVarBool(g_CvarEnable))
	{
		return Plugin_Continue;
	}

	// Allow camping for t on cs maps
	if(g_bIsCsMap && clientteam == 2 && GetConVarBool(g_CvarAllowTCamp))
	{
		return Plugin_Continue;
	}

	// Allow camping for ct on de maps
	if(!g_bIsCsMap && clientteam == 3 && GetConVarBool(g_CvarAllowCtCamp))
	{
		return Plugin_Continue;
	}

	// get the players position and start the timing cycle
	GetClientAbsOrigin(client, g_fLastPos[client]);
	g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);

	return Plugin_Continue;
}

public Action:CheckCamperTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = INVALID_HANDLE;

		return Plugin_Handled;
	}

	// store clients eye angle to check if player is afk
	if(g_fSpawnEyeAng[client][1] == 0.0)
	{
		GetEntDataVector(client, g_iOffsEyeAngle, g_fSpawnEyeAng[client]);
		g_bIsAfk[client] = true;
	}

	new Float:currentPos[3];
	GetClientAbsOrigin(client, currentPos);

	if(IsCamping(client, g_fLastPos[client], currentPos))
	{
		// it looks like this person may be camping, time to get serious
		g_caughtCount[client] = 0;
		g_timerCount[client] = 1;

		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = CreateTimer(1.0, CaughtCampingTimer, client, TIMER_REPEAT);
	}

	g_fLastPos[client] = currentPos;
	return Plugin_Handled;
}

public Action:CaughtCampingTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = INVALID_HANDLE;

		return Plugin_Handled;
	}

	new Float:currentPos[3];
	GetClientAbsOrigin(client, currentPos);

	if(g_timerCount[client] < GetConVarInt(g_CvarPollCount))
	{
		if(IsCamping(client, g_fLastPos[client], currentPos))
		{
			g_caughtCount[client]++;
		}
		g_timerCount[client]++;
	}
	else
	{
		if(g_caughtCount[client] >= GetConVarInt(g_CvarPollsNeeded) && IsCamping(client, g_fLastPos[client], currentPos))
		{
			decl String:name[30];
			GetClientName(client, name, sizeof(name));

			// get weapon name
			decl String:weapon[20];
			GetClientWeapon(client,weapon,20);
			ReplaceString(weapon, 20, "weapon_", "");

			// get the place where client is camping
			new String:place[50] = "";
			if(g_iLastPlaceName != -1) GetEntDataString(client, g_iLastPlaceName, place, sizeof(place));

			// show camp message to everyone
			new String:Saytext[192];
			new MaxClients = GetMaxClients();

			for(new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(Saytext, sizeof(Saytext), "%T", "Player camping", i,"%s1",weapon,place,YELLOW,TEAMCOLOR,YELLOW,GREEN,YELLOW,GREEN);
					SayText2(i, client, true, Saytext, name);
				}
			}

			// start beacon timer
			g_hBeaconList[client] = CreateTimer(BEACON_DELAY, BeaconTimer, client, TIMER_REPEAT);

			// check if client is still camping
			KillTimer(g_hTimerList[client]);
			g_hTimerList[client] = CreateTimer(1.0, CamperTimer, client, TIMER_REPEAT);
		}
		else
		{
			if(g_hBeaconList[client] != INVALID_HANDLE)
			{
				KillTimer(g_hBeaconList[client]);
				g_hBeaconList[client] = INVALID_HANDLE;
			}

			KillTimer(g_hTimerList[client]);
			g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);

			g_fLastPos[client] = currentPos;
		}
	}
	return Plugin_Handled;
}

public Action:CamperTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = INVALID_HANDLE;

		return Plugin_Handled;
	}

	// check if still camping
	new Float:currentPos[3];
	GetClientAbsOrigin(client, currentPos);

	if(IsPlayerAlive(client) && !IsCamping(client, g_fLastPos[client], currentPos))
	{
		g_caughtCount[client] = 0;
		g_timerCount[client] = 1;

		KillTimer(g_hBeaconList[client]);
		g_hBeaconList[client] = INVALID_HANDLE;

		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);

		g_fLastPos[client] = currentPos;
	}

	return Plugin_Handled;
}

public Action:BeaconTimer(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		KillTimer(g_hBeaconList[client]);
		g_hBeaconList[client] = INVALID_HANDLE;

		return Plugin_Handled;
	}

	// create a beam effect and the anathor one immediately after
	if(GetConVarBool(g_CvarBeacon))
	{
		new color[] = {150, 0, 0, 255};
		BeamRing(client, color);
		CreateTimer(0.2, BeaconTimer2, client);

		new Float:vecPos[3];
		GetClientAbsOrigin(client, vecPos);
		EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
	}

	// slap player
	new ClientHealth = GetClientHealth(client);
	new LowHealth = GetConVarInt(g_CvarLowHealth);
	new SlapDmg = GetConVarInt(g_CvarSlap);

	if (SlapDmg > 0 && ClientHealth > LowHealth)
	{
		ClientHealth -= SlapDmg;
		if (ClientHealth >= LowHealth)
		{
			SetClientHealth(client, ClientHealth);

			// emit slap sound from player
			new Float:vecPos[3];
			GetClientAbsOrigin(client, vecPos);

			decl String:g_slapSound[100];
			Format(g_slapSound, 64, "player/damage%i.wav", GetRandomInt(1, 3));
			EmitSoundToAll(g_slapSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
		}
		else
		{
			SetClientHealth(client, LowHealth);
		}
	}
	return Plugin_Handled;
}

public Action:BeaconTimer2(Handle:timer, any:client)
{
	new color[] = {255, 0, 0, 255};
	if(!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client))
	{
		KillTimer(g_hBeaconList[client]);
		g_hBeaconList[client] = INVALID_HANDLE;

		return Plugin_Handled;
	}

	// create beamring on client
	BeamRing(client, color);

	return Plugin_Handled;
}

BeamRing(client, color[4])
{
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

SayText2(to, from, bool:chat, const String:param1[], const String:param2[])
{
	new Handle:hBf = INVALID_HANDLE;

	hBf = StartMessageOne("SayText2", to);

	BfWriteByte(hBf, from);
	BfWriteByte(hBf, chat);
	BfWriteString(hBf, param1);
	BfWriteString(hBf, param2);
	EndMessage();
}