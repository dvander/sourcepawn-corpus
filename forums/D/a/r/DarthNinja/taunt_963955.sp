#include <sourcemod>
#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
	name = "Taunt-a-Noob",
	author = "DarthNinja",
	description = "Makes a client taunt",
	version = "1.2",
	url = "www.AlliedMods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_taunt", Command_FTaunt, ADMFLAG_SLAY, "sm_taunt <#userid|name> - Forces player(s) to taunt if alive");
	CreateConVar("TauntaNoobVersion", "1.2", "Taunt a Noob Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
}

public Action:Command_FTaunt( client, args )
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_taunt <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:taunttarget[32];
	GetCmdArg(1, taunttarget, sizeof(taunttarget));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			taunttarget,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		PerformFakeExec(client, target_list[i], "taunt");
	}
	
	return Plugin_Handled;
}

stock PerformFakeExec(client, target, const String:cmd[])
{
	FakeClientCommandEx(target, "taunt");
	LogAction(client, target, "%L forced %L to taunt.", client, target);
}
