//#include <sourcemod>
/***
	Programming is philosophy.
	Silence is golden.
	# GAMEVOTING #
		Vladimir Zhelnov @neatek
		Sourcemod 1.8 -gv188 // 2017
		Sourcemod 1.10 - gv190 // 2020
	Contact me:
	https://discord.gg/J7eSXuU
	https://neatek.ru/en
	Supports: Sourcebans++, MaterialAdmin, Sourcemod (2020)
***/
#undef REQUIRE_PLUGIN
#include <sourcebanspp>
#include <sourcecomms>
#include <materialadmin>
#pragma semicolon 1
#pragma newdecls required
#define VERSION "1.9.3"
#define REASON_LEN 68
#define EVENT_PARAMS Handle event, const char[] name, bool dontBroadcast
#define VALID_PLAYER if(IsCorrectPlayer(client))
#define VALID_TARGET if(IsCorrectPlayer(target))
#define EVENT_GET_PLAYER GetClientOfUserId(GetEventInt(event, "userid"));
public Plugin myinfo =
{
	name = "GameVoting",
	author = "Neatek",
	description = "Simple sourcemod plugin for voting",
	version = VERSION,
	url = "https://github.com/neatek/GameVoting"
};
#define VOTE_BAN 1
#define VOTE_KICK 2
#define VOTE_MUTE 3
#define VOTE_SILENCE 4
#define VAR_VOTEBAN g_VoteChoise[client].vbSteam
#define VAR_VOTEKICK g_VoteChoise[client].vkSteam
#define VAR_VOTEMUTE g_VoteChoise[client].vmSteam
#define VAR_VOTESILENCE g_VoteChoise[client].vsSteam
#define VAR_IVOTEBAN g_VoteChoise[i].vbSteam
#define VAR_IVOTEKICK g_VoteChoise[i].vkSteam
#define VAR_IVOTEMUTE g_VoteChoise[i].vmSteam
#define VAR_IVOTESILENCE g_VoteChoise[i].vsSteam
#define VAR_TVOTEBAN g_VoteChoise[target].vbSteam
#define VAR_TVOTEKICK g_VoteChoise[target].vkSteam
#define VAR_TVOTEMUTE g_VoteChoise[target].vmSteam
#define VAR_TVOTESILENCE g_VoteChoise[target].vsSteam
#define VAR_CTYPE g_VoteChoise[client].current_type
#define PLUG_TAG "GameVoting"
#define BAN_COMMAND  "voteban"
#define KICK_COMMAND "votekick"
#define GAG_COMMAND  "votegag"
#define MUTE_COMMAND "votemute"
#define SILENCE_COMMAND "votesilence"
#define CONVAR_VERSION ConVars[0]
#define CONVAR_ENABLED ConVars[1]
#define CONVAR_BAN_DURATION ConVars[2]
#define CONVAR_MUTE_DURATION ConVars[3]
//#define CONVAR_SILENCE_DURATION ConVars[4] 
#define CONVAR_KICK_DURATION ConVars[5]
#define CONVAR_BAN_ENABLE ConVars[6]
#define CONVAR_KICK_ENABLE ConVars[7]
#define CONVAR_MUTE_ENABLE ConVars[8]
//#define CONVAR_SILENCE_ENABLE ConVars[9]
#define CONVAR_MIN_PLAYERS ConVars[10]
#define CONVAR_AUTODISABLE ConVars[11]
#define CONVAR_BAN_PERCENT ConVars[12]
#define CONVAR_KICK_PERCENT ConVars[13]
#define CONVAR_MUTE_PERCENT ConVars[14]
//#define CONVAR_SILENCE_PERCENT ConVars[15]
#define CONVAR_IMMUNITY_FLAG ConVars[16]
#define CONVAR_IMMUNITY_zFLAG ConVars[17]
#define CONVAR_FLAG_START_VOTE ConVars[4]
#define CONVAR_START_VOTE_DELAY ConVars[9]
#define CONVAR_START_VOTE_ENABLE ConVars[15]
#define CONVAR_AUTHID_TYPE ConVars[18]
#define CONVAR_ENABLE_LOGS ConVars[19]
#define CONVAR_START_VOTE_MIN ConVars[20]
#define CONVAR_BOT_ENABLED ConVars[21]
#define CONVAR_ONLY_TEAMMATES ConVars[22]
#define LOGS_ENABLED if(strlen(LogFilePath) > 0 && CONVAR_ENABLE_LOGS.IntValue > 0)
//#define PLUGIN_DEBUG 1
//#define PLUGIN_DEBUG_MODE 1
enum struct ENUM_VOTE_CHOISE
{
	int current_type;
	int voteban_reason;
	char vbSteam[32];
	char vkSteam[32];
	char vmSteam[32];
	char vsSteam[32];
}
enum struct ENUM_KICKED_PLAYERS
{
	int time;
	char Steam[32];
}
int g_startvote_delay = 0;
ConVar ConVars[23];
char LogFilePath[512];
ArrayList gReasons;
ENUM_VOTE_CHOISE g_VoteChoise[MAXPLAYERS+1];
ENUM_KICKED_PLAYERS g_KickedPlayers[MAXPLAYERS+1];

bool is_sourcebanspp_comms = false;
bool is_sourcebanspp_bans = false;
bool is_maadmin_comms = false;
bool is_maadmin_bans = false;

public bool sourcebanspp_bans() {
	char fFile[86];
	BuildPath(Path_SM, fFile, sizeof(fFile), "plugins/sbpp_main.smx");
	LogMessage("[GameVoting] Sourcebans++ check bans file: %s", fFile);
	if(FileExists(fFile)) {
		return true;
	}
	return false;
}

public bool sourcebanspp_comms() {
	char fFile[86];
	BuildPath(Path_SM, fFile, sizeof(fFile), "plugins/sbpp_comms.smx");
	LogMessage("[GameVoting] Sourcebans++ check comms file: %s", fFile);
	if(FileExists(fFile)) {
		return true;
	}
	return false;
}

