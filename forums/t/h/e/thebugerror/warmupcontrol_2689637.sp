#include <sourcemod>
#include <geoip>
#include <cstrike>

//DEFINE MAX LETTERS COMMANDS CAN HAVE
#define MAX_COMMAND_CHAR 256	//MAX ALLOWED CHARACTERS FOR A CONSOLE COMMAND INPUT
#define BYPASS "\"bypass\""		//BYPASS ARGUMENT USED TO PASS THRU ALIAS EVENT FUNCTIONS
#define PLUGIN_VERSION "1.7"	//ACTUAL VERSION OF THIS PLUGIN




//PLUGIN INFO
public Plugin myinfo = 
{
	name = "Automatic Warm Up Control mechanism", 
	author = "Ruza", 
	description = "Holds Warm Up until 2 players has joined the match", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/undefined-player/"
}




/*---------------------------------------------*
 *                                             *
 *                EXTENDED HOOK                *
 *                                             *
 *---------------------------------------------*/
enum struct EHook{
	ConVarChanged cbHookChange;
	bool hasHookChange;
	bool hasHookChangeInit;
	
	void UnHookChange(ConVar commandCvar){
		if(this.hasHookChange){
			UnhookConVarChange(commandCvar, this.cbHookChange);
			this.hasHookChange = false;
		}
	}
	void SetHookChange(ConVar commandCvar, ConVarChanged cbHookChange){
		this.UnHookChange(commandCvar);
		HookConVarChange(commandCvar, cbHookChange);
		this.cbHookChange = cbHookChange;
		this.hasHookChange = true;
		this.hasHookChangeInit = true;
	}
	void ReHookChange(ConVar commandCvar){
		if(this.hasHookChangeInit && !this.hasHookChange){
			HookConVarChange(commandCvar, this.cbHookChange);
			this.hasHookChange = true;
		}
	}
}
/*---------------------------------------------*
 *                                             *
 *          EXTENDED CONVAR DATA TYPE          *
 *                                             *
 *---------------------------------------------*/
enum struct EConVar{
	ConVar commandCvar;						//Command convar data if present
	char commandName[MAX_COMMAND_CHAR];		//Command Name
	char commandValueDef[MAX_COMMAND_CHAR];	//Original Command Value if present
	int flagsValueDef;						//Original Command Flags
	bool isSetup;							//EConVar ran setup
	bool isInit;							//EConVar was initialized
	EHook hookChange;						//Hook to change ConVar value event
	
	
	void Init(char[] commandName){
		if(this.isInit){
			this.Default();
		}
		this.isInit = true;
		strcopy(this.commandName, MAX_COMMAND_CHAR, commandName);
		this.commandCvar = FindConVar(this.commandName);
		this.Setup();
	}
	void Notify(bool notify = true){
		if(this.isInit){
			if(!this.isSetup){
				this.Setup();
			}
			if(notify){
				SetCommandFlags(this.commandName, GetCommandFlags(this.commandName)|FCVAR_NOTIFY);
			}else{
				SetCommandFlags(this.commandName, GetCommandFlags(this.commandName)&(~FCVAR_NOTIFY));
			}
		}
	}
	void Cheat(bool cheat = true){
		if(this.isInit){
			if(!this.isSetup){
				this.Setup();
			}
			if(cheat){
				SetCommandFlags(this.commandName, GetCommandFlags(this.commandName)|FCVAR_CHEAT);
			}else{
				SetCommandFlags(this.commandName, GetCommandFlags(this.commandName)&(~FCVAR_CHEAT));
			}
		}
	}
	void Setup(){
		if(this.isInit){
			this.isSetup = true;
			if(this.commandCvar != null){
				this.commandCvar.GetString(this.commandValueDef, MAX_COMMAND_CHAR);
			}else{
				this.commandValueDef[0] = '\0';
			}
			this.flagsValueDef = GetCommandFlags(this.commandName);
		}
	}
	void Default(bool notify = false){
		if(this.isInit && this.isSetup){
			this.Notify(notify);
			this.Cheat(false);
			if(this.commandCvar){
				this.hookChange.UnHookChange(this.commandCvar);
				SetConVarString(this.commandCvar, this.commandValueDef[0] ? this.commandValueDef  : "\"\"");
				this.hookChange.ReHookChange(this.commandCvar);
			}else{
				ServerCommand("%s", this.commandName);
			}
			SetCommandFlags(this.commandName, this.flagsValueDef);
			this.isSetup = false;
		}
	}
	void Execute(char[] commandValue, bool cheat = false, bool notify = false){
		if(this.isInit){
			if(!this.isSetup){
				this.Setup();
			}
			this.Notify(notify);
			this.Cheat(false);
			if(this.commandCvar){
				this.hookChange.UnHookChange(this.commandCvar);
				SetConVarString(this.commandCvar, commandValue[0] ? commandValue  : "\"\"");
				this.hookChange.ReHookChange(this.commandCvar);
			}else{
				ServerCommand("%s %s", this.commandName, commandValue[0] ? commandValue  : "\"\"");
			}
			this.Cheat(cheat);
		}
	}
	void HookChange(ConVarChanged callback){
		if(this.isInit && this.commandCvar){
			this.hookChange.SetHookChange(this.commandCvar, callback);
		}
	}
}







