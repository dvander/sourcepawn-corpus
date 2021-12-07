#pragma semicolon 1

#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define VERSION_NUMBER "1.04"

public Plugin myinfo = {
	name = "Freak Fortress 2: Fog Effects",
	description = "フォグ効果",
	author = "Koishi",
	version = VERSION_NUMBER,
};

#define INACTIVE 100000000.0

int envFog=-1;
bool AMSOnly[MAXPLAYERS+1];
float fogDuration[MAXPLAYERS+1]=INACTIVE;

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
	
	if(FF2_GetRoundState()==1)
	{
		PrepareAbilities();
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrepareAbilities();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	KillFog(envFog);

	for(int client=MaxClients;client;client--)
	{
		if(client<=0||client>MaxClients||!IsClientInGame(client))
		{
			continue;
		}
		
		if(fogDuration[client]!=INACTIVE)
		{
			fogDuration[client]=INACTIVE;
			SDKUnhook(client, SDKHook_PreThinkPost, FogTimer);
		}			
	}
	envFog=-1;
}

public void PrepareAbilities()
{
	for(int client=MaxClients;client;client--)
	{
		if(client<=0||client>MaxClients||!IsClientInGame(client))
		{
			continue;
		}
		
		fogDuration[client]=INACTIVE;
		AMSOnly[client]=false;
		
		int boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, "rage_fog_fx") && FF2_HasAbility(boss, "ff2_sarysapub3", "ability_management_system"))
			{
				AMSOnly[client]=true;
				AMS_InitSubability(boss, client, this_plugin_name, "rage_fog_fx", "FOG");
			}
			if(FF2_HasAbility(boss, this_plugin_name, "fog_fx"))
			{
				int fogcolor[3][3];
				// fog color
				fogcolor[0][0]=FF2_GetAbilityArgument(boss, this_plugin_name, "fog_fx", 2, 255);
				fogcolor[0][1]=FF2_GetAbilityArgument(boss, this_plugin_name, "fog_fx", 3, 255);
				fogcolor[0][2]=FF2_GetAbilityArgument(boss, this_plugin_name, "fog_fx", 4, 255);
				// fog color 2
				fogcolor[1][0]=FF2_GetAbilityArgument(boss, this_plugin_name, "fog_fx", 5, 255);
				fogcolor[1][1]=FF2_GetAbilityArgument(boss, this_plugin_name, "fog_fx", 6, 255);
				fogcolor[1][2]=FF2_GetAbilityArgument(boss, this_plugin_name, "fog_fx", 7, 255);
				// fog start
				float fogstart=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "fog_fx", 8, 64.0);
				// fog end
				float fogend=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "fog_fx", 9, 384.0);
				// fog density
				float fogdensity=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "fog_fx", 10, 1.0);

				envFog = StartFog(FF2_GetAbilityArgument(boss, this_plugin_name, "fog_fx", 1, 0), fogcolor[0], fogcolor[1], fogstart, fogend, fogdensity);

				for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						SetVariantString("MyFog");
						AcceptEntityInput(i, "SetFogController");
					}
				}
			}
		}
	}
}

public void FF2_OnAbility2(int boss,const char[] plugin_name,const char[] ability_name,int status)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(StrEqual(ability_name, "rage_fog_fx", false) && !AMSOnly[client])
	{
		FOG_Invoke(client);
	}
}

public bool FOG_CanInvoke(int client)
{
	return true;
}

public void FOG_Invoke(int client)
{
	int fogcolor[3][3];
	
	int boss=FF2_GetBossIndex(client);
	
	// fog color
	fogcolor[0][0]=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_fog_fx", 2, 255);
	fogcolor[0][1]=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_fog_fx", 3, 255);
	fogcolor[0][2]=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_fog_fx", 4, 255);
	// fog color 2
	fogcolor[1][0]=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_fog_fx", 5, 255);
	fogcolor[1][1]=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_fog_fx", 6, 255);
	fogcolor[1][2]=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_fog_fx", 7, 255);
	// fog start
	float fogstart=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_fog_fx", 8, 64.0);
	// fog end
	float fogend=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_fog_fx", 9, 384.0);
	// fog density
	float fogdensity=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_fog_fx", 10, 1.0);
	
	if(fogDuration[client]!=INACTIVE)
	{
		fogDuration[client]+=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_fog_fx", 11, 5.0);
	}
	else
	{
		envFog = StartFog(FF2_GetAbilityArgument(boss, this_plugin_name, "rage_fog_fx", 1, 0), fogcolor[0], fogcolor[1], fogstart, fogend, fogdensity);
		fogDuration[client]=GetGameTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_fog_fx", 11, 5.0);
		SDKHook(client, SDKHook_PreThinkPost, FogTimer);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetVariantString("MyFog");
			AcceptEntityInput(i, "SetFogController");
		}
	}
}

public void FogTimer(int client)
{
	if(GetGameTime()>=fogDuration[client])
	{
		KillFog(envFog);
		fogDuration[client]=INACTIVE;
		SDKUnhook(client, SDKHook_PreThinkPost, FogTimer);
		envFog=-1;
	}
}

int StartFog(int fogblend, int fogcolor[3], int fogcolor2[3], float fogstart=64.0, float fogend=384.0, float fogdensity=1.0)
{
	int iFog = CreateEntityByName("env_fog_controller");

	char fogcolors[3][16];
	IntToString(fogblend, fogcolors[0], sizeof(fogcolors[]));
	Format(fogcolors[1], sizeof(fogcolors[]), "%i %i %i", fogcolor[0], fogcolor[1], fogcolor[2]);
	Format(fogcolors[2], sizeof(fogcolors[]), "%i %i %i", fogcolor2[0], fogcolor2[1], fogcolor2[2]);
	if(IsValidEntity(iFog)) 
	{
        DispatchKeyValue(iFog, "targetname", "MyFog");
        DispatchKeyValue(iFog, "fogenable", "1");
        DispatchKeyValue(iFog, "spawnflags", "1");
        DispatchKeyValue(iFog, "fogblend", fogcolors[0]);
        DispatchKeyValue(iFog, "fogcolor", fogcolors[1]);
        DispatchKeyValue(iFog, "fogcolor2", fogcolors[2]);
        DispatchKeyValueFloat(iFog, "fogstart", fogstart);
        DispatchKeyValueFloat(iFog, "fogend", fogend);
        DispatchKeyValueFloat(iFog, "fogmaxdensity", fogdensity);
        DispatchSpawn(iFog);
        
        AcceptEntityInput(iFog, "TurnOn");
	}
	return iFog;
}

stock bool IsEntityValid(int ent)
{
	return 	IsValidEdict(ent) && ent > MaxClients;
}

stock void KillFog(int entity)
{
	if (IsEntityValid(entity))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SetVariantString("");
				AcceptEntityInput(i, "SetFogController");
			}
		}
		AcceptEntityInput(entity, "Kill");
		entity=-1;
	}
}