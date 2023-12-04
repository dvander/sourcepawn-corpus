#pragma newdecls required

#include <sourcemod>
#include <cstrike>

char g_botName[512] = "Mara\x04Bot";
char g_ctName[128];
char g_tName[128];
char g_mapPool[9][128];
bool g_botActive = false;
bool g_knife = true;
bool g_knifedone = false;
bool g_overtime = true;
bool g_warmup = false;
bool g_ct_ready = false;
bool g_t_ready = false;
bool g_abort = false;
bool g_live = false;
bool g_paused = false;
bool g_ctRmvPause = false;
bool g_tRmvPause = false;
bool g_staySwitchDone = false;
bool g_printScore = false;
bool g_switcher = false;
int g_maxRounds = 30;
int g_otStartmoney = 10000;
int g_otRounds = 6;
int g_boX = 1;
int g_mapCount = 1;
int g_wonKnife = 0; // 2 for T, 3 for CT
int g_roundsstarted = 0;
int g_otswitcher = 0;
int g_mapWinner = 0;
int g_team1score = 0;
int g_team2score = 0;
Handle kv;
Handle Timer_warmupHandle = INVALID_HANDLE;
Handle Timer_CountdownHandle = INVALID_HANDLE;
Handle Timer_pauseHandle = INVALID_HANDLE;
Handle Timer_staySwitchHandle = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "MaraBot v1.2",
	author = "Luca Heft",
	description = "This Bot handles competitive Games",
	version = "1.2",
	url = "http://www.mara-esports.de/"
};

