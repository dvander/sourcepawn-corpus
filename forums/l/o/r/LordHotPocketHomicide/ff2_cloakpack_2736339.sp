
#define DEBUG

#define PLUGIN_NAME           "ff2_cloakpack"

#define CLOAK_SPEED			  "cloakpack_speed" //Done
#define CLOAK_STATUS		  "cloakpack_statinvuln" //Done
#define CLOAK_NOBUMP		  "cloakpack_nocollision" //WIP
#define CLOAK_TRAIL			  "cloakpack_trail"
#define CLOAK_DMG			  "cloakpack_damage" //Done
#define CLOAK_SOUNDS		  "cloakpack_noise" //Could probably borrow code from ff2_passivenoise

#define PLUGIN_AUTHOR         "Spookmaster"
#define PLUGIN_DESCRIPTION    "Various simple abilities for bosses that use invis watches."
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""

#include <sourcemod>
#include <sdktools>
#include <freak_fortress_2>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#tryinclude <collisionhook>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
//#pragma newdecls required


float cloakspd[MAXPLAYERS+1] = {0.0, ...};
float contactDrain[MAXPLAYERS+1] = {0.0, ...};
float dmgMult[MAXPLAYERS+1] = {0.0, ...};
float dmgDrain[MAXPLAYERS+1] = {0.0, ...};

int milkInv[MAXPLAYERS+1] = {0, ...};
int flameInv[MAXPLAYERS+1] = {0, ...};
int gasInv[MAXPLAYERS+1] = {0, ...};
int bleedInv[MAXPLAYERS+1] = {0, ...};
int pissInv[MAXPLAYERS+1] = {0, ...};
int markInv[MAXPLAYERS+1] = {0, ...};
int flickInv[MAXPLAYERS+1] = {0, ...};
int dazeInv[MAXPLAYERS+1] = {0, ...};
int glowInv[MAXPLAYERS+1] = {0, ...};
int collision_blockbump[MAXPLAYERS+1] = {0, ...};
//int collisionBase[MAXPLAYERS+1] = {0, ...};
//int collisionPass[MAXPLAYERS+1] = {0, ...};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	HookEvent("arena_round_start", roundStart);
}

public void roundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			int bossIDX = FF2_GetBossIndex(client);
			if (bossIDX != -1)
			{
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_SPEED))
				{
					cloakspd[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_SPEED, "arg0", 0, 0.0);
					
					SDKHook(client, SDKHook_PreThink, cloakSpeed);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_STATUS))
				{
					milkInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg0", 0, 0);
					flameInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg1", 1, 0);
					gasInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg2", 2, 0);
					bleedInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg3", 3, 0);
					pissInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg4", 4, 0);
					markInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg5", 5, 0);
					flickInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg6", 6, 0);
					dazeInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg7", 7, 0);
					glowInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg8", 8, 0);
					
					SDKHook(client, SDKHook_PreThink, cloakStats);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_DMG))
				{
					dmgMult[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_DMG, "arg0", 0, 0.0);
					dmgDrain[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_SPEED, "arg1", 1, 0.0);
					
					SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP))
				{
					contactDrain[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP, "arg0", 0, 0.0);
					collision_blockbump[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP, "arg1", 1, 0);
					
					//SDKHook(client, SDKHook_ShouldCollide, blockCol);
					//SDKHook(client, SDKHook_StartTouch, noCol);
				}
			}
		}
	}
	HookEvent("teamplay_round_win", cloakEnd);
}

public Action cloakSpeed(client)
{		
	if (IsValidClient(client))
	{
		if (cloakspd[client] != 0.0 && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", cloakspd[client]);
		}
	}
}

public Action cloakStats(client)
{		
	if (IsValidClient(client))
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			if (TF2_IsPlayerInCondition(client, TFCond_Milked) && milkInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Milked);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_OnFire) && flameInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_OnFire);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Gas) && gasInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Gas);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Bleeding) && bleedInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Bleeding);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Jarated) && pissInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Jarated);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) && markInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_MarkedForDeath);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_MarkedForDeathSilent) && markInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_CloakFlicker) && flickInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_CloakFlicker);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && dazeInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Dazed);
			}
			if (FF2_GetClientGlow(client) > 0 && glowInv[client] != 0)
			{
				FF2_SetClientGlow(client, 0.0, 0.0);
			}
		}
	}
}

/*public Action noCol(int Boss, int iEntity)
{
	if(IsValidClient(iEntity) && IsValidClient(Boss))
	{
		bool yes;
		CH_PassFilter(Boss, iEntity, yes);
	}
	return Plugin_Continue;
}*/

