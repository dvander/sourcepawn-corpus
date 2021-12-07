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
#define PLUGIN_VERSION "2.5.2"
#define NON_CAMPER_DELAY 1.0
#define MAX_WEAPONS 49

// Plugin definitions
public Plugin:myinfo =
{
	name = "Anticamp CS:S and CS:GO",
	author = "stachi",
	description = "Detects camping players",
	version = PLUGIN_VERSION,
	url = "http://www.stachi.de/"
};

enum GameType
{
	GAME_CSS,
	GAME_CSGO
};
new GameType:g_iGame;
new String:WeaponConfigFile[PLATFORM_MAX_PATH];
new const String:g_sWeaponList[MAX_WEAPONS][13] = {"glock","usp","p228","deagle","elite","fiveseven","m3",
													"xm1014","galil","ak47","scout","sg552","awp","g3sg1",
													"famas","m4a1","aug","sg550","mac10","tmp","mp5navy",
													"ump45","p90","m249","flashbang","hegrenade","smokegrenade","c4","knife",
													"mp7","mp9","bizon","galilar","ssg08","scar20","hkp2000","tec9","negev",
													"p250","sg556","sg553","sawedoff","mag7","nova","knifegg","taser","molotov",
													"incgrenade","decoy"
													};

new g_iWeaponCampTime[MAX_WEAPONS];
new g_iOffsLastPlaceName = -1;
new g_iOffsEyeAngle = -1;

new Float:g_fLastPos[MAXPLAYERS + 1][3];
new Float:g_fSpawnEyeAng[MAXPLAYERS + 1][3];

new g_timerCount[MAXPLAYERS + 1];

new bool:g_bIsAfk[MAXPLAYERS + 1];
new bool:g_bIsBlind[MAXPLAYERS + 1];
new bool:g_bIsCtMap = false;
new bool:g_bIsTMap = false;
new bool:g_bWeaponCfg = false;
new bool:g_bTeamsHaveAlivePlayers = false;

new Handle:g_hCampTimerList[MAXPLAYERS + 1];
new Handle:g_hPunishTimerList[MAXPLAYERS + 1];
new Handle:g_hDelayTimerList[MAXPLAYERS + 1];

new Handle:g_CvarBeacon = INVALID_HANDLE;
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarSlapSlay = INVALID_HANDLE;
new Handle:g_CvarTakeCash = INVALID_HANDLE;
new Handle:g_CvarBlind = INVALID_HANDLE;
new Handle:g_CvarSlapDmg = INVALID_HANDLE;
new Handle:g_CvarPunishDelay = INVALID_HANDLE;
new Handle:g_CvarPunishFreq = INVALID_HANDLE;
new Handle:g_CvarPunishAnyway = INVALID_HANDLE;
new Handle:g_CvarMinHealth = INVALID_HANDLE;
new Handle:g_CvarMinCash = INVALID_HANDLE;
new Handle:g_CvarRadius = INVALID_HANDLE;
new Handle:g_CvarCampTime = INVALID_HANDLE;
new Handle:g_CvarAllowTCamp = INVALID_HANDLE;
new Handle:g_CvarAllowTCampPlanted = INVALID_HANDLE;
new Handle:g_CvarAllowCtCamp = INVALID_HANDLE;
new Handle:g_CvarAllowCtCampDropped = INVALID_HANDLE;

new g_beamSprite;
new g_haloSprite;
new g_MoneyOffset;

new g_iBRColorT[] = {150, 0, 0, 255};
new g_iBRColorCT[] = {0, 0, 150, 255};

new UserMsg:g_FadeUserMsgId;

