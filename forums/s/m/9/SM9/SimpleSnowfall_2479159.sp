/****************************************************************************************************
	Simple Snowfall
*****************************************************************************************************/

/*
****************************************************************************************************
CHANGELOG
****************************************************************************************************
	0.1 - First Release.
	0.2 - Added better support for TF2.
	0.3 - 
		- Ignore certain maps which would cause an infinite loop while adjusting boundaries, (Use at your own risk on Surf, Bhop, Kz, Arena as I can't guarantee clients won't crash on these.)
		- Added support for maps which already contain rain, snow or other precipitation effects, It should override these with snow now instead of layering 2 effects at once.
*/

#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.3"

public Plugin myinfo = 
{
	name = "Simple Snowfall", 
	author = "SM9(); (xCoderx)", 
	description = "Add an xmas feeling to your maps ;)",
	version = PLUGIN_VERSION
};

int g_iSnow = -1;

float g_fMinBounds[3];
float g_fMaxBounds[3];
float g_fOrigin[3];

char g_szMapPath[128];

char g_szIgnoreMaps[][] = 
{
	"surf_",
	"bhop_",
	"kz_",
	"am_"
}

public void OnPluginStart() {
	HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
	HookEventEx("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
}

public void OnMapEnd()
{
	if(IsValidEntity(g_iSnow) && g_iSnow > 0) {
		AcceptEntityInput(g_iSnow, "Kill");
	}
	
	g_iSnow = -1;
}

public void OnMapStart()
{
	g_iSnow = -1;
	
	char szMapName[64]; GetCurrentMap(szMapName, 64);
	
	Format(g_szMapPath, sizeof(g_szMapPath), "maps/%s.bsp", szMapName);
	PrecacheModel(g_szMapPath, true);
	
	GetEntPropVector(0, Prop_Data, "m_WorldMins", g_fMinBounds);
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", g_fMaxBounds);
	
	bool bIgnoreBoundaryAdjustments = false;
	int iIgnoreList = sizeof(g_szIgnoreMaps);
	
	for (int i = 0; i < iIgnoreList; i++) {
		if(StrContains(szMapName, g_szIgnoreMaps[i], false) != -1) {
			bIgnoreBoundaryAdjustments = true;
			break;
		}
	}
	
	if(!bIgnoreBoundaryAdjustments) {
		while(TR_PointOutsideWorld(g_fMinBounds)) {
			g_fMinBounds[0]++;
			g_fMinBounds[1]++;
			g_fMinBounds[2]++;
		}
		
		while(TR_PointOutsideWorld(g_fMaxBounds)) {
			g_fMaxBounds[0]--;
			g_fMaxBounds[1]--;
			g_fMaxBounds[2]--;
		}
	}
	
	g_fOrigin[0] = (g_fMinBounds[0] + g_fMaxBounds[0]) / 2;
	g_fOrigin[1] = (g_fMinBounds[1] + g_fMaxBounds[1]) / 2;
	g_fOrigin[2] = (g_fMinBounds[2] + g_fMaxBounds[2]) / 2;
	
	CreateSnow();
}

public void Event_RoundStart(Event eEvent, const char[] szName, bool bDontBroadcast) {
	CreateSnow();
}

public void CreateSnow()
{
	bool bSnowValid = false;
	
	if (!IsValidEntity(g_iSnow) || g_iSnow <= 0) {
		g_iSnow = CreateEntityByName("func_precipitation");
	} else {
		bSnowValid = true;
	}
	
	DispatchKeyValue(g_iSnow, "model", g_szMapPath);
	DispatchKeyValue(g_iSnow, "preciptype", "3");
	DispatchKeyValue(g_iSnow, "renderamt", "5");
	DispatchKeyValue(g_iSnow, "density", "75");
	DispatchKeyValue(g_iSnow, "rendercolor", "255 255 255");
	
	SetEntPropVector(g_iSnow, Prop_Send, "m_vecMins", g_fMinBounds);
	SetEntPropVector(g_iSnow, Prop_Send, "m_vecMaxs", g_fMaxBounds);
	TeleportEntity(g_iSnow, g_fOrigin, NULL_VECTOR, NULL_VECTOR);
	
	if(!bSnowValid) {
		DispatchSpawn(g_iSnow);
	}
	
	ActivateEntity(g_iSnow);
}

public void OnEntityCreated(int iEntity, const char[] szClassName)
{
	if(!StrEqual(szClassName, "func_precipitation", false)) {
		return;
	}
	
	SDKHook(iEntity, SDKHook_SpawnPost, SnowSpawned);
}

public void SnowSpawned(int iSnow)
{
	g_iSnow = iSnow;
	CreateSnow();
}