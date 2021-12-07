#pragma semicolon 1

#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define VERSION_NUMBER "1.00"

public Plugin myinfo = {
	name = "Freak Fortress 2: Monochromatic",
	description = "The following has been brought to you in black and white",
	author = "Koishi",
	version = VERSION_NUMBER,
};

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

stock void SetMonochrome(int client, bool enable)
{
	int flags=GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", flags);
	ClientCommand(client, "r_screenoverlay \"%s\"", enable ? "debug/yuv" : "");
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client=MaxClients;client;client--)
	{
		if(client<=0||client>MaxClients||!IsClientInGame(client))
		{
			continue;
		}
		SetMonochrome(client, false);
	}
}

public void PrepareAbilities()
{

	int mode=0;
	for(int client=MaxClients;client;client--)
	{
		if(client<=0||client>MaxClients||!IsClientInGame(client))
		{
			continue;
		}

		int boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, "monochrome"))
			{
				mode=FF2_GetAbilityArgument(boss, this_plugin_name, "monochrome", 1);
				if(mode==1)
				{
					SetMonochrome(client, true);
				}
			}
		}
		
		if(mode==2 && FF2_GetBossIndex(client)==-1 || mode==3)
		{
			SetMonochrome(client, true);
		}
	}
}

public void FF2_OnAbility2(int boss,const char[] plugin_name,const char[] ability_name,int status)
{
	return;
}