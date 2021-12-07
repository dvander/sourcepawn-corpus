//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1

#define SOUND_LEVELUP "misc/happy_birthday.wav"
#define SOUND_MISSION "imgay/skill_up.wav"
#define SOUND_MISSION_FAILED "imgay/death.mp3"
#define ACHIEVEMENT_PARTICLE     "Achieved"

#define SPR_VOICE_VMT	"materials/sprites/minimap_icons/voiceicon.vmt"
#define SPR_VOICE_VTF	"materials/sprites/minimap_icons/voiceicon.vtf"

#define TF2_PLAYER_SLOWED       (1 << 0)    // 1		Heavy Firing
#define TF2_PLAYER_ZOOMED       (1 << 1)    // 2		Sniper Zoom
#define TF2_PLAYER_DISGUISING   (1 << 2)    // 4		Undergoing Disguise
#define TF2_PLAYER_DISGUISED	(1 << 3)    // 8		Is disguised
#define TF2_PLAYER_CLOAKED      (1 << 4)    // 16		Is invisible
#define TF2_PLAYER_INVULN       (1 << 5)    // 32		Ubercharge
#define TF2_PLAYER_GLOWING	    (1 << 6)    // 64		Teleport Trail
#define TF2_PLAYER_TAUNTING	    (1 << 7)    // 128		Taunting
#define TF2_PLAYER_TELEPORT		(1 << 10)   // 1024		Is in teleporter
#define TF2_PLAYER_CRITS	    (1 << 11)   // 2048		Kritzkrieg
#define TF2_PLAYER_FEIGNDEATH	(1 << 13)   // 8192		Dead Ringer
#define TF2_PLAYER_BLUR		    (1 << 14)   // 16384	Bonk (Fast)
#define TF2_PLAYER_STUN			(1 << 15)   // 32768 	Bonk (Slow)
#define TF2_PLAYER_HEALING      (1 << 16)   // 65536 	Medic healing
#define TF2_PLAYER_ONFIRE		(1 << 17)   // 131072 	On fire
#define TF2_PLAYER_OVERHEALING  (1 << 18)   // 262144	Is overhealed
#define TF2_PLAYER_JAR	  		(1 << 19)   // 524288	Is jarate'd

#define PLUGIN_VERSION "0.1"

