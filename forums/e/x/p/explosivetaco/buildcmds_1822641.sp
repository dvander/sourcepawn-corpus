#include <sourcemod>
#include <sdktools> 
   
public Plugin:myinfo =
{
	name = "Build Server Commands",
	author = "explosivetaco",
	description = "BuildCmds",
	version = "1.0.0.0",
	url = ""
};
 
public OnPluginStart()
{
	RegConsoleCmd("ent_delete", Command_del, "say hook");
	RegConsoleCmd("freezetrigger", Command_freeze, "say hook");
	RegConsoleCmd("unfreezetrigger", Command_unfreeze, "say hook");
	RegConsoleCmd("deletetrigger", Command_deltrigger, "say hook");
	RegConsoleCmd("ent_freeze", Command_Freezeit, "say hook");
	RegConsoleCmd("ent_unfreeze", Command_UnFreezeit, "say hook");
	new String:prop[32];
	GetCmdArg(1, prop, sizeof(prop));
}

 
public Action:Command_Freezeit(Client,args)
{
    	PrintToChat(Client, "[Freezed Entity]");
	decl Ent;       
	Ent = GetClientAimTarget(Client, false);

    	SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
	SetEntityMoveType(Ent, MOVETYPE_NONE);  
	return Plugin_Handled;
}

public Action:Command_UnFreezeit(Client,args)
{
    	PrintToChat(Client, "[Unfreezed Entity]");
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
    	SetEntProp(Ent, Prop_Data, "m_takedamage", 2, 1)
	SetEntityMoveType(Ent, MOVETYPE_VPHYSICS); 
	return Plugin_Handled;
}

public Action:Command_del(Client, args)
{
	FakeClientCommand(Client, "ent_remove");
	return Plugin_Handled
}

public Action:Command_freeze(Client, args)
{
	new String:prop[32];
	GetCmdArg(1, prop, sizeof(prop));
	
	if(StrEqual(prop,"!freeze"))
	{
	FakeClientCommand(Client, "ent_freeze");
	PrintToChat(Client, "[Freezed Entity]");
	return Plugin_Handled;
	}
		return Plugin_Handled;
}

public Action:Command_unfreeze(Client, args)
{
	new String:prop[32];
	GetCmdArg(1, prop, sizeof(prop));
	
	if(StrEqual(prop,"!unfreeze"))
	{
	FakeClientCommand(Client, "ent_unfreeze");
	PrintToChat(Client, "[Unfreezed Entity]");
	return Plugin_Handled;
	}
		return Plugin_Handled;
}

public Action:Command_deltrigger(Client, args)
{
	new String:prop[32];
	GetCmdArg(1, prop, sizeof(prop));
	
	if(StrEqual(prop,"!del"))
	{
	FakeClientCommand(Client, "ent_delete");
	PrintToChat(Client, "[Deleted Entity]");
	return Plugin_Handled;
	}
		return Plugin_Handled;
}
