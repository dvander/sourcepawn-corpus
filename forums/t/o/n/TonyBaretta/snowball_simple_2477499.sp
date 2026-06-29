#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

ConVar g_hSnowBallSoundEnabled;
ConVar g_Cvar_Enabled;
int LastUsed[MAXPLAYERS+1];
#define IN_ATTACK3		(1 << 25)

public Plugin myinfo =
{
	name = "Snowball simple",
	author = "TonyBaretta",
	description = "Snowball simple",
	version = PLUGIN_VERSION,
	url = "http://www.wantedgov.it"
}
public void OnMapStart() 
{
	PrecacheSound("weapons/knife_swing.wav", true);
}
public void OnPluginStart()
{
	g_Cvar_Enabled = CreateConVar("snowballs_enabled", "1", "Enable snowball?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSnowBallSoundEnabled = CreateConVar("stunball_sound", "0", "Enables/disables stunball sound", FCVAR_NONE, true, 0.0, true, 1.0);
	AddNormalSoundHook(view_as<NormalSHook>(NoBallStunSound));
	CreateConVar("snowball_version", PLUGIN_VERSION, "snowball tf2 version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public void OnClientPostAdminCheck(int client)
{
    if (!IsFakeClient(client))
    {
        SDKHook(client, SDKHook_PreThink, OnPreThink);
    }
}
public Action OnPreThink(int iClient) 
{
	if (GetConVarBool(g_Cvar_Enabled)){
		if(GetClientButtons(iClient) & IN_ATTACK3){
			if((IsValidClient(iClient)) && (IsPlayerAlive(iClient))){
				int currentTime = GetTime();
				if (currentTime - LastUsed[iClient] < 1.5)
					return Plugin_Handled;
				LastUsed[iClient] = GetTime();
				int iBall = CreateEntityByName("tf_projectile_stun_ball");
				if(IsValidEntity(iBall))
				{
					//iClient = GetEntPropEnt(iBall, Prop_Data, "m_hOwner")
					float vPosition[3];
					float vAngles[3];
					float flSpeed = 1500.0;
					float vVelocity[3];
					float vBuffer[3];
					GetClientEyePosition(iClient, vPosition);
					GetClientEyeAngles(iClient, vAngles);
						
					GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						
					vVelocity[0] = vBuffer[0]*flSpeed;
					vVelocity[1] = vBuffer[1]*flSpeed;
					vVelocity[2] = vBuffer[2]*flSpeed;
					SetEntPropVector(iBall, Prop_Data, "m_vecVelocity", vVelocity);
					SetEntPropEnt(iBall, Prop_Send, "m_hOwnerEntity", iClient);
					SetEntProp(iBall, Prop_Send, "m_iTeamNum", GetClientTeam(iClient));
					SetVariantString("OnUser3 !self:FireUser4::3.0:1");
					AcceptEntityInput(iBall, "AddOutput");
					HookSingleEntityOutput(iBall, "OnUser4", BallBreak, false);
					AcceptEntityInput(iBall, "FireUser3");
					DispatchSpawn(iBall);
					EmitSoundToClient(iClient, "weapons/knife_swing.wav");
					TeleportEntity(iBall, vPosition, vAngles, vVelocity);
					CreateParticle(iBall, "xms_icicle_melt", true, 3.0);
					SetEntityRenderColor(iBall, 190, 251, 250, 255);
				}
			}
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;	
}
public void BallBreak(const char[] output, int caller, int activator, float delay){

	if(caller == -1){
		return;
	}	
	AcceptEntityInput(caller, "Kill");
}
public Action NoBallStunSound(int clients[64], int numClients, char Pathname[PLATFORM_MAX_PATH], int entity, int channel, float volume, int level, int pitch, int flags) 
{
	if(!g_hSnowBallSoundEnabled.IntValue){
		if(StrContains(Pathname, "pl_impact_stun.wav", false) != -1)return Plugin_Stop;
		else
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if((IsValidClient(client)) && (IsPlayerAlive(client))){
		if(condition == TFCond_Dazed)
		{
			SetEntityRenderColor(client, 0, 193, 255, 255);
			CreateParticle(client, "xms_icicle_impact_dryice", true, 1.0);
		}
	}
}
public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if((IsValidClient(client)) && (IsPlayerAlive(client))){
		if(condition == TFCond_Dazed)
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
	}
}
stock int CreateParticle(int iEntity, char[] sParticle, bool bAttach = false, float time)
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		float fPosition[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
		TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(iParticle, "effect_name", sParticle);
		
		if (bAttach)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);			
		}

		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
		CreateTimer(time, DeleteParticle, iParticle)
	}
	return iParticle;
}
public Action DeleteParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		char classN[64];
		GetEdictClassname(particle, classN, sizeof(classN));
		if (StrEqual(classN, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}