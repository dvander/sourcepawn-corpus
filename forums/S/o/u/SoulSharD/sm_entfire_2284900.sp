#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegAdminCmd("sm_entfire", Command_EntFire, ADMFLAG_CHEATS);
}

public Action:Command_EntFire(client, args)
{
	decl String:arg1[128], String:arg2[128], String:arg3[32], String:arg4[8];
	new Float:flDelay;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));

	flDelay = StringToFloat(arg4);
	if(!FireEntityInput(arg1, arg2, arg3, flDelay))
	{
		ReplyToCommand(client, "[SM] Unable to execute command.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

FireEntityInput(String:strTargetname[], String:strInput[], String:strParameter[]="", Float:flDelay=0.0)
{
	decl String:strBuffer[255];
	Format(strBuffer, sizeof(strBuffer), "OnUser1 %s:%s:%s:%f:1", strTargetname, strInput, strParameter, flDelay);
	
	new entity = CreateEntityByName("info_target");
	if(IsValidEdict(entity))
	{
		DispatchSpawn(entity);
		ActivateEntity(entity);
	
		SetVariantString(strBuffer);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		
		CreateTimer(0.0, DeleteEdict, entity);
		return true;
	}
	return false;
}

public Action:DeleteEdict(Handle:timer, any:entity)
{
	if(IsValidEdict(entity)) RemoveEdict(entity);
	return Plugin_Stop;
}