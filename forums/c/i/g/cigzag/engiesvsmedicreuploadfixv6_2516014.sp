#include<sourcemod>
#include<sdktools>
#include<tf2>
#include<tf2_stocks> 
#include<clients>
#include<morecolors>

int DiedYet[64]; //this array stores wether a player is in the game and wether a player is in blue or red team
int GameStarted=0; //this int stores the amount of time the game has been started, resets when the game ends.
bool IsSettingTeam = false; //this bool switches to false when balancing teams so that the player death trackers doesn't messes up
bool ZombieStarted = false; //This variable is set to true after some time after round start to prevent victory from triggering too soon
ConVar zve_setup_time = null;
bool WaitingEnded = false;
new Handle:global_handleStoreMyTimer;
new Handle:global_handleStoreMyTimer2;

/* HOW THIS PLUGIN WORKS:
 *	Basically, it keeps track of wether a player has died or not during a game (in the DiedYet array)
 *	when a player is connected it has its DiedYet value set to -1 if the game has started, 1 else.
 *	when a player dies, it has its DiedYet value set to -1 too.
 *  if a player has its DiedYet value set to -1, it will spawn as a blue medic
 * 	if a player has its DiedYet value set to 1, it will spawn as a red engineer.
 *	Any sentry will instantly be destroyed and blue medics can only use melee weapons.
 */ 

public Plugin myinfo ={
	name = "Engineers Vs Zombies v1.2wfv",
	author = "shewowkees, edited by weird fox",
	description = "zombie like gamemode",
	version = "1.1.1",
	url = "noSiteYet"
};

public void OnPluginStart(){
	PrintToServer("Engies vs Medics V1.1 by shewowkees and edited by weirdfox, inspired by Muselk.");
	HookEvent("player_spawn",Event_PlayerSpawnChangeClass,EventHookMode_Post);
	HookEvent("player_spawn",Event_PlayerSpawnChangeTeam,EventHookMode_Pre);
	HookEvent("player_death",Event_PlayerDeath,EventHookMode_Post);
	HookEvent("tf_game_over",Event_TFGameOver,EventHookMode_Post);
	HookEvent("player_regenerate",Event_PlayerRegenerate,EventHookMode_Post);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_TeamPlayRoundWin);
	HookEvent("teamplay_waiting_begins",Event_WaitingBegins,EventHookMode_Post);
	HookEvent("player_disconnect",Event_PlayerDisconnect,EventHookMode_Post);
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_ChangeClass, "joinclass");
	AddCommandListener(CommandListener_ChangeTeam, "jointeam");
	AddCommandListener(CommandListener_Kill, "kill");
	AddCommandListener(CommandListener_Kill, "explode");
	//CONVARS
	
	zve_setup_time = CreateConVar("zve_setup_time", "30.0", "Default setup time");
	AutoExecConfig(true, "plugin_zve");
}
/*
 * This method disables respawn times and prevents teams auto balance.
 * It also makes the server ban the idle players immediatly, only switching
 *	them to spectator mode would cause the plugin to misbehave.
 *
 */
public OnMapStart(){ 
	function_ResetPlugin();
	ServerCommand("mp_disable_respawn_times 1"); 
	ServerCommand("mp_teams_unbalance_limit 30"); 
	ServerCommand("mp_idledealmethod 2");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_idlemaxtime 10");
	ServerCommand("mp_waitingforplayers_time 35");
	WaitingEnded = false;
	
	
}
// public OnEventShutdown()
// {
	// UnHookEvent("player_spawn",Event_PlayerSpawnChangeClass);
	// UnHookEvent("player_spawn",Event_PlayerSpawnChangeTeam);
	// UnHookEvent("player_death",Event_PlayerDeath);
	// UnHookEvent("tf_game_over",Event_TFGameOver);
	// UnHookEvent("player_regenerate",Event_PlayerRegenerate);
	// UnHookEvent("teamplay_round_start", Event_RoundStart);
	// UnHookEvent("teamplay_waiting_begins",Event_WaitingBegins);
	// UnHookEvent("player_disconnect",Event_PlayerDisconnect);
// }
/*
 * This method initializes DiedYet of the connecting client to the right value.
 */
public void OnClientPostAdminCheck(int client){
	if(ZombieStarted){
		DiedYet[client]=-1;
	}else{
		DiedYet[client]=1;
	}
		
}

public void OnGameFrame(){
	new edict_index = FindEntityByClassname(-1, "tf_dropped_weapon");
	if (edict_index != -1){
		
		AcceptEntityInput(edict_index, "Kill");
		
	}
	edict_index = FindEntityByClassname(-1, "tf_ammo_pack");
	if (edict_index != -1){
		
		AcceptEntityInput(edict_index, "Kill");
		
	}
}

