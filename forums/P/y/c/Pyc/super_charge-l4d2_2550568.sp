#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

#define PROP_CAR (1<<0)
#define PROP_CAR_ALARM (1<<1)
#define PROP_CONTAINER (1<<2)
#define PROP_LIFT (1<<3)

ConVar g_h_CvarChargerPower, g_h_CvarChargerCarry, g_h_CvarObjects,
	g_h_CvarPushLimit, g_h_CvarRemoveObject, g_h_CvarChargerDamage;

int entOwner[2048+1];
bool incapChecked[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[L4D2] Super Charge",
	author = "DJ_WEST, cravenge",
	description = "Provides Chargers To Move Cars With Ability.",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
};

public void OnPluginStart()
{
	char s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2", false))
	{
		SetFailState("[SC] Plugin Supports L4D2 Only!");
	}
	
	CreateConVar("super_charge-l4d2_version", PLUGIN_VERSION, "Super Charge Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_h_CvarChargerPower = CreateConVar("super_charge-l4d2", "750.0", "Power Applied To Super Charge", FCVAR_NOTIFY, true, 0.0, true, 5000.0);
	g_h_CvarChargerCarry = CreateConVar("super_charge-l4d2_carry", "1", "Enable/Disable Super Charge If Carrying", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_h_CvarObjects = CreateConVar("super_charge-l4d2_objects", "15", "Objects: 1=Cars, 2=Car Alarms, 4=Containers, 8=Fork Lifts", FCVAR_NOTIFY, true, 1.0, true, 15.0);
	g_h_CvarPushLimit = CreateConVar("super_charge-l4d2_push_limit", "10", "Super Charge Push Limit", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	g_h_CvarRemoveObject = CreateConVar("super_charge-l4d2_remove", "30", "Delay Before Charged Objects Disappear", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_h_CvarChargerDamage = CreateConVar("super_charge-l4d2_damage", "10", "Damage Applied To Charger", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("charger_charge_end", OnChargerChargeEnd);
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsSurvivor(victim) || !IsPlayerAlive(victim) || !IsValidEnt(inflictor))
	{
		return Plugin_Continue;
	}
	
	char sClass[64];
	GetEdictClassname(inflictor, sClass, sizeof(sClass));
	if (StrEqual(sClass, "prop_physics") || StrEqual(sClass, "prop_car_alarm"))
    { 
		int charger = CheckForChargers();
		if (entOwner[inflictor] == charger)
		{ 
			int realDmg = RoundFloat(damage);
			
			Event OnPlayerHurt = CreateEvent("player_hurt", true);
			OnPlayerHurt.SetInt("userid", GetClientUserId(victim));
			OnPlayerHurt.SetInt("attacker", GetClientUserId(charger));
			OnPlayerHurt.SetInt("dmg_health", realDmg);
			OnPlayerHurt.SetString("weapon", "charger_claw");
			OnPlayerHurt.Fire(false);
			
			Handle stateFix = CreateDataPack();
			WritePackCell(stateFix, GetClientUserId(victim));
			WritePackCell(stateFix, GetClientUserId(charger));
			WritePackCell(stateFix, realDmg);
			CreateTimer(1.0, CheckForIncaps, stateFix, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
			
			return Plugin_Changed;
		} 
	} 
	
	return Plugin_Continue;
}

public Action CheckForIncaps(Handle timer, Handle stateFix)
{ 
	ResetPack(stateFix);
	
	int victim = GetClientOfUserId(ReadPackCell(stateFix));
	int attacker = GetClientOfUserId(ReadPackCell(stateFix));
	
	int dmgTaken = ReadPackCell(stateFix);
	
	if (!IsSurvivor(victim) || !IsCharger(attacker)) 
	{
		return Plugin_Continue;
	}
	
	if (IsPlayerAlive(victim))
	{
		Event OnPlayerHurt = CreateEvent("player_hurt", true);
		OnPlayerHurt.SetInt("userid", GetClientUserId(victim));
		OnPlayerHurt.SetInt("attacker", GetClientUserId(attacker));
		OnPlayerHurt.SetInt("dmg_health", dmgTaken);
		OnPlayerHurt.SetString("weapon", "charger_claw");
		OnPlayerHurt.Fire(false);
		
		if (GetEntProp(victim, Prop_Send, "m_isIncapacitated", 1) && !incapChecked[victim])
		{
			incapChecked[victim] = true;
			
			Event OnPlayerIncapacitated = CreateEvent("player_incapacitated", true);
			OnPlayerIncapacitated.SetInt("userid", GetClientUserId(victim));
			OnPlayerIncapacitated.SetInt("attacker", GetClientUserId(attacker));
			OnPlayerIncapacitated.Fire(false);
			
			incapChecked[victim] = false;
		}
	}
	else
	{
		Event OnPlayerDeath = CreateEvent("player_death", true);
		OnPlayerDeath.SetInt("userid", GetClientUserId(victim));
		OnPlayerDeath.SetInt("attacker", GetClientUserId(attacker));
		OnPlayerDeath.Fire(false);
	}
	return Plugin_Stop;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			incapChecked[i] = false;
		}
	}
}

public Action OnChargerChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
	int charger = GetClientOfUserId(event.GetInt("userid"));
	if (!IsCharger(charger))
	{
		return Plugin_Continue;
	}
	
	if (g_h_CvarChargerCarry.BoolValue && GetEntProp(charger, Prop_Send, "m_carryVictim") > 0)
	{
		return Plugin_Continue;
	}
	
	float vOrigin[3], vAngles[3], vEndOrigin[3], vVelocity[3];
	
	GetClientAbsOrigin(charger, vOrigin);
	GetClientAbsAngles(charger, vAngles);
	
	vOrigin[2] += 20.0;
	
	Handle trace;
	
	trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_ALL, RayType_Infinite, TraceFilterClients, charger);
	if (TR_DidHit(trace))
	{
		int impacted = TR_GetEntityIndex(trace);
		TR_GetEndPosition(vEndOrigin, trace);
		
		if (IsValidEnt(impacted) && GetVectorDistance(vOrigin, vEndOrigin) <= 100.0)
		{
			if (GetEntityMoveType(impacted) != MOVETYPE_VPHYSICS)
			{
				return Plugin_Continue;
			}
			
			int i_PushCount = GetEntProp(impacted, Prop_Data, "m_iHealth");
			if (i_PushCount >= g_h_CvarPushLimit.IntValue)
			{
				return Plugin_Continue;
			}
			
			int type = g_h_CvarObjects.IntValue;
			
			char iClass[16], iModel[64];
			
			GetEdictClassname(impacted, iClass, sizeof(iClass));
			GetEntPropString(impacted, Prop_Data, "m_ModelName", iModel, sizeof(iModel));
			
			if (StrEqual(iClass, "prop_car_alarm") && !(type & PROP_CAR_ALARM))
			{
				return Plugin_Continue;
			}
			else if (StrEqual(iClass, "prop_physics"))
			{
				if ((StrContains(iModel, "car") != -1 && !(type & PROP_CAR) && !(type & PROP_CAR_ALARM)) || (StrContains(iModel, "dumpster") != -1 && !(type & PROP_CONTAINER)) || (StrContains(iModel, "forklift") != -1 && !(type & PROP_LIFT)))
				{
					return Plugin_Continue;
				}
			}
			
			i_PushCount++;
			SetEntProp(impacted, Prop_Data, "m_iHealth", i_PushCount);
			
			GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
			
			float power = g_h_CvarChargerPower.FloatValue;
			
			vVelocity[0] *= power;
			vVelocity[1] *= power;
			vVelocity[2] *= power;
			
			TeleportEntity(impacted, NULL_VECTOR, NULL_VECTOR, vVelocity);
			
			entOwner[impacted] = charger;
			CreateTimer(3.0, ResetBool, impacted);
			
			Handle pack = CreateDataPack();
			WritePackCell(pack, impacted);
			WritePackFloat(pack, vEndOrigin[0]);
			CreateTimer(0.5, CheckEntity, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
			
			int pushDamage = g_h_CvarChargerDamage.IntValue;
			if (pushDamage > 0)
			{
				int i_Health = GetClientHealth(charger);
				
				i_Health -= pushDamage;
				if (i_Health > 0) 
				{
					SetEntityHealth(charger, i_Health);
				}
				else
				{
					ForcePlayerSuicide(charger);
				}
			}
			
			int objRemove = g_h_CvarRemoveObject.IntValue;
			if (objRemove > 0)
			{
				CreateTimer(float(objRemove), RemoveEntity, impacted, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
//		CloseHandle(trace);
	}
	
	CloseHandle(trace);
	
	return Plugin_Continue;
}

public Action ResetBool(Handle timer, any entity)
{
	if (entOwner[entity] == 0)
	{
		return Plugin_Stop;
	}
	
	entOwner[entity] = 0;
	return Plugin_Stop;
}

public Action RemoveEntity(Handle timer, any objEnt)
{
	if (!IsValidEnt(objEnt))
	{
		return Plugin_Stop;
	}
	
	RemoveEdict(objEnt);
	return Plugin_Stop;
}

public bool TraceFilterClients(int entity, int mask, any data)
{
	if (entity == data)
	{
		return false;
	}
	
	if (0 < entity <= MaxClients)
	{
		return false;
	}
	
	return true;
}

public Action CheckEntity(Handle timer, Handle pack)
{
	ResetPack(pack, false);
	
	int entity = ReadPackCell(pack);
	float vLastOrigin = ReadPackFloat(pack);
	
	if (!IsValidEnt(entity))
	{
		return Plugin_Stop;
	}
	
	float entOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entOrigin);
	if (entOrigin[0] != vLastOrigin)
	{
		Handle newPack = CreateDataPack();
		WritePackCell(newPack, entity);
		WritePackFloat(newPack, entOrigin[0]);
		CreateTimer(0.1, CheckEntity, newPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	}
	else
	{
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	}
	return Plugin_Stop;
}

int CheckForChargers()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{ 
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 6)
		{
			count += 1;
		}
	}
	return count;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsCharger(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6 && IsPlayerAlive(client) && !GetEntProp(client, Prop_Send, "m_isGhost", 1));
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

