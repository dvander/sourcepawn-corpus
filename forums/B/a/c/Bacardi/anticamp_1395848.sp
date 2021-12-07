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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <cstrike>

#define YELLOW				 "\x01"
#define TEAMCOLOR			 "\x03"
#define GREEN				 "\x04"
#define PLUGIN_VERSION "2.21"
#define NON_CAMPER_DELAY 1.0
#define BEACON_DELAY 2.0
#define MAX_WEAPONS 29

new String:ConfigFile[PLATFORM_MAX_PATH];

// Plugin definitions
public Plugin:myinfo =
{
	name = "Anticamp CS:S",
	author = "stachi",
	description = "Detects camping players",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/newreply.php?do=postreply&t=99960"
};


new String:g_sWeaponList[MAX_WEAPONS][] = {"glock","usp","p228","deagle","elite","fiveseven","m3",
										   "xm1014","galil","ak47","scout","sg552","awp","g3sg1",
										   "famas","m4a1","aug","sg550","mac10","tmp","mp5navy",
										   "ump45","p90","m249","flashbang","hegrenade","smokegrenade","c4","knife"
										  };

new g_iOffsLastPlaceName = -1;
new g_iOffsEyeAngle = -1;

new g_iWeaponCampTime[MAX_WEAPONS];

new Float:g_fLastPos[MAXPLAYERS + 1][3];
new Float:g_fSpawnEyeAng[MAXPLAYERS + 1][3];

new g_timerCount[MAXPLAYERS + 1];

new bool:g_bIsAfk[MAXPLAYERS + 1];
new bool:g_bIsCtMap = false;
new bool:g_bIsTMap = false;
new bool:g_bWeaponCfg= false;

new Handle:g_hTimerList[MAXPLAYERS + 1];
new Handle:g_hBeaconList[MAXPLAYERS + 1];

new Handle:g_CvarBeacon = INVALID_HANDLE;
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarSlap = INVALID_HANDLE;
new Handle:g_CvarSlapDmg = INVALID_HANDLE;
new Handle:g_CvarSlapAnyway = INVALID_HANDLE;
new Handle:g_CvarLowHealth = INVALID_HANDLE;
new Handle:g_CvarRadius = INVALID_HANDLE;
new Handle:g_CvarCampTime = INVALID_HANDLE;
new Handle:g_CvarAllowTCamp = INVALID_HANDLE;
new Handle:g_CvarAllowTCampPlanted = INVALID_HANDLE;
new Handle:g_CvarAllowCtCamp = INVALID_HANDLE;
new Handle:g_CvarAllowCtCampDropped = INVALID_HANDLE;

new g_beamSprite;
new g_haloSprite;

