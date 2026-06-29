/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Survivor Upgrades - A modification for the game Left4Dead */

/* Note:  The upgrades were created by Valve - this mod simply makes them available. */

/* Version History
* 1.0
*		-Initial release.
* 1.1 
*      - Filtered out #L4D_Upgrade_laser_sight_expire text broadcast when turning off a laser.
*		- Added cvars to allow disabling of specific upgrades.  (Hot Meal is disabled, by default.)
*      - Added verbosity cvar.  0 for no messages, 1 for expire events only, 2 for expire events 
*        and short self messages, 3 for everything.
*      - Added potential fix for bots taking over for players getting upgrades.
* 1.2
*      - Filtered out #L4D_Upgrade_laser_sight_expire for real this time... :)
*      - Filtered out #L4D_NOTIFY_VOMIT_ON when a survivor with a raincoat was vomited on.
*      - Added code to deal with multiple tank_spawn events being generated.  If this event 
*        occurs twice within 15 seconds, only the first event will grant upgrades.
* 1.3
*      - Fixed bug in the error message displayed if someone with every upgrade were to get another.  (Thanks Number Six)
*      - Added incendiary ammo upgrade.
*      - Changed addUpgrade, giveRandomUpgrade, and removeUpgrade to be targeted, per tommy76's suggestions.
*      - Changed giveRandomUpgrade to giveRandomUpgrades, which now takes how many upgrades to give as a parameter.
*      - Changed addUpgrade, giveRandomUpgrade, and removeUpgrade to go through the rest of the mod's calls, 
*        rather than directly applying an upgrade.  (Prevents things like getting an upgrade twice.)  This also 
*        changes the index values to 1 to 15.
*      - Setting the allowed cvar for an upgrade to 2 will make it so that it is automatically given out to 
*        survivors at the start of a round. (Thanks again to tommy76.)
* 1.4
*      - Added colors to text messages (Thanks to Mecha the Slag)
*      - Fixed bug with incendiary ammo that occured in most games. (Thanks for the log, Number Six)
*      - Fixed logic error in random upgrade selection that made the last two upgrades very
*        unlikely to be picked.  (Thanks for the report, Sirenic.)
*/

/* KrX's Modified version - Version History
* 
* Version k1
* 		- Initial release. Changes from original version (Jerrith's v1.4):
* 		- Incorporated from MagnoT's modified release:
* 			- Fixed warning messages during mapchanges
* 			- Witches no longer burn forever
* 			- Added a Admin command to clean all client upgrades, 'cleanallupgrades'
* 			- Removed laseron and laseroff - laser toggles that (say /laser)
* 			- Only alive survivors can get upgrades
* 		- Incorporated and modified from MagnoT's modified release:
* 			- Fixed giving 1 extra upgrade at start of each round
* 			- Added showing of Help 20 seonds after connection to server
* 			- Added Help for clients: say /upghelp
* 		- Added modifications by KrX:
* 			- Fixed Help spamming Errors that client is not connected to server
* 			- Added command /upghelp2 to see at what times clients get upgrades
* 			- Fixed: /listupgrades now show even if Verbosity is 0
* 			- Added alternate command for /listupgrades: /upgrades
* 			- Added activation of Survivor Upgrades only on specific gamemodes, updates Help as well 
* 				(surup_enablecoop [1], surup_enablesv [1], surup_enablevs [0])
* 				Possible for Laser-only: disable upgrades on all gamemodes, then set  surup_always_laser to 1
* 			- Enable/Disable carrying Upgrades over to next Mission 
* 				(surup_reset_on_map_change [0])
* 			- Enable/Disable resetting of Upgrades when you lose any mission 
* 				(surup_reset_on_mission_lost [0])
* 			- Set Reloader Upgrade multiplier of weapons 
* 				(surup_reloader_speed [0.5], surup_reloader_shotgun_speed [0.5])
* 			- Fixed Flag for surup_upgrades_at_tank_spawn and added min/max values for ConVars
* 			- Fixed Survivors who went Idle/AFK and came back not getting their upgrades again
* 
* Version k2
*		vk2b1 (K2 Beta 1)
* 		- Fixed bug where survivors will get all upgrades if surup_upgrades_at_tank_spawn "0" and the tank is killed
* 		- Added primary attacker's name of the tank when broadcast to all if Verbosity > 2
* 		- Added option whether Incendiary Ammo upgrade lights Tank up
* 			(surup_ignite_tank [1])
* 			Please delete old survivor_upgrades_k.cfg or add surup_ignite_tank ConVar value to it.
* 		vk2b2 (K2 Beta 2)
*		- Attempted to fix Reloader and certain other upgrades not being given even though the client is notified that he has it
*		- Small code optimizations
*		- Fixed mission_lost not resetting if convar is set to reset in some cases
* 		vkb3 (K2 Beta 3)
* 		- Lots of Code optimizations
* 		- Option to ignite Tank with Incendiary Ammo now working (Adapted from AtomicStryker's specialammo plugin)
* 		- Added option to re-give initial upgrades when mission is lost instead of completely removing them
* 			(surup_reset_on_mission_lost - 0 = off, 1 = on, re-give initial, 2 = on, remove all upgrades)
* 			Please delete old survivor_upgrades_k.cfg
* 		- /upghelp now receives arguments. Say /upghelp 2 to see different categories of surup help.
* 			"/upghelp2" now obsolete. Replaced with: "/upghelp 2"
* 		- Fixed changelog formatting
* 		- Added PLUGIN_TAG to all PrintToChat and PrintToChatAll messages
* 		- Removed debug messages
*/

#include <sourcemod>
#include <sdktools>

#define NUPGRADES 31
#define NVALID 15

#define PLUGIN_VERSION "1.4k2b3"
#define PLUGIN_NAME "Survivor Upgrades_K"
#define PLUGIN_TAG "[SurUp]"

#pragma semicolon 1

//CTerrorPlayer::AddUpgrade(SurvivorUpgradeType)
//_ZN13CTerrorPlayer10AddUpgradeE19SurvivorUpgradeType
new Handle:AddUpgrade = INVALID_HANDLE;

//CTerrorPlayer::RemoveUpgrade(SurvivorUpgradeType)
//_ZN13CTerrorPlayer13RemoveUpgradeE19SurvivorUpgradeType
new Handle:RemoveUpgrade = INVALID_HANDLE;

//CTerrorPlayer::GiveRandomUpgrade()
//_ZN13CTerrorPlayer17GiveRandomUpgradeEv
//new Handle:GiveRandomUpgrade = INVALID_HANDLE;

