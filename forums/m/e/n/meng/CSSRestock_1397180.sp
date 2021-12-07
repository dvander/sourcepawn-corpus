#include <sourcemod>
#include <sdktools>

#define NAME "CSS Restock"
#define VERSION "1.1.1"
#define RESTOCK_SOUND "buttons/weapon_confirm.wav"
#define NUM_WEAPONS 24

new Handle:g_CVarEnabled;
new Handle:g_CVarEmptyOnly;
new Handle:g_CVarBullets;
new Handle:g_CVarLimit;
new g_iTimesUsed[MAXPLAYERS+1];
new Handle:g_CVarAdmFlag;
new g_AdmFlag;

new const String:g_sWeaponNames[NUM_WEAPONS][32] = {

	"weapon_ak47", "weapon_m4a1", "weapon_sg552",
	"weapon_aug", "weapon_galil", "weapon_famas",
	"weapon_scout", "weapon_m249", "weapon_mp5navy",
	"weapon_p90", "weapon_ump45", "weapon_mac10",
	"weapon_tmp", "weapon_m3", "weapon_xm1014",
	"weapon_glock", "weapon_usp", "weapon_p228",
	"weapon_deagle", "weapon_elite", "weapon_fiveseven",
	"weapon_awp", "weapon_g3sg1", "weapon_sg550"
};

new const g_AmmoData[NUM_WEAPONS][2] = {

	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {4, 200}, {6, 120},
	{10, 100}, {8, 100}, {8, 100},
	{6, 120}, {7, 32}, {7, 32},
	{6, 120}, {8, 100}, {9, 52},
	{1, 35}, {6, 120}, {10, 100},
	{5, 30}, {2, 90}, {3, 90}
};

public Plugin:myinfo = {

	name = NAME,
	author = "meng",
	description = "Restocks ammunition.",
	version = VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart() {

	CreateConVar("sm_restock", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarEnabled = CreateConVar("sm_restock_enabled", "1", "1/0 Enable/Disable plugin.", _, true, 0.0, true, 1.0);
	g_CVarEmptyOnly = CreateConVar("sm_restock_emptyonly", "0", "1/0 If enabled, players can only restock with empty ammo reserves.", _, true, 0.0, true, 1.0);
	g_CVarBullets = CreateConVar("sm_restock_bullets", "0", "The number of bullets set as reserve, regardless of weapon. 0 = Standard CSS ammo counts.", _, true, 0.0, true, 999.0);
	g_CVarLimit = CreateConVar("sm_restock_limit", "0", "The number of times a player can use restock per spawn. 0 = unlimited.", _, true, 0.0, true, 999.0);
	g_CVarAdmFlag = CreateConVar("sm_restock_adminflag", "0", "Admin flag required to use restock. 0 = No flag needed.");
	AutoExecConfig(true, "restock");
	HookConVarChange(g_CVarAdmFlag, CVarChange);
	RegConsoleCmd("restock", CmdRestock);
	HookEvent("player_spawn", EventPlayerSpawn);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_AdmFlag = ReadFlagString(newValue);
}

public EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iTimesUsed[client] = 0;
}

public Action:CmdRestock(client, args) {

	if ((GetClientTeam(client) > 1) && IsPlayerAlive(client)) {
		if (!GetConVarBool(g_CVarEnabled)) {
			PrintToChat(client, "\x04[SM] Restock \x01Restock is currently disabled.");
			return Plugin_Handled;
		}
		if ((g_AdmFlag > 0) && !CheckCommandAccess(client, "restock", g_AdmFlag, true)) {
			PrintToChat(client, "\x04[SM] Restock \x01You do not have access.");
			return Plugin_Handled;
		}
		new limit = GetConVarInt(g_CVarLimit);
		if ((limit > 0) && (g_iTimesUsed[client] >= limit)) {
			PrintToChat(client, "\x04[SM] Restock \x01Restock limit reached. [ Limit = %i ]", limit);
			return Plugin_Handled;
		}
		/* Restock this dude! */
		RestockClientAmmo(client);
	}
	return Plugin_Handled;
}

RestockClientAmmo(client) {

	new weaponIndex, dataIndex, ammoOffset, bullets = GetConVarInt(g_CVarBullets);
	new bool:restocked;
	decl String:sClassName[32];
	for (new i = 0; i <= 1; i++) {
		if (((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1) && 
		GetEdictClassname(weaponIndex, sClassName, 32) &&
		((dataIndex = GetAmmoDataIndex(sClassName)) != -1) &&
		((ammoOffset = FindDataMapOffs(client, "m_iAmmo")+(g_AmmoData[dataIndex][0]*4)) != -1)) {
			if (!restocked && GetConVarBool(g_CVarEmptyOnly) && (GetEntData(client, ammoOffset) > 0)) {
				PrintToChat(client, "\x04[SM] Restock \x01Ammo reserves must be empty.");
				break;
			}
			else { /* Restock! */
				SetEntData(client, ammoOffset, (bullets > 0) ? bullets : g_AmmoData[dataIndex][1]);
				restocked = true;
			}
		}
	}
	if (restocked) {
		g_iTimesUsed[client]++;
		EmitSoundToClient(client, RESTOCK_SOUND, _, _, _, _, 0.7);
		PrintToChat(client, "\x04[SM] Restock \x01Ammo Restocked.");
	}
}

GetAmmoDataIndex(const String:weapon[]) {

	for (new i = 0; i < NUM_WEAPONS; i++)
		if (StrEqual(weapon, g_sWeaponNames[i]))
			return i;
	return -1;
}