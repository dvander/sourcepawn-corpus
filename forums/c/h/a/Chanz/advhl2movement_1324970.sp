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
//#include <smlib>


/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
#define PLUGIN_NAME				"Advanced HL2 Movement"
#define PLUGIN_SHORTNAME		"advhl2movement"
#define PLUGIN_AUTHOR			"Chanz"
#define PLUGIN_DESCRIPTION		"This plugin enables advanced Half-Life 2 Multiplayer movement, such as bhop without delay."
#define PLUGIN_VERSION 			"0.2.4"
#define PLUGIN_URL				"http://www.mannisfunhouse.eu/"

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


/*****************************************************************


G L O B A L   V A R S


*****************************************************************/
// ConVar Handles
new Handle:g_cvar_Version;
new Handle:g_cvar_Enable;
new Handle:g_cvar_Debug;
//new Handle:g_cvar_SprintSpeed;

//ConVars runtime saver:
new g_iPluginEnable;
new g_iPluginDebug;
//new Float:g_fPluginSprintSpeed;

// Misc
new bool:g_bIsDeveloper[MAXPLAYERS+1];
new g_iLastButtons[MAXPLAYERS+1];
new bool:g_bFlipFlopSpeed[MAXPLAYERS+1];

/*****************************************************************


F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	
	decl String:pluginFileName[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE,pluginFileName,sizeof(pluginFileName));
	decl String:cvarVersionInfo[512];
	Format(cvarVersionInfo,sizeof(cvarVersionInfo),"\n  || %s ('%s') v%s\n  || Builddate:'%s - %s'\n  || Author(s):'%s'\n  || URL:'%s'\n  || Description:'%s'",PLUGIN_NAME,pluginFileName,PLUGIN_VERSION,__TIME__,__DATE__,PLUGIN_AUTHOR,PLUGIN_URL,PLUGIN_DESCRIPTION);
	g_cvar_Version = CreateConVar("sm_advhl2movement_version", PLUGIN_VERSION, cvarVersionInfo, FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	SetConVarString(g_cvar_Version,PLUGIN_VERSION);
	
	//Cvars
	g_cvar_Enable = CreateConVar("sm_advhl2movement_enable", "1", "Enables or Disables Advanced HL2 Movement (1=Enable|0=Disabled)",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	g_cvar_Debug = CreateConVar("sm_advhl2movement_debug", "0", "Enables or Disables debug mode of Advanced HL2 Movement (2=SendToClient|1=Enable|0=Disabled)",FCVAR_PLUGIN|FCVAR_DONTRECORD,true,0.0,true,2.0);
	//g_cvar_SprintSpeed = FindConVar("hl2_sprintspeed");
	
	//Cvar Runtime optimizer
	g_iPluginEnable = GetConVarInt(g_cvar_Enable);
	g_iPluginDebug = GetConVarInt(g_cvar_Debug);
	//g_fPluginSprintSpeed = GetConVarFloat(g_cvar_SprintSpeed);
	
	//Cvar Hooks
	HookConVarChange(g_cvar_Enable,ConVarChange_Enable);
	HookConVarChange(g_cvar_Debug,ConVarChange_Debug);
	//HookConVarChange(g_cvar_SprintSpeed,ConVarChange_SprintSpeed);
	
	//Init for first or late load
	Plugin_LoadInit();
	
	AutoExecConfig(true,"plugin.advhl2movement");
	
	//Show the dev that he is loading the right plugin
	Server_PrintDebug(cvarVersionInfo);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	
	if(g_iPluginEnable == 0){
		
		Server_PrintDebug("Plugin is disabled");
		return Plugin_Continue;
	}
	
	if(IsFakeClient(client)){
		
		Client_PrintDebug(client,"you are a bot -> no plugin action",client);
		return Plugin_Continue;
	}
	
	if(buttons == 0){
		return Plugin_Continue;
	}
	
	new entityFlags = GetEntityFlags(client);
	
	new m_fIsSprinting = GetEntProp(client,Prop_Data,"m_fIsSprinting",1);
	
	new sprintButton = -1;
	
	if(buttons & IN_SPEED){
		sprintButton = 1;
	}
	else {
		sprintButton = 0;
	}
	
	Client_PrintDebug(client,"Flags: %d; Buttons: %d;",entityFlags,buttons);
	Client_PrintDebug(client,"#1 SprintButton: %d; m_fIsSprinting: %d;",sprintButton,m_fIsSprinting);
	
	/*if(g_iLastButtons[client] & IN_SPEED){
		SetEntProp(client,Prop_Data,"m_fIsSprinting",1,1);
		SetEntProp(client,Prop_Data,"m_bDucked",0,1);
		SetEntProp(client,Prop_Data,"m_bDucking",0,1);
	}*/
	
	
	
	if((buttons & IN_SPEED) && (m_fIsSprinting == 0)){
		
		if(g_bFlipFlopSpeed[client]){
			
			buttons &= ~IN_SPEED;
			//SetEntProp(client,Prop_Data,"m_fIsSprinting",1,1);
			g_bFlipFlopSpeed[client] = false;
			Client_PrintDebug(client,"flip (m_fIsSprinting: %d)",m_fIsSprinting);
		}
		else {
			
			//SetEntProp(client,Prop_Data,"m_fIsSprinting",0,1);
			g_bFlipFlopSpeed[client] = true;
			Client_PrintDebug(client,"flop (m_fIsSprinting: %d)",m_fIsSprinting);
		}
	}
	
	
	//m_fIsSprinting = GetEntProp(client,Prop_Data,"m_fIsSprinting",1);
	//Client_PrintDebug(client,"#2 SprintButton: %d; m_fIsSprinting: %d;",sprintButton,m_fIsSprinting);
	
	return Plugin_Changed;
}

public OnClientDisconnect(client){
	
	Client_InitVars(client);
}

public OnClientPostAdminCheck(client){
	
	Client_InitVars(client);
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

/*public ConVarChange_SprintSpeed(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_fPluginSprintSpeed = StringToFloat(newVal);
}*/

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

stock Client_InitVars(client){
	
	//Variables:
	g_bIsDeveloper[client] = Client_IsDeveloper(client);
	g_iLastButtons[client] = 0;
	g_bFlipFlopSpeed[client] = false;
}

stock ClientAll_InitVars(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_InitVars(client);
	}
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

/*Function_ClientPush(client,Float:speed=100.0) {
	
	new Float:angles[3];
	new Float:velocity[3];
	new Float:currentVelocity[3];
	
	Entity_GetVelocity(client,currentVelocity);	
	GetClientEyeAngles(client,angles);
	
	velocity[0] = FloatMul(Cosine( 			DegToRad(angles[1])), speed);
	velocity[1] = FloatMul(Sine( 			DegToRad(angles[1])), speed);
	velocity[2] = currentVelocity[2];
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}*/
