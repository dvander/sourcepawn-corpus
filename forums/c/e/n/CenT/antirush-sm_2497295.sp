#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>

#define PLUGIN_VERSION "1.5"
// 1.3a TnT removed printing RUSH info to players
// 1.4 	Added support for Warmup time and Workshop maps.
// 1.4a Disabled showing fences during warmup if convar is set to 0.
// 1.5 https://forums.alliedmods.net/showpost.php?p=2497295&postcount=168
#define NO_POINT 0
#define FIRST_POINT 1
#define SECOND_POINT 2

#define TYPE_ZONE 1
#define TYPE_FENCE 2

#define PREFIX "\x04Anti Rush \x01> \x03"

new Handle:g_hZones;
new Handle:g_hFences;

new g_iPlayerEditsType[MAXPLAYERS+2] = {-1,...};

new g_iPlayerCreatesZoneFence[MAXPLAYERS+2] = {NO_POINT,...};
new bool:g_bPlayerPressesUse[MAXPLAYERS+2] = {false,...};
new bool:g_bPlayerNamesNewZone[MAXPLAYERS+2] = {false,...};
new bool:g_bPlayerRenamesZone[MAXPLAYERS+2] = {false,...};
new bool:g_bPlayerIsRushing[MAXPLAYERS+2] = {false,...};

new g_iPlayerEditsZone[MAXPLAYERS+2] = {-1,...};
new g_iPlayerEditsVector[MAXPLAYERS+2] = {-1,...};

new Float:g_fTempZoneVector1[MAXPLAYERS+2][3];
new Float:g_fTempZoneVector2[MAXPLAYERS+2][3];

new g_iLaserMaterial = -1;
new g_iHaloMaterial = -1;
new g_iGlowSprite = -1;

new bool:g_bIsRushAllowed = false;
new Handle:g_hAllowRushingTimer = INVALID_HANDLE;
new Handle:g_hShowFencesTimer = INVALID_HANDLE;
new g_iTeamZones[2];

new Handle:g_hCVEnable;
new Handle:g_hCVNoRushTime;
new Handle:g_hCVPunishment;
new Handle:g_hCVLastManRushing;
new Handle:g_hCVOneOnOneRushing;
new Handle:g_hCVAdminImmunity;
new Handle:g_hCVFenceColor;
new Handle:g_hCVFenceColorWhenAllowed;
new Handle:g_hCVShowZones;
new Handle:g_hCVShowFencesWhenAllowed;
new Handle:g_hCVWarmupEnable;
new Handle:g_hCVFreezeTime;

public Plugin:myinfo = 
{
	name = "Anti Rush",
	author = "Jannik 'Peace-Maker' Hartung, Wilczek, CenT",
	description = "Defines zones where players aren't allowed to enter until a time has passed",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/, http://g4g.pl"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SDKHook");
	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_antirush_version", PLUGIN_VERSION, "Anti Rush Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	LoadTranslations("antirush.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("nextmap.phrases");
	LoadTranslations("playercommands.phrases");
	
	g_hCVEnable = CreateConVar("sm_antirush_enable", "1", "Enable Anti Rush?", 0, true, 0.0, true, 1.0);
	g_hCVNoRushTime = CreateConVar("sm_antirush_norushtime", "120", "Time in seconds rushing is not allowed after round start?", 0, true, 0.0, true, 530.0);
	g_hCVPunishment = CreateConVar("sm_antirush_punishment", "2", "How should the plugin handle players who enter defined zones by default? 1: Announce in chat, 2: Bounce back, 3: Slay, 4: Only knife, 5: Allow all weapons again", 0, true, 1.0, true, 5.0);
	g_hCVLastManRushing = CreateConVar("sm_antirush_lastmanrushing", "1", "Allow rushing if there is only one player left alive in a team.", 0, true, 0.0, true, 1.0);
	g_hCVOneOnOneRushing = CreateConVar("sm_antirush_oneononerushing", "0", "Allow rushing if there is only one player left alive in BOTH teams.", 0, true, 0.0, true, 1.0);
	g_hCVAdminImmunity = CreateConVar("sm_antirush_adminimmunity", "0", "Should admins be allowed to rush?", 0, true, 0.0, true, 1.0);
	g_hCVFenceColor = CreateConVar("sm_antirush_fencecolor", "255 0 0 255", "Which color should the fences have? RGBA: red green blue alpha", 0);
	g_hCVFenceColorWhenAllowed = CreateConVar("sm_antirush_fencecolor_allowed", "0 255 0 255", "Which color should the fences have when rushing is allowed? RGBA: red green blue alpha", 0);
	g_hCVShowZones = CreateConVar("sm_antirush_showzones", "1", "Show the zones either when rushing is not allowed?", 0, true, 0.0, true, 1.0);
	g_hCVShowFencesWhenAllowed = CreateConVar("sm_antirush_fence_allowed", "1", "Should fences be displayed when rushing is allowed?", 0, true, 0.0, true, 1.0);
	g_hCVWarmupEnable = CreateConVar("sm_antirush_enable_at_warmup", "0", "Should antirush be active during warmup", 0, true, 0.0, true, 1.0);
	
	g_hZones = CreateArray();
	g_hFences = CreateArray();
	
	RegConsoleCmd("say", Command_ChatHook);
	RegConsoleCmd("say_team", Command_ChatHook);
	
	HookEvent("bullet_impact", Event_OnBulletImpact);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("round_end", Event_OnRoundEnd);
	
	// Hook CS:S specific events
	decl String:sGameMod[64];
	GetGameFolderName(sGameMod, sizeof(sGameMod));
	if((StrContains(sGameMod, "cstrike", false) != -1) || (StrContains(sGameMod, "csgo", false) != -1)) 
	{
		HookEvent("bomb_planted", Event_OnBombPlanted);
		HookEvent("hostage_follows", Event_OnHostageFollows);
	}
	
	g_hCVFreezeTime = FindConVar("mp_freezetime");
	
	RegAdminCmd("sm_zones", Command_SetupZones, ADMFLAG_CONFIG, "Sets up anti rush zones");
	
	AutoExecConfig(true, "plugin.antirush");
}

/**
 * Events
 */
public OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo.vmt");
	g_iGlowSprite = PrecacheModel("sprites/blueglow1.vmt", true);
	
	PrecacheModel("models/items/car_battery01.mdl", true);
	
	ParseZoneConfig();
}

public OnMapEnd()
{
	if(g_hAllowRushingTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAllowRushingTimer);
		g_hAllowRushingTimer = INVALID_HANDLE;
	}
	
	if(g_hShowFencesTimer != INVALID_HANDLE)
	{
		KillTimer(g_hShowFencesTimer);
		g_hShowFencesTimer = INVALID_HANDLE;
	}
}

public OnClientPutInServer(client)
{
	// Optionally hook some weapon forwards for knife only punishment
	SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_BlockWeapon);
	SDKHook(client, SDKHook_WeaponEquip, Hook_BlockWeapon);
	SDKHook(client, SDKHook_WeaponCanUse, Hook_BlockWeapon);
}

public OnClientDisconnect(client)
{
	g_iPlayerEditsType[client] = -1;
	g_iPlayerCreatesZoneFence[client] = NO_POINT;
	g_iPlayerEditsZone[client] = -1;
	g_iPlayerEditsVector[client] = -1;
	
	g_bPlayerPressesUse[client] = false;
	g_bPlayerNamesNewZone[client] = false;
	g_bPlayerRenamesZone[client] = false;
	
	g_bPlayerIsRushing[client] = false;
}

// When adding a new zone, players can push +use to save a location at their feet
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_USE)
	{
		if(!g_bPlayerPressesUse[client] && g_iPlayerCreatesZoneFence[client] != NO_POINT)
		{
			new Float:fOrigin[3];
			GetClientAbsOrigin(client, fOrigin);
			
			// Player is creating a zone
			if(g_iPlayerCreatesZoneFence[client] == FIRST_POINT)
			{
				g_fTempZoneVector1[client][0] = fOrigin[0];
				g_fTempZoneVector1[client][1] = fOrigin[1];
				g_fTempZoneVector1[client][2] = fOrigin[2];
				g_iPlayerCreatesZoneFence[client] = SECOND_POINT;
				if(g_iPlayerEditsType[client] == TYPE_FENCE)
					PrintToChat(client, "%s%t", PREFIX, "Shoot Fence End");
				else
					PrintToChat(client, "%s%t", PREFIX, "Shoot Zone Edge");
			}
			else if(g_iPlayerCreatesZoneFence[client] == SECOND_POINT)
			{
				g_fTempZoneVector2[client][0] = fOrigin[0];
				g_fTempZoneVector2[client][1] = fOrigin[1];
				g_fTempZoneVector2[client][2] = fOrigin[2];
				g_iPlayerCreatesZoneFence[client] = NO_POINT;
				g_bPlayerNamesNewZone[client]= true;
				if(g_iPlayerEditsType[client] == TYPE_FENCE)
					PrintToChat(client, "%s%t", PREFIX, "Type Fence Name");
				else
					PrintToChat(client, "%s%t", PREFIX, "Type Zone Name");
			}
		}
		g_bPlayerPressesUse[client] = true;
	}
	else
	{
		g_bPlayerPressesUse[client] = false;
	}
	return Plugin_Continue;
}

