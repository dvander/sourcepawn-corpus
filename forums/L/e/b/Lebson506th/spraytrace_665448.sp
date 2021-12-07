/*
*	Spray Trace
*
*	Originally by Nican
*	Punishment menu added by mbalex (Aka Cpt.Moore)
*	Both versions combined by Lebson506th
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
*	The punishments including a text warning, a warning and a slap, a warning and burning the player,
*	a warning and slaying the player, kick, temporary ban, or permanent ban.
*
*	Usage
*	-----
*
*	sm_spray_dista (default: 50.0) - maximum distance the plugin will trace the spray
*	sm_spray_refresh (default: 1.0) - How often sprays will be traced to show on HUD - 0.0 to disable feature
*	sm_spray_bantime (default: 60) - How long the temporary ban is for - 0 to disable temporary banning
*	sm_spray_burntime (default: 10) - How long the burn punishment is for.
*	sm_spray_slapdamage (default: 5) - How much damage the slap punishment is for. 0 to disable
*	sm_spray_adminonly (default: 0) - Changes showing the trace messages on HUD. 0 - Only admin can trace sprays 1 - All players can trace all sprays 2 - All players can trace all non-admin sprays.
*	sm_spray_fullhud (default: 0) - Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins
*	sm_spray_fullhudadmin (default: 1) - Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to admins
*	sm_spray_enableslay (default: 0) - Enables (1) or disables (0) the use of Slay as a punishment.
*	sm_spray_enableburn (default: 0) - Enables (1) or disables (0) the use of Burn as a punishment.
*	sm_spray_enablepban (default: 1) - Enables (1) or disables (0) the use of a Permanent Ban as a punishment.
*	sm_spray_enablekick (default: 1) - Enables (1) or disables (0) the use of Kick as a punishment.
*	sm_spray_enablebeacon (default: 0) - Enables putting a beacon on the sprayer as a punishment.
*	sm_spray_enablefreeze (default: 0) - Enables the use of Freeze as a punishment.
*	sm_spray_enablefreezebomb (default: 0) - Enables the use of Freeze Bomb as a punishment.
*	sm_spray_enablefirebomb (default: 0) - Enables the use of Fire Bomb as a punishment.
*	sm_spray_enabletimebomb (default: 0) - Enables the use of Time Bomb as a punishment.
*	sm_spray_drugtime (default: 0) - set the time a sprayer is drugged as a punishment. 0 to disable.
*	sm_spray_restrict (default: 0) - Enables (1) or disables (0) restricting admins with the "ban" flag's punishments. (1 = warn only, 0 = all)
*	sm_spray_autoremove (default: 0) - Enables automatically removing sprays when a punishment is dealt.
*	sm_spray_useimmunity (default: 1) - Enables or disables using admin immunity to determine if one admin can punish another.
*	sm_spray_global (default: 1) - Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.
*	sm_spray_usehud (default: 1) - Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.
*	sm_spray_hudtime (default: 1.0) - How long the HUD messages are displayed.
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
*	To Do
*	----------
*
*	- Get translated into more languages
*	- Wait for TempEnts to work with Insurgency.
*
*	Change Log
*	----------
*
*	5/1/2011 - v5.8a
*	- Fixed translations acting weirdly
*	- Refactored the code
*	- Added additional protection against various errors
*	- Removed unused translations
*
*	4/12/2009 - v5.8
*	- Minor code and comment changes.
*	- Removed HUD support for DoD:S after testing revealed that it is not supported.
*	- Added common language translations to fix a rare translation not found error.
*	- Added CVAR "sm_spray_global" to enable/disable global spray tracing. If this is on, sprays can still be tracked when a player leaves the server.
*	- Added CVAR "sm_spray_usehud" to enable/disable using the HUD to trace sprays. If this is disabled, or the game is not supported, the hint text will be used instead.
*	- Added CVAR "sm_spray_hudtime" to change how long the HUD messages are displayed.
*	- Added variable clearing to prevent the "ghost" effect on map change.
*	- Added L4D HUD support.
*
*	2/27/2009 - v5.7
*	- Added new setting for sm_spray_adminonly. If this is set to 2, players can trace other player's sprays on the HUD, but cannot trace admin's sprays.
*	- Fixed red glow precaching twice.
*	- Changed the code to clean it up a little bit.
*	- Changed code to use MaxClients that was introduced in 1.1.
*
*	11/29/2008 - v5.6a
*	- Reverted my "fix" for L4D. HUD still works on L4D though.
*	- Changed banning to ban via the admin who is punishing rather than by the server. (This creates more accurate logs and has the correct user for bans via SourceBnas)
*
*	11/27/2008 - v5.6
*	- Added HUD support for Left4Dead.
*	- Fixed a small bug where part of the spray location wasn't being reset on map change.
*	- Fixed spray locations not being reset after a spray was removed.
*
*	11/10/2008 - v5.5a
*	- Fixed a very small bug that caused error messages in rare situations.
*
*	10/26/2008 - v5.5
*	- Changed version CVAR to not be added to the auto-created config.
*	- Changed SourceBans method to not use the include file, meaning the forum can now compile this plugin again.
*	- Added the ability for admins with greater immunity to not be punished by lesser admins. *UPDATE TRANSLATIONS*
*	- Added sm_spray_useimmunity to control this new behavior.
*	- Moved around some code to reduce redundancy.
*
*	9/8/2008 - v5.4a
*	- Fixed sm_spray_restrict not working.
*
*	9/8/2008 - v5.4
*	- Changed plugin to auto generate a config file in cfg/sourcemod
*	- Added the option to automatically remove a spray when a punishment is dealt using sm_spray_autoremove
*	- Added freeze, firebomb, freezebomb, timebomb, beacon, and drug as punishments.
*	- Added CVARs to control these new punishments.
*	- Removed "sm_spray_enableslap". Setting sm_spray_slapdamage to 0 will disable this punishment now.
*	- Changed translations to reflect the new punishments.
*
*	8/29/2008 - v5.3e
*	- Added sm_spray_restrict to restrict which commands an admin can use. (If admin has the "ban" flag, they can use all commands. Otherwise it is just the "warn")
*
*	8/21/2008 - v5.3d
*	- Fixed problem with burn not working.
*
*	8/21/2008 - v5.3c
*	- Fixed a bug that would cause the punishment menu to not work when burn was enabled.
*
*	8/21/2008 - v5.3b
*	- Fixed two redundant translations.
*	- Added CVARs to enable or disable permanent bans and kicks.
*	- Added a CVAR that toggles showing sprayer's name and Steam ID or just sprayer's name on the HUD to admins
*
*	8/20/2008 - v5.3a
*	- Fixed a bug where the client = 0.
*	- Fixed a bug where i forgot to change something for the new logging.
*	- Changed some translations to show admin name for logging purposes.
*
*	8/19/2008 - v5.3
*	- Added a CVAR to enable or disable the slap punishment.
*	- Added burn and slay to the list of punishments and added CVARs to enable or disable them.
*	- Added a CVAR to change how long the sprayer is burnt for.
*	- Added a CVAR to change how much damage the slap causes.
*	- Updated logging to log the admin's name.
*	- Updated translations for new features.
*
*	8/19/2008 - v5.2b
*	- Added HUD support for Obsidian Conflict
*
*	8/10/2008 - v5.2a
*	- Fixed a rare bug where the client was not connected.
*
*	8/9/2008 - v5.2
*	- Added sm_spray_fullhud cvar. Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins
*	- Change SourceBans integration to use it's Native function. Thanks to the suggestion from Pyrocon.
*	- Fixed a bug where client wasn't being kicked after being banned.
*	- Fixed a bug where the sm_spray_bantime cvar wasn't doing anything.
*
*	8/8/2008 - v5.1c
*	- Fixed bug with MySQL Bans and SourceBans thanks to Procyon and DJ Tsunami (Really this time).
*	- Fixed bug where the client would not be banned correctly because they had already been kicked.
*
*	8/8/2008 - v5.1b
*	- Fixed bug with MySQL Bans and SourceBans thanks to Procyon and DJ Tsunami
*
*	8/7/2008 - v5.1a
*	- Fixed a bug when the client was not connected
*	- Made the menu of names re-display after an admin spray has been performed.
*	- Added sm_spray_adminonly that toggles showing the trace messages to admins only (1) or all players (0).
*
*	8/7/2008 - v5.1
*	- Added sm_adminspray command. Sprays any player's spray in front of you.
*	- Modified translations a bit, adding new ones for the new command.
*	- Added new command to the menu including a player list.
*
*	8/7/2008 - v5.0
*	- Re-added glow effect to show which spray is being traced.
*	- Added "Could Not Kick" translation for when a player leaves before they can be kicked.
*	- Removed unused translations.
*	- Fixed some potential bugs when the sprayer leaves before his punishment can be dealt.
*	- Changed logging to show amount of a time a player is banned for.
*	- Added "sm_removespray" command that removes the spray in front of you. Thanks to berni for the actual remove spray code.
*	- Added translations for the new command.
*	- Added new command to the admin menu.
*	- Changed the admin menu to show to admins that have the Ban flag instead of the slay flag. (Console commands were already set to ban)
*
*	8/3/2008 - v4.9a
*	- Changed logging to show which kind of ban it is.
*
*	8/3/2008 - v4.9
*	- Reorganized things in to a more efficient way of managing the menu.
*	- Added sm_spray_bantime that allows admins to change the length of the temporary ban. 0 disables temporary banning.
*	- Changed some translations that were supposed to show the player's name but did.
*	  They now show the player's name and their Steam ID.
*	- Added MySQL Bans integration
*	- Added logging information that will hopefully help to fix the SourceBans integration.
*
*	8/2/2008 - v4.8
*	- Added [Spray Trace] tag to displayed messages to show where the messages are coming from.
*	- Re-did translations in a better way using a lot less variables.
*
*	8/1/2008 - v4.7
*	- Fixed SourceBans support. (failed)
*	- Added header comment and changelog to source file.
*
*	7/31/2008 - v4.6
*	- Fixed missing translation for ban reason.
*	- Fixed error in translation usage for "Could Not find player: whatever".
*	- (Hopefully) Implemented SourceBans support. (failed)
*
*	7/30/2008 - v4.5
*	- Fixed client-side crashing issue by removing beam effects.
*	- Removed all variables and functions dependant on beam effects.
*	  including Locate Sprays which caused major crashes.
*	- Added more missing translations.
*
*	7/30/2008 - v4.3
*	- Added missing translations.
*	- Attempted to fix client-side errors (failed).
*
*	7/30/2008 - v4.2
*	- Added translations for many phrases.
*
*	7/21/2008 - v4.1 - First fix by Lebson506th, all previous by Nican
*	- Combined Nican's v3.1 Spray Tracer with Cpt.Moore's modifcations.
*
*	3/8/2008 - v3.1
*	- Added HUD showing.
*	- Added to Admin Menu.
*	- Fixed not tracking on floor.
*
*	11/9/2007 - v2.1
*	- Fixed error of the tracer only tracing the player it self.
*
*	8/29/2007 - v1.1
*	- Removed need for Hacks ext.
*	- Fixed player view tracing.
*
*	8/29/2007 - v1.0
*	- Initial release.
*/

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "5.8a"
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
#define	USEFREEZE 12
#define USEBEACON 13
#define	USEFREEZEBOMB 14
#define	USEFIREBOMB 15
#define	USETIMEBOMB 16
#define	DRUGTIME 17
#define AUTOREMOVE 18
#define RESTRICT 19
#define IMMUNITY 20
#define GLOBAL 21
#define USEHUD 22
#define HUDTIME 23
#define NUMCVARS 24