new g_ItemRewardCount;
new g_ItemRewardName[256][256];
new g_ItemRewardExpire[256];
new g_ItemRewardLevel[256];
new g_ItemRewardClass[256];
new g_LIST_USERS[MAXPLAYERS+1];
new g_Rocket_Jump[MAXPLAYERS+1];
new g_Demo_Splash[MAXPLAYERS+1];
new g_Demo_Splash_Dmg[MAXPLAYERS+1];
new g_Client_Mission_C[MAXPLAYERS+1];
new g_Client_Mission_I[MAXPLAYERS+1];
new g_Client_Mission_T[MAXPLAYERS+1];
new g_Client_Mission_S[MAXPLAYERS+1];
new g_Client_Mission_M[MAXPLAYERS+1];
new g_Client_Heal[MAXPLAYERS+1];
new g_Target_Particles[MAXPLAYERS+1];
new Handle:levelHUD[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_Demo_Splash_Reset[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_Mission_Counter[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_Freezecam[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:hudLevel1;
new Handle:hudLevel2;
new Handle:hudLevel3;
new Handle:hudXp1;
new Handle:hudXp2;
new Handle:hudXp3;
new Handle:hudMission;
new Handle:g_CVDB = INVALID_HANDLE;
//new Handle:hudLevelUp;

new Handle:g_HDATABASE = INVALID_HANDLE;			/** Database connection */
new boolean:g_BCONNECTED = false;

new round_start = true;

new Handle:cvar_enable;
new Handle:cvar_level_default;
new Handle:cvar_level_max;
new Handle:cvar_exp_default;
new Handle:cvar_exp_levelup;
new Handle:cvar_show_skill_name;
new Handle:cvar_show_rank_name;
new Handle:cvar_equip;
new Handle:cvar_missions;
new Handle:cvar_beta;
new Handle:cvar_nosubmit;
new Handle:cvar_sprite;

new AllowLoad = true;

static const String:var_mission[][] = {
"Kill your target with a rocket, then taunt!", "Hit your target 3 times total with rockets while rocket jumping!", "Kill your target with a melee weapon!",
"?", "Axtinguish or Backburn your target!", "Kill your target from a great distance!",
"Hit your target with the Scattergun or FaN at point blank range!", "?", "Kill your target while in the air!",
"?", "?", "Slay your target with a melee weapon!",
"?", "?", "Kill your target with a melee weapon!",
"?", "Shoot your target in the head once!", "?",
"?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?"};

static const String:var_desc[][] = {
"Hit enemies directly with rockets!","Rocket Jump and hurt enemies!","Hit enemies up close!",
"Reflect objects!", "Ambush using the backburner or axtinguisher!", "Hurt enemies from a distance!",
"Hurt enemies badly in one shot with the Scattergun or FaN!", "Hurt and kill enemy support classes!", "Hurt enemies while airborne!",
"Hit multiple enemies at once with explosives!", "Destroy buildings!", "Slay ememies with melee weapons!",
"Kill enemies using your sentry!", "Support your team with dispensers and teleporters!", "Kill enemies with your wrench (spies are a good target)!",
"Hit enemies at close range!", "Kill enemies by shooting them in the head using your Sniper or Huntsman!", "Attack enemies that are disabled (slowed by spinning minigun, on fire, taunting, or otherwise)"};

static const String:var_skills[][] = {
"Soldat's Aim","Air Force","Close Combatant",
"Poof Blaster", "Ambush Academy", "Distance Damager",
"Meatshot", "Support Stalker", "Air Mobility",
"Splash Master", "Hardhat Harmer", "Drunken Royalty",
"Sentry Shooting", "Team Support", "Wacky Wrench",
"Sneakup Sniper", "Boom Headshot", "Psychological Warfare"};

static const String:var_ranks[][] = {
"Aiming Amateur","Private Scopist", "Elite Scopist", "The Direct Hit","Private Birdie", "Captain Sparrow", "Lieutenant Hawk", "Screamin' Eagle", "Distant Coward", "Mobility Unit", "Point Blank Catalyst", "Saxton Hale",
"Baby Poofer", "Cold Breezer", "Jet Lagger", "Tornado", "Student Stinger", "Back Biter", "Spinal Tapper", "Queen Bee", "Hugger", "Knuckle Dodger", "Yardman", "Fiercy Sniper",
"Vegetarian", "Butcher", "Slaughterer", "Mass Murderer", "Easily Spotted", "Drink Slipper", "Kidnapper", "Secret Agent", "Ground Turtle", "Jumpman", "Floating Fist", "Lucy in the Sky",
"Hardly Flowing", "Dog Paddler", "The Breaststroker", "Olympic Athlete", "Toy Bomb", "C4", "Artillery", "Nuclear Bomb", "Sober Stable Boy", "Baron Le Wine", "Duke BAC", "Knight of the Bottle-shaped Table",
"Ol' Rusty", "Dirty Pipes", "Clean Machine", "Massive Tank", "Solo Show", "Little Helper", "Life Saver", "Team's Best Friend", "Toy Story", "Monkey Wrench", "Wrench Massacrist", "Monster Wrench",
"Forest Camper", "Mile Man", "Corner Killer", "Battle Frontier", "Bodyshooter", "Chesthitter", "Neck Cutter", "Head Hammer", "Mentally Stable", "Schizophrenic", "Maniac", "Man Who Bludged Wife with Golf Trophy",
"?", "?", "?", "?", "?", "?", "?", "?"};

static const String:var_classes[][] = {"Soldier", "Pyro","Scout","Demoman","Engineer","Sniper","?","?","?"};
static const String:var_announcer_kill[][] = {"vo/announcer_dec_kill07.wav", "vo/announcer_dec_kill08.wav", "vo/announcer_dec_kill09.wav", "vo/announcer_dec_kill11.wav", "vo/announcer_dec_kill12.wav", "vo/announcer_dec_missionbegins10s01.wav"};
static const String:var_announcer_gj[][] = {"vo/announcer_dec_success01.wav", "vo/announcer_dec_success02.wav"};

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo = 
{
    name = "Cosmetic Class Experience",
    author = "Mecha the Slag",
    description = "Cosmetic Class Experience",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
    // G A M E  C H E C K //
    decl String:game[32];
    GetGameFolderName(game, sizeof(game));
    if(!(StrEqual(game, "tf")))
    {
        SetFailState("This plugin is not for %s", game);
    }
    
    // C O N V A R S //
    cvar_enable = CreateConVar("cce_enabled", "1", "Enables the plugin");
    cvar_level_default = CreateConVar("cce_level_default", "1", "Default level for players when they join");
    cvar_level_max = CreateConVar("cce_level_max", "4", "Maxmimum level players can reach");
    cvar_exp_default = CreateConVar("cce_exp_default", "150", "Default max experience for players when they join");
    cvar_exp_levelup = CreateConVar("cce_exp_levelup", "500", "Experience increase on level up");
    cvar_show_skill_name = CreateConVar("cce_show_skill_name", "1", "Show the skill name in the hud?");
    cvar_show_rank_name = CreateConVar("cce_show_rank_name", "1", "Show the rank name in the hud?");
    cvar_equip = CreateConVar("cce_equip", "1", "Use with Damizean's Equipment Manager?");
    cvar_missions = CreateConVar("cce_missions", "7", "Mission maximum roll rate. If 0, missions are disabled.");
    cvar_beta = CreateConVar("cce_beta", "0", "Beta testing features.");
    cvar_nosubmit = CreateConVar("cce_nosubmit", "1", "Skills do not get submitted (useful for beta testing).");
    cvar_sprite = CreateConVar("cce_sprite", "1", "Indicate the target with a sprite?");
    g_CVDB 	= CreateConVar("cce_db", "cce", "MySQL Database to use");
    CreateConVar("cce_version", PLUGIN_VERSION, "Version of the plugin");
    
    // H O O K S //
    HookEvent("player_hurt", Player_Hurt);
    HookEvent("player_death", Player_Death);
    HookEvent("rocket_jump", Rocket_Jump);
    HookEvent("rocket_jump_landed", Rocket_Jump_Landed);
    HookEvent("object_deflected", Object_Deflected);
    HookEvent("player_spawn", Player_Spawn);
    HookEvent("player_team", Player_Team);
    HookEvent("object_destroyed", Object_Destroyed);
    HookEvent("player_teleported", Player_Teleported);
    HookEvent("player_shield_blocked", Player_Shield_Blocked);
    RegConsoleCmd("say", Cmd_BlockTriggers);
    RegConsoleCmd("say_team", Cmd_BlockTriggers);
    HookEvent		("teamplay_point_captured", point_captured);
    HookEvent("teamplay_round_win", Event_Round_End);
    HookEvent("teamplay_round_active", Event_Round_Begin);
    HookEvent("arena_round_start", Event_Round_Begin);
    HookEvent("teamplay_restart_round", Event_Round_Begin);
    
    // O T H E R //
    hudLevel1 = CreateHudSynchronizer();
    hudLevel2 = CreateHudSynchronizer();
    hudLevel3 = CreateHudSynchronizer();
    hudMission = CreateHudSynchronizer();
    hudXp1 = CreateHudSynchronizer();
    hudXp2 = CreateHudSynchronizer();
    hudXp3 = CreateHudSynchronizer();
    //hudLevelUp = CreateHudSynchronizer();
    
    RegConsoleCmd("cce_test",        Cmd_Test, "test");
    
    RegConsoleCmd("skill",                 Cmd_Menu, "Shows the skill help");
    RegConsoleCmd("skills",                Cmd_Menu, "Shows the skill help");
    RegConsoleCmd("stats",                Cmd_Menu, "Shows the skill help");
    RegConsoleCmd("help",                  Cmd_Menu, "Shows the skill help");
    RegConsoleCmd("em",                  Cmd_Menu, "Shows the skill help");
    RegConsoleCmd("equip",                  Cmd_Menu, "Shows the skill help");
}

public OnMapEnd()
{
	/**
	 * Clean up on map end just so we can start a fresh connection when we need it later.
	 */
	if (g_HDATABASE != INVALID_HANDLE)
	{
		CloseHandle(g_HDATABASE);
		g_HDATABASE = INVALID_HANDLE;
	}
}

public OnMapStart() {
    ParseAwardList();
}

public Action:Event_Round_Begin(Handle:event, const String:name[], bool:dontBroadcast)
{
    round_start = true;
    return Plugin_Continue;
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
    round_start = false;
    return Plugin_Continue;
}



//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientPostAdminCheck(client) {
    if(GetConVarInt(cvar_enable) && AllowLoad)
    {
        levelHUD[client] = CreateTimer(5.0, DrawHudTimer, client);
        g_Client_Heal[client] = 0;
        g_Rocket_Jump[client] = 0;
        g_Demo_Splash[client] = 0;
        g_Demo_Splash_Dmg[client] = 0;
        g_Client_Mission_C[client] = 0;
        g_Client_Mission_I[client] = 0;
        g_Client_Mission_T[client] = 0;
        g_Client_Mission_S[client] = 0;
        g_Client_Mission_M[client] = 0;
    }
}

public OnClientPutInServer(client) {
    if(GetConVarInt(cvar_enable) && AllowLoad)
    {
        GetClientPref(client);
        CheckClientEquip(client, -1, -1);
        CreateTimer(30.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:Timer_Welcome(Handle:hTimer, any:iClient)
{
	if (iClient < 1 || iClient > MaxClients) return Plugin_Stop;
	if (!IsValidClient(iClient)) return Plugin_Stop;
	
	CPrintToChat(iClient, "Welcome to the MFGG Server. Type !skills in chat to view your skills and progress!");
	return Plugin_Stop;
}


///////////////////
//D R A W  H U D //
///////////////////
DrawHud(any:client)
{
    if(IsValidClient(client))
    {
        // SKILLS
        Client_Healed(client);
    
    
        new insert = g_LIST_USERS[client];
        new tfclass = GetClientClass(client);
        
        if (tfclass >= 0) {
            // GET MAX XPs
            new max_xp1 = GetConVarInt(cvar_exp_default) + (GetArrayCell(insert,tfclass * 3 + 0,0)-1) * (GetConVarInt(cvar_exp_levelup));
            new max_xp2 = GetConVarInt(cvar_exp_default) + (GetArrayCell(insert,tfclass * 3 + 1,0)-1) * (GetConVarInt(cvar_exp_levelup));
            new max_xp3 = GetConVarInt(cvar_exp_default) + (GetArrayCell(insert,tfclass * 3 + 2,0)-1) * (GetConVarInt(cvar_exp_levelup));
            
            // ADD NEW LEVELS
            if(GetArrayCell(insert,tfclass * 3 + 0,1) >= max_xp1 && GetArrayCell(insert,tfclass * 3 + 0,0) < GetConVarInt(cvar_level_max)) LevelUp(client, tfclass, 1, max_xp1);
            if(GetArrayCell(insert,tfclass * 3 + 1,1) >= max_xp2 && GetArrayCell(insert,tfclass * 3 + 1,0) < GetConVarInt(cvar_level_max)) LevelUp(client, tfclass, 2, max_xp2);
            if(GetArrayCell(insert,tfclass * 3 + 2,1) >= max_xp3 && GetArrayCell(insert,tfclass * 3 + 2,0) < GetConVarInt(cvar_level_max)) LevelUp(client, tfclass, 3, max_xp3);
            
            //DISPLAY HUDs
            SetHudTextParams(0.16, 0.80, 2.0, 100, 200, 255, 0);
            GetHudText(client, hudLevel1, 1, insert, tfclass, max_xp1);
            
            SetHudTextParams(0.16, 0.83, 2.0, 255, 200, 100, 0);
            GetHudText(client, hudLevel2, 2, insert, tfclass, max_xp2);
            
            SetHudTextParams(0.16, 0.86, 2.0, 255, 100, 200, 0);
            GetHudText(client, hudLevel3, 3, insert, tfclass, max_xp3);
            
            if (g_Client_Mission_S[client] > 0) {            
                g_Client_Mission_M[client] = g_Client_Mission_M[client] - 2;
                if (g_Client_Mission_M[client] < 0) g_Client_Mission_M[client] = 0;
                if (g_Client_Mission_M[client] <= 0 && g_Client_Mission_S[client] == 1) g_Client_Mission_S[client] = 2;
                SetHudTextParams(0.16, 0.10, 2.0, 255, 0, 0, 0);
                new String:Mission[512];
                new String:Class[512];
                Format(Mission, sizeof(Mission),var_mission[g_Client_Mission_C[client] * 3 + g_Client_Mission_I[client]-1]);
                Format(Class, sizeof(Class),var_classes[g_Client_Mission_C[client]]);
                ShowSyncHudText(client, hudMission, "%s Mission (%s)\nTarget: %N\n%s", Class, GetTimerString(g_Client_Mission_M[client]), g_Client_Mission_T[client], Mission);
            }
        }
    }
}

public Action:DrawHudTimer(Handle:hTimer, any:client) {
    DrawHud(client);
    levelHUD[client] = CreateTimer(2.0, DrawHudTimer, client);
}

GetHudText(client, hud, i, Handle:insert, tfclass, max_xp) {
    new String:Stars[128];
    new String:Exp[128];
    new String:Skillname[128];
    new String:Rankname[128];
    new level = GetArrayCell(insert,tfclass * 3 + i-1,0);
    strcopy(Stars, sizeof(Stars), "+");
    if (tfclass < 0) tfclass = 0;
    if (level >= 2) strcopy(Stars, sizeof(Stars), "++");
    if (level >= 3) strcopy(Stars, sizeof(Stars), "+++");
    if (level >= 4) strcopy(Stars, sizeof(Stars), "++++");
    if (level < GetConVarInt(cvar_level_max)) Format(Exp, sizeof(Exp), " (exp: %i/%i)",GetArrayCell(insert,tfclass * 3 + i-1,1), max_xp);
    if (GetConVarBool(cvar_show_skill_name)) Format(Skillname, sizeof(Skillname), "%s: ",var_skills[tfclass * 3 + i-1]);
    //LogMessage("%N) tfclass: %d, i: %d, level: %d, array: %d", client, tfclass, i, level, tfclass * 12 + (i-1) * 4 +  level-1);
    if (GetConVarBool(cvar_show_rank_name)) Format(Rankname, sizeof(Rankname), "%s ",var_ranks[tfclass * 12 + (i-1) * 4 +  level-1]);
    ShowSyncHudText(client, hud, "%s%s[%s]%s", Skillname, Rankname, Stars, Exp);
}

////////////////////////
//D A M A G E  D O N E//
////////////////////////
public Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetConVarInt(cvar_enable) && AllowLoad)
    {
        new damaged = GetClientOfUserId(GetEventInt(event, "userid"));
        new client = GetClientOfUserId(GetEventInt(event, "attacker"));
        new damage = GetEventInt(event, "damageamount");
        new weaponid = GetEventInt(event, "weaponid");
        new exp = 0;
        
        if (IsValidClient(client) && IsPlayerAlive(client) && (client != damaged)) {
        
            if (GetConVarBool(cvar_beta)) PrintToChatAll("Weaponid: %d", weaponid);
        
            // Soldier: Aim
            if (TF2_GetPlayerClass(client) == TFClass_Soldier && (weaponid == 22 || weaponid == 64)) {
                if (!(damage <= 30)) {
                    exp = (damage - 30) / 15;
                    //PrintToChatAll("Damage: %d, exp: %d", damage, exp);
                    if (exp >= 100) exp = 100;
                    
                    GiveExp(client, 0, 1, exp);
                }
            }
            // Soldier: Air
            if (TF2_GetPlayerClass(client) == TFClass_Soldier && (!(GetEntityFlags(client) & FL_ONGROUND)) && g_Rocket_Jump[client] == 1) {
                exp = damage / 4;
                if (exp >= 200) exp = 200;
                GiveExp(client, 0, 2, exp);
                
                if (g_Client_Mission_T[client] == damaged && g_Client_Mission_C[client] == 0 && g_Client_Mission_I[client] == 2 && (weaponid == 22 || weaponid == 64)) {
                    g_Mission_Counter[client] = g_Mission_Counter[client] + 1;
                    
                    if (g_Mission_Counter[client] >= 3) MissionComplete(client);
                }
            }
            
            // Soldier: Close Combat
            if (TF2_GetPlayerClass(client) == TFClass_Soldier) {
                new Float:vec1[3];
                new Float:vec2[3];
                GetClientAbsOrigin(client, vec1);
                GetClientAbsOrigin(damaged, vec2);
                new distance = GetVectorDistance(vec1, vec2);
                distance = distance - 1111588000;
                distance = distance/1000000;
                exp = (20-distance);
                exp = exp / 3;
                GiveExp(client, 0, 3, exp);
            }
            // Pyro: Distance Damager
            if (TF2_GetPlayerClass(client) == TFClass_Pyro  && (weaponid == 57 || weaponid == 15)) {
                new Float:vec1[3];
                new Float:vec2[3];
                GetClientAbsOrigin(client, vec1);
                GetClientAbsOrigin(damaged, vec2);
                new distance = GetVectorDistance(vec1, vec2);
                distance = distance - 1111588000;
                distance = distance/1000000;
                exp = (distance - 30);
                if (weaponid == 57 && exp > 0) exp = 1;
                 GiveExp(client, 1, 3, exp);
            }
            
            // Pyro: Ambush Academy
            if (TF2_GetPlayerClass(client) == TFClass_Pyro  && (weaponid == 4 || weaponid == 25)) {
                new boolean:g_crit = false;
                g_crit = GetEventBool(event, "crit");
                if (g_crit) {
                    if (weaponid == 4) exp = 15;
                    if (weaponid == 25) exp = 2;
                    GiveExp(client, 1, 2, exp);
                    if (g_Client_Mission_C[client] == 1 && g_Client_Mission_I[client] == 2 && g_Client_Mission_T[client] == damaged) {
                        MissionComplete(client);
                    }
                }
            }
            
            // Scout: Meatshot
            if (TF2_GetPlayerClass(client) == TFClass_Scout && weaponid == 16) {
                if(!(damage <= 20)) {
                    exp = (damage - 20) / 11;
                    if (exp >= 100) exp = 100;
                    
                    GiveExp(client, 2, 1, exp);
                    
                    if (g_Client_Mission_C[client] == 2 && g_Client_Mission_I[client] == 1 && g_Client_Mission_T[client] == damaged && damage >= 100) {
                        MissionComplete(client);
                    }
                }
            }
            
            // Scout: Support
            if (IsValidClient(damaged) && (TF2_GetPlayerClass(damaged) == TFClass_Sniper || TF2_GetPlayerClass(damaged) == TFClass_Spy || TF2_GetPlayerClass(damaged) == TFClass_Medic) && TF2_GetPlayerClass(client) == TFClass_Scout) {
                exp = damage / 7;
                
                GiveExp(client, 2, 2, exp);
            }
            
            // Scout: Air
            if (TF2_GetPlayerClass(client) == TFClass_Scout && (!(GetEntityFlags(client) & FL_ONGROUND))) {
                exp = damage / 8;
                if (exp >= 200) exp = 200;
                GiveExp(client, 2, 3, exp);
            }
            
            // Demoman: Melee
            if (TF2_GetPlayerClass(client) == TFClass_DemoMan && (weaponid == 3 || weaponid == 63)) {
                exp = damage / 20;
                if (exp >= 50) exp = 50;
                GiveExp(client, 3, 3, exp);
            }
            
            // Demoman: Splash
            if (TF2_GetPlayerClass(client) == TFClass_DemoMan) {
                if ((g_Demo_Splash[client] >= 1)) {
                    g_Demo_Splash[client] ++;
                    
                    g_Demo_Splash_Dmg[client] = g_Demo_Splash_Dmg[client] + damage;
                }
                if (!(g_Demo_Splash[client] > 0)) {
                    g_Demo_Splash[client] = 1;
                    g_Demo_Splash_Dmg[client] = damage;
                    g_Demo_Splash_Reset[client] = CreateTimer(0.4, ResetDemoSplash, client);
                }
            }
            
            // Sniper: Psycho
            if (TF2_GetPlayerClass(client) == TFClass_Sniper && IsValidClient(damaged) && ((GetEntData(damaged, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_SLOWED) || (GetEntData(damaged, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_TAUNTING) || (GetEntData(damaged, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_STUN) || (GetEntData(damaged, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_ONFIRE))) {
                exp = damage / 25;
                if (exp >= 5) exp = 5;
                GiveExp(client, 5, 3, exp);
            }
            
            // Sniper: Close Combat
            if (TF2_GetPlayerClass(client) == TFClass_Sniper) {
                new Float:vec1[3];
                new Float:vec2[3];
                GetClientAbsOrigin(client, vec1);
                GetClientAbsOrigin(damaged, vec2);
                new distance = GetVectorDistance(vec1, vec2);
                distance = distance - 1111588000;
                distance = distance/1000000;
                exp = (40-distance);
                exp = exp / 8;
                GiveExp(client, 5, 1, exp);
            }
            
            // Sniper: Efficiency Mission
            if (TF2_GetPlayerClass(client) == TFClass_Sniper  && (weaponid == 17 || weaponid == 60)) {
                new boolean:g_crit = false;
                g_crit = GetEventBool(event, "crit");
                if (g_crit) {
                    if (g_Client_Mission_C[client] == 5 && g_Client_Mission_I[client] == 2 && g_Client_Mission_T[client] == damaged) {
                        MissionComplete(client);
                    }
                }
            }
            
        }
    }
}

public Action:ResetDemoSplash(Handle:hTimer, any:client) {
    if (g_Demo_Splash[client] >= 2) {
        new exp = g_Demo_Splash_Dmg[client];
        exp = exp / 20;
        GiveExp(client, 3, 1, exp);
    }
    
    g_Demo_Splash[client] = 0;
    g_Demo_Splash_Dmg[client] = 0;
    g_Demo_Splash_Reset[client] = INVALID_HANDLE;
}

public Rocket_Jump(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_Rocket_Jump[client] = 1;
    GiveExp(client, 0, 2, 1);
}

public Rocket_Jump_Landed(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_Rocket_Jump[client] = 0;
}

public Object_Deflected(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new weaponid = GetEventInt(event, "weaponid");
    new exp = 0;
    
    if (TF2_GetPlayerClass(client) == TFClass_Pyro) {
        //PrintToChatAll("Weaponid: %d", weaponid);
        if (weaponid == 22) exp = 40;
        if (weaponid == 52) exp = 35;
        if (weaponid == 64) exp = 70;
        if (weaponid == 35) exp = 1;
        GiveExp(client, 1, 1, exp);
    }
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(cvar_enable) && AllowLoad) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        CheckClientEquip(client, -1, -1);
        
        new doit = GetRandomInt(1, GetConVarInt(cvar_missions)*GetClientNumber());
        new AllPlayers = GetClientCount(true);
        new myteam = GetClientTeam(client);
        new tfclass = GetClientClass(client);
        
        if (IsValidClient(client) && (!IsFakeClient(client)) && doit == 1 && AllPlayers >= 2 && myteam > 1 && g_Client_Mission_S[client] == 0 && tfclass >= 0 && GetConVarInt(cvar_missions) > 0 && round_start) {
            new target = GetRandomInt(1, AllPlayers);
            while ((!IsValidClient(target)) || GetClientTeam(target) == myteam || GetClientTeam(target) == 1) {
                target = GetRandomInt(1, AllPlayers);
            }
            
            g_Client_Mission_C[client] = tfclass;
            g_Client_Mission_I[client] = GetRandomInt(1,3);
            g_Client_Mission_T[client] = target;
            g_Client_Mission_S[client] = 0;
            if (tfclass >= 0) MissionMenu(client, target, tfclass);
        }
        
        for (new i = 1; i <= MaxClients; i++) {
            if (g_Client_Mission_S[i] >= 1 && g_Client_Mission_T[i] == client) {
                CreateSprite(client, i, SPR_VOICE_VMT);
            }
        }
    }
}

public Player_Team(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(cvar_enable) && AllowLoad) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        
        for (new i = 1; i <= MaxClients; i++) {
            if (g_Client_Mission_S[i] >= 1 && g_Client_Mission_T[i] == client && ((GetClientTeam(client) == GetClientTeam(i)) || GetClientTeam(client) == 1)) {
                MissionEnded(i);
            }
        }
    }
}


public point_captured(Handle:event, const String:name[], bool:noBroadcast) {
    if (GetConVarBool(cvar_enable) && AllowLoad) {
        decl String:cappers[MAXPLAYERS+1] = "";
        if (GetEventString(event,"cappers", cappers, MAXPLAYERS)>0) {
        
            new len = strlen(cappers);
            for(new i=0;i<len;i++) {
            
                new client  = cappers{i};
                new tfclass = GetClientClass(client);
                if (tfclass >= 0) GiveExp(client, tfclass, 1, 2);
                if (tfclass >= 0) GiveExp(client, tfclass, 2, 2);
                if (tfclass >= 0) GiveExp(client, tfclass, 3, 2);
            }
        }
    }
}

public Object_Destroyed(Handle:event, const String:name[], bool:noBroadcast) {
    if (GetConVarBool(cvar_enable) && AllowLoad) {
        new client = GetClientOfUserId(GetEventInt(event, "attacker"));
        new wasbuilding = GetEventBool(event, "was_building");
        new objid = GetEventInt(event, "objecttype");
        
        new tfclass = GetClientClass(client);
        
        if (tfclass == 3) {
            new exp = 20;
            if (objid == 0) exp = 12;
            if (objid == 1) exp = 7;
            if (objid == 2) exp = 5;
            if (wasbuilding) exp = exp / 4;
            GiveExp(client, 3, 2, exp);
        }
    }
}

Client_Healed(client) {
    new healing = 0;
    new diff = 0;
    new tfclass = GetClientClass(client);
    healing = GetEntProp(client, Prop_Send, "m_iHealPoints");
    
    if (healing > g_Client_Heal[client]) {
        diff = healing - g_Client_Heal[client];
        g_Client_Heal[client] = healing;
        if (tfclass == 4) {
            diff = diff / 15;
            if (diff >= 5) diff = 5;
            GiveExp(client, 4, 2, diff);
        }
    }
}

public Player_Teleported(Handle:event, const String:name[], bool:noBroadcast) {
    if (GetConVarBool(cvar_enable) && AllowLoad) {
        new user = GetClientOfUserId(GetEventInt(event, "userid"));
        new builder = GetClientOfUserId(GetEventInt(event, "builderid"));
        
        new tfclass = GetClientClass(builder);
        
        if (tfclass == 4 && (user != builder)) {
            new exp = 4;
            GiveExp(builder, 4, 2, exp);
        }
    }
}

public Player_Shield_Blocked(Handle:event, const String:name[], bool:noBroadcast) {
    if (GetConVarBool(cvar_enable) && AllowLoad) {
        new client = GetEventInt(event, "blocker_entindex");
        
        new tfclass = GetClientClass(client);
        
        if (tfclass == 5) {
            new exp = 15;
            GiveExp(client, 5, 1, exp);
        }
    }
}

// MISSIONS

public Action:MissionMenu(client, target, tfclass) {
    new mission = g_Client_Mission_C[client] * 3 + g_Client_Mission_I[client]-1;
    new String:MissionInfo[512];
    new String:MissionSkill[128];
    Format(MissionInfo, sizeof(MissionInfo), var_mission[mission]);
    Format(MissionSkill, sizeof(MissionSkill), var_skills[mission]);
    
    if (!(StrEqual(MissionInfo, "?"))) {
    
	new Handle:menu = CreateMenu(MissionMenuHandler);
        SetMenuTitle(menu, "A new mission is available as %s!\nTarget: %N\nMission: %s\nReward: %d EXP in %s\nTime Limit: 2:00 minutes\n ", var_classes[g_Client_Mission_C[client]], target, MissionInfo, 50, MissionSkill);
        
        AddMenuItem(menu, "option1", "Accept");
        AddMenuItem(menu, "option2", "Decline");
        
        SetMenuExitButton(menu, false);
        DisplayMenu(menu, client, 15);
    }

	return Plugin_Handled;
}

public MissionMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //ACCEPT
            {
                if (g_Client_Mission_S[client] == 0) {
                    new mission = g_Client_Mission_C[client] * 3 + g_Client_Mission_I[client]-1;
                    new String:MissionInfo[512];
                    Format(MissionInfo, sizeof(MissionInfo), var_mission[mission]);
                    if (!(StrEqual(MissionInfo, "?"))) {
                        CPrintToChatAllEx(client, "{teamcolor}%N{default} has been sent on a mission against {green}%N{default}", client, g_Client_Mission_T[client]);
                        g_Client_Mission_S[client] = 1;
                        g_Client_Mission_M[client] = 120;
                        EmitSoundToClient(client, SOUND_MISSION);
                        new String:Announcement[512];
                        Format(Announcement, sizeof(Announcement), var_announcer_kill[GetRandomInt(0, sizeof(var_announcer_kill)-1)]);
                        EmitSoundToAll(Announcement);
                        g_Mission_Counter[client] = 0;
                        CreateSprite(g_Client_Mission_T[client], client, SPR_VOICE_VMT);
                    }
                }
			}
        }
    }
}

MissionEnded(client) {
    DestroySprite(g_Client_Mission_T[client]);
    g_Client_Mission_C[client] = 0;
    g_Client_Mission_I[client] = 0;
    g_Client_Mission_S[client] = 0;
    g_Client_Mission_M[client] = 0;
    g_Client_Mission_T[client] = 0;
    g_Mission_Counter[client] = 0;
    if (IsValidClient(client)) {
        PrintToChat(client, "You failed your mission...");
        EmitSoundToClient(client, SOUND_MISSION_FAILED);
    }
}

MissionComplete(client) {
    if (g_Client_Mission_S[client] > 0) {
        new mission = g_Client_Mission_C[client] * 3 + g_Client_Mission_I[client]-1;
        new String:MissionSkill[512];
        Format(MissionSkill, sizeof(MissionSkill), var_skills[mission]);
        //DestroySprite(g_Client_Mission_T[client]);
        g_Client_Mission_S[client] = 0;
        g_Client_Mission_M[client] = 0;
        g_Client_Mission_T[client] = 0;
        
        CPrintToChatAllEx(client, "{teamcolor}%N{default} completed his mission in {green}%s{default} and earned {olive}50 EXP{default}!", client, MissionSkill);
        // mission = tfclass * 3 + (i-1)
        // mission - (i-1) / 3 = tfclass
        GiveExp(client, g_Client_Mission_C[client], g_Client_Mission_I[client], 50);
        g_Client_Mission_I[client] = 0;
        g_Client_Mission_C[client] = 0;
        new String:Announcement[512];
        Format(Announcement, sizeof(Announcement), var_announcer_gj[GetRandomInt(0, sizeof(var_announcer_gj)-1)]);
        EmitSoundToAll(Announcement);
    }
}

public Action:FreezeCam(Handle:hTimer, any:client) {
    g_Freezecam[client] = INVALID_HANDLE;
    
    if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier && g_Client_Mission_C[client] == 0 && g_Client_Mission_I[client] == 1 && (GetEntData(client, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_TAUNTING)) {
        MissionComplete(client);
    }
}

////////////////////////////
//P L A Y E R  K I L L E D//
////////////////////////////
public Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
    if(GetConVarInt(cvar_enable) && AllowLoad) {
        new client = GetClientOfUserId(GetEventInt(event, "attacker"));
        new killed = GetClientOfUserId(GetEventInt(event, "userid"));
        new String:Weapon[512];
        GetEventString(event, "weapon", Weapon, sizeof(Weapon));
        
        g_Rocket_Jump[killed] = 0;
        g_Demo_Splash[killed] = 0;
        g_Demo_Splash_Dmg[killed] = 0;
        
        DestroySprite(killed);
        
        // EXP
        // Engineer: Sentry
        if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer && (StrEqual(Weapon, "obj_sentrygun") || StrEqual(Weapon, "obj_sentrygun2") || StrEqual(Weapon, "obj_sentrygun3"))) {
            GiveExp(client, 4, 1, 5);
        }
        
        // Engineer: Melee
        if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer && StrEqual(Weapon, "wrench")) {
            GiveExp(client, 4, 3, 10);
        }
        
        // Sniper: Efficient
        if (GetConVarBool(cvar_beta)) PrintToChatAll("Customkill: %d, weapon: %s", GetEventInt(event, "customkill"), Weapon);
        if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Sniper && (StrEqual(Weapon, "sniperrifle") || StrEqual(Weapon, "tf_projectile_arrow") || StrEqual(Weapon, "compound_bow")  || StrEqual(Weapon, "huntsman")) && GetEventInt(event, "customkill") == 1) {
            GiveExp(client, 5, 2, 5);
        }
        
        // MISSIONS
        if (g_Client_Mission_S[killed] >= 2) MissionEnded(killed);
            if (IsValidClient(client) && IsValidClient(killed)) {
            
            if (TF2_GetPlayerClass(client) == TFClass_Soldier && g_Client_Mission_C[client] == 0 && g_Client_Mission_I[client] == 1 && g_Client_Mission_T[client] == killed && StrEqual(Weapon, "tf_projectile_rocket")) g_Freezecam[client] = CreateTimer(2.0, FreezeCam, client);
            
            // Soldier: Melee
            if (TF2_GetPlayerClass(client) == TFClass_Soldier && g_Client_Mission_C[client] == 0 && g_Client_Mission_I[client] == 3 && g_Client_Mission_T[client] == killed && (StrEqual(Weapon, "shovel") || StrEqual(Weapon, "pickaxe"))) {
                MissionComplete(client);
            }
            
            // Scout: Air
            if (TF2_GetPlayerClass(client) == TFClass_Scout && g_Client_Mission_C[client] == 2 && g_Client_Mission_I[client] == 3 && g_Client_Mission_T[client] == killed && (!(GetEntityFlags(client) & FL_ONGROUND))) {
                MissionComplete(client);
            }
            
            // Pyro: Distance Damager
            if (TF2_GetPlayerClass(client) == TFClass_Pyro  && g_Client_Mission_C[client] == 1 && g_Client_Mission_I[client] == 2) {
                new Float:vec1[3];
                new Float:vec2[3];
                GetClientAbsOrigin(client, vec1);
                GetClientAbsOrigin(killed, vec2);
                new distance = GetVectorDistance(vec1, vec2);
                distance = distance - 1111588000;
                distance = distance/1000000;
                if (distance >= 50) MissionComplete(client);
            }
            
            // Demoman: Melee
            if (TF2_GetPlayerClass(client) == TFClass_DemoMan && g_Client_Mission_C[client] == 3 && g_Client_Mission_I[client] == 3 && g_Client_Mission_T[client] == killed && (StrEqual(Weapon, "bottle") || StrEqual(Weapon, "sword"))) {
                MissionComplete(client);
            }
            
            // Engineer: Melee
            if (TF2_GetPlayerClass(client) == TFClass_Engineer && g_Client_Mission_C[client] == 4 && g_Client_Mission_I[client] == 3 && g_Client_Mission_T[client] == killed && StrEqual(Weapon, "wrench")) {
                MissionComplete(client);
            }
        }
    }
    
}