/*----------------------------------------------------------------------------------------------------------------------------------------------------------------*
 *        ###############################################################################################################################################         *
 *----------------------------------------------------------------------------------------------------------------------------------------------------------------*/







/*---------------------------------------------*
 *                                             *
 *               GLOBAL VARIABLES              *
 *                                             *
 *---------------------------------------------*/
//WARMUP
// - WARMUP EXTENDED CONVARS
EConVar mp_do_warmup_period;
EConVar mp_warmuptime;
EConVar mp_warmup_pausetimer;
EConVar mp_warmup_start;
// - WARMUP VARIABLES
// - - WARMUP VARIABLES FUNCTIONAL
int NUM_PLAYERS_REQUIRED;
int JOINED_SPECTATOR;
int JOINED_TERRORIST;
int JOINED_COUNTERTERRORIST;
int JOINED_GAME_PLAY;
bool isWarmupOn;
bool isWarmupForced;
bool isWinPanelOn;
// - WARMUP TRAINING
// - - WARMUP TRAINING EXTENDED CONVARS
EConVar ammo_grenade_limit_flashbang;
EConVar ammo_grenade_limit_total;
EConVar sv_infinite_ammo;
EConVar mp_buy_anywhere;
EConVar mp_buytime;
EConVar mp_death_drop_grenade;
EConVar mp_death_drop_gun;
EConVar mp_maxmoney;
EConVar mp_playercashawards;
EConVar mp_startmoney;
EConVar mp_teamcashawards;
EConVar mp_t_default_grenades;
EConVar mp_t_default_secondary;
EConVar mp_ct_default_grenades;
EConVar mp_ct_default_secondary;





/*---------------------------------------------*
 *                                             *
 *             MAIN LOGIC OF PLUGIN            *
 *                                             *
 *---------------------------------------------*/
