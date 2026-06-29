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
#define PLUGIN_NAME				"Tick X Map Fix"
#define PLUGIN_TAG				"sm"
#define PLUGIN_PRINT_PREFIX		"[SM] "
#define PLUGIN_AUTHOR			"Chanz"
#define PLUGIN_DESCRIPTION		"This plugin fixes maps which are made only for tick 66 servers to work under tick 100 servers"
#define PLUGIN_VERSION 			"2.5.36"
#define PLUGIN_URL				"http://forums.alliedmods.net/showthread.php?p=1528146"

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
#define THINK_INTERVAL 10.5
#define TOP_PRE_TICKRATE_TEXT "Current Tickrate: "

/*****************************************************************


G L O B A L   V A R S


*****************************************************************/
//Use a good notation, constants for arrays, initialize everything that has nothing to do with clients!
//If you use something which requires client index init it within the function Client_InitVars (look below)
//Example: Bad: "decl servertime" Good: "new g_iServerTime = 0"
//Example client settings: Bad: "decl saveclientname[33][32] Good: "new g_szClientName[MAXPLAYERS+1][MAX_NAME_LENGTH];" -> later in Client_InitVars: GetClientName(client,g_szClientName,sizeof(g_szClientName));

//Cvars
new Handle:g_cvarDoors_Speed_Elevator 		= INVALID_HANDLE;
new Handle:g_cvarDoors_Speed 				= INVALID_HANDLE;
new Handle:g_cvarDoors_Speed_Prop 			= INVALID_HANDLE;

//RunTimeOptimizer
new Float:g_flPlugin_Doors_Speed_Elevator 	= -1.0;
new Float:g_flPlugin_Doors_Speed 			= -1.0;
new Float:g_flPlugin_Doors_Speed_Prop 		= -1.0;

//Doors
enum DoorsTypeTracked {
	
	DoorsTypeTracked_None = -1,
	DoorsTypeTracked_Func_Door = 0,
	DoorsTypeTracked_Func_Door_Rotating = 1,
	DoorsTypeTracked_Func_MoveLinear = 2,
	DoorsTypeTracked_Prop_Door = 3,
	DoorsTypeTracked_Prop_Door_Rotating = 4
	
};
new String:g_szDoors_Type_Tracked[][MAX_NAME_LENGTH] = {
	
	"func_door",
	"func_door_rotating",
	"func_movelinear",
	"prop_door",
	"prop_door_rotating"
};

enum DoorsData {
	
	DoorsTypeTracked:DoorsData_Type,
	Float:DoorsData_Speed,
	Float:DoorsData_BlockDamage,
	bool:DoorsData_ForceClose
}

new Float:g_ddDoors[2048][DoorsData];
new bool:g_bDoors_HasChangedValues = false;

//Clients
new bool:g_bShowTickRate[MAXPLAYERS+1] = {false,...};