public bool maadmin_comms() {
	char fFile[86];
	BuildPath(Path_SM, fFile, sizeof(fFile), "plugins/ma_basecomm.smx");
	LogMessage("[GameVoting] MaterialAdmin check comms file: %s", fFile);
	if(FileExists(fFile)) {
		return true;
	}
	return false;
}

public bool maadmin_bans() {
	char fFile[86];
	BuildPath(Path_SM, fFile, sizeof(fFile), "plugins/materialadmin.smx");
	LogMessage("[GameVoting] MaterialAdmin check bans file: %s", fFile);
	if(FileExists(fFile)) {
		return true;
	}
	return false;
}

public void loadReasons() {
	if(gReasons != null) gReasons.Clear();
	char fFile[86];
	BuildPath(Path_SM, fFile, sizeof(fFile), "configs/gvreasons.txt");
	if(FileExists(fFile))
	{
		File oFile = OpenFile(fFile,"r");
		if(oFile == null) SetFailState("I can't open file: addons/sourcemod/configs/gvreasons.txt");
		if(FileSize(fFile) < 5) SetFailState("Please, fill this file: addons/sourcemod/configs/gvreasons.txt");
		char buff[REASON_LEN];
		int oLines = 1;
		gReasons = new ArrayList(REASON_LEN, 0);
		while(!IsEndOfFile(oFile))
		{
			if(!ReadFileLine(oFile,buff,REASON_LEN)) {
				//SetFailState("I can't read file: addons/sourcemod/configs/gvreasons.txt");
				continue;
			}
			TrimString(buff);
			if(strlen(buff) > 3)
			{
				#if defined PLUGIN_DEBUG
				LogMessage("Push reason: %s", buff);
				#endif

				int index = gReasons.PushString(buff);

				LOGS_ENABLED {
					LogToFile(LogFilePath, "Reason loaded : %s (index : %d)", buff, index);
					PrintToServer("Reason loaded : %s (index : %d)", buff, index);
				}
				
				oLines++;
			}
			else
			{
				LogError("Can't add reason: %s, because its smaller than 3 letters. (LINE: %d)", buff, oLines);
			}
		}
		
		oFile.Close();
	}
	else
		SetFailState("Please, create file in directory: addons/sourcemod/configs/gvreasons.txt, with reasons on one line!");
}

