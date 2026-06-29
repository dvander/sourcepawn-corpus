#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new String:items[2][50] =
{
	"weapon_defibrillator_spawn",
	"weapon_defibrillator"
};

//-----------------------------------------------------------------------------
public OnPluginStart()
{
	CreateTimer(20.0, Timer_RemoveItems, _, TIMER_REPEAT);
}
 
public Action Timer_RemoveItems(Handle timer)
{
	RemoveAllEntitiesByClassname();
	return Plugin_Continue;
}
	
//-----------------------------------------------------------------------------
public OnMapStart()
{
	RemoveAllEntitiesByClassname();
}

//---------------------------------------------------------------------------
public RemoveAllEntitiesByClassname()
{
	new ent = -1;
	new prev = 0;
	for(new i=0; i<2; i++)
	{	
		while ((ent = FindEntityByClassname(ent, items[i])) != -1)
		{
			if (prev) 
				RemoveEdict(prev);
			prev = ent;
		}
		if (prev)
			RemoveEdict(prev);
	}
}
		