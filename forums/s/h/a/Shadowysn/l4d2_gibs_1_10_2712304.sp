#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MODEL "models/gibs/hgibs.mdl"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead)
	{
		//g_isSequel = false;
		return APLRes_Success;
	}
	else if(GetEngineVersion() == Engine_Left4Dead2)
	{
		//g_isSequel = true;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = "[L4D2] Gibs",
	author = "BHaType, Shadowysn (gamedata-less edit)",
	description = "Skull gibs fly out when a common infected is killed in the head",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=319355"
};

public void OnPluginStart()
{
	HookEvent("player_death", player_death);
}

public void OnMapStart()
{
	PrecacheModel(MODEL, true);
}

void GetAttachmentPos(int entity, const char[] str, float[3] origin_b, float[3] angles_b)
{
	float position[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
	
	int target = CreateEntityByName("info_teleport_destination");
	DispatchSpawn(target);
	ActivateEntity(target);
	AcceptEntityInput(target, "Kill");
	
	TeleportEntity(target, position, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(target, "SetParent", entity, target);
	SetVariantString(str);
	AcceptEntityInput(target, "SetParentAttachment", entity, target);
	
	AcceptEntityInput(target, "ClearParent", -1, -1);
	
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", origin_b);
	GetEntPropVector(target, Prop_Data, "m_angRotation", angles_b);
	angles_b[2] = 0.0;
}

void player_death(Event event, const char[] name, bool dontbroadcast)
{
	int entity = event.GetInt("entityid");
	
	if (entity <= MaxClients || !event.GetBool("headshot"))
		return;
		
	int client = GetClientOfUserId(event.GetInt("attacker"));
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;
	
	float vCL_Angles[3], vVec[3], vOrigin[3], vAng[3];
	GetAttachmentPos(entity, "forward", vOrigin, vAng);
	
	int iGib = CreateEntityByName("env_shooter");
	DispatchKeyValue(iGib, "shootmodel", MODEL);
	
	GetClientEyeAngles(client, vCL_Angles);
	
	GetAngleVectors(vCL_Angles, vVec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vVec, GetRandomFloat(300.0, 600.0));	
	
	vCL_Angles[0] = 0.0, vCL_Angles[2] = 0.0;
	vOrigin[2] += 2.5;
	TeleportEntity(iGib, vOrigin, vCL_Angles, NULL_VECTOR);
	
	DispatchKeyValue(iGib, "shootsounds", "-1");
	DispatchKeyValue(iGib, "m_iGibs", "1");
	DispatchKeyValueVector(iGib, "gibangles", vAng);
	DispatchKeyValueVector(iGib, "gibanglevelocity", vVec);
	DispatchKeyValue(iGib, "m_flVelocity", "500");
	DispatchKeyValue(iGib, "m_flVariance", "0.35");
	DispatchKeyValue(iGib, "simulation", "1");
	DispatchKeyValue(iGib, "m_flGibLife", "10");
	DispatchKeyValue(iGib, "spawnflags", "4");
	
	DispatchSpawn(iGib);
	ActivateEntity(iGib);
	AcceptEntityInput(iGib, "Kill");
	
	AcceptEntityInput(iGib, "Shoot");
}