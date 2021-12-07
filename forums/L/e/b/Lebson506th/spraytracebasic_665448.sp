/*
*	Spray Trace
*
*	Spray Trace originally by Nican
*	Punishment menu added by mbalex (Aka Cpt.Moore)
*	Both versions combined by Lebson506th
*	Basic version by Lebson506th
*
*	Description
*	-----------
*
*	This is a handy plugin for server admins to manipulate player sprays in a couple different ways.
*
*	1) Trace a player's spray on any surface
* 		The plugin marks which spray is being looked at by a red glow and then displays a menu to deal out punishments.
*
*	2) Remove a player's spray from any surface
*		The plugin removes the spray that is being looked at and displays a menu to deal out punishments
*
*	3) Spray any player's spray logo on command.
*		Sprays the selected user's spray where the admin is looking.
*
*	The punishments including a text warning, kick, temporary ban, or permanent ban.
*
*	Usage
*	-----
*
*	sm_spraybasic_distance (default: 50.0) - maximum distance the plugin will trace the spray
*	sm_spraybasic_bantime (default: 60) - How long the temporary ban is for - 0 to disable temporary banning
*	sm_spraybasic_enablepban (default: 1) - Enables (1) or disables (0) the use of a Permanent Ban as a punishment.
*	sm_spraybasic_autoremove (default: 0) - Enables automatically removing sprays when a punishment is dealt.
*	sm_spraybasic_useimmunity (default: 1) - Enables or disables using admin immunity to determine if one admin can punish another.
*	sm_spraybasic_global (default: 1) - Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.
*
*	sm_spray_version - Returns the current version of the spray tracer.
*
*	Admin menu integration into the Server Commands section
*
*	Or in console use these commands:
*	
*	sm_spraytrace - to look up the owner of the logo in front of you
*	sm_removespray - to remove the logo in front of you
*	sm_adminspray "name" - to spray another player's logo in front of you
*
*	Change Log
*	----------
*
*	6/12/2011 - v5.8b
*	- Fixed an error due to a malformed translation on kick.
*	- Fixed punishments not working because of screwed up logic.
*	- Fixed Admins getting a second chance to punish other admins that are supposed to be immune.
*
*	5/5/2011 - v5.8a
*	- Re-added sm_spraybasic_enablepban to enable/disable the permanent ban option from the menu.
*	- Changed the versioning system to match the main plugin.
*
*	5/1/2011 - v1.0
*	- Initial release.
*/

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "5.8b"
#define MAXDIS 0
#define TBANTIME 1
#define PBAN 2
#define AUTOREMOVE 3
#define IMMUNITY 4
#define GLOBAL 5
#define NUMCVARS 6

//Nican: I am doing all this global for those "happy" people who spray something and quit the server
new Float:g_vecSprayLocation[MAXPLAYERS + 1][3];
new String:g_szSprayerName[MAXPLAYERS + 1][64];
new String:g_szSprayerID[MAXPLAYERS + 1][32];
new String:g_szMenuSprayerID[MAXPLAYERS + 1][32];
new g_SprayTime[MAXPLAYERS + 1];

// Misc. globals
new Handle:g_hCVars[NUMCVARS];
new Handle:g_hTopMenu;
new Handle:g_hExternalBan = INVALID_HANDLE;
new g_PreCacheRedGlow;

