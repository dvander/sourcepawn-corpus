#define PLUGIN_FULLNAME                 "BuildCMDS" // Used when printing the plugin name anywhere
#define PLUGIN_AUTHOR                   "explosivetaco"       // Author of the plugin
#define PLUGIN_DESCRIPTION              "Build Commands For A Build Server" // Description of the plugin
#define PLUGIN_VERSION                  "2.1"                               // Version of the plugin
#define PLUGIN_URL                      "www.sourcemod.net"                // URL associated with the project
#define PLUGIN_CVAR_PREFIX              "buildcmdsv2" // Prefix for plugin cvars
#include <sourcemod>
#include <sdktools> 
   
public Plugin:myinfo = 
{
    name           = PLUGIN_FULLNAME,
    author         = PLUGIN_AUTHOR,
    description    = PLUGIN_DESCRIPTION,
    version        = PLUGIN_VERSION,
    url            = PLUGIN_URL
}
 
public OnPluginStart()
{
	RegConsoleCmd("sm_delete", Command_del);
	RegConsoleCmd("freezetrigger", Command_freeze);
	RegConsoleCmd("unfreezetrigger", Command_unfreeze);
	RegConsoleCmd("deletetrigger", Command_deltrigger);
	RegConsoleCmd("sm_freezeent", Command_Freezeit);
	RegConsoleCmd("sm_unfreezeent", Command_UnFreezeit);
}

 
public Action:Command_Freezeit(Client,args)
{
	decl Ent;       
	Ent = GetClientAimTarget(Client, false);

    	SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
	SetEntityMoveType(Ent, MOVETYPE_NONE);  
	return Plugin_Handled
}

public Action:Command_UnFreezeit(Client,args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
    	SetEntProp(Ent, Prop_Data, "m_takedamage", 2, 1)
	SetEntityMoveType(Ent, MOVETYPE_VPHYSICS); 
	return Plugin_Handled
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
	
	if(StrEqual(prop,"!freezeprop"))
	{
	FakeClientCommand(Client, "sm_freezeprop");
	PrintToChat(Client, "[Freezed Entity]");
	return Plugin_Handled
	}
		return Plugin_Handled
}

public Action:Command_unfreeze(Client, args)
{
	new String:prop[32];
	GetCmdArg(1, prop, sizeof(prop));
	
	if(StrEqual(prop,"!unfreezeprop"))
	{
	FakeClientCommand(Client, "sm_unfreezeprop");
	PrintToChat(Client, "[Unfreezed Entity]");
	return Plugin_Handled
	}
		return Plugin_Handled
}

public Action:Command_deltrigger(Client, args)
{
	new String:prop[32];
	GetCmdArg(1, prop, sizeof(prop));
	
	if(StrEqual(prop,"!del"))
	{
	FakeClientCommand(Client, "sm_delete");
	PrintToChat(Client, "[Deleted Entity]");
	return Plugin_Handled
	}
		return Plugin_Handled
}