//Nican: I am doing all this global for those "happy" people who spray something and quit the server
new Float:g_arrSprayTrace[MAXPLAYERS + 1][3];
new String:g_arrSprayName[MAXPLAYERS + 1][64];
new String:g_arrSprayID[MAXPLAYERS + 1][32];
new String:g_arrMenuSprayID[MAXPLAYERS + 1][32];
new g_arrSprayTime[MAXPLAYERS + 1];

// Misc. globals
new Handle:g_arrCVars[NUMCVARS];
new Handle:g_hSprayTimer = INVALID_HANDLE;
new Handle:g_hTopMenu;
new Handle:g_hExternalBan = INVALID_HANDLE;
new Handle:g_hHUDMessage;
new bool:g_bCanUseHUD;
new g_PrecacheRedGlow;

public Plugin:myinfo = 
{
	name = "Spray Tracer",
	author = "Nican132, CptMoore, Lebson506th",
	description = "Traces sprays on the wall",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	LoadTranslations("spraytrace.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_spray_version", PLUGIN_VERSION, "Spray tracer plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
 
	RegAdminCmd("sm_spraytrace", TestTrace, ADMFLAG_BAN, "Look up the owner of the logo in front of you.");
	RegAdminCmd("sm_removespray", RemoveSpray, ADMFLAG_BAN, "Remove the logo in front of you.");
	RegAdminCmd("sm_adminspray", AdminSpray, ADMFLAG_BAN, "Sprays the named player's logo in front of you.");

	g_arrCVars[REFRESHRATE] = CreateConVar("sm_spray_refresh","1.0","How often the program will trace to see player's spray to the HUD. 0 to disable.");
	g_arrCVars[MAXDIS] = CreateConVar("sm_spray_dista","50.0","How far away the spray will be traced to.");
	g_arrCVars[TBANTIME] = CreateConVar("sm_spray_bantime","60","How long the temporary ban is for. 0 to disable temporary banning.");
	g_arrCVars[ADMINONLY] = CreateConVar("sm_spray_adminonly","0","Changes showing the trace messages on HUD. 0 - Only admin can trace sprays 1 - All players can trace all sprays 2 - All players can trace all non-admin sprays.");
	g_arrCVars[FULLHUD] = CreateConVar("sm_spray_fullhud","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins.");
	g_arrCVars[FULLHUDADMIN] = CreateConVar("sm_spray_fullhudadmin","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to admins.");
	g_arrCVars[BURNTIME] = CreateConVar("sm_spray_burntime","10","How long the burn punishment is for.");
	g_arrCVars[SLAPDMG] = CreateConVar("sm_spray_slapdamage","5","How much damage the slap punishment is for. 0 to disable.");
	g_arrCVars[USESLAY] = CreateConVar("sm_spray_enableslay","0","Enables the use of Slay as a punishment.");
	g_arrCVars[USEBURN] = CreateConVar("sm_spray_enableburn","0","Enables the use of Burn as a punishment.");
	g_arrCVars[USEPBAN] = CreateConVar("sm_spray_enablepban","1","Enables the use of a Permanent Ban as a punishment.");
	g_arrCVars[USEKICK] = CreateConVar("sm_spray_enablekick","1","Enables the use of Kick as a punishment.");
	g_arrCVars[USEBEACON] = CreateConVar("sm_spray_enablebeacon","0","Enables putting a beacon on the sprayer as a punishment.");
	g_arrCVars[USEFREEZE] = CreateConVar("sm_spray_enablefreeze","0","Enables the use of Freeze as a punishment.");
	g_arrCVars[USEFREEZEBOMB] = CreateConVar("sm_spray_enablefreezebomb","0","Enables the use of Freeze Bomb as a punishment.");
	g_arrCVars[USEFIREBOMB] = CreateConVar("sm_spray_enablefirebomb","0","Enables the use of Fire Bomb as a punishment.");
	g_arrCVars[USETIMEBOMB] = CreateConVar("sm_spray_enabletimebomb","0","Enables the use of Time Bomb as a punishment.");
	g_arrCVars[DRUGTIME] = CreateConVar("sm_spray_drugtime","0","set the time a sprayer is drugged as a punishment. 0 to disable.");
	g_arrCVars[AUTOREMOVE] = CreateConVar("sm_spray_autoremove","0","Enables automatically removing sprays when a punishment is dealt.");
	g_arrCVars[RESTRICT] = CreateConVar("sm_spray_restrict","0","Enables or disables restricting admins with the \"ban\" flag's punishments. (1 = warn only, 0 = all)");
	g_arrCVars[IMMUNITY] = CreateConVar("sm_spray_useimmunity","1","Enables or disables using admin immunity to determine if one admin can punish another.");
	g_arrCVars[GLOBAL] = CreateConVar("sm_spray_global","1","Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");
	g_arrCVars[USEHUD] = CreateConVar("sm_spray_usehud","1","Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.");
	g_arrCVars[HUDTIME] = CreateConVar("sm_spray_hudtime","1.0","How long the HUD messages are displayed.");

	HookConVarChange(g_arrCVars[REFRESHRATE], TimerChanged);

	AddTempEntHook("Player Decal",PlayerSpray);

	CreateTimers();

	new String:gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));

	g_bCanUseHUD = StrEqual(gamename,"tf",false) || StrEqual(gamename,"hl2mp",false) || StrEqual(gamename,"sourceforts",false) || StrEqual(gamename,"obsidian",false) || StrEqual(gamename,"left4dead",false) || StrEqual(gamename,"l4d",false);
	if(g_bCanUseHUD)
		g_hHUDMessage = CreateHudSynchronizer();

	AutoExecConfig(true, "plugin.spraytrace");
}

