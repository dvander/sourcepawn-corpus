#pragma semicolon 1

// Definitions
#define PLUGIN_VERSION "0.32d"
#define ACHIEVEMENT_SOUND "misc/achievement_earned.wav"
#define ACHIEVEMENT_PARTICLE "Achieved"

// Misc Definitions
#define DF_CRITS        1048576    //crits = DAMAGE_ACID
#define DF_CRITS_BUFFBANNER        (1<<16)    //16
#define DF_CRITS_JARATE            (1<<22)    //4194304 

// Handles
new Handle:g_Achievements_Server; // Array containing all achievement information from GET. Contains: id, name, description, triggers, blocks
new Handle:g_Blocks_Server; // Array containing all block information from GET. Contains: id, event, target, triggers, requirements
new Handle:g_Achievements_User; // Array containing all achievement information to be sent to POST. Contains: id, steamid, triggers, complete
new Handle:g_Blocks_User; // Array containing all block information to be sent to POST. Contains: id, steamid, triggers, complete

// Strings
new String:TempInputString[512];

// Ints
new g_Gamemode = 0;
new Req_Capture_Count = 0;
new TempInputCrit = 0;

// Bools
new Req_Crafted = false;

// Arrays
new g_ClientConditions[MAXPLAYERS+1];
new g_motd[MAXPLAYERS+1] = 0;

// Handles
new Handle:cvar_achinfo;
new Handle:cvar_bot;
new Handle:cvar_debug;
new Handle:cvar_url;
new Handle:cvar_skin;
//(THRAKA)
new Handle:g_hForwardClientGainAch;

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#include mw_achievements/misc.inc
#include mw_achievements/sql.inc
#include mw_achievements/webinterface.inc
#include mw_achievements/events.inc
#include mw_achievements/requirement.inc

#include mw_achievements/events/common.inc
#include mw_achievements/events/tf2/common.inc
#include mw_achievements/events/l4d2/common.inc


public Plugin:myinfo = {
    name = "MechaWare Custom Achievements",
    author = "Mecha the Slag",
    description = "Custom Achievements in any Source game!",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    g_Achievements_Server = CreateArray();
    g_Achievements_User = CreateArray();
    g_Blocks_Server = CreateArray();
    g_Blocks_User = CreateArray();

    GetAchievementInfo();
    ConnectDB_Post();
    
    RegAdminCmd("mc_refresh", Command_Refresh, ADMFLAG_GENERIC, "Refreshes Achievement Info");
    CreateConVar("mc_version", PLUGIN_VERSION, "Version of the plugin");
    cvar_achinfo = CreateConVar("mc_info", "1", "Display achievement description on unlock?");
    cvar_bot = CreateConVar("mc_bot", "0", "Allow bots to earn achievements? (should always be 0)");
    cvar_debug = CreateConVar("mc_debug", "0", "Print debugging");
    cvar_url = CreateConVar("mc_url", "http://mechaware.net/tf2/achievements/index.php", "Path to the web interface");
    cvar_skin = CreateConVar("mc_skin", "", "Name of a skin to use for the web interface (if none, teamfortress)");
    
    // G A M E  C H E C K //
    decl String:game[32];
    GetGameFolderName(game, sizeof(game));
    g_Gamemode = 0;
    if(StrEqual(game, "tf")) g_Gamemode = 1;
    if(StrEqual(game, "left4dead2")) g_Gamemode = 2;
    
    // Webinterface
    RegConsoleCmd("say", Show_Web);
    
    //LogMessage("Gamemode: %s (%d)", game, g_Gamemode);
    // Hooks
    HookEvent("player_death", Player_Death);
    HookEvent("player_spawn", Player_Spawn);
    RegConsoleCmd("say", Player_Chat);
    RegConsoleCmd("say_team", Player_Chat);
    HookEvent("break_breakable", Break_Breakable);
    
    if (g_Gamemode == 1) { // TF2 Events
        HookEvent("teamplay_point_captured", Point_Capture);
        HookEvent("deploy_buff_banner", Deploy_Buff_Banner);
        HookEvent("player_mvp", Player_Mvp);
        HookEvent("player_sapped_object", Player_Sapped_Object);
        HookEvent("player_healedbymedic", Player_HealedByMedic);
        HookEvent("player_chargedeployed", Player_Chargedeployed);
        HookEvent("item_found", Item_Found);
    }
    if (g_Gamemode == 2) { // L4D2 Events
        HookEvent("pills_used", Pills_Used);
        HookEvent("heal_success", Heal_Success);
        HookEvent("player_entered_checkpoint", Player_Entered_Checkpoint);
        HookEvent("tank_frustrated", Tank_Frustrated);
        HookEvent("player_hurt", Player_Hurt_Native); // This goes in the standard source events common.inc. This is because L4D2 does not support SDKHook's OnTakeDamage.
    }
    //(THRAKA)
    g_hForwardClientGainAch = CreateGlobalForward("mw_ach_ClientGainedAchievement", ET_Ignore, Param_Cell, Param_Cell, Param_String);
}