// When adding a new zone, player shots are saved as positions
public Action:Event_OnBulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:x = GetEventFloat(event, "x");
	new Float:y = GetEventFloat(event, "y");
	new Float:z = GetEventFloat(event, "z");
	
	// Player is creating a zone
	if(g_iPlayerCreatesZoneFence[client] == FIRST_POINT)
	{
		g_fTempZoneVector1[client][0] = x;
		g_fTempZoneVector1[client][1] = y;
		g_fTempZoneVector1[client][2] = z;
		g_iPlayerCreatesZoneFence[client] = SECOND_POINT;
		if(g_iPlayerEditsType[client] == TYPE_FENCE)
			PrintToChat(client, "%s%t", PREFIX, "Shoot Fence End");
		else
			PrintToChat(client, "%s%t", PREFIX, "Shoot Zone Edge");
	}
	else if(g_iPlayerCreatesZoneFence[client] == SECOND_POINT)
	{
		g_fTempZoneVector2[client][0] = x;
		g_fTempZoneVector2[client][1] = y;
		g_fTempZoneVector2[client][2] = z;
		g_iPlayerCreatesZoneFence[client] = NO_POINT;
		g_bPlayerNamesNewZone[client]= true;
		if(g_iPlayerEditsType[client] == TYPE_FENCE)
			PrintToChat(client, "%s%t", PREFIX, "Type Fence Name");
		else
			PrintToChat(client, "%s%t", PREFIX, "Type Zone Name");
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bIsRushAllowed || GetArraySize(g_hZones) == 0 || !GetConVarBool(g_hCVEnable))
	return Plugin_Handled;
	
	if(g_hAllowRushingTimer != INVALID_HANDLE)
	{
		TriggerTimer(g_hAllowRushingTimer);
	}
	
	return Plugin_Handled;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Allow rushing by default
	g_bIsRushAllowed = true;
	
	if(g_hAllowRushingTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAllowRushingTimer);
		g_hAllowRushingTimer = INVALID_HANDLE;
	}
	
	if(g_hShowFencesTimer != INVALID_HANDLE)
	{
		KillTimer(g_hShowFencesTimer);
		g_hShowFencesTimer = INVALID_HANDLE;
	}
	
	// First remove any old zone triggers
	new iEnts = GetMaxEntities();
	decl String:sClassName[64];
	for(new i=MaxClients;i<iEnts;i++)
	{
		if(IsValidEntity(i)
		&& IsValidEdict(i)
		&& GetEdictClassname(i, sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "trigger_multiple") != -1
		&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "sm_zone") != -1)
		{
			AcceptEntityInput(i, "Kill");
		}
	}
	
	// Stop here, if we aren't enabled
	if(!GetConVarBool(g_hCVEnable))
		return Plugin_Continue;
	
	// Create triggers to check, if player touches the zone.
	new iSize = GetArraySize(g_hZones);
	for(new i=0;i<iSize;i++)
	{
		SpawnTriggerMultipleInBox(i);
	}
	
	// Disallow rushing and show the fences, if there are zones defined on this map
	new Float:fNoRushTime = GetConVarFloat(g_hCVNoRushTime);
	if(fNoRushTime >= 0.0 && GetArraySize(g_hZones) > 0)
	{
		if(fNoRushTime == 0){
			g_bIsRushAllowed = false;
			g_hShowFencesTimer = CreateTimer(1.0, Timer_ShowFenceBeams, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			return Plugin_Continue;
		}
		
		new iTeam1Count = GetTeamClientCountAlive(2);
		new iTeam2Count = GetTeamClientCountAlive(3);
		// Last man rushing and only one player in a team already?
		if((GetConVarBool(g_hCVLastManRushing) && (iTeam1Count == 1 || iTeam2Count == 1))
		// One on One rushing allowed and there is only 1 player alive in both teams?
		|| (GetConVarBool(g_hCVOneOnOneRushing) && (iTeam1Count == 1 && iTeam2Count == 1)))
		{
			return Plugin_Continue;
		}
		
		// Take mp_freezetime into account
		new Float:fFreezeTime;
		if(g_hCVFreezeTime != INVALID_HANDLE)
			fFreezeTime = GetConVarFloat(g_hCVFreezeTime);
		
		g_bIsRushAllowed = false;
		g_hAllowRushingTimer = CreateTimer(fNoRushTime+fFreezeTime, Timer_OnAllowRushing, _, TIMER_FLAG_NO_MAPCHANGE);
		g_hShowFencesTimer = CreateTimer(1.0, Timer_ShowFenceBeams, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		
		// First team
		//if(g_iTeamZones[0] == 0)
		//	PrintToChatTeam(2, "%s%t", PREFIX, "T Allowed");
		//else
		//	PrintToChatTeam(2, "%s%t", PREFIX, "T Disallowed", RoundToCeil(fNoRushTime));
		
		//if(g_iTeamZones[1] == 0)
		//	PrintToChatTeam(3, "%s%t", PREFIX, "CT Allowed");
		//else
		//	PrintToChatTeam(3, "%s%t", PREFIX, "CT Disallowed", RoundToCeil(fNoRushTime));
	}
	
	return Plugin_Continue;
}

// Reset rushers
public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bPlayerIsRushing[client] = false;
}

// Check for last man in one team or one on one
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bPlayerIsRushing[client] = false;
	
	if(g_bIsRushAllowed || GetArraySize(g_hZones) == 0 || !GetConVarBool(g_hCVEnable))
		return Plugin_Handled;
	
	// This is a bit cs:s specific, but i think teams 2 and 3 are used in multiple mods?
	new iTeam1Count = GetTeamClientCountAlive(2);
	new iTeam2Count = GetTeamClientCountAlive(3);
	
	
	// Allow rushing if there is only one player left in a team
	if((GetConVarBool(g_hCVLastManRushing) && (iTeam1Count == 1 || iTeam2Count == 1))
	// One on One rushing allowed and there is only 1 player alive in both teams?
	|| (GetConVarBool(g_hCVOneOnOneRushing) && (iTeam1Count == 1 && iTeam2Count == 1)))
	{
		if(g_hAllowRushingTimer != INVALID_HANDLE)
		{
			TriggerTimer(g_hAllowRushingTimer);
		}
	}
	
	return Plugin_Handled;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new oldteam = GetEventInt(event, "oldteam");
	
	if(g_bIsRushAllowed || GetArraySize(g_hZones) == 0 || !GetConVarBool(g_hCVEnable))
		return Plugin_Handled;
	
	if(team < 2 && oldteam < 2)
		return Plugin_Handled;
	
	// This is a bit cs:s specific, but i think teams 2 and 3 are used in multiple mods?
	new iTeam1Count = GetTeamClientCountAlive(2);
	new iTeam2Count = GetTeamClientCountAlive(3);
	
	
	// Allow rushing if there is only one player left in a team
	if((GetConVarBool(g_hCVLastManRushing) && (iTeam1Count == 1 || iTeam2Count == 1))
	// One on One rushing allowed and there is only 1 player alive in both teams?
	|| (GetConVarBool(g_hCVOneOnOneRushing) && (iTeam1Count == 1 && iTeam2Count == 1)))
	{
		if(g_hAllowRushingTimer != INVALID_HANDLE)
		{
			TriggerTimer(g_hAllowRushingTimer);
		}
	}
	
	return Plugin_Handled;
}

// Allow rushing, if bomb gets planted
public Action:Event_OnBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bIsRushAllowed || GetArraySize(g_hZones) == 0 || !GetConVarBool(g_hCVEnable))
		return Plugin_Handled;
	
	if(g_hAllowRushingTimer != INVALID_HANDLE)
	{
		TriggerTimer(g_hAllowRushingTimer);
	}
	
	return Plugin_Handled;
}

// Allow rushing, if a hostage starts following a player
public Action:Event_OnHostageFollows(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bIsRushAllowed || GetArraySize(g_hZones) == 0 || !GetConVarBool(g_hCVEnable))
		return Plugin_Handled;
	
	if(g_hAllowRushingTimer != INVALID_HANDLE)
	{
		TriggerTimer(g_hAllowRushingTimer);
	}
	
	return Plugin_Handled;
}

/**
 * SDKHook Callbacks
 */

