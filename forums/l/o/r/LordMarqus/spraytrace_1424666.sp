#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

//#define DEBUG

#define PLUGIN_VERSION "5.8.2"
#define MAXDIS 0
#define REFRESHRATE 1
#define TBANTIME 2
#define ADMINONLY 3
#define FULLHUD 4
#define FULLHUDADMIN 5
#define BURNTIME 6
#define SLAPDMG 7
#define USESLAY 8
#define USEBURN 9
#define USEPBAN 10
#define USEKICK 11
#define USEFREEZE 12
#define USEBEACON 13
#define USEFREEZEBOMB 14
#define USEFIREBOMB 15
#define USETIMEBOMB 16
#define DRUGTIME 17
#define AUTOREMOVE 18
#define RESTRICT 19
#define IMMUNITY 20
#define GLOBAL 21
#define USEHUD 22
#define HUDTIME 23
#define NUMCVARS 24

new Float:g_fSprayTrace[MAXPLAYERS + 1][3];
new String:g_sSprayName[MAXPLAYERS + 1][64];
new String:g_sSprayID[MAXPLAYERS + 1][32];
new String:g_sMenuSprayID[MAXPLAYERS + 1][32];
new g_iSprayTime[MAXPLAYERS + 1] = {0, ...};
new g_iSprayRounds[MAXPLAYERS + 1] = {-1, ...};

new Handle:g_hCvars[NUMCVARS];
new Handle:g_hSprayTimer = INVALID_HANDLE;
new Handle:g_hTopMenu;
new Handle:g_hExternalBan = INVALID_HANDLE;
new Handle:g_hHudMessage;
new bool:g_bCanHUD;
new g_iRedGlowIndex;