public void register_ConVars() {
	is_sourcebanspp_comms = sourcebanspp_comms();
	is_sourcebanspp_bans = sourcebanspp_bans();
	is_maadmin_comms = maadmin_comms();
	is_maadmin_bans = maadmin_bans();

	// Global
	CONVAR_VERSION = CreateConVar("sm_gamevoting_version", VERSION, "Version of gamevoting plugin. DISCORD - https://discord.gg/J7eSXuU , Author: Neatek, www.neatek.ru", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CONVAR_ENABLED = CreateConVar("gamevoting_enable", "1", "Enable or disable plugin (def:1)", _, true, 0.0, true, 1.0);	
	CONVAR_AUTHID_TYPE = CreateConVar("gamevoting_authid", "1", "AuthID type, 1 - AuthId_Engine, 2 - AuthId_Steam2, 3 - AuthId_Steam3, 4 - AuthId_SteamID64 (def:1)", _, true, 1.0, true, 4.0);
	CONVAR_ENABLE_LOGS = CreateConVar("gamevoting_logs",	 "1", "Enable or disable logs for plugin (def:1)", _, true, 0.0, true, 1.0);
	// Min players
	CONVAR_MIN_PLAYERS = CreateConVar("gamevoting_players",	"8", "Minimum players need to enable votes (def:8)", _, true, 0.0, true, 20.0);
	CONVAR_AUTODISABLE = CreateConVar("gamevoting_autodisable","0", "Disable plugin when admins on server? (def:0)", _, true, 0.0, true, 1.0);
	// Disables
	CONVAR_BAN_ENABLE = CreateConVar("gamevoting_voteban",	"1", "Enable or disable voteban functional (def:1)", _, true, 0.0, true, 1.0);
	CONVAR_KICK_ENABLE = CreateConVar("gamevoting_votekick",	"1", "Enable or disable votekick (def:1)", _, true, 0.0, true, 1.0);
	CONVAR_MUTE_ENABLE = CreateConVar("gamevoting_votemute",	"1", "Enable or disable votemute (def:1)", _, true, 0.0, true, 1.0);
	//CONVAR_SILENCE_ENABLE = CreateConVar("gamevoting_votesilence",	"1",	"Enable or disable silence (def:1)", _, true, 0.0, true, 1.0);
	// Durations
	CONVAR_BAN_DURATION = CreateConVar("gamevoting_voteban_delay", "20", "Ban duration in minutes (def:120)", _, true, 1.0, false);
	CONVAR_KICK_DURATION = CreateConVar("gamevoting_votekick_delay", "20", "Kick duration in seconds (def:20)", _, true, 1.0, false);
	CONVAR_MUTE_DURATION = CreateConVar("gamevoting_votemute_delay", "20", "Mute duration in minutes (def:120)", _, true, 1.0, false);
	//CONVAR_SILENCE_DURATION = CreateConVar("gamevoting_votesilence_delay", "1", "Mute duration in minutes (def:120)", _, true, 0.0, false);
	// Percent
	CONVAR_BAN_PERCENT = CreateConVar("gamevoting_voteban_percent",	"80", "Needed percent of players for ban someone (def:80)", _, true, 1.0, true, 100.0);
	CONVAR_KICK_PERCENT = CreateConVar("gamevoting_votekick_percent", "80", "Needed percent of players for kick someone (def:80)", _, true, 1.0, true, 100.0);
	CONVAR_MUTE_PERCENT = CreateConVar("gamevoting_votemute_percent", "75", "Needed percent of players for mute someone (def:75)", _, true, 1.0, true, 100.0);
	//CONVAR_SILENCE_PERCENT = CreateConVar("gamevoting_votesilence_percent",	 "75",	"Needed percent of players for silence someone (def:75)", _, true, 0.0, true, 100.0);
	// ImmunityFlags
	CONVAR_IMMUNITY_FLAG = CreateConVar("gamevoting_immunity_flag",	"a", "Immunity flag from all votes, set empty for disable immunity (def:a)");
	CONVAR_IMMUNITY_zFLAG = CreateConVar("gamevoting_immunity_zflag", "1", "Immunity for admin flag \"z\"");
	// StartVote
	CONVAR_START_VOTE_ENABLE = CreateConVar("gamevoting_startvote_enable", "1", "Disable of enable public votes (def:1)", _, true, 0.0, true, 1.0);
	CONVAR_FLAG_START_VOTE = CreateConVar("gamevoting_startvote_flag", "", "Who can start voting for ban or something, set empty for all players (def:a)");
	CONVAR_START_VOTE_DELAY = CreateConVar("gamevoting_startvote_delay", "20", "Delay between public votes in seconds (def:20)", _, true, 5.0, false);
	CONVAR_START_VOTE_MIN = CreateConVar("gamevoting_startvote_min", "4", "Minimum players for start \"startvote\" feature (def:4)", _, true, 2.0);
	CONVAR_BOT_ENABLED = CreateConVar("gamevoting_bots_enabled", "0", "Disable of enable bots in votes (def:0)", _, true, 0.0, true, 1.0);
	CONVAR_ONLY_TEAMMATES = CreateConVar("gamevoting_only_teammates", "0", "Disable of enable only teammates in votes (def:0)", _, true, 0.0, true, 1.0);
	// Listeners
	AddCommandListener(OnClientCommands, "say");
	AddCommandListener(OnClientCommands, "say_team");
	// Configs&Translations
	AutoExecConfig(true, "gamevoting");
	LoadTranslations("gamevoting.phrases");
}


public int MenuHandler_Reason(Menu menu, MenuAction action, int client, int item) {
	if(action == MenuAction_End) CloseHandle(menu);
	else if(action == MenuAction_Select) 
	{
		char item1[11];
		GetMenuItem(menu, item, item1, sizeof(item1));
		g_VoteChoise[client].voteban_reason = StringToInt(item1); // reason from array
		LOGS_ENABLED {
			char reason[64];
			if(g_VoteChoise[client].voteban_reason > -1) {
				gReasons.GetString(g_VoteChoise[client].voteban_reason, reason, sizeof(reason));
			}
			PrintToServer("Player %N choised reason : %s - #%i - #%i",  client, reason, g_VoteChoise[client].voteban_reason, StringToInt(item1));
			LogToFile(LogFilePath, "Player %N choised reason : %s - #%i - #%i",  client, reason, g_VoteChoise[client].voteban_reason, StringToInt(item1));
		}
		// Handle StartVote Enable/Disable
		if(CONVAR_START_VOTE_ENABLE.IntValue > 0) {
			ShowMenu(client, VOTE_BAN, true);
		}
		else {
			ShowMenu(client, VOTE_BAN, false);
		}
	}
}

public void DisplayReasons(int client) {
	Menu mReasons = CreateMenu(MenuHandler_Reason);
	SetMenuTitle(mReasons, "[GameVoting] Reason");
	int sSize = ((gReasons.Length)-1);
	char buff[REASON_LEN];
	char buff2[18];
	for(int i = 0; i <= sSize; i++) {
		gReasons.GetString(i, buff, sizeof(buff));
		IntToString(i, buff2, sizeof(buff2));
		//AddMenuItem(mReasons, buff2, buff, ITEMDRAW_DEFAULT);
		mReasons.AddItem(buff2, buff, ITEMDRAW_DEFAULT);
		LOGS_ENABLED {
			//LogToFile(LogFilePath, "Reason loaded : %s (index : %d)", buff, index);
			PrintToServer("Display menu reason: %s - %s ", buff2, buff);
		}
	}
	DisplayMenu(mReasons, client, 0);
}

public void OnMapStart() {
	loadReasons();
}

public void checkcommands(int client, char[] string) {
	VALID_PLAYER {
		#if defined PLUGIN_DEBUG_MODE
			PrintToChatAll("checkcommands : %s", string);
		#endif
	
		if(string[0] == '!' && string[1] == 'v' && string[2] == 'o' && string[3] == 't' && string[4] == 'e') {
			CheckCommand(client, string, "!");
		}
		
		else if(string[0] == '/' && string[1] == 'v' && string[2] == 'o' && string[3] == 't' && string[4] == 'e') {
			CheckCommand(client, string, "/");
		}
		
		else if(string[0] == 'v' && string[1] == 'o' && string[2] == 't' && string[3] == 'e') {
			CheckCommand(client, string, "");
		}
	}
}

public Action OnClientCommands(int client, char[] command, int argc) 
{
	char text[32]; 
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	#if defined PLUGIN_DEBUG_MODE
		PrintToChatAll("s : %s", text);
	#endif
	
	checkcommands(client,text);
	return Plugin_Continue;
}

// Chat listener
/*public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	checkcommands(client,sArgs);
	return Plugin_Continue;
}*/

public void OnPluginStart() {
	// Disable standart votes
	ServerCommand("sv_allow_votes 0");
	// Events
	HookEvent("player_disconnect", Event_PlayerDisconnected);
	register_ConVars();
	GVInitLog();
}

public void OnPluginEnd() {
	UnhookEvent("player_disconnect", Event_PlayerDisconnected);
}

public void GVInitLog() {
	loadReasons();
	if(CONVAR_ENABLE_LOGS.IntValue > 0) {
		BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/gamevoting/");
		if(!DirExists(LogFilePath)) {
			CreateDirectory(LogFilePath, 777);
		}
		char ftime[68];
		FormatTime(ftime, sizeof(ftime), "logs/gamevoting/gv%m-%d.txt",  GetTime());
		BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), ftime);
		LogToFile(LogFilePath, "Sourcebans++ Bans Detect: %b", is_sourcebanspp_bans);
		LogToFile(LogFilePath, "Sourcebans++ Comms Detect: %b", is_sourcebanspp_comms);
		LogToFile(LogFilePath, "MaterialAdmin Comms Detect: %b", is_maadmin_comms);
		LogToFile(LogFilePath, "MaterialAdmin Bans Detect: %b", is_maadmin_bans);
	}
}

