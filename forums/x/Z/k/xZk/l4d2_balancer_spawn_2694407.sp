#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define DEBUG						false

#define PLUGIN_NAME			        "[L4D2] Balancer Spawn Infected"
#define PLUGIN_AUTHOR		        "xZk"
#define PLUGIN_DESCRIPTION	        "Balances the spawn of Infected, depending on the number of Survivor players in game"
#define PLUGIN_VERSION		        "1.1.0"
#define PLUGIN_URL			        ""

#define DIRECTORSCRIPT_TYPE0		"DirectorScript.DirectorOptions"
#define DIRECTORSCRIPT_TYPE1		"DirectorScript.MapScript.LocalScript.DirectorOptions"

#define CFG_INFECTEDLIMIT "data/l4d2_balancer_spawn_infectedlimit.cfg"

enum SIClass
{
	SI_Smoker = 1,
	SI_Boomer,
	SI_Hunter,
	SI_Spitter,
	SI_Jockey,
	SI_Charger,
	SI_Witch,
	SI_Tank,
	SI_MAX_SIZE
}

char g_sInfectedLimit[9][]=
{
	"CommonLimit",
	"SmokerLimit",
	"BoomerLimit",
	"HunterLimit",
	"SpitterLimit",
	"JockeyLimit",
	"ChargerLimit",
	"WitchLimit",
	"TankLimit"
};

char sLimitBalancerType[][]=
{
	"base"    
	,"decrement"	
	,"increment"	
	,"minimun"	
    ,"maximun"	
};

ConVar cvarPluginEnable ,cvarBalancerMode ,cvarCheckMode ,cvarPlayersBase ,cvarLimitBase ,cvarLimitInc ,cvarLimitDec ,cvarLimitMin ,cvarLimitMax ,cvarIntervalBase ,cvarIntervalInc ,cvarIntervalDec ,cvarIntervalMin ,cvarIntervalMax;
bool g_bPluginEnable;
int g_iCheckMode;
int g_iBalancerMode;
int g_iPlayersBase;
int g_iLimitBase;
int g_iLimitDec;
int g_iLimitInc;
int g_iLimitMin;
int g_iLimitMax;
int g_iLimitBalancerType[9][5];

Handle g_hTimerCheck;
Handle g_hTimerBalancer;
char g_sDSType[64] = DIRECTORSCRIPT_TYPE0;
float g_fIntervalBase;
float g_fIntervalMin;
float g_fIntervalMax;
float g_fIntervalDec;
float g_fIntervalInc;
float g_fIntervalSpecial;
int g_iSurvivorsChecked = -1;
int g_iLimitMaxSpecial;
int g_iLimitInfected[9];
bool g_bLeft4DHooks;

