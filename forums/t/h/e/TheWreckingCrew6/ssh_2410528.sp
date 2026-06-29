#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <ssh>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <updater>

#pragma semicolon 1

//Used to easily access my cvars out of an array.
#define PLUGIN_VERSION "1.2.3"
#define ENABLED 0
#define ANTIOVERLAP 1
#define AUTH 2
#define SQL 3
#define MAXDIS 4
#define REFRESHRATE 5
#define USEBAN 6
#define BURNTIME 7
#define SLAPDMG 8
#define USESLAY 9
#define USEBURN 10
#define USEPBAN 11
#define USEKICK 12
#define	USEFREEZE 13
#define USEBEACON 14
#define	USEFREEZEBOMB 15
#define	USEFIREBOMB 16
#define	USETIMEBOMB 17
#define USESPRAYBAN 18
#define	DRUGTIME 19
#define AUTOREMOVE 20
#define RESTRICT 21
#define IMMUNITY 22
#define GLOBAL 23
#define LOCATION 24
#define HUDTIME 25
#define CONFIRMACTIONS 26
#define NUMCVARS 27

#define FLAGS_CVARS	FCVAR_PLUGIN|FCVAR_NOTIFY

#define MAX_CONNECTIONS 5

#define UPDATE_URL    "http://tf2app.com/thewreckingcrew6/plugins/ssh/updater.txt"

//Creates my array of CVars
new Handle:g_arrCVars[NUMCVARS];

//Vital arrays that store all of our important information :D
new String:gS_arrSprayName[MAXPLAYERS + 1][64];
new String:gS_arrSprayID[MAXPLAYERS + 1][32];
new String:gS_arrMenuSprayID[MAXPLAYERS + 1][32];
new Float:gF_SprayVector[MAXPLAYERS+1][3];
new g_arrSprayTime[MAXPLAYERS + 1];
new String:gS_Auth[MAXPLAYERS+1][128];
new bool:gB_Spraybanned[MAXPLAYERS+1];

//Our Timer that will be initialized later
new Handle:g_hSprayTimer = INVALID_HANDLE;

//Global boolean that is defined later on if your server can use the HUD. (sm_ssh_location == 4)
new bool:g_bCanUseHUD;
new g_iHudLoc;

//The HUD that will be initialized later IF your server supports the HUD.
new Handle:gH_HUD = INVALID_HANDLE;

//Used later to decide what type of ban to place
new Handle:g_hExternalBan = INVALID_HANDLE;

new gI_Connections;

//Our main admin menu handle >.>
new Handle:gH_AdminMenu = INVALID_HANDLE;
TopMenuObject menu_category;

//Forwards
new Handle:gH_BanForward = INVALID_HANDLE;
new Handle:gH_UnbanForward = INVALID_HANDLE;

//Were we late loaded?
new bool:gB_Late;

//Used for the glow that is applied when tracing a spray
new g_PrecacheRedGlow;

//The plugin info :D
public Plugin:myinfo = 
{
	name = "Super Spray Handler",
	description = "Ultimate Tool for Admins to manage Sprays on their servers.",
	author = "shavit, Nican132, CptMoore, Lebson506th, and TheWreckingCrew6",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=163134"
}

//Used to create the natives for other plugins to hook into this beauty
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ssh_BanClient", Native_BanClient);
	CreateNative("ssh_UnbanClient", Native_UnbanClient);
	CreateNative("ssh_IsBanned", Native_IsBanned);
	
	RegPluginLibrary("ssh");
	
	gB_Late = late;
	
	return APLRes_Success;
}

