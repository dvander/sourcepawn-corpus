#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

#define VERSION "2.0 beta1"

#define CONFIG_FILE "data/projectile_replacer.cfg"

#define ON "On"
#define OFF "Off"

#define CLASS_LENGTH 65
// global variables
new Handle:g_Cvar_Enabled = INVALID_HANDLE;

//new g_ArrayModelSize;
new g_ClassSize = 65;

// For storage, we need a multiple dimensional array, but it can't be fixed size...
// Therefore, we have adt_arrays of adt_arrays. :/
//new Handle:g_Replacements = INVALID_HANDLE;
new Handle:g_ReplacementClasses = INVALID_HANDLE;

// Handle to a KeyValues structure
new Handle:g_kvReplacements = INVALID_HANDLE;

new Handle:g_Cookie_Enabled = INVALID_HANDLE;

new Handle:g_ReplacementCookies = INVALID_HANDLE;

new Handle:g_Menu_Main = INVALID_HANDLE;

// adt_trie
new Handle:g_ClassMenuHandles = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Projectile Model Replacer",
	author = "Powerlord",
	description = "Change the model on projectiles as specified in data/projectile_replacer.cfg",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187108"
}

public OnPluginStart()
{
	LoadTranslations("projectile_replacer.phrases");
	LoadTranslations("common.phrases"); // Necessary for On and Off phrases
	
	CreateConVar("tpr_version", VERSION, "Projectile Replacer version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("tpr_enabled", "1", "Projectile Replacer enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	RegAdminCmd("tpr_reload", ReloadConfig, ADMFLAG_CONFIG, "Reload Projectile Replacer configuration file");
	
	HookConVarChange(g_Cvar_Enabled, OnEnabledChanged);
	
	//g_ArrayModelSize = ByteCountToCells(PLATFORM_MAX_PATH);
	
	// This is the index of the Tries
	g_ReplacementClasses = CreateArray(ByteCountToCells(g_ClassSize));
	
	// This is a Trie of array handles
	//g_Replacements = CreateTrie();

	// This is a Trie of cookie handles, corresponding to the values in ReplacementClasses
	g_ReplacementCookies = CreateTrie();
	
	g_Cookie_Enabled = RegClientCookie("tpr_enabled", "Is Projectile Replacer Enabled?", CookieAccess_Public);
	
	// Add a menu to the Cookies list so you can open our menu from there
	SetCookieMenuItem(CookieHandler, 0, "Projectile Replacer");
	
	g_ClassMenuHandles = CreateTrie();
}

public OnPluginEnd()
{
	CloseHandle(g_kvReplacements);
}

public OnConfigsExecuted()
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		// Re-read our configuration every time configurations are reloaded.
		ReadConfigFile();
	}
}

public OnEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		// Re-read our configuration when the convar is enabled
		// This allows us to not reload the config when the plugin is disabled on map start
		ReadConfigFile();
	}
}

public Action:ReloadConfig(client, args)
{
	ReadConfigFile();
	
	ReplyToCommand(client, "%t", "Configuration Reloaded to Client");
	
	return Plugin_Handled;
}

ClearConfigData()
{
	// Clear cookie handles, here to prevent leaking handles
	new classCount = GetArraySize(g_ReplacementClasses);
	for (new i = 0; i < classCount; i++)
	{
		decl String:classname[CLASS_LENGTH];
		GetArrayString(g_ReplacementClasses, i, classname, CLASS_LENGTH);
		
		// Cookie handle
		new Handle:cookie;
		GetTrieValue(g_ReplacementCookies, classname, cookie);
		
		CloseHandle(cookie);
		
		// Menu handle
		new Handle:menu;
		GetTrieValue(g_ClassMenuHandles, classname, menu);
		
		CloseHandle(menu);
	}

	ClearTrie(g_ClassMenuHandles);
	ClearTrie(g_ReplacementCookies);
	ClearArray(g_ReplacementClasses);
	
}

