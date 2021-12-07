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


/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
#define PLUGIN_NAME				"Infinite Aux Power only for Half-Life 2 MultiPlayer"
#define PLUGIN_AUTHOR			"Berni & Chanz"
#define PLUGIN_DESCRIPTION		"Gives all players infinite aux power. HL2MP only!"
#define PLUGIN_VERSION 			"2.0.0"
#define PLUGIN_URL				"http://www.mannisfunhouse.eu/ OR http://forums.alliedmods.net/showthread.php?p=642281"

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
#define WHAT_ADMIN_IS_DEVELOPER Admin_Root

#define bits_SUIT_DEVICE_SPRINT		0x00000001
#define bits_SUIT_DEVICE_FLASHLIGHT	0x00000002
#define bits_SUIT_DEVICE_BREATHER	0x00000004

/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:g_cvar_Version 				= INVALID_HANDLE;
new Handle:g_cvar_Enable 				= INVALID_HANDLE;
new Handle:g_cvar_Debug 				= INVALID_HANDLE;

new Handle:g_cvar_Sprinting				= INVALID_HANDLE;
new Handle:g_cvar_Breathing				= INVALID_HANDLE;

//ConVars runtime saver:
new g_iPluginEnable					= 1;
new g_iPluginDebug						= 0;
new g_iPluginSprinting					= 0;
new g_iPluginBreathing					= 0;

// Misc
new bool:g_bIsDeveloper[MAXPLAYERS+1] 	= {false,...};

/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/
public OnPluginStart() {

	//Init for first or late load
	Plugin_LoadInit();

	//Version Info & Cvar
	decl String:pluginFileName[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE,pluginFileName,sizeof(pluginFileName));
	
	decl String:modDir[PLATFORM_MAX_PATH];
	GetGameFolderName(modDir,sizeof(modDir));
	
	if(!StrEqual(modDir,"hl2mp",false)){
		
		SetFailState("%s will not work in other games/mods than HL2MP! This plugin always disables itself if the game is not HL2DM, you can delete the plugin file: %s",PLUGIN_NAME,pluginFileName);
	}
	
	decl String:cvarVersionInfo[512];
	Format(cvarVersionInfo,sizeof(cvarVersionInfo),"\n  || %s ('%s') v%s\n  || Builddate:'%s - %s'\n  || Author(s):'%s'\n  || URL:'%s'\n  || Description:'%s'",PLUGIN_NAME,pluginFileName,PLUGIN_VERSION,__TIME__,__DATE__,PLUGIN_AUTHOR,PLUGIN_URL,PLUGIN_DESCRIPTION);
	
	g_cvar_Version = CreateConVar("sm_infinite_aux_version", PLUGIN_VERSION, cvarVersionInfo, FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	SetConVarString(g_cvar_Version,PLUGIN_VERSION);
	
	//Cvars
	g_cvar_Enable = CreateConVar("sm_infinite_aux_enable", "1", "Enables or Disables HL2MP Infinite Aux Power (1=Enable|0=Disabled)",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	g_cvar_Debug = CreateConVar("sm_infinite_aux_debug", "0", "Enables or Disables debug mode of HL2MP Infinite Aux Power (2=SendToClient|1=Enable|0=Disabled)",FCVAR_PLUGIN|FCVAR_DONTRECORD,true,0.0,true,2.0);
	g_cvar_Sprinting = CreateConVar("sm_infinite_aux_sprinting", "0", "Enables infinite Battery power for sprinting",FCVAR_PLUGIN,true,0.0,true,1.0);
	g_cvar_Breathing = CreateConVar("sm_infinite_aux_breathing", "0", "Enables infinite Battery power for breating",FCVAR_PLUGIN,true,0.0,true,1.0);
	
	//Cvar Runtime optimizer
	g_iPluginEnable = GetConVarInt(g_cvar_Enable);
	g_iPluginDebug = GetConVarInt(g_cvar_Debug);
	g_iPluginSprinting = GetConVarInt(g_cvar_Sprinting);
	g_iPluginBreathing = GetConVarInt(g_cvar_Breathing);
	
	//Cvar Hooks
	HookConVarChange(g_cvar_Enable,ConVarChange_Enable);
	HookConVarChange(g_cvar_Debug,ConVarChange_Debug);
	HookConVarChange(g_cvar_Sprinting,ConVarChange_Sprinting);
	HookConVarChange(g_cvar_Breathing,ConVarChange_Breathing);
	
	AutoExecConfig(true,"plugin.infinite_aux_power");
	
	//debug messages only after the debug cvars and runtime optimizer has been set
	Server_PrintDebug("modDir: %s",modDir);
	Server_PrintDebug(cvarVersionInfo);
}

public OnClientDisconnect(client){
	
	Client_InitVars(client);
}

public OnClientPostAdminCheck(client){
	
	Client_InitVars(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	
	if(g_iPluginEnable == 0){
		
		Server_PrintDebug("Plugin is disabled");
		return Plugin_Continue;
	}
	
	if((g_iPluginSprinting == 0) && (g_iPluginBreathing == 0)){
		
		Server_PrintDebug("sm_infinite_sprinting AND sm_infinite_breathing are 0 -> so this plugin doesn't do anything");
		return Plugin_Continue;
	}
	
	if(IsFakeClient(client)){
		
		Client_PrintDebug(client,"you are a bot -> no plugin action",client);
		return Plugin_Continue;
	}
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client)){
		
		Client_PrintDebug(client,"you are not in game or not alive");
		return Plugin_Continue;
	}
	
	new m_bitsActiveDevices = GetEntProp(client, Prop_Send, "m_bitsActiveDevices");
	
	if((g_iPluginSprinting == 1) && (m_bitsActiveDevices & bits_SUIT_DEVICE_SPRINT)){
		
		Client_PrintDebug(client,"Debug: sprint");
		SetEntPropFloat(client, Prop_Data, "m_flSuitPowerLoad", 0.0);
		SetEntProp(client, Prop_Send, "m_bitsActiveDevices", m_bitsActiveDevices & ~bits_SUIT_DEVICE_SPRINT);
	}
	
	if((g_iPluginBreathing > 0) && (m_bitsActiveDevices & bits_SUIT_DEVICE_BREATHER)){
		
		SetEntPropFloat(client, Prop_Data, "m_flSuitPowerLoad", 0.0);
		SetEntProp(client, Prop_Send, "m_bitsActiveDevices", m_bitsActiveDevices & ~bits_SUIT_DEVICE_BREATHER);
	}
	
	return Plugin_Continue;
}

/****************************************************************


		C A L L B A C K   F U N C T I O N S


****************************************************************/
public ConVarChange_Enable(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPluginEnable = StringToInt(newVal);
}

public ConVarChange_Debug(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPluginDebug = StringToInt(newVal);
}

public ConVarChange_Sprinting(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPluginSprinting = StringToInt(newVal);
}

public ConVarChange_Breathing(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPluginBreathing = StringToInt(newVal);
}


/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/
stock Plugin_LoadInit(){
	
	Server_InitVars();
	ClientAll_InitVars();
}

stock Server_InitVars(){
	
	//Init Server
	g_cvar_Version 					= INVALID_HANDLE;
	g_cvar_Enable 					= INVALID_HANDLE;
	g_cvar_Debug 					= INVALID_HANDLE;

	//ConVars runtime saver
	g_iPluginEnable				= 1;
	g_iPluginDebug					= 0;
}

stock ClientAll_InitVars(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_InitVars(client);
	}
}

