#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define WEAPONS_MAX_LENGTH 32
#define WEAPONS_SLOTS_MAX 5

#define VERSION "1.0"
#define PLUGIN_NAME "[CSGO] Random Weapon",

new String:weapons_all[][] =  { "weapon_ak47", "weapon_aug", "weapon_famas", "weapon_galilar", "weapon_sg556", "weapon_m4a1", 
	"weapon_g3sg1", "weapon_scar20", "weapon_ssg08", "weapon_awp", 
	"weapon_deagle", "weapon_elite", "weapon_fiveseven", "weapon_glock", "weapon_hkp2000", "weapon_p250", "weapon_tec9", 
	"weapon_bizon", "weapon_mac10", "weapon_mp7", "weapon_mp9", "weapon_p90", "weapon_ump45", 
	"weapon_xm1014", "weapon_sawedoff", "weapon_nova", "weapon_mag7", 
	"weapon_m249", "weapon_negev" };

new Handle:h_knife_damage_state_cvar = INVALID_HANDLE;
new Handle:h_kills_needed_min = INVALID_HANDLE;
new Handle:h_kills_needed_max = INVALID_HANDLE;
new Handle:h_spawn_last_weapon = INVALID_HANDLE;
new Handle:h_show_kill_count = INVALID_HANDLE;
new Handle:h_weapons_cvar[sizeof weapons_all];

int kills_per_client[MAXPLAYERS][4]; //index 0: player index, index 1, current kills, index 2, kills needed, index 3, last weapon index

/*      What this plugin does
*
*   Give a player a completely random weapon
*   Specify the probability of weapons individually through cvars
*   Set the kills needed to get a new weapon (random or fixed integer)
*   Respawn with last weapon or a new one
*   Set display kills needed for new weapon
*
*   Set the weapon's proba to 0 if you don't want to have it in game
*/

public Plugin myinfo = 
{
	name = PLUGIN_NAME
	author = "Keplyx", 
	description = "Give a random weapon to the player on a kill", 
	version = VERSION, 
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	for (new client_target = 1; client_target <= MaxClients; client_target++)
	{
		if (IsClientInGame(client_target))
		{
			SDKHook(client_target, SDKHook_OnTakeDamage, TakeDamageHook);
		}
	}
	CreateCustomConVars();
	
	PrintToServer("*************************************");
	PrintToServer("* Random Weapons successfuly loaded *");
	PrintToServer("*************************************");
}

public OnClientPutInServer(client_target)
{
	SDKHook(client_target, SDKHook_OnTakeDamage, TakeDamageHook);
}

public OnClientDisconnect(client_target)
{
	DeleteClient(client_target);
}

