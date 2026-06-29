
/********************************************************************************************
* Plugin	: HappyTankWitch
* Version	: 0.1
* Game	: Left4Dead 
* Author	: Cia Hang
* Testers	: Myself

* Version 0.1
* 		- Initial release
*********************************************************************************************/ 
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#tryinclude <left4dhooks>

#define PLUGIN_VERSION "0.1"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "Happy Tank Witch",
	author = "Cia Hang",  
	description = "For every Tank that spawns, so shall a Witch",
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net/" 		
};

ConVar hPluginEnabled;
bool bPluginEnabled = false, bHooked = false, bLateload = false, bL4DHLib = false, bL4D2 = false, bWitchSpawned = false;
#if !defined _l4dh_included
	#pragma unused bL4DHLib
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	#if defined _l4dh_included
	bLateload = late;
	#endif
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_happy_tank_witch_version", PLUGIN_VERSION, "L4D Happy Tank Witch plugin Version.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hPluginEnabled = CreateConVar("l4d_happy_tank_witch_plugin_enabled", "1", " Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	hPluginEnabled.AddChangeHook(ConVarPluginOnChanged);
	AutoExecConfig(true, "l4d_happy_tank_witch");

	#if defined _l4dh_included
	if(bLateload)
	{
		bL4DHLib = LibraryExists("left4dhooks");
	}
	#endif
}

#if defined _l4dh_included
public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "left4dhooks") == 0)
	{
		bL4DHLib = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "left4dhooks") == 0)
	{
		bL4DHLib = false;
	}
}
#endif

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void IsAllowed()
{
	bPluginEnabled = hPluginEnabled.BoolValue;
	if(bPluginEnabled && !bHooked)
	{
		bHooked = true;
		#if !defined _l4dh_included
		HookEvent("tank_spawn", Events);
		#endif
		HookEvent("witch_killed", Events);
		HookEvent("round_start", Events);
		HookEvent("round_end", Events);
		HookEvent("mission_lost", Events);
		HookEvent("map_transition", Events);
	}
	else if(!bPluginEnabled && bHooked)
	{
		bHooked = false;
		#if !defined _l4dh_included
		UnhookEvent("tank_spawn", Events);
		#endif
		UnhookEvent("witch_killed", Events);
		UnhookEvent("round_start", Events);
		UnhookEvent("round_end", Events);
		UnhookEvent("mission_lost", Events);
		UnhookEvent("map_transition", Events);
	}
}

void Events(Event event, const char[] name, bool dontBroadcast)
{
	#if !defined _l4dh_included
	if (strcmp(name, "tank_spawn") == 0)
	{
		SpawnAWitch();
	}
	else if(strcmp(name, "witch_killed") == 0)
	#else
	if(strcmp(name, "witch_killed") == 0)
	#endif
	{
		if (bWitchSpawned)
		{
			bWitchSpawned = false;
		}
	}
	else if(strcmp(name, "round_start") == 0 || strcmp(name, "round_end") == 0 || strcmp(name, "mission_lost") == 0 || strcmp(name, "map_transition") == 0)
	{
		if (bWitchSpawned)
		{
			bWitchSpawned = false;
		}
	}
}

#if defined _l4dh_included
public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	if(bL4DHLib && client > 0 && IsClientInGame(client))
	{
		if(bL4D2)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					L4D2_SpawnWitch(vecPos, vecAng);
					bWitchSpawned = true;
				}
				case 2:
				{
					L4D2_SpawnWitchBride(vecPos, vecAng);
					bWitchSpawned = true;
				}
			}
		}
		else
		{
			SpawnAWitch();
		}
	}
}
#endif

void SpawnAWitch()
{
	if (!bWitchSpawned)
	{
		bWitchSpawned = true;
		int anyclient = GetAnyClient();
		if (anyclient == 0)
		{		
			anyclient = CreateFakeClient("Bot");
			if (anyclient == 0)
			{		
				return;	
			}
		}
		char command[] = "z_spawn";
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);		
		FakeClientCommand(anyclient, "z_spawn witch auto");
		SetCommandFlags(command, flags);
	}
	else
	{
		return;
	}
}

int GetAnyClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			return i;
		}
	}
	return 0;
}