public int FindFreeSlot() {
	for(int i =0 ; i <= MAXPLAYERS; i ++) {
		if(g_KickedPlayers[i].time == 0) {
			return i;
		} else if(g_KickedPlayers[i].time < GetTime()) {
			g_KickedPlayers[i].time = 0;
		}
	}
	return -1;
}

stock bool IsAdmin(int client)
{
	AdminId admin = GetUserAdmin(client);

	if(admin == INVALID_ADMIN_ID)
		return false;
		
	return GetAdminFlag(admin, Admin_Generic);
}

public bool adminsonserver()
{
	bool result = false;
	for(int i=0; i < MaxClients; ++i) {
		if(IsCorrectPlayer(i)) {
			if(IsAdmin(i)) {
				result = true;
				break;
			}
		}
	}
	return result;
}

public void ClearVotesForClient(int client, int type) {
	VALID_PLAYER {
		char auth[32];
		//GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));
		player_steam(client, auth, sizeof(auth));
		for(int i =0 ; i <= MAXPLAYERS; i ++) {
			
			switch(type) {
				case VOTE_BAN: {
					if(StrEqual(VAR_IVOTEBAN,auth,true)) {
						strcopy(VAR_IVOTEBAN, 32, "");
					}
				}
				
				case VOTE_KICK: {
					if(StrEqual(VAR_IVOTEKICK,auth,true)) {
						strcopy(VAR_IVOTEKICK, 32, "");
					}
				}
				
				case VOTE_MUTE: {
					if(StrEqual(VAR_IVOTEMUTE,auth,true)) {
						strcopy(VAR_IVOTEMUTE, 32, "");
					}
				}

				default: {
					break;
				}
				
			}
			/*if(StrEqual(VAR_IVOTESILENCE,auth,true)) {
				strcopy(VAR_IVOTESILENCE, 32, "");
			}*/
		}
	}
}

public void PushKickedPlayer(int client) {
	VALID_PLAYER {
		int slot = FindFreeSlot();
		#if defined PLUGIN_DEBUG_MODE
			LogMessage("Kicked free slot : %d", slot);
		#endif
		if(slot > -1) {
			g_KickedPlayers[client].time = GetTime() + ( CONVAR_KICK_DURATION.IntValue );
			#if defined PLUGIN_DEBUG_MODE
				LogMessage("Kicked time : %d", (GetTime() + ( CONVAR_KICK_DURATION.IntValue )));
			#endif
			char auth[32];
			//GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));
			player_steam(client, auth, sizeof(auth));
			strcopy(g_KickedPlayers[client].Steam, 32, auth);
		}
		KickClient(client, "Kicked by GameVoting (wait: %dsec)", CONVAR_KICK_DURATION.IntValue);
	}
	
}

public int KickedPlayer(int client) {
	VALID_PLAYER {
		char auth[32];
		//GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));
		player_steam(client, auth, sizeof(auth));
		
		for(int i =0 ; i <= MAXPLAYERS; i ++) {
			if(StrEqual(g_KickedPlayers[i].Steam,auth,true)) {
			
				if(g_KickedPlayers[i].time > GetTime()) {
					return ( g_KickedPlayers[i].time - GetTime() );
				}
				else {
					strcopy(g_KickedPlayers[i].Steam, 32, "");
					g_KickedPlayers[i].time = 0;
					return 0;
				
				}
			}
		}
	}
	
	return 0;
}

public void OnClientPostAdminCheck(int client) {
	VALID_PLAYER {
		int wait = KickedPlayer(client);
		
		#if defined PLUGIN_DEBUG_MODE
			LogMessage("Kicked wait : %d", wait);
		#endif
		
		if(wait > 0) {
			KickClient(client, "Kicked by GameVoting (Wait: %d sec)", wait);
		}
	}
}

public int GetCountVotes(int client, int type) {

	VALID_PLAYER {
	
		int i_Counted = 0;
	
		char auth[32];
		//GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));
		player_steam(client, auth, sizeof(auth));
	
		for(int target = 0; target <= MAXPLAYERS; target++) {
			VALID_TARGET {
			
				switch(type) {
					case VOTE_BAN: {
						if(StrEqual(VAR_TVOTEBAN,auth,true)) {
							i_Counted++;
						}
					}
				
					case VOTE_KICK: {
						if(StrEqual(VAR_TVOTEKICK,auth,true)) {
							i_Counted++;
						}
					}
				
					case VOTE_MUTE: {
						if(StrEqual(VAR_TVOTEMUTE,auth,true)) {
							i_Counted++;
						}
					}
				
					case VOTE_SILENCE: {
						if(StrEqual(VAR_TVOTESILENCE,auth,true)) {
							i_Counted++;
						}
					}
				
					default: {
						break;
					}
				
				}
			
			}
		
		}
		
		return i_Counted;
	
	}
	
	
	return 0;
}

public void ClearChoise(int client) {
	strcopy(VAR_VOTEBAN, 32, "");
	strcopy(VAR_VOTEKICK, 32, "");
	strcopy(VAR_VOTEMUTE, 32, "");
	g_VoteChoise[client].voteban_reason = 0;
	//strcopy(VAR_VOTESILENCE, 32, "");
}

