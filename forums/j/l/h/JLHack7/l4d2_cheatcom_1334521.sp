#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Cheat Command",
	author = "JLHack7 + Zuko",
	description = "Cheat command",
	version = VERSION,
}

public OnPluginStart()
{
	RegAdminCmd("sm_cheat2", Command_CheatCom, ADMFLAG_SLAY, "Executes command reguardless of cheat flags");
	RegAdminCmd("sm_rcheat", Command_RconCheat, ADMFLAG_BAN, "Executes cheat command to server");
}

//Cheat Command
public Action:Command_CheatCom(client, args)
{
	decl String:newcom[80];
	decl String:newargs[150];
		
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_cheat <command>");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, newcom, sizeof(newcom));
		GetCmdArgString(newargs, sizeof(newargs));
		if (client == 0)
		{
			new flags = GetCommandFlags(newcom);	
			SetCommandFlags(newcom, flags & ~FCVAR_CHEAT);	
			ServerCommand("%s", newargs);
			SetCommandFlags(newcom, flags|FCVAR_CHEAT);
		
		}	
		else
		{
			if (IsClientConnected(client) && IsClientInGame(client))
			{
				new flags = GetCommandFlags(newcom);	
				SetCommandFlags(newcom, flags & ~FCVAR_CHEAT);	
				FakeClientCommand(client, "%s", newargs);
				SetCommandFlags(newcom, flags);
			}
			
		}

	}
	return Plugin_Handled;
}
//End of Cheat Command

//Rcon Cheat Command
public Action:Command_RconCheat(client, args)
{
	decl String:newcom[80];
	decl String:newargs[150];
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_rcheat <command>");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, newcom, sizeof(newcom));
		GetCmdArgString(newargs, sizeof(newargs));
		new flags = GetCommandFlags(newcom);
		SetCommandFlags(newcom, flags & ~FCVAR_CHEAT);
		ServerCommand("%s", newargs);
		SetCommandFlags(newcom, flags);
	}
	return Plugin_Handled;
}
//End of Rcon Cheat Command
