/*
Changelog:

v1.0 -
Plugin released. 

v2.0 - 
+ Add map delete
* Commands name changed

v2.1 - 
+ Add block delete current map
*/

#include <sourcemod>
#define DELETER_VERSION 	"2.1"

new c_Map;
new s_Map;

public Plugin:myinfo =
{
	name = "Deleter",
	author = "wyd3x",
	description = "Delete plugins/maps from the server",
	version = DELETER_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=197680"
};

public OnPluginStart()
{
	RegAdminCmd("sm_pdelete", comman_pdelete, ADMFLAG_ROOT, "Delete plugins");
	RegAdminCmd("sm_mdelete", comman_mdelete, ADMFLAG_ROOT, "Delete maps");
	CreateConVar("sm_deleter_version", DELETER_VERSION, "deleter version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
}
public Action:comman_pdelete(client, args)
{
	if (args != 1)
	{
	ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_pdelete <plugin name>");
	return Plugin_Handled;
	}
	
	new String:sPlugin[32];
	GetCmdArgString(sPlugin, 32);
	TrimString(sPlugin);
	StripQuotes(sPlugin);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	Format(sPath, PLATFORM_MAX_PATH, "addons/sourcemod/plugins/%s.smx", sPlugin);
	
	if (FileExists(sPath))
	{
		ServerCommand("sm plugins unload %s", sPlugin);
		DeleteFile(sPath);
		PrintToChat(client, "\x04[SM]\x01 Successfully deleted the plugin \x04 %s" , sPlugin);
	} else {
		PrintToChat(client, "\x04[SM] \x01The plugin %s does not exists.");
	}
	return Plugin_Handled;
}

public Action:comman_mdelete(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_mdelete <map name>");
		return Plugin_Handled;
	}
	new String:cMap[250];
	c_Map = GetCurrentMap(cMap, sizeof(cMap));
	new String:sMap[250];
	s_Map = GetCmdArgString(sMap, 250);
	TrimString(sMap);
	StripQuotes(sMap);
	if (c_Map == s_Map)
	{
		ReplyToCommand(client, "\x04[SM]\x01 You can`t delete current map");
		return Plugin_Handled;
	}
	decl String:sPath[PLATFORM_MAX_PATH];
	Format(sPath, PLATFORM_MAX_PATH, "maps/%s.bsp", sMap);
	
	if (FileExists(sPath))
	{
		DeleteFile(sPath);
		PrintToChat(client, "\x04[SM]\x01 Successfully deleted the Map \x04 %s" , sMap);
	} else {
		PrintToChat(client, "\x04[SM] \x01The Map %s does not exists.");
	}
	return Plugin_Handled;
}
