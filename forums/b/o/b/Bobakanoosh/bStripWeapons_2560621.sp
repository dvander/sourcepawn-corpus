#define PLUGIN_AUTHOR "Bobakanoosh"
#define PLUGIN_VERSION "1.0.0"

#pragma newdecls required

#include <sdktools>

public Plugin myinfo =  {

	name = "bStripWeapons",
	author = PLUGIN_AUTHOR,
	description = "Strips all weapons on round start.",
	version = PLUGIN_VERSION,
	url = ""
	
};

public void OnPluginStart() {

	HookEvent("round_start", Event_RoundStart);
	
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {

	for(int i = 1; i < MaxClients; i++) {
	
		if(IsValidClient(i)) {
		
			StripAllWeapons(i);
			GivePlayerItem(i, "weapon_knife");
		
		}
	
	}

}

stock bool IsValidClient(int client, bool noBots=true) {

	if (client < 1 || client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (!IsClientConnected(client))
		return false;

	if (noBots)
		if (IsFakeClient(client))
			return false;

	if (IsClientSourceTV(client))
		return false;

	return true;

}

stock void StripAllWeapons(int client) {

	if (!IsValidClient(client, false))
		return;

	int weapon;
	for (int i; i < 4; i++) {

		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {

			if (IsValidEntity(weapon)) {

				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");

			}

		}

	}

}