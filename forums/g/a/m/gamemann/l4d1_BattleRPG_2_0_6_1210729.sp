//BattleRPG by .#Zipcore

//Change Jobnames in RPG-Menu

#include <sourcemod>
#include <sdktools>

#define Version "2.0.6"
#define Author ".#Zipcore"
#define Name "Battle RPG 2 beta"
#define JOBMAX 13
#define Description "Roleplay Game Mode for L4D1"
#define URL ""
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo=
{
	name = Name,
	author = Author,
	description = Description,
	version = Version,
	url = URL
};
/* Config */
new Handle:MsgExpEnable
new Handle:MsgAnnounceEnable
new Handle:CfgCheckExpTimer
new Handle:CfgAnnounceTimer

/* Infected EXP */
new Handle:HunExp
new Handle:SmoExp
new Handle:BooExp
new Handle:TanExp
new Handle:WitExp
new Handle:ReviveExp
new Handle:LevelUpExp

/* Jobs */
new Handle:JobReqLevel[JOBMAX+1]
new Handle:JobCash[JOBMAX+1]
new Handle:JobHealth[JOBMAX+1]
new Handle:JobHP[JOBMAX+1]
new Handle:JobAgi[JOBMAX+1]
new Handle:JobStr[JOBMAX+1]
new Handle:JobEnd[JOBMAX+1]

/* Client */
new Level[MAXPLAYERS+1]
new Cash[MAXPLAYERS+1]

new EXP[MAXPLAYERS+1]
new Job[MAXPLAYERS+1]
new JobLock[MAXPLAYERS+1]

new TempHP[MAXPLAYERS+1]
new TempStr[MAXPLAYERS+1]
new TempAgi[MAXPLAYERS+1]
new TempEnd[MAXPLAYERS+1]

/* Other */
new ZC
new LegValue
new Handle:Announce[MAXPLAYERS+1]
new Handle:CheckExp[MAXPLAYERS+1]
new ISJOBCONFIRM[MAXPLAYERS+1]
//new ISBUYCONFIRM[MAXPLAYERS+1]

public OnPluginStart()
{
	CreateConVar(Name, Version, Description, CVAR_FLAGS)
	
	RegConsoleCmd("rpgmenu", RPG_Menu)
	RegConsoleCmd("jobmenu", Job_Menu)
	RegConsoleCmd("jobconfirm", JobConfirmChooseMenu)
	RegConsoleCmd("jobinfo", JobInfo)
	//RegConsoleCmd("buymenu", BuyShop_Menu)
	//RegConsoleCmd("buyconfirm", BuyConfirmChooseMenu)
	
	RegAdminCmd("rpg_givelevel",GiveLevel,ADMFLAG_KICK,"rpg_givelevel [#userid|name] [number]")
	
	HookEvent("witch_killed", ExpWitchKilled)
	HookEvent("revive_success", ExpRevive)
	HookEvent("player_death", ExpInfectedKilled)
	HookEvent("heal_success", SetPlayerHP)
	HookEvent("player_first_spawn", SpawnFirst)
	HookEvent("player_spawn", PlayerSpawn)
	HookEvent("player_hurt", PlayerHurt)
	HookEvent("infected_hurt", InfectedHurt)
	HookEvent("round_start", RoundStart)
	
	ZC = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")
	LegValue = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue")
	
	SetCvars()
	AutoExecConfig(true, "l4d2_battle_rpg_2.0.6")
	LogMessage("[Battle-RPG 2] - Loaded")
}

public Action:SpawnFirst(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	CheckExp[target] = CreateTimer(GetConVarFloat(CfgCheckExpTimer), CheckExpTimer, target, TIMER_REPEAT)
	if(GetConVarInt(MsgAnnounceEnable) == 1)
	{
		Announce[target] = CreateTimer(GetConVarFloat(CfgAnnounceTimer), AnnounceTimer, target, TIMER_REPEAT)
	}
	
	if(!IsFakeClient(target))
	{
		PrintToChat(target, "\x04[Battle-RPG] \x03Welcome \x04BATTLE RPG \x03v2.0.6beta \x05by .#Zipcore")
		PrintToChat(target, "\x04[Battle-RPG] \x03Type \x04!rpgmenu\x03 in chat to see [Main-Menu]")
	}
}

//Reset on Player Spawn
public Action:PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(target) == TEAM_SURVIVORS && !IsFakeClient(target))
	{
		ResetTarget(target)
	}
}


//Round Start
public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i = 1; i < MaxClients; i++)
	{
		ResetTarget(i)
	}
}

public Action:SetPlayerHP(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new HealSucTarget = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(HealSucTarget) == TEAM_SURVIVORS && !IsFakeClient(HealSucTarget))
	{
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), GetHealthMaxToSet(HealSucTarget), 4, true)
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), GetHealthMaxToSet(HealSucTarget), 4, true)
	}
}

