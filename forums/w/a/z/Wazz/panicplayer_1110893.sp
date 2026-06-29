#pragma semicolon 1

#include <sourcemod>
#include <ctfplayershared>

public Plugin:myinfo =
{
	name = "Panic Player",
	author = "Wazz",
	description = "Sets panic on a player",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{	
	RegAdminCmd("sm_panic", Cmd_Panic, ADMFLAG_SLAY, "Sets panic on a player");
	
	LoadTranslations("common.phrases");
}

public Action:Cmd_Panic(client, args)
{
	if (args != 2 && args != 3)
	{
		ReplyToCommand(client, "Usage: sm_panic <target> <duration> <OPT:reason>");
		
		return Plugin_Handled;
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float:duration = 0.0;
	GetCmdArg(2, buffer, sizeof(buffer));
	duration = StringToFloat(buffer);
	
	for (new i = 0; i < target_count; i ++)
	{
		CTF_StunPlayer(target_list[i], duration, _, 193, 0);
	}
	
	if (duration)
	{
		if (args == 3)
		{
			GetCmdArg(3, buffer, sizeof(buffer));
			PrintToChatAll("%s has been panicked! (Reason: %s)", target_name, buffer);
		}
		else
		{
			PrintToChatAll("%s has been panicked!", target_name);	
		}
	}
	
	return Plugin_Handled;
}