#include <sourcemod>
#include <sdktools>

#define VERSION "1.3"

new maxt = 0;
new maxct = 0;

new Handle:Cvar_Version = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "SpawnPoint generator",
	author = "AnorexiasGrizzli",
	description = "This plugin automatically generates new spawn points bypassing team is full errors.",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	Cvar_Version = CreateConVar("sm_spg_version", VERSION, "SpawnPoint Generator Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	
	HookConVarChange(Cvar_Version, VersionChange);
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, VERSION);
}

public OnMapStart()
{
	maxt=0;
	maxct=0;

	new ent=-1;
	while ((ent = FindEntityByClassname2(ent, "info_player_terrorist")) != -1)
	{
		maxt++;
	}

	ent=-1;
	while ((ent = FindEntityByClassname2(ent, "info_player_counterterrorist")) != -1)
	{
		maxct++;
	}

	if((maxct+maxt)<MaxClients)
	{
		GenerateSpawnPoints();
		new Handle:noblock = INVALID_HANDLE;
		noblock = FindConVar("sm_noblock")
		
		if(noblock != INVALID_HANDLE)
		{
			SetConVarInt(noblock, 1, true, true);
		}
	}
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
 
public GenerateSpawnPoints()
{
	new Float:q=float(MaxClients)/(float(maxt)+float(maxct));
	new Float:newt=float(maxt)*q;
	new Float:newct=float(maxct)*q;
	new i = 0;
	new tspawn = -1;
	while((tspawn = FindEntityByClassname2(tspawn, "info_player_terrorist")) != -1)
	{
		if(i<(RoundToNearest(newt)-maxt))
		{
			new Float:position[3];
			FindEntityByClassname2(i, "info_player_terrorist");
			GetEntPropVector(tspawn, Prop_Send, "m_vecOrigin", position);
			new newtspawn = CreateEntityByName("info_player_terrorist");
			DispatchSpawn(newtspawn);
			TeleportEntity(newtspawn, position, NULL_VECTOR, NULL_VECTOR);
			i++;
		}
	}
	i=0;
	new ctspawn = -1;
	while((ctspawn = FindEntityByClassname2(ctspawn, "info_player_counterterrorist")) != -1)
	{
		if(i<(RoundToNearest(newct)-maxct))
		{
			new Float:position[3];
			FindEntityByClassname2(i, "info_player_counterterrorist");
			GetEntPropVector(ctspawn, Prop_Send, "m_vecOrigin", position);
			new newctspawn = CreateEntityByName("info_player_counterterrorist");
			DispatchSpawn(newctspawn);
			TeleportEntity(newctspawn, position, NULL_VECTOR, NULL_VECTOR);
			i++;
		}
	}
}