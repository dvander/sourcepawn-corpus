/*
* Infinite-Jumping (Bunny Hop, Double Jump & Initial Jump)
* 
* Description:
* Lets user auto jump when holding down space. This plugin includes the DoubleJump plugin too. This plugin should work for all games.
* 
* Installation:
* Place infinite-jumping.smx into your '<moddir>/addons/sourcemod/plugins/' folder.
* Place plugin.infinite-jumping.cfg into your '<moddir>/cfg/sourcemod/' folder.
* 
* 
* For more information see: http://forums.alliedmods.net/showthread.php?p=1239361 OR http://www.mannisfunhouse.eu/
*/

/*****************************************************************


C O M P I L E   O P T I O N S


*****************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
#define PLUGIN_NAME				"Infinite Jumping"
#define PLUGIN_TAG				"sm"
#define PLUGIN_PRINT_PREFIX		"[SM]"
#define PLUGIN_AUTHOR			"Chanz"
#define PLUGIN_DESCRIPTION		"Lets user auto jump when holding down space. This plugin includes the DoubleJump plugin too."
#define PLUGIN_VERSION 			"2.14.40"
#define PLUGIN_URL				"http://forums.alliedmods.net/showthread.php?p=1239361 OR http://www.mannisfunhouse.eu/"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/*****************************************************************


P L U G I N   I N C L U D E S


*****************************************************************/
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#include <smlib>
#include <smlib/pluginmanager>

/*****************************************************************


P L U G I N   D E F I N E S


*****************************************************************/
#define TIMER_THINK 10.0

/*****************************************************************


G L O B A L   V A R S


*****************************************************************/
//ConVar Handles:
new Handle:g_cvarFlag_Infinite 					= INVALID_HANDLE;
new Handle:g_cvarFlag_Double 					= INVALID_HANDLE;
new Handle:g_cvarFlag_PerfectDouble 			= INVALID_HANDLE;
new Handle:g_cvarFlag_GameSlowDowns 			= INVALID_HANDLE;
new Handle:g_cvarFlag_ForwardBoost	 			= INVALID_HANDLE;
new Handle:g_cvarBoost_Initial 					= INVALID_HANDLE;
new Handle:g_cvarBoost_Double 					= INVALID_HANDLE;
new Handle:g_cvarMax_DoubleJumps 				= INVALID_HANDLE;
new Handle:g_cvarOr_Stamina						= INVALID_HANDLE;
new Handle:g_cvarOr_SlowDownOnHurt 				= INVALID_HANDLE;
new Handle:g_cvarBoost_Forward					= INVALID_HANDLE;
new Handle:g_cvarBoost_Forward_WSAD				= INVALID_HANDLE;

//ConVars runtime saver:
new String:g_szPlugin_Flag_Infinite[11] 		= "";
new String:g_szPlugin_Flag_Double[11] 			= "";
new String:g_szPlugin_Flag_PerfectDouble[11] 	= "";
new String:g_szPlugin_Flag_GameSlowDowns[11] 	= "";
new String:g_szPlugin_Flag_ForwardBoost[11] 	= "";
new Float:g_flPlugin_Boost_Initial 				= 0.0;
new Float:g_flPlugin_Boost_Double 				= 0.0;
new g_iPlugin_Max_DoubleJumps 					= 0;
new Float:g_flPlugin_Or_Stamina 				= 0.0;
new Float:g_flPlugin_Or_SlowDownOnHurt			= 1.0;
new Float:g_flPlugin_Boost_Forward				= 0.0;
new g_iPlugin_Boost_Forward_WSAD				= 1;

//Cookies
new bool:g_bCookiesEnabled						= false;

new Handle:g_hCookie_BanTime 					= INVALID_HANDLE;
new Handle:g_hCookie_Switch 					= INVALID_HANDLE;

new g_iCooMem_BanTime[MAXPLAYERS+1];
new bool:g_bCooMem_Switch[MAXPLAYERS+1];
new bool:g_bIsBanned[MAXPLAYERS+1];

//Allow list for Clients:
new bool:g_bAllow_InfiniteJump[MAXPLAYERS+1];
new bool:g_bAllow_DoubleJump[MAXPLAYERS+1];
new bool:g_bAllow_PerfectDoubleJump[MAXPLAYERS+1];
new bool:g_bAllow_AntiSlowDowns[MAXPLAYERS+1];
new bool:g_bAllow_ForwardBoost[MAXPLAYERS+1];

//Counter
new g_iDoubleJumps[MAXPLAYERS+1];

//Offsets
new g_Offset_m_flStamina = -1;
new g_Offset_m_flVelocityModifier = -1;

