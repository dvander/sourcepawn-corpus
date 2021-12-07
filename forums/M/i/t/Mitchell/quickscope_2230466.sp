#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.2.0"

public Plugin:myinfo = {
	name = "QuickScope",
	author = "Mitch",
	description = "QuickScoping Plugin",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=252333"
};

new Handle:cvar_Enabled = INVALID_HANDLE;
new Handle:cvar_Delay = INVALID_HANDLE;
new Handle:cvar_WeaponList = INVALID_HANDLE;
new bool:gEnabled;
new Float:gDelay;
new String:gWeaponList[256];

public OnPluginStart() {
	
	cvar_Enabled = CreateConVar("sm_quickscope_enabled", "1", "Disable/Enable Plugin (1/0)");
	HookConVarChange(cvar_Enabled, OnSettingChanged);
	gEnabled = GetConVarBool(cvar_Enabled);
	
	cvar_Delay = CreateConVar("sm_quickscope_delay", "0.5", "Delay the scope resets on the weapon.");
	HookConVarChange(cvar_Delay, OnSettingChanged);
	gDelay = GetConVarFloat(cvar_Delay);
	
	cvar_WeaponList = CreateConVar("sm_quickscope_weapons", "", "List of weapons to restrict to quickscoping (Blank = all)");
	HookConVarChange(cvar_WeaponList, OnSettingChanged);
	GetConVarString(cvar_WeaponList, gWeaponList, sizeof(gWeaponList));
	
	AutoExecConfig();
	
	CreateConVar("sm_quickscope_version", VERSION, "QuickScope Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("weapon_zoom", EventWeaponZoom, EventHookMode_Post);
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == cvar_Enabled) {
		gEnabled = bool:StringToInt(newValue);
	} else if(convar == cvar_Delay) {
		gDelay = StringToFloat(newValue);
	} else if(convar == cvar_WeaponList) {
		strcopy(gWeaponList, sizeof(gWeaponList), newValue);
	}
}

public Action:EventWeaponZoom(Handle:event,const String:name[],bool:dontBroadcast) {
	if (gEnabled) {
		new userid = GetEventInt(event, "userid");
		if(StrEqual(gWeaponList, "", false)) {
			CreateTimer(gDelay, Unscope, userid);
		} else {
			new client = GetClientOfUserId(userid);
			if(client) {
				new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(weapon)) {
					decl String:classname[32];
					GetEntityClassname(weapon, classname, sizeof(classname));
					ReplaceString(classname, sizeof(classname), "weapon_", "");
					if(StrContains(gWeaponList, classname, false) != -1) {
						CreateTimer(gDelay, Unscope, userid);
					}
				}
			}
		}
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