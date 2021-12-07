#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.1.1"

public Plugin:myinfo = 
{
	name = "[L4D] & [L4D2] Special Spawn Regulator",
	author = "chinagreenelvis",
	description = "Regulates and randomizes special spawns.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=142376"
}

new Handle:specialregulator_announce = INVALID_HANDLE;
new Handle:specialregulator_delay = INVALID_HANDLE;
new Handle:specialregulator_duration = INVALID_HANDLE;
new Handle:specialregulator_interval_min = INVALID_HANDLE;
new Handle:specialregulator_interval_max = INVALID_HANDLE;
new Handle:specialregulator_lucky = INVALID_HANDLE;
new Handle:specialregulator_l4d_favor = INVALID_HANDLE;

new Handle:TimerSpecialDelay = INVALID_HANDLE;
new Handle:TimerSpecialInterval = INVALID_HANDLE;
new Handle:TimerSpecialDuration = INVALID_HANDLE;

new bool:SpecialsEnabled = false;

new boomerlimit = 0;
new chargerlimit = 0;
new hunterlimit = 0;
new jockeylimit = 0;
new smokerlimit = 0;
new spitterlimit = 0;

public OnPluginStart()
{	
	specialregulator_announce = CreateConVar("specialregulator_announce", "0", "Announce special spawn activity? 0:no, 1:yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_delay = CreateConVar("specialregulator_delay", "60", "Time until the first specials are allowed to spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_duration = CreateConVar("specialregulator_duration", "20", "Time during which specials are allowed to spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_interval_min = CreateConVar("specialregulator_interval_min", "30", "Minimum time between special spawns", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_interval_max = CreateConVar("specialregulator_interval_max", "60", "Maximum time between special spawns", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_lucky = CreateConVar("specialregulator_lucky", "0", "Enable lucky break? Special spawns randomizer will be given a chance for zero. 0: no, 1: yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_l4d_favor = CreateConVar("specialregulator_l4d_favor", "1", "Favor L4D specials? Boomers, smokers, and hunters will spawn more often. 0: no, 1: yes, 2: force only l4d specials", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
		
	AutoExecConfig(true, "l4d_2_specialregulator");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
	{
		//PrintToServer("Starting initial spawn delay.");
		SpecialsEnabled = false;
		DisableSpecials();
		if (TimerSpecialDelay == INVALID_HANDLE)
		{
			TimerSpecialDelay = CreateTimer(GetConVarFloat(specialregulator_delay), Timer_SpecialInterval);
			if (GetConVarInt(specialregulator_announce) == 1)
			{
				PrintToChatAll("The initial special spawn delay will last for %f seconds.", GetConVarFloat(specialregulator_delay));
			}
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDelay);
		TimerSpecialDelay = INVALID_HANDLE;
	}
	if (TimerSpecialInterval != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialInterval);
		TimerSpecialInterval = INVALID_HANDLE;
	}
	if (TimerSpecialDuration != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDuration);
		TimerSpecialDuration = INVALID_HANDLE;
	}
}

public Action:Timer_SpecialDuration(Handle:timer)
{	
	//PrintToServer("Specials disabled.")
	SpecialsEnabled = false;
	DisableSpecials();
	new randomspecialinterval = GetRandomInt(GetConVarInt(specialregulator_interval_min), GetConVarInt(specialregulator_interval_max));
	new Float:specialinterval = float(randomspecialinterval);
	TimerSpecialInterval = CreateTimer(specialinterval, Timer_SpecialInterval);
	if (GetConVarInt(specialregulator_announce) == 1)
	{
		PrintToChatAll("Specials will be prevented from spawning for %f seconds.", specialinterval);
	}
	TimerSpecialDuration = INVALID_HANDLE;
}

public Action:Timer_SpecialInterval(Handle:timer)
{
	TimerSpecialDelay = INVALID_HANDLE;
	//PrintToServer("Specials enabled.");
	SpecialsEnabled = true;
	EnableSpecials();
	new Float:specialduration = GetConVarFloat(specialregulator_duration);
	TimerSpecialDuration = CreateTimer(specialduration, Timer_SpecialDuration);
	if (GetConVarInt(specialregulator_announce) == 1)
	{
		PrintToChatAll("Selected specials will be allowed to spawn for %f seconds.", specialduration);
	}
	TimerSpecialInterval = INVALID_HANDLE;
}

static EnableSpecials()
{
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
	//PrintToServer("%i survivors are alive.", alivesurvivors);
	new allowedspecials = 0;
	if (GetConVarInt(FindConVar("specialregulator_lucky")) == 0)
	{
		allowedspecials = GetRandomInt(1, alivesurvivors);
	}
	if (GetConVarInt(specialregulator_lucky) == 1)
	{
		allowedspecials = GetRandomInt(0, alivesurvivors);
	}
	//PrintToServer("%i specials are allowed to spawn.", allowedspecials);
	if (allowedspecials > 0)
	{
		for (new i = 1; i <= allowedspecials; i++)
		{
			new randomspecial = 0;
			if (GetConVarInt(specialregulator_l4d_favor) == 0)
			{
				randomspecial = GetRandomInt(1, 6);
			}
			if (GetConVarInt(specialregulator_l4d_favor) == 1)
			{
				new randomfavor = GetRandomInt(1, 2);
				if (randomfavor == 1)
				{
					randomspecial = GetRandomInt(1, 3);
				}
				if (randomfavor == 2)
				{
					randomspecial = GetRandomInt(1, 6);
				}
			}
			if (GetConVarInt(specialregulator_l4d_favor) == 2)
			{
				randomspecial = GetRandomInt(1, 3);
			}
			if (randomspecial == 1)
			{
				boomerlimit = GetConVarInt(FindConVar("z_boomer_limit"));
				SetConVarInt(FindConVar("z_boomer_limit"), boomerlimit+1);
				//PrintToServer("A boomer is allowed to spawn.");
			}
			if (randomspecial == 2)
			{
				smokerlimit = GetConVarInt(FindConVar("z_smoker_limit"));
				SetConVarInt(FindConVar("z_smoker_limit"), smokerlimit+1);
				//PrintToServer("A smoker is allowed to spawn.");
			}
			if (randomspecial == 3)
			{
				hunterlimit = GetConVarInt(FindConVar("z_hunter_limit"));
				SetConVarInt(FindConVar("z_hunter_limit"), hunterlimit+1);
				//PrintToServer("A hunter is allowed to spawn.");
			}	
			if (randomspecial == 4)
			{
				jockeylimit = GetConVarInt(FindConVar("z_jockey_limit"));
				SetConVarInt(FindConVar("z_jockey_limit"), jockeylimit+1);
				//PrintToServer("A jockey is allowed to spawn.");
			}	
			if (randomspecial == 5)
			{
				chargerlimit = GetConVarInt(FindConVar("z_charger_limit"));
				SetConVarInt(FindConVar("z_charger_limit"), chargerlimit+1);
				//PrintToServer("A charger is allowed to spawn.");
			}	
			if (randomspecial == 6)
			{
				spitterlimit = GetConVarInt(FindConVar("z_spitter_limit"));
				SetConVarInt(FindConVar("z_spitter_limit"), spitterlimit+1);
				//PrintToServer("A spitter is allowed to spawn.");
			}
		}
	}
	AnnounceSpecials();
}

static DisableSpecials()
{
	//PrintToServer("Disabling specials.");
	SetConVarInt(FindConVar("z_boomer_limit"), 0);
	SetConVarInt(FindConVar("z_charger_limit"), 0);
	SetConVarInt(FindConVar("z_hunter_limit"), 0);
	SetConVarInt(FindConVar("z_jockey_limit"), 0);
	SetConVarInt(FindConVar("z_smoker_limit"), 0);
	SetConVarInt(FindConVar("z_spitter_limit"), 0);
	AnnounceSpecials();
}

static AnnounceSpecials()
{
	if (GetConVarInt(specialregulator_announce) == 1)
	{
		boomerlimit = GetConVarInt(FindConVar("z_boomer_limit"));
		if (boomerlimit > 0)
		{
			PrintToChatAll("Boomer limit: %i", boomerlimit);
		}
		chargerlimit = GetConVarInt(FindConVar("z_charger_limit"));
		if (chargerlimit > 0)
		{
			PrintToChatAll("Charger limit: %i", chargerlimit);
		}
		hunterlimit = GetConVarInt(FindConVar("z_hunter_limit"));
		if (hunterlimit > 0)
		{
			PrintToChatAll("Hunter limit: %i", hunterlimit);
		}
		jockeylimit = GetConVarInt(FindConVar("z_jockey_limit"));
		if (jockeylimit > 0)
		{
			PrintToChatAll("Jockey limit: %i", jockeylimit);
		}
		smokerlimit = GetConVarInt(FindConVar("z_smoker_limit"));
		if (smokerlimit > 0)
		{
			PrintToChatAll("Smoker limit: %i", smokerlimit);
		}
		spitterlimit = GetConVarInt(FindConVar("z_spitter_limit"));
		if (spitterlimit > 0)
		{
			PrintToChatAll("Spitter limit: %i", spitterlimit);
		}
		new limit = boomerlimit + chargerlimit + hunterlimit + jockeylimit + smokerlimit + spitterlimit;
		if (limit == 0)
		{
			if (SpecialsEnabled == true)
			{
				PrintToChatAll("Lucky break! No specials were selected for spawning.");
			}
			if (SpecialsEnabled == false)
			{
				PrintToChatAll("All specials are prevented from spawning.");
			}
		}
	}
}
	