///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client) {
    if (GetConVarBool(cvar_enable) && AllowLoad) {
        for (new i = 1; i <= MaxClients; i++) {
            if (g_Client_Mission_S[i] >= 1 && g_Client_Mission_T[i] == client) {
                MissionEnded(i);
            }
        }

        if (g_LIST_USERS[client] != INVALID_HANDLE) {
            CloseHandle(g_LIST_USERS[client]);
            g_LIST_USERS[client] = INVALID_HANDLE;
        }
        CloseHandle(levelHUD[client]);
    }
}

///////////////
//S T O C K S//
///////////////
stock GiveExp(client, tfclass, i, xp) {
    new tfclass2 = GetClientClass(client);
    if (xp < 0) xp = 0;
    if (round_start && xp > 0 && tfclass2 == tfclass) {
        new insert = g_LIST_USERS[client];
        new oldlevel = GetArrayCell(insert,tfclass * 3 + i-1,0);
        if (oldlevel < GetConVarInt(cvar_level_max)) {
            new oldxp = GetArrayCell(insert,tfclass * 3 + i-1,1);
            new pos = GetConVarInt(cvar_show_rank_name) + GetConVarInt(cvar_show_skill_name);
            SetArrayCell(insert,tfclass * 3 + i-1,oldxp + xp,1);
            SetHudTextParams(0.36 + pos * 0.10, 0.80 + (i-1) * 0.03, 2.0, 255, 0, 0, 150);
            new hud;
            if (i == 1) hud = hudXp1;
            if (i == 2) hud = hudXp2;
            if (i == 3) hud = hudXp3;
            ShowSyncHudText(client, hud, "+%d EXP", xp);
            //DrawHud(client);
            SubmitSql(client, tfclass,i, 2, oldxp + xp);
        }
    }
}


