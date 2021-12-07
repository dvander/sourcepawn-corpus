/*
*	Simple TK Manager
*	By Lebson506th
*
*	Description
*	-----------
*
*	This plugin is just a simple solution to an annoying problem: Team killers.
*	All this plugin does is count how many times a person TKs, and then kicks
*	them when they reach that limit. This also has a reflect damage ability
*	where it will reflect all team damage back onto the attacker.
*
*	Note: Reflect damage does not block headshots and/or shots that kill the
*	victim instantly. In these cases both the victim and the attacker will die.
*
*	Usage
*	-----
*
*	sm_stk_enabled (default: 1) - Enables(1) or disables(0) the plugin.
*	sm_stk_reflect (default: 1) - Enables(1) or disables(0) reflecting damage back onto a team attacker.
*	sm_stk_limit (default: 5) - Sets the number of TKs a player has to get before they are automatically kicked.
*	sm_stk_forgivemessage (default: 1) - Changes who the forgiven/not forgiven messages can be seen by.
*						0 - Nobody
*						1 - Everyone
*						2 - People involved
*						3 - Admin and people involved
*						4 - Admins only
*	sm_stk_countmessage (default: 2) - Changes who the TK count message can be seen by.
*						0 - Nobody
*						1 - Everyone
*						2 - People involved
*						3 - Admin and people involved
*						4 - Admins only
*	sm_stk_punishmessage (default: 1) - Changes who the punishment messages can be seen by.
*						0 - Nobody
*						1 - Everyone
*						2 - People involved
*						3 - Admin and people involved
*						4 - Admins only
*	sm_stk_kickmessage (default: 1) - Show a message to everyone(1) or admin only (2) when a player is kicked for TKing. 0 to disable
*	sm_stk_protecttime (default: 10) - Automatically slay any team attacker in spawn during this amount of seconds after spawn
*	sm_stk_immunity (default: 7) - Manages admin immunity mode.
*						0 - Disabled, no admin immunity.
*						1 - Admin immune to reflect damage and spawn slaying.
*						2 - Admin immune to being kicked for TKing.
*						3 - Options 1 and 2
*						4 - Admin immune to TK punishments
*						5 - Options 1 and 4
*						6 - Options 2 and 4
*						7 - Options 1, 2 and 4
*	sm_stk_punishmode (default: 1) - Manages the TKer punishment modes on top of kick.
*						0 - No additional punishment.
*						1 - Let the victim choose.
*						2 - Use sm_stk_punishment
*	sm_stk_punishment (default: 1) - Manages the TKer punishment if sm_stk_punishmode = 2.
*						0 - Warn
*						1 - Slay
*						2 - Burn
*						3 - Freeze
*						4 - Beacon
*						5 - Freeze Bomb
*						6 - Fire Bomb
*						7 - Time Bomb
*						8 - Drug
*						9 - Remove % Cash
*						10 - Slap
*	sm_stk_allowslay (default: 1) - If sm_stk_punishmode = 1, allow slaying the attacker as a punishment.
*	sm_stk_allowfreeze (default: 1) - If sm_stk_punishmode = 1, allow freezing the attacker as a punishment.
*	sm_stk_allowbeacon (default: 1) - If sm_stk_punishmode = 1, allow putting a beacon on the attacker as a punishment.
*	sm_stk_allowfreezebomb (defualt: 1) - If sm_stk_punishmode = 1, allow putting a freezebomb on the attacker as a punishment.
*	sm_stk_allowfirebomb (deault: 1) - If sm_stk_punishmode = 1, allow putting a firebomb on the attacker as a punishment.
*	sm_stk_allowtimebomb (default: 1) - If sm_stk_punishmode = 1, allow putting a timebomb on the attacker as a punishment.
*	sm_stk_drugtime (default: 10) - If sm_stk_punishmode = 1, set the time a TKer is drugged as a punishment. 0.0 to disable.
*	sm_stk_burntime (default: 10) - If sm_stk_punishmode = 1, set the time a TKer is burnt as a punishment. 0.0 to disable.
*	sm_stk_slapdamage (default: 5) - If sm_stk_punishmode = 1, slap the TKer for this amount of damage as a punishment. 0 to disable.
*	sm_stk_bantime (default: -1) - Manages how long a player is banned for once they reach the TK limit. (Less than 0 is a kick)
*	sm_stk_removecash (default: 25) - Sets the percentage of cash the victim can remove from the attacker. 0 to disable. Only for CSS.
*	sm_stk_logging (default: 2)  - Sets the logging mode. 0 = No logging, 1 = Verbose logging, 2 = Only log TK Count and "Kicked" messages, 3 = Only log "Kicked" messages
*
*	ToDo
*	----
*
*	- Get translated into more languages
*	- Looking for suggestions
*
*	Change Log
*	----------
*
*	5/27/2011 - v1.0d
*	- Fixed admins not being able to be punished even when sm_stk_immunity was set to 0
*	- Fixed a rare error when sm_stk_punishment was set to something invalid.
*
*	5/26/2011 - v1.0c
*	- Fixed a small error in the French translations
*	- Fixed a small error in the chat printing.
*
*	4/12/2009 - v1.0b
*	- Added automatic changing of "mp_spawnprotecttime" to 0 on plugin start if it is available.
*	- Removed supper for Resistance and Liberation because it doesn't report events required to make this plugin work.
*
*	3/1/2009 - v1.0a
*	- Fixed a small error related to invalid clients.
*	- Reverted some small code changes to prevent more errors like this.
*
*	2/27/2009 - v1.0
*	- Added logging into its own file. The file is located in sourcemod/logs/stk_log_mmddyy.log.
*	- Added logging of every message so you know the progress of people TKing rather than just when they are kicked.
*	- Added sm_stk_loggin to manage the logging behavior.
*	- Added support for Resistance and Liberation using the same workaround used for Insurgency.
*	- Changed code to use MaxClients variable introduced in SourceMod 1.1
*	- Changed code to clean it up a little.
*	- Removed redundant check for insurgency support.
*
*	10/5/2008 - v0.9
*	- Thanks to FeuerSturm, the in-spawn slaying now works a lot better and I was able to drop my ridiculous work around.
*	- Changed some code around to maybe reduce the possibility of the auto-forgive bug more.
*
*	9/29/2008 - v0.8e
*	- Fixed SourceBans integration. For real this time.
*	- Removed the need for a seperate include file. Now compiles on the forum and the web compiler.
*
*	9/29/2008 - v0.8d
*	- Fixed SourceBans integration.
*
*	9/27/2008 - v0.8c
*	- Changed version CVAR to not get added to the auto-created config.
*	- Added automatic MySQL Banning and SourceBans support if banning is enabled (sm_stk_bantime >= 0)
*
*	9/10/2008 - v0.8b
*	- Shifted around some code to reduce the probability of the auto-forgive bug, if not eliminate it.
*	- Removed some redundant and useless code.
*	- Fixed a possible bug where a client was being queried even after they had been kicked.
*
*	9/9/2008 - v0.8a
*	- Fixed a bug where forgiving a player meant that you forgived everyone until you rejoined.
*	- Fixed sm_stk_drugtime and sm_stk_burntime defaulting to 1 instead of 10
*	- Fixed the "warn" punishment not displaying according to the punishment message CVAR.
*
*	9/8/2008 - v0.8
*	- Changed the plugin to auto-generate a config file in cfg/sourcemod.
*	- Added slap, firebomb, freezebomb, timebomb, and removal of money as punishments.
*	- Added CVARs to enable and disable the new punishments.
*	- Changed translations to reflect the new punishments.
*	- Changed sm_stk_punishment to reflect the new punishments.
*
*	9/3/2008 - v0.7f
*	- Fixed passed handler error for the undrug function.
*	- Fixed a future error where the script would try to punish a player after the map changed and end up punishing the wrong person (or throwing an error).
*
*	9/2/2008 - v0.7e
*	- Small tweak to fix insurgency error messages.
*
*	9/2/2008 - v0.7d
*	- Fixed punishment menu not showing up.
*	- Fixed TK immunity when sm_stk_immunity was set to 0
*	- Fixed wrong punishments when not all were enabled
*
*	9/2/2008 - v0.7c
*	- Changed something I was testing that was probably causing crashes.
*
*	9/1/2008 - v0.7b
*	- Fixed slay not working in insurgency.
*
*	8/31/2008 - v0.7a
*	- Fixed a bug where the client was less than 0.
*	- Fixed an array out of bounds error.
*	- Fixed some bugs where I was trying to reset a variable of a client that was no longer connected.
*	- Added more checks to hopefully fix the auto-forgive bug.
*
*	8/30/2008 - v0.7
*	- Everything from v0.7Beta to v0.7Beta4
*	- Added some variable checks to prevent future errors
*	- Added some attacker/client checks to hopefully eliminate the auto-forgive bug.
*
*	8/29/2008 - v0.7Beta4
*	- Fixed CVARs being from for sm_stk_burntime and sm_stk_drugtime
*	- Added sm_stk_bantime that manages how long a player is banned for once they reach the TK limit. (Less than 0 is a kick)
*
*	8/29/2008 - v0.7Beta3
*	- Changed sm_stk_allowburn to sm_stk_burntime to change the length of the burn punishment. 0.0 to disable.
*	- Changed sm_stk_allowdrug to sm_stk_drugtime to change the length of the drug punishment. 0.0 to disable.
*	- Fixed a drugged player not undrugging.
*	- Fixed a punishment not working if the attacker was dead from reflected damage. (Punishment will happen on next spawn. Possible delay of up to 5 seconds after it).
*
*	8/29/2008 - v0.7Beta2
*	- Fixed the sm_stk_punishmode 2 not working.
*	- Fixed displaying the punishment menu to the wrong client. (Letting the attacker punish the victim is bad)
*	- Fixed Burn not working.
*	- Fixed Freeze not working.
*	- Fixed admins not being immune to TK punishments when sm_stk_immunity was set to protect them.
*
*	8/29/2008 - v0.7Beta
*	- Fixed a bug where admin were not immune to spawn slaying if they killed the victim.
*	- Added two punishment modes. 1, the victim gets to choose a punishment from a menu. 2, the admin defines a pre-set punishment, 0 disables.
*	- Added sm_stk_punishmode, sm_stk_punishment, sm_stk_allowslay, sm_stkallowfreeze, sm_stk_allowbeacon, sm_stk_drugtime, and sm_stk_burntime. See documentation.
*	- Changed sm_stk_immunity to account for the new punishments. Now defaults to 7, as well as multiple additions. See documentation.
*
*	8/27/2008 - v0.6
*	- Added sm_stk_immunity cvar to change admin immunity.
*						0 - Disabled, no admin immunity.
*						1 - Admin immune to reflect damage and spawn slaying.
*						2 - Admin immune to being kicked for TKing.
*						3 - Both options 1 and 2
*	- Changed translations to work with the new command. (Update both files)
*
*	8/25/2008 - v0.5a
*	- Changed the auto-forgive to be more consistent.
*	- Fixed a bug where slaying in spawn wouldn't work if reflect damage was turned off sometimes.
*	- Changed display to show when a player was slayed for too much TA vs. TAing in spawn.
*
*	8/24/2008 - v0.5
*	- Changed how the message management was done to clean it up a bit.
*	- Fixed a bug where an invalid client was being referenced.
*	- Changed the kick message to show the kicked player's Steam ID (update translations)
*	- Added logging to show who is kicked for TKing.
*	- Fixed a bug where the player would sometimes not be killed after a TK with reflect damage on.
*	- Changed the in spawn killing routine to make sure the person dies. (No more stuck in the skybox)
*	- Added German translations thanks to tObIwAnKeNoBi
*	- Removed some unneeded code.
*	- Added the ability to slay spawn attackers for a certain amount of time after the victim spawns.
*	- Added sm_stk_protecttime to manage this function.
*	- If a player still has a forgive menu open, all TKs done to that player are now autoforgiven.
*	- Removed the "exit" button from the forgive menu. It is a yes or no question, make a choice.
*
*	8/23/2008 - v0.4
*	- Fixed TK count not being reset after a player is kicked.
*	- Fixed a bug where TKers in spawn would not die with reflect damage enabled. (If players are alive after being "suicided" their health is set to 1 and then they are dropped a large distance to their death)
*	- Changed the way i did reflect damage (it was based on the first version of Reflect Team Damage instead of the second)
*	- Changed "sm_stk_messagetype" to "sm_stk_forgivemessage"
*	- Added a message that informs the TKer of how many TKs they have and how many they need until they are kicked.
*	- Added "sm_stk_countmessage" to manage who sees this message.
*	- Added "sm_stk_kickmessage" to manage who sees the message when a player is kicked for TKing.
*	- Fixed a bug where the TK manager would not work if reflect was off.
*
*	8/23/2008 - v0.3
*	- Fixed some minor warning.
*	- Fixed menu not showing up properly.
*	- Fixed bugs where client was <= 0
*
*	8/22/2008 - v0.2
*	- Added the ability to forgive players who TKed from a menu.
*	- Added a CVAR to change the who the forgive/did not forgive messages are displayed to.
*
*	8/22/2008 - v0.1
*	- Initial Release
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0d"

#define ALLIES 2
#define AXIS 3

new HideTeamswitchMsg[MAXPLAYERS + 1];
new TKCount[MAXPLAYERS + 1] = {0, ...};
new TKerClient[MAXPLAYERS + 1] = {-1, ...};
new VictimClient[MAXPLAYERS + 1];
new SpawnTime[MAXPLAYERS + 1] = {0, ...};

new String:PunishmentClient[MAXPLAYERS + 1][MAXPLAYERS + 1];
new String:logFileName[PLATFORM_MAX_PATH];

new money_offset = -1;
new bool:isCSS = false;

new Handle:external_ban = INVALID_HANDLE;

new Handle:g_CvarEnabled;
new Handle:g_CvarReflect;
new Handle:g_CvarTKLimit;
new Handle:g_CvarForgive;
new Handle:g_CvarCount;
new Handle:g_CvarPunishMsg;
new Handle:g_CvarKickMsg;
new Handle:g_CvarSpawnProtect;
new Handle:g_CvarImmunity;
new Handle:g_CvarPunishMode;
new Handle:g_CvarPunishment;
new Handle:g_CvarUseSlay;
new Handle:g_CvarUseFreeze;
new Handle:g_CvarUseBeacon;
new Handle:g_CvarUseFreezeBomb;
new Handle:g_CvarUseFireBomb;
new Handle:g_CvarUseTimeBomb;
new Handle:g_CvarDrugTime;
new Handle:g_CvarBurnTime;
new Handle:g_CvarSlapDamage;
new Handle:g_CvarBanTime;
new Handle:g_CvarRemoveCash;
new Handle:g_CvarLogging;

public Plugin:myinfo =
{
	name = "Simple TK Manager",
	author = "Lebson506th",
	description = "A very simple TK manager plugin that includes reflected damage.",
	version = PLUGIN_VERSION,
	url = "http://www.506th-pir.org/"
};

public OnPluginStart() {
	LoadTranslations("simpletk.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_stk_version", PLUGIN_VERSION, "Simple TK Manager plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_CvarEnabled = CreateConVar("sm_stk_enabled","1","Enables(1) or disables(0) the plugin.");
	g_CvarReflect = CreateConVar("sm_stk_reflect","1","Enables(1) or disables(0) reflecting damage back onto a team attacker.");
	g_CvarTKLimit = CreateConVar("sm_stk_limit","5","Sets the number of TKs a player has to get before they are automatically kicked.");
	g_CvarForgive = CreateConVar("sm_stk_forgivemessage","1","Changes who the forgiven and not forgiven messages can be seen by. 0 - Nobody, 1 - Everyone, 2 - People involved, 3 - Admin and people involved, 4 - Admins only");
	g_CvarCount = CreateConVar("sm_stk_countmessage","2","Changes who the TK count message can be seen by. 0 - Nobody, 1 - Everyone, 2 - Person, 3 - Admin and person, 4 - Admins only");
	g_CvarPunishMsg = CreateConVar("sm_stk_punishmessage","1","Changes who the punishment messages can be seen by. 0 - Nobody, 1 - Everyone, 2 - People involved, 3 - Admin and people involved, 4 - Admins only");
	g_CvarKickMsg = CreateConVar("sm_stk_kickmessage","1","Show a message to everyone(1) or admin only (2) when a player is kicked for TKing. 0 to disable");
	g_CvarSpawnProtect = CreateConVar("sm_stk_protecttime","10","Automatically slay any team attacker in spawn during this amount of seconds after spawn");
	g_CvarImmunity = CreateConVar("sm_stk_immunity","7","Manages admin immunity mode. See documentation for full value list.");
	g_CvarPunishMode = CreateConVar("sm_stk_punishmode","1","Manages the TKer punishment modes. 0 - No additional punishment. 1 - Let the victim choose. 2 - Use sm_stk_punishment");
	g_CvarPunishment = CreateConVar("sm_stk_punishment","1","Manages the TKer punishment if sm_stk_punishmode = 2. 0 - Warn, 1 - Slay, 2 - Burn, 3 - Freeze, 4 - Beacon, 5 - Freeze Bomb, 6 - Fire Bomb, 7 - Time Bomb, 8 - Drug, 9 - Remove % Cash, 10 - Slap");
	g_CvarUseSlay = CreateConVar("sm_stk_allowslay","1","If sm_stk_punishmode = 1, allow slaying the attacker as a punishment.");
	g_CvarUseFreeze = CreateConVar("sm_stk_allowfreeze","1","If sm_stk_punishmode = 1, allow freezing the attacker as a punishment.");
	g_CvarUseBeacon = CreateConVar("sm_stk_allowbeacon","1","If sm_stk_punishmode = 1, allow putting a beacon on the attacker as a punishment.");
	g_CvarUseFreezeBomb = CreateConVar("sm_stk_allowfreezebomb","1","If sm_stk_punishmode = 1, allow putting a freezebomb on the attacker as a punishment.");
	g_CvarUseFireBomb = CreateConVar("sm_stk_allowfirebomb","1","If sm_stk_punishmode = 1, allow putting a firebomb on the attacker as a punishment.");
	g_CvarUseTimeBomb = CreateConVar("sm_stk_allowtimebomb","1","If sm_stk_punishmode = 1, allow putting a timebomb on the attacker as a punishment.");
	g_CvarDrugTime = CreateConVar("sm_stk_drugtime","10","If sm_stk_punishmode = 1, set the time a TKer is drugged as a punishment. 0.0 to disable.");
	g_CvarBurnTime = CreateConVar("sm_stk_burntime","10","If sm_stk_punishmode = 1, set the time a TKer is burnt as a punishment. 0.0 to disable.");
	g_CvarSlapDamage = CreateConVar("sm_stk_slapdamage","5","If sm_stk_punishmode = 1, slap the TKer for this amount of damage as a punishment. 0 to disable.");
	g_CvarBanTime = CreateConVar("sm_stk_bantime","-1","Manages how long a player is banned for once they reach the TK limit. (Less than 0 is a kick)");
	g_CvarRemoveCash = CreateConVar("sm_stk_removecash","25","Sets the percentage of cash the victim can remove from the attacker. 0 to disable. Only for CSS.");
	g_CvarLogging = CreateConVar("sm_stk_logging","2","Sets the logging mode. 0 = No logging, 1 = Verbose logging, 2 = Only log TK Count and \"Kicked\" messages, 3 = Only log \"Kicked\" messages");

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);

	HookConVarChange(g_CvarEnabled, OnEnableChanged);
	HookConVarChange(g_CvarReflect, OnReflectChanged);
	HookConVarChange(g_CvarSpawnProtect, OnProtectChanged);

	new Handle:spawnprotect = FindConVar("mp_spawnprotectiontime");

	if( spawnprotect != INVALID_HANDLE )
		SetConVarInt(spawnprotect, 0);

	decl String:gameName[80];
	GetGameFolderName(gameName, 80);

	isCSS = StrEqual(gameName, "cstrike");
	if(isCSS) {
		money_offset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if(money_offset == 1)
			SetFailState("Money offset could not be found.");
	}

	AutoExecConfig(true, "plugin.simpletk");
}

/*
	On CVAR changed functions to hook and unhook needed events.
*/

public OnEnableChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "0") == 0)
			UnhookEvent("player_death", Event_PlayerDeath);
		else if (strcmp(newval, "1") == 0)
			HookEvent("player_death", Event_PlayerDeath);
	}
}

public OnReflectChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "0") == 0 && GetConVarInt(g_CvarSpawnProtect) <= 0)
			UnhookEvent("player_hurt", Event_PlayerHurt);
		else if (strcmp(newval, "1") == 0)
			HookEvent("player_hurt", Event_PlayerHurt);
	}
}

public OnProtectChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (StringToInt(newval) <= 0) {
			if(!GetConVarBool(g_CvarReflect))
				UnhookEvent("player_hurt", Event_PlayerHurt);

			UnhookEvent("player_spawn", Event_PlayerSpawn);
		}
		else {
			if(!GetConVarBool(g_CvarReflect))
				HookEvent("player_hurt", Event_PlayerHurt);

			HookEvent("player_spawn", Event_PlayerSpawn);
		}
	}
}

/*
	Handlers to reset variables on disconnect and map start.
*/

public OnMapStart() {
	decl String:ctime[64];

	FormatTime(ctime, sizeof(ctime), "logs/stk_log_%m%d%Y.log");
	BuildPath(Path_SM, logFileName, sizeof(logFileName), ctime);
}