stock Client_InitVars(client){
	
	//Variables:
	g_bIsDeveloper[client] = Client_IsDeveloper(client);
}

stock bool:Client_IsDeveloper(client){
	
	if(!IsClientAuthorized(client)){
		
		return false;
	}
	
	new AdminId:adminid = GetUserAdmin(client);
	
	if(adminid == INVALID_ADMIN_ID){
		
		//PrintToChat(client,"you are not admin at all");
		return false;
	}
	else if(GetAdminFlag(adminid,WHAT_ADMIN_IS_DEVELOPER)){
		
		//PrintToChat(client,"you are allowed as developer");
		return true;
	}
	
	//PrintToChat(client,"you don't have permission to be developer");
	return false;
}

stock Server_PrintDebug(const String:format[],any:...){
	
	if(g_iPluginEnable == 0){
		return;
	}
	
	switch(g_iPluginDebug){
		
		case 1:{
			decl String:vformat[1024];
			VFormat(vformat, sizeof(vformat), format, 2);
			PrintToServer(vformat);
		}
		case 2:{
			decl String:vformat[1024];
			VFormat(vformat, sizeof(vformat), format, 2);
			PrintToServer(vformat);
			ClientAll_PrintDebug(vformat);
		}
		case 3:{
			decl String:vformat[1024];
			VFormat(vformat, sizeof(vformat), format, 2);
			ClientAll_PrintDebug(vformat);
		}
	}
}

stock ClientAll_PrintDebug(const String:format[],any:...){
	
	if(g_iPluginEnable == 0){
		return;
	}
	
	switch(g_iPluginDebug){
		
		case 1,2,3:{
			
			decl String:vformat[1024];
			VFormat(vformat, sizeof(vformat), format, 2);
			
			for(new client=1;client<=MaxClients;client++){
				
				if(!IsClientInGame(client)){
					continue;
				}
				
				Client_PrintDebug(client,vformat);
			}
		}
	}
}

stock Client_PrintDebug(client,const String:format[],any:...){
	
	if(g_iPluginEnable == 0){
		return;
	}
	
	switch(g_iPluginDebug){
		
		case 1,2,3:{
			
			if(!g_bIsDeveloper[client]){
				return;
			}
			
			decl String:vformat[1024];
			VFormat(vformat, sizeof(vformat), format, 3);
			PrintToChat(client,vformat);
		}
	}
}

