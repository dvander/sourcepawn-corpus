#pragma semicolon 1

#define PLUGIN_AUTHOR "DeathChaos25"
#define PLUGIN_VERSION "1.5"

#include <sourcemod>
#include <sdktools>

#define SOUND_BIGREWARD			"UI/BigReward.wav"			// Give
#define SOUND_LITTLEREWARD		"UI/LittleReward.wav"		// Receive

// arrays to keep track of weapons
static Handle:SMGArray = INVALID_HANDLE;
static Handle:T1ShotgunArray = INVALID_HANDLE;
static Handle:T2ShotgunArray = INVALID_HANDLE;
static Handle:SniperArray = INVALID_HANDLE;
static Handle:AssaultRifleArray = INVALID_HANDLE;
static Handle:PistolArray = INVALID_HANDLE;
static Handle:MagnumArray = INVALID_HANDLE;
static Handle:NearbyItems = INVALID_HANDLE;


// per bot preferences

// coach
static bool:CoachCanUseSMG;
static bool:CoachCanUseT1Shotgun;
static bool:CoachCanUseT2Shotgun;
static bool:CoachCanUseSniper;
static bool:CoachCanUseAssaultRifle;
static bool:CoachCanUsePistol;
static bool:CoachCanUseMagnum;

// ellis
static bool:EllisCanUseSMG;
static bool:EllisCanUseT1Shotgun;
static bool:EllisCanUseT2Shotgun;
static bool:EllisCanUseSniper;
static bool:EllisCanUseAssaultRifle;
static bool:EllisCanUsePistol;
static bool:EllisCanUseMagnum;

// nick
static bool:NickCanUseSMG;
static bool:NickCanUseT1Shotgun;
static bool:NickCanUseT2Shotgun;
static bool:NickCanUseSniper;
static bool:NickCanUseAssaultRifle;
static bool:NickCanUsePistol;
static bool:NickCanUseMagnum;

// rochelle
static bool:RochelleCanUseSMG;
static bool:RochelleCanUseT1Shotgun;
static bool:RochelleCanUseT2Shotgun;
static bool:RochelleCanUseSniper;
static bool:RochelleCanUseAssaultRifle;
static bool:RochelleCanUsePistol;
static bool:RochelleCanUseMagnum;

// bill
static bool:BillCanUseSMG;
static bool:BillCanUseT1Shotgun;
static bool:BillCanUseT2Shotgun;
static bool:BillCanUseSniper;
static bool:BillCanUseAssaultRifle;
static bool:BillCanUsePistol;
static bool:BillCanUseMagnum;

// francis
static bool:FrancisCanUseSMG;
static bool:FrancisCanUseT1Shotgun;
static bool:FrancisCanUseT2Shotgun;
static bool:FrancisCanUseSniper;
static bool:FrancisCanUseAssaultRifle;
static bool:FrancisCanUsePistol;
static bool:FrancisCanUseMagnum;

// louis
static bool:LouisCanUseSMG;
static bool:LouisCanUseT1Shotgun;
static bool:LouisCanUseT2Shotgun;
static bool:LouisCanUseSniper;
static bool:LouisCanUseAssaultRifle;
static bool:LouisCanUsePistol;
static bool:LouisCanUseMagnum;

// zoey
static bool:ZoeyCanUseSMG;
static bool:ZoeyCanUseT1Shotgun;
static bool:ZoeyCanUseT2Shotgun;
static bool:ZoeyCanUseSniper;
static bool:ZoeyCanUseAssaultRifle;
static bool:ZoeyCanUsePistol;
static bool:ZoeyCanUseMagnum;

// bots found nothing they can use?
// pick disabled weapons then if restriction is 0
static bool:ZoeyFound;
static bool:NickFound;
static bool:EllisFound;
static bool:CoachFound;
static bool:RochelleFound;
static bool:LouisFound;
static bool:BillFound;
static bool:FrancisFound;

static bool:IsRestricted;

// survivor models to identify who is the bot
static const String:MODEL_NICK[] = "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] = "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] = "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] = "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] = "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] = "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] = "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] = "models/survivors/survivor_manager.mdl";

public Plugin:myinfo = 
{
	name = "[L4D2] Bots Weapon Preferences Editor", 
	author = PLUGIN_AUTHOR, 
	description = "Complete Manipulation over which weapons the bots can or can't use", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=264265"
};

public OnPluginStart()
{
	CreateConVar("sm_bots_weapon_preferences_manipulation_version", PLUGIN_VERSION, "[L4D2] Bots Weapon preferences manipulation Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	//RegConsoleCmd("sm_ammo", AmmoHere);
	RegConsoleCmd("sm_swapprimary", SwapGunWithBot1, "Swaps your primary weapon with whatever bot you're aiming at");
	RegConsoleCmd("sm_swapsecondary", SwapGunWithBot2, "Swaps your secondary weapon with whatever bot you're aiming at");
	SetRestrictions();
	AutoExecConfig(true, "l4d2_bots_weapon_preferences_manipulation");
}

public OnMapStart()
{
	SMGArray = CreateArray();
	T1ShotgunArray = CreateArray();
	T2ShotgunArray = CreateArray();
	SniperArray = CreateArray();
	AssaultRifleArray = CreateArray();
	PistolArray = CreateArray();
	MagnumArray = CreateArray();
}

public OnMapEnd()
{
	ArrayReset();
}

public Action:ResetArrays(Handle:Timer)
{
	ArrayReset();
	
	SMGArray = CreateArray();
	T1ShotgunArray = CreateArray();
	T2ShotgunArray = CreateArray();
	SniperArray = CreateArray();
	AssaultRifleArray = CreateArray();
	PistolArray = CreateArray();
	MagnumArray = CreateArray();
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity <= 0 || entity > 2048 || classname[0] != 'w' || classname[1] != 'e' || classname[2] != 'a')return;
	CreateTimer(2.0, CheckEntityForGrab, entity);
}