public OnClientPostAdminCheck(client) {
	ResetVariables(client);
}

public OnClientDisconnect(client) {
	ResetVariables(client);
}

public ResetVariables(client) {
	TKCount[client] = 0;
	TKerClient[client] = -1;
	PunishmentClient[client] = "";
	VictimClient[client] = -1;
	HideTeamswitchMsg[client] = 0;
}

/*
	Handler to deal with slaying.
	Also deal with spawn slaying not working in DoD:S
*/

public KillHandler(victim, attacker, bool:spawn) {
	new String:gamename[32];
	new bool:NoForceKill;
	GetGameFolderName(gamename, sizeof(gamename));

	NoForceKill = StrEqual(gamename,"insurgency",false);

	if(NoForceKill)
		ClientCommand(attacker, "kill");
	else {
		ForcePlayerSuicide(attacker);

		// Player wasn't killed. Usually happens in DoD:S when the player is in spawn.
		if(IsPlayerAlive(attacker)) {
			//This code thanks to FeuerSturm.
			new Team = GetClientTeam(attacker);
			new OpTeam = Team == ALLIES ? AXIS : ALLIES;

			SecretTeamSwitch(attacker, OpTeam);
			SecretTeamSwitch(attacker, Team);
			//End of FeuerSturm's code.
		}
	}

	new String:Msg[128];

	if(spawn)
		Format(Msg, sizeof(Msg), "%t", "Spawn");
	else
		Format(Msg, sizeof(Msg), "%t", "TKSlayed");
	
	PrintToChat(attacker, Msg);

	if(GetConVarInt(g_CvarLogging) == 1)
		LogToFile(logFileName, Msg);
}

