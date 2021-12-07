#pragma semicolon 1

#include <sourcemod>
//#include <sdktools>
//#include <sdkhooks>

#define PLUGIN_NAME		"[CURE] Infinity"
#define PLUGIN_VERSION	"1.0.0"

int iClip1Offset = 1240;
ConVar hInfAmmo = null;
int iInfAmmo;
ConVar hInfAmmoAdm = null;
int iInfAmmoAdm;
bool bIsAdmin[MAXPLAYERS+1];
bool bLate;

public Plugin myinfo =
{
	name 		= PLUGIN_NAME,
	author 		= "Grey83",
	description 	= "Make endless clip in Codename CURE",
	version 		= PLUGIN_VERSION,
	url 			= "https://forums.alliedmods.net/showthread.php?t=282490"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	CreateConVar("cure_infinity_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hInfAmmo = CreateConVar("sm_inf_ammo", "0", "Mode for all players:\n0 - Normal clip, 1 - Infinite clip.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hInfAmmoAdm = CreateConVar("sm_inf_adm", "1", "Mode for admins:\n0 - Normal clip\n1 -  Infinite clip", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	iInfAmmo = GetConVarInt(hInfAmmo);
	iInfAmmoAdm = GetConVarInt(hInfAmmoAdm);

	HookConVarChange(hInfAmmo, OnConVarChange);
	HookConVarChange(hInfAmmoAdm, OnConVarChange);

	AutoExecConfig(true, "cure_infinity");

	if (bLate) {
		LookupClients();
		bLate = false;
	}
}

public void OnConVarChange(Handle hCVar, const char[] oldValue, const char[] newValue)
{
	if (hCVar == hInfAmmo) iInfAmmo = StringToInt(newValue);
	else if (hCVar == hInfAmmoAdm) iInfAmmoAdm = StringToInt(newValue);
}

void LookupClients() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(client)
{
	if  (1 <= client <= MaxClients && !IsFakeClient(client)) bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
}

public void OnGameFrame()
{
	int iWeapon, iClip;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && (iInfAmmo || (bIsAdmin[i] && iInfAmmoAdm)))
		{
			iWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (IsValidEdict(iWeapon))
			{
				iClip = GetClipSize(i);
 				if (iClip) SetEntData(iWeapon, iClip1Offset, iClip, _, true);
			}
		}
	}
}

stock int GetClipSize(int client)
{
	char sPlayerWeapon[32];
	GetClientWeapon(client, sPlayerWeapon, sizeof(sPlayerWeapon));

	if (StrContains(sPlayerWeapon, "weapon_galil") == 0)
		return 65;
	else if (StrContains(sPlayerWeapon, "weapon_mp5") == 0)
		return 32;
	else if (StrContains(sPlayerWeapon, "weapon_elites") == 0)
		return 30;
	else if (StrContains(sPlayerWeapon, "weapon_fiveseven") == 0 || StrContains(sPlayerWeapon, "weapon_g3sg1") == 0)
		return 20;
	else if (StrContains(sPlayerWeapon, "weapon_glock") == 0)
		return 18;
	else if (StrContains(sPlayerWeapon, "weapon_p228") == 0)
		return 14;
	else if (StrContains(sPlayerWeapon, "weapon_shotgun") == 0)
		return 9;
	else if (StrContains(sPlayerWeapon, "weapon_m4super90") == 0)
		return 8;
	else return 0;
}