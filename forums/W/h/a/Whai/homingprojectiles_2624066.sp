#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] Homing Projectiles",
	author = "Phil25 - Whai",
	description = "Homing Projectiles from RTD'",
	version = PLUGIN_VERSION,
	url = ""
};

#define HOMING_SPEED 0.5
#define HOMING_REFLE 1.1

bool bHasHomingProjectiles[MAXPLAYERS+1];
Handle hArrayHomingProjectile;

ConVar hEnable, hCanSeeEveryone;
bool bEnable, bCanSeeEveryone;


public void OnPluginStart()
{
	RegAdminCmd("sm_homingprojectiles", Command_HomingProjectiles, ADMFLAG_SLAY, "Toggle Homing Projectiles");
	
	CreateConVar("sm_homingprojectiles_version", PLUGIN_VERSION, "[TF2] Homing Projectiles Version", FCVAR_NOTIFY | FCVAR_SPONLY);
	
	hEnable = CreateConVar("sm_homingprojectiles_enable", "1", "Enable/Disable \"Homing Projectiles\" Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hEnable.AddChangeHook(ConVarChanged);
	
	hCanSeeEveryone = CreateConVar("sm_homingprojectiles_canseeeveryone", "0", "If projectiles can attack/see invisible/disguised spies", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCanSeeEveryone.AddChangeHook(ConVarChanged);
	
	LoadTranslations("common.phrases");
	
	hArrayHomingProjectile = CreateArray(2);
	ClearArray(hArrayHomingProjectile);
}

public void OnClientPutInServer(int iClient)
{
	bHasHomingProjectiles[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
	bHasHomingProjectiles[iClient] = false;
}

public void OnMapStart()
{
	ClearArray(hArrayHomingProjectile);
}

public void OnMapEnd()
{
	ClearArray(hArrayHomingProjectile);
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	bEnable = GetConVarBool(hEnable);
	bCanSeeEveryone = GetConVarBool(hCanSeeEveryone);
}

public Action Command_HomingProjectiles(int iClient, int iArgs)
{
	if(bEnable)
	{
		
		char arg1[MAX_NAME_LENGTH], arg2[32], target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if(!iClient && !iArgs)
		{
			ReplyToCommand(iClient, "[SM] Usage in server console: sm_homingprojectiles <target>\n[SM] Usage in server console: sm_homingprojectiles <target> <1 - enable | 0 - disable>");
			return Plugin_Handled;
		}
		if(!iArgs)
		{
			if(bHasHomingProjectiles[iClient])
			{
				bHasHomingProjectiles[iClient] = false;
				ReplyToCommand(iClient, "[SM] Homing Projectiles is now disabled to you");
			}
			else
			{
				bHasHomingProjectiles[iClient] = true;
				ReplyToCommand(iClient, "[SM] Homing Projectiles is now enabled to you");
			}
		}
		if(iArgs == 1)
		{
			
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(iClient, target_count);
				return Plugin_Handled;
			}
			
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					return Plugin_Handled;
				
				if(!bHasHomingProjectiles[target])
				{
					bHasHomingProjectiles[target] = true;
					ReplyToCommand(target, "[SM] Homing Projectiles is now enabled to you");
				}
				else
				{
					bHasHomingProjectiles[target] = false;
					ReplyToCommand(target, "[SM] Homing Projectiles is now disabled to you");
				}
			}
		}
		if(iArgs == 2)
		{
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			
			if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(iClient, target_count);
				return Plugin_Handled;
			}
			
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					return Plugin_Handled;
				
				if(StrEqual(arg2, "on", false) || StrEqual(arg2, "1", false))
				{
					if(!bHasHomingProjectiles[target])
						ReplyToCommand(target, "[SM] Homing Projectiles is now disabled to you");
						
					bHasHomingProjectiles[target] = true;	
				}
				else if(StrEqual(arg2, "off", false) || StrEqual(arg2, "0", false))
				{
					if(bHasHomingProjectiles[target])
						ReplyToCommand(target, "[SM] Homing Projectiles is now enabled to you");
					
					bHasHomingProjectiles[target] = false;
				}
			}
		}
		if(iArgs > 2)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_homingprojectiles <target>\n[SM] Usage: sm_homingprojectiles <target> <1 - enable | 0 - disable>");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(iClient, "[SM] Cannot use the command, plugin not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public void OnEntityCreated(int iEntity, const char[] cClassname)
{
	if(IsValidProjectiles(cClassname))
		CreateTimer(0.2, CheckProjectilesOwner, EntIndexToEntRef(iEntity));
	
}

public Action CheckProjectilesOwner(Handle timer, any iRefEntity)
{
	int iProjectile = EntRefToEntIndex(iRefEntity);
	
	if(iProjectile <= MaxClients || !IsValidEntity(iProjectile))
		return Plugin_Handled;
	
	int iOwner = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	
	if(iOwner < 1 || !IsValidClient(iOwner))
		return Plugin_Handled;
	
	if(!bHasHomingProjectiles[iOwner])
		return Plugin_Handled;
	
	if(GetEntProp(iProjectile, Prop_Send, "m_nForceBone") != 0)
		return Plugin_Handled;
	
	SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 1);
	
	int iData[2];
	iData[0] = EntIndexToEntRef(iProjectile);
	PushArrayArray(hArrayHomingProjectile, iData);
	
	return Plugin_Handled;
}

