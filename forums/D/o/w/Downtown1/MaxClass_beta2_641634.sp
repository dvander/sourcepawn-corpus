#include <sourcemod>
#include <sdktools>

#define TF2_SCOUT 1
#define TF2_SNIPER 2
#define TF2_SOLDIER 3 
#define TF2_DEMOMAN 4
#define TF2_MEDIC 5
#define TF2_HEAVY 6
#define TF2_PYRO 7
#define TF2_SPY 8
#define TF2_ENG 9
#define PL_VERSION "3.1BETA.2"

#define DEBUG 0
//To change the flag, look at: http://docs.sourcemod.net/api/index.php?fastload=file&id=28& for the right values
#define TF2L_ADMIN_FLAG Admin_Cheats
#define CHECKFORADMIN 1

//1=count admins towards class limit, 0=admins will not count towards class limit
#define COUNTADMINS 1

public Plugin:myinfo = 
{
  name = "TF Max Players",
  author = "Nican132",
  description = "Set max players to each class",
  version = PL_VERSION,
  url = "http://sourcemod.net/"
};       

//[amount of players][team][class] max amount
new MaxClass[MAXPLAYERS][5][10];
//[team][class] count array
new CurrentCount[5][10];
new bool:isrunning;
new Handle:IsMaxPlayersOn;
new TF_classoffsets, maxents, ResourceEnt, maxplayers;