public void OnPluginStart(){

	kv = CreateKeyValues("config");
	HookEvent("round_start",Event_round_start);
	HookEvent("round_end",Event_round_end);
	HookEvent("cs_match_end_restart",Event_cs_match_end_restart);
	//initializes variables from config/MaraBot.cfg
	initVariables();
	
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs){

	//check if message is a command
	if(sArgs[0] == '!'){
		//check if client is admin, if no admin INVALID_ADMIN_ID is returned
		AdminId admin = GetUserAdmin(client);

		//Test MaraBot
		if (strcmp(sArgs, "!test", false) == 0){
			char msg[128];
			Format(msg,128,"%s \x01works!",g_botName);
			sayToChat(msg);
		}
		
		//print commands into clients console
		else if (strcmp(sArgs, "!commands", false) == 0){
			char t_clientName[128];
			GetClientName(client,t_clientName,128);
			char msg[128];
			Format(msg,128,"%s check your console for command help!",t_clientName);
			sayToChat(msg);
			PrintToConsole(client,"!test - test if bot is working");
			PrintToConsole(client,"!start (admin-only) - starts the bot");
			PrintToConsole(client,"!sleep (admin-only) - sets bot in sleep mode");
			PrintToConsole(client,"!knife (admin-only) - set knife round on/off");
			PrintToConsole(client,"!overtime (admin-only) - set overtime on/off");
			PrintToConsole(client,"!restart (admin-only) - restarts game (sets score to 0:0)");
			PrintToConsole(client,"!pause - pause game in next freezetime");
			PrintToConsole(client,"!unpause - unpause game");
			PrintToConsole(client,"!ready or !r - sets your team ready");
			PrintToConsole(client,"!unready - sets your team unready");
			PrintToConsole(client,"!settings - shows game settings in chat");
			PrintToConsole(client,"!stay - stay on your side after knife round");
			PrintToConsole(client,"!switch - switch side after knife round");
			PrintToConsole(client,"!abort - abort game start countdown");
			PrintToConsole(client,"!team1name (admin-only) - set name of team 1");
			PrintToConsole(client,"!team2name (admin-only) - set name of team 2");
		}
		
		//sets the bot active and starts the warmup of the game
		else if (StrContains(sArgs, "!start", false) == 0 && admin != INVALID_ADMIN_ID){
			
			g_botActive = true;
			g_warmup = true;
			
			setTeamNames();
			
			//reset variables just to be safe
			g_ct_ready = false;
			g_t_ready = false;
			g_mapCount = 1;
			g_knifedone = false;
			g_live = false;
			g_abort = false;
			g_staySwitchDone = false;
			g_paused = false;
			g_ctRmvPause = false;
			g_tRmvPause = false;
			g_roundsstarted = 0;
			g_otswitcher = 0;
			g_printScore = false;
			g_switcher = false;
			
			killAllTimers();
			
			//if !start has more than 7 characters get substring and load this map else exec warmup.cfg
			if(strlen(sArgs)>7){
				char msg[128];
				g_boX = ExplodeString(sArgs," ",g_mapPool,9,128) - 1;
				Format(msg,128,"Playing BO%d",g_boX);
				sayToChat(msg);
				for(int i=1;i<=g_boX;i++){
					Format(msg,128,"Map %d: %s",i,g_mapPool[i]);
					sayToChat(msg);
				}
				
				char t_currentMap[128];
				GetCurrentMap(t_currentMap,128);
				if(strcmp(t_currentMap,g_mapPool[1],false)){
					ServerCommand("changelevel %s", g_mapPool[1]);
					CreateTimer(5.0, delayWarmupcfg);
				} else {
					ServerCommand("exec MaraBotWarmup.cfg");
				}
			} else {
				char t_currentMap[128];
				GetCurrentMap(t_currentMap,128);
				g_boX = 1;
				g_mapPool[1] = t_currentMap;
				sayToChat("Playing BO1");
				char msg[128];
				Format(msg,128,"Map 1: %s",g_mapPool[1]);
				sayToChat(msg);
				
				ServerCommand("exec MaraBotWarmup.cfg");
			}
			Timer_warmupHandle = CreateTimer(10.0, Timer_warmup, _, TIMER_REPEAT);
		}
		
		//check if bot is active
		else if(g_botActive){
			//sets the bot to sleep
			if (strcmp(sArgs, "!sleep", false) == 0  && admin != INVALID_ADMIN_ID){
				g_botActive = false;
				killAllTimers();
				sayToChat("zzZZZZzzzzZZzzz");
			}
			
			//sets ready states and starts game if both teams ready
			else if ((strcmp(sArgs, "!ready", false) == 0 && Timer_warmupHandle != INVALID_HANDLE) || (strcmp(sArgs, "!r", false) == 0 && Timer_warmupHandle != INVALID_HANDLE)){
				int clientid = GetClientTeam(client); //2 T, 3 CT
				
				if(clientid == 2){
					g_t_ready = true;
					sayToChat("T side is now \x06ready\x01!")
				} else if (clientid == 3){
					g_ct_ready = true;
					sayToChat("CT side is now \x06ready\x01!")
				}
				
				//when both teams ready start game
				if(g_ct_ready && g_t_ready){
					killAllTimers();
					g_abort = false;
					Timer_CountdownHandle = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
				}
			}
			
			//sets unready states
			else if (strcmp(sArgs, "!unready", false) == 0 && Timer_warmupHandle != INVALID_HANDLE){
				int clientid = GetClientTeam(client); //2 T, 3 CT
				
				if(clientid == 2){
					g_t_ready = false;
					sayToChat("T side is now \x07unready\x01!")
				} else if (clientid == 3){
					g_ct_ready = false;
					sayToChat("CT side is now \x07unready\x01!")
				}
			}
			
			//abort countdown
			else if (strcmp(sArgs, "!abort", false) == 0 && Timer_CountdownHandle != INVALID_HANDLE){
				killAllTimers();
				Timer_warmupHandle = CreateTimer(10.0, Timer_warmup, _, TIMER_REPEAT);
				char msg[128];
				char t_clientName[128];
				GetClientName(client,t_clientName,128);
				Format(msg,128,"\x02Match aborted by %s.",t_clientName);
				sayToChat(msg);
				g_abort = true;
				
				if(GetClientTeam(client) == 2){
					g_t_ready = false;
				} else if (GetClientTeam(client) == 3){
					g_ct_ready = false;
				}
			}
			
			//pause match
			else if (strcmp(sArgs, "!pause", false) == 0 && g_live && !g_paused){
				g_paused = true;
				ServerCommand("mp_pause_match");
				Timer_pauseHandle = CreateTimer(5.0, Timer_pause, _, TIMER_REPEAT);
			}
			
			//unpause match
			else if (strcmp(sArgs, "!unpause", false) == 0 && g_paused){
				int teamid = GetClientTeam(client); //2 T, 3 CT
				
				if(teamid == 3){
					g_ctRmvPause = true;
				} else if(teamid == 2){
					g_tRmvPause = true;
				}
				
				if(g_ctRmvPause && g_tRmvPause){
					g_paused = false;
					g_ctRmvPause = false;
					g_tRmvPause = false;
					ServerCommand("mp_unpause_match");
				}
			}
			
			//restarts game
			else if (strcmp(sArgs, "!restart", false) == 0  && admin != INVALID_ADMIN_ID && g_live){
				killAllTimers();
				g_roundsstarted = 0;
				g_switcher = false;
				g_otswitcher = 0;
				sayToChat("Restarting Match...");
				ServerCommand("mp_restartgame 2");
			}
			
			//set kniferound on/off - write to config
			else if (StrContains(sArgs, "!knife", false) == 0  && admin != INVALID_ADMIN_ID && g_warmup){
				if(g_knife){
					g_knife = false;
					sayToChat("Knife Round: \x07off");
					
					//write to config
					KvSetNum(kv,"knife",0);
					char kv_file[512];
					BuildPath(Path_SM, kv_file, 512, "configs/MaraBot.cfg");
					KeyValuesToFile(kv,kv_file);
				} else {
					g_knife = true;
					sayToChat("Knife Round: \x06on");
					
					//write to config
					KvSetNum(kv,"knife",1);
					char kv_file[512];
					BuildPath(Path_SM, kv_file, 512, "configs/MaraBot.cfg");
					KeyValuesToFile(kv,kv_file);
				}
			}
			
			//set overtime on/off - write to config
			else if (StrContains(sArgs, "!overtime", false) == 0  && admin != INVALID_ADMIN_ID && g_warmup){
				if(g_overtime){
					g_overtime = false;
					sayToChat("Overtime: \x07off");
					
					//write to config
					KvSetNum(kv,"overtime",0);
					char kv_file[512];
					BuildPath(Path_SM, kv_file, 512, "configs/MaraBot.cfg");
					KeyValuesToFile(kv,kv_file);
				} else {
					g_overtime = true;
					sayToChat("Overtime: \x06on");
					
					//write to config
					KvSetNum(kv,"overtime",1);
					char kv_file[512];
					BuildPath(Path_SM, kv_file, 512, "configs/MaraBot.cfg");
					KeyValuesToFile(kv,kv_file);
				}
			}
			
			//show game settings
			else if (StrContains(sArgs, "!settings", false) == 0){
				
				char msg[128];
				char temp[128];
				
				//best of X
				Format(temp,128,"Best of [%d], ",g_boX);
				StrCat(msg,128,temp);
				
				//Overtime enabled? if yes show also overtime rounds
				if(g_overtime){
					Format(temp,128,"Overtime [\x06on\x01], Overtime rounds [%d], ",g_otRounds);
					StrCat(msg,128,temp);
				} else {
					StrCat(msg,128,"Overtime [\x07off\x01], ");
				}
				//knife round enabled?
				if(g_knife){
					StrCat(msg,128,"Knife round [\x06on\x01], ");
				} else {
					StrCat(msg,128,"Knife round [\x07off\x01], ");
				}
				
				sayToChat(msg);
			}
			
			//switch command
			else if (strcmp(sArgs, "!switch", false) == 0 && GetClientTeam(client) == g_wonKnife && Timer_staySwitchHandle != INVALID_HANDLE){
				g_staySwitchDone = true;
				ServerCommand("mp_swapteams");
				CreateTimer(1.0, Timer_startGame);
			}
			
			//stay command
			else if (strcmp(sArgs, "!stay", false) == 0 && GetClientTeam(client) == g_wonKnife && Timer_staySwitchHandle != INVALID_HANDLE){
				g_staySwitchDone = true;
				CreateTimer(1.0, Timer_startGame);
			}
			
			//set team1 name and write to config
			else if (StrContains(sArgs, "!team1name", false) == 0  && admin != INVALID_ADMIN_ID){
				char name[128];
				strcopy(name,128,sArgs[11]);
				g_ctName = name;
				ServerCommand("mp_teamname_1 %s",name);
				
				//write to config
				KvSetString(kv,"ct",name);
				char kv_file[512];
				BuildPath(Path_SM, kv_file, 512, "configs/MaraBot.cfg");
				KeyValuesToFile(kv,kv_file);
			}
			
			//set team2 name and write to config
			else if (StrContains(sArgs, "!team2name", false) == 0  && admin != INVALID_ADMIN_ID){
				char name[128];
				strcopy(name,128,sArgs[11]);
				g_tName = name;
				ServerCommand("mp_teamname_2 %s",name);
				
				KvSetString(kv,"t",name);
				char kv_file[512];
				BuildPath(Path_SM, kv_file, 512, "configs/MaraBot.cfg");
				KeyValuesToFile(kv,kv_file);
			}
		}
	}
}

