///Description////////////////////////////////////////////////////////////////////
// ChaseMod is the CS GO version of the former HideNSeek mod (HNS) for CS 1.6.
// In ChaseMod the CTs, with only knives at their disposal, try to catch the Ts. 
// Terrorists can't attack, so they have to run and perform tricks to escape or even kill the CTs.
// If CTs don't manage to kill all the Ts until the round ends, they lose.
// Maps for this mod should have a cm_ or hns_ prefix in their name, altough it's not mandatory.
// The same maps should allow various tricks such as highjumps, ladderjumps, surfs, bhops...
//////////////////////////////////////////////////////////////////////////////////

///TODOs//////////////////////////////////////////////
// set player carrying grenade running speed to 250
// fix first freeze timer going mad (actual freezetime bigger than convar freezetime)
// add possibility to change grenade run speed to knife run speed (bugged atm)
// don't allow Ts to throw grenades before countdown is over
// change the name to HNS as requested by community
// add collision convars, not just enforce no teammate collision
// add max number of grenades a T can get
// molotov no damage on Ts
// add possibility to hide the radar
// add freeze grenades
// add in-game info about the mod
// global countdown at start (with maybe sounds)
//////////////////////////////////////////////////////

//done since last update
/*
 * cts can no longer pickup grenades (they will be left on the ground)
 * fixed grenade probability simulation
 * fixed T knife animation for good
 * fixed client 0 and dividing by 0 errors in log
*/

///CVARs/////////////////////////////////////////////////////////////////////////////
// cm_freezetime - Seconds before CTs can move at roundstart;
// cm_freezeblind - Decides if CTs get blinded or not when frozen (0 - Disabled, 1 - Enabled)
// cm_airaccelerate - The value at which sv_airaccelerate is being kept;
// cm_roundpoints - Bonus points for every winning player;
// cm_bonuspoints - Bonus points for killing as a CT and for surviving as a T;
// cm_maximumwins - Maximum consecutive rounds won by T before the teams get swapped;
// cm_flashbangchance - The chance of getting a Flashbang as a Terrorist;
// cm_molotovchance - The chance of getting a Molotov as a Terrorist;
// cm_smokegrenadechance - The chance of getting a Smoke Grenade as a Terrorist.
// cm_noflashblind - Removes the flashbang blind effect for Ts and Spectators (0 - Disabled, 1 - Ts only, 2 Ts and Spec)
// cm_blockjointeam - Blocks the ability of players to join a team (0 - Disabled, 1 - Enabled)
/////////////////////////////////////////////////////////////////////////////////////

//Credits go to Exolent for the original HideNSeek mod
//Thanks to: TESLA-X4, Doc-Holiday, Vladislav Dolgov and Jannik Hartung whose code helped me a lot.

#include <sourcemod>
#include <protobuf>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

// ConVars
#define PLUGIN_VERSION		"1.2.1"
#define FREEZE_TIME 		"8.0"
#define AIR_ACC				"120"
#define ROUND_POINTS		"3"
#define BONUS_POINTS		"2"
#define MAXIMUM_ROUNDS		"3"
#define FLASHBANG_CHANCE	"0.25"
#define MOLOTOV_CHANCE		"0.35"
#define	SMOKE_CHANCE		"0.4"
#define BLIND_CTS			"1"
#define NO_FLASH_BLIND		"2"		
#define BLOCK_JOIN_TEAM		"1"

// Fade Defines
#define FFADE_IN			0x0001
#define FFADE_OUT			0x0002
#define FFADE_MODULATE		0x0004
#define FFADE_STAYOUT		0x0008
#define FFADE_PURGE			0x0010
#define BLIND_COLORS		{6,42,120,228}	// Catalina Blue

public Plugin:myinfo =
{
	name = "ChaseMod",
	author = "ceLoFaN",
	description = "CTs with only knives chase the Ts",
	version = PLUGIN_VERSION,
	url = "steamcommunity.com/id/celofan"
};