public OnMapStart() {
    PrecacheSound(ACHIEVEMENT_SOUND);
}

public OnClientPutInServer(client) {
    GetClientDBInfo(client);
    g_motd[client] += 1;
    
    if (g_Gamemode != 2) SDKHook(client, SDKHook_OnTakeDamage, Player_Hurt);
}

public Action:Command_Refresh(client, args) {
    GetAchievementInfo();
    return Plugin_Handled;
}

public OnGameFrame() {
    for (new i = 1; i <= MaxClients; i++) {
        UpdateClientCondition(i);
    }
}

// (THRAKA) Thanks Thrawn for levelmod's example on natives and forwards
/////////////////
//N A T I V E S//
/////////////////
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
	public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	//LibraryExists("mw_achievements");
	RegPluginLibrary("mw_achievements");

	CreateNative("mw_ach_TriggerCustomAchievement", Native_TriggerCustomAchievement);
	CreateNative("mw_ach_HasClientAchieved", Native_HasClientAchieved);
	CreateNative("mw_ach_HasClientAchByIdName", Native_HasClientAchByIdName);

	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
		return true;
	#endif
}

//mw_ach_TriggerCustomAchievement(String:customEventName[128], clientId);
public Native_TriggerCustomAchievement(Handle:hPlugin, iNumParams)
{
	new String:achievementIdName[128];
	GetNativeString(1, achievementIdName, sizeof(achievementIdName));
	new clientId = GetNativeCell(2);
		
	for (new i = 0; i < GetArraySize(g_Achievements_Server); i++) {
        
		new any:t_ach_trie = GetArrayCell(g_Achievements_Server, i);
		new any:t_ach_id;
		new any:t_ach_game;
		new String:t_ach_idName[128];
		
		GetTrieString(t_ach_trie, "id_name", t_ach_idName, sizeof(t_ach_idName));
		GetTrieValue(t_ach_trie, "id", t_ach_id);
		GetTrieValue(t_ach_trie, "game", t_ach_game);
				
		if ((t_ach_game <= 0 || t_ach_game == g_Gamemode) && StrEqual(achievementIdName, t_ach_idName, false))
		{
			CreateTrieAch(clientId, t_ach_id);
			
			for (new i2 = 0; i2 < GetArraySize(g_Achievements_User); i2++) 
			{
				new any:t_achuser_trie = GetArrayCell(g_Achievements_User, i2);
				new any:t_achuser_client;
				new any:t_achuser_id;
				new t_achuser_completed = 0;
				
				GetTrieValue(t_achuser_trie, "achid", t_achuser_id);
				GetTrieValue(t_achuser_trie, "client", t_achuser_client);
				GetTrieValue(t_achuser_trie, "complete", t_achuser_completed);
				
				if (t_achuser_id == t_ach_id && t_achuser_client == clientId && t_achuser_completed <= 0) 
				{
                    
					new any:max;
					new any:triggers;
					GetTrieValue(t_ach_trie, "triggers", max);
					GetTrieValue(t_achuser_trie, "triggers", triggers);
					triggers += 1;
					
					// CHECK BLOCKS REMOVED
					
					// Achievement is completed
					if (triggers >= max) 
					{
						triggers = 0;
						t_achuser_completed += 1;
						
						SetTrieValue(t_achuser_trie, "complete", t_achuser_completed);
						new String:achname[128];
						GetTrieString(t_ach_trie, "name", achname, sizeof(achname));
						new String:strMessage[200];
						Format(strMessage, sizeof(strMessage), "\x03%N\x01 has earned the achievement \x05%s", clientId, achname);
						Forward_ClientGainedAchievement(clientId, t_ach_id, t_ach_idName);
						
						SayText2(clientId,strMessage);
						if (GetConVarBool(cvar_achinfo)) 
						{
							new String:achdesc[128];
							GetTrieString(t_ach_trie, "desc", achdesc, sizeof(achdesc));
							Format(strMessage, sizeof(strMessage), "(\x05%s\x01)", achdesc);
							SayText2(clientId, strMessage);
						}
						AchievementEffect(clientId);
					}
					SetTrieValue(t_achuser_trie, "triggers", triggers);
					
					UpdateUserAchievement(clientId, t_ach_id, triggers, t_achuser_completed);
					
					// RESET BLOCKS REMOVED
                }
            }
        }
    }
}