//This code thanks to FeuerSturm.

/*
	Player team handler.
	Suppresses the team join message
	when a player is being switched silently.
*/

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(HideTeamswitchMsg[client] == 1) {
		HideTeamswitchMsg[client] = 0;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/*
	Helper method to switch a player's team silently.
	Used to kill players in spawn if there is built in spawn protection.
*/

stock SecretTeamSwitch(client, newteam) {
	HideTeamswitchMsg[client] = 1;
	ChangeClientTeam(client, newteam);
	ShowVGUIPanel(client, newteam == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false);
}

//End of FeuerSturm's code.

/*
	Player spawn handler.
	Remembers spawn time for spawn attack protection.
*/

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarInt(g_CvarSpawnProtect) > 0) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if(client > 0 && IsClientInGame(client))
			SpawnTime[client] = GetTime();
	}
}

/*
	Player hurt handler.
	Deals with reflecting damage and spawn slaying.
*/

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetConVarBool(g_CvarEnabled)) {
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));

		if(attacker > 0 && IsClientInGame(attacker)) {
			if((GetConVarInt(g_CvarImmunity) == 1 || GetConVarInt(g_CvarImmunity) == 3 || GetConVarInt(g_CvarImmunity) == 7) &&
				GetUserAdmin(attacker) != INVALID_ADMIN_ID) {
				return;
			}

			new bool:spawnAttack = ((GetTime() - SpawnTime[victim]) <= GetConVarInt(g_CvarSpawnProtect));

			if(GetConVarBool(g_CvarReflect) || spawnAttack) {
				if(victim > 0 && IsClientInGame(victim)) {
					if(IsPlayerAlive(attacker) && GetClientTeam(attacker) == GetClientTeam(victim) && victim != attacker) {
						new victimLost = GetEventInt(event,"damage");
						new victimHealth = GetClientHealth(victim) + victimLost;
						new attackerHealth = GetClientHealth(attacker) - victimLost;

						if(victimHealth > 100)
							SetEntityHealth(victim, 100);
						else
							SetEntityHealth(victim, victimHealth);

						if(spawnAttack)
							KillHandler(victim, attacker, true);
						else if(attackerHealth <= 0)
							KillHandler(victim, attacker, false);
						else
							SetEntityHealth(attacker, attackerHealth);
					}
				}
			}
		}
	}
}

