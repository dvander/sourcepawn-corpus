#include <sourcemod>
#include <entity_prop_stocks>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <adminmenu>

#include <updater>
#include <morecolors>

#define CHAT_PREF_COLOR "{gold}[UA] {cyan}"
#define CHAT_PREF "[UA] "

#define EFFECT_MAX_COUNT 100
#define EFFECT_MAX 64

#define VERSION "1.0.1"

#define UPDATE_URL    "http://www.tf2app.com/thewreckingcrew6/plugins/ua/updater.txt"

enum Effects{

	String:sName[EFFECT_MAX],
	String:sParticle[EFFECT_MAX],
	bool:bIsDonator,
	bool:bIsDisabled,
	
}; 
int eEffects[EFFECT_MAX_COUNT][Effects];

public Plugin:myinfo = 
{
	name = "[TF2] Unusual Arrows",
	author = "TheWreckingCrew6",
	description = "Add Unusual Effects to your arrows!",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2418097"
}

new Handle:g_Cvar_Enabled = INVALID_HANDLE;

new Handle:g_Cvar_AutoUpdate = INVALID_HANDLE;
new Handle:g_Cvar_ReloadUpdate = INVALID_HANDLE;

new Handle:g_Cvar_DisabledEffects = INVALID_HANDLE;
new Handle:g_Cvar_RequiredFlag = INVALID_HANDLE;
new Handle:g_Cvar_DonatorFlag = INVALID_HANDLE;
new Handle:g_Cvar_DisabledProjectiles = INVALID_HANDLE;

new Handle:gH_AdminMenu;

new bool:g_bUpdater = false;
new bool:g_bForceUpdate = false;

new bool:g_bLateLoad = false;

new String:gS_DisPart[32][128];

int	g_iEffectCount = 0;
int g_iCoreEffectCount = 0;

int g_iEffectChoice[MAXPLAYERS + 1];

/******************************************************************************************
 *                                  PLUGIN STARTUP FUNCTIONS                              *
 ******************************************************************************************/

//For our natives and late loading.
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	
	return APLRes_Success;
}

//When our plugin starts up, everything has to get setup.
public OnPluginStart()
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
	
	//Create That File
	AutoExecConfig(true, "unusual_arrows");
	
	RegConsoleCmd("ua_effects", Command_Effects, "Choose your arrow effect");
	
	RegAdminCmd("ua_update", Command_Update, ADMFLAG_ROOT, "Force check for an update for Unusual Arrows.");
	RegAdminCmd("ua_reload", Command_Reload, ADMFLAG_ROOT, "Force reloads config files for Unusual Arrows.");
	
	//If the adminmenu is loaded, let's get it going in here! :D
	new Handle:topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

//Once our plugins our loaded, let's see if steamtools is up and running.
public OnAllPluginsLoaded()
{
	g_bUpdater = LibraryExists("updater");
	
	if (g_bUpdater)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

//Once our configs are done executing, we can get started up in here.
public OnConfigsExecuted()
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(g_iEffectChoice[i] < 0)
			{
				g_iEffectChoice[i] = GetRandomInt(0, g_iEffectCount);
				while(!IsClientDonator(i) && eEffects[g_iEffectChoice[i]][bIsDonator])
					g_iEffectChoice[i] = GetRandomInt(0, g_iEffectCount);
				
			}
		}
		g_bLateLoad = false;
	}
	ParseDisabledEffects();
	ParseDisabledProjectiles();
}

/******************************************************************************************
 *                                     LIBRARY FUNCTIONS                                  *
 ******************************************************************************************/

//If libraries are added, we need to change something.
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
    {
		g_bUpdater = true;
    }
	
	if (g_bUpdater)
		Updater_AddPlugin(UPDATE_URL);
}

//Can't keep trying to use libraries that aren't there anymore.
public OnLibraryRemoved(const String:name[])
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
		
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Checking", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Checking", LANG_SERVER);
	
	g_bForceUpdate = false;
	
	return Plugin_Continue;

}

