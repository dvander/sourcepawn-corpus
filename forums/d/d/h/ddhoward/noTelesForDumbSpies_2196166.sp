#define PLUGIN_VERSION "14.0910.3"
#define UPDATE_FILE "NoTelesForDumbSpies.txt"
#define CONVAR_PREFIX "sm_notelesfordumbspies"
#define UPD_LIBFUNC
#define DEFAULT_UPDATE_SETTING "3"

#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <ddhoward_updater>


new Handle:hcvar_enabled;
new cvar_enabled;

public Plugin:myinfo = {
	name = "[TF2] No Teleporters for Undisguised Enemies!",
	author = "Derek D. Howard",
	description = "Prevents undisguised enemies from using enemy teleporters.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=247929"
}

public OnPluginStart() {
	hcvar_enabled = CreateConVar(CONVAR_PREFIX, "1", "(0/1/2) Enables/Disables Plugin. Set to 2 to also block cloaked spies from using enemy teles.", FCVAR_PLUGIN);
}

public OnConfigsExecuted() {
	cvarChange(INVALID_HANDLE, "", "");
	HookConVarChange(hcvar_enabled, cvarChange);
}

public Action:TF2_OnPlayerTeleport(client, teleporter, &bool:result) {
	if (result && cvar_enabled > 0) {
		new teleteam = GetEntProp(teleporter, Prop_Send, "m_iTeamNum");
		if (GetClientTeam(client) != teleteam) {
			new disguiseTeam = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
			if (!TF2_IsPlayerInCondition(client, TFCond_Disguised)
			|| (cvar_enabled >= 2 && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			|| disguiseTeam != teleteam) {
				result = false;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	//uncomment the lines below if adding more cvars
	//if (hHandle == hcvar_enabled || hHandle == INVALID_HANDLE) {
		cvar_enabled = GetConVarInt(hcvar_enabled);
	//}
}