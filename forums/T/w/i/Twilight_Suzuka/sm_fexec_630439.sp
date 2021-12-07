#include <sourcemod>

public Plugin:myinfo =
{
	name = "Client Execute",
	author = "Twilight Suzuka",
	description = "Execute fake commands on clients for SourceMod",
	version = "1.0.0.1",
	url = "http://www.sourcemod.net"
};

public OnPluginStart ()
{
	CreateConVar ("sm_fexec_version", "1.0.0.1", "Client Fake Exec version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	RegAdminCmd ("sm_fexec", ClientFakeExec, ADMFLAG_RCON);
	
	LoadTranslations("common.phrases");
}

public Action:ClientFakeExec( client, args )
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fexec <#userid|name> <cmd>");
		return Plugin_Handled;
	}

	decl String:arg[65], String:cmd[192];
	GetCmdArg(1, arg, sizeof(arg) );
	GetCmdArg(2, cmd, sizeof(cmd) );
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
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
		PerformFakeExec(client, target_list[i], cmd);
	}
	
	return Plugin_Handled;
}

stock PerformFakeExec(client, target, const String:cmd[])
{
	FakeClientCommandEx(target,cmd);
	//LogAction(client, target, "\"%L\" executed command %s on \"%L\".", client, cmd, target);
}
