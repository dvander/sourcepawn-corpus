#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Ent_Delete",
	author = "ZePropKiller",
	description = "It removes the command ent_remove, and makes ent_delete remove stuff. Along with other additions.",
	version = "1.1.5.0",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	RegConsoleCmd("ent_delete", Command_Delete);
	RegAdminCmd("ent_remove", Command_Remove, ADMFLAG_ROOT);
	RegAdminCmd("ent_remove_all", Command_Remove, ADMFLAG_ROOT);
	RegAdminCmd("sm_delete_all", Command_DeleteAll, ADMFLAG_KICK, "sm_delete_all [entity]");
}

// Thanks to exvel for the function below. Exvel posted that in the FindEntityByClassname API.
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;

	return FindEntityByClassname(startEnt, classname);
}

public Action:Command_Delete(client,args)
{
    PrintToChat(client, "(Removed Entity)");
    decl Ent;
    Ent = GetClientAimTarget(client, false);
	RemoveEdict(Ent);
	return Plugin_Handled;
}

public Action:Command_Remove(client, args)
{
	PrintToChat(client, "[SM] Ent_Remove is disabled. Please use Ent_Delete");
	return Plugin_Handled;
}

public Action:Command_DeleteAll(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_delete_all [entity]");
		return Plugin_Handled;
	}
	
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_delete_all [entity]");
		return Plugin_Handled;
	}

	decl String:eent[64];
	GetCmdArg(1, eent, sizeof(eent));
	
	new bool:tn_is_ml;
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Removed all entities with classname: %s", eent);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Removed all entities with classname: %s", eent);
	}
	new index2 = -1;
	while ((index2 = FindEntityByClassname2(index2, eent)) != -1)
	RemoveEdict(index2);
	return Plugin_Handled;
}





