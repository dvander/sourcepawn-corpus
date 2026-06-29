#define PLUGIN_VERSION "1.0.1"

#define USE_SOURCEMOD_ADMIN_COMMAND	//comment this line out to make the plugin use rcon commands only.

new bool:DEBUG_PATH = false;

public Plugin:myinfo =
{
	name = "[Any] Plugin Enable/Disable",
	author = "DarthNinja",
	description = "Allows you to enable or disable a plugin by command",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_dis_enable_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	#if defined USE_SOURCEMOD_ADMIN_COMMAND
	RegAdminCmd("plugins", DisEnablePlugin, ADMFLAG_ROOT, "plugins <enable/disable> <file>");
	#else
	RegServerCmd("plugins", DisEnablePlugin, "plugins <enable/disable> <file>");
	#endif
}


#if defined USE_SOURCEMOD_ADMIN_COMMAND
public Action:DisEnablePlugin(client, args)	//dat grammar
{
#else
public Action:DisEnablePlugin(args)
{
	new client = 0;
#endif

	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: plugins <enable/disable> <file>");
		return Plugin_Handled;
	}
	new String:command[12], String:filename[64], String:disabledpath[256], String:enabledpath[256];
	GetCmdArg(1, command, sizeof(command));
	GetCmdArg(2, filename, sizeof(filename));
	
	if (StrContains(filename, ";", false) != -1)
		return Plugin_Handled;	// prevent badmins trying to exploit ServerCommand();
	//if (StrContains(filename, ".smx", false) != -1)
	//	ReplaceString(filename, sizeof(filename), ".smx", "", false);	//strip out .smx since we have it formatted below.

	BuildPath(Path_SM, disabledpath, sizeof(disabledpath), "plugins/disabled/%s", filename);	
	BuildPath(Path_SM, enabledpath, sizeof(enabledpath), "plugins/%s", filename);	
	new String:PluginWExt[70];
	Format(PluginWExt, sizeof(PluginWExt), "%s", filename);
	
	if (DEBUG_PATH)
	{
		ReplyToCommand(client, disabledpath);
		ReplyToCommand(client, enabledpath);
	}
	
	if (StrContains(command, "enable", false) == 0)
	{
		if (!DirExists(disabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: The file could not be found.");
			return Plugin_Handled;
		}
		if (DirExists(enabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: An existing file (%s) has been detected that conflicts with the one being moved.  No action has been taken.", enabledpath);
			return Plugin_Handled;
		}
		
		RenameFile(enabledpath, disabledpath);
		ServerCommand("sm plugins refresh");
	}
	else if (StrContains(command, "disable", false) == 0)
	{
		if (!DirExists(enabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: The file could not be found.");
			return Plugin_Handled;
		}
		if (DirExists(disabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: An existing file (%s) has been detected that conflicts with the one being moved.  No action has been taken.", disabledpath);
			return Plugin_Handled;
		}
		ServerCommand("sm plugins refresh");
		RenameFile(disabledpath, enabledpath);
		
		ReplyToCommand(client, "\x04[SM]\x01: The file '\x03%s\x01' has been unloaded and moved to the /disabled/ directory.", filename);
	}
	else
		ReplyToCommand(client, "[SM] Usage: plugin <enable/disable> <file>");
	return Plugin_Handled;
}