public Action:Updater_OnPluginDownloading()
{
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Download", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Download", LANG_SERVER);
	
	return Plugin_Continue;
}

public Updater_OnPluginUpdating()
{
	for(new i = 1; i <= MAXPLAYERS; i++)
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
	
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Successful_Update", i);
	}
	
	if(GetConVarBool(g_Cvar_ReloadUpdate))
	{
		ReloadPlugin();
		PrintToServer("%s %T", CHAT_PREF, "Reload_Plugin", LANG_SERVER);
		for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "ua_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Reload_Plugin", i);
	}
	}
}

public Update(int client)
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
public OnMapStart()
{
	for(new i = 0; i < sizeof(g_iEffectChoice); i++)
	{
		g_iEffectChoice[i] = -1;
	}
}

//Once a client is in, we need to prepare them for our gamemode.
public OnClientPutInServer(client)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	g_iEffectChoice[client] = GetRandomInt(0, g_iEffectCount);
	while(eEffects[g_iEffectChoice[client]][bIsDonator] && !IsClientDonator(client))
		g_iEffectChoice[client] = GetRandomInt(0, g_iEffectCount);
}

//When a client disconnects, let's default all their variables back to normal.
public OnClientDisconnect_Post(client)
{
	g_iEffectChoice[client] = -1;
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
	int iPrevId = -1, iDonator = 0, iNormal = 0, iWarnings = 0;
	
	if(FileToKeyValues(hKv, sPath) && KvGotoFirstSubKey(hKv)){
	
		char sEffectId[4], sParticleBuffer[EFFECT_MAX];
		int iEffectId = 0;
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
		int iEffectId = 0;
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
	for(int i = 0; i < g_iEffectCount; i++)
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
		if(iEffectId < 0)
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
public OnAdminMenuReady(Handle:topmenu)
{
	if(topmenu == gH_AdminMenu)
	{
		return;
	}
	
	gH_AdminMenu = topmenu;
	
	new TopMenuObject:server_commands = FindTopMenuCategory(gH_AdminMenu, ADMINMENU_SERVERCOMMANDS);
	
	AddToTopMenu(gH_AdminMenu, "ua_update", TopMenuObject_Item, AdminMenu_Updater, server_commands, "ua_update", ADMFLAG_ROOT);
	AddToTopMenu(gH_AdminMenu, "ua_reload", TopMenuObject_Item, AdminMenu_Reload, server_commands, "ua_reload", ADMFLAG_ROOT);
}

public AdminMenu_Updater(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength)
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

public AdminMenu_Reload(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength)
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
public Action:Command_Update (int client, int args){

	if(!g_bUpdater || !GetConVarBool(g_Cvar_AutoUpdate)){
	
		CReplyToCommand(client, "%s %T", CHAT_PREF_COLOR, "No_Updater", client);
		return Plugin_Handled;
	}
	
	Update(client);
	
	return Plugin_Handled;
}

public Action:Command_Effects(client, args)
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

public Action:Command_Reload(int client, int args)
{
	ParseEffects();
	ParseCustomEffects();

	return Plugin_Handled;
}

/******************************************************************************************
 *                                    EFFECTS MENU                                        *
 ******************************************************************************************/
 
public DisplayGroups(client)
{
	new Handle:menu = CreateMenu(MenuHandler_EffectsSection);
	SetMenuTitle(menu, "%T", "Choose_Effect_Group", client);
	
	decl String:CEMenu[128];
	Format(CEMenu, sizeof(CEMenu), "%T", "Current_Effect", client, eEffects[g_iEffectChoice[client]][sName]);
	
	decl String:DMenu[32];
	Format(DMenu, sizeof(DMenu), "%T", "Donator_Effects", client);
	
	decl String:NMenu[32];
	Format(NMenu, sizeof(NMenu), "%T", "Normal_Effects", client);
	
	AddMenuItem(menu, "0", CEMenu, ITEMDRAW_DISABLED);
	
	if(IsClientDonator(client))
		AddMenuItem(menu, "1", DMenu);
		
	AddMenuItem(menu, "2", NMenu);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
} 

public MenuHandler_EffectsSection(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[8];
		GetMenuItem(menu, param2, info, 8);
		new choice = StringToInt(info);
		
		switch(choice)
		{
			case 1:
			{
				DisplayDonatorEffects(param1);
			}
			
			case 2:
			{
				DisplayEffects(param1);
			}
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public DisplayDonatorEffects(client)
{
	if(!GetConVarBool(g_Cvar_Enabled))
		return;
		
	if(!IsValidClient(client))
		return;
		
	new Handle:menu = CreateMenu(MenuHandler_Effects);
	SetMenuTitle(menu, "%T", "Choose_Effect", client);
	
	for(new i = 0; i < g_iEffectCount; i++)
	{
		new String:info[8];
		IntToString(i, info, sizeof(info));
		new String:name[EFFECT_MAX];
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

public DisplayEffects(client)
{
	if(!GetConVarBool(g_Cvar_Enabled))
		return;
		
	if(!IsValidClient(client))
		return;

	new Handle:menu = CreateMenu(MenuHandler_Effects);
	SetMenuTitle(menu, "%T", "Choose_Effect", client);
	
	for(new i = 0; i < g_iEffectCount; i++)
	{
		new String:info[8];
		IntToString(i, info, sizeof(info));
		new String:name[EFFECT_MAX];
		//name = eEffects[i][sName];
		strcopy(name, sizeof(name), eEffects[i][sName]);
		
		if(!eEffects[i][bIsDonator])
			AddMenuItem(menu, info, name);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Effects(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[8];
		GetMenuItem(menu, param2, info, 8);
		
		g_iEffectChoice[param1] = StringToInt(info);
		new String:name[64];
		Format(name, sizeof(name), "%s%s%s", "{violet}", eEffects[g_iEffectChoice[param1]][sName], "{cyan}");
		CPrintToChat(param1, "%s %T", CHAT_PREF_COLOR, "Chosen_Effect", param1, name);
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
public OnEntityCreated(entity, const String:classname[])
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

public Unusualify(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if(client < 1)
	{
		return; //Not valid client
	}

	if(IsClientAllowed(client))
		AddParticle(entity);
	
	//Unhook to prevent being called twice
	SDKUnhook(entity, SDKHook_Spawn, Unusualify);
}

AddParticle(entity)
{
	//new amount = GetConVarInt(v_HowHoly);
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new amount = 1;
	
	for(new i=1; i <= amount; i++)
	{
		CreateParticle(entity, eEffects[g_iEffectChoice[client]][sParticle], true);
	}
}

stock CreateParticle(iEntity, String:strParticle[], bool:bAttach = false, String:strAttachmentPoint[]="", Float:fOffset[3]={0.0, 0.0, 0.0})
{
    new iParticle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(iParticle))
    {
        decl Float:fPosition[3];
        decl Float:fAngles[3];
        decl Float:fForward[3];
        decl Float:fRight[3];
        decl Float:fUp[3];
        
        // Retrieve entity's position and angles
        //GetClientAbsOrigin(iClient, fPosition);
        //GetClientAbsAngles(iClient, fAngles);
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
        // Determine vectors and apply offset
        GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
        fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
        fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
        fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
		//SetEntProp
        
        // Teleport and attach to client
        //TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
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
 *                                         STOCKS                                         *
 ******************************************************************************************/

//Checks a client to see if it is valid.
stock bool:IsValidClient(client, bool:checkstv = true) {
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
	if(!IsClientConnected(client))
	{
		PrintToChat(client, "Client Is Connected");
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	new String:flags[16];
	GetConVarString(g_Cvar_RequiredFlag, flags, sizeof(flags));
	new ibFlags = ReadFlagString(flags);
	
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
	if(!IsClientConnected(client))
	{
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	new String:flags[16];
	GetConVarString(g_Cvar_DonatorFlag, flags, sizeof(flags));
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if(view_as<bool>(GetUserFlagBits(client) & ibFlags))
		{
			return true;
		}
	}
	
	return false;
}