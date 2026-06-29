#pragma semicolon 1

/*--------------------------------------------------------------------------------
/ Includes
/-------------------------------------------------------------------------------*/

#include <sourcemod>
#include <sdktools>
#include <sdktools_entinput>

/*--------------------------------------------------------------------------------
/ Globals
/-------------------------------------------------------------------------------*/

#define PLUGIN_NAME "[TF2] Capture Toggle"
#define PLUGIN_VERSION "0.0.3-Log"
#define PLUGIN_AUTHOR "AW 'Swixel' Stanley, DarthNinja, PC Gamer"
#define PLUGIN_URL "https://forums.alliedmods.net"
#define PLUGIN_DESCRIPTION "Enables or Disables the Capturing Objectives."

/*--------------------------------------------------------------------------------
/ Handles
/-------------------------------------------------------------------------------*/

new Handle:g_hArenaAutoDisable;
new Handle:g_hAlwaysDisableMapObjectives;

/*--------------------------------------------------------------------------------
/ Plugin
/-------------------------------------------------------------------------------*/

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

public OnPluginStart ()
{
	// ConVars
	CreateConVar("sm_tf_captoggle", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hArenaAutoDisable = CreateConVar("sm_cap_auto_arena", "0", "Sets whether or not Arena capture points are automatically disabled on round start");
	g_hAlwaysDisableMapObjectives = CreateConVar("sm_cap_always_blocked", "0", "Sets whether or not all map objectives are automatically disabled on map start", 0, true, 0.0, true, 1.0);	

	/// Admin Commands
	RegAdminCmd("sm_cap_enable", Command_EnableObjectives, ADMFLAG_BAN, "Enable Objectives"); 
	RegAdminCmd("sm_cap_disable", Command_DisableObjectives, ADMFLAG_BAN, "Disable Objectives");
	RegAdminCmd("sm_capon", Command_EnableObjectives, ADMFLAG_BAN, "Enable Objectives"); 
	RegAdminCmd("sm_capoff", Command_DisableObjectives, ADMFLAG_BAN, "Disable Objectives");

	// Hook Events
	HookEvent("arena_round_start", Event_ArenaRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookConVarChange(g_hAlwaysDisableMapObjectives, CvarChange);	
}

/*--------------------------------------------------------------------------------
/ Functions
/-------------------------------------------------------------------------------*/

public void OnMapStart()
{
	if(GetConVarInt(g_hAlwaysDisableMapObjectives) == 1)
	{
		ToggleObjectiveState(false);    
	}
}

public Action:OnRoundStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{ 
	if(GetConVarInt(g_hAlwaysDisableMapObjectives) == 1)
	{
		ToggleObjectiveState(false);    
	}
}

public Event_ArenaRoundStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(GetConVarInt(g_hArenaAutoDisable) == 1)
	{
		ToggleObjectiveState(false);    
	}
	if(GetConVarInt(g_hAlwaysDisableMapObjectives) == 1)
	{
		ToggleObjectiveState(false);    
	}
}

public void CvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hAlwaysDisableMapObjectives)
	{
		if(StringToInt(newValue) == 0)
		{
			ToggleObjectiveState(true);
			PrintToChatAll("[SM] Map objectives enabled");
			PrintToServer("[SM] Map objectives enabled");			
			
		}
		else if(StringToInt(newValue) == 1)
		{
			ToggleObjectiveState(false);
			PrintToChatAll("[SM] Map objectives disabled");	
			PrintToServer("[SM] Map objectives disabled");				
		}
	}			
}

ToggleObjectiveState(bool:newState)
{
	/* Things to enable or disable */
	new String:targets[5][25] = {"team_control_point_master","team_control_point","trigger_capture_area","item_teamflag","func_capturezone"};
	new String:input[7] = "Disable";
	if(newState) input = "Enable";

	/* Loop through things that should be enabled/disabled, and push it as an input */
	new ent = 0;
	for (new i = 0; i < 5; i++)
	{
		ent = MaxClients+1;
		while((ent = FindEntityByClassname(ent, targets[i]))!=-1)
		{
			AcceptEntityInput(ent, input);
		}
	}
	LogMessage("[SM] Objective State Now: %sd", input);
}

/*--------------------------------------------------------------------------------
/ Commands
/-------------------------------------------------------------------------------*/

public Action:Command_DisableObjectives(client,args)
{
	LogMessage("[SM] %N has disabled the map objective", client);
	ToggleObjectiveState(false);
	return Plugin_Handled;
}

public Action:Command_EnableObjectives(client,args)
{
	LogMessage("[SM] %N has enabled the map objective", client);
	ToggleObjectiveState(true);
	return Plugin_Handled;
}