/*
	Clears all stored sprays when the map changes.
	Also prechaches the model.
*/

public OnMapStart() {
	g_PrecacheRedGlow = PrecacheModel("sprites/redglow1.vmt");

	for(new i = 1; i <= MaxClients; i++)
		ClearVariables(i);
}

/*
	Clears all stored sprays for a disconnecting
	client if global spray tracing is disabled.
*/

public OnClientDisconnect(client) {
	if(!GetConVarBool(g_arrCVars[GLOBAL]))
		ClearVariables(client);
}

/*
	Clears the stored sprays for the given client.
*/

public ClearVariables(client) {
	g_arrSprayTrace[client][0] = 0.0;
	g_arrSprayTrace[client][1] = 0.0;
	g_arrSprayTrace[client][2] = 0.0;
	strcopy(g_arrSprayName[client], sizeof(g_arrSprayName[]), "");
	strcopy(g_arrSprayID[client], sizeof(g_arrSprayID[]), "");
	strcopy(g_arrMenuSprayID[client], sizeof(g_arrMenuSprayID[]), "");
	g_arrSprayTime[client] = 0;
}

/*
Records the location, name, ID, and time of all sprays
*/

public Action:PlayerSpray(const String:szTempEntName[], const arrClients[], iClientCount, Float:flDelay) {
	new client = TE_ReadNum("m_nPlayer");

	if(IsValidClient(client)) {
		TE_ReadVector("m_vecOrigin", g_arrSprayTrace[client]);

		g_arrSprayTime[client] = RoundFloat(GetGameTime());
		GetClientName(client, g_arrSprayName[client], 64);
		GetClientAuthString(client, g_arrSprayID[client], 32);
	}
}

