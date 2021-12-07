#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <updater>
#include <morecolors>

#pragma newdecls required
#pragma semicolon 1

#define CHAT_PREF_COLOR "{gold}[UA] {cyan}"
#define CHAT_PREF "[UA] "

#define EFFECT_MAX_COUNT 150
#define EFFECT_MAX 64

#define PROJ_COUNT 15

#define VERSION "1.1.0"

#define UPDATE_URL    "http://www.tf2app.com/thewreckingcrew6/plugins/ua/updater.txt"

enum Effects{

	String:sName[EFFECT_MAX],
	String:sParticle[EFFECT_MAX],
	bool:bIsDonator,
	bool:bIsDisabled,
	
}; 
int eEffects[EFFECT_MAX_COUNT][Effects];

public Plugin myinfo = 
{
	name = "[TF2] Unusual Arrows",
	author = "TheWreckingCrew6",
	description = "Add Unusual Effects to your arrows!",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2418097"
}

Handle g_Cvar_Enabled = INVALID_HANDLE;

Handle g_Cvar_AutoUpdate = INVALID_HANDLE;
Handle g_Cvar_ReloadUpdate = INVALID_HANDLE;

Handle g_Cvar_DisabledEffects = INVALID_HANDLE;
Handle g_Cvar_RequiredFlag = INVALID_HANDLE;
Handle g_Cvar_DonatorFlag = INVALID_HANDLE;
Handle g_Cvar_DisabledProjectiles = INVALID_HANDLE;
Handle g_Cvar_NoEffectOption = INVALID_HANDLE;

Handle gH_AdminMenu;
Handle gH_SQL;
char gS_SQLDriver[16];

bool g_bUpdater = false;
bool g_bForceUpdate = false;

bool g_bLateLoad = false;

char gS_DisPart[32][128];

int	g_iEffectCount = 0;
int g_iCoreEffectCount = 0;
int g_iChangeChoice[MAXPLAYERS + 1];

bool g_bEffectsLoaded[MAXPLAYERS + 1];
bool g_bDisabled[MAXPLAYERS + 1];

char gS_Auth[MAXPLAYERS + 1][32];

int g_iEffectChoice[MAXPLAYERS + 1][PROJ_COUNT];

char g_Projectile_Classnames[][] = { "tf_projectile_arrow", "tf_projectile_ball_ornament", "tf_projectile_energy_ball", "tf_projectile_energy_ring", 
	"tf_projectile_cleaver", "tf_projectile_flare", "tf_projectile_grapplinghook", "tf_projectile_healing_bolt", "tf_projectile_jar", 
	"tf_projectile_jar_milk", "tf_projectile_pipe", "tf_projectile_pipe_remote", "tf_projectile_rocket", "tf_projectile_stun_ball", "tf_projectile_syringe" };
	
char g_Projectile_Names[][] = { "Arrow", "Ornament", "Energy Ball", "Energy Ring", "Cleaver", "Flare", "Grappling Hook", "Healing Bolt", "Jar", 
	"Milk", "Pipe", "Sticky", "Rocket", "Sandman Ball", "Syringe" };
	
char g_Projectile_SQL[][] = { "arrow", "ornament", "energyball", "energyring", "cleaver", "flare", "grappling", "healingbolt", "jar", "milk", "pipe", 
	"remotepipe", "rocket", "stunball", "syringe" };

/******************************************************************************************
 *                                  PLUGIN STARTUP FUNCTIONS                              *
 ******************************************************************************************/

//For our natives and late loading.
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	
	return APLRes_Success;
}