public Action:CheckEntityForGrab(Handle:timer, any:entity)
{
	if (!IsValidEntity(entity))
	{
		return;
	}
	new String:classname[128]; GetEntityClassname(entity, classname, sizeof(classname));
	
	// categorize weapons by category and add them to the appropriate arrays to keep track of them
	if (StrContains(classname, "weapon_", false) != -1)
	{
		if (IsPistol(entity) && PistolArray != INVALID_HANDLE)
		{
			if (!IsWeaponOwned(entity))
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (entity == GetArrayCell(PistolArray, i))
					{
						return;
					}
					else if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						RemoveFromArray(PistolArray, i);
					}
				}
				PushArrayCell(PistolArray, entity);
			}
		}
		else if (IsMagnum(entity) && MagnumArray != INVALID_HANDLE)
		{
			if (!IsWeaponOwned(entity))
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (entity == GetArrayCell(MagnumArray, i))
					{
						return;
					}
					else if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						RemoveFromArray(MagnumArray, i);
					}
				}
				PushArrayCell(MagnumArray, entity);
			}
		}
		else if (IsT1Shotgun(entity) && T1ShotgunArray != INVALID_HANDLE)
		{
			if (!IsWeaponOwned(entity))
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (entity == GetArrayCell(T1ShotgunArray, i))
					{
						return;
					}
					else if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						RemoveFromArray(T1ShotgunArray, i);
					}
				}
				PushArrayCell(T1ShotgunArray, entity);
			}
		}
		else if (IsT2Shotgun(entity) && T2ShotgunArray != INVALID_HANDLE)
		{
			if (!IsWeaponOwned(entity))
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (entity == GetArrayCell(T2ShotgunArray, i))
					{
						return;
					}
					else if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						RemoveFromArray(T2ShotgunArray, i);
					}
				}
				PushArrayCell(T2ShotgunArray, entity);
			}
		}
		else if (IsSMG(entity) && SMGArray != INVALID_HANDLE)
		{
			if (!IsWeaponOwned(entity))
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (entity == GetArrayCell(SMGArray, i))
					{
						return;
					}
					else if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						RemoveFromArray(SMGArray, i);
					}
				}
				PushArrayCell(SMGArray, entity);
			}
		}
		else if (IsSniper(entity) && SniperArray != INVALID_HANDLE)
		{
			if (!IsWeaponOwned(entity))
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (entity == GetArrayCell(SniperArray, i))
					{
						return;
					}
					else if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						RemoveFromArray(SniperArray, i);
					}
				}
				PushArrayCell(SniperArray, entity);
			}
		}
		else if (IsAssaultRifle(entity) && AssaultRifleArray != INVALID_HANDLE)
		{
			if (!IsWeaponOwned(entity))
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (entity == GetArrayCell(AssaultRifleArray, i))
					{
						return;
					}
					else if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						RemoveFromArray(AssaultRifleArray, i);
					}
				}
				PushArrayCell(AssaultRifleArray, entity);
			}
		}
	}
}

public OnEntityDestroyed(entity)
{
	if (entity <= 0 || entity > 2048)return;
	
	if (IsPistol(entity) && PistolArray != INVALID_HANDLE)
	{
		if (!IsWeaponOwned(entity))
		{
			for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
			{
				if (entity == GetArrayCell(PistolArray, i))
				{
					RemoveFromArray(PistolArray, i);
				}
			}
		}
	}
	else if (IsMagnum(entity) && MagnumArray != INVALID_HANDLE)
	{
		if (!IsWeaponOwned(entity))
		{
			for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
			{
				if (entity == GetArrayCell(MagnumArray, i))
				{
					RemoveFromArray(MagnumArray, i);
				}
			}
		}
	}
	else if (IsT1Shotgun(entity) && T1ShotgunArray != INVALID_HANDLE)
	{
		if (!IsWeaponOwned(entity))
		{
			for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
			{
				if (entity == GetArrayCell(T1ShotgunArray, i))
				{
					RemoveFromArray(T1ShotgunArray, i);
				}
			}
		}
	}
	else if (IsT2Shotgun(entity) && T2ShotgunArray != INVALID_HANDLE)
	{
		if (!IsWeaponOwned(entity))
		{
			for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
			{
				if (entity == GetArrayCell(T2ShotgunArray, i))
				{
					RemoveFromArray(T2ShotgunArray, i);
				}
			}
		}
	}
	else if (IsSMG(entity) && SMGArray != INVALID_HANDLE)
	{
		if (!IsWeaponOwned(entity))
		{
			for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
			{
				if (entity == GetArrayCell(SMGArray, i))
				{
					RemoveFromArray(SMGArray, i);
				}
			}
		}
	}
	else if (IsSniper(entity) && SniperArray != INVALID_HANDLE)
	{
		if (!IsWeaponOwned(entity))
		{
			for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
			{
				if (entity == GetArrayCell(SniperArray, i))
				{
					RemoveFromArray(SniperArray, i);
				}
			}
		}
	}
	else if (IsAssaultRifle(entity) && AssaultRifleArray != INVALID_HANDLE)
	{
		if (!IsWeaponOwned(entity))
		{
			for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
			{
				if (entity == GetArrayCell(AssaultRifleArray, i))
				{
					RemoveFromArray(AssaultRifleArray, i);
				}
			}
		}
	}
}

