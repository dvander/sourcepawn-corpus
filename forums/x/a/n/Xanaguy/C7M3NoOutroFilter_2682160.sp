#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "No Outro Filter for The Sacrifice",
	author = "Xanaguy",
	description = "Removes the yellow color_correction entity from the outro",
	version = "1.1",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("c7m3_no_outrofilter", "1.0", "The Sacrifice No Outro Filter Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapStart()
{
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if(StrEqual(mapname, "c7m3_port"))
	{
		new filter = FindEntityByName("colorcorrection_outro", -1);
		
		AcceptEntityInput(filter, "Kill");
	}
}

stock FindEntityByName(String:name[], any:startcount)
{
	decl String:classname[128];
	new maxentities = GetMaxEntities();
	
	for (new i = startcount; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEdictClassname(i, classname, 128);
		
		if (FindDataMapOffs(i, "m_iName") == -1) continue;
		
		decl String:iname[128];
		GetEntPropString(i, Prop_Data, "m_iName", iname, sizeof(iname));
		if (strcmp(name, iname, false) == 0) return i;
	}
	return -1;
}