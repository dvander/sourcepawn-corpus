#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[L4D] Advanced spawn items",
	author = "Jonny",
	description = "Plugin drops some items from killed special-infected",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_advspawnitem", Command_SpawnItem, ADMFLAG_CHANGEMAP, "sm_advspawnitem <parameters>");
}

public Action:Command_SpawnItem(client, args)
{
	if (args < 8)
	{
		ReplyToCommand(client, "[SM] Usage: sm_advspawnitem <parameters>");
		return Plugin_Handled;
	}
	
	decl Float:VecDirection[3];
	decl Float:VecOrigin[3];
	decl Float:VecAngles[3];
	decl String:modelname[64];
	GetCmdArg(1, modelname, sizeof(modelname));

	decl String:TempString[20];
	GetCmdArg(2, TempString, sizeof(TempString));
	VecDirection[0] = StringToFloat(TempString);
	GetCmdArg(3, TempString, sizeof(TempString));
	VecDirection[1] = StringToFloat(TempString);
	GetCmdArg(4, TempString, sizeof(TempString));
	VecDirection[2] = StringToFloat(TempString);
	GetCmdArg(5, TempString, sizeof(TempString));
	VecOrigin[0] = StringToFloat(TempString);
	GetCmdArg(6, TempString, sizeof(TempString));
	VecOrigin[1] = StringToFloat(TempString);
	GetCmdArg(7, TempString, sizeof(TempString));
	VecOrigin[2] = StringToFloat(TempString);
	GetCmdArg(8, TempString, sizeof(TempString));
	VecAngles[0] = 0.0;
	VecAngles[1] = StringToFloat(TempString);
	VecAngles[2] = 0.0;
	
	new spawned_item = CreateEntityByName(modelname);

	DispatchKeyValue(spawned_item, "model", "Custom_Spawn");
	DispatchKeyValueFloat(spawned_item, "MaxPitch", 360.00);
	DispatchKeyValueFloat(spawned_item, "MinPitch", -360.00);
	DispatchKeyValueFloat(spawned_item, "MaxYaw", 90.00);
	DispatchSpawn(spawned_item);

	DispatchKeyValueVector(spawned_item, "Angles", VecAngles);
	DispatchSpawn(spawned_item);
	TeleportEntity(spawned_item, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}