/*****************************************************************


F O R W A R D   P U B L I C S


*****************************************************************/
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	
	MarkNativeAsOptional("SetCookieMenuItem");
	MarkNativeAsOptional("RegClientCookie");
	MarkNativeAsOptional("AreClientCookiesCached");
	MarkNativeAsOptional("SetClientCookie");
	MarkNativeAsOptional("GetClientCookie");
	return APLRes_Success;
}

public OnPluginStart() {
	
	//Init for smlib
	SMLib_OnPluginStart(PLUGIN_NAME,PLUGIN_TAG,PLUGIN_VERSION,PLUGIN_AUTHOR,PLUGIN_DESCRIPTION,PLUGIN_URL);
	
	//Translations (you should use it always when printing something to clients)
	//Always with plugin. as prefix, the short name and .phrases as postfix.
	decl String:translationsName[PLATFORM_MAX_PATH];
	Format(translationsName,sizeof(translationsName),"plugin.%s.phrases",g_sPlugin_Short_Name);
	File_LoadTranslations(translationsName);
	
	
	//ConVars
	g_cvarFlag_Infinite				= CreateConVarEx("flags_infinite", 			"0", 		"Automatic rejump.\n\"1\" = force on.\n\"0\" = force off.\n\"<adminflag>\" = admin with this flag can (a,b,c,d,...).\nSee: addons/sourcemod/configs/admin_levels.cfg for more info.",FCVAR_PLUGIN);
	g_cvarFlag_Double				= CreateConVarEx("flags_double", 			"0", 		"Rejump in mid air.\n\"\" = everyone can.\n\"0\" = noone can.\n\"<adminflag>\" = admin with this flag can (a,b,c,d,...).\nSee: addons/sourcemod/configs/admin_levels.cfg for more info.",FCVAR_PLUGIN);
	g_cvarFlag_PerfectDouble		= CreateConVarEx("flags_perfectdouble", 	"0", 		"Jump automatic in mid air when jump is pressed.\n\"\" = everyone can.\n\"0\" = noone can.\n\"<adminflag>\" = admin with this flag can (a,b,c,d,...).\nSee: addons/sourcemod/configs/admin_levels.cfg for more info.",FCVAR_PLUGIN);
	g_cvarFlag_GameSlowDowns		= CreateConVarEx("flags_gameslowdowns",		"",			"Bypass game slow downs as stamina or slow down on hurt.\n\"\" = everyone can.\n\"0\" = noone can.\n\"<adminflag>\" = admin with this flag can (a,b,c,d,...).\nSee: addons/sourcemod/configs/admin_levels.cfg for more info.",FCVAR_PLUGIN);
	g_cvarFlag_ForwardBoost			= CreateConVarEx("flags_forwardboost",		"0",		"Automatic forward boost by each jump.\n\"\" = everyone can.\n\"0\" = noone can.\n\"<adminflag>\" = admin with this flag can (a,b,c,d,...).\nSee: addons/sourcemod/configs/admin_levels.cfg for more info.",FCVAR_PLUGIN);
	
	g_cvarBoost_Initial 			= CreateConVarEx("boost_initial", 			"0.0",		"If you wish to jump higher or lower, then change this value.\nIn units per second.\nnegative values = players can't jump that high anymore\n0.0 = normal jump height\npositive values = players can jump heigher.",FCVAR_PLUGIN);
	g_cvarBoost_Double 				= CreateConVarEx("boost_double", 			"290.0",	"The amount of vertical boost, to apply when mid air double jumping.\nIn units per second.\nnegative values = player are pushed down in mid air, when double/multi jump.\n0.0 = only falling can be stopped, when jump is pressed in mid air.\npositive values = players can jump heigher, when pressing space in midair",FCVAR_PLUGIN);
	g_cvarMax_DoubleJumps 			= CreateConVarEx("max_doublejumps", 		"1",		"The maximum number of re-jumps allowed while in mid air.\n if you want to disable this, don't set it to 0 instead use the sm_infinitejumpging_flags_double console var.",FCVAR_PLUGIN,true,0.0);
	g_cvarOr_Stamina				= CreateConVarEx("override_stamina", 		"0.0", 		"This will be the new stamina value when you land.\n0.0 = full stamina/no speed is lost.\n-1.0 = let the engine handle how much speed a player looses.\nExample: 1315.0 is the default value in css, but use -1.0 instead if you wish to disable.",FCVAR_PLUGIN);
	g_cvarOr_SlowDownOnHurt			= CreateConVarEx("override_slowdownonhurt",	"1.0",		"This will override the speed ratio when hurt.\n1.0 = no speed is lost.\n0.5 = 50% slower.\n0.0 = stops\n2.0 = 100% faster.\n-1.0 = let the engine/game handle how much speed players loose.",FCVAR_PLUGIN);
	g_cvarBoost_Forward				= CreateConVarEx("boost_forward",			"50.0",		"Amount of boost per second to push the client forward when jumping.\nIn units per second.\nBe careful this value adds ontop of the velocity at each jump.",FCVAR_PLUGIN);
	g_cvarBoost_Forward_WSAD		= CreateConVarEx("boost_forward_wsad",		"1",		"If this is 1 then players need to press W,S,A,D (movement keys) and jump, to receive a boost (adds basicly more control).",FCVAR_PLUGIN,true,0.0,true,1.0);
	
	
	//ConVar runtime saver
	GetConVarString					(g_cvarFlag_Infinite,g_szPlugin_Flag_Infinite,sizeof(g_szPlugin_Flag_Infinite));
	GetConVarString					(g_cvarFlag_Double,g_szPlugin_Flag_Double,sizeof(g_szPlugin_Flag_Double));
	GetConVarString					(g_cvarFlag_PerfectDouble,g_szPlugin_Flag_PerfectDouble,sizeof(g_szPlugin_Flag_PerfectDouble));
	GetConVarString					(g_cvarFlag_GameSlowDowns,g_szPlugin_Flag_GameSlowDowns,sizeof(g_szPlugin_Flag_GameSlowDowns));
	GetConVarString					(g_cvarFlag_ForwardBoost,g_szPlugin_Flag_ForwardBoost,sizeof(g_szPlugin_Flag_ForwardBoost));
	
	g_flPlugin_Boost_Initial		= GetConVarFloat(g_cvarBoost_Initial);
	g_flPlugin_Boost_Double			= GetConVarFloat(g_cvarBoost_Double);
	g_iPlugin_Max_DoubleJumps		= GetConVarInt(g_cvarMax_DoubleJumps);
	g_flPlugin_Or_Stamina			= GetConVarFloat(g_cvarOr_Stamina);
	g_flPlugin_Or_SlowDownOnHurt	= GetConVarFloat(g_cvarOr_SlowDownOnHurt);
	g_flPlugin_Boost_Forward		= GetConVarFloat(g_cvarBoost_Forward);
	g_iPlugin_Boost_Forward_WSAD	= GetConVarInt(g_cvarBoost_Forward_WSAD);
	
	
	//ConVar Hooks
	HookConVarChange(g_cvarFlag_Infinite,ConVarChange_Flag_Infinite);
	HookConVarChange(g_cvarFlag_Double,ConVarChange_Flag_Double);
	HookConVarChange(g_cvarFlag_PerfectDouble,ConVarChange_Flag_PerfectDouble);
	HookConVarChange(g_cvarFlag_GameSlowDowns,ConVarChange_Flag_GameSlowDowns);
	HookConVarChange(g_cvarFlag_ForwardBoost,ConVarChange_Flag_ForwardBoost);
	
	HookConVarChange(g_cvarBoost_Initial,ConVarChange_Boost_Initial);
	HookConVarChange(g_cvarBoost_Double,ConVarChange_Boost_Double);
	HookConVarChange(g_cvarMax_DoubleJumps,ConVarChange_Max_DoubleJumps);
	HookConVarChange(g_cvarOr_Stamina,ConVarChange_Or_Stamina);
	HookConVarChange(g_cvarOr_SlowDownOnHurt,ConVarChange_Or_SlowDownOnHurt);
	HookConVarChange(g_cvarBoost_Forward,ConVarChange_Boost_Forward);
	HookConVarChange(g_cvarBoost_Forward_WSAD,ConVarChange_Boost_Forward_WSAD);
	
	
	//Admin Commands
	RegAdminCmd("sm_ban_autojump",Command_Ban,ADMFLAG_BAN,"Bans a player for a certain time from Infinite Jumping");
	
	//User Commands
	//RegConsoleCmd("sm_jumping_reset",Command_Reset,"Resets all your personal Infinite Jumping settings to default values");
	RegConsoleCmd("sm_autojump", Command_AutoJump, "On/Off Infinite (Auto) Jumping");

	
	g_bCookiesEnabled = (GetExtensionFileStatus("clientprefs.ext") == 1);
	
	if (g_bCookiesEnabled) {
		// prepare title for clientPref menu
		decl String:menutitle[64];
		Format(menutitle, sizeof(menutitle), "%s",PLUGIN_NAME);
		SetCookieMenuItem(PrefMenu, 0, menutitle);
		
		
		//Cookies
		g_hCookie_BanTime = RegClientCookie("infjumping_bantime","How long a client is banned from Infinite Jumping",CookieAccess_Protected);
		g_hCookie_Switch = RegClientCookie("infjumping_switch","Disables/Enables Infinite Jumping",CookieAccess_Public);
		
		
		for (new client=1; client <= MaxClients; client++) {
			
			if (!IsClientInGame(client)) {
				continue;
			}
			
			if (!AreClientCookiesCached(client)) {
				continue;
			}
			
			ClientIngameAndCookiesCached(client);
		}
	}
	
	//Event Hooks
	HookEventEx("player_hurt", Event_Player_Hurt);
	
	//Timer
	CreateTimer(TIMER_THINK,Timer_Think,INVALID_HANDLE,TIMER_REPEAT);
	
	//Auto Config
	AutoExecConfig(true,"plugin.infinite-jumping");
}