/*
	Player Death handler.
	Calls the forgive menu if a TK occurs unless
	the attacker is an immune admin.
	Also handles reflecting a kill back onto the attacker.
*/

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetConVarBool(g_CvarEnabled)) {
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if(attacker > 0 && victim > 0 && IsClientInGame(attacker) && IsClientInGame(victim)) {
			if(GetClientTeam(attacker) == GetClientTeam(victim) && victim != attacker) {
				if((GetConVarInt(g_CvarImmunity) == 6 || GetConVarInt(g_CvarImmunity) == 7) &&
					GetUserAdmin(attacker) != INVALID_ADMIN_ID) {
					new String:attackerName[32];
					new String:victimName[32];
					new String:ForgiveMsg[128];

					GetClientName(attacker, attackerName, 31);
					GetClientName(victim, victimName, 31);
					Format(ForgiveMsg, sizeof(ForgiveMsg), "%t", "Auto Forgave Admin", victimName, attackerName);

					DoChat(victim, attacker, ForgiveMsg, ForgiveMsg, GetConVarInt(g_CvarForgive), false);
					return;
				}

				if(IsPlayerAlive(attacker) && GetConVarBool(g_CvarReflect)) {
					if((GetConVarInt(g_CvarImmunity) != 1 && GetConVarInt(g_CvarImmunity) != 3 &&
						GetConVarInt(g_CvarImmunity) != 5 && GetConVarInt(g_CvarImmunity) != 7) ||
						GetUserAdmin(attacker) == INVALID_ADMIN_ID) {
						KillHandler(victim, attacker, false);
					}
				}

				if(TKerClient[victim] == -1)
					ForgiveMenu(attacker, victim);
				else {
					new String:attackerName[32];
					new String:victimName[32];
					new String:ForgiveMsg[128];

					GetClientName(attacker, attackerName, 31);
					GetClientName(victim, victimName, 31);
					Format(ForgiveMsg, sizeof(ForgiveMsg), "%t", "Auto Forgave", victimName, attackerName);

					DoChat(victim, attacker, ForgiveMsg, ForgiveMsg, GetConVarInt(g_CvarForgive), false);
				}
			}
		}
	}
}