//What we want to do when this beauty starts up.
public OnPluginStart()
{
	//We want these translations files :D
	LoadTranslations("ssh.phrases");
	LoadTranslations("common.phrases");

	//Base convar obviously
	CreateConVar("sm_spray_version", PLUGIN_VERSION, "Super Spray Handler plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	
	//Beautiful Commands
	RegAdminCmd("sm_spraytrace", Command_TraceSpray, ADMFLAG_BAN, "Look up the owner of the logo in front of you.");
	RegAdminCmd("sm_removespray", Command_RemoveSpray, ADMFLAG_BAN, "Remove the logo in front of you.");
	RegAdminCmd("sm_adminspray", Command_AdminSpray, ADMFLAG_BAN, "Sprays the named player's logo in front of you.");
	RegAdminCmd("sm_qremovespray", Command_QuickRemoveSpray, ADMFLAG_BAN, "Removes the logo in front of you without opening punishment menu.");
	RegAdminCmd("sm_removeallsprays", Command_RemoveAllSprays, ADMFLAG_BAN, "Removes all sprays from the map.");

	RegAdminCmd("sm_sprayban", Command_Sprayban, ADMFLAG_BAN, "Usage: sm_sprayban <target>");
	RegAdminCmd("sm_sban", Command_Sprayban, ADMFLAG_BAN, "Usage: sm_sban <target>");
	
	RegAdminCmd("sm_offlinesprayban", Command_OfflineSprayban, ADMFLAG_BAN, "Usage: sm_offlinesprayban <steamid> [name]");
	RegAdminCmd("sm_offlinesban", Command_OfflineSprayban, ADMFLAG_BAN, "Usage: sm_offlinesban <steamid> [name]");
	
	RegAdminCmd("sm_sprayunban", Command_Sprayunban, ADMFLAG_UNBAN, "Usage: sm_sprayunban <target>");
	RegAdminCmd("sm_sunban", Command_Sprayunban, ADMFLAG_UNBAN, "Usage: sm_sunban <target>");
	
	RegAdminCmd("sm_sbans", Command_Spraybans, ADMFLAG_GENERIC, "Shows a list of all connected spray banned players.");
	RegAdminCmd("sm_spraybans", Command_Spraybans, ADMFLAG_GENERIC, "Shows a list of all connected spray banned players.");
	
	CreateConVar("sm_ssh_version", PLUGIN_VERSION, "Super Spray Handler version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	//Spray Manager CVars
	g_arrCVars[ENABLED] = CreateConVar("sm_ssh_enabled", "1", "Enable \"Super Spray Handler\"?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_arrCVars[ANTIOVERLAP] = CreateConVar("sm_ssh_overlap", "0", "Prevent spray-on-spray overlapping?\nIf enabled, specify an amount of units that another player spray's distance from the new spray needs to be it or more, recommended value is 75.", FCVAR_PLUGIN, true, 0.0);
	g_arrCVars[AUTH] = CreateConVar("sm_ssh_auth", "1", "Which authentication identifiers should be seen in the HUD?\n- This is a \"math\" cvar, add the proper numbers for your likings. (Example: 1 + 4 = 5/Name + IP address)\n1 - Name\n2 - SteamID\n4 - IP address", FCVAR_PLUGIN, true, 1.0);
	
	//SSH CVars
	g_arrCVars[REFRESHRATE] = CreateConVar("sm_ssh_refresh","1.0","How often the program will trace to see player's spray to the HUD. 0 to disable.");
	g_arrCVars[MAXDIS] = CreateConVar("sm_ssh_dista","50.0","How far away the spray will be traced to.");
	g_arrCVars[USEBAN] = CreateConVar("sm_ssh_enableban","1","Whether or not banning is enabled. 0 to disable temporary banning.");
	g_arrCVars[BURNTIME] = CreateConVar("sm_ssh_burntime","10","How long the burn punishment is for.");
	g_arrCVars[SLAPDMG] = CreateConVar("sm_ssh_slapdamage","5","How much damage the slap punishment is for. 0 to disable.");
	g_arrCVars[USESLAY] = CreateConVar("sm_ssh_enableslay","0","Enables the use of Slay as a punishment.");
	g_arrCVars[USEBURN] = CreateConVar("sm_ssh_enableburn","0","Enables the use of Burn as a punishment.");
	g_arrCVars[USEPBAN] = CreateConVar("sm_ssh_enablepban","1","Enables the use of a Permanent Ban as a punishment.");
	g_arrCVars[USEKICK] = CreateConVar("sm_ssh_enablekick","1","Enables the use of Kick as a punishment.");
	g_arrCVars[USEBEACON] = CreateConVar("sm_ssh_enablebeacon","0","Enables putting a beacon on the sprayer as a punishment.");
	g_arrCVars[USEFREEZE] = CreateConVar("sm_ssh_enablefreeze","0","Enables the use of Freeze as a punishment.");
	g_arrCVars[USEFREEZEBOMB] = CreateConVar("sm_ssh_enablefreezebomb","0","Enables the use of Freeze Bomb as a punishment.");
	g_arrCVars[USEFIREBOMB] = CreateConVar("sm_ssh_enablefirebomb","0","Enables the use of Fire Bomb as a punishment.");
	g_arrCVars[USETIMEBOMB] = CreateConVar("sm_ssh_enabletimebomb","0","Enables the use of Time Bomb as a punishment.");
	g_arrCVars[USESPRAYBAN] = CreateConVar("sm_ssh_enablespraybaninmenu","1","Enables Spray Ban in the Punishment Menu.");
	g_arrCVars[DRUGTIME] = CreateConVar("sm_ssh_drugtime","0","set the time a sprayer is drugged as a punishment. 0 to disable.");
	g_arrCVars[AUTOREMOVE] = CreateConVar("sm_ssh_autoremove","0","Enables automatically removing sprays when a punishment is dealt.");
	g_arrCVars[RESTRICT] = CreateConVar("sm_ssh_restrict","1","Enables or disables restricting admins to punishments they are given access to. (1 = commands they have access to, 0 = all)");
	g_arrCVars[IMMUNITY] = CreateConVar("sm_ssh_useimmunity","1","Enables or disables using admin immunity to determine if one admin can punish another.");
	g_arrCVars[GLOBAL] = CreateConVar("sm_ssh_global","1","Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");
	g_arrCVars[LOCATION] = CreateConVar("sm_ssh_location","1","Where players will see the owner of the spray that they're aiming at? 0 - Disabled 1 - Hud hint 2 - Hint text (like sm_hsay) 3 - Center text (like sm_csay) 4 - HUD");
	g_arrCVars[HUDTIME] = CreateConVar("sm_ssh_hudtime","1.0","How long the HUD messages are displayed.");
	g_arrCVars[CONFIRMACTIONS] = CreateConVar("sm_ssh_confirmactions","1","Should you have to confirm spray banning and un-spraybanning?");
	
	HookConVarChange(g_arrCVars[REFRESHRATE], TimerChanged);
	HookConVarChange(g_arrCVars[LOCATION], LocationChanged);
	g_iHudLoc = GetConVarInt(g_arrCVars[LOCATION]);
	
	AutoExecConfig(true, "plugin.ssh");
	
	//Forwards
	gH_BanForward = CreateGlobalForward("ssh_OnBan", ET_Event, Param_Cell);
	gH_UnbanForward = CreateGlobalForward("ssh_OnUnban", ET_Event, Param_Cell);
	
	//Adds hook that looks for when a player sprays a decal.
	AddTempEntHook("Player Decal", Player_Decal);
	
	//Figures out what game you're running to then check for HUD support.
	new String:gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));
	
	//Checks for support of the HUD in current server, if not supported, changes sm_ssh_location to 1.
	g_bCanUseHUD = StrEqual(gamename,"tf",false) || StrEqual(gamename,"hl2mp",false) || StrEqual(gamename,"sourceforts",false) || StrEqual(gamename,"obsidian",false) || StrEqual(gamename,"left4dead",false) || StrEqual(gamename,"l4d",false);
	if (g_bCanUseHUD)
		gH_HUD = CreateHudSynchronizer();
	
	if(gH_HUD == INVALID_HANDLE && GetConVarInt(g_arrCVars[LOCATION]) == 4)
	{
		SetConVarInt(g_arrCVars[LOCATION], 1, true);
		
		LogError("[Super Spray Handler] This game can't use HUD messages, value of \"sm_ssh_location\" forced to 1.");
	}
	
	//Calls creating the admin menu, but checks to make sure server has admin menu plugin loaded.
	new Handle:topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
	
	SQL_Connector();
}

//When the map starts we want to create timers, cache our glow effect, and clear any info that may have decided to stick around.
public OnMapStart() {
	g_hSprayTimer = INVALID_HANDLE;
	CreateTimers();
	g_PrecacheRedGlow = PrecacheModel("sprites/redglow1.vmt");

	for (new i = 1; i <= MaxClients; i++)
		ClearVariables(i);
}

//If sm_ssh_global = 0 then we want to get rid of a players spray when they leave.
public OnClientDisconnect(client) {
	if (!GetConVarBool(g_arrCVars[GLOBAL]))
		ClearVariables(client);
}

//When a client joins we need to 1: default his spray to 0 0 0. 2: Check in the database if he is spray banned.
public OnClientPutInServer(client)
{
	gF_SprayVector[client] = Float:{0.0, 0.0, 0.0};
	CheckBan(client);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

//If you unload the admin menu, we don't want to keep using it :/
public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
	{
		gH_AdminMenu = INVALID_HANDLE;
	}
}


/******************************************************************************************
 *                           SPRAY TRACING TO THE HUD/HINT TEXT                           *
 ******************************************************************************************/

//Handles tracing sprays to the HUD or hint message
public Action:CheckAllTraces(Handle:hTimer) {
	if (GetClientCount(true) <= 0)
		return;
	static iSprayTarget[MAXPLAYERS + 1] = { -1, ... };
	static Float:flSprayTraceTime[MAXPLAYERS + 1][2];	//0 is last look time, 1 is last actual hud text time
	decl String:strMessage[64];
	new bUseHUD = (g_bCanUseHUD ? g_iHudLoc : 0);
	new Float:vecPos[3];
	new bool:bHudParamsSet = false;
	new Float:flGameTime = GetGameTime();
	//Pray for the processor - O(n^2) (but better now)
	for (new client = 1; client <= MaxClients; client++) {
		if (!IsValidClient(client) || IsFakeClient(client)) {
			iSprayTarget[client] = -1;
			continue;
		}
		
		//We don't want the message to show on our screen for years after we stopped looking at a spray. right?
		if(bUseHUD == 1)
			Client_PrintKeyHintText(client, "");
		else if(bUseHUD == 2)
			Client_PrintHintText(client, "");
		else if(bUseHUD == 3)
			PrintCenterText(client, "");
			
		//Make sure you're looking at a valid location.
		if (!GetClientEyeEndLocation(client, vecPos)) {
			if (flGameTime > flSprayTraceTime[client][0] + GetConVarFloat(g_arrCVars[HUDTIME]) - GetConVarFloat(g_arrCVars[REFRESHRATE])) {
				if (iSprayTarget[client] != -1) {	//wow, such repeated code
					if(gH_HUD != INVALID_HANDLE)
						ClearSyncHud(client, gH_HUD);
					else
					{
					if(bUseHUD == 1)
						Client_PrintKeyHintText(client, "");
					else if(bUseHUD == 2)
						Client_PrintHintText(client, "");
					else if(bUseHUD == 3)
						PrintCenterText(client, "");
					}
				}
				iSprayTarget[client] = -1;
			}
			continue;
		}
		
		//Do you REALLY have full access?
		new bool:bFullAccess = true;
		if (!CheckCommandAccess(client, "ssh_hud_access_full", ADMFLAG_GENERIC, true)) {
			bFullAccess = false;
			if (!CheckCommandAccess(client, "ssh_hud_access", 0, true)) {
				continue;
			}
		}
		
		//Let's check if you can trace admins
		new bool:bTraceAdmins = CheckCommandAccess(client, "ssh_hud_can_trace_admins", 0, true);
		new target = -1;
		for (new a = 1; a <= MaxClients; a++) {
			if (GetVectorDistance(vecPos, gF_SprayVector[a]) > GetConVarFloat(g_arrCVars[MAXDIS])) {
				continue;
			}
			target = a;
			break;
		}
		//Lets just figure out what target we're looking at?
		if (!IsValidClient(target)) {
			target = -1;
			if (flGameTime > flSprayTraceTime[client][0] + GetConVarFloat(g_arrCVars[HUDTIME]) - GetConVarFloat(g_arrCVars[REFRESHRATE])) {
				if (iSprayTarget[client] != -1) {	//wow, such repeated code
					if(gH_HUD != INVALID_HANDLE)
						ClearSyncHud(client, gH_HUD);
					else
					{
					if(bUseHUD == 1)
						Client_PrintKeyHintText(client, "");
					else if(bUseHUD == 2)
						Client_PrintHintText(client, "");
					else if(bUseHUD == 3)
						PrintCenterText(client, "");
					}
				}
				iSprayTarget[client] = -1;
			}
			continue;
		}
		
		//Check if you're an admin.
		new bool:bTargetIsAdmin = CheckCommandAccess(target, "ssh_hud_is_admin", ADMFLAG_GENERIC, true);
		if (!bTraceAdmins && bTargetIsAdmin) {
			target = -1;
			if (flGameTime > flSprayTraceTime[client][0] + GetConVarFloat(g_arrCVars[HUDTIME]) - GetConVarFloat(g_arrCVars[REFRESHRATE])) {
				if (iSprayTarget[client] != -1) {	//wow, such repeated code
					if(gH_HUD != INVALID_HANDLE)
						ClearSyncHud(client, gH_HUD);
					else
					{
					if(bUseHUD == 1)
						Client_PrintKeyHintText(client, "");
					else if(bUseHUD == 2)
						Client_PrintHintText(client, "");
					else if(bUseHUD == 3)
						PrintCenterText(client, "");
					}
				}
				iSprayTarget[client] = -1;
			}
			continue;
		}
		
		if (CheckForZero(gF_SprayVector[target])) {
			target = -1;
			if (flGameTime > flSprayTraceTime[client][0] + GetConVarFloat(g_arrCVars[HUDTIME]) - GetConVarFloat(g_arrCVars[REFRESHRATE])) {
				if (iSprayTarget[client] != -1) {	//wow, such repeated code
					if(gH_HUD != INVALID_HANDLE)
						ClearSyncHud(client, gH_HUD);
					else
					{
					if(bUseHUD == 1)
						Client_PrintKeyHintText(client, "");
					else if(bUseHUD == 2)
						Client_PrintHintText(client, "");
					else if(bUseHUD == 3)
						PrintCenterText(client, "");
					}
				}
				iSprayTarget[client] = -1;
			}
			continue;
		}
		
		//Generate the text that is to be shown on your screen.
		if (bFullAccess)
			FormatEx(strMessage, 128, "Sprayed by:\n%s", gS_Auth[target]);
		else
			FormatEx(strMessage, 128, "Sprayed by:\n%s", gS_arrSprayName[target]);
		
		switch(bUseHUD)
		{
			case 1: Client_PrintKeyHintText(client, strMessage);
			case 2: Client_PrintHintText(client, strMessage); //This is annoying af. Need to find a way to fix it.
			case 3: PrintCenterText(client, strMessage);
						
			case 4:
			{
				if (!bHudParamsSet) {
					bHudParamsSet = true;
					//15s sounds reasonable
					SetHudTextParams(0.04, 0.6, 15.0, 255, 12, 39, 240 + (RoundToFloor(flGameTime) % 2), _, 0.2);	//the color tends to get weird if you don't set it different each tick
				}
				if (flGameTime > flSprayTraceTime[client][1] + 14.5 || target != iSprayTarget[client]) {
					ShowSyncHudText(client, gH_HUD, strMessage);
					iSprayTarget[client] = target;
					flSprayTraceTime[client][1] = flGameTime;
				}
				flSprayTraceTime[client][0] = flGameTime;
			}
						
			default: continue;
		}
	}
}


/******************************************************************************************
 *                           ADMIN MENU METHODS FOR CUSTOM MENU                           *
 ******************************************************************************************/

 //Our custom category needs to know what to do right?
public CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayTitle)
	{
		FormatEx(buffer, maxlength, "Spray Commands: ");
	}
	
	else if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Commands");
	}
}

//When the admin menu is ready, lets define our topmenu object, and add our commands to it.
public OnAdminMenuReady(Handle:topmenu)
{
	if(menu_category == INVALID_TOPMENUOBJECT)
	{
		OnAdminMenuCreated(topmenu);
	}

	if(topmenu == gH_AdminMenu)
	{
		return;
	}
	
	gH_AdminMenu = topmenu;
	
	AddToTopMenu(gH_AdminMenu, "sm_spraybans", TopMenuObject_Item, AdminMenu_SprayBans, menu_category, "sm_spraybans", ADMFLAG_BAN);
	AddToTopMenu(gH_AdminMenu, "sm_spraytrace", TopMenuObject_Item, AdminMenu_TraceSpray, menu_category, "sm_spraytrace", ADMFLAG_BAN);
	AddToTopMenu(gH_AdminMenu, "sm_removespray", TopMenuObject_Item, AdminMenu_SprayRemove, menu_category, "sm_removespray", ADMFLAG_BAN);
	AddToTopMenu(gH_AdminMenu, "sm_adminspray", TopMenuObject_Item, AdminMenu_AdminSpray, menu_category, "sm_adminspray", ADMFLAG_BAN);
	AddToTopMenu(gH_AdminMenu, "sm_sprayban", TopMenuObject_Item, AdminMenu_SprayBan, menu_category, "sm_sprayban", ADMFLAG_BAN);
	AddToTopMenu(gH_AdminMenu, "sm_sprayunban", TopMenuObject_Item, AdminMenu_SprayUnban, menu_category, "sm_sprayunban", ADMFLAG_UNBAN);
	AddToTopMenu(gH_AdminMenu, "sm_qremovespray", TopMenuObject_Item, AdminMenu_QuickSprayRemove, menu_category, "sm_qremovespray", ADMFLAG_BAN);
	AddToTopMenu(gH_AdminMenu, "sm_removeallsprays", TopMenuObject_Item, AdminMenu_RemoveAllSprays, menu_category, "sm_removeallsprays", ADMFLAG_BAN);
}