public OnPluginStart()
{
	CreateConVar("anticamp_css_version", PLUGIN_VERSION, "anticamp_css_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_CvarEnable = CreateConVar("sm_anticamp_enable", "1", "Set to 0 to disable anticamp", 0, true, 0.0, true, 1.0);
	g_CvarBeacon = CreateConVar("sm_anticamp_beacon", "1", "Set to 0 to disable beacons", 0, true, 0.0, true, 1.0);
	g_CvarSlap = CreateConVar("sm_anticamp_slap", "1", "Set to 0 to disable slap", 0, true, 0.0, true, 1.0);
	g_CvarSlapDmg = CreateConVar("sm_anticamp_slap_dmg", "5", "Amount of health decrease during camping every 2 sec", 0, true, 0.0, true, 100.0);
	g_CvarLowHealth = CreateConVar("sm_anticamp_minhealth", "15", "Set to the minimum health a camper keep. Set to 0 to slap till dead", 0, true, 0.0, true, 100.0);
	g_CvarSlapAnyway = CreateConVar("sm_anticamp_minhealth_camp", "1", "Set to 0 to allow camping below minhealth. Set to 1 to slap without damge", 0, true, 0.0, true, 1.0);
	g_CvarRadius = CreateConVar("sm_anticamp_radius", "120", "The radius to check for camping", 0, true, 50.0, true, 500.0);
	g_CvarCampTime = CreateConVar("sm_anticamp_camptime", "30", "The amount of times a suspected camper is checked for", 0, true, 5.0, true, 60.0);
	g_CvarAllowTCamp = CreateConVar("sm_anticamp_t_camp", "1", "Set to 1 to allow camping for Ts on cs maps. Set to 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowTCampPlanted = CreateConVar("sm_anticamp_t_camp_planted", "1", "Set to 1 to allow camping for Ts if bomb planted. Set to 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCamp = CreateConVar("sm_anticamp_ct_camp", "1", "Set to 1 to allow camping for CTs on de maps. Set to 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCampDropped = CreateConVar("sm_anticamp_ct_camp_dropped", "1", "Set to 1 to allow camping for CTs if bomb dropped. Is only needed if sm_anticamp_ct_camp is 0", 0, true, 0.0, true, 1.0);


	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_PostNoCopy);
	HookEvent("bomb_dropped", EventBombDropped, EventHookMode_PostNoCopy);
	HookEvent("bomb_pickup", EventBombPickup, EventHookMode_PostNoCopy);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);

	g_iOffsEyeAngle = FindSendPropOffs("CCSPlayer","m_angEyeAngles[0]");
	g_iOffsLastPlaceName = FindSendPropOffs("CBasePlayer", "m_szLastPlaceName");

	LoadTranslations("anticamp.phrases");

	// Auto-generate config file
	AutoExecConfig(true,"plugin.anticamp","sourcemod");
}

public OnMapStart()
{
	// beacon sound
	PrecacheSound("buttons/button17.wav",true);

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
	BuildPath(Path_SM,ConfigFile,sizeof(ConfigFile),"configs/anticamp_weapons.cfg");
	
	if(!FileExists(ConfigFile)) 
		LogMessage("anticamp_weapons.cfg not parsed...file doesn't exist! Using sm_anticamp_camptime");
	else
	{
		new Handle:filehandle = OpenFile(ConfigFile, "r");

		decl String:buffer[32];

		while(!IsEndOfFile(filehandle))
		{
			ReadFileLine(filehandle, buffer, sizeof(buffer));
			TrimString(buffer);

			if(buffer[0] == '/' || buffer[0] == '\0')
				continue;

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
						g_iWeaponCampTime[i] = 0;
				}
			}
		}
		CloseHandle(filehandle);
	}
}

GetWeaponCampTime(client)
{
	if(!g_bWeaponCfg)
		return GetConVarInt(g_CvarCampTime);

	// get weapon name
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

bool:CheckAliveTeams()
{
	#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
		new MaxClients = GetMaxClients();
	#endif
	
	new alivect, alivet, team;
	alivect = 0, alivet = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			team = GetClientTeam(i);
			if(team == 3)
				alivect++;
			else if(team == 2)
				alivet++;
		}
	}
	
	if(alivect > 0 && alivet > 0)
		return true;
	else
		return false;
}

bool:IsCamping(client)
{
	new Float:CurrentPos[3];
	GetClientAbsOrigin(client, CurrentPos);

	if(GetVectorDistance(g_fLastPos[client], CurrentPos) < GetConVarInt(g_CvarRadius))
	{
		if(!g_bIsAfk[client])
			if(GetClientHealth(client) > GetConVarInt(g_CvarLowHealth) || GetConVarBool(g_CvarSlapAnyway))
				return true;
	}
	else if(g_bIsAfk[client])
		g_bIsAfk[client] = false;

	g_fLastPos[client] = CurrentPos;
	return false;
}