public OnMapStart() {
	
	// hax against valvefail (thx psychonic for fix)
	if(GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE){
		SetConVarString(g_cvarVersion, PLUGIN_VERSION);
	}
}

public OnConfigsExecuted(){
	
	ClientAll_Init();
}

public OnClientConnected(client){
	
	Client_Init(client);
}

public OnClientPostAdminCheck(client){
	
	Client_Init(client);
}

public OnClientCookiesCached(client){
	
	if (IsClientInGame(client)) {
		ClientIngameAndCookiesCached(client);
	}
}

public OnClientPutInServer(client){
	
	if (g_bCookiesEnabled && AreClientCookiesCached(client)) {
		ClientIngameAndCookiesCached(client);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	
	if(g_iPlugin_Enable != 1){
		//PrintToChatAll("[%s] Plugin Disabled",PLUGIN_NAME);
		return Plugin_Continue;
	}
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client)){
		//PrintToChatAll("[%s] client: %d is not ingame, alive or a bot",PLUGIN_NAME);
		return Plugin_Continue;
	}
	
	return Client_HandleJumping(client,buttons);
}

/****************************************************************


C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action:Timer_Think(Handle:timer){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!Client_IsValid(client,true)){
			continue;
		}
		
		if(!Client_IsBanned(client) && g_bIsBanned[client]){
			g_bIsBanned[client] = false;
			Client_PrintToChat(client,false,"{B}%s %t",PLUGIN_PRINT_PREFIX,"You have been unbanned",PLUGIN_NAME);
		}
	}
	return Plugin_Continue;
}


public Action:Command_AutoJump(client, args){
	
	if (g_bCooMem_Switch[client]) {
		g_bCooMem_Switch[client] = false;
		Client_PrintToChat(client, false, "{R}%s %t",PLUGIN_PRINT_PREFIX,"You Disabled",PLUGIN_NAME);
		
		if (g_bCookiesEnabled) {
			SetClientCookie(client, g_hCookie_Switch, "off");
		}
	}
	else {
		g_bCooMem_Switch[client] = true;
		Client_PrintToChat(client, false, "{B}%s %t",PLUGIN_PRINT_PREFIX,"You Enabled",PLUGIN_NAME);
		
		if (g_bCookiesEnabled) {
			SetClientCookie(client, g_hCookie_Switch, "on");
		}
	}
	return Plugin_Handled;
}

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen){
	
	if (action == CookieMenuAction_SelectOption) {
		DisplaySettingsMenu(client);
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item){
	
	if (action == MenuAction_Select) {
		decl String:preference[8];
		
		GetMenuItem(prefmenu, item, preference, sizeof(preference));
		
		g_bCooMem_Switch[client] = bool:StringToInt(preference);
		
		if (g_bCooMem_Switch[client]) {
			SetClientCookie(client, g_hCookie_Switch, "on");
			Client_PrintToChat(client,false,"{B}%s %t",PLUGIN_PRINT_PREFIX,"You Enabled",PLUGIN_NAME);
		}
		else {
			SetClientCookie(client, g_hCookie_Switch, "off");
			Client_PrintToChat(client,false,"{R}%s %t",PLUGIN_PRINT_PREFIX,"You Disabled",PLUGIN_NAME);
		}
		
		DisplaySettingsMenu(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(prefmenu);
	}
}

public ConVarChange_Flag_Infinite(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	strcopy(g_szPlugin_Flag_Infinite,sizeof(g_szPlugin_Flag_Infinite),newVal);
	ClientAll_CheckJumpFlags();
}

public ConVarChange_Flag_Double(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	strcopy(g_szPlugin_Flag_Double,sizeof(g_szPlugin_Flag_Double),newVal);
	ClientAll_CheckJumpFlags();
}

public ConVarChange_Flag_PerfectDouble(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	strcopy(g_szPlugin_Flag_PerfectDouble,sizeof(g_szPlugin_Flag_PerfectDouble),newVal);
	ClientAll_CheckJumpFlags();
}

public ConVarChange_Flag_GameSlowDowns(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	strcopy(g_szPlugin_Flag_GameSlowDowns,sizeof(g_szPlugin_Flag_GameSlowDowns),newVal);
	ClientAll_CheckJumpFlags();
}

public ConVarChange_Flag_ForwardBoost(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	strcopy(g_szPlugin_Flag_ForwardBoost,sizeof(g_szPlugin_Flag_ForwardBoost),newVal);
	ClientAll_CheckJumpFlags();
}

public ConVarChange_Boost_Initial(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Boost_Initial = StringToFloat(newVal);
}

public ConVarChange_Boost_Double(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Boost_Double = StringToFloat(newVal);
}

public ConVarChange_Max_DoubleJumps(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPlugin_Max_DoubleJumps = StringToInt(newVal);
}

public ConVarChange_Or_Stamina(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Or_Stamina = StringToFloat(newVal);
}

public ConVarChange_Or_SlowDownOnHurt(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Or_SlowDownOnHurt = StringToFloat(newVal);
}

public ConVarChange_Boost_Forward(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_flPlugin_Boost_Forward = StringToFloat(newVal);
}

public ConVarChange_Boost_Forward_WSAD(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPlugin_Boost_Forward_WSAD = StringToInt(newVal);
}

public Action:Command_Ban(client,args){
	
	if(args < 1){
		decl String:command[32];
		GetCmdArg(0,command,sizeof(command));
		Client_Reply(client,"%s %t",PLUGIN_PRINT_PREFIX,"Usage: Ban",command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1,target,sizeof(target));
	decl String:arg2[11];
	GetCmdArg(2,arg2,sizeof(arg2));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
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
	
	new bantime = StringToInt(arg2);
	
	if(bantime != 0){
		
		Client_PrintToConsole(client,"\n%s Banned %d players from %s for %d minutes:",PLUGIN_PRINT_PREFIX,target_count,PLUGIN_NAME,bantime);
	}
	else {
		
		Client_PrintToConsole(client,"\n%s Unbanned %d players from %s:",PLUGIN_PRINT_PREFIX,target_count,PLUGIN_NAME);
	}
	
	new i=0;
	new String:targetName[MAX_NAME_LENGTH];
	for (i=0;i<target_count;++i) {
		
		GetClientName(target_list[i],targetName,sizeof(targetName));
		Client_PrintToConsole(client,"\n%s",targetName);
		if(bantime != 0){
			
			Client_Ban(target_list[i],client,bantime);
		}
		else {
			
			Client_UnBan(target_list[i],client);
		}
	}
	
	Client_PrintToConsole(client,"\n-----------------------\n");
	
	if(bantime != 0){
		
		Client_PrintToChat(client,false,"{R}%s %t",PLUGIN_PRINT_PREFIX,"See console output");
	}
	
	return Plugin_Handled;
}

Client_Ban(client,banner,bantime){
	
	new String:bannerName[MAX_NAME_LENGTH];
	GetClientName(banner,bannerName,sizeof(bannerName));
	
	new String:szTime[11];
	g_iCooMem_BanTime[client] = GetTime()+bantime*60;
	IntToString(bantime,szTime,sizeof(szTime));
	
	if(g_bCookiesEnabled){
		SetClientCookie(client,g_hCookie_BanTime,szTime);
	}
	g_bIsBanned[client] = true;
	
	Client_PrintToChat(client,false,"{R}%s %t",PLUGIN_PRINT_PREFIX,"You have been banned by",PLUGIN_NAME,bannerName,bantime);
}


Client_UnBan(client,banner){
	
	new String:bannerName[MAX_NAME_LENGTH];
	GetClientName(banner,bannerName,sizeof(bannerName));
	
	g_iCooMem_BanTime[client] = 0;
	
	if(g_bCookiesEnabled){
		SetClientCookie(client,g_hCookie_BanTime,"0");
	}
	g_bIsBanned[client] = false;
	
	Client_PrintToChat(client,false,"{R}%s %t",PLUGIN_PRINT_PREFIX,"You have been unbanned by",PLUGIN_NAME,bannerName);
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	if(g_flPlugin_Or_SlowDownOnHurt == -1.0){
		return Plugin_Continue;
	}
	
	if(g_Offset_m_flVelocityModifier < 1){
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!g_bAllow_AntiSlowDowns[client] || IsFakeClient(client)){
		return Plugin_Continue;
	}
	
	Client_PrintDebug(client,"setting your: m_flVelocityModifier (off: %d) to: %f",g_Offset_m_flVelocityModifier,g_flPlugin_Or_SlowDownOnHurt);
	
	SetEntDataFloat(client, g_Offset_m_flVelocityModifier, g_flPlugin_Or_SlowDownOnHurt, true);
	
	return Plugin_Continue;
}

/*****************************************************************


P L U G I N   F U N C T I O N S


*****************************************************************/
bool:Client_IsBanned(client){
	
	return (g_iCooMem_BanTime[client] > GetTime());
}