//WHEN SOMEONE REUPLOADS OR REMOVE THIS PLUGIN AND THIS
//ONE NEEDS TO BE ENDED THEN CLEAN OUR HANDS TO LOOK NICE
public void OnPluginEnd(){
	ammo_grenade_limit_flashbang.Default();
	ammo_grenade_limit_total.Default();
	sv_infinite_ammo.Default();
	mp_buy_anywhere.Default();
	mp_buytime.Default();
	mp_death_drop_grenade.Default();
	mp_death_drop_gun.Default();
	mp_maxmoney.Default();
	mp_playercashawards.Default();
	mp_startmoney.Default();
	mp_teamcashawards.Default();
	mp_t_default_grenades.Default();
	mp_t_default_secondary.Default();
	mp_ct_default_grenades.Default();
	mp_ct_default_secondary.Default();
	mp_warmup_pausetimer.Default();
	mp_do_warmup_period.Default();
	mp_warmuptime.Default();
}
//WHEN PLUGIN STARTS (PREPARE PLUGIN)
public void OnPluginStart()
{
	//WARMPUP
	// - WARMUP INITIALIZE EConVars
	mp_do_warmup_period.Init("mp_do_warmup_period");
	mp_warmuptime.Init("mp_warmuptime");
	mp_warmup_pausetimer.Init("mp_warmup_pausetimer");
	mp_warmup_start.Init("mp_warmup_start");
	// - WARMUP VARIABLES
	// - - WARMUP VARIABLES FUNCTIONAL Set
	NUM_PLAYERS_REQUIRED = 2;
	isWarmupOn = false;
	isWarmupForced = false;
	isWinPanelOn = false;
	// - WARMUP TRAINING
	// - - WARMUP TRAINING INITIALIZE EConVars
	ammo_grenade_limit_flashbang.Init("ammo_grenade_limit_flashbang");
	ammo_grenade_limit_total.Init("ammo_grenade_limit_total");
	sv_infinite_ammo.Init("sv_infinite_ammo");
	mp_buy_anywhere.Init("mp_buy_anywhere");
	mp_buytime.Init("mp_buytime");
	mp_death_drop_grenade.Init("mp_death_drop_grenade");
	mp_death_drop_gun.Init("mp_death_drop_gun");
	mp_maxmoney.Init("mp_maxmoney");
	mp_playercashawards.Init("mp_playercashawards");
	mp_startmoney.Init("mp_startmoney");
	mp_teamcashawards.Init("mp_teamcashawards");
	mp_t_default_grenades.Init("mp_t_default_grenades");
	mp_t_default_secondary.Init("mp_t_default_secondary");
	mp_ct_default_grenades.Init("mp_ct_default_grenades");
	mp_ct_default_secondary.Init("mp_ct_default_secondary");
	// - WARMUP BOOT
	CreateTimer(0.5, decideWarmup); //Recheck Warmup conditions
	
	
	//HOOK EVENTS
	HookEvent("player_connect", playerConnected, EventHookMode_Post);		//Player has connected
	HookEvent("player_disconnect", playerDisconnected, EventHookMode_Post);	//Player has disconnected
	HookEvent("player_team", playerChoseTeam, EventHookMode_Post);			//Player chose team
	HookEvent("cs_win_panel_match", winPanel, EventHookMode_Pre);			//Win panel pops up at end of the match
	HookEvent("cs_match_end_restart", matchEndRestart, EventHookMode_Post);	//Match resets to same map
	//MAKE ADMIN COMMANDS
	RegAdminCmd("sm_warmup_debug", sm_warmup_debug, ADMFLAG_KICK, "Displays debug information.");
	RegAdminCmd("sm_warmup_start", sm_warmup_start, ADMFLAG_KICK, "Forces infinite WarmUp start.");
	RegAdminCmd("sm_warmup_end", sm_warmup_end, ADMFLAG_KICK, "Forces infinite WarmUp end.");
	RegAdminCmd("sm_warmup_toggle", sm_warmup_toggle, ADMFLAG_KICK, "Toggles infinite WarmUp.");
	RegAdminCmd("sm_warmup_check", sm_warmup_check, ADMFLAG_KICK, "Checks conditions for WarmUp are met and then decides to run WarmUp.");
	RegAdminCmd("sm_warmup_version", sm_warmup_version, ADMFLAG_KICK, "Shows actual version of Automatic WarmUp control plugin.");
	//HOOKING SERVER COMMANDS
	mp_do_warmup_period.HookChange(alias_mp_do_warmup_period);				//Remapping command mp_do_warmup_period
	mp_warmup_pausetimer.HookChange(alias_mp_warmup_pausetimer);			//Remapping command mp_warmup_pausetimer
	AddCommandListener(alias_mp_warmup_start, "mp_warmup_start");			//Remapping command mp_warmup_start
	AddCommandListener(alias_mp_warmup_end, "mp_warmup_end");				//Remapping command mp_warmup_end
	AddCommandListener(alias_endround, "endround");							//Remapping command endround
}
//WHEN MAP LOADS (MAINLY WHEN MAP CHANGES NORMALLY)
public void OnMapStart(){
	isWinPanelOn = false;			//Win panel is not present anymore
	isWarmupForced = false;			//Disables forced Warmup
	CreateTimer(0.5, decideWarmup); //Recheck Warmup conditions
}
//WHEN MAP LOADED AND CONFIGS EXECUTED (FIXES FORCE MAP CHANGE)
public void OnConfigsExecuted(){
	isWinPanelOn = false;			//Win panel is not present anymore
	isWarmupForced = false;			//Disables forced Warmup
	CreateTimer(0.5, decideWarmup); //Recheck Warmup conditions
}




