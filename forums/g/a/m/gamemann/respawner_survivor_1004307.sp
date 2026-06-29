#include <sourcemod>
#include <SDKtools>

#define Plugin_version "1"


Public Plugin:myinfo =
{
Name = "respawner_survivor",
Author = "christian (gamemann)",
Desciption = "when a survivor dies it gives them 1-2 minutes to respawn again",
Version = "Plugin_version,
URL = "",
}
Public OnPluginStart()
{
RegAdminCmd("sm_survivor_spawn", Command_survivor_spawn, ADMFLAG_SURVIVOR_SPAWN)
}

Public Action:Command_survivor_spawn(cielent, args)
{
	Return Plugin_Handle;
}

New Handle:sm_respawn_survivor
{
Sm_respawn_survivor = CreateConvar("spawn_time",
"0.8"
"sets the maxiam of spawn time"
_,	/* Flags will be discussed later*/
True,		/* has the minium*/
0.1,
True,		/* sets a maxium*/
200.0)
}

New sm_survivor_spawn
SetStartSurvivorSpawn(new SurvivorSpawn)
{
SM_survivor_spawn = GetConVarInt(SM_survivor_spawn)
SetConVarint(sm_survivor_spawn, spawn_survivor)
}

Public sm_survivor_spawn()
{
Decl String:buffer[100]
GetCvarSTring(sm_survivor_spawn, budder, sizeof(buffer))
Return Stringtoint(buffer)

