#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Anti Color Abuse",
	author = "11530",
	description = "Removes ability for any player to use colors.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_hAllowAdmin = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bAllowAdmin;
new bool:g_bEnabled;

new String:sCodes[][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08"};

public OnPluginStart()
{
	CreateConVar("sm_anticolorabuse_version", PLUGIN_VERSION, "Plugin version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hEnabled = CreateConVar("sm_anticolorabuse_enabled", "1", "Enable/disable the plugin.", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnConVarEnabledChanged);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	g_hAllowAdmin = CreateConVar("sm_anticolorabuse_allowadmin", "0", "Allow admins to use colors.", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hAllowAdmin, OnConVarAllowAdminChanged);
	g_bAllowAdmin = GetConVarBool(g_hAllowAdmin);

	AddCommandListener(OnSayCommand, "say");
	AddCommandListener(OnSayCommand, "say2");
	AddCommandListener(OnSayCommand, "say_team");
}

public OnConVarEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = (StringToInt(newValue) == 0 ? false : true);
}

public OnConVarAllowAdminChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bAllowAdmin = (StringToInt(newValue) == 0 ? false : true);
}

public Action:OnSayCommand(client, const String:command[], argc)
{
	decl String:text[192];
	new startidx = 0;
	if (!g_bEnabled || GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}
	
	for (new i = 0; i < sizeof(sCodes); i++)
	{
		if (StrContains(text[startidx], sCodes[i], false) > -1)
		{
			if (!g_bAllowAdmin || (g_bAllowAdmin && !CheckCommandAccess(client, "anticolorabuseflag", ADMFLAG_GENERIC)))
			{
				PrintToChat(client, "[SM] You cannot use colors here!");
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}