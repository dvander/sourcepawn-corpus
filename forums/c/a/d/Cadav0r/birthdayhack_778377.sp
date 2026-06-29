#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:g_Cvar_bd = INVALID_HANDLE;
#pragma semicolon 1
new Handle:hTopMenu = INVALID_HANDLE;

#define PLUGIN_VERSION "0.0.3"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "TF2 Birthday hack",
	author = "R-Hehl, cadav0r",
	description = "Allows to enable Birthdaymode",
	version = PLUGIN_VERSION,
	url = "http://www.Compactaim.de"
};

public OnPluginStart()
{
	LoadTranslations("birthdayhack.phrases");
	CreateConVar("sm_bdhack_version", PLUGIN_VERSION, "Birthday Hack Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_bd = FindConVar("tf_birthday");
	RegAdminCmd("sm_bd", bdcmd, ADMFLAG_GENERIC);

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}
 


public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}

	/* Save the Handle */
	hTopMenu = topmenu;

	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	AddToTopMenu(hTopMenu, 
		"bdcmd",
		TopMenuObject_Item,
		AdminMenu_sw,
		server_commands,
		"bdcmd",
		ADMFLAG_GENERIC);

}

public AdminMenu_sw(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (GetConVarBool(g_Cvar_bd))
			Format(buffer, maxlength, "%t", "Deactivate Birthday MOD");
		else
			Format(buffer, maxlength, "%t", "Activate Birthday MOD");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		bdcmd(param,param);
	}
}

public Action:bdcmd(client, args)
{
	SetConVarBool(g_Cvar_bd, !GetConVarBool(g_Cvar_bd));
	new String:name[32];
	GetClientName(client, name, 32);
	if (GetConVarBool(g_Cvar_bd))
	{
		PrintCenterTextAll("%t", "Birthday MOD Activated", name);
		LogMessage("%s activate Birthday MOD", name);
	}
	else
	{
		PrintCenterTextAll("%t", "Birthday MOD Deactivated", name);
		LogMessage("%s deactivate Birthday MOD", name);
	}
	return Plugin_Handled;
}