DisplaySettingsMenu(client){
	
	decl String:MenuItem[128];
	new Handle:prefmenu = CreateMenu(PrefMenuHandler);
	
	Format(MenuItem, sizeof(MenuItem), "%s", PLUGIN_NAME);
	SetMenuTitle(prefmenu, MenuItem);
	
	new String:checked[] = String:0x9A88E2;
	
	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "Enabled", g_bCooMem_Switch[client] ? checked : "   ");
	AddMenuItem(prefmenu, "1", MenuItem);
	
	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "Disabled", g_bCooMem_Switch[client] ? "   " : checked);
	AddMenuItem(prefmenu, "0", MenuItem);
	
	DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
}


ClientIngameAndCookiesCached(client){
	
	new String:buffer[255];
	GetClientCookie(client,g_hCookie_BanTime,buffer,sizeof(buffer));
	g_iCooMem_BanTime[client] = StringToInt(buffer);
	g_bIsBanned[client] = Client_IsBanned(client);
	
	GetClientCookie(client,g_hCookie_Switch,buffer,sizeof(buffer));
	g_bCooMem_Switch[client] = (!StrEqual(buffer,"off",false));
}

enum VelocityOverride {
	
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
};
//Thank you DarthNinja & javalia for this.
stock Client_Push(client, Float:clientEyeAngle[3], Float:power, VelocityOverride:override[3]=VelocityOvr_None)
{
	decl	Float:forwardVector[3],
	Float:newVel[3];
	
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	
	Entity_GetAbsVelocity(client,newVel);
	
	for(new i=0;i<3;i++){
		switch(override[i]){
			case VelocityOvr_Velocity:{
				newVel[i] = 0.0;
			}
			case VelocityOvr_OnlyWhenNegative:{				
				if(newVel[i] < 0.0){
					newVel[i] = 0.0;
				}
			}
			case VelocityOvr_InvertReuseVelocity:{				
				if(newVel[i] < 0.0){
					newVel[i] *= -1.0;
				}
			}
		}
		
		newVel[i] += forwardVector[i];
	}
	
	Entity_SetAbsVelocity(client,newVel);
}

