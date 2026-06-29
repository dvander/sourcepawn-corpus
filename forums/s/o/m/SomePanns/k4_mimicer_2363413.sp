#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define INACTIVE 100000000.0
#define SOUND_SLOW_MO_START "replay/enterperformancemode.wav"
#define SOUND_SLOW_MO_END "replay/exitperformancemode.wav" 
#define SOUND_STUN_BALL "player/pl_impact_stun.wav"
bool Mimicer_CanUse[MAXPLAYERS+1]=false;
float DisguiseTime[MAXPLAYERS+1]=INACTIVE;

public Plugin myinfo = {
    name = "Freak Fortress 2: Mimicer's passive ability",
    author = "Kah!",
    version = "1.0",
};
    
public void OnPluginStart2()
{
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	if(FF2_GetRoundState()==1)
	{
		HookAbilities();
	}
	
}

stock void UpdateClientCheatValue(int client, int value)
{
    if(client>0 && client<=MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
    {
		Handle cvarCheats=FindConVar("sv_cheats");
		SendConVarValue(client, cvarCheats, value ? "1" : "0");
    }
}

public Action FF2_OnAbility2(int boss,const char[] plugin_name,const char[] ability_name,int status)
{
	if(!strcmp(ability_name, "special_mimicer"))
	{
		float ImmoDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2); // Global immobility duration
	
		for(int target=1; target<=MaxClients; target++) {
			if(IsValidClient(target, true) && GetClientTeam(target)!=FF2_GetBossTeam())
			{
				TF2_StunPlayer(target, ImmoDuration, 0.0, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT, target); // Stuns all non-boss players on the map
				EmitSoundToAll(SOUND_STUN_BALL);
				PrintToChat(target, "[FF2] Mimicer has stunned you!");
			}
		}
	}
}

public Action FF2_OnLoseLife(int boss, int &lives, int maxLives)
{
	if(FF2_HasAbility(boss, this_plugin_name, "special_mimicer"))
	{
		Handle cvarTimeScale=FindConVar("host_timescale");
		float TscaleDur = 16.0; // if speed is set at 2.0 the duration will be half of TscaleDur
		float TscaleSpeed = 2.0; // standard speed is 1.0 and 2.0 is doubled speed
	
		SetConVarFloat(cvarTimeScale, TscaleSpeed); 
		CreateTimer(TscaleDur, SlowMoTimer);
		for(int client=1; client<=MaxClients; client++) {
			UpdateClientCheatValue(client, 1);
			if(IsValidClient(client, true) && GetClientTeam(client)!=FF2_GetBossTeam())
			{
				TF2_StunPlayer(client, TscaleDur, 0.0, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
			}
			EmitSoundToAll(SOUND_SLOW_MO_START);
			PrintToChat(client, "[FF2] Mimicer is in fast motion, causing you to get stunned!");
		}
	}
}

public Action SlowMoTimer(Handle timer)
{
	Handle cvarTimeScale=FindConVar("host_timescale");
	SetConVarFloat(cvarTimeScale, 1.0);
	for(int client=1; client<=MaxClients; client++) {	
		UpdateClientCheatValue(client, 0);
		EmitSoundToAll(SOUND_SLOW_MO_END);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.35, CheckAbilities);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client, false))
			continue;
		if(Mimicer_CanUse[client])
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
			{
				TF2_RemovePlayerDisguise(client);
			}
			Mimicer_CanUse[client]=false;	
			DisguiseTime[client]=INACTIVE;
			SDKUnhook(client, SDKHook_PreThink, Mimicer_PreThink);
		}
	}
}

public Action CheckAbilities(Handle timer)
{
	HookAbilities();
}

void HookAbilities()
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client, false))
			continue;
		Mimicer_CanUse[client]=false;	
		DisguiseTime[client]=INACTIVE;
		int boss=FF2_GetBossIndex(client);
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, "special_mimicer"))
		{
			Mimicer_CanUse[client]=true;
			if(FF2_GetBossLives(boss) == 2) {
			TF2_DisguisePlayer(client, (FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (TFTeam_Red) : (TFTeam_Blue), view_as<TFClassType>(GetRandomInt(1,9)));	
			SDKHook(client, SDKHook_PreThink, Mimicer_PreThink);
			} 
		}
	}
}

public void Mimicer_PreThink(int client)
{
	if(!IsValidClient(client, true) && FF2_GetRoundState()==1)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
		{
			TF2_RemovePlayerDisguise(client);
		}
		SDKUnhook(client, SDKHook_PreThink, Mimicer_PreThink);
	}
	Mimicer_Tick(client, GetEngineTime());
}

void Mimicer_Tick(int client, float gTime)
{
		if(gTime >= DisguiseTime[client])
		{
			int boss=FF2_GetBossIndex(client);
			if(FF2_GetBossLives(boss) == 2) {
				TF2_DisguisePlayer(client, (FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (TFTeam_Red) : (TFTeam_Blue), view_as<TFClassType>(GetRandomInt(1,9)));	
				DisguiseTime[client]=INACTIVE;
			}
		}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(Mimicer_CanUse[client])
	{
		DisguiseTime[client]=GetEngineTime()+3.0;
	}
}

stock bool IsValidClient(int client, bool isAlive=false)
{
	if(!client||client>MaxClients)	return false;
	if(isAlive) return IsClientInGame(client) && IsPlayerAlive(client);
	return IsClientInGame(client);
}