#pragma semicolon 1
#pragma newdecls required

static const char
	PL_NAME[]	= "Find command",
	PL_VER[]	= "1.0.0_13.03.2023";

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Search plugin by command",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public void OnPluginStart()
{
	CreateConVar("sm_find_cmd_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	RegAdminCmd("sm_find_cmd", Cmd_Find, ADMFLAG_ROOT);
}

public Action Cmd_Find(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_find_cmd <console command name>");
		return Plugin_Handled;
	}

	char cmd[32];
	GetCmdArg(1, cmd, sizeof(cmd));
	if(!TrimString(cmd))
	{
		ReplyToCommand(client, "[SM] Usage: sm_find_cmd <console command name>");
		return Plugin_Handled;
	}

	if(GetCommandFlags(cmd) == INVALID_FCVAR_FLAGS)
	{
		ReplyToCommand(client, "[SM] Command '%s' don't registred", cmd);
		return Plugin_Handled;
	}

	ReplyToCommand(client, "\n[SM] '%s' is registered to:", cmd);

	CommandIterator iter = new CommandIterator();
	if(!iter)
	{
		LogError("Failed to create CommandIterator =(");
		return Plugin_Handled;
	}

	Handle plugin;
	int num;
	char buffer[32], name[32];
	while(iter.Next())
	{
		iter.GetName(buffer, sizeof(buffer));
		if(strcmp(cmd, buffer, false))
			continue;

		num++;
		plugin = iter.Plugin;
		GetPluginFilename(plugin, name, sizeof(name));
		if(GetPluginInfo(plugin, PlInfo_Name, buffer, sizeof(buffer)))
			ReplyToCommand(client, "  \"%s\" (file: %s)", buffer, name);
		else ReplyToCommand(client, "  (file: %s)", name);
	}
	CloseHandle(iter);

	ReplyToCommand(client, "  -= %i matches found =-\n", num);

	return Plugin_Handled;
}