public Plugin:myinfo = 
{
	name = "Spray Tracer",
	author = "Nican132, CptMoore, Lebson506th, LordMarqus",
	description = "Traces sprays on the wall",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() 
{
	CreateConVar("sm_spray_version", PLUGIN_VERSION, "Spray tracer plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
 
	RegAdminCmd("sm_spraytrace", TestTrace, ADMFLAG_BAN, "Look up the owner of the logo in front of you.");
	RegAdminCmd("sm_removespray", RemoveSpray, ADMFLAG_BAN, "Remove the logo in front of you.");
	RegAdminCmd("sm_adminspray", AdminSpray, ADMFLAG_BAN, "Sprays the named player's logo in front of you.");

	g_hCvars[REFRESHRATE] = CreateConVar("sm_spray_refresh","1.0","How often the program will trace to see player's spray to the HUD. 0 to disable.");
	g_hCvars[MAXDIS] = CreateConVar("sm_spray_dista","50.0","How far away the spray will be traced to.");
	g_hCvars[TBANTIME] = CreateConVar("sm_spray_bantime","60","How long the temporary ban is for. 0 to disable temporary banning.");
	g_hCvars[ADMINONLY] = CreateConVar("sm_spray_adminonly","0","Changes showing the trace messages on HUD. 0 - Only admin can trace sprays 1 - All players can trace all sprays 2 - All players can trace all non-admin sprays.");
	g_hCvars[FULLHUD] = CreateConVar("sm_spray_fullhud","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins.");
	g_hCvars[FULLHUDADMIN] = CreateConVar("sm_spray_fullhudadmin","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to admins.");
	g_hCvars[BURNTIME] = CreateConVar("sm_spray_burntime","10","How long the burn punishment is for.");
	g_hCvars[SLAPDMG] = CreateConVar("sm_spray_slapdamage","5","How much damage the slap punishment is for. 0 to disable.");
	g_hCvars[USESLAY] = CreateConVar("sm_spray_enableslay","0","Enables the use of Slay as a punishment.");
	g_hCvars[USEBURN] = CreateConVar("sm_spray_enableburn","0","Enables the use of Burn as a punishment.");
	g_hCvars[USEPBAN] = CreateConVar("sm_spray_enablepban","1","Enables the use of a Permanent Ban as a punishment.");
	g_hCvars[USEKICK] = CreateConVar("sm_spray_enablekick","1","Enables the use of Kick as a punishment.");
	g_hCvars[USEBEACON] = CreateConVar("sm_spray_enablebeacon","0","Enables putting a beacon on the sprayer as a punishment.");
	g_hCvars[USEFREEZE] = CreateConVar("sm_spray_enablefreeze","0","Enables the use of Freeze as a punishment.");
	g_hCvars[USEFREEZEBOMB] = CreateConVar("sm_spray_enablefreezebomb","0","Enables the use of Freeze Bomb as a punishment.");
	g_hCvars[USEFIREBOMB] = CreateConVar("sm_spray_enablefirebomb","0","Enables the use of Fire Bomb as a punishment.");
	g_hCvars[USETIMEBOMB] = CreateConVar("sm_spray_enabletimebomb","0","Enables the use of Time Bomb as a punishment.");
	g_hCvars[DRUGTIME] = CreateConVar("sm_spray_drugtime","0","set the time a sprayer is drugged as a punishment. 0 to disable.");
	g_hCvars[AUTOREMOVE] = CreateConVar("sm_spray_autoremove","0","Enables automatically removing sprays when a punishment is dealt.");
	g_hCvars[RESTRICT] = CreateConVar("sm_spray_restrict","0","Enables or disables restricting admins with the \"ban\" flag's punishments. (1 = warn only, 0 = all)");
	g_hCvars[IMMUNITY] = CreateConVar("sm_spray_useimmunity","1","Enables or disables using admin immunity to determine if one admin can punish another.");
	g_hCvars[GLOBAL] = CreateConVar("sm_spray_global","1","Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");
	g_hCvars[USEHUD] = CreateConVar("sm_spray_usehud","1","Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.");
	g_hCvars[HUDTIME] = CreateConVar("sm_spray_hudtime","1.0","How long the HUD messages are displayed.");

	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	
	HookConVarChange(g_hCvars[REFRESHRATE], TimerChanged);

	AddTempEntHook("Player Decal", PlayerSpray);

	CreateTimers();

	g_hHudMessage = CreateHudSynchronizer();
	if (g_hHudMessage != INVALID_HANDLE)
	{
		g_bCanHUD = true;
		#if defined DEBUG
		PrintToServer("Can HUD");
		#endif
	}
	else
	{
		g_bCanHUD = false;
		#if defined DEBUG
		PrintToServer("Cannot HUD");
		#endif
	}
	
	LoadTranslations("spraytrace.phrases");
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "spraytrace");
}

/*
	Clears all stored sprays when the map changes.
	Also prechaches the model.
*/
public OnMapStart() 
{
	g_iRedGlowIndex = PrecacheModel("sprites/redglow1.vmt");

	for (new i = 1; i <= MaxClients; ++i)
		ClearVariables(i);
}

/*
	Clears all stored sprays for a disconnecting
	client if global spray tracing is disabled.
*/
public OnClientDisconnect(client)
{
	if (!GetConVarBool(g_hCvars[GLOBAL]))
		ClearVariables(client);
}

/*
	Clears the stored sprays for the given client.
*/
ClearVariables(client) 
{
	g_fSprayTrace[client][0] = 0.0;
	g_fSprayTrace[client][1] = 0.0;
	g_fSprayTrace[client][2] = 0.0;
	strcopy(g_sSprayName[client], sizeof(g_sSprayName[]), "");
	strcopy(g_sSprayID[client], sizeof(g_sSprayID[]), "");
	strcopy(g_sMenuSprayID[client], sizeof(g_sMenuSprayID[]), "");
	g_iSprayTime[client] = 0;
	g_iSprayRounds[client] = -1;
}

/*
	Check for sprays removed by the server.
*/
public EventRoundStart(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; ++i) 
	{
		if (g_iSprayRounds[i] >= 0)
		{
			++g_iSprayRounds[i];
			if (g_iSprayRounds[i] >= 2)
				ClearVariables(i);
		}
	}
}

/*
Records the location, name, ID, and time of all sprays
*/
public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");

	if (client && IsClientInGame(client)) 
	{
		TE_ReadVector("m_vecOrigin", g_fSprayTrace[client]);

		g_iSprayTime[client] = RoundFloat(GetGameTime());
		g_iSprayRounds[client] = 0;
		GetClientName(client, g_sSprayName[client], 64);
		GetClientAuthString(client, g_sSprayID[client], 32);
	}
}

