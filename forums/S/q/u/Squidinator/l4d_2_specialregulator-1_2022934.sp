#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.1.3"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Special Spawn Regulator",
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
	specialregulator_announce = CreateConVar("specialregulator_announce", "0", "Announce special spawn activity in the server console? 0:no, 1:yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
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
	UnsetCheatVar( FindConVar( "director_no_specials" ) );
	UnsetCheatVar( FindConVar( "z_smoker_limit" ) );
	UnsetCheatVar( FindConVar( "z_boomer_limit" ) );
	UnsetCheatVar( FindConVar( "z_hunter_limit" ) );
	UnsetCheatVar( FindConVar( "z_spitter_limit" ) );
	UnsetCheatVar( FindConVar( "z_jockey_limit" ) );
	UnsetCheatVar( FindConVar( "z_charger_limit" ) );

	//PrintToServer("ROUND START");
	//PrintToServer("Starting initial spawn delay.");
	SpecialsEnabled = false;
	DisableSpecials();
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
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDelay);
		TimerSpecialDelay = INVALID_HANDLE;
	}
	if (TimerSpecialDelay == INVALID_HANDLE)
	{
		TimerSpecialDelay = CreateTimer(GetConVarFloat(specialregulator_delay), Timer_SpecialInterval);
		if (GetConVarInt(specialregulator_announce) == 1)
		{
			PrintToServer("The initial special spawn delay will last for %f seconds.", GetConVarFloat(specialregulator_delay));
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
		PrintToServer("Specials will be prevented from spawning for %f seconds.", specialinterval);
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
		PrintToServer("Selected specials will be allowed to spawn for %f seconds.", specialduration);
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
			if (IsClientInGame(i))
			{
				if (IsClientConnected(i))
				{
					if (GetClientTeam(i) == 2) 
					{
						if (IsPlayerAlive(i))
						{
							alivesurvivors++;
						}
					}
				}
			}
		}
	}
	//PrintToServer("%i survivors are alive.", alivesurvivors);
	new allowedspecials = 0;
	if (GetConVarInt(FindConVar("specialregulator_lucky")) == 0)
	{
		if (alivesurvivors > 0)
		{
			allowedspecials = GetRandomInt(1, alivesurvivors);
		}
		else
		{
			allowedspecials = 0;
		}
	}
	if (GetConVarInt(specialregulator_lucky) == 1)
	{
		if (alivesurvivors > 0)
		{
			allowedspecials = GetRandomInt(0, alivesurvivors);
		}
		else
		{
			allowedspecials = 0;
		}
	}
	//PrintToServer("%i specials are allowed to spawn.", allowedspecials);
	if (allowedspecials > 0)
	{
		SetConVarInt(FindConVar("director_no_specials"), 0);

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
	SetConVarInt(FindConVar("director_no_specials"), 1);


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
			PrintToServer("Boomer limit: %i", boomerlimit);
		}
		chargerlimit = GetConVarInt(FindConVar("z_charger_limit"));
		if (chargerlimit > 0)
		{
			PrintToServer("Charger limit: %i", chargerlimit);
		}
		hunterlimit = GetConVarInt(FindConVar("z_hunter_limit"));
		if (hunterlimit > 0)
		{
			PrintToServer("Hunter limit: %i", hunterlimit);
		}
		jockeylimit = GetConVarInt(FindConVar("z_jockey_limit"));
		if (jockeylimit > 0)
		{
			PrintToServer("Jockey limit: %i", jockeylimit);
		}
		smokerlimit = GetConVarInt(FindConVar("z_smoker_limit"));
		if (smokerlimit > 0)
		{
			PrintToServer("Smoker limit: %i", smokerlimit);
		}
		spitterlimit = GetConVarInt(FindConVar("z_spitter_limit"));
		if (spitterlimit > 0)
		{
			PrintToServer("Spitter limit: %i", spitterlimit);
		}
		new limit = boomerlimit + chargerlimit + hunterlimit + jockeylimit + smokerlimit + spitterlimit;
		if (limit == 0)
		{
			if (SpecialsEnabled == true)
			{
				if (GetConVarInt(specialregulator_lucky) == 1)
				{
					PrintToServer("Lucky break! No specials were selected for spawning.");
				}
				else
				{
					PrintToServer("Something went wrong. No specials are allowed to spawn.");
				}
			}
			if (SpecialsEnabled == false)
			{
				PrintToServer("All specials are prevented from spawning.");
			}
		}
	}
}

UnsetCheatVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags &= ~FCVAR_CHEAT;
	SetConVarFlags(hndl, flags);
}
	