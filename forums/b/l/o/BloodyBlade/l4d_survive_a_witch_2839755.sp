#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#tryinclude <left4dhooks>

#define PLUGIN_VERSION "0.2"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Survive A Witch",
	author = "AlexDarby(Rewritten by BloodyBlade)",
	description = "WitchesInSurvivalMode",
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net/" 	
};

ConVar hPluginEnabled, hGameMode, hCountWitches;
int iCountWitches = 0, iCountW = 0;
bool bHooked = false, bL4D2 = false, bWitchSpawned = false;
#if defined _l4dh_included
bool bLateload = false, bL4DHLib = false;
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
	CreateConVar("l4d_survive_a_witch_version", PLUGIN_VERSION, "L4D Survive A Witch plugin Version.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hPluginEnabled = CreateConVar("l4d_survive_a_witch_enabled", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCountWitches = CreateConVar("l4d_survive_a_witch_count_witches", "1", "How many witches allowed at once?(Def. 1, Max 32)", CVAR_FLAGS, true, 0.0, true, 32.0);

	AutoExecConfig(true, "l4d_survive_a_witch");

	hPluginEnabled.AddChangeHook(ConVarPluginOnChanged);
	hGameMode = FindConVar("mp_gamemode");
	hGameMode.AddChangeHook(ConVarPluginOnChanged);
	hCountWitches.AddChangeHook(ConVarCountChanged);

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

void ConVarCountChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	iCountWitches = hCountWitches.IntValue;
}

void IsAllowed()
{
	bool bPluginEnabled = hPluginEnabled.BoolValue;
	if(!bHooked &&  bPluginEnabled && IsSurvivalGameMode())
	{
		bHooked = true;
		ConVarCountChanged(null, "", "");
		#if !defined _l4dh_included
		HookEvent("tank_spawn", Events);
		#endif
		HookEvent("witch_killed", Events);
		HookEvent("round_start", Events);
		HookEvent("round_end", Events);
		HookEvent("mission_lost", Events);
		HookEvent("map_transition", Events);
	}
	else if(bHooked && (!bPluginEnabled || !IsSurvivalGameMode()))
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
		if(IsSurvivalGameMode())
		{
			SpawnAWitch();
		}
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

		if(iCountW > 0)
		{
			iCountW--;
		}
	}
	else if(strcmp(name, "round_start") == 0 || strcmp(name, "round_end") == 0 || strcmp(name, "mission_lost") == 0 || strcmp(name, "map_transition") == 0)
	{
		if (bWitchSpawned)
		{
			bWitchSpawned = false;
		}

		if(iCountW > 0)
		{
			iCountW = 0;
		}
	}
}

#if defined _l4dh_included
public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	if(bHooked && bL4DHLib && IsSurvivalGameMode() && client > 0 && IsClientInGame(client))
	{
		if(bL4D2)
		{
			if(L4D2_GetWitchCount() < iCountWitches)
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
		if(iCountW < iCountWitches)
		{
			int anyclient = GetAnyClient();
			if (anyclient == 0)
			{		
				anyclient = CreateFakeClient("Bot");
				if (anyclient == 0)
				{		
					return;	
				}
			}

			if(bL4D2)
			{
				char command[] = "z_spawn_old";
				int flags = GetCommandFlags(command);
				SetCommandFlags(command, flags & ~FCVAR_CHEAT);		
				FakeClientCommand(anyclient, "z_spawn_old witch auto");
				SetCommandFlags(command, flags);
			}
			else
			{
				char command[] = "z_spawn";
				int flags = GetCommandFlags(command);
				SetCommandFlags(command, flags & ~FCVAR_CHEAT);		
				FakeClientCommand(anyclient, "z_spawn witch auto");
				SetCommandFlags(command, flags);
			}
			iCountW++;
		}
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

stock bool IsSurvivalGameMode()
{
	char sGameModeName[32];
	hGameMode.GetString(sGameModeName, 32);
	return StrContains(sGameModeName, "survival", false) != -1;
}
