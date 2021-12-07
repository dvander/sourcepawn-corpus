#include <sourcemod>

public Plugin:myinfo =
{
	name = "[ANY] In-Game Sourcemod Manager Commands",
	author = "Bitl",
	description = "Makes managing any plugin/extension faster!",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_reloadplugin", Command_PluginReload, ADMFLAG_RCON);
	RegAdminCmd("sm_unloadplugin", Command_PluginUnload, ADMFLAG_RCON);
	RegAdminCmd("sm_loadplugin", Command_PluginLoad, ADMFLAG_RCON);
	RegAdminCmd("sm_reloadextension", Command_ExtensionReload, ADMFLAG_RCON);
	RegAdminCmd("sm_unloadextension", Command_ExtensionUnload, ADMFLAG_RCON);
	RegAdminCmd("sm_loadextension", Command_ExtensionLoad, ADMFLAG_RCON);
}

public Action:Command_PluginReload(client, args)
{
	new String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	ServerCommand("sm plugins reload %s", arg1);
}

public Action:Command_PluginUnload(client, args)
{
	new String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	ServerCommand("sm plugins unload %s", arg1);
}

public Action:Command_PluginLoad(client, args)
{
	new String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	ServerCommand("sm plugins load %s", arg1);
}

public Action:Command_ExtensionReload(client, args)
{
	new String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	ServerCommand("sm exts reload %s", arg1);
}

public Action:Command_ExtensionUnload(client, args)
{
	new String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	ServerCommand("sm exts unload %s", arg1);
}

public Action:Command_ExtensionLoad(client, args)
{
	new String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	ServerCommand("sm exts load %s", arg1);
}


