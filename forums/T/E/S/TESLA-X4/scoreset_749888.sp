#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new nfrag = 0
new ndeath = 0

public Plugin:myinfo = 
{
	name = "Score Set",
	author = "TESLA-X4",
	description = "Allows admins to set players' frag and death counts",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	
	CreateConVar("scoreset_version", PLUGIN_VERSION, "Version of Score Set on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	RegAdminCmd("sm_killset", Command_KillSet, ADMFLAG_CUSTOM1, "Sets the target's frag count")
	RegAdminCmd("sm_killadd", Command_KillAdd, ADMFLAG_CUSTOM1, "Adds to the target's frag count")
	RegAdminCmd("sm_deathset", Command_DeathSet, ADMFLAG_CUSTOM1, "Sets the target's death count")
	RegAdminCmd("sm_deathadd", Command_DeathAdd, ADMFLAG_CUSTOM1, "Adds to the target's death count")
}

public Action:Command_KillSet(client, args)
{
	decl String:target[65]
	decl String:sfrags[11]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_killset <#userid|name> <new frag count (integer)>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, sfrags, sizeof(sfrags))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	new sfrag = StringToInt(sfrags)
	for (new i = 0; i < target_count; i++)
	{
		PerformKillSet(target_list[i], sfrag)
		if (client > 0)
		{
			PrintToChat(client, "\x01[SM] Set \x04%N\x01's frag count (new frags: \x04%i\x01)", target_list[i], sfrag)
		}
		LogAction(client, target_list[i], "\"%L\" set \"%L\"'s frag count (new frags: \"%i\")", client, target_list[i], sfrag)
	}
	return Plugin_Handled
}

public Action:Command_KillAdd(client, args)
{
	decl String:target[65]
	decl String:afrags[11]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_killadd <#userid|name> <frags to add (integer)>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, afrags, sizeof(afrags))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	new afrag = StringToInt(afrags)
	for (new i = 0; i < target_count; i++)
	{
		nfrag = PerformKillAdd(target_list[i], afrag)
		if (client > 0)
		{
			PrintToChat(client, "\x01[SM] Added \x04%i\x01 frags to \x04%N\x01's score (new frags: \x04%i\x01)", afrag, target_list[i], nfrag)
		}
		LogAction(client, target_list[i], "\"%L\" added \"%i\" frags to \"%L\"'s score (new frags: \"%i\")", client, afrag, target_list[i], nfrag)
	}
	return Plugin_Handled
}

public Action:Command_DeathSet(client, args)
{
	decl String:target[65]
	decl String:sdeaths[11]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_deathset <#userid|name> <new death count (integer)>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, sdeaths, sizeof(sdeaths))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	new sdeath = StringToInt(sdeaths)
	for (new i = 0; i < target_count; i++)
	{
		PerformDeathSet(target_list[i], sdeath)
		if (client > 0)
		{
			PrintToChat(client, "\x01[SM] Set \x04%N\x01's death count (new deaths: \x04%i\x01)", target_list[i], sdeath)
		}
		LogAction(client, target_list[i], "\"%L\" set \"%L\"'s death count (new deaths: \"%i\")", client, target_list[i], sdeath)
	}
	return Plugin_Handled
}

public Action:Command_DeathAdd(client, args)
{
	decl String:target[65]
	decl String:adeaths[11]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_deathadd <#userid|name> <deaths to add (integer)>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, adeaths, sizeof(adeaths))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	new adeath = StringToInt(adeaths)
	for (new i = 0; i < target_count; i++)
	{
		ndeath = PerformDeathAdd(target_list[i], adeath)
		if (client > 0)
		{
			PrintToChat(client, "\x01[SM] Added \x04%i\x01 deaths to \x04%N\x01's death count (new deaths: \x04%i\x01)", adeath, target_list[i], ndeath)
		}
		LogAction(client, target_list[i], "\"%L\" added \"%i\" deaths to \"%L\"'s death count (new deaths: \"%i\")", client, adeath, target_list[i], ndeath)
	}
	return Plugin_Handled
}

public PerformKillSet(client, fscore)
{
	SetScore(client, fscore)
}

public PerformKillAdd(client, ascore)
{
	new cfrag = GetClientFrags(client)
	new fscore = cfrag + ascore
	SetScore(client, fscore)
	return fscore
}

public PerformDeathSet(client, fdeath)
{
	SetDeaths(client, fdeath)
}

public PerformDeathAdd(client, adeath)
{
	new cdeath = GetClientDeaths(client)
	new fdeath = cdeath + adeath
	SetDeaths(client, fdeath)
	return fdeath
}

public SetScore(client, score)
{
	if (IsClientInGame(client))
		SetEntProp(client, Prop_Data, "m_iFrags", score);
}

public SetDeaths(client, deaths)
{
	if (IsClientInGame(client))
		SetEntProp(client, Prop_Data, "m_iDeaths", deaths);
}