public OnPluginStart()
{
	CreateConVar("anticamp_css_version", PLUGIN_VERSION, "anticamp_css_version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_CvarEnable = CreateConVar("sm_anticamp_enable", "1", "Set 0 to disable anticamp", 0, true, 0.0, true, 1.0);
	g_CvarBeacon = CreateConVar("sm_anticamp_beacon", "1", "Set 0 to disable beacons", 0, true, 0.0, true, 1.0);
	g_CvarTakeCash = CreateConVar("sm_anticamp_take_cash", "0", "Amount of money decrease while camping every sm_anticamp_punish_freq. Set 0 to disable", 0, true, 0.0, true, 16000.0);
	g_CvarMinCash = CreateConVar("sm_anticamp_mincash", "0", "Minimum money a camper reserves", 0, true, 0.0, true, 16000.0);
	g_CvarBlind = CreateConVar("sm_anticamp_blind", "0", "Blind a player while camping", 0, true, 0.0, true, 1.0);
	g_CvarSlapSlay = CreateConVar("sm_anticamp_slap_mode", "1", "Set 1 to slap or 2 to slay (kills instantly). Set 0 to disable both", 0, true, 0.0, true, 2.0);
	g_CvarSlapDmg = CreateConVar("sm_anticamp_slap_dmg", "5", "Amount of health decrease while camping every sm_anticamp_punish_freq. Ignored for slay", 0, true, 0.0, true, 100.0);
	g_CvarMinHealth = CreateConVar("sm_anticamp_minhealth", "15", "Minimum health a camper reserves. Set 0 to slap till dead. If slay set the health from which player will not be killed", 0, true, 0.0, true, 100.0);
	g_CvarPunishDelay = CreateConVar("sm_anticamp_punish_delay", "2", "Delay between camper notification and first punishment in secounds", 0, true, 0.0, true, 60.0);
	g_CvarPunishFreq = CreateConVar("sm_anticamp_punish_freq", "2", "Time between punishments while camping in secounds", 0, true, 1.0, true, 60.0);
	g_CvarPunishAnyway = CreateConVar("sm_anticamp_minhealth_camp", "1", "Set 0 to allow camping below minhealth. Set 1 to punish without damage", 0, true, 0.0, true, 1.0);
	g_CvarRadius = CreateConVar("sm_anticamp_radius", "120", "The radius to check for camping", 0, true, 50.0, true, 500.0);
	g_CvarCampTime = CreateConVar("sm_anticamp_camptime", "30", "The amount of times a suspected camper is checked for", 0, true, 2.0, true, 60.0);
	g_CvarAllowTCamp = CreateConVar("sm_anticamp_t_camp", "1", "Set 1 to allow camping for Ts on cs maps. Set 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowTCampPlanted = CreateConVar("sm_anticamp_t_camp_planted", "1", "Set 1 to allow camping for Ts if bomb planted. Set 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCamp = CreateConVar("sm_anticamp_ct_camp", "1", "Set 1 to allow camping for CTs on de maps. Set 0 to disable", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCampDropped = CreateConVar("sm_anticamp_ct_camp_dropped", "1", "Set 1 to allow camping for CTs if bomb dropped. Is only needed if sm_anticamp_ct_camp is 0", 0, true, 0.0, true, 1.0);

	decl String:gamedir[PLATFORM_MAX_PATH];
	GetGameFolderName(gamedir, sizeof(gamedir));
	if(strcmp(gamedir, "cstrike") == 0)
	{
		g_iGame = GAME_CSS;
		WeaponConfigFile = "configs/anticamp_css_weapons.cfg";
	}
	else
	{
		g_iGame = GAME_CSGO;
		WeaponConfigFile = "configs/anticamp_csgo_weapons.cfg";
	}

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_PostNoCopy);
	HookEvent("bomb_dropped", EventBombDropped, EventHookMode_PostNoCopy);
	HookEvent("bomb_pickup", EventBombPickup, EventHookMode_PostNoCopy);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("cs_win_panel_match", EventRoundEnd, EventHookMode_PostNoCopy); // Sometimes round_end did not fire
	if(g_iGame == GAME_CSGO)
	{
		HookEvent("announce_phase_end", EventRoundEnd, EventHookMode_PostNoCopy); // Sometimes round_end and cs_win_panel_match did not fire in CS:GO
	}

	g_iOffsEyeAngle = FindSendPropOffs("CCSPlayer","m_angEyeAngles[0]");
	g_iOffsLastPlaceName = FindSendPropOffs("CBasePlayer", "m_szLastPlaceName");
	g_MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_FadeUserMsgId = GetUserMessageId("Fade");

	LoadTranslations("anticamp.phrases");

	// Auto-generate config file
	AutoExecConfig(true,"plugin.anticamp","sourcemod");
}

public OnMapStart()
{
	// beacon sound
	PrecacheSound("buttons/button17.wav",true);

	if(g_iGame == GAME_CSGO)
	{
		g_beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_haloSprite = PrecacheModel("materials/sprites/halo.vmt");
	}
	else
	{
		g_beamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	}

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
	decl String:PathToConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, PathToConfigFile, sizeof(PathToConfigFile), WeaponConfigFile);

	if(!FileExists(PathToConfigFile))
		LogMessage("%s not parsed...file doesn't exist! Using sm_anticamp_camptime", PathToConfigFile);
	else
	{
		new Handle:filehandle = OpenFile(PathToConfigFile, "r");

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
	new alivect, alivet, team;
	alivect = 0, alivet = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			team = GetClientTeam(i);
			if(team == CS_TEAM_CT)
				alivect++;
			else if(team == CS_TEAM_T)
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
			if(GetClientHealth(client) > GetConVarInt(g_CvarMinHealth) || GetConVarBool(g_CvarPunishAnyway))
				return true;
	}
	else if(g_bIsAfk[client])
		g_bIsAfk[client] = false;

	g_fLastPos[client] = CurrentPos;
	return false;
}

public Action:EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	//Check if anticamp is enabled
	if(!GetConVarBool(g_CvarEnable))
		return Plugin_Continue;

	// Check if booth Teams have alive players
	g_bTeamsHaveAlivePlayers = CheckAliveTeams();

	return Plugin_Continue;
}

