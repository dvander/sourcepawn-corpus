/* Ban Player Sprays
* 
* 	DESCRIPTION
* 		Allow you to permanently remove a player's ability to use the in-game spray function
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Beta Release
* 
* 		0.0.2.0	*	Added sm_banspray_list for admins to check if anyone connected to the server is banned
* 					from using sprays
* 
* 		0.0.3.0	+	Added CVar to allow or restrict sprays before client(s) authorized
* 				+	Added ability to remove any sprays a player sprayed if they're banned.
* 
* 		0.0.3.1	+	Added option to turn on spray tracing so when aiming at spray it will display who sprayed it
* 					including their name, steamID, and time sprayed.  All controlled with CVars.
* 
* 		0.0.3.2	+	Added command "sm_removespray" to remove spray without banning sprays.  Either aim at a spray
* 					and use the command or provide a player's name and the spray will be removed.
* 
* 		0.0.3.3	*	Changed command from sm_removespray to sm_deletespray
* 
* 	TO DO List
* 		*	[DONE] Add menu for admins to use and a menu for players to be able to view if they're
* 			on the ban list or not
* 
* 	KNOWN ISSUES
* 		None that I could find during my testing
* 
* 	REQUESTS
* 		Suggest something
* 
* 	CREDITS
* 		Credit for some of the code goes to the author(s) of SprayTracer (https://forums.alliedmods.net/showthread.php?t=75480)
*/

#pragma semicolon 1
#include <sourcemod>
#include <adminmenu>
#include <clientprefs>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "0.0.3.3"

new g_BanSprayTarget[MAXPLAYERS+1];
new bool:PlayerCanSpray[MAXPLAYERS+1] = {false, ...};
new bool:PlayerCachedCookie[MAXPLAYERS+1] = {false, ...};

new bool:Debug;
new bool:RemoveSprayOnBan;
new bool:AllowSpraysBeforeAuthentication;

new Handle:g_cookie;
new Handle:g_adminMenu = INVALID_HANDLE;

new String:TmpLoc[30];
new Float:vecTempLoc[3];

