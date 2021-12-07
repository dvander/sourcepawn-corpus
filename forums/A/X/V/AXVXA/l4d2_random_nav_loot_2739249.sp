#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[L4D2] Navigation Loot Spawner",
	author = "BHaType",
	description = "Spawn random",
	version = "0.4",
	url = "SDKCall"
};

static const char szWeapons[][] =
{
	"shovel",
	"pitchfork",
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"katana",
	"machete",
	"tonfa",
	"knife",
    "weapon_autoshotgun",
    "weapon_hunting_rifle",
    "weapon_pistol",
    "weapon_pistol_magnum",
    "weapon_pumpshotgun",
    "weapon_rifle",
    "weapon_rifle_ak47",
    "weapon_rifle_desert",
    "weapon_rifle_m60",
    "weapon_rifle_sg552",
    "weapon_shotgun_chrome",
    "weapon_shotgun_spas",
    "weapon_smg",
    "weapon_smg_mp5",
    "weapon_smg_silenced",
    "weapon_sniper_awp",
    "weapon_sniper_military",
    "weapon_sniper_scout",
	"weapon_chainsaw",
	"weapon_adrenaline",
	"weapon_defibrillator",
	"weapon_first_aid_kit",
	"weapon_pain_pills",
	"weapon_fireworkcrate",
	"weapon_gascan",
	"weapon_oxygentank",
	"weapon_propanetank",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_ammo_spawn",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_gnome",
	"weapon_cola_bottles"
};

static const int gChances[] =
{
	100,	//shovel
	100,	//pitchfork
	100,	//baseball_bat
	100,	//cricket_bat
	100,	//crowbar
	100,	//electric_guitar
	100,	//fireaxe
	100,	//frying_pan
	100,	//golfclub
	100,	//katana
	100,	//machete
	100,	//tonfa
	100,	//knife
	100,	//weapon_autoshotgun
	100,	//weapon_hunting_rifle
	100,	//weapon_pistol
	100,	//weapon_pistol_magnum
	100,	//weapon_pumpshotgun
	100,	//weapon_rifle
	100,	//weapon_rifle_ak47
	100,	//weapon_rifle_desert
	100,	//weapon_rifle_m60
	100,	//weapon_rifle_sg552
	100,	//weapon_shotgun_chrome
	100,	//weapon_shotgun_spas
	100,	//weapon_smg
	100,	//weapon_smg_mp5
	100,	//weapon_smg_silenced
	100,	//weapon_sniper_awp
	100,	//weapon_sniper_military
	100,	//weapon_sniper_scout
	100,	//weapon_chainsaw
	100,	//weapon_adrenaline
	100,	//weapon_defibrillator
	100,	//weapon_first_aid_kit
	100,	//weapon_pain_pills
	100,	//weapon_fireworkcrate
	100,	//weapon_gascan
	100,	//weapon_oxygentank
	100,	//weapon_propanetank
	100,	//weapon_molotov
	100,	//weapon_pipe_bomb
	100,	//weapon_vomitjar
	100,	//weapon_ammo_spawn
	100,	//weapon_upgradepack_explosive
	100,	//weapon_upgradepack_incendiary
	100,	//weapon_gnome
	100		//weapon_cola_bottles	
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
	g_hLootCount = CreateConVar("sm_nav_loot_spawner_count", "25", "How many loot we spawn?", FCVAR_NONE);
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
	GameData hData = new GameData("l4d2_nav_loot");
	
	TheNavAreas = hData.GetAddress("TheNavAreas");
	TheCount = LoadFromAddress(hData.GetAddress("TheCount"), NumberType_Int32);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "SurvivorBot::IsReachable");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hReachableCheck = EndPrepSDKCall();
	
	delete hData;
	
	if (TheNavAreas == Address_Null || !TheCount || g_hReachableCheck == null)
		SetFailState("[Navigation Spawner] Bad data, please check your gamedata");
	
	HookEvent("round_start", eEvent);
	
	g_bLoaded = true;
	
	AutoExecConfig(true, "l4d2_nav_loot_spawner");
	
	if (!g_bLateload)
		CreateTimer(6.5, tSpawn);
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
	
	CreateTimer(1.0, tSpawn);
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
		
		if (g_iReachebleCheck)
		{
			for (int l = 1; l <= MaxClients; l++) 
			{
				if (!IsClientInGame(l) || GetClientTeam(l) != 2 || !IsFakeClient(l))
					continue;
					
				if (SDKCall(g_hReachableCheck, l, vOrigin) != 1)
					bContinue = true;
				break;
			}
			
			if (bContinue)
				continue;
		}
		
		
		
		vAngles[1] = GetRandomFloat(-179.0, 179.0);
		
		int iRandom = GetRandomInt(0, sizeof szWeapons - 1);
		
		if (GetRandomInt(0, 100) > gChances[iRandom])
			continue;
		
		if (iRandom != 41) 
			vOrigin[2] += 14.5;

		if (iRandom <= 10)
		{
			Melee(szWeapons[iRandom], vOrigin, vAngles);
			continue;
		}
		
		entity = CreateEntityByName(szWeapons[iRandom]);
		
		if (entity <= MaxClients)
			continue;
		
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		DispatchSpawn(entity);
		
		//PrintToServer("Spawned weapon at %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2]);
	}
}

void Melee(const char[] szMelee, float vOrigin[3], float vAngles[3])
{
	int iWeapon = CreateEntityByName("weapon_melee");
	
	if (iWeapon <= MaxClients)
		return;
	
	DispatchKeyValue(iWeapon, "melee_script_name", szMelee);
	DispatchSpawn(iWeapon);
	TeleportEntity(iWeapon, vOrigin, vAngles, NULL_VECTOR);
	
	char szName[PLATFORM_MAX_PATH];
	GetEntPropString(iWeapon, Prop_Data, "m_ModelName", szName, sizeof szName); 
	
	if (StrContains(szName, "hunter") != -1)
		AcceptEntityInput(iWeapon, "kill");
}