native bool L4D_HasAnySurvivorLeftSafeArea();

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("L4D_HasAnySurvivorLeftSafeArea");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadInfectedLimit();
	
	cvarPluginEnable			  = CreateConVar("balancer_spawn", "1","0: Disable, 1: Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	cvarBalancerMode			  = CreateConVar("balancer_spawn_mode","0","0: Edit only director, 1: Override director and vscripts, 2: Override forward director scripts(require left4dhooks)", FCVAR_NONE, true, 0.0, true, 2.0);
	cvarCheckMode			      = CreateConVar("balancer_spawn_check","2","0: Check all players survivor, 1: Not check survivor bots, 2: Not check survivors dead, 3: Select all Not check modes", FCVAR_NONE, true, 0.0, true, 3.0);
	cvarPlayersBase	              = CreateConVar("balancer_spawn_check_base", "4", "Set survivor players base config", FCVAR_NONE, true, 1.0);
	cvarLimitBase	              = CreateConVar("balancer_spawn_limit_si_base", "4", "Set limit specials to players base config, -1:Disable limit balancer", FCVAR_NONE, true, -1.0);
	cvarLimitDec			      = CreateConVar("balancer_spawn_limit_si_dec", "1", "Set limit to decrease for each 1 player less than players base config, -1:Disable limit decrement");
	cvarLimitInc			      = CreateConVar("balancer_spawn_limit_si_inc", "1", "Set limit to increase for each 1 player more than players base config, -1:Disable limit increment");
	cvarLimitMin		          = CreateConVar("balancer_spawn_limit_si_min", "1", "Set min limit for all special infected, -1:Disable limit min");
	cvarLimitMax		          = CreateConVar("balancer_spawn_limit_si_max", "-1", "Set max limit for all special infected, -1:Disable limit max");
	cvarIntervalBase	          = CreateConVar("balancer_spawn_interval_si_base", "45.0", "Set interval special respawn for players base config, -1:Disable interval balancer", FCVAR_NONE, true, -1.0);
	cvarIntervalDec	              = CreateConVar("balancer_spawn_interval_si_dec", "0.0", "Set interval to decrease for each 1 player less than players base config, 0:Disable interval decrement");
	cvarIntervalInc	              = CreateConVar("balancer_spawn_interval_si_inc", "-5.0", "Set interval to increase for each 1 player more than players base config, 0:Disable interval increment");
	cvarIntervalMin	              = CreateConVar("balancer_spawn_interval_si_min", "3.0", "Set min interval respawn for all special infected, -1:Disable interval min");
	cvarIntervalMax	              = CreateConVar("balancer_spawn_interval_si_max", "60.0", "Set max interval respawn for all special infected, -1:Disable interval max");
	
	AutoExecConfig(true, "l4d2_balancer_spawn");

	cvarPluginEnable.AddChangeHook(CvarChanged_Enable);
	cvarBalancerMode.AddChangeHook(CvarsChanged);
	cvarCheckMode.AddChangeHook(CvarsChanged);
	cvarPlayersBase.AddChangeHook(CvarsChanged);
	cvarLimitBase.AddChangeHook(CvarsChanged);
	cvarLimitDec.AddChangeHook(CvarsChanged);
	cvarLimitInc.AddChangeHook(CvarsChanged);
	cvarLimitMax.AddChangeHook(CvarsChanged);
	cvarLimitMax.AddChangeHook(CvarsChanged);
	cvarIntervalBase.AddChangeHook(CvarsChanged);
	cvarIntervalDec.AddChangeHook(CvarsChanged);
	cvarIntervalInc.AddChangeHook(CvarsChanged);
	cvarIntervalMin.AddChangeHook(CvarsChanged);
	cvarIntervalMax.AddChangeHook(CvarsChanged);
	
	RegAdminCmd("sm_bs_reload", CmdReloadInfectedLimit, ADMFLAG_ROOT, "reload config infected limit");

	EnablePlugin();
}

public void OnAllPluginsLoaded()
{
	g_bLeft4DHooks = GetFeatureStatus(FeatureType_Native, "L4D_HasAnySurvivorLeftSafeArea") == FeatureStatus_Available;
}

public Action CmdReloadInfectedLimit(int client, int args)
{	
	LoadInfectedLimit();
	ReplyToCommand(client, "reloaded config:%s", CFG_INFECTEDLIMIT);
	return Plugin_Handled;
}

void EnablePlugin(){
	g_bPluginEnable = cvarPluginEnable.BoolValue;
	if(g_bPluginEnable){
		HookEvent("player_spawn", Events_CheckPlayers);
		HookEvent("player_death", Events_CheckPlayers);
		HookEvent("player_disconnect", Events_CheckPlayers);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("round_start", Event_RoundStart);
	}
	GetCvarsValues();
}

void DisablePlugin(){
	UnhookEvent("player_spawn", Events_CheckPlayers);
	UnhookEvent("player_death", Events_CheckPlayers);
	UnhookEvent("player_disconnect", Events_CheckPlayers);
	UnhookEvent("round_end", Event_RoundEnd);
	UnhookEvent("round_start", Event_RoundStart);
	delete g_hTimerCheck;
	delete g_hTimerBalancer;
}

