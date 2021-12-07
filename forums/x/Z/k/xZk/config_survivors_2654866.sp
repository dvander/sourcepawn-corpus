//#define DEBUG				true

#define PLUGIN_NAME			  "Config Survivors"
#define PLUGIN_AUTHOR		  "xZk"
#define PLUGIN_DESCRIPTION	  "allows to execute custom configs for each number of survivors"
#define PLUGIN_VERSION		  "1.0"
#define PLUGIN_URL			  ""

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin myinfo = 
{
	name				 = PLUGIN_NAME,
	author				 = PLUGIN_AUTHOR,
	description			 = PLUGIN_DESCRIPTION,
	version				 = PLUGIN_VERSION,
	url					 = PLUGIN_URL
};

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SPECTATOR(%1) (GetClientTeam(%1) == 1)
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_PLAYER(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SPECTATOR(%1) (IS_VALID_PLAYER(%1) && IS_SPECTATOR(%1))
#define IS_VALID_SURVIVOR(%1) (IS_VALID_PLAYER(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_PLAYER(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define PATH_PREFIX_ACTUAL			 "cfg/"
#define PATH_PREFIX_VISIBLE			 "config_survivors/"

ConVar cvar_enable;
ConVar cvar_create;
ConVar cvar_folder;
ConVar cvar_prefix_file;
ConVar cvar_sufix_file;
ConVar cvar_check_mode;


int IsEnable;
int CreateMode;
int CheckMode;
char FolderConfig[PLATFORM_MAX_PATH];
char PrefixFile[64];
char SufixFile[64];
// bool IsIgnoreBots;
// bool IsCheckAlive;

int Survivors= -1;

public void OnPluginStart()
{
	cvar_enable		 = CreateConVar("config_survivors_enable", "1","0:Disable, 1:Enable Plugin");
	cvar_create		 = CreateConVar("config_survivors_create", "-1" , "-1: Create the files when survivors are checked, 0: No create files automatically, N > 0: Set N files for create automatically");
	cvar_folder		 = CreateConVar("config_survivors_folder", "config_survivors", "Set folder name for save cfg files" );
	cvar_prefix_file = CreateConVar("config_survivors_prefix","config_","Set name prefix cfg files");
	cvar_sufix_file	 = CreateConVar("config_survivors_sufix","_survivors","Set name sufix cfg files");
	cvar_check_mode	 = CreateConVar("config_survivors_check_mode","0","0: Disable check mode, 1: Ignore check idle survivors, 2: Ignore check survivors bot, 4: Check only alive survivors, 7: Select all check modes");

	AutoExecConfig(true, "config_survivors");
	HookEvent("player_spawn", Event_PlayerSpawnKick);
	HookEvent("player_disconnect", Event_PlayerSpawnKick);
	HookEvent("player_death", Event_PlayerDeath);
	
	cvar_enable.AddChangeHook(CvarsChanged);	 
	cvar_create.AddChangeHook(CvarsChanged);	 
	cvar_folder.AddChangeHook(CvarsChanged);	 
	cvar_prefix_file.AddChangeHook(CvarsChanged);
	cvar_sufix_file.AddChangeHook(CvarsChanged); 
	cvar_check_mode.AddChangeHook(CvarsChanged); 

	
	GetConvars();
	createConfigFiles();
}

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	GetConvars();
	createConfigFiles();
}

void GetConvars(){
	IsEnable	     = cvar_enable.BoolValue;
	CreateMode	     = cvar_create.IntValue;
	CheckMode	     = cvar_check_mode.IntValue;
	cvar_folder.GetString(FolderConfig,sizeof(FolderConfig));
	cvar_prefix_file.GetString(PrefixFile,sizeof(PrefixFile));
	cvar_sufix_file.GetString(SufixFile,sizeof(SufixFile));
}

public Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	createConfigFiles();
}

public void Event_PlayerSpawnKick(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IS_VALID_SURVIVOR(client))
		CreateTimer(0.1, DelayCheck,_,TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IS_VALID_SURVIVOR(client))
		CheckSurvivors();
}

public Action DelayCheck(Handle timer)
{
	CheckSurvivors();
}