//called when match ends
public Action Event_cs_match_end_restart(Handle event , const char[] name , bool dontBroadcast){

	g_botActive = true;
	g_warmup = true;
	
	setTeamNames();
	killAllTimers();
	
	//reset variables just to be safe
	g_ct_ready = false;
	g_t_ready = false;
	g_knifedone = false;
	g_live = false;
	g_abort = false;
	g_staySwitchDone = false;
	g_paused = false;
	g_ctRmvPause = false;
	g_tRmvPause = false;
	g_roundsstarted = 0;
	g_otswitcher = 0;
	g_printScore = false;
	g_switcher = false;
	ServerCommand("exec MaraBotWarmup.cfg");
	Timer_warmupHandle = CreateTimer(10.0, Timer_warmup, _, TIMER_REPEAT);
	
	//check for boX
	if(g_boX > 1){
		
		char msg[128];
		if(g_mapWinner == 1){
			g_team1score++;
			Format(msg,128,"\x04%s won %d. Map.",g_ctName,g_mapCount);
			sayToChat(msg);
		} else {
			g_team2score++;
			Format(msg,128,"\x04%s won %d. Map.",g_tName,g_mapCount);
			sayToChat(msg);
		}
		
		if(g_team1score > g_boX/2){
			Format(msg,128,"\x04%s won the best of %d.",g_ctName,g_boX);
			sayToChat(msg);
			g_team1score = 0;
			g_team2score = 0;
			g_boX = 1;
			g_mapCount = 1;
		} else if (g_team2score > g_boX/2){
			Format(msg,128,"\x04%s won the best of %d.",g_tName,g_boX);
			sayToChat(msg);
			g_team1score = 0;
			g_team2score = 0;
			g_boX = 1;
			g_mapCount = 1;
		} else if(g_team1score == g_boX/2 && g_mapCount == g_boX){
			Format(msg,128,"\x04After playing %d matches, the game resulted in a draw.",g_boX);
			sayToChat(msg);
			g_team1score = 0;
			g_team2score = 0;
			g_boX = 1;
			g_mapCount = 1;
		} else {
			sayToChat("Loading next map in 5 seconds...");
			CreateTimer(5.0, Timer_loadMap);
		}
		
	} else {
		char msg[128];
		g_team1score = 0;
		g_team2score = 0;
		if(g_mapWinner == 1){
			g_team1score++;
			Format(msg,128,"\x04%s won the match.",g_ctName);
			sayToChat(msg);
		} else {
			g_team2score++;
			Format(msg,128,"\x04%s won the match.",g_tName);
			sayToChat(msg);
		}
	}
}