//When our plugin starts up, everything has to get setup.
public void OnPluginStart()
{
	//Translations
	LoadTranslations("common.phrases");
	LoadTranslations("unusual_arrows.phrases");
	
	if(!ParseEffects())
		return;
	
	ParseCustomEffects();
		
	//Basic Version CVar
	CreateConVar("ua_version", VERSION, "Unusual Arrows Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	//Plugin Controls
	g_Cvar_Enabled = CreateConVar("ua_enabled", "1", "Enable Unusual Arrows?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_Cvar_AutoUpdate = CreateConVar("ua_autoupdate", "1", "If Updater is installed, we want to autoupdate this ish.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_ReloadUpdate = CreateConVar("ua_reloadupdate", "1", "If an Update is installed, do you want to reload the plugin automatically?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Unusual Projectiles Settings
	g_Cvar_DisabledEffects = CreateConVar("ua_disabledeffects", "", "List the effect numbers you want to disable. Seperate multiple with a ','.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_Cvar_RequiredFlag = CreateConVar("ua_adminflag", "", "What flag should clients have to use the feature at all? (Leave blank for none)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_Cvar_DonatorFlag = CreateConVar("ua_donatorflag", "a", "What flag should identify clients as a donator?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_Cvar_DisabledProjectiles = CreateConVar("ua_disabledproj", "", "List the projectile names you wish to disable. Seperate multiple with a ','.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_Cvar_NoEffectOption = CreateConVar("ua_noeffectoption", "1", "Should there be an option to have no effect in the menu?", FCVAR_PLUGIN);
	
	//Create That File
	AutoExecConfig(true, "unusual_arrows");
	
	RegConsoleCmd("uae", Command_Effects, "Choose your arrow effect");
	
	RegAdminCmd("ua_update", Command_Update, ADMFLAG_ROOT, "Force check for an update for Unusual Arrows.");
	RegAdminCmd("ua_reload", Command_Reload, ADMFLAG_ROOT, "Force reloads config files for Unusual Arrows.");
	
	//If the adminmenu is loaded, let's get it going in here! :D
	Handle topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	gH_SQL = INVALID_HANDLE;
	if(SQL_CheckConfig("ua"))
		SQL_TConnect(SQLQuery_Connect, "ua");
}

//Once our plugins our loaded, let's see if steamtools is up and running.
public void OnAllPluginsLoaded()
{
	g_bUpdater = LibraryExists("updater");
	
	if (g_bUpdater)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

//Once our configs are done executing, we can get started up in here.
public void OnConfigsExecuted()
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (g_bLateLoad)
	{
		g_bLateLoad = false;
	}
	ParseDisabledEffects();
	ParseDisabledProjectiles();
}

/******************************************************************************************
 *                                     LIBRARY FUNCTIONS                                  *
 ******************************************************************************************/

//If libraries are added, we need to change something.
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
    {
		g_bUpdater = true;
    }
	
	if (g_bUpdater)
		Updater_AddPlugin(UPDATE_URL);
}

//Can't keep trying to use libraries that aren't there anymore.
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		gH_AdminMenu = INVALID_HANDLE;
	}
	
	else if (StrEqual(name, "updater"))
	{
		g_bUpdater = false;
	}
}

/******************************************************************************************
 *                                       UPDATER                                          *
 ******************************************************************************************/

//When Updater is Checking for an update, here's what we wish to do.
public Action Updater_OnPluginChecking (){

	if(!GetConVarBool(g_Cvar_AutoUpdate) && !g_bForceUpdate)
		return Plugin_Handled;
		
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Checking", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Checking", LANG_SERVER);
	
	g_bForceUpdate = false;
	
	return Plugin_Continue;

}

public Action Updater_OnPluginDownloading()
{
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Download", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Download", LANG_SERVER);
	
	return Plugin_Continue;
}

public int Updater_OnPluginUpdating()
{
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Install", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Install", LANG_SERVER);
}

//When our plugin is updated, if you want to reload the plugin, it will reload it.
public int Updater_OnPluginUpdated ()
{
	PrintToServer("%s %T", CHAT_PREF, "Successful_Update", LANG_SERVER);
	
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Successful_Update", i);
	}
	
	if(GetConVarBool(g_Cvar_ReloadUpdate))
	{
		ReloadPlugin();
		PrintToServer("%s %T", CHAT_PREF, "Reload_Plugin", LANG_SERVER);
		for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Reload_Plugin", i);
	}
	}
}

public void Update(int client)
{
	if(!g_bUpdater)
	{
		CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "No_Updater", client);
	}
	else
	{
		g_bForceUpdate = true;
		if(!Updater_ForceUpdate())
		{
			CReplyToCommand(client, "%s %T", CHAT_PREF_COLOR, "Cant_Update", client);
		}
		g_bForceUpdate = false;
	}
}

/******************************************************************************************
 *                           SETTING UP OUR NEEDED VARIABLES :D                           *
 ******************************************************************************************/

//On map start let's initialize our variables.
public void OnMapStart()
{
	for(int i = 0; i < MAXPLAYERS + 1; i++)
	{
		SQL_LoadEffects(i);
	}
}

public void OnClientConnected(int client)
{
	g_bEffectsLoaded[client] = false;
	g_bDisabled[client] = false;
	strcopy(gS_Auth[client], sizeof(gS_Auth[]), "");
}

public void OnClientAuthorized(int iClient, const char[] strAuth)
{
	strcopy(gS_Auth[iClient], sizeof(gS_Auth[]), strAuth);
}

public void OnClientPostAdminCheck(int iClient)
{
	SQL_LoadEffects(iClient);
}

public int OnRebuildAdminCache(AdminCachePart iPart)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		OnClientConnected(i);
		OnClientPostAdminCheck(i);
	}
}

//Once a client is in, we need to prepare them for our gamemode.
public void OnClientPutInServer(int client)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
}