new bool:CanViewSprayInfo[MAXPLAYERS+1];
new DisplayType;
new bool:TraceSprays;
new Float:TraceRate;
new Float:TraceDistance;
new Handle:g_TraceTimer;
new Float:SprayLocation[MAXPLAYERS+1][3];
new String:SprayerName[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:SprayerID[MAXPLAYERS+1][32];
new Float:SprayTime[MAXPLAYERS+1];
new Float:vectorPos[3];

public Plugin:myinfo =
{
	name = "Banned Sprays",
	author = "TnTSCS aka ClarkKent",
	description = "Permanently remove a player's ability to use sprays",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	new Handle:hRandom; //KyleS HATES Handles
	
	HookConVarChange((CreateConVar("sm_bannedsprays_version", PLUGIN_VERSION, 
	"The version of 'Sniper Restrict'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_remove", "1", 
	"Remove the player's spray after they are banned from using sprays?\n0 = Leave Spray\n1 = Remove Spray")), OnRemoveSprayChanged);
	RemoveSprayOnBan = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_auth", "0", 
	"If player's SteamID hasn't been authenticated yet, restrict sprays?\n0 = No, allow\n1 = Yes Do Not Allow")), OnAuthenticationChanged);
	AllowSpraysBeforeAuthentication = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_tmploc", "0.00 0.00 0.00", 
	"Location for sprays to be moved to.\nMust have 2+ decimal places to be valie")), OnTempLocChanged);
	GetConVarString(hRandom, TmpLoc, sizeof(TmpLoc));
	StringToVector(TmpLoc, vecTempLoc);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_debug", "0", 
	"Enable some debug logging?\n0 = No\n1 = Yes")), OnDebugChanged);
	Debug = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_trace", "1", 
	"Trace all player sprays to display info when aimed at?\n0 = No\n1 = Yes")), OnTraceChanged);
	TraceSprays = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_tracerate", "1.0", 
	"Rate at which to check all player sprays (in seconds)", _, true, 1.0)), OnTraceRateChanged);
	TraceRate = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_tracedist", "25.0", 
	"How far away the spray is from the aim to be traced", _, true, 1.0, true, 250.0)), OnTraceDistChanged);
	TraceDistance = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_bannedsprays_display", "7", 
	"Display Options (add them up and put total in CVar)\n1=CenterText\n2=HintText\n4=HudHintText", _, true, 1.0, true, 7.0)), OnDisplayChanged);
	DisplayType = GetConVarInt(hRandom);
	
	CloseHandle(hRandom);
	
	AddTempEntHook("Player Decal", PlayerSpray);
	
	SetCookieMenuItem(Menu_Status, 0, "Display Banned Spray Status");
	
	g_cookie = RegClientCookie("banned-spray", "Banned spray status", CookieAccess_Protected);
	
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_banspray", Command_BanSpray, ADMFLAG_BAN, "Permanently remove a players ability to use spray");
	RegAdminCmd("sm_unbanspray", Command_UnBanSpray, ADMFLAG_BAN, "Permanently remove a players ability to use spray");
	RegAdminCmd("sm_deletespray", Command_RemoveSpray, ADMFLAG_BAN, "Remove a player's spray by either looking at it or providing a player's name");
	RegAdminCmd("sm_banspray_list", Command_BanSprayList, ADMFLAG_GENERIC, "List of player's currently connected who are banned from using sprays");
	
	// **** Coming Soon ****
	//RegAdminCmd("sm_banspray_steamid", Command_BanSpraySteamID, ADMFLAG_BAN, "Manually add a SteamID to the list of players who are banned from using sprays");
	
	new Handle:topmenu = INVALID_HANDLE;
	
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	AutoExecConfig(true);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_adminMenu = INVALID_HANDLE;
	}
}

public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client))
	{
		if (AreClientCookiesCached(client))
		{
			ProcessCookies(client);
		}
		else
		{
			CreateTimer(2.0, Timer_Cookies, GetClientSerial(client), TIMER_REPEAT);
		}
		
		if (CheckCommandAccess(client, "AllowSprayTrace", ADMFLAG_CUSTOM4))
		{
			CanViewSprayInfo[client] = true;
		}
		else
		{
			CanViewSprayInfo[client] = false;
		}
	}
}

public OnClientDisconnect(client)
{
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		ResetVariables(client);
	}
}

public OnMapStart()
{
	if (TraceSprays)
	{
		ClearTimer(g_TraceTimer);
		
		g_TraceTimer = CreateTimer(TraceRate, TraceAllSprays, _, TIMER_REPEAT);
	}
}

public OnMapEnd()
{
	ResetVariables(0);
	
	ClearTimer(g_TraceTimer);
}

