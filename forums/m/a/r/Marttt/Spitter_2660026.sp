#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GAMEDATA		"l4d2_spitter_projectile"

public Plugin myinfo =
{
	name = "0x90",
	author = "BHaType (Thanks SilverShot for his plugin \"Spitter Projectile Creator\")",
	description = "0x90",
	version = "0x90",
	url = "0x90"
}

ConVar g_cvarCount;
Handle sdkActivateSpit, g_hSpitVelocity;

public void OnPluginStart()
{	
	Handle hGameConf = LoadGameConfigFile(GAMEDATA);
	if( hGameConf == null )
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CSpitterProjectile_Create") == false )
		SetFailState("Could not load the \"CSpitterProjectile_Create\" gamedata signature.");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkActivateSpit = EndPrepSDKCall();
	if( sdkActivateSpit == null )
		SetFailState("Could not prep the \"CSpitterProjectile_Create\" function.");
	
	g_hSpitVelocity = FindConVar("z_spit_velocity");
	g_cvarCount = CreateConVar("sm_spitter_projectiles"	, "15", "Count", FCVAR_NONE);
	HookEvent("ability_use", eAbility);
	
	AutoExecConfig(true, "Spitter");
}

public void eAbility(Event event, const char[] name, bool dontBroadcast)
{
	int client, count = GetConVarInt(g_cvarCount);
	
	client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client)) return;
	
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == 4)
	{
		float vPos[3], vAng[3];
		GetClientEyeAngles(client, vAng);
		GetClientEyePosition(client, vPos);
		GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vAng, vAng);
		ScaleVector(vAng, GetConVarFloat(g_hSpitVelocity));
		
		for (int i = 1; i <= count; i++)
		{
			vAng[0] += GetRandomFloat(-60.0, 60.0);
			vAng[1] += GetRandomFloat(-60.0, 60.0);
			vAng[2] += GetRandomFloat(-60.0, 60.0);
			vPos[0] += GetRandomFloat(-20.0, 20.0);
			vPos[1] += GetRandomFloat(-20.0, 20.0);
			vPos[2] += GetRandomFloat(-20.0, 20.0);
			SDKCall(sdkActivateSpit, vPos, vAng, vAng, vAng, client);
		}
	}
}