//When a client disconnects, let's default all their variables back to normal.
public void OnClientDisconnect_Post(int client)
{
	for(int i = 0; i < PROJ_COUNT; i++)
	{
		g_iEffectChoice[client][i] = -1;
	}
}

bool ParseEffects()
{
	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/ua_effects.default.cfg");
	
	if(!FileExists(sPath)){
	
		LogError("%s Failed to find ua_effects.default.cfg in configs/ folder!", CHAT_PREF);
		SetFailState("Failed to find ua_effects.default.cfg in configs/ folder!");
		return false;
	
	}
	
	g_iEffectCount = 0;
	Handle hKv = CreateKeyValues("Effects");
	int iPrevId = 0, iDonator = 0, iNormal = 0, iWarnings = 0;
	
	if(FileToKeyValues(hKv, sPath) && KvGotoFirstSubKey(hKv)){
	
		char sEffectId[4], sParticleBuffer[EFFECT_MAX];
		int iEffectId = 1;
		do{
	
			KvGetSectionName(hKv, sEffectId, sizeof(sEffectId));
			iEffectId = StringToInt(sEffectId);
			
			if(iPrevId +1 != iEffectId){
			
				LogError("%s Disorder in ua_effects.default.cfg detected; aborting! (iEffectId: %d)", CHAT_PREF, iEffectId);
				SetFailState("Disorder in ua_effects.default.cfg detected; aborting! (iEffectId: %d)", iEffectId);
				return false;
			
			}
			iPrevId++;
			
				//----[ NAME ]----//
			
			KvGetString(hKv, "name", eEffects[iEffectId][sName], EFFECT_MAX);		
			
				//----[ PARTICLE ]----//
			
			strcopy(sParticleBuffer, EFFECT_MAX, "");
			KvGetString(hKv, "particle", sParticleBuffer, 64);
			
			EscapeString(sParticleBuffer, ' ', '\0', eEffects[iEffectId][sParticle], EFFECT_MAX);
			
				//----[ IsDonator ]----//
			
			eEffects[iEffectId][bIsDonator] = (KvGetNum(hKv, "donator", 0) == 1 ? true : false);
			
				//----[ STATS ]----//
			
			if(eEffects[iEffectId][bIsDonator])
				iDonator++;
			else
				iNormal++;
			
			g_iEffectCount++;
			g_iCoreEffectCount++;
		
		
		}while(KvGotoNextKey(hKv));
		
		PrintToServer("%s Loaded %d %s (%d donator, %d normal; with %d warnings).", CHAT_PREF, g_iEffectCount, g_iEffectCount > 1 ? "Effects" : "Effect", iDonator, iNormal, iWarnings);
	
		if(hKv != INVALID_HANDLE)
			CloseHandle(hKv);
		
		return true;
	
	}
	
	if(hKv != INVALID_HANDLE)
		CloseHandle(hKv);
	
	return false;
}

void ParseCustomEffects	(){

	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/ua_effects.custom.cfg");

	if(!FileExists(sPath)){
		return;
	}

	int iCustomEffectCount = 0;
	Handle hKv = CreateKeyValues("Effects");
	
	if(FileToKeyValues(hKv, sPath) && KvGotoFirstSubKey(hKv)){
	
		Handle hCustomized = CreateArray();
		char sEffectId[4];
		int iEffectId = 1;
		do{

			KvGetSectionName(hKv, sEffectId, sizeof(sEffectId));
			iEffectId = StringToInt(sEffectId);

			if(iEffectId >= g_iEffectCount || iEffectId < 0)
				continue;
			
			
				//----[ NAME ]----//
			
			if(KvJumpToKey(hKv, "name")){
			
				KvGoBack(hKv);
				KvGetString(hKv, "name", eEffects[iEffectId][sName], EFFECT_MAX);
			
			}
			
			
				//----[ PARTICLE ]----//
			
			if(KvJumpToKey(hKv, "particle")){
				KvGoBack(hKv);
				KvGetString(hKv, "particle", eEffects[iEffectId][sParticle], EFFECT_MAX);
			}
			
			
				//----[ IsDonator ]----//
			
			if(KvJumpToKey(hKv, "IsDonator")){
				KvGoBack(hKv);
				eEffects[iEffectId][bIsDonator] = KvGetNum(hKv, "donator", 0) == 1 ? true : false;
			}
			
			if(FindValueInArray(hCustomized, iEffectId) > -1)
				continue;
			
			
			iCustomEffectCount++;
			PushArrayCell(hCustomized, iEffectId);
		
		}while(KvGotoNextKey(hKv));
		
		PrintToServer("%s Customized %d effect%s.", CHAT_PREF, iCustomEffectCount, iCustomEffectCount == 1 ? "" : "s");
		delete hCustomized;
	
	}
	
	if(hKv != INVALID_HANDLE)
		CloseHandle(hKv);
}

