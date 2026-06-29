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

#define PLUGIN_VERSION "5.8"
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
new Float:SprayTrace[MAXPLAYERS + 1][3];
new String:SprayName[MAXPLAYERS + 1][64];
new String:SprayID[MAXPLAYERS + 1][32];
new String:MenuSprayID[MAXPLAYERS + 1][32];
new SprayTime[MAXPLAYERS + 1];

// Misc. globals
new Handle:g_cvars[NUMCVARS];
new Handle:spraytimer = INVALID_HANDLE;
new Handle:hTopMenu;
new Handle:external_ban = INVALID_HANDLE;
new Handle:HudMessage;
new bool:CanHUD;
new precache_redglow;

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

	g_cvars[REFRESHRATE] = CreateConVar("sm_spray_refresh","1.0","How often the program will trace to see player's spray to the HUD. 0 to disable.");
	g_cvars[MAXDIS] = CreateConVar("sm_spray_dista","50.0","How far away the spray will be traced to.");
	g_cvars[TBANTIME] = CreateConVar("sm_spray_bantime","60","How long the temporary ban is for. 0 to disable temporary banning.");
	g_cvars[ADMINONLY] = CreateConVar("sm_spray_adminonly","0","Changes showing the trace messages on HUD. 0 - Only admin can trace sprays 1 - All players can trace all sprays 2 - All players can trace all non-admin sprays.");
	g_cvars[FULLHUD] = CreateConVar("sm_spray_fullhud","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins.");
	g_cvars[FULLHUDADMIN] = CreateConVar("sm_spray_fullhudadmin","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to admins.");
	g_cvars[BURNTIME] = CreateConVar("sm_spray_burntime","10","How long the burn punishment is for.");
	g_cvars[SLAPDMG] = CreateConVar("sm_spray_slapdamage","5","How much damage the slap punishment is for. 0 to disable.");
	g_cvars[USESLAY] = CreateConVar("sm_spray_enableslay","0","Enables the use of Slay as a punishment.");
	g_cvars[USEBURN] = CreateConVar("sm_spray_enableburn","0","Enables the use of Burn as a punishment.");
	g_cvars[USEPBAN] = CreateConVar("sm_spray_enablepban","1","Enables the use of a Permanent Ban as a punishment.");
	g_cvars[USEKICK] = CreateConVar("sm_spray_enablekick","1","Enables the use of Kick as a punishment.");
	g_cvars[USEBEACON] = CreateConVar("sm_spray_enablebeacon","0","Enables putting a beacon on the sprayer as a punishment.");
	g_cvars[USEFREEZE] = CreateConVar("sm_spray_enablefreeze","0","Enables the use of Freeze as a punishment.");
	g_cvars[USEFREEZEBOMB] = CreateConVar("sm_spray_enablefreezebomb","0","Enables the use of Freeze Bomb as a punishment.");
	g_cvars[USEFIREBOMB] = CreateConVar("sm_spray_enablefirebomb","0","Enables the use of Fire Bomb as a punishment.");
	g_cvars[USETIMEBOMB] = CreateConVar("sm_spray_enabletimebomb","0","Enables the use of Time Bomb as a punishment.");
	g_cvars[DRUGTIME] = CreateConVar("sm_spray_drugtime","0","set the time a sprayer is drugged as a punishment. 0 to disable.");
	g_cvars[AUTOREMOVE] = CreateConVar("sm_spray_autoremove","0","Enables automatically removing sprays when a punishment is dealt.");
	g_cvars[RESTRICT] = CreateConVar("sm_spray_restrict","0","Enables or disables restricting admins with the \"ban\" flag's punishments. (1 = warn only, 0 = all)");
	g_cvars[IMMUNITY] = CreateConVar("sm_spray_useimmunity","1","Enables or disables using admin immunity to determine if one admin can punish another.");
	g_cvars[GLOBAL] = CreateConVar("sm_spray_global","1","Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");
	g_cvars[USEHUD] = CreateConVar("sm_spray_usehud","1","Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.");
	g_cvars[HUDTIME] = CreateConVar("sm_spray_hudtime","1.0","How long the HUD messages are displayed.");

	HookConVarChange(g_cvars[REFRESHRATE], TimerChanged);

	AddTempEntHook("Player Decal",PlayerSpray);

	CreateTimers();

	new String:gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));

	CanHUD = StrEqual(gamename,"tf",false) || StrEqual(gamename,"hl2mp",false) || StrEqual(gamename,"sourceforts",false) || StrEqual(gamename,"obsidian",false) || StrEqual(gamename,"left4dead",false) || StrEqual(gamename,"l4d",false);
	if(CanHUD)
		HudMessage = CreateHudSynchronizer();

	AutoExecConfig(true, "plugin.spraytrace");
}

