#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <left4downtown>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.2"

ConVar apdMinAmmoSMGs, apdMinAmmoT1Shotguns, apdMinAmmoRifles, apdMinAmmoT2Shotguns,
	apdMinAmmoSnipers, apdMinAmmoM60s, apdMinAmmoLaunchers;

int iMinAmmoSMGs, iMinAmmoT1Shotguns, iMinAmmoRifles, iMinAmmoT2Shotguns, iMinAmmoSnipers,
	iMinAmmoM60s, iMinAmmoLaunchers, iDeploy[MAXPLAYERS+1];

bool bUsingL4DT, bTongued[MAXPLAYERS+1];
ArrayList alAmmoPacks;

public Plugin myinfo =
{
	name = "[L4D2] Ammo Pack Deployers", 
	author = "cravenge", 
	description = "Manipulates Bots To Grab And Deploy Ammo Packs.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=261566"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (!StrEqual(sGameName, "left4dead2", false))
	{
		strcopy(error, err_max, "[APD] Plugin Supports L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("ammo_pack_deployers-l4d2_version", PLUGIN_VERSION, "Ammo Pack Deployers Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	apdMinAmmoSMGs = CreateConVar("apd-l4d2_min_ammo_smgs", "15", "Minimum Ammo Left On SMGs To Alert Bots", FCVAR_SPONLY|FCVAR_NOTIFY);
	apdMinAmmoT1Shotguns = CreateConVar("apd-l4d2_min_ammo_t1shotguns", "10", "Minimum Ammo Left On T1 Shotguns To Alert Bots", FCVAR_SPONLY|FCVAR_NOTIFY);
	apdMinAmmoRifles = CreateConVar("apd-l4d2_min_ammo_rifles", "25", "Minimum Ammo Left On Rifles To Alert Bots", FCVAR_SPONLY|FCVAR_NOTIFY);
	apdMinAmmoT2Shotguns = CreateConVar("apd-l4d2_min_ammo_t2shotguns", "10", "Minimum Ammo Left On T2 Shotguns To Alert Bots", FCVAR_SPONLY|FCVAR_NOTIFY);
	apdMinAmmoSnipers = CreateConVar("apd-l4d2_min_ammo_snipers", "20", "Minimum Ammo Left On Snipers To Alert Bots", FCVAR_SPONLY|FCVAR_NOTIFY);
	apdMinAmmoM60s = CreateConVar("apd-l4d2_min_ammo_m60s", "30", "Minimum Ammo Left On M60s To Alert Bots", FCVAR_SPONLY|FCVAR_NOTIFY);
	apdMinAmmoLaunchers = CreateConVar("apd-l4d2_min_ammo_launchers", "5", "Minimum Ammo Left On Grenade Launchers To Alert Bots", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	iMinAmmoSMGs = apdMinAmmoSMGs.IntValue;
	iMinAmmoT1Shotguns = apdMinAmmoT1Shotguns.IntValue;
	iMinAmmoRifles = apdMinAmmoRifles.IntValue;
	iMinAmmoT2Shotguns = apdMinAmmoT2Shotguns.IntValue;
	iMinAmmoSnipers = apdMinAmmoSnipers.IntValue;
	iMinAmmoM60s = apdMinAmmoM60s.IntValue;
	iMinAmmoLaunchers = apdMinAmmoLaunchers.IntValue;
	
	apdMinAmmoSMGs.AddChangeHook(OnAPDCVarsChanged);
	apdMinAmmoT1Shotguns.AddChangeHook(OnAPDCVarsChanged);
	apdMinAmmoRifles.AddChangeHook(OnAPDCVarsChanged);
	apdMinAmmoT2Shotguns.AddChangeHook(OnAPDCVarsChanged);
	apdMinAmmoSnipers.AddChangeHook(OnAPDCVarsChanged);
	apdMinAmmoM60s.AddChangeHook(OnAPDCVarsChanged);
	apdMinAmmoLaunchers.AddChangeHook(OnAPDCVarsChanged);
	
	AutoExecConfig(true, "ammo_pack_deployers-l4d2");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("tongue_grab", OnTongueGrab);
	HookEvent("tongue_release", OnTongueRelease);
	HookEvent("upgrade_pack_used", OnUpgradePackUsed);
	
	HookEvent("tank_spawn", OnTankSpawn);
	HookEvent("witch_spawn", OnWitchSpawn);
	HookEvent("create_panic_event", OnCreatePanicEvent);
	
	CreateTimer(1.0, CheckBotsAmmo, _, TIMER_REPEAT);
}

public void OnAPDCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	iMinAmmoSMGs = apdMinAmmoSMGs.IntValue;
	iMinAmmoT1Shotguns = apdMinAmmoT1Shotguns.IntValue;
	iMinAmmoRifles = apdMinAmmoRifles.IntValue;
	iMinAmmoT2Shotguns = apdMinAmmoT2Shotguns.IntValue;
	iMinAmmoSnipers = apdMinAmmoSnipers.IntValue;
	iMinAmmoM60s = apdMinAmmoM60s.IntValue;
	iMinAmmoLaunchers = apdMinAmmoLaunchers.IntValue;
}

public Action CheckBotsAmmo(Handle timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iPrimaryWeapon = GetPlayerWeaponSlot(i, 0);
			if (!IsValidEnt(iPrimaryWeapon) || HasEnoughAmmo(i, iPrimaryWeapon))
			{
				continue;
			}
			
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (IsValidEnt(iAmmoPack))
			{
				char sPackClass[64];
				GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
				FakeClientCommand(i, "use %s", sPackClass);
				
				iDeploy[i] = 1;
				break;
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	apdMinAmmoSMGs.RemoveChangeHook(OnAPDCVarsChanged);
	apdMinAmmoT1Shotguns.RemoveChangeHook(OnAPDCVarsChanged);
	apdMinAmmoRifles.RemoveChangeHook(OnAPDCVarsChanged);
	apdMinAmmoT2Shotguns.RemoveChangeHook(OnAPDCVarsChanged);
	apdMinAmmoSnipers.RemoveChangeHook(OnAPDCVarsChanged);
	apdMinAmmoM60s.RemoveChangeHook(OnAPDCVarsChanged);
	apdMinAmmoLaunchers.RemoveChangeHook(OnAPDCVarsChanged);
	
	delete apdMinAmmoSMGs;
	delete apdMinAmmoT1Shotguns;
	delete apdMinAmmoRifles;
	delete apdMinAmmoT2Shotguns;
	delete apdMinAmmoSnipers;
	delete apdMinAmmoM60s;
	delete apdMinAmmoLaunchers;
	
	UnhookEvent("round_start", OnRoundStart);
	UnhookEvent("tongue_grab", OnTongueGrab);
	UnhookEvent("tongue_release", OnTongueRelease);
	UnhookEvent("upgrade_pack_used", OnUpgradePackUsed);
	
	UnhookEvent("tank_spawn", OnTankSpawn);
	UnhookEvent("witch_spawn", OnWitchSpawn);
	UnhookEvent("create_panic_event", OnCreatePanicEvent);
}

public void OnAllPluginsLoaded()
{
	if (!FileExists("../addons/sourcemod/extensions/left4downtown.ext.2.l4d2.dll"))
	{
		bUsingL4DT = false;
	}
	else
	{
		bUsingL4DT = true;
	}
}

public void OnMapStart()
{
	alAmmoPacks = new ArrayList();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= 0 || entity > 2048)
	{
		return;
	}
	
	if (StrContains(classname, "weapon_", false) != -1)
	{
		CreateTimer(2.0, CheckEntityForGrab, entity);
	}
}

public Action CheckEntityForGrab(Handle timer, any entity)
{
	if (!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}
	
	char sEntityClass[64];
	GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
	if (StrContains(sEntityClass, "weapon_", false) != -1)
	{
		if (IsAmmoPack(entity) && !IsAmmoPackOwned(entity))
		{
			for (int i = 0; i < alAmmoPacks.Length; i++)
			{
				if (entity == alAmmoPacks.Get(i))
				{
					return Plugin_Stop;
				}
				else if (!IsValidEntity(alAmmoPacks.Get(i)))
				{
					alAmmoPacks.Erase(i);
				}
			}
			alAmmoPacks.Push(entity);
		}
	}
	
	return Plugin_Stop;
}

public void OnEntityDestroyed(int entity)
{
	if (IsAmmoPack(entity) && !IsAmmoPackOwned(entity))
	{
		for (int i = 0; i < alAmmoPacks.Length; i++)
		{
			if (entity == alAmmoPacks.Get(i))
			{
				alAmmoPacks.Erase(i);
			}
		}
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iDeploy[i] = 0;
			bTongued[i] = false;
		}
	}
	
	return Plugin_Continue;
}

public Action OnTongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int grabbed = GetClientOfUserId(event.GetInt("victim"));
	if (!IsSurvivor(grabbed) || !IsPlayerAlive(grabbed) || bTongued[grabbed])
	{
		return Plugin_Continue;
	}
	
	bTongued[grabbed] = true;
	return Plugin_Continue;
}

