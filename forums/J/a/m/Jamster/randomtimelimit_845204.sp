/**
 * ==================================================================================
 *  Random Timelimit Change Log
 * ==================================================================================
 * 
 * 1.0
 * - Initial release. 
 *
 * 1.1
 * - Added default timelimit option.
 *
 * 1.2
 * - Added KOTH support.
 *
 * 1.3
 * - Full translation support for cvars and errors.
 * - TF2 game check added.
 * - Some code optimisation.
 * - Removed FailSafe's and use better fallbacks.
 *
 * 1.3.1
 * - Added better random number generations with SM 1.3 specific code (thanks to 
 *   psychonic).
 * ==================================================================================
 */
 
#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.3.1"

public Plugin:myinfo = 
{
	name = "Random Timelimit",
	author = "Jamster",
	description = "Chooses a random timelimit depending on the gametype",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define ARENA 0
#define CTF 1
#define PL 2
#define CP 3
#define KOTH 4
#define DEF 5
#define TOTAL 6
#define MODES 4

new Handle:Cvar_GameType[MODES];
new Handle:Cvar_RandomTime_Enable;
new Handle:Cvar_Timelimit;
new Handle:Cvar_Time_Low[TOTAL];
new Handle:Cvar_Time_High[TOTAL];


public OnPluginStart()
{
	LoadTranslations("randomtimelimit.phrases");
	decl String:desc[256];
	
	Format(desc, sizeof(desc), "%t", "randtl_version");
	CreateConVar("sm_randomtimelimit_version", PLUGIN_VERSION, desc, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Format(desc, sizeof(desc), "%t", "randtl_enable");
	Cvar_RandomTime_Enable = CreateConVar("sm_randomtimelimit_enable", "1", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_arena_low");
	Cvar_Time_Low[ARENA] = CreateConVar("sm_randomtimelimit_arena_low", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_arena_high");
	Cvar_Time_High[ARENA] = CreateConVar("sm_randomtimelimit_arena_high", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_ctf_low");
	Cvar_Time_Low[CTF] = CreateConVar("sm_randomtimelimit_ctf_low", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_ctf_high");
	Cvar_Time_High[CTF] = CreateConVar("sm_randomtimelimit_ctf_high", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_pl_low");
	Cvar_Time_Low[PL] = CreateConVar("sm_randomtimelimit_pl_low", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_pl_high");
	Cvar_Time_High[PL] = CreateConVar("sm_randomtimelimit_pl_high", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_cp_low");
	Cvar_Time_Low[CP] = CreateConVar("sm_randomtimelimit_cp_low", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_cp_high");
	Cvar_Time_High[CP] = CreateConVar("sm_randomtimelimit_cp_high", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_koth_low");
	Cvar_Time_Low[KOTH] = CreateConVar("sm_randomtimelimit_koth_low", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_koth_high");
	Cvar_Time_High[KOTH] = CreateConVar("sm_randomtimelimit_koth_high", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_def_low");
	Cvar_Time_Low[DEF] = CreateConVar("sm_randomtimelimit_def_low", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "randtl_def_high");
	Cvar_Time_High[DEF] = CreateConVar("sm_randomtimelimit_def_high", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Cvar_GameType[ARENA] = FindConVar("tf_gamemode_arena");
	Cvar_GameType[CTF] = FindConVar("tf_gamemode_ctf");
	Cvar_GameType[PL] = FindConVar("tf_gamemode_payload");
	Cvar_GameType[CP] = FindConVar("tf_gamemode_cp");
	Cvar_Timelimit = FindConVar("mp_timelimit");
	
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "tf"))
	{
		LogError("%t", "randtl_game_error");
	}
	
	AutoExecConfig(true, "plugin.randomtimelimit");
}

public OnConfigsExecuted()
{
	if (!GetConVarInt(Cvar_RandomTime_Enable))
	{
		return;
	}
	
	// Checks all the values are OK
	new Time_Low[TOTAL];
	new Time_High[TOTAL];
	for (new i; i < TOTAL; i++)
	{
		Time_Low[i] = GetConVarInt(Cvar_Time_Low[i]);
		Time_High[i] = GetConVarInt(Cvar_Time_High[i]);
		if (Time_Low[i] > Time_High[i])
		{
			decl String:Error[32];
			switch (i)
			{
				case ARENA:
					Format(Error, sizeof(Error), "randtl_time_error_arena");
				case CTF:
					Format(Error, sizeof(Error), "randtl_time_error_ctf");
				case CP:
					Format(Error, sizeof(Error), "randtl_time_error_cp");
				case PL:
					Format(Error, sizeof(Error), "randtl_time_error_pl");
				case KOTH:
					Format(Error, sizeof(Error), "randtl_time_error_koth");
				case DEF:
					Format(Error, sizeof(Error), "randtl_time_error_def");
			}
			LogError("%t", Error);
			new StoredLow = Time_Low[i];
			Time_Low[i] = Time_High[i];
			Time_High[i] = StoredLow;
		}
	}
	
	// All OK, continue with setting the timelimit
	new GameType[MODES+1];
	for (new i; i < MODES; i++)
	{
		GameType[i] = GetConVarInt(Cvar_GameType[i]);
	}

	decl String:CurrentMap[65];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if (!StrContains(CurrentMap, "koth_", false))
	{
		GameType[KOTH] = 1;
		GameType[CP] = 0;
	}
	
	new TimeLimit;
	for (new i; i < TOTAL-1; i++)
	{
		switch (GameType[i])
		{
			case 0:
				continue;
		}	
		
		if (!Time_Low[i] && !Time_High[i])
		{
			break;
		}
			
		if (Time_Low[i] == Time_High[i])
		{
			TimeLimit = Time_Low[i];
		}
		else
		{
			TimeLimit = RTL_GetRandomInt(Time_Low[i], Time_High[i]);
		}
		
		SetConVarInt(Cvar_Timelimit, TimeLimit);
		break;
	}
	
	if (!TimeLimit)
	{
		if (!Time_Low[DEF] && !Time_High[DEF])
		{
			return;
		}
		
		if (Time_Low[DEF] == Time_High[DEF])
		{
			TimeLimit = Time_Low[DEF];
		}
		else
		{
			TimeLimit = RTL_GetRandomInt(Time_Low[DEF], Time_High[DEF]);
		}
		
		SetConVarInt(Cvar_Timelimit, TimeLimit);
	}
}

// Thanks to psychonic for this.
 
RTL_GetRandomInt(const min, const max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}