public Action:L4D2_OnFindScavengeItem(client, &item)
{
	if (!item)
	{
		decl Float:Origin[3], Float:TOrigin[3];
		new Primary = GetPlayerWeaponSlot(client, 0);
		new Secondary = GetPlayerWeaponSlot(client, 1);
		NearbyItems = CreateArray();
		if (IsCoach(client))
		{
			CoachFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && CoachCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && CoachCanUsePistol && !CoachCanUseMagnum
				 || IsPistol(Secondary) && GetEntProp(Secondary, Prop_Send, "m_hasDualWeapons") == 0)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && CoachCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && CoachCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && CoachCanUseSMG
				 || HasLowAmmo(client, Primary) && CoachCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && CoachCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && CoachCanUseT2Shotgun || HasT1(client, Primary) && CoachCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						CoachFound = true;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && CoachCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && CoachCanUseAssaultRifle || HasT1(client, Primary) && CoachCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						CoachFound = true;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && CoachCanUseSniper
				 || HasLowAmmo(client, Primary) && CoachCanUseSniper || HasT1(client, Primary) && CoachCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						CoachFound = true;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
		
		else if (IsRochelle(client))
		{
			RochelleFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && RochelleCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && RochelleCanUsePistol && !RochelleCanUseMagnum
				 || IsPistol(Secondary) && GetEntProp(Secondary, Prop_Send, "m_hasDualWeapons") == 0)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && RochelleCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && RochelleCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && RochelleCanUseSMG
				 || HasLowAmmo(client, Primary) && RochelleCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && RochelleCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && RochelleCanUseT2Shotgun || HasT1(client, Primary) && RochelleCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						RochelleFound = false;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && RochelleCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && RochelleCanUseAssaultRifle || HasT1(client, Primary) && RochelleCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						RochelleFound = false;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && RochelleCanUseSniper
				 || HasLowAmmo(client, Primary) && RochelleCanUseSniper || HasT1(client, Primary) && RochelleCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						RochelleFound = false;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
		else if (IsNick(client))
		{
			NickFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && NickCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && NickCanUsePistol && !NickCanUseMagnum
				 || IsPistol(Secondary) && GetEntProp(Secondary, Prop_Send, "m_hasDualWeapons") == 0)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && NickCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && NickCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && NickCanUseSMG
				 || HasLowAmmo(client, Primary) && NickCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && NickCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && NickCanUseT2Shotgun || HasT1(client, Primary) && NickCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						NickFound = true;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && NickCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && NickCanUseAssaultRifle || HasT1(client, Primary) && NickCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						NickFound = true;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && NickCanUseSniper
				 || HasLowAmmo(client, Primary) && NickCanUseSniper || HasT1(client, Primary) && NickCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						NickFound = true;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
		else if (IsEllis(client))
		{
			EllisFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && EllisCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && EllisCanUsePistol && !EllisCanUseMagnum
				 || IsPistol(Secondary) && GetEntProp(Secondary, Prop_Send, "m_hasDualWeapons") == 0)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && EllisCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && EllisCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && EllisCanUseSMG
				 || HasLowAmmo(client, Primary) && EllisCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && EllisCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && EllisCanUseT2Shotgun || HasT1(client, Primary) && EllisCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						EllisFound = true;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && EllisCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && EllisCanUseAssaultRifle || HasT1(client, Primary) && EllisCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						EllisFound = true;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && EllisCanUseSniper
				 || HasLowAmmo(client, Primary) && EllisCanUseSniper || HasT1(client, Primary) && EllisCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						EllisFound = true;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
		else if (IsBill(client))
		{
			BillFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && BillCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && BillCanUsePistol && !BillCanUseMagnum
				 || IsPistol(Secondary) && GetEntProp(Secondary, Prop_Send, "m_hasDualWeapons") == 0)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && BillCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && BillCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && BillCanUseSMG
				 || HasLowAmmo(client, Primary) && BillCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && BillCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && BillCanUseT2Shotgun || HasT1(client, Primary) && BillCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						BillFound = true;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && BillCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && BillCanUseAssaultRifle || HasT1(client, Primary) && BillCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						BillFound = true;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && BillCanUseSniper
				 || HasLowAmmo(client, Primary) && BillCanUseSniper || HasT1(client, Primary) && BillCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						BillFound = true;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
		else if (IsFrancis(client))
		{
			FrancisFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && FrancisCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && FrancisCanUsePistol && !FrancisCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && FrancisCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && FrancisCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && FrancisCanUseSMG
				 || HasLowAmmo(client, Primary) && FrancisCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && FrancisCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && FrancisCanUseT2Shotgun || HasT1(client, Primary) && FrancisCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						FrancisFound = true;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && FrancisCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && FrancisCanUseAssaultRifle || HasT1(client, Primary) && FrancisCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						FrancisFound = true;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && FrancisCanUseSniper
				 || HasLowAmmo(client, Primary) && FrancisCanUseSniper || HasT1(client, Primary) && FrancisCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						FrancisFound = true;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
		else if (IsLouis(client))
		{
			LouisFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && LouisCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && LouisCanUsePistol && !LouisCanUseMagnum
				 || IsPistol(Secondary) && GetEntProp(Secondary, Prop_Send, "m_hasDualWeapons") == 0)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && LouisCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && LouisCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && LouisCanUseSMG
				 || HasLowAmmo(client, Primary) && LouisCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && LouisCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && LouisCanUseT2Shotgun || HasT1(client, Primary) && LouisCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						LouisFound = true;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && LouisCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && LouisCanUseAssaultRifle || HasT1(client, Primary) && LouisCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						LouisFound = true;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && LouisCanUseSniper
				 || HasLowAmmo(client, Primary) && LouisCanUseSniper || HasT1(client, Primary) && LouisCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						LouisFound = true;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
		else if (IsZoey(client))
		{
			ZoeyFound = false;
			// Now we force our preferences onto the bots
			// get magnums if enabled
			if (!IsMagnum(Secondary) && ZoeyCanUseMagnum)
			{
				for (new i = 0; i <= GetArraySize(MagnumArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(MagnumArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(MagnumArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(MagnumArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get pistols if enabled
			else if (!IsPistol(Secondary) && !IsMagnum(Secondary) && ZoeyCanUsePistol && !ZoeyCanUseMagnum
				 || IsPistol(Secondary) && GetEntProp(Secondary, Prop_Send, "m_hasDualWeapons") == 0)
			{
				for (new i = 0; i <= GetArraySize(PistolArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(PistolArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(PistolArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(PistolArray, i);
						return Plugin_Changed;
					}
				}
			}
			// get T1 shotguns if enabled
			else if (!IsValidEdict(Primary) && ZoeyCanUseT1Shotgun
				 || HasLowAmmo(client, Primary) && ZoeyCanUseT1Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T1ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T1ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T1ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(T1ShotgunArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get smgs if enabled
			else if (!IsValidEdict(Primary) && ZoeyCanUseSMG
				 || HasLowAmmo(client, Primary) && ZoeyCanUseSMG)
			{
				for (new i = 0; i <= GetArraySize(SMGArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SMGArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SMGArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						item = GetArrayCell(SMGArray, i);
						return Plugin_Changed;
					}
				}
			}
			
			// get T2 Shotguns if enabled
			else if (!IsValidEdict(Primary) && ZoeyCanUseT2Shotgun
				 || HasLowAmmo(client, Primary) && ZoeyCanUseT2Shotgun || HasT1(client, Primary) && ZoeyCanUseT2Shotgun)
			{
				for (new i = 0; i <= GetArraySize(T2ShotgunArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(T2ShotgunArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(T2ShotgunArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(T2ShotgunArray, i));
						ZoeyFound = true;
					}
				}
			}
			
			// get Assault Rifles if enabled
			else if (!IsValidEdict(Primary) && ZoeyCanUseAssaultRifle
				 || HasLowAmmo(client, Primary) && ZoeyCanUseAssaultRifle || HasT1(client, Primary) && ZoeyCanUseAssaultRifle)
			{
				for (new i = 0; i <= GetArraySize(AssaultRifleArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(AssaultRifleArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(AssaultRifleArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(AssaultRifleArray, i));
						ZoeyFound = true;
					}
				}
			}
			
			// get Sniper Rifles if enabled
			else if (!IsValidEdict(Primary) && ZoeyCanUseSniper
				 || HasLowAmmo(client, Primary) && ZoeyCanUseSniper || HasT1(client, Primary) && ZoeyCanUseSniper)
			{
				for (new i = 0; i <= GetArraySize(SniperArray) - 1; i++)
				{
					if (!IsValidEntity(GetArrayCell(SniperArray, i)))
					{
						return Plugin_Continue;
					}
					GetEntPropVector(GetArrayCell(SniperArray, i), Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(TOrigin, Origin);
					if (distance < 500)
					{
						PushArrayCell(NearbyItems, GetArrayCell(SniperArray, i));
						ZoeyFound = true;
					}
				}
			}
			item = GetRandomValueFromArray(NearbyItems);
			CloseHandle(NearbyItems);
			NearbyItems = INVALID_HANDLE;
			return Plugin_Changed;
		}
	}
	// bookmark1
	else if (IsSniper(item) || IsT2Shotgun(item) || IsAssaultRifle(item) || IsT1Shotgun(item) || IsSMG(item) || IsPistol(item) || IsMagnum(item))
	{
		new Primary = GetPlayerWeaponSlot(client, 0);
		if (IsCoach(client))
		{
			if (CoachFound || IsRestricted)
			{
				if (IsPistol(item) && !CoachCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !CoachCanUseMagnum
					 || IsT1Shotgun(item) && !CoachCanUseT1Shotgun
					 || IsT2Shotgun(item) && !CoachCanUseT2Shotgun
					 || IsAssaultRifle(item) && !CoachCanUseAssaultRifle
					 || IsSniper(item) && !CoachCanUseSniper
					 || IsSMG(item) && !CoachCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
		else if (IsEllis(client))
		{
			if (EllisFound || IsRestricted)
			{
				if (IsPistol(item) && !EllisCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !EllisCanUseMagnum
					 || IsT1Shotgun(item) && !EllisCanUseT1Shotgun
					 || IsT2Shotgun(item) && !EllisCanUseT2Shotgun
					 || IsAssaultRifle(item) && !EllisCanUseAssaultRifle
					 || IsSniper(item) && !EllisCanUseSniper
					 || IsSMG(item) && !EllisCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
		
		else if (IsNick(client))
		{
			if (NickFound || IsRestricted)
			{
				if (IsPistol(item) && !NickCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !NickCanUseMagnum
					 || IsT1Shotgun(item) && !NickCanUseT1Shotgun
					 || IsT2Shotgun(item) && !NickCanUseT2Shotgun
					 || IsAssaultRifle(item) && !NickCanUseAssaultRifle
					 || IsSniper(item) && !NickCanUseSniper
					 || IsSMG(item) && !NickCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
		
		else if (IsRochelle(client))
		{
			if (RochelleFound || IsRestricted)
			{
				if (IsPistol(item) && !RochelleCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !RochelleCanUseMagnum
					 || IsT1Shotgun(item) && !RochelleCanUseT1Shotgun
					 || IsT2Shotgun(item) && !RochelleCanUseT2Shotgun
					 || IsAssaultRifle(item) && !RochelleCanUseAssaultRifle
					 || IsSniper(item) && !RochelleCanUseSniper
					 || IsSMG(item) && !RochelleCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
		
		else if (IsBill(client))
		{
			if (BillFound || IsRestricted)
			{
				if (IsPistol(item) && !BillCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !BillCanUseMagnum
					 || IsT1Shotgun(item) && !BillCanUseT1Shotgun
					 || IsT2Shotgun(item) && !BillCanUseT2Shotgun
					 || IsAssaultRifle(item) && !BillCanUseAssaultRifle
					 || IsSniper(item) && !BillCanUseSniper
					 || IsSMG(item) && !BillCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
		
		else if (IsLouis(client))
		{
			if (LouisFound || IsRestricted)
			{
				if (IsPistol(item) && !LouisCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !LouisCanUseMagnum
					 || IsT1Shotgun(item) && !LouisCanUseT1Shotgun
					 || IsT2Shotgun(item) && !LouisCanUseT2Shotgun
					 || IsAssaultRifle(item) && !LouisCanUseAssaultRifle
					 || IsSniper(item) && !LouisCanUseSniper
					 || IsSMG(item) && !LouisCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
		
		else if (IsFrancis(client))
		{
			if (FrancisFound || IsRestricted)
			{
				if (IsPistol(item) && !FrancisCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !FrancisCanUseMagnum
					 || IsT1Shotgun(item) && !FrancisCanUseT1Shotgun
					 || IsT2Shotgun(item) && !FrancisCanUseT2Shotgun
					 || IsAssaultRifle(item) && !FrancisCanUseAssaultRifle
					 || IsSniper(item) && !FrancisCanUseSniper
					 || IsSMG(item) && !FrancisCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
		
		else if (IsZoey(client))
		{
			if (ZoeyFound || IsRestricted)
			{
				if (IsPistol(item) && !ZoeyCanUsePistol && !HasPistol(client)
					 || IsMagnum(item) && !ZoeyCanUseMagnum
					 || IsT1Shotgun(item) && !ZoeyCanUseT1Shotgun
					 || IsT2Shotgun(item) && !ZoeyCanUseT2Shotgun
					 || IsAssaultRifle(item) && !ZoeyCanUseAssaultRifle
					 || IsSniper(item) && !ZoeyCanUseSniper
					 || IsSMG(item) && !ZoeyCanUseSMG)
				{
					return Plugin_Handled;
				}
			}
			else if (IsSniper(item) || IsSMG(item) || IsT2Shotgun(item) || IsT1Shotgun(item) || IsAssaultRifle(item))
			{
				if (IsValidEdict(Primary) || IsValidEntity(Primary))
				{
					if (!HasLowAmmo(client, Primary) && HasT1(client, Primary) && IsT1Weapon(item)
					     || !HasLowAmmo(client, Primary) && HasT2(client, Primary) && IsT2Weapon(item)) //currentedit
					{
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:SwapGunWithBot1(client, args)
{
	if(!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You must be an ingame alive survivor to use this command!");
	}
	
	new target = GetClientAimTarget(client, true);
	
	if(IsSurvivor(target) && IsPlayerAlive(target) && IsFakeClient(target))
	{
		GiveWeaponToRecipient(client, target, 0, true);
	}
}

public Action:SwapGunWithBot2(client, args)
{
	if(!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You must be an ingame alive survivor to use this command!");
	}
	
	new target = GetClientAimTarget(client, true);
	
	if(IsSurvivor(target) && IsPlayerAlive(target) && IsFakeClient(target))
	{
		GiveWeaponToRecipient(client, target, 1, true);
	}
}

// stock bools

stock bool:IsWeaponOwned(weapon)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i))
		{
			if (GetPlayerWeaponSlot(i, 0) == weapon || GetPlayerWeaponSlot(i, 1) == weapon)
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

// identifying which weapon we are reffering to
stock bool:IsPistol(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		new String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_pistol") || StrEqual(classname, "weapon_pistol_spawn") || StrEqual(modelname, "models/w_models/weapons/w_pistol_b.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsMagnum(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		new String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_pistol_magnum") || StrEqual(classname, "weapon_pistol_magnum_spawn") || StrEqual(modelname, "models/w_models/weapons/w_desert_eagle.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsSMG(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		new String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_smg")
				 || StrEqual(classname, "weapon_smg_spawn")
				 || StrEqual(classname, "weapon_smg_silenced")
				 || StrEqual(classname, "weapon_smg_silenced_spawn")
				 || StrEqual(classname, "weapon_smg_mp5")
				 || StrEqual(classname, "weapon_smg_mp5_spawn")
				 || StrEqual(modelname, "models/w_models/weapons/w_smg_mp5.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_smg_uzi.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_smg_a.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsT1Shotgun(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		new String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_pumpshotgun")
				 || StrEqual(classname, "weapon_pumpshotgun_spawn")
				 || StrEqual(classname, "weapon_shotgun_chrome")
				 || StrEqual(classname, "weapon_shotgun_chrome_spawn")
				 || StrEqual(modelname, "models/w_models/weapons/w_shotgun.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_pumpshotgun_a.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsT2Shotgun(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		new String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_autoshotgun")
				 || StrEqual(classname, "weapon_autoshotgun_spawn")
				 || StrEqual(classname, "weapon_shotgun_spas")
				 || StrEqual(classname, "weapon_shotgun_spas_spawn")
				 || StrEqual(modelname, "models/w_models/weapons/w_autoshot_m4super.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_shotgun_spas.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsAssaultRifle(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		new String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_rifle")
				 || StrEqual(classname, "weapon_rifle_spawn")
				 || StrEqual(classname, "weapon_rifle_desert")
				 || StrEqual(classname, "weapon_rifle_desert_spawn")
				 || StrEqual(classname, "weapon_rifle_ak47")
				 || StrEqual(classname, "weapon_rifle_ak47_spawn")
				 || StrEqual(classname, "weapon_rifle_sg552")
				 || StrEqual(classname, "weapon_rifle_sg552_spawn")
				 || StrEqual(modelname, "models/w_models/weapons/w_rifle_m16a2.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_desert_rifle.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_rifle_ak47.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_rifle_sg552.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsSniper(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		new String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_hunting_rifle")
				 || StrEqual(classname, "weapon_hunting_rifle_spawn")
				 || StrEqual(classname, "weapon_sniper_military")
				 || StrEqual(classname, "weapon_sniper_military_spawn")
				 || StrEqual(classname, "weapon_sniper_awp")
				 || StrEqual(classname, "weapon_sniper_awp_spawn")
				 || StrEqual(classname, "weapon_sniper_scout")
				 || StrEqual(classname, "weapon_sniper_scout_spawn")
				 || StrEqual(modelname, "models/w_models/weapons/w_sniper_mini14.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_sniper_military.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_sniper_awp.mdl")
				 || StrEqual(modelname, "models/w_models/weapons/w_sniper_scout.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsT1Weapon(Primary)
{
	if (IsValidEdict(Primary) || IsValidEntity(Primary))
	{
		if (IsT1Shotgun(Primary) || IsSMG(Primary))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsT2Weapon(Primary)
{
	if (IsValidEdict(Primary) || IsValidEntity(Primary))
	{
		if (IsT2Shotgun(Primary) || IsAssaultRifle(Primary) || IsSniper(Primary))
		{
			return true;
		}
	}
	return false;
}

stock bool:HasT1(client, Primary)
{
	if (IsValidEdict(Primary) || IsValidEntity(Primary))
	{
		if (IsT1Shotgun(Primary) || IsSMG(Primary))
		{
			return true;
		}
	}
	return false;
}

stock bool:HasT2(client, Primary)
{
	if (IsValidEdict(Primary) || IsValidEntity(Primary))
	{
		if (IsT2Shotgun(Primary) || IsAssaultRifle(Primary) || IsSniper(Primary))
		{
			return true;
		}
	}
	return false;
}

stock bool:HasLowAmmo(client, Primary)
{
	if (IsValidEdict(Primary) || IsValidEntity(Primary))
	{
		new iPrimType = GetEntProp(Primary, Prop_Send, "m_iPrimaryAmmoType");
		new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, iPrimType);
		if (IsT2Shotgun(Primary) && ammo <= 70
			 || IsAssaultRifle(Primary) && ammo <= 250
			 || IsSniper(Primary) && ammo <= 125
			 || IsT1Shotgun(Primary) && ammo <= 45
			 || IsSMG(Primary) && ammo <= 450)
		{
			return true;
		}
	}
	return false;
}

stock bool:HasPistol(client)
{
	new Secondary = GetPlayerWeaponSlot(client, 1);
	if (IsPistol(Secondary))
	{
		return true;
	}
	return false;
}

// what survivor is the bot?
stock bool:IsZoey(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_ZOEY, false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsFrancis(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_FRANCIS, false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsLouis(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_LOUIS, false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsBill(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_BILL, false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsNick(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_NICK, false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsEllis(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_ELLIS, false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsCoach(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_COACH, false))
		{
			return true;
		}
	}
	return false;
}

stock GetRandomValueFromArray(Handle:Array)
{
	new rng;
	if (Array != INVALID_HANDLE)
	{
		rng = GetRandomInt(0, GetArraySize(Array) - 1);
		if (!IsValidEntity(rng))
		{
			GetRandomValueFromArray(Array);
		}
		if (rng > MaxClients)return rng;
	}
	return -1;
}

stock ArrayReset()
{
	CloseHandle(SMGArray);
	CloseHandle(T1ShotgunArray);
	CloseHandle(T2ShotgunArray);
	CloseHandle(SniperArray);
	CloseHandle(PistolArray);
	CloseHandle(MagnumArray);
	CloseHandle(NearbyItems);
	
	SMGArray = INVALID_HANDLE;
	T1ShotgunArray = INVALID_HANDLE;
	T2ShotgunArray = INVALID_HANDLE;
	SniperArray = INVALID_HANDLE;
	PistolArray = INVALID_HANDLE;
	MagnumArray = INVALID_HANDLE;
	NearbyItems = INVALID_HANDLE;
}
stock bool:IsRochelle(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_ROCHELLE, false))
		{
			return true;
		}
	}
	return false;
}


public GiveWeaponToRecipient(giver, recipient, slot, swap)
{
	// Only survivors that are alive can do this
	if (!IsSurvivor(giver) || !IsSurvivor(recipient))return;
	new SLOT_EMPTY = -1;
	
	// If we are not swapping, and the recipient already has an item, bail
	new eRecipientWeapon = GetPlayerWeaponSlot(recipient, slot);
	if (!swap && eRecipientWeapon != SLOT_EMPTY)return;
	
	// If we are swapping, and the recipient weapon is invalid, bail
	if (swap && (eRecipientWeapon == SLOT_EMPTY || !IsValidEntity(eRecipientWeapon)))return;
	
	// Make sure the weapon the giver is giving is still valid
	new eGiverWeapon = GetPlayerWeaponSlot(giver, slot);
	if (eGiverWeapon == SLOT_EMPTY || !IsValidEntity(eGiverWeapon))return;
	
	new hasdualclient, hasdualtarget, clientclip, targetclip;
	new String:class[128]; GetEntityClassname(eGiverWeapon, class, sizeof(class));
	if(StrEqual(class, "weapon_pistol"))
	{
		hasdualclient = GetEntProp(eGiverWeapon, Prop_Send, "m_hasDualWeapons");
		clientclip = GetEntProp(eGiverWeapon, Prop_Send, "m_iClip1");
		AcceptEntityInput(eGiverWeapon, "Kill");
		eGiverWeapon = CreateEntityByName("weapon_pistol");
		DispatchSpawn(eGiverWeapon);
	}
	GetEntityClassname(eRecipientWeapon, class, sizeof(class));
	if(StrEqual(class, "weapon_pistol"))
	{
		hasdualtarget = GetEntProp(eRecipientWeapon, Prop_Send, "m_hasDualWeapons");
		targetclip = GetEntProp(eRecipientWeapon, Prop_Send, "m_iClip1");
		AcceptEntityInput(eRecipientWeapon, "Kill");
		eRecipientWeapon = CreateEntityByName("weapon_pistol");
		DispatchSpawn(eRecipientWeapon);
	}
	CallThrowWeapon(giver, eGiverWeapon, recipient);
	if (swap)CallThrowWeapon(recipient, eRecipientWeapon, giver);
	
	CallOnWeaponDropped(giver, eGiverWeapon, recipient);
	if (swap)CallOnWeaponDropped(recipient, eRecipientWeapon, giver);
	
	GetEntityClassname(eGiverWeapon, class, sizeof(class));
	if(StrEqual(class, "weapon_pistol"))
	{
		SetEntProp(eGiverWeapon, Prop_Send, "m_hasDualWeapons", hasdualclient);
		EquipPlayerWeapon(recipient, eGiverWeapon);
		SetEntProp(eGiverWeapon, Prop_Send, "m_iClip1", clientclip);
	}
	GetEntityClassname(eRecipientWeapon, class, sizeof(class));
	if(StrEqual(class, "weapon_pistol"))
	{
		SetEntProp(eRecipientWeapon, Prop_Send, "m_hasDualWeapons", hasdualtarget);
		EquipPlayerWeapon(giver, eRecipientWeapon);
		SetEntProp(eRecipientWeapon, Prop_Send, "m_iClip1", targetclip);
	}
	
	PlaySound(recipient, SOUND_LITTLEREWARD);
	if (swap)PlaySound(giver, SOUND_LITTLEREWARD);
}

// CTerrorPlayer::ThrowWeapon(giver, weapon, weapon, recipient, 512.0, 0, 0);
public CallThrowWeapon(giver, weapon, recipient)
{
	static Handle:hThrowWeapon = INVALID_HANDLE;
	if (hThrowWeapon == INVALID_HANDLE)
	{
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4d2_weapon_drop");
		
		StartPrepSDKCall(SDKCall_Player);
		
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "ThrowWeapon"); // this pointer is giver
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer); // weapon
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); // Recipient
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain); // Force (default 512.0)
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // always 0
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // always 0
		
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // returns true/false?
		
		hThrowWeapon = EndPrepSDKCall();
		CloseHandle(hConf);
		
		if (hThrowWeapon == INVALID_HANDLE)
		{
			SetFailState("Can't get ThrowWeapon SDKCall!");
			return;
		}
	}
	
	SDKCall(hThrowWeapon, giver, weapon, recipient, 512.0, 0, 0);
}




//  CTerrorWeapon::OnDropped(CTerrorWeapon *weapon, CTerrorPlayer *giver, CTerrorPlayer *recipient)
public CallOnWeaponDropped(giver, weapon, recipient)
{
	static Handle:hOnWeaponDropped = INVALID_HANDLE;
	if (hOnWeaponDropped == INVALID_HANDLE)
	{
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4d2_weapon_drop");
		
		StartPrepSDKCall(SDKCall_Entity);
		
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "OnWeaponDropped"); // this pointer is giver
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); // Giver
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); // Recipient
		
		// returns ... some kind of CBaseEntity::ThinkSet thinger?
		
		hOnWeaponDropped = EndPrepSDKCall();
		CloseHandle(hConf);
		
		if (hOnWeaponDropped == INVALID_HANDLE)
		{
			SetFailState("Can't get OnWeaponDropped SDKCall!");
			return;
		}
	}
	
	SDKCall(hOnWeaponDropped, weapon, giver, recipient);
}

// convars on a per survivor bot basis
// Coach

public ConVarCoachMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoachCanUseMagnum = GetConVarBool(convar);
}

public ConVarCoachPistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoachCanUsePistol = GetConVarBool(convar);
}

public ConVarCoachT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoachCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarCoachT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoachCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarCoachSMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoachCanUseSMG = GetConVarBool(convar);
}

public ConVarCoachAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoachCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarCoachSnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoachCanUseSniper = GetConVarBool(convar);
}

// Ellis

public ConVarEllisMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EllisCanUseMagnum = GetConVarBool(convar);
}

public ConVarEllisPistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EllisCanUsePistol = GetConVarBool(convar);
}

public ConVarEllisT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EllisCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarEllisT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EllisCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarEllisSMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EllisCanUseSMG = GetConVarBool(convar);
}

public ConVarEllisAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EllisCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarEllisSnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EllisCanUseSniper = GetConVarBool(convar);
}

// Rochelle

public ConVarRochelleMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RochelleCanUseMagnum = GetConVarBool(convar);
}

public ConVarRochellePistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RochelleCanUsePistol = GetConVarBool(convar);
}

public ConVarRochelleT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RochelleCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarRochelleT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RochelleCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarRochelleSMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RochelleCanUseSMG = GetConVarBool(convar);
}

public ConVarRochelleAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RochelleCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarRochelleSnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RochelleCanUseSniper = GetConVarBool(convar);
}

// Nick

public ConVarNickMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NickCanUseMagnum = GetConVarBool(convar);
}

public ConVarNickPistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NickCanUsePistol = GetConVarBool(convar);
}

public ConVarNickT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NickCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarNickT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NickCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarNickSMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NickCanUseSMG = GetConVarBool(convar);
}

public ConVarNickAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NickCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarNickSnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NickCanUseSniper = GetConVarBool(convar);
}

// Bill

public ConVarBillMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BillCanUseMagnum = GetConVarBool(convar);
}

public ConVarBillPistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BillCanUsePistol = GetConVarBool(convar);
}

public ConVarBillT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BillCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarBillT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BillCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarBillSMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BillCanUseSMG = GetConVarBool(convar);
}

public ConVarBillAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BillCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarBillSnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BillCanUseSniper = GetConVarBool(convar);
}

// Louis

public ConVarLouisMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LouisCanUseMagnum = GetConVarBool(convar);
}

public ConVarLouisPistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LouisCanUsePistol = GetConVarBool(convar);
}

public ConVarLouisT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LouisCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarLouisT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LouisCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarLouisSMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LouisCanUseSMG = GetConVarBool(convar);
}

public ConVarLouisAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LouisCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarLouisSnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LouisCanUseSniper = GetConVarBool(convar);
}

// Francis

public ConVarFrancisMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrancisCanUseMagnum = GetConVarBool(convar);
}

public ConVarFrancisPistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrancisCanUsePistol = GetConVarBool(convar);
}

public ConVarFrancisT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrancisCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarFrancisT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrancisCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarFrancisSMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrancisCanUseSMG = GetConVarBool(convar);
}

public ConVarFrancisAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrancisCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarFrancisSnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrancisCanUseSniper = GetConVarBool(convar);
}

// Zoey

public ConVarZoeyMagnums(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ZoeyCanUseMagnum = GetConVarBool(convar);
}

public ConVarZoeyPistols(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ZoeyCanUsePistol = GetConVarBool(convar);
}

public ConVarZoeyT1Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ZoeyCanUseT1Shotgun = GetConVarBool(convar);
}

public ConVarZoeyT2Shotguns(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ZoeyCanUseT2Shotgun = GetConVarBool(convar);
}

public ConVarZoeySMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ZoeyCanUseSMG = GetConVarBool(convar);
}

public ConVarZoeyAssaultRifles(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ZoeyCanUseAssaultRifle = GetConVarBool(convar);
}

public ConVarZoeySnipers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ZoeyCanUseSniper = GetConVarBool(convar);
}

public ConVarRestrictions(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsRestricted = GetConVarBool(convar);
}

// just a test command
/*
public Action:AmmoHere(client, args)
{
	new String:classname[128];
	new Primary = GetPlayerWeaponSlot(client, 0);
	new clip = GetEntProp(Primary, Prop_Send, "m_iClip1");
	new iPrimType = GetEntProp(Primary, Prop_Send, "m_iPrimaryAmmoType");
	new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, iPrimType);
	GetEntityClassname(Primary, classname, 128);
	
	PrintToChatAll("Your current primary is %s \nYour current ammo clip has %i bullets \nAnd you have %i reserve ammo", classname, clip, ammo);
}*/

public SetRestrictions()
{
	// coach
	new Handle:CoachPistols = CreateConVar("coach_enable_pistols", "1", "Can Coach use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachPistols, ConVarCoachPistols);
	CoachCanUsePistol = GetConVarBool(CoachPistols);
	
	new Handle:CoachMagnums = CreateConVar("coach_enable_magnums", "1", "Can Coach use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachMagnums, ConVarCoachMagnums);
	CoachCanUseMagnum = GetConVarBool(CoachMagnums);
	
	new Handle:CoachT1Shotguns = CreateConVar("coach_enable_t1_shotguns", "1", "Can Coach use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachT1Shotguns, ConVarCoachT1Shotguns);
	CoachCanUseT2Shotgun = GetConVarBool(CoachT1Shotguns);
	
	new Handle:CoachT2Shotguns = CreateConVar("coach_enable_t2_shotguns", "1", "Can Coach use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachT2Shotguns, ConVarCoachT2Shotguns);
	CoachCanUseT2Shotgun = GetConVarBool(CoachT2Shotguns);
	
	new Handle:CoachSMG = CreateConVar("coach_enable_smgs", "1", "Can Coach use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachSMG, ConVarCoachSMG);
	CoachCanUseSMG = GetConVarBool(CoachSMG);
	
	new Handle:CoachSnipers = CreateConVar("coach_enable_snipers", "1", "Can Coach use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachSnipers, ConVarCoachSnipers);
	CoachCanUseSniper = GetConVarBool(CoachSnipers);
	
	new Handle:CoachAssaultRifles = CreateConVar("coach_enable_assault_rifles", "1", "Can Coach use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachAssaultRifles, ConVarCoachAssaultRifles);
	CoachCanUseAssaultRifle = GetConVarBool(CoachAssaultRifles);
	
	
	// ellis
	new Handle:EllisPistols = CreateConVar("ellis_enable_pistols", "1", "Can Ellis use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(EllisPistols, ConVarEllisPistols);
	EllisCanUsePistol = GetConVarBool(EllisPistols);
	
	new Handle:EllisMagnums = CreateConVar("ellis_enable_magnums", "1", "Can Ellis use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(EllisMagnums, ConVarEllisMagnums);
	EllisCanUseMagnum = GetConVarBool(EllisMagnums);
	
	new Handle:EllisT1Shotguns = CreateConVar("ellis_enable_t1_shotguns", "1", "Can Ellis use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(EllisT1Shotguns, ConVarEllisT1Shotguns);
	EllisCanUseT2Shotgun = GetConVarBool(EllisT1Shotguns);
	
	new Handle:EllisT2Shotguns = CreateConVar("ellis_enable_t2_shotguns", "1", "Can Ellis use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(EllisT2Shotguns, ConVarEllisT2Shotguns);
	EllisCanUseT2Shotgun = GetConVarBool(EllisT2Shotguns);
	
	new Handle:EllisSMG = CreateConVar("ellis_enable_smgs", "1", "Can Ellis use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(EllisSMG, ConVarEllisSMG);
	EllisCanUseSMG = GetConVarBool(EllisSMG);
	
	new Handle:EllisSnipers = CreateConVar("ellis_enable_snipers", "1", "Can Ellis use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(EllisSnipers, ConVarEllisSnipers);
	EllisCanUseSniper = GetConVarBool(EllisSnipers);
	
	new Handle:EllisAssaultRifles = CreateConVar("ellis_enable_assault_rifles", "1", "Can Ellis use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(EllisAssaultRifles, ConVarEllisAssaultRifles);
	EllisCanUseAssaultRifle = GetConVarBool(EllisAssaultRifles);
	
	
	// Rochelle
	new Handle:RochellePistols = CreateConVar("rochelle_enable_pistols", "1", "Can Rochelle use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(RochellePistols, ConVarRochellePistols);
	RochelleCanUsePistol = GetConVarBool(RochellePistols);
	
	new Handle:RochelleMagnums = CreateConVar("rochelle_enable_magnums", "1", "Can Rochelle use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(RochelleMagnums, ConVarRochelleMagnums);
	RochelleCanUseMagnum = GetConVarBool(RochelleMagnums);
	
	new Handle:RochelleT1Shotguns = CreateConVar("rochelle_enable_t1_shotguns", "1", "Can Rochelle use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(RochelleT1Shotguns, ConVarRochelleT1Shotguns);
	RochelleCanUseT2Shotgun = GetConVarBool(RochelleT1Shotguns);
	
	new Handle:RochelleT2Shotguns = CreateConVar("rochelle_enable_t2_shotguns", "1", "Can Rochelle use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(RochelleT2Shotguns, ConVarRochelleT2Shotguns);
	RochelleCanUseT2Shotgun = GetConVarBool(RochelleT2Shotguns);
	
	new Handle:RochelleSMG = CreateConVar("rochelle_enable_smgs", "1", "Can Rochelle use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(RochelleSMG, ConVarRochelleSMG);
	RochelleCanUseSMG = GetConVarBool(RochelleSMG);
	
	new Handle:RochelleSnipers = CreateConVar("rochelle_enable_snipers", "1", "Can Rochelle use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(RochelleSnipers, ConVarRochelleSnipers);
	RochelleCanUseSniper = GetConVarBool(RochelleSnipers);
	
	new Handle:RochelleAssaultRifles = CreateConVar("rochelle_enable_assault_rifles", "1", "Can Rochelle use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(RochelleAssaultRifles, ConVarRochelleAssaultRifles);
	RochelleCanUseAssaultRifle = GetConVarBool(RochelleAssaultRifles);
	
	
	// Nick
	new Handle:NickPistols = CreateConVar("nick_enable_pistols", "1", "Can Nick use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(NickPistols, ConVarNickPistols);
	NickCanUsePistol = GetConVarBool(NickPistols);
	
	new Handle:NickMagnums = CreateConVar("nick_enable_magnums", "1", "Can Nick use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(NickMagnums, ConVarNickMagnums);
	NickCanUseMagnum = GetConVarBool(NickMagnums);
	
	new Handle:NickT1Shotguns = CreateConVar("nick_enable_t1_shotguns", "1", "Can Nick use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(NickT1Shotguns, ConVarNickT1Shotguns);
	NickCanUseT2Shotgun = GetConVarBool(NickT1Shotguns);
	
	new Handle:NickT2Shotguns = CreateConVar("nick_enable_t2_shotguns", "1", "Can Nick use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(NickT2Shotguns, ConVarNickT2Shotguns);
	NickCanUseT2Shotgun = GetConVarBool(NickT2Shotguns);
	
	new Handle:NickSMG = CreateConVar("nick_enable_smgs", "1", "Can Nick use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(NickSMG, ConVarNickSMG);
	NickCanUseSMG = GetConVarBool(NickSMG);
	
	new Handle:NickSnipers = CreateConVar("nick_enable_snipers", "1", "Can Nick use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(NickSnipers, ConVarNickSnipers);
	NickCanUseSniper = GetConVarBool(NickSnipers);
	
	new Handle:NickAssaultRifles = CreateConVar("nick_enable_assault_rifles", "1", "Can Nick use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(NickAssaultRifles, ConVarNickAssaultRifles);
	NickCanUseAssaultRifle = GetConVarBool(NickAssaultRifles);
	
	// Bill
	new Handle:BillPistols = CreateConVar("bill_enable_pistols", "1", "Can Bill use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(BillPistols, ConVarBillPistols);
	BillCanUsePistol = GetConVarBool(BillPistols);
	
	new Handle:BillMagnums = CreateConVar("bill_enable_magnums", "1", "Can Bill use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(BillMagnums, ConVarBillMagnums);
	BillCanUseMagnum = GetConVarBool(BillMagnums);
	
	new Handle:BillT1Shotguns = CreateConVar("bill_enable_t1_shotguns", "1", "Can Bill use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(BillT1Shotguns, ConVarBillT1Shotguns);
	BillCanUseT2Shotgun = GetConVarBool(BillT1Shotguns);
	
	new Handle:BillT2Shotguns = CreateConVar("bill_enable_t2_shotguns", "1", "Can Bill use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(BillT2Shotguns, ConVarBillT2Shotguns);
	BillCanUseT2Shotgun = GetConVarBool(BillT2Shotguns);
	
	new Handle:BillSMG = CreateConVar("bill_enable_smgs", "1", "Can Bill use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(BillSMG, ConVarBillSMG);
	BillCanUseSMG = GetConVarBool(BillSMG);
	
	new Handle:BillSnipers = CreateConVar("bill_enable_snipers", "1", "Can Bill use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(BillSnipers, ConVarBillSnipers);
	BillCanUseSniper = GetConVarBool(BillSnipers);
	
	new Handle:BillAssaultRifles = CreateConVar("bill_enable_assault_rifles", "1", "Can Bill use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(BillAssaultRifles, ConVarBillAssaultRifles);
	BillCanUseAssaultRifle = GetConVarBool(BillAssaultRifles);
	
	
	// Francis
	new Handle:FrancisPistols = CreateConVar("francis_enable_pistols", "1", "Can Francis use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(FrancisPistols, ConVarFrancisPistols);
	FrancisCanUsePistol = GetConVarBool(FrancisPistols);
	
	new Handle:FrancisMagnums = CreateConVar("francis_enable_magnums", "1", "Can Francis use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(FrancisMagnums, ConVarFrancisMagnums);
	FrancisCanUseMagnum = GetConVarBool(FrancisMagnums);
	
	new Handle:FrancisT1Shotguns = CreateConVar("francis_enable_t1_shotguns", "1", "Can Francis use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(FrancisT1Shotguns, ConVarFrancisT1Shotguns);
	FrancisCanUseT2Shotgun = GetConVarBool(FrancisT1Shotguns);
	
	new Handle:FrancisT2Shotguns = CreateConVar("francis_enable_t2_shotguns", "1", "Can Francis use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(FrancisT2Shotguns, ConVarFrancisT2Shotguns);
	FrancisCanUseT2Shotgun = GetConVarBool(FrancisT2Shotguns);
	
	new Handle:FrancisSMG = CreateConVar("francis_enable_smgs", "1", "Can Francis use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(FrancisSMG, ConVarFrancisSMG);
	FrancisCanUseSMG = GetConVarBool(FrancisSMG);
	
	new Handle:FrancisSnipers = CreateConVar("francis_enable_snipers", "1", "Can Francis use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(FrancisSnipers, ConVarFrancisSnipers);
	FrancisCanUseSniper = GetConVarBool(FrancisSnipers);
	
	new Handle:FrancisAssaultRifles = CreateConVar("francis_enable_assault_rifles", "1", "Can Francis use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(FrancisAssaultRifles, ConVarFrancisAssaultRifles);
	FrancisCanUseAssaultRifle = GetConVarBool(FrancisAssaultRifles);
	
	
	// Louis
	new Handle:LouisPistols = CreateConVar("louis_enable_pistols", "1", "Can Louis use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(LouisPistols, ConVarLouisPistols);
	LouisCanUsePistol = GetConVarBool(LouisPistols);
	
	new Handle:LouisMagnums = CreateConVar("louis_enable_magnums", "1", "Can Louis use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(LouisMagnums, ConVarLouisMagnums);
	LouisCanUseMagnum = GetConVarBool(LouisMagnums);
	
	new Handle:LouisT1Shotguns = CreateConVar("louis_enable_t1_shotguns", "1", "Can Louis use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(LouisT1Shotguns, ConVarLouisT1Shotguns);
	LouisCanUseT2Shotgun = GetConVarBool(LouisT1Shotguns);
	
	new Handle:LouisT2Shotguns = CreateConVar("louis_enable_t2_shotguns", "1", "Can Louis use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(LouisT2Shotguns, ConVarLouisT2Shotguns);
	LouisCanUseT2Shotgun = GetConVarBool(LouisT2Shotguns);
	
	new Handle:LouisSMG = CreateConVar("louis_enable_smgs", "1", "Can Louis use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(LouisSMG, ConVarLouisSMG);
	LouisCanUseSMG = GetConVarBool(LouisSMG);
	
	new Handle:LouisSnipers = CreateConVar("louis_enable_snipers", "1", "Can Louis use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(LouisSnipers, ConVarLouisSnipers);
	LouisCanUseSniper = GetConVarBool(LouisSnipers);
	
	new Handle:LouisAssaultRifles = CreateConVar("louis_enable_assault_rifles", "1", "Can Louis use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(LouisAssaultRifles, ConVarLouisAssaultRifles);
	LouisCanUseAssaultRifle = GetConVarBool(LouisAssaultRifles);
	
	
	// Zoey
	new Handle:ZoeyPistols = CreateConVar("zoey_enable_pistols", "1", "Can Zoey use pistols? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(ZoeyPistols, ConVarZoeyPistols);
	ZoeyCanUsePistol = GetConVarBool(ZoeyPistols);
	
	new Handle:ZoeyMagnums = CreateConVar("zoey_enable_magnums", "1", "Can Zoey use magnums? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(ZoeyMagnums, ConVarZoeyMagnums);
	ZoeyCanUseMagnum = GetConVarBool(ZoeyMagnums);
	
	new Handle:ZoeyT1Shotguns = CreateConVar("zoey_enable_t1_shotguns", "1", "Can Zoey use t1 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(ZoeyT1Shotguns, ConVarZoeyT1Shotguns);
	ZoeyCanUseT2Shotgun = GetConVarBool(ZoeyT1Shotguns);
	
	new Handle:ZoeyT2Shotguns = CreateConVar("zoey_enable_t2_shotguns", "1", "Can Zoey use t2 shotguns? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(ZoeyT2Shotguns, ConVarZoeyT2Shotguns);
	ZoeyCanUseT2Shotgun = GetConVarBool(ZoeyT2Shotguns);
	
	new Handle:ZoeySMG = CreateConVar("zoey_enable_smgs", "1", "Can Zoey use smgs? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(ZoeySMG, ConVarZoeySMG);
	ZoeyCanUseSMG = GetConVarBool(ZoeySMG);
	
	new Handle:ZoeySnipers = CreateConVar("zoey_enable_snipers", "1", "Can Zoey use snipers? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(ZoeySnipers, ConVarZoeySnipers);
	ZoeyCanUseSniper = GetConVarBool(ZoeySnipers);
	
	new Handle:ZoeyAssaultRifles = CreateConVar("zoey_enable_assault_rifles", "1", "Can Zoey use assault rifles? (0 = No, 1 = Yes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(ZoeyAssaultRifles, ConVarZoeyAssaultRifles);
	ZoeyCanUseAssaultRifle = GetConVarBool(ZoeyAssaultRifles);
	
	// Restriction Type
	new Handle:Restrictions = CreateConVar("restriction_type", "0", "What kind of restrictions will be applied to disabled weapons? (0 = Bots may pick up disabled weapons when it is their only choice, 1 = Bots will NEVER pick up restricted weapons)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(Restrictions, ConVarRestrictions);
	IsRestricted = GetConVarBool(Restrictions);
} 

PlaySound(client, const String:s_Sound[32])
EmitSoundToClient(client, s_Sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);