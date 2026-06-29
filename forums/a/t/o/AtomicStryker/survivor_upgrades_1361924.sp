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
 
#include <sourcemod>
#include <sdktools>

#define NUPGRADES 31
#define NVALID 15

#define PLUGIN_VERSION "1.4"
#define PLUGIN_NAME "Survivor Upgrades"
#define PLUGIN_TAG "[SurUp]"

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

new Handle:AlwaysLaser = INVALID_HANDLE;
new Handle:UpgradesAtSpawn = INVALID_HANDLE;
new Handle:UpgradesAtWitchKillKiller = INVALID_HANDLE;
new Handle:UpgradesAtWitchKillAll = INVALID_HANDLE;
new Handle:UpgradesAtTankSpawn = INVALID_HANDLE;
new Handle:UpgradesAtTankKillKiller = INVALID_HANDLE;
new Handle:UpgradesAtTankKillAll = INVALID_HANDLE;
new Handle:Verbosity = INVALID_HANDLE;

new bool:bBlockUntilRoundStart;
new bool:bBlockTankSpawn;
new UserMsg:sayTextMsgId;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	// Try the windows version first.
	StartPrepSDKCall(SDKCall_Player); // A1 3C ? ? ? 83 ? ? ? 57 8B F9 0F ? ? ? ? ? 8B 4C ? ? 56 51 E8
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\xA1\x3C\x2A\x2A\x2A\x83\x2A\x2A\x2A\x57\x8B\xF9\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x4C\x2A\x2A\x56\x51\xE8", 25))
	{
		//PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer10AddUpgradeE19SurvivorUpgradeType", 0);
		PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x89\xE5\x57\x56\x53\x83\xEC\x2A\xE8\x2A\x2A\x2A\x2A\x81\xC3\x2A\x2A\x2A\x2A\x8B\x7D\x2A\x8B\x83\x2A\x2A\x2A\x2A\x8B\x40\x2A\x8B\x48\x2A\x85\xC9\x75\x2A\x83\xC4\x2A\x5B\x5E\x5F\x5D\xC3\x8B\x45\x2A\x89\x2A\x2A\xE8", 54);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	AddUpgrade = EndPrepSDKCall();
	
	if (AddUpgrade == INVALID_HANDLE)
	{
		LogError("AddUpgrade Signature broken, go annoy AtomicStryer");
	}

	StartPrepSDKCall(SDKCall_Player); // 51 53 55 8B 6C ? ? 8B D9 56 8B CD 83 E1 ? BE 01
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x51\x53\x55\x8B\x6C\x2A\x2A\x8B\xD9\x56\x8B\xCD\x83\xE1\x2A\xBE\x01", 17))
	{
		//PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer13RemoveUpgradeE19SurvivorUpgradeType", 0);
		PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x89\xE5\x57\x56\x53\x83\xEC\x2A\xE8\x2A\x2A\x2A\x2A\x81\xC3\x2A\x2A\x2A\x2A\x8B\x75\x2A\x8B\x55\x2A\xC1\xFA\x2A\x81", 30);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	RemoveUpgrade = EndPrepSDKCall();
	
	if (RemoveUpgrade == INVALID_HANDLE)
	{
		LogError("RemoveUpgrade Signature broken, go annoy AtomicStryer");
	}

	//StartPrepSDKCall(SDKCall_Player);
	//if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x83\xEC\x18\xA1****\x56\x33\xF6\x39\x70\x30\x89***\x0F*****\x53\x55\x57\x33\xED\x33\xDB\x33\xFF", 33))
	//{
	//	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer17GiveRandomUpgradeEv", 0);	
	//}
	//GiveRandomUpgrade = EndPrepSDKCall();

	IndexToUpgrade[0] = 1;
	UpgradeShortInfo[0] = "\x03Kevlar Body Armor \x05(Reduce Damage)";
	UpgradeLongInfo[0] = "This body armor helps you stay alive when attacked by infected.";
	UpgradeAllowed[0] = CreateConVar("surup_allow_kevlar_body_armor", "1", "Whether or not we give out the Kevlar Body Armor upgrade.", FCVAR_PLUGIN);

	IndexToUpgrade[1] = 8;
	UpgradeShortInfo[1] = "\x03Raincoat \x05(Ignore Boomer Vomit) \x01[Single Use]";
	UpgradeLongInfo[1] = "This raincoat stops boomer vomit from hitting you, however it is ruined in the process and only good for one use."; 
	UpgradeAllowed[1] = CreateConVar("surup_allow_raincoat", "1", "Whether or not we give out the Raincoat upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[2] = 11;
	UpgradeShortInfo[2] = "\x03Climbing Chalk \x05(Self Ledge Save) \x01[Single Use]";
	UpgradeLongInfo[2] = "This chalk allows you to get a good enough grip to pull yourself up from a ledge without help, however there's only enough to do it once.";
	UpgradeAllowed[2] = CreateConVar("surup_allow_climbing_chalk", "1", "Whether or not we give out the Climbing Chalk upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[3] = 12;
	UpgradeShortInfo[3] = "\x03Second Wind \x05(Self Revive) \x01[Single Use]";
	UpgradeLongInfo[3] = "This allows you to attempt to stand up by yourself, once, after being incapacitated.  Damage taken while getting up may cause the attempt to fail.";
	UpgradeAllowed[3] = CreateConVar("surup_allow_second_wind", "1", "Whether or not we give out the Second Wind upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[4] = 13;
	UpgradeShortInfo[4] = "\x03Goggles \x05(See through Boomer Vomit)";
	UpgradeLongInfo[4] = "This allows you to still see clearly after being vomited on.  Does not prevent infected from swarming!";
	UpgradeAllowed[4] = CreateConVar("surup_allow_goggles", "1", "Whether or not we give out the Goggles upgrade.", FCVAR_PLUGIN);
	  
	IndexToUpgrade[5] = 16;
	UpgradeShortInfo[5] = "\x03Hot Meal \x05(Health Bonus)";
	UpgradeLongInfo[5] = "Don't you feel better after a good hot meal?  Raises your health to 150.";
	UpgradeAllowed[5] = CreateConVar("surup_allow_hot_meal", "0", "Whether or not we give out the Hot Meal upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[6] = 17;
	UpgradeShortInfo[6] = "\x03Laser Sight \x05(Bright Red Beam)";
	UpgradeLongInfo[6] = "The laser helps you aim more accurately at your targets.";
	UpgradeAllowed[6] = CreateConVar("surup_allow_laser_sight", "0", "Whether or not we give out the Laser Sight upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[7] = 19;
	UpgradeShortInfo[7] = "\x03Combat Sling \x05(Reduced Recoil)";
	UpgradeLongInfo[7] = "This reduces the effects of recoil when firing your weapons.";
	UpgradeAllowed[7] = CreateConVar("surup_allow_combat_sling", "1", "Whether or not we give out the Combat Sling upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[8] = 20;
	UpgradeShortInfo[8] = "\x03Large Clip \x05(Increase ammo clip capacity)";
	UpgradeLongInfo[8] = "This provides an increase in the number of shots you can take before having to reload.";
	UpgradeAllowed[8] = CreateConVar("surup_allow_large_clip", "1", "Whether or not we give out the Large Clip upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[9] = 21;
	UpgradeShortInfo[9] = "\x03Hollow Point Ammo \x05(Increased bullet damage)";
	UpgradeLongInfo[9] = "This ammo allows you to deal more damage to the infected you shoot at.  Common infected die in an explosion of blood.";
	UpgradeAllowed[9] = CreateConVar("surup_allow_hollow_point_ammo", "1", "Whether or not we give out the Hollow Point Ammo upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[10] = 26;
	UpgradeShortInfo[10] = "\x03Knife \x05(Escape Hunter or Smoker restraint) \x01[Single Use]";
	UpgradeLongInfo[10] = "This knife allows you to escape from a hunter or smoker that has trapped you, however it is ruined in the process.";
	UpgradeAllowed[10] = CreateConVar("surup_allow_knife", "1", "Whether or not we give out the Knife upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[11] = 27;
	UpgradeShortInfo[11] = "\x03Smelling Salts \x05(Fast Revive of other players)";
	UpgradeLongInfo[11] = "These smelling salts allow you to revive another player faster than normal.";
	UpgradeAllowed[11] = CreateConVar("surup_allow_smelling_salts", "1", "Whether or not we give out the Smelling Salts upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[12] = 28;
	UpgradeShortInfo[12] = "\x03Ointment \x05(Increased Run Speed when injured)";
	UpgradeLongInfo[12] = "This ointment increases your run speed while you are injured.";
	UpgradeAllowed[12] = CreateConVar("surup_allow_ointment", "1", "Whether or not we give out the Ointment upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[13] = 29;
	UpgradeShortInfo[13] = "\x03Reloader \x05(Fast Reload)";
	UpgradeLongInfo[13] = "This reloader allows you to reload your weapons much faster than normal.";
	UpgradeAllowed[13] = CreateConVar("surup_allow_reloader", "1", "Whether or not we give out the Reloader upgrade.", FCVAR_PLUGIN);
	
	IndexToUpgrade[14] = 30;
	UpgradeShortInfo[14] = "\x03Incendiary Ammo \x05(Bullets cause fire)";
	UpgradeLongInfo[14] = "This ammo allows you to set on fire any infected you shoot with it.";
	UpgradeAllowed[14] = CreateConVar("surup_allow_incendiary_ammo", "1", "Whether or not we give out the Incendiary Ammo upgrade.", FCVAR_PLUGIN);

	RegAdminCmd("addupgrade", addUpgrade, ADMFLAG_KICK);
	RegAdminCmd("removeupgrade", removeUpgrade, ADMFLAG_KICK);
	RegAdminCmd("giverandomupgrades", giveRandomUpgrades, ADMFLAG_KICK);
	RegConsoleCmd("listupgrades", ListUpgrades);
	RegConsoleCmd("laseron", LaserOn);
	RegConsoleCmd("laseroff", LaserOff);
	RegConsoleCmd("laser", LaserToggle);

	ActivateHooks();

	CreateConVar("surup_version", PLUGIN_VERSION, "The version of Survivor Upgrades plugin.", FCVAR_PLUGIN);

	AlwaysLaser = CreateConVar("surup_always_laser", "1", "Whether or not we always give survivors the laser sight upgrade.", FCVAR_PLUGIN);
	UpgradesAtSpawn = CreateConVar("surup_upgrades_at_spawn", "3", "How many random upgrades to give survivors when they spawn.", FCVAR_PLUGIN);
	UpgradesAtWitchKillKiller = CreateConVar("surup_upgrades_at_witch_kill_killer", "1", "How many random upgrades to give survivors when they personally kill the witch.", FCVAR_PLUGIN);
	UpgradesAtWitchKillAll = CreateConVar("surup_upgrades_at_witch_kill_all", "1", "How many random upgrades to give survivors when their team kills the witch.", FCVAR_PLUGIN);
	UpgradesAtTankSpawn = CreateConVar("surup_upgrades_at_tank_spawn", "1", "How many random upgrades to give survivors when a tank spawns.");
	UpgradesAtTankKillKiller = CreateConVar("surup_upgrades_at_tank_kill_killer", "1", "How many random upgrades to give survivors when they personally kill the tank.", FCVAR_PLUGIN);
	UpgradesAtTankKillAll = CreateConVar("surup_upgrades_at_tank_kill_all", "1", "How many random upgrades to give survivors when their team kills the tank.", FCVAR_PLUGIN);
	Verbosity = CreateConVar("surup_verbosity", "2", "How much text output about upgrades players see (0 = none, 3 = max, default 2).", FCVAR_PLUGIN);
	
	sayTextMsgId = GetUserMessageId("SayText");
	HookUserMessage(sayTextMsgId, SayTextHook, true);
	bBlockUntilRoundStart = false;
	bBlockTankSpawn = false;

	AutoExecConfig(true, "survivor_upgrades");
}

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "Jerrith",
	description = "Gives survivors access to upgrades.",
	version = PLUGIN_VERSION,
	url = "jerrith.com"
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

	if(StrContains(message, "prevent_it_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 1);
		return Plugin_Handled;
	}			
	if(StrContains(message, "ledge_save_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 2);
		return Plugin_Handled;
	}
	if(StrContains(message, "revive_self_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 3);
		return Plugin_Handled;
	}
	if(StrContains(message, "knife_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 4);
		return Plugin_Handled;
	}
	
	if(StrContains(message, "laser_sight_expire")!= -1)
	{
		return Plugin_Handled;
	}

	if(StrContains(message, "_expire")!= -1)
	{
		return Plugin_Handled;
	}

	if(StrContains(message, "#L4D_Upgrade_")!=-1)
	{
		if(StrContains(message, "description")!=-1)
		{
			return Plugin_Handled;
		}
	}
	
	if(StrContains(message, "NOTIFY_VOMIT_ON") != -1)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:DelayPrintExpire(Handle:hTimer, any:text)
{
	if(GetConVarInt(Verbosity) > 0)
	{
		if(text == 1)
		{
			PrintToChatAll("\x01Boomer vomit was stopped by a (now ruined) \x05Raincoat\x01!");
		}
		if(text == 2)
		{
			PrintToChatAll("\x05Climbing Chalk\x01 was used to climb back up from a ledge!");
		}
		if(text == 3)
		{
			PrintToChatAll("\x01A survivor got their \x05Second Wind\x01 and stood back up!");
		}
		if(text == 4)
		{
			PrintToChatAll("\x01A \x05Knife\x01 was used to escape!");
		}
	}
}

public ActivateHooks()
{
	if(!bHooked)
	{
		bHooked = true;
		HookEvent("round_start", Event_RoundStart);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("tank_spawn", Event_TankSpawn);
		HookEvent("tank_killed", Event_TankKilled);
		HookEvent("witch_killed", Event_WitchKilled);
		HookEvent("player_team", Event_PlayerTeam);
		HookEvent("player_bot_replace", Event_PlayerBotReplace);
		HookEvent("bot_player_replace", Event_BotPlayerReplace);
		HookEvent("player_entered_start_area", Event_PlayerEnteredStartArea);
		HookEvent("infected_hurt", Event_InfectedHurt);
		HookEvent("player_hurt", Event_PlayerHurt);
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	if(attacker == 0)
	{
		return Plugin_Continue;
	}
	new client = GetClientOfUserId(attacker);
	if (!bClientHasUpgrade[client][14])
	{
		return Plugin_Continue;
	}
	if (GetClientTeam(client) != 2)
	{
		return Plugin_Continue;
	}
	new infected = GetEventInt(event, "userid");
	new infectedClient = GetClientOfUserId(infected);
	if (GetClientTeam(infectedClient) != 3)
	{
		return Plugin_Continue;
	}
	new damagetype = GetEventInt(event, "type");
	if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
	{
		IgniteEntity(infectedClient, 360.0, false);
	}
	return Plugin_Continue;
}

public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	new client = GetClientOfUserId(attacker);
	if (!bClientHasUpgrade[client][14])
	{
		return Plugin_Continue;
	}
	if(GetClientTeam(client) != 2)
	{
		return Plugin_Continue;
	}
	new infected = GetEventInt(event, "entityid");
	new damagetype = GetEventInt(event, "type");
	if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
	{
		IgniteEntity(infected, 360.0, false);
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bBlockUntilRoundStart = false;
	for(new i=1;i<GetMaxClients();++i)
	{
		CreateTimer(1.0, GiveInitialUpgrades, i);
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	bBlockUntilRoundStart = true;
	ResetValues();
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
	new numUpgrades = GetConVarInt(UpgradesAtTankSpawn);
	if(numUpgrades > 0)
	{
		if(GetConVarInt(Verbosity)>1)
		{
			PrintToChatAll("The tank is coming!  Hope this helps...");
			for(new i=1;i<GetMaxClients();i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				GiveClientUpgrades(i, numUpgrades);
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
	new killerUserId = GetEventInt(event, "attacker");
	new killerClient = GetClientOfUserId(killerUserId);
	
	if (numUpgradesAll > 0 || (numUpgradesKiller > 0 && killerClient != 0))
	{
		if(GetConVarInt(Verbosity)>1)
		{
			PrintToChatAll("The tank is dead!  The survivors get upgrades...");
		}
		if(numUpgradesAll > 0)
		{
			for(new i=1; i<GetMaxClients(); i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				GiveClientUpgrades(i, numUpgradesAll);
			}
		}
		if(numUpgradesKiller > 0)
		{
			if(killerClient != 0)
			{
				if(GetConVarInt(Verbosity)>2)
				{
					PrintToChatAll("The primary attacker also gets:");
				}
				else if (GetConVarInt(Verbosity)>1)
				{
					PrintToChat(killerClient, "As primary attacker, you also get:");
				}
				GiveClientUpgrades(killerClient, numUpgradesKiller);
			}
			else
			{
				if(GetConVarInt(Verbosity)>1)
				{
					PrintToChatAll("No primary attacker on the tank, so nobody gets the bonus.");
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
	new killerUserId = GetEventInt(event, "attacker");
	new killerClient = GetClientOfUserId(killerUserId);
	
	if (numUpgradesAll > 0 || (numUpgradesKiller > 0 && killerClient != 0))
	{
		if(GetConVarInt(Verbosity)>1)
		{
			PrintToChatAll("The witch is dead!  The survivors get upgrades...");
		}
		if(numUpgradesAll > 0)
		{
			for(new i=1; i<GetMaxClients(); i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				GiveClientUpgrades(i, numUpgradesAll);
			}
		}
		if(numUpgradesKiller > 0)
		{
			if(killerClient != 0)
			{
				if(GetConVarInt(Verbosity)>2)
				{
					PrintToChatAll("The primary attacker also gets:");
				}
				else if (GetConVarInt(Verbosity)>1)
				{
					PrintToChat(killerClient, "As primary attacker, you also get:");
				}
				GiveClientUpgrades(killerClient, numUpgradesKiller);
			}
			else
			{
				if(GetConVarInt(Verbosity)>1)
				{
					PrintToChatAll("No primary attacker on the witch, so nobody gets the bonus.");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetEventInt(event, "team")==2)
	{
		CreateTimer(5.0, GiveInitialUpgrades, playerClient);
		return;
	}
	if(GetEventInt(event, "oldteam")==2)
	{
		CreateTimer(4.0, ClearOldUpgradeInfo, playerClient);
	}
}

public OnClientPutInServer(client)
{
	CreateTimer(5.0, GiveInitialUpgrades, client);
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
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[botClient][i] = bClientHasUpgrade[playerClient][i];
	}
	bBotControlled[botClient] = true;
}

public Action:Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Player replaced a bot.
	new playerClient = GetClientOfUserId(GetEventInt(event, "player"));
	new botClient = GetClientOfUserId(GetEventInt(event, "bot"));
	bUpgraded[playerClient] = bUpgraded[botClient];
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[playerClient][i] = bClientHasUpgrade[botClient][i];
	}
	ListMyTeamUpgrades(playerClient, true);
	bBotControlled[botClient] = false;
}

public ListMyTeamUpgrades(client, bool:brief)
{
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

public ListMyUpgrades(client, bool:brief)
{
	if(GetConVarInt(Verbosity)>1)
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

public Action:Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(5.0, GiveInitialUpgrades, playerClient);
}

public OnConfigsExecuted()
{
	new Handle:SU_CVAR = FindConVar("survivor_upgrades");
	SetConVarInt(SU_CVAR, 1);
		
	SetConVarInt(FindConVar("vs_max_team_switches"), 9999);
	
	SetConVarInt(FindConVar("sv_vote_issue_change_difficulty_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_change_map_now_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_change_mission_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_restart_game_allowed"), 1, true, false);
}

public Action:GiveInitialUpgrades(Handle:hTimer, any:client)
{
	if(bBlockUntilRoundStart) return;
	if(!IsClientInGame(client)) return;
	if(GetClientTeam(client) != 2) return;
	if(bUpgraded[client]) return;
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
	new numStarting = GetConVarInt(UpgradesAtSpawn)
	if(numStarting > 0)
	{
		GiveClientUpgrades(client, numStarting);
	}
}

public GiveClientUpgrades(client, numUpgrades)
{
	decl String:name[64];
	GetClientName(client, name, 64);
	for(new num=0; num<numUpgrades; ++num)
	{
		new numOwned = GetNumUpgrades(client);
		if(numOwned == NVALID)
		{
			if(GetConVarInt(Verbosity)>1)
			{
				PrintToChatAll("\x04%s\x01 would have gotten an upgrade but already has them all.", name);
			}
			return;
		}
		new offset = GetRandomInt(0,NVALID-(numOwned+1));
		new val = 0;
		while(offset > 0 || bClientHasUpgrade[client][val] || GetConVarInt(UpgradeAllowed[val])!=1)
		{
			if((!bClientHasUpgrade[client][val]) && GetConVarInt(UpgradeAllowed[val])==1)
			{
				offset = offset - 1;
			}
			val = val + 1;
		}
		GiveClientSpecificUpgrade(client, val);
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

public TakeClientSpecificUpgrade(any:client, upgrade)
{
	SDKCall(RemoveUpgrade, client, IndexToUpgrade[upgrade]);
	bClientHasUpgrade[client][upgrade]=false;
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
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: addUpgrade [upgrade id] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS]
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
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE,
				subTargetName, sizeof(subTargetName), tn_is_ml);

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
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: giveRandomUpgrades [number of Upgrades] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS]
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
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE,
				subTargetName, sizeof(subTargetName), tn_is_ml);
			
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
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: removeUpgrade [upgrade id] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS]
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
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE,
				subTargetName, sizeof(subTargetName), tn_is_ml);
			
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

public Action:ListUpgrades(client, args)
{
	ListMyUpgrades(client, false);
	return Plugin_Handled;
}

public Action:LaserOn(client, args)
{
	if(GetConVarInt(AlwaysLaser) != 1)
	{
		return;
	}
	SDKCall(AddUpgrade, client, 17);
	bClientHasUpgrade[client][6] = true;
}

public Action:LaserOff(client, args)
{
	if(GetConVarInt(AlwaysLaser) != 1)
	{
		return;
	}
	SDKCall(RemoveUpgrade, client, 17);
	bClientHasUpgrade[client][6] = false;
}

public Action:LaserToggle(client, args)
{
	if(GetConVarInt(AlwaysLaser) != 1)
	{
		return;
	}
	if (bClientHasUpgrade[client][6])
	{
		LaserOff(client, 0);
	}
	else
	{
		LaserOn(client, 0);
	}
}