public Action:EventBombPickup(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarBool(g_CvarAllowCtCampDropped) && !GetConVarBool(g_CvarAllowCtCamp))
	{
		#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
			new MaxClients = GetMaxClients();
		#endif

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientConnected(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT && g_hTimerList[i] == INVALID_HANDLE)
			{
				GetClientAbsOrigin(i, g_fLastPos[i]);
				g_hTimerList[i] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, i, TIMER_REPEAT);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:EventBombDropped(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarBool(g_CvarAllowCtCampDropped) && !GetConVarBool(g_CvarAllowCtCamp))
	{	
		#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
			new MaxClients = GetMaxClients();
		#endif
  
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientConnected(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT && g_hTimerList[i] != INVALID_HANDLE)
				ResetTimer(i);
		}
	}

	return Plugin_Continue;
}

public Action:EventBombPlanted(Handle:event,const String:name[],bool:dontBroadcast)
{
	#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
		new MaxClients = GetMaxClients();
	#endif
	
	new teamindex;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			teamindex = GetClientTeam(i);
			
			if(teamindex == CS_TEAM_T && GetConVarBool(g_CvarAllowTCampPlanted) && g_hTimerList[i] != INVALID_HANDLE)
				ResetTimer(i);
		}
	}
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// get the client team
	new clientteam = GetClientTeam(client);

	// return if new client
	if(clientteam == CS_TEAM_NONE)
		return Plugin_Continue;

	// reset caught timer
	g_timerCount[client] = 0;

	// reset player eye angle
	g_fSpawnEyeAng[client][1] = 0.0;

	// check to see if there is an outstanding handle from last round
	ResetTimer(client);

	if(!GetConVarBool(g_CvarEnable))
		return Plugin_Continue;

	// client have immunity
	if(CheckCommandAccess(client, "anticamp_immunity", ADMFLAG_SLAY))
	{
		return Plugin_Continue;
	}

	// Allow camping for t on cs maps
	if(g_bIsCtMap && clientteam == CS_TEAM_T && GetConVarBool(g_CvarAllowTCamp))
		return Plugin_Continue;

	// Allow camping for ct on de maps
	if(g_bIsTMap && clientteam == CS_TEAM_CT && GetConVarBool(g_CvarAllowCtCamp))
		return Plugin_Continue;

	// get the players position and start the timing cycle
	GetClientAbsOrigin(client, g_fLastPos[client]);
	g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);

	return Plugin_Continue;
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(CheckAliveTeams())
	{
		#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
			new MaxClients = GetMaxClients();
		#endif
	
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && g_hTimerList[i] != INVALID_HANDLE)
				ResetTimer(i);
		}
	}
}

