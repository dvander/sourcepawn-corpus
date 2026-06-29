#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1b"


new Handle:H_preciptype;
new Handle:H_density;
new Handle:H_color;

public Plugin:myinfo =
{
	name = "SM Snowfall",
	author = "Franc1sco Steam: franug",
	description = "snowfall on some maps",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnMapStart()
{
	CreateConVar("sm_snowfall_version", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("round_start", Event_RoundStart);

        H_preciptype = CreateConVar("sm_snowfall_type", "3", "Type of the precipitation");
        H_density = CreateConVar("sm_snowfall_density", "5", "Density of the precipitation");
        H_color = CreateConVar("sm_snowfall_color", "255 255 255", "Color of the precipitation");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	decl String:MapName[128];
	decl String:buffer[128];
	decl String:pre[128];
	decl String:den[128];
	decl String:col[128];

        GetConVarString(H_preciptype, pre, sizeof(pre));
        GetConVarString(H_density, den, sizeof(den));
        GetConVarString(H_color, col, sizeof(col));


	GetCurrentMap(MapName, sizeof(MapName));
	Format(buffer, sizeof(buffer), "maps/%s.bsp", MapName);
	new ent = CreateEntityByName("func_precipitation");
	DispatchKeyValue(ent, "model", buffer);
	DispatchKeyValue(ent, "preciptype", pre);
	DispatchKeyValue(ent, "renderamt", den);
	DispatchKeyValue(ent, "rendercolor", col);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	new Float:minbounds[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMins", minbounds); 
	new Float:maxbounds[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", maxbounds); 	
	
	SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);    
	new Float:m_vecOrigin[3];
	m_vecOrigin[0] = (minbounds[0] + maxbounds[0])/2;
	m_vecOrigin[1] = (minbounds[1] + maxbounds[1])/2;
	m_vecOrigin[2] = (minbounds[2] + maxbounds[2])/2;
	TeleportEntity(ent, m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
}

