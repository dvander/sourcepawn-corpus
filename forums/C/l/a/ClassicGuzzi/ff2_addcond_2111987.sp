#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define ME 2048

#define PLUGIN_VERSION "1.0 beta"

public Plugin:myinfo = {
//	name = "",
	author = "SuperStarPL",
//	description = "",
	version = PLUGIN_VERSION,
};

new Handle:OnHaleRage = INVALID_HANDLE;

//new Handle:chargeHUD;
new Handle:cvarKAC;
new BossTeam=_:TFTeam_Blue;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);	

	return APLRes_Success;
}


public OnPluginStart2()
{
	//chargeHUD = CreateHudSynchronizer();
	//HookEvent("teamplay_round_start", event_round_start);
	
	LoadTranslations("ff2_1st_set.phrases");
	//LoadTranslations("freak_fortress_2.phrases");
	cvarKAC = FindConVar("kac_enable");
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	if (cvarKAC && GetConVarBool(cvarKAC))
		SetConVarBool(cvarKAC,false);
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	new slot=FF2_GetAbilityArgument(index,this_plugin_name,ability_name,0);
	if (!slot)
	{
		if (index == 0)		//Starts VSH rage ability forward
		{
			new Action:act = Plugin_Continue;
			Call_StartForward(OnHaleRage);
			new Float:dist=FF2_GetRageDist(index,this_plugin_name,ability_name);
			new Float:newdist=dist;
			Call_PushFloatRef(newdist);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return Plugin_Continue;
			if (act == Plugin_Changed) dist = newdist;	
		}
	}

	if (!strcmp(ability_name,"rage_addcondition"))
		Rage_addcondition(ability_name,index);
	return Plugin_Continue;
}
/**		Add Condition

Rage_AddCondition
Will add the condition to players for selected amount of time during rage.

-Arg1 = Duration (Default 5.0)
-Arg2 = Condition type float (Default 1-TFCond_Milked)


**/
Rage_addcondition(const String:ability_name[],index)
{
	decl Float:pos[3];
	decl Float:pos2[3];
	decl i;
	new Float:condduration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0);
	
	new condition;
	FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 2, 1.0);
	
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
	for(i=1;i<=MaxClients;i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
		if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
		{
		switch(condition)
			{
				case 1:
				{
					TF2_AddCondition(i, TFCond_Milked, condduration);
				}
				case 2:
				{
					TF2_AddCondition(i, TFCond_Jarated, condduration);
				}
			}
		}
		}
}