public Action:Hook_BlockWeapon(client, weapon)
{
	if(g_bPlayerIsRushing[client])
	{
		// Block any other weapon but the knife
		decl String:sClassName[64];
		if(IsValidEntity(weapon)
		&& IsValidEdict(weapon)
		&& GetEdictClassname(weapon, sClassName, sizeof(sClassName))
		&& !StrEqual(sClassName, "weapon_knife", false))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
 
/**
 * Timer Callbacks
 */
public Action:Timer_OnAllowRushing(Handle:timer, any:data)
{
	g_hAllowRushingTimer = INVALID_HANDLE;
	g_bIsRushAllowed = true;
	
	// Allow the usage of the knife again
	for(new i=1;i<=MaxClients;i++)
	{
		g_bPlayerIsRushing[i] = false;
	}
	
	if(!GetConVarBool(g_hCVEnable) || GameRules_GetProp("m_bWarmupPeriod") == 1 && !GetConVarBool(g_hCVWarmupEnable))
	{
		
		return Plugin_Stop;
	}
	else
	{
		PrintToChatAll("%s%t", PREFIX, "Rushing Allowed");
	}
	
	return Plugin_Stop;
}

public Action:Timer_ShowFenceBeams(Handle:timer, any:data)
{
	if(!GetConVarBool(g_hCVEnable) || GameRules_GetProp("m_bWarmupPeriod") == 1 && !GetConVarBool(g_hCVWarmupEnable) || (g_bIsRushAllowed && !g_hCVShowFencesWhenAllowed))
	{
		g_hShowFencesTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	else
	{	
		// Get the desired color
		new String:sRGBA[16], String:sRGBAA[16], String:sColors[4][4], String:sColorsA[4][4], iColor[4];
		
		GetConVarString(g_hCVFenceColor, sRGBA, sizeof(sRGBA));
		ExplodeString(sRGBA, " ", sColors, 4, 4);
		
		GetConVarString(g_hCVFenceColorWhenAllowed, sRGBAA, sizeof(sRGBAA));
		ExplodeString(sRGBAA, " ", sColorsA, 4, 4);
		
		for(new c=0;c<4;c++)
		{
			if (g_bIsRushAllowed && g_hCVShowFencesWhenAllowed)
			{
				if(strlen(sColorsA[c]) == 0)
				{
					iColor[0] = 0;
					iColor[1] = 255;
					iColor[2] = 0;
					iColor[3] = 255;
					break;
				}
			
				iColor[c] = StringToInt(sColorsA[c]);
				
			}
			
			else
			{
				if(strlen(sColors[c]) == 0)
				{
					iColor[0] = 0;
					iColor[1] = 255;
					iColor[2] = 0;
					iColor[3] = 255;
					break;
				}
				
				iColor[c] = StringToInt(sColors[c]);
			}
		}
		
		new iSize = GetArraySize(g_hFences);
		new Handle:hFence;
		new Float:fPos1[3], Float:fPos2[3];
		new clients[MaxClients], num, iTeam, iClientTeam;
		for(new i=0;i<iSize;i++)
		{
			hFence = GetArrayCell(g_hFences, i);
			GetArrayArray(hFence, 1, fPos1, 3);
			GetArrayArray(hFence, 2, fPos2, 3);
			iTeam = GetArrayCell(hFence, 3);
			
			TE_SetupBeamPoints(fPos1, fPos2, g_iLaserMaterial, g_iHaloMaterial, 0, 20, 1.0, 2.0, 2.0, 1, 0.0, iColor, 5);
			
			num = 0;
			// Don't show the beam to players who are currently editing the fence or are in the team, who's allowed to rush
			for(new client=1;client<=MaxClients;client++)
			{
				if((g_iPlayerEditsType[client] != TYPE_FENCE || g_iPlayerEditsType[client] == TYPE_FENCE && g_iPlayerEditsZone[client] != i) && IsClientInGame(client) && (iTeam == 0 || (iClientTeam = GetClientTeam(client)) < 2 || iClientTeam == iTeam))
				{
					clients[num] = client;
					num++;
				}
			}
			if(num > 0)
				TE_Send(clients, num);
		}
		
		// Show the zones if wanted
		if(GetConVarBool(g_hCVShowZones))
		{	
			new Handle:hZone;
			iSize = GetArraySize(g_hZones);
			for(new i=0;i<iSize;i++)
			{
				hZone = GetArrayCell(g_hZones, i);
				GetArrayArray(hZone, 1, fPos1, 3);
				GetArrayArray(hZone, 2, fPos2, 3);
				iTeam = GetArrayCell(hZone, 3);
				
				// Don't show the beam to players who are currently editing the zone or are in the team, who's allowed to rush
				for(new client=1;client<=MaxClients;client++)
				{
					if((g_iPlayerEditsType[client] != TYPE_ZONE || g_iPlayerEditsType[client] == TYPE_ZONE && g_iPlayerEditsZone[client] != i) && IsClientInGame(client) && (iTeam == 0 || (iClientTeam = GetClientTeam(client)) < 2 || iClientTeam == iTeam))
					{
						TE_SendBeamBoxToClient(client, fPos1, fPos2, g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, iColor, 0);
					}
				}
			}
		}	
	}
	
	return Plugin_Continue;
}

/**
 * Entity Output Handlers
 */
public EntOut_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	
	if(g_bIsRushAllowed || !GetConVarBool(g_hCVEnable))
	{
		return;
	}
	
	//Check if it's warmup period
	if(GameRules_GetProp("m_bWarmupPeriod") == 1 && !GetConVarBool(g_hCVWarmupEnable))
	{
		//LogMessage("Punishing disabled during warmup");
		return;
	}
	
	/*// if the touching entity is a weapon, remove it, if we strip to knife
	decl String:sClassName[64];
	if(iPunishment == 4
	&& IsValidEntity(activator)
	&& IsValidEdict(activator)
	&& GetEdictClassname(activator, sClassName, sizeof(sClassName))
	&& StrContains(sClassName, "weapon_") != -1
	&& GetEntPropEnt(activator, Prop_Send, "m_hOwnerEntity") == -1)
	{
		RemoveEdict(activator);
	}*/
	
	// Ignore dead players
	if(activator < 1 || activator > MaxClients || !IsPlayerAlive(activator))
		return;
	
	// Admin immune?
	if(GetConVarBool(g_hCVAdminImmunity) && CheckCommandAccess(activator, "antirush_immune", ADMFLAG_GENERIC, true))
	{
		return;
	}
	
	decl String:sTargetName[256];
	GetEntPropString(caller, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
	ReplaceString(sTargetName, sizeof(sTargetName), "sm_zone ", "");
	
	// Check if he's in the team, this zone blocks
	new iSize = GetArraySize(g_hZones), iZonePunishment = -1;
	new Handle:hZone;
	decl String:sZoneName[64];
	for(new i=0;i<iSize;i++)
	{
		hZone = GetArrayCell(g_hZones, i);
		GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
		// Check the team for this zone
		if(StrEqual(sZoneName, sTargetName))
		{
			new iTeam = GetArrayCell(hZone, 3);
			iZonePunishment = GetArrayCell(hZone, 4);
			if(iTeam != 0 && GetClientTeam(activator) != iTeam)
				return;
		}
	}
	
	new iPunishment = GetConVarInt(g_hCVPunishment);
	if(iZonePunishment > 0)
		iPunishment = iZonePunishment;
	
	switch(iPunishment)
	{
		// Just tell everybody
		case 1:
		{
			decl String:sName[64];
			GetClientName(activator, sName, sizeof(sName));
			PrintToChatAll("%s%t", PREFIX, "Player Entered Zone", sName, sTargetName);
		}
		// Bounce him back
		case 2:
		{
			new Float:fVelocity[3];
			fVelocity[0] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[0]"); 
			fVelocity[1] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[1]"); 
			fVelocity[2] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[2]");
			
			fVelocity[0] *= -10.0;
			fVelocity[1] *= -10.0;
			// Always bounce back with at least 200 velocity
			if(fVelocity[1] > 0.0 && fVelocity[1] < 200.0)
				fVelocity[1] = 200.0;
			else if(fVelocity[1] < 0.0 && fVelocity[1] > -200.0)
				fVelocity[1] = -200.0;
			// Never push the player up.
			if(fVelocity[2] > 0.0)
				fVelocity[2] *= -1.0;

			TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
		// Slay
		case 3:
		{
			ForcePlayerSuicide(activator);
			decl String:sName[64];
			GetClientName(activator, sName, sizeof(sName));
			PrintToChatAll("%s%t", PREFIX, "Player Slayed", sName, sTargetName);
		}
		// Only allow the usage of the knife
		case 4:
		{
			// Let the player hold the knife
			new iWeapon = GetPlayerWeaponSlot(activator, 2);
			decl String:sWeapon[32];
			if(iWeapon != -1)
			{
				GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
				FakeClientCommand(activator, "use %s", sWeapon);
			}
			
			// Don' allow the usage of other weapons but the knife
			g_bPlayerIsRushing[activator] = true;
		}
		// Allow the usage of any weapon again
		case 5:
		{
			g_bPlayerIsRushing[activator] = false;
		}
	}
}

/**
 * Command Callbacks
 */
public Action:Command_SetupZones(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Anti Rush > %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	g_bPlayerNamesNewZone[client] = false;
	g_bPlayerRenamesZone[client] = false;
	
	g_iPlayerEditsType[client] = -1;
	g_iPlayerCreatesZoneFence[client] = NO_POINT;
	ClearVector(g_fTempZoneVector1[client]);
	ClearVector(g_fTempZoneVector2[client]);
	
	decl String:sMap[PLATFORM_MAX_PATH], String:sMenuText[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	new Handle:menu = CreateMenu(MenuHandler_Zones);
	SetMenuTitle(menu, "%T: %s", "Map", client, sMap);
	SetMenuExitButton(menu, true);
	
	Format(sMenuText, sizeof(sMenuText), "%T", "Active Zones", client);
	AddMenuItem(menu, "active_zones", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Active Fences", client);
	AddMenuItem(menu, "active_fences", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Add Zones", client);
	AddMenuItem(menu, "add_zone", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Add Fence", client);
	AddMenuItem(menu, "add_fence", sMenuText);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return  Plugin_Handled;
}

public Action:Command_ChatHook(client, args)
{
	// This player just added a new zone
	if (g_bPlayerNamesNewZone[client])
	{
		// get the name
		new String:sZoneName[512], String:sMenuText[64];
		GetCmdArgString(sZoneName, sizeof(sZoneName));
		StripQuotes(sZoneName);
		
		g_bPlayerNamesNewZone[client] = false;
		
		if(StrEqual(sZoneName, "!stop"))
		{
			if(g_iPlayerEditsType[client] == TYPE_FENCE)
				PrintToChat(client, "%s%t", PREFIX, "Abort Fence Name");
			else
				PrintToChat(client, "%s%t", PREFIX, "Abort Zone Name");
			
			g_iPlayerEditsType[client] = -1;
			ClearVector(g_fTempZoneVector1[client]);
			ClearVector(g_fTempZoneVector2[client]);
			return Plugin_Handled;
		}
		
		// Confirm the new zone
		new Handle:menu = CreateMenu(MenuHandler_SaveNewZone);
		SetMenuTitle(menu, "%T", "Adding Zone", client);
		SetMenuExitButton(menu, false);
		
		Format(sMenuText, sizeof(sMenuText), "%T", "Save", client);
		AddMenuItem(menu, sZoneName, sMenuText);
		Format(sMenuText, sizeof(sMenuText), "%T", "Discard", client);
		AddMenuItem(menu, "discard", sMenuText);
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		
		// Don't show the name in chat
		return Plugin_Handled;
	}
	else if(g_bPlayerRenamesZone[client])
	{
		// get the name
		new String:sZoneName[512];
		GetCmdArgString(sZoneName, sizeof(sZoneName));
		StripQuotes(sZoneName);
		
		g_bPlayerRenamesZone[client] = false;
		
		if(StrEqual(sZoneName, "!stop"))
		{
			
			if(g_iPlayerEditsType[client] == TYPE_FENCE)
				PrintToChat(client, "%s%t", PREFIX, "Abort Fence Rename");
			else
				PrintToChat(client, "%s%t", PREFIX, "Abort Zone Rename");
				
			ShowZoneOptionMenu(client);
			return Plugin_Handled;
		}
		
		if(g_iPlayerEditsType[client] == TYPE_ZONE)
		{
			// remove the trigger_multiple as long as it's still named the same
			KillTriggerEntity(g_iPlayerEditsZone[client]);
		}
		
		// Set the zone/fence name
		decl String:sOldZoneName[64];
		new Handle:hZone;
		if(g_iPlayerEditsType[client] == TYPE_ZONE)
		{
			hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[client]);
		}
		else
		{
			hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[client]);
		}
		GetArrayString(hZone, 0, sOldZoneName, sizeof(sOldZoneName));
		SetArrayString(hZone, 0, sZoneName);
		
		if(g_iPlayerEditsType[client] == TYPE_ZONE)
		{
			// Spawn the zone again with the new name
			SpawnTriggerMultipleInBox(g_iPlayerEditsZone[client]);
		}
		
		// Update the config file
		decl String:sConfigFile[PLATFORM_MAX_PATH], String:inputMap[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH];
		GetCurrentMap(inputMap, sizeof(inputMap));
		GetMapDisplayName(inputMap, sMap, sizeof(sMap)); 
		BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/antirush/%s.cfg", sMap);
		
		PrintToChat(client, "%s%t", PREFIX, "Name Edited");
		
		// Read the config
		new Handle:kv = CreateKeyValues("ZonesAndFences");
		FileToKeyValues(kv, sConfigFile);
		if(!KvGotoFirstSubKey(kv))
		{
			PrintToChat(client, "%sConfig file is empty. Can't edit it permanently!", PREFIX);
			CloseHandle(kv);
			ShowZoneOptionMenu(client);
			return Plugin_Handled;
		}
		
		decl String:sType[15];
		if(g_iPlayerEditsType[client] == TYPE_ZONE)
		{
			Format(sType, sizeof(sType), "zones");
		}
		else
		{
			Format(sType, sizeof(sType), "fences");
		}
		
		// find the zone to edit
		decl String:sBuffer[256];
		do
		{
			KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
			if(StrEqual(sBuffer, sType))
			{
				if(KvGotoFirstSubKey(kv))
				{
					do
					{
						// is this the section to edit?
						KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
						if(StrEqual(sBuffer, sOldZoneName))
						{
							// write the new name
							KvSetString(kv, "name", sZoneName);
							break;
						}
						
					} while (KvGotoNextKey(kv));
				}
			}
		} while (KvGotoNextKey(kv));
		
		KvRewind(kv);
		KeyValuesToFile(kv, sConfigFile);
		CloseHandle(kv);
		
		ShowZoneOptionMenu(client);
		
		// Don't show the name in chat
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/**
 * Menu Handlers
 */

public MenuHandler_Zones(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		// List all Zones
		if(StrEqual(info, "active_zones"))
		{
			ShowActiveZonesMenu(param1);
		}
		else if(StrEqual(info, "active_fences"))
		{
			ShowActiveFencesMenu(param1);
		}
		else if(StrEqual(info, "add_fence"))
		{
			PrintToChat(param1, "%s%t", PREFIX, "Add Fence Instruction");
			g_iPlayerEditsType[param1] = TYPE_FENCE;
			g_iPlayerCreatesZoneFence[param1] = FIRST_POINT;
		}
		else if(StrEqual(info, "add_zone"))
		{
			PrintToChat(param1, "%s%t", PREFIX, "Add Zone Instruction");
			
			g_iPlayerEditsType[param1] = TYPE_ZONE;
			g_iPlayerCreatesZoneFence[param1] = FIRST_POINT;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SelectZone(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		// Store the zone index for further reference
		new iZone = StringToInt(info);
		g_iPlayerEditsZone[param1] = iZone;
		
		ShowZoneOptionMenu(param1);
	}
	else if(action == MenuAction_Cancel)
	{
		// Player isn't editing this zone anymore
		g_iPlayerEditsZone[param1] = -1;
		g_iPlayerEditsType[param1] = -1;
		if(param2 == MenuCancel_ExitBack)
		{
			Command_SetupZones(param1, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SelectVector(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new Handle:hZone, Float:fVec1[3], Float:fVec2[3];
		new String:sRGBA[16], String:sColors[4][4], iColor[4];
		// Show the box, if teleporting to it, show it either
		if(StrEqual(info, "show") || StrEqual(info, "teleport"))
		{
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			else
				hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[param1]);
			GetArrayArray(hZone, 1, fVec1, 3);
			GetArrayArray(hZone, 2, fVec2, 3);
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				TE_SendBeamBoxToClient(param1, fVec1, fVec2, g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
			}
			else
			{
				// Get the desired color
				GetConVarString(g_hCVFenceColor, sRGBA, sizeof(sRGBA));
				ExplodeString(sRGBA, " ", sColors, 4, 4);
				for(new c=0;c<4;c++)
				{
					// Invalid setting? reset to default
					if(strlen(sColors[c]) == 0)
					{
						iColor[0] = 255;
						iColor[1] = 0;
						iColor[2] = 0;
						iColor[3] = 255;
						break;
					}
					iColor[c] = StringToInt(sColors[c]);
				}
				
				TE_SetupBeamPoints(fVec1, fVec2, g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, iColor, 0);
				TE_SendToClient(param1);
			}
			
			if(!StrEqual(info, "teleport"))
				// Redisplay the menu
				ShowZoneOptionMenu(param1);
		}
		
		// Teleport to position
		if(StrEqual(info, "teleport"))
		{
			new Float:fOrigin[3];
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			}
			else
			{
				hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[param1]);
			}
			GetArrayArray(hZone, 1, fVec1, 3);
			GetArrayArray(hZone, 2, fVec2, 3);
			GetMiddleOfABox(fVec1, fVec2, fOrigin);
			TeleportEntity(param1, fOrigin, NULL_VECTOR, Float:{0.0,0.0,0.0});
			
			// Redisplay the menu
			ShowZoneOptionMenu(param1);
		}
		// Change zone team
		else if(StrEqual(info, "team"))
		{
			decl String:sZoneName[64];
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			}
			else
			{
				hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[param1]);
			}
			
			GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
			
			// Switch through the teams
			new iTeam = GetArrayCell(hZone, 3);
			
			// Decrease old zone count
			switch(iTeam)
			{
				// Both teams
				case 0:
				{
					g_iTeamZones[0]--;
					g_iTeamZones[1]--;
				}
				// First team
				case 2:
				{
					g_iTeamZones[0]--;
				}
				case 3:
				{
					g_iTeamZones[1]--;
				}
			}
			
			iTeam++;
			if(iTeam > 3)
				iTeam = 0;
			else if(iTeam < 2)
				iTeam = 2;
			
			// Increase zone count
			switch(iTeam)
			{
				// Both teams
				case 0:
				{
					g_iTeamZones[0]++;
					g_iTeamZones[1]++;
				}
				// First team
				case 2:
				{
					g_iTeamZones[0]++;
				}
				case 3:
				{
					g_iTeamZones[1]++;
				}
			}
			
			SetArrayCell(hZone, 3, iTeam);
			
			// The actual config file
			decl String:sConfigFile[PLATFORM_MAX_PATH], String:inputMap[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH];
			GetCurrentMap(inputMap, sizeof(inputMap));
			GetMapDisplayName(inputMap, sMap, sizeof(sMap));
			BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/antirush/%s.cfg", sMap);
			
			new Handle:kv = CreateKeyValues("ZonesAndFences");
			FileToKeyValues(kv, sConfigFile);
			if(!KvGotoFirstSubKey(kv))
			{
				CloseHandle(kv);
				ShowZoneOptionMenu(param1);
				PrintToChat(param1, "%sConfig file is empty. Can't edit it permanently!", PREFIX);
				return;
			}
			
			// Choose the correct type
			decl String:sType[15];
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				Format(sType, sizeof(sType), "zones");
			}
			else
			{
				Format(sType, sizeof(sType), "fences");
			}
			
			decl String:sBuffer[256];
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				if(StrEqual(sBuffer, sType))
				{
					if(KvGotoFirstSubKey(kv))
					{
						do
						{
							KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
							if(StrEqual(sBuffer, sZoneName))
							{
								KvSetNum(kv, "team", iTeam);
								break;
							}
							
						} while (KvGotoNextKey(kv));
					}
				}
			} while (KvGotoNextKey(kv));
			
			KvRewind(kv);
			KeyValuesToFile(kv, sConfigFile);
			CloseHandle(kv);
			
			ShowZoneOptionMenu(param1);
		}
		// Change zone punishment
		else if(StrEqual(info, "punishment"))
		{
			decl String:sZoneName[64];
			hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			
			GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
			
			// Switch through the punishments
			new iPunishment = GetArrayCell(hZone, 4);
			
			new iPunishmentCount = 5;
			// Don't allow the knife only and allow all weapons again punishments to be chosen, since they require sdkhooks
			if(!LibraryExists("sdkhooks"))
				iPunishmentCount = 3;
			
			iPunishment++;
			if(iPunishment > iPunishmentCount)
				iPunishment = -1;
			else if(iPunishment < 1)
				iPunishment = 1;
			
			SetArrayCell(hZone, 4, iPunishment);
			
			// The actual config file
			decl String:sConfigFile[PLATFORM_MAX_PATH], String:inputMap[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH];
			GetCurrentMap(inputMap, sizeof(inputMap));
			GetMapDisplayName(inputMap, sMap, sizeof(sMap));
			BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/antirush/%s.cfg", sMap);
			
			new Handle:kv = CreateKeyValues("ZonesAndFences");
			FileToKeyValues(kv, sConfigFile);
			if(!KvGotoFirstSubKey(kv))
			{
				CloseHandle(kv);
				ShowZoneOptionMenu(param1);
				PrintToChat(param1, "%sConfig file is empty. Can't edit it permanently!", PREFIX);
				return;
			}
			
			decl String:sBuffer[256];
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				if(StrEqual(sBuffer, "zones"))
				{
					if(KvGotoFirstSubKey(kv))
					{
						do
						{
							KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
							if(StrEqual(sBuffer, sZoneName))
							{
								// Don't keep the info in the file, if it's default
								if(iPunishment == -1)
									KvDeleteKey(kv, "punishment");
								else
									KvSetNum(kv, "punishment", iPunishment);
								break;
							}
							
						} while (KvGotoNextKey(kv));
					}
				}
			} while (KvGotoNextKey(kv));
			
			KvRewind(kv);
			KeyValuesToFile(kv, sConfigFile);
			CloseHandle(kv);
			
			ShowZoneOptionMenu(param1);
		}
		// Start editing the zone
		else if(StrEqual(info, "vec1") || StrEqual(info, "vec2"))
		{
			if(StrEqual(info, "vec1"))
				g_iPlayerEditsVector[param1] = 1;
			else
				g_iPlayerEditsVector[param1] = 2;
				
			// Store the current vectors
			if(IsNullVector(g_fTempZoneVector1[param1]) && IsNullVector(g_fTempZoneVector2[param1]))
			{
				if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				{
					hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
				}
				else
				{
					hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[param1]);
				}
				GetArrayArray(hZone, 1, fVec1, 3);
				GetArrayArray(hZone, 2, fVec2, 3);
				
				ClearVector(g_fTempZoneVector1[param1]);
				ClearVector(g_fTempZoneVector2[param1]);
				
				AddVectors(g_fTempZoneVector1[param1], fVec1, g_fTempZoneVector1[param1]);
				AddVectors(g_fTempZoneVector2[param1], fVec2, g_fTempZoneVector2[param1]);
			}
			
			// Display the zone for now
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				TE_SendBeamBoxToClient(param1, g_fTempZoneVector1[param1], g_fTempZoneVector2[param1], g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
			}
			else
			{
				// Get the desired color
				GetConVarString(g_hCVFenceColor, sRGBA, sizeof(sRGBA));
				ExplodeString(sRGBA, " ", sColors, 4, 4);
				for(new c=0;c<4;c++)
				{
					// Invalid setting? reset to default
					if(strlen(sColors[c]) == 0)
					{
						iColor[0] = 255;
						iColor[1] = 0;
						iColor[2] = 0;
						iColor[3] = 255;
						break;
					}
					iColor[c] = StringToInt(sColors[c]);
				}
				
				TE_SetupBeamPoints(g_fTempZoneVector1[param1], g_fTempZoneVector2[param1], g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, iColor, 0);
				TE_SendToClient(param1);
			}
			
			// Highlight the currently edited edge for players editing a zone
			if(g_iPlayerEditsVector[param1] == 1)
			{
				TE_SetupGlowSprite(g_fTempZoneVector1[param1], g_iGlowSprite, 5.0, 1.0, 100);
				TE_SendToClient(param1);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				TE_SetupGlowSprite(g_fTempZoneVector2[param1], g_iGlowSprite, 5.0, 1.0, 100);
				TE_SendToClient(param1);
			}
			
			ShowZoneVectorEditMenu(param1);
		}
		// Rename
		else if(StrEqual(info, "name"))
		{
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				PrintToChat(param1, "%s%t", PREFIX, "Type Zone Name");
			else
				PrintToChat(param1, "%s%t", PREFIX, "Type Fence Name");
			g_bPlayerRenamesZone[param1] = true;
		}
		// Delete
		else if(StrEqual(info, "delete"))
		{
			new Handle:panel = CreatePanel();
			
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			else
				hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[param1]);
				
			decl String:sBuffer[256];
			GetArrayString(hZone, 0, sBuffer, sizeof(sBuffer));
			
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				Format(sBuffer, sizeof(sBuffer), "%T", "Confirm Delete Zone", param1, sBuffer);
			else
				Format(sBuffer, sizeof(sBuffer), "%T", "Confirm Delete Fence", param1, sBuffer);
			
			SetPanelTitle(panel, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%T", "Yes", param1);
			DrawPanelItem(panel, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%T", "No", param1);
			DrawPanelItem(panel, sBuffer);
			
			SendPanelToClient(panel, param1, PanelHandler_ConfirmDelete, 20);
			
			CloseHandle(panel);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		g_iPlayerEditsZone[param1] = -1;
		g_iPlayerEditsVector[param1] = -1;
		ClearVector(g_fTempZoneVector1[param1]);
		ClearVector(g_fTempZoneVector2[param1]);
		
		if(param2 == MenuCancel_ExitBack)
		{
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				ShowActiveZonesMenu(param1);
			else
				ShowActiveFencesMenu(param1);
		}
		else
		{
			g_iPlayerEditsType[param1] = -1;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_EditVector(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		// Save the new coordinates to the file and the adt_array
		if(StrEqual(info, "save"))
		{
			// The dynamic array cache
			new Handle:hZone;
			new String:sZoneName[64];
			
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			else
				hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[param1]);
			GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
			SetArrayArray(hZone, 1, g_fTempZoneVector1[param1], 3);
			SetArrayArray(hZone, 2, g_fTempZoneVector2[param1], 3);
			
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				// Refresh the trigger_multiple
				KillTriggerEntity(g_iPlayerEditsZone[param1]);
				SpawnTriggerMultipleInBox(g_iPlayerEditsZone[param1]);
			}
			
			PrintToChat(param1, "%s%t", PREFIX, "Saved");
			
			// The actual config file
			decl String:sConfigFile[PLATFORM_MAX_PATH], String:inputMap[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH];
			GetCurrentMap(inputMap, sizeof(inputMap));
			GetMapDisplayName(inputMap, sMap, sizeof(sMap));
			BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/antirush/%s.cfg", sMap);
			
			new Handle:kv = CreateKeyValues("ZonesAndFences");
			FileToKeyValues(kv, sConfigFile);
			if(!KvGotoFirstSubKey(kv))
			{
				CloseHandle(kv);
				ShowZoneVectorEditMenu(param1);
				PrintToChat(param1, "%sConfig file is empty. Can't edit it permanently!", PREFIX);
				return;
			}
			
			decl String:sType[15];
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				Format(sType, sizeof(sType), "zones");
			}
			else
			{
				Format(sType, sizeof(sType), "fences");
			}
			
			decl String:sBuffer[256];
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				if(StrEqual(sBuffer, sType))
				{
					if(KvGotoFirstSubKey(kv))
					{
						do
						{
							KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
							if(StrEqual(sBuffer, sZoneName))
							{
								KvSetVector(kv, "vec1", g_fTempZoneVector1[param1]);
								
								KvSetVector(kv, "vec2", g_fTempZoneVector2[param1]);
								break;
							}
							
						} while (KvGotoNextKey(kv));
					}
				}
			} while (KvGotoNextKey(kv));
			
			KvRewind(kv);
			KeyValuesToFile(kv, sConfigFile);
			CloseHandle(kv);
		}
		// Add to the x axis
		else if(StrEqual(info, "ax"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
				g_fTempZoneVector1[param1][0] += 5.0;
			else if(g_iPlayerEditsVector[param1] == 2)
				g_fTempZoneVector2[param1][0] += 5.0;
		}
		// Add to the y axis
		else if(StrEqual(info, "ay"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
				g_fTempZoneVector1[param1][1] += 5.0;
			else if(g_iPlayerEditsVector[param1] == 2)
				g_fTempZoneVector2[param1][1] += 5.0;
		}
		// Add to the z axis
		else if(StrEqual(info, "az"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
				g_fTempZoneVector1[param1][2] += 5.0;
			else if(g_iPlayerEditsVector[param1] == 2)
				g_fTempZoneVector2[param1][2] += 5.0;
		}
		// Subtract from the x axis
		else if(StrEqual(info, "sx"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
				g_fTempZoneVector1[param1][0] -= 5.0;
			else if(g_iPlayerEditsVector[param1] == 2)
				g_fTempZoneVector2[param1][0] -= 5.0;
		}
		// Subtract from the y axis
		else if(StrEqual(info, "sy"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
				g_fTempZoneVector1[param1][1] -= 5.0;
			else if(g_iPlayerEditsVector[param1] == 2)
				g_fTempZoneVector2[param1][1] -= 5.0;
		}
		// Subtract from the z axis
		else if(StrEqual(info, "sz"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
				g_fTempZoneVector1[param1][2] -= 5.0;
			else if(g_iPlayerEditsVector[param1] == 2)
				g_fTempZoneVector2[param1][2] -= 5.0;
		}
		
		// Just show the box again
		if(!StrEqual(info, "save"))
		{
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				TE_SendBeamBoxToClient(param1, g_fTempZoneVector1[param1], g_fTempZoneVector2[param1], g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
			}
			else
			{
				// Get the desired color
				new String:sRGBA[16], String:sColors[4][4], iColor[4];
				GetConVarString(g_hCVFenceColor, sRGBA, sizeof(sRGBA));
				ExplodeString(sRGBA, " ", sColors, 4, 4);
				for(new c=0;c<4;c++)
				{
					// Invalid setting? reset to default
					if(strlen(sColors[c]) == 0)
					{
						iColor[0] = 255;
						iColor[1] = 0;
						iColor[2] = 0;
						iColor[3] = 255;
						break;
					}
					iColor[c] = StringToInt(sColors[c]);
				}
				
				TE_SetupBeamPoints(g_fTempZoneVector1[param1], g_fTempZoneVector2[param1], g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, iColor, 0);
				TE_SendToClient(param1);
			}
			
			// Highlight the currently edited edge for players editing a zone
			if(g_iPlayerEditsVector[param1] == 1)
			{
				TE_SetupGlowSprite(g_fTempZoneVector1[param1], g_iGlowSprite, 5.0, 1.0, 100);
				TE_SendToClient(param1);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				TE_SetupGlowSprite(g_fTempZoneVector2[param1], g_iGlowSprite, 5.0, 1.0, 100);
				TE_SendToClient(param1);
			}
		}
		
		// Redisplay the menu
		ShowZoneVectorEditMenu(param1);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
			ShowZoneOptionMenu(param1);
		else
			g_iPlayerEditsZone[param1] = -1;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SaveNewZone(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		// Don't save the new zone
		if(StrEqual(info, "discard"))
		{
			g_iPlayerEditsType[param1] = -1;
			ClearVector(g_fTempZoneVector1[param1]);
			ClearVector(g_fTempZoneVector2[param1]);
			
			PrintToChat(param1, "%s%t", "Discarded", PREFIX);
		}
		// Save the new zone
		else
		{
			// save it to the file
			decl String:sConfigFile[PLATFORM_MAX_PATH], String:inputMap[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH];
			GetCurrentMap(inputMap, sizeof(inputMap));
			GetMapDisplayName(inputMap, sMap, sizeof(sMap));
			BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/antirush/%s.cfg", sMap);
			
			new Handle:kv = CreateKeyValues("ZonesAndFences");
			FileToKeyValues(kv, sConfigFile);
			
			decl String:sType[15];
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				Format(sType, sizeof(sType), "zones");
			}
			else
			{
				Format(sType, sizeof(sType), "fences");
			}
			
			// Create the zones/fences key, if not there already
			KvJumpToKey(kv, sType, true);
			
			decl String:sNum[5], String:sBuffer[256];
			new iNum = 0, iTemp;
			
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					// Get the highest numer and increase.
					KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
					iTemp = StringToInt(sBuffer);
					if(iTemp >= iNum)
					{
						iNum = iTemp + 1;
					}
					
					// There is already a zone with this name
					KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
					if(StrEqual(sBuffer, info))
					{
						PrintToChat(param1, "%s%t", PREFIX, "Name Already Taken", info);
						g_bPlayerNamesNewZone[param1] = true;
						return;
					}
				} while (KvGotoNextKey(kv));
				KvGoBack(kv);
			}
			
			IntToString(iNum, sNum, sizeof(sNum));
			KvJumpToKey(kv, sNum, true);
			KvSetString(kv, "name", info);
			KvSetVector(kv, "vec1", g_fTempZoneVector1[param1]);
			KvSetVector(kv, "vec2", g_fTempZoneVector2[param1]);
			
			KvRewind(kv);
			KeyValuesToFile(kv, sConfigFile);
			CloseHandle(kv);
			
			// Store the current vectors to the array
			new Handle:hTempArray = CreateArray(ByteCountToCells(256));
			
			// set the name
			PushArrayString(hTempArray, info);
			
			// set the vec1
			PushArrayArray(hTempArray, g_fTempZoneVector1[param1], 3);
			
			// set the vec2
			PushArrayArray(hTempArray, g_fTempZoneVector2[param1], 3);
			
			// Set the team to both by default
			PushArrayCell(hTempArray, 0);
			
			// save the new zone for editing
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				// Set the punishment to default for zones
				PushArrayCell(hTempArray, -1);
				
				g_iPlayerEditsZone[param1] = PushArrayCell(g_hZones, hTempArray);
				
				// Spawn the trigger_multiple
				SpawnTriggerMultipleInBox(g_iPlayerEditsZone[param1]);
			}
			else
			{
				g_iPlayerEditsZone[param1] = PushArrayCell(g_hFences, hTempArray);
			}
			
			PrintToChat(param1, "%s%t", PREFIX, "Saved");
			
			ShowZoneOptionMenu(param1);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		g_iPlayerEditsZone[param1] = -1;
		g_iPlayerEditsVector[param1] = -1;
		ClearVector(g_fTempZoneVector1[param1]);
		ClearVector(g_fTempZoneVector2[param1]);
			
		if(param2 == MenuCancel_ExitBack)
		{
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				ShowActiveZonesMenu(param1);
			else
				ShowActiveFencesMenu(param1);
		}
		else
		{
			g_iPlayerEditsType[param1] = -1;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public PanelHandler_ConfirmDelete(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		// Selected yes
		if(param2 == 1)
		{
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				// Kill the trigger_multiple if zone
				KillTriggerEntity(g_iPlayerEditsZone[param1]);
			}
			
			// Delete from cache array
			decl String:sZoneName[64];
			new Handle:hZone;
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			else
				hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[param1]);
			
			GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
			CloseHandle(hZone);
			
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
				RemoveFromArray(g_hZones, g_iPlayerEditsZone[param1]);
			else
				RemoveFromArray(g_hFences, g_iPlayerEditsZone[param1]);
			
			g_iPlayerEditsZone[param1] = -1;
			
			// Delete from config file
			decl String:sConfigFile[PLATFORM_MAX_PATH], String:inputMap[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH];
			GetCurrentMap(inputMap, sizeof(inputMap));
			GetMapDisplayName(inputMap, sMap, sizeof(sMap));
			BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/antirush/%s.cfg", sMap);
			
			new Handle:kv = CreateKeyValues("ZonesAndFences");
			FileToKeyValues(kv, sConfigFile);
			if(!KvGotoFirstSubKey(kv))
			{
				CloseHandle(kv);
				if(g_iPlayerEditsType[param1] == TYPE_ZONE)
					ShowActiveZonesMenu(param1);
				else
					ShowActiveFencesMenu(param1);
				return;
			}
			
			decl String:sType[15];
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				Format(sType, sizeof(sType), "zones");
			}
			else
			{
				Format(sType, sizeof(sType), "fences");
			}
			
			decl String:sBuffer[256];
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				if(StrEqual(sBuffer, sType))
				{
					if(KvGotoFirstSubKey(kv))
					{
						do
						{
							KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
							if(StrEqual(sBuffer, sZoneName))
							{
								KvDeleteThis(kv);
								break;
							}
							
						} while (KvGotoNextKey(kv));
					}
				}
			} while (KvGotoNextKey(kv));
			
			KvRewind(kv);
			KeyValuesToFile(kv, sConfigFile);
			CloseHandle(kv);
			
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				PrintToChat(param1, "%s%t", PREFIX, "Deleted Zone", sZoneName);
				ShowActiveZonesMenu(param1);
			}
			else
			{
				PrintToChat(param1, "%s%t", PREFIX, "Deleted Fence", sZoneName);
				ShowActiveFencesMenu(param1);
			}
		}
		else
		{
			if(g_iPlayerEditsType[param1] == TYPE_ZONE)
			{
				PrintToChat(param1, "%s%t", PREFIX, "Canceled Zone Deletion");
			}
			else
			{
				PrintToChat(param1, "%s%t", PREFIX, "Canceled Fence Deletion");
			}
			ShowZoneOptionMenu(param1);
		}
	} else if (action == MenuAction_Cancel) {
		if(g_iPlayerEditsType[param1] == TYPE_ZONE)
		{
			PrintToChat(param1, "%s%t", PREFIX, "Canceled Zone Deletion");
		}
		else
		{
			PrintToChat(param1, "%s%t", PREFIX, "Canceled Fence Deletion");
		}
		ShowZoneOptionMenu(param1);
	}
}


ShowActiveZonesMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SelectZone);
	SetMenuTitle(menu, "%T", "Active Zones", client);
	SetMenuExitBackButton(menu, true);
	
	g_iPlayerEditsType[client] = TYPE_ZONE;
	
	new iSize = GetArraySize(g_hZones);
	new Handle:hZone;
	decl String:sBuffer[256], String:sNum[3];
	for(new i=0;i<iSize;i++)
	{
		hZone = GetArrayCell(g_hZones, i);
		GetArrayString(hZone, 0, sBuffer, sizeof(sBuffer));
		IntToString(i, sNum, sizeof(sNum));
		AddMenuItem(menu, sNum, sBuffer);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

ShowActiveFencesMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SelectZone);
	SetMenuTitle(menu, "%T", "Active Fences", client);
	SetMenuExitBackButton(menu, true);
	
	g_iPlayerEditsType[client] = TYPE_FENCE;
	
	new iSize = GetArraySize(g_hFences);
	new Handle:hFence;
	decl String:sBuffer[256], String:sNum[3];
	for(new i=0;i<iSize;i++)
	{
		hFence = GetArrayCell(g_hFences, i);
		GetArrayString(hFence, 0, sBuffer, sizeof(sBuffer));
		IntToString(i, sNum, sizeof(sNum));
		AddMenuItem(menu, sNum, sBuffer);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

ShowZoneOptionMenu(client)
{
	if(g_iPlayerEditsZone[client] == -1)
		return;
	
	// Get the zone name
	decl String:sZoneName[64], String:sMenuText[64], String:sBuffer[64];
	new Handle:hZone;
	if(g_iPlayerEditsType[client] == TYPE_ZONE)
		hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[client]);
	else
		hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[client]);
	GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
	
	new iTeam = GetArrayCell(hZone, 3);
	
	new Handle:menu = CreateMenu(MenuHandler_SelectVector);
	if(g_iPlayerEditsType[client] == TYPE_ZONE)
		SetMenuTitle(menu, "%T", "Manage Zone", client, sZoneName);
	else
		SetMenuTitle(menu, "%T", "Manage Fence", client, sZoneName);
		
	SetMenuExitBackButton(menu, true);
	
	if(g_iPlayerEditsType[client] == TYPE_ZONE)
		Format(sMenuText, sizeof(sMenuText), "%T", "Show Zone", client);
	else
		Format(sMenuText, sizeof(sMenuText), "%T", "Show Fence", client);
	
	AddMenuItem(menu, "show", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Edit First Point", client);
	AddMenuItem(menu, "vec1", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Edit Second Point", client);
	AddMenuItem(menu, "vec2", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Edit Name", client);
	AddMenuItem(menu, "name", sMenuText);
	
	Format(sMenuText, sizeof(sMenuText), "%T", "Teleport To", client);
	AddMenuItem(menu, "teleport", sMenuText);
	
	// Get team names or say "both"
	if(iTeam > 0)
		GetTeamName(iTeam, sBuffer, sizeof(sBuffer));
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "Both", client);
	
	Format(sMenuText, sizeof(sMenuText), "%T", "Trigger Team", client, sBuffer);
	AddMenuItem(menu, "team", sMenuText);
	
	if(g_iPlayerEditsType[client] == TYPE_ZONE)
	{
		new iPunishment = GetArrayCell(hZone, 4);
		switch(iPunishment)
		{
			// No individual punishment selected. Using default one
			case -1:
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Default", client);
			}
			case 1:
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Print Message", client);
			}
			case 2:
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Bounce Back", client);
			}
			case 3:
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Slay player", client);
			}
			case 4:
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Only Knife", client);
			}
			case 5:
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Allow Weapons Again", client);
			}
		}
		
		Format(sMenuText, sizeof(sMenuText), "%T: %s", "Punishment", client, sBuffer);
		AddMenuItem(menu, "punishment", sMenuText);
		
		Format(sMenuText, sizeof(sMenuText), "%T", "Delete Zone", client);
	}
	else
		Format(sMenuText, sizeof(sMenuText), "%T", "Delete Fence", client);
	AddMenuItem(menu, "delete", sMenuText);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