/*
sm_spray_refresh handlers for tracing to HUD or hint message
*/

public TimerChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[]) {
	CreateTimers();
}

stock CreateTimers() {
	if(g_hSprayTimer != INVALID_HANDLE) {
		KillTimer( g_hSprayTimer );
		g_hSprayTimer = INVALID_HANDLE;
	}

	new Float:timer = GetConVarFloat( g_arrCVars[REFRESHRATE] );

	if( timer > 0.0 )
		g_hSprayTimer = CreateTimer( timer, CheckAllTraces, 0, TIMER_REPEAT);	
}

/*
Handle tracing sprays to the HUD or hint message
*/

public Action:CheckAllTraces(Handle:hTimer, any:useless) {
	new Float:vecPos[3];
	new bool:bHasHUDChanged = false;

	//God pray for the processor
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i) || IsFakeClient(i))
			continue;

		if(GetPlayerEye(i, vecPos)) {
			for(new a = 1; a <= MaxClients; a++) {
				if(GetVectorDistance(vecPos, g_arrSprayTrace[a]) <= GetConVarFloat(g_arrCVars[MAXDIS])) {
					new AdminId:admin = GetUserAdmin(i);

					if(!(GetConVarInt(g_arrCVars[ADMINONLY]) == 1) || (admin != INVALID_ADMIN_ID)) {
						if(g_bCanUseHUD && GetConVarBool(g_arrCVars[USEHUD])) {
							//Save bandwidth, only send the message if needed.
							if(!bHasHUDChanged) {
								bHasHUDChanged = true;
								SetHudTextParams(0.04, 0.6, GetConVarFloat(g_arrCVars[HUDTIME]), 255, 50, 50, 255);
							}

							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || (GetConVarInt(g_arrCVars[ADMINONLY]) != 2)) {
								if((admin != INVALID_ADMIN_ID && GetConVarBool(g_arrCVars[FULLHUDADMIN])) || GetConVarBool(g_arrCVars[FULLHUD]))
									ShowSyncHudText(i, g_hHUDMessage, "%T", "Sprayed", i, g_arrSprayName[a], g_arrSprayID[a]);
								else
									ShowSyncHudText(i, g_hHUDMessage, "%T", "Sprayed Name", i, g_arrSprayName[a]);
							}
						}
						else {
							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || (GetConVarInt(g_arrCVars[ADMINONLY]) != 2)) {
								if((admin != INVALID_ADMIN_ID && GetConVarBool(g_arrCVars[FULLHUDADMIN])) || GetConVarBool(g_arrCVars[FULLHUD]))
									PrintHintText(i, "%T", "Sprayed", i, g_arrSprayName[a], g_arrSprayID[a]);
								else
									PrintHintText(i, "%T", "Sprayed Name", i, g_arrSprayName[a]);
							}
						}
					}

					break;
				}
			}
		}
	}
}