/*****************************************************************


F O R W A R D   P U B L I C S


*****************************************************************/
public OnPluginStart() {
	
	//Init for smlib
	SMLib_OnPluginStart(PLUGIN_NAME,PLUGIN_TAG,PLUGIN_VERSION,PLUGIN_AUTHOR,PLUGIN_DESCRIPTION,PLUGIN_URL);
	
	//Translations (you should use it always when printing something to clients)
	//Always with plugin. as prefix, the short name and .phrases as postfix.
	//decl String:translationsName[PLATFORM_MAX_PATH];
	//Format(translationsName,sizeof(translationsName),"plugin.%s.phrases",g_sPlugin_Short_Name);
	//File_LoadTranslations(translationsName);
	
	//Command Hooks (AddCommandListener) (If the command already exists, like the command kill, then hook it!)
	
	
	//Register New Commands (RegConsoleCmd) (If the command doesn't exist, hook it here)
	
	
	//Register Admin Commands (RegAdminCmd)
	RegAdminCmd("sm_tickrate",Command_TickRate,ADMFLAG_BAN,"enables the target to see the current tickrate at top left corner");
	
	//Cvars: Create a global handle variable.
	//Example: g_cvarEnable = CreateConVarEx("enable","1","example ConVar");
	g_cvarDoors_Speed_Elevator 		= CreateConVarEx("doors_speed_elevator", 	"1.05", "Sets the speed of all func_door entities used as elevators on a map.\nEx: 1.05 means +5% speed", FCVAR_PLUGIN);
	g_cvarDoors_Speed 				= CreateConVarEx("doors_speed", 			"2.00", "Sets the speed of all func_door entities that are not elevators on a map.\nEx: 2.00 means +100% speed", FCVAR_PLUGIN);
	g_cvarDoors_Speed_Prop			= CreateConVarEx("doors_speed_prop", 		"2.00", "Sets the speed of all prop_door entities on a map.\nEx: 2.00 means +100% speed", FCVAR_PLUGIN);
	
	//Event Hooks
	HookEvent("round_start",Event_Round_Start,EventHookMode_Post);
	
	//Timer
	CreateTimer(THINK_INTERVAL,Timer_Think,INVALID_HANDLE,TIMER_REPEAT);
	
	//Auto Config (you should always use it)
	//Always with "plugin." prefix and the short name
	new tick = RoundToFloor(1.0/GetTickInterval());
	decl String:configName[MAX_PLUGIN_SHORTNAME_LENGTH+8];
	
	new String:path[PLATFORM_MAX_PATH];
	Format(path,sizeof(path),"cfg/sourcemod/plugin.%s",g_sPlugin_Short_Name);
	
	if(!DirExists(path)){
		
		//0775
		if(!CreateDirectory(path,
			FPERM_U_READ|	FPERM_U_WRITE|	FPERM_U_EXEC|
			FPERM_G_READ|	FPERM_G_WRITE|	FPERM_G_EXEC|
			FPERM_O_READ|					FPERM_O_EXEC
		)) {
			SetFailState("directory %s is missing and can't be created.",path);
		}
	}
	Format(configName,sizeof(configName),"plugin.%s/tickrate-%d",g_sPlugin_Short_Name,tick);
	AutoExecConfig(true,configName);
}

public OnPluginEnd(){
	
	if(g_bDoors_HasChangedValues){
		Door_ResetSettingsAll();
	}
}

public OnMapStart() {
	
	// hax against valvefail (thx psychonic for fix)
	if(GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE){
		SetConVarString(g_cvarVersion, PLUGIN_VERSION);
	}
	
	Door_ClearSettingsAll();
}

public OnConfigsExecuted(){
	
	//Set your ConVar runtime optimizers here
	//Example: g_iPlugin_Enable = GetConVarInt(g_cvarEnable);
	g_flPlugin_Doors_Speed_Elevator 	= GetConVarFloat(g_cvarDoors_Speed_Elevator);
	g_flPlugin_Doors_Speed 				= GetConVarFloat(g_cvarDoors_Speed);
	g_flPlugin_Doors_Speed_Prop 		= GetConVarFloat(g_cvarDoors_Speed_Prop);
	
	//Hook ConVar Change
	HookConVarChange(g_cvarEnable,					ConVarChange_Enable);
	HookConVarChange(g_cvarDoors_Speed_Elevator,	ConVarChange_Doors_Speed_Elevator);
	HookConVarChange(g_cvarDoors_Speed,				ConVarChange_Doors_Speed);
	HookConVarChange(g_cvarDoors_Speed_Prop,		ConVarChange_Doors_Speed_Prop);
	
	//Mind: this is only here for late load, since on map change or server start, there isn't any client.
	//Remove it if you don't need it.
	Client_InitializeAll();
	
	if(g_iPlugin_Enable != 0){
		
		Door_GetSettingsAll();
		Door_SetSettingsAll();
	}
}

public OnClientConnected(client){
	
	Client_Initialize(client);
}

public OnClientPostAdminCheck(client){
	
	Client_Initialize(client);
}

/****************************************************************


C A L L B A C K   F U N C T I O N S


****************************************************************/
/****************************************************************

C O N V A R C H A N G E S

****************************************************************/
public ConVarChange_Enable(Handle:cvar, const String:szOldVal[], const String:szNewVal[]){
	
	new oldVal = StringToInt(szOldVal);
	new newVal = StringToInt(szNewVal);
	
	if(oldVal == newVal){
		return;
	}
	
	if(g_bDoors_HasChangedValues) {
		
		Door_ResetSettingsAll();
	}
	
	if(newVal == 1){
		
		Door_ClearSettingsAll();
		Door_GetSettingsAll();
		Door_SetSettingsAll();
	}
}

public ConVarChange_Doors_Speed_Elevator(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Doors_Speed_Elevator = StringToFloat(newVal);
	
	if(g_iPlugin_Enable != 0){
		Door_SetSettingsAll();
	}
}

public ConVarChange_Doors_Speed(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Doors_Speed = StringToFloat(newVal);
	
	if(g_iPlugin_Enable != 0){
		Door_SetSettingsAll();
	}
}