public Action:Timer_Cookies(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Stop;
	}
	
	if (AreClientCookiesCached(client))
	{
		ProcessCookies(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public ProcessCookies(client)
{
	PlayerCachedCookie[client] = true;
	PlayerCanSpray[client] = true;
	
	if (PlayerSprayIsBanned(client))
	{
		PrintToServer("[Banned Sprays] Ban added for %N's sprays.", client);
		
		PerformSprayBan(0, client);
	}
}

public PerformSprayBan(admin, client)
{
	if (RemoveSprayOnBan)
	{
		SprayDecal(client, 0, vecTempLoc);
	}
	
	PlayerCanSpray[client] = false;
	SetClientCookie(client, g_cookie, "1");
	
	ShowActivity2(admin, "[Banned Sprays] ", "Banned %N's sprays.", client);
}

public PerformSprayUnBan(admin, client)
{
	PlayerCanSpray[client] = true;
	
	SetClientCookie(client, g_cookie, "0");
	
	ShowActivity2(admin, "[Banned Sprays] ", "Unbanned %N's sprays", client);
}

bool:PlayerSprayIsBanned(client)
{
	decl String:cookie[5];
	cookie[0] = '\0';
	
	GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
	
	if (StrEqual(cookie, "1"))
	{
		return true;
	}
	
	return false;
}

public Action:PlayerSpray(const String:te_name[], const clients[], client_count, Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");
	
	if (IsClientInGame(client))
	{
		if (Debug)
		{
			LogMessage("%N is attempting to spray...", client);
		}
		
		TE_ReadVector("m_vecOrigin", SprayLocation[client]);
		SprayTime[client] = GetGameTime();
		GetClientName(client, SprayerName[client], sizeof(SprayerName[]));
		GetClientAuthString(client, SprayerID[client], sizeof(SprayerID[]));
		
		if (Debug)
		{
			LogMessage("%N's spray info:", client);
			LogMessage("Spray Location: %.2f %.2f %.2f", SprayLocation[client][0], SprayLocation[client][1], SprayLocation[client][2]);
			LogMessage("Spray Time [%.2f] - Sprayer Name [%s] - SprayerID [%s]", SprayTime[client], SprayerName[client], SprayerID[client]);
		}
		
		if (!PlayerCachedCookie[client])
		{
			if (Debug)
			{
				LogMessage("%N's cookies are not cached yet", client);
			}
			
			if (AllowSpraysBeforeAuthentication)
			{
				return Plugin_Continue;
			}
			else
			{
				CPrintToChat(client, "{green}[{red}Banned Sprays{green}] Permissions are being checked, you cannot use sprays until verified.  Try again in a few seconds.");
				return Plugin_Handled;
			}
		}
		
		if (!PlayerCanSpray[client])
		{
			CPrintToChat(client, "{red}[{green}Banned Sprays{red}] You are no longer allowed to use sprays on this server.");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public SprayDecal(client, entIndex, Float:vecPos[3])
{
	if (!IsValidClient(client))
	{
		if (Debug)
		{
			LogMessage("Client (%i) is not a valid client, cannot remove spray.", client);
		}
		
		return;
	}

	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", vecPos);
	TE_WriteNum("m_nEntity", entIndex);
	TE_WriteNum("m_nPlayer", client);
	TE_SendToAll();
}

// ------------------------------------------------------------------------------------------
// --- Thanks to author(s) of Spray Tracer for the following four pieces of code ---
// ------------------------------------------------------------------------------------------
public Action:TraceAllSprays(Handle:timer)
{
	vectorPos[0] = 0.0;
	vectorPos[1] = 0.0;
	vectorPos[2] = 0.0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !CanViewSprayInfo[i] || IsFakeClient(i))
		{
			continue;
		}
		
		if (GetPlayerAimPosition(i, vectorPos))
		{
			for (new a = 1; a <= MaxClients; a++)
			{
				if (!IsClientInGame(a) || IsFakeClient(a))
				{
					continue;
				}
				
				if (GetVectorDistance(vectorPos, SprayLocation[a]) <= TraceDistance)
				{
					if (DisplayType & 1)
					{
						PrintCenterText(i, "Sprayed By [%s - %s]\n[%.2f] seconds ago", SprayerName[a], SprayerID[a], (GetGameTime() - SprayTime[a]));
					}
					
					if (DisplayType & 2)
					{
						PrintHintText(i, "Sprayed By [%s]\nID: [%s]\n[%.2f] seconds ago", SprayerName[a], SprayerID[a], (GetGameTime() - SprayTime[a]));
					}
					
					if (DisplayType & 4)
					{
						Client_PrintKeyHintText(i, "Banned Player Sprays\n\nSprayed By [%s]\nID: [%s]\n[%.2f] seconds ago", SprayerName[a], SprayerID[a], (GetGameTime() - SprayTime[a]));
					}
				}
			}
		}
	}
}

/**
 * @param		client		Player's ClientID
 * @param		vecPos	Vector Position player is aiming at
 * 
 * @return			True if player aim vector is found, false otherwise
 */
bool:GetPlayerAimPosition(client, Float:vecPos[3])
{
	if(!IsClientInGame(client))
	{
		return false;
	}

	new Float:vecAngles[3], Float:vecOrigin[3];

	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);

	new Handle:hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(hTrace))
	{
	 	TR_GetEndPosition(vecPos, hTrace);
		CloseHandle(hTrace);
		return true;
	}

	CloseHandle(hTrace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
 	return entity > MaxClients;
}

public bool:IsValidClient(client)
{
	if (client <= 0)
	{
		return false;
	}
	
	if (client > MaxClients)
	{
		return false;
	}

	return IsClientInGame(client);
}

/**
 * Function to clear/kill the timer and set to INVALID_HANDLE if it's still active
 * 
 * @param	timer		Handle of the timer
 * @noreturn
 */
ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

ResetVariables(client)
{
	if (!client)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SprayerID[i][0] = '\0';
				SprayerName[i][0] = '\0';
				SprayLocation[i][0] = 0.0;
				SprayLocation[i][1] = 0.0;
				SprayLocation[i][2] = 0.0;
				SprayTime[i] = 0.0;
				//PlayerCachedCookie[i] = false;
				//PlayerCanSpray[i] = false;
			}
		}
		
		return;
	}
	
	SprayerID[client][0] = '\0';
	SprayerName[client][0] = '\0';
	SprayLocation[client][0] = 0.0;
	SprayLocation[client][1] = 0.0;
	SprayLocation[client][2] = 0.0;
	SprayTime[client] = 0.0;
	
	//PlayerCachedCookie[client] = false;
	//PlayerCanSpray[client] = false;
}