/*
sm_spray_refresh handlers for tracing to HUD or hint message
*/
public TimerChanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	CreateTimers();
}

stock CreateTimers() 
{
	if (g_hSprayTimer != INVALID_HANDLE) 
	{
		KillTimer(g_hSprayTimer);
		g_hSprayTimer = INVALID_HANDLE;
	}

	new Float:timerInterval = GetConVarFloat(g_hCvars[REFRESHRATE]);

	if (timerInterval > 0.0)
		g_hSprayTimer = CreateTimer(timerInterval, CheckAllTraces, _, TIMER_REPEAT);	
}

/*
Handle tracing sprays to the HUD or hint message
*/
public Action:CheckAllTraces(Handle:timer, any:useless) 
{
	new Float:pos[3];
	new bool:hasChangedHud = false;
	
	new Float:maxDistance = GetConVarFloat(g_hCvars[MAXDIS]);
	new bool:useHud = GetConVarBool(g_hCvars[USEHUD]);
	new adminOnly = GetConVarInt(g_hCvars[ADMINONLY]);
	new Float:hudTime = GetConVarFloat(g_hCvars[HUDTIME]);
	new bool:fullHudAdmin = GetConVarBool(g_hCvars[FULLHUDADMIN]);
	new bool:fullHud = GetConVarBool(g_hCvars[FULLHUD]);

	for (new i = 1; i <= MaxClients; ++i) 
	{
		#if defined DEBUG
		new Float:startTime = GetEngineTime();
		#endif
		
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (GetPlayerEye(i, pos)) 
		{
			#if defined DEBUG
			PrintToChat(i, "Eye trace: %.1f %.1f %.1f", pos[0], pos[1], pos[2]);
			#endif
			for (new a = 1; a <= MaxClients; ++a) 
			{
				new Float:distance = GetVectorDistance(pos, g_fSprayTrace[a], true);
				if (distance <= maxDistance * maxDistance) 
				{
					#if defined DEBUG
					PrintToChat(i, "Found spray, distance: %f", distance);
					#endif
					
					new AdminId:admin = GetUserAdmin(i);

					if (!(adminOnly == 1) || (admin != INVALID_ADMIN_ID)) 
					{
						if (g_bCanHUD && useHud) 
						{
							if (!hasChangedHud)
							{
								hasChangedHud = true;
								SetHudTextParams(0.04, 0.6, hudTime, 255, 50, 50, 255);
							}

							if ((adminOnly != 2) || (admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID))) 
							{
								if (fullHud || (admin != INVALID_ADMIN_ID && fullHudAdmin))
									ShowSyncHudText(i, g_hHudMessage, "%t", "Sprayed", g_sSprayName[a], g_sSprayID[a]);
								else
									ShowSyncHudText(i, g_hHudMessage, "%t", "Sprayed Name", g_sSprayName[a]);
							}
						}
						else 
						{
							if ((adminOnly != 2) || (admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID))) 
							{
								if (fullHud || (admin != INVALID_ADMIN_ID && fullHudAdmin))
									PrintHintText(i, "%t", "Sprayed", g_sSprayName[a], g_sSprayID[a]);
								else
									PrintHintText(i, "%t", "Sprayed Name", g_sSprayName[a]);
							}
						}
					}

					break;
				}
			}
			#if defined DEBUG
			PrintToChat(i, "Operation time = %f", GetEngineTime() - startTime);
			#endif
		}
		else
		{
			#if defined DEBUG
			PrintToChat(i, "GetPlayerEye returned false");
			#endif
		}
	}
}

