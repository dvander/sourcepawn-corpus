#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name = "Freak Fortress 2: special_noanims",
	author = "RainBolt Dash",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.41,Timer_Disable_Anims);
	CreateTimer(9.31,Timer_Disable_Anims);
	return Plugin_Continue;
}


public Action:Timer_Disable_Anims(Handle:hTimer)
{
	decl Boss;
	for (new index = 0; (Boss=GetClientOfUserId(FF2_GetBossUserId(index)))>0; index++)
	{
		if (FF2_HasAbility(index,this_plugin_name,"special_noanims"))
			SetEntProp(Boss, Prop_Send, "m_bUseClassAnimations",0);
	}
	return Plugin_Continue;
}
