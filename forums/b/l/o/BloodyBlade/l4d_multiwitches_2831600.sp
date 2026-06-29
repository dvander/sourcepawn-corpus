#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#tryinclude <left4dhooks>

#define PLUGIN_VERSION "1.4"
#define CVAR_FLAGS FCVAR_NOTIFY
#define WITCH_MODEL "models/infected/witch.mdl"
#define WITCH_BRIDE_MODEL "models/infected/witch_bride.mdl"

#if !defined DEBUG_MULTIWITCHES
	#define DEBUG_MULTIWITCHES 0
#endif

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Multiwitches",
	author = "McFlurry",
	description = "Spawns more witches.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

ConVar hEnable, hCount, hModes;
bool bHooked = false, bL4D2 = false;
int iCount = 0;
#if defined _l4dh_included
float Pos[3];
bool bLateload = false, bL4DHLib = false;
#else
int iWitchcount = 0;
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion engine = GetEngineVersion();
	if(engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only runs in Left 4 Dead game series.");
		return APLRes_SilentFailure;
	}
	#if defined _l4dh_included
	bLateload = late;
	#endif
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_multiwitches_version", PLUGIN_VERSION, "Version of MultiWitches on this server!", CVAR_FLAGS|FCVAR_DONTRECORD);
	hEnable = CreateConVar("l4d_multiwitches_enable", "1", "Enable or Disable this plugin?", CVAR_FLAGS);
	hCount = CreateConVar("l4d_multiwitches_witches", "1", "How many extra witches to create?", CVAR_FLAGS);
	hModes = CreateConVar("l4d_multiwitches_modes", "coop,realism,versus,teamversus","Which gamemodes allow extra witches", CVAR_FLAGS);

	AutoExecConfig(true, "l4d_multiwitches");

	hEnable.AddChangeHook(ConVarPluginOnChanged);
	hCount.AddChangeHook(ConVarsChanged);
	hModes.AddChangeHook(ConVarPluginOnChanged);

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

public void OnMapStart()
{
	#if !defined _l4dh_included
	iWitchcount = 0;
	#endif
	PrecacheModel(WITCH_MODEL, true);
	if(bL4D2)
	{
		PrecacheModel(WITCH_BRIDE_MODEL, true);
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iCount = hCount.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = hEnable.BoolValue;
	if(!bHooked && bPluginOn && IsAllowedGameMode())
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		#if !defined _l4dh_included
		HookEvent("witch_spawn", Event_Witch);
		#endif
	}
	else if(bHooked && (!bPluginOn || !IsAllowedGameMode()))
	{
		bHooked = false;
		#if !defined _l4dh_included
		UnhookEvent("witch_spawn", Event_Witch);
		#endif
	}
}

#if defined _l4dh_included
public Action L4D_OnSpawnWitch(const float vecPos[3], const float vecAng[3])
{
	if(bHooked && bL4DHLib && L4D2_GetWitchCount() < iCount)
	{
		AddWitch();
	}
	return Plugin_Continue;
}
#else
Action Event_Witch(Event event, const char[] name, bool dontBroadcast)
{
	if(iWitchcount < iCount)
	{
		iWitchcount++;
		AddWitch();
	}
	else
	{
		iWitchcount = 0;
	}
	return Plugin_Continue;
}
#endif

void AddWitch()
{
	if(bL4D2)
	{
		#if defined _l4dh_included
		if(bL4DHLib)
		{
			if(L4D_GetRandomPZSpawnPosition(0, 7, 5, Pos))
			{
				int iRandomWitchType = GetRandomInt(1, 2);
				if(iRandomWitchType == 1)
				{
					L4D2_SpawnWitch(Pos, NULL_VECTOR);
				}
				else if(iRandomWitchType == 2)
				{
					L4D2_SpawnWitchBride(Pos, NULL_VECTOR);
				}
			}
		}
		#else
		int flags = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				FakeClientCommand(i, "z_spawn_old witch auto");
				break;
			}
		}
		SetCommandFlags("z_spawn_old", flags|FCVAR_CHEAT);
		#endif
	}
	else
	{
		int flags = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				FakeClientCommand(i, "z_spawn witch auto");
				break;
			}
		}
		SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
	}
	#if DEBUG_MULTIWITCHES
	PrintToChatAll("AddWitch() Called!");
	PrintToServer("AddWitch() Called!");
	#endif
}

stock bool IsAllowedGameMode()
{
	char gamemode[24], gamemodeactive[128];
	FindConVar("mp_gamemode").GetString(gamemode, sizeof(gamemode));
	hModes.GetString(gamemodeactive, sizeof(gamemodeactive));
	return StrContains(gamemodeactive, gamemode) != -1;
}

#if DEBUG_MULTIWITCHES
public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "witch", false))
	{
		PrintToChatAll("Witch %d Created!", entity);
		PrintToServer("Witch %d Created!", entity);
	}
}
#endif