public void TF2_OnWaitingForPlayersEnd(){
	
	WaitingEnded = true;
	
}



//EVENTS




//PLAYER RELATED EVENTS

/*
 * This code is from Tsunami's TF2 build restrictions. It prevents engineers
 * from even placing a sentry.
 *
 */
public Action:CommandListener_Build(client, const String:command[], argc)
{

	// Get arguments
	decl String:sObjectType[256]
	GetCmdArg(1, sObjectType, sizeof(sObjectType));
	
	// Get object mode, type and client's team
			new iObjectType = StringToInt(sObjectType),
			iTeam       = GetClientTeam(client);
	
	// If invalid object type passed, or client is not on Blu or Red
	if(iObjectType < TFObject_Dispenser || iObjectType > TFObject_Sentry || iTeam < TFTeam_Red){
		
		return Plugin_Continue;
	}
	
	//Blocks sentry building
	else if(iObjectType==TFObject_Sentry){
		CPrintToChat(client, "\x05\x01 {red}You can't build sentries in this gamemode!");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:CommandListener_ChangeTeam(client, const String:command[],argc){
	decl String:arg1[256]
	GetCmdArg(1, arg1, sizeof(arg1));
	if(strcmp(arg1,"blue",false)==0 && DiedYet[client] == -1){
		
		return Plugin_Continue;
		
	}else if(DiedYet[client]==-1){
		
		ClientCommand(client,"jointeam blue");
		
	}
	if(strcmp(arg1,"red",false)==0 && DiedYet[client]== 1){
		
		return Plugin_Continue;
		
	}else if(DiedYet[client]==1){
		
		ClientCommand(client,"jointeam red");
		
	}
	CPrintToChat(client, "\x05\x01 {red}You can't betray your team in this gamemode!");
	return Plugin_Handled;
	// decl String:arg1[256]
	// GetCmdArgString(arg1, sizeof(arg1));
	// CPrintToChatAll(arg1);
	// return Plugin_Continue;
	
}

public Action:CommandListener_ChangeClass(client,const String:command[], argc){
	decl String:arg1[256]
	GetCmdArg(1, arg1, sizeof(arg1));
	if(strcmp(arg1,"medic",false)==0 && DiedYet[client] == -1){
		
		return Plugin_Continue;
		
	}else if(DiedYet[client]==-1){
		
		ClientCommand(client,"joinclass medic");
		
	}
	if(strcmp(arg1,"engineer",false)==0 && DiedYet[client]== 1){
		
		return Plugin_Continue;
		
	}else if(DiedYet[client]==1){
		
		ClientCommand(client,"joinclass engineer");
		
	}
	CPrintToChat(client, "\x05\x01 {red}You can't change your class in this gamemode!");
	return Plugin_Handled;
	// decl String:arg1[256]
	// GetCmdArgString(arg1, sizeof(arg1));
	// CPrintToChatAll(arg1);
	// return Plugin_Continue;
}

public Action:CommandListener_Kill(client, const String:command[], argc){
	CPrintToChat(client, "\x05\x01 {red}You can't kill yourself in this gamemode!");
	return Plugin_Handled;
	
}

 /*
 * This method forces the spawning player to switch to the right team BEFORE he appears
 */
 public Action:Event_PlayerSpawnChangeTeam(Event event, const char[] name, bool dontBroadcast){
	 
	 int client = GetClientOfUserId(event.GetInt("userid"));
	if(DiedYet[client]==-1){ //if client is supposed to be a blue medic
	
		TF2_ChangeClientTeam(client, TFTeam_Blue); //Always put him to team blue
				
	}else if(DiedYet[client]==1){ //if the client is supposed to be a red engineer.
		
		if( TF2_GetClientTeam(client)==TFTeam_Blue ){
			//if the client chooses blue team from the beginning, puts his DiedYet value to -1 
			TF2_ChangeClientTeam(client, TFTeam_Red);
			DiedYet[client]=-1;

			
		}
		
	}
 }
 /*
 * This method forces the player to be on the right team, the right class and to use the right weapons.
 */
public Action:Event_PlayerSpawnChangeClass(Event event, const char[] name, bool dontBroadcast){

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(DiedYet[client]==0){
		
		if(GameStarted>0){
			DiedYet[client]=-1;
		}else{
			DiedYet[client]=1;
		}
		
	}
	if(DiedYet[client]==-1 || DiedYet[client]==0){ //if client is supposed to be a blue medic
	
		
		if( TF2_GetPlayerClass(client) != TFClass_Medic){ //if he isn't a medic, changes his class,  him and makes him respawn.
			CPrintToChat(client,"\x05\x01 {red}As a zombie, you can only be medic!");
			TF2_SetPlayerClass(client, TFClass_Medic, true, true);
			TF2_RespawnPlayer(client);
		}
		
		
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary); //Could be replaced by melee mode but too lazy.
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
		
	}else if(DiedYet[client]==1){ //if the client is supposed to be a red engineer.
		
		
			if( TF2_GetPlayerClass(client) != TFClass_Engineer){ //if the client isn't an engineer, changes his class, kills him and makes him respawn
				CPrintToChat(client,"\x05\x01 {red}As a human, You can only be engineer!");
				TF2_SetPlayerClass(client, TFClass_Engineer, true, true);
				DiedYet[client]=1; //sets the diedyet value to 1 because the suicide would set it to -1
				TF2_RespawnPlayer(client);
			}
		

	}
	function_CheckVictory();
}
/*
 * This method updates the DiedValue of a player if needed,changes his team and checks for victory
 */
public Action:Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)//On player death, sets his DiedYet value to -1
{ 
	
    if (GetPlayerCount() == 1)
    {
        for(new i = 1; i <= MaxClients; i++)
        {
            if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
            {
                CPrintToChatAll("{red}%N is getting an boost!", i);
                ServerCommand("sm_givew_ex @red 8001");
                ServerCommand("sm_givew @red 8001");
            }
        }
    }
 
	if(WaitingEnded && ZombieStarted && !IsSettingTeam){
	
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(GameStarted>0)
		{
			CPrintToChat(client,"\x05\x01 {grey}You have been infected, you can't become a human again!");
			DiedYet[client] = -1;
			TF2_ChangeClientTeam(client,TFTeam_Blue);
			TF2_SetPlayerClass(client, TFClass_Medic, true, true);
			
		}
		function_CheckVictory();
	
	
	}
}