public ConVarChange_Doors_Speed_Prop(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Doors_Speed_Prop = StringToFloat(newVal);
	
	if(g_iPlugin_Enable != 0){
		Door_SetSettingsAll();
	}
}

/****************************************************************

E V E N T S

****************************************************************/
public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(g_iPlugin_Enable != 0){
		
		Door_ClearSettingsAll();
		Door_GetSettingsAll();
		Door_SetSettingsAll();
	}
	return Plugin_Continue;
}
/****************************************************************

T I M E R

****************************************************************/
public Action:Timer_Think(Handle:timer){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	new Float:tickInterval = GetTickInterval();
	new Float:tickRate = -1.0;
	new color[3];
	new alpha = 235;
	
	if(0.0 < tickInterval){
		tickRate = 1.0/tickInterval;
		Color_GetByValueBorders(tickRate,color);
	}
	
	LOOP_CLIENTS(client,CLIENTFILTER_INGAMEAUTH){
		
		if(!g_bShowTickRate[client]){
			continue;
		}
		
		if(tickRate == -1.0){
			
			Client_PrintToTop(client,255,255,255,255,THINK_INTERVAL,"%sN/A",TOP_PRE_TICKRATE_TEXT);
			continue;
		}
		
		Client_PrintToTop(client,color[0],color[1],color[2],alpha,THINK_INTERVAL,"%s%f",TOP_PRE_TICKRATE_TEXT,tickRate,THINK_INTERVAL,GetTime());
	}
	
	return Plugin_Continue;
}

