#include <sourcemod>
#include <tf2>

public Plugin:myinfo = 
{
	name = "Bonk!",
	author = "Afronanny",
	description = "asdfasgadsfkjgahuihjk",
	version = "1.0",
	url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_bonkeffect", Command_BonkEffect, ADMFLAG_SLAY);
}

public Action:Command_BonkEffect(client, args)
{
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
	{
		if (IsClientInGame(targets[i]))
		{		
			TF2_AddCondition(targets[i], TFCond_Bonked, -1.0);
			FakeClientCommand(client, "taunt");
		}
	}
	return Plugin_Handled;
}