ShowZoneVectorEditMenu(client)
{
	if(g_iPlayerEditsZone[client] == -1 || g_iPlayerEditsVector[client] == -1)
		return;
	
	// Get the zone name
	decl String:sZoneName[64], String:sMenuText[64];
	new Handle:hZone;
	if(g_iPlayerEditsType[client] == TYPE_ZONE)
		hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[client]);
	else
		hZone = GetArrayCell(g_hFences, g_iPlayerEditsZone[client]);
	
	GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
	
	new Handle:menu = CreateMenu(MenuHandler_EditVector);
	if(g_iPlayerEditsType[client] == TYPE_ZONE)
		SetMenuTitle(menu, "%T", "Edit Zone", client, sZoneName, g_iPlayerEditsVector[client]);
	else
		SetMenuTitle(menu, "%T", "Edit Fence", client, sZoneName, g_iPlayerEditsVector[client]);
	
	SetMenuExitBackButton(menu, true);
	
	Format(sMenuText, sizeof(sMenuText), "%T", "Add to X", client);
	AddMenuItem(menu, "ax", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Add to Y", client);
	AddMenuItem(menu, "ay", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Add to Z", client);
	AddMenuItem(menu, "az", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Subtract from X", client);
	AddMenuItem(menu, "sx", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Subtract from Y", client);
	AddMenuItem(menu, "sy", sMenuText);
	Format(sMenuText, sizeof(sMenuText), "%T", "Subtract from Z", client);
	AddMenuItem(menu, "sz", sMenuText);
	
	if(g_iPlayerEditsType[client] == TYPE_ZONE)
		Format(sMenuText, sizeof(sMenuText), "%T", "Show Zone", client);
	else
		Format(sMenuText, sizeof(sMenuText), "%T", "Show Fence", client);
	
	AddMenuItem(menu, "show", sMenuText);
		
	Format(sMenuText, sizeof(sMenuText), "%T", "Save", client);
	AddMenuItem(menu, "save", sMenuText);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

ParseZoneConfig()
{
	// Clear previous info
	CloseHandleArray(g_hZones);
	ClearArray(g_hZones);
	CloseHandleArray(g_hFences);
	ClearArray(g_hFences);
	
	decl String:sConfigFile[PLATFORM_MAX_PATH], String:inputMap[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH];
	GetCurrentMap(inputMap, sizeof(inputMap));
	GetMapDisplayName(inputMap, sMap, sizeof(sMap));
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/antirush/%s.cfg", sMap);
	
	if(!FileExists(sConfigFile))
	{
		//SetFailState("Can't find configfile: %s", sConfigFile);
		LogMessage("Error - can't find configfile: %s", sConfigFile);
		return;
	}
	
	new Handle:kv = CreateKeyValues("ZonesAndFences");
	FileToKeyValues(kv, sConfigFile);
	if(!KvGotoFirstSubKey(kv))
	{
		CloseHandle(kv);
		//SetFailState("Error parsing config file: %s", sConfigFile);
		return;
	}
	
	decl String:sBuffer[256];
	new Handle:hTempArray;
	new Float:fVec[3];
	new iZoneIndex, iTeam, iPunishment;
	do
	{
		KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer, "zones"))
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					hTempArray = CreateArray(ByteCountToCells(256));
					
					KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
					PushArrayString(hTempArray, sBuffer);
					
					KvGetVector(kv, "vec1", fVec);
					PushArrayArray(hTempArray, fVec, 3);
					
					KvGetVector(kv, "vec2", fVec);
					PushArrayArray(hTempArray, fVec, 3);
					
					iTeam = KvGetNum(kv, "team", 0);
					PushArrayCell(hTempArray, iTeam);
					
					// Increase zone count
					switch(iTeam)
					{
						// Both teams
						case 0:
						{
							g_iTeamZones[0]++;
							g_iTeamZones[1]++;
						}
						// First team
						case 2:
						{
							g_iTeamZones[0]++;
						}
						case 3:
						{
							g_iTeamZones[1]++;
						}
					}
					
					iPunishment = KvGetNum(kv, "punishment", -1);
					// Reset the punishment to the default, if sdkhooks isn't loaded
					if(!LibraryExists("sdkhooks") && iPunishment > 3)
						iPunishment = -1;
					PushArrayCell(hTempArray, iPunishment);
					
					iZoneIndex = PushArrayCell(g_hZones, hTempArray);
					
					SpawnTriggerMultipleInBox(iZoneIndex);
					
				} while (KvGotoNextKey(kv));
				KvGoBack(kv);
			}
		}
		else if(StrEqual(sBuffer, "fences"))
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					hTempArray = CreateArray(ByteCountToCells(256));
					
					KvGetString(kv, "name", sBuffer, sizeof(sBuffer));
					PushArrayString(hTempArray, sBuffer);
					
					KvGetVector(kv, "vec1", fVec);
					PushArrayArray(hTempArray, fVec, 3);
					
					KvGetVector(kv, "vec2", fVec);
					PushArrayArray(hTempArray, fVec, 3);
					
					iTeam = KvGetNum(kv, "team", 0);
					PushArrayCell(hTempArray, iTeam);
					
					// Increase zone count
					switch(iTeam)
					{
						// Both teams
						case 0:
						{
							g_iTeamZones[0]++;
							g_iTeamZones[1]++;
						}
						// First team
						case 2:
						{
							g_iTeamZones[0]++;
						}
						case 3:
						{
							g_iTeamZones[1]++;
						}
					}
					
					PushArrayCell(g_hFences, hTempArray);
					
				} while (KvGotoNextKey(kv));
				KvGoBack(kv);
			}
		}
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