public Action:EventBombPickup(Handle:event,const String:name[],bool:dontBroadcast)
{
	//Check if anticamp is enabled
	if(!GetConVarBool(g_CvarEnable))
		return Plugin_Continue;

	if(GetConVarBool(g_CvarAllowCtCampDropped) && !GetConVarBool(g_CvarAllowCtCamp))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT && g_hCampTimerList[i] == INVALID_HANDLE)
			{
				GetClientAbsOrigin(i, g_fLastPos[i]);
				g_hCampTimerList[i] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, i, TIMER_REPEAT);
			}
		}
	}

	return Plugin_Continue;
}

public Action:EventBombDropped(Handle:event,const String:name[],bool:dontBroadcast)
{
	//Check if anticamp is enabled
	if(!GetConVarBool(g_CvarEnable))
		return Plugin_Continue;

	if(GetConVarBool(g_CvarAllowCtCampDropped) && !GetConVarBool(g_CvarAllowCtCamp))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && g_hCampTimerList[i] != INVALID_HANDLE && GetClientTeam(i) == CS_TEAM_CT)
				ResetTimer(i);
		}
	}

	return Plugin_Continue;
}

public Action:EventBombPlanted(Handle:event,const String:name[],bool:dontBroadcast)
{
	//Check if anticamp is enabled
	if(!GetConVarBool(g_CvarEnable))
		return Plugin_Continue;

	if(GetConVarBool(g_CvarAllowTCampPlanted))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && g_hCampTimerList[i] != INVALID_HANDLE && GetClientTeam(i) == CS_TEAM_T)
				ResetTimer(i);

		}
	}

	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	//Check if anticamp is enabled
	if(!GetConVarBool(g_CvarEnable))
		return Plugin_Continue;

	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// get the client team
	new clientteam = GetClientTeam(client);

	// return if new client
	if(clientteam == CS_TEAM_NONE)
		return Plugin_Continue;

	// Check if booth Teams have alive players and safe it
	g_bTeamsHaveAlivePlayers = CheckAliveTeams();

	// reset caught timer
	g_timerCount[client] = 0;

	// reset player eye angle
	g_fSpawnEyeAng[client][1] = 0.0;

	// check to see if there is an outstanding handle from last round
	ResetTimer(client);

	// Allow camping for t on cs maps if enabled
	if(g_bIsCtMap && GetConVarBool(g_CvarAllowTCamp) && clientteam == CS_TEAM_T)
		return Plugin_Continue;

	// Allow camping for ct on de maps if enabled
	if(g_bIsTMap && GetConVarBool(g_CvarAllowCtCamp) && clientteam == CS_TEAM_CT)
		return Plugin_Continue;

	// get the players position and start the timing cycle
	GetClientAbsOrigin(client, g_fLastPos[client]);
	g_hCampTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);

	return Plugin_Continue;
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Check if anticamp is enabled
	if(!GetConVarBool(g_CvarEnable))
		return Plugin_Continue;

	// Check if booth Teams have alive players
	g_bTeamsHaveAlivePlayers = CheckAliveTeams();

	if(g_bTeamsHaveAlivePlayers)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && g_hCampTimerList[i] != INVALID_HANDLE)
			{
				ResetTimer(i);
			}
		}
	}

	return Plugin_Continue;
}

