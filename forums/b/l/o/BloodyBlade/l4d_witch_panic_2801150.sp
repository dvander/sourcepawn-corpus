#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define PANIC_SOUND "npc/mega_mob/mega_mob_incoming.wav"

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Witch Panic",
	author = "BloodyBlade",
	description = "You'll think twice about messing with the witch",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198078797525/"
}

public void OnPluginStart()
{
	CreateConVar("Witch_Panic", PLUGIN_VERSION, "Version of Witch Panic", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	HookEvent("witch_harasser_set", WitchPanic_Event);
	HookEvent("witch_killed", WitchPanic_Event);
}

public void OnMapStart()
{
	PrecacheSound(PANIC_SOUND, true);
}

Action WitchPanic_Event(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(2.0, PanicEvent);
    return Plugin_Continue;
}

Action PanicEvent(Handle timer)
{
    EmitSoundToAll(PANIC_SOUND);
    SpawntyCommand(GetAnyClient(), "z_spawn", "mob auto");
    return Plugin_Stop;
}

stock void SpawntyCommand(int client, char[] command, char[] arguments = "")
{
	if (client)
	{
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

int GetAnyClient() 
{ 
	for (int target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target)) 
		    return target; 
	} 
	return -1; 
}
