/**
 * Knife Warmup - SourceMod plugin to provide knife warmup facilities for CSS games
 * http://www.miketomasello.net/
 * Copyright (C) 2007 Mike Tomasello <miketomasello@gmail.com>
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

new const String:PLUGIN_VERSION[] = "1.4.46";

new handle:g_hStatusCvar;

new Handle:hGameConf;
new Handle:hRoundRespawn;
new Handle:hRemoveItems;
new handle:hGiveNamedItem;

new g_nActiveOffset = 1896;
new g_nClipOffset = 1204;

new String:g_szWeapon[32];
new g_nWaitTime = 0;
new g_nUseKnife = 1;
new g_bStarted = false;
new g_bRunning = false;
new g_nSecondsPassed = 0;

new String:g_szUserWeapons[][32];
new String:g_szWeaponList[26][32] = {
	"knife",
	"hegrenade",
	"galil",
	"ak47",
	"scout",
	"sg552",
	"awp",
	"g3sg1",
	"famas",
	"m4a1",
	"aug",
	"sg550",
	"glock",
	"usp",
	"p228",
	"deagle",
	"elite",
	"fiveseven",
	"m3",
	"xm1014",
	"mac10",
	"tmp",
	"mp5navy",
	"ump45",
	"p90",
	"m249"
};

public Plugin:myinfo = {
	name = "Warmup",
	author = "Mike Tomasello",
	description = "When a new map loads, players will be given a specific weapon (or a random weapon) for a set number of seconds while other players finish connecting to the server, so that the game can begin proper.",
	version = PLUGIN_VERSION,
	url = "http://www.miketomasello.net/"
};

public OnPluginStart()
{
	// Create plugin version cvar
	CreateConVar(
		"sm_warmup_version",
		PLUGIN_VERSION,
		"Version of Warmup plugin",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
	);
	
	// Create status cvar
	g_hStatusCvar = CreateConVar(
		"sm_warmup_status",
		"0",
		"Status of Warmup plugin",
		FCVAR_PLUGIN
	);
	
	// Create warmup time cvar
	CreateConVar(
		"sm_warmup_time",
		"60",
		"The amount of seconds that the Warmup takes before the game starts.",
		FCVAR_PLUGIN,
		true,
		30.0
	);
	
	// Create weapon choice cvar  
	CreateConVar(
		"sm_warmup_weapon",
		"knife",
		"The weapon that should be granted to players during warmup.",
		FCVAR_PLUGIN
	);

	// Create knife use cvar  
	CreateConVar(
		"sm_warmup_knifetoo",
		"0",
		"If sm_warmup_weapon is not 'knife', this cvar dictates whether a player should be given a knife as well as the warmup weapon.",
		FCVAR_PLUGIN
	);
	
	// Create post warmup config cvar  
	CreateConVar(
		"sm_warmup_postconfig",
		"sourcemod/afterwarmup.cfg",
		"The location of the config file to execute when a warmup finishes, relative to the mod's cfg folder.",
		FCVAR_PLUGIN
	);

	// get config file for SDKTools signatures/offets 
	hGameConf = LoadGameConfigFile("warmup.games");
	
	// load translations 
	LoadTranslations("warmup.phrases");
	
	// Prep SDK call for respawning 
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	
	// Prep SDK call for disarming 
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hRemoveItems = EndPrepSDKCall();
	
	// Prep SDK call for giving back a knife 
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hGiveNamedItem = EndPrepSDKCall();
	
	// Hook death event for respawning and weapon equip for knife only 
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_TeamSelected);
	HookEvent("hegrenade_detonate", Event_GrenadeDetonate);
	HookEvent("flashbang_detonate", Event_GrenadeDetonate);
	HookEvent("smokegrenade_detonate", Event_GrenadeDetonate);
	
	// Prepare infinite ammo send property offsets
	new nOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	if (nOffset != -1) g_nActiveOffset = nOffset;
	nOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	if (nOffset != -1) g_nClipOffset = nOffset;
}

public OnMapStart()
{
	// update convars
	GetConVarString(FindConVar("sm_warmup_weapon"), g_szWeapon, sizeof(g_szWeapon));
	g_nUseKnife = GetConVarInt(FindConVar("sm_warmup_knifetoo"));
	g_nWaitTime = GetConVarInt(FindConVar("sm_warmup_time"));
	
	SetRandomSeed(GetEngineTime());
	
	// detect random mode
	if (!(StrContains(g_szWeapon, "random") != 0)) g_szWeapon = GetRandomWeapon();

	// reset counter/tracking variables
	g_bStarted = false;
	g_bRunning = false;
	g_nSecondsPassed = 0;
}


WriteCountDownHint(secondsRemaining)
{
	decl String:parsedMessage[192];
	Format(parsedMessage, sizeof(parsedMessage), "%T", "Seconds before game begins", LANG_SERVER, secondsRemaining);
	decl String:infoMessage[192];
	Format(infoMessage, sizeof(infoMessage), "%T", "Currently on warmup mode", LANG_SERVER);
	
	decl String:szHintMessage[192];
	Format(szHintMessage, sizeof(szHintMessage), "%s\n%s", infoMessage, parsedMessage);
	
	new Handle:HintMessage = StartMessageAll("HintText", USERMSG_RELIABLE);
	BfWriteByte(HintMessage, -1);
	BfWriteString(HintMessage, szHintMessage);
	EndMessage();
}

GetRandomWeapon()
{
	decl String:weapon[32];
	weapon = g_szWeaponList[GetRandomInt(0, 25)];

	// returns a random weapon from the weapon array
	return weapon;
}

GivePlayerWeapon(playerId)
{
	decl String:weapon[32];
	
	if (strcmp(g_szWeapon, "haphazard") != 0)
		Format(weapon, sizeof(weapon), "weapon_%s", g_szWeapon);
	else
		Format(weapon, sizeof(weapon), "weapon_%s", g_szUserWeapons[GetClientOfUserId(playerId)]);
	
	SDKCall(hRemoveItems, GetClientOfUserId(playerId), false);
	SDKCall(hGiveNamedItem, GetClientOfUserId(playerId), weapon, 0);
	
	// check if the weapon given was a knife, if not we may have to give them one too
	if ((strcmp(g_szWeapon, "knife") != 0) && (g_nUseKnife == 1))
	{
		SDKCall(hGiveNamedItem, GetClientOfUserId(playerId), "weapon_knife", 0);
	}
}

public Action:WarmupTimerTick(Handle:timer)
{
	g_nSecondsPassed++;

	WriteCountDownHint(g_nWaitTime - g_nSecondsPassed);
	
	if (g_nSecondsPassed >= g_nWaitTime - 1)
	{
		// Load ending config file
		decl string:configFile[128];
		GetConVarString(FindConVar("sm_warmup_postconfig"), configFile, sizeof(configFile));
		ServerCommand("exec %s", configFile);

		// warmup is over
		ServerCommand("mp_restartgame 1");
		SetConVarInt(g_hStatusCvar, 0);
		PrintToChatAll("[SM] %T", "Warmup over", LANG_SERVER);
		g_bRunning = false;
	
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:RespawnPlayer(Handle:timer, any:playerId)
{
	new playerIndex = GetClientOfUserId(playerId);
	
	// if it is haphazard mode, assign them a new weapon
	if (!(strcmp(g_szWeapon, "haphazard") != 0)) g_szUserWeapons[playerIndex] = GetRandomWeapon();
		
	// make sure they are dead
	if (!(GetEntData(playerIndex, FindSendPropOffs("CBasePlayer", "m_lifeState"), 1) == 0))
	{
		SDKCall(hRoundRespawn, playerIndex);
	}
	
	return Plugin_Handled;
}

public Action:DisarmPlayer(Handle:timer, any:playerId)
{
	GivePlayerWeapon(playerId);	

	return Plugin_Handled;
}

public Event_TeamSelected(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (!g_bRunning) return;
		
	if (!GetEventBool(event, "disconnect"))
	{
		new teamId = GetEventInt(event, "team");
		if (teamId > 1)
		{
			new playerId = GetEventInt(event, "userid");
			g_szUserWeapons[GetClientOfUserId(playerId)] = GetRandomWeapon();
			CreateTimer(0.6, RespawnPlayer, playerId);
		}
	}
}

public Event_GrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bRunning) return;

	new playerId = GetEventInt(event, "userid");
	GivePlayerWeapon(playerId);
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bRunning) return;
	
	new playerId = GetEventInt(event, "userid");	

	// get entity handle info for ammo data offset
	new hAmmoOffset = GetEntDataEnt(GetClientOfUserId(playerId), g_nActiveOffset);
	// get current ammo
	new nCurrentAmmo = GetEntData(hAmmoOffset, g_nClipOffset);
	// send change over network
	SetEntData(hAmmoOffset, g_nClipOffset, nCurrentAmmo + 1, 4, true);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bStarted)
	{
		g_bStarted = true;
		g_bRunning = true;
		SetConVarInt(g_hStatusCvar, 1);
		CreateTimer(1.0, WarmupTimerTick, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (g_bStarted && g_bRunning)
	{
		PrintToChatAll("[SM] %T", "Seconds before game begins", LANG_SERVER, g_nWaitTime - g_nSecondsPassed);
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bRunning) return;
	
	// get player killed and respawn her
	new victimId = GetEventInt(event, "userid");
	// if we were to insta respawn then all sorts of evil problems begin to occur
	CreateTimer(0.2, RespawnPlayer, victimId);
}

public Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bRunning) return;
	
	new String:item[32];
	GetEventString(event, "item", item, 32);
	
	if (strcmp(g_szWeapon, "haphazard") != 0)
	{
		if ((strcmp(item, g_szWeapon) != 0) && (strcmp(item, "knife") != 0))
		{
			new userId = GetEventInt(event, "userid");
			CreateTimer(0.1, DisarmPlayer, userId);
		}
	}
	else
	{
		new userId = GetEventInt(event, "userid");
		
		if ((strcmp(item, g_szUserWeapons[GetClientOfUserId(userId)]) != 0) && (strcmp(item, "knife") != 0))
		{
			CreateTimer(0.1, DisarmPlayer, userId);
		}
	}
}