public Action CH_PassFilter(int ent1, int ent2, &bool:yes)
{
    if (IsValidEntity(ent1) && IsValidEntity(ent2) && IsValidClient(ent1) && IsValidClient(ent2))
    {
    	int bossIDX = FF2_GetBossIndex(ent1);
    	if (bossIDX != -1)
    	{
    		if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP) && TF2_GetClientTeam(ent2) != TF2_GetClientTeam(ent1))
    		{
    			if(TF2_IsPlayerInCondition(ent1, TFCond_Cloaked))
        		{
        			if (TF2_IsPlayerInCondition(ent1, TFCond_CloakFlicker) && collision_blockbump[ent1] == 1)
					{
						TF2_RemoveCondition(ent1, TFCond_CloakFlicker);
					}
					if (contactDrain[ent1] != 0.0)
					{
						float cloak = GetEntPropFloat(ent1, Prop_Send, "m_flCloakMeter");
						if (cloak - contactDrain[ent1] >= 0.0)
						{
							SetEntPropFloat(ent1, Prop_Send, "m_flCloakMeter", cloak - contactDrain[ent1]);
						}
					}
           		 	yes=false;
            		return Plugin_Stop;
        		} 
    		}
    	}
    	int bossIDX2 = FF2_GetBossIndex(ent2);
    	if (bossIDX2 != -1)
    	{
    		if (FF2_HasAbility(bossIDX2, PLUGIN_NAME, CLOAK_NOBUMP) && TF2_GetClientTeam(ent2) != TF2_GetClientTeam(ent1))
    		{
    			if(TF2_IsPlayerInCondition(ent2, TFCond_Cloaked))
        		{
        			if (TF2_IsPlayerInCondition(ent2, TFCond_CloakFlicker) && collision_blockbump[ent2] == 1)
					{
						TF2_RemoveCondition(ent2, TFCond_CloakFlicker);
					}
					if (contactDrain[ent2] != 0.0)
					{
						float cloak = GetEntPropFloat(ent2, Prop_Send, "m_flCloakMeter");
						if (cloak - contactDrain[ent2] >= 0.0)
						{
							SetEntPropFloat(ent2, Prop_Send, "m_flCloakMeter", cloak - contactDrain[ent2]);
						}
					}
           		 	yes=false;
            		return Plugin_Stop;
        		} 
    		}
    	}
    }
    return Plugin_Continue;
}

/*public Action CH_PassFilter(int ent1, int ent2, &bool:yes)
{
    if(IsValidEntity(ent1) && IsValidEntity(ent2) && IsValidClient(ent1) && IsValidClient(ent2))
    {
        if(NoCollide[ent1] || NoCollide[ent2])
        {
            yes=false;
            return Plugin_Stop;
        }
        return Plugin_Continue;    
    }
}*/

/*public bool blockCol(entity, collisiongroup, contentsmask, bool result)
{
    if (IsValidClient(entity))
    {
    	if (TF2_IsPlayerInCondition(entity, TFCond_Cloaked))
    	{
    		if (TF2_IsPlayerInCondition(entity, TFCond_CloakFlicker) && collision_blockbump[entity] == 1)
			{
				TF2_RemoveCondition(entity, TFCond_CloakFlicker);
			}
			if (contactDrain[entity] != 0.0)
			{
				float cloak = GetEntPropFloat(entity, Prop_Send, "m_flCloakMeter");
				if (cloak - contactDrain[entity] >= 0.0)
				{
					SetEntPropFloat(entity, Prop_Send, "m_flCloakMeter", cloak - contactDrain[entity]);
				}
			}
			result = false;
    	}
    	else
    	{
    		result = true;
    	}
    }
    return result;
}*/

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
        Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(victim))
	{
		if (TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
		{
			if (dmgDrain[victim] != 0.0)
			{
				float cloak = GetEntPropFloat(victim, Prop_Send, "m_flCloakMeter");
				if (cloak - dmgDrain[victim] >= 0.0)
				{
					SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", cloak - dmgDrain[victim]);
				}
			}
			if (dmgMult[victim] != 1.0)
			{
				damage *= dmgMult[victim];
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}
public void cloakEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			cloakspd[client] = 0.0;
			dmgMult[client] = 0.0;
			dmgDrain[client] = 0.0;
			contactDrain[client] = 0.0;
			
			milkInv[client] = 0;
			flameInv[client] = 0;
			gasInv[client] = 0;
			bleedInv[client] = 0;
			pissInv[client] = 0;
			markInv[client] = 0;
			flickInv[client] = 0;
			dazeInv[client] = 0;
			glowInv[client] = 0;
			collision_blockbump[client] = 0;
			
			SDKUnhook(client, SDKHook_PreThink, cloakSpeed);
			SDKUnhook(client, SDKHook_PreThink, cloakStats);
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			//SDKUnhook(client, SDKHook_ShouldCollide, blockCol);
			//SDKUnhook(client, SDKHook_StartTouch, noCol);
		}
	}
}


stock bool IsValidClient(int client, bool replaycheck=true, bool onlyrealclients=true) //Function borrowed from Nolo001, credit goes to him.
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	//if(onlyrealclients)                    Commented out for testing purposes
	//{
	//	if(IsFakeClient(client))
	//		return false;
	//}
	
	return true;
}