stock CheatCommand(client, const String:command[], const String:arguments[])
{
    if (!client) return;
    new admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, admindata);
}

public Action:GiveLevel(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpg_givelevel [Name] [Amount of Level to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			Level[targetclient] += StringToInt(arg2)
		}
		CreateTimer(0.1, StatusUp, client)
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled;
}

SetCvars()
{
	/* Config Msg */
	MsgExpEnable = CreateConVar("rpg_msg_showexp","1","How much Skill Points to spend", FCVAR_PLUGIN)
	MsgAnnounceEnable = CreateConVar("rpg_msg_announce","1","Plugin announce if no job is selected", FCVAR_PLUGIN)
	CfgCheckExpTimer = CreateConVar("rpg_cfg_checkexp_timer","3.0","Check Exp timer", FCVAR_PLUGIN)
	CfgAnnounceTimer = CreateConVar("rpg_cfg_announce_timer","120.0","Plugin announce timer", FCVAR_PLUGIN)
	
	/* Infected EXP */
	HunExp = CreateConVar("rpg_exp_Hunter","2200", "EXP that Hunter gives", FCVAR_PLUGIN)
	SmoExp = CreateConVar("rpg_exp_Smoker","1900","EXP that Smoker gives", FCVAR_PLUGIN)
	BooExp = CreateConVar("rpg_exp_Boomer","1500","EXP that Boomer gives", FCVAR_PLUGIN)
	TanExp = CreateConVar("rpg_exp_Tank","10000","EXP that Tank gives", FCVAR_PLUGIN)
	WitExp = CreateConVar("rpg_exp_Witch","3500","EXP that Witch gives", FCVAR_PLUGIN)
	ReviveExp = CreateConVar("rpg_exp_revive","2500","EXP when you succeed Setting someone up", FCVAR_PLUGIN)
	
	/* LevelUpExp X*/
	LevelUpExp = CreateConVar("rpg_job_exp_levelup","5000","Level Up Exp", FCVAR_PLUGIN)
	
	/* ReqLevel of Job X*/
	JobReqLevel[0] = CreateConVar("rpg_job_reqlevel_0","0","ReqLevel of Job 0", FCVAR_PLUGIN)
	JobReqLevel[1] = CreateConVar("rpg_job_reqlevel_1","0","ReqLevel of Job 1", FCVAR_PLUGIN)
	JobReqLevel[2] = CreateConVar("rpg_job_reqlevel_2","10","ReqLevel of Job 2", FCVAR_PLUGIN)
	JobReqLevel[3] = CreateConVar("rpg_job_reqlevel_3","20","ReqLevel of Job 3", FCVAR_PLUGIN)
	JobReqLevel[4] = CreateConVar("rpg_job_reqlevel_4","30","ReqLevel of Job 4", FCVAR_PLUGIN)
	JobReqLevel[5] = CreateConVar("rpg_job_reqlevel_5","50","ReqLevel of Job 5", FCVAR_PLUGIN)
	JobReqLevel[6] = CreateConVar("rpg_job_reqlevel_6","75","ReqLevel of Job 6", FCVAR_PLUGIN)
	JobReqLevel[7] = CreateConVar("rpg_job_reqlevel_7","100","ReqLevel of Job 7", FCVAR_PLUGIN)
	JobReqLevel[8] = CreateConVar("rpg_job_reqlevel_8","150","ReqLevel of Job 8", FCVAR_PLUGIN)
	JobReqLevel[9] = CreateConVar("rpg_job_reqlevel_9","200","ReqLevel of Job 9", FCVAR_PLUGIN)
	JobReqLevel[10] = CreateConVar("rpg_job_reqlevel_10","250","ReqLevel of Job 10", FCVAR_PLUGIN)
	JobReqLevel[11] = CreateConVar("rpg_job_reqlevel_11","300","ReqLevel of Job 11", FCVAR_PLUGIN)
	JobReqLevel[12] = CreateConVar("rpg_job_reqlevel_12","350","ReqLevel of Job 12", FCVAR_PLUGIN)
	JobReqLevel[13] = CreateConVar("rpg_job_reqlevel_13","500","ReqLevel of Job 13", FCVAR_PLUGIN)
	
	/* Cash of Job X*/
	JobCash[0] = CreateConVar("rpg_job_cash_0","10000","Cash of Job 0", FCVAR_PLUGIN)
	JobCash[1] = CreateConVar("rpg_job_cash_1","10000","Cash of Job 1", FCVAR_PLUGIN)
	JobCash[2] = CreateConVar("rpg_job_cash_2","15000","Cash of Job 2", FCVAR_PLUGIN)
	JobCash[3] = CreateConVar("rpg_job_cash_3","20000","Cash of Job 3", FCVAR_PLUGIN)
	JobCash[4] = CreateConVar("rpg_job_cash_4","25000","Cash of Job 4", FCVAR_PLUGIN)
	JobCash[5] = CreateConVar("rpg_job_cash_5","50000","Cash of Job 5", FCVAR_PLUGIN)
	JobCash[6] = CreateConVar("rpg_job_cash_6","75000","Cash of Job 6", FCVAR_PLUGIN)
	JobCash[7] = CreateConVar("rpg_job_cash_7","100000","Cash of Job 7", FCVAR_PLUGIN)
	JobCash[8] = CreateConVar("rpg_job_cash_8","150000","Cash of Job 8", FCVAR_PLUGIN)
	JobCash[9] = CreateConVar("rpg_job_cash_9","250000","Cash of Job 9", FCVAR_PLUGIN)
	JobCash[10] = CreateConVar("rpg_job_cash_10","500000","Cash of Job 10", FCVAR_PLUGIN)
	JobCash[11] = CreateConVar("rpg_job_cash_11","750000","Cash of Job 11", FCVAR_PLUGIN)
	JobCash[12] = CreateConVar("rpg_job_cash_12","1000000","Cash of Job 12", FCVAR_PLUGIN)
	JobCash[13] = CreateConVar("rpg_job_cash_13","5000000","Cash of Job 13", FCVAR_PLUGIN)
	
	/* Health of Job X*/
	JobHealth[0] = CreateConVar("rpg_job_health_0","100","Health of Job 0", FCVAR_PLUGIN)
	JobHealth[1] = CreateConVar("rpg_job_health_1","100","Health of Job 1", FCVAR_PLUGIN)
	JobHealth[2] = CreateConVar("rpg_job_health_2","120","Health of Job 2", FCVAR_PLUGIN)
	JobHealth[3] = CreateConVar("rpg_job_health_3","130","Health of Job 3", FCVAR_PLUGIN)
	JobHealth[4] = CreateConVar("rpg_job_health_4","140","Health of Job 4", FCVAR_PLUGIN)
	JobHealth[5] = CreateConVar("rpg_job_health_5","150","Health of Job 5", FCVAR_PLUGIN)
	JobHealth[6] = CreateConVar("rpg_job_health_6","160","Health of Job 6", FCVAR_PLUGIN)
	JobHealth[7] = CreateConVar("rpg_job_health_7","170","Health of Job 7", FCVAR_PLUGIN)
	JobHealth[8] = CreateConVar("rpg_job_health_8","180","Health of Job 8", FCVAR_PLUGIN)
	JobHealth[9] = CreateConVar("rpg_job_health_9","200","Health of Job 9", FCVAR_PLUGIN)
	JobHealth[10] = CreateConVar("rpg_job_health_10","250","Health of Job 10", FCVAR_PLUGIN)
	JobHealth[11] = CreateConVar("rpg_job_health_11","300","Health of Job 11", FCVAR_PLUGIN)
	JobHealth[12] = CreateConVar("rpg_job_health_12","500","Health of Job 12", FCVAR_PLUGIN)
	JobHealth[13] = CreateConVar("rpg_job_health_13","1000","Health of Job 13", FCVAR_PLUGIN)
	
	/* HP of Job X*/
	JobHP[0] = CreateConVar("rpg_job_hp_0","0","HP of Job 0", FCVAR_PLUGIN)
	JobHP[1] = CreateConVar("rpg_job_hp_1","1","HP of Job 1", FCVAR_PLUGIN)
	JobHP[2] = CreateConVar("rpg_job_hp_2","2","HP of Job 2", FCVAR_PLUGIN)
	JobHP[3] = CreateConVar("rpg_job_hp_3","3","HP of Job 3", FCVAR_PLUGIN)
	JobHP[4] = CreateConVar("rpg_job_hp_4","4","HP of Job 4", FCVAR_PLUGIN)
	JobHP[5] = CreateConVar("rpg_job_hp_5","5","HP of Job 5", FCVAR_PLUGIN)
	JobHP[6] = CreateConVar("rpg_job_hp_6","6","HP of Job 6", FCVAR_PLUGIN)
	JobHP[7] = CreateConVar("rpg_job_hp_7","7","HP of Job 7", FCVAR_PLUGIN)
	JobHP[8] = CreateConVar("rpg_job_hp_8","8","HP of Job 8", FCVAR_PLUGIN)
	JobHP[9] = CreateConVar("rpg_job_hp_9","9","HP of Job 9", FCVAR_PLUGIN)
	JobHP[10] = CreateConVar("rpg_job_hp_10","10","HP of Job 10", FCVAR_PLUGIN)
	JobHP[11] = CreateConVar("rpg_job_hp_11","11","HP of Job 11", FCVAR_PLUGIN)
	JobHP[12] = CreateConVar("rpg_job_hp_12","12","HP of Job 12", FCVAR_PLUGIN)
	JobHP[13] = CreateConVar("rpg_job_hp_13","20","HP of Job 13", FCVAR_PLUGIN)
	
	/* Agi of Job X*/
	JobAgi[0] = CreateConVar("rpg_job_agi_0","0","Agi of Job 0", FCVAR_PLUGIN)
	JobAgi[1] = CreateConVar("rpg_job_agi_1","1","Agi of Job 1", FCVAR_PLUGIN)
	JobAgi[2] = CreateConVar("rpg_job_agi_2","2","Agi of Job 2", FCVAR_PLUGIN)
	JobAgi[3] = CreateConVar("rpg_job_agi_3","3","Agi of Job 3", FCVAR_PLUGIN)
	JobAgi[4] = CreateConVar("rpg_job_agi_4","4","Agi of Job 4", FCVAR_PLUGIN)
	JobAgi[5] = CreateConVar("rpg_job_agi_5","5","Agi of Job 5", FCVAR_PLUGIN)
	JobAgi[6] = CreateConVar("rpg_job_agi_6","6","Agi of Job 6", FCVAR_PLUGIN)
	JobAgi[7] = CreateConVar("rpg_job_agi_7","7","Agi of Job 7", FCVAR_PLUGIN)
	JobAgi[8] = CreateConVar("rpg_job_agi_8","8","Agi of Job 8", FCVAR_PLUGIN)
	JobAgi[9] = CreateConVar("rpg_job_agi_9","9","Agi of Job 9", FCVAR_PLUGIN)
	JobAgi[10] = CreateConVar("rpg_job_agi_10","10","Agi of Job 10", FCVAR_PLUGIN)
	JobAgi[11] = CreateConVar("rpg_job_agi_11","11","Agi of Job 11", FCVAR_PLUGIN)
	JobAgi[12] = CreateConVar("rpg_job_agi_12","12","Agi of Job 12", FCVAR_PLUGIN)
	JobAgi[13] = CreateConVar("rpg_job_agi_13","13","Agi of Job 13", FCVAR_PLUGIN)
	
	/* Str of Job X*/
	JobStr[0] = CreateConVar("rpg_job_str_0","0","Str of Job 0", FCVAR_PLUGIN)
	JobStr[1] = CreateConVar("rpg_job_str_1","1","Str of Job 1", FCVAR_PLUGIN)
	JobStr[2] = CreateConVar("rpg_job_str_2","2","Str of Job 2", FCVAR_PLUGIN)
	JobStr[3] = CreateConVar("rpg_job_str_3","3","Str of Job 3", FCVAR_PLUGIN)
	JobStr[4] = CreateConVar("rpg_job_str_4","4","Str of Job 4", FCVAR_PLUGIN)
	JobStr[5] = CreateConVar("rpg_job_str_5","5","Str of Job 5", FCVAR_PLUGIN)
	JobStr[6] = CreateConVar("rpg_job_str_6","6","Str of Job 6", FCVAR_PLUGIN)
	JobStr[7] = CreateConVar("rpg_job_str_7","7","Str of Job 7", FCVAR_PLUGIN)
	JobStr[8] = CreateConVar("rpg_job_str_8","8","Str of Job 8", FCVAR_PLUGIN)
	JobStr[9] = CreateConVar("rpg_job_str_9","9","Str of Job 9", FCVAR_PLUGIN)
	JobStr[10] = CreateConVar("rpg_job_str_10","10","Str of Job 10", FCVAR_PLUGIN)
	JobStr[11] = CreateConVar("rpg_job_str_11","11","Str of Job 11", FCVAR_PLUGIN)
	JobStr[12] = CreateConVar("rpg_job_str_12","12","Str of Job 12", FCVAR_PLUGIN)
	JobStr[13] = CreateConVar("rpg_job_str_13","13","Str of Job 13", FCVAR_PLUGIN)
	
	/* End of Job X*/
	JobEnd[0] = CreateConVar("rpg_job_end_1","0","End of Job 0", FCVAR_PLUGIN)
	JobEnd[1] = CreateConVar("rpg_job_end_1","1","End of Job 1", FCVAR_PLUGIN)
	JobEnd[2] = CreateConVar("rpg_job_end_2","2","End of Job 2", FCVAR_PLUGIN)
	JobEnd[3] = CreateConVar("rpg_job_end_3","3","End of Job 3", FCVAR_PLUGIN)
	JobEnd[4] = CreateConVar("rpg_job_end_4","4","End of Job 4", FCVAR_PLUGIN)
	JobEnd[5] = CreateConVar("rpg_job_end_5","5","End of Job 5", FCVAR_PLUGIN)
	JobEnd[6] = CreateConVar("rpg_job_end_6","6","End of Job 6", FCVAR_PLUGIN)
	JobEnd[7] = CreateConVar("rpg_job_end_7","7","End of Job 7", FCVAR_PLUGIN)
	JobEnd[8] = CreateConVar("rpg_job_end_8","8","End of Job 8", FCVAR_PLUGIN)
	JobEnd[9] = CreateConVar("rpg_job_end_9","9","End of Job 9", FCVAR_PLUGIN)
	JobEnd[10] = CreateConVar("rpg_job_end_10","10","End of Job 10", FCVAR_PLUGIN)
	JobEnd[11] = CreateConVar("rpg_job_end_11","11","End of Job 11", FCVAR_PLUGIN)
	JobEnd[12] = CreateConVar("rpg_job_end_12","12","End of Job 12", FCVAR_PLUGIN)
	JobEnd[13] = CreateConVar("rpg_job_end_13","13","End of Job 13", FCVAR_PLUGIN)
}