/*
	Clears all stored sprays when the map changes.
	Also prechaches the model.
*/

public OnMapStart() {
	precache_redglow = PrecacheModel("sprites/redglow1.vmt");

	for(new i = 1; i <= MaxClients; i++)
		ClearVariables(i);
}

/*
	Clears all stored sprays for a disconnecting
	client if global spray tracing is disabled.
*/

public OnClientDisconnect(client) {
	if(!GetConVarBool(g_cvars[GLOBAL]))
		ClearVariables(client);
}

/*
	Clears the stored sprays for the given client.
*/

public ClearVariables(client) {
	SprayTrace[ client ][0] = 0.0;
	SprayTrace[ client ][1] = 0.0;
	SprayTrace[ client ][2] = 0.0;
	strcopy(SprayName[ client ], sizeof(SprayName[]), "");
	strcopy(SprayID[ client ], sizeof(SprayID[]), "");
	strcopy(MenuSprayID[ client ], sizeof(MenuSprayID[]), "");
	SprayTime[ client ] = 0;
}

/*
Records the location, name, ID, and time of all sprays
*/

public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay) {
	new client = TE_ReadNum("m_nPlayer");

	if(client && IsClientInGame(client)) {
		TE_ReadVector("m_vecOrigin",SprayTrace[client]);

		SprayTime[client] = RoundFloat(GetGameTime());
		GetClientName(client, SprayName[client], 64);
		GetClientAuthString(client, SprayID[client], 32);
	}
}

/*
sm_spray_refresh handlers for tracing to HUD or hint message
*/

public TimerChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	CreateTimers();
}

stock CreateTimers() {
	if(spraytimer != INVALID_HANDLE) {
		KillTimer( spraytimer );
		spraytimer = INVALID_HANDLE;
	}

	new Float:timer = GetConVarFloat( g_cvars[REFRESHRATE] );

	if( timer > 0.0)
		spraytimer = CreateTimer( timer, CheckAllTraces, 0, TIMER_REPEAT);	
}

/*
Handle tracing sprays to the HUD or hint message
*/

