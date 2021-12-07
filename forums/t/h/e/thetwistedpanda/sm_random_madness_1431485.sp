#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "1.0.5"

#define SLOT_HEGRENADE 11
#define SLOT_FBGRENADE 12
#define SLOT_SMGRENADE 13

#define NUM_WEAPONS 26 //0 - 25
new String:g_sWeapons[NUM_WEAPONS][24] = 
{
	"knife", "glock", "usp", "p228", "deagle",
	"elite", "fiveseven", "m3", "xm1014", "galil",
	"ak47", "scout", "sg552", "awp", "g3sg1",
	"famas", "m4a1", "aug", "sg550", "mac10",
	"tmp", "mp5navy", "ump45", "p90", "m249",
	"hegrenade"
};
	
new Handle:g_hEnable = INVALID_HANDLE;
new Handle:g_hDisabled = INVALID_HANDLE;
new Handle:g_hRounds = INVALID_HANDLE;
new Handle:g_hSpawnKnife = INVALID_HANDLE;
new Handle:g_hSpawnGrenade = INVALID_HANDLE;
new Handle:g_hSpawnT = INVALID_HANDLE;
new Handle:g_hSpawnCt = INVALID_HANDLE;
new Handle:g_hGrenadeCount = INVALID_HANDLE;
new Handle:g_hTourneyMode = INVALID_HANDLE;
new Handle:g_hRoundAdvert = INVALID_HANDLE;
new Handle:g_hSpawnArmor = INVALID_HANDLE;
new Handle:g_hStripDeath = INVALID_HANDLE;
new Handle:g_hStripBuy = INVALID_HANDLE;
new Handle:g_hStripObjectives = INVALID_HANDLE;
new Handle:g_hStripWeapons = INVALID_HANDLE;
new Handle:g_hStripGrenades = INVALID_HANDLE;
new Handle:g_hEnabledWeapons = INVALID_HANDLE;
new Handle:g_hDisabledWeapons = INVALID_HANDLE;

new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bEnding, bool:g_bSpawnKnife, bool:g_bStripDeath, bool:g_bStripBuy, bool:g_bStripObjectives, bool:g_bStripWeapons, bool:g_bStripGrenades, bool:g_bTourneyMode, bool:g_bRoundAdvert, bool:g_bSpawnGrenade, bool:g_bGrenadeLevel;
new g_iMyWeapons = -1, g_iRounds, g_iWaited, g_iDisabled, g_iEnabled, g_iCurrent, g_iSpawnArmor, g_iGrenadeCount, g_iSpawnT, g_iSpawnCt;
new String:g_sWeapon[24], String:g_sSpawnT[8][32], String:g_sSpawnCt[8][32];

