#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAX_FRAMECHECK 10
//#define OVERLAY "materials/vgui/player_ammo_panel"

int GameMode;

bool L4D2Version;
bool bPistol[MAXPLAYERS+1] = {true, ...};
bool bPistolFix[MAXPLAYERS+1] = {true, ...};

Handle PistolResetClip = INVALID_HANDLE;
Handle PistolAmmoReserve = INVALID_HANDLE;
Handle PistolEmptyNotify = INVALID_HANDLE;
Handle PistolReloadNotify = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "[L4D2] Pistol Reloading",
	author = "MasterMind420, Ludastar, DeathChaos25, AtomicStryker",
	description = "Allows limited Pistol/Magnum ammo to be roloaded at ammo piles.",
	version = "1.3",
	url = ""
};

public void OnPluginStart()
{
	GameCheck();

	PistolResetClip = CreateConVar("l4d_pistol_reset_clip", "0", "0=Disable pistol clip reset to 0 when ammo pickup, 1=Enable pistol clip reset to 0 when ammo pickup", FCVAR_NOTIFY);
	PistolAmmoReserve = CreateConVar("l4d_pistol_ammo_reserve", "120", "Pistol ammo reserve amount", FCVAR_NOTIFY);
	PistolEmptyNotify = CreateConVar("l4d_pistol_empty_notify", "2", "0=Disable pistol empty notification, 1=Enable chat pistol empty notification, 2=Enable hint pistol empty notification", FCVAR_NOTIFY);
	PistolReloadNotify = CreateConVar("l4d_pistol_reload_notify", "2", "0=Disable pistol reload notification, 1=Enable chat pistol reload notification, 2=Enable hint pistol reload notification", FCVAR_NOTIFY);

	HookConVarChange(PistolAmmoReserve, ConvarChanged);

	HookEvent("player_use", Event_Ammo_Pickup);

	AutoExecConfig(true, "l4d_pistol_reloading");
}

void GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
		GameMode = 0;

	GetGameFolderName(GameName, sizeof(GameName));

	if (StrEqual(GameName, "left4dead2", false))
		L4D2Version = true;
	else
		L4D2Version = false;

	GameMode+=0;
}

public void ConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
    CvarsChanged();
}

public void OnMapStart()
{
	CvarsChanged();
	//PrecacheDecal(OVERLAY, true); //OVERLAY PRECACHE
}

void CvarsChanged()
{
	SetConVarInt(FindConVar("ammo_pistol_max"), GetConVarInt(PistolAmmoReserve));
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client)) return;

	if (GetConVarInt(PistolEmptyNotify) > 0)
		CreateTimer(0.1, PistolNotifyTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	bPistol[client] = true;
	bPistolFix[client] = true;

	SDKHook(client, SDKHook_WeaponEquip, Hook_WeaponEquip);

	if (GetConVarInt(PistolEmptyNotify) > 0)
		SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponSwitch);

	//DisplayScreenOverlay();

	if(L4D2Version || !L4D2Version) return;
}

public Action Hook_WeaponEquip(int client, int weapon)
{
	if (!IsSurvivor(client) || !bPistolFix[client])
		return;

	bPistolFix[client] = false;
}

/*[----->|BOT PISTOL AMMO|<-----]*/
public void OnGameFrame()
{
	int iFrameskip = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	if(iFrameskip != 0 || !IsServerProcessing())
		return;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsFakeClient(client))
			continue;

		int Weapon = GetPlayerWeaponSlot(client, 1);
		if (Weapon == -1) continue;

		char sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_pistol") || StrEqual(sWeapon, "weapon_pistol_magnum"))
		{
			int AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
			if (AmmoType == -1) continue;

			int Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, AmmoType);

			if (Ammo == 0)
				SetEntProp(client, Prop_Send, "m_iAmmo", 120, _, AmmoType);
		}
	}
}

public Action PistolNotifyTimer(Handle Timer, any client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client)) return;

	int Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (Weapon == -1) return;

	char sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!(StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)))
		return;

	int AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (AmmoType == -1) return;

	int Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");
	int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

	if (bPistol[client] && Ammo < 1 && Clip <= 1)
	{
		if (GetConVarInt(PistolEmptyNotify) == 1)
		{
			if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
				PrintToChat(client, "PISTOLS EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol", false))
				PrintToChat(client, "PISTOL EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
				PrintToChat(client, "MAGNUM EMPTY");
		}
		else if (GetConVarInt(PistolEmptyNotify) == 2)
		{
			if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
				PrintHintText(client, "PISTOLS EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol", false))
				PrintHintText(client, "PISTOL EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
				PrintHintText(client, "MAGNUM EMPTY");
		}

		bPistol[client] = false;
	}
}