public Action:CheckAllTraces(Handle:timer, any:useless) {
	new Float:pos[3];
	new bool:HasChangedHud = false;

	//God pray for the processor
	for(new i = 1; i<= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if(GetPlayerEye(i, pos)) {
			for(new a=1; a<=MaxClients;a++) {
				if(GetVectorDistance(pos, SprayTrace[a]) <= GetConVarFloat(g_cvars[MAXDIS])) {
					new AdminId:admin = GetUserAdmin(i);

					if(!(GetConVarInt(g_cvars[ADMINONLY]) == 1) || (admin != INVALID_ADMIN_ID)) {
						if(CanHUD && GetConVarBool(g_cvars[USEHUD])) {
							//Save bandwidth, only send the message if needed.
							if(!HasChangedHud) {
								HasChangedHud = true;
								SetHudTextParams(0.04, 0.6, GetConVarFloat(g_cvars[HUDTIME]), 255, 50, 50, 255);
							}

							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || (GetConVarInt(g_cvars[ADMINONLY]) != 2)) {
								if((admin != INVALID_ADMIN_ID && GetConVarBool(g_cvars[FULLHUDADMIN])) || GetConVarBool(g_cvars[FULLHUD]))
									ShowSyncHudText(i, HudMessage, "%t", "Sprayed", SprayName[a], SprayID[a]);
								else
									ShowSyncHudText(i, HudMessage, "%t", "Sprayed Name", SprayName[a]);
							}
						}
						else {
							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || (GetConVarInt(g_cvars[ADMINONLY]) != 2)) {
								if((admin != INVALID_ADMIN_ID && GetConVarBool(g_cvars[FULLHUDADMIN])) || GetConVarBool(g_cvars[FULLHUD]))
									PrintHintText(i, "%t", "Sprayed", SprayName[a], SprayID[a]);
								else
									PrintHintText(i, "%t", "Sprayed Name", SprayName[a]);
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
	new Float:pos[3];

	if(GetPlayerEye(client, pos)) {
	 	for(new i = 1; i<= MaxClients; i++) {
			if(GetVectorDistance(pos, SprayTrace[i]) <= GetConVarFloat(g_cvars[MAXDIS])) {
				new time = RoundFloat(GetGameTime()) - SprayTime[i];

				PrintToChat(client, "[Spray Trace] %t", "Spray By", SprayName[i], SprayID[i], time);
				GlowEffect(client, SprayTrace[i], 2.0, 0.3, 255, precache_redglow);
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

public Action:RemoveSpray(client, args) {
	new Float:pos[3];

	if(GetPlayerEye(client, pos)) {
		new String:adminName[32];

		GetClientName(client, adminName, 31);

	 	for(new i = 1; i<= MaxClients; i++) {
			if(GetVectorDistance(pos, SprayTrace[i]) <= GetConVarFloat(g_cvars[MAXDIS])) {
				new Float:vEndPos[3];

				PrintToChat(client, "[Spray Trace] %t", "Spray By", SprayName[i], SprayID[i], RoundFloat(GetGameTime()) - SprayTime[i]);

				SprayDecal(i, 0, vEndPos);

				SprayTrace[ i ][0] = 0.0;
				SprayTrace[ i ][1] = 0.0;
				SprayTrace[ i ][2] = 0.0;

				PrintToChat(client, "[Spray Trace] %t", "Spray Removed", SprayName[i], SprayID[i], adminName);
				LogAction(client, -1, "[Spray Trace] %t", "Spray Removed", SprayName[i], SprayID[i], adminName);
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

public Action:AdminSpray(client, args) {
	new target;

	if (args == 1) {
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		target = FindTarget(client, arg, false, false);

		if (!target) {
			ReplyToCommand(client, "[Spray Trace] %t", "Could Not Find Name", arg);
			return Plugin_Handled;
		}
	}
	else
		target = client;

	GoSpray(client, target);

	return Plugin_Handled;
}

public GoSpray(client, target) {
	new Float:vEndPos[3];

	if(GetPlayerEye(client, vEndPos) && IsClientInGame(client) && IsClientInGame(target)) {
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
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
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
	if (topmenu == hTopMenu)
		return;

	/* Save the Handle */
	hTopMenu = topmenu;

	/* Find the "Server Commands" category */
	new TopMenuObject:spray_commands = AddToTopMenu(
		hTopMenu,		// Menu
		"Spray Commands",		// Name
		TopMenuObject_Category,	// Type
		CategoryHandler,	// Callback
		INVALID_TOPMENUOBJECT	// Parent
		);

	if( spray_commands == INVALID_TOPMENUOBJECT ){
		// Error... lame...
		return;
		}

	AddToTopMenu(hTopMenu, "sm_spraytrace", TopMenuObject_Item, AdminMenu_TraceSpray, spray_commands, "sm_spraytrace", ADMFLAG_BAN);
	AddToTopMenu(hTopMenu, "sm_removespray", TopMenuObject_Item, AdminMenu_SprayRemove, spray_commands, "sm_removespray", ADMFLAG_BAN);
	AddToTopMenu(hTopMenu, "sm_adminspray", TopMenuObject_Item, AdminMenu_AdminSpray, spray_commands, "sm_adminspray", ADMFLAG_BAN);
}

public CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
			{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Spray Commands:");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spray Commands");
	}
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
	MenuSprayID[clientId] = SprayID[sprayerId];

	new Handle:menu = CreateMenu(AdminMenuHandler);

	SetMenuTitle(menu, "%t", "Title", SprayName[sprayerId], SprayID[sprayerId], RoundFloat(GetGameTime()) - SprayTime[sprayerId]);

	new String:warn[128];
	Format(warn, 127, "%t", "Warn");
	AddMenuItem(menu, "warn", warn);

	if(!GetConVarBool(g_cvars[RESTRICT]) || GetAdminFlag(GetUserAdmin(clientId), Admin_Ban)) {
		if(GetConVarInt(g_cvars[SLAPDMG]) > 0) {
			new String:slap[128];
			Format(slap, 127, "%t", "SlapWarn", GetConVarInt(g_cvars[SLAPDMG]));
			AddMenuItem(menu, "slap", slap);
		}

		if(GetConVarBool(g_cvars[USESLAY])) {
			new String:slay[128];
			Format(slay, 127, "%t", "Slay");
			AddMenuItem(menu, "slay", slay);
		}

		if(GetConVarBool(g_cvars[USEBURN])) {
			new String:burn[128];
			Format(burn, 127, "%t", "BurnWarn", GetConVarInt(g_cvars[BURNTIME]));
			AddMenuItem(menu, "burn", burn);
		}

		if(GetConVarBool(g_cvars[USEFREEZE])) {
			new String:freeze[128];
			Format(freeze, 127, "%t", "Freeze");
			AddMenuItem(menu, "freeze", freeze);
		}

		if(GetConVarBool(g_cvars[USEBEACON])) {
			new String:beacon[128];
			Format(beacon, 127, "%t", "Beacon");
			AddMenuItem(menu, "beacon", beacon);
		}

		if(GetConVarBool(g_cvars[USEFREEZEBOMB])) {
			new String:freezebomb[128];
			Format(freezebomb, 127, "%t", "FreezeBomb");
			AddMenuItem(menu, "freezebomb", freezebomb);
		}

		if(GetConVarBool(g_cvars[USEFIREBOMB])) {
			new String:firebomb[128];
			Format(firebomb, 127, "%t", "FireBomb");
			AddMenuItem(menu, "firebomb", firebomb);
		}

		if(GetConVarBool(g_cvars[USETIMEBOMB])) {
			new String:timebomb[128];
			Format(timebomb, 127, "%t", "TimeBomb");
			AddMenuItem(menu, "timebomb", timebomb);
		}

		if(GetConVarInt(g_cvars[DRUGTIME]) > 0) {
			new String:Drug[128];
			Format(Drug, 127, "%t", "Drug");
			AddMenuItem(menu, "Drug", Drug);
		}

		if(GetConVarBool(g_cvars[USEKICK])) {
			new String:kick[128];
			Format(kick, 127, "%t", "Kick");
			AddMenuItem(menu, "kick", kick);
		}

		if(GetConVarInt(g_cvars[TBANTIME]) > 0) {
			new String:ban[128];
			Format(ban, 127, "%t", "Ban", GetConVarInt(g_cvars[TBANTIME]));
			AddMenuItem(menu, "ban", ban);
		}

		if(GetConVarBool(g_cvars[USEPBAN])) {
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

		sprayerID = MenuSprayID[client];
		sprayer = GetClientFromAuthID(MenuSprayID[client]);
		sprayerName = SprayName[sprayer];
		GetClientName(client, adminName, sizeof(adminName));
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if ((strcmp(info,"ban") == 0) || (strcmp(info,"pban") == 0)) {
			if (sprayer) {
				new time = 0;
				new String:bad[128];
				Format(bad, 127, "%t", "Bad Spray Logo");
	
				if(strcmp(info,"ban") == 0)
					time = GetConVarInt(g_cvars[TBANTIME]);
	
				external_ban = FindConVar("sb_version");
	
				//SourceBans integration
				if ( external_ban != INVALID_HANDLE ) {
					ClientCommand(client, "sm_ban #%d %d \"%s\"", GetClientUserId(sprayer), time, bad);

					if(time == 0)
						LogAction(client, -1, "[Spray Trace] %t", "EPBanned", adminName, sprayerName, sprayerID, "SourceBans");
					else
						LogAction(client, -1, "[Spray Trace] %t", "EBanned", adminName, sprayerName, sprayerID, time, "SourceBans");
	
					CloseHandle(external_ban);
				}
				else {
					external_ban = FindConVar("mysql_bans_version");
	
					//MySQL Bans integration
					if ( external_ban != INVALID_HANDLE ) {
						ClientCommand(client, "mysql_ban #%d %d \"%s\"", GetClientUserId(sprayer), time, bad);
	
						if(time == 0)
							LogAction(client, -1, "[Spray Trace] %t", "EPBanned", adminName, sprayerName, sprayerID, "MySQL Bans");
						else
							LogAction(client, -1, "[Spray Trace] %t", "EBanned", adminName, sprayerName, sprayerID, time, "MySQL Bans");
	
						CloseHandle(external_ban);
					}
					else {
						//Normal Ban
						BanClient(sprayer, time, BANFLAG_AUTHID, bad, bad);
	
						if(time == 0)
							LogAction(client, -1, "[Spray Trace] %t", "PBanned", adminName, sprayerName, sprayerID);
						else
							LogAction(client, -1, "[Spray Trace] %t", "Banned", adminName, sprayerName, sprayerID, time);
					}
				}

				if(time == 0)
					PrintToChatAll("\x03[Spray Trace] %t", "PBanned", adminName, sprayerName, sprayerID);
				else
					PrintToChatAll("\x03[Spray Trace] %t", "Banned", adminName, sprayerName, sprayerID, time);
			}
			else {
				PrintToChat(client, "\x04[Spray Trace] %t", "Could Not Find Name ID", sprayerName, sprayerID);
				LogAction(client, -1, "[Spray Trace] %t", "Could Not Find Name ID", sprayerName, sprayerID);
			}
		}
		else if( sprayer && IsClientInGame(sprayer) ) {
			new AdminId:sprayerAdmin = GetUserAdmin(sprayer);
			new AdminId:clientAdmin = GetUserAdmin(client);

			if( ((sprayerAdmin != INVALID_ADMIN_ID) && (clientAdmin != INVALID_ADMIN_ID)) && GetConVarBool(g_cvars[IMMUNITY]) && !CanAdminTarget(clientAdmin, sprayerAdmin) ) {
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
				PrintToChat(client, "\x04[Spray Trace] %t", "Slapped And Warned", sprayerName, sprayerID, GetConVarInt(g_cvars[SLAPDMG]));
				LogAction(client, -1, "[Spray Trace] %t", "Log Slapped And Warned", adminName, sprayerName, sprayerID, GetConVarInt(g_cvars[SLAPDMG]));
				SlapPlayer(sprayer, GetConVarInt(g_cvars[SLAPDMG]));
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
				ClientCommand(client, "sm_burn \"%s\" %d", sprayerName, GetConVarInt(g_cvars[BURNTIME]));
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
				CreateTimer(GetConVarFloat(g_cvars[DRUGTIME]), Undrug, sprayer, TIMER_FLAG_NO_MAPCHANGE);
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

		if(GetConVarBool(g_cvars[AUTOREMOVE])) {
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

public GetClientFromAuthID(const String:authid[]) {
	new String:tmpAuthID[32];
	for ( new i = 1; i <= GetMaxClients(); i++ ) {
		if (IsClientInGame(i) && !IsFakeClient(i) ) {
			GetClientAuthString(i, tmpAuthID, 32);

			if ( strcmp(tmpAuthID, authid) == 0 )
				return i;
		}
	}
	return 0;
}

stock bool:GetPlayerEye(client, Float:pos[3]) {
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}

	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
 	return entity > MaxClients;
}

public GlowEffect(client, Float:pos[3], Float:life, Float:size, bright, model) {
	new clients[1];
	clients[0] = client;
	TE_SetupGlowSprite(pos, model, life, size, bright);
	TE_Send(clients,1);
}

public SprayDecal(client, entIndex, Float:pos[3]) {
	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nEntity", entIndex);
	TE_WriteNum("m_nPlayer", client);
	TE_SendToAll();
}

/*
	Undrug handler to undrug a player after sm_spray_drugtime
*/

public Action:Undrug(Handle:timer, any:client) {
	if(client && IsClientInGame(client)) {
		new String:clientName[32];
		GetClientName(client, clientName, 31);

		ServerCommand("sm_undrug \"%s\"", clientName);
	}

	return Plugin_Handled;
}