/*
	Forgive menu handlers.
*/

public Action:ForgiveMenu(attacker, victim) {
	if(attacker <= MaxClients && victim <= MaxClients && attacker > 0 && victim) {
		if(IsClientInGame(attacker) && IsClientInGame(victim)) {
			TKerClient[victim] = attacker;

			new Handle:menu = CreateMenu(AdminMenuHandler);
			new String:attackerName[32];

			GetClientName(attacker, attackerName, 31);

			SetMenuTitle(menu, "%t", "ForgiveMenu", attackerName);

			new String:yes[128];
			new String:no[128];
			Format(yes, sizeof(yes), "%t", "Yes");
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no), "%t", "No");
			AddMenuItem(menu, "no", no);

			SetMenuExitButton(menu, false);
			DisplayMenu(menu, victim, MENU_TIME_FOREVER);
		}
	}

	return Plugin_Handled;
}

public AdminMenuHandler(Handle:menu, MenuAction:action, client, itemNum) {
	if ( action == MenuAction_Select ) {
		if(client > 0 && IsClientInGame(client)) {
			new attacker = TKerClient[client];
			TKerClient[client] = -1;

			if(attacker > 0 && IsClientInGame(attacker)) {
				new String:attackerName[32];
				new String:victimName[32];
				new String:info[32];

				GetClientName(attacker, attackerName, 31);
				GetClientName(client, victimName, 31);
				GetMenuItem(menu, itemNum, info, sizeof(info));

				if ( strcmp(info,"yes") == 0 ) {
					new String:ForgiveMsg[128];
					Format(ForgiveMsg, sizeof(ForgiveMsg), "%t", "Forgave", victimName, attackerName);

					DoChat(client, attacker, ForgiveMsg, ForgiveMsg, GetConVarInt(g_CvarForgive), false);
				}
				else if ( strcmp(info,"no") == 0 )
					DidNotForgive(attacker, client, victimName);
			}
		}
	}
	else if ( action == MenuAction_End )
		CloseHandle(menu);
}

/*
	Punishment menu handlers.
*/

public Action:PunishMenu(victim, attacker) {
	if(attacker <= MaxClients && victim <= MaxClients && attacker > 0 && victim) {
		if(IsClientInGame(attacker) && IsClientInGame(victim)) {
			TKerClient[victim] = attacker;

			new Handle:menu = CreateMenu(PunishMenuHandler);
			new String:attackerName[32];

			GetClientName(attacker, attackerName, 31);

			SetMenuTitle(menu, "%t", "PunishMenu", attackerName);

			new String:warn[128];
			Format(warn, sizeof(warn), "%t", "Warn");
			AddMenuItem(menu, "warn", warn);

			if(GetConVarInt(g_CvarSlapDamage) > 0) {
				new String:slap[128];
				Format(slap, sizeof(slap), "%t", "Slap");
				AddMenuItem(menu, "slap", slap);
			}

			if(GetConVarBool(g_CvarUseSlay)) {
				new String:slay[128];
				Format(slay, sizeof(slay), "%t", "Slay");
				AddMenuItem(menu, "slay", slay);
			}

			if(GetConVarInt(g_CvarBurnTime) > 0) {
				new String:burn[128];
				Format(burn, sizeof(burn), "%t", "Burn");
				AddMenuItem(menu, "burn", burn);
			}

			if(GetConVarBool(g_CvarUseFreeze)) {
				new String:freeze[128];
				Format(freeze, sizeof(freeze), "%t", "Freeze");
				AddMenuItem(menu, "freeze", freeze);
			}

			if(GetConVarBool(g_CvarUseBeacon)) {
				new String:beacon[128];
				Format(beacon, sizeof(beacon), "%t", "Beacon");
				AddMenuItem(menu, "beacon", beacon);
			}

			if(GetConVarBool(g_CvarUseFreezeBomb)) {
				new String:freezebomb[128];
				Format(freezebomb, sizeof(freezebomb), "%t", "FreezeBomb");
				AddMenuItem(menu, "freezebomb", freezebomb);
			}

			if(GetConVarBool(g_CvarUseFireBomb)) {
				new String:firebomb[128];
				Format(firebomb, sizeof(firebomb), "%t", "FireBomb");
				AddMenuItem(menu, "firebomb", firebomb);
			}

			if(GetConVarBool(g_CvarUseTimeBomb)) {
				new String:timebomb[128];
				Format(timebomb, sizeof(timebomb), "%t", "TimeBomb");
				AddMenuItem(menu, "timebomb", timebomb);
			}

			if(GetConVarInt(g_CvarDrugTime) > 0) {
				new String:drug[128];
				Format(drug, sizeof(drug), "%t", "Drug");
				AddMenuItem(menu, "drug", drug);
			}

			if(isCSS && GetConVarInt(g_CvarRemoveCash) > 0) {
				new String:cash[128];
				Format(cash, sizeof(cash), "%t", "RemoveCash", GetConVarInt(g_CvarRemoveCash));
				AddMenuItem(menu, "removecash", cash);
			}

			SetMenuExitButton(menu, false);
			DisplayMenu(menu, victim, MENU_TIME_FOREVER);
		}
	}

	return Plugin_Handled;
}