public int GetCountNeeded(int type) {

/*
	#define CONVAR_BAN_PERCENT ConVars[12]
	#define CONVAR_KICK_PERCENT ConVars[13]
	#define CONVAR_MUTE_PERCENT ConVars[14]
	#define CONVAR_SILENCE_PERCENT ConVars[15]
*/
	int players = CountPlayers();

	switch(type) {
	
		case VOTE_BAN: {
			///CONVAR_BAN_PERCENT.FloatValue 
			///((player.num() * cVbPercent.IntValue) / 100);
			return ((players * CONVAR_BAN_PERCENT.IntValue) / 100);
		}
				
		case VOTE_KICK: {
			return ((players * CONVAR_KICK_PERCENT.IntValue) / 100);
		}
				
		case VOTE_MUTE: {
			return ((players * CONVAR_MUTE_PERCENT.IntValue) / 100);
		}
				
		/*case VOTE_SILENCE: {
			return ((players * CONVAR_SILENCE_PERCENT.IntValue) / 100);
		}*/
		
		default: {
		
			return -1;
			
		}
	
	}
	
	//return -1;
}

public void SetChoise(int type, int client, int target) {
	VALID_PLAYER {
		VALID_TARGET {
		
			char auth[32];
			//GetClientAuthId(target, AuthId_Engine, auth, sizeof(auth));
			player_steam(target, auth, sizeof(auth));
			
			int needed = GetCountNeeded(type);
			
			if(CONVAR_BOT_ENABLED.IntValue < 1) {
				if(needed < 1) {
					needed = 3;
				}
			}
			
			int current = 0;
			
			switch(type) {
					
				case VOTE_BAN: {
					strcopy(VAR_VOTEBAN, 32, auth);
					//g_VoteChoise[i].voteban_reason
					current = GetCountVotes(target, VOTE_BAN);
					//PrintToChatAll("Player %N voted for ban %N. (%d/%d)", client, target, current, needed);
					char c_name[32],t_name[32];
					GetClientName(client, c_name, sizeof(c_name));
					GetClientName(target, t_name, sizeof(t_name));
					PrintToChatAll("\x04[GameVoting]\x01 %t", "gv_voted_for_ban", c_name, t_name, current, needed);

					LOGS_ENABLED {
						char reason[64];
						if(g_VoteChoise[client].voteban_reason > -1)
							gReasons.GetString(g_VoteChoise[client].voteban_reason, reason, sizeof(reason));

						char auth1[32];//,auth2[32];
						player_steam(client, auth1, sizeof(auth1)); 
						//player_steam(target, auth2, sizeof(auth1));
						LogToFile(LogFilePath, "Player %N(%s) voted for ban %N(%s). (%d/%d) (Reason: %s - #%d)",  client, auth1, target, auth, current, needed, reason, g_VoteChoise[client].voteban_reason);
						PrintToServer("Player %N(%s) voted for ban %N(%s). (%d/%d) (Reason: %s - #%d)",  client, auth1, target, auth, current, needed, reason, g_VoteChoise[client].voteban_reason);
					}
				}
				
				case VOTE_KICK: {
					strcopy(VAR_VOTEKICK, 32, auth);
					current = GetCountVotes(target, VOTE_KICK);
					char c_name[32],t_name[32];
					GetClientName(client, c_name, sizeof(c_name));
					GetClientName(target, t_name, sizeof(t_name));
					//PrintToChatAll("Player %N voted for kick %N. (%d/%d)", client, target, current, needed);
					PrintToChatAll("\x04[GameVoting]\x01 %t", "gv_voted_for_kick", c_name, t_name, current, needed);
					
					LOGS_ENABLED {
						char auth1[32];//,auth2[32];
						player_steam(client, auth1, sizeof(auth1)); 
						//player_steam(target, auth2, sizeof(auth1));
						LogToFile(LogFilePath, "Player %N(%s) voted for kick %N(%s). (%d/%d)",  client, auth1, target, auth, current, needed);
					}
				}
				
				case VOTE_MUTE: {
					strcopy(VAR_VOTEMUTE, 32, auth);
					current = GetCountVotes(target, VOTE_MUTE);
					char c_name[32],t_name[32];
					GetClientName(client, c_name, sizeof(c_name));
					GetClientName(target, t_name, sizeof(t_name));
					//PrintToChatAll("Player %N voted for mute %N. (%d/%d)", client, target, current, needed);
					PrintToChatAll("\x04[GameVoting]\x01 %t", "gv_voted_for_mute", c_name, t_name, current, needed);
					
					LOGS_ENABLED {
						char auth1[32];//,auth2[32];
						player_steam(client, auth1, sizeof(auth1)); 
						//player_steam(target, auth2, sizeof(auth1));
						LogToFile(LogFilePath, "Player %N(%s) voted for mute %N(%s). (%d/%d)",  client, auth1, target, auth, current, needed);
					}
				}

				default: {
					return;
				}
				
			}

			if(current >= needed) 
			{
				DoAction(target, type, client);
			}
			else if(current >= CONVAR_START_VOTE_MIN.IntValue && StartVoteFlag(client)) 
			{
				if(type != VOTE_BAN) 
				{
					ShowMenu(client, type, true);
				}
				else 
				{
					DisplayReasons(client);
				}
			}
		}
	}
}

public int CountPlayers() {
	int output = 0;
	
	for(int i = 1; i <= MaxClients; i++) 
		if(IsCorrectPlayer(i) && !HasImmunity(i)) 
			output++;
	
	return output;
}

public int CountPlayers_withoutImmunity() {
	int output = 0;
	
	for(int i = 1; i <= MaxClients; i++) 
		if(IsCorrectPlayer(i)) 
			output++;
	
	return output;
}

