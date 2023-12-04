#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[L4D2] Navigation Loot Spawner",
	author = "BHaType",
	description = "Spawn random props",
	version = "0.4",
	url = "SDKCall"
};

static const char szWeapons[][] =
{
    "models/props_vehicles/cara_69sedan.mdl",
    "models/props_vehicles/cara_82hatchback.mdl",
    "models/props_vehicles/cara_84sedan.mdl",
	"models/props_vehicles/cara_95sedan.mdl",
};

static const int gChances[] =
{
	100,	//weapon_rifle_ak47
	100,	//weapon_smg
	100,	//weapon_sniper_awp
	100,	//weapon_sniper_military
	100,	//weapon_sniper_scout
	100,	//weapon_chainsaw
	100,	//weapon_adrenaline
};

ConVar g_hLootCount, g_hNavBits, g_hCheckReacheble;
bool g_bLoaded, g_bLateload;
Address TheNavAreas;
int TheCount, g_iLootCount, g_iNavFlagsCheck, g_iReachebleCheck;
Handle g_hReachableCheck;

public APLRes AskPluginLoad2(Handle hPlugin, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hLootCount = CreateConVar("sm_nav_loot_spawner_count", "10", "How many loot we spawn?", FCVAR_NONE);
	g_hNavBits = CreateConVar("sm_nav_loot_spawn_flags", "0", "Should we spawn loot in flags zones?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCheckReacheble = CreateConVar("sm_nav_loot_check_position_reacheble", "0", "Should we check position reachebly? (Windows only)", FCVAR_NONE, true, 0.0, true, 1.0);
	
	g_hLootCount.AddChangeHook(OnConVarChanged);
	g_hNavBits.AddChangeHook(OnConVarChanged);
	g_hCheckReacheble.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, "l4d2_nav_loot_spawner");
	
	g_iLootCount = g_hLootCount.IntValue;
	g_iNavFlagsCheck = g_hNavBits.IntValue;
	g_iReachebleCheck = g_hCheckReacheble.IntValue;
}

public void OnConVarChanged(Handle hConVar, const char[] oldValue, const char[] newValue)
{
	g_iLootCount = g_hLootCount.IntValue;
	g_iNavFlagsCheck = g_hNavBits.IntValue;
	g_iReachebleCheck = g_hCheckReacheble.IntValue;
}

public void OnMapStart()
{
	PrecacheModel("models/props_vehicles/cara_69sedan.mdl", true);
    PrecacheModel("models/props_vehicles/cara_82hatchback.mdl", true);
    PrecacheModel("models/props_vehicles/cara_84sedan.mdl", true);
	PrecacheModel("models/props_vehicles/cara_95sedan.mdl", true);
	
	GameData hData = new GameData("l4d2_nav_loot");
	
	TheNavAreas = hData.GetAddress("TheNavAreas");
	TheCount = 1500;
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "SurvivorBot::IsReachable");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hReachableCheck = EndPrepSDKCall();
	
	delete hData;
	
	if (TheNavAreas == Address_Null || !TheCount)
		SetFailState("[Navigation Spawner] Bad data, please check your gamedata");
	
	HookEvent("round_start", eEvent);
	
	g_bLoaded = true;
	
	AutoExecConfig(true, "l4d2_nav_loot_spawner");
	
	if (!g_bLateload)
		CreateTimer(12.5, tSpawn);
	else
		CreateRandomLoot(g_iLootCount);
}

public Action tSpawn (Handle timer)
{
	CreateRandomLoot(g_iLootCount);
}

public void OnMapEnd()
{
	g_bLoaded = false;
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	if (!g_bLoaded)
		return;
	
	CreateTimer(12.4, tSpawn);
}

void CreateRandomLoot (int count)
{
	Address iRandomArea;
	int entity;
	float vMins[3], vMaxs[3], vOrigin[3], vAngles[3];
	bool bContinue;
	
	for (int i = 1; i <= count; i++)
	{
		iRandomArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(4 * GetRandomInt(0, TheCount)), NumberType_Int32));
		
		if (iRandomArea == Address_Null || (g_iNavFlagsCheck && LoadFromAddress(iRandomArea + view_as<Address>(84), NumberType_Int32) != 0x20000000))
			continue;
		
		vMins[0] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(4), NumberType_Int32));
		vMins[1] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(8), NumberType_Int32));
		vMins[2] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(12), NumberType_Int32));
		
		vMaxs[0] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(16), NumberType_Int32));
		vMaxs[1] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(20), NumberType_Int32));
		vMaxs[2] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(24), NumberType_Int32));

		AddVectors(vMins, vMaxs, vOrigin);
		ScaleVector(vOrigin, 0.5);
		
		
		vAngles[1] = GetRandomFloat(-179.0, 179.0);
		
		int iRandom = GetRandomInt(0, sizeof szWeapons - 1);
		
		if (GetRandomInt(0, 100) > gChances[iRandom])
			continue;
		
		if (iRandom != 41) 
			vOrigin[2] += 14.5;

		
		entity = CreateEntityByName("prop_physics_override");
		
		if (entity <= MaxClients)
			continue;
		
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		DispatchKeyValue(entity, "model", szWeapons[iRandom]);
		DispatchSpawn(entity);
		
		//PrintToServer("Spawned weapon at %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2]);
	}
}