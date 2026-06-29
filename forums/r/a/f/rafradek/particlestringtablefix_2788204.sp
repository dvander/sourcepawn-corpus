#pragma semicolon 1
#pragma newdecls required

#include <dhooks>

DynamicDetour g_hDHook_CServerGameDLL_LevelInit;

public Plugin myinfo =
{
	name 		= "Particle String Table Fix",
	author 		= "rafradek",
	description = "Port of https://forums.alliedmods.net/showthread.php?t=322106 to TF2",
	version 	= "1",
	url 		= ""
};

Handle particle_system_mgr_create;
Handle particle_system_mgr_destroy;
Handle particle_system_mgr_init;
//Handle particle_system_mgr_count;
Handle parse_particle_effects;

Address particle_system_mgr_addr;
Address particle_system_query_addr;

public void OnPluginStart()
{
	GameData hGameData = new GameData("particlestringtablefix");
	if (hGameData == null) {
		SetFailState("Cannot load particlestringtablefix gamedata");
	}

	g_hDHook_CServerGameDLL_LevelInit = DynamicDetour.FromConf(hGameData, "CServerGameDLL::LevelInit");

	if (g_hDHook_CServerGameDLL_LevelInit == null) {
		SetFailState("Cannot init g_hDHook_CreateStringTable detour");
	}

	g_hDHook_CServerGameDLL_LevelInit.Enable(Hook_Pre, DHookCallback_CServerGameDLL_LevelInit);
    
    StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData,SDKConf_Signature, "CParticleSystemMgr::CParticleSystemMgr");
	particle_system_mgr_create=EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData,SDKConf_Signature, "CParticleSystemMgr::~CParticleSystemMgr");
	particle_system_mgr_destroy=EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData,SDKConf_Signature, "CParticleSystemMgr::Init");
	PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
	particle_system_mgr_init=EndPrepSDKCall();

    // StartPrepSDKCall(SDKCall_Raw);
	// PrepSDKCall_SetFromConf(hGameData,SDKConf_Signature, "CParticleSystemMgr::GetParticleSystemCount");
    // PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	// particle_system_mgr_count=EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData,SDKConf_Signature, "ParseParticleEffects");
	PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
	parse_particle_effects=EndPrepSDKCall();

    particle_system_mgr_addr = GameConfGetAddress(hGameData, "s_ParticleSystemMgr");
    particle_system_query_addr = GameConfGetAddress(hGameData, "s_ParticleSystemQuery");
	delete hGameData;
}

public MRESReturn DHookCallback_CServerGameDLL_LevelInit(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	SDKCall(particle_system_mgr_destroy, particle_system_mgr_addr);
	SDKCall(particle_system_mgr_create, particle_system_mgr_addr);
	SDKCall(particle_system_mgr_init, particle_system_mgr_addr, particle_system_query_addr);
	SDKCall(parse_particle_effects, false, false);
	return MRES_Ignored;
}