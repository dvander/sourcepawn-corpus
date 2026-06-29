#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2.1"

public Plugin:myinfo = 
{
	name = "[L4D] & [L4D2] Special Spawn Regulator",
	author = "chinagreenelvis",
	description = "Regulates the intervals of special spawns.",
	version = PLUGIN_VERSION,
	url = "www.chinagreenelvis.com"
}

new Handle:specialregulator_delay = INVALID_HANDLE;
new Handle:specialregulator_duration = INVALID_HANDLE;
new Handle:specialregulator_interval = INVALID_HANDLE;

new Handle:TimerSpecialDelay = INVALID_HANDLE;
new Handle:TimerSpecialDuration = INVALID_HANDLE;
new Handle:TimerSpecialsAllow = INVALID_HANDLE;
new Handle:TimerSpecialsDisable = INVALID_HANDLE;

public OnPluginStart()
{	
	specialregulator_delay = CreateConVar("specialregulator_delay", "120", "Time until the first specials are allowed to spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_duration = CreateConVar("specialregulator_duration", "30", "Time during which specials are allowed to spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	specialregulator_interval = CreateConVar("specialregulator_interval", "60", "Time between special spawns", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
		
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
		SetConVarInt(FindConVar("director_no_specials"), 1);
		if (TimerSpecialDelay == INVALID_HANDLE)
		{
			TimerSpecialDelay = CreateTimer(GetConVarFloat(specialregulator_delay), Timer_SpecialDelay);
		}
	}
}

public Action:Timer_SpecialDelay(Handle:timer)
{	
	//PrintToChatAll("TimerSpecialDelay finished. Specials now allowed to spawn.");
	SetConVarInt(FindConVar("director_no_specials"), 0);
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		TimerSpecialDelay = INVALID_HANDLE;
	}
	if (TimerSpecialsAllow == INVALID_HANDLE)
	{
		TimerSpecialsAllow = CreateTimer(GetConVarFloat(specialregulator_interval), Timer_SpecialsAllow, _, TIMER_REPEAT);
	}
	if (TimerSpecialDuration == INVALID_HANDLE)
	{
		TimerSpecialDuration = CreateTimer(GetConVarFloat(specialregulator_duration), Timer_SpecialDuration);
	}
}

public Action:Timer_SpecialDuration(Handle:timer)
{	
	//PrintToChatAll("TimerSpecialDuration finished. Specials now disabled.");
	SetConVarInt(FindConVar("director_no_specials"), 1);
	if (TimerSpecialDuration != INVALID_HANDLE)
	{
		TimerSpecialDuration = INVALID_HANDLE;
	}
	if (TimerSpecialsDisable == INVALID_HANDLE)
	{
		TimerSpecialsDisable = CreateTimer(GetConVarFloat(specialregulator_interval), Timer_SpecialsDisable, _, TIMER_REPEAT);
	}
}

public Action:Timer_SpecialsAllow(Handle:timer)
{
	//PrintToChatAll("Specials allowed to spawn.");
	SetConVarInt(FindConVar("director_no_specials"), 0);
}

public Action:Timer_SpecialsDisable(Handle:timer)
{
	//PrintToChatAll("Specials disabled.");
	SetConVarInt(FindConVar("director_no_specials"), 1);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDelay);
		TimerSpecialDelay = INVALID_HANDLE;
	}
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialDuration);
		TimerSpecialDuration = INVALID_HANDLE;
	}
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialsAllow);
		TimerSpecialsAllow = INVALID_HANDLE;
	}
	if (TimerSpecialDelay != INVALID_HANDLE)
	{
		KillTimer(TimerSpecialsDisable);
		TimerSpecialsDisable = INVALID_HANDLE;
	}
}

