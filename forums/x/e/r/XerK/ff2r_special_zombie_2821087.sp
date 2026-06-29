/*
	"clone_on_death"
	{
		"slot"				"0"			// Ability slot
		"die on boss death"	"true"		// If clones die when the boss dies
		
		"character"
		{
			// Character Config
		}
		
		"plugin_name"		"ff2r_special_zombie"
	}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>
#include <tf2items>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2 Rewrite: Special Zombie"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Turn people into your minion upon their death"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXTF2PLAYERS	36

bool DieOnDeath[MAXTF2PLAYERS][MAXTF2PLAYERS];

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
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
}


public void OnPluginEnd()
{
	for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		for(int target = 0; target <= MaxClients; target++)
		{
			if(IsValidClient(target) && DieOnDeath[clientIdx][target])
			{
				ForcePlayerSuicide(target);
				DieOnDeath[clientIdx][target] = false;
			}				
		}
	}
}

public void FF2R_OnBossRemoved(int clientIdx)
{
	for(int target = 0; target <= MaxClients; target++)
	{
		if(IsValidClient(target) && DieOnDeath[clientIdx][target])
		{
			ForcePlayerSuicide(target);
			DieOnDeath[clientIdx][target] = false;
		}				
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{	
	int clientIdx = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(clientIdx))
		return;
	
	int attackerIdx = GetClientOfUserId(event.GetInt("attacker"));	// Not necessarily needed if abilities are not effecting players
	if(!IsValidClient(attackerIdx))
		return;
	
	if(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;	// Make sure it is not deadringer
	
	BossData boss1 = FF2R_GetBossData(clientIdx);
	if(boss1)
	{
		AbilityData ability1 = boss1.GetAbility("clone_on_death");
		if(ability1.IsMyPlugin())
		{
			for(int target = 0; target <= MaxClients; target++)
			{
				if(IsValidClient(target) && DieOnDeath[clientIdx][target])
				{
					ForcePlayerSuicide(target);
					DieOnDeath[clientIdx][target] = false;
				}				
			}
		}
	}
	
	BossData boss = FF2R_GetBossData(attackerIdx);
	if(boss)
	{
		AbilityData ability = boss.GetAbility("clone_on_death");
		if(ability.IsMyPlugin())
		{
			DataPack pack;
			CreateDataTimer(0.1, Timer_Respawn, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(attackerIdx));
			pack.WriteCell(GetClientUserId(clientIdx));
		}
	}
}

public Action Timer_Respawn(Handle timer, DataPack pack)
{
	pack.Reset();
	int clientIdx = GetClientOfUserId(pack.ReadCell());
	int targetIdx = GetClientOfUserId(pack.ReadCell());	
	
	if(targetIdx && IsValidClient(targetIdx) && clientIdx && IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
	{
		AbilityData ability = FF2R_GetBossData(clientIdx).GetAbility("clone_on_death");
		
		DieOnDeath[clientIdx][targetIdx] = ability.GetBool("die on boss death", true);
		ConfigData minion = ability.GetSection("character");
			
		if(IsPlayerAlive(targetIdx))
			ForcePlayerSuicide(targetIdx);
		
		if(minion)
			FF2R_CreateBoss(targetIdx, minion, GetClientTeam(clientIdx));
			
		FF2R_SetClientMinion(targetIdx, true);
		
		float pos[3], ang[3];
		GetEntPropVector(targetIdx, Prop_Send, "m_vecOrigin", pos);
		GetClientAbsAngles(targetIdx, ang);
			
		TF2_RespawnPlayer(targetIdx);
		TeleportEntity(targetIdx, pos, ang, NULL_VECTOR);
	}
	return Plugin_Continue;
}

public void FF2R_OnAbility(int clientIdx, const char[] ability, AbilityData cfg)
{
	return;
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