static String:ClassNames[10][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy Guy", "Pyro", "Spy", "Engineer" }
static String:TF_ClassNames[10][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavyweapons", "pyro", "spy", "engineer" }

public OnPluginStart(){
	CreateConVar("sm_tf_limitplayers", PL_VERSION, "TF2 max class", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	IsMaxPlayersOn = CreateConVar("sm_maxclass_allow","1","Enable/Disable max class blocking");

	HookEvent("player_changeclass", Playerchangeclass);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("teamplay_teambalanced_player", PlayerTeamBalanced);
	
	TF_classoffsets = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass");
	
	RegAdminCmd("sm_classlimit", Command_PrintTable, ADMFLAG_CUSTOM4, "Re-reads and prints the limits");
	//RegConsoleCmd("sm_classlimit", Command_PrintTable)
}


public OnMapStart(){
	maxplayers = GetMaxClients();
	maxents = GetMaxEntities();
	
	StartReadingFromTable();
}

public Action:PlayerTeamBalanced(Handle:event, const String:name[], bool:dontBroadcast){
	if(!isrunning)
		return;
		
	if(!GetConVarBool(IsMaxPlayersOn))
		return;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	#if CHECKFORADMIN == 1
    	if(CheckForAdmin( client )){
            return;
        }
    #endif
	
	new team = GetEventInt(event, "team");
	new class = TF_GetClass(client);
	new clientcount = GetClientCount(true);
	
  #if DEBUG == 1
    LogMessage("Teambalanced: %N", client)
  #endif
	
	if(MaxClass[clientcount][team][class] <= -1)
		return;
	
	if(team < 2 ||  team > 3)
		return;
		
	RecountClasses();
	
	if(CurrentCount[team][class] > MaxClass[clientcount][team][class]){
		PrintToChat(client, "\x04[MaxClass]\x01 There is a overflow of %s in your team.", ClassNames[class]);
		PrintToChat(client, "\x04[MaxClass]\x01 Please, choose another class.");
		
		//FakeClientCommand(client, "joinclass 0");
		SwitchClientClass(client, FindUnusedClass(team, clientcount));
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	if(!isrunning)
		return;
		
	if(!GetConVarBool(IsMaxPlayersOn))
		return;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
    #if CHECKFORADMIN == 1
    	if(CheckForAdmin( client )){
            return;
        }
    #endif
	
	new clientcount = GetClientCount(true);
	new class = TF_GetClass(client);
	new team = GetClientTeam(client);
	
	#if DEBUG == 1
    LogMessage("PlayerSpawn: %N", client)
  #endif
	
	if(class == 0)
		return;
	
	if(MaxClass[clientcount][team][class] <= -1)
		return;
		
	RecountClasses();
	
	if(CurrentCount[team][class] > MaxClass[clientcount][team][class]){
		PrintToChat(client, "\x04[MaxClass]\x01 There is a overflow of %s in your team.", ClassNames[class]);
		PrintToChat(client, "\x04[MaxClass]\x01 Please, choose another class.");
		
		//FakeClientCommand(client, "joinclass 0");
		SwitchClientClass(client, FindUnusedClass(team, clientcount));
	}
}

public Action:Playerchangeclass(Handle:event, const String:name[], bool:dontBroadcast){
	if(!isrunning)
		return;
		
	if(!GetConVarBool(IsMaxPlayersOn))
		return;
 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	#if CHECKFORADMIN == 1
    	if(CheckForAdmin( client )){
            return;
        }
    #endif
	
	new class = GetEventInt(event, "class");
	new oldclass = TF_GetClass(client);
	
	if(class == oldclass){ return; }
	
  #if DEBUG == 1
    LogMessage("ChangeClass: %N", client)
  #endif
	
	new team = GetClientTeam(client);
	new clientcount = GetClientCount(true);
	
	if(MaxClass[clientcount][team][class] <= -1)
		return;
	
	RecountClasses();
	
	if(CurrentCount[team][class] >= MaxClass[clientcount][team][class]){	 	
	 	if(MaxClass[clientcount][team][class] == 0)
			PrintToChat(client, "\x04[MaxClass]\x01 No %ss are allowed on your team now.", ClassNames[class]);
		else if(MaxClass[clientcount][team][class] == 1) 
			PrintToChat(client, "\x04[MaxClass]\x01 %s class is full. Only one %d is allowed in your team.", ClassNames[class], MaxClass[clientcount][team][class]);
		else
			PrintToChat(client, "\x04[MaxClass]\x01 %s class is full. Only %d %ss are allowed in your team.", ClassNames[class],  MaxClass[clientcount][team][class], ClassNames[class]);
		
		PrintToChat(client, "\x04[MaxClass]\x01 Please, go back and choose another class.");
		
		//If the user just connected to server, his class is 0, with is nothing, let's just pick a random class
		if(oldclass == 0){
			oldclass = FindUnusedClass(team, clientcount);
		}
		
		//Wth won't this work! gah! I alredy tried every possible way, with delay, CommandEx...
		//At least this will stop player from joing the class		
		//FakeClientCommand(client, "joinclass %d", oldclass);
		SwitchClientClass(client, oldclass);
	}
}

FindUnusedClass(team, clientcount){
	new i;
	for(i=1; i<=9; i++){
		if((MaxClass[clientcount][team][i] == -1) || (CurrentCount[team][i] < MaxClass[clientcount][team][i]) ){
			return i;
		}
	}
	return 0;
}

RecountClasses(){
	new i;
	for(i=0; i<=9; i++){
		//CurrentCount[1][i] = 0;
		CurrentCount[2][i] = 0;
		CurrentCount[3][i] = 0;
		//CurrentCount[4][i] = 0;
	}
	
	for(i=1; i<=maxplayers; i++){
	 	if(IsClientInGame(i)){
	 	    #if CHECKFORADMIN == 1 && COUNTADMINS == 0
            if(CheckForAdmin( i )){
                continue;
            }
            #endif
	 	 
			CurrentCount[ GetClientTeam(i) ][ TF_GetClass(i) ]++;
			
		}
	}
}

bool:StartReadingFromTable(){
	new String:file[256], String:mapname[32];
	
	BuildPath(Path_SM, file, sizeof(file),"configs/MaxClass.txt");
 
	if(!FileExists(file)){
		LogMessage("[MaxClass] Class manager is not running! Could not find file %s", file);
		isrunning= false;
		return false;
	}
	
 
	new Handle:kv = CreateKeyValues("MaxClassPlayers");
	FileToKeyValues(kv, file);
	
	//Get in the first sub-key, first look for the map, then look for default
	GetCurrentMap(mapname, sizeof(mapname));
	if (!KvJumpToKey(kv, mapname)){
		if (!KvJumpToKey(kv, "default")){
			LogMessage("[MaxClass] Class manager is not running! Could not find where to read from file");
			isrunning = false;
			return false;
		}		
	}
	
	//There is nothing else that can give errors, the pluggin in running!
	isrunning = true;
	
	new MaxPlayers[10], breakpoint, iStart, iEnd, i, a;
	decl String:buffer[64],String:start[32], String:end[32];
	new redblue[5];
	
	//Reset all numbers to -1
	for(i=0; i<10; i++){
		MaxPlayers[i] = -1;
	}
	for(i=0; i<=maxplayers; i++){
	 	for(a=1; a < 5; a++){
			MaxClass[i][a] = MaxPlayers;
		}
	}
	
		
	if (!KvGotoFirstSubKey(kv)){
	 	//If there is nothing in there, what there is to read?
		return true;
	}
	
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		
		//Collect all data
		MaxPlayers[TF2_SCOUT] =    KvGetNum(kv, "scout", -1);
		MaxPlayers[TF2_SNIPER] =   KvGetNum(kv, "sniper", -1);
		MaxPlayers[TF2_SOLDIER] =  KvGetNum(kv, "soldier", -1);
		MaxPlayers[TF2_DEMOMAN] =  KvGetNum(kv, "demoman", -1);
		MaxPlayers[TF2_MEDIC] =    KvGetNum(kv, "medic", -1);
		MaxPlayers[TF2_HEAVY] =    KvGetNum(kv, "heavy", -1);
		MaxPlayers[TF2_PYRO] =     KvGetNum(kv, "pyro", -1);
		MaxPlayers[TF2_SPY] =      KvGetNum(kv, "spy", -1);
		//God... I hate having bad english, fix it if it does not find
		MaxPlayers[TF2_ENG] =      KvGetNum(kv, "engenner", -1);
		if(MaxPlayers[TF2_ENG] == -1)
			MaxPlayers[TF2_ENG] =      KvGetNum(kv, "engineer", -1);
		
		//Why am I doing the 4 teams if there are only 2?
		redblue[2] =  KvGetNum(kv, "team2", 1);
		redblue[3] =  KvGetNum(kv, "team3", 1);
		
		if(redblue[2] == 1)
			redblue[2] =  KvGetNum(kv, "red", 1);
			
		if(redblue[3] == 1)
			redblue[3] =  KvGetNum(kv, "blue", 1);
		
		if((redblue[2] + redblue[3]) == 0)
			continue;
    
    	//Just 1 number
		if(StrContains(buffer,"-") == -1){	
			iStart = CheckBoundries(StringToInt(buffer));
    	 	
			for(a=0; a<= 4; a++){
				if(redblue[a] == 1)
					MaxClass[iStart][a] = MaxPlayers;			
			}
		//A range, like 1-5
		} else {
		 	//Break the "1-5" into "1" and "5"
			breakpoint=SplitString(buffer,"-",start,sizeof(buffer));
			strcopy(end,sizeof(end),buffer[breakpoint]);
			TrimString(start);
			TrimString(end);
	        
	        //make "1" and "5" into integers
	        //Check boundries, see if does not go out of the array limits
			iStart = CheckBoundries(StringToInt(start));
			iEnd = CheckBoundries(StringToInt(end))
	        
	        //Copy data to the global array for each one in the range
			for(i= iStart; i<= iEnd;i++){
			 	for(a=0; a<= 4; a++){
					if(redblue[a] == 1)
						MaxClass[i][a] = MaxPlayers;			
				}
			}
		}    
	} while (KvGotoNextKey(kv));
 
	CloseHandle(kv);
	
	ResourceEnt = FindResourceObject();
	if(ResourceEnt == -1){
		LogMessage("Attetion! Server could not find player data table");
		LogMessage("Stopping Class limit for the map");
		isrunning = false;
	}
	
	return false
}

CheckBoundries(i){
	if(i < 0)
		return 0;
	if(i > MAXPLAYERS)
		return MAXPLAYERS;
	return i;
}

public Action:Command_PrintTable(client, args){
	
	if (args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_classlimit <#team>");
		return Plugin_Handled;
	}
	
	decl String:teamstr[64];
	GetCmdArg(1, teamstr, sizeof(teamstr));
	new i, team = StringToInt(teamstr);
	
	StartReadingFromTable();
	
	if(team < 2 || team > 3){
		ReplyToCommand(client, "[SM] %d is not a valid team. 2=red and 3=blue.", team);
		return Plugin_Handled;
	}
 	
 	if(client == 0)
 		PrintToServer("Players Sco Sni Sol Dem Med Hea Pyr Spy Eng");
 	else	
 		PrintToConsole(client,"Players Sco Sni Sol Dem Med Hea Pyr Spy Eng");
 		
	for(i=1; i<= maxplayers; i++){
	 	if(client == 0)
 			PrintToServer("%d         %d   %d   %d   %d   %d   %d   %d   %d   %d", i, MaxClass[i][team][TF2_SCOUT], MaxClass[i][team][TF2_SNIPER],MaxClass[i][team][TF2_SOLDIER],MaxClass[i][team][TF2_DEMOMAN],MaxClass[i][team][TF2_MEDIC],MaxClass[i][team][TF2_HEAVY],MaxClass[i][team][TF2_PYRO],MaxClass[i][team][TF2_SPY],MaxClass[i][team][TF2_ENG]);		
		else
			PrintToConsole(client, "%d         %d   %d   %d   %d   %d   %d   %d   %d   %d", i, MaxClass[i][team][TF2_SCOUT], MaxClass[i][team][TF2_SNIPER],MaxClass[i][team][TF2_SOLDIER],MaxClass[i][team][TF2_DEMOMAN],MaxClass[i][team][TF2_MEDIC],MaxClass[i][team][TF2_HEAVY],MaxClass[i][team][TF2_PYRO],MaxClass[i][team][TF2_SPY],MaxClass[i][team][TF2_ENG]);
	}
	
	return Plugin_Handled;
}

stock FindResourceObject(){
	new i, String:classname[64];
	
	//Isen't there a easier way?
	//FindResourceObject does not work
	for(i = maxplayers; i <= maxents; i++){
	 	if(IsValidEntity(i)){
			GetEntityNetClass(i, classname, 64);
			if(StrEqual(classname, "CTFPlayerResource")){
			 		//LogMessage("Found CTFPlayerResource at %d", i)
					return i;
			}
		}
	}
	return -1;	
}

stock TF_GetClass(client){
	return GetEntData(ResourceEnt, TF_classoffsets + (client*4), 4);
}

stock SwitchClientClass(client, class){
  #if DEBUG == 1
    LogMessage("Changing class: %N ---- %d", client, class)
  #endif
	FakeClientCommand(client, "joinclass %s", TF_ClassNames[class]);
	FakeClientCommandEx(client, "joinclass %s", TF_ClassNames[class]); 
	
}


stock bool:CheckForAdmin( client ){
    if(client == 0){ return true; }
    
    new AdminId:adminid = GetUserAdmin(client);
    if(adminid == INVALID_ADMIN_ID)
        return false;

    return GetAdminFlag( adminid , TF2L_ADMIN_FLAG ) || GetAdminFlag( adminid , Admin_Root );
}