new Handle:g_hFreezeTime = INVALID_HANDLE;
new Handle:g_hAirAccelerate = INVALID_HANDLE;
new Handle:g_hRoundPoints = INVALID_HANDLE;
new Handle:g_hBonusPoints = INVALID_HANDLE;
new Handle:g_hMaximumWins = INVALID_HANDLE;
new Handle:g_hFlashbangChance = INVALID_HANDLE;
new Handle:g_hMolotovChance = INVALID_HANDLE;
new Handle:g_hSmokeGrenadeChance = INVALID_HANDLE;
new Handle:g_hFreezeBlind = INVALID_HANDLE;
new Handle:g_hNoFlashBlind= INVALID_HANDLE;
new Handle:g_hBlockJoinTeam = INVALID_HANDLE;

//Roundstart vars	
new Float:g_fRoundStartTime; 	// Save the game time when the round starts
new g_iDeathTerroristsCount;	// Counts Terrorists deaths during a round
new g_iTCount;					// Counts the number of Ts at roundstart
new bool:g_bBombFound;			// Records if the bomb has been found
new bool:g_bTCanUseGrenades;	// Decides if Terrorists can use grenades

//Mapstart vars
new g_iTWinsInARow;				// How many rounds the terrorist won in a row
new g_iConnectedClients;		// How many clients are currently connected

//Pluginstart vars
new Float:g_fGrenadeSpeedMultiplier;

//Add your protected ConVars here!
new String:g_saProtectedConVars[][] = {
	"sv_airaccelerate",		// use cm_airaccelerate instead
	"sv_gravity",
	"mp_limitteams",
	"mp_freezetime",
	"sv_alltalk",
	"mp_playerid",
	"mp_solid_teammates",
	"mp_halftime",
	"mp_playercashawards",
	"mp_teamcashawards",
	"mp_friendlyfire"
};

new g_iaForcedValues[] = {
	120,	// sv_airaccelerate, the value doesn't matter
	800,	// sv_gravity
	1,		// mp_limitteams
	0,		// mp_freezetime
	1,		// sv_alltalk
	1,		// mp_playerid
	0,		// mp_solid_teammates
	0,		// mp_halftime
	0,		// mp_playercashawards
	0,		// mp_teamcashawards
	0		// mp_friendlyfire
};
new Handle:g_hProtectedConvar[sizeof(g_saProtectedConVars)] = {INVALID_HANDLE, ...};