new bool:bHooked = false;
new bool:bUpgraded[MAXPLAYERS+1];
new bool:bBotControlled[MAXPLAYERS+1];
new IndexToUpgrade[NVALID];
new bool:bClientHasUpgrade[MAXPLAYERS+1][NVALID];
new String:UpgradeShortInfo[NVALID][256];
new String:UpgradeLongInfo[NVALID][1024];
new Handle:UpgradeAllowed[NVALID];

// Give Upgrades ConVars
new Handle:AlwaysLaser = INVALID_HANDLE;
new Handle:UpgradesAtSpawn = INVALID_HANDLE;
new Handle:UpgradesAtWitchKillKiller = INVALID_HANDLE;
new Handle:UpgradesAtWitchKillAll = INVALID_HANDLE;
new Handle:UpgradesAtTankSpawn = INVALID_HANDLE;
new Handle:UpgradesAtTankKillKiller = INVALID_HANDLE;
new Handle:UpgradesAtTankKillAll = INVALID_HANDLE;
new Handle:IgniteTank = INVALID_HANDLE;
new Handle:ReloaderSpeed = INVALID_HANDLE;
new Handle:ReloaderShotgunSpeed = INVALID_HANDLE;
new Handle:Verbosity = INVALID_HANDLE;

// Reset ConVars
new Handle:ResetOnMissionLost = INVALID_HANDLE;
new Handle:ResetOnMapChange = INVALID_HANDLE;

// GameType checking ConVars
new Handle:cvar_EnableCoop = INVALID_HANDLE;
new Handle:cvar_EnableSv = INVALID_HANDLE;
new Handle:cvar_EnableVersus = INVALID_HANDLE;
new Handle:cvar_Gamemode = INVALID_HANDLE;
new String:g_CurrentMode[9];	// Longest string: "survival", 8 chars (8+1)