public Action:CheckCamperTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!g_bTeamsHaveAlivePlayers || !IsClientInGame(client) || !IsPlayerAlive(client))
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
		KillTimer(g_hCampTimerList[client]);
		g_hCampTimerList[client] = CreateTimer(1.0, CaughtCampingTimer, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action:CaughtCampingTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!g_bTeamsHaveAlivePlayers || !IsClientInGame(client) || !IsPlayerAlive(client))
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

			g_hCampTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);
			return Plugin_Handled;
		}
	}
	else
	{
		// get client details
		decl String:name[32];
		decl String:camperTeam[18];
		decl String:camperSteamID[64];
		GetClientName(client, name, sizeof(name));
		GetTeamName(GetClientTeam(client),camperTeam,sizeof(camperTeam));
		GetClientAuthString(client, camperSteamID, sizeof(camperSteamID));

		// get weapon name
		decl String:weapon[20];
		GetClientWeapon(client,weapon,20);
		ReplaceString(weapon, 20, "weapon_", "");

		// get place name
		decl String:place[24];
		GetEntDataString(client, g_iOffsLastPlaceName, place, sizeof(place));

		new bool:Location = StrEqual(place, "", false);

		// log camping
		LogToGame("\"%s<%d><%s><%s>\" triggered \"camper\"",name,GetClientUserId(client),camperSteamID,camperTeam);

		// print to chat
		decl String:Saytext[192];
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(Saytext, sizeof(Saytext), "\x04[Anticamp]\x01 %T", "Player camping", i, name,weapon,place,YELLOW,TEAMCOLOR,YELLOW,GREEN,YELLOW,GREEN);

				if(Location)
					ReplaceString(Saytext, 192, "@", "");

				if(GetUserMessageType() == UM_Protobuf) {
					PbSayText2(i, client, true, Saytext, name);
				}else{
					SayText2(i, client, true, Saytext, name);
				}
			}
		}

		// reset camp counter
		g_timerCount[client] = 0;

		// start beacon timer
		if(GetConVarFloat(g_CvarPunishDelay) == GetConVarFloat(g_CvarPunishFreq))
			g_hPunishTimerList[client] = CreateTimer(GetConVarFloat(g_CvarPunishDelay), PunishTimer, client, TIMER_REPEAT);
		else if(GetConVarInt(g_CvarPunishDelay) <= 0)
		{
			g_hPunishTimerList[client] = CreateTimer(0.1, PunishTimer, client, TIMER_REPEAT);
			g_hDelayTimerList[client] = CreateTimer(0.1, PunishDelayTimer, client);
		}
		else
		{
			g_hPunishTimerList[client] = CreateTimer(GetConVarFloat(g_CvarPunishDelay), PunishTimer, client, TIMER_REPEAT);
			g_hDelayTimerList[client] = CreateTimer(GetConVarFloat(g_CvarPunishDelay), PunishDelayTimer, client);
		}

		// start camp timer
		KillTimer(g_hCampTimerList[client]);
		g_hCampTimerList[client] = CreateTimer(1.0, CamperTimer, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action:PunishDelayTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!g_bTeamsHaveAlivePlayers || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	KillTimer(g_hPunishTimerList[client]);
	g_hPunishTimerList[client] = CreateTimer(GetConVarFloat(g_CvarPunishFreq), PunishTimer, client, TIMER_REPEAT);
	g_hDelayTimerList[client] = INVALID_HANDLE;

	return Plugin_Handled;
}

public Action:CamperTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!g_bTeamsHaveAlivePlayers || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// check if still camping
	if(!IsCamping(client))
	{
		ResetTimer(client);
		g_hCampTimerList[client] = CreateTimer(NON_CAMPER_DELAY, CheckCamperTimer, client, TIMER_REPEAT);
	}

	return Plugin_Handled;
}