public PunishMenuHandler(Handle:menu, MenuAction:action, client, itemNum) {
	if ( action == MenuAction_Select ) {
		if(client > 0 && IsClientInGame(client)) {
			new attacker = TKerClient[client];
			TKerClient[client] = -1;

			if(attacker > 0 && IsClientInGame(attacker)) {
				new String:info[32];
				GetMenuItem(menu, itemNum, info, sizeof(info));

				if(IsPlayerAlive(attacker))
					PunishHandler(client, attacker, info);
				else {
					PunishmentClient[attacker] = info;
					CreateTimer(5.0, WaitForSpawn, attacker, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	else if ( action == MenuAction_End )
		CloseHandle(menu);
}

/*
	Handler for when a player is not forgiven.
	Made it a function because i used it twice.
*/

public DidNotForgive(attacker, client, String:victimName[32]) {
	if(attacker > 0 && client > 0 && IsClientInGame(attacker) && IsClientInGame(client)) {
		new String:attackerName[32];
		GetClientName(attacker, attackerName, 31);

		if((GetConVarInt(g_CvarImmunity) != 2 && GetConVarInt(g_CvarImmunity) != 3 &&
			GetConVarInt(g_CvarImmunity) != 6 && GetConVarInt(g_CvarImmunity) != 7) ||
			GetUserAdmin(attacker) == INVALID_ADMIN_ID) {
			TKCount[attacker] = TKCount[attacker] + 1;
			
			if(GetConVarInt(g_CvarCount) > 0 && GetConVarInt(g_CvarCount) < 5) {
				new String:TKCountMsg[128];
				Format(TKCountMsg, sizeof(TKCountMsg), "%t", "TK Count Others", attackerName, TKCount[attacker], GetConVarInt(g_CvarTKLimit));
				new String:TKCountMsg2[128];
				Format(TKCountMsg2, sizeof(TKCountMsg2), "%t", "TK Count", TKCount[attacker], GetConVarInt(g_CvarTKLimit));

				DoChat(client, attacker, TKCountMsg, TKCountMsg2, GetConVarInt(g_CvarCount), true);
			}
		}

		if(GetConVarInt(g_CvarForgive) > 0 && GetConVarInt(g_CvarForgive) < 5) {
			new String:DidNotForgiveMsg[128];
			Format(DidNotForgiveMsg, sizeof(DidNotForgiveMsg), "%t", "Did Not Forgive", victimName, attackerName);

			DoChat(client, attacker, DidNotForgiveMsg, DidNotForgiveMsg, GetConVarInt(g_CvarForgive), false);
		}

		if(TKCount[attacker] >= GetConVarInt(g_CvarTKLimit)) {
			new String:attackerID[32];
			GetClientAuthString(attacker, attackerID, 31);

			if(GetConVarInt(g_CvarBanTime) < 0)
				KickClient(attacker, "%t", "TK Limit Reached");
			else {
				new String:reason[128];
				new time = GetConVarInt(g_CvarBanTime);
				Format(reason, sizeof(reason), "%t", "TK Limit Reached");

				external_ban = FindConVar("sb_version");

				//SourceBans integration
				if ( external_ban != INVALID_HANDLE ) {
					ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(attacker), time, reason);
	
					CloseHandle(external_ban);
				}
				else {
					external_ban = FindConVar("mysql_bans_version");
	
					//MySQL Bans integration
					if ( external_ban != INVALID_HANDLE ) {
						ServerCommand("mysql_ban #%d %d \"%s\"", GetClientUserId(attacker), time, reason);
	
						CloseHandle(external_ban);
					}
					else //Normal Ban
						BanClient(attacker, time, BANFLAG_AUTHID, reason, reason);
				}
			}

			if(GetConVarInt(g_CvarLogging) > 0)
				LogToFile(logFileName, "%t", "Kicked", attackerName, attackerID);

			if(GetConVarInt(g_CvarKickMsg) == 1)
				PrintToChatAll("[STK] %t", "Kicked", attackerName, attackerID);
			else if(GetConVarInt(g_CvarKickMsg) == 2) {
				for(new a=1; a<=MaxClients;a++) {
					if(IsClientInGame(a) && GetUserAdmin(a) != INVALID_ADMIN_ID && a != attacker)
						PrintToChat(a, "[STK] %t", "Kicked", attackerName, attackerID);
				}
			}
		}
		else if((GetConVarInt(g_CvarImmunity) < 4 && GetConVarInt(g_CvarImmunity) >= 0) || GetUserAdmin(attacker) == INVALID_ADMIN_ID) {
			if(GetConVarInt(g_CvarPunishMode) == 1)
				PunishMenu(client, attacker);
			else if(GetConVarInt(g_CvarPunishMode) == 2) {
				new String:punishment[32];

				switch(GetConVarInt(g_CvarPunishment)) {
					case 0:
						punishment = "warn";
					case 1:
						punishment = "slay";
					case 2:
						punishment = "burn";
					case 3:
						punishment = "freeze";
					case 4:
						punishment = "beacon";
					case 5:
						punishment = "freezebomb";
					case 6:
						punishment = "firebomb";
					case 7:
						punishment = "timebomb";
					case 8:
						punishment = "drug";
					case 9:
						punishment = "removecash";
					case 10:
						punishment = "slap";
					default:
						punishment = "warn";
				}

				if(IsPlayerAlive(attacker))
					PunishHandler(client, attacker, punishment);
				else {
					PunishmentClient[attacker] = punishment;
					VictimClient[attacker] = client;
					CreateTimer(5.0, WaitForSpawn, attacker, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

/*
	Punishment helper method
*/

public PunishHandler(client, attacker, String:punishment[32]) {
	if(client > 0 && IsClientInGame(client)) {
		if(attacker > 0 && IsClientInGame(attacker)) {
			new String:attackerName[32];
			new String:victimName[32];
			new String:PunishMsg[128];

			GetClientName(attacker, attackerName, 31);
			GetClientName(client, victimName, 31);

			if ( strcmp(punishment, "warn", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "Warned", victimName, attackerName);
			}
			else if ( strcmp(punishment, "slay", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "Slayed", victimName, attackerName);

				KillHandler(client, attacker, false);
			}
			else if ( strcmp(punishment, "slap", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "Slapped", victimName, attackerName, GetConVarInt(g_CvarSlapDamage));

				SlapPlayer(attacker, GetConVarInt(g_CvarSlapDamage));
			}
			else if ( strcmp(punishment, "burn", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "Burnt", victimName, attackerName);

				ServerCommand("sm_burn \"%s\" 10", attackerName);
			}
			else if ( strcmp(punishment, "freeze", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "Froze", victimName, attackerName);

				ServerCommand("sm_freeze \"%s\"", attackerName);
			}
			else if ( strcmp(punishment, "beacon", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "Beaconed", victimName, attackerName);

				ServerCommand("sm_beacon \"%s\"", attackerName);
			}
			else if ( strcmp(punishment, "freezebomb", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "FreezeBombed", victimName, attackerName);

				ServerCommand("sm_freezebomb \"%s\"", attackerName);
			}
			else if ( strcmp(punishment, "firebomb", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "FireBombed", victimName, attackerName);

				ServerCommand("sm_firebomb \"%s\"", attackerName);
			}
			else if ( strcmp(punishment, "timebomb", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "TimeBombed", victimName, attackerName);

				ServerCommand("sm_timebomb \"%s\"", attackerName);
			}
			else if ( strcmp(punishment, "drug", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "Drugged", victimName, attackerName);

				CreateTimer(GetConVarFloat(g_CvarDrugTime), Undrug, attacker, TIMER_FLAG_NO_MAPCHANGE);
				ServerCommand("sm_drug \"%s\"", attackerName);
			}
			else if ( strcmp(punishment, "removecash", false) == 0 ) {
				Format(PunishMsg, sizeof(PunishMsg), "%t", "CashRemoved", victimName, GetConVarInt(g_CvarRemoveCash), attackerName);

				new divisor = GetConVarInt(g_CvarRemoveCash) / 100;
				new cash = GetEntData(attacker, money_offset) * divisor;
				SetEntData(attacker, money_offset, cash);\
			}

			DoChat(client, attacker, PunishMsg, PunishMsg, GetConVarInt(g_CvarPunishMsg), false);
		}
	}
}

/*
	Chat helper method.
*/

public DoChat(victim, attacker, String:msg1[128], String:msg2[128], cvar, bool:isCount) {
	new logMode = GetConVarInt(g_CvarLogging);

	if(logMode && ((logMode == 1) || ((logMode == 2) && isCount))) {
		new String:aid[32], String:vid[32];

		GetClientAuthString(attacker, aid, sizeof(aid));
		GetClientAuthString(victim, vid, sizeof(vid));

		LogToFile(logFileName, "%s (A: %s V: %s)", msg1, aid, vid);
	}

	if(cvar == 1)
		PrintToChatAll("[STK] %s", msg1);
	else {
		if(cvar > 1 && cvar <= 4) {
			for(new a = 1; a <= MaxClients; a++) {
				if(IsClientInGame(a)) {
					if(GetUserAdmin(a) != INVALID_ADMIN_ID) {
						if(cvar == 3 || cvar == 4)
							PrintToChat(a, "[STK] %s", msg1);
					}
					else if(a == victim && (cvar == 2 || cvar == 3))
						PrintToChat(victim, "[STK] %s", msg1);
					else if(a == attacker && (cvar == 2 || cvar== 3))
						PrintToChat(attacker, "[STK] %s", msg2);
				}
			}
		}
	}
}

/*
	Undrug handler to undrug a player after sm_stk_drugtime
*/

public Action:Undrug(Handle:timer, any:client) {
	if(client > 0 && IsClientInGame(client)) {
		new String:clientName[32];
		GetClientName(client, clientName, 31);

		ServerCommand("sm_undrug \"%s\"", clientName);
	}

	return Plugin_Handled;
}

/*
	Handler to deal punishment to a TKer if he/she was dead when the punishment was to be dealt.
*/

public Action:WaitForSpawn(Handle:timer, any:attacker) {
	if(attacker > 0 && IsClientInGame(attacker)) {
		new victim = VictimClient[attacker];
		VictimClient[attacker] = -1;

		if(victim > 0 && IsClientInGame(victim)) {
			if(IsPlayerAlive(attacker)) {
				new String:punishment[32];

				strcopy(punishment, 31, PunishmentClient[attacker]);
				PunishmentClient[attacker] = "";

				PunishHandler(victim, attacker, punishment);
			}
			else
				CreateTimer(5.0, WaitForSpawn, attacker, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Handled;
}