stock CloseHandleArray(Handle:adt_array)
{
	new iSize = GetArraySize(adt_array);
	new Handle:hZone;
	for(new i=0;i<iSize;i++)
	{
		hZone = GetArrayCell(adt_array, i);
		CloseHandle(hZone);
	}
}

stock ClearVector(Float:vec[3])
{
	vec[0] = 0.0;
	vec[1] = 0.0;
	vec[2] = 0.0;
}

stock bool:IsNullVector(const Float:vec[3])
{
	if(vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0)
		return true;
	return false;
}

stock GetMiddleOfABox(const Float:vec1[3], const Float:vec2[3], Float:buffer[3])
{
	new Float:mid[3];
	MakeVectorFromPoints(vec1, vec2, mid);
	mid[0] = mid[0] / 2.0;
	mid[1] = mid[1] / 2.0;
	mid[2] = mid[2] / 2.0;
	AddVectors(vec1, mid, buffer);
}

stock SpawnTriggerMultipleInBox(iZoneIndex)
{
	new Float:fMiddle[3], Float:fMins[3], Float:fMaxs[3];
	
	decl String:sZoneName[128];
	new Handle:hZone = GetArrayCell(g_hZones, iZoneIndex);
	GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
	GetArrayArray(hZone, 1, fMins, 3);
	GetArrayArray(hZone, 2, fMaxs, 3);
	
	new iEnt = CreateEntityByName("trigger_multiple");
	
	DispatchKeyValue(iEnt, "spawnflags", "64");
	Format(sZoneName, sizeof(sZoneName), "sm_zone %s", sZoneName);
	DispatchKeyValue(iEnt, "targetname", sZoneName);
	DispatchKeyValue(iEnt, "wait", "0");
	
	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);
	SetEntProp(iEnt, Prop_Data, "m_spawnflags", 64 );
	
	GetMiddleOfABox(fMins, fMaxs, fMiddle);
	
	TeleportEntity(iEnt, fMiddle, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(iEnt, "models/items/car_battery01.mdl");
	
	// Have the mins always be negative
	fMins[0] = fMins[0] - fMiddle[0];
	if(fMins[0] > 0.0)
		fMins[0] *= -1.0;
	fMins[1] = fMins[1] - fMiddle[1];
	if(fMins[1] > 0.0)
		fMins[1] *= -1.0;
	fMins[2] = fMins[2] - fMiddle[2];
	if(fMins[2] > 0.0)
		fMins[2] *= -1.0;
	
	// And the maxs always be positive
	fMaxs[0] = fMaxs[0] - fMiddle[0];
	if(fMaxs[0] < 0.0)
		fMaxs[0] *= -1.0;
	fMaxs[1] = fMaxs[1] - fMiddle[1];
	if(fMaxs[1] < 0.0)
		fMaxs[1] *= -1.0;
	fMaxs[2] = fMaxs[2] - fMiddle[2];
	if(fMaxs[2] < 0.0)
		fMaxs[2] *= -1.0;
	
	SetEntPropVector(iEnt, Prop_Send, "m_vecMins", fMins);
	SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", fMaxs);
	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 2);
	
	new iEffects = GetEntProp(iEnt, Prop_Send, "m_fEffects");
	iEffects |= 32;
	SetEntProp(iEnt, Prop_Send, "m_fEffects", iEffects);
	
	HookSingleEntityOutput(iEnt, "OnStartTouch", EntOut_OnStartTouch);
}