void ParseDisabledEffects()
{
	for(int i = 1; i < g_iEffectCount; i++)
		eEffects[i][bIsDisabled] = false;

	char sDisabled[2][255];
	GetConVarString(g_Cvar_DisabledEffects, sDisabled[0], 255);
	EscapeString(sDisabled[0], ' ', '\0', sDisabled[1], 255);
	
	if(strlen(sDisabled[1]) == 0)
		return;

	int iDisabledNum = CountCharInString(sDisabled[1], ',') +1;
	char[][] sDisabledPieces = new char[iDisabledNum][32];
	ExplodeString(sDisabled[1], ",", sDisabledPieces, iDisabledNum, 32);

	int iEffectId = -1, iArraySize = 0;
	Handle hDisabledArray = CreateArray();
	for(int i = 0; i < iDisabledNum; i++){

		iEffectId = StringToInt(sDisabledPieces[i]);
		if(iEffectId < 1)
			continue;

		if(FindValueInArray(hDisabledArray, iEffectId) != -1)
			continue;

		eEffects[iEffectId][bIsDisabled] = true;
		PushArrayCell(hDisabledArray, iEffectId);
		iArraySize++;
	}
	
	delete hDisabledArray;
}

void ParseDisabledProjectiles()
{
	char sDisabled[2][255];
	GetConVarString(g_Cvar_DisabledProjectiles, sDisabled[0], 255);
	EscapeString(sDisabled[0], ' ', '\0', sDisabled[1], 255);
	
	if(strlen(sDisabled[1]) == 0)
		return;

	int iDisabledNum = CountCharInString(sDisabled[1], ',') +1;
	ExplodeString(sDisabled[1], ",", gS_DisPart, iDisabledNum, 128);
}

/******************************************************************************************
 *                                     ADMIN MENU SUPPORT                                 *
 ******************************************************************************************/

//When the admin menu is ready, lets define our topmenu object, and add our commands to it.
public void OnAdminMenuReady(Handle topmenu)
{
	if(topmenu == gH_AdminMenu)
	{
		return;
	}
	
	gH_AdminMenu = topmenu;
	
	TopMenuObject server_commands = FindTopMenuCategory(gH_AdminMenu, ADMINMENU_SERVERCOMMANDS);
	
	AddToTopMenu(gH_AdminMenu, "ua_update", TopMenuObject_Item, AdminMenu_Updater, server_commands, "ua_update", ADMFLAG_ROOT);
	AddToTopMenu(gH_AdminMenu, "ua_reload", TopMenuObject_Item, AdminMenu_Reload, server_commands, "ua_reload", ADMFLAG_ROOT);
}

public void AdminMenu_Updater(Handle hTopMenu, TopMenuAction action, TopMenuObject tmoObjectID, int param, char[] szBuffer, int iMaxLength)
{
	if(!IsValidClient(param))
		return;
		
	if (action == TopMenuAction_DisplayOption)
	{
		Format(szBuffer, iMaxLength, "%T", "Check_Updater", param);
	}
	else if (action == TopMenuAction_SelectOption && g_bUpdater && GetConVarBool(g_Cvar_AutoUpdate))
	{
		Update(param);
	}
}

public void AdminMenu_Reload(Handle hTopMenu, TopMenuAction action, TopMenuObject tmoObjectID, int param, char[] szBuffer, int iMaxLength)
{
	if(!IsValidClient(param))
		return;
		
	if (action == TopMenuAction_DisplayOption)
	{
		Format(szBuffer, iMaxLength, "%T", "Reload", param);
	}
	else if (action == TopMenuAction_SelectOption && g_bUpdater && GetConVarBool(g_Cvar_AutoUpdate))
	{
		ParseEffects();
		ParseCustomEffects();
	}
}

/******************************************************************************************
 *                                       COMMANDS                                         *
 ******************************************************************************************/
 
//Our Update Command, that allows you to update the plugin on command.
public Action Command_Update (int client, int args){

	if(!g_bUpdater || !GetConVarBool(g_Cvar_AutoUpdate)){
	
		CReplyToCommand(client, "%s %T", CHAT_PREF_COLOR, "No_Updater", client);
		return Plugin_Handled;
	}
	
	Update(client);
	
	return Plugin_Handled;
}

public Action Command_Effects(int client, int args)
{
	if(!GetConVarBool(g_Cvar_Enabled))
		return Plugin_Continue;
		
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	if(!IsClientAllowed(client))
	{
		CReplyToCommand(client, "%s %T", CHAT_PREF_COLOR, "No_Access", client);
		return Plugin_Handled;
	}

	DisplayGroups(client);
	
	return Plugin_Handled;
}