void CheckSurvivors(){
	
	if(!IsEnable)
		return;
		
	int survivors_checked = 0;
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsValidSurvivorCheck(i))
		{
			survivors_checked++;
		}
	}
	//if (DEBUG)PrintToChatAll("%d Survivors", Survivors);
	//if(survivors_checked == 0)
		//return;
	
	if(survivors_checked != Survivors || Survivors == -1){
		Survivors = survivors_checked;
		SetConfig();
		//if (DEBUG)PrintToChatAll("set cfg for: %d Survivors", Survivors);
	}
	return;
}

bool IsValidSurvivorCheck(int client){
	if(IS_VALID_SURVIVOR(client)){
		if((CheckMode & 1) && GetBotOfIdle(client) == client)
			return false;
		if((CheckMode & 2) && IsFakeClient(client) && GetBotOfIdle(client) == 0)
			return false;
		if((CheckMode & 4) && !IsPlayerAlive(client) )
			return false;
			
		return true;
	}
	return false;
}

void SetConfig()
{	
	char pathfile[PLATFORM_MAX_PATH];
	char file_name[PLATFORM_MAX_PATH];
	Format(file_name,sizeof(file_name),"%s%i%s",PrefixFile, Survivors, SufixFile);
	getConfigFilename(pathfile, sizeof(pathfile), file_name, true);
	if (FileExists(pathfile)){
		getConfigFilename(pathfile, sizeof(pathfile), file_name);
		ServerCommand("exec \"%s\"", pathfile);
	}
	else if(CreateMode == -1){
		char label[32];
		Format(label,sizeof(label), "%i Survivors",Survivors);
		createConfigFile(file_name,label);
	}
		
}

void createConfigFiles() {
	
	if(!IsEnable)
		return;
	
	if(!StrEqual(FolderConfig,"")){
		createConfigDir(FolderConfig, PATH_PREFIX_ACTUAL);
	}
	if(CreateMode > 0){
		char file_name[PLATFORM_MAX_PATH];
		for(int i; i <= CreateMode; i++){
			Format(file_name,sizeof(file_name),"%s%i%s",PrefixFile, i, SufixFile);
			char label[32];
			Format(label,sizeof(label), "%i Survivors",i);
			createConfigFile(file_name, label);
		}	
	}
}

void createConfigDir(const char[] filename, const char[] prefix= "") {
	char dirname[PLATFORM_MAX_PATH];
	Format(dirname, sizeof(dirname), "%s%s/", prefix, filename);
	if(DirExists(dirname))
		return;
	CreateDirectory(
		dirname,  
		FPERM_U_READ + FPERM_U_WRITE + FPERM_U_EXEC + 
		FPERM_G_READ + FPERM_G_WRITE + FPERM_G_EXEC + 
		FPERM_O_READ + FPERM_O_WRITE + FPERM_O_EXEC
	);
}

void getConfigFilename(char[] buffer, const int maxlen, const char[] filename, bool actualPath = false) {
	Format(buffer, maxlen, "%s%s%s%s.cfg", 
		(actualPath ? PATH_PREFIX_ACTUAL : ""), FolderConfig, 
		(StrEqual(FolderConfig,"") ? "": "/"), filename);
}

void createConfigFile(const char[] filename, const char[] label = "") {
	char configFilename[PLATFORM_MAX_PATH];
	char configLabel[128];
	Handle fileHandle = INVALID_HANDLE;
	getConfigFilename(configFilename, sizeof(configFilename), filename, true);
	// Check if config exists
	if (FileExists(configFilename)) return;
	// If it doesnt, create it
	fileHandle = OpenFile(configFilename, "w+");
	// Determine content
	if (strlen(label) > 0) strcopy(configLabel, sizeof(configLabel), label);
	else				   strcopy(configLabel, sizeof(configLabel), configFilename);
	if (fileHandle != INVALID_HANDLE) {
		WriteFileLine(fileHandle, "// Configfile for: %s", configLabel);
		CloseHandle(fileHandle);
	}
}

stock int GetBotOfIdle(client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (GetIdlePlayer(i) == client) return i;
	}
	return 0;
}

stock int GetIdlePlayer(int bot)
{
	if(IS_SURVIVOR_ALIVE(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(IS_VALID_SPECTATOR(client))
			{
				return client;
			}
		}
	}
	return 0;
}