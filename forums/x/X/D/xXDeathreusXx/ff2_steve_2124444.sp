#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name = "Freak Fortress 2: Custom Requested Rage",
	author = "Deathreus",
	version = "1.0",
};

#define ME 2048
#define MAX_PLAYERS 33

new Handle:cvarKAC;
new BossTeam=_:TFTeam_Blue;
new ff2flags[MAXPLAYERS+1];
new Handle:OnHaleRage = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	//OnHaleJump = CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);	
	
	return APLRes_Success;
}

public OnPluginStart2()
{
	HookEvent("arena_round_start", event_round_start);
	HookEvent("teamplay_round_start", event_round_start);

	LoadTranslations("freak_fortress_2.phrases");

	cvarKAC = FindConVar("kac_enable");
	//cvarCheats = FindConVar("sv_cheats");
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
	if (!strcmp(ability_name, "rage_steve"))
		Rage_Steve(ability_name, index);
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3,Timer_GetBossTeam);
	for(new i=1; i<=MaxClients; i++)
		ff2flags[i]=0;

	return Plugin_Continue;
}

Rage_Steve(const String:ability_name[], index)
{
	new Boss = GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:Duration = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 1);   // Duration
	
	if(GetClientTeam(Boss)==BossTeam)
	{
		TF2_AddCondition(Boss, TFCond_Buffed, Duration);
		TF2_AddCondition(Boss, TFCond_DefenseBuffed, Duration);
		TF2_AddCondition(Boss, TFCond_RegenBuffed, Duration);
	}
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	if (cvarKAC && GetConVarBool(cvarKAC))
		SetConVarBool(cvarKAC,false);
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}