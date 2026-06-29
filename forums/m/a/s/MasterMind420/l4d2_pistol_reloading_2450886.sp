#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define MAX_FRAMECHECK 10

static bool:PistolFix[MAXPLAYERS+1] = {true, ...};
static Handle:PistolAmmoReserve = INVALID_HANDLE;
static Handle:l4d2_pistol_ammo_lock = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[L4D2] Pistol Reloading",
	author = "MasterMind420, Ludastar, DeathChaos25, AtomicStryker",
	description = "Allows limited Pistol/Magnum ammo to be roloaded at ammo piles.",
	version = "1.1",
	url = ""
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	PistolAmmoReserve = CreateConVar("l4d2_pistol_reserve", "120", "Pistol ammo reserve amount(setting higher than 120 may have unintended results)");
	l4d2_pistol_ammo_lock = CreateConVar("l4d2_pistol_ammo_lock", "1", "0=Disable pistol ammo lock at 1, 1=Enable pistol ammo lock at 1");

	HookConVarChange(PistolAmmoReserve, ConvarChanged);
	//HookConVarChange(PistolAmmoLock, ConvarChanged);

	HookEvent("player_use", Event_Ammo_Pile, EventHookMode_Pre);
	HookEvent("item_pickup", Event_Item_Pickup);

	AutoExecConfig(true, "l4d2_pistol_reloading");
}

public ConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
    CvarsChanged();
}

public OnMapStart()
{
	CvarsChanged();
}

CvarsChanged()
{
	SetConVarInt(FindConVar("ammo_pistol_max"), GetConVarInt(PistolAmmoReserve));
	//SetConVarInt(FindConVar("pistol_ammo_lock"), GetConVarInt(PistolAmmoLock));
}

public OnClientPutInServer(client)
{
	PistolAmmoFix(client);
	
	//PISTOL/MAGNUM AMMO LOCK
	if (GetConVarInt(l4d2_pistol_ammo_lock) == 1)
		CreateTimer(0.1, PistolAmmoLock, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	//SDKHook(client, SDKHook_WeaponEquip, WeaponEquip); //Fires as soon as the player actually equipped the weapon.
	//SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse); //Fires as soon as the player tries to pickup the weapon.
	//SDKHook(Weapon, SDKHook_Reload, WeaponReload); //Fires as soon as the player reloads a weapon.
}

/*
public Action:WeaponCanUse(client, Weapon)
{
    decl String:sWeapon[32];
    GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

    if (StrEqual(sWeapon, "weapon_pistol"))
    {
		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType == -1)
			continue;

		//SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);

		decl CurrentAmmo;
		CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, AmmoType);

		if (GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
			SetEntProp(client, Prop_Send, "m_iAmmo", CurrentAmmo + ReserveAmmo, _, AmmoType);
    }
	else if (StrEqual(sWeapon, "weapon_pistol_magnum"))
	{
	
	}
	//return Plugin_Handled; //Block what your trying to do
    return Plugin_Continue; //Unblock what your trying to do
}

public Action:WeaponEquip(client, Weapon)
{
	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	//static ReserveAmmo;
	//ReserveAmmo = GetConVarInt(PistolAmmoReserve);

	static AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

	if (AmmoType != -1)
	{
		if (StrEqual(sWeapon, "weapon_pistol"))
		{
			SDKHook(Weapon, SDKHook_Reload, WeaponReload)
			//SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
			//if (GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
			//	SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 210, _, AmmoType);
		}
		else if (StrEqual(sWeapon, "weapon_pistol_magnum"))
		{
			SDKHook(Weapon, SDKHook_Reload, WeaponReload)
			//SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
		}
	}
	//return Plugin_Handled; //Block what your trying to do
	return Plugin_Continue; //Unblock what your trying to do
}

public Action:WeaponReload(Weapon, client)
{
	if (IsSurvivor(client) && IsPlayerAlive(client) && IsValidEntity(Weapon))
	{
		static AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

		if (AmmoType != -1)
		{
			static Clip;
			Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

			static Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			if (Ammo < 1 && Clip == 1) //LOCK GUN CLIPS
				SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
		}
	}
	//return Plugin_Handled; //Block what your trying to do
	return Plugin_Continue; //Unblock what your trying to do
}
*/

PistolAmmoFix(client)
{
	if (!IsSurvivor(client) || !PistolFix[client])
		return;

	static Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);

	if (!IsValidEntity(Weapon))
		return;

	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "weapon_pistol", false) || !StrEqual(sWeapon, "weapon_pistol_magnum", false))
		return;

	decl AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (AmmoType != -1)
	{
		decl ReserveAmmo;
		ReserveAmmo = GetConVarInt(PistolAmmoReserve);

		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);

		PistolFix[client] = false;
	}
}

