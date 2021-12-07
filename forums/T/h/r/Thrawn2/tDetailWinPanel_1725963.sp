#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>

#define VERSION 		"0.0.3"

enum TrackData {
	Damage,
	Healing,
	LifeTime,
	Kills,
	LastScore,
	Float:LastSpawn
}

new g_PlayerData[MAXPLAYERS+1][TrackData];

new bool:g_bSDKHooksAvailable = false;

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

public Plugin:myinfo = {
	name 		= "tDetailWinPanel",
	author 		= "Thrawn",
	description = "Uses the arena winpanel for standard rounds.",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tdetailwinpanel_version", VERSION, "Uses the arena winpanel for standard rounds.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if(LibraryExists("SDKHooks")) {
		g_bSDKHooksAvailable = true;
	}

	g_hCvarEnabled = CreateConVar("sm_tdetailwinpanel_enable", "1", "Enable tDetailWinPanel", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	HookEvent("teamplay_win_panel", Event_DefaultWinPanel, EventHookMode_Pre);

	// These are used for score tracking
	//HookEvent("stats_resetround", Event_RoundStart);
	HookEvent("teamplay_round_start", Event_RoundStart);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_healed", Event_PlayerHealed);

	if(g_bSDKHooksAvailable) {
		/* Account for late loading */
		for(new iClient = 1; iClient <= MaxClients; iClient++) {
			if(IsClientInGame(iClient)) {
				SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public OnLibraryAdded(const String:sLibrary[]) {
	if(StrEqual(sLibrary, "SDKHooks")) {
		g_bSDKHooksAvailable = true;
	}
}

public OnLibraryRemoved(const String:sLibrary[]) {
	if(StrEqual(sLibrary, "SDKHooks")) {
		g_bSDKHooksAvailable = false;
	}
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnMapStart() {
	ResetAllPlayers();
}

public OnClientDisconnect(iClient) {
	ResetPlayerData(iClient);
}

public OnClientPutInServer(iClient) {
	ResetPlayerData(iClient);

	if(g_bSDKHooksAvailable) {
    	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action:OnTakeDamage(iClient, &iAttacker, &inflictor, &Float:iDamage, &damagetype) {
	if(!g_bEnabled)return Plugin_Continue;

	if(iAttacker > 0 && iAttacker != iClient && IsClientInGame(iAttacker)) {
		g_PlayerData[iAttacker][Damage] += iDamage;
	}

	return Plugin_Continue;
}


public Event_PlayerHealed(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;
	if(g_bSDKHooksAvailable)return;

	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "healer"));
	new iAmount = GetEventInt(hEvent, "amount");

	if(iAttacker > 0 && IsClientInGame(iAttacker)) {
		g_PlayerData[iAttacker][Healing] += iAmount;
	}
}


public Event_PlayerHurt(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;
	if(g_bSDKHooksAvailable)return;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new iDamage = GetEventInt(hEvent, "damageamount");

	if(iAttacker > 0 && iAttacker != iClient && IsClientInGame(iAttacker)) {
		g_PlayerData[iAttacker][Damage] += iDamage;
	}
}

public Event_PlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	g_PlayerData[iClient][LastSpawn] = GetGameTime();
}

public Event_PlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	// Score the attacker a point
	if(iAttacker > 0 && iAttacker != iClient && IsClientInGame(iAttacker)) {
		g_PlayerData[iAttacker][Kills]++;
	}

	// Add the lifetime of the dead player to his total lifetime.
	if(g_PlayerData[iClient][LastSpawn] > 0.0) {
		g_PlayerData[iClient][LifeTime] += RoundFloat(GetGameTime() - g_PlayerData[iClient][LastSpawn]);
		g_PlayerData[iClient][LastSpawn] = 0.0;
	}
}

public Action:Event_RoundStart(Handle:hOld, const String:name[], bool:dontBroadcast) {
	if(!g_bEnabled)return;

	ResetAllPlayers();
}

public SortScoreDesc(x[], y[], array[][], Handle:data)      // this sorts everything in the info array descending
{
    if (x[1] > y[1])
        return -1;
    else if (x[1] < y[1])
        return 1;
    return 0;
}

public Action:Event_DefaultWinPanel(Handle:hOld, const String:name[], bool:dontBroadcast) {
	if(!g_bEnabled)return Plugin_Continue;

	new SortArray[MAXPLAYERS+1][2];
	for(new iClient = 1; iClient <= MaxClients; iClient++) {
		if(!IsClientInGame(iClient))continue;

		// Add remaining lifetime
		if(g_PlayerData[iClient][LastSpawn] > 0.0) {
			g_PlayerData[iClient][LifeTime] += RoundFloat(GetGameTime() - g_PlayerData[iClient][LastSpawn]);
			g_PlayerData[iClient][LastSpawn] = 0.0;
		}

		new iCurrentScore = TF2_GetPlayerResourceData(iClient, TFResource_TotalScore);

		// Calculate score difference
		SortArray[iClient][1] = iCurrentScore - g_PlayerData[iClient][LastScore];
		SortArray[iClient][0] = iClient;

		g_PlayerData[iClient][LastScore] = iCurrentScore;
	}

	SortCustom2D(SortArray, MAXPLAYERS+1, SortScoreDesc);

	new Handle:hNew = CreateEvent("arena_win_panel", true);
	CopyEventDataInt(hOld, hNew, "panel_style");
	CopyEventDataInt(hOld, hNew, "winning_team");
	CopyEventDataInt(hOld, hNew, "winreason");
	CopyEventDataString(hOld, hNew, "cappers");
	CopyEventDataInt(hOld, hNew, "flagcaplimit");
	CopyEventDataInt(hOld, hNew, "blue_score");
	CopyEventDataInt(hOld, hNew, "red_score");
	CopyEventDataInt(hOld, hNew, "blue_score_prev");
	CopyEventDataInt(hOld, hNew, "red_score_prev");
	CopyEventDataInt(hOld, hNew, "round_complete");

	new iRedMVPs = 0;
	new iBlueMVPs = 0;
	for(new iMVP = 0; iMVP < MAXPLAYERS+1; iMVP++) {
		new iClient = SortArray[iMVP][0];
		new iScore = SortArray[iMVP][1];

		if(iClient == 0)continue;
		if(!IsClientInGame(iClient))continue;
		if(iScore == 0)continue;

		new iTeam = GetClientTeam(iClient);
		switch(iTeam) {
			case 2: {	// Red
				if(iRedMVPs >= 3)continue;
				iRedMVPs++;
			}

			case 3: {	// Blue
				if(iBlueMVPs >= 3)continue;
				iBlueMVPs++;
			}

			default: {
				continue;
			}
		}

		SetEventPlayerScore(hNew, iRedMVPs+iBlueMVPs, iClient,
								  g_PlayerData[iClient][Damage],
								  g_PlayerData[iClient][Healing],
								  g_PlayerData[iClient][LifeTime],
								  g_PlayerData[iClient][Kills]);
	}

	// Set remaining slots to 0
	for (new iRank = iRedMVPs+iBlueMVPs+1; iRank <= 6; iRank++) {
		SetEventPlayerScore(hNew, iRank, 0, 0, 0, 0, 0);
	}

	FireEvent(hNew);

	return Plugin_Handled;
}

/*
 * Tracking
*/
ResetAllPlayers() {
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client)) {
			ResetPlayerData(client);
		}
	}
}

ResetPlayerData(iClient) {
	g_PlayerData[iClient][Damage] = 0;
	g_PlayerData[iClient][Healing] = 0;
	g_PlayerData[iClient][LifeTime] = 0;
	g_PlayerData[iClient][Kills] = 0;

	if(IsClientInGame(iClient)) {
		g_PlayerData[iClient][LastScore] = TF2_GetPlayerResourceData(iClient, TFResource_TotalScore);
	} else {
		g_PlayerData[iClient][LastScore] = 0;
	}
}


/*
 * Event creation
*/
SetEventPlayerScore(Handle:hEvent, iRank, iClient, iDamage, iHealing, iLifeTime, iKills) {
	if(iRank < 1 || iRank > 6) {
		return;
	}

	decl String:sPrefix[20];
	Format(sPrefix, sizeof(sPrefix), "player_%i", iRank);
	SetEventInt(hEvent, sPrefix, iClient);

	new String:sDamage[20];
	Format(sDamage, sizeof(sDamage), "%s_damage", sPrefix);
	SetEventInt(hEvent, sDamage, iDamage);

	new String:sHealing[20];
	Format(sHealing, sizeof(sHealing), "%s_healing", sPrefix);
	SetEventInt(hEvent, sHealing, iHealing);

	new String:sLifeTime[20];
	Format(sLifeTime, sizeof(sLifeTime), "%s_lifetime", sPrefix);
	SetEventInt(hEvent, sLifeTime, iLifeTime);

	new String:sKills[20];
	Format(sKills, sizeof(sKills), "%s_kills", sPrefix);
	SetEventInt(hEvent, sKills, iKills);
}

CopyEventDataInt(Handle:hOld, Handle:hNew, const String:sKey[]) {
	SetEventInt(hNew, sKey, GetEventInt(hOld, sKey));
}

CopyEventDataString(Handle:hOld, Handle:hNew, const String:sKey[]) {
	decl String:sTmp[512];
	GetEventString(hOld, sKey, sTmp, sizeof(sTmp));
	SetEventString(hNew, sKey, sTmp);
}