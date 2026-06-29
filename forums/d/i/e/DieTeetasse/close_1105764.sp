#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define MAX_DOORS 128
#define MULTIPLIER 0.2

new global_doorsused[MAX_DOORS];
new global_doorscount = 0;

public OnMapStart()
{
	new doors[MAX_DOORS];
	new doorscount = 0;
	new bool:doorsused[MAX_DOORS];
	new entitycount = GetEntityCount();
	new String:entname[64];
	
	//loop through ents
	for (new i = 1; i < entitycount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, entname, sizeof(entname));
			
			if (StrEqual(entname, "prop_door_rotating"))
			{
				doors[doorscount] = i;
				doorsused[doorscount] = false;
				doorscount++;
			}
		}
	}
	
	new doorslocked = RoundFloat(float(doorscount) * MULTIPLIER);
	new rnd;
	
	global_doorscount = 0;
	
	for (new i = 0; i < doorslocked; i++)
	{
		rnd = GetRandomInt(0, doorscount-1);
		
		//repeat if already used
		if (doorsused[rnd])
		{
			i--;
			continue;
		}
		
		AcceptEntityInput(doors[rnd], "Close");
		AcceptEntityInput(doors[rnd], "Lock");
		
		doorsused[rnd] = true;
		
		global_doorsused[global_doorscount] = doors[rnd];
		global_doorscount++;
	}
	
	HookEntityOutput("prop_door_rotating", "OnLockedUse", TriedToOpenDoor);
}

public TriedToOpenDoor(String:output[], caller, activator, Float:delay)
{
	new bool:inarray = false;

	for (new i = 0; i < global_doorscount; i++)
	{
		if (caller == global_doorsused[i])
		{
			inarray = true;
			break;
		}
	}
	
	if (!inarray) return;
	if (!IsClientInGame(activator)) return;
	if (IsFakeClient(activator)) return;
	
	PrintToChat(activator, "Door is locked. Melee/shoot it to open.");
}