/*---------------------------------------------*
 *                                             *
 *                EVENT FUNCTIONS              *
 *                                             *
 *---------------------------------------------*/
//PLAYER HAS CONNECTED TO THE GAME
public void playerConnected(Event event, const char[] name, bool dontBroadcast){
	CreateTimer(0.5, decideWarmup); //Recheck Warmup conditions
}
//PLAYER HAS DISCONNECTED FROM THE GAME
public void playerDisconnected(Event event, const char[] name, bool dontBroadcast){
	CreateTimer(0.5, decideWarmup); //Recheck Warmup conditions
}
//PLAYER CHOSE TEAM
public void playerChoseTeam(Event event, const char[] name, bool dontBroadcast){
	CreateTimer(0.5, decideWarmup); //Recheck Warmup conditions
}
//WHEN END MATCH WIN PANEL POPS UP (DONT DO WARMUP OTHERWISE GAME STUCKS)
public void winPanel(Event event, const char[] name, bool dontBroadcast){
	isWinPanelOn = true;			//Dont do Warmup at all otherwise match stucks in scoreboard
}
//WHEN MATCH ENDS AND RESETS TO SAME MAP INSTEAD OF A FRESH LOAD
public void matchEndRestart(Event event, const char[] name, bool dontBroadcast){
	isWinPanelOn = false;			//Win panel is not present anymore
	isWarmupForced = false;			//Disables forced Warmup
	CreateTimer(0.5, decideWarmup);	//Recheck Warmup conditions
}


