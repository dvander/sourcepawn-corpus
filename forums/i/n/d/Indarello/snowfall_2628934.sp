#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"


Handle H_preciptype;
Handle H_density;
Handle H_color;
Handle H_render;

char preciptype[24];
char density[24];
char thecolor[24];
char render[24];

float m_vecOrigin[3];
float maxbounds[3];
float minbounds[3];

char PrecipitationModel[128];

bool enable;

public Plugin myinfo =
{
	name = "SM Snowfall (Precipitation)",
	author = "Franc1sco franug",
	description = "Add precipitations to the maps",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	CreateConVar("sm_snowfall_version", PLUGIN_VERSION, "version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEventEx("round_start", Event_RoundStart);
	HookEventEx("teamplay_round_start", Event_RoundStart);

	H_preciptype = CreateConVar("sm_snowfall_type", "7", "Type of the precipitation");
	H_density = CreateConVar("sm_snowfall_density", "75", "Density of the precipitation");
	H_color = CreateConVar("sm_snowfall_color", "255 255 255", "Color of the precipitation");
	H_render = CreateConVar("sm_snowfall_renderamt", "5", "Render of the precipitation");
	
	HookConVarChange(H_preciptype, CVarChange);
	HookConVarChange(H_density, CVarChange);
	HookConVarChange(H_color, CVarChange);
	HookConVarChange(H_render, CVarChange);
	
	GetCVars();
	
	RegAdminCmd ("sm_getabs", ClientExec, ADMFLAG_RCON);
}


public CVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

void GetCVars()
{
	GetConVarString(H_preciptype, preciptype, sizeof(preciptype));
	GetConVarString(H_density, density, sizeof(density));
	GetConVarString(H_color, thecolor, sizeof(thecolor));
	GetConVarString(H_render, render, sizeof(render));
}

public Action:ClientExec (client, args)
{
	new Float:VictimPos[3];
	GetClientAbsOrigin(client,VictimPos);
	PrintToChatAll("[%0.1f][%0.1f][%0.1f]", VictimPos[0], VictimPos[1], VictimPos[2]);
	return Plugin_Handled;
}

public void OnMapStart()
{
	char MapName[64]; 
	GetCurrentMap(MapName, 64);
	
	enable = true;
	
	Format(PrecipitationModel, sizeof(PrecipitationModel), "maps/%s.bsp", MapName);
	PrecacheModel(PrecipitationModel, true);

	if(StrContains(MapName, "de_dust2") != -1)
	{
		minbounds = Float:{-2201.0, -1544.0, -120.0};
		maxbounds = Float:{1505.7, 3095.4, 610.1};
	}
	else if(StrContains(MapName, "cs_insertion") != -1)
	{
		minbounds = Float:{-3939.5, -2297.8, -158.5};
		maxbounds = Float:{5301.0, 2231.6, 634.8};
	}
	else if(StrContains(MapName, "de_mirage") != -1)
	{
		minbounds = Float:{-2634.5, -2520.2, -274.8};
		maxbounds = Float:{1333.6, 928.3, 278.6};
	}
	else if(StrContains(MapName, "cs_assault") != -1)
	{	
		minbounds = Float:{4356.8, 3872.9, -864.9};
		maxbounds = Float:{7892.3, 7213.9, -30.1};
	}
	else enable = false;
	
	m_vecOrigin[0] = (minbounds[0] + maxbounds[0]) / 2;
	m_vecOrigin[1] = (minbounds[1] + maxbounds[1]) / 2;
	m_vecOrigin[2] = (minbounds[2] + maxbounds[2]) / 2;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (!enable)return;
	
	ClearPrecipitations();
	
	new ent = CreateEntityByName("func_precipitation");
	DispatchKeyValue(ent, "model", PrecipitationModel);
	DispatchKeyValue(ent, "preciptype", preciptype);
	DispatchKeyValue(ent, "renderamt", render);
	DispatchKeyValue(ent, "density", density);
	DispatchKeyValue(ent, "rendercolor", thecolor);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);    
	//PrintToChatAll("[%0.1f][%0.1f][%0.1f] [%0.1f][%0.1f][%0.1f]", minbounds[0], minbounds[1], minbounds[2], maxbounds[0], maxbounds[1], maxbounds[2]);
	TeleportEntity(ent, m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
}

ClearPrecipitations()
{
	new index = -1;
	while ((index = FindEntityByClassname2(index, "func_precipitation")) != -1)
		AcceptEntityInput(index, "Kill");	
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;

	return FindEntityByClassname(startEnt, classname);
}