//When we have our admin menu created, lets make our custom category.
public void OnAdminMenuCreated(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == gH_AdminMenu && menu_category != INVALID_TOPMENUOBJECT)
	{
		return;
	}
 
	menu_category = AddToTopMenu(topmenu,
		"Spray Commands",
		TopMenuObject_Category,
		CategoryHandler,
		INVALID_TOPMENUOBJECT);
}

/******************************************************************************************
 *                               SQL METHODS FOR SPRAY BANS                               *
 ******************************************************************************************/

 //Connects us to the database and reads the databases.cfg
void SQL_Connector()
{
	if(g_arrCVars[SQL] != INVALID_HANDLE)
	{
		CloseHandle(g_arrCVars[SQL]);
	}
	
	g_arrCVars[SQL] = INVALID_HANDLE;
	
	if(SQL_CheckConfig("ssh"))
	{
		SQL_TConnect(SQL_ConnectorCallback, "ssh");
	}
	
	else
	{
		SetFailState("PLUGIN STOPPED - Reason: No config entry found for 'ssh' in databases.cfg - PLUGIN STOPPED");
	}
}

//What actually is called to establish a connection to the database.
public SQL_ConnectorCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Connection to SQL database has failed, reason: %s", error);
		
		gI_Connections++;
		
		SQL_Connector();
		
		if(gI_Connections > MAX_CONNECTIONS)
		{
			SetFailState("Connection to SQL database has failed too many times (%d), plugin unloaded to prevent spam.", MAX_CONNECTIONS);
		}
		
		return;
	}
	
	new String:driver[16];
	SQL_GetDriverIdent(owner, driver, 16);
	
	g_arrCVars[SQL] = CloneHandle(hndl);
	
	if(StrEqual(driver, "mysql", false))
	{
		SQL_LockDatabase(g_arrCVars[SQL]);
		SQL_FastQuery(g_arrCVars[SQL], "SET NAMES \"UTF8\""); 
		SQL_UnlockDatabase(g_arrCVars[SQL]);
		
		SQL_TQuery(g_arrCVars[SQL], SQL_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `ssh` (`auth` VARCHAR(32) NOT NULL, `name` VARCHAR(32) DEFAULT '<unknown>', PRIMARY KEY (`auth`)) ENGINE = InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;");
	}
	
	else if(StrEqual(driver, "sqlite", false))
	{
		SQL_TQuery(g_arrCVars[SQL], SQL_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `ssh` (`auth` VARCHAR(32) NOT NULL, `name` VARCHAR(32) DEFAULT '<unknown>', PRIMARY KEY (`auth`));");
	}
	
	CloseHandle(hndl);
}

//More SQL Stuff
public SQL_CreateTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(owner == INVALID_HANDLE)
	{
		LogError(error);
		
		SQL_Connector();
		
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on SQL_ConnectorCallback: %s", error);
		
		return;
	}
	
	if(gB_Late)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				OnClientPutInServer(i);
				CheckBan(i);
			}
		}
	}
}

//What is called to check in the database if a player is spray banned.
void CheckBan(client)
{
	if(IsValidClient(client))
	{
		new bool:fetched;
			
		new String:auth[32];
		GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			
		decl String:sQuery[256];
		FormatEx(sQuery, 256, "SELECT * FROM ssh WHERE auth = '%s'", auth);
			
		SQL_LockDatabase(g_arrCVars[SQL]);
		new Handle:hQuery = SQL_Query(g_arrCVars[SQL], sQuery);
			
		while(SQL_FetchRow(hQuery))
		{
			fetched = true;
		}
			
		SQL_UnlockDatabase(g_arrCVars[SQL]);
		CloseHandle(hQuery);
			
		gB_Spraybanned[client] = fetched;
	}
}

/******************************************************************************************
 *                           OUR HOOKS :D TO ACTUALLY DO STUFF                            *
 ******************************************************************************************/

 //When a player trys to spray a decal.
public Action:Player_Decal(const String:name[], const clients[], count, Float:delay)
{
	//Is this plugin enabled? If not then no need to run the rest of this.
	if(!GetConVarBool(g_arrCVars[ENABLED]))
	{
		return Plugin_Continue;
	}
	
	//Gets the client that is spraying.
	new client = TE_ReadNum("m_nPlayer");
	
	//Is this even a valid client?
	if(IsValidClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client))
	{
		//We need to check if this player is spray banned, and if so, we will pre hook this spray attempt and block it.
		if(gB_Spraybanned[client])
		{
			PrintToChat(client, "\x04[Super Spray Handler]\x01 You are Spray Banned and thus unable to Spray.");
			return Plugin_Handled;
		}
		
		//If we're here, they are obviously not spray banned. So lets find where they are spraying.
		new Float:fSprayVector[3];
		TE_ReadVector("m_vecOrigin", fSprayVector);
		
		//Now we need to check if this spray is too close to another spray if sm_ssh_overlap > 0
		if(GetConVarFloat(g_arrCVars[ANTIOVERLAP]) > 0)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && i != client)
				{
					if(!CheckForZero(gF_SprayVector[i]))
					{
						if(GetVectorDistance(fSprayVector, gF_SprayVector[i]) <= GetConVarFloat(g_arrCVars[ANTIOVERLAP]))
						{
							PrintToChat(client, "\x04[Super Spray Handler]\x01 Your spray is too close to \x05%N\x01's spray.", i);
							
							return Plugin_Handled;
						}
					}
				}
			}
		}
		
		//Either anti-overlapping isn't enabled or the spray was sprayed in an ok location
		//Now Let's store the Sprays Location, Time of Spray, Who Sprayed it, and the ID of the player.
		gF_SprayVector[client] = fSprayVector;
		g_arrSprayTime[client] = RoundFloat(GetGameTime());
		GetClientName(client, gS_arrSprayName[client], 64);
		GetClientAuthId(client, AuthId_Steam2, gS_arrSprayID[client], 32, true);
		
		//This is where we generate what is displayed when tracing a spray to HUD/Hint
		strcopy(gS_Auth[client], 128, "");
		
		//If our math variable includes a 1 in it, we will add the player's name into the string.
		if(GetConVarInt(g_arrCVars[AUTH]) & 1)
		{
			Format(gS_Auth[client], 128, "%s%N", gS_Auth[client], client);
		}
		
		//If our math variable includes a 2 in it, we will add the player's STEAM_ID into the string.
		if(GetConVarInt(g_arrCVars[AUTH]) & 2)
		{
			new String:auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			
			Format(gS_Auth[client], 128, "%s%s(%s)", gS_Auth[client], GetConVarInt(g_arrCVars[AUTH]) & 1? "\n":"", auth);
		}
		
		//And lastly, if our math variable includes a 4 in it, we simply add the IP into the string.
		if(GetConVarInt(g_arrCVars[AUTH]) & 4)
		{
			new String:IP[32];
			GetClientIP(client, IP, 32);
			
			Format(gS_Auth[client], 128, "%s%s(%s)", gS_Auth[client], GetConVarInt(g_arrCVars[AUTH]) & (1|2)? "\n":"", IP);
		}
	}
	//Now we're done here.
	return Plugin_Continue;
}

//When the Location cvar changes, this is called
public LocationChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[]) {
	g_iHudLoc = GetConVarInt(hConVar);
	SetConVarInt(g_arrCVars[LOCATION], StringToInt(szNewValue), true, false);
}

/******************************************************************************************
 *                                   SPRAY BANNING >.>                                    *
 ******************************************************************************************/

 //What decides what happens when you select the Spray Ban option in the admin menu
public AdminMenu_SprayBan(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Ban");
	}
	
	else if(action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(MenuHandler_SprayBan);
		SetMenuTitle(menu, "Spray Ban:");
		
		new count;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(!gB_Spraybanned[i])
				{
					if(!IsClientReplay(i) && !IsClientSourceTV(i))
					{
						new String:info[8];
						new String:name[MAX_NAME_LENGTH];
						
						IntToString(GetClientUserId(i), info, 8);
						GetClientName(i, name, MAX_NAME_LENGTH);
						
						AddMenuItem(menu, info, name);
						
						count++;
					}
				}
			}
		}
		
		if(!count)
		{
			AddMenuItem(menu, "none", "No matching players found");
		}
		
		SetMenuExitBackButton(menu, true);
		
		DisplayMenu(menu, param, 20);
	}
}

//What happens when you use the spray ban menu?
public MenuHandler_SprayBan(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[8];
		GetMenuItem(menu, param2, info, 8);
		
		FakeClientCommand(param1, "sm_sprayban #%d", StringToInt(info));
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			RedisplayAdminMenu(gH_AdminMenu, param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

//What is called when you run !sm_sprayban
public Action:Command_Sprayban(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!GetConVarBool(g_arrCVars[ENABLED]))
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	if(!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sprayban <target>");
		
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	new target = FindTarget(client, arg1);
	
	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	if(gB_Spraybanned[target])
	{
		ReplyToCommand(client, "[SM] Unable to spray ban %N, reason - already spray banned.", target);
		
		return Plugin_Handled;
	}
	
	if(GetConVarBool(g_arrCVars[CONFIRMACTIONS]))
		DisplayConfirmMenu(client, target, 0);
	else
		RunSprayBan(client, target);
	
	return Plugin_Handled;
}

//What actually places the spray ban.
public RunSprayBan(client, target)
{
	ReplyToCommand(client, "[SM] Successfully spray banned %N.", target);
	PrintToChat(target, "\x04[Super Spray Handler]\x01 You've been spray banned.");
	
	new String:auth[32];
	GetClientAuthId(target, AuthId_Steam2, auth, 32, true);
	
	decl String:targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, MAX_NAME_LENGTH);
	
	decl String:targetSafeName[2 * strlen(targetName) + 1];
	SQL_LockDatabase(g_arrCVars[SQL]);
	SQL_EscapeString(g_arrCVars[SQL], targetName, targetSafeName, 2 * strlen(targetName) + 1);
	SQL_UnlockDatabase(g_arrCVars[SQL]);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "INSERT INTO ssh (auth, name) VALUES ('%s', '%s');", auth,  targetSafeName);
	
	SQL_LockDatabase(g_arrCVars[SQL]);
	SQL_FastQuery(g_arrCVars[SQL], sQuery);
	SQL_UnlockDatabase(g_arrCVars[SQL]);
	
	LogAction(client, target, "Spray banned.");
	ShowActivity(client, "Spray banned %N", target);
	
	gF_SprayVector[target] = Float:{0.0, 0.0, 0.0};
	
	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", Float:{0.0, 0.0, 0.0});
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nPlayer", target);
	TE_SendToAll();
	
	gB_Spraybanned[target] = true;
	
	Call_StartForward(gH_BanForward);
	Call_PushCell(target);
	Call_Finish();
}