/*
 *The role of this method is to prevent blue team from getting back their full 
 *equipment after regenerating (from the locker) .
 */
public Action:Event_PlayerRegenerate(Event event, const char[] name, bool dontBroadcast){ 
	
	for(int i=0;i<64;i++){
		if( DiedYet[i]==-1 ){
				
				TF2_RemoveWeaponSlot(i, TFWeaponSlot_Primary);
				TF2_RemoveWeaponSlot(i, TFWeaponSlot_Secondary);
				
		}
	}
}


/*
 * This method resets a player's DiedYet value when he disconnects.
 */
public Action:Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast){
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	DiedYet[client] = 0;
	function_CheckVictory();
	
	
	
	
}

//ROUND RELATED EVENTS


/*
 * This functions decrements GameStarted because it will be incremented when the waiting begins
 */
public Action:Event_WaitingBegins(Event event, const char[] name, bool dontBroadcast){
	GameStarted=-1;
}
/*
 * This method deletes all unwanted elements from the map and balances the teams
 */
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	function_PrepareMap();
	function_ResetTeams(true);
	CreateTimer(2.30,Stun);
	GameStarted++;
	ServerCommand("sm_resetex @all");
	CPrintToChatAll("\x05\x01 {grey}This server is running Zombies Vs Engineers V1.1 by shewowkees");
	CPrintToChatAll("\x05\x01 {grey}The goal for humans (red team) is to survive untill the time runs out!");
	CPrintToChatAll("\x05\x01 {grey}The goal for zombies (blue team) is to kill all the humans before the time runs out!");
	CPrintToChatAll("\x05\x01 {grey}This plugin can be downloaded from sourcemod / allied modders.");
	CPrintToChatAll("{red}Do not steal this plugin and claim it as your own!");
	CPrintToChatAll("{red}The zombies are stuck in there cage, go hide before they escape!");
	ServerCommand("sm_settime 600");
	
    if(global_handleStoreMyTimer != INVALID_HANDLE)
    {
        KillTimer(global_handleStoreMyTimer);
        global_handleStoreMyTimer = INVALID_HANDLE;
    }

    global_handleStoreMyTimer = CreateTimer(300.0, ZombieAbility);
    
    if(global_handleStoreMyTimer2 != INVALID_HANDLE)
    {
        KillTimer(global_handleStoreMyTimer2);
        global_handleStoreMyTimer2 = INVALID_HANDLE;
    }

    global_handleStoreMyTimer2 = CreateTimer(600.0, RoundEndAbility);
    
}