/** 
 * Converts a string to a vector.
 *
 * @param str			String to convert to a vector.
 * @param vector			Vector to store the converted string to vector
 * @return			True on success, false on failure
 */
StringToVector(String:str[], Float:vector[3])
{
	new String:t_str[3][20];
	
	ReplaceString(str, sizeof(str[]), ",", " ", false);
	ReplaceString(str, sizeof(str[]), ";", " ", false);
	ReplaceString(str, sizeof(str[]), "  ", " ", false);
	TrimString(str);
	
	ExplodeString(str, " ", t_str, sizeof(t_str), sizeof(t_str[]));
	
	vector[0] = StringToFloat(t_str[0]);
	vector[1] = StringToFloat(t_str[1]);
	vector[2] = StringToFloat(t_str[2]);
	
	if (Debug)
	{
		LogMessage("Converted string [%s] to vector [%f %f %f]", str, vector[0], vector[1], vector[2]);
	}
}

// ----------------------------------------------
// --------------- COMMANDS ---------------
// ----------------------------------------------
public Action:Command_BanSpray(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[Ban Spray] Usage: sm_banspray <player>");
		return Plugin_Handled;
	}

	new target;
	decl String:target_name[MAX_NAME_LENGTH];
	target_name[0] = '\0';
	
	GetCmdArg(1, target_name, sizeof(target_name));
	
	if ((target = FindTarget( 
			client,
			target_name,
			true,
			true)) <= 0)
	{
		return Plugin_Handled;
	}
	
	PerformSprayBan(client, target);
	
	return Plugin_Handled;
}

public Action:Command_UnBanSpray(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[Ban Spray] Usage: sm_unbanspray <player>");
		return Plugin_Handled;
	}

	new target;
	decl String:target_name[MAX_NAME_LENGTH];
	target_name[0] = '\0';
	
	GetCmdArg(1, target_name, sizeof(target_name));
	
	if ((target = FindTarget( 
			client,
			target_name,
			false,
			true)) <= 0)
	{
		return Plugin_Handled;
	}
	
	PerformSprayUnBan(client, target);
	
	return Plugin_Handled;
}

