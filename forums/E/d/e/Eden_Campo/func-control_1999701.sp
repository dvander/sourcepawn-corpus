#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
    name = "Function Control",
    author = "Eden.Campo",
    description = "Easy-to-use func controller.",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_func_control", Command_ControlFunc, ADMFLAG_ROOT);
	RegAdminCmd("sm_fc", Command_ControlFunc, ADMFLAG_ROOT);
	RegAdminCmd("sm_func_look", Command_FuncLook, ADMFLAG_ROOT);
	RegAdminCmd("sm_fl", Command_FuncLook, ADMFLAG_ROOT);
	RegAdminCmd("sm_func_details", Command_FuncDetails, ADMFLAG_ROOT);
	RegAdminCmd("sm_fd", Command_FuncDetails, ADMFLAG_ROOT);
	RegAdminCmd("sm_func_create", Command_FuncCreate, ADMFLAG_ROOT);
	RegAdminCmd("sm_fc", Command_FuncCreate, ADMFLAG_ROOT);
	RegAdminCmd("sm_func_teleport", Command_FuncTele, ADMFLAG_ROOT);
	RegAdminCmd("sm_ft", Command_FuncTele, ADMFLAG_ROOT);
	RegAdminCmd("sm_func_look_teleport", Command_FuncLookTele, ADMFLAG_ROOT);
	RegAdminCmd("sm_flt", Command_FuncLookTele, ADMFLAG_ROOT);
}

public Action:Command_ControlFunc(client, args)
{
	if(args < 2)
	{
		CPrintToChat(client, "{green}[Func Control]{default} Usage: !control_func <func> <input>");
		return Plugin_Handled;
	}
	
	new String:arg1[62];
	new String:arg2[62];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new Entity;
	while( (Entity = FindEntityByClassname(Entity, arg1) ) != -1)
	AcceptEntityInput(Entity, arg2);
	
	CPrintToChat(client, "{green}[Func Control]{default} Run entity control on func: %s. Input: %s", arg1, arg2);
	
	return Plugin_Handled;
}

public Action:Command_FuncLook(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Func Control]{default} Usage: !func_look <input>");
		return Plugin_Handled;
	}
	
	new String:arg1[62];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new Entity = GetClientAimTarget(client, false);
	
	if(!IsValidEntity(Entity))
	{
		CPrintToChat(client, "{green}[Func Control]{default} Entity not valid!");
		return Plugin_Handled;
	}
	
	AcceptEntityInput(Entity, arg1);
	
	new String:EntNum[400];
	new String:EntName[400];
	IntToString(Entity, EntNum, sizeof(EntNum));
	GetEntityClassname(Entity, EntName, sizeof(EntName));
	CPrintToChat(client, "{green}[Func Control]{default} Run entity control on: %s(%s). Input: %s", EntName, EntNum, arg1);
	
	return Plugin_Handled;
}

public Action:Command_FuncDetails(client, args)
{
	if(args > 0)
	{
		CPrintToChat(client, "{green}[Func Control]{default} Usage: !func_name");
		return Plugin_Handled;
	}
	
	new Entity = GetClientAimTarget(client, false);
	
	if(!IsValidEntity(Entity))
	{
		CPrintToChat(client, "{green}[Func Control]{default} Entity not valid!");
		return Plugin_Handled;
	}
	
	new String:EntNum[400];
	new String:EntName[400];
	IntToString(Entity, EntNum, sizeof(EntNum));
	GetEntityClassname(Entity, EntName, sizeof(EntName));
	CPrintToChat(client, "{green}[Func Control]{default} ---Entity Description---");
	CPrintToChat(client, "{green}[Func Control]{default} ---Entity Name: %s---", EntName);
	CPrintToChat(client, "{green}[Func Control]{default} ---Entity ID %s---", EntNum);
	
	return Plugin_Handled;
}

public Action:Command_FuncCreate(client, args)
{
	new String:arg[400];
	GetCmdArg(1, arg, sizeof(arg));
	
	new func = CreateEntityByName("prop_physics_multiplayer");
		
	DispatchKeyValue(func, "model", arg);
	DispatchKeyValue(func, "spawnflags", "256");
	DispatchKeyValueFloat(func, "physdamagescale", 0.0);
	DispatchKeyValueFloat(func, "ExplodeDamage", 0.0);
	DispatchKeyValueFloat(func, "ExplodeRadius", 0.0);
		
	DispatchSpawn(func);
	ActivateEntity(func);
	
	SetEntityModel(func, arg);
	
	new Float:pos[3];
	GetClientEyePosition(client, pos);
	TeleportEntity(func, pos, NULL_VECTOR, NULL_VECTOR);
	
	CPrintToChat(client, "{green}[Func Control]{default} Successfully created entity. Set model: %s", arg);
	
	return Plugin_Handled;
}

public Action:Command_FuncTele(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Func Control]{default} Usage: !func_teleport <func>");
		return Plugin_Handled;
	}

	new String:arg[400];
	GetCmdArg(1, arg, sizeof(arg));
	
	new Entity;
	while( (Entity = FindEntityByClassname(Entity, arg) ) != -1)
	{
		new Float:pos[3];
		GetClientEyePosition(client, pos);
		TeleportEntity(Entity, pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}

public Action:Command_FuncLookTele(client, args)
{
	if(args > 0)
	{
		CPrintToChat(client, "{green}[Func Control]{default} Usage: !func_look_tele");
		return Plugin_Handled;
	}
	
	new Entity = GetClientAimTarget(client, false);
	
	if(!IsValidEntity(Entity))
	{
		CPrintToChat(client, "{green}[Func Control]{default} Entity not valid!");
		return Plugin_Handled;
	}
	
	new Float:pos[3];
	GetClientEyePosition(client, pos);
	TeleportEntity(Entity, pos, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Handled;
}