//called when a round starts
public Action Event_round_start(Handle event , const char[] name, bool dontBroadcast){

	if(g_live){
		g_roundsstarted++;
		
		if(g_roundsstarted > g_maxRounds + g_otRounds/2){
			g_otswitcher++;
		}
		
		if(g_otswitcher > g_otRounds){
			g_otswitcher = 1;
			if(g_switcher){g_switcher = false;}
			else {g_switcher = true;}
		}
	}
}

//called when a round ends
public Action Event_round_end(Handle event, const char[] name, bool dontBroadcast){

	//print score to chat
	if(g_live && g_printScore){
	
		Handle CVarCTName;
		Handle CVarTName;
		char temp_team1name[128];
		char temp_team2name[128];
		
		//get Teamnames from CVar and set them temporarily
		CVarCTName = FindConVar("mp_teamname_1");
		CVarTName = FindConVar("mp_teamname_2");
		GetConVarString(CVarCTName, temp_team1name, 128);
		GetConVarString(CVarTName, temp_team2name, 128);
	
		CloseHandle(CVarCTName);
		CloseHandle(CVarTName);
		
		int t_score = CS_GetTeamScore(CS_TEAM_T);
		int ct_score = CS_GetTeamScore(CS_TEAM_CT);
		
		int t_winningTeam = GetEventInt(event, "winner");
		
		if((g_roundsstarted > g_maxRounds/2 && g_roundsstarted <= g_maxRounds + g_otRounds/2) || g_switcher){
			if(t_winningTeam == 2){
				g_mapWinner = 1;
			} else {
				g_mapWinner = 2;
			}
			char msg[128];
			Format(msg,128,"(%d) %s %d : %d %s (%d)",g_team2score,temp_team2name,ct_score,t_score,temp_team1name,g_team2score);
			sayToChat(msg);
		} else {
			if(t_winningTeam == 2){
				g_mapWinner = 2;
			} else {
				g_mapWinner = 1;
			}
			char msg[128];
			Format(msg,128,"(%d) %s %d : %d %s (%d)",g_team1score,temp_team1name,ct_score,t_score,temp_team2name,g_team2score);
			sayToChat(msg);
		}
	}
	
	if(g_knife){
		if(!g_knifedone && g_live){
			g_knifedone = true;
			sayToChat("Type \x06!stay\x01 or \x06!switch\x01 to decide your starting team.");
			Timer_staySwitchHandle = CreateTimer(5.0, Timer_staySwitch, _, TIMER_REPEAT);
			int t_winningTeam = GetEventInt(event, "winner");
			if(t_winningTeam == 2){
				g_wonKnife = 2;
			} else if (t_winningTeam == 3){
				g_wonKnife = 3;
			}
		}
	}
	
}