public Action:CheckCamperTimer(Handle:timer, any:client)
{		
	// check to make sure the client is still connected and there are players in both teams
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || !CheckAliveTeams())
	{
		ResetTimer(client);

		return Plugin_Handled;
	}

	// store client's eye angle for afk checking
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
		// it looks like this person may be camping, time to get serious
		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = CreateTimer(1.0, CaughtCampingTimer, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action:CaughtCampingTimer(Handle:timer, any:client)
{
	#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
		new MaxClients = GetMaxClients();
	#endif
	
	// check to make sure the client is still connected and there are players in both teams 
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || !CheckAliveTeams())
	{
		ResetTimer(client);

		return Plugin_Handled;
	}

	if(g_timerCount[client] < GetWeaponCampTime(client))
	{
		if(IsCamping(client))
		{
			g_timerCount[client]++;
			return Plugin_Handled;
		}
		else
		{
			ResetTimer(client);
			g_timerCount[client] = 0;

			g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);
			return Plugin_Handled;
		}
	}
	else
	{
		// get client details
		decl String:name[32];
		decl String:camperTeam[10];
		decl String:camperSteamID[64];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, camperSteamID, sizeof(camperSteamID));
		new clientteam = GetClientTeam(client);
		
		if(clientteam == CS_TEAM_CT)
			camperTeam = "CT";
		else if(clientteam == CS_TEAM_T)
			camperTeam = "TERRORIST";
	
		// get weapon name
		decl String:weapon[20];
		GetClientWeapon(client,weapon,20);
		ReplaceString(weapon, 20, "weapon_", "");

		// get place name
		new String:place[24];
		GetEntDataString(client, g_iOffsLastPlaceName, place, sizeof(place));

		new bool:Location = StrEqual(place, "", false);
		
		// log camping
		LogToGame("\"%s<%d><%s><%s>\" triggered \"camper\"",name,GetClientUserId(client),camperSteamID,camperTeam);

		// show camp message to all
		decl String:Saytext[192];

		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(Saytext, sizeof(Saytext), "%T", "Player camping", i,"%s1",weapon,place,YELLOW,TEAMCOLOR,YELLOW,GREEN,YELLOW,GREEN);

				if(Location)
					ReplaceString(Saytext, 192, "@", "");

				SayText2(i, client, true, Saytext, name);
			}
		}

		// reset camp counter
		g_timerCount[client] = 0;

		// start beacon timer
		g_hBeaconList[client] = CreateTimer(BEACON_DELAY, BeaconTimer, client, TIMER_REPEAT);

		// start camp timer
		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = CreateTimer(1.0, CamperTimer, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action:CamperTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams 
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || !CheckAliveTeams())
	{
		ResetTimer(client);

		return Plugin_Handled;
	}

	// check if still camping
	if(!IsCamping(client))
	{
		ResetTimer(client);
		g_hTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);
	}

	return Plugin_Handled;
}

public Action:BeaconTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || !CheckAliveTeams())
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// create a beam effect and the anathor one immediately after
	if(GetConVarBool(g_CvarBeacon))
	{
	new colorct[] = {0, 0, 150, 255};
	new colort[] = {150, 0, 0, 255};
	new clientteam = GetClientTeam(client);
	
	if(clientteam == CS_TEAM_CT)
		BeamRing(client, colorct);
	else if(clientteam == CS_TEAM_T)
		BeamRing(client, colort);
		
	CreateTimer(0.2, BeaconTimer2, client);

	new Float:vecPos[3];
	GetClientAbsOrigin(client, vecPos);
	EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
	}

	// slap player
	new ClientHealth = GetClientHealth(client);
	new LowHealth = GetConVarInt(g_CvarLowHealth);
	new SlapDmg = GetConVarInt(g_CvarSlapDmg);

	if(GetConVarBool(g_CvarSlap) && ClientHealth > LowHealth)
	{	
		ClientHealth -= SlapDmg;
		
		if(ClientHealth > LowHealth || LowHealth <= 0)
			SlapPlayer(client, SlapDmg, true);
		else
		{
			if(!GetConVarBool(g_CvarSlapAnyway))
				ResetTimer(client);
				
			SetEntityHealth(client, LowHealth);
			SlapPlayer(client, 0, true);
		}
	}
	else if(GetConVarBool(g_CvarSlap))
		SlapPlayer(client, 0, true);

	return Plugin_Handled;
}

public Action:BeaconTimer2(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || !CheckAliveTeams())
	{
		ResetTimer(client);

		return Plugin_Handled;
	}
	// create beamring on client
	new colort[] = {150, 0, 0, 255};
	new colorct[] = {0, 0, 150, 255};

	new clientteam = GetClientTeam(client);
	
	if(clientteam == CS_TEAM_CT)
		BeamRing(client, colorct);
	else if(clientteam == CS_TEAM_T)
		BeamRing(client, colort);

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

ResetTimer(client)
{
	if(g_hBeaconList[client] != INVALID_HANDLE)
	{
		KillTimer(g_hBeaconList[client]);
		g_hBeaconList[client] = INVALID_HANDLE;
	}

	if(g_hTimerList[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimerList[client]);
		g_hTimerList[client] = INVALID_HANDLE;
	}
}