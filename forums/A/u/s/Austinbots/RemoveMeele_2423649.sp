#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "RemoveMelee ",
	author = "Austinbots",
	description = "Removes all melee weapons from all maps",
	version = "1.0",
	url = ""
}

new String:meleeWeapons[13][25] =
{
	"weapon_melee_spawn",
	"weapon_chainsaw_spawn",
	"cricket_bat",
	"crowbar",
	"baseball_bat",
	"electric_guitar",
	"fireaxe",
	"katana",
	"tonfa",
	"golfclub",
	"machete",
	"frying_pan",
	"riotshield"
};

//-----------------------------------------------------------------------------
public OnPluginStart()
{
}

//-----------------------------------------------------------------------------
public OnMapStart()
{
	for(new i=0; i<=12; i++)
		RemoveAllEntitiesByClassname(meleeWeapons[i]);
}

//---------------------------------------------------------------------------
// RemoveAllEntitiesByClassname()
//---------------------------------------------------------------------------
stock RemoveAllEntitiesByClassname(const String:classname[])
{
	new ent = -1;
	new prev = 0;
	while ((ent = FindEntityByClassname(ent, classname)) != -1)
	{
		if (prev) RemoveEdict(prev);
		prev = ent;
	}
	if (prev)
		RemoveEdict(prev);
}
		