/****************************************************************

C O M M A N D S

****************************************************************/
public Action:Command_TickRate(client,args){
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	decl String:arg2[11];
	GetCmdArg(2, arg2, sizeof(arg2));
	new bool:newState = bool:StringToInt(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
	decl bool:tn_is_ml;
	
	new target_count = 0;
	
	if(args == 2){
		
		target_count = ProcessTargetString(
		target,
		client,
		target_list,
		sizeof(target_list),
		COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml
		);
		
		if (target_count <= 0) {
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	else if(args == 0){
		
		target_count=1;
		target_list[0] = client;
		newState = !g_bShowTickRate[client];
	}
	else {
		
		new String:command[64];
		GetCmdArg(0,command,sizeof(command));
		Client_Reply(client,"%sUsage: %s [<target> <0/1>]",PLUGIN_PRINT_PREFIX,command);
	}
	
	for (new i=0;i<target_count;i++) {
		
		g_bShowTickRate[target_list[i]] = newState;
		
		if(newState){
			
			Client_PrintToChat(target_list[i],true,"[%s] Live tickrate viewer enabled - refresh rate: %f seconds",PLUGIN_NAME,THINK_INTERVAL);
		}
		else {
			
			Client_PrintToChat(target_list[i],true,"[%s] Live tickrate viewer disabled",PLUGIN_NAME);
		}
	}
	
	if(target_count > 1){
		
		if(newState){
			
			Client_PrintToChat(client,true,"[%s] You've enabled tickrate viewer for %s which affected %d players.",PLUGIN_NAME,target,target_count);
		}
		else {
			
			Client_PrintToChat(client,true,"[%s] You've disabled tickrate viewer for %s which affected %d players.",PLUGIN_NAME,target,target_count);
		}
	}
	return Plugin_Handled;
}

/*****************************************************************


P L U G I N   F U N C T I O N S


*****************************************************************/

stock Color_GetByValueBorders(const Float:value, color[3], Float:redMark=0.0, Float:yellowMark=33.0, Float:greenMark=66.0, Float:blueMark=99.0){
	
	color[0] = Math_Clamp(-7.7272727*value+510,0,255);
	color[1] = Math_Clamp(-0.75*value+75,0,255);
	color[2] = Math_Clamp(7.5*value-495,0,255);
}

Door_SetSettingsAll(){
	
	g_bDoors_HasChangedValues = true;
	
	new countEnts=0;
	new entity = -1;
	
	for(new i=0;i<sizeof(g_szDoors_Type_Tracked);i++){
		
		while ((entity = FindEntityByClassname(entity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE){
			
			Door_SetSettings(entity);
			countEnts++;
		}
		
		entity = -1;
	}
	
	Server_PrintDebug("[%s] Affected %d doors",PLUGIN_NAME,countEnts);
}

Door_SetSettings(entity){
	
	if(g_ddDoors[entity][DoorsData_Type] == DoorsTypeTracked_None){
		return;
	}
	
	if(g_ddDoors[entity][DoorsData_Type] != DoorsTypeTracked_Func_MoveLinear) {
		
		Entity_SetForceClose(entity,false);
	}
	
	if(
		g_ddDoors[entity][DoorsData_Type] == DoorsTypeTracked_Prop_Door ||
		g_ddDoors[entity][DoorsData_Type] == DoorsTypeTracked_Prop_Door_Rotating
	) {
		
		Entity_SetSpeed(entity,g_ddDoors[entity][DoorsData_Speed]*g_flPlugin_Doors_Speed_Prop);
	}
	else {
		
		new Float:moveDir[3];
		Entity_GetMoveDirection(entity,moveDir);
		Entity_SetSpeed(entity,g_ddDoors[entity][DoorsData_Speed]*((moveDir[2] == 1.0) ? g_flPlugin_Doors_Speed_Elevator : g_flPlugin_Doors_Speed));
		
		Entity_SetBlockDamage(entity,0.0);
	}
}

Door_ResetSettingsAll(){
	
	new countEnts=0;
	new entity = -1;
	
	for(new i=0;i<sizeof(g_szDoors_Type_Tracked);i++){
		
		while ((entity = FindEntityByClassname(entity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE){
			
			Door_ResetSettings(entity);
			countEnts++;
		}
		
		entity = -1;
	}
	
	Server_PrintDebug("[%s] Affected %d doors",PLUGIN_NAME,countEnts);
}

Door_ResetSettings(entity){
	
	if(g_ddDoors[entity][DoorsData_Type] == DoorsTypeTracked_None){
		return;
	}
	
	if(g_ddDoors[entity][DoorsData_Type] != DoorsTypeTracked_Func_MoveLinear) {
		
		Entity_SetForceClose(entity,g_ddDoors[entity][DoorsData_ForceClose]);
	}
	
	if(
		g_ddDoors[entity][DoorsData_Type] != DoorsTypeTracked_Prop_Door &&
		g_ddDoors[entity][DoorsData_Type] != DoorsTypeTracked_Prop_Door_Rotating
	) {
		Entity_SetBlockDamage(entity,g_ddDoors[entity][DoorsData_BlockDamage]);
	}
	
	Entity_SetSpeed(entity,g_ddDoors[entity][DoorsData_Speed]);
}

Door_GetSettingsAll(){
	
	new countEnts=0;
	new entity = -1;
	
	for(new i=0;i<sizeof(g_szDoors_Type_Tracked);i++){
		
		while ((entity = FindEntityByClassname(entity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE){
			
			Door_GetSettings(entity,DoorsTypeTracked:i);
			countEnts++;
		}
		
		entity = -1;
	} 
}

Door_GetSettings(entity,DoorsTypeTracked:type){
	
	g_ddDoors[entity][DoorsData_Type] = type;
	
	if(g_ddDoors[entity][DoorsData_Type] != DoorsTypeTracked_Func_MoveLinear) {
		
		g_ddDoors[entity][DoorsData_ForceClose] = Entity_GetForceClose(entity);
	}
	
	if(
		g_ddDoors[entity][DoorsData_Type] != DoorsTypeTracked_Prop_Door &&
		g_ddDoors[entity][DoorsData_Type] != DoorsTypeTracked_Prop_Door_Rotating
	) {
		
		g_ddDoors[entity][DoorsData_BlockDamage] = Entity_GetBlockDamage(entity);
	}
	
	g_ddDoors[entity][DoorsData_Speed] = Entity_GetSpeed(entity);
}

Door_ClearSettingsAll(){
	
	g_bDoors_HasChangedValues = false;
	
	for(new i=0;i<sizeof(g_ddDoors);i++){
		
		g_ddDoors[i][DoorsData_Type] = DoorsTypeTracked_None;
		g_ddDoors[i][DoorsData_Speed] = 0.0;
		g_ddDoors[i][DoorsData_BlockDamage] = 0.0;
		g_ddDoors[i][DoorsData_ForceClose] = false;
	}
}


stock Client_InitializeAll(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_Initialize(client);
	}
}

stock Client_Initialize(client){
	
	//Variables
	Client_InitializeVariables(client);
	
	
	//Functions
	
	
	//Functions where the player needs to be in game
	if(!IsClientInGame(client)){
		return;
	}
}

stock Client_InitializeVariables(client){
	
	//Plugin Client Vars
	g_bShowTickRate[client] = false;
}


