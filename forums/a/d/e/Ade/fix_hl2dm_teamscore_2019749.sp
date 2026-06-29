/*****************************************************************


C O M P I L E   O P T I O N S


*****************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/*****************************************************************


P L U G I N   I N C L U D E S


*****************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>


/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
#define PLUGIN_NAME				"Fix HL2DM TeamScore"
#define PLUGIN_TAG				"sm"
#define PLUGIN_AUTHOR			"Chanz"
#define PLUGIN_DESCRIPTION		"Fixes the issue that the team score goes up by 1 point for every team kill."
#define PLUGIN_VERSION 			"2.1.4"
#define PLUGIN_URL				"http://forums.alliedmods.net/showthread.php?t=147988 OR http://www.mannisfunhouse.eu/"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/*****************************************************************


		P L U G I N   D E F I N E S


*****************************************************************/
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_BLUE		2
#define TEAM_RED		3


#define THINK_INTERVALL 0.2

/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/
//Use a good notation, constants for arrays, initialize everything that has nothing to do with clients!
//If you use something which requires client index init it within the function Client_InitVars (look below)
//Example: Bad: "decl servertime" Good: "new g_iServerTime = 0"
//Example client settings: Bad: "decl saveclientname[33][32] Good: "new g_szClientName[MAXPLAYERS+1][MAX_NAME_LENGTH];" -> later in Client_InitVars: GetClientName(client,g_szClientName,sizeof(g_szClientName));

//ConVars
new Handle:g_cvarTeamPlay = INVALID_HANDLE;
new Handle:g_cvarConnectSpectate = INVALID_HANDLE;

//ConVar Runtime Optimizer
new g_iPlugin_TeamPlay = -1;
new g_iPlugin_ConnectSpectate = -1;

/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/
public OnPluginStart() {
	
	//Init for smlib
	SMLib_OnPluginStart(PLUGIN_NAME,PLUGIN_TAG,PLUGIN_VERSION,PLUGIN_AUTHOR,PLUGIN_DESCRIPTION,PLUGIN_URL);
	
	decl String:gameFolder[PLATFORM_MAX_PATH];
	GetGameFolderName(gameFolder,sizeof(gameFolder));
	if(!StrEqual(gameFolder,"hl2mp",false)){
		SetFailState("this game/mod isn't hl2mp, so you probably don't need this plugin, but if you think you need this plugin for you game/mod contact %s on %s, and ask him to add it",PLUGIN_AUTHOR,PLUGIN_URL);
	}
	
	//Command Hooks (AddCommandListener) (If the command already exists, like the command kill, then hook it!)
	
	
	//Register New Commands (RegConsoleCmd) (If the command doesn't exist, hook it here)
	
	
	//Register Admin Commands (RegAdminCmd)
	
	
	//Cvars: Create a global handle variable (HookConVarChange is automatically added).
	//Example: g_cvarEnable = CreateConVarEx("enable","1","example ConVar");
	g_cvarTeamPlay = FindConVar("mp_teamplay");
	
	//Set your ConVar runtime optimizers here
	//Example: g_iPlugin_Enable = GetConVarInt(g_cvarEnable);
	g_iPlugin_TeamPlay = (g_cvarTeamPlay != INVALID_HANDLE) ? GetConVarInt(g_cvarTeamPlay) : -1;
	
	//ConVar Hooks
	
	//Event Hooks
	
	//Auto Config (you should always use it)
	//Always with "plugin." prefix and the short name
	decl String:configName[MAX_PLUGIN_SHORTNAME_LENGTH+8];
	Format(configName,sizeof(configName),"plugin.%s",g_sPlugin_Short_Name);
	AutoExecConfig(true,configName);
	
	//Timer
	CreateTimer(THINK_INTERVALL,Timer_Think,INVALID_HANDLE,TIMER_REPEAT);
}

public OnConfigsExecuted(){
	
	new Handle:plugin_ConnectSpectate = FindPluginByFile("connectspectate.smx");
	
	if(plugin_ConnectSpectate != INVALID_HANDLE){
		
		g_cvarConnectSpectate = FindConVar("connectspectate_enable");
		g_iPlugin_ConnectSpectate = (g_cvarConnectSpectate != INVALID_HANDLE) ? GetConVarInt(g_cvarConnectSpectate) : -1;
		HookConVarChange(g_cvarConnectSpectate,ConVarChange_ConnectSpectate);
	}
	else {
		
		g_iPlugin_ConnectSpectate = -1;
	}
}