public Action Command_Reload(int client, int args)
{
	ParseEffects();
	ParseCustomEffects();

	return Plugin_Handled;
}

/******************************************************************************************
 *                                    EFFECTS MENU                                        *
 ******************************************************************************************/
 
public void DisplayGroups(int client)
{
	Handle menu = CreateMenu(MenuHandler_EffectsSection);
	SetMenuTitle(menu, "%T", "Choose_Effect_Group", client);
	
	char CEMenu[128];
	Format(CEMenu, sizeof(CEMenu), "%T", "Current_Effects", client);
	
	char Disable[32];
	if(g_bDisabled[client])
		Format(Disable, sizeof(Disable), "%T", "Enable_Effects", client);
	else
		Format(Disable, sizeof(Disable), "%T", "Disable_Effects", client);
	
	char DMenu[32];
	Format(DMenu, sizeof(DMenu), "%T", "Donator_Effects", client);
	
	char NMenu[32];
	Format(NMenu, sizeof(NMenu), "%T", "Normal_Effects", client);
	
	AddMenuItem(menu, "0", CEMenu);
	
	AddMenuItem(menu, "3", Disable);
	
	bool IsThereDonator = false;
	for(int i = 1; i < g_iEffectCount; i++)
	{
		if(eEffects[i][bIsDonator])
			IsThereDonator = true;
	}
	
	if(IsClientDonator(client) && IsThereDonator)
		AddMenuItem(menu, "1", DMenu);
		
	AddMenuItem(menu, "2", NMenu);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
} 

