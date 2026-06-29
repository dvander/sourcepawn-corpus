#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"
static bool IsFinale;

public Plugin:myinfo = 
{
	name = "Unlock screen freeze",
	author = "ZBzibing",
	description = "After the rescue was initiated, all players failed. When restarting, the perspective of the bystander was permanently frozen.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2766144"
};

new Handle:Remove_camerafinale;

public OnPluginStart()
{
	CreateConVar("sm_REC_version", PLUGIN_VERSION, "Plugins Version",     FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Remove_camerafinale = CreateConVar("l4d_REC_Swich", "1", "Plug-in switch.0:off 1:on", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEventEx("round_start", REC, EventHookMode_Post);
}

public Action:REC(Handle:event,const String:name[],bool:dontBroadcast)
{
	 IsFinale = FindEntityByClassname(-1, "trigger_finale") != INVALID_ENT_REFERENCE;
	if (!GetConVarBool(Remove_camerafinale))
	{
		return Plugin_Continue;
	}
	new maxent = GetMaxEntities(), String:Removeview[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, Removeview, sizeof(Removeview));
			if ( ( StrContains(Removeview, "point_viewcontrol")) != -1 || StrContains(Removeview, "point_deathfall_camera") != -1 )
			if (IsFinale == true || IsBuggedMap())
   		{
        //PrintToChatAll("\x04[SM] Audience freeze view is unlocked!");
        RemoveEdict(i);
    }
			
		}
	}	
	return Plugin_Continue;
}

bool IsBuggedMap()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if ( StrEqual(sMap, "l4d_hospital04_interior", false) 
	|| StrEqual(sMap, "l4d_hospital05_rooftop", false) 
	|| StrEqual(sMap, "l4d_garage02_lots", false) 
	|| StrEqual(sMap, "l4d_smalltown05_houseboat", false) 
	|| StrEqual(sMap, "l4d_airport05_runway", false) 
	|| StrEqual(sMap, "l4d_farm01_hilltop", false) 
	|| StrEqual(sMap, "l4d_farm05_cornfield", false) 
	|| StrEqual(sMap, "l4d_river03_port", false)
	|| StrEqual(sMap, "tutorial_standards", false) 
		)
	{
		return true;
	}
		return false;
}
