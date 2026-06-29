#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.1.0"

public Plugin:myinfo = {
	name = "QuickScope",
	author = "Mitch",
	description = "QuickScoping Plugin",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=252333"
};

new bool:g_enabled;
new Handle:g_Cvarenabled = INVALID_HANDLE;

public OnPluginStart() {
	CreateConVar("sm_quickscope_version", VERSION, "QuickScope Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvarenabled = CreateConVar("sm_quickscope_enabled", "1", "Enable this plugin. 0 = Disabled");
	HookEvent("weapon_zoom", EventWeaponZoom, EventHookMode_Post);
	HookConVarChange(g_Cvarenabled, OnSettingChanged);
	g_enabled = GetConVarBool(g_Cvarenabled);
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_enabled = bool:StringToInt(newValue);
}

public Action:EventWeaponZoom(Handle:event,const String:name[],bool:dontBroadcast) {
	if (g_enabled) {
		new userid = GetEventInt(event, "userid");
		CreateTimer(0.5, Unscope, userid);
	}
	return Plugin_Continue;
}

public Action:Unscope(Handle:Timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client) {
		new wep = GetPlayerWeaponSlot(client, 0);
		if(IsValidEntity(wep)) {
			SetEntProp(wep, Prop_Send, "m_zoomLevel", 0);
		}
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		SetEntProp(client, Prop_Send, "m_bIsScoped", 0);
		SetEntProp(client, Prop_Send, "m_bResumeZoom", 0);
	}
	return Plugin_Handled;
}