stock KillTriggerEntity(iZoneIndex)
{
	new Handle:hZone;
	decl String:sZoneName[128];
	hZone = GetArrayCell(g_hZones, iZoneIndex);
	GetArrayString(hZone, 0, sZoneName, sizeof(sZoneName));
	Format(sZoneName, sizeof(sZoneName), "sm_zone %s", sZoneName);
	
	new iEnts = GetMaxEntities();
	decl String:sClassName[256];
	for(new i=MaxClients;i<iEnts;i++)
	{
		if(IsValidEntity(i)
		&& IsValidEdict(i)
		&& GetEdictClassname(i, sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "trigger_multiple") != -1
		&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
		&& StrEqual(sClassName, sZoneName, false))
		{
			UnhookSingleEntityOutput(i, "OnStartTouch", EntOut_OnStartTouch);
			AcceptEntityInput(i, "Kill");
			break;
		}
	}
}

/**
 * Sets up a boxed beam effect.
 * 
 * Ported from eventscripts vecmath library
 *
 * @param client		The client to show the box to.
 * @param uppercorner	One upper corner of the box.
 * @param bottomcorner	One bottom corner of the box.
 * @param ModelIndex	Precached model index.
 * @param HaloIndex		Precached model index.
 * @param StartFrame	Initital frame to render.
 * @param FrameRate		Beam frame rate.
 * @param Life			Time duration of the beam.
 * @param Width			Initial beam width.
 * @param EndWidth		Final beam width.
 * @param FadeLength	Beam fade time duration.
 * @param Amplitude		Beam amplitude.
 * @param color			Color array (r, g, b, a).
 * @param Speed			Speed of the beam.
 * @noreturn
 */
