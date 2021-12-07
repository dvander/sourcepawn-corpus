#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[L4D2] Tank By Threat",
	author = "BHaType",
	description = "Spawn tank through nav threat",
	version = "0.0",
	url = "SDKCall"
};

Address TheNavAreas;
int TheCount, g_iTanks;
bool g_bLoaded;
ConVar g_hTanks;

public void OnPluginStart()
{
	g_hTanks = CreateConVar("sm_tank_count", "2", "Count of tanks", FCVAR_NONE);
	
	AutoExecConfig(true, "l4d_tank_by_threat");
	
	g_iTanks = g_hTanks.IntValue;
	g_hTanks.AddChangeHook(OnConVarChanged);
	
	HookEvent("round_start_post_nav", eEvent, EventHookMode_PostNoCopy);
}

public void OnConVarChanged(Handle hConVar, const char[] oldValue, const char[] newValue)
{
	g_iTanks = g_hTanks.IntValue;
}

public void OnMapStart()
{
	GameData hData = new GameData("l4d2_nav_loot");
	
	TheNavAreas = hData.GetAddress("TheNavAreas");
	TheCount = LoadFromAddress(hData.GetAddress("TheCount"), NumberType_Int32);
	
	delete hData;
	
	if (TheNavAreas == Address_Null || !TheCount)
		SetFailState("[Navigation Spawner] Bad data, please check your gamedata");
		
	CreateTimer(8.0, tTimer);
	g_bLoaded = true;
}

public void OnMapEnd()
{
	g_bLoaded = false;
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	if (g_bLoaded)
		CreateTimer(2.0, tTimer);
}

public Action tTimer (Handle timer)
{
	Start();
}

void Start()
{
	int iCounter;
	Address[] iThreat = new Address[TheCount / 4];

	Address iArea;
	float vOrigin[3], vMins[3], vMaxs[3];
	
	for (int i = 1; i <= TheCount; i++)
	{
		iArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(4 * GetRandomInt(50, TheCount)), NumberType_Int32));
		
		if (iArea == Address_Null || LoadFromAddress(iArea + view_as<Address>(84), NumberType_Int32) != 0x20000000)
			continue;
		
		if (iCounter > TheCount / 4)
			break;
		
		if (LoadFromAddress(iArea + view_as<Address>(301), NumberType_Int32) & 0x40)
		{
			iThreat[iCounter] = iArea;
			iCounter++;
		}
	}
	
	for (int i = 1; i <= g_iTanks; i++) 
	{
		iArea = iThreat[GetRandomInt(0, iCounter)];
		
		vMins[0] = view_as<float>(LoadFromAddress(iArea + view_as<Address>(4), NumberType_Int32));
		vMins[1] = view_as<float>(LoadFromAddress(iArea + view_as<Address>(8), NumberType_Int32));
		vMins[2] = view_as<float>(LoadFromAddress(iArea + view_as<Address>(12), NumberType_Int32));
		
		vMaxs[0] = view_as<float>(LoadFromAddress(iArea + view_as<Address>(16), NumberType_Int32));
		vMaxs[1] = view_as<float>(LoadFromAddress(iArea + view_as<Address>(20), NumberType_Int32));
		vMaxs[2] = view_as<float>(LoadFromAddress(iArea + view_as<Address>(24), NumberType_Int32));

		AddVectors(vMins, vMaxs, vOrigin);
		ScaleVector(vOrigin, 0.5);
		
		TankByOrigin(vOrigin);
	}
}

void TankByOrigin(float vOrigin[3])
{
	int entity = CreateEntityByName("info_zombie_spawn");
	
	if (entity == -1)
		return;
	
	DispatchKeyValue(entity, "population", "tank");
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	DispatchSpawn(entity);
	
	AcceptEntityInput(entity, "SpawnZombie");
	AcceptEntityInput(entity, "kill");
}