/*
*	[L4D2] SI Trash Talk
*	Copyright (C) 2025 JustMe
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#define PLUGIN_VERSION "1.0.1"


/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] SI Trash Talk
*	Author	:	JustMe
*	Descrp	:	Allows Special Infected trash talk.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=351524
*	Plugins	:	https://update.sourcemod.net/plugins.php?cat=0&mod=6&title=&author=thaivanco123&description=&search=1

========================================================================================
	Change Log:

1.0.1 (17-May-2026)
	- Replaced crash-prone info_gamemode entity with L4D_GetGameModeType native.

1.0.0 (31-Aug-2025)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <left4dhooks>

#define CVAR_FLAGS FCVAR_NOTIFY

ArrayList g_hGenericKilledLines;
ArrayList g_hBotKilledLines;
ArrayList g_hTankKilledLines;
ArrayList g_hTankKilledRespLines;
ArrayList g_hTeamKillRespLines;
ArrayList g_hSurvMurderLines;
ArrayList g_hSpecMurderLines;
ArrayList g_hSurvIncapLines;
ArrayList g_hSpecGrabLines;
ArrayList g_hMissionLostLines;
ArrayList g_hCampFinishedLines;
ArrayList g_hTextResponseLines;
ArrayList g_hSpecSpawnLines;
ArrayList g_hAlarmLines;
ArrayList g_hWitchDeathLines;
ArrayList g_hWitchCrownLines;
ArrayList g_hMedkitLines;
ArrayList g_hSurvBileLines;

int g_iChances[7];
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow;

// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] SI Trash Talk",
	author = "JustMe",
	description = "Special Infected trash talk",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hGenericKilledLines = new ArrayList(ByteCountToCells(256));
	g_hBotKilledLines = new ArrayList(ByteCountToCells(256));
	g_hTankKilledLines = new ArrayList(ByteCountToCells(256));
	g_hTankKilledRespLines = new ArrayList(ByteCountToCells(256));
	g_hTeamKillRespLines = new ArrayList(ByteCountToCells(256));
	g_hSurvMurderLines = new ArrayList(ByteCountToCells(256));
	g_hSpecMurderLines = new ArrayList(ByteCountToCells(256));
	g_hSurvIncapLines = new ArrayList(ByteCountToCells(256));
	g_hSpecGrabLines = new ArrayList(ByteCountToCells(256));
	g_hMissionLostLines = new ArrayList(ByteCountToCells(256));
	g_hCampFinishedLines = new ArrayList(ByteCountToCells(256));
	g_hTextResponseLines = new ArrayList(ByteCountToCells(256));
	g_hSpecSpawnLines = new ArrayList(ByteCountToCells(256));
	g_hAlarmLines = new ArrayList(ByteCountToCells(256));
	g_hWitchDeathLines = new ArrayList(ByteCountToCells(256));
	g_hWitchCrownLines = new ArrayList(ByteCountToCells(256));
	g_hMedkitLines = new ArrayList(ByteCountToCells(256));
	g_hSurvBileLines = new ArrayList(ByteCountToCells(256));

	g_hCvarAllow = CreateConVar("l4d2_si_trash_talk_allow", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes = CreateConVar("l4d2_si_trash_talk_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff = CreateConVar("l4d2_si_trash_talk_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog = CreateConVar("l4d2_si_trash_talk_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
	CreateConVar("l4d2_si_trash_talk_version", PLUGIN_VERSION, "SI Trash Talk plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d2_si_trash_talk");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	IsAllowed();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	
}

public void OnMapEnd()
{
	
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LoadConfig();

		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("player_incapacitated", Event_PlayerIncap);
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("lunge_pounce", Event_HunterPounce);
		HookEvent("charger_pummel_start", Event_ChargerPummel);
		HookEvent("charger_carry_start", Event_ChargerCarry);
		HookEvent("mission_lost", Event_MissionLost);
		HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
		HookEvent("player_say", Event_PlayerSay);
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("triggered_car_alarm", Event_CarAlarm);
		HookEvent("witch_killed", Event_WitchKilled);
		HookEvent("heal_success", Event_HealSuccess);
		HookEvent("player_now_it", Event_PlayerNowIt);
	}
	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("player_incapacitated", Event_PlayerIncap);
		UnhookEvent("jockey_ride", Event_JockeyRide);
		UnhookEvent("lunge_pounce", Event_HunterPounce);
		UnhookEvent("charger_pummel_start", Event_ChargerPummel);
		UnhookEvent("charger_carry_start", Event_ChargerCarry);
		UnhookEvent("mission_lost", Event_MissionLost);
		UnhookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
		UnhookEvent("player_say", Event_PlayerSay);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("triggered_car_alarm", Event_CarAlarm);
		UnhookEvent("witch_killed", Event_WitchKilled);
		UnhookEvent("heal_success", Event_HealSuccess);
		UnhookEvent("player_now_it", Event_PlayerNowIt);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
    if (g_hCvarMPGameMode == null)
        return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if (iCvarModesTog != 0)
    {
        if (g_iCurrentMode == 0)
        {
            if (!L4D_HasMapStarted())
                return false;
            g_iCurrentMode = L4D_GetGameModeType();
        }

        if (g_iCurrentMode == 0)
            return false;

        if (!(iCvarModesTog & g_iCurrentMode))
            return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}

void LoadConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/l4d2_si_trash_talk.cfg");

	KeyValues kv = new KeyValues("TrashTalk");
	if( kv.ImportFromFile(path) )
	{
		if( kv.JumpToKey("Chances") )
		{
			g_iChances[0] = kv.GetNum("Map_Specific", 8);
			g_iChances[1] = kv.GetNum("On_Death", 4);
			g_iChances[2] = kv.GetNum("On_Death_Bot", 8);
			g_iChances[3] = kv.GetNum("Text_Response", 8);
			g_iChances[4] = kv.GetNum("On_Spawn", 12);
			g_iChances[5] = kv.GetNum("On_Survivor_Heal", 3);
			g_iChances[6] = kv.GetNum("On_Biling", 15);
			kv.GoBack();
		}
	}
	else
	{
		kv.JumpToKey("Chances", true);
		kv.SetNum("Map_Specific", 2);
		kv.SetNum("On_Death", 1);
		kv.SetNum("On_Death_Bot", 2);
		kv.SetNum("Text_Response", 2);
		kv.SetNum("On_Spawn", 3);
		kv.SetNum("On_Survivor_Heal", 1);
		kv.SetNum("On_Biling", 3);
		kv.GoBack();
		kv.Rewind();
		kv.ExportToFile(path);
	}
	delete kv;

	LoadMessagesFromFile("generic_killed.txt", g_hGenericKilledLines);
	LoadMessagesFromFile("bot_killed.txt", g_hBotKilledLines);
	LoadMessagesFromFile("tank_killed.txt", g_hTankKilledLines);
	LoadMessagesFromFile("tank_killed_resp.txt", g_hTankKilledRespLines);
	LoadMessagesFromFile("team_kill_resp.txt", g_hTeamKillRespLines);
	LoadMessagesFromFile("surv_murder.txt", g_hSurvMurderLines);
	LoadMessagesFromFile("spec_murder.txt", g_hSpecMurderLines);
	LoadMessagesFromFile("surv_incap.txt", g_hSurvIncapLines);
	LoadMessagesFromFile("spec_grab.txt", g_hSpecGrabLines);
	LoadMessagesFromFile("mission_lost.txt", g_hMissionLostLines);
	LoadMessagesFromFile("camp_finished.txt", g_hCampFinishedLines);
	LoadMessagesFromFile("text_response.txt", g_hTextResponseLines);
	LoadMessagesFromFile("spec_spawn.txt", g_hSpecSpawnLines);
	LoadMessagesFromFile("alarm.txt", g_hAlarmLines);
	LoadMessagesFromFile("witch_death.txt", g_hWitchDeathLines);
	LoadMessagesFromFile("witch_crown.txt", g_hWitchCrownLines);
	LoadMessagesFromFile("medkit.txt", g_hMedkitLines);
	LoadMessagesFromFile("surv_bile.txt", g_hSurvBileLines);
}

void LoadMessagesFromFile(const char[] filename, ArrayList array)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/l4d2_si_trash_talk/%s", filename);

	array.Clear();

	char dir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dir, sizeof(dir), "configs/l4d2_si_trash_talk");
	if( !DirExists(dir) )
	{
		CreateDirectory(dir, 511);
	}

	if( !FileExists(path) )
	{
		File file = OpenFile(path, "w");
		if( file != null )
		{
			if( StrEqual(filename, "generic_killed.txt") )
			{
				file.WriteLine("lol");
				file.WriteLine("kys");
				file.WriteLine("yeah thats totally fair");
				file.WriteLine("touch grass");
				file.WriteLine("guys can you kick PLAYERNAME");
				file.WriteLine("i bet you missed your parents funeral for l4d2");
				file.WriteLine("get a life please");
				file.WriteLine("i bet your family loves you /s");
				file.WriteLine("is there a reason you dont go outside?");
				file.WriteLine("yeah thats not cheating at all");
				file.WriteLine("wallhacks");
				file.WriteLine("PLAYERNAME is a cheater");
				file.WriteLine("at least i have a life outside of l4d2 unlike you");
				file.WriteLine("192.168.0.1");
				file.WriteLine("have you ever heard of a shower before?");
				file.WriteLine("please kick PLAYERNAME they are cheating");
				file.WriteLine("PLAYERNAME is hacking");
				file.WriteLine("imagine spending your whole life on l4d2");
				file.WriteLine("get a job you loser");
				file.WriteLine("you're such a sweaty tryhard");
				file.WriteLine("lets see how good you are once you turn your aimbot off");
				file.WriteLine("im gonna dox your sorry ass if you keep shooting me");
				file.WriteLine("why are you wasting your life away tryharding at l4d2 PLAYERNAME?");
				file.WriteLine("You must be so proud of yourself, hacking at l4d2 all day");
				file.WriteLine("I can smell PLAYERNAME's sweaty stench from here");
				file.WriteLine("have you ever considered leaving your moms basement?");
				file.WriteLine("its tryhards like you who ruin l4d2");
				file.WriteLine("your parents should have been left 4 dead");
				file.WriteLine("do you actually have a life perchance PLAYERNAME?");
				file.WriteLine("this is so unfair truly");
				file.WriteLine("at least i have someone in my life that loves me unlike you PLAYERNAME");
				file.WriteLine("waited the whole respawn for that");
				file.WriteLine("what no pussy does to a mf");
				file.WriteLine("PLAYERNAME are you gonna turn off your hacks anytime soon?");
				file.WriteLine("that was bullshit");
				file.WriteLine("i am going to filet you like a salmon");
				file.WriteLine("i cannot stand people like you");
				file.WriteLine("its players like you who ruin l4d2");
				file.WriteLine("just so you know you dont have to go all out on a casual game of l4d");
				file.WriteLine("is this all you have in your life PLAYERNAME?");
				file.WriteLine("i think youd enjoy life more if you went outside");
				file.WriteLine("hey PLAYERNAME you know such things like jobs exist right?");
				file.WriteLine("hey PLAYERNAME your shower is feeling rather lonely");
				file.WriteLine("i will hunt down your firstborn");
				file.WriteLine("nobody likes people like you PLAYERNAME");
				file.WriteLine("is the basement you live in getting stuffy PLAYERNAME?");
				file.WriteLine("im gonna fuckin swat this PLAYERNAME i swear to god");
				file.WriteLine("you are disrespecting a future us police officer PLAYERNAME");
				file.WriteLine("im gonna come to your house and gut you");
				file.WriteLine("how's that cardboard box you call home working out PLAYERNAME?");
				file.WriteLine(">:(");
				file.WriteLine("do you think PLAYERNAME actually thinks theyre good at the game");
				file.WriteLine("PLAYERNAME i feel sorry for you");
				file.WriteLine("go volunteer or do something with your life PLAYERNAME");
				file.WriteLine("boy do i love when players like PLAYERNAME come to ruin my games");
				file.WriteLine("i bet PLAYERNAME has screenshots of his kills printed on the walls");
				file.WriteLine("here we see someone with no life whatsoever:");
				file.WriteLine("i am moments from ddosing this fucking server");
				file.WriteLine("wasnt my fault i died it was the tls update");
				file.WriteLine("this is all l4d2 is once tls ruined everything");
			}
			else if( StrEqual(filename, "bot_killed.txt") )
			{
				file.WriteLine("when are some actual players joining this is pissing me off");
				file.WriteLine("why did valve make the bots so broken");
				file.WriteLine("imagine needing robots to win for you lmao");
				file.WriteLine("does this server have some advanced bot mod or something?");
				file.WriteLine("PLAYERNAME the bot is using some advanced bullshit ai");
				file.WriteLine("can you guys stop letting the bots do everything for you");
				file.WriteLine("of course you let the aimbots do everything for you lmao");
				file.WriteLine("dead server");
				file.WriteLine("is that an actual player pretending to be a bot?");
				file.WriteLine("can someone just join already damn");
				file.WriteLine("i swear these bots are cracked");
				file.WriteLine("go into console type status then callvote kick and the id of the bot pls");
				file.WriteLine("revolutionary ai huh valve?");
				file.WriteLine("PLAYERNAME is 100% a human and not a bot they have to be");
				file.WriteLine("these bots are so annoying");
				file.WriteLine("how tf did that bot see me");
				file.WriteLine("i cannot stand these fucking things");
				file.WriteLine("l4d2 would be more fun if bots didnt exist");
				file.WriteLine("i love it when bots insta-snipe me with no chance of me reacting");
				file.WriteLine("can some human players go do something instead of letting the bots win for them");
				file.WriteLine("i cant even dox a bot to stop them");
				file.WriteLine("im gonna go to valve hq to remove bots from the game");
				file.WriteLine("how in gods name do these bots work");
				file.WriteLine("PLAYERNAME are you actually a bot i cannot tell");
			}
			else if( StrEqual(filename, "tank_killed.txt") )
			{
				file.WriteLine("bullshit spawn");
				file.WriteLine("tank is so underpowered");
				file.WriteLine("this is so unbalanced");
				file.WriteLine("my team is ass");
				file.WriteLine("this map sucks anyway");
				file.WriteLine("survivors need to be nerfed badly");
				file.WriteLine("this is so stupid lol");
				file.WriteLine("what am i supposed to do if my idiot team doesnt help me");
				file.WriteLine("again screwed by bad spawn");
				file.WriteLine("im getting so sick of this survivor metamancing crap");
				file.WriteLine("would you please give me a good spawn for once valve?");
				file.WriteLine("this is so unfair");
				file.WriteLine("what can i even do here");
				file.WriteLine("im going back to roblox screw this");
				file.WriteLine("team what the fuck are you doing");
				file.WriteLine("summer sale team always ruins my game");
				file.WriteLine("piece of shit survivors");
				file.WriteLine("PLAYERNAME cool your mouse for a sec k?");
				file.WriteLine("the fuck was that spawn dude lol");
				file.WriteLine("what chance could i have had there");
				file.WriteLine("i bet the survivor team feels so proud of themselves");
				file.WriteLine("fuck this shit im leaving");
				file.WriteLine("who the hell balanced this game i need to know");
				file.WriteLine("my team is run by ants");
				file.WriteLine("team you know you have to help me as tank right?");
				file.WriteLine("they make me go in alone and expect me to win pos team");
				file.WriteLine("im not having fun");
			}
			else if( StrEqual(filename, "tank_killed_resp.txt") )
			{
				file.WriteLine("so were fucked right");
				file.WriteLine("why is our tank so ass");
				file.WriteLine("how do you lose when you have that much health");
				file.WriteLine("can we kick our tank player now");
				file.WriteLine("who let little timmy play tank");
				file.WriteLine("i knew that would happen");
				file.WriteLine("survivors just locking onto the tank bruh");
				file.WriteLine("now what");
				file.WriteLine("our tank fell asleep at the wheel");
				file.WriteLine("our tank is throwing");
				file.WriteLine(":/");
				file.WriteLine("we just fumbled the win there");
				file.WriteLine("he coulda had that cmon");
				file.WriteLine("did he let his little brother play or something");
				file.WriteLine("tank player just fucked us all over");
				file.WriteLine("ok tank that was a pretty poor display there");
			}
			else if( StrEqual(filename, "team_kill_resp.txt") )
			{
				file.WriteLine("uhhhhh you guys good");
				file.WriteLine("at least PLAYERNAME is out of the picture");
				file.WriteLine("LMAO");
				file.WriteLine("hey thanks for doing my job for me");
				file.WriteLine("that makes things easier");
				file.WriteLine("LMAOOOOOOOO");
				file.WriteLine("XD");
				file.WriteLine("PLAYERNAME are u gonna do something about that");
				file.WriteLine("rip");
				file.WriteLine("i think he forgot what team he was on");
				file.WriteLine("hey thanks");
				file.WriteLine("uhhhhh what");
				file.WriteLine("well that should give us an advantage");
				file.WriteLine("PLAYERNAME you should stay down");
				file.WriteLine("lol dumbass");
				file.WriteLine("no wonder the survivors are losing theyre shooting each other");
				file.WriteLine("dude is infighting like hes an enemy in doom");
				file.WriteLine("finally they realised that PLAYERNAME was dead weight");
			}
			else if( StrEqual(filename, "surv_murder.txt") )
			{
				file.WriteLine("rip");
				file.WriteLine("that should be enough");
				file.WriteLine("you have played this before right PLAYERNAME");
				file.WriteLine("EZ");
				file.WriteLine("wipe incoming");
				file.WriteLine("gottem");
				file.WriteLine("LMAO");
				file.WriteLine("zzzzz");
				file.WriteLine("cope harder PLAYERNAME");
				file.WriteLine("you mad PLAYERNAME?");
				file.WriteLine("uninstall");
				file.WriteLine("this mf using steam deck");
				file.WriteLine("dubs");
				file.WriteLine("ok whos next on the chopping block");
				file.WriteLine("this game is so easy with survivors like these");
				file.WriteLine("get fuckin smoked");
				file.WriteLine("one down");
				file.WriteLine("noob down");
				file.WriteLine("( ͡° ͜ʖ ͡°)");
				file.WriteLine("idiot got fucked so hard");
				file.WriteLine("PLAYERNAME you do know how to play right?");
				file.WriteLine("pro tip dont die that easily PLAYERNAME lol");
			}
			else if( StrEqual(filename, "spec_murder.txt") )
			{
				file.WriteLine("what the fuck dude");
				file.WriteLine("bro why");
				file.WriteLine("fuck off");
				file.WriteLine("wow rude");
				file.WriteLine("PLAYERNAME you piece of shit");
				file.WriteLine("fucking asshole thinks killing teammates is funny");
				file.WriteLine("ok ur getting kicked PLAYERNAME");
				file.WriteLine("FUCK OFF");
				file.WriteLine("bro what");
				file.WriteLine("wtf are you doing");
				file.WriteLine("you have got to be kidding me");
				file.WriteLine("the fuck was that for");
				file.WriteLine("????????");
				file.WriteLine("excuse me?");
				file.WriteLine("...ok then");
			}
			else if( StrEqual(filename, "surv_incap.txt") )
			{
				file.WriteLine("ez");
				file.WriteLine("are you guys even trying");
				file.WriteLine("i havent even needed to take of the blindfold yet");
				file.WriteLine("EZ");
				file.WriteLine("wipe incoming");
				file.WriteLine("gottem");
				file.WriteLine("zzzzz");
				file.WriteLine("cope harder PLAYERNAME");
				file.WriteLine("you're so bad its not even funny");
				file.WriteLine("have you tried not playing this game with only one hand?");
				file.WriteLine("you mad bro?");
				file.WriteLine("uninstall");
				file.WriteLine("this mf using steam deck");
				file.WriteLine("dubs");
				file.WriteLine("this game is so easy with survivors like these");
				file.WriteLine("( ͡° ͜ʖ ͡°)");
				file.WriteLine("idiot got fucked so hard");
				file.WriteLine("PLAYERNAME you do know how to play right?");
				file.WriteLine("im actively sleeping while playing this and am still winning");
				file.WriteLine("still winning even though im using a usb steering wheel");
				file.WriteLine("PLAYERNAME just stood there like a dumbass");
				file.WriteLine("noob xd");
			}
			else if( StrEqual(filename, "spec_grab.txt") )
			{
				file.WriteLine("lmao you suck");
				file.WriteLine("imagine being that bad lmao");
				file.WriteLine("learn to m2 loser");
				file.WriteLine("Is this your first time playing PLAYERNAME?");
				file.WriteLine("get gud pls");
				file.WriteLine("have you ever played this game before");
				file.WriteLine("get better please");
				file.WriteLine("you have to not get owned to win btw");
				file.WriteLine("get better!");
				file.WriteLine("i havent even needed to try yet");
				file.WriteLine("youre really good! /s");
				file.WriteLine("please learn the game before ruining our lobbies");
				file.WriteLine("go back to roblox lmao");
				file.WriteLine("worst player ive ever went against lmao");
				file.WriteLine("PLAYERNAME sleeping");
				file.WriteLine("PLAYERNAME getting cooked so hard LMAO");
				file.WriteLine("EZ");
				file.WriteLine("do you have a license for sucking this bad?");
				file.WriteLine("just quit the lobby im not even trying");
				file.WriteLine("this mf using steam deck");
				file.WriteLine("incap incoming");
				file.WriteLine("PLAYERNAME just stood there like a dumbass");
				file.WriteLine("get fucked PLAYERNAME");
				file.WriteLine("that was easy");
				file.WriteLine("didnt even see it coming did you PLAYERNAME");
				file.WriteLine("youre making this so easy im actually getting worse");
				file.WriteLine("honk mimimimimi");
			}
			else if( StrEqual(filename, "mission_lost.txt") )
			{
				file.WriteLine("ez wipe");
				file.WriteLine("imagine losing there lmao");
				file.WriteLine("theyre gonna rage quit watch");
				file.WriteLine("im waiting for them to actually put me in some hard lobbies lmao");
				file.WriteLine("ggez");
				file.WriteLine("we gonna destroy you next round aswell lol");
				file.WriteLine("i couldnt lose that easily of i tried lmao");
				file.WriteLine("this is just getting sad at this point");
				file.WriteLine("really you lose like that?");
				file.WriteLine("its like winning against a toddler in chess, no satisfaction");
				file.WriteLine("are you guys actually gonna try next time?");
				file.WriteLine("thats one less loose end");
				file.WriteLine("watch em quit watch watch");
				file.WriteLine("theyre actively hovering over the quit button i know it");
				file.WriteLine("get the fuck outta here lmao");
				file.WriteLine("and thats how its done. plain and simple");
				file.WriteLine("havent even broken a sweat yet");
				file.WriteLine("you lost to a guy playing blindfolded lol");
			}
			else if( StrEqual(filename, "camp_finished.txt") )
			{
				file.WriteLine("actual bullshit");
				file.WriteLine("i hate this game");
				file.WriteLine("that was so unbalanced");
				file.WriteLine("what a totally fair and fun game that was! /s");
				file.WriteLine("kill yourself");
				file.WriteLine("this game is actually broken");
				file.WriteLine("if only i wasnt lagging so hard");
				file.WriteLine("dumbest game ive played so far");
				file.WriteLine("this sucks im leaving");
				file.WriteLine("the fuck was that");
				file.WriteLine("team what the hell have you been doing this whole time");
				file.WriteLine("im the only one here who was actually doing something");
				file.WriteLine("enough l4d2 for today");
				file.WriteLine("im blocking all of you");
				file.WriteLine("gonna make sure these survivors get nothing but ddosed games from now on");
				file.WriteLine("least unbalanced l4d2 game");
				file.WriteLine("we coulda had that cmon team");
				file.WriteLine("its this damn new internet that doesnt work");
				file.WriteLine("my mouse ran out of charge its not my fault");
				file.WriteLine("pos keyboard doesnt work we coulda won if it did");
			}
			else if( StrEqual(filename, "text_response.txt") )
			{
				file.WriteLine("stfu");
				file.WriteLine("no one cares");
				file.WriteLine("shut up and play already");
				file.WriteLine("i did not ask stfu");
				file.WriteLine("play instead of talking dumbass");
				file.WriteLine("seriously no one gives a shit");
				file.WriteLine("PLAYERNAME are you gonna play or just type all day?");
				file.WriteLine("can you just play already instead of chatting about nothing");
				file.WriteLine("yeah PLAYERNAME thats cool but did i ask?");
				file.WriteLine("imma keep it real with you i do not care");
				file.WriteLine("shut up");
				file.WriteLine("*yawn*");
				file.WriteLine("does he actually think someone is talking to him");
				file.WriteLine("PLAYERNAME have you realised that no one cares yet?");
				file.WriteLine("youre old and wrong");
				file.WriteLine("can you kick PLAYERNAME hes not actually playing");
				file.WriteLine("PLAYERNAME shut the fuck up please :)");
				file.WriteLine("i honestly dont care");
				file.WriteLine("yeah yeah whatever can we play now?");
				file.WriteLine("less talky more shooty pls");
				file.WriteLine("can we play now instead of chatting about nothing");
				file.WriteLine("uh huh sure");
				file.WriteLine("dafuq are they talking about");
				file.WriteLine("im so lost what is he on about");
				file.WriteLine("PLAYERNAME nobody want to hear it just play the game or leave");
				file.WriteLine("shut thee fucketh up please kind sir");
				file.WriteLine("stop talking no one cares");
			}
			else if( StrEqual(filename, "spec_spawn.txt") )
			{
				file.WriteLine("lets fuck em up boys");
				file.WriteLine("wipe incoming trust me");
				file.WriteLine("here we go");
				file.WriteLine("i can already see them shaking in their boots");
				file.WriteLine("cheats arent gonna save them from this");
				file.WriteLine("aight lets go");
				file.WriteLine("this is gonna be easy");
				file.WriteLine("easiest incap of my life incoming");
				file.WriteLine("this should be a freebie");
				file.WriteLine("this should be an easy one");
				file.WriteLine("watch what im about to do");
				file.WriteLine("check this out");
				file.WriteLine("distraction message and then get em");
				file.WriteLine("not one of you are gonna survive this");
				file.WriteLine("im gonna be all over you like shingles");
				file.WriteLine("i am going to enjoy killing each and every one of you idiots");
				file.WriteLine("this is my world. you are not welcome in my world");
				file.WriteLine("hide cowards for i am approaching");
				file.WriteLine("you have moments to live");
				file.WriteLine("im gonna fuck em up so hard");
				file.WriteLine("survivors are not gonna like whats about to happen");
				file.WriteLine("i can say with 100% certainty that we've already pretty much won");
				file.WriteLine("HERE I COME");
				file.WriteLine("boutta pop off so hard");
				file.WriteLine("here i go winning again");
			}
			else if( StrEqual(filename, "alarm.txt") )
			{
				file.WriteLine("thanks for setting off the alarm");
				file.WriteLine("ok that should make things easier for us");
				file.WriteLine("lmao dumbass");
				file.WriteLine("i think PLAYERNAME is trying to help us");
				file.WriteLine("u guys should keep PLAYERNAME hes very helpful");
				file.WriteLine("nice");
				file.WriteLine("lol thanks PLAYERNAME");
				file.WriteLine("i think PLAYERNAME doesnt know hes not meant to shoot those");
			}
			else if( StrEqual(filename, "witch_death.txt") )
			{
				file.WriteLine("useless ai witch");
				file.WriteLine("the fuck was she doing that whole time");
				file.WriteLine("why is the witch so underpowered");
				file.WriteLine("witch cant do anything");
				file.WriteLine("witch is fuckin useless");
				file.WriteLine("was that really all she did");
				file.WriteLine("is this the best ai they could give to the witch");
				file.WriteLine("bruh there goes our insta-incap machine");
				file.WriteLine("witch is so underpowered");
				file.WriteLine("what a waste of a witch");
				file.WriteLine("ok that makes things harder for sure");
			}
			else if( StrEqual(filename, "witch_crown.txt") )
			{
				file.WriteLine("thats such an annoying mechanic");
				file.WriteLine("go play realism noob");
				file.WriteLine("PLAYERNAME who are you trying to impress with your crowning");
				file.WriteLine("worst witch crown ive ever seen");
				file.WriteLine("the fuck was that crown PLAYERNAME");
				file.WriteLine("i think that was his first time crowning a witch");
				file.WriteLine("i hate that survivors are allowed to do that");
				file.WriteLine("why did he crown her like that lol");
				file.WriteLine("that was the weirdest crown ive ever seen in my life");
			}
			else if( StrEqual(filename, "medkit.txt") )
			{
				file.WriteLine("waste of kit");
				file.WriteLine("u should use all the medkits");
				file.WriteLine("dumbest medkit use lol");
				file.WriteLine("rip medkit");
				file.WriteLine("i dont think that was the best time to use that");
				file.WriteLine("bad kit usage");
				file.WriteLine("kick PLAYERNAME for wasting kit");
				file.WriteLine("thats some interesting kit usage");
				file.WriteLine("ok the survivors are stupid if they're using kits like that");
			}
			else if( StrEqual(filename, "surv_bile.txt") )
			{
				file.WriteLine("got a boom");
				file.WriteLine("green looks good on you");
				file.WriteLine("ole mate doesnt know to not shoot the boomer");
				file.WriteLine("+1 boom");
				file.WriteLine("ez");
				file.WriteLine("coulda gotten more");
				file.WriteLine("u guys blind or something");
				file.WriteLine("how did they let me get away with that");
			}
			
			delete file;
		}
	}

	File file = OpenFile(path, "r");
	if( file != null )
	{
		char line[256];
		while( !file.EndOfFile() && file.ReadLine(line, sizeof(line)) )
		{
			TrimString(line);
			if( strlen(line) > 0 && line[0] != ';' && line[0] != '/' && line[0] != '#' )
			{
				array.PushString(line);
			}
		}
		delete file;
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if( !IsValidClient(victim) || !IsValidClient(attacker) )
		return;

	if( GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3 )
	{
		// Survivor killed SI
		if( IsFakeClient(attacker) )
		{
			if( GetRandomInt(1, g_iChances[2]) == 1 )
			{
				char message[256];
				GetRandomArrayString(g_hBotKilledLines, message, sizeof(message));
				FormatPlayerName(attacker, message, sizeof(message));
				SayTrashTalk(victim, message);
			}
		}
		else
		{
			if( GetRandomInt(1, g_iChances[1]) == 1 )
			{
				char message[256];
				GetRandomArrayString(g_hGenericKilledLines, message, sizeof(message));
				FormatPlayerName(attacker, message, sizeof(message));
				SayTrashTalk(victim, message);
			}
		}
	}
	else if( GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2 )
	{
		// SI killed survivor
		char message[256];
		GetRandomArrayString(g_hSurvMurderLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
	else if( GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 3 )
	{
		// SI killed SI
		char message[256];
		GetRandomArrayString(g_hSpecMurderLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
}

public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if( !IsValidClient(victim) || !IsValidClient(attacker) )
		return;

	if( GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3 )
	{
		char message[256];
		GetRandomArrayString(g_hSurvIncapLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
}

public void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if( !IsValidClient(attacker) || !IsValidClient(victim) )
		return;

	if( GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2 && !IsFakeClient(victim) )
	{
		char message[256];
		GetRandomArrayString(g_hSpecGrabLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
}

public void Event_HunterPounce(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if( !IsValidClient(attacker) || !IsValidClient(victim) )
		return;

	if( GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2 && !IsFakeClient(victim) )
	{
		char message[256];
		GetRandomArrayString(g_hSpecGrabLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
}

public void Event_ChargerPummel(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if( !IsValidClient(attacker) || !IsValidClient(victim) )
		return;

	if( GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2 && !IsFakeClient(victim) )
	{
		char message[256];
		GetRandomArrayString(g_hSpecGrabLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
}

public void Event_ChargerCarry(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if( !IsValidClient(attacker) || !IsValidClient(victim) )
		return;

	if( GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2 && !IsFakeClient(victim) )
	{
		char message[256];
		GetRandomArrayString(g_hSpecGrabLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	int randomSI = GetRandomSI();
	if( randomSI != -1 )
	{
		char message[256];
		GetRandomArrayString(g_hMissionLostLines, message, sizeof(message));
		SayTrashTalk(randomSI, message);
	}
}

public void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	int randomSI = GetRandomSI();
	if( randomSI != -1 )
	{
		char message[256];
		GetRandomArrayString(g_hCampFinishedLines, message, sizeof(message));
		SayTrashTalk(randomSI, message);
	}
}

public void Event_PlayerSay(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char text[256];
	event.GetString("text", text, sizeof(text));

	if( IsValidClient(client) && GetClientTeam(client) == 2 && !IsFakeClient(client) && 
		GetRandomInt(1, g_iChances[3]) == 1 && StrContains(text, "!") == -1 )
	{
		int randomSI = GetRandomSI();
		if( randomSI != -1 )
		{
			char message[256];
			GetRandomArrayString(g_hTextResponseLines, message, sizeof(message));
			FormatPlayerName(client, message, sizeof(message));
			SayTrashTalk(randomSI, message);
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if( IsValidClient(client) && GetClientTeam(client) == 3 && IsFakeClient(client) && 
		GetRandomInt(1, g_iChances[4]) == 1 )
	{
		char message[256];
		GetRandomArrayString(g_hSpecSpawnLines, message, sizeof(message));
		SayTrashTalk(client, message);
	}
}

public void Event_CarAlarm(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if( IsValidClient(client) )
	{
		int randomSI = GetRandomSI();
		if( randomSI != -1 )
		{
			char message[256];
			GetRandomArrayString(g_hAlarmLines, message, sizeof(message));
			FormatPlayerName(client, message, sizeof(message));
			SayTrashTalk(randomSI, message);
		}
	}
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	bool oneshot = event.GetBool("oneshot");

	if( IsValidClient(client) )
	{
		int randomSI = GetRandomSI();
		if( randomSI != -1 )
		{
			char message[256];
			if( oneshot )
				GetRandomArrayString(g_hWitchCrownLines, message, sizeof(message));
			else
				GetRandomArrayString(g_hWitchDeathLines, message, sizeof(message));

			FormatPlayerName(client, message, sizeof(message));
			SayTrashTalk(randomSI, message);
		}
	}
}

public void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));
	int health = event.GetInt("health_restored");

	if( IsValidClient(client) && IsValidClient(subject) && 
		GetRandomInt(1, g_iChances[5]) == 1 )
	{
		int fullhp = 50;
		ConVar hCvar = FindConVar("z_difficulty");
		if( hCvar != null )
		{
			char difficulty[16];
			hCvar.GetString(difficulty, sizeof(difficulty));

			if( StrEqual(difficulty, "Hard") || StrEqual(difficulty, "Impossible") )
				fullhp = 70;
		}

		if( health < fullhp && !IsInThirdStrike(subject) )
		{
			int randomSI = GetRandomSI();
			if( randomSI != -1 )
			{
				char message[256];
				GetRandomArrayString(g_hMedkitLines, message, sizeof(message));
				FormatPlayerName(client, message, sizeof(message));
				SayTrashTalk(randomSI, message);
			}
		}
	}
}

public void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if( IsValidClient(victim) && IsValidClient(attacker) && 
		GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3 && 
		GetRandomInt(1, g_iChances[6]) == 1 )
	{
		char message[256];
		GetRandomArrayString(g_hSurvBileLines, message, sizeof(message));
		FormatPlayerName(victim, message, sizeof(message));
		SayTrashTalk(attacker, message);
	}
}



// ====================================================================================================
//					FUNCTIONS
// ====================================================================================================
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsInThirdStrike(int client)
{
	return (GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 1);
}

int GetRandomSI()
{
	int[] clients = new int[MaxClients];
	int count = 0;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsValidClient(i) && GetClientTeam(i) == 3 && IsFakeClient(i) )
		{
			clients[count++] = i;
		}
	}

	return (count > 0) ? clients[GetRandomInt(0, count-1)] : -1;
}

void GetRandomArrayString(ArrayList array, char[] buffer, int maxlen)
{
	if( array.Length > 0 )
	{
		array.GetString(GetRandomInt(0, array.Length-1), buffer, maxlen);
	}
	else
	{
		buffer[0] = '\0';
	}
}

void FormatPlayerName(int client, char[] message, int maxlen)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	ReplaceString(message, maxlen, "PLAYERNAME", name);
}

void SayTrashTalk(int client, const char[] message)
{
	if( !IsValidClient(client) ) return;

	char classname[32];
	GetSIClassName(client, classname, sizeof(classname));

	char formatted[256];
	if( StrEqual(classname, "Smoker") ) {
		Format(formatted, sizeof(formatted), "{green}[%s] {default}%s", classname, message);
	}
	else if( StrEqual(classname, "Boomer") ) {
		Format(formatted, sizeof(formatted), "{blue}[%s] {default}%s", classname, message);
	}
	else if( StrEqual(classname, "Hunter") ) {
		Format(formatted, sizeof(formatted), "{red}[%s] {default}%s", classname, message);
	}
	else if( StrEqual(classname, "Spitter") ) {
		Format(formatted, sizeof(formatted), "{lime}[%s] {default}%s", classname, message);
	}
	else if( StrEqual(classname, "Jockey") ) {
		Format(formatted, sizeof(formatted), "{yellow}[%s] {default}%s", classname, message);
	}
	else if( StrEqual(classname, "Charger") ) {
		Format(formatted, sizeof(formatted), "{orange}[%s] {default}%s", classname, message);
	}
	else if( StrEqual(classname, "Tank") ) {
		Format(formatted, sizeof(formatted), "{lightgreen}[%s] {default}%s", classname, message);
	}
	else {
		Format(formatted, sizeof(formatted), "[%s] %s", classname, message);
	}

	CPrintToChatAll(formatted);
}

void GetSIClassName(int client, char[] buffer, int maxlen)
{
	int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	switch( zombieClass )
	{
		case 1: strcopy(buffer, maxlen, "Smoker");
		case 2: strcopy(buffer, maxlen, "Boomer");
		case 3: strcopy(buffer, maxlen, "Hunter");
		case 4: strcopy(buffer, maxlen, "Spitter");
		case 5: strcopy(buffer, maxlen, "Jockey");
		case 6: strcopy(buffer, maxlen, "Charger");
		case 8: strcopy(buffer, maxlen, "Tank");
		default: strcopy(buffer, maxlen, "SI");
	}
}