public void CreateCustomConVars()
{
	SetConVarInt(FindConVar("mp_buytime"), 0);
	SetConVarInt(FindConVar("mp_buy_anywhere"), 0);
	SetConVarInt(FindConVar("mp_buy_during_immunity"), 0);
	CreateConVar("rdm_test_version", VERSION, "Test random weapons version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	h_knife_damage_state_cvar = CreateConVar("rdm_enable_knife", "0", "Sets whether knife does damage. 0 = no damage, 1 = normal damage");
	h_kills_needed_min = CreateConVar("rdm_kills_needed_min", "1", 
		"Sets the minimum kills needed to get a random weapon. Kills needed value is random between min and max. Set rdm_kills_needed_min and rdm_kills_needed_max at the same value if you want a fixed number of kills. min = 1, max = 100", 
		FCVAR_NONE, true, 1.0, true, 100.0);
	h_kills_needed_max = CreateConVar("rdm_kills_needed_max", "1", 
		"Sets the maximum kills needed to get a random weapon. Kills needed value is random between min and max. Set rdm_kills_needed_min and rdm_kills_needed_max at the same value if you want a fixed number of kills. min = 1, max = 100", 
		FCVAR_NONE, true, 1.0, true, 100.0);
	h_spawn_last_weapon = CreateConVar("rdm_spawn_last_weapon", "1", "Sets whether to spawn with the last weapon. If no, the kill counter will be reset on spawn, if yes, it will stay. 0 = no, 1 = yes");
	h_show_kill_count = CreateConVar("rdm_show_kill_count", "1", "Sets whether to show the kills needed to get a new weapon. 0 = no, 1 = yes");
	for (int i = 0; i < sizeof weapons_all; i++)
	{
		new String:cvarName[32];
		Format(cvarName, sizeof cvarName, "%s%s", "rdm_", weapons_all[i]);
		h_weapons_cvar[i] = CreateConVar(cvarName, "1.0", "Sets the probability of the weapon. 0 = min proba, 1 = max proba", FCVAR_NONE, true, 0.0, true, 1.0);
	}
	
	AutoExecConfig(true, "rdm-weapons");
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker_id = event.GetInt("attacker");
	int attacker = GetClientOfUserId(attacker_id);
	AddKillToCounter(attacker);
	if (CheckKillCount(attacker))
		GiveRandomWeapon(attacker);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client_id = event.GetInt("userid");
	int client_target = GetClientOfUserId(client_id);
	
	if (GetConVarInt(FindConVar("mp_buy_anywhere")) != 0)
	   SetConVarInt(FindConVar("mp_buy_anywhere"), 0);
	if (GetConVarInt(FindConVar("mp_buy_during_immunity")) != 0)
       SetConVarInt(FindConVar("mp_buy_during_immunity"), 0);
	   
	if (CheckKillCount(client_target) || !GetConVarBool(h_spawn_last_weapon))
	{
		SetNewKillCount(CheckClient(client_target));
		GiveRandomWeapon(client_target);
	}
	else if (GetConVarBool(h_spawn_last_weapon))
		GiveLastWeapon(client_target);
}

public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((client >= 1) && (client <= MaxClients) && (attacker >= 1) && (attacker <= MaxClients) && (attacker == inflictor) && GetConVarInt(h_knife_damage_state_cvar) == 0)
	{
		decl String:weaponName[64];
		GetClientWeapon(attacker, weaponName, sizeof(weaponName));
		if (StrContains(weaponName, "knife", false) != -1)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}


public int CheckClient(int client_target)
{
	//Check if player is already listed
	for (int i = 0; i < sizeof kills_per_client; i++)
	{
		if (kills_per_client[i][0] == client_target)
		{
			//PrintToChat(client_target, "Found client %i in list!", client_target);
			return i;
		}
	}
	//If not listed, gets added to the array in an empty place
	//PrintToChat(client_target, "Client %i not found in list!", client_target);
	for (int i = 0; i < sizeof kills_per_client; i++)
	{
		if (kills_per_client[i][0] == 0)
		{
			kills_per_client[i][0] = client_target;
			//PrintToChat(client_target, "Added client %i in list at %i!", client_target, i);
			return i;
		}
	}
	return -1;
}

public void DeleteClient(int client_target)
{
	for (int i = 0; i < sizeof kills_per_client; i++)
	{
		if (kills_per_client[i][0] == client_target)
		{
			kills_per_client[i][0] = 0;
			kills_per_client[i][1] = 0;
			kills_per_client[i][2] = 0;
			kills_per_client[i][3] = 0;
		}
	}
}

public bool CheckKillCount(int client_target)
{
	int clientIndex = CheckClient(client_target);
	if (clientIndex == -1)
	{
		PrintToServer("Random Weapons ERROR: invalid client");
		return false;
	}
	else
	{
		if (kills_per_client[clientIndex][1] == kills_per_client[clientIndex][2])
		{
			SetNewKillCount(clientIndex);
			PrintToChat(client_target, "New kill count for client %i: %i", client_target, kills_per_client[clientIndex][2]);
			return true;
		}
		//PrintToChat(client_target, "Client %i does not have enough kills. Needed: %i, Have %i", client_target, kills_per_client[clientIndex][2], kills_per_client[clientIndex][1]);
		if (GetConVarBool(h_show_kill_count))
			PrintHintText(client_target, "%i / %i kills for next weapon", kills_per_client[clientIndex][1], kills_per_client[clientIndex][2]);
		return false;
	}
}

public void AddKillToCounter(int client_target)
{
	int clientIndex = CheckClient(client_target);
	if (clientIndex == -1)
	{
		PrintToServer("Random Weapons ERROR: invalid client");
	}
	else
	{
		kills_per_client[clientIndex][1]++;
		//PrintToChat(client_target, "Added kill to client %i", client_target);
	}
}

public void SetNewKillCount(int clientIndex)
{
	kills_per_client[clientIndex][1] = 0;
	kills_per_client[clientIndex][2] = GetRandomInt(GetConVarInt(h_kills_needed_min), GetConVarInt(h_kills_needed_max));
}


public void GiveRandomWeapon(int client_target)
{
	float totalProba = 0.0;
	for (int i = 0; i < sizeof weapons_all; i++)
	{
		totalProba += GetConVarFloat(h_weapons_cvar[i]);
	}
	
	if (totalProba == 0.0)
	{
		PrintToChat(client_target, "Random Weapons ERROR: All weapons disabled");
	}
	else
	{
		float rdmWeapon = 0.0;
		do
		{
			rdmWeapon = GetRandomFloat(0.0, totalProba);
		} while (rdmWeapon == 0.0);
		float currentProba = 0.0;
		
		for (int i = 0; i < sizeof weapons_all; i++)
		{
			if (rdmWeapon <= (currentProba + GetConVarFloat(h_weapons_cvar[i])))
			{
				kills_per_client[CheckClient(client_target)][3] = i;
				GiveWeapon(weapons_all[i], client_target);
				break;
			}
			currentProba = currentProba + GetConVarFloat(h_weapons_cvar[i]);
		}
	}
	
}

public void GiveLastWeapon(int client_target)
{
	RemovePlayerWeapons(client_target);
	int weaponIndex = kills_per_client[CheckClient(client_target)][3];
	GivePlayerItem(client_target, weapons_all[weaponIndex]);
	PrintToChat(client_target, "You got back your %s", weapons_all[weaponIndex]);
}

public void GiveWeapon(String:weapon[], int client_target)
{
	RemovePlayerWeapons(client_target);
	GivePlayerItem(client_target, weapon);
	//PrintHintText(client_target, "You got a : %s", weapon);
}


public void RemovePlayerWeapons(client_target)
{
	new weaponIndex;
	new String:weapon_name[WEAPONS_MAX_LENGTH];
	
	for (new i = 0; i < WEAPONS_SLOTS_MAX; i++) {
		if (GetPlayerWeaponSlot(client_target, i) != -1) {
			weaponIndex = GetPlayerWeaponSlot(client_target, i);
			
			GetEdictClassname(weaponIndex, weapon_name, sizeof weapon_name);
			
			if (!StrEqual(weapon_name, "weapon_knife", false))
			{
				//PrintToChat(client_target, "removed: %s", weapon_name);
				RemovePlayerItem(client_target, weaponIndex);
				RemoveEdict(weaponIndex);
			}
			
		}
	}
} 