Client_ForceJump(client,Float:power){
	
	Client_Push(client,Float:{-90.0,0.0,0.0},power,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
}

Client_DoubleJump(client) {
	
	if((1 <= g_iDoubleJumps[client] <= g_iPlugin_Max_DoubleJumps)){
		
		g_iDoubleJumps[client]++;
		
		Client_Push(client,Float:{-90.0,0.0,0.0},g_flPlugin_Boost_Double,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_Velocity});
	}
}


stock Action:Client_HandleJumping(client, &buttons){
	
	if(g_bIsBanned[client]){
		return Plugin_Continue;
	}
	
	if(!g_bCooMem_Switch[client]){
		return Plugin_Continue;
	}
	
	if(Client_GetWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER){
		//PrintToChatAll("[%s] Water level: %d",PLUGIN_NAME,Client_GetWaterLevel(client));
		return Plugin_Continue;
	}
	
	if(Client_IsOnLadder(client)){
		//PrintToChatAll("[%s] is on ladder",PLUGIN_NAME);
		return Plugin_Continue;
	}
	
	static ls_iLastButtons[MAXPLAYERS+1] = {0,...};
	static ls_iLastFlags[MAXPLAYERS+1] = {0,...};
	
	new flags = GetEntityFlags(client);
	//new m_bDucked = GetEntProp(client,Prop_Send,"m_bDucked",1);
	//new m_bDucking = GetEntProp(client,Prop_Send,"m_bDucking",1);
	
	decl Float:clientEyeAngles[3];
	GetClientEyeAngles(client,clientEyeAngles);
	
	//PrintToChat(client,"m_bDucked: %d; m_bDucking: %d",m_bDucked,m_bDucking);
	//new Float:m_flStamina = GetEntDataFloat(client,g_Offset_m_flStamina);
	//Client_PrintDebug(client,"your m_flStamina value: %f",m_flStamina);
	//PrintToChat(client,"buttons: %d",buttons);
	
	if(flags & FL_ONGROUND){
		g_iDoubleJumps[client] = 1;
	}
	
	if(buttons & IN_JUMP){
		
		//PrintToChat(client,"m_bDucked: %d; m_bDucking: %d",m_bDucked,m_bDucking);
		
		if(flags & FL_ONGROUND){
			
			if(g_bAllow_InfiniteJump[client] && g_flPlugin_Boost_Initial != 0.0){
				
				Client_ForceJump(client,g_flPlugin_Boost_Initial);
			}
			
			//boost client
			if(g_bAllow_ForwardBoost[client] && g_flPlugin_Boost_Forward != 0.0){
				
				clientEyeAngles[0] = 0.0;
				
				if(g_iPlugin_Boost_Forward_WSAD == 0){
					
					Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
				}
				else {
					
					if(buttons & IN_FORWARD){
						Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
					}
					
					if(buttons & IN_BACK){
						clientEyeAngles[1] += 180.0;
						Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
					}
					
					if(buttons & IN_MOVELEFT){
						clientEyeAngles[1] += 90.0;
						Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
					}
					
					if(buttons & IN_MOVERIGHT){
						clientEyeAngles[1] += -90.0;
						Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
					}
				}
			}
			
			ls_iLastButtons[client] = buttons;
		}
		else {
			
			if(g_bAllow_AntiSlowDowns[client] && g_Offset_m_flStamina != -1 && g_flPlugin_Or_Stamina != -1.0){
				//you dont loose speed in css when you hit the ground with this:
				SetEntDataFloat(client, g_Offset_m_flStamina, g_flPlugin_Or_Stamina, true);
			}
			
			if(g_bAllow_DoubleJump[client]){
				
				if(g_bAllow_PerfectDoubleJump[client]){
					
					decl Float:clientVel[3];
					Entity_GetAbsVelocity(client,clientVel);
					
					if(clientVel[2] < 0.0){
						
						Client_DoubleJump(client);
					}
				}
				else if(!(ls_iLastButtons[client] & IN_JUMP)){
					
					Client_DoubleJump(client);
				}
			}
			
			ls_iLastButtons[client] = buttons;
			
			//set this here to protect ls_iLastButtons from this changes:
			if(g_bAllow_InfiniteJump[client]){
				
				buttons &= ~IN_JUMP;
			}
		}
	}
	else {
		
		//Disabled because scroll wheel users are at a big disadvantage
		/*if(g_Offset_m_flStamina != -1 && g_flPlugin_Or_Stamina != -1.0 && ls_iLastButtons[client] & IN_JUMP){
		
		Client_PrintDebug(client,"setting your stamina to 1315.0");
		//SetEntDataFloat(client, g_Offset_m_flStamina, 1315.0, true);
		}*/
		
		//need to be set when IN_JUMP is not pressed & set this here to protect ls_iLastButtons from this changes:
		ls_iLastButtons[client] = buttons;
	}
	
	ls_iLastFlags[client] = flags;
	
	return Plugin_Continue;
}



