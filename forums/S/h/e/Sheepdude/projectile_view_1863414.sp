#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#pragma semicolon 1

#define PLUGIN_VERSION "1.8.0"
#define UPDATE_URL "http://sheepdude.silksky.com/sourcemod-plugins/raw/default/projectile_view.txt"

public Plugin:myinfo = 
{
	name = "Grenade / Projectile View",
	author = "Sheepdude",
	description = "View a projectile or thrown grenade's flight from the projectile's perspective",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

// Updater handles
new Handle:h_cvarUpdater;

// Cookie handles
new Handle:h_CookieClientPref;

// Convar handles
new Handle:h_cvarVersion;
new Handle:h_cvarEnable;
new Handle:h_cvarDefaultState;
new Handle:h_cvarToggleView;
new Handle:h_cvarRoll;
new Handle:h_cvarPrint;
new Handle:h_cvarReplace;

// Convar variables
new bool:g_cvarEnable;
new bool:g_cvarDefaultState;
new bool:g_cvarToggleView;
new Float:g_cvarRoll;
new bool:g_cvarPrint;
new bool:g_cvarReplace;

// Plugin variables
new bool:g_ClientView[MAXPLAYERS+1];
new g_ClientNade[MAXPLAYERS+1];
new g_NumClients;
new bool:g_IsCS;

/******
 *Load*
*******/

public OnPluginStart()
{
	// Translations
	LoadTranslations("projectile_view.phrases");
	
	// Updater convar
	h_cvarUpdater = CreateConVar("sm_projectile_view_auto_update", "1", "Update plugin automatically if Updater is installed (1 - auto update, 0 - don't update", 0, true, 0.0, true, 1.0);
	
	// Plugin convars
	h_cvarVersion = CreateConVar("sm_projectile_view_version", PLUGIN_VERSION, "Plugin version", FCVAR_CHEAT|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	h_cvarEnable = CreateConVar("sm_projectile_view_enable", "1", "Enable plugin (1 - enable, 0 - disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarDefaultState = CreateConVar("sm_projectile_view_default", "1", "Default camera state (1 - projectile view, 0 - default view)", 0, true, 0.0, true, 1.0);
	h_cvarToggleView = CreateConVar("sm_projectile_view_toggle", "1", "Switch back to previously spawned projectile when toggling view (1 - switch, 0 - only to newly spawned projectiles)", 0, true, 0.0, true, 1.0);
	h_cvarRoll = CreateConVar("sm_projectile_view_roll", "0.0", "Camera roll adjustment for projectile view", 0, true, -360.0, true, 360.0);
	h_cvarPrint = CreateConVar("sm_projectile_view_print", "1", "Print messages to chat (1 - print, 0 - don't print)", 0, true, 0.0, true, 1.0);
	h_cvarReplace = CreateConVar("sm_projectile_view_replace_nade", "1", "CS Only: Gives the player another grenade after the nade is thrown (1 - extra nades, 0 - no nades)", 0, true, 0.0, true, 1.0);

	// Convar hooks
	HookConVarChange(h_cvarVersion, OnConvarChanged);
	HookConVarChange(h_cvarEnable, OnConvarChanged);
	HookConVarChange(h_cvarDefaultState, OnConvarChanged);
	HookConVarChange(h_cvarToggleView, OnConvarChanged);
	HookConVarChange(h_cvarRoll, OnConvarChanged);
	HookConVarChange(h_cvarPrint, OnConvarChanged);
	HookConVarChange(h_cvarReplace, OnConvarChanged);
	
	// Console commands
	RegConsoleCmd("sm_projectile_view", ToggleViewCmd, "Toggle between regular and projectile view");
	RegConsoleCmd("sm_grenade_view", ToggleViewCmd, "Toggle between regular and projectile view");
	RegConsoleCmd("sm_projectileview", ToggleViewCmd, "Toggle between regular and projectile view");
	RegConsoleCmd("sm_grenadeview", ToggleViewCmd, "Toggle between regular and projectile view");

	// Event hooks
	HookEventEx("decoy_started", OnDetonate);
	HookEventEx("smokegrenade_detonate", OnDetonate);
	
	// Execute configuration file
	AutoExecConfig(true, "projectile_view");
	
	// Cookies
	h_CookieClientPref = RegClientCookie("Grenade / Projectile View", "Camera settings", CookieAccess_Private);
	SetCookieMenuItem(GGCookiePrefSelected, 0, "Grenade / Projectile View Preferences");
	
	// Discover whether mod is counter-strike
	decl String:GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	g_IsCS = StrContains(GameName, "cs", false) != -1;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Updater_AddPlugin");
	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	if(LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);	
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}

/*********
 *Updater*
**********/

public Action:Updater_OnPluginDownloading()
{
	if(!GetConVarBool(h_cvarUpdater))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
}

/**********
 *Forwards*
***********/

public OnClientPutInServer(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
		LoadClientCookies(client);
	if(g_NumClients < MaxClients)
		g_NumClients++;
}

public OnClientCookiesCached(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
		LoadClientCookies(client);
}

public OnConfigsExecuted()
{
	UpdateAllConvars();
	LoadCookies();
}

/**********
 *Commands*
***********/

public Action:ToggleViewCmd(client, args)
{
	// Client has access to toggle commands
	if(g_cvarEnable && IsValidClient(client) && CheckCommandAccess(client, "sm_projectile_view", 0, true))
	{
		// Toggle projectile view
		g_ClientView[client] = !g_ClientView[client];

		// Client just enabled projectile view
		if(g_ClientView[client])
		{
			if(g_cvarPrint)
				PrintToChat(client, "\x01\x0B\x04[SM]\x01 %t", "enabled");
			SetClientCookie(client, h_CookieClientPref, "1");

			// Reset viewpoint to previously spawned projectile if it is allowed
			if(g_ClientNade[client] > 0)
			{
				if(g_cvarToggleView && IsValidEntity(g_ClientNade[client]))
					SetClientViewEntity(client, g_ClientNade[client]);
				else
					g_ClientNade[client] = 0;
			}
		}
		else
		{
			if(g_cvarPrint)
				PrintToChat(client, "\x01\x0B\x04[SM]\x01 %t", "disabled");
			SetClientCookie(client, h_CookieClientPref, "0");

			// Reset viewpoint to client view
			if(g_ClientNade[client] > 0)
			{
				if(!g_cvarToggleView)
					g_ClientNade[client] = 0;
				SetClientViewEntity(client, client);
			}
		}
	}
	else
		PrintToChat(client, "\x01\x0B\x04[SM]\x01 %t", "access");
	return Plugin_Handled;
}

/********
 *Events*
*********/

public OnGameFrame()
{
	static Float:ClientAngles[3];
	for(new i = 1; i <= g_NumClients; i++)
	{
		if(IsClientInGame(i) && g_ClientNade[i] > 0 && g_ClientView[i])
		{
			GetClientEyeAngles(i, ClientAngles);
			if(g_cvarRoll != 0)
				ClientAngles[2] = g_cvarRoll;
			TeleportEntity(g_ClientNade[i], NULL_VECTOR, ClientAngles, NULL_VECTOR);
		}
	}
}

public OnDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Untrack projectiles that explode but still exist latently (such as smoke grenades)
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && client <= MaxClients && g_ClientNade[client] > 0)
	{
		g_ClientNade[client] = 0;
		if(IsClientInGame(client))
			SetClientViewEntity(client, client);
	}
}

/**********
 *SDKHooks*
***********/

public OnEntityCreated(iEntity, const String:classname[]) 
{
	if(g_cvarEnable && StrContains(classname, "_projectile") != -1)
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
}

public OnEntityDestroyed(entity)
{
	// If destroyed entity was being viewed, reset client's view
	for(new i = 1; i <= g_NumClients; i++)
		if(entity == g_ClientNade[i])
		{
			g_ClientNade[i] = 0;
			if(IsClientInGame(i))
				SetClientViewEntity(i, i);
		}
}

public OnEntitySpawned(iGrenade)
{
	new client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	if(IsValidClient(client) && !IsFakeClient(client) && g_ClientNade[client] == 0)
	{
		// Change client view entity to their last spawned projectile
		g_ClientNade[client] = iGrenade;
		if(g_ClientView[client])
			SetClientViewEntity(client, iGrenade);
		
		// Replenish Counter-Strike grenades
		if(g_cvarReplace)
		{
			decl String:clsname[32], String:grenadename[16];
			GetEntityClassname(iGrenade, clsname, sizeof(clsname));
			SplitString(clsname, "_projectile", grenadename, sizeof(grenadename));
			strcopy(clsname, sizeof(clsname), "weapon_");
			StrCat(clsname, sizeof(clsname), grenadename);
			GivePlayerItem(client, clsname);
		}
	}
}

/*********
 *Convars*
**********/

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_cvarVersion)
		ResetConVar(h_cvarVersion);
	else if(cvar == h_cvarEnable)
	{
		g_cvarEnable = GetConVarBool(h_cvarEnable);
		for(new i = 1; i <= MaxClients; i++)
			g_ClientView[i] = g_cvarEnable && g_cvarDefaultState;
	}
	else if(cvar == h_cvarDefaultState)
		g_cvarDefaultState = GetConVarBool(h_cvarDefaultState);
	else if(cvar == h_cvarToggleView)
		g_cvarToggleView = GetConVarBool(h_cvarToggleView);
	else if(cvar == h_cvarRoll)
		g_cvarRoll = GetConVarFloat(h_cvarRoll);
	else if(cvar == h_cvarPrint)
		g_cvarPrint = GetConVarBool(h_cvarPrint);
	else if(cvar == h_cvarReplace)
		g_cvarReplace = g_IsCS && GetConVarBool(h_cvarReplace);
}