/******************************************************************************************
 *                                 SPRAY UN-BANNING >.>                                   *
 ******************************************************************************************/

//What handles when you select to Un-Spray ban someone
public AdminMenu_SprayUnban(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Unban");
	}
	
	else if(action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(MenuHandler_SprayUnban);
		SetMenuTitle(menu, "Spray Unban:");
		
		new count;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(gB_Spraybanned[i])
				{
					new String:info[8];
					new String:name[MAX_NAME_LENGTH];
					
					IntToString(GetClientUserId(i), info, 8);
					GetClientName(i, name, MAX_NAME_LENGTH);
					
					AddMenuItem(menu, info, name);
					
					count++;
				}
			}
		}
		
		if(!count)
		{
			AddMenuItem(menu, "none", "No matching players found");
		}
		
		SetMenuExitBackButton(menu, true);
		
		DisplayMenu(menu, param, 20);
	}
}

//What handles your selection on who to unspray ban.
public MenuHandler_SprayUnban(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[8];
		GetMenuItem(menu, param2, info, 8);
		
		FakeClientCommand(param1, "sm_sprayunban #%d", StringToInt(info));
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			RedisplayAdminMenu(gH_AdminMenu, param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

//What is called when you run !sm_sprayunban
public Action:Command_Sprayunban(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!GetConVarBool(g_arrCVars[ENABLED]))
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	if(!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sprayunban <target>");
		
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	new target = FindTarget(client, arg1);
	
	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	if(!gB_Spraybanned[target])
	{
		ReplyToCommand(client, "[SM] Unable to spray unban %N, reason - not spray banned.", target);
		
		return Plugin_Handled;
	}
	
	if(GetConVarBool(g_arrCVars[CONFIRMACTIONS]))
		DisplayConfirmMenu(client, target, 1);
	else
		RunUnSprayBan(client, target);
	
	return Plugin_Handled;
}

//What actually handles un-spraybanning a player.
public RunUnSprayBan(client, target)
{
	ReplyToCommand(client, "[SM] Successfully spray unbanned %N.", target);
	PrintToChat(target, "\x04[Super Spray Handler]\x01 You've been spray unbanned.");
	
	gB_Spraybanned[target] = false;
	
	new String:auth[32];
	GetClientAuthId(target, AuthId_Steam2, auth, 32, true);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "DELETE FROM ssh WHERE auth = '%s';", auth);
	
	SQL_LockDatabase(g_arrCVars[SQL]);
	SQL_FastQuery(g_arrCVars[SQL], sQuery);
	SQL_UnlockDatabase(g_arrCVars[SQL]);
	
	LogAction(client, target, "Spray unbanned.");
	ShowActivity(client, "Spray unbanned %N", target);
	
	Call_StartForward(gH_UnbanForward);
	Call_PushCell(target);
	Call_Finish();
}

/******************************************************************************************
 *                              LISTING OUR SPRAYBANNED PLAYERS                           *
 ******************************************************************************************/

 //What is called to display the Options Menu
 public DisplayListOptionsMenu(client)
 {
	new Handle:menu = CreateMenu(MenuHandler_ListOptions);
	SetMenuTitle(menu, "What Spray-Banned Clients to you wish to list?");
	
	AddMenuItem(menu, "1", "Currently Connected Spray-Banned Clients");
	AddMenuItem(menu, "2", "All Spray-Banned clients");
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 20);
 }
 
 //Menu Handler for the Options Menu
 public MenuHandler_ListOptions(Handle:menu, MenuAction:action, param1, param2)
 {
	if(action == MenuAction_Select)
	{
		new String:choice[32];
		GetMenuItem(menu, param2, choice, sizeof(choice));
		new decision = StringToInt(choice);
		
		if(decision == 1)
			DisplaySprayBans(param1);
		else if(decision == 2)
			SQL_TQuery(g_arrCVars[SQL], AllSprayBansCallback, "SELECT * FROM ssh", GetClientSerial(param1));
		else
			PrintToChat(param1, "[SSH] Somehow you fucked up.");
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
 }
 
//What happens when you select to list currently connected spray banned players?
public AdminMenu_SprayBans(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Ban List");
	}
	
	else if(action == TopMenuAction_SelectOption)
	{
		DisplayListOptionsMenu(param);
	}
}

//What happens when you run !sm_spraybans?
public Action:Command_Spraybans(client, args)
{	
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!GetConVarBool(g_arrCVars[ENABLED]))
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	DisplayListOptionsMenu(client);
	
	return Plugin_Handled;
}

//Display the currently connected spray banned players.
public DisplaySprayBans(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SprayBans);
	SetMenuTitle(menu, "----------------------------------------------\nSpray Banned Players: (Select a client to un-sprayban)\n----------------------------------------------\n(Select a client to un-sprayban)");
	
	new count;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(gB_Spraybanned[i])
			{
				decl String:auth[MAX_STEAMAUTH_LENGTH];
				GetClientAuthId(i, AuthId_Steam2, auth, sizeof(auth), true);
				
				decl String:name[MAX_NAME_LENGTH];
				GetClientName(i, name, sizeof(name));
				
				decl String:Display[128];
				FormatEx(Display, 128, "%s - %s", name, auth);
		
				decl String:info[64];
				IntToString(i, info, sizeof(info));
				
				AddMenuItem(menu, info, Display);
				
				count++;
			}
		}
	}
	
	if(!count)
	{
		AddMenuItem(menu, "none", "No spray banned players are connected.");
	}
	
	SetMenuExitButton(menu, true);
	
	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 20);
}

//Menu HAndler for the spray bans menu
public MenuHandler_SprayBans(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select && CheckCommandAccess(param1, "sm_sprayunban", ADMFLAG_UNBAN, false))
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, 32);
		new target = StringToInt(info);
		new String:name[128];
		GetClientName(target, name, sizeof(name));
		new String:auth[MAX_STEAMAUTH_LENGTH];
		GetClientAuthId(target, AuthId_Steam2, auth, sizeof(auth), true);
		
		if(!StrEqual(info, "none"))
		{	
			new Handle:menu2 = CreateMenu(MenuHandler_Spraybans_Ban);
			SetMenuTitle(menu2, "Are you sure you want to spray un-ban %s (%s)?", name, auth);
			
			AddMenuItem(menu2, info, "Yes");
			AddMenuItem(menu2, "none", "No");
			
			SetMenuExitBackButton(menu2, true);
			
			DisplayMenu(menu2, param1, 20);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayListOptionsMenu(param1);
		}
	}
	
	return 0;
}

//Menu HAndler for the un-banning part of the list.
public MenuHandler_Spraybans_Ban(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, 32);
		
		new target = StringToInt(info);
		
		if(!StrEqual(info, "none"))
		{
			RunUnSprayBan(param1, target);
		}
		
		else
			DisplaySprayBans(param1);
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			Command_Spraybans(param1, -1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

//What is called to list all the spray bans there are in yoru database
public AllSprayBansCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL error in Listing All Spray Bans: %s", error);
		
		return;
	}
	
	new client = GetClientFromSerial(data);
	
	if(!IsValidClient(client))
	{
		CloseHandle(hndl);
		
		return;
	}
	
	new Handle:menu = CreateMenu(MenuHandler_AllSpraybans);
	SetMenuTitle(menu, "----------------------------------------------\nSpray Banned Players: (Select a client to un-sprayban)\n----------------------------------------------\n(Select a client to un-sprayban)");
	
	while(SQL_FetchRow(hndl))
	{
		decl String:auth[MAX_STEAMAUTH_LENGTH];
		SQL_FetchString(hndl, 0, auth, MAX_STEAMAUTH_LENGTH);
		
		decl String:auth2[MAX_STEAMAUTH_LENGTH];
		FormatEx(auth2, MAX_STEAMAUTH_LENGTH, auth);
		ReplaceString(auth2, MAX_STEAMAUTH_LENGTH, "STEAM_", "", false);
		
		decl String:name[MAX_NAME_LENGTH];
		SQL_FetchString(hndl, 1, name, MAX_NAME_LENGTH);
		ReplaceString(name, MAX_NAME_LENGTH, ";", "", false);
		
		decl String:Display[128];
		FormatEx(Display, 128, "%s - %s", name, auth);
		
		decl String:info[64];
		FormatEx(info, 64, "%s;%s", name, auth);
		
		// debug
		//PrintToChat(client, "%s", info);
		
		AddMenuItem(menu, info, Display);
	}
	
	if(!GetMenuItemCount(menu))
	{
		AddMenuItem(menu, "none", "There are no spray banned players.");
	}
	
	SetMenuExitButton(menu, true);
	
	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 20);
	
	CloseHandle(hndl);
}

//Menu Handler for the full list of spray banned players
public MenuHandler_AllSpraybans(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select && CheckCommandAccess(param1, "sm_sprayunban", ADMFLAG_UNBAN, false))
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, 64);
		//PrintToChat(param1, "%s", info);
		
		if(!StrEqual(info, "none"))
		{
			decl String:tokens[64][64];
			ExplodeString(info, ";", tokens, sizeof(tokens), sizeof(tokens[]));  
			
			//PrintToChat(param1, "%i", sizeof(tokens));
			//PrintToChat(param1, "%s", tokens[1]);
			
			new Handle:menu2 = CreateMenu(MenuHandler_AllSpraybans_Ban);
			SetMenuTitle(menu2, "Are you sure you want to spray un-ban %s (%s)?", tokens[0], tokens[1]);
			
			AddMenuItem(menu2, tokens[1], "Yes");
			AddMenuItem(menu2, "none", "No");
			
			SetMenuExitBackButton(menu2, true);
			
			DisplayMenu(menu2, param1, 20);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayListOptionsMenu(param1);
		}
	}
	
	return 0;
}