public void CvarChanged_Enable(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPluginEnable = convar.BoolValue;
	if (g_bPluginEnable && strcmp(oldValue, "0") == 0)
		EnablePlugin();
	else if (!g_bPluginEnable && strcmp(oldValue, "1") == 0)
		DisablePlugin();
}

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvarsValues();
}

void GetCvarsValues(){
	g_iCheckMode			   = cvarCheckMode.IntValue;
	g_iBalancerMode			   = cvarBalancerMode.IntValue;
	g_iPlayersBase	           = cvarPlayersBase.IntValue;
	g_iLimitBase	           = cvarLimitBase.IntValue;
	g_iLimitDec                = cvarLimitDec.IntValue;
	g_iLimitInc                = cvarLimitInc.IntValue;
	g_iLimitMin	               = cvarLimitMin.IntValue;
	g_iLimitMax	               = cvarLimitMax.IntValue;
	g_fIntervalBase	           = cvarIntervalBase.FloatValue;
	g_fIntervalDec             = cvarIntervalDec.FloatValue;
	g_fIntervalInc             = cvarIntervalInc.FloatValue;
	g_fIntervalMin	           = cvarIntervalMin.FloatValue;
	g_fIntervalMax	           = cvarIntervalMax.FloatValue;
}

void LoadInfectedLimit(){
	//get config file
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CFG_INFECTEDLIMIT);

	//create config file
	KeyValues hFile = new KeyValues("InfectedLimit");
	if(!FileExists(sPath))
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
		
		for( int i; i < sizeof(g_sInfectedLimit); i++ ){
			if(hFile.JumpToKey(g_sInfectedLimit[i], true))
			{
				for( int j; j < sizeof(sLimitBalancerType); j++ ){
					hFile.SetNum(sLimitBalancerType[j], -1);
				}
				hFile.Rewind();
			}
		}
		hFile.ExportToFile(sPath);
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CFG_INFECTEDLIMIT);
	}
	// load config
	if( hFile.ImportFromFile(sPath) )
	{
		for( int i; i < sizeof(g_sInfectedLimit); i++ ){
			if(hFile.JumpToKey(g_sInfectedLimit[i], true)){
				for( int j; j < sizeof(sLimitBalancerType); j++ ){
					g_iLimitBalancerType[i][j] = hFile.GetNum(sLimitBalancerType[j], -1);
				}
				hFile.Rewind();
			}
		}
	}
	delete hFile;
}

public void OnMapEnd()
{
	delete g_hTimerCheck;
	delete g_hTimerBalancer;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimerCheck;
	delete g_hTimerBalancer;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LoadInfectedLimit();
	delete g_hTimerCheck;
	delete g_hTimerBalancer;
	g_iSurvivorsChecked = -1;
	g_hTimerCheck = CreateTimer(0.9, TimerCheck);
	if(g_iBalancerMode <= 1)
		g_hTimerBalancer = CreateTimer(1.0, TimerBalancer, _, TIMER_REPEAT);
	 
}

public void Events_CheckPlayers(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidSurvivor(client)){
		delete g_hTimerCheck;
		g_hTimerCheck = CreateTimer(1.0, TimerCheck);
	}
}

