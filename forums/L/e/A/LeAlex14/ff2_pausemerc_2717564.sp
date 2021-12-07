#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define MAX_PLAYERS 33

public Plugin:myinfo = {
   name = "Freak Fortress 2: Pause mercs but not the boss",
   author = "Lealex14",		
   description = "Disable all movement and velocity",
   version = "2.5.0"
}

float g_fBaseVelocity[2049][3];
float g_fBaseAngle[2049][3];
bool g_bPlayerPause[MAXPLAYERS+1][MAXPLAYERS+1];
bool g_bEntPause[MAXPLAYERS+1][2049];
bool g_bPlayerBonked[MAXPLAYERS+1][MAXPLAYERS+1];
float g_fPlayerBonkedVelocity[MAXPLAYERS+1];
float g_fPlayerDamagePause[MAXPLAYERS+1][MAXPLAYERS+1];
int g_iTimeStop=0;
MoveType g_iBaseMoveType[2049];

public OnPluginStart2()
{
	int iLock=0;
	for (new client = 1; client <= MaxClients; client++)
	{
		
		if (IsValidEdict(client) && IsClientInGame(client))
		{
			new boss = FF2_GetBossIndex(client);
			if (FF2_HasAbility(boss, this_plugin_name, "pausemerc"))
			{
				iLock=1;
			}
		}
		
	}
	for (new player = 1; player <= MaxClients; player++)
	{
		if (IsValidEdict(player) && IsClientInGame(player))
		{
			if (iLock==1)
			{
				OnClientPutInServer(player);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePause);
}

public Action OnTakeDamagePause(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (g_iTimeStop<=0)
	{
		return Plugin_Continue;
	}
	
	if (g_iTimeStop == victim || GetClientTeam(g_iTimeStop)==GetClientTeam(victim))
	{
		damage=0.0;
		return Plugin_Changed;
	}
	int iboss = FF2_GetBossIndex(g_iTimeStop);
	if (FF2_GetAbilityArgument(iboss,this_plugin_name,"pausemerc", 7, 0)==1)
	{
		if (GetClientTeam(victim)!= GetClientTeam(attacker))
		{
			float fMaxDamage = FF2_GetAbilityArgumentFloat(iboss,this_plugin_name,"pausemerc", 8, 100.0);
			if (damage >= fMaxDamage && fMaxDamage!=0.0)
				damage=fMaxDamage;
			
			g_fPlayerDamagePause[g_iTimeStop][victim]+=damage;
			damage=0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
	
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
    if (!strcmp(ability_name, "pausemerc"))
        Rage_pause(ability_name, index);
}


public Action Stop_pause_Ent(Handle timer, iBoss)
{
	for(new ient=1; ient<=2048; ient++) // 2048 = Max entities
    {
		if (IsValidEntity(ient) && g_bEntPause[iBoss][ient])
		{
			SetEntityMoveType(ient, g_iBaseMoveType[ient]);
			SetEntPropVector(ient, Prop_Data, "m_vecVelocity", g_fBaseVelocity[ient]);
			SetEntPropVector(ient, Prop_Data, "m_angRotation", g_fBaseAngle[ient]);
			g_bEntPause[iBoss][ient]=false;
		}
	}
}

public Action Stop_pause_Player(Handle timer, iBoss)
{
	for(new iplayer=1; iplayer<=MaxClients; iplayer++) // 2048 = Max entities
    {
		if (g_bPlayerPause[iBoss][iplayer])
		{
			if (g_iBaseMoveType[iplayer]!=MOVETYPE_NONE)
				SetEntityMoveType(iplayer, g_iBaseMoveType[iplayer]);
			else
				SetEntityMoveType(iplayer, MOVETYPE_WALK);
			
			SetEntPropVector(iplayer, Prop_Data, "m_vecVelocity", g_fBaseVelocity[iplayer]);
			SetEntPropVector(iplayer, Prop_Data, "m_angRotation", g_fBaseAngle[iplayer]);
			g_bPlayerPause[iBoss][iplayer] = false;
			TF2_RemoveCondition(iplayer,TFCond_FreezeInput);
			if (g_fPlayerDamagePause[iBoss][iplayer]>0)
			{
				SDKHooks_TakeDamage(iplayer, 0, iBoss, g_fPlayerDamagePause[iBoss][iplayer]);
				g_fPlayerDamagePause[iBoss][iplayer]=0.0;
			}
		}
	}
	g_iTimeStop = 0;
}

public Action Bonk(Handle timer, iBoss)
{
	bool bBonkLock = false;
	for(new player=1; player<=MaxClients; player++) // 2048 = Max entities
    {
		if (IsClientInGame(player) && IsPlayerAlive(player) && g_bPlayerBonked[iBoss][player] && iBoss!=player)
		{
			if (!TF2_IsPlayerInCondition(player, TFCond_Bonked))
			{
				GetEntPropVector(player, Prop_Data, "m_vecVelocity", g_fBaseVelocity[player]);
				GetEntPropVector(player, Prop_Data, "m_angRotation", g_fBaseAngle[player]);
				g_iBaseMoveType[player] = GetEntityMoveType(player);
				SetEntPropVector(player, Prop_Data, "m_vecVelocity", g_fBaseVelocity[player]);
				SetEntPropVector(player, Prop_Data, "m_angRotation", g_fBaseAngle[player]);
				SetEntityMoveType(player, MOVETYPE_NONE);
				g_bPlayerBonked[iBoss][player] = false;
				g_bPlayerPause[iBoss][player] = true;
				TF2_AddCondition(player, TFCond_FreezeInput, 99999.99, iBoss);
			}
			else
			{
				bBonkLock = true;
			}
		}
	}
	if (bBonkLock == true)
		CreateTimer(0.5, Bonk, iBoss, TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angles[3], &weapon)
{
	if (g_iTimeStop <= 0 || !g_bPlayerBonked[g_iTimeStop][client])
	{
		return Plugin_Continue;
	}
	velocity[0] *= g_fPlayerBonkedVelocity[client];
	velocity[1] *= g_fPlayerBonkedVelocity[client];
	velocity[2] *= g_fPlayerBonkedVelocity[client];
	return Plugin_Changed;
}

public Action reenablebuilding(Handle timer, building)
{
	SetEntProp(building, Prop_Send, "m_bDisabled", 0);
}

public OnEntityCreated(entity, const String:classname[]) 
{
	if (strncmp(classname, "tf_projectile_",14)==0 && g_iTimeStop > 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, Stop_Ent_Created);
	}
}

public Stop_Ent_Created(entity) 
{
	new iboss = FF2_GetBossIndex(g_iTimeStop);
	float fRange = FF2_GetAbilityArgumentFloat(iboss,this_plugin_name,"pausemerc", 2, 99999.0);
	float fPosEnt[3];
	float fdistance;
	float fPosBoss[3];
	GetEntPropVector(g_iTimeStop, Prop_Send, "m_vecOrigin", fPosBoss);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fPosEnt);
	fdistance = GetVectorDistance(fPosBoss, fPosEnt);
	if (fdistance<=fRange)
	{
		if (FF2_GetAbilityArgument(iboss,this_plugin_name,"pausemerc", 5, 0)==2 || (FF2_GetAbilityArgument(iboss,this_plugin_name,"pausemerc", 5, 0)==1 && GetEntProp(entity, Prop_Send, "m_iTeamNum")!=GetClientTeam(g_iTimeStop)))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecVelocity", g_fBaseVelocity[entity]);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", g_fBaseAngle[entity]);
			SetEntPropVector(entity, Prop_Data, "m_vecVelocity", NULL_VECTOR);
			g_iBaseMoveType[entity] = GetEntityMoveType(entity);
			SetEntityMoveType(entity, MOVETYPE_NONE);
			g_bEntPause[g_iTimeStop][entity]=true;
		}
	}
}

public Action Rage_pause(const String:ability_name[], index)
{	
	int iBoss = GetClientOfUserId(FF2_GetBossUserId(index));
	float fDuration = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 1, 10.0);      
	float fRange = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2, 99999.0);
	int iApplyBonk = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3, 0);
	int iApplyProjectile = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5, 0);
	int iApplyPlayer = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 6, 0);
	float fPosEnt[3];
	float fdistance;
	float fPosBoss[3];
	int ient;
	int iplayer;
	GetEntPropVector(iBoss, Prop_Send, "m_vecOrigin", fPosBoss);
	g_iTimeStop=iBoss;
	for(ient=1; ient<=2048; ient++) // 2048 = Max entities
    {
		if (IsValidEdict(ient) && IsValidEntity(ient) && iApplyProjectile>0)
		{
			new String:sClassname[64];
			GetEdictClassname(ient, sClassname, sizeof(sClassname));
			if (strncmp(sClassname, "obj_",4)==0 || strncmp(sClassname, "tf_projectile_",14)==0)
			{
				GetEntPropVector(ient, Prop_Send, "m_vecOrigin", fPosEnt);
				fdistance = GetVectorDistance(fPosBoss, fPosEnt);
				if (fdistance<=fRange)
				{
					if (iApplyProjectile==2 || (iApplyProjectile==1 && GetEntProp(ient, Prop_Send, "m_iTeamNum")!=GetClientTeam(g_iTimeStop)))
					{
						if (strncmp(sClassname, "obj_",4)==0)
						{
							SetEntProp(ient, Prop_Send, "m_bDisabled", 1);
							CreateTimer(fDuration, reenablebuilding, ient, TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (strncmp(sClassname, "tf_projectile_",14)==0)
						{
							GetEntPropVector(ient, Prop_Data, "m_vecVelocity", g_fBaseVelocity[ient]);
							GetEntPropVector(ient, Prop_Data, "m_angRotation", g_fBaseAngle[ient]);
							SetEntPropVector(ient, Prop_Data, "m_vecVelocity", NULL_VECTOR);
							g_iBaseMoveType[ient] = GetEntityMoveType(ient);
							SetEntityMoveType(ient, MOVETYPE_NONE);
							g_bEntPause[iBoss][ient]=true;
						}
					}
				}
			}
		}
    }
	bool bBonkLock = false;
	for(iplayer=1; iplayer<=MaxClients; iplayer++) // 2048 = Max entities
    {
		if (IsClientInGame(iplayer) && IsPlayerAlive(iplayer) && iBoss!=iplayer)
		{
			GetEntPropVector(iplayer, Prop_Send, "m_vecOrigin", fPosEnt);
			fdistance = GetVectorDistance(fPosBoss, fPosEnt);
			if (fdistance<=fRange && ((GetClientTeam(iBoss)!=GetClientTeam(iplayer) && iApplyPlayer==1) || iApplyPlayer==0))
			{
				g_fPlayerDamagePause[iBoss][iplayer]=0.0;
				if (!TF2_IsPlayerInCondition(iplayer, TFCond_Bonked) || iApplyBonk==0)
				{
					GetEntPropVector(iplayer, Prop_Data, "m_vecVelocity", g_fBaseVelocity[iplayer]);
					GetEntPropVector(iplayer, Prop_Data, "m_angRotation", g_fBaseAngle[iplayer]);
					SetEntPropVector(iplayer, Prop_Data, "m_vecVelocity", NULL_VECTOR);
					TF2_AddCondition(iplayer, TFCond_FreezeInput, 99999.99, iBoss);
					g_iBaseMoveType[iplayer] = GetEntityMoveType(iplayer);
					SetEntityMoveType(iplayer, MOVETYPE_NONE);
					g_bPlayerPause[iBoss][iplayer] = true;
				}
				else if (iBoss!=iplayer)
				{
					g_bPlayerBonked[iBoss][iplayer] = true;
					g_fPlayerBonkedVelocity[iplayer] = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 4, 0.75);
					bBonkLock = true;
				}
			}
		}
	}
	if (bBonkLock)
		CreateTimer(0.5, Bonk, iBoss, TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(fDuration, Stop_pause_Player, iBoss, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(fDuration, Stop_pause_Ent, iBoss, TIMER_FLAG_NO_MAPCHANGE);
}