public void OnGameFrame()
{
	for(int i = GetArraySize(hArrayHomingProjectile)-1; i >= 0; i--){
	
		int iData[2];
		GetArrayArray(hArrayHomingProjectile, i, iData);
		
		if(iData[0] == 0)
		{
			RemoveFromArray(hArrayHomingProjectile, i);
			continue;
		}
		
		int iProjectile = EntRefToEntIndex(iData[0]);
		
		if(iProjectile > MaxClients)
			HomingProjectile_Think(iProjectile, iData[0], i, iData[1]);
			
		else
			RemoveFromArray(hArrayHomingProjectile, i);
	}
}

void HomingProjectile_Think(int iProjectile, int iRefProjectile, int iArrayIndex, int iCurrentTarget)
{

	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	
	if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, iTeam))
		HomingProjectile_FindTarget(iProjectile, iRefProjectile, iArrayIndex);
		
	else
		HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile);
	
}

void HomingProjectile_FindTarget(int iProjectile, int iRefProjectile, int iArrayIndex)
{
	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	float fPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fPos1);
	
	int iBestTarget;
	float fBestLength = 99999.9;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(HomingProjectile_IsValidTarget(i, iProjectile, iTeam))
		{
			float fPos2[3];
			GetClientEyePosition(i, fPos2);
			
			float fDistance = GetVectorDistance(fPos1, fPos2);
			
			if(fDistance < fBestLength)
			{
				iBestTarget = i;
				fBestLength = fDistance;
			}
		}
	}
	if(iBestTarget >= 1 && iBestTarget <= MaxClients)
	{
		int iData[2];
		iData[0] = iRefProjectile;
		iData[1] = iBestTarget;
		SetArrayArray(hArrayHomingProjectile, iArrayIndex, iData);
		
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile);
	}
	else
	{
		int iData[2];
		iData[0] = iRefProjectile;
		iData[1] = 0;
		SetArrayArray(hArrayHomingProjectile, iArrayIndex, iData);
	}
}

void HomingProjectile_TurnToTarget(int client, int iProjectile)
{
	float fTargetPos[3], fRocketPos[3], fInitialVelocity[3];
	GetClientAbsOrigin(client, fTargetPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fRocketPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fInitialVelocity);
	
	float fSpeedInit = GetVectorLength(fInitialVelocity);
	float fSpeedBase = fSpeedInit *HOMING_SPEED;
	
	fTargetPos[2] += 30 +Pow(GetVectorDistance(fTargetPos, fRocketPos), 2.0) /10000;
	
	float fNewVec[3], fAng[3];
	SubtractVectors(fTargetPos, fRocketPos, fNewVec);
	NormalizeVector(fNewVec, fNewVec);
	GetVectorAngles(fNewVec, fAng);

	float fSpeedNew = fSpeedBase +GetEntProp(iProjectile, Prop_Send, "m_iDeflected") *fSpeedBase *HOMING_REFLE;
	
	ScaleVector(fNewVec, fSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, fAng, fNewVec);
}

stock bool HomingProjectile_IsValidTarget(int client, int iProjectile, int iTeam)
{

	if(client < 1 || client > MaxClients)	return false;
	if(!IsClientInGame(client))			return false;
	if(!IsPlayerAlive(client))			return false;
	if(GetClientTeam(client) == iTeam)	return false;
	
	if(!bCanSeeEveryone)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			return false;
		
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
			return false;
			
	}
	
	return CanEntitySeeTarget(iProjectile, client);
}

stock bool CanEntitySeeTarget(int iEnt, int iTarget){
	if(!iEnt) return false;

	float fStart[3], fEnd[3];
	if(IsValidClient(iEnt))
		GetClientEyePosition(iEnt, fStart);
	else GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fStart);

	if(IsValidClient(iTarget))
		GetClientEyePosition(iTarget, fEnd);
	else GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fEnd);

	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, TraceFilterIgnorePlayersAndSelf, iEnt);
	if(hTrace != INVALID_HANDLE){
		if(TR_DidHit(hTrace)){
			CloseHandle(hTrace);
			return false;
		}
		CloseHandle(hTrace);
	}
	return true;
}

public bool TraceFilterIgnorePlayersAndSelf(int iEntity, int iContentsMask, any iTarget){
	if(iEntity == iTarget)
		return false;

	if(1 <= iEntity <= MaxClients)
		return false;

	return true;
}

stock bool IsValidProjectiles(const char[] sClassname){

	if(!strcmp(sClassname, "tf_projectile_rocket") 
	|| !strcmp(sClassname, "tf_projectile_arrow") 
	|| !strcmp(sClassname, "tf_projectile_flare") 
	|| !strcmp(sClassname, "tf_projectile_energy_ball") 
	|| !strcmp(sClassname, "tf_projectile_healing_bolt"))
		return true;
	
	return false;
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}