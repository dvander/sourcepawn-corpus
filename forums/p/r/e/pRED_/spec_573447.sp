#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0"


public Plugin:myinfo = 
{
	name = "Spec",
	author = "pRED*",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_spec", Command_Spec, ADMFLAG_GENERIC);
}

Action:FindPlayer(client, String:target[])
{
	new num=trim_quotes(target)
	
	new targets[MAXPLAYERS];
	
	new String:buffername[2];
	new bool:bufferbool;
	
	new count = ProcessTargetString(target[num],
						   client, 
						   targets,
						   MAXPLAYERS,
						   0,
						   buffername,
						   1,
						   bufferbool);
	
	if (count < 1)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < count; i++)
	{
		ExecTeam(client, targets[i])
	}
	
	return Plugin_Handled;
}


public ExecTeam(client, target)
{
	CS_SwitchTeam(client, 1);
	
	PrintToChat(client,"\x01\x04Moved %N to spectator", client);
}

public Action:Command_Spec(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spec <name or #userid>");
		return Plugin_Handled;	
	}
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))

	return FindPlayer(client, Target)
}

trim_quotes(String:text[])
{
	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	
	return startidx
}