/* Reset Player */
ResetTarget(targetid)
{
	Job[targetid] = 0
	JobLock[targetid] = 0
	EXP[targetid] = 0
	TempStr[targetid] = 0
	TempAgi[targetid] = 0
	TempHP[targetid] = 0
	TempEnd[targetid] = 0	
	RebuildStatus(targetid)
}

/* Get Job Information */
GetHealthMaxToSet(targetid) //Job Basis Health + Temp Health Skill
{
	new MaxHealth = (GetJobHealth(Job[targetid])+TempHP[targetid])
	return MaxHealth
}
GetJobHealth(jobid)
{
	return GetConVarInt(JobHealth[jobid])
}
GetJobReqLevel(jobid)
{
	return GetConVarInt(JobReqLevel[jobid])
}
GetJobHP(jobid)
{
	return GetConVarInt(JobHP[jobid])
}
GetJobCash(jobid)
{
	return GetConVarInt(JobCash[jobid])
}
GetJobAgi(jobid)
{
	return GetConVarInt(JobAgi[jobid])
}
GetJobStr(jobid)
{
	return GetConVarInt(JobStr[jobid])
}
GetJobEnd(jobid)
{
	return GetConVarInt(JobEnd[jobid])
}
SetEndurance(client, health, endurance)
{
	SetEntityHealth(client, health+endurance)
}
SetEndReflect(client, health, endurance)
{
	if(health > endurance)
	{
		SetEntityHealth(client, health-endurance)
	}
	else
	{
		ForcePlayerSuicide(client)
	}
}
SetStrDamage(client, health, str)
{
	if(health > str)
	{
		SetEntityHealth(client, health-str)
	}
}
bool:IsPlayerTank(client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	else
	return false;
}