/*
Trace spray function
*/

public Action:TestTrace(client, args) {
	if(!IsValidClient(client))
		return Plugin_Handled;

	new Float:vecPos[3];

	if(GetPlayerEye(client, vecPos)) {
	 	for(new i = 1; i<= MaxClients; i++) {
			if(GetVectorDistance(vecPos, g_arrSprayTrace[i]) <= GetConVarFloat(g_arrCVars[MAXDIS])) {
				new time = RoundFloat(GetGameTime()) - g_arrSprayTime[i];

				PrintToChat(client, "[Spray Trace] %T", "Spray By", client, g_arrSprayName[i], g_arrSprayID[i], time);
				GlowEffect(client, g_arrSprayTrace[i], 2.0, 0.3, 255, g_PrecacheRedGlow);
				AdminMenu(client, i);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(client, "[Spray Trace] %T", "No Spray", client);

	return Plugin_Handled;
}

/*
Remove spray function
*/

public Action:RemoveSpray(client, args) {
	if(!IsValidClient(client))
		return Plugin_Handled;

	new Float:vecPos[3];

	if(GetPlayerEye(client, vecPos)) {
		new String:szAdminName[32];

		GetClientName(client, szAdminName, 31);

	 	for(new i = 1; i<= MaxClients; i++) {
			if(GetVectorDistance(vecPos, g_arrSprayTrace[i]) <= GetConVarFloat(g_arrCVars[MAXDIS])) {
				new Float:vecEndPos[3];

				PrintToChat(client, "[Spray Trace] %T", "Spray By", client, g_arrSprayName[i], g_arrSprayID[i], RoundFloat(GetGameTime()) - g_arrSprayTime[i]);

				SprayDecal(i, 0, vecEndPos);

				g_arrSprayTrace[i][0] = 0.0;
				g_arrSprayTrace[i][1] = 0.0;
				g_arrSprayTrace[i][2] = 0.0;

				PrintToChat(client, "[Spray Trace] %T", "Spray Removed", client, g_arrSprayName[i], g_arrSprayID[i], szAdminName);
				LogAction(client, -1, "[Spray Trace] %T", "Spray Removed", LANG_SERVER, g_arrSprayName[i], g_arrSprayID[i], szAdminName);
				AdminMenu(client, i);

				return Plugin_Handled;
			}
		}
	}

	PrintToChat(client, "[Spray Trace] %T", "No Spray", client);

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

		if (!IsValidClient(target)) {
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
	if(!IsValidClient(client))
		return;

	new Float:vecEndPos[3];

	if(GetPlayerEye(client, vecEndPos) && IsClientInGame(client) && IsClientInGame(target)) {
		new String:targetName[32];
		new String:szAdminName[32];
		new traceEntIndex = TR_GetEntityIndex();

		GetClientName(target, targetName, 31);
		GetClientName(client, szAdminName, 31);

		SprayDecal(target, traceEntIndex, vecEndPos);
		EmitSoundToAll("misc/sprayer.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);

		PrintToChat(client, "\x04[Spray Trace] %T", "Admin Sprayed", client, szAdminName, targetName);
		LogAction(client, -1, "[Spray Trace] %T", "Admin Sprayed", LANG_SERVER, szAdminName, targetName);
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

	new Handle:menu = CreateMenu(MenuHandler_AdminSpray);

	SetMenuTitle(menu, "%T", "Admin Spray Menu", client);
	SetMenuExitBackButton(menu, true);

	AddTargetsToMenu(menu, client, true, false);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminSpray(Handle:menu, MenuAction:action, param1, param2) {
	if(!IsValidClient(param1))
		return;

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
			PrintToChat(param1, "[Spray Trace] %T", "Could Not Find", param1);
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

public AdminMenu_TraceSpray(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if(!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "Trace", param);
	else if (action == TopMenuAction_SelectOption)
		TestTrace(param, 0);
}

public AdminMenu_SprayRemove(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if(!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "Remove", param);
	else if (action == TopMenuAction_SelectOption)
		RemoveSpray(param, 0);
}

public AdminMenu_AdminSpray(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if(!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
		Format(szBuffer, iMaxLength, "%T", "AdminSpray", param);
	else if (action == TopMenuAction_SelectOption)
		DisplayAdminSprayMenu(param);
}

/*
Admin punishment menu
*/

public Action:AdminMenu(client, sprayer) {
	if(!IsValidClient(client))
		return Plugin_Handled;

	g_arrMenuSprayID[client] = g_arrSprayID[sprayer];

	new Handle:hMenu = CreateMenu(AdminMenuHandler);

	SetMenuTitle(hMenu, "%T", "Title", client, g_arrSprayName[sprayer], g_arrSprayID[sprayer], RoundFloat(GetGameTime()) - g_arrSprayTime[sprayer]);

	new String:szWarn[128];
	Format(szWarn, 127, "%T", "Warn", client);
	AddMenuItem(hMenu, "warn", szWarn);

	if(!GetConVarBool(g_arrCVars[RESTRICT]) || GetAdminFlag(GetUserAdmin(client), Admin_Ban)) {
		if(GetConVarInt(g_arrCVars[SLAPDMG]) > 0) {
			new String:szSlap[128];
			Format(szSlap, 127, "%T", "SlapWarn", client, GetConVarInt(g_arrCVars[SLAPDMG]));
			AddMenuItem(hMenu, "slap", szSlap);
		}

		if(GetConVarBool(g_arrCVars[USESLAY])) {
			new String:szSlay[128];
			Format(szSlay, 127, "%T", "Slay", client);
			AddMenuItem(hMenu, "slay", szSlay);
		}

		if(GetConVarBool(g_arrCVars[USEBURN])) {
			new String:szBurn[128];
			Format(szBurn, 127, "%T", "BurnWarn", client, GetConVarInt(g_arrCVars[BURNTIME]));
			AddMenuItem(hMenu, "burn", szBurn);
		}

		if(GetConVarBool(g_arrCVars[USEFREEZE])) {
			new String:szFreeze[128];
			Format(szFreeze, 127, "%T", "Freeze", client);
			AddMenuItem(hMenu, "freeze", szFreeze);
		}

		if(GetConVarBool(g_arrCVars[USEBEACON])) {
			new String:szBeacon[128];
			Format(szBeacon, 127, "%T", "Beacon", client);
			AddMenuItem(hMenu, "beacon", szBeacon);
		}

		if(GetConVarBool(g_arrCVars[USEFREEZEBOMB])) {
			new String:szFreezeBomb[128];
			Format(szFreezeBomb, 127, "%T", "FreezeBomb", client);
			AddMenuItem(hMenu, "freezebomb", szFreezeBomb);
		}

		if(GetConVarBool(g_arrCVars[USEFIREBOMB])) {
			new String:szFireBomb[128];
			Format(szFireBomb, 127, "%T", "FireBomb", client);
			AddMenuItem(hMenu, "firebomb", szFireBomb);
		}

		if(GetConVarBool(g_arrCVars[USETIMEBOMB])) {
			new String:szTimeBomb[128];
			Format(szTimeBomb, 127, "%T", "TimeBomb", client);
			AddMenuItem(hMenu, "timebomb", szTimeBomb);
		}

		if(GetConVarInt(g_arrCVars[DRUGTIME]) > 0) {
			new String:szDrug[128];
			Format(szDrug, 127, "%T", "szDrug", client);
			AddMenuItem(hMenu, "drug", szDrug);
		}

		if(GetConVarBool(g_arrCVars[USEKICK])) {
			new String:szKick[128];
			Format(szKick, 127, "%T", "Kick", client);
			AddMenuItem(hMenu, "kick", szKick);
		}

		if(GetConVarInt(g_arrCVars[TBANTIME]) > 0) {
			new String:szBan[128];
			Format(szBan, 127, "%T", "Ban", client, GetConVarInt(g_arrCVars[TBANTIME]));
			AddMenuItem(hMenu, "ban", szBan);
		}

		if(GetConVarBool(g_arrCVars[USEPBAN])) {
			new String:szPBan[128];
			Format(szPBan, 127, "%T", "PBan", client);
			AddMenuItem(hMenu, "pban", szPBan);
		}
	}

	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public AdminMenuHandler(Handle:hMenu, MenuAction:action, client, itemNum) {
	if ( action == MenuAction_Select ) {
		new String:szInfo[32];
		new String:szSprayerName[64];
		new String:szSprayerID[32];
		new String:szAdminName[64];
		new sprayer;

		szSprayerID = g_arrMenuSprayID[client];
		sprayer = GetClientFromAuthID(g_arrMenuSprayID[client]);
		szSprayerName = g_arrSprayName[sprayer];
		GetClientName(client, szAdminName, sizeof(szAdminName));
		GetMenuItem(hMenu, itemNum, szInfo, sizeof(szInfo));

		if ((strcmp(szInfo, "sban") == 0) || (strcmp(szInfo, "pban") == 0)) {
			if (sprayer) {
				new iTime = 0;
				new String:szBad[128];
				Format(szBad, 127, "%T", "Bad Spray Logo", LANG_SERVER);
	
				if(strcmp(szInfo, "ban") == 0)
					iTime = GetConVarInt(g_arrCVars[TBANTIME]);
	
				g_hExternalBan = FindConVar("sb_version");
	
				//SourceBans integration
				if ( g_hExternalBan != INVALID_HANDLE ) {
					ClientCommand(client, "sm_ban #%d %d \"%s\"", GetClientUserId(sprayer), iTime, szBad);

					if(iTime == 0)
						LogAction(client, -1, "[Spray Trace] %T", "EPBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, "SourceBans");
					else
						LogAction(client, -1, "[Spray Trace] %T", "EBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime, "SourceBans");
	
					CloseHandle(g_hExternalBan);
				}
				else {
					g_hExternalBan = FindConVar("mysql_bans_version");
	
					//MySQL Bans integration
					if ( g_hExternalBan != INVALID_HANDLE ) {
						ClientCommand(client, "mysql_ban #%d %d \"%s\"", GetClientUserId(sprayer), iTime, szBad);
	
						if(iTime == 0)
							LogAction(client, -1, "[Spray Trace] %T", "EPBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, "MySQL Bans");
						else
							LogAction(client, -1, "[Spray Trace] %T", "EBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime, "MySQL Bans");
	
						CloseHandle(g_hExternalBan);
					}
					else {
						//Normal Ban
						BanClient(sprayer, iTime, BANFLAG_AUTHID, szBad, szBad);
	
						if(iTime == 0)
							LogAction(client, -1, "[Spray Trace] %T", "PBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
						else
							LogAction(client, -1, "[Spray Trace] %T", "Banned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime);
					}
				}

				if(iTime == 0)
					PrintToChatAll("\x03[Spray Trace] %T", "PBanned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				else
					PrintToChatAll("\x03[Spray Trace] %T", "Banned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, iTime);
			}
			else {
				PrintToChat(client, "\x04[Spray Trace] %T", "Could Not Find Name ID", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Could Not Find Name ID", LANG_SERVER, szSprayerName, szSprayerID);
			}
		}
		else if( sprayer && IsClientInGame(sprayer) ) {
			new AdminId:sprayerAdmin = GetUserAdmin(sprayer);
			new AdminId:clientAdmin = GetUserAdmin(client);

			if( ((sprayerAdmin != INVALID_ADMIN_ID) && (clientAdmin != INVALID_ADMIN_ID)) && GetConVarBool(g_arrCVars[IMMUNITY]) && !CanAdminTarget(clientAdmin, sprayerAdmin) ) {
				PrintToChat(client, "\x04[Spray Trace] %T", "Admin Immune", client, szSprayerName);
				LogAction(client, -1, "[Spray Trace] %T", "Admin Immune Log", LANG_SERVER, szAdminName, szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "warn") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Warned", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "slap") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Slapped And Warned", client, szSprayerName, szSprayerID, GetConVarInt(g_arrCVars[SLAPDMG]));
				LogAction(client, -1, "[Spray Trace] %T", "Log Slapped And Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID, GetConVarInt(g_arrCVars[SLAPDMG]));
				SlapPlayer(sprayer, GetConVarInt(g_arrCVars[SLAPDMG]));
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "slay") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Slayed And Warned", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Slayed And Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_slay \"%s\"", szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "burn") == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Burnt And Warned", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Burnt And Warned", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_burn \"%s\" %d", szSprayerName, GetConVarInt(g_arrCVars[BURNTIME]));
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "freeze", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Froze", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Froze", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_freeze \"%s\"", szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "beacon", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Beaconed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Beaconed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_beacon \"%s\"", szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "freezebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "FreezeBombed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log FreezeBombed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_freezebomb \"%s\"", szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "firebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "FireBombed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log FireBombed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_firebomb \"%s\"", szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "timebomb", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "TimeBombed", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log TimeBombed", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				ClientCommand(client, "sm_timebomb \"%s\"", szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "drug", false) == 0 ) {
				PrintToChat(sprayer, "\x03[Spray Trace] %T", "Please change", sprayer);
				PrintToChat(client, "\x04[Spray Trace] %T", "Drugged", client, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Drugged", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
				CreateTimer(GetConVarFloat(g_arrCVars[DRUGTIME]), Undrug, sprayer, TIMER_FLAG_NO_MAPCHANGE);
				ClientCommand(client, "sm_drug \"%s\"", szSprayerName);
				AdminMenu(client, sprayer);
			}
			else if ( strcmp(szInfo, "kick") == 0 ) {
				KickClient(sprayer, "%T", "Bad Spray Logo", sprayer);
				PrintToChatAll("\x03[Spray Trace] %T", "Kicked", LANG_SERVER, szSprayerName, szSprayerID);
				LogAction(client, -1, "[Spray Trace] %T", "Log Kicked", LANG_SERVER, szAdminName, szSprayerName, szSprayerID);
			}
		}
		else {
			PrintToChat(client, "\x04[Spray Trace] %T", "Could Not Find Name ID", client, szSprayerName, szSprayerID);
			LogAction(client, -1, "[Spray Trace] %T", "Could Not Find Name ID", LANG_SERVER, szSprayerName, szSprayerID);
		}

		if(GetConVarBool(g_arrCVars[AUTOREMOVE])) {
			new Float:vecEndPos[3];
			SprayDecal(sprayer, 0, vecEndPos);

			PrintToChat(client, "[Spray Trace] %T", "Spray Removed", client, szSprayerName, szSprayerID, szAdminName);
			LogAction(client, -1, "[Spray Trace] %T", "Spray Removed", LANG_SERVER, szSprayerName, szSprayerID, szAdminName);
		}
	}
	else if ( action == MenuAction_End )
		CloseHandle(hMenu);
}

/*
Helper Methods
*/

public GetClientFromAuthID(const String:szAuthID[]) {
	new String:szOtherAuthID[32];
	for ( new i = 1; i <= GetMaxClients(); i++ ) {
		if (IsClientInGame(i) && !IsFakeClient(i) ) {
			GetClientAuthString(i, szOtherAuthID, 32);

			if ( strcmp(szOtherAuthID, szAuthID) == 0 )
				return i;
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

public GlowEffect(client, Float:vecPos[3], Float:flLife, Float:flSize, bright, model) {
	if(!IsValidClient(client))
		return;

	new arrClients[1];
	arrClients[0] = client;
	TE_SetupGlowSprite(vecPos, model, flLife, flSize, bright);
	TE_Send(arrClients,1);
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

/*
	Undrug handler to undrug a player after sm_spray_drugtime
*/

public Action:Undrug(Handle:hTimer, any:client) {
	if(IsValidClient(client)) {
		new String:clientName[32];
		GetClientName(client, clientName, 31);

		ServerCommand("sm_undrug \"%s\"", clientName);
	}

	return Plugin_Handled;
}

public bool:IsValidClient(client) {
	if(client <= 0)
		return false;
	if(client > MaxClients)
		return false;

	return IsClientInGame(client);
}