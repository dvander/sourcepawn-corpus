#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:g_Cvar_FF = INVALID_HANDLE;
#pragma semicolon 1
new Handle:hTopMenu = INVALID_HANDLE;

#define PLUGIN_VERSION "0.0.4"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "TF2 FF hack",
	author = "R-Hehl",
	description = "Allows to enabel FF in TF2",
	version = PLUGIN_VERSION,
	url = "http://www.Compactaim.de"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_ffhack_version", PLUGIN_VERSION, "FF Hack Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_FF = FindConVar("mp_friendlyfire");
	RegAdminCmd("sm_ff", ff_cmd, ADMFLAG_GENERIC);

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

	new TopMenuObject:fun_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	AddToTopMenu(hTopMenu, 
		"ff_cmd",
		TopMenuObject_Item,
		AdminMenu_sw,
		fun_commands,
		"ff_cmd",
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
		Format(buffer, maxlength, "Friendly Fire");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ff_cmd(param,param);
	}
}
public Action:ff_cmd(client, args)
{
	
	SetConVarBool(g_Cvar_FF, !GetConVarBool(g_Cvar_FF));
	new String:name[32];
	GetClientName(client, name, 32);
	PrintCenterTextAll("%s Set Friendly Fire to %i",name,GetConVarBool(g_Cvar_FF));
	return Plugin_Handled;
}