/* Get EXP Special Infected */
public Action:ExpInfectedKilled(Handle:event, String:event_name[], bool:dontBroadcast)	
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	new killed = GetClientOfUserId(GetEventInt(event, "userid"))
	new ZClass = GetEntData(killed, ZC)

	if(!IsFakeClient(killer) && GetClientTeam(killer) == TEAM_SURVIVORS && killer != 0)
	{
		new targetexp = EXP[killer]
		//Smoker
		if(ZClass == 1)
		{
			targetexp += GetConVarInt(SmoExp)
			if(GetConVarInt(MsgExpEnable) == 1)
			{
				PrintToChat(killer, "\x04[Battle-RPG]\x03You got \x04%d\x03 EXP by killing a \x04Smoker\x03!", GetConVarInt(SmoExp))
			}
		}
		//Boomer
		if(ZClass == 2)
		{
			targetexp += GetConVarInt(BooExp)
			if(GetConVarInt(MsgExpEnable) == 1)
			{
				PrintToChat(killer, "\x04[Battle-RPG]\x03You got \x04%d\x03 EXP by killing a \x04Boomer\x03!", GetConVarInt(BooExp))
			}
		}
		// Hunter
		if(ZClass == 3)
		{
			targetexp += GetConVarInt(HunExp)
			if(GetConVarInt(MsgExpEnable) == 1)
			{
				PrintToChat(killer, "\x04[Battle-RPG]\x03You got \x04%d\x03 EXP by killing a \x04Hunter\x03!", GetConVarInt(HunExp))
			}
		}
		// Tank
		if(IsPlayerTank(killed))
		{
			targetexp += GetConVarInt(TanExp)
			if(GetConVarInt(MsgExpEnable) == 1)
			{
				PrintToChat(killer, "\x04[Battle-RPG]\x03You got \x04%d\x03 EXP by killing a \x04Tank\x03!", GetConVarInt(TanExp))
			}
		}
		EXP[killer] = targetexp
	}
}

