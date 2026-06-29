#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

int BossTeam = view_as<int>(TFTeam_Blue);

float g_flBeamDamage = 1337.0;
float g_flBeamSize = 25.0;
bool g_bIgnoreWalls = false;
bool g_bIgnoreInvulnerability = false;
float g_vMins[3] = {-24.5, -24.5, 0.0};
float g_vMaxs[3] = {24.5, 24.5, 85.0};
int g_iBeamR = 34;
int g_iBeamG = 34;
int g_iBeamB = 255;

float g_vEyeAngleLock[MAXPLAYERS+1][3];
bool g_bHasRaged[MAXPLAYERS+1] = false;

int g_Glow;

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	if(FF2_GetRoundState() == 1)	// Late-load
	{
		BossTeam = FF2_GetBossTeam();
		int iBoss;
		for(int iIndex; (iBoss=GetClientOfUserId(FF2_GetBossUserId(iIndex)))>0; iIndex++)
		{
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_octogonapus"))
			{
				g_flBeamDamage = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_octogonapus", 2, 1337.0);
				g_flBeamSize = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_octogonapus", 3, 25.0);
				g_bIgnoreWalls = view_as<bool>(FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 5, 1));
				g_bIgnoreInvulnerability = view_as<bool>(FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 6, 0));
				g_iBeamR = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 9, 255);
				g_iBeamG = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 10, 255);
				g_iBeamB = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 11, 255);
				
				char sBuffer[32], sMinMax[3][16];
				FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_octogonapus", 7, sBuffer, sizeof(sBuffer));
				ExplodeString(sBuffer, ",", sMinMax, 3, sizeof(sMinMax[]));
				for (new i = 0; i < 3; i++)
					g_vMins[i] = StringToFloat(sMinMax[i]);
				
				FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_octogonapus", 8, sBuffer, sizeof(sBuffer));
				ExplodeString(sBuffer, ",", sMinMax, 3, sizeof(sMinMax[]));
				for (new i = 0; i < 3; i++)
					g_vMaxs[i] = StringToFloat(sMinMax[i]);
			}
		}
	}
}

public void OnMapStart() {
	g_Glow = PrecacheModel("sprites/blueglow2.vmt");
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	BossTeam = FF2_GetBossTeam();
	if(StrEqual(sName, "teamplay_round_start", false))
	{
		for(int iBoss=MaxClients; iBoss>0; iBoss--)
		{
			if(IsValidClient(iBoss, true))
			{
				CreateTimer(0.3, OctogonapusPreBlast, iBoss, TIMER_FLAG_NO_MAPCHANGE);
				HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
				break;
			}
		}
	}
	else
	{
		for(int iIndex; GetClientOfUserId(FF2_GetBossUserId(iIndex))>0; iIndex++)
		{
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_octogonapus"))
			{
				g_flBeamDamage = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_octogonapus", 2, 1337.0);
				g_flBeamSize = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_octogonapus", 3, 25.0);
				g_bIgnoreWalls = view_as<bool>(FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 5, 1));
				g_bIgnoreInvulnerability = view_as<bool>(FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 6, 0));
				g_iBeamR = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 9, 255);
				g_iBeamG = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 10, 255);
				g_iBeamB = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_octogonapus", 11, 255);
				
				char sBuffer[32], sMinMax[3][16];
				FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_octogonapus", 7, sBuffer, sizeof(sBuffer));
				ExplodeString(sBuffer, ",", sMinMax, 3, sizeof(sMinMax[]));
				for (new i = 0; i < 3; i++)
					g_vMins[i] = StringToFloat(sMinMax[i]);
				
				FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_octogonapus", 8, sBuffer, sizeof(sBuffer));
				ExplodeString(sBuffer, ",", sMinMax, 3, sizeof(sMinMax[]));
				for (new i = 0; i < 3; i++)
					g_vMaxs[i] = StringToFloat(sMinMax[i]);
			}
		}
	}
}

