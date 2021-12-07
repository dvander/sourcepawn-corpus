#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>
#include <l4d2d_timers>

#define PLUGIN_VERSION "3.0"

enum InflictedWeapon
{
    CHARGER
};

new Handle:IdentifyInflictor = INVALID_HANDLE;

new tankZClass;

new Handle:hWitchDamageConVar;
new Handle:hAcidSpitArea;

new bool:bChargerPunched[MAXPLAYERS+1];
new bool:bChargerCharging[MAXPLAYERS+1];

new const survivorProps[] = 
{
	13284,
	16008,
	16128,
	15976
};

new Handle:hMWDNotIncapped;
new Handle:hMWDIncapped;
new Handle:hMTDIncapPound;
new Handle:hMTDRockThrow;
new Handle:hMSDAcidSpit;
new Handle:hMCDPunch = INVALID_HANDLE;
new Handle:hMCDFirstPunch = INVALID_HANDLE;
new Handle:hMCDSmash = INVALID_HANDLE;
new Handle:hMCDStumble = INVALID_HANDLE;
new Handle:hMCDPound = INVALID_HANDLE;
new Handle:hMCDCappedVictim = INVALID_HANDLE;
new Handle:hMCDIncappedPound = INVALID_HANDLE;

new Float:sDamageTicks;

new bool:lateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	lateLoad = late;
	return APLRes_Success;    
}

public Plugin:myinfo =
{
	name = "Modified Infected Damage",
	author = "cravenge",
	description = "Allows Modifications Of Damages Taken From Spitters, Chargers, Tanks, and Witches.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	if (lateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i)) 
			{
				OnClientPutInServer(i);
			}
		}
	}
	
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if(StrEqual(GameName, "left4dead2"))
	{
		tankZClass = 8;
	}
	else
	{
		tankZClass = 5;
	}
	
	hWitchDamageConVar = FindConVar("z_witch_damage");
	hAcidSpitArea = CreateTrie();
	
	CreateConVar("mid_version", PLUGIN_VERSION, "Modified Boss Damage Version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hMWDNotIncapped = CreateConVar("mwd_not_incapped", "50", "Witch Damage Inflicted To Survivors", FCVAR_NOTIFY);
	hMWDIncapped = CreateConVar("mwd_incapped", "100", "Witch Damage Inflicted To Incapacitated Survivors", FCVAR_NOTIFY);
	hMTDIncapPound = CreateConVar("mtd_incappound", "100", "Tank Damage Inflicted To Incapped Survivors", FCVAR_NOTIFY);
	hMTDRockThrow = CreateConVar("mtd_rockthrow", "50", "Tank Damage Inflicted From Throwing Rocks", FCVAR_NOTIFY);
	hMSDAcidSpit = CreateConVar("msd_acidspit", "3", "Spitter Damage Inflicted By Acid Spits", FCVAR_NOTIFY);
	hMCDPunch = CreateConVar("mcd_punch", "15", "Charger Damage Inflicted After Punches", FCVAR_NOTIFY, true, 0.0);
	hMCDFirstPunch = CreateConVar("mcd_firstpunch", "12", "Charger Damage Inflicted From First Punch", FCVAR_NOTIFY, true, -1.0);
	hMCDSmash = CreateConVar("mcd_impact", "10", "Charger Damage Inflicted From Impacts", FCVAR_NOTIFY, true, 0.0);
	hMCDStumble = CreateConVar("mcd_stumble", "5", "Charger Damage Inflicted After Stumbling", FCVAR_NOTIFY, true, 0.0);
	hMCDPound = CreateConVar("mcd_pound", "25", "Charger Damage Inflicted From Each Pounding", FCVAR_NOTIFY, true, 0.0);
	hMCDCappedVictim = CreateConVar("mcd_cappedvictim", "7", "Charger Damage Inflicted To Capped Victims", FCVAR_NOTIFY, true, 0.0);
	hMCDIncappedPound = CreateConVar("mcd_incapped", "50", "Charger Damage Inflicted To Incapacitated Victims", FCVAR_NOTIFY, true, 0.0);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("charger_charge_start", OnChargerChargeStart, EventHookMode_Post);
	HookEvent("charger_charge_end", OnChargerChargeEnd, EventHookMode_Post);
	
	IdentifyInflictor = BuildInflictorTrie();
	
	AutoExecConfig(true, "modified_infected_damage");
}

public OnConfigsExecuted()
{
	sDamageTicks = GetConVarFloat(hMSDAcidSpit);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
    RevertStates();
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    RevertStates();
}

RevertStates()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
		{
			bChargerPunched[i] = false;
			bChargerCharging[i] = false;
		}
    }
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsCharger(client))
	{
		return Plugin_Continue;
	}
    
    bChargerPunched[client] = false;
    bChargerCharging[client] = false;
    
    return Plugin_Continue;
}

public Action:OnChargerChargeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new clientId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(clientId);
    if (IsCharger(client))
	{
        bChargerCharging[client] = true;
    }
}

public Action:OnChargerChargeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new clientId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(clientId);
    if (IsCharger(client))
	{
        bChargerCharging[client] = false;
    }
}