// Function for check is valid or not player
public bool IsCorrectPlayer(int client) {
	if(client > 4096) {
		client = EntRefToEntIndex(client);
	}
		
	if( (client < 1 || client > MaxClients) || !IsClientConnected(client) ||  !IsClientInGame( client ) ) {
		return false;
	}
	
	if(CONVAR_BOT_ENABLED.IntValue < 1) {
		if(IsFakeClient(client) || IsClientSourceTV(client)) {
			return false;
		}
	}
	
	return true;
}

// Great event for storing data
public Action Event_PlayerDisconnected(EVENT_PARAMS) 
{
	int client = EVENT_GET_PLAYER
	VALID_PLAYER {
		ClearChoise(client);
		// valid player
		#if defined PLUGIN_DEBUG_MODE
			LogMessage("%N player disconnected", client);
		#endif
	}
}

// Check commands
public void CheckCommand(int client, const char[] args, const char[] pref) {
	
	char command[24];
	strcopy(command, sizeof(command), args);
	TrimString(command);
	
	#if defined PLUGIN_DEBUG_MODE
		PrintToChatAll("CheckCommand : %s", command);
	#endif
	
	if(strlen(pref) > 0) {
		ReplaceString(command, sizeof(command), pref, "", true);
	}
	
	if(CONVAR_ENABLED.IntValue < 1) {
		return;
	}

	if(CountPlayers_withoutImmunity() < CONVAR_MIN_PLAYERS.IntValue) {
		//PrintToChat(client, "[GameVoting] Minimum players for voting - %d.", CONVAR_MIN_PLAYERS.IntValue);
		PrintToChat(client, "\x04[GameVoting]\x01 %t", "gv_min_players", CONVAR_MIN_PLAYERS.IntValue);
		return;
	}
	
	if(CONVAR_AUTODISABLE.IntValue > 0) {
		if(adminsonserver()) {
			return;
		}
	}
	
	if(StrEqual(command, BAN_COMMAND, false)) {
		if(CONVAR_BAN_ENABLE.IntValue < 1) {
			return;
		}
	
		DisplayReasons(client);
		//ShowMenu(client,VOTE_BAN,false);
		return;
	}
	
	if(StrEqual(command, KICK_COMMAND, false)) {
		if(CONVAR_KICK_ENABLE.IntValue < 1) {
			return;
		}
	
		ShowMenu(client,VOTE_KICK,false);
		return;
	}
	
	if(StrEqual(command, MUTE_COMMAND, false)) {
		if(CONVAR_MUTE_ENABLE.IntValue < 1) {
			return;
		}
	
		ShowMenu(client,VOTE_MUTE,false);
		return;
	}
	
	/*if(StrEqual(command, SILENCE_COMMAND, false)) {
		if(CONVAR_SILENCE_ENABLE.IntValue < 1) {
			return;
		}
	
		ShowMenu(client,VOTE_SILENCE);
		return;
	}*/
}

public bool StartVoteFlag(int client) {

	char s_flag[11];
	GetConVarString(CONVAR_FLAG_START_VOTE, s_flag, sizeof(s_flag));

	if(CONVAR_START_VOTE_ENABLE.IntValue < 1) {
		return false;
	}

	if(g_startvote_delay > GetTime() && CONVAR_START_VOTE_ENABLE.IntValue > 0 ) {
		//PrintToChat(client, "[GameVoting] Please wait %dsec before start public vote.", ((g_startvote_delay)-GetTime()) );
		PrintToChat(client, "\x04[GameVoting]\x01 %t", "gv_wait_before_startvote", ((g_startvote_delay)-GetTime()));
		return false;
	}

	if(strlen(s_flag) < 1) {
		return true;
	}
	
	int b_flags = ReadFlagString(s_flag);
	if ((GetUserFlagBits(client) & b_flags) == b_flags) {
		return true;
	}
	
	return false;
}

public bool HasImmunity(int client) {
	char s_flag[11];
	GetConVarString(CONVAR_IMMUNITY_FLAG, s_flag, sizeof(s_flag));
	
	if(strlen(s_flag) < 1) {
		return false;
	}
	
	int b_flags = ReadFlagString(s_flag);

	if ((GetUserFlagBits(client) & b_flags) == b_flags) {
		return true;
	}
	if(CONVAR_IMMUNITY_zFLAG.IntValue > 0) {
		if (GetUserFlagBits(client) & ADMFLAG_ROOT) {
			return true;
		}
	}

	return false;
	//CONVAR_IMMUNITY_FLAG
}

// Show ban&kick&mute&silence menu
public void ShowMenu(int client, int type, bool startvote_force) {

	VALID_PLAYER {
	
		if(CountPlayers_withoutImmunity() < 1)
			return;
	
		VAR_CTYPE = type;
		
		Menu mymenu;
		
		//if(!StartVoteFlag(client)) {
		if(!startvote_force) {
			mymenu = new Menu(menu_handler);
		}
		else {
			mymenu = new Menu(startvote_menu_player_handler);
		}

		//}
		//else {
		//	//CONVAR_START_VOTE_MIN
		//	if(CONVAR_START_VOTE_ENABLE.IntValue > 0)
		//		mymenu = new Menu(startvote_menu_player_handler);
		//	else
		//		mymenu = new Menu(menu_handler);
		//}

		char s_mtitle[48];
		switch(type) {
			case VOTE_BAN: {
				//mymenu.SetTitle("GAMEVOTING - BAN");
				Format(s_mtitle, sizeof(s_mtitle), "GAMEVOTING - %T", "gv_ban_title", client);
			}
			case VOTE_KICK: {
				//mymenu.SetTitle("GAMEVOTING - KICK");
				Format(s_mtitle, sizeof(s_mtitle), "GAMEVOTING - %T", "gv_kick_title", client);
			}
			case VOTE_MUTE: {
				//mymenu.SetTitle("GAMEVOTING - MUTE");
				Format(s_mtitle, sizeof(s_mtitle), "GAMEVOTING - %T", "gv_mute_title", client);
			}
			//case VOTE_SILENCE: {
				//mymenu.SetTitle("GAMEVOTING - SILENCE");
			//}
			default: {
				//mymenu.SetTitle("GAMEVOTING");
				Format(s_mtitle, sizeof(s_mtitle), "GAMEVOTING");
			}	
		}
		
		mymenu.SetTitle(s_mtitle);
		
		//mymenu.AddItem("-1", "\nSELECT TARGET PLAYER", ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);

		char Name[48], id[11];
		for(int target=0;target<MaxClients;target++) {
			VALID_TARGET {

				if(CONVAR_ONLY_TEAMMATES.IntValue > 0) {
					if(GetClientTeam(target) != GetClientTeam(client)) {
						continue;
					}
				}
			
				if(target != client && !HasImmunity(target)) {
					IntToString(target, id, sizeof(id));
					FormatEx(Name,sizeof(Name),"%N",target);
					mymenu.AddItem(id,Name);
				}

			}
		}
		mymenu.Display(client, MENU_TIME_FOREVER);
	}
}