public Action Event_WaitingForPlayersBegin(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("sm_resetex @all");
}
public Action Event_TeamPlayRoundWin(Event event, const char[] name, bool dontBroadcast) 
{
	ServerCommand("sm_resetex @all");
	if(global_handleStoreMyTimer != INVALID_HANDLE)
    {
 
        KillTimer(global_handleStoreMyTimer);
        global_handleStoreMyTimer = INVALID_HANDLE;
    }
 
 
    if(global_handleStoreMyTimer2 != INVALID_HANDLE)
    {
 
        KillTimer(global_handleStoreMyTimer2);
        global_handleStoreMyTimer2 = INVALID_HANDLE;
    }
}

public Action RoundEndAbility(Handle timer)
{
	ServerCommand("sm_slay @red");
}

public Action ZombieAbility(Handle timer)
{
	CPrintToChatAll("\x05\x01 {red}Zombies have been given special abilities");
	ServerCommand("sm_giveweapon_ex @blue 8004");
	ServerCommand("sm_givew @blue 8004");
}

public Action:Event_TFGameOver(Event event, const char[] name, bool dontBroadcast){ //Once the game is over, resets the DiedYet values
	
	GameStarted = 0;
	function_AllEngineers(false);
}


//TIMERS


public Action Stun(Handle timer){
	function_StunTeam(TFTeam_Blue);
	if(WaitingEnded){
		CreateTimer(GetConVarFloat(zve_setup_time), Infection);
	}
	
	
}
public Action Infection(Handle timer){
	CPrintToChatAll("\x05\x01 {grey}Zombies have escaped, hide quickly!");
	ZombieStarted = true;
	function_DeleteDoors();
}


//FUNCTIONS



/*
 * This function deletes all element that can influence game winning from the map.
 * The game winngin elements part is from perky (hide n seek plugin).
 *
 * @param -
 * @return -
 */
public function_PrepareMap(){
	
	//code below is from Perky in Hide n seek plugin, it disables cp and ctf gamemodes.
	//following code disables cp and pl 
	new edict_index;
	new x = -1;
	for (new i = 0; i < 5; i++){
			edict_index = FindEntityByClassname(x, "trigger_capture_area"); //finds any capture area
			if (IsValidEntity(edict_index)){
				SetVariantInt(0); //Argument value is 0 if the input needs any
				AcceptEntityInput(edict_index, "SetTeam"); //set its team to 0
				AcceptEntityInput(edict_index, "Disable"); // Disables it
				x = edict_index;
			}
	}
	//following code disables flags
	x = -1;
	new flag_index;
	for (new i = 0; i < 5; i++){
		flag_index = FindEntityByClassname(x, "item_teamflag"); //finds flags
		if (IsValidEntity(flag_index)){
			AcceptEntityInput(flag_index, "Disable"); //disables them
			x = flag_index;
		}
	}
	
}
/*
 * This function deletes door and spawnroom things
 */
 public function_DeleteDoors(){//following code opens all doors. This part was made by myself
	 
	int x = -1
	new RespawnRoomIndex;
	bool HasFound = true;
	
	while(HasFound){
	
		RespawnRoomIndex = FindEntityByClassname (x, "func_door"); //finds doors
		
		if(RespawnRoomIndex==-1){//breaks the loop if no matching entity has been found
			
			HasFound=false;
			
		}else{
		
			if (IsValidEntity(RespawnRoomIndex)){
				AcceptEntityInput(RespawnRoomIndex,"Open");
				AcceptEntityInput(RespawnRoomIndex, "Kill"); //Deletes the door it.
				x = RespawnRoomIndex;
				
			}
		
		}
		
	}
	//following code disables respawnroom player blocking. This part was made by myself
	x = -1
	new RespawnRoomBlockerIndex;
	HasFound = true;
	
	while(HasFound){
	
		RespawnRoomBlockerIndex = FindEntityByClassname (x, "func_respawnroomvisualizer"); //finds blockers
		
		if(RespawnRoomBlockerIndex==-1){//breaks the loop if no matching entity has been found
			
			HasFound=false;
			
		}else{
		
			if (IsValidEntity(RespawnRoomBlockerIndex)){
			
				AcceptEntityInput(RespawnRoomBlockerIndex, "Kill"); //Deletes the blocker
				x = RespawnRoomBlockerIndex;
				
			}
		
		}
		
	}
	 
 }
/*
 * This functions makes a team given in argument win.
 * The code is from perky, author of the hide n seek plugin
 * 
 * @param team		The TFTeam that will win.
 * @return -
 */
