#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:g_hCvarEnabled,				bool:g_bCvarEnabled;

new Handle:g_hCvarSentryEnabled,		bool:g_bCvarSentryEnabled;
new Handle:g_hCvarDispenserEnabled,		bool:g_bCvarDispenserEnabled;
new Handle:g_hCvarTeleEnabled,			bool:g_bCvarTeleEnabled;

new Handle:g_hCvarBuildingSizeMax,		Float:g_flCvarBuildingSizeMax;
new Handle:g_hCvarBuildingSizeMin,		Float:g_flCvarBuildingSizeMin;

#define PLUGIN_VERSION			"2.0"

public Plugin:myinfo =
{
	name = "Building Size Randomizer",
	author = "Pelipoika",
	description = "Upon building placed, gives it a random size",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
//	In case you're wondering why on earth do i keep these old cvar codes here, i like nostalgic things.
//	HookConVarChange(g_hCvarEnabled = CreateConVar("sm_buildingresizer_enabled", "1.0", "Enable Randomly scaled buildings\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0), OnConVarChange);
	
	g_hCvarEnabled = CreateConVar("sm_buildingresizer_enabled", "1.0", "Enable Randomly scaled buildings\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);
	
//	HookConVarChange(g_hCvarSentryEnabled = CreateConVar("sm_resizesentry_enabled", "1.0", "Resize Sentry\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0), OnConVarChange);

	g_hCvarSentryEnabled = CreateConVar("sm_resizesentry_enabled", "1.0", "Resize Sentry\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarSentryEnabled = GetConVarBool(g_hCvarSentryEnabled);
	HookConVarChange(g_hCvarSentryEnabled, OnConVarChange);
	
//	HookConVarChange(g_hCvarDispenserEnabled = CreateConVar("sm_resizedispenser_enabled", "1.0", "Resize Dispenser\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0), OnConVarChange);

	g_hCvarDispenserEnabled = CreateConVar("sm_resizedispenser_enabled", "1.0", "Resize Dispenser\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarDispenserEnabled = GetConVarBool(g_hCvarDispenserEnabled);
	HookConVarChange(g_hCvarDispenserEnabled, OnConVarChange);
	
//	HookConVarChange(g_hCvarTeleEnabled = CreateConVar("sm_resizeteleporter_enabled", "1.0", "Resize Teleporter\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0), OnConVarChange);
	
	g_hCvarTeleEnabled = CreateConVar("sm_resizeteleporter_enabled", "1.0", "Resize Teleporter\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarTeleEnabled = GetConVarBool(g_hCvarTeleEnabled);
	HookConVarChange(g_hCvarTeleEnabled, OnConVarChange);
	
//	HookConVarChange(g_hCvarBuildingSizeMin = CreateConVar("sm_building_minsize", "0.6", "Min size the building can randomly be scaled to", FCVAR_PLUGIN, true, 0.0), OnConVarChange);
	
	g_hCvarBuildingSizeMin = CreateConVar("sm_building_minsize", "0.6", "Min size the building can randomly be scaled to", FCVAR_PLUGIN, true, 0.0);
	g_flCvarBuildingSizeMin = GetConVarFloat(g_hCvarBuildingSizeMin);
	HookConVarChange(g_hCvarBuildingSizeMin, OnConVarChange);
	
//	HookConVarChange(g_hCvarBuildingSizeMax = CreateConVar("sm_building_maxsize", "2.0", "Max size the building can randomly be scaled to", FCVAR_PLUGIN, true, 0.0), OnConVarChange);

	g_hCvarBuildingSizeMax = CreateConVar("sm_building_maxsize", "2.0", "Max size the building can randomly be scaled to", FCVAR_PLUGIN, true, 0.0);
	g_flCvarBuildingSizeMax = GetConVarFloat(g_hCvarBuildingSizeMax);
	HookConVarChange(g_hCvarBuildingSizeMax, OnConVarChange);
	
	HookEvent("player_builtobject", Event_Player_BuiltObject, EventHookMode_Post);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	GetNewValues();
}

GetNewValues()	//Not the best but at least an improvement right?
{
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	
	g_bCvarSentryEnabled = GetConVarBool(g_hCvarSentryEnabled);
	g_bCvarDispenserEnabled = GetConVarBool(g_hCvarDispenserEnabled);
	g_bCvarTeleEnabled = GetConVarBool(g_hCvarTeleEnabled);
				
	g_flCvarBuildingSizeMax = GetConVarFloat(g_hCvarBuildingSizeMax);
	g_flCvarBuildingSizeMin = GetConVarFloat(g_hCvarBuildingSizeMin);
}

public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bCvarEnabled) 
			return Plugin_Continue;
		
	new index = GetEventInt(event, "index");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!CheckCommandAccess(client, "sm_resizebuilding_access", 0))
	{
		return Plugin_Handled;
	}
	
	decl String:classname[32];
	GetEdictClassname(index, classname, sizeof(classname));
	
	if(strcmp("obj_dispenser", classname) == 0)
	{
		if(!g_bCvarDispenserEnabled) 
			return Plugin_Continue;
	}
	if(strcmp("obj_sentrygun", classname) == 0)
	{
		if(!g_bCvarSentryEnabled) 
			return Plugin_Continue;
	}
	if(strcmp("obj_teleporter", classname) == 0)
	{
		if(!g_bCvarTeleEnabled) 
			return Plugin_Continue;
	}
	SetEntPropFloat(index, Prop_Send, "m_flModelScale", GetRandomFloat(g_flCvarBuildingSizeMax, g_flCvarBuildingSizeMin));
	return Plugin_Handled;
}