public Plugin:myinfo = 
{
	name = "Spray Tracer - Basic Edition",
	author = "Nican132, CptMoore, Lebson506th",
	description = "Traces sprays on the wall",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	LoadTranslations("spraytracebasic.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_spraybasic_version", PLUGIN_VERSION, "Spray tracer plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
 
	RegAdminCmd("sm_spraytrace", TraceSpray, ADMFLAG_BAN, "Look up the owner of the logo in front of you.");
	RegAdminCmd("sm_removespray", RemoveSpray, ADMFLAG_BAN, "Remove the logo in front of you.");
	RegAdminCmd("sm_adminspray", AdminSpray, ADMFLAG_BAN, "Sprays the named player's logo in front of you.");

	g_hCVars[MAXDIS] = CreateConVar("sm_spraybasic_distance","50.0","How far away the spray will be traced to.");
	g_hCVars[TBANTIME] = CreateConVar("sm_spraybasic_bantime","60","How long the temporary ban is for. 0 to disable temporary banning.");
	g_hCVars[PBAN] = CreateConVar("sm_spraybasic_enablepban","1","Enables (1) or disables (0) the use of a Permanent Ban as a punishment.");
	g_hCVars[AUTOREMOVE] = CreateConVar("sm_spraybasic_autoremove","1","Enables automatically removing sprays when a punishment is dealt.");
	g_hCVars[IMMUNITY] = CreateConVar("sm_spraybasic_useimmunity","1","Enables or disables using admin immunity to determine if one admin can punish another.");
	g_hCVars[GLOBAL] = CreateConVar("sm_spraybasic_global","1","Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");

	AddTempEntHook("Player Decal", PlayerSpray);

	AutoExecConfig(true, "plugin.spraytracebasic");
}

/*
	Clears all stored sprays when the map changes.
	Also prechaches the model.
*/

public OnMapStart() {
	g_PreCacheRedGlow = PrecacheModel("sprites/redglow1.vmt");

	for(new i = 1; i <= MaxClients; i++)
		ClearVariables(i);
}

/*
	Clears all stored sprays for a disconnecting
	client if global spray tracing is disabled.
*/

public OnClientDisconnect(client) {
	if(!GetConVarBool(g_hCVars[GLOBAL]))
		ClearVariables(client);
}

/*
	Clears the stored sprays for the given client.
*/

public ClearVariables(client) {
	g_vecSprayLocation[client][0] = 0.0;
	g_vecSprayLocation[client][1] = 0.0;
	g_vecSprayLocation[client][2] = 0.0;
	strcopy(g_szSprayerName[client], sizeof(g_szSprayerName[]), "");
	strcopy(g_szSprayerID[client], sizeof(g_szSprayerID[]), "");
	strcopy(g_szMenuSprayerID[client], sizeof(g_szMenuSprayerID[]), "");
	g_SprayTime[client] = 0;
}

/*
Records the location, name, ID, and time of all sprays
*/

public Action:PlayerSpray(const String:szTempEntityName[], const arrClients[], iClientCount, Float:flDelay) {
	new client = TE_ReadNum("m_nPlayer");

	if(IsValidClient(client)) {
		TE_ReadVector("m_vecOrigin", g_vecSprayLocation[client]);

		g_SprayTime[client] = RoundFloat(GetGameTime());
		GetClientName(client, g_szSprayerName[client], 64);
		GetClientAuthString(client, g_szSprayerID[client], 32);
	}
}

/*
Trace spray function
*/

public Action:TraceSpray(caller, args) {
	if(!IsValidClient(caller))
		return Plugin_Handled;

	new Float:vecPos[3];

	if(GetPlayerEye(caller, vecPos)) {
	 	for(new client = 1; client <= MaxClients; client++) {
			if(GetVectorDistance(vecPos, g_vecSprayLocation[client]) <= GetConVarFloat(g_hCVars[MAXDIS])) {
				new flTime = RoundFloat(GetGameTime()) - g_SprayTime[client];

				PrintToChat(caller, "[Spray Trace] %T", "Spray By", caller, g_szSprayerName[client], g_szSprayerID[client], flTime);
				GlowEffect(caller, g_vecSprayLocation[client], 2.0, 0.3, 255, g_PreCacheRedGlow);
				AdminMenu(caller, client);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(caller, "[Spray Trace] %T", "No Spray", caller);

	return Plugin_Handled;
}

/*
Remove spray function
*/

public Action:RemoveSpray(caller, args) {
	if(!IsValidClient(caller))
		return Plugin_Handled;

	new Float:vecPos[3];

	if(GetPlayerEye(caller, vecPos)) {
		new String:adminName[32];

		GetClientName(caller, adminName, 31);

	 	for(new client = 1; client <= MaxClients; client++) {
			if(GetVectorDistance(vecPos, g_vecSprayLocation[client]) <= GetConVarFloat(g_hCVars[MAXDIS])) {
				new Float:vEndPos[3];

				PrintToChat(caller, "[Spray Trace] %T", "Spray By", caller, g_szSprayerName[client], g_szSprayerID[client], RoundFloat(GetGameTime()) - g_SprayTime[client]);

				SprayDecal(client, 0, vEndPos);

				g_vecSprayLocation[client][0] = 0.0;
				g_vecSprayLocation[client][1] = 0.0;
				g_vecSprayLocation[client][2] = 0.0;

				PrintToChat(caller, "[Spray Trace] %T", "Spray Removed", caller, g_szSprayerName[client], g_szSprayerID[client], adminName);
				LogAction(caller, -1, "[Spray Trace] %T", "Spray Removed", LANG_SERVER, g_szSprayerName[client], g_szSprayerID[client], adminName);
				AdminMenu(caller, client);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(caller, "[Spray Trace] %T", "No Spray", caller);

	return Plugin_Handled;
}

/*
Admin spray functions
*/

public Action:AdminSpray(client, args) {
	if(!IsValidClient(client))
		return Plugin_Handled;

	new target;

	if (args == 1) {
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		target = FindTarget(client, arg, false, false);

		if (!target) {
			ReplyToCommand(client, "[Spray Trace] %T", "Could Not Find Name", client, arg);
			return Plugin_Handled;
		}
	}
	else
		target = client;

	GoSpray(client, target);

	return Plugin_Handled;
}

public GoSpray(client, target) {
	new Float:vecEndPos[3];

	if(GetPlayerEye(client, vecEndPos) && IsValidClient(client) && IsValidClient(target)) {
		new String:szTargetName[32];
		new String:szAdminName[32];
		new iTraceEntIndex = TR_GetEntityIndex();

		GetClientName(target, szTargetName, 31);
		GetClientName(client, szAdminName, 31);

		SprayDecal(target, iTraceEntIndex, vecEndPos);
		EmitSoundToAll("misc/sprayer.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);

		PrintToChat(client, "\x04[Spray Trace] %T", "Admin Sprayed", client, szAdminName, szTargetName);
		LogAction(client, -1, "[Spray Trace] %T", "Admin Sprayed", LANG_SERVER, szAdminName, szTargetName);
	}
	else
		PrintToChat(client, "\x04[Spray Trace] %T", "Cannot Spray", client);
} 

/*
Admin Spray menu
*/

DisplayAdminSprayMenu(client) {
	if(!IsValidClient(client))
		return;

	new Handle:hMenu = CreateMenu(MenuHandler_AdminSpray);

	SetMenuTitle(hMenu, "%T", "Admin Spray Menu", client);
	SetMenuExitBackButton(hMenu, true);

	AddTargetsToMenu(hMenu, client, true, false);

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminSpray(Handle:hMenu, MenuAction:maAction, param1, param2) {
	if(!IsValidClient(param1))
		return;

	if (maAction == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (maAction == MenuAction_Select) {
		decl String:szInfo[32];
		new target;

		GetMenuItem(hMenu, param2, szInfo, sizeof(szInfo));

		target = GetClientOfUserId(StringToInt(szInfo))

		if (!IsValidClient(target))
			PrintToChat(param1, "[Spray Trace] %T", "Could Not Find", param1);
		else
			GoSpray(param1, target);

		DisplayAdminSprayMenu(param1);
	}
	else
		CloseHandle(hMenu);
}

/*
Admin hMenu integration
*/

public OnAdminMenuReady(Handle:hTopMenu) {
	/* Block us from being called twice */
	if (hTopMenu == g_hTopMenu)
		return;

	/* Save the Handle */
	g_hTopMenu = hTopMenu;

	/* Find the "Server Commands" category */
	new TopMenuObject:tmoServerCommands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);

	AddToTopMenu(g_hTopMenu, "sm_spraytrace", TopMenuObject_Item, AdminMenu_TraceSpray, tmoServerCommands, "sm_spraytrace", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_removespray", TopMenuObject_Item, AdminMenu_SprayRemove, tmoServerCommands, "sm_removespray", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_adminspray", TopMenuObject_Item, AdminMenu_AdminSpray, tmoServerCommands, "sm_adminspray", ADMFLAG_BAN);
}

public AdminMenu_TraceSpray(Handle:hTopMenu, TopMenuAction:maAction, TopMenuObject:tmoObject, param, String:szBuffer[], iMaxLength) {
	if(!IsValidClient(param))
		return;

	if (maAction == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "Trace", param);
	else if (maAction == TopMenuAction_SelectOption)
		TraceSpray(param, 0);
}

public AdminMenu_SprayRemove(Handle:hTopMenu, TopMenuAction:maAction, TopMenuObject:tmoObject, param, String:szBuffer[], iMaxLength) {
	if(!IsValidClient(param))
		return;

	if (maAction == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "Remove", param);
	else if (maAction == TopMenuAction_SelectOption)
		RemoveSpray(param, 0);
}

public AdminMenu_AdminSpray(Handle:hTopMenu, TopMenuAction:maAction, TopMenuObject:tmoObject, param, String:szBuffer[], iMaxLength) {
	if(!IsValidClient(param))
		return;

	if (maAction == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "AdminSpray", param);
	else if (maAction == TopMenuAction_SelectOption)
		DisplayAdminSprayMenu(param);
}

/*
Admin punishment hMenu
*/

public Action:AdminMenu(client, sprayer) {
	if(!IsValidClient(client))
		return Plugin_Handled;

	new Handle:hMenu = CreateMenu(AdminMenuHandler);
	new String:szMenuItem[128];
	g_szMenuSprayerID[client] = g_szSprayerID[sprayer];

	SetMenuTitle(hMenu, "%T", "Title", client, g_szSprayerName[sprayer], g_szSprayerID[sprayer], RoundFloat(GetGameTime()) - g_SprayTime[sprayer]);
	
	Format(szMenuItem, 127, "%T", "Warn", client);
	AddMenuItem(hMenu, "warn", szMenuItem);

	Format(szMenuItem, 127, "%T", "Kick", client);
	AddMenuItem(hMenu, "kick", szMenuItem);

	if(GetConVarInt(g_hCVars[TBANTIME]) > 0) {
		Format(szMenuItem, 127, "%T", "Ban", client, GetConVarInt(g_hCVars[TBANTIME]));
		AddMenuItem(hMenu, "ban", szMenuItem);
	}

	if(GetConVarBool(g_hCVars[PBAN])) {
		Format(szMenuItem, 127, "%T", "PBan", client);
		AddMenuItem(hMenu, "pban", szMenuItem);
	}

	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public AdminMenuHandler(Handle:hMenu, MenuAction:maAction, client, iItem) {
	if(!IsValidClient(client))
		return;

	if ( maAction == MenuAction_Select ) {
		new String:szInfo[32];
		new String:szSprayerName[64];
		new String:szSprayerID[32];
		new String:szAdminName[64];
		new sprayer;

		szSprayerID = g_szMenuSprayerID[client];
		sprayer = GetClientFromAuthID(g_szMenuSprayerID[client]);
		szSprayerName = g_szSprayerName[sprayer];
		GetClientName(client, szAdminName, sizeof(szAdminName));
		GetMenuItem(hMenu, iItem, szInfo, sizeof(szInfo));

		if(IsValidClient(sprayer) ) {
			new AdminId:sprayerAdmin = GetUserAdmin(sprayer);
			new AdminId:clientAdmin = GetUserAdmin(client);
			
			if( ((sprayerAdmin != INVALID_ADMIN_ID) && (clientAdmin != INVALID_ADMIN_ID)) &&
				  GetConVarBool(g_hCVars[IMMUNITY]) && !CanAdminTarget(clientAdmin, sprayerAdmin) ) {
				PrintToChat(client, "\x04[Spray Trace] %T", "Admin Immune", client, szSprayerName, szSprayerName);
				LogAction(client, -1, "[Spray Trace] %T", "Admin Immune Log", LANG_SERVER, szAdminName, szSprayerName, szSprayerName);
			}
			else if ((strcmp(szInfo,"ban") == 0) || (strcmp(szInfo,"pban") == 0)) {
				new iBanTime = 0;
				new String:szBad[128];
				Format(szBad, 127, "%T", "Bad Spray Logo", LANG_SERVER);
	
				if(strcmp(szInfo,"ban") == 0)
					iBanTime = GetConVarInt(g_hCVars[TBANTIME]);
	
				g_hExternalBan = FindConVar("sb_version");
	
				//SourceBans integration
				if ( g_hExternalBan != INVALID_HANDLE ) {
					ClientCommand(client, "sm_ban #%d %d \"%s\"", GetClientUserId(sprayer), iBanTime, szBad);

					if(iBanTime == 0)
						LogAction(client, -1, "[Spray Trace] %T", "EPBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, "SourceBans");
					else
						LogAction(client, -1, "[Spray Trace] %T", "EBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iBanTime, "SourceBans");
	
					CloseHandle(g_hExternalBan);
				}
				else {
					g_hExternalBan = FindConVar("mysql_bans_version");
	
					//MySQL Bans integration
					if ( g_hExternalBan != INVALID_HANDLE ) {
						ClientCommand(client, "mysql_ban #%d %d \"%s\"", GetClientUserId(sprayer), iBanTime, szBad);
	
						if(iBanTime == 0)
							LogAction(client, -1, "[Spray Trace] %T", "EPBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, "MySQL Bans");
						else
							LogAction(client, -1, "[Spray Trace] %T", "EBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iBanTime, "MySQL Bans");
	
						CloseHandle(g_hExternalBan);
					}
					else {
						//Normal Ban
						BanClient(sprayer, iBanTime, BANFLAG_AUTHID, szBad, szBad);
	
						if(iBanTime == 0)
							LogAction(client, -1, "[Spray Trace] %T", "PBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
						else
							LogAction(client, -1, "[Spray Trace] %T", "Banned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iBanTime);
					}
				}

				if(iBanTime == 0)
					PrintToChatAll("\x03[Spray Trace] %T", "PBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				else
					PrintToChatAll("\x03[Spray Trace] %T", "Banned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iBanTime);
			}
			else if ( strcmp(szInfo,"warn") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Warned", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo,"kick") == 0 ) {
				KickClient(sprayer, "%T", "Bad Spray Logo", sprayer);
				PrintToChatAll("\x03[Spray Trace] %T", "Kicked", LANG_SERVER, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Kicked", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
			}
		}
		else {
			PrintToChat(client, "\x04[Spray Trace] %T", "Could Not Find Name ID", client, szSprayerName, szSprayerID);
			LogAction(client, -1, "[Spray Trace] %T", "Could Not Find Name ID", LANG_SERVER, szSprayerName, szSprayerID);
		}

		if(GetConVarBool(g_hCVars[AUTOREMOVE])) {
			new Float:vecEndPos[3];
			SprayDecal(sprayer, 0, vecEndPos);

			PrintToChat(client, "[Spray Trace] %T", "Spray Removed", client, szSprayerName, szSprayerID, szAdminName);
			LogAction(client, -1, "[Spray Trace] %T", "Spray Removed", LANG_SERVER, szSprayerName, szSprayerID, szAdminName);
		}
	}
	else if ( maAction == MenuAction_End )
		CloseHandle(hMenu);
}

/*
Helper Methods
*/

public GetClientFromAuthID(const String:szAuthID[]) {
	new String:szOtherAuthID[32];

	for(new client = 1; client <= GetMaxClients(); client++) {
		if(IsValidClient(client) && !IsFakeClient(client)) {
			GetClientAuthString(client, szOtherAuthID, 32);

			if ( strcmp(szOtherAuthID, szAuthID) == 0 )
				return client;
		}
	}
	return 0;
}

stock bool:GetPlayerEye(client, Float:vecPos[3]) {
	if(!IsValidClient(client))
		return false;

	new Float:vecAngles[3], Float:vecOrigin[3];

	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);

	new Handle:hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(hTrace)) {
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(vecPos, hTrace);
		CloseHandle(hTrace);

		return true;
	}

	CloseHandle(hTrace);

	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
 	return entity > MaxClients;
}

public GlowEffect(client, Float:vecPos[3], Float:flLife, Float:flSize, iBright, precacheModel) {
	if(!IsValidClient(client))
		return;

	new arrClients[1];

	arrClients[0] = client;

	TE_SetupGlowSprite(vecPos, precacheModel, flLife, flSize, iBright);
	TE_Send(arrClients, 1);
}

public SprayDecal(client, entIndex, Float:vecPos[3]) {
	if(!IsValidClient(client))
		return;

	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", vecPos);
	TE_WriteNum("m_nEntity", entIndex);
	TE_WriteNum("m_nPlayer", client);
	TE_SendToAll();
}

public bool:IsValidClient(client) {
	if(client <= 0)
		return false;
	if(client > MaxClients)
		return false;

	return IsClientInGame(client);
}