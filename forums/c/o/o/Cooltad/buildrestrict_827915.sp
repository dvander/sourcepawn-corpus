#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "0.5"

#define TF_OBJECT_DISPENSER	0
#define TF_OBJECT_SENTRY		3
#define TF_OBJECT_TELE_ENTR	1
#define TF_OBJECT_TELE_EXIT	2

#define TF_TEAM_BLU					3
#define TF_TEAM_RED					2

public Plugin:myinfo =
{
	name        = "TF2 Build Restrictions",
	author      = "Tsunami",
	description = "Restrict buildings in TF2.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new g_iMaxEntities;
new Handle:g_hEnabled;
new Handle:g_hImmunity;
new Handle:g_hLimits[4][4];

public OnPluginStart()
{
	CreateConVar("sm_buildrestrict_version", PL_VERSION, "Restrict buildings in TF2.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled                                  = CreateConVar("sm_buildrestrict_enabled",                "1", "Enable/disable restricting buildings in TF2.");
	g_hImmunity                                 = CreateConVar("sm_buildrestrict_immunity",               "0", "Enable/disable admin immunity for restricting buildings in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_OBJECT_DISPENSER] = CreateConVar("sm_buildrestrict_blu_dispensers",         "1", "Limit for Blu dispensers in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_OBJECT_SENTRY]    = CreateConVar("sm_buildrestrict_blu_sentries",           "3", "Limit for Blu sentries in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_OBJECT_TELE_ENTR] = CreateConVar("sm_buildrestrict_blu_teleport_entrances", "1", "Limit for Blu teleport entrances in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_OBJECT_TELE_EXIT] = CreateConVar("sm_buildrestrict_blu_teleport_exits",     "1", "Limit for Blu teleport exits in TF2.");
	g_hLimits[TF_TEAM_RED][TF_OBJECT_DISPENSER] = CreateConVar("sm_buildrestrict_red_dispensers",         "1", "Limit for Red dispensers in TF2.");
	g_hLimits[TF_TEAM_RED][TF_OBJECT_SENTRY]    = CreateConVar("sm_buildrestrict_red_sentries",           "3", "Limit for Red sentries in TF2.");
	g_hLimits[TF_TEAM_RED][TF_OBJECT_TELE_ENTR] = CreateConVar("sm_buildrestrict_red_teleport_entrances", "1", "Limit for Red teleport entrances in TF2.");
	g_hLimits[TF_TEAM_RED][TF_OBJECT_TELE_EXIT] = CreateConVar("sm_buildrestrict_red_teleport_exits",     "1", "Limit for Red teleport exits in TF2.");
	g_iMaxEntities                              = GetMaxEntities();
	
	RegConsoleCmd("build", Command_Build, "Restrict buildings in TF2.");
}

public Action:Command_Build(client, args)
{
	if (
	IsClientConnected(client) &&
	IsClientInGame(client) &&
	IsPlayerAlive(client))
	{
		// If plugin is disabled, or immunity is enabled and client is immune, allow building
		if(!GetConVarBool(g_hEnabled) || (GetConVarBool(g_hImmunity) && GetUserFlagBits(client) & (ADMFLAG_GENERIC|ADMFLAG_ROOT)))
			return Plugin_Continue;
	
		// Get first argument
		decl String:sObject[256];
		GetCmdArg(1, sObject, sizeof(sObject));
		
		// Get object type and limit for that object on client's team
		new iObject = StringToInt(sObject),
		iLimit  = GetConVarInt(g_hLimits[GetClientTeam(client)][iObject]);
		
		// If limit is -1, allow building
		if(iLimit == -1)
			return Plugin_Continue;
		// If limit is 0, block building
		else if(iLimit == 0)
			return Plugin_Handled;
		
		decl String:sClassName[32];
		// Loop through all entities, excluding clients and the world
		for(new i = MaxClients + 1, iCount = 0; i < g_iMaxEntities; i++)
		{
			// If entity index is invalid, continue
			if(!IsValidEntity(i))
				continue;
			
			GetEntityNetClass(i, sClassName, sizeof(sClassName));
			// If entity is an object, object type equals the argument, builder equals the client and limit was reached, block building
			if (strncmp(sClassName, "CObject", 7)            == 0       &&
					GetEntProp(i,    Prop_Send, "m_iObjectType") == iObject &&
					GetEntPropEnt(i, Prop_Send, "m_hBuilder")    == client  &&
					++iCount == iLimit)
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}