stock LevelUp(client, tfclass, i, max_xp) {
    new insert = g_LIST_USERS[client];
    new oldlevel = GetArrayCell(insert,tfclass * 3 + i-1,0);
    new oldxp = GetArrayCell(insert,tfclass * 3 + i-1,1);
    new newxp = 0;
    new String:tfclass_txt[128];
    
    // Get old total
    new oldtotal1 = GetArrayCell(insert,tfclass * 3 + 0,0) -1;
    new oldtotal2 = GetArrayCell(insert,tfclass * 3 + 1,0) -1;
    new oldtotal3 = GetArrayCell(insert,tfclass * 3 + 2,0) -1;
    new oldtotal = oldtotal1 + oldtotal2 + oldtotal3;
    
    SetArrayCell(insert,tfclass * 3 + i-1,oldlevel + 1,0);
    
    if ((oldlevel+1) < GetConVarInt(cvar_level_max)) {
        newxp = oldxp - max_xp;
    }
    
    SetArrayCell(insert,tfclass * 3 + i-1,newxp,1);
    
    strcopy(tfclass_txt, sizeof(tfclass_txt), var_classes[tfclass]);
    
    new String:Stars[128];
    strcopy(Stars, sizeof(Stars), "+");
    if (oldlevel >= 2) strcopy(Stars, sizeof(Stars), "++");
    if (oldlevel >= 3) strcopy(Stars, sizeof(Stars), "+++");
    
    //SetHudTextParams(0.6, 0.87 + (i-1)*0.03, 5.0, 100, 255, 100, 150, 2);    
    //ShowSyncHudText(client, hudLevelUp, "LEVEL UP!");
    //PrintToChatAll("Client: %N, class: %d, i: %d, level: %d, total: %d", client, tfclass, i, oldlevel, tfclass * 12 + (i-1) * 4 +  oldlevel-1);
    if (!IsFakeClient(client)) CPrintToChatAllEx(client, "{teamcolor}%N{default} went from {green}%s {olive}[%s]{default} to {green}%s {olive}[%s+]{default} as {green}%s", client, var_ranks[tfclass * 12 + (i-1) * 4 +  oldlevel-1], Stars, var_ranks[tfclass * 12 + (i-1) * 4 +  oldlevel], Stars, tfclass_txt);
    EmitSoundToClient(client, SOUND_LEVELUP);
    AttachAchievementParticle(client);
    SubmitSql(client, tfclass,i, 2, newxp);
    SubmitSql(client, tfclass,i, 1, oldlevel + 1);
    CheckClientEquip(client, oldtotal, tfclass);
}

stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

GetClientClass(client) {
    new tfclass = -1;
    // GET CLASS
    if (TF2_GetPlayerClass(client) == TFClass_Soldier) tfclass = 0;
    if (TF2_GetPlayerClass(client) == TFClass_Pyro) tfclass = 1;
    if (TF2_GetPlayerClass(client) == TFClass_Scout) tfclass = 2;
    if (TF2_GetPlayerClass(client) == TFClass_DemoMan) tfclass = 3;
    if (TF2_GetPlayerClass(client) == TFClass_Engineer) tfclass = 4;
    if (TF2_GetPlayerClass(client) == TFClass_Sniper) tfclass = 5;
    
    return tfclass;
}

GetClientPref(client) {
    new Handle:insert = CreateArray(2);
    new index = 0;
    new level = 1;
    new testlevel = 0;
    new xp = 0;
    new String:strSteamId[128];
    GetClientAuthString		(client, strSteamId, sizeof(strSteamId));
    
    new Handle:		strHQuery;
    decl String:	strQuery[255];
    decl String:    temp[255];
    Format			(strQuery, sizeof(strQuery), "SELECT * FROM `mw_skills` WHERE `steamid` = '%s'", strSteamId);
    
    new Handle:strData = CreateTrie();
    
    if (IsValidClient(client) && !IsFakeClient(client) && (!(GetConVarBool(cvar_nosubmit)))) {
        strHQuery 			= ConnectionBD(strQuery);
        while (SQL_FetchRow(strHQuery)) {
            SQL_FetchString(strHQuery, 0,temp,sizeof(temp));
            SetTrieValue	(strData, temp, SQL_FetchInt(strHQuery, 2));
        }
        CloseHandle			(strHQuery);
    }
    
    for (new c=0;c<9;c++) {
        for (new s=1;s<=3;s++) {
            testlevel = 0;
            level = 1;
            xp = 0;
            
            Format(temp, sizeof(temp),  "%s_%d_%d_%d", strSteamId, c, s, 1);
            GetTrieValue(strData, temp, testlevel);
            if (testlevel < 1) testlevel = 1;
            level = testlevel;
            Format(temp, sizeof(temp),  "%s_%d_%d_%d", strSteamId, c, s, 2);
            GetTrieValue(strData, temp, xp);
            
            index = PushArrayCell(insert, level);
            SetArrayCell(insert, index, xp, 1);
        }
    }
    
    g_LIST_USERS[client] = insert;
    CloseHandle(strData);
}