//This function will be called within SMLib_OnPluginStart.
stock ClientAll_Init(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_Init(client);
	}
}

stock Client_Init(client){
	
	//Variables
	Client_InitVars(client);
	
	//Functions
	Client_CheckJumpFlags(client);
	Client_GetOffsetsFrom(client);
}

stock Client_InitVars(client){
	
	//Plugin Client Vars
	g_bAllow_InfiniteJump[client] 		= false;
	g_bAllow_DoubleJump[client] 		= false;
	g_bAllow_PerfectDoubleJump[client] 	= false;
	g_bAllow_AntiSlowDowns[client] 		= false;
	g_bAllow_ForwardBoost[client] 		= false;
}

stock Client_GetOffsetsFrom(client){
	
	if(g_Offset_m_flStamina != -1 && g_Offset_m_flVelocityModifier != -1){
		return;
	}
	
	if(!IsValidEntity(client)){
		return;
	}
	
	decl String:netclass[64];
	
	GetEntityNetClass(client,netclass,sizeof(netclass));
	
	g_Offset_m_flStamina = FindSendPropInfo(netclass,"m_flStamina");
	g_Offset_m_flVelocityModifier = FindSendPropInfo(netclass,"m_flVelocityModifier");
	
	Server_PrintDebug("Offsets from client %d: m_flStamina: %d; m_flVelocityModifier: %d",client,g_Offset_m_flStamina,g_Offset_m_flVelocityModifier);
}