stock TE_SendBeamBoxToClient(client, const Float:uppercorner[3], const Float:bottomcorner[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
{
	// Create the additional corners of the box
	new Float:tc1[3];
	AddVectors(tc1, uppercorner, tc1);
	tc1[0] = bottomcorner[0];
	new Float:tc2[3];
	AddVectors(tc2, uppercorner, tc2);
	tc2[1] = bottomcorner[1];
	new Float:tc3[3];
	AddVectors(tc3, uppercorner, tc3);
	tc3[2] = bottomcorner[2];
	new Float:tc4[3];
	AddVectors(tc4, bottomcorner, tc4);
	tc4[0] = uppercorner[0];
	new Float:tc5[3];
	AddVectors(tc5, bottomcorner, tc5);
	tc5[1] = uppercorner[1];
	new Float:tc6[3];
	AddVectors(tc6, bottomcorner, tc6);
	tc6[2] = uppercorner[2];
	
	// Draw all the edges
	TE_SetupBeamPoints(uppercorner, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(uppercorner, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(uppercorner, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
}

/**
 * Prints a message to all clients in a team in the chat area.
 *
 * @param team			Team index.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
stock PrintToChatTeam(const team, const String:format[], any:...)
{
	decl String:buffer[192];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			PrintToChat(i, "%s", buffer);
		}
	}
}

/**
 * Counts all alive players in a team
 *
 * @param team			Team index.
 * @return				Alive player count
 */
stock GetTeamClientCountAlive(team)
{
	new iCount = 0;
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
		{
			iCount++;
		}
	}
	
	return iCount;
}