public Action Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (hEvent.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	int iBoss = GetClientOfUserId(FF2_GetBossUserId(iAttacker));
	
	if(iAttacker == iBoss)
	{
		if(FF2_IsFF2Enabled() && FF2_GetRoundState() == 1)
		{
			RequestFrame(RespawnPlayer, iVictim);
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float vVel[3], float vAng[3], int &iWeapon)
{
	if(!IsValidClient(iClient, true, true))	
		return Plugin_Continue;
	
	if(g_bHasRaged[iClient])
	{
		TeleportEntity(iClient, NULL_VECTOR, g_vEyeAngleLock[iClient], NULL_VECTOR);
		CopyVector(g_vEyeAngleLock[iClient], vAng);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void FF2_OnAbility2(int iBoss, const char[] pluginName, const char[] abilityName, int iStatus) {
	if(!strncmp(abilityName, "rage_octogonapus", false))
		Rage_Octogonapus(iBoss, abilityName);
}

void Rage_Octogonapus(int iIndex, const char[] ability_name)
{
	int iBoss = GetClientOfUserId(FF2_GetBossUserId(iIndex));
	float flDelay = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, ability_name, 1);
	float flMaxLength = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, ability_name, 4);
	
	TF2_AddCondition(iBoss, TFCond_Ubercharged, flDelay+0.4);
	SetEntityMoveType(iBoss, MOVETYPE_NONE);
	
	float vStart[3], vAng[3], vEnd[3];
	GetClientEyePosition(iBoss, vStart);
	GetClientEyeAngles(iBoss, vAng);
	
	CopyVector(vAng, g_vEyeAngleLock[iBoss]);
	
	Handle hTrace = TR_TraceRayFilterEx(vStart, vAng, CONTENTS_SOLID, RayType_Infinite, TraceFilterThings, iBoss);
	TR_GetEndPosition(vEnd, hTrace);
	delete hTrace;
	
	ConstrainDistance(vStart, vEnd, flMaxLength ? flMaxLength:9999.0);
	
	Handle hData;
	CreateDataTimer(flDelay, OctogonapusBlast, hData, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(hData, iBoss);
	WritePackCell(hData, 0);
	WritePackFloat(hData, vStart[0]);
	WritePackFloat(hData, vStart[1]);
	WritePackFloat(hData, vStart[2]);
	WritePackFloat(hData, vEnd[0]);
	WritePackFloat(hData, vEnd[1]);
	WritePackFloat(hData, vEnd[2]);
	
	CreateTimer(flDelay*1.5, OctogonapusReset, iBoss, TIMER_FLAG_NO_MAPCHANGE);
	g_bHasRaged[iBoss] = true;
}

public Action OctogonapusBlast(Handle hTimer, Handle hPack)
{
	ResetPack(hPack);
	int iBoss = ReadPackCell(hPack);
	
	if(!FF2_IsFF2Enabled())
		return Plugin_Continue;
	
	if(!view_as<bool>(ReadPackCell(hPack)) && FF2_GetRoundState() != 1)
		return Plugin_Continue;
	
	if(!IsValidClient(iBoss, true, true))
		return Plugin_Continue;
	
	float vStart[3], vEnd[3], vAng[3];
	static float vGoal[3];
	
	for(int x=0; x<3; x++)
		vStart[x] = ReadPackFloat(hPack);
	
	for(int x=0; x<3; x++)
		vGoal[x] = ReadPackFloat(hPack);
		
	int iColor[4];
	iColor[0] = g_iBeamR;
	iColor[1] = g_iBeamG;
	iColor[2] = g_iBeamB;
	iColor[3] = 255;
	
	GetVectorAnglesTwoPoints(vStart, vGoal, vAng);
	while(!TR_PointOutsideWorld(vEnd))
	{
		GetForwardPosition(vStart, vAng, vEnd, g_flBeamSize*2.0);
		
		float vMiddle[3];
		for(int i=0; i<3; i++)
			vMiddle[i] = (vStart[i] + vEnd[i])/2;
		
		TE_SetupGlowSprite(vMiddle, g_Glow, 1.0, g_flBeamSize, 255);
		TE_SendToAll();
		
		TR_TraceHullFilter(vMiddle, vMiddle, g_vMins, g_vMaxs, CONTENTS_EMPTY, TraceFilterThings, iBoss);
		CopyVector(vEnd, vStart);
		
		int iClient = TR_GetEntityIndex();
		if(!IsValidClient(iClient, true))
			continue;
		
		if(!g_bIgnoreInvulnerability && IsPlayerInvincible(iClient))
			continue;
		
		SDKHooks_TakeDamage(iClient, iBoss, iBoss, g_flBeamDamage, DMG_ENERGYBEAM|DMG_DISSOLVE);
	}
	
	return Plugin_Continue;
}

public Action OctogonapusPreBlast(Handle hTimer, any iBoss)
{
	if(!FF2_IsFF2Enabled())
		return Plugin_Continue;
	
	if(!IsValidClient(iBoss, true, true))
		return Plugin_Continue;
	
	int iIndex = FF2_GetBossIndex(iBoss);
	if(!FF2_HasAbility(iIndex, this_plugin_name, "special_octoroundstart"))
		return Plugin_Continue;
	
	int iMerc = PickRandomMerc();
	
	float vStart[3], vEnd[3];
	GetClientEyePosition(iBoss, vStart);
	GetClientEyePosition(iMerc, vEnd);
	
	float flDelay = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_octoroundstart", 1);
	
	Handle hData;
	CreateDataTimer(flDelay, OctogonapusBlast, hData, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(hData, iBoss);
	WritePackCell(hData, 1);	  // Tell it to not check is the round is running
	WritePackFloat(hData, vStart[0]);
	WritePackFloat(hData, vStart[1]);
	WritePackFloat(hData, vStart[2]);
	WritePackFloat(hData, vEnd[0]);
	WritePackFloat(hData, vEnd[1]);
	WritePackFloat(hData, vEnd[2]);
	
	return Plugin_Continue;
}

public Action OctogonapusReset(Handle hTimer, any iBoss)
{
	g_bHasRaged[iBoss] = false;
	g_vEyeAngleLock[iBoss] = NULL_VECTOR;
	SetEntityMoveType(iBoss, MOVETYPE_WALK);
}

public void RespawnPlayer(iClient)
{
	TF2_RespawnPlayer(iClient);
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public bool TraceFilterThings(int iEntity, int fMask, any iBoss)
{
	if(iEntity == iBoss)
		return false;
	
	if(g_bIgnoreWalls && iEntity < 1)
		return false;
	
	if(iEntity > MaxClients)
		return false;
	
	return true;
}

stock bool IsValidClient(int iClient, bool bAlive = false, bool bTeam = false)
{
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;
	
	if(bTeam && GetClientTeam(iClient) != BossTeam)
		return false;

	return true;
}

public bool IsPlayerInvincible(int iClient) {
	return TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged) || TF2_IsPlayerInCondition(iClient, TFCond_UberchargedCanteen) || TF2_IsPlayerInCondition(iClient, TFCond_Bonked);
}

// I wonder if this could end up in an infinite loop...
public int PickRandomMerc()
{
	int iTarget = GetRandomInt(1, MaxClients);
	if(IsValidClient(iTarget, true) && GetClientTeam(iTarget) != BossTeam)
		return iTarget;
	else return PickRandomMerc();
}

// It's just simpler
public void CopyVector(float vVec1[3], float vVec2[3])
{
	vVec2[0] = vVec1[0];
	vVec2[1] = vVec1[1];
	vVec2[2] = vVec1[2];
}

stock void ConstrainDistance(float vStart[3], float vEnd[3], float flMaxDistance)
{
	float flDistance = GetVectorDistance(vStart, vEnd);
	if (flDistance <= flMaxDistance)
		return; // nothing to do
		
	float flConstraint = flMaxDistance / flDistance;
	vEnd[0] = ((vEnd[0] - vStart[0]) * flConstraint) + vStart[0];
	vEnd[1] = ((vEnd[1] - vStart[1]) * flConstraint) + vStart[1];
	vEnd[2] = ((vEnd[2] - vStart[2]) * flConstraint) + vStart[2];
}

stock void GetVectorAnglesTwoPoints(const float vStart[3], const float vEnd[3], float vAng[3])
{
	static float tmpVec[3];
	tmpVec[0] = vEnd[0] - vStart[0];
	tmpVec[1] = vEnd[1] - vStart[1];
	tmpVec[2] = vEnd[2] - vStart[2];
	GetVectorAngles(tmpVec, vAng);
}

// Found in Stop That Tank!
void GetForwardPosition(float vPos[3], float vAng[3], float vReturn[3], float flDistance = 50.0)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	for(int i=0; i<3; i++) vReturn[i] += vDir[i] * flDistance;
}