public void StartVote(int client, int target, int type) {

	VALID_PLAYER { VALID_TARGET {
		if(g_startvote_delay > GetTime()) {
			PrintToChat(client, "\x04[GameVoting]\x01 %t", "gv_wait_before_startvote", ((g_startvote_delay)-GetTime()));
			return;
		}

		g_startvote_delay = GetTime() + CONVAR_START_VOTE_DELAY.IntValue;
		
		char s_logs[128];
		char t_name[32];
		GetClientName(target, t_name, sizeof(t_name));
		char c_name[32];
		GetClientName(client, c_name, sizeof(c_name));

		switch(VAR_CTYPE) {
			case VOTE_BAN: {
				char reason[64];
				gReasons.GetString(g_VoteChoise[client].voteban_reason, reason, sizeof(reason));
				PrintToChatAll("\x04[GameVoting]\x01 %t", "gv_startvote_ban", c_name, t_name, reason);
			}
			case VOTE_KICK: {
				char reason[64];
				gReasons.GetString(g_VoteChoise[client].voteban_reason, reason, sizeof(reason));
				PrintToChatAll("\x04[GameVoting]\x01 %t", "gv_startvote_kick", c_name, t_name, reason);
			}
			default: {
			}
		}

		for(int i = 1; i <= MaxClients; i++) {
			if(IsCorrectPlayer(i)) {
				// start vote menus
				Menu mymenu = new Menu(menu_startvote_action_handler);
				char s_typeInitiator[48];
				// client, target, type / explode
				FormatEx(s_typeInitiator,sizeof(s_typeInitiator),"%d|%d|%d",client,target,VAR_CTYPE);
				
				char s_Menu[86];
				

				switch(VAR_CTYPE) {
					case VOTE_BAN: {
						//FormatEx(s_Menu,sizeof(s_Menu),"GAMEVOTING - Ban %N?", target);
						char reason[64];
						gReasons.GetString(g_VoteChoise[client].voteban_reason, reason, sizeof(reason));
						Format(s_Menu, sizeof(s_Menu), "GAMEVOTING - %T", "gv_ban_title_question", i, t_name, reason);
						if(strlen(s_logs) < 1) {
							LOGS_ENABLED {
								char auth[32], auth1[32];
								player_steam(client, auth, sizeof(auth)); player_steam(target, auth1, sizeof(auth1));
								FormatEx(s_logs, sizeof(s_logs), "Player %N(%s) started public vote for ban %N(%s). Reason = %s",  client, auth,target,auth1,reason);
							}
						}
					}
					case VOTE_KICK: {
						//FormatEx(s_Menu,sizeof(s_Menu),"GAMEVOTING - Kick %N?", target);
						Format(s_Menu, sizeof(s_Menu), "GAMEVOTING - %T", "gv_kick_title_question", i, t_name);
						
						if(strlen(s_logs) < 1) {
						LOGS_ENABLED {
							char auth[32],auth1[32];
							player_steam(client, auth, sizeof(auth)); player_steam(target, auth1, sizeof(auth1));
							FormatEx(s_logs, sizeof(s_logs), "Player %N(%s) started public vote for kick %N(%s).",  client, auth,target,auth1);
						}
						}
					}
					case VOTE_MUTE: {
						//FormatEx(s_Menu,sizeof(s_Menu),"GAMEVOTING - Mute %N?", target);
						Format(s_Menu, sizeof(s_Menu), "GAMEVOTING - %T", "gv_mute_title_question", i, t_name);
						
						if(strlen(s_logs) < 1) {
						LOGS_ENABLED {
							char auth[32],auth1[32];
							player_steam(client, auth, sizeof(auth)); player_steam(target, auth1, sizeof(auth1));
							FormatEx(s_logs,sizeof(s_logs), "Player %N(%s) started public vote for mute %N(%s).",  client, auth,target,auth1);
						}
						}
					}
					default: {
						FormatEx(s_Menu,sizeof(s_Menu),"GAMEVOTING?");
						return;
					}	
				}
				
				mymenu.SetTitle(s_Menu);
				mymenu.AddItem("","----", ITEMDRAW_DISABLED);
				mymenu.AddItem("","----", ITEMDRAW_DISABLED);
				Format(s_Menu, sizeof(s_Menu), "%T", "gv_yes", i);
				mymenu.AddItem(s_typeInitiator,s_Menu);
				Format(s_Menu, sizeof(s_Menu), "%T", "gv_no", i);
				mymenu.AddItem("",s_Menu);
				mymenu.Display(i, MENU_TIME_FOREVER);
			}
		}
		
		LOGS_ENABLED {
			LogToFile(LogFilePath, s_logs);
		}

	} }
}