public Action TimerBalancer(Handle timer)
{
	if(g_iBalancerMode == 2){
		g_hTimerBalancer = null;
		return Plugin_Stop;
	}
	
	if(g_bLeft4DHooks && !L4D_HasAnySurvivorLeftSafeArea()){
		return Plugin_Continue;
	}
	
	char dvalue[16];
	if(g_iLimitBase != -1){
		IntToString(g_iLimitMaxSpecial, dvalue, sizeof(dvalue));
		SetDirectorVar("MaxSpecials", dvalue);
		SetDirectorVar("DominatorLimit", dvalue);
	}
	
	if(g_fIntervalBase != -1.0){
		FloatToString(g_fIntervalSpecial, dvalue, sizeof(dvalue));
		SetDirectorVar("SpecialRespawnInterval", dvalue);
		SetDirectorVar("SpecialInitialSpawnDelayMin", dvalue);
		SetDirectorVar("SpecialInitialSpawnDelayMax", dvalue);
	}

	for(int i; i < sizeof(g_iLimitInfected); i++){
		if(g_iLimitInfected[i] == -1){
			continue;
		}
		IntToString(g_iLimitInfected[i], dvalue, sizeof(dvalue));
		SetDirectorVar(g_sInfectedLimit[i], dvalue);
		//if(DEBUG)PrintToChatAll("%s: %s",g_sInfectedLimit[i], dvalue);
	}
	return Plugin_Continue;
}

