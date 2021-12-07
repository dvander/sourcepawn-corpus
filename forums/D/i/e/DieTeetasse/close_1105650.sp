#include <sourcemod>
#include <sdktools>

#define MAX_DOORS 128
#define MULTIPLIER 0.2

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
	
	for (new i = 0; i < doorslocked; i++)
	{
		rnd = GetRandomInt(0, doorscount-1);
		
		//repeat if already used
		if (doorsused[rnd])
		{
			i--;
			continue;
		}
		
		AcceptEntityInput(doors[rnd], "Lock");
		doorsused[rnd] = true;
	}
}