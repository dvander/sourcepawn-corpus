/*
RussianRoulette.sp

Description:
	Each weapon has a random chance of killing the player who shot it

Versions:
	1.0
		* Initial Release
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define MAX_FILE_LEN 80
#define MAX_NUM_WEAPONS 20
#define WEAPON_STRING_SIZE 30

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Russian Roulette",
	author = "AMP",
	description = "Each weapon has a random chance of killing the owner when it kills",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:cvarEnabled = INVALID_HANDLE;
new weaponCount;
new String:weaponNames[MAX_NUM_WEAPONS][WEAPON_STRING_SIZE];
new Float:weaponChance[MAX_NUM_WEAPONS];
new bool:isHooked = false;

public OnPluginStart()
{
	cvarEnabled = CreateConVar("sm_russian_roulette_enable", "1", "Enables the LastMan plugin");
	HookConVarChange(cvarEnabled, EnabledChanged);

	// Create the rest of the cvar's
	CreateConVar("sm_russian_roulette_version", PLUGIN_VERSION, "Russian Roulette Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Finish by setting up iLifeState, hooking player_death and registering the lastman command
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	isHooked = true;
	
	// Load the weapons and probabilities from the config file
	LoadValues();
}

// The death event
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:weapon[WEAPON_STRING_SIZE];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(client && IsClientInGame(client)) {
		new pos = 0;
		while(pos < weaponCount) {
			if(StrEqual(weapon, weaponNames[pos])) {
				if(GetRandomFloat(0.0, 1.0) < weaponChance[pos]) {
					ForcePlayerSuicide(client);
					PrintCenterText(client, "Your luck has run out");
				}
				return;
			}
			pos++;
		}
	}
}

public LoadValues()
{
	new Handle:kv = CreateKeyValues("RussianRoulette");
	new String:filename[MAX_FILE_LEN];

	BuildPath(Path_SM, filename, MAX_FILE_LEN, "configs/russianroulette.cfg");
	FileToKeyValues(kv, filename);
	
	if (!KvGotoFirstSubKey(kv)) {
		SetFailState("configs/russianroulette.cfg not found or not correctly structured");
		return;
	}

	weaponCount = 0;
	do {
		KvGetSectionName(kv, weaponNames[weaponCount], WEAPON_STRING_SIZE);
		PrintToServer("Weapon name: %s", weaponNames[weaponCount]);
		weaponChance[weaponCount] = KvGetFloat(kv, "chance", 0.0);
		PrintToServer("Weapon name: %s, Chance %f", weaponNames[weaponCount], weaponChance[weaponCount]);
		if(weaponChance[weaponCount] > 0.0)
			weaponCount++;
	} while(KvGotoNextKey(kv) && weaponCount < MAX_NUM_WEAPONS);
	
	if(weaponCount == MAX_NUM_WEAPONS)
		PrintToServer("Stopped reading weapons file after %s, too many weapons", weaponNames[weaponCount - 1]);
		
	
	CloseHandle(kv);
}

// Looks for cvar changes of the enable cvar and hooks or unhooks the events
public EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarBool(cvarEnabled) && !isHooked) {
		HookEvent("player_death", EventPlayerDeath);
		isHooked = true;
	} else if(!GetConVarBool(cvarEnabled) && isHooked) {
		UnhookEvent("player_death", EventPlayerDeath);
		isHooked = false;
	}
}