public OnPluginStart()
{
	//ConVars here
	CreateConVar("chasemod_version", PLUGIN_VERSION, "Version of ChaseMod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hFreezeTime = CreateConVar("cm_freezetime", FREEZE_TIME, "The amount of time before CTs can move at roundstart", _, true, 0.0, true, 15.0);
	g_hFreezeBlind = CreateConVar("cm_freezeblind", BLIND_CTS, "Decides if CTS get blinded when frozen", _, true, 0.0, true, 1.0);
	g_hAirAccelerate = CreateConVar("cm_airaccelerate", AIR_ACC, "The value at which sv_airaccelerate is being kept");
	g_hRoundPoints = CreateConVar("cm_roundpoints", ROUND_POINTS, "Bonus points for every winning player", _, true, 0.0);
	g_hBonusPoints = CreateConVar("cm_bonuspoints", BONUS_POINTS, "Bonus points for kills (CTs) and for surviving (Ts)", _, true, 1.0, true, 3.0);
	g_hMaximumWins = CreateConVar("cm_maximumwins", MAXIMUM_ROUNDS, "Maximum consecutive rounds won by T before the teams get swapped", _, true, 0.0);
	g_hFlashbangChance = CreateConVar("cm_flashbangchance", FLASHBANG_CHANCE, "The chance of getting a Flashbang as a Terrorist", _, true, 0.0, true, 1.0);
	g_hMolotovChance = CreateConVar("cm_molotovchance", MOLOTOV_CHANCE, "The chance of getting a Molotov as a Terrorist", _, true, 0.0, true, 1.0);
	g_hSmokeGrenadeChance = CreateConVar("cm_smokegrenadechance", SMOKE_CHANCE, "The chance of getting a Smoke Grenade as a Terrorist", _, true, 0.0, true, 1.0);
	g_hNoFlashBlind = CreateConVar("cm_noflashblind", NO_FLASH_BLIND, "Removes the flashbang blind effect for Ts and Spectators", _, true, 0.0, true, 2.0);
	g_hBlockJoinTeam = CreateConVar("cm_blockjointeam", BLOCK_JOIN_TEAM, "Blocks the ability of players to change their team", _, true, 0.0, true, 1.0);
	
	//Enforce some server ConVars
	for(new i = 0; i < sizeof(g_saProtectedConVars); i++)
	{
		g_hProtectedConvar[i] = FindConVar(g_saProtectedConVars[i]);
		SetConVarInt(g_hProtectedConvar[i], g_iaForcedValues[i], true);
		HookConVarChange(g_hProtectedConvar[i], OnCvarChange);
		HookConVarChange(g_hAirAccelerate, OnCvarChange);	// cm_airaccelerate -> sv_airaccelerate
	}
	
	//Hooked'em
	HookEvent("player_spawn", OnSpawn);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("item_pickup", OnItemPickUp);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_blind", OnPlayerFlash, EventHookMode_Pre);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	g_fGrenadeSpeedMultiplier = 250.0 / 245.0;
}

public OnMapStart()
{
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);	// Not enforced
	g_iTWinsInARow = 0;
	g_iConnectedClients = 0;
	
	CreateHostageRescue();	// Make sure T wins when the time runs out
	RemoveBombsites();
}

public Action:OnRoundStart(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	g_bBombFound = false;
	
	g_bTCanUseGrenades = false;
	new Float:freezetime = GetConVarFloat(g_hFreezeTime);
	CreateTimer(freezetime, AllowGrenades);
	
	g_fRoundStartTime = GetGameTime();
	g_iDeathTerroristsCount = 0;	
	g_iTCount = GetTeamClientCount(CS_TEAM_T);
	
	RemoveHostages();
	
	return Plugin_Continue;
}

public Action:AllowGrenades(Handle:timer)
{
	g_bTCanUseGrenades = true;
}

public OnClientConnected(client)
{
	g_iConnectedClients++;
}

public OnClientDisconnect(client)
{
	g_iConnectedClients--;
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:OnWeaponCanUse(client, weapon)
{
	new String:weapon_name[64];
	GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));
	if(GetClientTeam(client) == CS_TEAM_T)
		return Plugin_Continue;
	else if(GetClientTeam(client) == CS_TEAM_CT && IsWeaponGrenade(weapon_name))
		return Plugin_Handled;
	return Plugin_Continue;
}  

public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:cvarName[64];

	GetConVarName(convar, cvarName, sizeof(cvarName));
	if(StrEqual("cm_airaccelerate", cvarName))
	{
		for(new i = 0; i < sizeof(g_saProtectedConVars); i++)
		{
			if(StrEqual(g_saProtectedConVars[i], "sv_airaccelerate"))
			{
				new value = StringToInt(newValue)
				g_iaForcedValues[i] = value;
				SetConVarInt(FindConVar("sv_airaccelerate"), GetConVarInt(g_hAirAccelerate));	//why even try to change
			}
		}
	}
	
	for(new i = 0; i < sizeof(g_saProtectedConVars); i++)
	{
		if(StrEqual(g_saProtectedConVars[i], cvarName) && StringToInt(newValue) != g_iaForcedValues[i])
		{
			SetConVarInt(convar, g_iaForcedValues[i]);
			PrintToServer("  [CM] %s is a protected CVAR.", cvarName);
		}
	}
}