CheckClientEquip(client, oldtotal, tfclass) {
    if (GetConVarBool(cvar_equip)) {
        ServerCommand("tf_equipment_remove \"%N\" %d", client, 1);
        ServerCommand("tf_equipment_remove \"%N\" %d", client, 2);
        ServerCommand("tf_equipment_remove \"%N\" %d", client, 3);
        
        new insert = g_LIST_USERS[client];
        
        for (new c=0;c<9;c++) {
            new level1 = GetArrayCell(insert,c * 3 + 0,0) - 1;
            new level2 = GetArrayCell(insert,c * 3 + 1,0) - 1;
            new level3 = GetArrayCell(insert,c * 3 + 2,0) - 1;
            
            new level = level1 + level2 + level3;
            
            for (new i=0;i<g_ItemRewardCount;i++) {
                if (c == g_ItemRewardClass[i] && level >= g_ItemRewardLevel[i] && (g_ItemRewardExpire[i] == -1 || level < g_ItemRewardExpire[i])) {
                    ServerCommand("tf_equipment_equip \"%N\" \"%s\"", client, g_ItemRewardName[i]);
                    if (oldtotal >= 0 && tfclass >= 0 && c == tfclass && oldtotal < g_ItemRewardLevel[i] && !IsFakeClient(client)) CPrintToChatAllEx(client, "{teamcolor}%N{default} has found: {green}%s", client, g_ItemRewardName[i]);
                }
            }
        }
    }
}

