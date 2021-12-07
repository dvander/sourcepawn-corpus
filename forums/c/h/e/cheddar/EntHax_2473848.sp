#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

static const int ACCESS_FLAG = ADMFLAG_ROOT;

static char buffer[128], value_buffer[16], result_buffer[128], type_char[4];

public Plugin myinfo = 
{
	name		= "EntHax",
	author		= "Cheddar (rewritten by Grey83)",
	description	= "Gets/Sets Entity Properties in Game",
	version		= "0.08",
	url			= "https://forums.alliedmods.net/showthread.php?t=291045"
}

public void OnPluginStart() 
{
	RegAdminCmd("getentindex", getentindex, ACCESS_FLAG, "Gets ALL Entity Indexes based on Classname");
	RegAdminCmd("entpropint", entpropint, ACCESS_FLAG, "Gets/Sets int VALUE of PROPERTY for given ENTITY INDEX");
	RegAdminCmd("entpropfloat", entpropfloat, ACCESS_FLAG, "Gets/Sets float VALUE of PROPERTY for given ENTITY INDEX");
	RegAdminCmd("entpropstring", entpropstring, ACCESS_FLAG, "Gets/Sets string VALUE of PROPERTY for given ENTITY INDEX");
	RegAdminCmd("entrespawn", entrespawn, ACCESS_FLAG, "Respawns Entity at given Index");
	RegAdminCmd("setentitymodel", setentitymodel, ACCESS_FLAG, "Respawns Entity at given Index");
	RegAdminCmd("sv_clear", SV_Clear, ACCESS_FLAG, "Clears the console");
}

public Action getentindex(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[EntHax] Usage: getentindex <classname>");
		return Plugin_Handled;
	}

	GetCmdArg(1, buffer, sizeof(buffer));
	PrintToConsole(client, " \n[EntHax] Finding entities named '%s'", buffer);

	int ent = -1, num;
	while((ent = FindEntityByClassname(ent, buffer)) != -1)
	{
		num++;
		PrintToConsole(client, "	%3i) %i", num, ent);
	}
	if(!num) PrintToConsole(client, "	 [EntHax] ERROR: No entities with specified classname were found!");

	type_char[0] = '\0';
	PrintToConsole(client, type_char);

	return Plugin_Handled;
}

public Action entpropint(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[EntHax] Usage: getentpropint <entity_index> <property> [value]");
		return Plugin_Handled;
	}

	GetCmdArg(1, buffer, sizeof(buffer));
	int index_int = StringToInt(buffer);
	if(!IsValidEntity(index_int))
	{
		ReplyToCommand(client, "[EntHax] ERROR: Entity with index #%i is invalid!", index_int);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	if(!HasEntProp(index_int, Prop_Data, buffer))
	{
		ReplyToCommand(client, "[EntHax] ERROR: Entity #%i does not contain property '%s'!", index_int, buffer);
		return Plugin_Handled;
	}

	int value_int;
	if(args > 2)
	{
		GetCmdArg(3, value_buffer, sizeof(value_buffer));
		SetEntProp(index_int, Prop_Data, buffer, (value_int = StringToInt(value_buffer)));
		type_char = "SET";
	}
	else
	{
		value_int = GetEntProp(index_int, Prop_Data, buffer);
		type_char = "GET";
	}

	PrintToConsole(client, " \n[EntHax] %s Index --> %i", type_char, index_int);
	PrintToConsole(client, "	 %s Type ---> %s", type_char, buffer);
	PrintToConsole(client, "	 %s Value --> %i\n ", type_char, value_int);

	return Plugin_Handled;
}

public Action entpropfloat(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[EntHax] Usage: entpropfloat <entity_index> <property> [value]");
		return Plugin_Handled;
	}

	GetCmdArg(1, buffer, sizeof(buffer));
	int index_int = StringToInt(buffer);
	if(!IsValidEntity(index_int))
	{
		ReplyToCommand(client, "[EntHax] ERROR: Entity with index #%i is invalid!", index_int);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	if(!HasEntProp(index_int, Prop_Data, buffer))
	{
		ReplyToCommand(client, "[EntHax] Entity #%i does not contain property '%s'!", index_int, buffer);
		return Plugin_Handled;
	}

	float value_float;
	if(args > 2)
	{
		GetCmdArg(3, value_buffer, sizeof(value_buffer));
		value_float = StringToFloat(value_buffer);
		SetEntPropFloat(index_int, Prop_Data, buffer, (value_float = StringToFloat(value_buffer)));
		type_char = "SET";
	}
	else
	{
		value_float = GetEntPropFloat(index_int, Prop_Data, buffer);
		type_char = "GET";
	}

	PrintToConsole(client, " \n[EntHax] %s Index --> %i", type_char, index_int);
	PrintToConsole(client, "	 %s Type ---> %s", type_char, buffer);
	PrintToConsole(client, "	 %s Value -> %f\n ", type_char, value_float);

	return Plugin_Handled;
}

public Action entpropstring(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[EntHax] Usage: entpropstring <entity_index> <property> [value]");
		return Plugin_Handled;
	}

	GetCmdArg(1, buffer, sizeof(buffer));
	int index_int = StringToInt(buffer);
	if(!IsValidEntity(index_int))
	{
		ReplyToCommand(client, "[EntHax] ERROR: Entity with index #%i is invalid!", index_int);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	if(!HasEntProp(index_int, Prop_Data, buffer))
	{
		ReplyToCommand(client, "[EntHax] Entity #%i does not contain property '%s'!", index_int, buffer);
		return Plugin_Handled;
	}

	if(args > 2)
	{
		GetCmdArg(3, result_buffer, sizeof(result_buffer));
		SetEntPropString(index_int, Prop_Data, buffer, result_buffer);
		type_char = "SET";
	}
	else
	{
		GetEntPropString(index_int, Prop_Data, buffer, result_buffer, sizeof(result_buffer));
		type_char = "GET";
	}

	PrintToConsole(client, " \n[EntHax] %s Index --> %i", type_char, index_int);
	PrintToConsole(client, "	 %s Type ---> %s", type_char, buffer);
	PrintToConsole(client, "	 %s Value -> %s\n ", type_char, result_buffer);

	return Plugin_Handled;
}

public Action entrespawn(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[EntHax] Usage: respawnent <entity_index>");
		return Plugin_Handled;
	}

	GetCmdArg(1, buffer, sizeof(buffer));

	static int index_int;
	if(DispatchSpawn((index_int = StringToInt(buffer))))
		PrintToConsole(client, " \n[EntHax] Entity #%i has been respawned",index_int);
	else PrintToConsole(client, " \n[EntHax] ERROR: Can't respawn entity with index #%i!\n ",index_int);

	return Plugin_Handled;
}

public Action setentitymodel(int client, int args)
{
	GetCmdArg(1, buffer, sizeof(buffer));
	static int index_int;
	index_int = StringToInt(buffer);
	GetCmdArg(2, buffer, sizeof(buffer));
	SetEntityModel(index_int, buffer);
	PrintToConsole(client, " \n[EntHax] Entity #%i now has model:%s",index_int,buffer);	
	return Plugin_Handled;
}

public Action SV_Clear(int client, int args)
{
	type_char[0] = '\0';
	for(int i; i < 36; i++)
	{
		PrintToConsole(client, type_char);
	}

	return Plugin_Handled;
}