//native mw_ach_HasClientAchieved(achievementId, clientId);
public Native_HasClientAchieved(Handle:hPlugin, iNumParams)
{
	new achievementId = GetNativeCell(1);
	new clientId = GetNativeCell(2);
	
	for (new i = 0; i < GetArraySize(g_Achievements_Server); i++) {
        
		new any:t_ach_trie = GetArrayCell(g_Achievements_Server, i);
		new any:t_ach_id;
		new any:t_ach_game;
		new String:t_ach_idName[128];
		
		GetTrieString(t_ach_trie, "id_name", t_ach_idName, sizeof(t_ach_idName));
		GetTrieValue(t_ach_trie, "id", t_ach_id);
		GetTrieValue(t_ach_trie, "game", t_ach_game);
		
		if ((t_ach_game <= 0 || t_ach_game == g_Gamemode) && t_ach_id == achievementId)
		{
			CreateTrieAch(clientId, t_ach_id);
			
			for (new i2 = 0; i2 < GetArraySize(g_Achievements_User); i2++) 
			{
				new any:t_achuser_trie = GetArrayCell(g_Achievements_User, i2);
				new t_achuser_completed = 0;
				
				GetTrieValue(t_achuser_trie, "complete", t_achuser_completed);
				
				return t_achuser_completed > 0;
            }
        }
    }
	
	return false;
}

//native mw_ach_HasClientAchByIdName(String:achievementIdName[128], clientId);
public Native_HasClientAchByIdName(Handle:hPlugin, iNumParams)
{
	new String:achievementIdName[128];
	GetNativeString(1, achievementIdName, sizeof(achievementIdName));
	new clientId = GetNativeCell(2);
		
	for (new i = 0; i < GetArraySize(g_Achievements_Server); i++) {
        
		new any:t_ach_trie = GetArrayCell(g_Achievements_Server, i);
		new any:t_ach_id;
		new any:t_ach_game;
		new String:t_ach_idName[128];
		
		GetTrieString(t_ach_trie, "id_name", t_ach_idName, sizeof(t_ach_idName));
		GetTrieValue(t_ach_trie, "id", t_ach_id);
		GetTrieValue(t_ach_trie, "game", t_ach_game);
		
		if ((t_ach_game <= 0 || t_ach_game == g_Gamemode) && StrEqual(achievementIdName, t_ach_idName, false))
		{
			CreateTrieAch(clientId, t_ach_id);
			
			for (new i2 = 0; i2 < GetArraySize(g_Achievements_User); i2++) 
			{
				new any:t_achuser_trie = GetArrayCell(g_Achievements_User, i2);
				new t_achuser_completed = 0;
				
				GetTrieValue(t_achuser_trie, "complete", t_achuser_completed);

				return t_achuser_completed > 0;
            }
        }
    }
	
	return false;
}

//forward mw_ach_ClientGainedAchievement(clientId, achievementId, String:achievementIdName[128]);
public Forward_ClientGainedAchievement(clientId, achievementId, String:achievementIdName[128])
{
	Call_StartForward(g_hForwardClientGainAch);
	Call_PushCell(clientId);
	Call_PushCell(achievementId);
	Call_PushString(achievementIdName);
	Call_Finish();
}