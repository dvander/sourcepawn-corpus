/*
* Changelog:
* v1.0 -
* Plugin released. 
* 
* v1.1 - (shavit)
* Shitload of changes.
*/

#include <sourcemod>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "Delete plugins",
	author = "wyd3x",
	description = "Delete plugins from the server",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=197680"
};

public OnPluginStart()
{
	RegAdminCmd("sm_delete", Command_Delete, ADMFLAG_ROOT, "Delete a plugin. Usage: sm_delete <plugin name>");
	
	CreateConVar("sm_deleteplugins_version", PLUGIN_VERSION, "Plugin's version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
}

public Action:Command_Delete(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_delete <plugin name>");
		
		return Plugin_Handled;
	}
	
	new String:sPlugin[32];
	GetCmdArgString(sPlugin, 32);
	TrimString(sPlugin);
	StripQuotes(sPlugin);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	Format(sPath, PLATFORM_MAX_PATH, "addons/sourcemod/plugins/%s.smx", sPlugin);
	
	if(FileExists(sPath))
	{
		DeleteFile(sPath);
		
		ServerCommand("sm plugins unload %s", sPlugin);
		
		PrintToChat(client, "\x04[SM]\x01 Successfully deleted the plugin \"\x05%s\x01\".", sPlugin);
	}
	
	else
	{
		PrintToChat(client, "\x04[SM]\x01 The plugin \x05%s\x01 does not exists.", sPlugin);
	}
	
	return Plugin_Handled;
}