UpdateAllConvars()
{
	g_cvarEnable = GetConVarBool(h_cvarEnable);
	g_cvarDefaultState = GetConVarBool(h_cvarDefaultState);
	g_cvarToggleView = GetConVarBool(h_cvarToggleView);
	g_cvarRoll = GetConVarFloat(h_cvarRoll);
	g_cvarPrint = GetConVarBool(h_cvarPrint);
	g_cvarReplace = g_IsCS && GetConVarBool(h_cvarReplace);
	for(new i = 1; i <= MaxClients; i++)
			g_ClientView[i] = g_cvarEnable && g_cvarDefaultState;
}

/*********
 *Cookies*
**********/

LoadCookies()
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			LoadClientCookies(i);
}

LoadClientCookies(client)
{
	if(AreClientCookiesCached(client))
	{
		decl String:buffer[5];
		GetClientCookie(client, h_CookieClientPref, buffer, 5);
		if(!StrEqual(buffer, ""))
			g_ClientView[client] = g_cvarEnable && StrEqual(buffer, "1");
	}
}

public GGCookiePrefSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if(action == CookieMenuAction_SelectOption)
		ShowPluginCookieMenu(client);
}

ShowPluginCookieMenu(client)
{
	new Handle:menu = CreateMenu(PluginCookieMenuHandler);
	SetMenuTitle(menu, "Grenade / Projectile View Preferences");
	decl String:buffer[100];
	if(!g_ClientView[client])
		Format(buffer, sizeof(buffer), "Grenade / Projectile View (Disabled)");
	else
		Format(buffer, sizeof(buffer), "Grenade / Projectile View (Enabled)");
	AddMenuItem(menu, "Toggle", buffer);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public PluginCookieMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	if(action == MenuAction_Select)	
	{
		if(g_ClientView[param1])
		{
			g_ClientView[param1] = false;
			SetClientCookie(param1, h_CookieClientPref, "0");
		}
		else
		{
			g_ClientView[param1] = g_cvarEnable;
			SetClientCookie(param1, h_CookieClientPref, "1");
		}
		ShowPluginCookieMenu(param1);
	} 
}

/********
 *Stocks*
*********/

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}