//Unbanning handler for the all spray bans menu
public MenuHandler_AllSpraybans_Ban(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, 32);
		
		if(!StrEqual(info, "none"))
		{
			decl String:sQuery[128];
			FormatEx(sQuery, 128, "DELETE FROM ssh WHERE auth = '%s'", info);
			
			new Handle:pack = CreateDataPack();
			WritePackCell(pack, GetClientSerial(param1));
			WritePackString(pack, info);
			
			SQL_TQuery(g_arrCVars[SQL], Offlinebans_UnbanCallback, sQuery, pack);
		}
		
		else
			SQL_TQuery(g_arrCVars[SQL], AllSprayBansCallback, "SELECT * FROM ssh", GetClientSerial(param1));
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			SQL_TQuery(g_arrCVars[SQL], AllSprayBansCallback, "SELECT * FROM ssh", GetClientSerial(param1));
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

/******************************************************************************************
 *                               OFFLINE SPRAY BANNING                                    *
 ******************************************************************************************/

//Its like spray-banning, but offline...Allows you to target offline clients.
public Action:Command_OfflineSprayban(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!GetConVarBool(g_arrCVars[ENABLED]))
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	if(!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_offlinesprayban <\"steamid\"> [name]");
		
		return Plugin_Handled;
	}
	
	new String:auth[MAX_STEAMAUTH_LENGTH];
	new String:authp1[MAX_STEAMAUTH_LENGTH];
	GetCmdArg(1, authp1, MAX_STEAMAUTH_LENGTH);
	new String:authp2[MAX_STEAMAUTH_LENGTH];
	GetCmdArg(2, authp2, MAX_STEAMAUTH_LENGTH);
	new String:authp3[MAX_STEAMAUTH_LENGTH];
	GetCmdArg(3, authp3, MAX_STEAMAUTH_LENGTH);
	new String:authp4[MAX_STEAMAUTH_LENGTH];
	GetCmdArg(4, authp4, MAX_STEAMAUTH_LENGTH);
	new String:authp5[MAX_STEAMAUTH_LENGTH];
	GetCmdArg(5, authp5, MAX_STEAMAUTH_LENGTH);
	Format(auth, MAX_STEAMAUTH_LENGTH, "%s%s%s%s%s", authp1, authp2, authp3, authp4, authp5);
	
	if(args == 1 && !StrEqual(auth, "STEAM_"))
	{
		ReplyToCommand(client, "[SM] Invalid SteamID. Valid SteamIDs are formmated in this way - STEAM_A:B:XXXXXXX.");
		
		return Plugin_Handled;
	}
	
	new String:targetName[MAX_NAME_LENGTH];
	FormatEx(targetName, MAX_NAME_LENGTH, "<unknown>");
	
	if(args >= 6)
	{
		GetCmdArg(6, targetName, MAX_NAME_LENGTH);
	}
	
	decl String:targetSafeName[2 * strlen(targetName) + 1];
	SQL_LockDatabase(g_arrCVars[SQL]);
	SQL_EscapeString(g_arrCVars[SQL], targetName, targetSafeName, 2 * strlen(targetName) + 1);
	SQL_UnlockDatabase(g_arrCVars[SQL]);
	
	decl String:Driver[64];
	SQL_ReadDriver(g_arrCVars[SQL], Driver, sizeof(Driver));
	//PrintToChat(client, "%s", Driver);
	
	decl String:sQuery[256];
	if(StrEqual(Driver, "mysql"))
		FormatEx(sQuery, 256, "INSERT INTO ssh (auth, name) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE name = '%s';", auth,  targetSafeName, targetSafeName);
	else
		FormatEx(sQuery, 256, "INSERT OR REPLACE INTO ssh (auth, name) VALUES ('%s', COALESCE((SELECT name FROM ssh WHERE auth = '%s'), '%s'))", auth, auth, targetSafeName);
	//PrintToChat(client, "%s", sQuery);
	
	SQL_LockDatabase(g_arrCVars[SQL]);
	SQL_FastQuery(g_arrCVars[SQL], sQuery);
	SQL_UnlockDatabase(g_arrCVars[SQL]);
	
	ShowActivity(client, "Spray banned %s. (%s)", targetSafeName, auth);
	
	new target = -1;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			new String:sAuth[32];
			GetClientAuthId(i, AuthId_Steam2, sAuth, 32, true);
			
			if(StrEqual(sAuth, auth))
			{
				target = i;
				
				break;
			}
		}
	}
	
	if(target != -1)
	{
		gF_SprayVector[target] = Float:{0.0, 0.0, 0.0};
		
		TE_Start("Player Decal");
		TE_WriteVector("m_vecOrigin", Float:{0.0, 0.0, 0.0});
		TE_WriteNum("m_nEntity", 0);
		TE_WriteNum("m_nPlayer", target);
		TE_SendToAll();
		
		gB_Spraybanned[target] = true;
		
		Call_StartForward(gH_BanForward);
		Call_PushCell(target);
		Call_Finish();
		
		LogAction(client, target, "Spray banned.");
		
		PrintToChat(target, "\x04[Super Spray Handler]\x01 You've been spray banned.");
	}
	
	return Plugin_Handled;
}

/******************************************************************************************
 *                              OFFLINE UN-SPRAY BANNING                                  *
 ******************************************************************************************/

 //Its like spray-unbanning, but offline...Allows you to target offline clients.
public Offlinebans_UnbanCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL error in MenuHandler_AllSpraybans_Ban: %s", error);
		
		return;
	}
	
	ResetPack(data);
	
	new client = GetClientFromSerial(ReadPackCell(data));
	
	new String:auth[MAX_STEAMAUTH_LENGTH];
	ReadPackString(data, auth, MAX_STEAMAUTH_LENGTH);
	
	CloseHandle(data);
	
	if(!IsValidClient(client))
	{
		CloseHandle(hndl);
		
		return;
	}
	
	LogToFile("addons/sourcemod/logs/ssh.log", "%L: Spray unbanned %s.", client, auth);
	
	new target = -1;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			new String:sAuth[32];
			GetClientAuthId(i, AuthId_Steam2, sAuth, 32, true);
			
			if(StrEqual(sAuth, auth))
			{
				target = i;
				
				break;
			}
		}
	}
	
	if(target != -1)
	{
		gB_Spraybanned[target] = false;
		
		Call_StartForward(gH_UnbanForward);
		Call_PushCell(target);
		Call_Finish();
		
		PrintToChat(target, "\x04[Super Spray Handler]\x01 You've been spray unbanned.");
	}
	
	CloseHandle(hndl);
}

/******************************************************************************************
 *                                         NATIVES                                        *
 ******************************************************************************************/

 //Native to spray-ban a client.
public Native_BanClient(Handle:handler, numParams)
{
	new client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		ThrowError("Player index %d is invalid.", client);
	}
	
	if(gB_Spraybanned[client])
	{
		ThrowError("Player index %d is already spray banned.", client);
	}
	
	new String:auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "INSERT INTO ssh (auth, name) VALUES ('%s', '%N');", auth,  client);
	
	SQL_LockDatabase(g_arrCVars[SQL]);
	SQL_FastQuery(g_arrCVars[SQL], sQuery);
	SQL_UnlockDatabase(g_arrCVars[SQL]);
	
	if(bool:GetNativeCell(2))
	{
		TE_Start("Player Decal");
		TE_WriteVector("m_vecOrigin", Float:{0.0, 0.0, 0.0});
		TE_WriteNum("m_nEntity", 0);
		TE_WriteNum("m_nPlayer", client);
		TE_SendToAll();
		
		gF_SprayVector[client] = Float:{0.0, 0.0, 0.0};
	}
	
	gB_Spraybanned[client] = true;
	
	PrintToChat(client, "\x04[Super Spray Handler]\x01 You've been spray banned.");
}

//Native to un-sprayban a client.
public Native_UnbanClient(Handle:handler, numParams)
{
	new client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		ThrowError("Player index %d is invalid.", client);
	}
	
	if(!gB_Spraybanned[client])
	{
		ThrowError("Player index %d is not spray banned.", client);
	}
	
	new String:auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "DELETE FROM ssh WHERE auth = '%s';", auth);
	
	SQL_LockDatabase(g_arrCVars[SQL]);
	SQL_FastQuery(g_arrCVars[SQL], sQuery);
	SQL_UnlockDatabase(g_arrCVars[SQL]);
	
	gB_Spraybanned[client] = false;
	
	PrintToChat(client, "\x04[Super Spray Handler]\x01 You've been spray unbanned.");
}

//Native to check if a client is spray banned.
public Native_IsBanned(Handle:handler, numParams)
{
	new client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		return ThrowError("Player index %d is invalid.", client);
	}
	
	return gB_Spraybanned[client];
}

/******************************************************************************************
 *                                         TIMERS :D                                      *
 ******************************************************************************************/

//sm_spray_refresh handlers for tracing to HUD or hint message
public TimerChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[]) {
	CreateTimers();
}