// This function does a lot.  It reads the config file, then creates the main menu.  Submenus are dynamically generated.
ReadConfigFile()
{
	
	ClearConfigData();
	
	decl String:filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "%s", CONFIG_FILE);
	
	if (g_kvReplacements != INVALID_HANDLE)
	{
		CloseHandle(g_kvReplacements);
	}
	
	g_kvReplacements = CreateKeyValues("ProjectileReplacements_v2");

	if (!FileToKeyValues(g_kvReplacements, filePath))
	{
		SetFailState("%T", "Configuration Load Failed", LANG_SERVER, filePath);
		return;
	}

	// Formerly LoadModels

	KvRewind(g_kvReplacements);
	
	if (!KvGotoFirstSubKey(g_kvReplacements))
	{
		// Whoops, configuration is empty
		return;
	}

	do
	{
		new bool:classHasItems = false;
		
		decl String:classname[CLASS_LENGTH];
		KvGetSectionName(g_kvReplacements, classname, CLASS_LENGTH);
		
		if (!KvGotoFirstSubKey(g_kvReplacements))
		{
			// Move along people, nothing to see here!
			continue;
		}
		
		do
		{
			decl String:model[PLATFORM_MAX_PATH];
			KvGetString(g_kvReplacements, "model", model, PLATFORM_MAX_PATH);
			
			if (!StrEqual(model, ""))
			{
				classHasItems = true;
				PrecacheModel(model);
			}
			
		} while (KvGotoNextKey(g_kvReplacements));
		
		KvGoBack(g_kvReplacements);

		if (classHasItems)
		{
			// Add to the main menu
			decl String:modelName[64];
			KvGetString(g_kvReplacements, "name", modelName, sizeof(modelName), classname);
			
			AddMenuItem(g_Menu_Main, classname, modelName);
			
			// Create a client cookie.
			decl String:cookie_name[CLASS_LENGTH+3];
			Format(cookie_name, sizeof(cookie_name), "%s%s", "tpr", classname);
			
			decl String:cookie_desc[128];
			Format(cookie_desc, sizeof(cookie_desc), "Projectile Replacer model for ", modelName);
			
			new Handle:cookie = RegClientCookie(cookie_name, cookie_desc, CookieAccess_Protected);
			PushArrayString(g_ReplacementClasses, classname);
			SetTrieValue(g_ReplacementCookies, classname, cookie);
		}
		
		
	} while (KvGotoNextKey(g_kvReplacements));

	LogMessage("%T", "Configuration Loaded", LANG_SERVER, GetArraySize(g_ReplacementClasses));
}

public OnEntityCreated(entity, const String:classname[])
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		if (FindStringInArray(g_ReplacementClasses, classname) > -1)
		{
			SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawned);
		}
	}
}

public ProjectileSpawned(entity)
{
	decl String:classname[g_ClassSize];
	
	GetEntityClassname(entity, classname, g_ClassSize);
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	new bool:bPlayer = false;
	
	if (owner > 0 && owner <= MaxClients)
	{
		if (!IsClientInGame(owner))
		{
			return;
		}

		decl String:enabledString[2];
		GetClientCookie(owner, g_Cookie_Enabled, enabledString, sizeof(enabledString));
		if (!StringToInt(enabledString))
		{
			return;
		}
		
		bPlayer = true;
	}
	
	
	
	
	
	
	
	
	decl String:cookie_name[CLASS_LENGTH+3];
	Format(cookie_name, sizeof(cookie_name), "%s%s", "tpr", classname);
	
	new Handle:cookie = FindClientCookie(cookie_name);
	
	if (cookie == INVALID_HANDLE)
	{
		decl String:cookie_desc[CLASS_LENGTH+32];
		Format(cookie_desc, sizeof(cookie_desc), "Projectile Replacer model for ", classname);
		cookie = RegClientCookie(cookie_name, "", CookieAccess_Protected);
	}

	
	// Old code, needs replacing
	
	/*
	new Handle:replacements;
	if (GetTrieValue(g_Replacements, classname, replacements))
	{
		decl String:model[PLATFORM_MAX_PATH];
		new rand = GetRandomInt(1, GetArraySize(replacements)) - 1;
		GetArrayString(replacements, rand, model, PLATFORM_MAX_PATH);
		SetEntityModel(entity, model);
	}
	*/

}

