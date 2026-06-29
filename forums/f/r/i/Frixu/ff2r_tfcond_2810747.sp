/*
	"rage_tfcondition"	// Ability name can use suffixes
	{
		"slot"			"0"						// Ability slot
		"selfconds"		"5 ; 5.8"				// Self conditions
		"allyconds"		"5 ; 2.7"				// Ally conditions
		"allyrange"		"1024.0"				// Ally range
		"enemyconds"	"27 ; 7.7 ; 24 ; 7.7"	// Enemy conditions
		"enemyrange"	"1337.0"				// Enemy range
		
		"plugin_name"	"ff2r_tfcond"
	}
	
	"tweak_tfcondition"	// Ability name can't use suffixes, no multiple instances
	{
		"slot"								"0"						// Ability slot (not required)
		"selfconds"							"11 ; -1.0"				// Self conditions
		
		"allyconds"							"5 ; 20.0"				// Ally conditions
		"remove allyconds on boss death"	"true"					// Remove allyconds on boss death
		"apply allyconds upon respawn"		"true"					// Apply allyconds to allied players when they are respawn 
																	// (Only unlimited duration conditions re-apply & conditions don't re-apply if boss is dead)
																	
		"enemyconds"						"27 ; 7.7 ; 24 ; -1.0"	// Enemy conditions
		"remove enemyconds on boss death"	"true"					// Remove enemyconds on boss death
		"apply enemyconds upon respawn"		"true"					// Apply enemyconds to enemy players when they are respawn
																	// (Only unlimited duration conditions re-apply & conditions don't re-apply if boss is dead)
		"plugin_name"						"ff2r_tfcond"
	}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2 Rewrite: TFCond"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Subplugin for applying conditions to players"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXTF2PLAYERS	36

char TWEAK_AllyConditions[MAXTF2PLAYERS][512];
char TWEAK_EnemyConditions[MAXTF2PLAYERS][512];

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PlayerInventoryApplication);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		if(IsClientInGame(clientIdx))
		{
			BossData cfg = FF2R_GetBossData(clientIdx);			
			if(cfg)
				FF2R_OnBossCreated(clientIdx, cfg, false);
		}
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{	
	int clientIdx = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(clientIdx))
		return;
	
	FF2R_OnBossRemoved(clientIdx);
}

public void Event_PlayerInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetEventInt(event, "userid");
	if(IsValidClient(victim))
	{
		for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
		{
			if(IsValidClient(clientIdx) && IsPlayerAlive(clientIdx) && clientIdx != victim)
			{
				BossData cfg = FF2R_GetBossData(clientIdx);			
				if(cfg)
				{
					AbilityData ability = cfg.GetAbility("tweak_tfcondition");
					if(ability.IsMyPlugin())	// Incase of duplicated ability names
					{
						if(!ability.GetBool("enabled"))
							return;
							
						if(GetClientTeam(victim) == GetClientTeam(clientIdx))
						{
							if(ability.GetBool("apply allyconds upon respawn"))
							{
								AddOnlyUnlimitedCondition(victim, TWEAK_AllyConditions[clientIdx]);
							}
						}
						else
						{
							if(ability.GetBool("apply enemyconds upon respawn"))
							{
								AddOnlyUnlimitedCondition(victim, TWEAK_EnemyConditions[clientIdx]);
							}
						}
					}
				}
			}
		}
	}
}

public void FF2R_OnBossCreated(int clientIdx, BossData cfg, bool setup)
{
	AbilityData ability = cfg.GetAbility("tweak_tfcondition");
	if(!ability.IsMyPlugin())	// Incase of duplicated ability names
		return;
		
	if(!ability.GetBool("enabled", true))
		return;
		
	char buffer[256];
	if(ability.GetString("selfconds", buffer, sizeof(buffer)))
	{
		RemoveCondition(clientIdx, buffer);
		AddCondition(clientIdx, buffer);
	}
		
		
	for(int victim = 1; victim <= MaxClients; victim++)
	{
		if(IsValidClient(victim) && IsPlayerAlive(victim) && victim != clientIdx)
		{	
			if(GetClientTeam(victim) == GetClientTeam(clientIdx))
			{
				if(ability.GetString("allyconds", buffer, sizeof(buffer)))
				{
					strcopy(TWEAK_AllyConditions[clientIdx], sizeof(TWEAK_AllyConditions[]), buffer);
					AddCondition(victim, buffer);
				}			
			}
			else
			{
				if(ability.GetString("enemyconds", buffer, sizeof(buffer)))
				{
					strcopy(TWEAK_EnemyConditions[clientIdx], sizeof(TWEAK_EnemyConditions[]), buffer);
					AddCondition(victim, buffer);
				}				
			}
		}
	}
}

public void FF2R_OnBossRemoved(int clientIdx)
{
	BossData cfg = FF2R_GetBossData(clientIdx);	
	AbilityData ability = cfg.GetAbility("tweak_tfcondition");
	if(!ability.IsMyPlugin())	// Incase of duplicated ability names
		return;
	
	for(int victim = 1; victim <= MaxClients; victim++)
	{
		if(IsValidClient(victim) && IsPlayerAlive(victim) && victim != clientIdx)
		{
			if(GetClientTeam(victim) == GetClientTeam(clientIdx))
			{
				if(ability.GetBool("remove allyconds on boss death"))
				{
					RemoveCondition(victim, TWEAK_AllyConditions[clientIdx]);
				}
			}
			else
			{
				if(ability.GetBool("remove enemyconds on boss death"))
				{
					RemoveCondition(victim, TWEAK_AllyConditions[clientIdx]);
				}
			}
		}
	}
}

public void FF2R_OnAbility(int clientIdx, const char[] ability, AbilityData cfg)
{	
	if(!cfg.IsMyPlugin())	// Incase of duplicated ability names
		return;
	
	if(!cfg.GetBool("enabled", true))	// hidden/internal bool for abilities
		return;
	
	if(!StrContains(ability, "rage_tfcondition", false))
	{
		Rage_TFCond(clientIdx, ability, cfg);
	}
}

public void Rage_TFCond(int clientIdx, const char[] ability_name, AbilityData ability)
{
	char buffer[256];
	if(ability.GetString("selfconds", buffer, sizeof(buffer)))
	{
		RemoveCondition(clientIdx, buffer);
		AddCondition(clientIdx, buffer);
	}
	
	float pos1[3], pos2[3];
	GetClientEyePosition(clientIdx, pos1);
	
	for(int victim = 1; victim <= MaxClients; victim++)
	{
		if(IsValidClient(victim) && IsPlayerAlive(victim) && victim != clientIdx)
		{
			GetClientEyePosition(victim, pos2);
			float distance = GetVectorDistance(pos1, pos2, true);
			
			if(GetClientTeam(victim) == GetClientTeam(clientIdx))
			{
				if(ability.GetString("allyconds", buffer, sizeof(buffer)))
				{
					if(distance <= ability.GetFloat("allyrange"))
					{
						RemoveCondition(victim, buffer);
						AddCondition(victim, buffer);
					}
				}
			}
			else
			{
				if(ability.GetString("enemyconds", buffer, sizeof(buffer)))
				{
					if(distance <= ability.GetFloat("enemyrange"))
					{
						RemoveCondition(victim, buffer);
						AddCondition(victim, buffer);
					}
				}
			}
		}
	}
}

stock void AddCondition(int clientIdx, char[] conditions)
{
	char conds[32][32];
	int count = ExplodeString(conditions, " ; ", conds, sizeof(conds), sizeof(conds));
	if (count > 0)
	{
		for (int i = 0; i < count; i+=2)
		{
			if(!TF2_IsPlayerInCondition(clientIdx, view_as<TFCond>(StringToInt(conds[i]))))
			{
				TF2_AddCondition(clientIdx, view_as<TFCond>(StringToInt(conds[i])), StringToFloat(conds[i+1]));
			}
		}
	}
}

stock void AddOnlyUnlimitedCondition(int clientIdx, char[] conditions)
{
	char conds[32][32];
	int count = ExplodeString(conditions, " ; ", conds, sizeof(conds), sizeof(conds));
	if (count > 0)
	{
		for (int i = 0; i < count; i+=2)
		{
			if(!TF2_IsPlayerInCondition(clientIdx, view_as<TFCond>(StringToInt(conds[i]))) && StringToFloat(conds[i+1]) < 0.0)
			{
				TF2_AddCondition(clientIdx, view_as<TFCond>(StringToInt(conds[i])), TFCondDuration_Infinite);
			}
		}
	}
}

stock void RemoveCondition(int clientIdx, char[] conditions)
{
	char conds[32][32];
	int count = ExplodeString(conditions, " ; ", conds, sizeof(conds), sizeof(conds));
	if (count > 0)
	{
		for (int i = 0; i < count; i+=2)
		{
			if(TF2_IsPlayerInCondition(clientIdx, view_as<TFCond>(StringToInt(conds[i]))))
			{
				TF2_RemoveCondition(clientIdx, view_as<TFCond>(StringToInt(conds[i])));
			}
		}
	}
}

stock bool IsValidClient(int clientIdx, bool replaycheck=true)
{
	if(clientIdx <= 0 || clientIdx > MaxClients)
		return false;

	if(!IsClientInGame(clientIdx) || !IsClientConnected(clientIdx))
		return false;

	if(GetEntProp(clientIdx, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(clientIdx) || IsClientReplay(clientIdx)))
		return false;

	return true;
}