#define PLUGIN_VERSION		"1.0.2 "
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"switch_upgradepacks"
#define PLUGIN_NAME_FULL	"[L4D2] Switch Upgrade Packs Type"
#define PLUGIN_DESCRIPTION	"hold or tap reload key to switch upgrade packs type"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=340632"

/*
 *	v1.0 just released; 30-November-2022
 *	v1.0.1 fix remove item cause entity leak, thanks to Silvers; 30-November-2022 (2nd time)
 *	v1.0.2 fix forgot to listen key release :C sorry; 1-December-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2)

bool bLateLoad = false;
bool hasTranslations = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	return APLRes_Success;
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cAnnounce;	int iAnnounce;
ConVar cHoldTime;	float flHoldTime;


public void OnPluginStart() {

	CreateConVar			(PLUGIN_NAME, PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cAnnounce =	CreateConVar(PLUGIN_NAME ... "_announce", "2",	"announce types 0=dont announce 1=center 2=chat 4=hint. add numbers together you want", FCVAR_NOTIFY);
	cHoldTime =	CreateConVar(PLUGIN_NAME ... "_holdtime", "2",	"time(seconds) for hold the reload to switch types 0=tap mode", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cAnnounce.AddChangeHook(OnConVarChanged);
	cHoldTime.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases");
	else
		LogError("not translations file %s found yet, please check install guide for %s", PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt", PLUGIN_NAME_FULL);

	// Late Load
	if (bLateLoad)
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
}


void ApplyCvars() {

	flHoldTime = cHoldTime.FloatValue;
	iAnnounce = cAnnounce.IntValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

float time_reload_start [MAXPLAYERS + 1];
buttons_last [MAXPLAYERS + 1];
bool bBlockAnnounce = false;

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	if (IsSurvivor(client) && IsPlayerAlive(client)) {
		

		float time = GetEngineTime();

		bool reload_pressed = buttons & IN_RELOAD && !(buttons_last[client] & IN_RELOAD);
		bool reload_released = !(buttons & IN_RELOAD) && buttons_last[client] & IN_RELOAD;

		if (reload_pressed)
			time_reload_start[client] = time;

		if (reload_released)
			time_reload_start[client] = 0.0

		if ( (!flHoldTime && reload_pressed) || time_reload_start[client] && time - time_reload_start[client] > flHoldTime ) {

			time_reload_start[client] = 0.0;

			static char name_weapon[32];

			int weapon_current = L4D_GetPlayerCurrentWeapon(client);

			if (weapon_current != INVALID_ENT_REFERENCE) {

				GetEntityClassname(weapon_current, name_weapon, sizeof(name_weapon));

				if ( strcmp(name_weapon, "weapon_upgradepack_explosive") == 0 ) {

					if (RemovePlayerItem(client, weapon_current)) {
						GivePlayerItem(client, "weapon_upgradepack_incendiary");
						RemoveEntity(weapon_current);
					}
					
				} else if ( strcmp(name_weapon, "weapon_upgradepack_incendiary") == 0 ) {

					if (RemovePlayerItem(client, weapon_current)) {
						GivePlayerItem(client, "weapon_upgradepack_explosive");
						RemoveEntity(weapon_current);
					}
				}
			}
		}
		buttons_last[client] = buttons;
	}
}


public void OnClientPutInServer(int client) {

	if (!IsFakeClient(client))
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect_Post(int client) {

	time_reload_start[client] = 0.0;
	buttons_last[client] = 0;
}

void OnWeaponSwitchPost(int client, int weapon) {

	time_reload_start[client] = 0.0;
	static char name_weapon[32];

	GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));

	if ( StartsWith(name_weapon, "weapon_upgradepack_") )
		Announce(client, "%t", flHoldTime ? "Switch By Hold" : "Switch By Tap");
}


/////////////////////////////
// Stocks Below     ////////
///////////////////////////

enum {
	ANNOUNCE_CENTER =	(1 << 0),
	ANNOUNCE_CHAT	=	(1 << 1),
	ANNOUNCE_HINT	=	(1 << 2),
}

void Announce(int client, const char[] format, any ...) {

	if (!hasTranslations)
		return;

	static char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (IsClient(client)) {

		if (iAnnounce & ANNOUNCE_CHAT)
			PrintToChat(client, "%s", buffer);

		if (iAnnounce & ANNOUNCE_HINT)
			PrintHintText(client, "%s", buffer);

		if (iAnnounce & ANNOUNCE_CENTER)
			PrintCenterText(client, "%s", buffer);
	}
}

stock void ReplaceColor(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}

/**
 * @brief Returns a players current weapon, or -1 if none.
 *
 * @param client			Client ID of the player to check
 *
 * @return weapon entity index or -1 if none
 */
stock int L4D_GetPlayerCurrentWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

bool StartsWith(const char[] str, const char[] substr) {
	return strncmp(str, substr, strlen(substr) -1, true) == 0;
}