new g_iTeam[MAXPLAYERS + 1];
new g_iGrenades[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Random Madness",
	author = "Twisted|Panda",
	description = "A gametype that forces all players to use the same weapon, which is randomly selected each round.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_randommadness_version", PLUGIN_VERSION, "Random Madness: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnable = CreateConVar("sm_randommadness_enable", "1", "Enables/Disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDisabled = CreateConVar("sm_randommadness_disabled", "", "List of specific weapon names to disable from being randomly selected, comma limited \"awp, sg550, g3sg1\"", FCVAR_NONE);
	g_hRounds = CreateConVar("sm_randommadness_rounds", "1", "The number of rounds to spend on each weapon. Setting a value of 0 will result in the same weapon for the entire map.", FCVAR_NONE, true, 0.0);
	g_hSpawnKnife = CreateConVar("sm_randommadness_spawn_knife", "1", "If enabled, players will spawn with a knife if not on a knife level.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnGrenade = CreateConVar("sm_randommadness_spawn_grenade", "0", "If enabled, players will spawn with a grenade if not on a knife level.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnT = CreateConVar("sm_randommadness_spawn_t", "item_nvgs", "The additional gear players on the Terrorist team will spawn with, separate multiple items with \", \".", FCVAR_NONE);
	g_hSpawnCt = CreateConVar("sm_randommadness_spawn_ct", "item_nvgs, item_defuser", "The additional gear players on the Counter-Terrorist team will spawn with, separate multiple items with \", \".", FCVAR_NONE);
	g_hGrenadeCount = CreateConVar("sm_randommadness_grenade_count", "0", "The number of grenades players will get when on the grenade level. Set to 0 for infinite grenades.", FCVAR_NONE, true, 0.0);
	g_hTourneyMode = CreateConVar("sm_randommadness_tourney_mode", "0", "If enabled, every weapon will be used once before being able to be used again.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hRoundAdvert = CreateConVar("sm_randommadness_round_advert", "1", "If enabled, a message pertaining to the game tyep will be displayed each round.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnArmor = CreateConVar("sm_randommadness_spawn_armor", "0", "The amount of armor players will spawn with. Values above 0 will also give players the helmet.", FCVAR_NONE, true, 0.0);
	g_hStripDeath = CreateConVar("sm_randommadness_strip_death", "1", "If enabled, a player's equipment will be stripped upon their death.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hStripBuy = CreateConVar("sm_randommadness_strip_buy", "1", "If enabled, all buyzones will be stripped from the map at the start of the round.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hStripObjectives = CreateConVar("sm_randommadness_strip_objectives", "0", "If enabled, all objectives will be stripped from the map at the start of the round.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hStripWeapons = CreateConVar("sm_randommadness_strip_weapons", "1", "If enabled, all weapons will be stripped from the map at the start of the round.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hStripGrenades = CreateConVar("sm_randommadness_strip_grenades", "0", "If enabled, all grenades will be stripped from the map at the start of the round if sm_randommadness_strip_weapons is enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_random_madness");

	HookConVarChange(g_hEnable, Action_OnSettingsChange);
	HookConVarChange(g_hDisabled, Action_OnSettingsChange);
	HookConVarChange(g_hRounds, Action_OnSettingsChange);
	HookConVarChange(g_hSpawnKnife, Action_OnSettingsChange);
	HookConVarChange(g_hSpawnGrenade, Action_OnSettingsChange);
	HookConVarChange(g_hSpawnT, Action_OnSettingsChange);
	HookConVarChange(g_hSpawnCt, Action_OnSettingsChange);
	HookConVarChange(g_hGrenadeCount, Action_OnSettingsChange);
	HookConVarChange(g_hTourneyMode, Action_OnSettingsChange);
	HookConVarChange(g_hRoundAdvert, Action_OnSettingsChange);
	HookConVarChange(g_hSpawnArmor, Action_OnSettingsChange);
	HookConVarChange(g_hStripDeath, Action_OnSettingsChange);
	HookConVarChange(g_hStripBuy, Action_OnSettingsChange);
	HookConVarChange(g_hStripObjectives, Action_OnSettingsChange);
	HookConVarChange(g_hStripWeapons, Action_OnSettingsChange);
	HookConVarChange(g_hStripGrenades, Action_OnSettingsChange);
	
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_Pre);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("hegrenade_detonate", Event_OnGrenadeBoom, EventHookMode_Post);
	g_hEnabledWeapons = CreateArray(24);
	g_hDisabledWeapons = CreateArray(24);

	g_iMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	if(g_iMyWeapons == -1)
		SetFailState("Unable to locate the CBasePlayer offset \"m_hMyWeapons\"! (CS:S Only!)");
}

public OnPluginEnd()
{
	if(g_hDisabledWeapons != INVALID_HANDLE)
		ClearArray(g_hDisabledWeapons);

	if(g_hEnabledWeapons != INVALID_HANDLE)
		ClearArray(g_hEnabledWeapons);
}

public OnMapStart()
{
	Void_SetDefaults();

	if(g_bEnabled)
	{
		g_iWaited = g_iRounds == 0 ? -1 : 0;
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		decl String:_sBuffer[1024];
		GetConVarString(g_hDisabled, _sBuffer, sizeof(_sBuffer));
		Void_PopulateArray(_sBuffer);
		
		g_iCurrent = GetRandomInt(0, (g_iEnabled - 1));
		GetArrayString(g_hEnabledWeapons, g_iCurrent, g_sWeapon, sizeof(g_sWeapon));
		if(g_iWaited == -1)
			g_iWaited--;

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
					
					if(IsPlayerAlive(i))
						CreateTimer(0.1, Timer_Gear, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
				}
				else
					g_iTeam[i] = 0;
			}

			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_iGrenades[client] = 0;
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;

		decl String:_sClassName[64];
		new _iTemp = GetMaxEntities();
		for(new i = (MaxClients + 1); i <= _iTemp; i++)
		{
			if(!IsValidEdict(i) || !IsValidEntity(i))
				continue;

			GetEdictClassname(i, _sClassName, sizeof(_sClassName));			
			if(g_bStripBuy && StrContains("func_buyzone", _sClassName) > -1)
			{
				AcceptEntityInput(i, "Kill");
				continue;
			}
			
			if(g_bStripObjectives && StrContains("func_bomb_target|func_hostage_rescue|c4|hostage_entity", _sClassName) > -1)
			{
				AcceptEntityInput(i, "Kill");
				continue;
			}
			
			if(g_bStripWeapons && StrContains("weapon_", _sClassName) > -1)
			{
				if(!g_bStripGrenades && StrContains("hegrenade|smokegrenade|flashbang", _sClassName) > -1)
					continue;

				AcceptEntityInput(i, "Kill");
				continue;
			}
		}
		
		if(g_iRounds > 1)
		{
			decl String:_sBuffer[128];
			Format(_sBuffer, sizeof(_sBuffer), "%s, Round %d/%d!", g_sWeapon, (g_iWaited + 1), g_iRounds);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					new Handle:_hKv = CreateKeyValues("Stuff", "Title", _sBuffer);
					KvSetColor(_hKv, "color", 255, 255, 255, 255);
					KvSetNum(_hKv, "level", 1);
					KvSetNum(_hKv, "time", 10);
					CreateDialog(i, _hKv, DialogType_Msg);
					CloseHandle(_hKv);
				}
			}
		}
		
		if(g_bRoundAdvert)
		{
			if(!g_iRounds)
				PrintToChatAll("\x03This server is running \x04Random Madness\x03! The %s has been selected at random to be used for this map!", g_sWeapon[7]);
			else if(g_iRounds == 1)
				PrintToChatAll("\x03This server is running \x04Random Madness\x03! A weapon will be randomly selected every round for players to use!");
			else
				PrintToChatAll("\x03This server is running \x04Random Madness\x03! A weapon will be randomly selected every %d rounds for players to use!", g_iRounds);
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;

		new _iReason = GetEventInt(event, "reason");
		if(_iReason != 10 && _iReason != 16)
		{
			if(g_bTourneyMode)
			{
				new _iIndex = FindStringInArray(g_hEnabledWeapons, g_sWeapon);
				RemoveFromArray(g_hEnabledWeapons, _iIndex);
				g_iEnabled--;

				if(g_iEnabled <= 0)
				{
					decl String:_sBuffer[1024];
					GetConVarString(g_hDisabled, _sBuffer, sizeof(_sBuffer));
					Void_PopulateArray(_sBuffer);
				}
			}

			if(g_iRounds)
				g_iWaited++;

			if(g_iWaited >= g_iRounds)
			{
				g_iWaited = 0;
				g_iCurrent = GetRandomInt(0, (g_iEnabled - 1));
				GetArrayString(g_hEnabledWeapons, g_iCurrent, g_sWeapon, sizeof(g_sWeapon));
				
				g_bGrenadeLevel = StrEqual(g_sWeapon, "weapon_hegrenade", false) ? true : false;
				for(new i = 1; i <= MaxClients; i++)
					g_iGrenades[i] = 0;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= 1)
			return Plugin_Continue;
		
		CreateTimer(0.1, Timer_Gear, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
		
		g_iTeam[client] = GetEventInt(event, "team");
	}
	
	return Plugin_Continue;
}

public Action:Event_OnGrenadeBoom(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled && !g_bEnding && g_bGrenadeLevel)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
			return Plugin_Continue;

		if(!g_iGrenadeCount || g_iGrenades[client] < g_iGrenadeCount)
		{
			g_iGrenades[client]++;
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Gear(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsPlayerAlive(client))
	{
		decl String:_sClassname[64];
		for (new i = 0, _iEntity; i < 128; i += 4) 
		{
			_iEntity = GetEntDataEnt2(client, g_iMyWeapons + i);
			if(_iEntity > 0)
			{
				GetEdictClassname(_iEntity, _sClassname, sizeof(_sClassname));
				if(g_bSpawnKnife && StrEqual(_sClassname, "weapon_knife"))
					continue;
				else if(g_bSpawnGrenade && StrEqual(_sClassname, "weapon_hegrenade"))
					continue;
				else if(!g_bStripObjectives && StrEqual(_sClassname, "weapon_c4"))
					continue;
				
				AcceptEntityInput(_iEntity, "Kill");
			}
		}
		
		GivePlayerItem(client, g_sWeapon);
		FakeClientCommand(client, "use %s", g_sWeapon);
		
		SetEntProp(client, Prop_Send, "m_ArmorValue", g_iSpawnArmor);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", g_iSpawnArmor ? 1 : 0);
		
		switch(g_iTeam[client])
		{
			case CS_TEAM_T:
				for(new i = 0; i < g_iSpawnT; i++)
					GivePlayerItem(client, g_sSpawnT[i]);
			case CS_TEAM_CT:
				for(new i = 0; i < g_iSpawnCt; i++)
					GivePlayerItem(client, g_sSpawnCt[i]);
		}

		if(!g_bGrenadeLevel && g_bSpawnGrenade && !GetGrenadeCount(client, SLOT_HEGRENADE))
			GivePlayerItem(client, "weapon_hegrenade");
	}
}

public Action:Hook_WeaponDrop(client, weapon)
{
	if (g_bStripDeath && weapon > 0 && IsValidEdict(weapon) && GetClientHealth(client) <= 0)
		AcceptEntityInput(weapon, "Kill");

	return Plugin_Continue;
}

GetGrenadeCount(client, type)
{
	new offsAmmo = FindDataMapOffs(client, "m_iAmmo") + (type * 4);
	
	return GetEntData(client, offsAmmo);
}

Void_PopulateArray(const String:_sDisabled[] = "")
{
	decl String:_sBuffer[24], String:_sValues[NUM_WEAPONS][24];
	ClearArray(g_hDisabledWeapons);
	ClearArray(g_hEnabledWeapons);
	
	g_iDisabled = ExplodeString(_sDisabled, ", ", _sValues, NUM_WEAPONS, 24);
	for(new i = 0; i < NUM_WEAPONS; i++)
	{
		new bool:skip = false;
		for(new j = 0; j < g_iDisabled; j++)
		{
			if(StrEqual(g_sWeapons[i], _sValues[j], false))
			{
				skip = true;
				break;
			}
		}

		if(!skip)
		{
			Format(_sBuffer, sizeof(_sBuffer), "weapon_%s", g_sWeapons[i]);
			PushArrayString(g_hEnabledWeapons, _sBuffer);
		}
	}

	g_iEnabled = GetArraySize(g_hEnabledWeapons);
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnable) ? true : false;
	g_iRounds = GetConVarInt(g_hRounds);
	g_bSpawnKnife = GetConVarInt(g_hSpawnKnife) ? true : false;
	g_bStripDeath = GetConVarInt(g_hStripDeath) ? true : false;
	g_bStripBuy = GetConVarInt(g_hStripBuy) ? true : false;
	g_bStripObjectives = GetConVarInt(g_hStripObjectives) ? true : false;
	g_bStripWeapons = GetConVarInt(g_hStripWeapons) ? true : false;
	g_bStripGrenades = GetConVarInt(g_hStripGrenades) ? true : false;
	g_bTourneyMode = GetConVarInt(g_hTourneyMode) ? true : false;
	g_bRoundAdvert = GetConVarInt(g_hRoundAdvert) ? true : false;
	g_iSpawnArmor = GetConVarInt(g_hSpawnArmor);
	g_bSpawnGrenade = GetConVarInt(g_hSpawnGrenade) ? true : false;
	g_iGrenadeCount = GetConVarInt(g_hGrenadeCount);
	
	decl String:_sBuffer[128];
	GetConVarString(g_hSpawnT, _sBuffer, sizeof(_sBuffer));
	g_iSpawnT = ExplodeString(_sBuffer, ", ", g_sSpawnT, 8, 32);
	GetConVarString(g_hSpawnCt, _sBuffer, sizeof(_sBuffer));
	g_iSpawnCt = ExplodeString(_sBuffer, ", ", g_sSpawnCt, 8, 32);
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnable)
	{
		g_bEnabled = StringToInt(newvalue) ? true : false;
		if(!StringToInt(oldvalue))
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
				}
				else
					g_iTeam[i] = 0;
			}
		}
	}
	else if(cvar == g_hRounds)
	{
		g_iRounds = StringToInt(newvalue);
		g_iWaited = g_iRounds == 0 ? -1 : 0;
	}
	else if(cvar == g_hSpawnKnife)
		g_bSpawnKnife = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSpawnGrenade)
		g_bSpawnGrenade = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripDeath)
		g_bStripDeath = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripBuy)
		g_bStripBuy = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripObjectives)
		g_bStripObjectives = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripWeapons)
		g_bStripWeapons = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripGrenades)
		g_bStripGrenades = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hDisabled)
		Void_PopulateArray(newvalue);
	else if(cvar == g_hTourneyMode)
		g_bTourneyMode = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hRoundAdvert)
		g_bRoundAdvert = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSpawnArmor)
		g_iSpawnArmor = StringToInt(newvalue);
	else if(cvar == g_hGrenadeCount)
		g_iGrenadeCount = StringToInt(newvalue);
	else if(cvar == g_hSpawnT)
		g_iSpawnT = ExplodeString(newvalue, ", ", g_sSpawnT, 8, 32);
	else if(cvar == g_hSpawnCt)
		g_iSpawnCt = ExplodeString(newvalue, ", ", g_sSpawnCt, 8, 32);
}