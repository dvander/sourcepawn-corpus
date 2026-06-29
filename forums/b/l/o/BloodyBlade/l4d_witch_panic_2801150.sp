#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY
#define PANIC_SOUND "npc/mega_mob/mega_mob_incoming.wav"

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Witch Panic",
	author = "BloodyBlade",
	description = "You'll think twice about messing with the witch",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198078797525/"
}

ConVar hWitchPanicPluginEnabled, hWitchPanicOnHarasserSet, hWitchPanicOnDeath;
bool bHooked = false, bWitchPanicOnHarasserSet = false, bWitchPanicOnDeath = false;

public void OnPluginStart()
{
	CreateConVar("l4d_witch_panic_version", PLUGIN_VERSION, "[L4D & L4D2] Witch Panic plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hWitchPanicPluginEnabled = CreateConVar("l4d_witch_panic_plugin_enabled", "1", " Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	hWitchPanicOnHarasserSet = CreateConVar("l4d_witch_panic_on_harasser_set", "1", "Create a panic when the witch harasser set?", CVAR_FLAGS, true, 0.0, true, 1.0);
	hWitchPanicOnDeath = CreateConVar("l4d_witch_panic_on_death", "1", "Create a panic when a witch is killed?", CVAR_FLAGS, true, 0.0, true, 1.0);
	hWitchPanicPluginEnabled.AddChangeHook(ConVarPluginOnChanged);
	hWitchPanicOnHarasserSet.AddChangeHook(ConVarsChanged);
	hWitchPanicOnDeath.AddChangeHook(ConVarsChanged);
	AutoExecConfig(true, "l4d_witch_panic");
}

public void OnMapStart()
{
	PrecacheSound(PANIC_SOUND, true);
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
	bWitchPanicOnHarasserSet = hWitchPanicOnHarasserSet.BoolValue;
	bWitchPanicOnDeath = hWitchPanicOnDeath.BoolValue;
}

void IsAllowed()
{
	bool bPluginOn = hWitchPanicPluginEnabled.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("witch_harasser_set", Event_WitchHarraserOrDeathPanic);
		HookEvent("witch_killed", Event_WitchHarraserOrDeathPanic);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("witch_harasser_set", Event_WitchHarraserOrDeathPanic);
		UnhookEvent("witch_killed", Event_WitchHarraserOrDeathPanic);
	}
}

Action Event_WitchHarraserOrDeathPanic(Event event, const char[] name, bool dontBroadcast)
{
	if (strcmp(name, "witch_harasser_set") == 0)
	{
		if(bWitchPanicOnHarasserSet)
		{
			CreateTimer(1.0, PanicEvent);
		}
	}
	else if(strcmp(name, "witch_killed") == 0)
	{
		if(bWitchPanicOnDeath)
		{
			CreateTimer(1.0, PanicEvent);
		}
	}
	return Plugin_Continue;
}

Action PanicEvent(Handle timer)
{
	int iAnyClient = GetAnyClient();
	if(iAnyClient > 0)
	{
		EmitSoundToAll(PANIC_SOUND);
		char sCommand[16];
		strcopy(sCommand, sizeof(sCommand), "z_spawn");
		int flags = GetCommandFlags(sCommand);
		SetCommandFlags(sCommand, flags & ~FCVAR_CHEAT);
		FakeClientCommand(iAnyClient, "z_spawn mob auto");
		SetCommandFlags(sCommand, flags);
	}
	return Plugin_Stop;
}

int GetAnyClient() 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			return i;
		}
	}
	return 0;
}
