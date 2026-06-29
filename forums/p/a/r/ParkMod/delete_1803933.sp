#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.0.0"

new Handle:Remove_Disabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Delete",
	author = "PM",
	description = "PM.",
	version = 1.01,
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_delete", Command_Delete);
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






