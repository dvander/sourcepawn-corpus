#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define MAX_FRAMECHECK 10

GameMode;
L4D2Version;

bool:bPistol[MAXPLAYERS+1] = {true, ...};
bool:PistolFix[MAXPLAYERS+1] = {true, ...};

Handle:PistolAmmoLock = INVALID_HANDLE;
Handle:PistolResetClip = INVALID_HANDLE;
Handle:PistolAmmoReserve = INVALID_HANDLE;
Handle:PistolEmptyNotify = INVALID_HANDLE;
Handle:PistolReloadNotify = INVALID_HANDLE;
Handle:PistolAmmoUseDistance = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[L4D2] Pistol Reloading",
	author = "MasterMind420, Ludastar, DeathChaos25, AtomicStryker",
	description = "Allows limited Pistol/Magnum ammo to be roloaded at ammo piles.",
	version = "1.2",
	url = ""
}

public OnPluginStart()
{
	GameCheck();

	PistolAmmoLock = CreateConVar("l4d_pistol_ammo_lock", "1", "0=Disable pistol ammo lock at 1, 1=Enable pistol ammo lock at 1", FCVAR_NOTIFY);
	PistolResetClip = CreateConVar("l4d_pistol_reset_clip", "0", "0=Disable pistol clip reset to 0 when ammo pickup, 1=Enable pistol clip reset to 0 when ammo pickup", FCVAR_NOTIFY);
	PistolAmmoReserve = CreateConVar("l4d_pistol_ammo_reserve", "120", "Pistol ammo reserve amount", FCVAR_NOTIFY);
	PistolEmptyNotify = CreateConVar("l4d_pistol_empty_notify", "2", "0=Disable pistol empty notification, 1=Enable chat pistol empty notification, 2=Enable hint pistol empty notification", FCVAR_NOTIFY);
	PistolReloadNotify = CreateConVar("l4d_pistol_reload_notify", "2", "0=Disable pistol reload notification, 1=Enable chat pistol reload notification, 2=Enable hint pistol reload notification", FCVAR_NOTIFY);
	PistolAmmoUseDistance = CreateConVar("l4d_pistol_ammo_use_distance", "96", " Distance at which you want to use ammo piles ", FCVAR_NOTIFY);

	HookConVarChange(PistolAmmoReserve, ConvarChanged);

	HookEvent("player_use", Event_Ammo_Pickup);
	HookEvent("weapon_pickup", Event_Item_Pickup);

	AutoExecConfig(true, "l4d_pistol_reloading");
}

GameCheck()
{
	decl String:GameName[16];
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
		L4D2Version=true;
	else
		L4D2Version=false;

	GameMode+=0;
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

public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(PistolAmmoLock) == 1)
		CreateTimer(0.1, PistolAmmoLockTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if (!IsFakeClient(client))
	{
		bPistol[client] = true;
		PistolFix[client] = true;
		PistolAmmoFix(client);
		SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponSwitch);
	}
}

/*[----->|ROUND START AMMO|<-----]*/
PistolAmmoFix(client)
{
	if (!IsSurvivor(client) || !PistolFix[client])
		return;
	
	decl ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);
	
	decl Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);

	if (!IsValidEntity(Weapon))
		return;

	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "weapon_pistol", false) || !StrEqual(sWeapon, "weapon_pistol_magnum", false))
		return;

	decl AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (AmmoType == -1)
		return;

	if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 210, _, AmmoType);

	else if (StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false) && L4D2Version)
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);

	PistolFix[client] = false;
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

		if (StrEqual(sWeapon, "weapon_pistol") || StrEqual(sWeapon, "weapon_pistol_magnum"))
		{
			decl AmmoType;
			AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
			if (AmmoType == -1)
				continue;

			decl Ammo;
			Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, AmmoType);

			if (Ammo == 0)
				SetEntProp(client, Prop_Send, "m_iAmmo", 120, _, AmmoType);
		}
	}
}

/*[----->|AMMO LOCK|<-----]*/
public Action:PistolAmmoLockTimer(Handle:Timer, any:client)
{
	if (!IsServerProcessing() || !IsSurvivor(client) || !IsPlayerAlive(client) || IsClientInKickQueue(client))
		return Plugin_Continue;

	decl aWeapon;
	aWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	decl Weapon;
	Weapon = GetPlayerWeaponSlot(client, 1);

	if (!IsValidEntity(aWeapon) || !IsValidEntity(Weapon))
		return Plugin_Continue;

	if (Weapon != -1 || aWeapon == Weapon)
	{
		decl String:sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_first_aid_kit", false))
			return Plugin_Continue;

		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType == -1)
			return Plugin_Continue;

		decl Clip;
		Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

		decl Ammo;
		Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

		if (Ammo < 1 && Clip <= 1)
		{
			if (bPistol[client])
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

	decl ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);

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

	if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 210, _, AmmoType);
	else if (StrEqual(sWeapon, "weapon_pistol", false))
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
	else if (StrEqual(sWeapon, "weapon_pistol_magnum", false) && L4D2Version)
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);

	return Plugin_Continue;
}

