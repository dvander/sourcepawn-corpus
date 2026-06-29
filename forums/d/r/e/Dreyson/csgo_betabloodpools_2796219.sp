#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin myinfo = {
    name        = "[CSGO]: Beta Blood Pools",
    author      = "Dreyson",
    description = "Restores the cut beta feature where blood pools would spawn underneath bodies.",
    version     = "1.3.0",
    url         = ""
};

public void OnPluginStart()
{
    HookEvent("player_death", player_death, EventHookMode_Post);
}

int CreateCSRagdoll(int client)
{
	int Ragdoll = CreateEntityByName("cs_ragdoll");
	float fPos[3], fAng[3];
	GetClientAbsOrigin(client, fPos); GetClientAbsAngles(client, fAng);
	
	TeleportEntity(Ragdoll, fPos, fAng, NULL_VECTOR);
	
	SetEntProp(Ragdoll, Prop_Send, "m_nModelIndex", GetEntProp(client, Prop_Send, "m_nModelIndex"));
	SetEntProp(Ragdoll, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntPropEnt(Ragdoll, Prop_Send, "m_hPlayer", client);
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathPose", GetEntProp(client, Prop_Send, "m_nSequence"));
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathFrame", GetEntProp(client, Prop_Send, "m_flAnimTime"));
	SetEntProp(Ragdoll, Prop_Send, "m_nForceBone", GetEntProp(client, Prop_Send, "m_nForceBone"));
	
	int m_hRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	static float ragdollForce[3];
	
	if(m_hRagdoll > 0 && IsValidEdict(m_hRagdoll)) {
	GetEntPropVector(m_hRagdoll, Prop_Send, "m_vecRagdollOrigin", fPos);
	GetEntPropVector(m_hRagdoll, Prop_Send, "m_vecForce", ragdollForce);
	AcceptEntityInput(m_hRagdoll, "Kill"); 
	}
	else
	{
	GetEntPropVector(client, Prop_Send, "m_vecVelocity", ragdollForce);
	}
	
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollOrigin", fPos);
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecForce", ragdollForce);
	SetEntPropEnt(client, Prop_Send, "m_hRagdoll", Ragdoll);
	
	DispatchSpawn(Ragdoll);
	ActivateEntity(Ragdoll);
	
	return Ragdoll;
}

void player_death(Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0 || IsPlayerAlive(client)) return;
	
	int iRagdoll = CreateCSRagdoll(client);
	
	BloodOnFloorPrep(iRagdoll);
}

int BloodOnFloorPrep(int iRagdoll)
{
	float fPos[3];
	GetEntPropVector(iRagdoll, Prop_Send, "m_vecOrigin", fPos);
	fPos[2] += 1.0;
	
	BloodOnFloor(fPos, iRagdoll);
}

int BloodOnFloor(float fPos[3], int iRagdoll)
{
	int iBlood = CreateEntityByName("info_particle_system");
	
	if(!IsValidEntity(iBlood) || !IsValidEntity(iRagdoll))
		return;
	
	DispatchKeyValue(iBlood, "effect_name", "blood_pool");
	TeleportEntity(iBlood, fPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iBlood);
	ActivateEntity(iBlood);
	SetVariantString("!activator");
	AcceptEntityInput(iBlood, "SetParent", iRagdoll);
	CreateTimer(5.0, StartBlood, iBlood);
}

public Action:StartBlood(Handle:iTimer, int iBlood)
{
	if(IsValidEntity(iBlood))
	AcceptEntityInput(iBlood, "Start");
}