#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.4"

public Plugin:myinfo =
{
        name = "[ND] Resource Management",
        author = "databomb",
        description = "Provides (non-cheat) cvars and resource management commands.",
        version = VERSION,
        url = "vintagejailbreak.org"
};

new g_iConsort;
new g_iEmpire;

new Handle:gH_Cvar_ConsortResources = INVALID_HANDLE;
new Handle:gH_Cvar_EmpireResources = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_checkresources", CheckResources, ADMFLAG_KICK, "Returns the current resources for both teams");
	RegAdminCmd("sm_setresources", SetResources, ADMFLAG_BAN, "Sets a teams resource");
	gH_Cvar_ConsortResources = CreateConVar("sm_starting_resources_consort", "10000", "Starting resources to give Consortium team", FCVAR_PLUGIN, true, 0.0, true, 250000.0);
	gH_Cvar_EmpireResources = CreateConVar("sm_starting_resources_empire", "8000", "Starting resources to give Empire team", FCVAR_PLUGIN, true, 0.0, true, 250000.0);
	CreateConVar("sm_resource_management_ver", VERSION, "Resource Management Version",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("round_start", Round_Started);
	
	new Handle:h_Resources = FindConVar("nd_starting_resources");
	SetConVarInt(h_Resources, 1337);
}

public Round_Started(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, Timer_SetResources);
}

public OnMapStart()
{
	g_iConsort = FindEntityByClassname(-1, "nd_team_consortium");
	g_iEmpire = FindEntityByClassname(-1, "nd_team_empire");
}

public Action:Timer_SetResources(Handle:timer)
{
	new iResourcesEmpire = GetConVarInt(gH_Cvar_EmpireResources);
	new iResourcesConsortium = GetConVarInt(gH_Cvar_ConsortResources);
	PrintToChatAll("Balancing Starting Resources | Empire %d | Consortium %d", iResourcesEmpire, iResourcesConsortium);

	SetEntProp(g_iConsort, Prop_Send, "m_iResourcePoints", iResourcesConsortium);
	SetEntProp(g_iEmpire, Prop_Send, "m_iResourcePoints", iResourcesEmpire);

	return Plugin_Handled;
}

public Action:CheckResources(client, args)
{
	ReplyToCommand(client, "Consort %d | Empire %d", GetEntProp(g_iConsort, Prop_Send, "m_iResourcePoints"), GetEntProp(g_iEmpire, Prop_Send, "m_iResourcePoints"));

	return Plugin_Handled;
}

public Action:SetResources(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "Usage: nd_setresources <team:all,empire,consortium> <resource amount>");
		return Plugin_Handled;
	}


	new String:sTeam[256];
	// temporarily use sTeam for other purposes
	GetCmdArg(2, sTeam, sizeof(sTeam));
	new iResources = StringToInt(sTeam);
	if (iResources < 0 || iResources > 250000)
	{
		ReplyToCommand(client, "Invalid resource amount: %d. Enter a value between 0 and 250,000", iResources);
		return Plugin_Handled;
	}

	GetCmdArg(1, sTeam, sizeof(sTeam));
	if (!strcmp(sTeam, "all", false))
	{
		SetEntProp(g_iConsort, Prop_Send, "m_iResourcePoints", iResources);
		SetEntProp(g_iEmpire, Prop_Send, "m_iResourcePoints", iResources);
	}
	else if (!strcmp(sTeam, "consortium", false))
	{
		SetEntProp(g_iConsort, Prop_Send, "m_iResourcePoints", iResources);
	}
	else if (!strcmp(sTeam, "empire", false))
	{
		SetEntProp(g_iEmpire, Prop_Send, "m_iResourcePoints", iResources);
	}
	else
	{
		ReplyToCommand(client, "Invalid team name: %s. Enter 'all', 'empire', or 'consortium'", sTeam);
		return Plugin_Handled;
	}

	LogAction(client, -1, "%N changed team (%s) resources to %d", client, sTeam, iResources);
	ShowActivity2(client, "[SM] ", "Changed %s resources to %d", sTeam, iResources);
	return Plugin_Handled;
}
