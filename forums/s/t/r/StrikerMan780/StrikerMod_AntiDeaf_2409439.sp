#pragma semicolon 1

#define PLUGIN_AUTHOR "Striker The Hedgefox"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <dhooks>

public Plugin myinfo = 
{
	name = "[StrikerMod][dHooks] Disable Explosion Ringing (HL2DM)",
	author = PLUGIN_AUTHOR,
	description = "First of the StrikerMod series of plugins. Properly gets rid of the tinnitus/deafening effect when hit by explosions, without affecting damage.",
	version = PLUGIN_VERSION,
	url = "http://shadowmavericks.com/forums/"
};

new Handle:hSetPlayerDSP = INVALID_HANDLE;
new Handle:cv_disablering;
new Handle:cv_debugring;

public void OnPluginStart()
{
	new Handle:gameconf = LoadGameConfigFile("dsphook.games"); 
	if(gameconf == INVALID_HANDLE) 
    { 
        SetFailState("Failed to find dsphook.games.txt gamedata"); 
    }
	new offset = GameConfGetOffset(gameconf, "SetPlayerDSP"); 
	if(offset == -1) 
	{ 
		SetFailState("Failed to find offset for SetPlayerDSP"); 
		CloseHandle(gameconf); 
	}
	StartPrepSDKCall(SDKCall_Static); 
	if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CreateInterface")) 
	{ 
		SetFailState("Failed to get CreateInterface"); 
		CloseHandle(gameconf); 
	}
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); 
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL); 
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	new String:interface_id[64]; 
	if(!GameConfGetKeyValue(gameconf, "EngineInterface", interface_id, sizeof(interface_id))) 
	{ 
		SetFailState("Failed to get EngineInterface key in gamedata"); 
		CloseHandle(gameconf); 
	} 
	
	new Handle:temp = EndPrepSDKCall(); 
	new Address:addr = SDKCall(temp, interface_id, 0); 
     
	CloseHandle(gameconf); 
	CloseHandle(temp);
	
	if(!addr) 
	{ 
		SetFailState("Failed to get %s ptr", interface_id); 
	} 
    
	hSetPlayerDSP = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, Hook_SetPlayerDSP);
	DHookAddParam(hSetPlayerDSP, HookParamType_Unknown);
	DHookAddParam(hSetPlayerDSP, HookParamType_Int);
	DHookAddParam(hSetPlayerDSP, HookParamType_Bool);
	DHookRaw(hSetPlayerDSP, false, addr);
	
	cv_disablering = CreateConVar("strkmod_disable_ring","1","Disable Explosion Ear Ringing/Confusion",FCVAR_PLUGIN);
	cv_debugring = CreateConVar("strkmod_debug_ring","0","Debug SetPlayerDSP hook",FCVAR_PLUGIN);
}

public MRESReturn:Hook_SetPlayerDSP(Handle:hParams)
{
	//new client = DHookGetParam(hParams, 1);
	int dsp = DHookGetParam(hParams, 2);
	
	if(GetConVarBool(cv_debugring))
	{
		PrintToChatAll("[DEBUG] SetPlayerDSP: %d", dsp);
	}
	
	if( ((dsp >= 32) || (dsp <= 37)) && GetConVarBool(cv_disablering))
	{
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}