public function_teamWin(team) //code from hide n seek
{
		new edict_index = FindEntityByClassname(-1, "team_control_point_master");
			if (edict_index == -1)
			{
				new g_ctf = CreateEntityByName("team_control_point_master");
				DispatchSpawn(g_ctf);
				AcceptEntityInput(g_ctf, "Enable");
			}
			
			new search = FindEntityByClassname(-1, "team_control_point_master")
			SetVariantInt(team);
			AcceptEntityInput(search, "SetWinner");
				//AcceptEntityInput(search, "SetTeam");
				//AcceptEntityInput(search, "RoundWin");
				//AcceptEntityInput(search, "kill");
	
	
		
		
		
}
/*
 * This function computes the teams balance depending on the player counts and
 * puts them in the right team and if kills is true, it kills all the players. 
 *
 * @param kills		Wether the function should kill the players or not.
 * @return -
 *
 *
 */



public function_ResetTeams(bool kills){
	
	IsSettingTeam=true;
	function_AllEngineers(false);
	//following code counts the connected players
	int PlayerCount=0;
	for(int i=0;i<64;i++){
		
		if(DiedYet[i]!=0){
			
			PlayerCount++;
			
		}	
	
	}
	
	//following code will compute the needed starting blue Medics, depending on the player count.
	int StartingMedics = 0;
	if(PlayerCount > 1){ //if there is 2 or more players
	
		StartingMedics=1;
		
	}
	if(PlayerCount>5){
	
		StartingMedics=2;
		
	}
	if(PlayerCount >10){
	
		StartingMedics=3;
		
	}
	if(PlayerCount >18){
		
		StartingMedics=4;
	
	}
	
	//following code will make needed players start as medic
	while(StartingMedics>0){
		int i = GetRandomInt(0,63);
			if(DiedYet[i]==1){
				DiedYet[i]=-1;
				StartingMedics--;
			
			}
	}
	//Kills all the players
	if(kills){
		
		for(int i=0;i<64;i++){
		
		if(DiedYet[i]==-1){
			
			if(IsClientInGame(i)){
						ForcePlayerSuicide(i);
						TF2_RespawnPlayer(i);
			}
			
		}	
	
	}
		
	}
	
	IsSettingTeam=false;
	

}
/*
 * This function checks if victory conditions for blue team are met and 
 * triggers the victory and resets teams if needed.
 *
 * @param -
 * @return -
 *
 *
 */
public function_CheckVictory(){
		
		if(ZombieStarted==false){
			return;
		}
	
		bool AllEngineersDead = true;
		for(int i=0;i<64;i++){
			if(DiedYet[i]==1){
				
				AllEngineersDead=false;
			
			}
		
		}
		if(AllEngineersDead){
			function_teamWin(TFTeam_Blue);
			ZombieStarted=false;
		}
		
}
	
/*
 * This function puts all players to red engineers.
 *
 * @param kill 		if true, will kill the players and force their respawn.
 * @return -
 *
 *
 */
 public function_AllEngineers(bool kill){
	 for(int i=0;i<64;i++){
		if(DiedYet[i]!=0){
			DiedYet[i]=1;
			TF2_ChangeClientTeam(i, TFTeam_Red);
			if(kill==true){
				ForcePlayerSuicide(i);
				TF2_RespawnPlayer(i);
			}
			
		}
			
	}
	 
 }
 /* This function stuns all the players of a given team
  *
  */
  
  public function_StunTeam(int team){
	  float time = GetConVarFloat(zve_setup_time);
	  if(time>30.0){
		  time=30.0
	  }
	  int cmp=-10;
	  if(team==TFTeam_Blue){
		  cmp=-1;
	  }else if(team==TFTeam_Red){
		  cmp=1;
	  }
	  
	  for(int i=0;i<64;i++){
		  
		  if(DiedYet[i]==cmp){
			  TF2_StunPlayer(i, time, 0.0, TF_STUNFLAG_BONKSTUCK , 0);
		  }
		  
	  }
  }
  /*
   *This function resets every global scope variable
   */
  public function_ResetPlugin(){
	  int EmptyDiedYet[64];
	  DiedYet = EmptyDiedYet;
	  GameStarted=0; //this int stores the amount of time the game has been started, resets when the game ends.
	  IsSettingTeam = false; //this bool switches to false when balancing teams so that the player death trackers doesn't messes up
      ZombieStarted = false;
  }

GetPlayerCount()
{
    new players;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) >= 2)
        {
            players++;
        }
    }
    return players;
}

bool:IsValidClient(client, bool:bAllowBots = true)
{
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client))
    {
        return false;
    }
    return true;
}  