//Now we make the timers, and start them up.
stock CreateTimers() {
	if (g_hSprayTimer != INVALID_HANDLE) {
		KillTimer( g_hSprayTimer );
		g_hSprayTimer = INVALID_HANDLE;
	}

	new Float:timer = GetConVarFloat( g_arrCVars[REFRESHRATE] );

	if ( timer > 0.0 )
		g_hSprayTimer = CreateTimer( timer, CheckAllTraces, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

/******************************************************************************************
 *                                     TRACING SPRAYS                                     *
 ******************************************************************************************/

//What happens when you run the !sm_spraytrace command?
public Action:Command_TraceSpray(client, args) {
	if (!IsValidClient(client))
		return Plugin_Handled;

	new Float:vecPos[3];

	if (GetClientEyeEndLocation(client, vecPos)) {
	 	for (new i = 1; i <= MaxClients; i++) {
			if (GetVectorDistance(vecPos, gF_SprayVector[i]) <= GetConVarFloat(g_arrCVars[MAXDIS])) {
				new time = RoundFloat(GetGameTime()) - g_arrSprayTime[i];

				PrintToChat(client, "[SSH] %T", "Spray By", client, gS_arrSprayName[i], gS_arrSprayID[i], time);
				GlowEffect(client, gF_SprayVector[i], 2.0, 0.3, 255, g_PrecacheRedGlow);
				PunishmentMenu(client, i);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(client, "[SSH] %T", "No Spray", client);

	return Plugin_Handled;
}

//Admin Menu Handler for the spray trace function.
public AdminMenu_TraceSpray(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if (!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "Trace", param);
	else if (action == TopMenuAction_SelectOption)
	{
		Command_TraceSpray(param, 0);
	}
}

/******************************************************************************************
 *                                    REMOVING SPRAYS                                     *
 ******************************************************************************************/

 //What happens when you run !sm_removespray?
public Action:Command_RemoveSpray(client, args) {
	if (!IsValidClient(client))
		return Plugin_Handled;

	new Float:vecPos[3];

	if (GetClientEyeEndLocation(client, vecPos)) {
		new String:szAdminName[32];

		GetClientName(client, szAdminName, 31);

	 	for (new i = 1; i<= MaxClients; i++) {
			if (GetVectorDistance(vecPos, gF_SprayVector[i]) <= GetConVarFloat(g_arrCVars[MAXDIS])) {
				new Float:vecEndPos[3];

				PrintToChat(client, "[SSH] %T", "Spray By", client, gS_arrSprayName[i], gS_arrSprayID[i], RoundFloat(GetGameTime()) - g_arrSprayTime[i]);

				SprayDecal(i, 0, vecEndPos);

				gF_SprayVector[i][0] = 0.0;
				gF_SprayVector[i][1] = 0.0;
				gF_SprayVector[i][2] = 0.0;

				PrintToChat(client, "[SSH] %T", "Spray Removed", client, gS_arrSprayName[i], gS_arrSprayID[i], szAdminName);
				LogAction(client, -1, "[SSH] %T", "Spray Removed", LANG_SERVER, gS_arrSprayName[i], gS_arrSprayID[i], szAdminName);
				PunishmentMenu(client, i);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(client, "[SSH] %T", "No Spray", client);

	return Plugin_Handled;
}

//Admin menu handler for the Spray Removal selection
public AdminMenu_SprayRemove(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if (!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "Remove", param);
	else if (action == TopMenuAction_SelectOption)
	{
		Command_RemoveSpray(param, 0);
	}
}

/******************************************************************************************
 *                                 QUICK REMOVING SPRAYS                                  *
 ******************************************************************************************/

 //What happens when you run !sm_qremovespray?
public Action:Command_QuickRemoveSpray(client, args) {
	if (!IsValidClient(client))
		return Plugin_Handled;

	new Float:vecPos[3];

	if (GetClientEyeEndLocation(client, vecPos)) {
		new String:szAdminName[32];

		GetClientName(client, szAdminName, 31);

	 	for (new i = 1; i<= MaxClients; i++) {
			if (GetVectorDistance(vecPos, gF_SprayVector[i]) <= GetConVarFloat(g_arrCVars[MAXDIS])) {
				new Float:vecEndPos[3];

				PrintToChat(client, "[SSH] %T", "Spray By", client, gS_arrSprayName[i], gS_arrSprayID[i], RoundFloat(GetGameTime()) - g_arrSprayTime[i]);

				SprayDecal(i, 0, vecEndPos);

				gF_SprayVector[i][0] = 0.0;
				gF_SprayVector[i][1] = 0.0;
				gF_SprayVector[i][2] = 0.0;

				PrintToChat(client, "[SSH] %T", "Spray Removed", client, gS_arrSprayName[i], gS_arrSprayID[i], szAdminName);
				LogAction(client, -1, "[SSH] %T", "Spray Removed", LANG_SERVER, gS_arrSprayName[i], gS_arrSprayID[i], szAdminName);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(client, "[SSH] %T", "No Spray", client);

	return Plugin_Handled;
}

//Admin Menu handler for the QuickSprayRemove Selection
public AdminMenu_QuickSprayRemove(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength)
{
	if (!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "Quickly Remove Spray", param);
	else if (action == TopMenuAction_SelectOption)
	{
		Command_QuickRemoveSpray(param, 0);
		DisplayTopMenu(gH_AdminMenu, param, TopMenuPosition_LastCategory);
	}
}

/******************************************************************************************
 *                                  Removing All Sprays                                   *
 ******************************************************************************************/

public Action:Command_RemoveAllSprays(client, args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	new String:szAdminName[32];

	GetClientName(client, szAdminName, 31);
	
	for (new i = 1; i<= MaxClients; i++) {
		new Float:vecEndPos[3];

		SprayDecal(i, 0, vecEndPos);

		gF_SprayVector[i][0] = 0.0;
		gF_SprayVector[i][1] = 0.0;
		gF_SprayVector[i][2] = 0.0;

		PrintToChat(client, "[SSH] %T", "Sprays Removed", client, szAdminName);
		LogAction(client, -1, "[SSH] %T", "Sprays Removed", LANG_SERVER, szAdminName);

		return Plugin_Handled;
	}	
	
	PrintToChat(client, "[SSH] %T", "No Sprays", client);

	return Plugin_Handled;
	
}

//Admin Menu handler for the RemoveAll Selection
public AdminMenu_RemoveAllSprays(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength)
{
	if (!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "Remove All Sprays", param);
	else if (action == TopMenuAction_SelectOption)
	{
		Command_RemoveAllSprays(param, 0);
		DisplayTopMenu(gH_AdminMenu, param, TopMenuPosition_LastCategory);
	}
}

/******************************************************************************************
 *                                     ADMIN SPRAYING                                     *
 ******************************************************************************************/

//What happens when you run the !sm_adminspray <target> command.
public Action:Command_AdminSpray(client, args) {
	if (!IsValidClient(client)) {
		if (client == 0) ReplyToCommand(client, "[SSH] Command is in-game only.");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH];
	new target = client;
	if (args >= 1) {
		GetCmdArg(1, arg, sizeof(arg));

		target = FindTarget(client, arg, false, false);

		if (!IsValidClient(target)) {
			//ReplyToCommand(client, "[SSH] %T", "Could Not Find Name", client, arg);
			return Plugin_Handled;
		}
	}

	if (!GoSpray(client, target)) {
		ReplyToCommand(client, "%s[SSH] %T", GetCmdReplySource() == SM_REPLY_TO_CHAT ? "\x04" : "", "Cannot Spray", client);
	}
	else {
		ReplyToCommand(client, "%s[SSH] %T", GetCmdReplySource() == SM_REPLY_TO_CHAT ? "\x04" : "", "Admin Sprayed", client, client, target);
		LogAction(client, -1, "[SSH] %T", "Admin Sprayed", LANG_SERVER, client, target);
	}

	return Plugin_Handled;
}

//Displays the admin spray menu and adds targets to it.
DisplayAdminSprayMenu(client, iPos = 0) {
	if (!IsValidClient(client))
		return;

	new Handle:menu = CreateMenu(MenuHandler_AdminSpray);

	SetMenuTitle(menu, "%T", "Admin Spray Menu", client);
	SetMenuExitBackButton(menu, true);

	for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(!gB_Spraybanned[i])
				{
					if(!IsClientReplay(i) && !IsClientSourceTV(i))
					{
						new String:info[8];
						new String:name[MAX_NAME_LENGTH];
						
						IntToString(GetClientUserId(i), info, 8);
						GetClientName(i, name, MAX_NAME_LENGTH);
						
						AddMenuItem(menu, info, name);
					}
				}
			}
		}
	if(iPos == 0)
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	else
		DisplayMenuAtItem(menu, client, iPos, MENU_TIME_FOREVER);
}

//Menu Handler for the admin spray selection menu
public MenuHandler_AdminSpray(Handle:menu, MenuAction:action, param1, param2) {
	if (!IsValidClient(param1))
		return;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && gH_AdminMenu != INVALID_HANDLE)
			DisplayTopMenu(gH_AdminMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select) {
		decl String:info[32];
		new target;

		GetMenuItem(menu, param2, info, sizeof(info));

		target = GetClientOfUserId(StringToInt(info));

		if (target == 0 || !IsClientInGame(target))
			PrintToChat(param1, "[SSH] %T", "Could Not Find", param1);
		else if (gB_Spraybanned[target])
			PrintToChat(param1, "[SSH} %T", "Player is Spray Banned", param1);
		else
			GoSpray(param1, target);

		DisplayAdminSprayMenu(param1, GetMenuSelectionPosition());
	}
	else
		CloseHandle(menu);
}

//Admin Menu handler for the Admin Spray Selection
public AdminMenu_AdminSpray(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if (!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "AdminSpray", param);
	else if (action == TopMenuAction_SelectOption)
		DisplayAdminSprayMenu(param);
}

/******************************************************************************************
 *                                  SPRAYING THE SPRAYS                                   *
 ******************************************************************************************/

//Called before SprayDecal() to receive a player's decal file and find where to spray it.
public GoSpray(client, target) {
	//Receives the player decal file.
	decl String:spray[8];
	if (!GetPlayerDecalFile(target, spray, sizeof(spray)))
		return false;
	new Float:vecEndPos[3];
	
	//Finds where to spray the spray.
	if (!GetClientEyeEndLocation(client, vecEndPos)) {
		return false;
	}
	new traceEntIndex = TR_GetEntityIndex();
	if (traceEntIndex < 0)
		traceEntIndex = 0;

	//What actually sprays the decal
	SprayDecal(target, traceEntIndex, vecEndPos);
	EmitSoundToAll("player/sprayer.wav", SOUND_FROM_WORLD, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, _, _, _, vecEndPos);

	return true;
}

//Called to spray a players decal. Used for admin spray.
public SprayDecal(client, entIndex, Float:vecPos[3]) {
	if (!IsValidClient(client))
		return;

	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", vecPos);
	TE_WriteNum("m_nEntity", entIndex);
	TE_WriteNum("m_nPlayer", client);
	TE_SendToAll();
}

/******************************************************************************************
 *                                    PUNISHMENT MENU                                     *
 ******************************************************************************************/

//Called to open the punishment menu.
public Action:PunishmentMenu(client, sprayer) {
	if (!IsValidClient(client))
		return Plugin_Handled;

	gS_arrMenuSprayID[client] = gS_arrSprayID[sprayer];
	new Handle:hMenu = CreateMenu(PunishmentMenuHandler);
	
	SetMenuTitle(hMenu, "%T", "Title", client, gS_arrSprayName[sprayer], gS_arrSprayID[sprayer], RoundFloat(GetGameTime()) - g_arrSprayTime[sprayer]);
	
	
	//Makes life simpler later
	//Gos ahead and creates all the booleans that decide what is put into the punishment menu
	
	new bool:isRestricted = GetConVarBool(g_arrCVars[RESTRICT]); //Is the restriction cvar = to 1?
	
	new bool:useSlap = (GetConVarInt(g_arrCVars[SLAPDMG]) > 0) && (isRestricted ? CheckCommandAccess(client, "sm_slap", ADMFLAG_SLAY, false) : true);
	new bool:useSlay = (GetConVarBool(g_arrCVars[USESLAY])) && (isRestricted ? CheckCommandAccess(client, "sm_slay", ADMFLAG_SLAY, false) : true);
	new bool:useBurn = (GetConVarBool(g_arrCVars[USEBURN])) && (isRestricted ? CheckCommandAccess(client, "sm_burn", ADMFLAG_SLAY, false) : true);
	new bool:useFreeze = (GetConVarBool(g_arrCVars[USEFREEZE])) && (isRestricted ? CheckCommandAccess(client, "sm_freeze", ADMFLAG_SLAY, false) : true);
	new bool:useBeacon = (GetConVarBool(g_arrCVars[USEBEACON])) && (isRestricted ? CheckCommandAccess(client, "sm_beacon", ADMFLAG_SLAY, false) : true);
	new bool:useFreezeBomb = (GetConVarBool(g_arrCVars[USEFREEZEBOMB])) && (isRestricted ? CheckCommandAccess(client, "sm_freezebomb", ADMFLAG_SLAY, false) : true);
	new bool:useFireBomb = (GetConVarBool(g_arrCVars[USEFIREBOMB])) && (isRestricted ? CheckCommandAccess(client, "sm_firebomb", ADMFLAG_SLAY, false) : true);
	new bool:useTimeBomb = (GetConVarBool(g_arrCVars[USETIMEBOMB])) && (isRestricted ? CheckCommandAccess(client, "sm_timebomb", ADMFLAG_SLAY, false) : true);
	new bool:useDrug = (GetConVarInt(g_arrCVars[DRUGTIME]) > 0) && (isRestricted ? CheckCommandAccess(client, "sm_drug", ADMFLAG_SLAY, false) : true);
	new bool:useKick = (GetConVarBool(g_arrCVars[USEKICK])) && (isRestricted ? CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK, false) : true);
	new bool:useBan = (GetConVarBool(g_arrCVars[USEBAN])) && (isRestricted ? CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN, false) : true);
	new bool:useSprayBan = (GetConVarBool(g_arrCVars[USESPRAYBAN])) && (isRestricted ? CheckCommandAccess(client, "sm_sprayban", ADMFLAG_BAN, false) : true);
	
	//Adding Punishments to Punishment Menu
	new String:szWarn[128];
	Format(szWarn, 127, "%T", "Warn", client);
	AddMenuItem(hMenu, "warn", szWarn);
	
	if (useSlap) {
		new String:szSlap[128];
		Format(szSlap, 127, "%T", "SlapWarn", client, GetConVarInt(g_arrCVars[SLAPDMG]));
		AddMenuItem(hMenu, "slap", szSlap);
	}

	if (useSlay) {
		new String:szSlay[128];
		Format(szSlay, 127, "%T", "Slay", client);
		AddMenuItem(hMenu, "slay", szSlay);
	}

	if (useBurn) {
		new String:szBurn[128];
		Format(szBurn, 127, "%T", "BurnWarn", client, GetConVarInt(g_arrCVars[BURNTIME]));
		AddMenuItem(hMenu, "burn", szBurn);
	}

	if (useFreeze) {
		new String:szFreeze[128];
		Format(szFreeze, 127, "%T", "Freeze", client);
		AddMenuItem(hMenu, "freeze", szFreeze);
	}

	if (useBeacon) {
		new String:szBeacon[128];
		Format(szBeacon, 127, "%T", "Beacon", client);
		AddMenuItem(hMenu, "beacon", szBeacon);
	}

	if (useFreezeBomb) {
		new String:szFreezeBomb[128];
		Format(szFreezeBomb, 127, "%T", "FreezeBomb", client);
		AddMenuItem(hMenu, "freezebomb", szFreezeBomb);
	}

	if (useFireBomb) {
		new String:szFireBomb[128];
		Format(szFireBomb, 127, "%T", "FireBomb", client);
		AddMenuItem(hMenu, "firebomb", szFireBomb);
	}

	if (useTimeBomb) {
		new String:szTimeBomb[128];
		Format(szTimeBomb, 127, "%T", "TimeBomb", client);
		AddMenuItem(hMenu, "timebomb", szTimeBomb);
	}

	if (useDrug) {
		new String:szDrug[128];
		Format(szDrug, 127, "%T", "szDrug", client);
		AddMenuItem(hMenu, "drug", szDrug);
	}

	if (useKick) {
		new String:szKick[128];
		Format(szKick, 127, "%T", "Kick", client);
		AddMenuItem(hMenu, "kick", szKick);
	}

	if (useBan) {
		new String:szBan[128];
		Format(szBan, 127, "%T", "Ban", client);
		AddMenuItem(hMenu, "ban", szBan);
	}
	
	if (useSprayBan) {
		new String:szSPBan[128];
		Format(szSPBan, 127, "%T", "SPBan", client);
		AddMenuItem(hMenu, "spban", szSPBan);
	}
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

//Handler for the Punishment Menu
public PunishmentMenuHandler(Handle:hMenu, MenuAction:action, client, itemNum) {
	if ( action == MenuAction_Select ) {
		new String:szInfo[32];
		new String:szSprayerName[64];
		new String:szSprayerID[32];
		new String:szAdminName[64];
		new sprayer;

		szSprayerID = gS_arrMenuSprayID[client];
		sprayer = GetClientFromAuthID(gS_arrMenuSprayID[client]);
		szSprayerName = gS_arrSprayName[sprayer];
		GetClientName(client, szAdminName, sizeof(szAdminName));
		GetMenuItem(hMenu, itemNum, szInfo, sizeof(szInfo));
		
		//If you selected to ban someone, we arent going to run the rest of this, calls the ban times menu.
		if (strcmp(szInfo, "ban") == 0) {
			DisplayBanTimesMenu(client);
		}
		//Guess you selected not to ban someone, so now we do this stuff.
		else if ( sprayer && IsClientInGame(sprayer) ) {
			new AdminId:sprayerAdmin = GetUserAdmin(sprayer);
			new AdminId:clientAdmin = GetUserAdmin(client);
			
			//Uh Oh. You can't target this person. Now they're going to kill you.
			if ( ((sprayerAdmin != INVALID_ADMIN_ID) && (clientAdmin != INVALID_ADMIN_ID)) && GetConVarBool(g_arrCVars[IMMUNITY]) && !CanAdminTarget(clientAdmin, sprayerAdmin) ) {
				PrintToChat(client, "\x04[SSH] %T", "Admin Immune", client, szSprayerName);
				LogAction(client, -1, "[SSH] %T", "Admin Immune Log", LANG_SERVER, szAdminName, szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//Wag that finger at them. You're doing good.
			else if ( strcmp(szInfo, "warn") == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "Warned", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				PunishmentMenu(client, sprayer);
			}
			//SMACK! SLAP THAT HOE INTO THE NEXT DIMENSION.
			else if ( strcmp(szInfo, "slap") == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "Slapped And Warned", client, szSprayerName, szSprayerID, GetConVarInt(g_arrCVars[SLAPDMG]));
				LogAction(client, -1, "[SSH] %T", "Log Slapped And Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, GetConVarInt(g_arrCVars[SLAPDMG]));
				SlapPlayer(sprayer, GetConVarInt(g_arrCVars[SLAPDMG]));
				PunishmentMenu(client, sprayer);
			}
			//Now they're dead...>.>
			else if ( strcmp(szInfo, "slay") == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "Slayed And Warned", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log Slayed And Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_slay \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//You get to watch them scream in agony :D
			else if ( strcmp(szInfo, "burn") == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "Burnt And Warned", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log Burnt And Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_burn \"%s\" %d", szSprayerName, GetConVarInt(g_arrCVars[BURNTIME]));
				PunishmentMenu(client, sprayer);
			}
			//All of a sudden. Their legs don't work anymore. odd.
			else if ( strcmp(szInfo, "freeze", false) == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "Froze", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log Froze", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_freeze \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//BEEP. BEEP. BEEP. Now the whole server knows where they are.
			else if ( strcmp(szInfo, "beacon", false) == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "Beaconed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log Beaconed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_beacon \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//Their legs and anyone's legs around them are magically going to stop working in like....10 seconds...
			else if ( strcmp(szInfo, "freezebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "FreezeBombed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log FreezeBombed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_freezebomb \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//Now this is just cruel. You're going to hurt other people too....
			else if ( strcmp(szInfo, "firebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "FireBombed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log FireBombed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_firebomb \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//This is just horrible. You're straight murdering other people too...
			else if ( strcmp(szInfo, "timebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "TimeBombed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log TimeBombed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_timebomb \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//Slip something into their drink?
			else if ( strcmp(szInfo, "drug", false) == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[SSH] %T", "Drugged", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log Drugged", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				CreateTimer(GetConVarFloat(g_arrCVars[DRUGTIME]), Undrug, sprayer, TIMER_FLAG_NO_MAPCHANGE);
				ClientCommand(client, "sm_drug \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
			//GTFO
			else if ( strcmp(szInfo, "kick") == 0 ) {
				KickClient(sprayer, "%T", "Bad Spray Logo", sprayer);
				PrintToChatAll("\x03[SSH] %T", "Kicked", LANG_SERVER, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Log Kicked", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
			}
			//No more spraying for you :)
			else if ( strcmp(szInfo, "spban") == 0 ) {
				PrintToChat(sprayer, "\x03[SSH] %T", "Please change", sprayer);
				//PrintToChat(client, "\x04[SSH] %T", "SPBanned", client, szSprayerName, szSprayerID);
				//LogAction(client, -1, "[SSH] %T", "Log SPBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_sprayban \"%s\"", szSprayerName);
				PunishmentMenu(client, sprayer);
			}
		}
		//Nice. That's not a person.
		else {
			PrintToChat(client, "\x04[SSH] %T", "Could Not Find Name ID", client, szSprayerName, szSprayerID);
			LogAction(client, -1, "[SSH] %T", "Could Not Find Name ID", LANG_SERVER, szSprayerName, szSprayerID);
		}
		
		//If you want to auto-remove their spray after punishing, this does it.
		if (GetConVarBool(g_arrCVars[AUTOREMOVE])) {
			new Float:vecEndPos[3];
			SprayDecal(sprayer, 0, vecEndPos);

			PrintToChat(client, "[SSH] %T", "Spray Removed", client, szSprayerName, szSprayerID, szAdminName);
			LogAction(client, -1, "[SSH] %T", "Spray Removed", LANG_SERVER, szSprayerName, szSprayerID, szAdminName);
		}
	}
	else if ( action == MenuAction_End )
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			RedisplayAdminMenu(gH_AdminMenu, client);
		}
	}
}

/******************************************************************************************
 *                                     BAN TIMES MENU                                     *
 ******************************************************************************************/

//Called to display the list of ban times.
public DisplayBanTimesMenu(int client)
{
	new String:szSprayerName[64];
	new String:szSprayerID[32];
	new String:szAdminName[64];
	new sprayer;

	szSprayerID = gS_arrMenuSprayID[client];
	sprayer = GetClientFromAuthID(gS_arrMenuSprayID[client]);
	szSprayerName = gS_arrSprayName[sprayer];
	GetClientName(client, szAdminName, sizeof(szAdminName));

	if (!IsValidClient(client))
		return;

	new Handle:menu = CreateMenu(MenuHandler_BanTimes);

	SetMenuTitle(menu, "Ban %s for...", szSprayerName);
	SetMenuExitBackButton(menu, true);
	
	if(GetConVarBool(g_arrCVars[USEPBAN]))
		AddMenuItem(menu, "0", "Permanent");
	
	AddMenuItem(menu, "180", "3 Hours");
	AddMenuItem(menu, "360", "6 Hours");
	AddMenuItem(menu, "720", "12 Hours");
	AddMenuItem(menu, "1440", "1 Day");
	AddMenuItem(menu, "4320", "3 Days");
	AddMenuItem(menu, "10080", "1 Week");
	AddMenuItem(menu, "5", "5 Minutes");
	AddMenuItem(menu, "15", "15 Minutes");
	AddMenuItem(menu, "30", "30 Minutes");
	AddMenuItem(menu, "60", "1 Hour");
	AddMenuItem(menu, "43800", "1 Month");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

//Handler for the ban times menu
public MenuHandler_BanTimes(Handle:hMenu, MenuAction:action, client, itemNum)
{
	new String:szInfo[32];
	new String:szSprayerName[64];
	new String:szSprayerID[32];
	new String:szAdminName[64];
	new sprayer;

	szSprayerID = gS_arrMenuSprayID[client];
	sprayer = GetClientFromAuthID(gS_arrMenuSprayID[client]);
	szSprayerName = gS_arrSprayName[sprayer];
	GetClientName(client, szAdminName, sizeof(szAdminName));
	GetMenuItem(hMenu, itemNum, szInfo, sizeof(szInfo));

	if ( action == MenuAction_Select ) 
	{
			if (sprayer) {
				new iTime = StringToInt(szInfo);
				new String:szBad[128];
				Format(szBad, 127, "%T", "Bad Spray Logo", LANG_SERVER);
	
				g_hExternalBan = FindConVar("sb_version");
	
				//SourceBans integration
				if ( g_hExternalBan != INVALID_HANDLE ) {
					ClientCommand(client, "sm_ban #%d %d \"%s\"", GetClientUserId(sprayer), iTime, szBad);

					if (iTime == 0)
						LogAction(client, -1, "[SSH] %T", "EPBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, "SourceBans");
					else
						LogAction(client, -1, "[SSH] %T", "EBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime, "SourceBans");
	
					CloseHandle(g_hExternalBan);
				}
				else {
					g_hExternalBan = FindConVar("mysql_bans_version");
	
					//MySQL Bans integration
					if ( g_hExternalBan != INVALID_HANDLE ) {
						ClientCommand(client, "mysql_ban #%d %d \"%s\"", GetClientUserId(sprayer), iTime, szBad);
	
						if (iTime == 0)
							LogAction(client, -1, "[SSH] %T", "EPBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, "MySQL Bans");
						else
							LogAction(client, -1, "[SSH] %T", "EBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime, "MySQL Bans");
	
						CloseHandle(g_hExternalBan);
					}
					else {
						//Normal Ban
						BanClient(sprayer, iTime, BANFLAG_AUTHID, szBad, szBad);
	
						if (iTime == 0)
							LogAction(client, -1, "[SSH] %T", "PBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
						else
							LogAction(client, -1, "[SSH] %T", "Banned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime);
					}
				}

				if (iTime == 0)
					PrintToChatAll("\x03[SSH] %T", "PBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				else
					PrintToChatAll("\x03[SSH] %T", "Banned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime);
			}
			else {
				PrintToChat(client, "\x04[SSH] %T", "Could Not Find Name ID", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[SSH] %T", "Could Not Find Name ID", LANG_SERVER, szSprayerName, szSprayerID);
			}
	}
	
	
	else if ( action == MenuAction_End )
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			PunishmentMenu(client, sprayer);
		}
	}
		
	
}

/******************************************************************************************
 *                               CONFIRM YOUR ACTIONS MENU                                *
 ******************************************************************************************/

 //Called to display the Yes/No Menu for confirming your actions
public DisplayConfirmMenu(client, target, int type)
{
	if (!IsValidClient(client))
		return;
	
	if(type == 0)
	{
		new Handle:menu = CreateMenu(MenuHandler_SprayBanConf);
		new String:name[128]; 
		GetClientName(target, name, 128);
		
		SetMenuTitle(menu, "SprayBan %s?", name);
		SetMenuExitBackButton(menu, true);
		
		new String:info[8]; 
		IntToString(target, info, 8);
		
		AddMenuItem(menu, info, "Yes!");
		AddMenuItem(menu, "-1", "No!");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	
	else if(type == 1)
	{
		new Handle:menu = CreateMenu(MenuHandler_UnSprayBanConf);
		new String:name[128]; 
		GetClientName(target, name, 128);
		
		SetMenuTitle(menu, "Un-SprayBan %s?", name);
		SetMenuExitBackButton(menu, true);
		
		new String:info[8]; 
		IntToString(target, info, 8);
		
		AddMenuItem(menu, info, "Yes!");
		AddMenuItem(menu, "-1", "No!");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

//Menu Handler for confirming spraybanning someone.
public MenuHandler_SprayBanConf(Handle:hMenu, MenuAction:action, client, itemNum)
{
	new String:info[8];
	GetMenuItem(hMenu, itemNum, info, 8);
	int choice = StringToInt(info);
	
	if ( action == MenuAction_Select ) 
	{	
		if(choice == -1)
		{
			PunishmentMenu(client, choice);
		}
		else
		{
			RunSprayBan(client, choice);
		}
	}
	
	else if ( action == MenuAction_End )
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			PunishmentMenu(client, choice);
		}
	}
}

//Menu Handler for confirming un-spraybanning someone.
public MenuHandler_UnSprayBanConf(Handle:hMenu, MenuAction:action, client, itemNum)
{
	new String:info[8];
	GetMenuItem(hMenu, itemNum, info, 8);
	int choice = StringToInt(info);
	
	if ( action == MenuAction_Select ) 
	{	
		if(choice == -1)
		{
			PunishmentMenu(client, choice);
		}
		else
		{
			RunUnSprayBan(client, choice);
		}
	}
	
	else if ( action == MenuAction_End )
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			PunishmentMenu(client, choice);
		}
	}
}

/******************************************************************************************
 *                                     HELPER METHODS                                     *
 ******************************************************************************************/

 //Used to clear a player from existence in this plugin.
public ClearVariables(client) {
	gF_SprayVector[client][0] = 0.0;
	gF_SprayVector[client][1] = 0.0;
	gF_SprayVector[client][2] = 0.0;
	strcopy(gS_arrSprayName[client], sizeof(gS_arrSprayName[]), "");
	strcopy(gS_Auth[client], sizeof(gS_Auth[]), "");
	strcopy(gS_arrSprayID[client], sizeof(gS_arrSprayID[]), "");
	strcopy(gS_arrMenuSprayID[client], sizeof(gS_arrMenuSprayID[]), "");
	g_arrSprayTime[client] = 0;
	gB_Spraybanned[client] = false;
}

//Converts a clients auth id back into a client index
public GetClientFromAuthID(const String:szAuthID[]) {
	new String:szOtherAuthID[32];
	for ( new i = 1; i <= GetMaxClients(); i++ ) {
		if (IsClientInGame(i) && !IsFakeClient(i) ) {
			GetClientAuthId(i, AuthId_Steam2, szOtherAuthID, 32, true);

			if ( strcmp(szOtherAuthID, szAuthID) == 0 )
				return i;
		}
	}
	return 0;
}

public bool:TraceEntityFilter_NoPlayers(entity, contentsMask) {
	return entity > MaxClients;
}

public bool:TraceEntityFilter_OnlyWorld(entity, contentsMask) {
	return entity == 0;
}


//Used to make fix removing a spray when sm_ssh_overlap != 0
public bool:CheckForZero(Float:vecPos[3])
{
	if(vecPos[0] == 0 && vecPos[1] == 0 && vecPos[2] == 0)
		return true;
	else
		return false;
}

//Applies the glow effect on a spray when you trace the spray
public GlowEffect(client, Float:vecPos[3], Float:flLife, Float:flSize, bright, model) {
	if (!IsValidClient(client))
		return;

	new arrClients[1];
	arrClients[0] = client;
	TE_SetupGlowSprite(vecPos, model, flLife, flSize, bright);
	TE_Send(arrClients,1);
}

//Handles actually making drugs work on a timer.
public Action:Undrug(Handle:hTimer, any:client) {
	if (IsValidClient(client)) {
		new String:clientName[32];
		GetClientName(client, clientName, 31);

		ServerCommand("sm_undrug \"%s\"", clientName);
	}

	return Plugin_Handled;
}

//Pretty obvious what this accomplishes :/
stock bool:IsValidClient(client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

//What is used to find the exact location a player is looking. Used for tracing sprays to the hud/hint and other functions.
public bool:GetClientEyeEndLocation(client, Float:vector[3])
{
	if(!IsValidClient(client))
	{
		return false;
	}
	
	new Float:vOrigin[3];
	new Float:vAngles[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:hTraceRay = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, ValidSpray);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(vector, hTraceRay);
		CloseHandle(hTraceRay);
		
		return true;
	}

	CloseHandle(hTraceRay);
	
	return false;
}

//Checks to make sure a spray is of a valid client.
public bool:ValidSpray(entity, contentsmask)
{
	return entity > MaxClients;
}