// startvote_menu_handler
public int startvote_menu_player_handler(Menu menu, MenuAction action, int client, int item) {

	if (action == MenuAction_Select) {
	
		char info[11];
		GetMenuItem(menu, item, info, sizeof(info));
		StartVote(client, StringToInt(info), VAR_CTYPE);
		
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// action startvote
public int menu_startvote_action_handler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char info[48];
		GetMenuItem(menu, item, info, sizeof(info));
		if(strlen(info) > 0) 
		{
			char ex[3][11];
			ExplodeString(info, "|", ex, 3, 11);
			int target = StringToInt(ex[1]);
			int type = StringToInt(ex[2]);
			VALID_TARGET {
				SetChoise(type, client, target);
			}
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// Menu callback
public int menu_handler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char info[11];
		GetMenuItem(menu, item, info, sizeof(info));
		int target = StringToInt(info);
		VALID_TARGET {
			SetChoise(VAR_CTYPE, client, target);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public void player_steam(int client, char[] steam_id, int size) {
	char auth[32];
	switch(CONVAR_AUTHID_TYPE.IntValue)
	{
		case 1: {
			if(GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth))) {
				Format(steam_id,size,auth);
			}
				
		}
		case 2: {
			if(GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth))) {
				Format(steam_id,size,auth);
			}
				
		}
		case 3:  {
			if(GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth))) {
				Format(steam_id,size,auth);
			}
				
		}
		case 4:  {
			if(GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth))) {
				Format(steam_id,size,auth);
			}
				
		}
	}
}

public void DoAction(int client, int type, int last) {
	
	switch(type) {
		case VOTE_BAN: {
			ClearChoise(client);  // clear votes of players if kick or ban
			ClearVotesForClient(client, VOTE_BAN);
			
			LOGS_ENABLED {
				char auth[32];
				player_steam(client, auth, sizeof(auth));
				LogToFile(LogFilePath, "Player %N(%s) was banned by voting. (Last voted player: %N)",  client, auth,last);
			}
			
			//int reason_num = HasReason(last);
			char reason[64];
			if(g_VoteChoise[last].voteban_reason > -1) {
				gReasons.GetString(g_VoteChoise[last].voteban_reason, reason, sizeof(reason));
			}
			else {
				strcopy(reason, sizeof(reason), "Empty reason");
			}

			if(is_sourcebanspp_bans) 
			{
				char reasonstring[68];
				Format(reasonstring, sizeof(reasonstring), "Gamevoting (%N)(%s)", last, reason);
				SBPP_BanPlayer(0, client, CONVAR_BAN_DURATION.IntValue, reasonstring);
			} 
			else if(is_maadmin_bans) 
			{
				char reasonstring[68];
				Format(reasonstring, sizeof(reasonstring), "Gamevoting (%N)(%s)", last, reason);
				MABanPlayer(0, client, 1, CONVAR_BAN_DURATION.IntValue, reasonstring);
			} 
			else 
			{
				ServerCommand("sm_ban #%d %d \"Gamevoting (%N)(%s)\"", GetClientUserId(client), CONVAR_BAN_DURATION.IntValue, last, reason);
			}

			LOGS_ENABLED {
				LogToFile(LogFilePath, "Server command: sm_ban #%d %d \"Gamevoting (%N)(%s)\"", GetClientUserId(client), CONVAR_BAN_DURATION.IntValue, last, reason);
			}

			KickClient(client, "Banned by GameVoting (%s)", reason);
		}
		case VOTE_KICK: {
			ClearChoise(client); // clear votes of players if kick or ban
			ClearVotesForClient(client, VOTE_KICK);
			
			LOGS_ENABLED {
				char auth[32];
				player_steam(client, auth, sizeof(auth));
				LogToFile(LogFilePath, "Player %N(%s) was kicked by voting. (Last voted player: %N)",  client, auth,last);
			}

			PushKickedPlayer(client);
		}
		case VOTE_MUTE: {
			ClearVotesForClient(client, VOTE_MUTE);

			LOGS_ENABLED {
				char auth[32];
				player_steam(client, auth, sizeof(auth));
				LogToFile(LogFilePath, "Player %N(%s) was muted by voting. (Last voted player: %N)",  client, auth,last);
			}

			if(is_sourcebanspp_comms) {
				char reasonstring[68];
				Format(reasonstring, sizeof(reasonstring), "Muted by Gamevoting (%N)", last);
				SourceComms_SetClientMute(client, true, CONVAR_MUTE_DURATION.IntValue, true, reasonstring);
				SourceComms_SetClientGag(client, true, CONVAR_MUTE_DURATION.IntValue, true, reasonstring);
			}
			else if(is_maadmin_comms) {
				char reasonstring[68];
				Format(reasonstring, sizeof(reasonstring), "Muted by Gamevoting (%N)", last);
				MASetClientMuteType(0, client, reasonstring, 5, CONVAR_MUTE_DURATION.IntValue);
				MASetClientMuteType(0, client, reasonstring, 6, CONVAR_MUTE_DURATION.IntValue);
			}
			else {
			 	ServerCommand("sm_silence #%d %d \"Muted by Gamevoting (%N)\"", GetClientUserId(client), CONVAR_MUTE_DURATION.IntValue, last);
			}
			

		}
	}
	
}

public int HasReason(int target) {
	char auth[32];
	player_steam(target, auth, sizeof(auth));
	for(int i =0 ; i <= MAXPLAYERS; i ++) {
		/*Find steamid in array*/
		/*VAR_IVOTEBAN g_VoteChoise[i].vbSteam*/
		if(StrEqual(VAR_IVOTEBAN,auth,true)) {
			if(g_VoteChoise[i].voteban_reason > 0) {
				return g_VoteChoise[i].voteban_reason;
			}
		}
	}
		
	return -1;
}
