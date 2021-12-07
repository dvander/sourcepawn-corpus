/*
 * Anti-Camp-Pro v0.5
 * ==================
 * 
 * ################################################################################
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
 * 
 * ################################################################################ 
 * 
 * Powered by Den Grünes
 * Email: den_gruenes@gmx.de
 * 
 * Sourcemod:
 * 		2.1
 * 
 * Description:
 * 		Anticamppro plugin for Sourcemod. 
 * 		Detect camping players
 * 		
 * Versions:
 * 		0.1		First Release
 * 		0.2		Language phrases
 * 		0.3		Drop Weapons
 *		0.4		Spawn AFK detection
 * 		0.5		Disable map detection
 * 
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define YELLOW			 "\x01"
#define TEAMCOLOR		 "\x03"
#define GREEN			 "\x04"

#define NON_CAMPER_DELAY 1.0
#define CAMP_DELAY 1.0
#define BEACON_DELAY 2.0

#define CS_TEAM_NONE		0
#define CS_TEAM_SPECTATOR	1
#define CS_TEAM_T			2
#define CS_TEAM_CT			3

#define PLUGIN_VERSION "0.5"
#define DEBUG 0.0

// Plugin definitions
public Plugin:myinfo =
{
	name = "Anti Camp Pro CS:S",
	author = "Den Grünes (den_gruenes@gmx.de)",
	description = "Detects camping players",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};


#define NUM_PREFSOUND 2
#define DAMAGE 0
#define BEACON 1
new String:g_PrefSounds[NUM_PREFSOUND][PLATFORM_MAX_PATH];

// # timer lists
new Handle:g_TimerList[MAXPLAYERS + 1];
new Handle:g_BeaconList[MAXPLAYERS + 1];
new Handle:g_SpawnAfkList[MAXPLAYERS + 1];
new g_timerCount[MAXPLAYERS + 1];

// # internals
new Float:g_LastPosition[MAXPLAYERS + 1][3];
new bool:g_IsInCampArea[MAXPLAYERS + 1];
new bool:g_IsCamping[MAXPLAYERS + 1];
new Float:g_LastDistance[MAXPLAYERS + 1];
new bool:g_ClientSlapped[MAXPLAYERS + 1];
new Float:g_SpawnPosition[MAXPLAYERS + 1][3];

// # count events
new Float:g_timerBlindCount[MAXPLAYERS + 1];
new Float:g_timerSlapCount[MAXPLAYERS + 1];
new Float:g_timerDamageCount[MAXPLAYERS + 1];
new Float:g_timerBeaconCount[MAXPLAYERS + 1];
new Float:g_timerWeaponDropCount[MAXPLAYERS + 1];
new Float:g_timerSpawnAfkCount[MAXPLAYERS + 1];
new bool:g_SpawAfkTimerRun[MAXPLAYERS + 1];

// # map options (de or cs map)
new bool:g_IsCtMap = false;
new bool:g_IsTMap = false;


// # common
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarCampTime = INVALID_HANDLE;
new Handle:g_CvarDisplayCamper = INVALID_HANDLE;
new Handle:g_CvarRadius = INVALID_HANDLE;

// # damage
new Handle:g_CvarDamageTime = INVALID_HANDLE;
new Handle:g_CvarDamageAmount = INVALID_HANDLE;

// # slap
new Handle:g_CvarSlap = INVALID_HANDLE;
new Handle:g_CvarSlapTime = INVALID_HANDLE;
new Handle:g_CvarSlapAnyway = INVALID_HANDLE;

// # health
new Handle:g_CvarLowHealth = INVALID_HANDLE;

// # map options (de & cs maps)
new Handle:g_CvarAllowMapDetection = INVALID_HANDLE;
new Handle:g_CvarAllowTCampPlanted = INVALID_HANDLE;
new Handle:g_CvarAllowCtCampDropped = INVALID_HANDLE;

// # CT&T options
new Handle:g_CvarAllowTCamp = INVALID_HANDLE;
new Handle:g_CvarAllowCtCamp = INVALID_HANDLE;

// # blind
new Handle:g_CvarBlindEnable = INVALID_HANDLE;
new Handle:g_CvarBlindTime = INVALID_HANDLE;
new Handle:g_CvarBlindStart = INVALID_HANDLE;
new Handle:g_CvarBlindEnd = INVALID_HANDLE;
new Handle:g_CvarBlindMove = INVALID_HANDLE;

// # beacon
new Handle:g_CvarBeacon = INVALID_HANDLE;
new Handle:g_CvarBeaconTime = INVALID_HANDLE;

// # drop weapons
new Handle:g_CvarDropWeapon = INVALID_HANDLE;
new Handle:g_CvarDropWeaponPrimaryTime = INVALID_HANDLE;
new Handle:g_CvarDropWeaponSecondaryTime = INVALID_HANDLE;

// # spawn afk detection
new Handle:g_CvarSpawnAFK = INVALID_HANDLE;
new Handle:g_CvarSpawnAFKTime = INVALID_HANDLE;
new Handle:g_CvarSpawnAFKDropBombTime = INVALID_HANDLE;
new Handle:g_CvarSpawnAFKDropAllTime = INVALID_HANDLE;
new Handle:g_CvarSpawnAFKKillTime = INVALID_HANDLE;

// # beacon sprites
new g_beamSprite;
new g_haloSprite;

// # UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;

// # Last Placename
new g_OffsLastPlaceName = -1;

public OnPluginStart()
{
	CreateConVar("sm_anticamppro_version", PLUGIN_VERSION, "anticamp_css_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Enable Anti-Camp-Pro
	g_CvarEnable = CreateConVar("sm_anticamppro_enable", "1", "Set to 0 to disable anticamppro", 0, true, 0.0, true, 1.0);
	
	// Radius
	g_CvarRadius = CreateConVar("sm_anticamppro_radius", "120", "The radius to check for camping", 0, true, 50.0, true, 500.0);
	
	// Display Camp-Message
	g_CvarDisplayCamper = CreateConVar("sm_anticamppro_display", "center", "Display camper message to all (center/hint/chat/off)");
	
	// Start Anti-Camp-Time
	g_CvarCampTime = CreateConVar("sm_anticamppro_camptime", "15", "The amount of times a suspected camper is checked for", 0, true, 5.0, true, 60.0);
	
	// Beacon
	g_CvarBeacon = CreateConVar("sm_anticamppro_beacon", "1", "Set to 0 to disable beacons", 0, true, 0.0, true, 1.0);
	g_CvarBeaconTime = CreateConVar("sm_anticamppro_beacon_delay", "5", "Delay time to begin beacon", 0, true, 0.0, true, 30.0);
	
	// Blindness
	g_CvarBlindEnable = CreateConVar("sm_anticamppro_blind", "1", "Set to 0 to disable darkness", 0, true, 0.0, true, 1.0);
	g_CvarBlindTime = CreateConVar("sm_anticamppro_blind_delay", "5.0", "Set time for max blindness", 0, true, 5.0, true, 30.0);
	g_CvarBlindStart = CreateConVar("sm_anticamppro_blind_start", "90", "Begin blindness (percent-value)", 0, true, 0.0, true, 100.0);
	g_CvarBlindEnd = CreateConVar("sm_anticamppro_blind_end", "99.8", "End blindness (percent-value)", 0, true, 60.0, true, 100.0);
	g_CvarBlindMove = CreateConVar("sm_anticamppro_blind_move", "1", "Unblind to min-value by moving inside camp radius", 0, true, 0.0, true, 1.0);
	
	// Damage
	g_CvarDamageTime = CreateConVar("sm_anticamppro_damage_delay", "10", "Delay time to begin damage (set same slap time to slap with damage)", 0, true, 1.0, true, 30.0);
	g_CvarDamageAmount = CreateConVar("sm_anticamppro_damage_dmg", "3", "Amount of health decrease during camping every secound", 0, true, 0.0, true, 100.0);
	
	// Slap
	g_CvarSlap = CreateConVar("sm_anticamppro_slap", "1", "Set to 0 to disable slap", 0, true, 0.0, true, 1.0);
	g_CvarSlapTime = CreateConVar("sm_anticamppro_slap_delay", "20", "Delay time to begin slap (set same damage time to slap with damage)", 0, true, 1.0, true, 30.0);

	// Health Options
	g_CvarSlapAnyway = CreateConVar("sm_anticamppro_minhealth_camp", "1", "Set to 0 to allow camping below minhealth. Set to 1 to slap without damge", 0, true, 0.0, true, 1.0);
	g_CvarLowHealth = CreateConVar("sm_anticamppro_minhealth", "15", "Set to the minimum health a camper keep. Set to 0 to slap till dead", 0, true, 0.0, true, 100.0);
		
	// CT & T Options
	g_CvarAllowTCamp = CreateConVar("sm_anticamppro_t_camp", "1", "Set to 1 to allow camping for Ts on cs maps. Set to 0 to disable. Don´t work with *_zz_*", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCamp = CreateConVar("sm_anticamppro_ct_camp", "1", "Set to 1 to allow camping for CTs on de maps. Set to 0 to disable. Don´t work with *_zz_*", 0, true, 0.0, true, 1.0);
	
	// Map Options
	g_CvarAllowMapDetection = CreateConVar("sm_anticamppro_map_detection", "1", "Set to 1 to enable map detection. (usefull for zz maps if set to 0).", 0, true, 0.0, true, 1.0);
	g_CvarAllowTCampPlanted = CreateConVar("sm_anticamppro_t_camp_planted", "1", "Set to 1 to allow camping for Ts if bomb planted. Set to 0 to disable. Need map detection.", 0, true, 0.0, true, 1.0);
	g_CvarAllowCtCampDropped = CreateConVar("sm_anticamppro_ct_camp_dropped", "1", "Set to 1 to allow camping for CTs if bomb dropped. Is only needed if sm_anticamppro_ct_camp is 0. Need map detection.", 0, true, 0.0, true, 1.0);
	
	// Disable Map-Detection (Disabled CT&T-Map-Options)
	
	// Weapon drop
	g_CvarDropWeapon = CreateConVar("sm_anticamppro_weapon_drop", "1", "Set to 0 to disable weapon drop", 0, true, 0.0, true, 1.0);
	g_CvarDropWeaponPrimaryTime = CreateConVar("sm_anticamppro_weapon_drop_primary_delay", "8", "Delay time to drop primary weapon.", 0, true, 0.0, true, 120.0);
	g_CvarDropWeaponSecondaryTime = CreateConVar("sm_anticamppro_weapon_drop_secondary_delay", "15", "Delay time to drop secondary weapon.", 0, true, 0.0, true, 120.0);
	
	// Spawn AFK detection
	g_CvarSpawnAFK = CreateConVar("sm_anticamppro_spawn_afk", "1", "Set to 0 to disable spawn afk detection", 0, true, 0.0, true, 1.0);
	g_CvarSpawnAFKTime = CreateConVar("sm_anticamppro_spawn_afk_time", "5", "Begin afk timer", 0, true, 10.0, true, 120.0);
	g_CvarSpawnAFKDropBombTime = CreateConVar("sm_anticamppro_spawn_afk_dropbomb_delay", "1", "Delay time to drop bomb if terrorist. Set to 0 to disable", 0, true, 0.0, true, 120.0);
	g_CvarSpawnAFKDropAllTime = CreateConVar("sm_anticamppro_spawn_afk_dropall_delay", "15", "Delay time to drop all items, Set to 0 to disable.", 0, true, 0.0, true, 120.0);
	g_CvarSpawnAFKKillTime = CreateConVar("sm_anticamppro_spawn_afk_kill_delay", "30", "Delay time to kill player by slap (100% damage) on afk. Set to 0 to disable.", 0, true, 0.0, true, 120.0);
	
	// Register events
	HookEvent("player_spawn", eventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", eventPlayerDeath, EventHookMode_Post);
	HookEvent("bomb_planted", eventBombPlanted, EventHookMode_PostNoCopy);
	HookEvent("bomb_dropped", eventBombDropped, EventHookMode_PostNoCopy);
	HookEvent("bomb_pickup", eventBombPickup, EventHookMode_PostNoCopy);
	HookEvent("round_start", eventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", eventRoundEnd, EventHookMode_PostNoCopy);

	// Messages
	g_FadeUserMsgId = GetUserMessageId("Fade");
	g_OffsLastPlaceName = FindSendPropOffs("CBasePlayer", "m_szLastPlaceName");
	
	// Translation
	LoadTranslations("anticamppro.phrases");
 
	// Auto-generate config file
	AutoExecConfig(true, "anticamppro", "sourcemod");
	LoadConfig();
}

Debug(const String:msg[], any:client=-1)
{
	if (DEBUG == 1) {
		new String:out[255];
		Format(out, sizeof(out), "%s", msg);
		
		if (client == -1) {
			PrintToChatAll("[DEBUG] %s", out);
		} else if (client != -1 && IsClientConnected(client) && !IsFakeClient(client)) {
			decl String:name[32];
			decl String:txt[255];
			GetClientName(client, name, sizeof(name));
			
			Format(txt, sizeof(txt), "[%s] %s", name, out);
			PrintToChatAll("[DEBUG] %s", txt);
		}
	}
}

DefaultConfig()
{
	g_PrefSounds[DAMAGE] = "player/pl_pain5.wav";
	g_PrefSounds[BEACON] = "buttons/button17.wav";
}

LoadConfig()
{
	DefaultConfig();
	
	new Handle:kv = CreateKeyValues("anticamppro");
	new String:file[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "configs/anticamppro.txt");
	FileToKeyValues(kv, file);
	
	if (!KvGotoFirstSubKey(kv))
	{
		SetFailState("configs/anticamppro.txt not found or not correctly structured");
		CloseHandle(kv);
		return;
	}
	
	KvRewind(kv);
	if (KvJumpToKey(kv, "sounds", false)) {
		KvGetString(kv, "damage", g_PrefSounds[DAMAGE], PLATFORM_MAX_PATH, g_PrefSounds[DAMAGE]);
		KvGetString(kv, "beacon", g_PrefSounds[BEACON], PLATFORM_MAX_PATH, g_PrefSounds[BEACON]);
	}

	CloseHandle(kv);
}

PrintPlugin(any:client=INVALID_HANDLE)
{
	new String:msg[255];
	Format(msg, sizeof(msg), "%s v%s %s", "Anti-Camp-Professional", PLUGIN_VERSION,"by -=Den Gruenes=-");
	
	if (client != INVALID_HANDLE && IsClientInGame(client) && IsClientConnected(client)) {
		PrintHintText(client, msg);
	} else {
		PrintHintTextToAll(msg);
	}
}

PrintMessageAll(String:msg[])
{
	new String:mode[10];
	GetConVarString(g_CvarDisplayCamper, mode, sizeof(mode));

	if (StrEqual(mode, "hint")) {
		PrintHintTextToAll(msg);
	} else if (StrEqual(mode, "chat")) {
		PrintToChatAll(msg);
	} else if (StrEqual(mode, "center")) {
		PrintCenterTextAll(msg);
	}	
}

PrintCamper(client)
{
	Debug("Print Camper...");
	if (client) {
		
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		
		// get place name
		new String:place[24];
		GetEntDataString(client, g_OffsLastPlaceName, place, sizeof(place));
		
		if (!StrEqual(place, "")) {
			Format(place, sizeof(place), "(%s)", place);
		}
		
		// format message
		new String:msg[100];
		Format(msg, sizeof(msg), "%T", "Player camping", client, name, place, YELLOW, TEAMCOLOR, GREEN);
		
		PrintMessageAll(msg);
	}
	Debug("Print Camper end...");
}

PrintSpawnAfk(client)
{
	if (client) {
		
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		
		// format message
		new String:msg[100];
		Format(msg, sizeof(msg), "%T", "Player afk", client, name);
		
		PrintMessageAll(msg);
	}
}

PrepareSounds()
{
	for (new i = 0; i < NUM_PREFSOUND; i++) {
		if (!StrEqual(g_PrefSounds[i], "")) {
			PrecacheSound(g_PrefSounds[i], true);
		}
	}
}

PlaySound(client, sound)
{
	if (!StrEqual(g_PrefSounds[sound], "")) {
		new Float:current_position[3];
		GetClientAbsOrigin(client, current_position);
		EmitSoundToAll(g_PrefSounds[sound], client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, current_position, NULL_VECTOR, true, 0.0);
	}
}


PerformBlind(client, amount)
{
	new targets[2];
	targets[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0) {
		BfWriteShort(message, (0x0001 | 0x0010));
	} else {
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	
	EndMessage();
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

ClientReset(client, kill_timer=false)
{
	if (kill_timer) {
		// reset timers
		TimerReset(client);
	}
	
	// reset variables
	if (CheckClient(client)) {
		GetClientAbsOrigin(client, g_LastPosition[client]);
	}
	g_IsInCampArea[client] = false;
	g_IsCamping[client] = false;
	g_timerCount[client] = 0;
	g_timerBlindCount[client] = 0.0;
	g_LastDistance[client] = 0.0;
	g_timerSlapCount[client] = 0.0;
	g_timerDamageCount[client] = 0.0;
	g_timerBeaconCount[client] = 0.0;
	g_timerWeaponDropCount[client] = 0.0;
	g_timerSpawnAfkCount[client] = 0.0;
	g_SpawAfkTimerRun[client] = false;
	
	if (GetConVarBool(g_CvarBlindEnable)) {
		if (IsClientInGame(client) && IsClientConnected(client)) {
			// reset blindness
			PerformBlind(client, 0);
		}
	}
}

TimerReset(client)
{
	if (g_TimerList[client] != INVALID_HANDLE) {
		KillTimer(g_TimerList[client]);
		g_TimerList[client] = INVALID_HANDLE;
	}
	
	if (g_BeaconList[client] != INVALID_HANDLE) {
		KillTimer(g_BeaconList[client]);
		g_BeaconList[client] = INVALID_HANDLE;
	}
	
	if (g_SpawnAfkList[client] != INVALID_HANDLE) {
		KillTimer(g_SpawnAfkList[client]);
		g_SpawnAfkList[client] = INVALID_HANDLE;
	}
}

bool:IsInCampArea(client)
{
	new Float:CurrentPos[3];
	GetClientAbsOrigin(client, CurrentPos);

	if (GetVectorDistance(g_LastPosition[client], CurrentPos) < GetConVarInt(g_CvarRadius)) {
		if (!g_IsInCampArea[client])	{
			if (GetClientHealth(client) > GetConVarInt(g_CvarLowHealth) || GetConVarBool(g_CvarSlapAnyway))
				return true;
		}
	} else if (g_IsInCampArea[client]) {
		g_IsInCampArea[client] = false;
	}
	
	g_LastPosition[client] = CurrentPos;
	return false;
}

bool:IsCamping(any:client)
{
	if (CheckClient(client) && IsInCampArea(client)) {
		g_timerCount[client]++;
	} else {
		g_timerCount[client] = 0;
	}
	g_IsCamping[client] = (g_timerCount[client] > GetConVarInt(g_CvarCampTime));
	
	decl String:name[32];
	GetClientName(client, name, sizeof(name));
		
	decl String:txt[255];
	Format(txt, sizeof(txt), "Name: %s - Client: %d | Time: %d > Camptime: %d = Execute: %d", name, client,g_timerCount[client], GetConVarInt(g_CvarCampTime), g_IsCamping[client]);
	Debug(txt, client);
	
	return g_IsCamping[client];
}

bool:CheckClient(client)
{
	return (client && IsClientInGame(client) && IsClientConnected(client) && IsPlayerAlive(client));
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
			{
				alivect++;
			}
			else if(team == 2)
			{
				alivet++;
			}
		}
	}
	
	if(alivect > 0 && alivet > 0)
	{
		return true;
	}
	else
	{
		return false;
	}	
}


public OnMapStart()
{
	// Check map class
	g_IsCtMap = false;
	g_IsTMap  = false;
	
	// beacon sound
	PrecacheSound("buttons/button17.wav",true);

	// beacon sprites
	g_beamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	if (FindEntityByClassname(-1, "func_hostage_rescue") != -1) {
		g_IsCtMap = true;
	}
	
	if (FindEntityByClassname(-1, "func_bomb_target") != -1) {
		g_IsTMap = true;
	}
	
	PrepareSounds();
}

public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
}

public Action:eventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{	
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// get the client team
	new clientteam = GetClientTeam(client);

	// return if new client
	if (clientteam == CS_TEAM_NONE)	{
		return Plugin_Continue;
	}

	// check to see if there is an outstanding handle from last round
	TimerReset(client);
	
	// reset client vars
	ClientReset(client);
	
	// reset caught timer
	g_timerCount[client] = 0;	

	// spawn afk detection enabled
	if (GetConVarBool(g_CvarSpawnAFK)) {
		
		// reduce distance by player falling on spawn
		CreateTimer(0.5, timerSpawnPosition, client, TIMER_REPEAT);
		
		// init afk timer
		new Float:afk_time = GetConVarFloat(g_CvarSpawnAFKTime);
		g_SpawnAfkList[client] = CreateTimer(afk_time, timerCheckSpawnAfk, client, TIMER_REPEAT);
	}	
	
	// anti camp enabled
	if (!GetConVarBool(g_CvarEnable)) {
		return Plugin_Continue;
	}
	
	// print plugin message
	CreateTimer(2.5, timerPrintPlugin, client, TIMER_REPEAT);	
	
	// Allow camping for t on cs maps
	if (g_IsCtMap && GetConVarBool(g_CvarAllowMapDetection) && clientteam == CS_TEAM_T && GetConVarBool(g_CvarAllowTCamp))	{
		return Plugin_Continue;
	}
	
	// Allow camping for ct on de maps
	if (g_IsTMap && GetConVarBool(g_CvarAllowMapDetection) && clientteam == CS_TEAM_CT && GetConVarBool(g_CvarAllowCtCamp)) {
		return Plugin_Continue;
	}

	
	// get the players position and start the timing cycle
	g_TimerList[client] = CreateTimer(NON_CAMPER_DELAY, timerCheckClient, client, TIMER_REPEAT);
	
	return Plugin_Continue;
}

public Action:eventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	ClientReset(client, true);
}

public Action:eventBombPlanted(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarBool(g_CvarAllowMapDetection)) {
		#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
			new MaxClients = GetMaxClients();
		#endif
		
		new teamindex;

		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				teamindex = GetClientTeam(i);
				if (teamindex == CS_TEAM_T && GetConVarBool(g_CvarAllowTCampPlanted)) {
					ClientReset(i, true);
				} else if (teamindex == CS_TEAM_CT && g_TimerList[i] == INVALID_HANDLE)	{
					GetClientAbsOrigin(i, g_LastPosition[i]);
					g_TimerList[i] = CreateTimer(NON_CAMPER_DELAY, timerCheckClient, i, TIMER_REPEAT);
				}
			}
		}
	}
}

public Action:eventBombPickup(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarBool(g_CvarAllowCtCampDropped) && !GetConVarBool(g_CvarAllowCtCamp) && GetConVarBool(g_CvarAllowMapDetection)) {
		#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
			new MaxClients = GetMaxClients();
		#endif

		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && g_TimerList[i] == INVALID_HANDLE) {
				GetClientAbsOrigin(i, g_LastPosition[i]);
				g_TimerList[i] = CreateTimer(NON_CAMPER_DELAY, timerCheckClient, i, TIMER_REPEAT);
			}
		}
	}
	return Plugin_Continue;
}

public Action:eventBombDropped(Handle:event,const String:name[],bool:dontBroadcast)
{
	if ((GetConVarBool(g_CvarAllowCtCampDropped) || GetConVarBool(g_CvarAllowCtCamp)) && GetConVarBool(g_CvarAllowMapDetection)) {	
		#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 1
			new MaxClients = GetMaxClients();
		#endif
  
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && g_TimerList[i] != INVALID_HANDLE) {
				ClientReset(i, true);
			}
		}
	}
	return Plugin_Continue;
}

public Action:eventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
}

public Action:timerCheckClient(Handle:timer, any:client)
{
	if (!CheckClient(client) || !CheckAliveTeams())	{
		TimerReset(client);
		return Plugin_Handled;
	}
	
	if (IsCamping(client)) {
		Debug("IsCamping timer...", client);
		KillTimer(timer);
		g_TimerList[client] = CreateTimer(CAMP_DELAY, timerCampingClient, client, TIMER_REPEAT);
		PrintCamper(client);
	}
	return Plugin_Handled;
}

public Action:timerCampingClient(Handle:timer, any:client)
{
	if (!CheckClient(client)) {
		ClientReset(client, true);
		return Plugin_Handled;
	}
	
	if (IsCamping(client)) {
		// get client position
		new Float:CurrentPos[3];
		GetClientAbsOrigin(client, CurrentPos);
		
		// get client name
		decl String:name[32];
		GetClientName(client, name, sizeof(name));
		
		// distance to last position
		new Float:distance = GetVectorDistance(g_LastPosition[client], CurrentPos);

		// ################
		// # Blind Camper #
		// ################
		if (GetConVarBool(g_CvarBlindEnable)) {

			// current time 
			new Float:current_timer = g_timerBlindCount[client]++;
			// time for max blindness
			new Float:end_timer = GetConVarFloat(g_CvarBlindTime);
			// percent value of blindness
			new Float:percent_blindness = ((current_timer / end_timer) * 100);
			// get blindness start value
			new Float:blind_start = GetConVarFloat(g_CvarBlindStart);
			// get blindness end value
			new Float:blind_end = GetConVarFloat(g_CvarBlindEnd);
			// calculate delta of blindness
			new Float:blind_delta = ((blind_end - blind_start) / 100);
			// movearea
			new Float:movearea = 10.0;
			
			// check client is moving
			new Float:dist_delta = FloatAbs(distance-(g_LastDistance[client]));
			if (GetConVarBool(g_CvarBlindMove)) {
				if ((dist_delta > movearea || g_LastDistance[client] == 0) && !g_ClientSlapped[client]){
					g_LastDistance[client] = distance;
					PerformBlind(client, 0);
				}
			}
			
			// percent value overflow check
			if (percent_blindness > 100) {
				percent_blindness = Float:100.0;
			}
			
			// blindness value (0-255)
			new blindness = RoundToFloor((blind_start + (blind_delta * percent_blindness))*2.55);
			
			PerformBlind(client, blindness);
		}
		
		// ######################
		// # Slap/Damage Camper #
		// ######################
		
		// get slap time
		new Float:slap_time = GetConVarFloat(g_CvarSlapTime);
		// get damage time delay
		new Float:dmg_time = GetConVarFloat(g_CvarDamageTime);
		// get client health
		new client_health = GetClientHealth(client);
		// get min health damage
		new low_health = GetConVarInt(g_CvarLowHealth);
		// get damage amount
		new dmg_amount = GetConVarInt(g_CvarDamageAmount);
		// get slap time delay and increment
		new Float:slap_count = g_timerSlapCount[client]++;
		// get damage time delay and increment
		new Float:dmg_count = g_timerDamageCount[client]++;
		
		// check client health and damange > slap
		if (client_health > low_health) {	
			client_health -= dmg_amount;
			if (client_health > low_health || low_health <= 0) {
				if (GetConVarBool(g_CvarSlap) && slap_count > slap_time) {
					SlapPlayer(client, dmg_amount, true);
				} else if (dmg_count > dmg_time) {
					SetEntityHealth(client, client_health);
					PlaySound(client, DAMAGE);
				}
			} else 	if (GetConVarBool(g_CvarSlapAnyway)) {
				SetEntityHealth(client, low_health);
				if (GetConVarBool(g_CvarSlap) && slap_count > slap_time) {
					SlapPlayer(client, 0, true);
				} else if (dmg_count > dmg_time) {
					PlaySound(client, DAMAGE);
				}
			}
		} else if (GetConVarBool(g_CvarSlap) && slap_count > slap_time) {
			SlapPlayer(client, 0, true);
		} else if (dmg_count > dmg_time) {
			PlaySound(client, DAMAGE);
		}
		
		if (GetConVarBool(g_CvarSlap) && slap_count > slap_time) {
			g_ClientSlapped[client] = true;
			// get position after slap
			CreateTimer(0.25, timerEventSlapPosition, client, TIMER_REPEAT);
		}
		
		// #################
		// # Beacon camper #
		// #################
		if (GetConVarBool(g_CvarBeacon)) {
			new Float:beacon_time  = GetConVarFloat(g_CvarBeaconTime);
			new Float:beacon_count = g_timerBeaconCount[client]++;
			if (beacon_count > beacon_time) {
				PlaySound(client, BEACON);
				if (g_BeaconList[client] == INVALID_HANDLE) {
					g_BeaconList[client] = CreateTimer(0.2, timerBeaconRing, client, TIMER_REPEAT);
				}
			}
		}
		
		// ################
		// # Drop weapons #
		// ################
		if (GetConVarBool(g_CvarDropWeapon)) {
			new Float:weapon_primary_time = GetConVarFloat(g_CvarDropWeaponPrimaryTime);
			new Float:weapon_secondary_time = GetConVarFloat(g_CvarDropWeaponSecondaryTime);
			new Float:weapon_count = g_timerWeaponDropCount[client]++;
			
			if (weapon_count >= weapon_primary_time && weapon_count <= (weapon_primary_time+1)) {
				ClientCommand(client, "slot1; wait; wait; drop");
			}
			if (weapon_count >= weapon_secondary_time && weapon_count <= (weapon_secondary_time+1)) {
				ClientCommand(client, "slot2; wait; wait; drop");
			}			
		}
	} else {
		if (GetConVarBool(g_CvarBlindEnable)) {
			// reset blindness
			PerformBlind(client, 0);
			// reset last distance
			g_LastDistance[client] = 0.0;
			// reset blind timer
			g_timerBlindCount[client] = 0.0;
			// reset slap
			g_ClientSlapped[client] = false;
		}
		
		if (GetConVarBool(g_CvarSlap)) {
			// reset slap timer
			g_timerSlapCount[client] = 0.0;
			// reset slap
			g_ClientSlapped[client] = false;
		}
		
		g_timerDamageCount[client] = 0.0;
		g_timerSlapCount[client] = 0.0;
		g_timerWeaponDropCount[client] = 0.0;
		
		// reset timer
		TimerReset(client);
		g_TimerList[client] = CreateTimer(NON_CAMPER_DELAY, timerCheckClient, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action:timerEventSlapPosition(Handle:timer, any:client)
{
	// store client position and distance after slapping, to beware camp radius.
	if (CheckClient(client)) {
		// get client position
		new Float:CurrentPos[3];
		GetClientAbsOrigin(client, CurrentPos);

		// set new position
		g_LastPosition[client] = CurrentPos;
		
		// Set new last distance
		g_LastDistance[client] = GetVectorDistance(g_LastPosition[client], CurrentPos);
	}
	KillTimer(timer);
}

public Action:timerBeaconRing(Handle:timer, any:client)
{
	// check to make sure the client is still connected and there are players in both teams
	if (!CheckClient(client) || !CheckAliveTeams()) {
		ClientReset(client, true);
		return Plugin_Handled;
	}
	
	// create beamring on client
	new colort[] = {150, 0, 0, 255};
	new colorct[] = {0, 0, 150, 255};
	
	// client team
	new clientteam = GetClientTeam(client);
	
	// check team and make colored beacon
	if (clientteam == CS_TEAM_CT) {
		BeamRing(client, colorct);
	} else if (clientteam == CS_TEAM_T) {
		BeamRing(client, colort);
	}
	return Plugin_Handled;
}

public Action:timerPrintPlugin(Handle:timer, any:client)
{
	// display plugin message
	if (CheckClient(client)) {
		PrintPlugin(client);
	}
	KillTimer(timer);
}

public Action:timerSpawnPosition(Handle: timer, any:client)
{
	// store current spawn client position
	if (CheckClient(client)) {
		GetClientAbsOrigin(client, g_SpawnPosition[client]);
	}
	KillTimer(timer);
}

public Action:timerCheckSpawnAfk(Handle: timer, any:client)
{
	// check client
	if (!CheckClient(client)) {
		// kill timer
		KillTimer(timer);
		g_SpawnAfkList[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	// get client position
	new Float:current_position[3];
	GetClientAbsOrigin(client, current_position);
	
	// calculate distance 
	new Float:distance = GetVectorDistance(g_SpawnPosition[client], current_position);
	
	if (distance < Float:10.0) {
		
		if (!g_SpawAfkTimerRun[client]) {
			// renew timer to one times
			g_SpawAfkTimerRun[client] = true;
			g_SpawnAfkList[client] = CreateTimer(1.0, timerCheckSpawnAfk, client, TIMER_REPEAT);
			
			// display message
			PrintSpawnAfk(client);
		}
		
		// get and increment count
		new Float:count     = g_timerSpawnAfkCount[client]++;
		// get 'drop all' time delay
		new Float:drop_time = GetConVarFloat(g_CvarSpawnAFKDropAllTime);
		// get 'kill' time delay
		new Float:kill_time = GetConVarFloat(g_CvarSpawnAFKKillTime);
		// get 'drop bomb' time delay
		new Float:bomb_time = GetConVarFloat(g_CvarSpawnAFKDropBombTime);
		
		// drop bomb
		if (count == bomb_time || count == drop_time) {
			// get the client team
			new clientteam = GetClientTeam(client);
			
			if (clientteam == CS_TEAM_T) {
				// drop bomb
				ClientCommand(client, "slot5; wait; wait; wait; wait; drop; wait; wait; wait; wait");
			}
		}
		
		// drop all items
		if (count == drop_time) {
			// drop primary weapon
			ClientCommand(client, "slot1; wait; wait; wait; wait; drop; wait; wait; wait; wait");
			
			// drop secondary weapom
			ClientCommand(client, "slot2; wait; wait; wait; wait; drop; wait; wait; wait; wait");
		}
		
		// kill player
		if (count == kill_time) {
			// kill
			SlapPlayer(client, 100, true);
			
			// kill timer
			KillTimer(timer);
			g_SpawnAfkList[client] = INVALID_HANDLE;
		}
	} else {
		// kill timer
		KillTimer(timer);
		g_SpawnAfkList[client] = INVALID_HANDLE;
	}
	return Plugin_Handled;
}