public Action:OnSpawn(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new id = GetEventInt(hEvent, "userid");
	new client = GetClientOfUserId(id);
	new weapon = GetPlayerWeaponSlot(client, 2);
	
	SetEntProp(client, Prop_Send, "m_iAccount", 0);	//Set spawn money to 0$
	RemoveNades(client);
	SwitchToWeaponSlot(client, 2);
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		GiveNades(client);
		if(IsValidEntity(weapon))
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 9000.0); 	//change the firerate so we don't have weird clientside animations going on
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9000.0);
			
			SetEntityRenderMode(weapon, RENDER_NONE);	//world model of the knife won't show
		}
	}

	if(g_iConnectedClients > 1)
		CreateTimer(0.3, FreezeDelay, id);
		
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:FreezeDelay(Handle:timer, any:id)
{
	new Float:freezetime = GetConVarFloat(g_hFreezeTime);
	new client = GetClientOfUserId(id);
	new Float:currenttime;
	new blind = GetConVarBool(g_hFreezeBlind);
	
	if(client && IsClientInGame(client))
	{		
		if((GetClientTeam(client) == CS_TEAM_CT) && IsPlayerAlive(client))
		{
			if((currenttime = g_fRoundStartTime - GetGameTime() + freezetime) > 0.0 && currenttime <= freezetime)
			{
				if(blind)
				{
					FadeClient(client, FFADE_OUT|FFADE_PURGE|FFADE_STAYOUT, BLIND_COLORS);
					CreateTimer(currenttime, NormalVision, id);
				}
				Freeze(client, currenttime);
				CreateTimer(currenttime, Unfreeze, id);
			}
			else if(GetEntityMoveType(client) == MOVETYPE_NONE)
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
		}	
	}
}

Freeze(client, Float:time)
{
	SetEntityMoveType(client, MOVETYPE_NONE);
	PrintToChat(client, "  [CM] You are frozen for %0.0f seconds.", time);
}

public Action:Unfreeze(Handle:timer, any:id)
{
	new client = GetClientOfUserId(id);
	
	if(client && IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			if(GetClientTeam(client) == CS_TEAM_CT)
				PrintToChat(client, "  [CM] You are free to go now.");
		}
	}
	return Plugin_Continue;
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	new enabled = GetConVarBool(g_hBlockJoinTeam);
	if (!enabled || client == 0 || client > MaxClients)
		return Plugin_Continue;
	new team = GetClientTeam(client);
	if (team == CS_TEAM_T || team == CS_TEAM_CT)
	{
		PrintToChat(client, "  [CM] You are not allowed to change teams.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}  

public Action:OnItemPickUp(Handle:hEvent, const String:szName[], bool:dontBroadcast)
{
	new String:temp[64];
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	GetEventString(hEvent, "item", temp, sizeof(temp));
	if(!g_bBombFound)
		if(StrEqual(temp, "weapon_c4", false))	//Find the bomb carrier
		{
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));	//Remove the bomb
			g_bBombFound = true;
			return Plugin_Continue;
		}
	for (new i = 0; i < 2; i++)
		RemoveWeaponBySlot(client, i);
	return Plugin_Continue;
}

public OnWeaponSwitchPost(client, weapon)
{
	new String:weapon_name[64];
	GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));
	if(IsWeaponGrenade(weapon_name))
		SetClientSpeed(client, g_fGrenadeSpeedMultiplier);
	else
		SetClientSpeed(client, 1.0);
}


public Action:OnPlayerDeath(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new bpoints = GetConVarInt(g_hBonusPoints);
	decl String:nickname[MAX_NAME_LENGTH];

	if(GetClientTeam(victim) == CS_TEAM_T)
	{
		g_iDeathTerroristsCount++;
		if(attacker > 0 && attacker <= MaxClients)
		{
			if(GetClientTeam(attacker) == CS_TEAM_CT)
			{
				SetEntProp(attacker, Prop_Send, "m_iAccount", 0);	//Make sure the player doesn't get the money
				CS_SetClientContributionScore(attacker, CS_GetClientContributionScore(attacker) + bpoints -1);		
				GetClientName(victim, nickname, sizeof(nickname));
				PrintToChat(attacker, "  [CM] You got %d points for killing %s.", bpoints, nickname);
			}
		}
	}
}

