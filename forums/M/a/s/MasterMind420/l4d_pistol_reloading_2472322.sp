#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define MAX_FRAMECHECK 10

static bool:bPistol[MAXPLAYERS+1] = {true, ...};
static bool:PistolFix[MAXPLAYERS+1] = {true, ...};

static Handle:LockPistolAmmo = INVALID_HANDLE;
static Handle:PistolAmmoReserve = INVALID_HANDLE;
static Handle:PistolAmmoUseDistance = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[L4D2] Pistol Reloading",
	author = "MasterMind420, Ludastar, DeathChaos25, AtomicStryker",
	description = "Allows limited Pistol/Magnum ammo to be roloaded at ammo piles.",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{
	LockPistolAmmo = CreateConVar("l4d2_pistol_ammo_lock", "1", "0=Disable pistol ammo lock at 1, 1=Enable pistol ammo lock at 1", FCVAR_NOTIFY);
	PistolAmmoReserve = CreateConVar("l4d2_pistol_reserve", "120", "Pistol ammo reserve amount", FCVAR_NOTIFY);
	PistolAmmoUseDistance = CreateConVar("l4d2_pistol_ammo_use_distance", "96", " Distance at which you want to use ammo piles ", FCVAR_NOTIFY);

	HookConVarChange(PistolAmmoReserve, ConvarChanged);

	HookEvent("item_pickup", Event_Item_Pickup);
	HookEvent("player_use", Event_Ammo_Pickup, EventHookMode_PostNoCopy);

	AutoExecConfig(true, "l4d_pistol_reloading");
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
}

public OnClientPutInServer(client)
{
	PistolAmmoFix(client);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponSwitch);

	//PISTOL/MAGNUM AMMO LOCK
	if (GetConVarInt(LockPistolAmmo) == 1)
		CreateTimer(0.1, PistolAmmoLock, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

/*[----->|ROUND START AMMO|<-----]*/
PistolAmmoFix(client)
{
	if (!IsSurvivor(client) || !PistolFix[client])
		return;
	
	static ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);
	
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
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
		PistolFix[client] = false;
	}
}

/*[----->|BOT PISTOL AMMO|<-----]*/
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

/*[----->|AMMO LOCK|<-----]*/
public Action:PistolAmmoLock(Handle:Timer, any:client)
{
	if (!IsServerProcessing() || !IsSurvivor(client) || !IsPlayerAlive(client) || IsClientInKickQueue(client))
		return Plugin_Continue;

	//decl aWeapon;
	static aWeapon;
	aWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	//decl Weapon;
	static Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);

	if (!IsValidEntity(aWeapon) || !IsValidEntity(Weapon))
		return Plugin_Continue;

	if (Weapon != -1 || aWeapon == Weapon)
	{
		decl String:sWeapon[64];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_first_aid_kit", false))
			return Plugin_Continue;

		static AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

		if (AmmoType == -1)
			return Plugin_Continue;

		static Clip;
		Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

		static Ammo;
		Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

		if (Ammo < 1 && Clip <= 1)
		{
			if (bPistol[client])
			{
				PrintHintText(client, "WEAPON EMPTY", sWeapon);
				bPistol[client]=false
			}
			SetEntProp(Weapon, Prop_Send, "m_iClip1", 1);
			SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
		}
	}
	return Plugin_Continue;
}

/*[----->|ITEM PICKUP|<-----]*/
public Action:Event_Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	static ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);

	decl String:sWeapon[32];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));

	static Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);
	if (!IsValidEntity(Weapon))
		return Plugin_Continue;

	decl AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (AmmoType == -1)
		return Plugin_Continue;

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

/*[----->|AMMO PICKUP|<-----]*/
public Action:Event_Ammo_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	static ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);

	static AmmoPile;
	AmmoPile = GetClientAimTarget(client, false);

	if (AmmoPile < 32 || !IsValidEntity(AmmoPile))
		return Plugin_Continue;

	decl String:eName[32];
	GetEntityClassname(AmmoPile, eName, sizeof(eName));

	if (!StrEqual(eName, "weapon_ammo_spawn", false))
		return Plugin_Continue;

	static Weapon;
	//Weapon = GetPlayerWeaponSlot(client, 1);
	Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(Weapon))
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	static AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

	if (AmmoType == -1)
		return Plugin_Continue;

	//static Ammo;
	//Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

	//static Clip;
	//Clip = GetEntProp(Weapon, Prop_Send, "m_iClip1");

	static Float:cPos[3];
	static Float:aPos[3];

	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cPos);
	GetEntPropVector(AmmoPile, Prop_Data, "m_vecAbsOrigin", aPos);

	if (GetVectorDistance(cPos, aPos) <= GetConVarInt(PistolAmmoUseDistance))
	{
		bPistol[client]=true; //FIXES WEAPON EMPTY MESSAGE IN AMMO LOCK TIMER
		
		//PISTOL/MAGNUM AMMO UNLOCK
		if (GetConVarInt(LockPistolAmmo) == 1 && (StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)))
		{
			SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
			SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
		}

		if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
		{
			//if (Ammo < 1 && Clip == 1)
			//	SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 120, _, AmmoType);
			PrintHintText(client, "PISTOLS RELOADED");
		}
		else if (StrEqual(sWeapon, "weapon_pistol", false))
		{
			//if (Ammo < 1 && Clip == 1)
			//	SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
			PrintHintText(client, "PISTOL RELOADED");
		}
		if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
		{
			//if (Ammo < 1 && Clip == 1)
			//	SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
			PrintHintText(client, "MAGNUM RELOADED");
		}
	}
	return Plugin_Continue;
}

/*[----->|HOOKS|<-----]*/
/*WORKING WEAPON DETECTION*/
public Action:Hook_WeaponSwitch(client, Weapon)
{
	if (!IsServerProcessing() || !IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) || IsClientInKickQueue(client) || !IsValidEntity(Weapon))
		return Plugin_Continue;

	//decl aWeapon;
	static aWeapon;
	aWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(aWeapon) || !IsValidEntity(Weapon) || Weapon == -1)
		return Plugin_Continue;

	if (aWeapon == Weapon) //if (Weapon != -1 || aWeapon == Weapon)
	{
		decl String:sWeapon[64];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_first_aid_kit", false))
			return Plugin_Continue;

		static AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

		if (AmmoType == -1)
			return Plugin_Continue;

		static Clip;
		Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

		static Ammo;
		Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

		if (Ammo < 1 && Clip <= 1)
			PrintHintText(client, "WEAPON EMPTY", sWeapon);
	}
	return Plugin_Continue;
}

/*[----->|STOCKS|<-----]*/
stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}