public Action:PunishTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!g_bTeamsHaveAlivePlayers || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// create a beam effect and the anathor one immediately after
	if(GetConVarBool(g_CvarBeacon))
	{
		new clientteam = GetClientTeam(client);

		if(clientteam == CS_TEAM_CT)
			BeamRing(client, g_iBRColorCT);
		else if(clientteam == CS_TEAM_T)
			BeamRing(client, g_iBRColorT);

		CreateTimer(0.2, BeaconTimer2, client);

		new Float:vecPos[3];
		GetClientAbsOrigin(client, vecPos);
		EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
	}

	new ClientHealth = GetClientHealth(client);
	new MinHealth = GetConVarInt(g_CvarMinHealth);

	// take player cash
	if(GetConVarInt(g_CvarTakeCash) > 0)
	{
		if(ClientHealth > MinHealth || GetConVarBool(g_CvarPunishAnyway))
		{
			new ClientCash = GetEntData(client, g_MoneyOffset);
			new MinCash = GetConVarInt(g_CvarMinCash);

			if(ClientCash > MinCash)
			{
				ClientCash -= GetConVarInt(g_CvarTakeCash);

				if(ClientCash > MinCash)
					SetEntData(client, g_MoneyOffset, ClientCash, 4, true);
				else
					SetEntData(client, g_MoneyOffset, MinCash, 4, true);
			}
		}
		else if(!GetConVarBool(g_CvarPunishAnyway))
			ResetTimer(client);
	}

	switch(GetConVarInt(g_CvarSlapSlay))
	{
		case 1:
		{
			// slap player
			new SlapDmg = GetConVarInt(g_CvarSlapDmg);

			if(ClientHealth > MinHealth)
			{
				ClientHealth -= SlapDmg;

				if(ClientHealth > MinHealth || MinHealth <= 0)
					SlapPlayer(client, SlapDmg, true);
				else
				{
					if(!GetConVarBool(g_CvarPunishAnyway))
						ResetTimer(client);

					SetEntityHealth(client, MinHealth);
					SlapPlayer(client, 0, true);
				}
			}
			else if(GetConVarBool(g_CvarPunishAnyway))
				SlapPlayer(client, 0, true);
		}
		case 2:
		{
			// slay player
			if(ClientHealth > MinHealth)
				ForcePlayerSuicide(client);
		}
	}

	// blind player
	if(GetConVarBool(g_CvarBlind) && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		ClientHealth = GetClientHealth(client);

		if(ClientHealth > MinHealth || GetConVarBool(g_CvarPunishAnyway))
		{
			PerformBlind(client, 255);
			g_bIsBlind[client] = true;
		}
		else if(!GetConVarBool(g_CvarPunishAnyway))
			ResetTimer(client);
	}

	return Plugin_Handled;
}

public Action:BeaconTimer2(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if(!g_bTeamsHaveAlivePlayers || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		ResetTimer(client);
		return Plugin_Handled;
	}

	// create beamring on client
	new clientteam = GetClientTeam(client);

	if(clientteam == CS_TEAM_CT)
		BeamRing(client, g_iBRColorCT);
	else if(clientteam == CS_TEAM_T)
		BeamRing(client, g_iBRColorT);

	return Plugin_Handled;
}

BeamRing(client, color[4])
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);

	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 20.0, 440.0, g_beamSprite, g_haloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
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

stock PbSayText2(client, author = 0, bool:bWantsToChat = false, const String:szFormat[], any:...)
{
	decl String:szSendMsg[192];
	VFormat(szSendMsg, sizeof(szSendMsg), szFormat, 5);
	StrCat(szSendMsg, sizeof(szSendMsg), "\n");

	new Handle:pb = StartMessageOne("SayText2", client);

	if (pb != INVALID_HANDLE) {
		PbSetInt(pb, "ent_idx", author);
		PbSetBool(pb, "chat", bWantsToChat);
		PbSetString(pb, "msg_name", szSendMsg);
		PbAddString(pb, "params", "");
		PbAddString(pb, "params", "");
		PbAddString(pb, "params", "");
		PbAddString(pb, "params", "");
		EndMessage();
	}
}

ResetTimer(client)
{
	if(g_bIsBlind[client])
	{
		PerformBlind(client, 0);
		g_bIsBlind[client] = false;
	}

	if(g_hPunishTimerList[client] != INVALID_HANDLE)
	{
		KillTimer(g_hPunishTimerList[client]);
		g_hPunishTimerList[client] = INVALID_HANDLE;
	}

	if(g_hCampTimerList[client] != INVALID_HANDLE)
	{
		KillTimer(g_hCampTimerList[client]);
		g_hCampTimerList[client] = INVALID_HANDLE;
	}

	if(g_hDelayTimerList[client] != INVALID_HANDLE)
	{
		KillTimer(g_hDelayTimerList[client]);
		g_hDelayTimerList[client] = INVALID_HANDLE;
	}
}

PerformBlind(target, amount)
{
	if(IsClientInGame(target))
	{
		new targets[2];
		targets[0] = target;
		
		new color[4] = { 0, 0, 0, 0 };
		color[0] = 0;
		color[1] = 0;
		color[2] = 0;
		color[3] = amount;
		
		new flags;
		if (amount == 0)
			flags = (0x0001 | 0x0010);
		else
			flags = (0x0002 | 0x0008);

		new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
		
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(message, "duration", 768);
			PbSetInt(message, "hold_time", 1536);
			PbSetInt(message, "flags", flags);
			PbSetColor(message, "clr", color);
		}
		else
		{
			BfWriteShort(message, 768);
			BfWriteShort(message, 1536);
			BfWriteShort(message, flags);
			BfWriteByte(message, color[0]);
			BfWriteByte(message, color[1]);
			BfWriteByte(message, color[2]);
			BfWriteByte(message, color[3]);
		}

		EndMessage();
	}
}