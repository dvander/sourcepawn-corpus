#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#define PLUGIN_VERSION "1.0"
static bool IsFinale;

public Plugin myinfo = 
{
	name = "Unlock screen freeze",
	author = "ZBzibing",
	description = "After the rescue was initiated, all players failed. When restarting, the perspective of the bystander was permanently frozen.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2766144"
};

Handle Remove_camerafinale;

public void OnPluginStart()
{
	CreateConVar("sm_REC_version", PLUGIN_VERSION, "Plugins Version",     0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Remove_camerafinale = CreateConVar("l4d_REC_Swich", "1", "Plug-in switch.0:off 1:on", 0|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEventEx("round_start", REC, EventHookMode_Post);
}

public Action REC(Event event, const char[] name, bool dontBroadcast)
{
	IsFinale = FindEntityByClassname(-1, "trigger_finale") != INVALID_ENT_REFERENCE;
	if (!GetConVarBool(Remove_camerafinale))
	{
		return Plugin_Continue;
	}
	int maxent = GetMaxEntities();
	char Removeview[64];
	for (int i=MaxClients+1;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, Removeview, sizeof(Removeview));
			if ( ( strncmp(Removeview, "point_viewcontrol", 17)) == 0 || strcmp(Removeview, "point_deathfall_camera") == 0 ) 
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
	if ( StrEqual(sMap, "c1m4_atrium", false) 
	|| StrEqual(sMap, "c2m5_concert", false) 
	|| StrEqual(sMap, "c3m4_plantation", false) 
	|| StrEqual(sMap, "c4m5_milltown_escape", false) 
	|| StrEqual(sMap, "c5m5_bridge", false) 
	|| StrEqual(sMap, "c6m3_port", false) 
	|| StrEqual(sMap, "c7m3_port", false) 
	|| StrEqual(sMap, "c8m5_rooftop", false)
	|| StrEqual(sMap, "c9m2_lots", false)
	|| StrEqual(sMap, "c10m5_houseboat", false)
	|| StrEqual(sMap, "c11m5_runway", false)
	|| StrEqual(sMap, "c12m5_cornfield", false)
	|| StrEqual(sMap, "c13m4_cutthroatcreek", false)
	|| StrEqual(sMap, "c14m2_lighthouse", false)
		)
	{
		return true;
	}
	return false;
}