//starts the match
public void startGame(){
	g_live = true;
	g_warmup = false;
	ServerCommand("mp_warmup_end");
	
	if(g_knife){
		ServerCommand("exec MaraBotKnife.cfg");
		ServerCommand("mp_restartgame 2");
		CreateTimer(2.5, Timer_knifeMessage);
	} else {
		CreateTimer(0.1, Timer_startGame);
	}
}

//startGameTimer (first restart)
public Action Timer_startGame(Handle timer){
	setCVars();
	ServerCommand("exec MaraBotGame.cfg");
	ServerCommand("mp_restartgame 2");
	CreateTimer(3.0, Timer_secondRestart);
}

//second restart
public Action Timer_secondRestart(Handle timer){
	ServerCommand("mp_restartgame 2");
	g_roundsstarted = 0;
	g_switcher = false;
	g_otswitcher = 0;
	CreateTimer(2.5, Timer_liveMessage);
}

//print live to chat
public Action Timer_liveMessage(Handle timer){
	g_printScore = true;
	sayToChat("\x02live");
	sayToChat("\x02live");
	sayToChat("\x02live");
}

//print knife to chat
public Action Timer_knifeMessage(Handle timer){
	sayToChat("Knife round");
	sayToChat("Knife round");
	sayToChat("Knife round");
}

