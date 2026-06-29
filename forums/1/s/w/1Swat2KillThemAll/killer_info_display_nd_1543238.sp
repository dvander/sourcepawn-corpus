#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <smlib>
#include <colors>

// 1Swat2KillThemAll
#define PLUGIN_VERSION "1.3.1-ND"
// -- 1Swat2KillThemAll


/****************************************************************
			P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo = {
	name		= "Killer Info Display",
	// 1Swat2KillThemAll
	author		= "Berni, gH0sTy, Smurfy1982, Snake60, 1Swat2KillThemAll",
	// -- 1Swat2KillThemAll
	description	= "Displays the health, the armor and the weapon of the player who has killed you",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=670361"
}


/****************************************************************
			G L O B A L   V A R S
*****************************************************************/

// ConVar Handles
new
	Handle:cvVersion			= INVALID_HANDLE,
	Handle:cvPrinttochat		= INVALID_HANDLE,
	Handle:cvPrinttopanel		= INVALID_HANDLE,
	Handle:cvShowweapon			= INVALID_HANDLE,
	Handle:cvShowarmorleft		= INVALID_HANDLE,
	Handle:cvShowdistance		= INVALID_HANDLE,
	Handle:cvDistancetype		= INVALID_HANDLE,
	Handle:cvAnnouncetime		= INVALID_HANDLE,
	Handle:cvDefaultPref		= INVALID_HANDLE;

// Misc Vars
new
	bool:enabledForClient[MAXPLAYERS + 1],
	Handle:cookie = INVALID_HANDLE,
	bool:cookiesEnabled = false;

// 1Swat2KillThemAll
new bool:nucleardawn = false;
new Handle:cvNuclearDawn_ShowClass = INVALID_HANDLE;
new Handle:cvNuclearDawn_ShowRank  = INVALID_HANDLE;

enum ND_Class {
	ND_Class_Invalid = -1,
	ND_Class_Assault,
	ND_Class_Exo,
	ND_Class_Assassin,
	ND_Class_Support
}

stock ND_GetPlayerRank(client) {
	new ent = GetCNDPlayerResource();

	if (ent != INVALID_ENT_REFERENCE) {
		new offset = FindSendPropInfo("CNDPlayerResource", "m_iPlayerRank");
		if (offset > 0) {
			return GetEntData(ent, offset + client * 4);
		}
	}

	return 0;
}

stock ND_Class:ND_GetPlayerClass(client) {
	new ent = GetCNDPlayerResource();

	if (ent != INVALID_ENT_REFERENCE) {
		new offset = FindSendPropInfo("CNDPlayerResource", "m_iPlayerClass");
		if (offset > 0) {
			return ND_Class:GetEntData(ent, offset + client * 4);
		}
	}

	return ND_Class_Invalid;
}

stock ND_GetClassName(ND_Class:class, String:class_name[], maxlen) {
	static const String:ClassNames[ND_Class][] = {
		"Assault",
		"Exo",
		"Stealth",
		"Support"
	};

	if (class > ND_Class_Invalid && class < ND_Class) {
		strcopy(class_name, maxlen, ClassNames[class]);
	}
	else {
		class_name[0] = '\0';
	}
}

stock GetCNDPlayerResource() {
	static ref = INVALID_ENT_REFERENCE;

	new ent = INVALID_ENT_REFERENCE;

	for (new i = 0; i < 2 && ent == INVALID_ENT_REFERENCE; i++) {
		if (ref == INVALID_ENT_REFERENCE) {
			ent = FindEntityByNetClass("CNDPlayerResource");
			ref = EntIndexToEntRef(ent);
		}
		else {
			ent = EntRefToEntIndex(ref);
		}
	}

	return ent;
}

stock FindEntityByNetClass(const String:netclass[], start = INVALID_ENT_REFERENCE) {
	new len = strlen(netclass) + 2,
		maxEnts = GetMaxEntities();

	decl String:_netclass[len];

	for (new i = (start == INVALID_ENT_REFERENCE ? MaxClients + 1 : start); i <= maxEnts; i++) {
		if (IsValidEntity(i) && GetEntityNetClass(i, _netclass, len) && StrEqual(_netclass, netclass)) {
			return i;
		}
	}

	return INVALID_ENT_REFERENCE;
}
// -- 1Swat2KillThemAll