/* Get EXP Revive Someone*/
public Action:ExpRevive(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(Reviver) == TEAM_SURVIVORS && Reviver != Subject)
	{
		EXP[Reviver] += GetConVarInt(ReviveExp)
		RebuildStatus(Subject)
		if(GetConVarInt(MsgExpEnable) == 1)
		{
				PrintToChat(Reviver, "\x04[Battle-RPG]\x03You got \x04%d\x03 EXP by reviving \x04%N\x03!", GetConVarInt(ReviveExp), Subject)
		}
	}
}


/* Get EXP Witch Killed*/
public Action:ExpWitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(WitExp)
		if(GetConVarInt(MsgExpEnable) == 1)
		{
				PrintToChat(killer, "\x04[Battle-RPG]\x03You got \x04%d\x03 EXP by killing a \x04Witch\x03!", GetConVarInt(WitExp))
		}
	}
}

public Action:CheckExpTimer(Handle:timer, any:targetid)
{
	new TargetEXP = EXP[targetid]

	if(TargetEXP >= GetConVarInt(LevelUpExp))
	{
		EXP[targetid] -= GetConVarInt(LevelUpExp)
		LevelUp(targetid)
	}
}

public Action:AnnounceTimer(Handle:timer, any:targetid)
{
	if(Job[targetid] == 0 && GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid))
	{
		PrintToChat(targetid, "\x04[Battle-RPG] \x03You didn't selected a job! Type \x04!jobmenu\x03 in chat to see [Job-Menu]")
	}
}