public int MenuHandler_EffectsSection(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[8];
		GetMenuItem(menu, param2, info, 8);
		int choice = StringToInt(info);
		
		switch(choice)
		{
			case 0:
			{
				DisplayChosenEffects(param1);
			}
			case 1:
			{
				DisplayDonatorEffects(param1);
			}
			
			case 2:
			{
				DisplayEffects(param1);
			}
			
			case 3:
			{
				if(g_bDisabled[param1])
				{
					g_bDisabled[param1] = false;
					CPrintToChat(param1, "%s%T", CHAT_PREF_COLOR, "Effects_Enabled", param1);
				}
				else
				{
					g_bDisabled[param1] = true;
					CPrintToChat(param1, "%s%T", CHAT_PREF_COLOR, "Effects_Disabled", param1);
				}

				if(gH_SQL != INVALID_HANDLE && IsClientAllowed(param1))
				{
					char strQuery[256];
					Format(strQuery, sizeof(strQuery), "SELECT disabled FROM ua_users WHERE auth = '%s'", gS_Auth[param1]);
					SQL_TQuery(gH_SQL, SQLQuery_Disable, strQuery, GetClientUserId(param1), DBPrio_High);
				}
			}
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public void DisplayChosenEffects(int client)
{
	if(!GetConVarBool(g_Cvar_Enabled))
		return;
		
	if(!IsValidClient(client))
		return;
	
	Handle menu = CreateMenu(MenuHandler_ChosenEffects);
	SetMenuTitle(menu, "%T", "Current_Effects", client);
	
	for(int i = 0; i < PROJ_COUNT; i++)
	{
		char info[32];
		if(g_iEffectChoice[client][i] == 0)
			Format(info, sizeof(info), "%s: None", g_Projectile_Names[i]);
		else
			Format(info, sizeof(info), "%s: %s", g_Projectile_Names[i], eEffects[g_iEffectChoice[client][i]][sName]);
		
		AddMenuItem(menu, "", info, ITEMDRAW_DISABLED);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_ChosenEffects(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayGroups(param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public void DisplayDonatorEffects(int client)
{
	if(!GetConVarBool(g_Cvar_Enabled))
		return;
		
	if(!IsValidClient(client))
		return;
		
	Handle menu = CreateMenu(MenuHandler_Effects);
	SetMenuTitle(menu, "%T", "Choose_Effect", client);
	
	if(GetConVarBool(g_Cvar_NoEffectOption))
		AddMenuItem(menu, "-1", "No Effect");
	
	for(int i = 0; i < g_iEffectCount; i++)
	{
		char info[8];
		IntToString(i, info, sizeof(info));
		char name[EFFECT_MAX];
		strcopy(name, sizeof(name), eEffects[i][sName]);
		
		if(eEffects[i][bIsDonator])
		{
				AddMenuItem(menu, info, name);
		}
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public void DisplayEffects(int client)
{
	if(!GetConVarBool(g_Cvar_Enabled))
		return;
		
	if(!IsValidClient(client))
		return;

	Handle menu = CreateMenu(MenuHandler_Effects);
	SetMenuTitle(menu, "%T", "Choose_Effect", client);
	
	if(GetConVarBool(g_Cvar_NoEffectOption))
		AddMenuItem(menu, "-1", "No Effect");
	
	for(int i = 1; i < g_iEffectCount; i++)
	{
		char info[8];
		IntToString(i, info, sizeof(info));
		char name[EFFECT_MAX];
		strcopy(name, sizeof(name), eEffects[i][sName]);
		
		if(!eEffects[i][bIsDonator])
			AddMenuItem(menu, info, name);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Effects(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[8];
		GetMenuItem(menu, param2, info, 8);
		
		int effect = StringToInt(info);
		DisplayProjectileOptions(param1, effect);
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayGroups(param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public void DisplayProjectileOptions(int client, int effect)
{
	if(!GetConVarBool(g_Cvar_Enabled))
		return;
		
	if(!IsValidClient(client))
		return;
		
	Handle menu = CreateMenu(MenuHandler_Projectiles);
	SetMenuTitle(menu, "%T", "Effect_Location", client);
	
	char info[32];
	Format(info, sizeof(info), "%i;%i", -1, effect);
	AddMenuItem(menu, info, "All");
	
	for(int i = 0; i < PROJ_COUNT; i++)
	{
		Format(info, sizeof(info), "%i;%i", i, effect);
		AddMenuItem(menu, info, g_Projectile_Names[i]);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Projectiles(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, 32);
		char info2[2][32];
		ExplodeString(info, ";", info2, 2, 32, false);
		
		int choice = StringToInt(info2[0]);
		int effect = StringToInt(info2[1]);
		
		if(choice == -1)
		{
			for(int i = 0; i < PROJ_COUNT; i++)
			{
				g_iEffectChoice[param1][i] = effect;
			}
			
			if(gH_SQL != INVALID_HANDLE && IsClientAllowed(param1))
			{
				char strQuery[256];
				Format(strQuery, sizeof(strQuery), "SELECT arrow, ornament, energyball, energyring, cleaver, flare, grappling, healingbolt, jar, milk, pipe, remotepipe, rocket, stunball, syringe FROM ua_users WHERE auth = '%s'", gS_Auth[param1]);
				SQL_TQuery(gH_SQL, SQLQuery_AllEffects, strQuery, GetClientUserId(param1), DBPrio_High);
			}
				
			char effectName[64];
			Format(effectName, sizeof(effectName), "{violet}%s{cyan}", eEffects[effect][sName]);
			CPrintToChat(param1, "%s%T", CHAT_PREF_COLOR, "Chosen_Effect_All", param1, effectName);
		}
		else
		{
			g_iEffectChoice[param1][choice] = effect;
			
			if(gH_SQL != INVALID_HANDLE && IsClientAllowed(param1))
			{
				char strQuery[256];
				Format(strQuery, sizeof(strQuery), "SELECT %s FROM ua_users WHERE auth = '%s'", g_Projectile_SQL[choice], gS_Auth[param1]);
				g_iChangeChoice[param1] = choice;
				SQL_TQuery(gH_SQL, SQLQuery_Effects, strQuery, GetClientUserId(param1), DBPrio_High);
			}
			
			char effectName[64];
			Format(effectName, sizeof(effectName), "{violet}%s{cyan}", eEffects[effect][sName]);
			char projectileName[64];
			Format(projectileName, sizeof(projectileName), "{violet}%s{cyan}", g_Projectile_Names[choice]);
			CPrintToChat(param1, "%s%T", CHAT_PREF_COLOR, "Chosen_Effect", param1, effectName, projectileName);
		}
		
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayGroups(param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

/******************************************************************************************
 *                                 TF2 CONDITION FORWARDS                                 *
 ******************************************************************************************/

//When an entity is created, this is automatically called.
public void OnEntityCreated(int entity, const char[] classname)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (StrContains(classname, "tf_projectile") != -1)
	{
		for(int i = 0; i < sizeof(gS_DisPart); i++)
		{
			if(StrEqual(classname, gS_DisPart[i]))
				return;
		}
		SDKHook(entity, SDKHook_Spawn, Unusualify);
	}
}

/******************************************************************************************
 *                                    ADDING THE EFFECTS                                  *
 ******************************************************************************************/

public void Unusualify(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	char name[32];
	GetEntityClassname(entity, name, sizeof(name));
	
	if(client < 1 || !IsClientAllowed(client) || g_bDisabled[client])
	{
		return; //Not valid client
	}
	
	int proj = -1;
	for(int i = 0; i < PROJ_COUNT; i++)
	{
		if(StrEqual(g_Projectile_Classnames[i], name))
			proj = i;
	}
	
	if(proj == -1)
	{
		return;
	}

	AddParticle(entity, proj);
	
	//Unhook to prevent being called twice
	SDKUnhook(entity, SDKHook_Spawn, Unusualify);
}

public void AddParticle(int entity, int projectile)
{
	//new amount = GetConVarInt(v_HowHoly);
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int amount = 1;
	
	if(g_iEffectChoice[client][projectile] == 0)
	{
		return;
	}
	
	if(eEffects[g_iEffectChoice[client][projectile]][bIsDonator] && !IsClientDonator(client))
		return;
	
	for(int i=1; i <= amount; i++)
	{
		CreateParticle(entity, eEffects[g_iEffectChoice[client][projectile]][sParticle], true);
	}
}

stock int CreateParticle(int iEntity, char[] strParticle, bool bAttach = false, char[] strAttachmentPoint="", float fOffset[3]={0.0, 0.0, 0.0})
{
    int iParticle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(iParticle))
    {
        float fPosition[3];
        float fAngles[3];
        float fForward[3];
        float fRight[3];
        float fUp[3];
		
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
        // Determine vectors and apply offset
        GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
        fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
        fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
        fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];

        TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(iParticle, "effect_name", strParticle);

        if (bAttach == true)
        {
            SetVariantString("!activator");
            AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);            
            
            if (StrEqual(strAttachmentPoint, "") == false)
            {
                SetVariantString(strAttachmentPoint);
                AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);                
            }
        }

        // Spawn and start
        DispatchSpawn(iParticle);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "Start");
    }

    return iParticle;
}

/******************************************************************************************
 *                                           SQL                                          *
 ******************************************************************************************/
 
 public void SQLQuery_Connect(Handle hOwner, Handle hQuery, const char[] strError, any iData)
{
	if(hQuery == INVALID_HANDLE)
		return;

	gH_SQL = hQuery;
	SQL_GetDriverIdent(hOwner, gS_SQLDriver, sizeof(gS_SQLDriver));

	if(StrEqual(gS_SQLDriver, "mysql", false))
	{
		LogMessage("MySQL server configured. Variable saving enabled.");
		SQL_TQuery(gH_SQL, SQLQuery_Update, "CREATE TABLE IF NOT EXISTS ua_users (id INT(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, disabled varchar(1), arrow INT, ornament INT, energyball INT, energyring INT, cleaver INT, flare INT, grappling INT, healingbolt INT, jar INT, milk INT, pipe INT, remotepipe INT, rocket INT, stunball INT, syringe INT, PRIMARY KEY (id))", _, DBPrio_High);
	}
	else if(StrEqual(gS_SQLDriver, "sqlite", false))
	{
		LogMessage("SQlite server configured. Variable saving enabled.");
		SQL_TQuery(gH_SQL, SQLQuery_Update, "CREATE TABLE IF NOT EXISTS ua_users (id INTERGER PRIMARY KEY, auth varchar(32) UNIQUE, disabled varchar(1), arrow INT, ornament INT, energyball INT, energyring INT, cleaver INT, flare INT, grappling INT, healingbolt INT, jar INT, milk INT, pipe INT, remotepipe INT, rocket INT, stunball INT, syringe INT)", _, DBPrio_High);
	}
	else
	{
		LogMessage("Saved variable server not configured. Variable saving disabled.");
		return;
	}

	for(int i = 1; i <= MaxClients; ++i) if(IsClientInGame(i))
		SQL_LoadEffects(i);
}

public void SQLQuery_LoadEffects(Handle hOwner, Handle hQuery, const char[] strError, any iData)
{
	int iClient = GetClientOfUserId(iData);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_FetchRow(hQuery) && SQL_GetRowCount(hQuery) != 0)
	{
		g_bDisabled[iClient] = view_as<bool>(SQL_FetchInt(hQuery, 0));
		for(int i = 0; i < PROJ_COUNT; i++)
		{
			g_iEffectChoice[iClient][i] = SQL_FetchInt(hQuery, (i + 1));
		}

		g_bEffectsLoaded[iClient] = true;
	}
}

public void SQL_LoadEffects(int iClient)
{
	if(!IsClientAllowed(iClient))
		return;

	if(gH_SQL != INVALID_HANDLE)
	{
		char strAuth[32];
		GetClientAuthId(iClient, AuthId_Steam2, strAuth, sizeof(strAuth), true);
		strcopy(gS_Auth[iClient], sizeof(gS_Auth[]), strAuth);

		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT disabled, arrow, ornament, energyball, energyring, cleaver, flare, grappling, healingbolt, jar, milk, pipe, remotepipe, rocket, stunball, syringe FROM ua_users WHERE auth = '%s'", gS_Auth[iClient]);
		SQL_TQuery(gH_SQL, SQLQuery_LoadEffects, strQuery, GetClientUserId(iClient), DBPrio_High);
	}
}

public void SQLQuery_Disable(Handle hOwner, Handle hQuery, const char[] strError, any iClientId)
{
	int iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO ua_users (disabled, auth) VALUES (%i, '%s')", g_bDisabled[iClient], gS_Auth[iClient]);
		SQL_TQuery(gH_SQL, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE ua_users SET disabled = '%i' WHERE auth = '%s'", g_bDisabled[iClient], gS_Auth[iClient]);
		SQL_TQuery(gH_SQL, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

public void SQLQuery_Effects(Handle hOwner, Handle hQuery, const char[] strError, any iClientId)
{
	int iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO ua_users (%s, auth) VALUES (%i, '%s')", g_Projectile_SQL[g_iChangeChoice[iClient]], g_iEffectChoice[iClient][g_iChangeChoice[iClient]], gS_Auth[iClient]);
		SQL_TQuery(gH_SQL, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE ua_users SET %s = %i WHERE auth = '%s'", g_Projectile_SQL[g_iChangeChoice[iClient]], g_iEffectChoice[iClient][g_iChangeChoice[iClient]], gS_Auth[iClient]);
		SQL_TQuery(gH_SQL, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

public void SQLQuery_AllEffects(Handle hOwner, Handle hQuery, const char[] strError, any iClientId)
{
	int iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}
	
	int i = g_iEffectChoice[iClient][0];

	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO ua_users (arrow, ornament, energyball, energyring, cleaver, flare, grappling, healingbolt, jar, milk, pipe, remotepipe, rocket, stunball, syringe, auth) VALUES (%i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, '%s')", i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, gS_Auth[iClient]);
		SQL_TQuery(gH_SQL, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE ua_users SET arrow = %i, ornament = %i, energyball = %i, energyring = %i, cleaver = %i, flare = %i, grappling = %i, healingbolt = %i, jar = %i, milk = %i, pipe = %i, remotepipe = %i, rocket = %i, stunball = %i, syringe = %i WHERE auth = '%s'", i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, gS_Auth[iClient]);
		SQL_TQuery(gH_SQL, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

public void SQLQuery_Update(Handle hOwner, Handle hQuery, const char[] strError, any iData)
{
	if(hQuery == INVALID_HANDLE)
		LogError("SQL Error: %s", strError);
}

/******************************************************************************************
 *                                         STOCKS                                         *
 ******************************************************************************************/

//Checks a client to see if it is valid.
stock bool IsValidClient(int client, bool checkstv = true) {
	if (client <= 0 || client > MaxClients)
		return false;
	if (!IsClientInGame(client))
		return false;
	if (checkstv && (IsClientReplay(client) || IsClientSourceTV(client)))
		return false;
	return true;
}

stock int EscapeString(const char[] input, int escape, int escaper, char[] output, int maxlen)
{
	// Number of chars we escaped
	int escaped = 0;

	// Format output buffer to ""
	Format(output, maxlen, "");


	// For each char in the input string
	for(int offset = 0; offset < strlen(input); offset++){

		// Get char at the current position
		int ch = input[offset];

		// Found the escape or escaper char
		if(ch == escape || ch == escaper){

			// Escape the escape char with the escaper^^
			Format(output, maxlen, "%s%c%c", output, escaper, ch);

			// Increase numbers of chars we escaped
			escaped++;

		}else
			// Add other char to output buffer
			Format(output, maxlen, "%s%c", output, ch);
	}

	// Return escaped chars
	return escaped;
}

stock int CountCharInString (const char[] sString, char cChar)
{

	int i = 0, count = 0;
	
	while(sString[i] != '\0')
		if(sString[i++] == cChar)
			count++;

	return count;

}

stock int ReadFlagFromConVar(Handle hCvar)
{

	char sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));

	return ReadFlagString(sBuffer);

}

stock bool IsClientAllowed (int client)
{
	if(!IsValidClient(client))
	{
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	char flags[16];
	GetConVarString(g_Cvar_RequiredFlag, flags, sizeof(flags));
	int ibFlags = ReadFlagString(flags);
	
	if(!StrEqual(flags, ""))
	{
		if(view_as<bool>(GetUserFlagBits(client) & ibFlags))
		{
			return true;
		}
	}
	else if(StrEqual(flags, ""))
	{
		return true;
	}
	
	return false;
}

stock bool IsClientDonator(int client)
{
	if(!IsValidClient(client))
	{
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	char flags[16];
	GetConVarString(g_Cvar_DonatorFlag, flags, sizeof(flags));
	int ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if(view_as<bool>(GetUserFlagBits(client) & ibFlags))
		{
			return true;
		}
	}
	
	return false;
}