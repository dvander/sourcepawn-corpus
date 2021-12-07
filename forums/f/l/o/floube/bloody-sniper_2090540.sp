#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

/****************************************************************
                        C O N S T A N T S
*****************************************************************/

#define PLUGIN_NAME     "Bloody Sniper"
#define PLUGIN_AUTHOR   "floube"
#define PLUGIN_DESC     "Players start to bleed after they get shot by a sniper"
#define PLUGIN_VERSION  "1.00"
#define PLUGIN_URL      "http://www.styria-games.eu/"

#define PLUGIN_TAG      "\x03[Bloody Sniper] \x01"
#define PLUGIN_TAG_CON  "[Bloody Sniper] "

/****************************************************************
                        P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

new Handle:g_hPluginEnabled = INVALID_HANDLE;
new Handle:g_hDamageIncrease = INVALID_HANDLE;
new Handle:g_hCausesBleeding = INVALID_HANDLE;

/****************************************************************
                        F O R W A R D   P U B L I C S
*****************************************************************/

public OnPluginStart() {
	CreateConVar("sm_bloody_sniper_version", PLUGIN_VERSION, "Bloody Sniper Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hPluginEnabled = CreateConVar("sm_bloody_sniper_enabled", "1", "0 = Bloody Sniper Plugin disabled; 1 = Bloody Sniper Plugin enabled", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hDamageIncrease = CreateConVar("sm_bloody_sniper_damage_increase", "50.0", "0 = Does not increase damage; X = Increase the damage by X percent; Negative X means decrease", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, false, _);
	g_hCausesBleeding = CreateConVar("sm_bloody_sniper_causes_bleeding", "6.0", "0 = Player does not bleed after hit; X = Player does bleed for X seconds after hit", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, false, _);

	if (GetConVarBool(g_hPluginEnabled)) {
		HookConVarChange(g_hDamageIncrease, CvarChange_GeneralFloat);
		HookConVarChange(g_hCausesBleeding, CvarChange_GeneralFloat);

		// Plugin late load, re-load
		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsValidClient(iClient, true) && IsClientInGame(iClient)) {
				OnClientPutInServer(iClient);
			}
		}
	}

	HookConVarChange(g_hPluginEnabled, CvarChange_PluginEnabled);
}

public OnMapStart() {
	
}

public OnClientPutInServer(iClient) {
	if (!GetConVarBool(g_hPluginEnabled))
		return;

	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iClient, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iWeapon, Float:fDamageForce[3], Float:fDamagePosition[3]) {
	if (!GetConVarBool(g_hPluginEnabled))
		return Plugin_Continue;

	if (!IsValidClient(iClient, true)) 
		return Plugin_Continue;

	if (IsValidClient(iAttacker, true) && TF2_GetPlayerClass(iAttacker) == TFClass_Sniper) {
		if (iDamageType & DMG_BULLET) {
			new String:sWeapon[64];
			GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));

			if (StrEqual(sWeapon, "tf_weapon_sniperrifle") || StrEqual(sWeapon, "tf_weapon_sniperrifle_decap")) {
				if (GetConVarFloat(g_hDamageIncrease) != 0.0) {
					fDamage = fDamage * (1 + (GetConVarFloat(g_hDamageIncrease) / 100));
				}

				if (GetConVarFloat(g_hCausesBleeding) >= 0.0) {
					TF2_MakeBleed(iClient, iAttacker, GetConVarFloat(g_hCausesBleeding));
				}

				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

/****************************************************************
			U T I L I T Y   F U N C T I O N S
*****************************************************************/

stock bool:IsValidClient(iClient, bool:bConnectedOnly=false) {
	if (bConnectedOnly)
		return (iClient > 0 && iClient <= MaxClients && IsClientConnected(iClient));

	return (iClient > 0 && iClient <= MaxClients);
}

/****************************************************************
			C V A R   C H A N G E   F U N C T I O N S
*****************************************************************/

public CvarChange_PluginEnabled(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	new String:sFile[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));

	if (StringToFloat(sNewValue) == 0) {
		SetConVarBool(g_hPluginEnabled, false);

		PrintToServer("%sPlugin is now disabled.", PLUGIN_TAG_CON);
		ServerCommand("sm plugins reload %s", sFile);
	} else {
		SetConVarBool(g_hPluginEnabled, true);

		PrintToServer("%sPlugin is now enabled.", PLUGIN_TAG_CON);
		ServerCommand("sm plugins reload %s", sFile);
	}
}

public CvarChange_GeneralFloat(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	SetConVarFloat(hCvar, StringToFloat(sNewValue));

	new String:sCvarName[33];
	GetConVarName(hCvar, sCvarName, sizeof(sCvarName));

	PrintToServer("%sPlugin cvar '%s' changed to %f", PLUGIN_TAG_CON, sCvarName, StringToFloat(sNewValue));
}