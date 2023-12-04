#define PLUGIN_VERSION		"1.1"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"defibrillator_distrubtor"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Defibrillator Distrubtor"
#define PLUGIN_DESCRIPTION	"give the defibrillator to specified survivor when someone die."
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2792907"
/**
 *	v1.0 just releases; 23-October-2022
 *	v1.1 new ConVar *_force to control if targets not found, cancel which filter; 25-November-2022
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define L4DWeaponSlot_FirstAid	3

#define IsClient(%1) (1 <= %1 <= MaxClients && IsClientInGame(%1))
#define IsSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2)

enum {
	nearest =		(1 << 0),
	stand =			(1 << 1),
	human =			(1 << 2),
	empty =			(1 << 3),
}


public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};


ConVar cFilters;		int filters;
ConVar cVictimOnly;		bool victim_only;
ConVar cForce;			int iForce;

public void OnPluginStart() {

	CreateConVar					(PLUGIN_NAME ... "_version", PLUGIN_VERSION,	"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cFilters =			CreateConVar(PLUGIN_NAME ... "_filters", "11",				"filters of giving targets 1=nearest one 2=stand on ground 4=human 8=empty slot \n-1=All 11=nearest standing and empty aid slot survivor\nadd numbers together you want.", FCVAR_NOTIFY);
	cVictimOnly =		CreateConVar(PLUGIN_NAME ... "_victim", "0",				"only trigger distrubte for survivor who die by zombie", FCVAR_NOTIFY);
	cForce =			CreateConVar(PLUGIN_NAME ... "_force", "8",					"if targets not found, cancel which filter", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cFilters.AddChangeHook(OnConVarChanged);
	cVictimOnly.AddChangeHook(OnConVarChanged);
	cForce.AddChangeHook(OnConVarChanged);

	HookEvent("player_death", OnPlayerDeath);
	
	ApplyCvars();
}


public void ApplyCvars() {

	filters = cFilters.IntValue;
	victim_only = cVictimOnly.BoolValue;
	iForce = cForce.IntValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

bool isPlayerDown(int client) {
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") || GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	static char name_attacker[32];

	int victim = GetClientOfUserId(event.GetInt("userid"));

	float vector_victim[3];
	vector_victim[0] = event.GetFloat("victim_x");
	vector_victim[1] = event.GetFloat("victim_y");
	vector_victim[2] = event.GetFloat("victim_z");

	if (IsSurvivor(victim)) {

		if (victim_only) {
			
			event.GetString("attackername", name_attacker, sizeof(name_attacker), "");

			if (!name_attacker[0])
				return;
		}

		ArrayList targets = new ArrayList();

		for (int client = 1; client <= MaxClients; client++) {

			if (IsSurvivor(client) && IsPlayerAlive(client)) {

				bool passed = true;

				if (filters & stand && isPlayerDown(client))
					passed = false;

				if (filters & human && IsFakeClient(client))
					passed = false;

				if (filters & empty && GetPlayerWeaponSlot(client, L4DWeaponSlot_FirstAid) != -1)
					passed = false;

				if (passed)
					targets.Push(client);
			}
		}

		if (targets.Length == 0) {

			for (int client = 1; client <= MaxClients; client++) {

				if (IsSurvivor(client) && IsPlayerAlive(client)) {

					bool passed = true;

					if ( (filters &~ iForce) & stand && isPlayerDown(client))
						passed = false;

					if ( (filters &~ iForce) & human && IsFakeClient(client))
						passed = false;

					if ( (filters &~ iForce) & empty && GetPlayerWeaponSlot(client, L4DWeaponSlot_FirstAid) != -1)
						passed = false;

					if (passed)
						targets.Push(client);
				}
			}
		}

		if (filters & nearest) {

			int nearest_client = 0;
			float nearest_distance;

			for (int i = 0; i < targets.Length; i++) {

				float vector_target[3];

				GetClientAbsOrigin(targets.Get(i), vector_target);

				float distance = GetVectorDistance(vector_victim, vector_target);

				if ( !nearest_client || (distance < nearest_distance) ) {

					nearest_client = targets.Get(i);

					nearest_distance = distance;
				}
			}

			if (nearest_client)
				GiveDefibrillator(nearest_client);

		} else {

			for (int i = 0; i < targets.Length; i++) {

				GiveDefibrillator(targets.Get(i));
			}
		}

		delete targets;
	}
}

bool GiveDefibrillator(int client) {

	int gived = GivePlayerItem(client, "weapon_defibrillator");

	return gived > 0;
}