/**
 * ====================
 *   Server Defense
 *   Author: Greyscale
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.5"

#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE;

new TopMenuObject:objServerDefense;

public Plugin:myinfo =
{
    name = "Server Defense Menu",
    author = "Greyscale",
    description = "Adds new section to SM's admin menu",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
    LoadTranslations("serverdefense.phrases");
    
    // ======================================================================
    
    new Handle:topmenu;
    
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
    {
        OnAdminMenuReady(topmenu);
    }
}
 
public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "adminmenu"))
    {
        hAdminMenu = INVALID_HANDLE;
    }
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	
	objServerDefense = AddToTopMenu(hAdminMenu, "Server Defense Options", TopMenuObject_Category, ServerDefenseHandler, INVALID_TOPMENUOBJECT);
 
	AddToTopMenu(hAdminMenu, "sd_spawnprotect", TopMenuObject_Item, AdminMenu_SpawnProtect, objServerDefense, "sd_spawnprotect", ADMFLAG_GENERIC);
	AddToTopMenu(hAdminMenu, "sd_anticamp", TopMenuObject_Item, AdminMenu_AntiCamp, objServerDefense, "sd_anticamp", ADMFLAG_GENERIC);
}
 
public ServerDefenseHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Server Defense Options:");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Server Defense Options");
	}
}

public AdminMenu_SpawnProtect(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    new Handle:cvarSpawnProtect = FindConVar("sd_spawnprotect");
    new bool:spawnprotection = GetConVarBool(cvarSpawnProtect);
    
    if (action == TopMenuAction_DisplayOption)
    {
        if (spawnprotection)
        {
            Format(buffer, maxlength, "Disable Spawn Protection");
        }
        else
        {
            Format(buffer, maxlength, "Enable Spawn Protection");
        }
    }
    else if (action == TopMenuAction_SelectOption)
    {
        SetConVarBool(cvarSpawnProtect, !spawnprotection);
        
        if (spawnprotection)
        {
            PrintToChat(param, "[%t] %t", "Server Defense", "Spawn protection disabled");
        }
        else
        {
            PrintToChat(param, "[%t] %t", "Server Defense", "Spawn protection enabled");
        }
    }
}

public AdminMenu_AntiCamp(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    new Handle:cvarAntiCamp = FindConVar("sd_anticamp");
    new bool:anticamp = GetConVarBool(cvarAntiCamp);
    
    if (action == TopMenuAction_DisplayOption)
    {
        if (anticamp)
        {
            Format(buffer, maxlength, "Disable Anti-Camp");
        }
        else
        {
            Format(buffer, maxlength, "Enable Anti-Camp");
        }
    }
    else if (action == TopMenuAction_SelectOption)
    {
        SetConVarBool(cvarAntiCamp, !anticamp);
        
        if (anticamp)
        {
            PrintToChat(param, "[%t] %t", "Server Defense", "Anti-Camp disabled");
        }
        else
        {
            PrintToChat(param, "[%t] %t", "Server Defense", "Anti-Camp enabled");
        }
    }
}