public Action:Command_BanSprayList(client, args)
{
	new String:bannedlist[4096], count;
	bannedlist[0] = '\0', count = 0;
	
	Format(bannedlist, sizeof(bannedlist), "\nList of Players With Banned Spray Status:\n");
	Format(bannedlist, sizeof(bannedlist), "%sSTATUS       Player Info\n\n", bannedlist);
	
	decl String:cookie[32];
	cookie[0] = '\0';
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			count ++;
			
			GetClientCookie(i, g_cookie, cookie, sizeof(cookie));
			
			if (StrEqual(cookie, "1"))
			{
				Format(bannedlist, sizeof(bannedlist), "%s*** BANNED : %L\n", bannedlist, i);
			}
			else
			{
				Format(bannedlist, sizeof(bannedlist), "%sNot Banned : %L\n", bannedlist, i);
			}
		}
	}
	
	Format(bannedlist, sizeof(bannedlist), "%s\n============================ end of list =============================\n", bannedlist);
	
	if (count == 0)
	{
		ReplyToCommand(client, "No players found");
		return Plugin_Handled;
	}
	
	PrintToConsole(client, bannedlist);
	return Plugin_Continue;
}

public Action:Command_RemoveSpray(client, args)
{
	new Float:vPos[3];
	
	if (args < 1)
	{
		if (GetPlayerAimPosition(client, vPos))
		{
			for (new a = 1; a <= MaxClients; a++)
			{
				if (!IsClientInGame(a) || IsFakeClient(a))
				{
					continue;
				}
				
				if (GetVectorDistance(vPos, SprayLocation[a]) <= TraceDistance)
				{
					SprayDecal(a, 0, vecTempLoc);
					PrintToChat(client, "Successfully removed %N's spray", a);
				}
				else
				{
					PrintToChat(client, "[SM] ERROR - not currently looking at a valid spray");
				}
			}
		}
		
		return Plugin_Handled;
	}
	
	new target;
	decl String:target_name[MAX_NAME_LENGTH];
	target_name[0] = '\0';
	
	GetCmdArg(1, target_name, sizeof(target_name));
	
	if ((target = FindTarget( 
			client,
			target_name,
			false,
			true)) <= 0)
	{
		return Plugin_Handled;
	}
	
	// Remove Player's Spray
	SprayDecal(target, 0, vecTempLoc);
	PrintToChat(client, "Successfully removed %N's spray", target);
	
	return Plugin_Handled;
}

// ------------------------------------------
// ---------------- MENU -----------------
// ------------------------------------------
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_adminMenu)
	{
		return;
	}
	
	g_adminMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(g_adminMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	AddToTopMenu(g_adminMenu, "sm_banspray", TopMenuObject_Item, AdminMenu_BanSpray, player_commands, "sm_banspray", ADMFLAG_BAN);
}

public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "Display Banned Spray Status");
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		CreateMenuStatus(client);
	}
}

public AdminMenu_BanSpray(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "Ban/Unban Player Sprays");
		}
		
		case TopMenuAction_SelectOption:
		{
			DisplayBanSprayPlayerMenu(param);
		}
	}
}

DisplayBanSprayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_BanSpray);

	decl String:title[100];
	Format(title, sizeof(title), "Ban Sprays for Player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanSpray(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;

	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_adminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_adminMenu, client, TopMenuPosition_LastCategory);
			}
		}
		
		case MenuAction_Select:
		{
			decl String:info[32];
			
			GetMenuItem(menu, param2, info, sizeof(info));
			new userid = StringToInt(info);
			new target = GetClientOfUserId(userid);
			
			if (!target)
			{
				PrintToChat(client, "[Banned Spray] %t", "Player no longer available");
			}
			else if (!CanUserTarget(client, target))
			{
				PrintToChat(client, "[Banned Spray] %t", "Unable to target");
			}
			else
			{
				g_BanSprayTarget[client] = target;
				DisplayBanSprayMenu(client, target);
			}
		}
	}
}

