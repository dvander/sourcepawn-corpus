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
	new String:command[12], String:plugin_file[64], String:disabledpath[256], String:enabledpath[256];
	GetCmdArg(1, command, sizeof(command));
	GetCmdArg(2, plugin_file, sizeof(plugin_file));
	
	if (StrContains(plugin_file, ";", false) != -1)
		return Plugin_Handled;	// prevent badmins trying to exploit ServerCommand();
	if (StrContains(plugin_file, ".smx", false) != -1)
		ReplaceString(plugin_file, sizeof(plugin_file), ".smx", "", false);	//strip out .smx since we have it formatted below.

	BuildPath(Path_SM, disabledpath, sizeof(disabledpath), "plugins/disabled/%s.smx", plugin_file);	
	BuildPath(Path_SM, enabledpath, sizeof(enabledpath), "plugins/%s.smx", plugin_file);	
	new String:PluginWExt[70];
	Format(PluginWExt, sizeof(PluginWExt), "%s.smx", plugin_file);
	
	if (DEBUG_PATH)
	{
		ReplyToCommand(client, disabledpath);
		ReplyToCommand(client, enabledpath);
	}
	
	if (StrContains(command, "enable", false) == 0)
	{
		if (!FileExists(disabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: The plugin file could not be found.");
			return Plugin_Handled;
		}
		if (FileExists(enabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: An existing plugin file (%s) has been detected that conflicts with the one being moved.  No action has been taken.", enabledpath);
			return Plugin_Handled;
		}
		
		RenameFile(enabledpath, disabledpath);
		ServerCommand("sm plugins load %s", plugin_file);
		new Handle:pack;
		CreateDataTimer(0.1, ReplyPluginStatus, pack);	// delay long enough for the plugin to load
		WritePackString(pack, PluginWExt);
		WritePackCell(pack, _:GetCmdReplySource());
		if (client != 0)
			WritePackCell(pack, GetClientUserId(client));
		else 
			WritePackCell(pack, 0);
	}
	else if (StrContains(command, "disable", false) == 0)
	{
		if (!FileExists(enabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: The plugin file could not be found.");
			return Plugin_Handled;
		}
		if (FileExists(disabledpath))
		{
			ReplyToCommand(client, "\x04[SM]\x01: An existing plugin file (%s) has been detected that conflicts with the one being moved.  No action has been taken.", disabledpath);
			return Plugin_Handled;
		}
		
		new Handle:Loaded = FindPluginByFile(PluginWExt);
		new String:PluginName[128];
		if (Loaded != INVALID_HANDLE)
			GetPluginInfo(Loaded, PlInfo_Name, PluginName, sizeof(PluginName));
		else
			strcopy(PluginName, sizeof(PluginName), PluginWExt);
		ServerCommand("sm plugins unload %s", plugin_file);
		RenameFile(disabledpath, enabledpath);
		
		ReplyToCommand(client, "\x04[SM]\x01: The plugin '\x03%s\x01' has been unloaded and moved to the /disabled/ directory.", PluginName);
	}
	else
		ReplyToCommand(client, "[SM] Usage: plugin <enable/disable> <file>");
	return Plugin_Handled;
}

public Action:ReplyPluginStatus(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new String:PluginWExt[70];
	ReadPackString(pack, PluginWExt, sizeof(PluginWExt));
	new ReplySource:reply = ReplySource:ReadPackCell(pack);
	SetCmdReplySource(reply);
	new client = ReadPackCell(pack);
	if (client != 0)
		client = GetClientOfUserId(client);
	
	new Handle:Loaded = FindPluginByFile(PluginWExt);
	if (Loaded != INVALID_HANDLE)
	{
		new String:PluginName[128];
		GetPluginInfo(Loaded, PlInfo_Name, PluginName, sizeof(PluginName));
		ReplyToCommand(client, "\x04[SM]\x01: Enabled and loaded plugin '\x03%s\x01'!", PluginName);
	}
	else
		ReplyToCommand(client, "\x04[SM]\x01: The plugin file '\x03%s\x01' was enabled, but it was not able to be loaded.\n\x03[SM]\x01: Use '\x05sm plugins load %s\x01' to try to load the plugin manually.", PluginWExt, PluginWExt);
}