/****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public OnPluginStart()
{	
	decl String:gamefolder[32];
	GetGameFolderName(gamefolder, sizeof(gamefolder));
	if (StrEqual(gamefolder, "nucleardawn"))
	{
		nucleardawn = true;
	}
	
	// ConVars
	cvVersion = CreateConVar("kid_version", PLUGIN_VERSION, "Killer info display plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(cvVersion, PLUGIN_VERSION);

	cvPrinttochat		= CreateConVar("kid_printtochat",		"1",		"Prints the killer info to the victims chat", FCVAR_PLUGIN);
	cvPrinttopanel		= CreateConVar("kid_printtopanel",		"1",		"Displays the killer info to the victim as a panel", FCVAR_PLUGIN);
	cvShowweapon		= CreateConVar("kid_showweapon",		"1",		"Set to 1 to show the weapon the player got killed with, 0 to disable.", FCVAR_PLUGIN);
	cvShowarmorleft		= CreateConVar("kid_showarmorleft",		"1",		"Set to 0 to disable, 1 to show the armor, 2 to show the suitpower the killer has left.", FCVAR_PLUGIN);
	cvShowdistance		= CreateConVar("kid_showdistance",		"1",		"Set to 1 to show the distance to the killer, 0 to disable.", FCVAR_PLUGIN);
	cvDistancetype		= CreateConVar("kid_distancetype",		"meters",	"Set to \"meters\" to show the distance in \"meters\" or \"feet\" for feet.", FCVAR_PLUGIN);
	cvAnnouncetime		= CreateConVar("kid_announcetime",		"5",		"Time in seconds after an announce about turning killer infos on/off is printed to chat, set to -1 to disable.", FCVAR_PLUGIN);
	cvDefaultPref		= CreateConVar("kid_defaultpref",		"1",		"Default client preference (0 - killer info display off, 1 - killer info display on)", FCVAR_PLUGIN);

	// 1Swat2KillThemAll
	if (nucleardawn) {
		cvNuclearDawn_ShowClass		= CreateConVar("kid_nd_class",		"1",		"Prints the class info to the victims chat", FCVAR_PLUGIN);
		cvNuclearDawn_ShowRank		= CreateConVar("kid_nd_rank",		"1",		"Prints the rank info to the victims chat", FCVAR_PLUGIN);
	}
	// -- 1Swat2KillThemAll

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	// create or load cfg
	AutoExecConfig(true);

	// add translations support
	LoadTranslations("killer_info_display_nd.phrases");
	
	cookiesEnabled = (GetExtensionFileStatus("clientprefs.ext") == 1);

	if (cookiesEnabled) {
		// prepare title for clientPref menu
		decl String:menutitle[64];
		Format(menutitle, sizeof(menutitle), "%T", "name", LANG_SERVER);
		SetCookieMenuItem(PrefMenu, 0, menutitle);
		cookie = RegClientCookie("killerinfo", "Enable (\"on\") / Disable (\"off\") Display of Killer Info", CookieAccess_Public);
		
		for (new client=1; client <= MaxClients; client++) {
			
			if (!IsClientInGame(client)) {
				continue;
			}

			if (!AreClientCookiesCached(client)) {
				continue;
			}

			ClientIngameAndCookiesCached(client);
		}
	}

	RegConsoleCmd("sm_killerinfo", Command_KillerInfo, "On/Off Killer info display");
}

public OnClientCookiesCached(client)
{
	if (IsClientInGame(client)) {
		ClientIngameAndCookiesCached(client);
	}
}

public OnClientPutInServer(client)
{
	if (cookiesEnabled && AreClientCookiesCached(client)) {
		ClientIngameAndCookiesCached(client);
	}
}

public OnClientConnected(client)
{
	enabledForClient[client] = true;
}

/***************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption) {
		DisplaySettingsMenu(client);
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select) {
		decl String:preference[8];

		GetMenuItem(prefmenu, item, preference, sizeof(preference));

		enabledForClient[client] = bool:StringToInt(preference);

		if (enabledForClient[client]) {
			SetClientCookie(client, cookie, "on");
		}
		else {
			SetClientCookie(client, cookie, "off");
		}

		DisplaySettingsMenu(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(prefmenu);
	}
}

public Action:Command_KillerInfo(client, args)
{
	if (enabledForClient[client]) {
		enabledForClient[client] = false;
		CPrintToChat(client, "{red}[Killer Info] %t", "kid_disabled");

		if (cookiesEnabled) {
			SetClientCookie(client, cookie, "off");
		}
	}
	else {
		enabledForClient[client] = true;
		CPrintToChat(client, "{blue}[Killer Info] %t", "kid_enabled");

		if (cookiesEnabled) {
			SetClientCookie(client, cookie, "on");
		}
	}	
}

public Action:Timer_Announce(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);

	// Check for invalid client serial
	if (client == 0) {
		return Plugin_Stop;
	}

	CPrintToChat(client, "{blue}[Killer Info] {default}%t", "announcement");
	
	return Plugin_Stop;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client		= GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker	= GetClientOfUserId(GetEventInt(event, "attacker"));
	new dominated	= GetEventBool(event, "dominated");
	new revenge		= GetEventBool(event, "revenge");

	if (client == 0 || attacker == 0 || client == attacker) {
		return Plugin_Continue;
	}
	
	if (!enabledForClient[client]) {
		return Plugin_Continue;
	}

	decl
		String:weapon[32],
		String:attackerName[MAX_NAME_LENGTH],
		String:unitType[8],
		String:distanceType[5];

	new
		Float:distance,
		armor;

	new healthLeft = GetClientHealth(attacker);
	new showArmorLeft = GetConVarInt(cvShowarmorleft);
	new bool:showDistance = GetConVarBool(cvShowdistance);
	new bool:showWeapon = GetConVarBool(cvShowweapon);

	GetEventString(event, "weapon", weapon, sizeof(weapon));		
	GetClientName(attacker, attackerName, sizeof(attackerName));
	GetConVarString(cvDistancetype, distanceType, sizeof(distanceType));

	if (showArmorLeft > 0) {

		if (showArmorLeft == 1) {
			armor = Client_GetArmor(attacker);
		}
		else {
			armor = RoundFloat(Client_GetSuitPower(client));
		}
	}

	if (showDistance) {
		
		distance = Entity_GetDistance(client, attacker);
		
		if (StrEqual(distanceType, "feet", false)) {
			distance = Math_UnitsToFeet(distance);
			Format(unitType, sizeof(unitType), "%t", "feet");
		}
		else {
			distance = Math_UnitsToMeters(distance);
			Format(unitType, sizeof(unitType), "%t", "meters");
		}
	}

	// Print To Chat ?
	if ((GetConVarBool(cvPrinttochat))) {
		
		new
			String:chat_weapon[64]		= "",
			String:chat_distance[64]	= "",
			String:chat_armor[64]		= "";

		// 1Swat2KillThemAll
		new String:chat_class[64]		= "",
			String:chat_rank[64]		= "";
		// -- 1Swat2KillThemAll
			
		if (showWeapon) {
			Format(chat_weapon, sizeof(chat_weapon), " %t", "chat_weapon", weapon);
		}
		
		if (showDistance) {
			Format(chat_distance, sizeof(chat_distance), " %t", "chat_distance", distance, unitType);
		}

		if (GetConVarBool(cvShowarmorleft) && armor > 0) {
			Format(chat_armor, sizeof(chat_armor), " %t", "chat_armor", armor, showArmorLeft == 1 ? "armor" : "suitpower");
		}

		// 1Swat2KillThemAll
		if (GetConVarBool(cvNuclearDawn_ShowClass)) {
			decl String:class[32];
			ND_GetClassName(ND_GetPlayerClass(attacker), class, sizeof(class));
			Format(chat_class, sizeof(chat_class), "%t", "chat_class", class);
		}

		if (GetConVarBool(cvNuclearDawn_ShowRank)) {
			Format(chat_rank, sizeof(chat_rank), "%t", "chat_rank", ND_GetPlayerRank(attacker));
		}
		// -- 1Swat2KillThemAll

		CPrintToChatEx(
			client,
			attacker,
			"{green}[Killer Info] %t",
			"chat_basic",
			attackerName,
			chat_weapon,
			chat_distance,
			healthLeft,
			chat_armor
			// 1Swat2KillThemAll
			, chat_class,
			chat_rank
			// -- 1Swat2KillThemAll
		);

		if (dominated) {
			CPrintToChatEx(
				client,
				attacker,
				"{green}[Killer Info] %t",
				"dominated",
				attackerName
			);
		}
		
		if (revenge) {
			CPrintToChatEx(
				client,
				attacker,
				"{green}[Killer Info] %t",
				"revenge",
				attackerName
			);
		}
	}

	// Print To Panel ?
	if ((GetConVarBool(cvPrinttopanel))) {

		new Handle:panel= CreatePanel();
		decl String:buffer[128];

		Format(buffer, sizeof(buffer), "%t", "panel_killer", attackerName);
		SetPanelTitle(panel, buffer);

		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		
		if (showWeapon) {
			Format(buffer, sizeof(buffer), "%t", "panel_weapon", weapon);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}

		// 1Swat2KillThemAll
		if (nucleardawn) {
			buffer[0] = '\0';
			decl String:buff[64];
			new bool:space = false;
			if ((space = GetConVarBool(cvNuclearDawn_ShowRank))) {
				ND_GetClassName(ND_GetPlayerClass(attacker), buff, sizeof(buff));
				Format(buffer, sizeof(buffer), "%t", "panel_rank", buff);
			}

			if (GetConVarBool(cvNuclearDawn_ShowClass)) {
				if (space) {
					StrCat(buffer, sizeof(buffer), " ");
				}

				Format(buff, sizeof(buff), "%t", "panel_rank", ND_GetPlayerRank(attacker));
				StrCat(buffer, sizeof(buffer), buff);
			}

			if (!StrEqual(buffer, "")) {
				DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
			}
		}
		// -- 1Swat2KillThemAll
		
		Format(buffer, sizeof(buffer), "%t", "panel_health", healthLeft);
		DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);

		if (showArmorLeft > 0 && armor > 0) {
			Format(buffer, sizeof(buffer), "%t", "panel_armor", showArmorLeft == 1 ? "armor" : "suitpower", armor);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}

		if (showDistance) {
			Format(buffer, sizeof(buffer), "%t", "panel_distance", distance, unitType);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}
		
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);

		if (dominated) {
			Format(buffer, sizeof(buffer), "%t", "dominated", attackerName);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}

		if (revenge) {
			Format(buffer, sizeof(buffer), "%t", "revenge", attackerName);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}

		SetPanelCurrentKey(panel, 10);
		SendPanelToClient(panel, client, Handler_DoNothing, 20);
	}

	return Plugin_Continue;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

/***************************************************************
			P L U G I N    F U N C T I O N S
****************************************************************/
 
ClientIngameAndCookiesCached(client)
{
	decl String:preference[8];
	GetClientCookie(client, cookie, preference, sizeof(preference));

	if (StrEqual(preference, "")) {
		enabledForClient[client] = GetConVarBool(cvDefaultPref);
		
		new Float:announceTime = GetConVarFloat(cvAnnouncetime);

		if (announceTime > 0.0) {
			CreateTimer(announceTime, Timer_Announce, GetClientSerial(client));
		}
	}
	else {
		enabledForClient[client] = !StrEqual(preference, "off", false);
	}
}

DisplaySettingsMenu(client)
{
	decl String:MenuItem[128];
	new Handle:prefmenu = CreateMenu(PrefMenuHandler);

	Format(MenuItem, sizeof(MenuItem), "%t", "name");
	SetMenuTitle(prefmenu, MenuItem);

	new String:checked[] = String:0x9A88E2;
	
	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "enabled", enabledForClient[client] ? checked : "   ");
	AddMenuItem(prefmenu, "1", MenuItem);

	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "disabled", enabledForClient[client] ? "   " : checked);
	AddMenuItem(prefmenu, "0", MenuItem);

	DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
}
