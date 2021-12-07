#include <sourcemod>
#include <sdktools>

new iCurrentEntity = -1;

public OnPluginStart()
{
	RegConsoleCmd("sm_entcreate", CmdCreate);
	RegConsoleCmd("sm_entkey", CmdKey);
	RegConsoleCmd("sm_entspawn", CmdSpawn);
	RegConsoleCmd("sm_entcancel", CmdCancel);
	RegConsoleCmd("sm_entinput", CmdInput);
	RegConsoleCmd("sm_entdone", CmdDone);
}

public Action:CmdCreate(client, args)
{
	if(iCurrentEntity > 0)
	{
		PrintToChat(client, "There is another entity being modified");
		return Plugin_Handled;
	}
	
	decl String:arg[256];
	GetCmdArgString(arg, sizeof(arg));
	iCurrentEntity = CreateEntityByName(arg);
	return Plugin_Handled;
}

public Action:CmdKey(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "Wrong. (sm_entkey <key> <value>)");
		return Plugin_Handled;
	}
	if(iCurrentEntity <= 0)
	{
		PrintToChat(client, "No entity selected");
		return Plugin_Handled;
	}
	
	decl String:arg1[256], arg2[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(IsValidEntity(iCurrentEntity) && IsValidEdict(iCurrentEntity))
	{
		DispatchKeyValue(iCurrentEntity, arg1, arg2);
		return Plugin_Handled;
	}
	
	PrintToChat(client, "The entity is not valid!");
	return Plugin_Handled;
}

public Action:CmdSpawn(client, args)
{
	if(iCurrentEntity <= 0)
	{
		PrintToChat(client, "No entity selected");
		return Plugin_Handled;
	}
	decl Float:pos[3];
	GetClientEyePosition(client, Float:pos);
	DispatchSpawn(iCurrentEntity);
	TeleportEntity(iCurrentEntity, pos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

public Action:CmdCancel(client, args)
{
	if(iCurrentEntity <= 0)
	{
		PrintToChat(client, "No entity selected");
		return Plugin_Handled;
	}
	if(IsValidEntity(iCurrentEntity) && IsValidEdict(iCurrentEntity))
	{
		AcceptEntityInput(iCurrentEntity, "Kill");
		iCurrentEntity = -1;
		PrintToChat(client, "Canceled");
		return Plugin_Handled;
	}
	iCurrentEntity = -1;
	PrintToChat(client, "Canceled but the entity was not valid!");
	return Plugin_Handled;
}

public Action:CmdInput(client, args)
{
	if(iCurrentEntity <= 0)
	{
		PrintToChat(client, "No entity selected");
		return Plugin_Handled;
	}
	decl String:arg[256];
	GetCmdArgString(arg, sizeof(arg));
	if(IsValidEntity(iCurrentEntity) && IsValidEdict(iCurrentEntity))
	{
		AcceptEntityInput(iCurrentEntity, arg);
		iCurrentEntity = -1;
		return Plugin_Handled;
	}
	PrintToChat(client, "The entity is not valid!");
	return Plugin_Handled;
}

public Action:CmdDone(client, args)
{
	if(iCurrentEntity <= 0)
	{
		PrintToChat(client, "No entity selected");
		return Plugin_Handled;
	}
	if(IsValidEntity(iCurrentEntity) && IsValidEdict(iCurrentEntity))
	{
		iCurrentEntity = -1;
		PrintToChat(client, "Done [Released]");
		return Plugin_Handled;
	}
	iCurrentEntity = -1;
	PrintToChat(client, "Released but the entity was not valid!");
	return Plugin_Handled;
}