// Erg, cookies use a different menu.  Anyway, we're going to use this to launch a submenu
public CookieHandler(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		ShowMainMenu(client, true);
	}
	
}

BuildMainMenu()
{
	if (g_Menu_Main != INVALID_HANDLE)
	{
		CloseHandle(g_Menu_Main);
	}
	
	g_Menu_Main = CreateMenu(MainMenuHandler);
	SetMenuTitle(g_Menu_Main, "%T", "Settings Menu Title", LANG_SERVER);
	
	AddMenuItem(g_Menu_Main, "status", "Status: On", ITEMDRAW_DISABLED);
	AddMenuItem(g_Menu_Main, "toggle", "Change Status");
	
	new size = GetArraySize(g_ReplacementClasses);
	
	for (new i = 0; i < size; i++)
	{
		decl String:classname[CLASS_LENGTH];
		GetArrayString(g_ReplacementClasses, i, classname, CLASS_LENGTH);
		
		KvRewind(g_kvReplacements);
		
		if (!KvJumpToKey(g_kvReplacements, classname))
		{
			return;
		}
	}
}

ShowMainMenu(client, bool:backToCookie)
{
	if (backToCookie)
	{
		SetMenuExitBackButton(g_Menu_Main, true);
	}
	else
	{
		SetMenuExitButton(g_Menu_Main, true);
	}
	
	DisplayMenu(g_Menu_Main, client, MENU_TIME_FOREVER);
	
}

public MainMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			// Change the menu title based on user's language
			SetMenuTitle(menu, "%T", "Settings Menu Title", param1);
		}

		/*
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		*/

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowCookieMenu(param1);
			}
		}
		
		case MenuAction_Select:
		{
			decl String:iteminfo[CLASS_LENGTH];
			GetMenuItem(menu, param2, iteminfo, CLASS_LENGTH);
			
			if (StrEqual(iteminfo, "toggle"))
			{
				decl String:status[4];
				
				GetClientCookie(g_Cookie_Enabled);
				GetClientCookie(param1, g_Cookie_Enabled, status, sizeof(status));
				
				if (StrEqual(status, ON, false))
				{
					strcopy(status, sizeof(status), OFF);
				}
				else
				{
					strcopy(status, sizeof(status), ON);
				}
				
				SetClientCookie(param1, g_Cookie_Enabled, status);
				
			}
			else
			{
				decl String:iteminfo[CLASS_LENGTH];
				GetMenuItem(menu, param2, iteminfo, CLASS_LENGTH);
				
			}
		}
		
		case MenuAction_DisplayItem:
		{
			// Change the menu title based on user's language
			// Only applies to static entries (aka "status" line and "toggle" entries
			decl String:iteminfo[CLASS_LENGTH];
			decl String:displayinfo[64];
			GetMenuItem(menu, param2, iteminfo, CLASS_LENGTH, _, displayinfo, sizeof(displayinfo));
			
			decl String:replace[128];
			
			if (StrEqual(iteminfo, "status"))
			{
				decl String:status[4];

				GetClientCookie(param1, g_Cookie_Enabled, status, sizeof(status));
				
				if (StrEqual(status, ON, false))
				{
					strcopy(status, sizeof(status), ON);
				}
				else
				{
					strcopy(status, sizeof(status), OFF);
				}
				
				
				Format(replace, sizeof(replace), "%T", "Status", param1, status);
				
				return RedrawMenuItem(replace);
			}
			else if (StrEqual(iteminfo, "toggle"))
			{
				Format(replace, sizeof(replace), "%T", "Toggle", param1);
				
				return RedrawMenuItem(replace);
			}
			else
			{
				Format(replace, sizeof(replace), "%T", "Model For", param1, displayinfo);
				
				return RedrawMenuItem(replace);
			}
			
		}
	}
}