stock ClientAll_CheckJumpFlags(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_CheckJumpFlags(client);
	}
}


stock Client_CheckJumpFlags(client){
	
	new AdminId:adminid = GetUserAdmin(client);
	new AdminFlag:flag;
	
	//g_bAllow_InfiniteJump:
	if(StrEqual(g_szPlugin_Flag_Infinite,"0",false)){
		
		Client_PrintDebug(client,"You are NOT allowed to infinite jump now! (%s)",g_szPlugin_Flag_Infinite);
		g_bAllow_InfiniteJump[client] = false;
	}
	else if(FindFlagByChar(g_szPlugin_Flag_Infinite[0],flag)){
		
		if(adminid == INVALID_ADMIN_ID){
			
			Client_PrintDebug(client,"You are NOT allowed to infinite jump now! (%s)",g_szPlugin_Flag_Infinite);
			g_bAllow_InfiniteJump[client] = false;
		}
		else if(GetAdminFlag(adminid,flag)){
			
			Client_PrintDebug(client,"You are allowed to infinite jump now! (%s)",g_szPlugin_Flag_Infinite);
			g_bAllow_InfiniteJump[client] = true;
		}
		else {
			
			Client_PrintDebug(client,"You are NOT allowed to infinite jump now! (%s)",g_szPlugin_Flag_Infinite);
			g_bAllow_InfiniteJump[client] = false;
		}
	}
	else {
		
		Client_PrintDebug(client,"You are allowed to infinite jump now! (%s)",g_szPlugin_Flag_Infinite);
		g_bAllow_InfiniteJump[client] = true;
	}
	
	//g_bAllow_DoubleJump:
	if(StrEqual(g_szPlugin_Flag_Double,"0",false)){
		
		Client_PrintDebug(client,"You are NOT allowed to double jump now! (%s)",g_szPlugin_Flag_Double);
		g_bAllow_DoubleJump[client] = false;
	}
	else if(FindFlagByChar(g_szPlugin_Flag_Double[0],flag)){
		
		if(adminid == INVALID_ADMIN_ID){
			
			Client_PrintDebug(client,"You are NOT allowed to double jump now! (%s)",g_szPlugin_Flag_Double);
			g_bAllow_DoubleJump[client] = false;
		}
		else if(GetAdminFlag(adminid,flag)){
			
			Client_PrintDebug(client,"You are allowed to double jump now! (%s)",g_szPlugin_Flag_Double);
			g_bAllow_DoubleJump[client] = true;
		}
		else {
			
			Client_PrintDebug(client,"You are NOT allowed to double jump now! (%s)",g_szPlugin_Flag_Double);
			g_bAllow_DoubleJump[client] = false;
		}
	}
	else {
		
		Client_PrintDebug(client,"You are allowed to double jump now! (%s)",g_szPlugin_Flag_Double);
		g_bAllow_DoubleJump[client] = true;
	}
	
	//g_bAllow_PerfectDoubleJump:
	if(StrEqual(g_szPlugin_Flag_PerfectDouble,"0",false)){
		
		Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_PerfectDouble);
		g_bAllow_PerfectDoubleJump[client] = false;
	}
	else if(FindFlagByChar(g_szPlugin_Flag_PerfectDouble[0],flag)){
		
		if(adminid == INVALID_ADMIN_ID){
			
			Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_PerfectDouble);
			g_bAllow_PerfectDoubleJump[client] = false;
		}
		else if(GetAdminFlag(adminid,flag)){
			
			Client_PrintDebug(client,"You are allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_PerfectDouble);
			g_bAllow_PerfectDoubleJump[client] = true;
		}
		else {
			
			Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_PerfectDouble);
			g_bAllow_PerfectDoubleJump[client] = false;
		}
	}
	else {
		
		Client_PrintDebug(client,"You are allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_PerfectDouble);
		g_bAllow_PerfectDoubleJump[client] = true;
	}
	
	
	
	//g_bAllow_AntiSlowDowns:
	if(StrEqual(g_szPlugin_Flag_GameSlowDowns,"0",false)){
		
		Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_GameSlowDowns);
		g_bAllow_AntiSlowDowns[client] = false;
	}
	else if(FindFlagByChar(g_szPlugin_Flag_GameSlowDowns[0],flag)){
		
		if(adminid == INVALID_ADMIN_ID){
			
			Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_GameSlowDowns);
			g_bAllow_AntiSlowDowns[client] = false;
		}
		else if(GetAdminFlag(adminid,flag)){
			
			Client_PrintDebug(client,"You are allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_GameSlowDowns);
			g_bAllow_AntiSlowDowns[client] = true;
		}
		else {
			
			Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_GameSlowDowns);
			g_bAllow_AntiSlowDowns[client] = false;
		}
	}
	else {
		
		Client_PrintDebug(client,"You are allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_GameSlowDowns);
		g_bAllow_AntiSlowDowns[client] = true;
	}
	
	
	
	
	//g_bAllow_ForwardBoost:
	if(StrEqual(g_szPlugin_Flag_ForwardBoost,"0",false)){
		
		Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_ForwardBoost);
		g_bAllow_ForwardBoost[client] = false;
	}
	else if(FindFlagByChar(g_szPlugin_Flag_ForwardBoost[0],flag)){
		
		if(adminid == INVALID_ADMIN_ID){
			
			Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_ForwardBoost);
			g_bAllow_ForwardBoost[client] = false;
		}
		else if(GetAdminFlag(adminid,flag)){
			
			Client_PrintDebug(client,"You are allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_ForwardBoost);
			g_bAllow_ForwardBoost[client] = true;
		}
		else {
			
			Client_PrintDebug(client,"You are NOT allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_ForwardBoost);
			g_bAllow_ForwardBoost[client] = false;
		}
	}
	else {
		
		Client_PrintDebug(client,"You are allowed to perfectdouble jump now! (%s)",g_szPlugin_Flag_ForwardBoost);
		g_bAllow_ForwardBoost[client] = true;
	}
}





