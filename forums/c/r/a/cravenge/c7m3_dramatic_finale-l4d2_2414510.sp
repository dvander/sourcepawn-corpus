#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:IsTheSacrificeFinale = false;
new bool:IsDramaticFinaleNeeded = false;

public Plugin:myinfo =
{
	name = "[L4D2] The Sacrifice Dramatic Finale",
	author = "cravenge",
	description = "Adds Dramatic Effects To The Sacrifice Finale.",
	version = "1.1",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("c7m3_dramatic_finale-l4d2_version", "1.0", "The Sacrifice Dramatic Finale Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("finale_escape_start", OnFinaleEscapeStart);
	HookEvent("tank_spawn", OnEffectsAdded);
	HookEvent("finale_win", OnEffectsRemoved);
	HookEvent("mission_lost", OnEffectsRemoved);
	HookEvent("round_end", OnEffectsRemoved);
}

public OnMapStart()
{
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if(StrEqual(mapname, "c7m3_port"))
	{
		IsTheSacrificeFinale = true;
	}
	else
	{
		IsTheSacrificeFinale = false;
	}
}

public Action:OnFinaleEscapeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(IsTheSacrificeFinale)
	{
		IsDramaticFinaleNeeded = true;
	}
	else
	{
		IsDramaticFinaleNeeded = false;
	}
}

public Action:OnEffectsAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(IsTheSacrificeFinale && IsDramaticFinaleNeeded)
	{
		SlowMotionEffects();
	}
}

public Action:OnEffectsRemoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(IsTheSacrificeFinale)
	{
		IsDramaticFinaleNeeded = false;
	}
}

stock SlowMotionEffects(const String:desiredTimeScale[] = "0.2", const String:re_Acceleration[] = "2.0", const String:minBlendRate[] = "1.0", const String:blendDeltaMultiplier[] = "2.0")
{
	new ent = CreateEntityByName("func_timescale");
	
	DispatchKeyValue(ent, "desiredTimescale", desiredTimeScale);
	DispatchKeyValue(ent, "acceleration", re_Acceleration);
	DispatchKeyValue(ent, "minBlendRate", minBlendRate);
	DispatchKeyValue(ent, "blendDeltaMultiplier", blendDeltaMultiplier);
	
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "Start");
	
	CreateTimer(1.0, RevertBackToNormal, ent, TIMER_REPEAT);
}

public Action:RevertBackToNormal(Handle:timer, any:ent)
{
	if(!IsDramaticFinaleNeeded)
	{
		if(IsValidEdict(ent))
		{
			AcceptEntityInput(ent, "Stop");
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