public Action:LevelUp(targetid)
{
	Level[targetid] += 1
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Level increased up to \x04%d", Level[targetid])

	Cash[targetid] += GetJobCash(Job[targetid])
	TempHP[targetid] += GetJobHP(Job[targetid])
	TempStr[targetid] += GetJobStr(Job[targetid])
	TempAgi[targetid] += GetJobAgi(Job[targetid])
	TempEnd[targetid] += GetJobEnd(Job[targetid])
	
	RebuildStatus(targetid)
	
}

public Action:PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "dmg_health")
	
	if(GetClientTeam(hurted) == TEAM_SURVIVORS && !IsFakeClient(hurted))
	{
		if(TempEnd[hurted] <= 50)
		{
			new EndHealth = GetEventInt(event, "health")
			new Float:EndFloat = TempEnd[hurted]*0.01
			new EndAddHealth = RoundToNearest(dmg*EndFloat)
			SetEndurance(hurted, EndHealth, EndAddHealth)
		}
		else
		{
			new EndHealth = GetEventInt(event, "health")
			new EndAddHealth = RoundToNearest(dmg*0.5)
			SetEndurance(hurted, EndHealth, EndAddHealth)
			new Float:RefFloat = (TempEnd[hurted]-50)*0.01
			new RefDecHealth = RoundToNearest(dmg*RefFloat)
			new RefHealth = GetClientHealth(attacker)
			SetEndReflect(attacker, RefHealth, RefDecHealth)
		}
	}
	
	if(GetClientTeam(hurted) == TEAM_INFECTED)
	{
		new StrHealth = GetEventInt(event, "health")
		new Float:StrFloat = TempStr[attacker]*0.01
		new StrRedHealth = RoundToNearest(dmg*StrFloat)
		SetStrDamage(hurted, StrHealth, StrRedHealth)
	}
}

public Action:InfectedHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetEventInt(event, "entityid")
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "amount")
	if(1 <= attacker <= MaxClients)
	{
		if(GetClientTeam(attacker) == TEAM_SURVIVORS && !IsFakeClient(attacker))
		{
			new Float:StrFloat = TempStr[attacker]*0.01
			new StrRedHealth = RoundToNearest(dmg*StrFloat)
			if(GetEntProp(hurted, Prop_Data, "m_iHealth") > StrRedHealth)
			{
				SetEntProp(hurted, Prop_Data, "m_iHealth", GetEntProp(hurted, Prop_Data, "m_iHealth")-StrRedHealth)
			}
		}
	}
}

public Action:StatusUp(Handle:timer, any:client)
{
	RebuildStatus(client)
}

RebuildStatus(client)
{
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), GetHealthMaxToSet(client), 4, true)
	SetEntDataFloat(client, LegValue, 1.0*(1.0 + TempAgi[client]*0.01), true)
	if(TempAgi[client] < 50)
	{
		SetEntityGravity(client, 1.0*(1.0-(TempAgi[client]*0.005)))
	}
	else
	{
		SetEntityGravity(client, 0.50)
	}
}

////////////////////////////////////////////////

/* MENU START*/

/* RPG MENU*/