/*
Trace spray function
*/
public Action:TestTrace(client, args) 
{
	new Float:pos[3];

	if (GetPlayerEye(client, pos)) 
	{
	 	for (new i = 1; i<= MaxClients; i++) 
		{
			if (GetVectorDistance(pos, g_fSprayTrace[i]) <= GetConVarFloat(g_hCvars[MAXDIS])) 
			{
				new time = RoundFloat(GetGameTime()) - g_iSprayTime[i];

				PrintToChat(client, "[Spray Trace] %t", "Spray By", g_sSprayName[i], g_sSprayID[i], time);
				GlowEffect(client, g_fSprayTrace[i], 2.0, 0.3, 255, g_iRedGlowIndex);
				AdminMenu(client, i);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(client, "[Spray Trace] %t", "No Spray");

	return Plugin_Handled;
}

/*
Remove spray function
*/
public Action:RemoveSpray(client, args) 
{
	new Float:pos[3];

	if (GetPlayerEye(client, pos)) {
		new String:adminName[32];

		GetClientName(client, adminName, 31);

	 	for (new i = 1; i <= MaxClients; ++i) 
		{
			if (GetVectorDistance(pos, g_fSprayTrace[i]) <= GetConVarFloat(g_hCvars[MAXDIS])) 
			{
				new Float:vEndPos[3];

				PrintToChat(client, "[Spray Trace] %t", "Spray By", g_sSprayName[i], g_sSprayID[i], RoundFloat(GetGameTime()) - g_iSprayTime[i]);

				SprayDecal(i, 0, vEndPos);

				ClearVariables(i);

				PrintToChat(client, "[Spray Trace] %t", "Spray Removed", g_sSprayName[i], g_sSprayID[i], adminName);
				LogAction(client, -1, "[Spray Trace] %t", "Spray Removed", g_sSprayName[i], g_sSprayID[i], adminName);
				AdminMenu(client, i);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(client, "[Spray Trace] %t", "No Spray");

	return Plugin_Handled;
}

/*
Admin spray functions
*/
public Action:AdminSpray(client, args) 
{
	new target;

	if (args == 1) 
	{
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		target = FindTarget(client, arg, false, false);

		if (!target) 
		{
			ReplyToCommand(client, "[Spray Trace] %t", "Could Not Find Name", arg);
			return Plugin_Handled;
		}
	}
	else
		target = client;

	GoSpray(client, target);

	return Plugin_Handled;
}

public GoSpray(client, target) 
{
	new Float:vEndPos[3];

	if (GetPlayerEye(client, vEndPos) && IsClientInGame(client) && IsClientInGame(target)) 
	{
		new String:targetName[32];
		new String:adminName[32];
		new traceEntIndex = TR_GetEntityIndex();

		GetClientName(target, targetName, 31);
		GetClientName(client, adminName, 31);

		SprayDecal(target, traceEntIndex, vEndPos);
		EmitSoundToAll("misc/sprayer.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);

		PrintToChat(client, "\x04[Spray Trace] %t", "Admin Sprayed", adminName, targetName);
		LogAction(client, -1, "[Spray Trace] %t", "Admin Sprayed", adminName, targetName);
	}
	else
		PrintToChat(client, "\x04[Spray Trace] %t", "Cannot Spray");
} 

/*
Admin Spray menu
*/
DisplayAdminSprayMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_AdminSpray);

	SetMenuTitle(menu, "%t", "Admin Spray Menu");
	SetMenuExitBackButton(menu, true);

	AddTargetsToMenu(menu, client, true, false);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminSpray(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select) {
		decl String:info[32];
		new target;

		GetMenuItem(menu, param2, info, sizeof(info));

		target = GetClientOfUserId(StringToInt(info))

		if (target == 0 || !IsClientInGame(target))
			PrintToChat(param1, "[Spray Trace] %t", "Could Not Find");
		else
			GoSpray(param1, target);

		DisplayAdminSprayMenu(param1);
	}
	else
		CloseHandle(menu);
}

/*
Admin menu integration
*/

public OnAdminMenuReady(Handle:topmenu) {
	/* Block us from being called twice */
	if (topmenu == g_hTopMenu)
		return;

	/* Save the Handle */
	g_hTopMenu = topmenu;

	/* Find the "Server Commands" category */
	new TopMenuObject:server_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	AddToTopMenu(g_hTopMenu, "sm_spraytrace", TopMenuObject_Item, AdminMenu_TraceSpray, server_commands, "sm_spraytrace", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_removespray", TopMenuObject_Item, AdminMenu_SprayRemove, server_commands, "sm_removespray", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_adminspray", TopMenuObject_Item, AdminMenu_AdminSpray, server_commands, "sm_adminspray", ADMFLAG_BAN);
}

public AdminMenu_TraceSpray(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%t", "Trace");
	else if (action == TopMenuAction_SelectOption)
		TestTrace(param, 0);
}

public AdminMenu_SprayRemove(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%t", "Remove");
	else if (action == TopMenuAction_SelectOption)
		RemoveSpray(param, 0);
}

public AdminMenu_AdminSpray(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%t", "AdminSpray");
	else if (action == TopMenuAction_SelectOption)
		DisplayAdminSprayMenu(param);
}

/*
Admin punishment menu
*/

public Action:AdminMenu(clientId, sprayerId) {
	g_sMenuSprayID[clientId] = g_sSprayID[sprayerId];

	new Handle:menu = CreateMenu(AdminMenuHandler);

	SetMenuTitle(menu, "%t", "Title", g_sSprayName[sprayerId], g_sSprayID[sprayerId], RoundFloat(GetGameTime()) - g_iSprayTime[sprayerId]);

	new String:warn[128];
	Format(warn, 127, "%t", "Warn");
	AddMenuItem(menu, "warn", warn);

	if (!GetConVarBool(g_hCvars[RESTRICT]) || GetAdminFlag(GetUserAdmin(clientId), Admin_Ban)) {
		if (GetConVarInt(g_hCvars[SLAPDMG]) > 0) {
			new String:slap[128];
			Format(slap, 127, "%t", "SlapWarn", GetConVarInt(g_hCvars[SLAPDMG]));
			AddMenuItem(menu, "slap", slap);
		}

		if (GetConVarBool(g_hCvars[USESLAY])) {
			new String:slay[128];
			Format(slay, 127, "%t", "Slay");
			AddMenuItem(menu, "slay", slay);
		}

		if (GetConVarBool(g_hCvars[USEBURN])) {
			new String:burn[128];
			Format(burn, 127, "%t", "BurnWarn", GetConVarInt(g_hCvars[BURNTIME]));
			AddMenuItem(menu, "burn", burn);
		}

		if (GetConVarBool(g_hCvars[USEFREEZE])) {
			new String:freeze[128];
			Format(freeze, 127, "%t", "Freeze");
			AddMenuItem(menu, "freeze", freeze);
		}

		if (GetConVarBool(g_hCvars[USEBEACON])) {
			new String:beacon[128];
			Format(beacon, 127, "%t", "Beacon");
			AddMenuItem(menu, "beacon", beacon);
		}

		if (GetConVarBool(g_hCvars[USEFREEZEBOMB])) {
			new String:freezebomb[128];
			Format(freezebomb, 127, "%t", "FreezeBomb");
			AddMenuItem(menu, "freezebomb", freezebomb);
		}

		if (GetConVarBool(g_hCvars[USEFIREBOMB])) {
			new String:firebomb[128];
			Format(firebomb, 127, "%t", "FireBomb");
			AddMenuItem(menu, "firebomb", firebomb);
		}

		if (GetConVarBool(g_hCvars[USETIMEBOMB])) {
			new String:timebomb[128];
			Format(timebomb, 127, "%t", "TimeBomb");
			AddMenuItem(menu, "timebomb", timebomb);
		}

		if (GetConVarInt(g_hCvars[DRUGTIME]) > 0) {
			new String:Drug[128];
			Format(Drug, 127, "%t", "Drug");
			AddMenuItem(menu, "Drug", Drug);
		}

		if (GetConVarBool(g_hCvars[USEKICK])) {
			new String:kick[128];
			Format(kick, 127, "%t", "Kick");
			AddMenuItem(menu, "kick", kick);
		}

		if (GetConVarInt(g_hCvars[TBANTIME]) > 0) {
			new String:ban[128];
			Format(ban, 127, "%t", "Ban", GetConVarInt(g_hCvars[TBANTIME]));
			AddMenuItem(menu, "ban", ban);
		}

		if (GetConVarBool(g_hCvars[USEPBAN])) {
			new String:pban[128];
			Format(pban, 127, "%t", "PBan");
			AddMenuItem(menu, "pban", pban);
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public AdminMenuHandler(Handle:menu, MenuAction:action, client, itemNum) {
	if ( action == MenuAction_Select ) {
		new String:info[32];
		new String:sprayerName[64];
		new String:sprayerID[32];
		new String:adminName[64];
		new sprayer;

		sprayerID = g_sMenuSprayID[client];
		sprayer = GetClientFromAuthID(g_sMenuSprayID[client]);
		sprayerName = g_sSprayName[sprayer];
		GetClientName(client, adminName, sizeof(adminName));
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if ((strcmp(info,"ban") == 0) || (strcmp(info,"pban") == 0)) {
			if (sprayer) {
				new time = 0;
				new String:bad[128];
				Format(bad, 127, "%t", "Bad Spray Logo");
	
				if (strcmp(info,"ban") == 0)
					time = GetConVarInt(g_hCvars[TBANTIME]);
	
				g_hExternalBan = FindConVar("sb_version");
	
				//SourceBans integration
				if ( g_hExternalBan != INVALID_HANDLE ) {
					ClientCommand(client, "sm_ban #%d %d \"%s\"", GetClientUserId(sprayer), time, bad);

					if (time == 0)
						LogAction(client, -1, "[Spray Trace] %t", "EPBanned", adminName, sprayerName, sprayerID, "SourceBans");
					else
						LogAction(client, -1, "[Spray Trace] %t", "EBanned", adminName, sprayerName, sprayerID, time, "SourceBans");
	
					CloseHandle(g_hExternalBan);
				}
				else {
					g_hExternalBan = FindConVar("mysql_bans_version");
	
					//MySQL Bans integration
					if ( g_hExternalBan != INVALID_HANDLE ) {
						ClientCommand(client, "mysql_ban #%d %d \"%s\"", GetClientUserId(sprayer), time, bad);
	
						if (time == 0)
							LogAction(client, -1, "[Spray Trace] %t", "EPBanned", adminName, sprayerName, sprayerID, "MySQL Bans");
						else
							LogAction(client, -1, "[Spray Trace] %t", "EBanned", adminName, sprayerName, sprayerID, time, "MySQL Bans");
	
						CloseHandle(g_hExternalBan);
					}
					else {
						//Normal Ban
						BanClient(sprayer, time, BANFLAG_AUTHID, bad, bad);
	
						if (time == 0)
							LogAction(client, -1, "[Spray Trace] %t", "PBanned", adminName, sprayerName, sprayerID);
						else
							LogAction(client, -1, "[Spray Trace] %t", "Banned", adminName, sprayerName, sprayerID, time);
					}
				}

				if (time == 0)
					PrintToChatAll("\x03[Spray Trace] %t", "PBanned", adminName, sprayerName, sprayerID);
				else
					PrintToChatAll("\x03[Spray Trace] %t", "Banned", adminName, sprayerName, sprayerID, time);
			}
			else {
				PrintToChat(client, "\x04[Spray Trace] %t", "Could Not Find Name ID", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Could Not Find Name ID", sprayerName, sprayerID);
			}
		}
		else if ( sprayer && IsClientInGame(sprayer) ) {
			new AdminId:sprayerAdmin = GetUserAdmin(sprayer);
			new AdminId:clientAdmin = GetUserAdmin(client);

			if ( ((sprayerAdmin != INVALID_ADMIN_ID) && (clientAdmin != INVALID_ADMIN_ID)) && GetConVarBool(g_hCvars[IMMUNITY]) && !CanAdminTarget(clientAdmin, sprayerAdmin) ) {
				PrintToChat(client, "\x04[Spray Trace] %t", "Admin Immune", sprayerName);
				LogAction(client, -1, "[Spray Trace] %t", "Admin Immune Log", adminName, sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info,"warn") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "Warned", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log Warned", adminName, sprayerName, sprayerID);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info,"slap") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "Slapped And Warned", sprayerName, sprayerID, GetConVarInt(g_hCvars[SLAPDMG]));
				LogAction(client, -1, "[Spray Trace] %t", "Log Slapped And Warned", adminName, sprayerName, sprayerID, GetConVarInt(g_hCvars[SLAPDMG]));
				SlapPlayer(sprayer, GetConVarInt(g_hCvars[SLAPDMG]));
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info,"slay") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "Slayed And Warned", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log Slayed And Warned", adminName, sprayerName, sprayerID);
				ClientCommand(client, "sm_slay \"%s\"", sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info,"burn") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "Burnt And Warned", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log Burnt And Warned", adminName, sprayerName, sprayerID);
				ClientCommand(client, "sm_burn \"%s\" %d", sprayerName, GetConVarInt(g_hCvars[BURNTIME]));
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info, "freeze", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "Froze", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log Froze", adminName, sprayerName, sprayerID);
				ClientCommand(client, "sm_freeze \"%s\"", sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info, "beacon", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "Beaconed", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log Beaconed", adminName, sprayerName, sprayerID);
				ClientCommand(client, "sm_beacon \"%s\"", sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info, "freezebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "FreezeBombed", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log FreezeBombed", adminName, sprayerName, sprayerID);
				ClientCommand(client, "sm_freezebomb \"%s\"", sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info, "firebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "FireBombed", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log FireBombed", adminName, sprayerName, sprayerID);
				ClientCommand(client, "sm_firebomb \"%s\"", sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info, "timebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "TimeBombed", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log TimeBombed", adminName, sprayerName, sprayerID);
				ClientCommand(client, "sm_timebomb \"%s\"", sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info, "drug", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %t", "Please change");
				PrintToChat(client, "\x04[Spray Trace] %t", "Drugged", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log Drugged", adminName, sprayerName, sprayerID);
				CreateTimer(GetConVarFloat(g_hCvars[DRUGTIME]), Undrug, sprayer, TIMER_FLAG_NO_MAPCHANGE);
				ClientCommand(client, "sm_drug \"%s\"", sprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(info,"kick") == 0 ) {
				KickClient(sprayer, "%t", "Bad Spray Logo");
				PrintToChatAll("\x03[Spray Trace] %t", "Kicked", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Log Kicked", adminName, sprayerName, sprayerID);
			}
		}
		else {
			PrintToChat(client, "\x04[Spray Trace] %t", "Could Not Find Name ID", sprayerName, sprayerID);
			LogAction(client, -1, "[Spray Trace] %t", "Could Not Find Name ID", sprayerName, sprayerID);
		}

		if (GetConVarBool(g_hCvars[AUTOREMOVE])) {
			new Float:vEndPos[3];
			SprayDecal(sprayer, 0, vEndPos);

			PrintToChat(client, "[Spray Trace] %t", "Spray Removed", sprayerName, sprayerID, adminName);
			LogAction(client, -1, "[Spray Trace] %t", "Spray Removed", sprayerName, sprayerID, adminName);
		}
	}
	else if ( action == MenuAction_End )
		CloseHandle(menu);
}

/*
Helper Methods
*/
public GetClientFromAuthID(const String:authid[]) 
{
	new String:tmpAuthID[32];
	for ( new i = 1; i <= GetMaxClients(); ++i) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i) ) 
		{
			GetClientAuthString(i, tmpAuthID, 32);

			if ( strcmp(tmpAuthID, authid) == 0 )
				return i;
		}
	}
	return 0;
}

stock bool:GetPlayerEye(client, Float:pos[3]) 
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace)) 
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}

	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
 	return entity > MaxClients;
}

public GlowEffect(client, Float:pos[3], Float:life, Float:size, bright, model) 
{
	new clients[1];
	clients[0] = client;
	TE_SetupGlowSprite(pos, model, life, size, bright);
	TE_Send(clients, 1);
}

public SprayDecal(client, entIndex, Float:pos[3])
{
	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nEntity", entIndex);
	TE_WriteNum("m_nPlayer", client);
	TE_SendToAll();
}

/*
	Undrug handler to undrug a player after sm_spray_drugtime
*/
public Action:Undrug(Handle:timer, any:client) 
{
	if (client && IsClientInGame(client)) 
	{
		new String:clientName[32];
		GetClientName(client, clientName, 31);

		ServerCommand("sm_undrug \"%s\"", clientName);
	}

	return Plugin_Handled;
}