/*[----->|AMMO PICKUP|<-----]*/
public Action:Event_Ammo_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	decl ReserveAmmo;
	ReserveAmmo = GetConVarInt(PistolAmmoReserve);

	//GET THE AMMO PILE
	new AmmoPile = GetEventInt(event, "targetid");
	if (!IsValidEntity(AmmoPile))
		return Plugin_Continue;

	decl String:eName[32];
	GetEntityClassname(AmmoPile, eName, sizeof(eName));

	if (!StrEqual(eName, "weapon_ammo_spawn", false))
		return Plugin_Continue;

	//GET THE WEAPON
	decl Weapon;
	Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(Weapon))
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	//GET AMMO & CLIP
	decl AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (AmmoType == -1)
		return Plugin_Continue;

	decl Ammo;
	Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

	decl Clip;
	Clip = GetEntProp(Weapon, Prop_Send, "m_iClip1");

	//GET CLIENT DISTANCE FROM AMMO PILE
	decl Float:cPos[3];
	decl Float:aPos[3];

	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cPos);
	GetEntPropVector(AmmoPile, Prop_Data, "m_vecAbsOrigin", aPos);

	if (GetVectorDistance(cPos, aPos) <= GetConVarInt(PistolAmmoUseDistance))
	{
		bPistol[client]=true; //FIXES WEAPON EMPTY MESSAGE IN AMMO LOCK TIMER
		
		//PISTOL/MAGNUM AMMO UNLOCK
		if (GetConVarInt(PistolAmmoLock) == 1 && (StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)))
			SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());

		if (StrEqual(sWeapon, "weapon_pistol", false) && GetEntProp(Weapon, Prop_Send, "m_hasDualWeapons"))
		{
			//RELOAD ON 1 AMMO LEFT IN CLIP
			if (Ammo < 1 && Clip == 1)
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);

			//PREVENT RELOAD WHEN AMMO FULL
			if (Ammo >= (ReserveAmmo + ReserveAmmo) && Clip == 30)
				return Plugin_Continue;
				
			//PISTOL RELOAD NOTIFICATION
			if (GetConVarInt(PistolReloadNotify) == 1)
				PrintToChat(client, "PISTOLS RELOADED");
			else if (GetConVarInt(PistolReloadNotify) == 2)
				PrintHintText(client, "PISTOLS RELOADED");
				
			//PISTOL CLIP RESET
			if (GetConVarInt(PistolResetClip) == 1)
			{
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
				SetEntProp(client, Prop_Send, "m_iAmmo", (ReserveAmmo + 15) + (ReserveAmmo + 15), _, AmmoType);
			}
			else
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + ReserveAmmo, _, AmmoType);
		}
		else if (StrEqual(sWeapon, "weapon_pistol", false))
		{
			//RELOAD ON 1 AMMO LEFT IN CLIP
			if (Ammo < 1 && Clip == 1)
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
				
			//PREVENT RELOAD WHEN AMMO FULL
			if (Ammo >= ReserveAmmo && Clip == 15)
				return Plugin_Continue;
				
			//PISTOL RELOAD NOTIFICATION
			if (GetConVarInt(PistolReloadNotify) == 1)
				PrintToChat(client, "PISTOL RELOADED");
			else if (GetConVarInt(PistolReloadNotify) == 2)
				PrintHintText(client, "PISTOL RELOADED");
				
			//PISTOL CLIP RESET
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
			//RELOAD ON 1 AMMO LEFT IN CLIP
			if (Ammo < 1 && Clip == 1)
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);

			//PREVENT RELOAD WHEN AMMO FULL
			if (Ammo >= ReserveAmmo && Clip == 8)
				return Plugin_Continue;
				
			//PISTOL RELOAD NOTIFICATION
			if (GetConVarInt(PistolReloadNotify) == 1)
				PrintToChat(client, "MAGNUM RELOADED");
			else if (GetConVarInt(PistolReloadNotify) == 2)
				PrintHintText(client, "MAGNUM RELOADED");

			//PISTOL CLIP RESET
			if (GetConVarInt(PistolResetClip) == 1)
			{
				SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 8, _, AmmoType);
			}
			else
				SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, AmmoType);
		}
	}
	return Plugin_Continue;
}

/*[----->|HOOKS|<-----]*/
public Action:Hook_WeaponSwitch(client, Weapon)
{
	if (!IsServerProcessing() || !IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) || IsClientInKickQueue(client) || !IsValidEntity(Weapon))
		return Plugin_Continue;

	decl aWeapon;
	aWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(aWeapon))
		return Plugin_Continue;

	if (Weapon != -1 || aWeapon == Weapon)
	{
		decl String:sWeapon[64];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_first_aid_kit", false))
			return Plugin_Continue;

		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType == -1)
			return Plugin_Continue;

		decl Clip;
		Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

		decl Ammo;
		Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

		if (Ammo < 1 && Clip <= 1)
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
		}
	}
	return Plugin_Continue;
}

/*[----->|STOCKS|<-----]*/
stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}