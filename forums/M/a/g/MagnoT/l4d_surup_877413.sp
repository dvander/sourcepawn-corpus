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

new bool:bHooked=false;
new bool:bBlockUntilRoundStart;
new bool:g_bIsSUEnabled=false;
new bool:g_bBroadcast=false;
new bool:g_bEnding=false;
new IndexToUpgrade[NVALID];
new bool:bUpgraded[MAXPLAYERS+1];
new bool:bBotControlled[MAXPLAYERS+1];
new bool:bClientHasUpgrade[MAXPLAYERS+1][NVALID];
new String:UpgradeShortInfo[NVALID][256];
new String:UpgradeLongInfo[NVALID][1024];

new Handle:UpgradeAllowed[NVALID];
new Handle:UpgradesAtWitchKillKiller	=INVALID_HANDLE;
new Handle:UpgradesAtWitchKillAll		=INVALID_HANDLE;
new Handle:UpgradesAtTankKillAll		=INVALID_HANDLE;
new Handle:Verbosity					=INVALID_HANDLE;
new Handle:g_hKillCount					=INVALID_HANDLE;
new Handle:g_hSpecialAmmo				=INVALID_HANDLE;

// msgs
new UserMsg:sayTextMsgId;
// kill counters
new killcount[MAXPLAYERS+1];
// for witch
new g_hWokeWitch=0;
// limited special ammo
new g_iSpecialAmmo[MAXPLAYERS+1];

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

	// upgrades data
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

	// cmds
	RegAdminCmd("addupgrade", addUpgrade, ADMFLAG_KICK);
	RegAdminCmd("removeupgrade", removeUpgrade, ADMFLAG_KICK);
	RegAdminCmd("giverandomupgrades", giveRandomUpgrades, ADMFLAG_KICK);
	RegAdminCmd("cleanallupgrades", CleanUpgrades, ADMFLAG_KICK);
	RegConsoleCmd("listupgrades", ListUpgrades);
	RegConsoleCmd("laser", LaserToggle);
	RegConsoleCmd("su_help", UserHelp);

	// hooks
	ActivateHooks();

	CreateConVar("surup_version", PLUGIN_VERSION, "The version of Survivor Upgrades plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	// convars
	UpgradesAtWitchKillKiller	=CreateConVar("surup_upgrades_at_witch_kill_killer", "1", "How many random upgrades to give survivors when they personally kill the witch.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	UpgradesAtWitchKillAll		=CreateConVar("surup_upgrades_at_witch_kill_all", "1", "How many random upgrades to give survivors when their team kills the witch.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	UpgradesAtTankKillAll		=CreateConVar("surup_upgrades_at_tank_kill_all", "1", "How many random upgrades to give survivors when their team kills the tank.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Verbosity					=CreateConVar("surup_verbosity", "2", "How much text output about upgrades players see (0 = none, 3 = max, default 2).", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hKillCount				=CreateConVar("surup_killcount", "120", "How much infected players have to kill to win a upgrade (default 120).", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSpecialAmmo				=CreateConVar("surup_specialammo", "45", "How much special ammo a player can get (default 45).", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	// handling msgs
	sayTextMsgId = GetUserMessageId("SayText");
	HookUserMessage(sayTextMsgId, SayTextHook, true);
	
	// init
	bBlockUntilRoundStart=false;
	g_bIsSUEnabled=false;
	g_bBroadcast=true;
	g_bEnding=false;

	//AutoExecConfig(true, "survivor_upgrades");
	AutoExecConfig(true, "l4d_surup");
}

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "Jerrith",
	description = "Gives survivors access to upgrades.",
	version = PLUGIN_VERSION,
	url = "jerrith.com"
};

public Action:CleanUpgrades(client, args)
{
	// no args required
	ResetValues();
}

// clean upgrades
public ResetValues()
{
	for(new i=1; i<=MaxClients; ++i)
	{
		bUpgraded[i]=false;
		bBotControlled[i]=false;
		for(new j=0; j<NVALID; ++j)
		{
			TakeClientSpecificUpgrade(i,j);
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
	// Prevents warnings when changing maps
	if(GetConVarInt(Verbosity) > 0 && g_bIsSUEnabled==true && g_bBroadcast==true)
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
		// Map change and mission failure reset upgrades
		HookEvent("round_start", Event_RoundStart);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("map_transition", Event_RoundEnd);
		HookEvent("mission_lost", Event_RoundEnd);
		
		// handling tank
		HookEvent("tank_killed", Event_TankKilled);
		
		// handling witch
		HookEvent("witch_harasser_set", Event_WitchWoke);
		HookEvent("witch_killed", Event_WitchKilled);
		
		// kills
		HookEvent("infected_death", KillUpgrade);
		
		HookEvent("player_team", Event_PlayerTeam);
		HookEvent("player_bot_replace", Event_PlayerBotReplace);
		HookEvent("bot_player_replace", Event_BotPlayerReplace);
		HookEvent("infected_hurt", Event_InfectedHurt);
		HookEvent("player_hurt", Event_PlayerHurt);
		
		// healing
		HookEvent("heal_success", Event_PlayerHealing);
		
		// hook weapon_fire to track the amount of bullets shot by the client
		HookEvent("weapon_fire", Event_TrackFire);
		
		// player is dead, so remove upgrades
		HookEvent("player_death", Event_Dead);
		
		// clean stats
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
	PrintToServer("[SU LOG: Map start");
	if(g_bIsSUEnabled==false)
	{
		// enough for everyone
		CreateTimer(25.0, ActivateSU);
	}
}
public Action:ActivateSU(Handle:hTimer)
{
	SetConVarInt(FindConVar("survivor_upgrades"), 1, true, false);
	//PrintToChatAll("Survivor Upgrades state: %d", GetConVarInt(FindConVar("survivor_upgrades")));
	g_bIsSUEnabled=true;
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("[SU LOG: Round start: %d clients - Real: %d", MaxClients, GetClientCount(true));
	bBlockUntilRoundStart=false;
	g_bEnding=false;
	return Plugin_Continue;
}
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("[SU LOG: Round end");
	bBlockUntilRoundStart=true;
	g_bIsSUEnabled=false;
	
	// clean upgrades
	ResetValues();
	
	// turn off survivor_upgrades convar to avoid bad behavior
	SetConVarInt(FindConVar("survivor_upgrades"), 0, true, false);
	//PrintToChatAll("Survivor Upgrades state: %d", GetConVarInt(FindConVar("survivor_upgrades")));
	
	return Plugin_Continue;
}

// notice that I didn't care about the ammo your currently holding
// clean whatever you have, hollow-point or incendiary
public Action:Event_TrackFire(Handle:event, const String:ename[], bool:dontBroadcast)
{
	// shooter
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	
	// only track special ammo usage
	if(client && (bClientHasUpgrade[client][14]==true || bClientHasUpgrade[client][9]==true))
	{
		g_iSpecialAmmo[client]++;
		//PrintCenterText(client, "Special ammo shots: %d", g_iSpecialAmmo[client]);
	
		if(g_iSpecialAmmo[client]>=GetConVarInt(g_hSpecialAmmo))
			CreateTimer(1.0, ExpireUpgrade, client);
	}
	return Plugin_Continue;
}

// Handling incendiary ammo
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	if(attacker == 0)	return Plugin_Continue;
	
	new client=GetClientOfUserId(attacker);
	
	// is incendiary?
	if (!bClientHasUpgrade[client][14])	return Plugin_Continue;
	
	if (GetClientTeam(client) != 2)	return Plugin_Continue;
	
	new infected = GetEventInt(event, "userid");
	new infectedClient = GetClientOfUserId(infected);
	
	// we don't want survivors in flames!
	if (GetClientTeam(infectedClient)!=3) return Plugin_Continue;
	
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
	if (!bClientHasUpgrade[client][14])	return Plugin_Continue;
	if(GetClientTeam(client) != 2) return Plugin_Continue;
	
	new infected = GetEventInt(event, "entityid");
	new damagetype = GetEventInt(event, "type");

	// if you shot a witch, she burns 4ever! solved
	decl String:witchn[64];
	GetEntityNetClass(infected, witchn, 64);
	if(strcmp(witchn, "Witch")==0) return Plugin_Continue;
	
	if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
	{
		IgniteEntity(infected, 360.0, false);
	}
	return Plugin_Continue;
}

// Gives a upgrade for who heal another player
public Action:Event_PlayerHealing(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Gives a upgrade for the one who healed somebody
	new healer = GetClientOfUserId(GetEventInt(event, "userid"));
	new healed = GetClientOfUserId(GetEventInt(event, "subject"));
	if(healer==0||healed==0) return Plugin_Handled;
	
	// bots are nice people
	// nah nah nah... not for bots
	if(IsFakeClient(healed)==true || IsFakeClient(healer)==true) return Plugin_Continue;
	
	// just handling bad behavior
	if (healer==healed)
		return Plugin_Continue;
	
	decl String:plname[64];
	GetClientName(healed, plname, 64);
	PrintToChat(healer, "\x05[ \x01You won a upgrade for healing \x04%s\x01.", plname);
	
	// Only for real players
	if (IsClientInGame(healer) && GetClientTeam(healer)==2 && healer!=healed && !IsFakeClient(healer))
		GiveClientUpgrades(healer, 1);
	
	return Plugin_Continue;
}

// Considering cheat since it's warning players about tank (?)
/*public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
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
}*/

public Action:Event_TankKilled(Handle:event, const String:ename[], bool:dontBroadcast)
{
	new numUpgradesAll=GetConVarInt(UpgradesAtTankKillAll);
	
	// finale constantly spawns tanks
	if (numUpgradesAll>0 && g_bEnding==false)
	{
		if(GetConVarInt(Verbosity)>0)
			PrintToChatAll("\x05[ \x01Tank is dead! The survivors get items...");
		
		// Upgrade for everyone
		// The player must be alive!
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i)==2 && !IsFakeClient(i) && IsPlayerAlive(i)==true)
				GiveClientUpgrades(i, 1);
		}
	}

	return Plugin_Continue;
}