//WHEN SOMEONE ATTEMPTS TO CHANGE MP_WARMUP_PERIOD COMMAND VALUE
//WHILE WARMUP THEN MOVE IT BACK TO WARMUP VALUE AND DONT DO ANYTHING
public void alias_mp_do_warmup_period(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(isWarmupOn && mp_do_warmup_period.commandCvar.IntValue != 1){
		mp_do_warmup_period.Execute("1");
	}
}
//WHEN SOMEONE ATTEMPTS TO CHANGE MP_WARMUP_PAUSETIMER COMMAND VALUE
//WHILE WARMUP THEN MOVE IT BACK TO WARMUP VALUE AND DONT DO ANYTHING
public void alias_mp_warmup_pausetimer(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(isWarmupOn && mp_warmup_pausetimer.commandCvar.IntValue != 1){
		mp_warmup_pausetimer.Execute("1");
	}
}
//WHEN SOMEONE USES MP_WARMUP_START COMMAND THEN STARTS OUR WARMUP
//CAN BE ACTIVATED BY USING \"bypass\"
public Action alias_mp_warmup_start(int client, const char[] command, int argc){
	char arg[MAX_COMMAND_CHAR];
	GetCmdArgString(arg, MAX_COMMAND_CHAR);
	if(!StrEqual(arg, BYPASS)){
		isWarmupForced = true;		//Warmup has been forced
		doWarmupStart();
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
//WHEN SOMEONE USES MP_WARMUP_END COMMAND THEN ENDS OUR WARMUP
//CAN BE ACTIVATED BY USING \"bypass\"
public Action alias_mp_warmup_end(int client, const char[] command, int argc){
	char arg[MAX_COMMAND_CHAR];
	GetCmdArgString(arg, MAX_COMMAND_CHAR);
	if(!StrEqual(arg, BYPASS)){
		isWarmupForced = false;		//Disables forced Warmup
		doWarmupEnd();
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
//DISABLING ENDROUND COMMAND WHILE WARMUP IS ON (TO PREVENT
//UNDESIRABLE RESPAWNING), CAN BE ACTIVATED BY USING \"bypass\"
//OTHER PLUGINS SHOULD CHECK IF WARMUP IS RUNNING TO NOT ABUSE
//THIS COMMAND
public Action alias_endround(int client, const char[] command, int argc){
	char arg[MAX_COMMAND_CHAR];
	GetCmdArgString(arg, MAX_COMMAND_CHAR);
	if(isWarmupOn && !StrEqual(arg, BYPASS)){
		return Plugin_Handled;
	}
	return Plugin_Continue;
}




/*---------------------------------------------*
 *                                             *
 *             DECIDE FOR WARMPUP              *
 *                                             *
 *---------------------------------------------*/
 public Action decideWarmup(Handle timer){
	//RESET VARIABLES
	JOINED_SPECTATOR = 0;
	JOINED_TERRORIST = 0;
	JOINED_COUNTERTERRORIST = 0;
	JOINED_GAME_PLAY = 0;
	//LOOP THRU ALL POSSIBLE CLIENTS
	for(int c = 1; c <= MaxClients; c++){
		//IF CLIENT IS CONNECTED AND IS IN THE GAME COLLECT THEIR TEAM INFO
		if(IsClientConnected(c) && IsClientInGame(c)){
			switch(GetClientTeam(c)){
				case CS_TEAM_SPECTATOR:{
					JOINED_SPECTATOR++;			//Player is as Spectator
				}
				case CS_TEAM_T:{
					JOINED_TERRORIST++;			//Player is as Terrorist
				}
				case CS_TEAM_CT:{
					JOINED_COUNTERTERRORIST++;	//Player is as CounterTerrorist
				}
			}
		}
	}
	//SUM PLAYERS JOINED IN THE MATCH
	JOINED_GAME_PLAY = JOINED_TERRORIST + JOINED_COUNTERTERRORIST;
	//IF SERVER IS ABANDONED DISABLE FORCED WARMUP
	if(JOINED_GAME_PLAY == 0 && JOINED_SPECTATOR == 0){
		isWarmupForced = false;		//Disables froced Warmup
	}
	//IF THERE ARE NOT ENOUGHT OF PLAYERS JOINED THE MATCH DO WARMUP OR
	//IF THERE ARE NO PLAYERS JOINED THE MATCH AND THERE ARE SPECTATORS
	//DO WARMUP OTHERWISE END WARMUP
	if((JOINED_GAME_PLAY > 0 && JOINED_GAME_PLAY < NUM_PLAYERS_REQUIRED) || (JOINED_GAME_PLAY == 0 && JOINED_SPECTATOR != 0)){
		doWarmupStart();			//Starts Warmup
	}else{
		doWarmupEnd();				//Ends Warmup
	}
 }




/*---------------------------------------------*
 *                                             *
 *              DO WARMUP COMMANDS             *
 *                                             *
 *---------------------------------------------*/
//WARMUP
// - WARMUP START
public void doWarmupStart(){
	//IF WARMUP IS NOT ON AND WIN PANEL IS NOT SHOWING
	//THEN IT IS ALLOWED TO DO WARMUP
	if(!isWarmupOn && !isWinPanelOn){
		isWarmupOn = true;		//Warmup is set on
		//WARMUP TRAINING
		// - COMMANDS SET NEW VALUES SILENTLY
		ammo_grenade_limit_flashbang.Execute("1");
		ammo_grenade_limit_total.Execute("5");
		sv_infinite_ammo.Execute("2");
		mp_buy_anywhere.Execute("1");
		mp_buytime.Execute("3600");
		mp_death_drop_grenade.Execute("0");
		mp_death_drop_gun.Execute("0");
		mp_maxmoney.Execute("65535");
		mp_playercashawards.Execute("1");
		mp_startmoney.Execute("65535");
		mp_teamcashawards.Execute("1");
		mp_t_default_grenades.Execute("weapon_molotov weapon_hegrenade weapon_flashbang weapon_decoy weapon_smokegrenade");
		mp_t_default_secondary.Execute("");
		mp_ct_default_grenades.Execute("weapon_incgrenade weapon_hegrenade weapon_flashbang weapon_decoy weapon_smokegrenade");
		mp_ct_default_secondary.Execute("");
		//WARMUP
		// - COMMANDS SET NEW VALUES SILENTLY
		mp_warmup_pausetimer.Execute("1");
		mp_do_warmup_period.Execute("1");
		mp_warmuptime.Execute("15");
		mp_warmup_start.Execute(BYPASS);
	}
}
// - WARMUP END
public void doWarmupEnd(){
	//IF WARMUP IS ON AND WIN PANEL IS NOT SHOWING
	//AND WARMUP WAS NOT FORCED THEN IT IS ALLOWED
	//TO END WARMUP
	if(isWarmupOn && !isWinPanelOn && !isWarmupForced){
		isWarmupOn = false;			//Warmup is set off
		//WARMUP TRAINING
		// - COMMANDS RETURN ORIGINAL VALUES SILENTLY
		ammo_grenade_limit_flashbang.Default();
		ammo_grenade_limit_total.Default();
		sv_infinite_ammo.Default();
		mp_buy_anywhere.Default();
		mp_buytime.Default();
		mp_death_drop_grenade.Default();
		mp_death_drop_gun.Default();
		mp_maxmoney.Default();
		mp_playercashawards.Default();
		mp_startmoney.Default();
		mp_teamcashawards.Default();
		mp_t_default_grenades.Default();
		mp_t_default_secondary.Default();
		mp_ct_default_grenades.Default();
		mp_ct_default_secondary.Default();
		//WARMUP
		// - COMMANDS SET NEW VALUES SILENTLY
		mp_warmup_pausetimer.Execute("0");
	}
}




/*---------------------------------------------*
 *                                             *
 *               CONSOLE COMMANDS              *
 *                                             *
 *---------------------------------------------*/
public Action sm_warmup_debug(int client, int args){
	PrintToConsole(client, "[WARMUP CONTROL DEBUG]");
	PrintToConsole(client, " - isWinPnl: %s", isWinPanelOn ? "true" : "false");
	PrintToConsole(client, " - isWmpFrc: %s", isWarmupForced ? "true" : "false");
	PrintToConsole(client, " - isWarmup: %s", isWarmupOn ? "true" : "false");
	PrintToConsole(client, " - Required: %d", NUM_PLAYERS_REQUIRED);
	PrintToConsole(client, " - - %d :: Joined Spec", JOINED_SPECTATOR);
	PrintToConsole(client, " - - %d :: Joined T", JOINED_TERRORIST);
	PrintToConsole(client, " - - %d :: Joined CT", JOINED_COUNTERTERRORIST);
	PrintToConsole(client, " - - %d :: Joined Play", JOINED_GAME_PLAY);
}
public Action sm_warmup_start(int client, int args){
	PrintToConsole(client, "[WARMUP CONTROL START]");
	PrintToConsole(client, "%s", isWarmupOn ? " - Warmup is already running" : " - Starting Warmup");
	isWarmupForced = true;		//Warmup has been forced
	doWarmupStart();
}
public Action sm_warmup_end(int client, int args){
	PrintToConsole(client, "[WARMUP CONTROL END]");
	PrintToConsole(client, "%s", isWarmupOn ? " - Ending Warmup" : " - Warmup is not running");
	isWarmupForced = false;		//Disables forced Warmup
	doWarmupEnd();
}
public Action sm_warmup_toggle(int client, int args){
	if(!isWarmupOn){
		sm_warmup_start(client, args);
	}else{
		sm_warmup_end(client, args);
	}
}
public Action sm_warmup_check(int client, int args){
	PrintToConsole(client, "[WARMUP CONTROL CHECK]");
	isWarmupForced = false;		//Disables forced Warmup
	decideWarmup(null);
	PrintToConsole(client, "%s", isWarmupOn ? " - Warmup was started" : " - Warmup was ended");
}
public Action sm_warmup_version(int client, int args){
	PrintToConsole(client, "[WARMUP CONTROL VERSION]");
	PrintToConsole(client, " - Version %s", PLUGIN_VERSION);
}