public Action:OnPlayerFlash(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new enabled = GetConVarInt(g_hNoFlashBlind);
	new team = GetClientTeam(client);
	
	if(enabled >= 1)
	{
		if(team == CS_TEAM_T)
			SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
		else
			if(enabled >= 2 && team == CS_TEAM_SPECTATOR)
				SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{		
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		if (buttons & (IN_ATTACK | IN_ATTACK2))
		{
			new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(iWeapon)) 
			{
				decl String:weapon_name[64];
				GetEntityClassname(iWeapon, weapon_name, sizeof(weapon_name));
				if(IsWeaponKnife(weapon_name))
				{
					SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 9000.0); 	//change the firerate so we don't have weird clientside animations going on
					SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9000.0);
					buttons &= ~(IN_ATTACK | IN_ATTACK2);	//Block attacks for Ts
					return Plugin_Changed;
				}
			}
			else
				return Plugin_Continue;
		}
	}
	else if(GetClientTeam(client) == CS_TEAM_CT)
		if (buttons & (IN_ATTACK))
		{
			buttons &= ~(IN_ATTACK);	//Block attack1 for CTs but use attack2 instead
			buttons |= IN_ATTACK2;
			return Plugin_Changed;
		}
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new WinningTeam = GetEventInt(hEvent, "winner");
	new rpoints = GetConVarInt(g_hRoundPoints);
	new bpoints = GetConVarInt(g_hBonusPoints);
	new MaxRounds = GetConVarInt(g_hMaximumWins);
	new CTScore = CS_GetTeamScore(CS_TEAM_CT);
	new points;
	
	if(WinningTeam == CS_TEAM_T)
	{
		if(!MaxRounds || ++g_iTWinsInARow < MaxRounds)
			PrintToChatAll("  [CM] Terrorists won.");
		else
		{
			SwapTeams();
			g_iTWinsInARow = 0;
			//Set the team scores
			CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T) + 1);
			SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T) + 1);
			CS_SetTeamScore(CS_TEAM_T, CTScore);
			SetTeamScore(CS_TEAM_T, CTScore);
			if(MaxRounds)
				PrintToChatAll("  [CM] Ts have won too many rounds in a row. Teams have been swapped.");
		}

		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
				if(GetClientTeam(i) == CS_TEAM_T)
				{
					CS_SetClientContributionScore(i, CS_GetClientContributionScore(i) + rpoints);
					if(IsPlayerAlive(i) && g_iDeathTerroristsCount)
					{
						new divider = g_iTCount - g_iDeathTerroristsCount;
						if(divider < 1)
							divider = 1; //actually getting the actual number of terrorists would be better
						points = bpoints * g_iDeathTerroristsCount / divider;			//how many points a surviving T deserves, depending on how many Ts have died
						CS_SetClientContributionScore(i, CS_GetClientContributionScore(i) + points);				//bonus score YAY
						PrintToChat(i, "  [CM] You got %d points for surviving the round and %d points for winning.", points, rpoints);
					}
					else
						PrintToChat(i, "  [CM] You got %d points for winning.", rpoints);
				}
		}
	}
	else if(WinningTeam == CS_TEAM_CT)
	{
		PrintToChatAll("  [CM] Counter-Terrorists won. Teams have been swapped.");
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
				if(GetClientTeam(i) == CS_TEAM_CT)
				{
					CS_SetClientContributionScore(i, CS_GetClientContributionScore(i) + rpoints);
					PrintToChat(i, "  [CM] You got %d points for winning.", rpoints);
				}
		}
		SwapTeams();
		g_iTWinsInARow = 0;
		//Set the team scores
		CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T));
		SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T));
		CS_SetTeamScore(CS_TEAM_T, CTScore);
		SetTeamScore(CS_TEAM_T, CTScore);
	}
}