//==================================================================================================
// Witch routines:
// Gives upgrades:	2 for the witch killer (one-shot)
//					1 for team, none for who woke her up without killing her
public Action:Event_WitchWoke(Handle:event, const String:ename[], bool:dontBroadcast)
{
	//short	userid	Player who woke up the witch
	//long 	witchid	Entindex of witch woken up
	// clean handle
	g_hWokeWitch=0;
	
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if (client==0) return Plugin_Handled;

	// assign handle
	g_hWokeWitch=client; 
	return Plugin_Continue;
}
public Action:Event_WitchKilled(Handle:event, const String:ename[], bool:dontBroadcast)
{
	//short userid	Player who killed the witch
	//long 	witchid	Entindex of witch that was killed.
	//bool 	oneshot	TRUE if the Witch was killed with one shot 
	
	// External config file
	new numUpgradesAll=GetConVarInt(UpgradesAtWitchKillAll);
	new numUpgradesKiller=GetConVarInt(UpgradesAtWitchKillKiller);
	
	// Get handles
	new killerClient=GetClientOfUserId(GetEventInt(event, "userid"));
	new bOneShot=GetEventBool(event, "oneshot");
	
	// Starting
	if (numUpgradesAll>0 || (numUpgradesKiller>0 && killerClient!=0))
	{
		if(GetConVarInt(Verbosity)>0)
			PrintToChatAll("\x05[ \x01Witch is dead! The survivors get items...");
				
		// Upgrade for the killer
		if(numUpgradesKiller==1)
		{
			if (bOneShot==1) // true
			{
				// The player whom killed her with one-shot gets 1 extra upgrade
				if(killerClient!=0 && IsClientInGame(killerClient)==true && GetClientTeam(killerClient)==2)
				{
					decl String:killerName[64];
					GetClientName(killerClient, killerName, 64);
					PrintToChatAll("\x05[ \x04%s\x01 killed the witch with one single shot", killerName);
					GiveClientUpgrades(killerClient, 1);
				} 
			}
		}
		
		// Upgrade for everyone
		if(numUpgradesAll==1)
		{
			for(new i=1; i<=MaxClients; i++)
			{
				// Person who woke up witch and didn't killed her doesn't get anything (punishment!)
				// IsPlayerAlive: avoid spectators from getting upgrades (not playing!)
				if(i!=g_hWokeWitch && IsClientInGame(i)==true && GetClientTeam(i)==2 && IsPlayerAlive(i)==true)
				{
					GiveClientUpgrades(i, 1);
				} else
				if(i==g_hWokeWitch)
				{
					PrintToChat(i,"\x05[ \x01You woke up the witch but didn't killed her");
					PrintToChat(i,"\x05[ \x01No upgrades for you");
					// clean handle
					g_hWokeWitch=0;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetEventInt(event, "oldteam")==2)
	{
		CreateTimer(4.0, ClearOldUpgradeInfo, playerClient);
	}
}

public OnClientPutInServer(client)
{
	if(client)
	{
		CreateTimer(20.0, ShowHelp, client);
	}
}

public Action:ShowHelp(Handle:hTimer, any:client)
{
	if(GetClientTeam(client)!=2) return;
	
	PrintToChat(client, "\x05[ \x01This server is running \x04Survivor Upgrades\x01 plugin");
	PrintToChat(client, "\x05[ \x01Type in the console:");
	PrintToChat(client, "\x05[ \x04laser\x01 to activate your laser sight");
	PrintToChat(client, "\x05[ \x04listupgrades\x01 to check out your upgrades");
	PrintToChat(client, "\x05[ \x04su_help\x01 to see this info");
}

public Action:ClearOldUpgradeInfo(Handle:hTimer, any:playerClient)
{
	// This is an attempt to prevent bots from getting extra upgrades... :)
	if(bBotControlled[playerClient])
	{
		return;
	}
	bUpgraded[playerClient] = false;
	for(new i=0; i<NVALID; ++i)
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
	for(new i=0; i<NVALID; ++i)
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
	for(new i=0; i<NVALID; ++i)
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
		for(new i=1;i<=MaxClients;i++)
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
	if(GetConVarInt(Verbosity)>0)
	{
		decl String:name[64];
		GetClientName(client, name, 64);
		for(new upgrade=0; upgrade<NVALID; ++upgrade)
		{
			if(bClientHasUpgrade[client][upgrade])
			{
				PrintToChat(client, "\x05[ \x01You have \x03%s\x01.", UpgradeShortInfo[upgrade]);
				if(GetConVarInt(Verbosity)>2 || !brief)
				{
					PrintToChat(client, "%s", UpgradeLongInfo[upgrade]);
				}
			}
		}
	}
}

/*public Action:Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(5.0, GiveInitialUpgrades, playerClient);
}*/

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

/*public Action:GiveInitialUpgrades(Handle:hTimer, any:client)
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
}*/

// Give N upgrades
public GiveClientUpgrades(client, numUpgrades)
{
	for(new num=0; num<numUpgrades; ++num)
	{
		// check if client got all upgrades
		new numOwned=GetNumUpgrades(client);
		if(numOwned==NVALID)
		{
			if(GetConVarInt(Verbosity)>1)
				PrintToChat(client, "\x05[ \x01You already got all upgrades.");
			return;
		}
		
		// Give random upgrade: the old version is way complicated!
		// attempts: 30 times
		for (new i=0; i<NVALID*2;++i)
		{
			new randUp=GetRandomInt(0,NVALID-1);
			//PrintToServer("[LOG: Trying %s - id: %d", UpgradeShortInfo[randUp], randUp);
			
			// Only one type of special ammo is allowed
			if((randUp==14 && bClientHasUpgrade[client][9]==true) || (randUp==9 && bClientHasUpgrade[client][14]==true))
			{
				PrintToChat(client, "\x05[ \x01You already have a special ammo");
			} else if(bClientHasUpgrade[client][randUp]==false && GetConVarInt(UpgradeAllowed[randUp])==1)
			{
				//PrintToServer("[LOG: Giving %s - id: %d", UpgradeShortInfo[randUp], randUp);
				GiveClientSpecificUpgrade(client, randUp);
				return;
			}
		}
	}
}

// Bots don't get items!
public GiveClientSpecificUpgrade(any:client, upgrade)
{
	decl String:name[64];
	GetClientName(client, name, 64);
	new VerbosityVal=GetConVarInt(Verbosity);

	// Print tasks
	if(VerbosityVal>2)
	{
		PrintToChatAll("\x04%s\x01 got %s\x01.", name, UpgradeShortInfo[upgrade]);
		PrintToChat(client, "%s", UpgradeLongInfo[upgrade]);
	}
	else if (VerbosityVal>0)
	{
		PrintToChat(client, "\x05[ \x01You have \x03%s\x01.", UpgradeShortInfo[upgrade]);
	}
	
	//======================================================================
	// dá o upgrade
	// not for bots
	if (IsFakeClient(client)==false)
	{
		SDKCall(AddUpgrade, client, IndexToUpgrade[upgrade]);
		bClientHasUpgrade[client][upgrade]=true;
	} else {
		return;
	}
	
	//======================================================================
	if(IndexToUpgrade[upgrade] == 30 || IndexToUpgrade[upgrade] == 21)
	{
		PrintToChat(client, "\x05[ \x01with\x04 %d bullets\x01 only.", GetConVarInt(g_hSpecialAmmo));
	}
}

// Notice that I clean both hollow-point and incendiary
public Action:ExpireUpgrade(Handle:hTimer, any:client)
{
	if(bClientHasUpgrade[client][14])
	{
		PrintToChat(client, "\x05[ \x01Your incendiary ammo is over now.");
		TakeClientSpecificUpgrade(client,14);
	}
	if(bClientHasUpgrade[client][9])
	{
		PrintToChat(client, "\x05[ \x01Your hollow-point ammo is over now.");
		TakeClientSpecificUpgrade(client,9);
	}
	
	// reset counter
	g_iSpecialAmmo[client]=0;
}

public TakeClientSpecificUpgrade(any:client, upgrade)
{
	SDKCall(RemoveUpgrade, client, IndexToUpgrade[upgrade]);
	bClientHasUpgrade[client][upgrade]=false;
}

// player is dead so we remove any upgrades it might have
public Action:Event_Dead(Handle:event, const String:ename[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(client==0) return Plugin_Handled;
	if(GetClientTeam(client)!=2) return Plugin_Continue;
	
	// dont broadcast knife, raincoat etc
	g_bBroadcast=false;
	
	// client lost upgrades
	for(new i=0;i<NVALID;++i)
	{
		if(bClientHasUpgrade[client][i]==true)
		{
			TakeClientSpecificUpgrade(client,i);
		}
	}
	
	// tell client
	PrintToChat(client, "\x05[ \x01You're dead and lost all of your upgrades.");
	
	//back again
	g_bBroadcast=true;
	
	return Plugin_Continue;
}

public GetNumUpgrades(client)
{
	new num=0;
	for(new i=0; i<NVALID; ++i)
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

// handling laser
public Action:LaserToggle(client, args)
{
	if (bClientHasUpgrade[client][6])
	{
		LaserOff(client, 0);
	}
	else
	{
		LaserOn(client, 0);
	}
}
public Action:LaserOn(client, args)
{
	PrintToChat(client, "\x05[ \x01Laser on");
	SDKCall(AddUpgrade, client, 17);
	bClientHasUpgrade[client][6] = true;
}
public Action:LaserOff(client, args)
{
	PrintToChat(client, "\x05[ \x01Laser off");
	SDKCall(RemoveUpgrade, client, 17);
	bClientHasUpgrade[client][6] = false;
}

//==============================================================================================
// Help!
public Action:UserHelp(client, args)
{
	// no args required
	PrintToChat(client, "\x05[ \x01Type in the console:");
	PrintToChat(client, "\x05[ \x04laser\x01 to activate your laser sight");
	PrintToChat(client, "\x05[ \x04listupgrades\x01 to check out your upgrades");
}

//==================================================================================================
// Kill upgrades:
// Gives upgrade:	everytime a player kills 120 infected
public Action:KillUpgrade(Handle:event, String:ename[], bool:dontBroadcast)
{
	new client 			= GetClientOfUserId(GetEventInt(event, "attacker"));
	//new bool:headshot 	= GetEventBool(event, "headshot");
	new bool:minigun 	= GetEventBool(event, "minigun");
	new bool:blast 		= GetEventBool(event, "blast");
	
	if (client)
	{
		// normal shot
		if (!minigun && !blast) 
			killcount[client] += 1;
			
		// Gives a upgrade everytime a player kills 120 infected
		if ((killcount[client] % GetConVarInt(g_hKillCount)) == 0 && killcount[client] > 1)
		{
			if(IsClientInGame(client)==true && GetClientTeam(client)==2)
			{
				decl String:name[64];
				GetClientName(client, name, 64);
				PrintToChatAll("\x05[ \x04%s\x01 won a upgrade for killing %d infected.",name, killcount[client]);
				GiveClientUpgrades(client, 1);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_Endind(Handle:event, const String:ename[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; ++i)
		killcount[i]=0;
	
	g_bIsSUEnabled=false;
	g_bEnding=true;
	
	// clean upgrades
	ResetValues();
	
	// turn off survivor_upgrades convar to avoid bad behavior
	SetConVarInt(FindConVar("survivor_upgrades"), 0, true, false);
	//PrintToChatAll("Survivor Upgrades state: %d", GetConVarInt(FindConVar("survivor_upgrades")));
}