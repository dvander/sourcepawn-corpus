#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bool:bIsBridge;
new bool:bIgnoreOverkill[MAXPLAYERS+1];

new Handle:hBridgeCarDamage = INVALID_HANDLE;
new Handle:hLogStandingDamage = INVALID_HANDLE;
new Handle:hCarStandingDamage = INVALID_HANDLE;
new Handle:hBumperCarStandingDamage	= INVALID_HANDLE;
new Handle:hHandtruckStandingDamage	= INVALID_HANDLE;
new Handle:hForkliftStandingDamage = INVALID_HANDLE;
new Handle:hBHLogStandingDamage = INVALID_HANDLE;
new Handle:hDumpsterStandingDamage = INVALID_HANDLE;
new Handle:hHaybaleStandingDamage = INVALID_HANDLE;
new Handle:hBaggageStandingDamage = INVALID_HANDLE;
new Handle:hStandardIncapDamage = INVALID_HANDLE;
new Handle:hOverHitInterval = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "[L4D2] Hittable Props Damage",
    author = "Stabby, Visor",
    version = "0.4",
    description = "Customizes Damage Taken From Hittable Props.",
	url = ""
};

public OnPluginStart()
{
	hBridgeCarDamage = CreateConVar("hpd-l4d2_tpcar_damage", "25.0", "Damage Inflicted By Cars In The Parish", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hLogStandingDamage = CreateConVar("hpd-l4d2_sflog_damage", "48.0", "Damage Inflicted By Logs In Swamp Fever", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hBHLogStandingDamage = CreateConVar("hpd-l4d2_bhlog_damage", "100.0", "Damage Inflicted By Logs In Blood Harvest", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hCarStandingDamage = CreateConVar("hpd-l4d2_car_damage", "100.0", "Damage Inflicted By Cars In Other Maps", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hBumperCarStandingDamage = CreateConVar("hpd-l4d2_bumpercar_damage", "100.0", "Damage Inflicted By Bumper Cars", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hHandtruckStandingDamage = CreateConVar("hpd-l4d2_handtruck_damage", "8.0", "Damage Inflicted By Hand Trucks", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hForkliftStandingDamage = CreateConVar("hpd-l4d2_forklift_damage", "100.0", "Damage Inflicted By Forklifts", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hDumpsterStandingDamage = CreateConVar("hpd-l4d2_dumpster_damage", "100.0", "Damage Inflicted By Dumpsters", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hHaybaleStandingDamage = CreateConVar("hpd-l4d2_haybale_damage", "48.0", "Damage Inflicred By Haybales", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hBaggageStandingDamage = CreateConVar("hpd-l4d2_baggage_damage", "48.0", "Damage Inflicted By Baggages", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	hStandardIncapDamage = CreateConVar("hpd-l4d2_incap_damage", "100", "Damage Inflicted By Hittable Props To Incapacitated Survivors", FCVAR_NOTIFY, true, -2.0, true, 300.0);
	hOverHitInterval = CreateConVar("hpd-l4d2_overhit_time", "1.2", "Delay Between Each Overhits", FCVAR_NOTIFY, true, 0.0, false);
	
	HookEvent("player_hurt", OnFrustrationRefill);
	HookEvent("player_incapacitated", OnFrustrationRefill);
}

public OnMapStart()
{
	decl String:buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	if (StrContains(buffer, "c5m5") != -1)
	{
		bIsBridge = true;
	}
	else
	{
		bIsBridge = false;
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType)
{
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim))
	{
		return Plugin_Continue;
	}
	
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || GetClientTeam(attacker) != 3 || GetEntProp(attacker, Prop_Send, "m_zombieClass") != 8)
	{
		return Plugin_Continue;
	}
	
	if (inflictor <= 0 || !IsValidEntity(inflictor) || !IsValidEdict(inflictor))
	{
		return Plugin_Continue;
	}
	
	decl String:sClass[64];
	GetEdictClassname(inflictor, sClass, sizeof(sClass));
	if (StrEqual(sClass, "prop_physics") || StrEqual(sClass, "prop_car_alarm"))
	{
		if (bIgnoreOverkill[victim])
		{
			return Plugin_Handled;
		}
		
		decl String:sModelName[128];
		GetEntPropString(inflictor, Prop_Data, "m_ModelName", sModelName, 128);
		
		new Float:val = GetConVarFloat(hStandardIncapDamage);
		if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") && val != -2)
		{
			if (val >= 0.0)
			{
				damage = val;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		else 
		{
			if (StrContains(sModelName, "cara_") != -1 || StrContains(sModelName, "taxi_") != -1 || StrContains(sModelName, "police_car") != -1)
			{
				if (bIsBridge)
				{
					damage = 4.0 * GetConVarFloat(hBridgeCarDamage);
					inflictor = 0;
				}
				else
				{
					damage = GetConVarFloat(hCarStandingDamage);
				}
			}
			else if (StrContains(sModelName, "dumpster") != -1)
			{
				damage = GetConVarFloat(hDumpsterStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props/cs_assault/forklift.mdl"))
			{
				damage = GetConVarFloat(hForkliftStandingDamage);
			}			
			else if (StrEqual(sModelName, "models/props_vehicles/airport_baggage_cart2.mdl"))
			{
				damage = GetConVarFloat(hBaggageStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_unique/haybails_single.mdl"))
			{
				damage = GetConVarFloat(hHaybaleStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_foliage/Swamp_FallenTree01_bare.mdl"))
			{
				damage = GetConVarFloat(hLogStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_foliage/tree_trunk_fallen.mdl"))
			{
				damage = GetConVarFloat(hBHLogStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_fairgrounds/bumpercar.mdl"))
			{
				damage = GetConVarFloat(hBumperCarStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props/cs_assault/handtruck.mdl"))
			{
				damage = GetConVarFloat(hHandtruckStandingDamage);
			}
		}
		
		new Float:interval = GetConVarFloat(hOverHitInterval);		
		if (interval >= 0.0)
		{
			bIgnoreOverkill[victim] = true;
			CreateTimer(interval, Timed_ClearInvulnerability, victim);
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:Timed_ClearInvulnerability(Handle:thisTimer, any:victim)
{
	bIgnoreOverkill[victim] = false;
	return Plugin_Stop;
}

public Action:OnFrustrationRefill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (tank <= 0 || tank > MaxClients || !IsClientInGame(tank) || GetClientTeam(tank) != 3 || GetEntProp(tank, Prop_Send, "m_zombieClass") != 8 || IsFakeClient(tank))
	{
		return Plugin_Continue;
	}
	
	new got_hit = GetClientOfUserId(GetEventInt(event, "userid"));
	if (got_hit <= 0 || got_hit > MaxClients || !IsClientInGame(got_hit) || GetClientTeam(got_hit) != 2 || !IsPlayerAlive(got_hit))
	{
		return Plugin_Continue;
	}
	
	SetEntProp(tank, Prop_Send, "m_frustration", 0);
}