public Action Event_Ammo_Pickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client)) return;

	int AmmoPile = event.GetInt("targetid");
	if (!IsValidEntity(AmmoPile)) return;

	char sWeapon[32];
	GetEntityClassname(AmmoPile, sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "weapon_ammo_spawn", false))
		return;

	int Weapon = GetPlayerWeaponSlot(client, 1);
	if (Weapon == -1) return;

	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!(StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)))
		return;

	float cPos[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cPos);

	float aPos[3];
	GetEntPropVector(AmmoPile, Prop_Data, "m_vecAbsOrigin", aPos);

	if (GetVectorDistance(cPos, aPos) <= 100)
	{
		bPistol[client] = true; //FIXES WEAPON EMPTY MESSAGE IN AMMO LOCK TIMER

		int AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType == -1) return;

		int ReserveAmmo = GetConVarInt(PistolAmmoReserve);
		int Clip = GetEntProp(Weapon, Prop_Send, "m_iClip1");
		int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

		if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
		{
			if (Ammo < 1 && Clip == 1)
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);

			if (Ammo >= ReserveAmmo && Clip == 30)
				return;
			else if (Ammo > ReserveAmmo && Clip <= 30)
				return;

			if (GetConVarInt(PistolReloadNotify) == 1)
				PrintToChat(client, "\x04PISTOLS RELOADED");
			else if (GetConVarInt(PistolReloadNotify) == 2)
				PrintHintText(client, "PISTOLS RELOADED");

			if (GetConVarInt(PistolResetClip) == 1)
			{
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 30, _, AmmoType);
			}
			else
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
		}
		else if (StrEqual(sWeapon, "weapon_pistol", false))
		{
			if (Ammo < 1 && Clip == 1)
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);

			if (Ammo >= ReserveAmmo && Clip == 15)
				return;
			else if (Ammo > ReserveAmmo && Clip <= 15)
				return;

			if (GetConVarInt(PistolReloadNotify) == 1)
				PrintToChat(client, "\x04PISTOL RELOADED");
			else if (GetConVarInt(PistolReloadNotify) == 2)
				PrintHintText(client, "PISTOL RELOADED");

			if (GetConVarInt(PistolResetClip) == 1)
			{
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 15, _, AmmoType);
			}
			else
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
		}

		if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
		{
			if (Ammo < 1 && Clip == 1)
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);

			if (Ammo >= ReserveAmmo && Clip == 8)
				return;
			else if (Ammo > ReserveAmmo && Clip <= 8)
				return;

			if (GetConVarInt(PistolReloadNotify) == 1)
				PrintToChat(client, "\x04MAGNUM RELOADED");
			else if (GetConVarInt(PistolReloadNotify) == 2)
				PrintHintText(client, "MAGNUM RELOADED");

			if (GetConVarInt(PistolResetClip) == 1)
			{
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 8, _, AmmoType);
			}
			else
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
		}
	}
}

public Action Hook_WeaponSwitch(int client, int Weapon)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) || Weapon == -1)
		return;

	char sWeapon[64];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!(StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)))
		return;

	int AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (AmmoType == -1) return;

	int Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");
	int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

	if (Ammo < 1 && Clip <= 1)
	{
		if (GetConVarInt(PistolEmptyNotify) == 1)
		{
			if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
				PrintToChat(client, "\x04PISTOLS EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol", false))
					PrintToChat(client, "\x04PISTOL EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
				PrintToChat(client, "\x04MAGNUM EMPTY");
		}
		else if (GetConVarInt(PistolEmptyNotify) == 2)
		{
			if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
				PrintHintText(client, "PISTOLS EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol", false))
				PrintHintText(client, "PISTOL EMPTY");
			else if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
				PrintHintText(client, "MAGNUM EMPTY");
		}
	}
}

/*=====[ OVERLAY FUNCTIONS ]=====
public DisplayScreenOverlay()
{
	int iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags &~ FCVAR_CHEAT);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			ClientCommand(i, "r_screenoverlay \"%s\"", OVERLAY);
	}

	SetCommandFlags("r_screenoverlay", iFlags);
}
*/

/*=====[ MY STOCKS ]=====*/
stock bool IsValidAdmin(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) return true;
	return false;
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) return true;
	return false;
}

stock bool IsSpectator(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1) return true;
	return false;
}

stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2) return true;
	return false;
}

stock bool IsInfected(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3) return true;
	return false;
}

//maybe you can split the ammo amount for single pistol, dual pistols (double ammo) and Magnum.