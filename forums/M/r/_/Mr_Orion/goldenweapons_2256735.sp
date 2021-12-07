#pragma semicolon 1

#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <tf2items>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
    name 		=		"[TF2] Golden Weapons",
    author		=		"11530, redone by Orion",
    description	=		"Weapons are made golden.",
    version		=		PLUGIN_VERSION,
    url			=		"http://www.sourcemod.net"
};

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hAdminOnly = INVALID_HANDLE;
new Handle:g_hGoldenItem = INVALID_HANDLE;

new bool:g_bEnabled;
new bool:g_bAdminOnly;

public OnPluginStart()
{
	CreateConVar("sm_goldenstocks_version", PLUGIN_VERSION, "\"Golden Stocks\" Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("sm_goldenweapons_enabled", "1", "0 = Disable plugin, 1 = Enable plugin", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	g_hAdminOnly = CreateConVar("sm_goldenweapons_adminonly", "1", "0 = Everyone, 1 = Admin only", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hAdminOnly, ConVarAdminOnlyChanged);
	g_bAdminOnly = GetConVarBool(g_hAdminOnly);

	g_hGoldenItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
	TF2Items_SetNumAttributes(g_hGoldenItem, 1);
	TF2Items_SetAttribute(g_hGoldenItem, 0, 150, 1.0);
}

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);
}

public ConVarAdminOnlyChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bAdminOnly = (StringToInt(newvalue) == 0 ? false : true);
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if (g_bEnabled)
	{
		if (iItemDefinitionIndex >= 0 && iItemDefinitionIndex < 1153)
		{
			if (!g_bAdminOnly || (CheckCommandAccess(client, "goldenweapons_override", ADMFLAG_SLAY)))
			{				
				hItem = g_hGoldenItem;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}