public Action:Cmd_BlockTriggers(iClient, iArgs)
{
    if (iClient < 1 || iClient > MaxClients) return Plugin_Continue;
    if (iArgs < 1) return Plugin_Continue;
    
    // Retrieve the first argument and check it's a valid trigger
    decl String:strArgument[64]; GetCmdArg(1, strArgument, sizeof(strArgument));
    if (StrEqual(strArgument, "!tf_equipment", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!equip", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!em", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!hats", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!hats", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!skills", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!stats", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!skill", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!help", true)) return Plugin_Handled;
    
    // If no valid argument found, pass
    return Plugin_Continue;
}

public Action:Cmd_Menu(client, iArgs)
{
    // Not allowed if not ingame.
    if (client == 0) { ReplyToCommand(client, "[TF2] Command is in-game only."); return Plugin_Handled; }
    
    
    new tfclass = GetClientClass(client);
    
    if (tfclass == -1) return Plugin_Handled;
    
    // Display menu.
    new Handle:hPanel = CreatePanel();
    
    // Add the different options
    new String:strItem[256];
    Format(strItem, sizeof(strItem), "%s", var_skills[tfclass * 3 + 1-1]);
    DrawPanelItem(hPanel, strItem);
    Format(strItem, sizeof(strItem), "%s", var_desc[tfclass * 3 + 1-1]);
    DrawPanelText(hPanel, strItem);
    DrawPanelText(hPanel, "\n");
    Format(strItem, sizeof(strItem), "%s", var_skills[tfclass * 3 + 2-1]);
    DrawPanelItem(hPanel, strItem);
    Format(strItem, sizeof(strItem), "%s", var_desc[tfclass * 3 + 2-1]);
    DrawPanelText(hPanel, strItem);
    DrawPanelText(hPanel, "\n");
    Format(strItem, sizeof(strItem), "%s", var_skills[tfclass * 3 + 3-1]);
    DrawPanelItem(hPanel, strItem);
    Format(strItem, sizeof(strItem), "%s", var_desc[tfclass * 3 + 3-1]);
    DrawPanelText(hPanel, strItem);
    Format(strItem, sizeof(strItem), " \n%s", ItemsFound(client, tfclass));
    DrawPanelText(hPanel, strItem);
    
    // Setup title
    Format(strItem, sizeof(strItem), "%s", var_classes[tfclass]);
    //SetMenuTitle(hMenu, strItem);
    SendPanelToClient(hPanel, client, Menu_Manager, 30);
    CloseHandle(hPanel);
    
    return Plugin_Handled;
}

ItemsFound(client, tfclass) {
    new output[512];
    new name[128];
    new insert = g_LIST_USERS[client];
    
    new level1 = GetArrayCell(insert,tfclass * 3 + 0,0) - 1;
    new level2 = GetArrayCell(insert,tfclass * 3 + 1,0) - 1;
    new level3 = GetArrayCell(insert,tfclass * 3 + 2,0) - 1;
    
    new level = level1 + level2 + level3;
    
    Format(output, sizeof(output), "Items Found:");
    
    for (new i=0;i<g_ItemRewardCount;i++) {
        if (tfclass == g_ItemRewardClass[i]) {
            Format(name, sizeof(name), "???");
            if (level >= g_ItemRewardLevel[i]) {
                Format(name, sizeof(name), "--> %s",g_ItemRewardName[i]);
            }
            Format(output, sizeof(output), "%s\n%s", output, name);
        }
    }
    return output;
}

public Menu_Manager(Handle:hPanel, MenuAction:maState, iParam1, iParam2) {
}


