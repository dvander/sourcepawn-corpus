#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
	name = "[L4D] & [L4D2] Special Spawn Regulator",
	author = "chinagreenelvis",
	description = "Regulates and randomizes special spawn intervals.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=142376"
}

new Handle:specialregulator_delay = INVALID_HANDLE;
new Handle:specialregulator_duration_min = INVALID_HANDLE;
new Handle:specialregulator_duration_max = INVALID_HANDLE;
new Handle:specialregulator_interval_min = INVALID_HANDLE;
new Handle:specialregulator_interval_max = INVALID_HANDLE;

new Handle:TimerSpecialDelay = INVALID_HANDLE;

new bool:EnableTimers = false;

public OnPluginStart()
{	
	specialregulator_delay = CreateConVar("specialregulator_delay", "120", "Time until the first specials are allowed to spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_duration_min = CreateConVar("specialregulator_duration_min", "15", "Minimum time during which specials are allowed to spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_duration_max = CreateConVar("specialregulator_duration_max", "30", "Maximum time during which specials are allowed to spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_interval_min = CreateConVar("specialregulator_interval_min", "30", "Minimum time between special spawns", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_interval_max = CreateConVar("specialregulator_interval_max", "60", "Maximum time between special spawns", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
		
	AutoExecConfig(true, "l4d_2_specialregulator");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("mission_lost", Event_MissionLost);
	HookEvent("round_end", Event_RoundEnd);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDelay);
		TimerSpecialDelay = INVALID_HANDLE;
	}
	EnableTimers = false;
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
	{
		//PrintToChatAll("Starting initial spawn delay.");
		DisableSpecials();
		if (TimerSpecialDelay == INVALID_HANDLE)
		{
			TimerSpecialDelay = CreateTimer(GetConVarFloat(specialregulator_delay), Timer_SpecialDelay);
		}
	}
}

public Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDelay);
		TimerSpecialDelay = INVALID_HANDLE;
	}
	EnableTimers = false;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDelay);
		TimerSpecialDelay = INVALID_HANDLE;
	}
	EnableTimers = false;
}

public Action:Timer_SpecialDelay(Handle:timer)
{	
	EnableTimers = true;
	//PrintToChatAll("Initial spawn delay is finished. Specials are now enabled.");
	AllowRandomSpecial();
	new randomspecialduration = GetRandomInt(GetConVarInt(specialregulator_duration_min), GetConVarInt(specialregulator_duration_max));
	new Float:specialduration = float(randomspecialduration);
	CreateTimer(specialduration, Timer_SpecialDuration);
	//PrintToChatAll("Specials will be allowed to spawn for %f seconds.", specialduration);
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		TimerSpecialDelay = INVALID_HANDLE;
	}
}

public Action:Timer_SpecialDuration(Handle:timer)
{
	if (EnableTimers == true)
	{
		//PrintToChatAll("Specials disabled.")
		DisableSpecials();
		new randomspecialinterval = GetRandomInt(GetConVarInt(specialregulator_interval_min), GetConVarInt(specialregulator_interval_max));
		new Float:specialinterval = float(randomspecialinterval);
		CreateTimer(specialinterval, Timer_SpecialInterval);
		//PrintToChatAll("Specials will be prevented from spawning for %f seconds.", specialinterval);
	}
}

public Action:Timer_SpecialInterval(Handle:timer)
{	
	if (EnableTimers == true)
	{
		//PrintToChatAll("Specials enabled.");
		AllowRandomSpecial();
		new randomspecialduration = GetRandomInt(GetConVarInt(specialregulator_duration_min), GetConVarInt(specialregulator_duration_max));
		new Float:specialduration = float(randomspecialduration);
		CreateTimer(specialduration, Timer_SpecialDuration);
		//PrintToChatAll("Specials will be allowed to spawn for %f seconds.", specialduration);
	}
}

static AllowRandomSpecial()
{
	//SetConVarInt(FindConVar("director_no_specials"), 0);
	new alivesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(i)
		{
			if (IsClientConnected(i) && GetClientTeam(i) == 2) 
			{
				if (IsPlayerAlive(i))
				{
					alivesurvivors++;
				}
			}
		}
	}
	//PrintToChatAll("%i survivors are alive.", alivesurvivors);
	new allowedspecials = GetRandomInt(0, alivesurvivors);
	//PrintToChatAll("%i specials are allowed to spawn.", allowedspecials);
	if (allowedspecials == 0)
	{
		//PrintToChatAll("You got lucky. This time.");
	}
	if (allowedspecials > 0)
	{
		for (new i = 1; i <= allowedspecials; i++)
		{
			new randomspecial = GetRandomInt(1, 6);
			if (randomspecial == 1)
			{
				new boomerlimit = GetConVarInt(FindConVar("z_boomer_limit"));
				SetConVarInt(FindConVar("z_boomer_limit"), boomerlimit+1);
				//PrintToChatAll("A boomer is allowed to spawn.");
			}
			if (randomspecial == 2)
			{
				new chargerlimit = GetConVarInt(FindConVar("z_charger_limit"));
				SetConVarInt(FindConVar("z_charger_limit"), chargerlimit+1);
				//PrintToChatAll("A charger is allowed to spawn.");
			}
			if (randomspecial == 3)
			{
				new hunterlimit = GetConVarInt(FindConVar("z_hunter_limit"));
				SetConVarInt(FindConVar("z_hunter_limit"), hunterlimit+1);
				//PrintToChatAll("A hunter is allowed to spawn.");
			}	
			if (randomspecial == 4)
			{
				new jockeylimit = GetConVarInt(FindConVar("z_jockey_limit"));
				SetConVarInt(FindConVar("z_jockey_limit"), jockeylimit+1);
				//PrintToChatAll("A jockey is allowed to spawn.");
			}	
			if (randomspecial == 5)
			{
				new smokerlimit = GetConVarInt(FindConVar("z_smoker_limit"));
				SetConVarInt(FindConVar("z_smoker_limit"), smokerlimit+1);
				//PrintToChatAll("A smoker is allowed to spawn.");
			}	
			if (randomspecial == 6)
			{
				new spitterlimit = GetConVarInt(FindConVar("z_spitter_limit"));
				SetConVarInt(FindConVar("z_spitter_limit"), spitterlimit+1);
				//PrintToChatAll("A spitter is allowed to spawn.");
			}
		}
	}
}

static DisableSpecials()
{
	//SetConVarInt(FindConVar("director_no_specials"), 1);
	//PrintToChatAll("Disabling specials.");
	SetConVarInt(FindConVar("z_boomer_limit"), 0);
	SetConVarInt(FindConVar("z_charger_limit"), 0);
	SetConVarInt(FindConVar("z_hunter_limit"), 0);
	SetConVarInt(FindConVar("z_jockey_limit"), 0);
	SetConVarInt(FindConVar("z_smoker_limit"), 0);
	SetConVarInt(FindConVar("z_spitter_limit"), 0);
	
}
	