#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1

//DHook
Handle g_hGetSecondaryAttackActivity;

//SDKCall
Handle g_hSDKPlayGesture;

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[TF2] Shortstop 'Shove' Animation Enabler",
	author = "Pelipoika, 404 (abrandnewday)",
	description = "Enables the Shortstop's unused alt-fire 'shove' world animation.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

//tf_weapon_handgun_scout_primary 
//ACT_MP_PUSH_STAND_SECONDARY  1817
//ACT_MP_PUSH_CROUCH_SECONDARY 1818
//ACT_MP_PUSH_SWIM_SECONDARY   1819
//CTFPlayer::PlayGesture "mp_playgesture: unknown sequence or act"

public void OnPluginStart()
{
	CreateConVar("tf2_shortstopshove_version", PLUGIN_VERSION, "Current Shortstop 'Shove' Animation Enabler version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	//CTFPistol_ScoutPrimary::SecondaryAttack
	//CTFPlayer::DoAnimationEvent
	Handle config = LoadGameConfigFile("tf2.shortstopshove");
	
	int offset = GameConfGetOffset(config, "CTFPistol_ScoutPrimary::SecondaryAttack");
	if(offset == -1)
	{
		SetFailState("Failed to get offset of CTFPistol_ScoutPrimary::SecondaryAttack");
	}
	g_hGetSecondaryAttackActivity = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, CTFPistol_ScoutPrimary__SecondaryAttack);
	DHookAddParam(g_hGetSecondaryAttackActivity, HookParamType_CBaseEntity);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTFPlayer::PlayGesture");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if ((g_hSDKPlayGesture = EndPrepSDKCall()) == INVALID_HANDLE)
	{
		SetFailState("Failed to create SDKCall for CTFPlayer::PlayGesture offset!");
	}
	
	delete config;
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if(StrEqual(classname, "tf_weapon_handgun_scout_primary"))
	{
		SDKHook(ent, SDKHook_Spawn, OnCTFPistol_ScoutPrimarySpawn);
	}
}

public void OnCTFPistol_ScoutPrimarySpawn(int wep)
{
	DHookEntity(g_hGetSecondaryAttackActivity, true, wep);
}

public MRESReturn CTFPistol_ScoutPrimary__SecondaryAttack(int pThis, Handle hReturn, Handle hParams)
{
	int client = GetEntPropEnt(pThis, Prop_Data, "m_hOwnerEntity");
	if(client > 0)
	{
		if(GetEntProp(client, Prop_Send, "m_nWaterLevel") >= 2)
		{
			SDKCall(g_hSDKPlayGesture, client, "ACT_MP_PUSH_SWIM_SECONDARY");
		}
		else if(GetEntProp(client, Prop_Send, "m_bDucked")) 
		{
			SDKCall(g_hSDKPlayGesture, client, "ACT_MP_PUSH_CROUCH_SECONDARY");
		}
		else		 
		{
			SDKCall(g_hSDKPlayGesture, client, "ACT_MP_PUSH_STAND_SECONDARY");
		}
	}
	
	return MRES_Ignored;
}  