public Action Timer_staySwitch(Handle timer)
{
	if(g_staySwitchDone){
		Timer_staySwitchHandle = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	sayToChat("Type \x06!stay\x01 or \x06!switch\x01 to decide your starting team.");

	return Plugin_Continue;
}

//Countdown
public Action Timer_Countdown(Handle timer)
{
	static int numPrinted = 10;
	
	if(g_abort){
		numPrinted = 10;
		Timer_warmupHandle = CreateTimer(10.0, Timer_warmup, _, TIMER_REPEAT);
		Timer_CountdownHandle = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if (numPrinted < 1){
		numPrinted = 10;
		Timer_CountdownHandle = INVALID_HANDLE;
		startGame();
		return Plugin_Stop;
	}
	
	char msg[128];
	Format(msg,128,"Match will start in %d seconds. Type !abort to abort Countdown.",numPrinted);
	sayToChat(msg);
	
	numPrinted--;

	return Plugin_Continue;
}

public Action Timer_warmup(Handle timer)
{
	if(!g_warmup){
		Timer_warmupHandle = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	sayToChat("Type \x06!ready\x01 in order to start the game.");

	Handle CVarCTName;
	Handle CVarTName;
	char t_ctname[128];
	char t_tname[128];
	
	//get Teamnames from CVar and set them temporarily
	CVarCTName = FindConVar("mp_teamname_1");
	CVarTName = FindConVar("mp_teamname_2");
	GetConVarString(CVarCTName, t_ctname, 128);
	GetConVarString(CVarTName, t_tname, 128);
	
	CloseHandle(CVarCTName);
	CloseHandle(CVarTName);
	
	char msg[128] = "\x01";
	StrCat(msg,128,t_ctname);
	if(g_ct_ready){
		StrCat(msg,128," (\x04CT\x01) - ");
	} else {
		StrCat(msg,128," (\x07CT\x01) - ");
	}
	
	StrCat(msg,128,t_tname);
	
	if(g_t_ready){
		StrCat(msg,128," (\x04T\x01)");
	} else {
		StrCat(msg,128," (\x07T\x01)");
	}
	
	sayToChat(msg);
	
	return Plugin_Continue;
}

public Action Timer_pause(Handle timer)
{
	if(!g_paused){
		Timer_pauseHandle = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	Handle CVarCTName;
	Handle CVarTName;
	char temp_team1name[128];
	char temp_team2name[128];
	
	//get Teamnames from CVar and set them temporarily
	CVarCTName = FindConVar("mp_teamname_1");
	CVarTName = FindConVar("mp_teamname_2");
	GetConVarString(CVarCTName, temp_team1name, 128);
	GetConVarString(CVarTName, temp_team2name, 128);
	
	CloseHandle(CVarCTName);
	CloseHandle(CVarTName);
	
	char msg[128] = "\x01";
	
	if((g_roundsstarted > g_maxRounds/2 && g_roundsstarted <= g_maxRounds + g_otRounds/2) || g_switcher){
		StrCat(msg,128,temp_team2name);
	} else {
		StrCat(msg,128,temp_team1name);
	}
	
	if(g_ctRmvPause){
		StrCat(msg,128," (\x04CT\x01) - ");
	} else {
		StrCat(msg,128," (\x07CT\x01) - ");
	}
	
	if((g_roundsstarted > g_maxRounds/2 && g_roundsstarted <= g_maxRounds + g_otRounds/2) || g_switcher){
		StrCat(msg,128,temp_team1name);
	} else {
		StrCat(msg,128,temp_team2name);
	}
	
	if(g_tRmvPause){
		StrCat(msg,128," (\x04T\x01)");
	} else {
		StrCat(msg,128," (\x07T\x01)");
	}
	
	sayToChat("Type \x06!unpause\x01 to remove the pause.");
	sayToChat(msg);

	return Plugin_Continue;
}

//sends delayed message to allchat
public void sayToChat(char[] msg){
	Handle data = CreateDataPack();
	WritePackString(data, msg);
	CreateTimer(0.1, sayToChatTimer, data);
}

//adds botname to message and prints messages to chat with .1 second delay
public Action sayToChatTimer(Handle timer, Handle data){
	ResetPack(data,false);
	char msg[512];
	ReadPackString(data,msg,512);
	CloseHandle(data);
	Format(msg,512,"[%s\x01] %s",g_botName,msg);
	ReplaceString(msg,512,"{white}","\x01",false);
	ReplaceString(msg,512,"{darkred}","\x02",false);
	ReplaceString(msg,512,"{purple}","\x03",false);
	ReplaceString(msg,512,"{green}","\x04",false);
	ReplaceString(msg,512,"{lightgreen}","\x05",false);
	ReplaceString(msg,512,"{lemongreen}","\x06",false);
	ReplaceString(msg,512,"{red}","\x07",false);
	ReplaceString(msg,512,"{gray}","\x08",false);
	ReplaceString(msg,512,"{yellow}","\x09",false);
	ReplaceString(msg,512,"{grayblue}","\x0A",false);
	ReplaceString(msg,512,"{lightblue}","\x0B",false);
	ReplaceString(msg,512,"{blue}","\x0C",false);
	ReplaceString(msg,512,"{pink}","\x0E",false);
	ReplaceString(msg,512,"{lightred}","\x0F",false);
	ReplaceString(msg,512,"{orange}","\x10",false);
	PrintToChatAll(msg);
}

//loads next map when playing a boX
public Action Timer_loadMap(Handle timer){
	g_mapCount++;
	ServerCommand("changelevel %s",g_mapPool[g_mapCount]);
}

//initalizes variables from config/MaraBot.cfg
public void initVariables(){
	
	char kv_file[512];
	BuildPath(Path_SM, kv_file, 512, "configs/MaraBot.cfg");
	if(FileToKeyValues(kv,kv_file)){

		char value[128];
		char value2[512];

		//get BotName
		KvGetString(kv, "botName", value2, 512);
		if(!(value2[0] == EOS)){
			g_botName = value2;
			value2[0] = EOS;
		}

		//get CT Name
		KvGetString(kv, "ct", value, 128);
		if(!(value[0] == EOS)){
			g_ctName = value;
			value[0] = EOS;
		}

		//get T Name
		KvGetString(kv, "t", value, 128);
		if(!(value[0] == EOS)){
			g_tName = value;
			value[0] = EOS;
		}

		//get knife round
		if(KvGetNum(kv, "knife") == 0){
			g_knife = false;
		} else {
			g_knife = true;
		}

		//get overtime
		if(KvGetNum(kv, "overtime") == 0){
			g_overtime = false;
		} else {
			g_overtime = true;
		}

		//get maxRounds
		if(KvGetNum(kv, "maxRounds") > 0){
			g_maxRounds = KvGetNum(kv, "maxRounds");
		}

		//get overtime startmoney
		if(KvGetNum(kv, "ot_startmoney") > 0){
			g_otStartmoney = KvGetNum(kv, "ot_startmoney");
		}

		//get overtime rounds
		if(KvGetNum(kv, "ot_rounds") > 0){
			g_otRounds = KvGetNum(kv, "ot_rounds");
		}
	}
}

//set teamnames
public void setTeamNames(){
	ServerCommand("mp_teamname_1 %s",g_ctName);
	ServerCommand("mp_teamname_2 %s",g_tName);
}

//kills all timers to prevent more of one kind
public Action killAllTimers(){
	//kill warmup timer if it exist
	if(Timer_warmupHandle != INVALID_HANDLE){
		KillTimer(Timer_warmupHandle);
		Timer_warmupHandle = INVALID_HANDLE;
	}
	//kill countdown timer if it exist
	if(Timer_CountdownHandle != INVALID_HANDLE){
		KillTimer(Timer_CountdownHandle);
		Timer_CountdownHandle = INVALID_HANDLE;
	}
	//kill stayswitch timer if it exist
	if(Timer_staySwitchHandle != INVALID_HANDLE){
		KillTimer(Timer_staySwitchHandle);
		Timer_staySwitchHandle = INVALID_HANDLE;
	}
	
	if(Timer_pauseHandle != INVALID_HANDLE){
		KillTimer(Timer_pauseHandle);
		Timer_pauseHandle = INVALID_HANDLE;
		g_paused = false;
		g_ctRmvPause = false;
		g_tRmvPause = false;
		ServerCommand("mp_unpause_match");
	}
}

//delays execution of MaraBotWarmup.cfg so new map can load
public Action delayWarmupcfg(Handle timer){
	ServerCommand("exec MaraBotWarmup.cfg");
}

//sets cvars
public Action setCVars(){
	
	//set maxRounds
	ServerCommand("mp_maxrounds %d",g_maxRounds);
	
	//set overtime
	if(g_overtime){
		ServerCommand("mp_overtime_enable 1");
	} else {
		ServerCommand("mp_overtime_enable 0");
	}
	
	//set overtime rounds
	ServerCommand("mp_overtime_maxrounds %d",g_otRounds);
	
	//set overtime money
	ServerCommand("mp_overtime_startmoney %d",g_otStartmoney);
}