public Action OnTongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	int released = GetClientOfUserId(event.GetInt("victim"));
	if (!IsSurvivor(released) || !IsPlayerAlive(released) || !bTongued[released])
	{
		return Plugin_Continue;
	}
	
	bTongued[released] = false;
	return Plugin_Continue;
}

public Action OnUpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
	int upgrader = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(upgrader) || !IsPlayerAlive(upgrader) || iDeploy[upgrader] == 0)
	{
		return Plugin_Continue;
	}
	
	int upgrade = event.GetInt("upgradeid");
	if (!IsValidEnt(upgrade))
	{
		return Plugin_Continue;
	}
	
	char sUpgradeClass[64];
	GetEdictClassname(upgrade, sUpgradeClass, sizeof(sUpgradeClass));
	if (StrEqual(sUpgradeClass, "upgrade_laser_sight"))
	{
		return Plugin_Continue;
	}
	
	iDeploy[upgrader] = 0;
	return Plugin_Continue;
}

public Action OnTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (bUsingL4DT)
	{
		return Plugin_Continue;
	}
	
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (tank <= 0 || tank > MaxClients || !IsClientInGame(tank))
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (!IsValidEnt(iAmmoPack))
			{
				continue;
			}
			
			char sPackClass[64];
			GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
			FakeClientCommand(i, "use %s", sPackClass);
			
			iDeploy[i] = 1;
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action OnWitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (bUsingL4DT)
	{
		return Plugin_Continue;
	}
	
	int witch = event.GetInt("witchid");
	if (!IsValidEnt(witch))
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (!IsValidEnt(iAmmoPack))
			{
				continue;
			}
			
			char sPackClass[64];
			GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
			FakeClientCommand(i, "use %s", sPackClass);
			
			iDeploy[i] = 1;
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action OnCreatePanicEvent(Event event, const char[] name, bool dontBroadcast)
{
	if (bUsingL4DT)
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (!IsValidEnt(iAmmoPack))
			{
				continue;
			}
			
			char sPackClass[64];
			GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
			if (!StrEqual(sPackClass, "weapon_upgradepack_explosive", false))
			{
				continue;
			}
			
			FakeClientCommand(i, "use weapon_upgradepack_explosive");
			iDeploy[i] = 1;
			
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action L4D_OnSpawnTank(float vector[3], float qangle[3])
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (!IsValidEnt(iAmmoPack))
			{
				continue;
			}
			
			char sPackClass[64];
			GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
			FakeClientCommand(i, "use %s", sPackClass);
			
			iDeploy[i] = 1;
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action L4D_OnSpawnWitch(float vector[3], float qangle[3])
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (!IsValidEnt(iAmmoPack))
			{
				continue;
			}
			
			char sPackClass[64];
			GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
			FakeClientCommand(i, "use %s", sPackClass);
			
			iDeploy[i] = 1;
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action L4D_OnWitchBride(float vector[3], float qangle[3])
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (!IsValidEnt(iAmmoPack))
			{
				continue;
			}
			
			char sPackClass[64];
			GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
			FakeClientCommand(i, "use %s", sPackClass);
			
			iDeploy[i] = 1;
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action L4D_OnSpawnMob(int &amount)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && IsFine(i) && iDeploy[i] == 0)
		{
			int iAmmoPack = GetPlayerWeaponSlot(i, 3);
			if (!IsValidEnt(iAmmoPack))
			{
				continue;
			}
			
			char sPackClass[64];
			GetEdictClassname(iAmmoPack, sPackClass, sizeof(sPackClass));
			if (!StrEqual(sPackClass, "weapon_upgradepack_explosive", false))
			{
				continue;
			}
			
			FakeClientCommand(i, "use weapon_upgradepack_explosive");
			iDeploy[i] = 1;
			
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action L4D2_OnFindScavengeItem(int client, int &item)
{
	if (!item)
	{
		float fItemPos[3], fScavengerPos[3];
		
		int iAmmoPack = GetPlayerWeaponSlot(client, 3);
		if (!IsValidEdict(iAmmoPack))
		{
			for (int i = 0; i < alAmmoPacks.Length; i++)
			{
				if (!IsValidEntity(alAmmoPacks.Get(i)))
				{
					return Plugin_Continue;
				}
				
				GetEntPropVector(alAmmoPacks.Get(i), Prop_Send, "m_vecOrigin", fItemPos);
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", fScavengerPos);
				
				float distance = GetVectorDistance(fScavengerPos, fItemPos);
				if (distance < 250.0)
				{
					item = alAmmoPacks.Get(i);
					return Plugin_Changed;
				}
			}
		}
	}
	else if (IsAmmoPack(item))
	{
		int iAmmoPack = GetPlayerWeaponSlot(client, 3);
		if (IsValidEnt(iAmmoPack))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsSurvivor(client) && IsPlayerAlive(client) && IsFakeClient(client) && IsFine(client))
	{
		int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (iActiveWeapon != -1 && IsValidEntity(iActiveWeapon))
		{
			char sWeaponClass[64];
			GetEntityClassname(iActiveWeapon, sWeaponClass, sizeof(sWeaponClass));
			if (iActiveWeapon == GetPlayerWeaponSlot(client, 3) && (StrEqual(sWeaponClass, "weapon_upgradepack_incendiary") || StrEqual(sWeaponClass, "weapon_upgradepack_explosive")))
			{
				if (iDeploy[client] == 1)
				{
					buttons |= IN_ATTACK;
				}
				else
				{
					buttons &= ~IN_ATTACK;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnMapEnd()
{
	alAmmoPacks.Clear();
}

bool IsAmmoPack(int entity)
{
	if (entity > 0 && entity < 2048 && IsValidEntity(entity))
	{
		char sEntityClass[64], sEntityModel[128];
		
		GetEntityClassname(entity, sEntityClass, sizeof(sEntityClass));
		GetEntPropString(entity, Prop_Data, "m_ModelName", sEntityModel, sizeof(sEntityModel));
		
		if (StrEqual(sEntityClass, "weapon_upgradepack_incendiary") || StrEqual(sEntityClass, "weapon_upgradepack_incendiary_spawn") || StrEqual(sEntityModel, "models/w_models/weapons/w_eq_incendiary_ammopack.mdl") || 
			StrEqual(sEntityClass, "weapon_upgradepack_explosive") || StrEqual(sEntityClass, "weapon_upgradepack_explosive_spawn") || StrEqual(sEntityModel, "models/w_models/weapons/w_eq_explosive_ammopack.mdl"))
		{
			return true;
		}
	}
	
	return false;
}

bool IsAmmoPackOwned(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (GetPlayerWeaponSlot(i, 3) == entity)
			{
				return true;
			}
		}
	}
	
	return false;
}

bool HasEnoughAmmo(int client, int weapon)
{
	if (!IsValidEnt(weapon))
	{
		return false;
	}
	
	int iAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"),
		iAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, iAmmoType);
	
	char sWeaponClass[64];
	GetEdictClassname(weapon, sWeaponClass, sizeof(sWeaponClass));
	if ((StrEqual(sWeaponClass, "weapon_smg") || StrEqual(sWeaponClass, "weapon_smg_silenced") || StrEqual(sWeaponClass, "weapon_smg_mp5")) && iAmmo <= iMinAmmoSMGs)
	{
		return true;
	}
	else if ((StrEqual(sWeaponClass, "weapon_pumpshotgun") || StrEqual(sWeaponClass, "weapon_shotgun_chrome")) && iAmmo <= iMinAmmoT1Shotguns)
	{
		return true;
	}
	else if ((StrEqual(sWeaponClass, "weapon_rifle") || StrEqual(sWeaponClass, "weapon_rifle_ak47") || StrEqual(sWeaponClass, "weapon_rifle_desert") || StrEqual(sWeaponClass, "weapon_rifle_sg552")) && iAmmo <= iMinAmmoRifles)
	{
		return true;
	}
	else if ((StrEqual(sWeaponClass, "weapon_autoshotgun") || StrEqual(sWeaponClass, "weapon_shotgun_spas")) && iAmmo <= iMinAmmoT2Shotguns)
	{
		return true;
	}
	else if ((StrEqual(sWeaponClass, "weapon_hunting_rifle") || StrEqual(sWeaponClass, "weapon_sniper_military") || StrEqual(sWeaponClass, "weapon_sniper_scout") || StrEqual(sWeaponClass, "weapon_sniper_awp")) && iAmmo <= iMinAmmoSnipers)
	{
		return true;
	}
	else if (StrEqual(sWeaponClass, "weapon_rifle_m60") && iAmmo <= iMinAmmoM60s)
	{
		return true;
	}
	else if (StrEqual(sWeaponClass, "weapon_grenade_launcher") && GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") + (68)) <= iMinAmmoLaunchers)
	{
		return true;
	}
	
	return false;
}

bool IsFine(int client)
{
	return (!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) && bTongued[client] && GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") <= 0 && 
		GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") <= 0 && GetEntPropEnt(client, Prop_Send, "m_carryAttacker") <= 0 && GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") <= 0);
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

