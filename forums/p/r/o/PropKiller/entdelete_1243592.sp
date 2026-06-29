#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.0.0"

new Handle:Remove_Disabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Ent_Delete",
	author = "ZePropKiller",
	description = "It removes the command ent_remove, and makes ent_delete remove stuff. Along with other additions.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("ent_delete", Command_Delete);
	RegConsoleCmd("ent_remove", Command_Remove);
	RegConsoleCmd("ent_remove_all", Command_Remove);
	RegAdminCmd("sm_delete_all", Command_DeleteAll, ADMFLAG_KICK, "sm_delete_all [entity]");
	Remove_Disabled = CreateConVar("sm_remove_disabled", "1", "Remove ent_remove and ent_remove_all",FCVAR_PLUGIN,true,0.0,true,1.0);
}

// Thanks to exvel for the function below. Exvel posted that in the FindEntityByClassname API.
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;

	return FindEntityByClassname(startEnt, classname);
}

public Action:Command_Delete(client,args)
{
	if(!GetConVarBool(Remove_Disabled))
	{
		PrintToChat(client, "[SM] The server owner has disabled Ent_Delete.");
		return Plugin_Handled;
	}
	else
	{
		decl String:modelname[128];
		decl String:name[128];
		decl Ent2;
		Ent2 = GetClientAimTarget(client, false);
		GetEdictClassname(Ent2, name, sizeof(name));
		GetEntPropString(Ent2, Prop_Data, "m_ModelName", modelname, 128);
		PrintToChat(client, "(Removed %s: %s)", name, modelname);
		RemoveEdict(Ent2);
		return Plugin_Handled;
	}
}

public Action:Command_Remove(client, args)
{
	if(!GetConVarBool(Remove_Disabled))
	{
		decl String:modelname[128];
		decl String:name[128];
		decl Ent2;
		Ent2 = GetClientAimTarget(client, false);
		GetEdictClassname(Ent2, name, sizeof(name));
		GetEntPropString(Ent2, Prop_Data, "m_ModelName", modelname, 128);
		PrintToChat(client, "(Removed %s: %s)", name, modelname);
		RemoveEdict(Ent2);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "[SM] Ent_Remove is disabled. Please use Ent_Delete");
		return Plugin_Handled;
	}
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

	ShowActivity2(client, "[SM] ", "Removed all entities with classname: %s", eent);

	new index2 = -1;
	while ((index2 = FindEntityByClassname2(index2, eent)) != -1)
	RemoveEdict(index2);
	return Plugin_Handled;
}