DisplayBanSprayMenu(client, target)
{
	new Handle:menu = CreateMenu(MenuHandler_BanSprays);

	decl String:title[100];
	title[0] = '\0';
	Format(title, sizeof(title), "Choose:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	decl String:cookie[8];

	GetClientCookie(target, g_cookie, cookie, sizeof(cookie));
	
	if (!strcmp(cookie, "1"))
	{
		AddMenuItem(menu, "0", "UnBan Player's Spray");
	}
	else 
	{
		AddMenuItem(menu, "1", "Ban Player's Spray");
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanSprays(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;

	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_Cancel:
		{
			if (param1 == MenuCancel_ExitBack && g_adminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_adminMenu, client, TopMenuPosition_LastCategory);
			}
		}
		
		case MenuAction_Select:
		{
			decl String:info[32];
			info[0] = '\0';
			
			GetMenuItem(menu, param2, info, sizeof(info));
			new action_info = StringToInt(info);
			
			switch (action_info)
			{
				case 0:
				{
					PerformSprayUnBan(client, g_BanSprayTarget[client]);
				}
				
				case 1:
				{
					PerformSprayBan(client, g_BanSprayTarget[client]);
				}
			}
		}
	}
}

CreateMenuStatus(client)
{
	new Handle:menu = CreateMenu(Menu_StatusDisplay);
	decl String:text[64];
	text[0] = '\0';
	decl String:cookie[8];
	cookie[0] = '\0';
	
	Format(text, sizeof(text), "Banned Spray Status");
	SetMenuTitle(menu, text);

	GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
	
	if (!strcmp(cookie, "1"))
	{
		AddMenuItem(menu, "banned-spray", "You are banned from using sprays", ITEMDRAW_DISABLED);
	}
	else
	{
		AddMenuItem(menu, "banned-spray", "You are not banned from using sprays", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}

public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	
	switch (action)
	{
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					ShowCookieMenu(client);
				}
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

// --------------------------------
// --------- SMLib Stuff -------
// -------- Thanks Berni --------
/**
 * Prints white text to the right-center side of the screen
 * for one client. Does not work in all games.
 * Line Breaks can be done with "\n".
 * 
 * @param client		Client Index.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @return				True on success, false if this usermessage doesn't exist.
 */
bool:Client_PrintKeyHintText(client, const String:format[], any:...)
{
	new Handle:userMessage = StartMessageOne("KeyHintText", client);
	
	if (userMessage == INVALID_HANDLE)
	{
		return false;
	}

	decl String:buffer[254];
	buffer[0] = '\0';
	
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(userMessage, "hints", format);
	}
	else
	{
		BfWriteByte(userMessage, 1); 
		BfWriteString(userMessage, buffer); 
	}
	
	EndMessage();
	
	return true;
}


public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnRemoveSprayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RemoveSprayOnBan = GetConVarBool(cvar);
}

public OnAuthenticationChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowSpraysBeforeAuthentication = GetConVarBool(cvar);
}

public OnTempLocChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, TmpLoc, sizeof(TmpLoc));
	StringToVector(TmpLoc, vecTempLoc);
}

public OnDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Debug = GetConVarBool(cvar);
}

public OnTraceChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TraceSprays = GetConVarBool(cvar);
	
	ClearTimer(g_TraceTimer);
	
	if (TraceSprays)
	{
		g_TraceTimer = CreateTimer(TraceRate, TraceAllSprays, _, TIMER_REPEAT);
	}
}

public OnTraceRateChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TraceRate = GetConVarFloat(cvar);
	
	ClearTimer(g_TraceTimer);
	
	g_TraceTimer = CreateTimer(TraceRate, TraceAllSprays, _, TIMER_REPEAT);
}

public OnDisplayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DisplayType = GetConVarInt(cvar);
}

public OnTraceDistChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TraceDistance = GetConVarFloat(cvar);
}