public OnMapStart() {
	
	// hax against valvefail (thx psychonic for fix)
	if(GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE){
		SetConVarString(g_cvarVersion, PLUGIN_VERSION);
	}
	
	g_iPlugin_TeamPlay = (g_cvarTeamPlay != INVALID_HANDLE) ? GetConVarInt(g_cvarTeamPlay) : -1;
}


/****************************************************************


		C A L L B A C K   F U N C T I O N S


****************************************************************/
	
public ConVarChange_ConnectSpectate(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPlugin_ConnectSpectate = StringToInt(newVal);
}



public Action:Timer_Think(Handle:timer){
	
	
	/*new count_TeamManagers = 0;
	
	new maxEntities = GetMaxEntities();
	for (new entity=MaxClients+1; entity < maxEntities; entity++) {
		
		if (!IsValidEntity(entity)) {
			continue;
		}
		
		if (!Entity_ClassNameMatches(entity, "team_manager", true)) {
			continue;
		}
		
		count_TeamManagers++;
	}
	
	PrintToServer("countet team_manager's found: %d",count_TeamManagers);*/
	
	if(g_iPlugin_Enable < 1){
		return Plugin_Continue;
	}
	
	if(g_iPlugin_TeamPlay != 1){
		return Plugin_Continue;
	}
	
	/*if(g_iPlugin_RemovePoints == 0){
		Server_PrintDebug("cvar remove_teampoints is 0 -> plugin_continue");
		return Plugin_Continue;
	}
	
	if(g_iPlugin_FriendlyFire != 1){
		Server_PrintDebug("friendly fire not enabled -> plugin_continue");
		return Plugin_Continue;
	}*/
	
	//new clientTeam = GetClientTeam(client);
	//new attackerTeam = GetClientTeam(attacker);
	
	new teamScore[4] = {0,...};
	static oldClientTeam[MAXPLAYERS+1] = {-1,...};
	static bool:oldIsClientAlive[MAXPLAYERS+1] = {false,...};
	new clientTeam = -1;
	new bool:isClientAlive = false;
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		clientTeam = GetClientTeam(client);
		isClientAlive = IsPlayerAlive(client);
		
		if((oldClientTeam[client] != -1) && (oldClientTeam[client] != clientTeam) && g_iPlugin_ConnectSpectate != 1){
			
			if((clientTeam == TEAM_SPECTATOR) && !oldIsClientAlive[client] && !isClientAlive){
				
				PrintToServer("client %d his score -1 because he was dead and joined spectator.",client);
				Client_SetScore(client,Client_GetScore(client)-1);
				//Client_SetDeaths(client,Client_GetDeaths(client)+1);
			}
			
			if((clientTeam != TEAM_SPECTATOR) && oldIsClientAlive[client] && !isClientAlive){
				
				PrintToServer("client %d his score +1 because he was alive and changed team and not to spectator.",client);
				Client_SetScore(client,Client_GetScore(client)+1);
				Client_SetDeaths(client,Client_GetDeaths(client)-1);
			}
			
			if(clientTeam == TEAM_SPECTATOR && oldIsClientAlive[client] && !isClientAlive){
				
				PrintToServer("client %d his death score -1",client);
				Client_SetDeaths(client,Client_GetDeaths(client)-1);
			}
		}
		
		teamScore[clientTeam] += Client_GetScore(client);
		
		//PrintToChat(client,"your score: %d",Client_GetScore(client));
		
		oldClientTeam[client] = clientTeam;
		oldIsClientAlive[client] = isClientAlive;
	}
	
	//PrintToChatAll("blue: %d; red: %d",teamScore[TEAM_BLUE],teamScore[TEAM_RED]);
	
	if(!Team_SetScore(TEAM_RED,teamScore[TEAM_RED])){
		
		PrintToServer("can't set teamscore for red team");
	}
	if(!Team_SetScore(TEAM_BLUE,teamScore[TEAM_BLUE])){
		
		PrintToServer("can't set teamscore for blue team");
	}
	
	return Plugin_Continue;
}
/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/