//RPG Menu
public Action:RPG_Menu(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		RPG_MenuFunc(client)
	}
	return Plugin_Handled
}

//RPG Menu Func
public Action:RPG_MenuFunc(targetid) 
{
	new Handle:menu = CreateMenu(RPG_MenuHandler)
	SetMenuTitle(menu, "Level: %d | Cash: %d $ | EXP: %d Exp", Level[targetid], Cash[targetid], EXP[targetid])

	AddMenuItem(menu, "option1", "Job Menu")
	AddMenuItem(menu, "option2", "Buyshop (off)")
	AddMenuItem(menu, "option3", "BackPack")
	
	SetMenuExitButton(menu, true)
	
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)

	return Plugin_Handled
}

public RPG_MenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0:
			{
				FakeClientCommand(client,"jobmenu")
			}
			case 1:
			{
				FakeClientCommand(client,"buymenu")
			}
			case 2:
			{
				FakeClientCommand(client,"pack")
			}
		}
	}
}

/* JobInfo*/
public Action:JobInfo(targetid, args)
{
	if(GetClientTeam(targetid) == TEAM_SURVIVORS)
	{
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Health: \x04%d\x03 HP(+\x04%d\x03 TempHP)", GetJobHealth(Job[targetid]), TempHP[targetid])
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Str: +\x04%d\x03% dmg, Agi: +\x04%d\x03% speed", TempStr[targetid], TempAgi[targetid])
		if(TempEnd[targetid] <= 50)
		{
			PrintToChat(targetid, "\x04[Battle-RPG] \x03Endurance: -\x04%d\x03% dmg (shield)", TempEnd[targetid])
		}
		else
		{
			PrintToChat(targetid, "\x04[Battle-RPG] \x03Endurance: -\x04%d\x03% dmg (shield) and +\x04%d\x03% dmg reflect", TempEnd[targetid], (TempEnd[targetid]-50))
		}
	}
	return Plugin_Handled
}

/* Job MENU*/

//Job Menu
public Action:Job_Menu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		Job_MenuFunc(client)
	}
	return Plugin_Handled
}

//Job Menu Func
public Action:Job_MenuFunc(targetid) 
{
	new Handle:menu = CreateMenu(Job_MenuHandler)

	SetMenuTitle(menu, "Level: %d | NextLv: -%dExp", Level[targetid], (GetConVarInt(LevelUpExp)-EXP[targetid]))

	AddMenuItem(menu, "option1", "Job Info")
	AddMenuItem(menu, "option2", "Civilian")
	AddMenuItem(menu, "option3", "Scout")
	AddMenuItem(menu, "option4", "Soldier")
	AddMenuItem(menu, "option5", "Medic")
	AddMenuItem(menu, "option6", "Drug Dealer")
	AddMenuItem(menu, "option7", "Sniper")
	AddMenuItem(menu, "option8", "Weapon Dealer")
	AddMenuItem(menu, "option9", "Pyrotechnical")
	AddMenuItem(menu, "option10", "Witch Hunter") 
	AddMenuItem(menu, "option11", "Tank Buster")
	AddMenuItem(menu, "option12", "Ninja")
	AddMenuItem(menu, "option13", "General")
	AddMenuItem(menu, "option14", "Fuck Me IM FAMOUS!!")
	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Job_MenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		if(itemNum == 0 && Job[client] > 0)
		{
			FakeClientCommand(client, "jobinfo")
		}
		else if(itemNum == 0 && Job[client] == 0)
		{
			PrintToChat(client, "\x04[Battle-RPG] \x03You didn't select a job!")
			FakeClientCommand(client, "jobmenu")
		}
		else
		{
			ISJOBCONFIRM[client] = itemNum
			FakeClientCommand(client, "jobconfirm")
		}
	}
}

public Action:JobConfirmChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		JobConfirmFunc(client)
	}
	return Plugin_Handled
}