public Action:NormalVision(Handle:hTimer, any:id)
{
	new client = GetClientOfUserId(id);
	if(client && IsClientInGame(client))
		FadeClient(client);
}

stock SwitchToWeaponSlot(client, slot)
{
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, slot));
}

stock RemoveNades(client)
{
	while(RemoveWeaponBySlot(client, 3)){}
}

stock GiveNades(client)
{
	new bool:yup = false;
	new Float:flashbangchance = GetConVarFloat(g_hFlashbangChance);
	new Float:molotovchance = GetConVarFloat(g_hMolotovChance);
	new Float:smokegrenadechance = GetConVarFloat(g_hSmokeGrenadeChance);
	if(GetRandomFloat(0.0, 1.0) < flashbangchance)
	{
		GivePlayerItem(client, "weapon_flashbang");
		yup = true;
	}
	if(GetRandomFloat(0.0, 1.0) < molotovchance)
	{
		GivePlayerItem(client, "weapon_molotov");
		yup = true;
	}
	if(GetRandomFloat(0.0, 1.0) < smokegrenadechance)
	{
		GivePlayerItem(client, "weapon_smokegrenade");
		yup = true;
	}
	if(yup)
		SwitchToWeaponSlot(client, 3);
}

stock SwapTeams()
{
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new team = GetClientTeam(i);
			if(team == CS_TEAM_T)
				CS_SwitchTeam(i, CS_TEAM_CT);
			else if(team == CS_TEAM_CT)
				CS_SwitchTeam(i, CS_TEAM_T);
		}
	}
}

stock FadeClient(client, flags = FFADE_PURGE, color[4] = {0, 0, 0, 0})
{
	new Handle:hFadeClient = StartMessageOne("Fade", client);
	PbSetInt(hFadeClient, "duration", 0);
	PbSetInt(hFadeClient, "hold_time", 0);
	PbSetInt(hFadeClient, "flags", flags);
	PbSetColor(hFadeClient, "clr", color);
	EndMessage();
}

stock bool:RemoveWeaponBySlot(client, slot)
{
	new entity = GetPlayerWeaponSlot(client, slot);
	if (entity > 0)
	{
		RemovePlayerItem(client, entity);
		AcceptEntityInput(entity, "Kill");
		return true;
	}
	return false;
}

stock CreateHostageRescue()
{
	new entity = -1;
	if((entity = FindEntityByClassname(entity, "func_hostage_rescue")) == -1) 
	{
		new hre = CreateEntityByName("func_hostage_rescue");
		DispatchKeyValue(hre, "targetname", "fake_hostage_rescue");
		DispatchKeyValue(hre, "origin", "-3141 -5926 -5358");
		DispatchSpawn(hre);
	}
}

stock RemoveHostages()
{
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "hostage_entity")) != -1) 	//Find hostages
		AcceptEntityInput(entity, "kill");
}

stock RemoveBombsites()
{
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "func_bomb_target")) != -1)	//Find bombsites
		AcceptEntityInput(entity, "kill");	//Destroy the entity
}

stock bool:IsWeaponKnife(const String:weapon[])
{
	return StrContains(weapon, "knife", false) != -1;
}

stock bool:IsWeaponGrenade(const String:weapon[])
{
	new const String:grenades[][] = {
		"weapon_flashbang",		
		"weapon_molotov",
		"weapon_smokegrenade",
		"weapon_decoy",
		"weapon_hegrenade",
		"weapon_incgrenade"
	}
	for(new i = 0; i < sizeof(grenades); i++)
		if(StrEqual(grenades[i], weapon))
			return true;
	return false;
}

stock SetClientSpeed(client, Float:speed)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}  