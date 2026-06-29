#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <ff2_ams>
#include <ff2_dynamic_defaults>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define MAJOR_REVISION "1"
#define MINOR_REVISION "3"
#define PATCH_REVISION "4"

#if !defined PATCH_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...PATCH_REVISION
#endif

// Movespeed
new Float:NewSpeed[MAXPLAYERS+1];
new Float:NewSpeedDuration[MAXPLAYERS+1];
new bool:NewSpeed_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new bool:DSM_SpeedOverride[MAXPLAYERS+1];

#define INACTIVE 100000000.0
#define MOVESPEED "rage_movespeed"
#define MOVESPEEDALIAS "MVS"

public Plugin:myinfo = {
    name = "Freak Fortress 2: Move Speed",
    author = "SHADoW NiNE TR3S",
    version = PLUGIN_VERSION,
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_win_panel", Event_WinPanel);
	
	if(FF2_GetRoundState()==1)
	{
		PrepareAbilities(); // late-load ? reload?
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrepareAbilities();
}

public PrepareAbilities()
{
	for(new client=1;client<=MaxClients;client++)
	{
		if (IsValidClient(client))
		{
			DSM_SpeedOverride[client]=NewSpeed_TriggerAMS[client]=false;
			NewSpeed[client]=0.0;
			NewSpeedDuration[client]=INACTIVE;
			
			new boss=FF2_GetBossIndex(client);
			if(boss>=0)
			{
				if(FF2_HasAbility(boss, this_plugin_name, MOVESPEED))
				{
					NewSpeed_TriggerAMS[client]=AMS_IsSubabilityReady(boss, this_plugin_name, MOVESPEED);
					if(NewSpeed_TriggerAMS[client])
					{
						AMS_InitSubability(boss, client, this_plugin_name, MOVESPEED, MOVESPEEDALIAS); // Important function to tell AMS that this subplugin supports it
					}
				}
			}
		}
	}
}

public Action:Event_WinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if (IsValidClient(client))
		{
			DSM_SpeedOverride[client]=false;
			NewSpeed_TriggerAMS[client]=false; // Cleanup
			SDKUnhook(client, SDKHook_PreThink, MoveSpeed_Prethink);
			NewSpeed[client]=0.0;
			NewSpeedDuration[client]=INACTIVE;
		}
	}
}

public bool:MVS_CanInvoke(client)
{
	return true;
}

Rage_MoveSpeed(client)
{
	if(NewSpeed_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability")) // Fail state?
		{
			NewSpeed_TriggerAMS[client]=false;
		}
		else
		{
			return;
		}
	}
	MVS_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public MVS_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	decl String:nSpeed[10], String:nDuration[10]; // Foolproof way so that args always return floats instead of ints
	FF2_GetAbilityArgumentString(boss, this_plugin_name, MOVESPEED, 1, nSpeed, sizeof(nSpeed));
	FF2_GetAbilityArgumentString(boss, this_plugin_name, MOVESPEED, 2, nDuration, sizeof(nDuration));
	
	if(NewSpeed_TriggerAMS[client])
	{
		new String:snd[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_movespeed_start", snd, sizeof(snd), boss))
		{
			EmitSoundToAll(snd, client);
			EmitSoundToAll(snd, client);
		}		
	}
	
	if(nSpeed[0]!='\0' || nDuration[0]!='\0')
	{
		if(nSpeed[0]!='\0')
		{
			NewSpeed[client]=StringToFloat(nSpeed); // Boss Move Speed
		}
		if(nDuration[0]!='\0')
		{
			if(NewSpeedDuration[client]!=INACTIVE)
			{
				NewSpeedDuration[client]+=StringToFloat(nDuration); // Add time if rage is active?
			}
			else
			{
				NewSpeedDuration[client]=GetEngineTime()+StringToFloat(nDuration); // Boss Move Speed Duration
			}
		}
		
		DSM_SpeedOverride[client]=FF2_HasAbility(boss, "ff2_dynamic_defaults", "dynamic_speed_management");
		if(DSM_SpeedOverride[client])
		{
			DSM_SetOverrideSpeed(client, NewSpeed[client]);
		}
		
		SDKHook(client, SDKHook_PreThink, MoveSpeed_Prethink);
	}
		
	new Float:dist2=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, MOVESPEED, 3);
	if(dist2)
	{
		if(dist2==-1)
		{
			dist2=FF2_GetRageDist(boss, this_plugin_name, MOVESPEED);
		}
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, MOVESPEED, 4, nSpeed, sizeof(nSpeed));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, MOVESPEED, 5, nDuration, sizeof(nDuration));
		
		new Float:pos[3], Float:pos2[3], Float:dist;
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		for(new target=1;target<=MaxClients;target++)
		{
			if(!IsValidClient(target))
				continue;
		
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos2);
			dist=GetVectorDistance( pos, pos2 );
			if (dist<dist2 && IsPlayerAlive(target) && GetClientTeam(target)!=FF2_GetBossTeam())
			{
				SDKHook(target, SDKHook_PreThink, MoveSpeed_Prethink);
				NewSpeed[target]=StringToFloat(nSpeed); // Victim Move Speed
				if(NewSpeedDuration[target]!=INACTIVE)
				{
					NewSpeedDuration[target]+=StringToFloat(nDuration); // Add time if rage is active?
				}
				else
				{
					NewSpeedDuration[target]=GetEngineTime()+StringToFloat(nDuration); // Victim Move Speed Duration
				}
			}
		}
	}
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
		
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!strcmp(ability_name, MOVESPEED))
	{
		Rage_MoveSpeed(client);
	}
	return Plugin_Continue;
}

public MoveSpeed_Prethink(client)
{
	if(!DSM_SpeedOverride[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", NewSpeed[client]);
	}
	SpeedTick(client, GetEngineTime());
}

public SpeedTick(client, Float:gameTime)
{
	// Move Speed
	if(gameTime>=NewSpeedDuration[client])
	{
		if(DSM_SpeedOverride[client])
		{
			DSM_SpeedOverride[client]=false;
			DSM_SetOverrideSpeed(client, -1.0);
		}
		
		new boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{
			new String:snd[PLATFORM_MAX_PATH];
			if(FF2_RandomSound("sound_movespeed_finish", snd, sizeof(snd), boss))
			{
				EmitSoundToAll(snd, client);
				EmitSoundToAll(snd, client);
			}
		}
	
		NewSpeed[client]=0.0;
		NewSpeedDuration[client]=INACTIVE;
		SDKUnhook(client, SDKHook_PreThink, MoveSpeed_Prethink);
	}
}

stock bool:IsValidClient(client, bool:isPlayerAlive=false)
{
	if (client <= 0 || client > MaxClients)
		return false;
	if(!isPlayerAlive)
		return IsClientInGame(client);
	return IsClientInGame(client) && IsPlayerAlive(client);
}