public Action:JobConfirmFunc(targetid)
{
	new Handle:menu = CreateMenu(JobConfirmHandler)
	SetMenuTitle(menu, "Sure? You will loose all your TempSkills!")
	AddMenuItem(menu, "option1", "Yes")
	AddMenuItem(menu, "option2", "No")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public JobConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select && itemNum == 0 && Level[client] >= GetJobReqLevel(ISJOBCONFIRM[client]) && JobLock[client] == 0)
	{
		if(ISJOBCONFIRM[client] == 0)
		{
			JobLock[client] = 0
			Job[client] = 0
		}
		else
		{
			JobLock[client] = 1
			Job[client] = ISJOBCONFIRM[client]
		}
		if(Job[client] == 1) //Civilian
		{
			//P. Weapon
			CheatCommand(client, "give", "smg")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			//Other Items
		}
		if(Job[client] == 2) //Scout
		{
			//P. Weapon
			CheatCommand(client, "give", "hunting_rifle")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			//Other Items
		}
		if(Job[client] == 3) //Soldier
		{
			//P. Weapon
			CheatCommand(client, "give", "rifle")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			//Other Items
		}
		if(Job[client] == 4) //Medic
		{
			//P. Weapon
			CheatCommand(client, "give", "smg")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "pipe_bomb")
			CheatCommand(client, "give", "first_aid_kit")
			//Other Items
		}
		if(Job[client] == 5) //Drug Dealer
		{
			//P. Weapon
			CheatCommand(client, "give", "hunting_rifle")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "first_aid_kit")
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "pain_pills")
			//Other Items
		}
		if(Job[client] == 6) //Sniper
		{
			//P. Weapon
			CheatCommand(client, "give", "hunting_rifle")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			//Other Items
			CheatCommand(client, "give", "upgradepack_explosive")
			CheatCommand(client, "give", "pipe_bomb")
		}
		if(Job[client] == 7) //Weapon Dealer
		{
			//P. Weapon
			CheatCommand(client, "give", "rifle")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			//Other Items
			CheatCommand(client, "give", "pipe_bomb")
			CheatCommand(client, "give", "molotov")
		}
		if(Job[client] == 8) //Pyrotechnical
		{
			//P. Weapon
			CheatCommand(client, "give", "autoshotgun")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			//Other Items
			CheatCommand(client, "give", "pipe_bomb")
			CheatCommand(client, "give", "molotov")
		}
		if(Job[client] == 9) //Witch Hunter
		{
			//P. Weapon
			CheatCommand(client, "give", "autoshotgun")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "molotov")
			//Other Items
			CheatCommand(client, "give", "pipe_bomb")
		}
		if(Job[client] == 10) //Tank Buster
		{
			//P. Weapon
			CheatCommand(client, "give", "autoshotgun")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "first_aid_kit")
			CheatCommand(client, "give", "pain_pills")
			//Other Items
			CheatCommand(client, "give", "molotov")
			CheatCommand(client, "give", "pipe_bomb")
			CheatCommand(client, "give", "molotov")
		}
		if(Job[client] == 11) //Ninja
		{
			//P. Weapon
			CheatCommand(client, "give", "smg")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "first_aid_kit")
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "pain_pills")
			//Other Items
			CheatCommand(client, "give", "vomitjar")
			CheatCommand(client, "give", "molotov")
			CheatCommand(client, "give", "upgradepack_explosive")
		}
		if(Job[client] == 12) //General
		{
			//P. Weapon
			CheatCommand(client, "give", "smg")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "pain_pills")
			//Other Items
			CheatCommand(client, "give", "vomitjar")
			CheatCommand(client, "give", "pipe_bomb")
			CheatCommand(client, "give", "molotov")
			CheatCommand(client, "give", "upgradepack_explosive")
		}
		if(Job[client] == 13) //Fuck Me IM FAMOUS!!
		{
			//P. Weapon
			CheatCommand(client, "give", "rifle")
			//S. Weapon
			CheatCommand(client, "give", "pistol")
			//Health Item
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "pain_pills")
			CheatCommand(client, "give", "first_aid_kit")
			//Other Items
			CheatCommand(client, "give", "vomitjar")
			CheatCommand(client, "give", "pipe_bomb")
			CheatCommand(client, "give", "molotov")
			//Special Items :D
			CheatCommand(client, "give", "molotov")
			CheatCommand(client, "give", "pipe_bomb")
			CheatCommand(client, "give", "molotov")
		}
		
		EXP[client] = 0
		TempStr[client] = 0
		TempAgi[client] = 0
		TempHP[client] = 0
		TempEnd[client] = 0	
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), GetHealthMaxToSet(client), 4, true)
		SetEntData(client, FindDataMapOffs(client, "m_iHealth"), GetHealthMaxToSet(client), 4, true)
		CheatCommand(client, "give", "health")
		RebuildStatus(client)
		PrintToChat(client, "\x04[Battle-RPG] \x03Job Confirmed!")
	}
	else if(action == MenuAction_Select && itemNum == 0 && Job[client] != 0)
	{
		PrintToChat(client, "\x04[Battle-RPG] \x03You have already choosen a job this round")
		FakeClientCommand(client,"jobmenu")
	}
	
	if(action == MenuAction_Select && itemNum == 0 && Level[client] < GetJobReqLevel(ISJOBCONFIRM[client]))
	{
		PrintToChat(client, "\x04[Battle-RPG] \x03Need Level %d Your Level: %d", GetJobReqLevel(ISJOBCONFIRM[client]), Level[client])
		FakeClientCommand(client,"jobmenu")
	}

}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