public Action TimerCheck(Handle timer)
{

	g_hTimerCheck = null;
	int survivors = GetSurvivorsCount();
	//if(DEBUG)PrintToChatAll("precheck survivors: %d", survivors);
	if(g_iSurvivorsChecked != survivors){
		g_iSurvivorsChecked = survivors;
		//if(DEBUG)PrintToChatAll("checkedsurvivors: %d", g_iSurvivorsChecked);
		int limitbalancer = survivors == g_iPlayersBase ? 0 : (survivors > g_iPlayersBase ? (g_iLimitInc > 0 ? g_iLimitInc : 0) : (g_iLimitDec > 0 ? g_iLimitDec : 0));
		g_iLimitMaxSpecial = g_iLimitBase + ((survivors - g_iPlayersBase) * limitbalancer);

		if(g_iLimitMin >= 0 && g_iLimitMaxSpecial < g_iLimitMin)
			g_iLimitMaxSpecial = g_iLimitMin;
		if(g_iLimitMax >= 0 && g_iLimitMaxSpecial > g_iLimitMax)
			g_iLimitMaxSpecial = g_iLimitMax;

		//if(DEBUG)PrintToChatAll("MaxSpecials: %d",g_iLimitMaxSpecial);
		float intervalbalancer = survivors == g_iPlayersBase ? 0.0 : (survivors > g_iPlayersBase ? g_fIntervalInc : g_fIntervalDec);
		g_fIntervalSpecial = g_fIntervalBase + ((survivors - g_iPlayersBase) * intervalbalancer);

		if(g_fIntervalMin >= 0.0 && g_fIntervalSpecial < g_fIntervalMin)
			g_fIntervalSpecial = g_fIntervalMin;
		if(g_fIntervalMax >= 0.0 && g_fIntervalSpecial > g_fIntervalMax)
			g_fIntervalSpecial = g_fIntervalMax;
		//if(DEBUG)PrintToChatAll("SpecialRespawnInterval: %f",g_fIntervalSpecial);
		
		for(int i; i < sizeof(g_iLimitInfected); i++){
			int t;
			int limitbase = g_iLimitBalancerType[i][t++];
			int limitdec = g_iLimitBalancerType[i][t++];
			int limitinc = g_iLimitBalancerType[i][t++];
			int limitmin = g_iLimitBalancerType[i][t++];
			int limitmax = g_iLimitBalancerType[i][t++];
			//if(DEBUG)PrintToChatAll("%s\n:%s: %i/:%s: %i/:%s: %i/:%s: %i /:%s: %i",g_sInfectedLimit[i], sLimitBalancerType[0], limitbase, sLimitBalancerType[1], limitdec, sLimitBalancerType[2], limitinc, sLimitBalancerType[3], limitmin, sLimitBalancerType[4], limitmax);
			if(limitbase < 0) {
				g_iLimitInfected[i] = -1;
				continue;
			}

			int limitclassbalancer = survivors == g_iPlayersBase ? 0 : (survivors > g_iPlayersBase ? (limitinc > 0 ? limitinc : 0) : (limitdec > 0 ? limitdec : 0));
			g_iLimitInfected[i] = limitbase + ((survivors - g_iPlayersBase) * limitclassbalancer);

			if(limitmin >= 0 && g_iLimitInfected[i] < limitmin)
				g_iLimitInfected[i] = limitmin;
			else if(limitmax >= 0 && g_iLimitInfected[i] > limitmax)
				g_iLimitInfected[i] = limitmax;
			
		}
	}
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	if(g_iBalancerMode != 2)
		return Plugin_Continue;
	
	if ((strcmp(key, "MaxSpecials", false) == 0 || strcmp(key, "DominatorLimit", false) == 0) && g_iLimitMaxSpecial != retVal && g_iLimitBase != -1)
	{
		//if(DEBUG)PrintToChatAll("MaxSpecials: %d / %d", retVal, g_iLimitMaxSpecial);
		retVal = g_iLimitMaxSpecial;
		return Plugin_Handled;
	}

	for(int i; i < sizeof(g_iLimitInfected); i++){
		if(g_iLimitInfected[i] == -1){
			continue;
		}
		if ((strcmp(key, g_sInfectedLimit[i], false) == 0) && g_iLimitInfected[i] != retVal ){
			//if(DEBUG)PrintToChatAll("%s: %d / %d", key, retVal, g_iLimitInfected[i]);
			retVal = g_iLimitInfected[i];
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action L4D_OnGetScriptValueFloat(const char[] key, float &retVal)
{
	if(g_iBalancerMode != 2 || g_fIntervalBase == -1.0)
		return Plugin_Continue;
		
	if ((strcmp(key, "SpecialRespawnInterval", false) == 0  
	//|| strcmp(key, "SpecialInitialSpawnDelayMin", false) == 0  
	//|| strcmp(key, "SpecialInitialSpawnDelayMax", false) == 0  
	) 
	&& g_fIntervalSpecial != retVal)
	{
		//if(DEBUG)PrintToChatAll("SpecialRespawnInterval: %f / %f",retVal,g_fIntervalSpecial);
		retVal = g_fIntervalSpecial;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

int GetSurvivorsCount(){
	int survivors = 0;
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsValidSurvivorCheck(i))
		{
			survivors++;
		}
	}
	return survivors;
}

bool IsValidSurvivorCheck(int client){
	if(IsValidSurvivor(client)){
		if((g_iCheckMode & 1) && IsFakeClient(client))
			return false;
		if((g_iCheckMode & 2) && !IsPlayerAlive(client))
			return false;
		
		return true;
	}
	return false;
}

void SetDirectorVar(char[] dvar, char[] dvalue){
	g_sDSType = g_iBalancerMode ? DIRECTORSCRIPT_TYPE1 : DIRECTORSCRIPT_TYPE0;
	L4D2_RunScript("%s.%s <- %s;", g_sDSType, dvar, dvalue);
}

//https://forums.alliedmods.net/showthread.php?p=2535972
stock void L4D2_RunScript(const char[] sCode, any ...){
	static iScriptLogic = INVALID_ENT_REFERENCE;
	
	if(!IsValidEnt(EntRefToEntIndex(iScriptLogic))) {
		iScriptLogic = FindEntityByClassname(MaxClients+1, "info_director");	
	}
	
	if(!IsValidEnt(EntRefToEntIndex(iScriptLogic))) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(!IsValidEnt(EntRefToEntIndex(iScriptLogic)))
			SetFailState("Could not create 'logic_script'");
		
		DispatchSpawn(iScriptLogic);
	}

	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

stock int IsValidSpect(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 1 );
}

stock int IsValidSurvivor(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 2 );
}

stock bool IsValidClient(int client){
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidEnt(int entity){
	return (entity > MaxClients && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}