new bool:bBlockUntilRoundStart;
new bool:bBlockTankSpawn;
new bool:bIgniteTank = false;
new bool:g_bIsSUEnabled = false;
new bool:g_bBroadcast = false;
new bool:g_InvalidGameMode = false;
new bool:t_MissionLost = false;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	// Try the windows version first.
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\xA1****\x83***\x57\x8B\xF9\x0F*****\x8B***\x56\x51\xE8****\x8B\xF0\x83\xC4\x04", 34))
	{
		PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer10AddUpgradeE19SurvivorUpgradeType", 0);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	AddUpgrade = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x51\x53\x55\x8B***\x8B\xD9\x56\x8B\xCD\x83\xE1\x1F\xBE\x01\x00\x00\x00\x57\xD3\xE6\x8B\xFD\xC1\xFF\x05\x89***", 32))
	{
		PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer13RemoveUpgradeE19SurvivorUpgradeType", 0);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	RemoveUpgrade = EndPrepSDKCall();
	
	//StartPrepSDKCall(SDKCall_Player);
	//if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x83\xEC\x18\xA1****\x56\x33\xF6\x39\x70\x30\x89***\x0F*****\x53\x55\x57\x33\xED\x33\xDB\x33\xFF", 33))
	//{
	//	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer17GiveRandomUpgradeEv", 0);	
	//}
	//GiveRandomUpgrade = EndPrepSDKCall();
	
	IndexToUpgrade[0] = 1;
	UpgradeShortInfo[0] = "\x03Kevlar Body Armor \x05(Reduce Damage)";
	UpgradeLongInfo[0] = "This body armor helps you stay alive when attacked by infected.";
	UpgradeAllowed[0] = CreateConVar("surup_allow_kevlar_body_armor", "1", "Whether or not we give out the Kevlar Body Armor upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[1] = 8;
	UpgradeShortInfo[1] = "\x03Raincoat \x05(Ignore Boomer Vomit) \x01[Single Use]";
	UpgradeLongInfo[1] = "This raincoat stops boomer vomit from hitting you, however it is ruined in the process and only good for one use."; 
	UpgradeAllowed[1] = CreateConVar("surup_allow_raincoat", "1", "Whether or not we give out the Raincoat upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[2] = 11;
	UpgradeShortInfo[2] = "\x03Climbing Chalk \x05(Self Ledge Save) \x01[Single Use]";
	UpgradeLongInfo[2] = "This chalk allows you to get a good enough grip to pull yourself up from a ledge without help, however there's only enough to do it once.";
	UpgradeAllowed[2] = CreateConVar("surup_allow_climbing_chalk", "1", "Whether or not we give out the Climbing Chalk upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[3] = 12;
	UpgradeShortInfo[3] = "\x03Second Wind \x05(Self Revive) \x01[Single Use]";
	UpgradeLongInfo[3] = "This allows you to attempt to stand up by yourself, once, after being incapacitated.  Damage taken while getting up may cause the attempt to fail.";
	UpgradeAllowed[3] = CreateConVar("surup_allow_second_wind", "1", "Whether or not we give out the Second Wind upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[4] = 13;
	UpgradeShortInfo[4] = "\x03Goggles \x05(See through Boomer Vomit)";
	UpgradeLongInfo[4] = "This allows you to still see clearly after being vomited on.  Does not prevent infected from swarming!";
	UpgradeAllowed[4] = CreateConVar("surup_allow_goggles", "1", "Whether or not we give out the Goggles upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[5] = 16;
	UpgradeShortInfo[5] = "\x03Hot Meal \x05(Health Bonus)";
	UpgradeLongInfo[5] = "Don't you feel better after a good hot meal?  Raises your health to 150.";
	UpgradeAllowed[5] = CreateConVar("surup_allow_hot_meal", "0", "Whether or not we give out the Hot Meal upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[6] = 17;
	UpgradeShortInfo[6] = "\x03Laser Sight \x05(Bright Red Beam)";
	UpgradeLongInfo[6] = "The laser helps you aim more accurately at your targets.";
	UpgradeAllowed[6] = CreateConVar("surup_allow_laser_sight", "2", "Whether or not we give out the Laser Sight upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[7] = 19;
	UpgradeShortInfo[7] = "\x03Combat Sling \x05(Reduced Recoil)";
	UpgradeLongInfo[7] = "This reduces the effects of recoil when firing your weapons.";
	UpgradeAllowed[7] = CreateConVar("surup_allow_combat_sling", "1", "Whether or not we give out the Combat Sling upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[8] = 20;
	UpgradeShortInfo[8] = "\x03Large Clip \x05(Increase ammo clip capacity)";
	UpgradeLongInfo[8] = "This provides an increase in the number of shots you can take before having to reload.";
	UpgradeAllowed[8] = CreateConVar("surup_allow_large_clip", "1", "Whether or not we give out the Large Clip upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[9] = 21;
	UpgradeShortInfo[9] = "\x03Hollow Point Ammo \x05(Increased bullet damage)";
	UpgradeLongInfo[9] = "This ammo allows you to deal more damage to the infected you shoot at.  Common infected die in an explosion of blood.";
	UpgradeAllowed[9] = CreateConVar("surup_allow_hollow_point_ammo", "1", "Whether or not we give out the Hollow Point Ammo upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[10] = 26;
	UpgradeShortInfo[10] = "\x03Knife \x05(Escape Hunter or Smoker restraint) \x01[Single Use]";
	UpgradeLongInfo[10] = "This knife allows you to escape from a hunter or smoker that has trapped you, however it is ruined in the process.";
	UpgradeAllowed[10] = CreateConVar("surup_allow_knife", "1", "Whether or not we give out the Knife upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[11] = 27;
	UpgradeShortInfo[11] = "\x03Smelling Salts \x05(Fast Revive of other players)";
	UpgradeLongInfo[11] = "These smelling salts allow you to revive another player faster than normal.";
	UpgradeAllowed[11] = CreateConVar("surup_allow_smelling_salts", "1", "Whether or not we give out the Smelling Salts upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[12] = 28;
	UpgradeShortInfo[12] = "\x03Ointment \x05(Increased Run Speed when injured)";
	UpgradeLongInfo[12] = "This ointment increases your run speed while you are injured.";
	UpgradeAllowed[12] = CreateConVar("surup_allow_ointment", "1", "Whether or not we give out the Ointment upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[13] = 29;
	UpgradeShortInfo[13] = "\x03Reloader \x05(Fast Reload)";
	UpgradeLongInfo[13] = "This reloader allows you to reload your weapons much faster than normal.";
	UpgradeAllowed[13] = CreateConVar("surup_allow_reloader", "1", "Whether or not we give out the Reloader upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	IndexToUpgrade[14] = 30;
	UpgradeShortInfo[14] = "\x03Incendiary Ammo \x05(Bullets cause fire)";
	UpgradeLongInfo[14] = "This ammo allows you to set on fire any infected you shoot with it.";
	UpgradeAllowed[14] = CreateConVar("surup_allow_incendiary_ammo", "1", "Whether or not we give out the Incendiary Ammo upgrade.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	// Game mode Cvars
	cvar_EnableCoop = CreateConVar("surup_enablecoop", "1", "Enable/Disable Survivor Upgrades in Coop", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableSv = CreateConVar("surup_enablesv", "1", "Enable/Disable Survivor Upgrades in Survival", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableVersus = CreateConVar("surup_enablevs", "0", "Enable/Disable Survivor Upgrades in Versus", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Gamemode = FindConVar("mp_gamemode");
	
	// Admin Commands
	RegAdminCmd("addupgrade", addUpgrade, ADMFLAG_KICK);
	RegAdminCmd("removeupgrade", removeUpgrade, ADMFLAG_KICK);
	RegAdminCmd("giverandomupgrades", giveRandomUpgrades, ADMFLAG_KICK);
	RegAdminCmd("removeallupgrades", removeAllUpgrades, ADMFLAG_KICK);
	// Client Commands
	RegConsoleCmd("listupgrades", ListUpgrades);
	RegConsoleCmd("upgrades", ListUpgrades);
	RegConsoleCmd("laser", LaserToggle);
	RegConsoleCmd("upghelp", UserHelp);
	
	AlwaysLaser = CreateConVar("surup_always_laser", "1", "Whether or not we _always_ give survivors the laser sight upgrade, Survivor Upgrades enabled or not", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	UpgradesAtSpawn = CreateConVar("surup_upgrades_at_spawn", "3", "How many random upgrades to give survivors when they spawn.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	UpgradesAtWitchKillKiller = CreateConVar("surup_upgrades_at_witch_kill_killer", "1", "How many random upgrades to give survivors when they personally kill the witch.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	UpgradesAtWitchKillAll = CreateConVar("surup_upgrades_at_witch_kill_all", "1", "How many random upgrades to give survivors when their team kills the witch.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	UpgradesAtTankSpawn = CreateConVar("surup_upgrades_at_tank_spawn", "1", "How many random upgrades to give survivors when a tank spawns.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	UpgradesAtTankKillKiller = CreateConVar("surup_upgrades_at_tank_kill_killer", "1", "How many random upgrades to give survivors when they personally kill the tank.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	UpgradesAtTankKillAll = CreateConVar("surup_upgrades_at_tank_kill_all", "1", "How many random upgrades to give survivors when their team kills the tank.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	IgniteTank = CreateConVar("surup_ignite_tank", "1", "Incendiary Ammo upgrade: Does it light the tank on fire?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ReloaderSpeed = CreateConVar("surup_reloader_speed", "0.5", "Reloader upgrade: How long should reloads take in seconds?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ReloaderShotgunSpeed = CreateConVar("surup_reloader_shotgun_speed", "0.5", "Reloader upgrade: How long should shotgun reloads take in seconds?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	ResetOnMissionLost = CreateConVar("surup_reset_on_mission_lost", "0", "Reset all upgrades and re-give initial upgrades on failing a mission? 0=false, 1=re-give initial, 2=lose all upgrades", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	ResetOnMapChange = CreateConVar("surup_reset_on_map_change", "0", "Reset all upgrades and re-give initial upgrades on map change (Proceeding to next mission)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	Verbosity = CreateConVar("surup_verbosity", "2", "How much text output about upgrades players see (0 = none, 3 = max, default 2).", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	CreateConVar("surup_version", PLUGIN_VERSION, "The version of Survivor Upgrades plugin. CVAR Help: 0=Off, 1=On, 2=Give at Start", FCVAR_PLUGIN);
	
	// Don't hook unneccesarily if we're not gonna use them
	if(!g_InvalidGameMode) {
		ActivateHooks();
		// Client say commands, used to remove all the #L4D_Upgrade stuff
		HookUserMessage(GetUserMessageId("SayText"), SayTextHook, true);
	} else {
		if(GetConVarInt(AlwaysLaser)) {
			HookEvent("player_team", Event_PlayerTeam);	// Must enable always for alwayslaser to work
			// Client say commands, used to remove all the #L4D_Upgrade stuff
			HookUserMessage(GetUserMessageId("SayText"), SayTextHook, true);
		}
	}
	
	// Initialisation
	bBlockUntilRoundStart = false;
	bBlockTankSpawn = false;
	bIgniteTank = false;
	g_bIsSUEnabled = false;
	g_bBroadcast = true;
	t_MissionLost = false;
	
	// Generate Config
	AutoExecConfig(true, "survivor_upgrades_k");
}

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "Jerrith,KrX",
	description = "Gives survivors upgrades from L4D",
	version = PLUGIN_VERSION,
	url = "krx.ath.cx/beta/sourcepawn/survivorupgradesk/"
};

public ResetValues()
{
	bBlockTankSpawn = false;
	for(new i=1; i < GetMaxClients(); ++i)
	{
		bUpgraded[i] = false;
		bBotControlled[i] = false;
		for(new j = 0; j < NVALID; ++j)
		{
			SDKCall(RemoveUpgrade, i, IndexToUpgrade[j]);
			bClientHasUpgrade[i][j] = false;
		}
	}
}

public Action:SayTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new String:message[1024];
	BfReadByte(bf);
	BfReadByte(bf);
	BfReadString(bf, message, 1024);

	if(StrContains(message, "prevent_it_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 1);
		return Plugin_Handled;
	}			
	if(StrContains(message, "ledge_save_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 2);
		return Plugin_Handled;
	}
	if(StrContains(message, "revive_self_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 3);
		return Plugin_Handled;
	}
	if(StrContains(message, "knife_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 4);
		return Plugin_Handled;
	}
	
	/*if(StrContains(message, "laser_sight_expire") != -1)
	{
		return Plugin_Handled;
	}*/

	if(StrContains(message, "_expire") != -1)
	{
		return Plugin_Handled;
	}

	if(StrContains(message, "#L4D_Upgrade_") != -1 && StrContains(message, "description") != -1)
	{
		return Plugin_Handled;
	}
	
	if(StrContains(message, "NOTIFY_VOMIT_ON") != -1)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:DelayPrintExpire(Handle:hTimer, any:text)
{
	// Prevents warnings when changing maps
	if(GetConVarInt(Verbosity) > 0 && g_bIsSUEnabled==true && g_bBroadcast==true)
	{
		if(text == 1)
		{
			PrintToChatAll("\x01%s Boomer vomit was stopped by a (now ruined) \x05Raincoat\x01!", PLUGIN_TAG);
		}
		if(text == 2)
		{
			PrintToChatAll("\x01%s \x05Climbing Chalk\x01 was used to climb back up from a ledge!", PLUGIN_TAG);
		}
		if(text == 3)
		{
			PrintToChatAll("\x01%s A survivor got their \x05Second Wind\x01 and stood back up!", PLUGIN_TAG);
		}
		if(text == 4)
		{
			PrintToChatAll("\x01%s A \x05Knife\x01 was used to escape!", PLUGIN_TAG);
		}
	}
}

public ActivateHooks()
{
	if(!bHooked)
	{
		bHooked = true;
		// Round Events
		HookEvent("round_start", Event_RoundStart);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("mission_lost", Event_MissionLost);	// Resets players' upgrades on every mission lost
		if(GetConVarInt(ResetOnMapChange))
			HookEvent("map_transition", Event_RoundEnd);	// Resets players' upgrades on next mission
		
		// Tank
		HookEvent("tank_spawn", Event_TankSpawn);
		HookEvent("tank_killed", Event_TankKilled);
		
		// Witch
		HookEvent("witch_killed", Event_WitchKilled);
		
		// Player Events
		HookEvent("player_team", Event_PlayerTeam);	// Must enable always for alwayslaser to work
		HookEvent("player_bot_replace", Event_PlayerBotReplace);
		HookEvent("bot_player_replace", Event_BotPlayerReplace);
		HookEvent("infected_hurt", Event_InfectedHurt);
		HookEvent("player_hurt", Event_PlayerHurt);
		// Only if current GameMode is Versus
		if (StrContains(g_CurrentMode, "versus", false) != -1) 
			HookEvent("player_entered_start_area", Event_PlayerEnteredStartArea);
		
		// Ending event
		HookEvent("finale_vehicle_leaving", Event_Endind);
	}
}
//============================================================================================
// Important for this version!
// If survivor_upgrades is 1, survivors get upgrades delivered by the game
// so survivors can get two upgrades (+1 from GiveInitialUpgrades).
// To avoid this, we just turn on the cvar after a few seconds the map has loaded

public OnMapStart()
{
	// Hmm... Seems like this is executed before OnPluginStart?
	// Check For Gamemode - disable according to ConVars
	GetConVarString(cvar_Gamemode, g_CurrentMode, sizeof(g_CurrentMode));
	// Check current gamemode then check if enabled
	if (StrContains(g_CurrentMode, "coop", false) != -1 && GetConVarBool(cvar_EnableCoop)) {
		g_InvalidGameMode=false;
	} else if (StrContains(g_CurrentMode, "survival", false) != -1 && GetConVarBool(cvar_EnableSv)) {
		g_InvalidGameMode=false;
	} else if (StrContains(g_CurrentMode, "versus", false) != -1 && GetConVarBool(cvar_EnableVersus)) {
		g_InvalidGameMode=false;
	} else { 
		g_InvalidGameMode=true;
	}
	
	PrintToServer("%s Server: Current GameMode: %s, Survivor Upgrades Disabled? %d", PLUGIN_TAG, g_CurrentMode, g_InvalidGameMode);
	
	if(g_InvalidGameMode) {
		PrintToServer("%s Server: Map start. Survivor Upgrades disabled for this gamemode [%s]!", PLUGIN_TAG, g_CurrentMode);
		if(GetConVarInt(AlwaysLaser))
			CreateTimer(25.0, ActivateSU);
	} else {
		PrintToServer("%s Server: Map start. Waiting 25 seconds to Activate Upgrades", PLUGIN_TAG);
		if(!g_bIsSUEnabled)
		{
			// enough for everyone to connect
			CreateTimer(25.0, ActivateSU);
		}
	}
}
public Action:ActivateSU(Handle:hTimer)
{
	if(g_InvalidGameMode) {
		PrintToChatAll("\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
		if(GetConVarInt(AlwaysLaser)) {
			for(new i=1;i<GetMaxClients();++i)
			{
				CreateTimer(1.0, GiveInitialUpgrades, i);
			}
		}
	} else {
		SetConVarInt(FindConVar("survivor_upgrades"), 1, true, false);
		// Reloader Upgrade durations
		SetConVarFloat(FindConVar("survivor_upgrade_reload_duration"), GetConVarFloat(ReloaderSpeed), true, false);
		SetConVarFloat(FindConVar("survivor_upgrade_reload_shotgun_duration"), GetConVarFloat(ReloaderShotgunSpeed), true, false);
		
		if(GetConVarInt(IgniteTank))
			bIgniteTank = true;
		
		if(GetConVarInt(Verbosity) > 1 && g_bBroadcast==true && GetConVarInt(FindConVar("survivor_upgrades"))) {
			PrintToChatAll("\x01%s Survivor Upgrades is \x05On!", PLUGIN_TAG);
		}
		g_bIsSUEnabled=true;
		for(new i=1;i<GetMaxClients();++i)
		{
			CreateTimer(1.0, GiveInitialUpgrades, i);
		}
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bBlockUntilRoundStart = false;
	if(!t_MissionLost) {
		PrintToServer("%s Server: Round Started!", PLUGIN_TAG);
	} else {
		// ROUND START AFTER MISSION LOST
		if(GetConVarInt(ResetOnMissionLost)) {
			ResetValues();
			if(GetConVarInt(ResetOnMissionLost) == 1) {
				for(new i=1;i<GetMaxClients();++i)
				{
					CreateTimer(1.0, GiveInitialUpgrades, i);
				}
			}
			PrintToServer("%s Server: Round Started after Misson Lost. Upgrades reset.", PLUGIN_TAG);
		} else {
			for(new i=1;i<GetMaxClients();++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == 2)
					ReGiveClientUpgrades(i);
			}
			PrintToServer("%s Server: Round Started after Misson Lost. Upgrades remain.", PLUGIN_TAG);
		}
		t_MissionLost = false;	// Reset temp variable
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!t_MissionLost) {
		PrintToServer("%s Server: Round Ended!", PLUGIN_TAG);
		bBlockUntilRoundStart = true;
		g_bIsSUEnabled = false;
		// Reset on Map Change, when RoundStart plugin should automatically GiveInitialUpgrades()
		if(GetConVarInt(ResetOnMapChange))
			ResetValues();
		// Turn off survivor_upgrades to avoid players getting extra upgrade at spawn
		SetConVarInt(FindConVar("survivor_upgrades"), 0, true, false);
	} else {
		// MISSION LOST! =(
		PrintToServer("%s Server: Round Ended! Mission Lost!", PLUGIN_TAG);
		bBlockUntilRoundStart = true;
		g_bIsSUEnabled = false;
	}
	return Plugin_Continue;
}

public Action:Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast) 
{
	// event mission_lost will be called before round_end if you lose a mission
	PrintToServer("%s Server: Mission Lost!", PLUGIN_TAG);
	t_MissionLost = true;	// Only set the variable for Event_RoundEnd and Event_RoundStart to handle resetting
}

// Incendiary Ammo Handling - all playable classes (Hunter, Smoker, Boomer, Tank, Survivors)
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	if(attacker == 0)
	{
		return Plugin_Continue;
	}
	new client = GetClientOfUserId(attacker);

	// Is Incendiary Ammo? Is Survivor?
	if (!bClientHasUpgrade[client][14] || GetClientTeam(client) != 2)
	{
		return Plugin_Continue;
	}
	
	new infectedClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Tank ignition. Adapted from l4d_specialammo.sp
	if(!bIgniteTank) {
		decl String:tankclass[64];
		GetClientModel(infectedClient, tankclass, 64);
		if(StrContains(tankclass, "hulk", false) != -1) {
			return Plugin_Continue; 
		}
	}
	
	// Is attacked Survivor? Don't set him aflame! Friendly Fire, literally.
	if (GetClientTeam(infectedClient) != 3)
	{
		return Plugin_Continue;
	}
	
	// BURNNNN!
	new damagetype = GetEventInt(event, "type");
	if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
	{
		IgniteEntity(infectedClient, 360.0, false);
	}
	return Plugin_Continue;
}

// Incendiary Ammo handling - non-playable classes (Common Infected, Witch)
public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// Is Incendiary Ammo? Is Survivor?
	if (!bClientHasUpgrade[client][14] || GetClientTeam(client) != 2)
	{
		return Plugin_Continue;
	}
	new infected = GetEventInt(event, "entityid");
	
	// Witches burn forever, so don't ignite! So make her fireproof!
	decl String:witchn[64];
	GetEntityNetClass(infected, witchn, 64);
	if(strcmp(witchn, "Witch")==0) {
		return Plugin_Continue;
	}
	
	// BURNNNN!
	new damagetype = GetEventInt(event, "type");
	if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
	{
		IgniteEntity(infected, 360.0, false);
	}
	return Plugin_Continue;
}

public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bBlockTankSpawn)
	{
		return Plugin_Continue;
	}
	else
	{
		CreateTimer(15.0, UnblockTankSpawn);
		bBlockTankSpawn = true;
	}
	new numUpgradesTankSpawn = GetConVarInt(UpgradesAtTankSpawn);
	if(numUpgradesTankSpawn > 0)
	{
		if(GetConVarInt(Verbosity)>1)
		{
			PrintToChatAll("%s The tank is coming!  Hope this helps...", PLUGIN_TAG);
			for(new i=1;i<GetMaxClients();i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				GiveClientUpgrades(i, numUpgradesTankSpawn);
			}
		}
	}
	return Plugin_Continue;
}

public Action:UnblockTankSpawn(Handle:hTimer)
{
	bBlockTankSpawn = false;
}

public Action:Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new numUpgradesAll = GetConVarInt(UpgradesAtTankKillAll);
	new numUpgradesKiller = GetConVarInt(UpgradesAtTankKillKiller);
	new killerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (numUpgradesAll > 0 || (numUpgradesKiller > 0 && killerClient != 0))
	{
		if(GetConVarInt(Verbosity)>1)
		{
			PrintToChatAll("%s The tank is dead!  The survivors get upgrades...", PLUGIN_TAG);
		}
		if(numUpgradesAll > 0)
		{
			for(new i=1; i<GetMaxClients(); i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
					// 											 ^Give only to surviving survivors
					GiveClientUpgrades(i, numUpgradesAll);
				}
			}
		}
		if(numUpgradesKiller > 0)
		{
			if(killerClient != 0)
			{
				if(GetConVarInt(Verbosity)>2)
				{
					decl String:tname[64];
					GetClientName(killerClient, tname, 64);
					PrintToChatAll("\x01%s The primary attacker,\x04 %s \x01 also gets:", PLUGIN_TAG, tname);
				}
				else if (GetConVarInt(Verbosity)>1)
				{
					PrintToChat(killerClient, "%s As the primary attacker, you also get:", PLUGIN_TAG);
				}
				GiveClientUpgrades(killerClient, numUpgradesKiller);
			}
			else
			{
				if(GetConVarInt(Verbosity)>1)
				{
					PrintToChatAll("%s No primary attacker on the tank, so nobody gets the bonus.", PLUGIN_TAG);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new numUpgradesAll = GetConVarInt(UpgradesAtWitchKillAll);
	new numUpgradesKiller = GetConVarInt(UpgradesAtWitchKillKiller);
	new killerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (numUpgradesAll > 0 || (numUpgradesKiller > 0 && killerClient != 0))
	{
		if(GetConVarInt(Verbosity)>1)
		{
			PrintToChatAll("%s The witch is dead!  The survivors get upgrades...", PLUGIN_TAG);
		}
		if(numUpgradesAll > 0)
		{
			for(new i=1; i<GetMaxClients(); i++)
			{
				if(!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
				// 													^Give only to surviving survivors
				GiveClientUpgrades(i, numUpgradesAll);
			}
		}
		if(numUpgradesKiller > 0)
		{
			if(killerClient != 0)
			{
				if(GetConVarInt(Verbosity)>2)
				{
					PrintToChatAll("%s The primary attacker also gets:", PLUGIN_TAG);
				}
				else if (GetConVarInt(Verbosity)>1)
				{
					PrintToChat(killerClient, "%s As primary attacker, you also get:", PLUGIN_TAG);
				}
				GiveClientUpgrades(killerClient, numUpgradesKiller);
			}
			else
			{
				if(GetConVarInt(Verbosity)>1)
				{
					PrintToChatAll("%s No primary attacker on the witch, so nobody gets the bonus.", PLUGIN_TAG);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bIsSUEnabled) {
		if(GetEventInt(event, "team")==2)
		{
			CreateTimer(5.0, GiveInitialUpgrades, GetClientOfUserId(GetEventInt(event, "userid")));
			return;
		}
		if(GetEventInt(event, "oldteam")==2)
		{
			CreateTimer(4.0, ClearOldUpgradeInfo, GetClientOfUserId(GetEventInt(event, "userid")));
		}
	}
}

public Action:ClearOldUpgradeInfo(Handle:hTimer, any:playerClient)
{
	// This is an attempt to prevent bots from getting extra upgrades... :)
	if(bBotControlled[playerClient])
	{
		return;
	}
	bUpgraded[playerClient] = false;
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[playerClient][i] = false;
	}
}

public Action:Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Bot replaced a player.
	new playerClient = GetClientOfUserId(GetEventInt(event, "player"));
	new botClient = GetClientOfUserId(GetEventInt(event, "bot"));
	bUpgraded[botClient] = bUpgraded[playerClient];
	bUpgraded[playerClient] = false;
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[botClient][i] = bClientHasUpgrade[playerClient][i];
		//if(bClientHasUpgrade[botClient][i])
		//	PrintToConsole(playerClient, "%d > %d Upgrade: %s", botClient, playerClient, UpgradeShortInfo[i]);
		// Reset the replaced player's upgrades
		bClientHasUpgrade[playerClient][i] = false;
	}
	bBotControlled[botClient] = true;
	
	ReGiveClientUpgrades(botClient);
	PrintToServer("%s Server: Bot %d Replaced Player %d", PLUGIN_TAG, botClient, playerClient);
}

public Action:Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Player replaced a bot.
	new playerClient = GetClientOfUserId(GetEventInt(event, "player"));
	new botClient = GetClientOfUserId(GetEventInt(event, "bot"));
	bUpgraded[playerClient] = bUpgraded[botClient];
	bUpgraded[botClient] = false;
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[playerClient][i] = bClientHasUpgrade[botClient][i];
		//if(bClientHasUpgrade[playerClient][i])
		//	PrintToConsole(playerClient, "%d > %d Upgrade: %s", playerClient, botClient, UpgradeShortInfo[i]);
		// Reset the replaced bot's upgrades
		bClientHasUpgrade[botClient][i] = false;
	}
	ListMyTeamUpgrades(playerClient, true);
	bBotControlled[botClient] = false;
	if(!bUpgraded[playerClient]) 
		PrintToChat(playerClient, "%s You will receive your initial upgrades on the next mission/mapchange.", PLUGIN_TAG);
	ReGiveClientUpgrades(playerClient);
	PrintToServer("%s Server: Player %d Replaced Bot %d", PLUGIN_TAG, playerClient, botClient);
}

// When the finale vehicle is leaving. Tanks always spawn and die, spawn and die, spawn and die
public Action:Event_Endind(Handle:event, const String:ename[], bool:dontBroadcast)
{
	g_bIsSUEnabled=false;
	bBlockTankSpawn = true;
	
	// clean upgrades
	ResetValues();
	
	// turn off survivor_upgrades convar to avoid bad behavior
	SetConVarInt(FindConVar("survivor_upgrades"), 0, true, false);
	//PrintToChatAll("Survivor Upgrades state: %d", GetConVarInt(FindConVar("survivor_upgrades")));
}

// For Versus Only
public Action:Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, GiveInitialUpgrades, GetClientOfUserId(GetEventInt(event, "userid")));
}

/****************************************************************************/
// End of Event Handles

public ListMyTeamUpgrades(client, bool:brief)
{
	if(g_InvalidGameMode) {
		PrintToChat(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
	} else {
		if(GetConVarInt(Verbosity)>2)
		{
			for(new i=1;i<GetMaxClients();i++)
			{
				if(client == i) continue;
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				
				decl String:name[64];
				GetClientName(i, name, 64);
				for(new upgrade=0; upgrade < NVALID; ++upgrade)
				{
					if(bClientHasUpgrade[i][upgrade])
					{
						PrintToChat(client, "\x04%s\x01 got %s\x01.", name, UpgradeShortInfo[upgrade]);
					}
				}
			}
		}
		ListMyUpgrades(client, brief);
	}
}

public ListMyUpgrades(client, bool:brief)
{
	if(GetConVarInt(Verbosity)>=0)
	{
		decl String:name[64];
		GetClientName(client, name, 64);
		for(new upgrade=0; upgrade < NVALID; ++upgrade)
		{
			if(bClientHasUpgrade[client][upgrade])
			{
				PrintToChat(client, "\x04%s\x01 got %s\x01.", name, UpgradeShortInfo[upgrade]);
				if(GetConVarInt(Verbosity)>2 || !brief)
				{
					PrintToChat(client, "%s", UpgradeLongInfo[upgrade]);
				}
			}
		}
	}
}

public OnConfigsExecuted()
{
	new Handle:SU_CVAR = FindConVar("survivor_upgrades");
	SetConVarInt(SU_CVAR, 0);
	
	SetConVarInt(FindConVar("vs_max_team_switches"), 9999);
	
	SetConVarInt(FindConVar("sv_vote_issue_change_difficulty_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_change_map_now_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_change_mission_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_restart_game_allowed"), 1, true, false);
}

public Action:GiveInitialUpgrades(Handle:hTimer, any:client)
{
	if(g_InvalidGameMode) {
		//PrintToChat(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
		if(GetConVarInt(AlwaysLaser)) {
			if(!IsClientInGame(client) || GetClientTeam(client) != 2 || bUpgraded[client]) return;
			if (GetConVarInt(AlwaysLaser)!=0 && !bClientHasUpgrade[client][6])
			{
				GiveClientSpecificUpgrade(client, 6);
				bUpgraded[client] = true;
			}
			if(IsClientInGame(client)) {
				if(GetClientTeam(client) == 2 && !IsFakeClient(client)) {
					PrintToChat(client, "\x01%s Laser Sights have been enabled. Say \x05/laser\x01 to toggle on/off.", PLUGIN_TAG);
				}
			}
		}
	} else {
		// 	Round Started?			Connected?					Survivors?					Already got init upgrades?
		if(bBlockUntilRoundStart || !IsClientInGame(client) || GetClientTeam(client) != 2 || bUpgraded[client]) return;
		bUpgraded[client] = true;
		for(new i=0; i<NVALID; ++i)
		{
			if(GetConVarInt(UpgradeAllowed[i])==2)
			{
				GiveClientSpecificUpgrade(client, i);
			}
		}
		if (GetConVarInt(AlwaysLaser)!=0 && !bClientHasUpgrade[client][6])
		{
			GiveClientSpecificUpgrade(client, 6);
		}
		new numStarting = GetConVarInt(UpgradesAtSpawn);
		if(numStarting > 0)
		{
			GiveClientUpgrades(client, numStarting);
		}
	}
}

public GiveClientUpgrades(client, numUpgrades)
{
	if(g_InvalidGameMode) {
		PrintToChat(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
	} else {
		decl String:name[64];
		GetClientName(client, name, 64);
		for(new num=0; num<numUpgrades; ++num)
		{
			new numOwned = GetNumUpgrades(client);
			if(numOwned == NVALID)
			{
				if(GetConVarInt(Verbosity)>1)
				{
					PrintToChatAll("\x01%s \x04%s\x01 would have gotten an upgrade but already has them all.", PLUGIN_TAG, name);
				}
				return;
			}
			new offset = GetRandomInt(0,NVALID-(numOwned+1));
			new val = 0;
			while(offset > 0 || bClientHasUpgrade[client][val] || GetConVarInt(UpgradeAllowed[val])!=1)
			{
				if((!bClientHasUpgrade[client][val]) && GetConVarInt(UpgradeAllowed[val])==1)
				{
					offset--;
				}
				val++;
			}
			GiveClientSpecificUpgrade(client, val);
		}
	}
}

public GiveClientSpecificUpgrade(any:client, upgrade)
{
	decl String:name[64];
	GetClientName(client, name, 64);
	new VerbosityVal = GetConVarInt(Verbosity);
	if(VerbosityVal > 2)
	{
		PrintToChatAll("\x04%s\x01 got %s\x01.", name, UpgradeShortInfo[upgrade]);
		PrintToChat(client, "%s", UpgradeLongInfo[upgrade]);
	}
	else if (VerbosityVal > 1)
	{
		PrintToChat(client, "\x04%s\x01 got %s\x01.", name, UpgradeShortInfo[upgrade]);
	}
	SDKCall(AddUpgrade, client, IndexToUpgrade[upgrade]);
	// We're just doing this for the sound effect, remove it immediately...
	if(IndexToUpgrade[upgrade] == 30)
	{
		SDKCall(RemoveUpgrade, client, IndexToUpgrade[upgrade]);
	}
	bClientHasUpgrade[client][upgrade]=true;
}

public ReGiveClientUpgrades(client)
{
	for(new upgrade=0; upgrade < NVALID; ++upgrade)
	{
		if(bClientHasUpgrade[client][upgrade])
		{
			SDKCall(RemoveUpgrade, client, IndexToUpgrade[upgrade]);
			SDKCall(AddUpgrade, client, IndexToUpgrade[upgrade]);
		}
	}
}

public TakeClientSpecificUpgrade(any:client, upgrade)
{
	if(g_InvalidGameMode) {
		PrintToChat(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
	} else {
		SDKCall(RemoveUpgrade, client, IndexToUpgrade[upgrade]);
		bClientHasUpgrade[client][upgrade]=false;
	}
}

public GetNumUpgrades(client)
{
	new num = 0;
	for(new i = 0; i < NVALID; ++i)
	{
		if(bClientHasUpgrade[client][i] || GetConVarInt(UpgradeAllowed[i])!=1)
		{
			++num;
		}
	}
	return num;
}

public Action:addUpgrade(client, args)
{
	if(g_InvalidGameMode) {
		ReplyToCommand(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
		return Plugin_Handled;
	}
	
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: addUpgrade [upgrade id] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS];
	new targetCount = 1;
	targetList[0] = client;
	if(GetCmdArgs() > 1)
	{
		targetCount = 0;
		for(new i = 2; i<=GetCmdArgs(); ++i)
		{
			decl String:arg[65];
			GetCmdArg(i, arg, sizeof(arg));
			
			decl String:subTargetName[MAX_TARGET_LENGTH];
			decl subTargetList[MAXPLAYERS], subTargetCount, bool:tn_is_ml;
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE, subTargetName, sizeof(subTargetName), tn_is_ml);
			
			for(new j = 0; j < subTargetCount; ++j)
			{
				new bool:bAdd = true;
				for(new k = 0; k < targetCount; ++k)
				{
					if(targetList[k] == subTargetList[j])
					{
						bAdd = false;
					}
				}
				if(bAdd)
				{
					targetList[targetCount] = subTargetList[j];
					++targetCount;
				}
			}
		}
	}
	if(targetCount == 0)
	{
		ReplyToCommand(client, "No players found that matched the targets you specified.");
		return Plugin_Handled;
	}
	
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	new upgrade = StringToInt(arg)-1;
	if(upgrade<0 || upgrade >= NVALID)
	{
		ReplyToCommand(client, "Invalid upgrade index.  Valid values are 1 to %d.", NVALID);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < targetCount; ++i)
	{
		GiveClientSpecificUpgrade(targetList[i], upgrade);
	}
	return Plugin_Handled;		
}

public Action:giveRandomUpgrades(client, args)
{
	if(g_InvalidGameMode) {
		ReplyToCommand(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
		return Plugin_Handled;
	}
	
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: giveRandomUpgrades [number of Upgrades] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS];
	new targetCount = 1;
	targetList[0] = client;
	if(GetCmdArgs() > 1)
	{
		targetCount = 0;
		for(new i = 2; i<=GetCmdArgs(); ++i)
		{
			decl String:arg[65];
			GetCmdArg(i, arg, sizeof(arg));
			
			decl String:subTargetName[MAX_TARGET_LENGTH];
			decl subTargetList[MAXPLAYERS], subTargetCount, bool:tn_is_ml;
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE, subTargetName, sizeof(subTargetName), tn_is_ml);
			
			for(new j = 0; j < subTargetCount; ++j)
			{
				new bool:bAdd = true;
				for(new k = 0; k < targetCount; ++k)
				{
					if(targetList[k] == subTargetList[j])
					{
						bAdd = false;
					}
				}
				if(bAdd)
				{
					targetList[targetCount] = subTargetList[j];
					++targetCount;
				}
			}
		}
	}
	if(targetCount == 0)
	{
		ReplyToCommand(client, "No players found that matched the targets you specified.");
		return Plugin_Handled;
	}
	
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	new upgrade = StringToInt(arg);
	
	for(new i = 0; i < targetCount; ++i)
	{
		GiveClientUpgrades(targetList[i], upgrade);
	}
	return Plugin_Handled;		
}

public Action:removeUpgrade(client, args)
{
	if(g_InvalidGameMode) {
		ReplyToCommand(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
		return Plugin_Handled;
	}
	
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: removeUpgrade [upgrade id] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS];
	new targetCount = 1;
	targetList[0] = client;
	if(GetCmdArgs() > 1)
	{
		targetCount = 0;
		for(new i = 2; i<=GetCmdArgs(); ++i)
		{
			decl String:arg[65];
			GetCmdArg(i, arg, sizeof(arg));
			
			decl String:subTargetName[MAX_TARGET_LENGTH];
			decl subTargetList[MAXPLAYERS], subTargetCount, bool:tn_is_ml;
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE, subTargetName, sizeof(subTargetName), tn_is_ml);
			
			for(new j = 0; j < subTargetCount; ++j)
			{
				new bool:bAdd = true;
				for(new k = 0; k < targetCount; ++k)
				{
					if(targetList[k] == subTargetList[j])
					{
						bAdd = false;
					}
				}
				if(bAdd)
				{
					targetList[targetCount] = subTargetList[j];
					++targetCount;
				}
			}
		}
	}
	if(targetCount == 0)
	{
		ReplyToCommand(client, "No players found that matched the targets you specified.");
		return Plugin_Handled;
	}
	
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	new upgrade = StringToInt(arg)-1;
	if(upgrade<0 || upgrade >= NVALID)
	{
		ReplyToCommand(client, "Invalid upgrade index.  Valid values are 1 to %d.", NVALID);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < targetCount; ++i)
	{
		TakeClientSpecificUpgrade(targetList[i], upgrade);
	}
	return Plugin_Handled;
}

public Action:removeAllUpgrades(client, args)
{
	if(g_InvalidGameMode) {
		PrintToChat(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
	} else {
		// No arguments required for function
		ResetValues();
	}
}

public Action:ListUpgrades(client, args)
{
	if(g_InvalidGameMode) {
		PrintToChat(client, "\x01%s Survivor Upgrades Have been \x04disabled\x01 for %s.", PLUGIN_TAG, g_CurrentMode);
	} else {
		ListMyUpgrades(client, false);
	}
	return Plugin_Handled;
}

public Action:LaserToggle(client, args)
{
	if(GetConVarInt(AlwaysLaser) != 1)
	{
		return;
	}
	if (bClientHasUpgrade[client][6])
	{
		PrintToChat(client, "%s Laser turned \x04Off!", PLUGIN_TAG);
		SDKCall(RemoveUpgrade, client, 17);
		bClientHasUpgrade[client][6] = false;
	}
	else
	{
		PrintToChat(client, "%s Laser turned \x02On!", PLUGIN_TAG);
		SDKCall(AddUpgrade, client, 17);
		bClientHasUpgrade[client][6] = true;
	}
}

//==============================================================================================
// Help!

// Show help 20 seconds after connecting
public OnClientPutInServer(client)
{
	if(client)
	{
		CreateTimer(20.0, ShowHelp, client);
	}
}

public Action:ShowHelp(Handle:hTimer, any:client)
{
	if(!IsClientInGame(client)) return;
	if(GetClientTeam(client)!=2 || IsFakeClient(client)) return;
	
	PrintToChat(client, "\x05| \x01This server is running \x05KrX's \x04Survivor Upgrades\x01 plugin v%s", PLUGIN_VERSION);
	if(g_InvalidGameMode) {
		PrintToChat(client, "\x05| \x04 Survivor Upgrades have been DISABLED for %s", g_CurrentMode);
		PrintToChat(client, "\x05| \x01Say:");
		if(GetConVarInt(AlwaysLaser))
			PrintToChat(client, "\x05| \x04/laser\x01 to toggle your laser sight");
		PrintToChat(client, "\x05| \x04/upghelp\x01 to see this info"); 
	} else {
		PrintToChat(client, "\x05| \x01Say:");
		PrintToChat(client, "\x05| \x04/laser\x01 to toggle your laser sight");
		PrintToChat(client, "\x05| \x04/upgrades\x01 to check out your upgrades");
		PrintToChat(client, "\x05| \x04/upghelp\x01 to see this info"); 
		PrintToChat(client, "\x05| \x04/upghelp 2\x01 to see at what times you get upgrades");
	}
}

public Action:UserHelp(client, args)
{
	PrintToChat(client, "\x05| KrX's \x04Survivor Upgrades\x01 plugin v%s Help", PLUGIN_VERSION);
	// If InvalidGameMode then there's nothing else to be done.
	if(g_InvalidGameMode) {
		PrintToChat(client, "\x05| \x04 Survivor Upgrades have been DISABLED for %s", g_CurrentMode);
		if(GetConVarInt(AlwaysLaser))
			PrintToChat(client, "\x05| \x01Say:");
		PrintToChat(client, "\x05| \x04/laser\x01 to toggle your laser sight"); 
		
		return Plugin_Handled;
	}
	
	new type = 1;
	if(GetCmdArgs() >= 1) {
		decl String:arg[3];
		GetCmdArg(1, arg, sizeof(arg));
		new ask = StringToInt(arg);
		if(ask == 2)
		{
			type = 2;
		}
	}
	if(type == 1) {
		// Normal help
		PrintToChat(client, "\x05| \x01Say:");
		PrintToChat(client, "\x05| \x04/laser\x01 to toggle your laser sight");
		PrintToChat(client, "\x05| \x04/upgrades\x01 to check out your upgrades");
		PrintToChat(client, "\x05| \x04/upghelp\x01 to see this info");
		PrintToChat(client, "\x05| \x04/upghelp 2\x01 to see at what times you get upgrades");
	} else if(type == 2) {
		// When do we get upgrades?
		PrintToChat(client, "\x05| \x01Upgrades per:");
		PrintToChat(client, "\x05| \x04Mission Start:\x01%d", GetConVarInt(UpgradesAtSpawn));
		PrintToChat(client, "\x05| \x04Tank Spawned:\x01%d, \x04Tank Killed:\x01%d, \x04Witch Killed:\x01%d", GetConVarInt(UpgradesAtTankSpawn), GetConVarInt(UpgradesAtTankKillAll), GetConVarInt(UpgradesAtWitchKillAll));
		PrintToChat(client, "\x05| \x04Primary Tank Killer:\x01%d, \x04Primary Witch Killer: \x01%d", GetConVarInt(UpgradesAtTankKillKiller), GetConVarInt(UpgradesAtWitchKillKiller));
	}
	
	return Plugin_Handled;
}