public OnEntityCreated(entity, const String:eClassName[])
{
	if (StrEqual(eClassName, "insect_swarm"))
	{
		decl String:sAreaTrie[8];
		IndexToKey(entity, sAreaTrie, sizeof(sAreaTrie));
		
		new sAreaCount[MaxClients];
		SetTrieArray(hAcidSpitArea, sAreaTrie, sAreaCount, MaxClients);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim) || !IsValidEdict(victim))
	{
		return Plugin_Continue;
	}
	
	if(inflictor <= 0 || !IsValidEdict(inflictor))
	{
		return Plugin_Continue;
	}
	
	decl String:iClass[64];
	if(attacker == inflictor)
	{
		GetClientWeapon(inflictor, iClass, sizeof(iClass));
	}
	else
	{
		GetEdictClassname(inflictor, iClass, sizeof(iClass));
	}
	
	if(IsWitch(attacker))
	{
		new Float:nWitchDamage = GetConVarFloat(hWitchDamageConVar);
		if(damage == nWitchDamage)
		{
			damage = PlayerIsIncapped(victim) ? GetConVarFloat(hMWDIncapped) : GetConVarFloat(hMWDNotIncapped);
			return Plugin_Changed;
		}
	}
	else if(IsTank(attacker))
	{
		if (PlayerIsIncapped(victim))
		{
			damage = GetConVarFloat(hMTDIncapPound);
		}
		else if (IsTankRock(inflictor))
		{
			damage = GetConVarFloat(hMTDRockThrow);
		}
		return Plugin_Changed;
	}
	else if(IsCharger(attacker))
	{
		new InflictedWeapon: InflictorIdentity;
		if (!GetTrieValue(IdentifyInflictor, iClass, InflictorIdentity) || InflictorIdentity != CHARGER)
		{
			return Plugin_Continue;
		}
		
		if (damage == 10.0)
		{
			if (damageForce[0] == 0.0 && damageForce[1] == 0.0 && damageForce[2] == 0.0)
			{
				damage = GetConVarFloat(hMCDSmash);
				return Plugin_Changed;
			}
			else
			{
				new Float:dmgFirstPunch = GetConVarFloat(hMCDFirstPunch);
				if (!bChargerPunched[attacker] && dmgFirstPunch > -1.0)
				{
					bChargerPunched[attacker] = true;
					damage = dmgFirstPunch;
					return Plugin_Changed;
				}
				
				damage = AlreadyCapped(victim) ? GetConVarFloat(hMCDCappedVictim) : GetConVarFloat(hMCDPunch);
				return Plugin_Changed;
			}
		}
		else if (damage == 2.0)
		{
			damage = GetConVarFloat(hMCDStumble);
			return Plugin_Changed;
		}
		else if (damage == 15.0 && (damageForce[0] == 0.0 && damageForce[1] == 0.0 && damageForce[2] == 0.0))
		{
			damage = PlayerIsIncapped(victim) ? GetConVarFloat(hMCDIncappedPound) : GetConVarFloat(hMCDPound);
			return Plugin_Changed;
		}
	}
	else if(StrEqual(iClass, "insect_swarm"))
	{
		decl String:sAreaTrie[8];
		IndexToKey(inflictor, sAreaTrie, sizeof(sAreaTrie));
		
		decl sAreaCount[MaxClients];
		if (GetTrieArray(hAcidSpitArea, sAreaTrie, sAreaCount, MaxClients))
		{
			sAreaCount[victim]++;
			
			if (KnowAcidSpitDuration(inflictor) >= 4 * 0.200072 && sAreaCount[victim] < 4)
			{
				sAreaCount[victim] = 4 + 1;
			}
			
			SetTrieArray(hAcidSpitArea, sAreaTrie, sAreaCount, MaxClients);
			
			if (sDamageTicks > -1.0)
			{
				damage = sDamageTicks;
			}
			
			if (4 >= sAreaCount[victim] || sAreaCount[victim] > 28)
			{
				damage = 0.0;
			}
			
			if (sAreaCount[victim] > 28)
			{
				AcceptEntityInput(inflictor, "Kill");
			}
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public OnEntityDestroyed(entity)
{
	decl String:sAreaTrie[8];
	IndexToKey(entity, sAreaTrie, sizeof(sAreaTrie));
	
	decl sAreaCount[MaxClients];
	if (GetTrieArray(hAcidSpitArea, sAreaTrie, sAreaCount, MaxClients))
	{
		RemoveFromTrie(hAcidSpitArea, sAreaTrie);
	}
}

bool:PlayerIsIncapped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsWitch(entity)
{
	if(entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		decl String:eClass[64];
		GetEdictClassname(entity, eClass, sizeof(eClass));
		return StrEqual(eClass, "witch");
	}
	return false;
}

bool:IsTank(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == tankZClass && IsPlayerAlive(client));
}

bool:IsTankRock(entity)
{
    if (entity > 0 && IsValidEntity(entity))
    {
        decl String:classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        return StrEqual(classname, "tank_rock");
    }
    return false;
}

Float:KnowAcidSpitDuration(spit)
{
	return ITimer_GetElapsedTime(IntervalTimer:(GetEntityAddress(spit) + Address:2968));
}

IndexToKey(kIndex, String:kString[], mLength)
{
	Format(kString, mLength, "%x", kIndex);
}

bool:IsCharger(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6 && IsPlayerAlive(client));
}

andle:BuildInflictorTrie()
{
	new Handle:cTrie = CreateTrie();
	SetTrieValue(cTrie, "weapon_charger_claw", CHARGER);
	return cTrie;
}

bool:AlreadyCapped(survivor)
{
	for (new i = 0; i < sizeof(survivorProps); i++)
	{
		if (IsClientInGame(GetEntDataEnt2(survivor, survivorProps[i])))
		{
			return true;
		}
	}
	return false;
}