public OnGameFrame()
{
	static iFrameskip = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	if(iFrameskip != 0 || !IsServerProcessing())
		return;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsFakeClient(client))
			continue;

		decl Weapon;
		Weapon = GetPlayerWeaponSlot(client, 1);

		if (!IsValidEntity(Weapon))
			continue;

		decl String:sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if (!StrEqual(sWeapon, "weapon_pistol") || !StrEqual(sWeapon, "weapon_pistol_magnum"))
			continue;

		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType == -1)
			continue;

		decl Ammo;
		Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, AmmoType);

		if (Ammo == 0)
		{
			if (StrEqual(sWeapon, "weapon_pistol", false))
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", 120, _, AmmoType); //135

				if (GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
					SetEntProp(client, Prop_Send, "m_iAmmo", 120, _, AmmoType); //300
			}
			else if (StrEqual(sWeapon, "weapon_pistol_magnum"))
				SetEntProp(client, Prop_Send, "m_iAmmo", 120, _, AmmoType); //128
		}
	}
}

public Action:PistolAmmoLock(Handle:Timer, any:client)
{
	if (!IsServerProcessing() || !IsSurvivor(client) || !IsPlayerAlive(client) || IsClientInKickQueue(client))
		return Plugin_Continue;

	decl Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);
	//Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(Weapon))
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false))
	{
		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType != -1)
		{
			decl Clip;
			Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

			decl Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			if (Ammo < 1 && Clip == 1) //LOCK GUN CLIPS
				SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
		}
	}
	return Plugin_Continue;
}

public Action:Event_Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));

	decl Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);
	if (!IsValidEntity(Weapon))
		return Plugin_Continue;

	decl AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (AmmoType == -1)
		return Plugin_Continue;

	decl ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);

	if (StrEqual(sWeapon, "weapon_pistol", false))
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);

		if (GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
			SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 210, _, AmmoType);
	}
	else if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);

	return Plugin_Continue;
}

public Action:Event_Ammo_Pile(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	decl AmmoPile;
	AmmoPile = GetClientAimTarget(client, false);
	if (AmmoPile < 32 || !IsValidEntity(AmmoPile))
		return Plugin_Continue;

	decl String:eName[32];
	GetEntityClassname(AmmoPile, eName, sizeof(eName));

	decl Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);
	//Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(Weapon))
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	static ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);

	if (StrEqual(eName, "weapon_ammo_spawn", false))
	{
		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType != -1)
		{
			decl Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			decl Float:cPos[3];
			decl Float:aPos[3];

			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cPos);
			GetEntPropVector(AmmoPile, Prop_Data, "m_vecAbsOrigin", aPos);

			if (GetVectorDistance(cPos, aPos) <= 125.0)
			{
				if (StrEqual(sWeapon, "weapon_pistol", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);

					if (GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
						SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 120, _, AmmoType);
					PrintHintText(client, "RELOADED");
				}
				if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 8, _, AmmoType);
					PrintHintText(client, "RELOADED");
				}

				//PISTOL/MAGNUM AMMO UNLOCK
				if (GetConVarInt(l4d2_pistol_ammo_lock) == 1 && (StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)))
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}