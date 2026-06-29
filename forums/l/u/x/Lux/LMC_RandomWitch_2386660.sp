#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
//#include <L4D2ModelChanger>

native LMC_SetEntityOverlayModel(iEntity, String:sModel[PLATFORM_MAX_PATH]);// remove this and uncomment out the l4d2modelchanger include to compile with the include

#define PLUGIN_VERSION "1.0"


#define MODEL_1			"models/infected/boomette.mdl"
#define MODEL_2			"models/survivors/survivor_producer.mdl"
#define MODEL_3			"models/survivors/survivor_teenangst.mdl"
#define MODEL_4			"models/survivors/survivor_teenangst_light.mdl"
#define MODEL_5			"models/infected/common_female_tankTop_jeans.mdl"
#define MODEL_6			"models/infected/common_female_tshirt_skirt.mdl"
#define MODEL_7			"models/infected/common_female_tankTop_jeans_rain.mdl"
#define MODEL_8			"models/infected/common_female_tshirt_skirt_swamp.mdl"
#define MODEL_9			"models/infected/common_female_formal.mdl"
#define MODEL_10		"models/infected/common_female_nurse01.mdl"
#define MODEL_11		"models/infected/common_female01.mdl"
#define MODEL_12		"models/infected/common_female_rural01.mdl"


static Handle:hCvar_RandomWitchEnable = INVALID_HANDLE;
static Handle:hCvar_RandomWitchChance = INVALID_HANDLE;

static bool:g_bRandomWitch = false;
static g_iRandomWitchChance = 15;

static bool:bLMC_Available = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	MarkNativeAsOptional("LMC_SetClientOverlayModel");
	MarkNativeAsOptional("LMC_SetEntityOverlayModel");
	MarkNativeAsOptional("LMC_GetEntityOverlayModel");
	MarkNativeAsOptional("LMC_HideClientOverlayModel");
	
	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	bLMC_Available = LibraryExists("L4D2ModelChanger");
	if(!bLMC_Available)
		LogError("Can't Find L4D2ModelChanger, install L4D2ModelChanger for this plugin to function.");
}

public OnLibraryAdded(const String:sName[])
{
	if(StrEqual(sName, "L4D2ModelChanger"))
		bLMC_Available = true;
	PrintToServer("LMC detected Lets get back to work.");
}

public OnLibraryRemoved(const String:sName[])
{
	if(StrEqual(sName, "L4D2ModelChanger"))
		bLMC_Available = false;
	PrintToServer("Disabling LMC_RandomWitch Reason L4D2ModelChanger Libary does not exist no more");
}

public Plugin:myinfo = 
{
	name = "LMC_RandomWitch",
	author = "Lux",
	description = "Adds a Random model to the witch LMC required",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2449184#post2449184"
}

#define AUTO_EXEC false
public OnPluginStart()
{
	CreateConVar("lmc_randomwitch_version", PLUGIN_VERSION, "Version of RandomWitch", FCVAR_SPONLY|FCVAR_DONTRECORD);

	hCvar_RandomWitchEnable = CreateConVar("lmc_randomwitch", "1", "Should We Enable Random Witch", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_RandomWitchChance = CreateConVar("lmc_randomwitchchance", "25", "Chance out of 100 to have a overlay model, (0, 100)", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	HookConVarChange(hCvar_RandomWitchEnable, eConvarsChanged);
	HookConVarChange(hCvar_RandomWitchChance, eConvarsChanged);
	
	CvarsChanged();
	
	#if AUTO_EXEC
	AutoExecConfig(true, "LMC_RandomWitch");
	#endif
	HookEvent("witch_spawn", eWitchSpawn);
}

public OnMapStart()
{
	CvarsChanged();
}

public eConvarsChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_bRandomWitch = GetConVarInt(hCvar_RandomWitchEnable) > 0;
	g_iRandomWitchChance = GetConVarInt(hCvar_RandomWitchChance);
}

public eWitchSpawn(Handle:hEvent, const String:sWitchID[], bool:bdontBroadcast)
{	
	if(!g_bRandomWitch || !bLMC_Available)
		return;
	
	if(GetRandomInt(1, 100) > g_iRandomWitchChance)
		return;
	
	static iWitch;
	iWitch = GetEventInt(hEvent, "witchid");
	
	if(iWitch < MaxClients+1 || iWitch > 2048 || !IsValidEntity(iWitch))
		return;
	
	switch(GetRandomInt(0, 11))
	{
		case 0:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_1);
		}
		case 1:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_2);
		}
		case 2:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_3);
		}
		case 3:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_4);
		}
		case 4:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_5);
		}
		case 5:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_6);
		}
		case 6:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_7);
		}
		case 7:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_8);
		}
		case 8:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_9);
		}
		case 9:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_10);
		}
		case 10:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_11);
		}
		case 11:{
		LMC_SetEntityOverlayModel(iWitch, MODEL_12);
		}
	}
}


