#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar Enable, Chance, RunTimes;
int iMaxRunTimes = 0, iChance = 0;
bool bHooked = false;

public Plugin myinfo = 
{
	name = "[L4D2] Coffee Ammo",
	author = "McFlurry",
	description = "Coffee ammo from L4D.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if(engine != Engine_Left4Dead2)
	{
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_coffee_version", PLUGIN_VERSION, "Version of Coffee ammo", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	Enable = CreateConVar("l4d2_coffee_enable", "1", "Coffee ammo enable", CVAR_FLAGS);
	Chance = CreateConVar("l4d2_coffee_chance", "2", "Coffee ammo chance", CVAR_FLAGS);
	RunTimes = CreateConVar("l4d2_coffee_runtimes", "2", "How many ammo spawns to check for replacement?", CVAR_FLAGS);

	AutoExecConfig(true, "l4d2_coffee");
	
	Enable.AddChangeHook(OnConVarEnableChanged);
	Chance.AddChangeHook(OnConVarsChanged);
	RunTimes.AddChangeHook(OnConVarsChanged);
}

public void OnMapStart()
{
	PrecacheModel("models/props_unique/spawn_apartment/coffeeammo.mdl", true);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar convar, const char[] OldValue, const char[] NewValue)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar convar, const char[] OldValue, const char[] NewValue)
{
	iMaxRunTimes = RunTimes.IntValue;
	iChance = Chance.IntValue;
}

void IsAllowed()
{
	bool bEnable = Enable.BoolValue;
	if(!bHooked && bEnable)
	{
		bHooked = true;
		OnConVarsChanged(null, "", "");
		HookEvent("round_start", Event_RoundStart);
	}
	else if(bHooked && !Enable)
	{
		bHooked = false;
		UnhookEvent("round_start", Event_RoundStart);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(8.0, CoffeeTime, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action CoffeeTime(Handle Timer)
{
	int runtimes = 0, ent = -1, prev = 0;
	while((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1 && runtimes < iMaxRunTimes)
	{
		runtimes++;
		if(prev && GetRandomInt(1, iChance) == 1)
		{
			SetEntityModel(prev, "models/props_unique/spawn_apartment/coffeeammo.mdl");
		}
		prev = ent;
	}

	if(prev && GetRandomInt(1, iChance) == 1 && IsValidEdict(prev))
	{
		SetEntityModel(prev, "models/props_unique/spawn_apartment/coffeeammo.mdl");
	}
	return Plugin_Stop;
}
