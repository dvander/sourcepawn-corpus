#define PLUGIN_VERSION "1.0"
#pragma semicolon 1
public Plugin:myinfo =
{
	name = "[Any] Target Admins",
	author = "ChauffeR",
	description = "Allows admins to target admins.",
	version = PLUGIN_VERSION,
};

public OnPluginStart()
{
	CreateConVar("sm_target_admins_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AddMultiTargetFilter("@admins", ProcessAdmins, "Admins", false);
}

public bool:ProcessAdmins(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetAdminFlag(GetUserAdmin(i), Admin_Generic))
			PushArrayCell(clients, i);
	}
	return true;
}