// ACHIEVEMENT EFFECT
AttachAchievementParticle(client)
{
    new strIParticle = CreateEntityByName("info_particle_system");
    
    new String:strName[128];
    if (IsValidEdict(strIParticle))
    {
        new Float:strflPos[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", strflPos);
        TeleportEntity(strIParticle, strflPos, NULL_VECTOR, NULL_VECTOR);
        
        Format(strName, sizeof(strName), "target%i", client);
        DispatchKeyValue(client, "targetname", strName);
        
        DispatchKeyValue(strIParticle, "targetname", "tf2particle");
        DispatchKeyValue(strIParticle, "parentname", strName);
        DispatchKeyValue(strIParticle, "effect_name", ACHIEVEMENT_PARTICLE);
        DispatchSpawn(strIParticle);
        SetVariantString(strName);
        AcceptEntityInput(strIParticle, "SetParent", strIParticle, strIParticle, 0);
        SetVariantString("head");
        AcceptEntityInput(strIParticle, "SetParentAttachment", strIParticle, strIParticle, 0);
        ActivateEntity(strIParticle);
        AcceptEntityInput(strIParticle, "start");
        
        CreateTimer(5.0, Timer_DeleteParticles, strIParticle);
    }
}

public Action:Timer_DeleteParticles(Handle:argTimer, any:argIParticle)
{
    if (IsValidEntity(argIParticle))
    {
        new String:strClassname[256];
        GetEdictClassname(argIParticle, strClassname, sizeof(strClassname));
        
        if (StrEqual(strClassname, "info_particle_system", false))
        {
            RemoveEdict(argIParticle);
        }
    }
}

public Action:Cmd_Test(client, iArgs) {
}

ParseAwardList() {
    new String:strLocation[256];
    new String:strLine[256];
    new String:strClass[256];
    new Handle:kvItemList = CreateKeyValues("TF2_ClassExperience");
    BuildPath(Path_SM, strLocation, 256, "configs/TF2_ClassExperienceRewards.cfg");
    FileToKeyValues(kvItemList, strLocation);
    
    
    if (!KvGotoFirstSubKey(kvItemList)) { SetFailState("Error, can't read file containing the item list : %s", strLocation); return; }
    g_ItemRewardCount = 0;
    
    //LogMessage("Parsing item list {");
    
    // Iterate through all keys.
    do {
        KvGetSectionName    (kvItemList,        strClass,    sizeof(strClass));
        KvGotoFirstSubKey   (kvItemList);
        do {
            KvGetSectionName    (kvItemList,        strLine,    sizeof(strLine));   g_ItemRewardLevel[g_ItemRewardCount]   =    StringToInt(strLine);
            KvGetString         (kvItemList,        "model",    g_ItemRewardName[g_ItemRewardCount],    256);
            g_ItemRewardExpire[g_ItemRewardCount] = KvGetNum(kvItemList, "expire", -1);
            g_ItemRewardClass[g_ItemRewardCount] = StringToInt(strClass);
            
            //LogMessage("    Found item -> \"%s\"", g_ItemRewardName[g_ItemRewardCount]);
            //LogMessage("        - Level : %i", g_ItemRewardLevel[g_ItemRewardCount]);
            //LogMessage("        - Class : %i", g_ItemRewardClass[g_ItemRewardCount]);
            
            // Go to next.
            g_ItemRewardCount++;
        } while (KvGotoNextKey(kvItemList));
        KvGoBack(kvItemList);
    } while (KvGotoNextKey(kvItemList));
    
    CloseHandle(kvItemList);    
    //LogMessage("}");
}

//// DATABASE STUFF
public OnConfigsExecuted() {
    PrecacheSound(SOUND_LEVELUP, true);
    
    precacheSound(SOUND_MISSION_FAILED);
    precacheSound(SOUND_MISSION);
    
    for (new i = 0; i < sizeof(var_announcer_kill); i++) {
        PrecacheSound(var_announcer_kill[i], true);
    }
    for (new i = 0; i < sizeof(var_announcer_gj); i++) {
        PrecacheSound(var_announcer_gj[i], true);
    }

    if (!(GetConVarBool(cvar_nosubmit))) {
        new String:strDB[128];
        GetConVarString		(g_CVDB, strDB, sizeof(strDB));
        if (SQL_CheckConfig(strDB))
        {
            SQL_TConnect	(cDatabaseConnect, strDB);
        }
        else
        {
            LogError		("Unable to open %s: No such database configuration.", strDB);
            g_BCONNECTED 	= false;
        }
    }
}

public cDatabaseConnect(Handle:arg_hOwner, Handle:argHQuery, const String:argsError[], any:argData) 
{
	new String:strDB[128];
	GetConVarString		(g_CVDB, strDB, sizeof(strDB));
	if (argHQuery == INVALID_HANDLE)
	{
		LogError("Unable to connect to %s: %s", strDB, argsError);
		g_BCONNECTED = false;
	}
	else
	{
		if (!SQL_FastQuery(argHQuery, "SET NAMES 'utf8'"))
		{
			LogError("Unable to change to utf8 mode.");
			g_BCONNECTED = false;
		}
		else
		{
			g_HDATABASE = argHQuery;
			g_BCONNECTED = true;
		}
	}
}

precacheSound(String:var[])
{
    new String:buffer[512];
    PrecacheSound(var, true);
    Format(buffer, sizeof(buffer), "sound/%s", var);
    AddFileToDownloadsTable(buffer);
}

SubmitSql(client, tfclass,skill, type, value) {
    if ((!(GetConVarBool(cvar_nosubmit))) && IsValidClient(client) && !IsFakeClient(client) && AllowLoad) {
        new String:strSteamId[128];
        new String:strId[512];
        new String:strQuery[512];
        GetClientAuthString		(client, strSteamId, sizeof(strSteamId));
        Format                  (strId, sizeof(strId),"%s_%d_%d_%d", strSteamId, tfclass, skill, type);
        Format                  (strQuery, sizeof(strQuery), "INSERT INTO `mw_skills` (`id`, `steamid`, `value`) VALUES ('%s', '%s', '%d') ON DUPLICATE KEY UPDATE `value` = '%d'", strId, strSteamId, value, value);
        SQL_TQuery              (g_HDATABASE, EmptyCallback, strQuery);
    }
}

// Empty callback
public EmptyCallback(Handle:argOwner, Handle:argHndl, const String:argError[], any:argData)
{
    if (argHndl == INVALID_HANDLE)
    {
        LogError("Query Error: %s",argError);
    }
}

public bool:IsDatabaseClosed()
{
	return !g_BCONNECTED;
}

Handle:ConnectionBD(const String:argQuery[])
{
    if (!(GetConVarBool(cvar_nosubmit))) {
        // This forces a reconnect on each strQuery. Not used but could come in handy.
        new Handle:strDb;
        new String:strDB[128];
        new Handle:strHQuery;
        decl String:strError[255];
        GetConVarString			(g_CVDB, strDB, sizeof(strDB));
        strDb = SQL_Connect		(strDB, true, strError, sizeof(strError));
        if (strDb == INVALID_HANDLE)
        {
            LogError			("Could not connect to database \"%s\": %s", strDB, strError);
            return 				INVALID_HANDLE;
        }
        if ((strHQuery = SQL_Query(strDb, argQuery)) == INVALID_HANDLE)
        {
            SQL_GetError		(strDb, strError, sizeof(strError));
            LogError			("'Count strQuery' failed: %s", argQuery);
            LogError			("Query error: %s", strError);
            return 				INVALID_HANDLE;
        }
        CloseHandle				(strDb);
        return 					strHQuery;
	}
}

Float:GetTimerString(time) {
    new String:survivalStringS[64];
    new String:survivalStringM[64];
    new Float:localtime = (time * 1.0);
    new minutetimer = RoundToFloor(localtime/60.0);
    new secondtimer = RoundToFloor(localtime - minutetimer*60.0);
    new String:addon[4];
    addon = "";
    if (secondtimer < 10) addon = "0";
    IntToString(secondtimer, survivalStringS, sizeof(survivalStringS));
    IntToString(minutetimer, survivalStringM, sizeof(survivalStringM));
    decl String:yTempString[512];
    yTempString = "";
    if (time > 0) Format(yTempString, sizeof(yTempString), "%s:%s%s",survivalStringM,addon,survivalStringS);
    if (time <= 0) Format(yTempString, sizeof(yTempString), "Last Chance!");
    
    return yTempString;
}

public OnEntityCreated(entity, const String:classname[]) {
	if (StrEqual(classname, "env_sprite")) {
		SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);
    }
}

public Hook_OnEntitySpawn(entity) {
	decl String:parentname[32];
	GetEntPropString(entity, Prop_Data, "m_iParent", parentname, sizeof(parentname));
	if (StrContains(parentname, "track") != -1)	{
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public Action:Hook_SetTransmit(entity, client) {
	if (!(g_Target_Particles[client] == entity))
		return Plugin_Handled;
	return Plugin_Continue;
}

stock CreateSprite(client, viewer, String:sprite[]) {
    if (GetConVarBool(cvar_sprite) && IsValidClient(client) && IsPlayerAlive(client) && (!(GetEntData(client, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_DISGUISED)) && (!(GetEntData(client, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_CLOAKED)) && (!(g_Target_Particles[viewer] > 0))) {
        new String:szTarget[16]; 
        Format(szTarget, sizeof(szTarget), "track%i", client);
        DispatchKeyValue(client, "targetname", szTarget);

        new Float:vOrigin[3];
        GetClientAbsOrigin(client, vOrigin);
        
        vOrigin[2] += 40;
        new ent = CreateEntityByName("env_sprite");
        if (ent)
        {
            DispatchKeyValue(ent, "model", sprite);
            DispatchKeyValue(ent, "classname", "env_sprite");
            DispatchKeyValue(ent, "spawnflags", "1");
            DispatchKeyValue(ent, "scale", "1.0");
            DispatchKeyValue(ent, "rendermode", "1");
            DispatchKeyValue(ent, "rendercolor", "255 255 255");
            DispatchKeyValue(ent, "parentname", szTarget);
            DispatchSpawn(ent);
            
            TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);
            
            SetSpriteParent(ent, szTarget);
            g_Target_Particles[viewer] = ent;
        }
    }
}

stock SetSpriteParent(ent, String:szTargetName[]) {
	SetVariantString(szTargetName);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	SetVariantString("head");
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
}

stock DestroySprite(client) {
    if (IsValidClient(client) && GetConVarBool(cvar_sprite)) {
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && g_Client_Mission_T[i] == client && IsValidEntity(g_Target_Particles[i])) {
                new ent = g_Target_Particles[i];
                AcceptEntityInput(ent, "kill");
                g_Target_Particles[i] = 0;
            }
        }
    }
}

GetClientNumber() {
    new number = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && (!(IsFakeClient(i)))) {
            number = number + 1;
        }
    }
    return number;
}