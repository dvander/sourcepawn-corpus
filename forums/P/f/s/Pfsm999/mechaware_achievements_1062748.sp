/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNIIIIIMMMMM?MMMMMMMMMMMMMMM
MMMMMMMMMMIIIIIIIIIMMMMMIIIIIMMMMMMMMMMM
MMMMMMMMIIIIIIIIIIIMMMMMIIIIIIIMMMMMMMMM
MMMMMMI7IIIIIIIIII8MMMMMIIIIIIIIIMMMMMMM
MMMMM77777777IIIIIMMMMMMIIIIIIIIIIMMMMMM
MMMM77777777777777MMMMMIIIIIIIIIIIIMMMMM
MMM777777777777777MMMMMIIIIIIIIII$$$MMMM
MMD777777777777MMMMMMMMM777III$$$$$$DMMM
MMMMMMMZ777777MMMMMMMMMMMO77$$$$$$$$$MMM
MMMMMMMMMMMMMMMMMMMMMMMMMMZZZZZZZZZZZMMM
MMMMMMMMM________________________ZZZZMMM
MMMMMMMM|TF2 ACHIEVEMENT PLUGIN |MMMMMMM
MM$$$$$$[_______________________|MMMMMMM
MMZZZZZZZZZZZMMMMMMMMMMMMMZ8MMMMMMMMMMMM
MM8OOOOOOOOOOOMMMMMMMMMMMOOOOOOOOOOO8MMM
MMMOOOOOOOOOOOOOMMMMMMOOOOOOOOOOOOOOMMMM
MMMMOOOOOOOOOOOOMMMMMOOOOOOOOOOOOOOMMMMM
MMMMMOOOOOOOOOOOMMMMM8888888888888MMMMMM
MMMMMMO88888888OMMMMM888888888888MMMMMMM
MMMMMMMM8888888MMMMMM8888888888MMMMMMMMM
MMMMMMMMMM88888MMMMMN88888888MMMMMMMMMMM
MMMMMMMMMMMMMD8MMMMM8DDDDDMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>

#define ACHIEVEMENT_SOUND 		"misc/achievement_earned.wav"
#define ACHIEVEMENT_PARTICLE 	"Achieved"
#define SCORED_SOUND			"player/taunt_bell.wav"
#define PLUGIN_VERSION			"0.7 build 8"
#define PLUGIN_NAME				"Custom Achievements"
#define PLUGIN_AUTHOR			"Pfsm999 & Mecha the Slag"
#define PLUGIN_DESCRIPTION		"Custom Achievements for Team Fortress 2 through SQL"
#define PLUGIN_URL				"www.mechaware.net"
 
#define DMG_VEHICLE				(1<<4)  //16
#define DMG_NERVEGAS			(1<<14) //65536
#define DMG_FALL				(1<<5)  //32
#define DF_CRITS				(1<<20) //1048576 = DAMAGE_ACID
#define DF_CRITS_BUFFBANNER		(1<<16)	//16
#define DF_CRITS_JARATE			(1<<22)	//4194304 
/*---------------------------------------------------------------------------------
V A R I A B L E S    H A N D L E S 
---------------------------------------------------------------------------------*/
new Handle:g_CVINFO 		= INVALID_HANDLE;
new Handle:g_CVURL 			= INVALID_HANDLE;
new Handle:g_CVDB 			= INVALID_HANDLE;
new Handle:g_CVTABLEPREFIX 	= INVALID_HANDLE;
new Handle:g_HDATABASE		= INVALID_HANDLE;	/** Database connection */
new Handle:g_CVMENU 		= INVALID_HANDLE;
new Handle:g_CVANNONCE 		= INVALID_HANDLE;
new Handle:g_CVCHATMOTD		= INVALID_HANDLE;
new Handle:g_CVCHATMENU		= INVALID_HANDLE;
/*---------------------------------------------------------------------------------
V A R I A B L E S    A C H I E V E M E N T S 
---------------------------------------------------------------------------------*/
new Handle:g_LIST_ACHIEVEMENTS_ID 				= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_NAME				= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_DESCRIPTION		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_TRIGGERS			= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_RESETDEATH		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_ONCOMPLETE		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_RESETTIME		= INVALID_HANDLE;
//RESET IN DEATH
new Handle:g_LIST_ACHIEVEMENTS_RESETINDEATH		= INVALID_HANDLE;
//---Block A 
new Handle:g_LIST_ACHIEVEMENTS_BLOCKA_TYPE		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKA_ID		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKA_MAX		= INVALID_HANDLE;
//---Block B
new Handle:g_LIST_ACHIEVEMENTS_BLOCKB_TYPE		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKB_ID		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKB_MAX		= INVALID_HANDLE;
//----Block C
new Handle:g_LIST_ACHIEVEMENTS_BLOCKC_TYPE		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKC_ID		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKC_MAX		= INVALID_HANDLE;
//---Block D
new Handle:g_LIST_ACHIEVEMENTS_BLOCKD_TYPE		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKD_ID		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKD_MAX		= INVALID_HANDLE;
//----Block E
new Handle:g_LIST_ACHIEVEMENTS_BLOCKE_TYPE		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKE_ID		= INVALID_HANDLE;
new Handle:g_LIST_ACHIEVEMENTS_BLOCKE_MAX		= INVALID_HANDLE;
/*---------------------------------------------------------------------------------
V A R I A B L E S    U S E R    A C H I E V E M E N T S
---------------------------------------------------------------------------------*/
new Handle:g_LIST_USERS_ACH_ID					= INVALID_HANDLE;
new Handle:g_LIST_USERS_ACH_STEAMID				= INVALID_HANDLE;
new Handle:g_LIST_USERS_ACH_ACHID				= INVALID_HANDLE;
new Handle:g_LIST_USERS_ACH_STATUS				= INVALID_HANDLE;
new Handle:g_LIST_USERS_ACH_COMPLETE			= INVALID_HANDLE;
/*---------------------------------------------------------------------------------
V A R I A B L E S    U S E R    B L O C K S
---------------------------------------------------------------------------------*/
new Handle:g_LIST_USERS_BLOCKS_ID				= INVALID_HANDLE;
new Handle:g_LIST_USERS_BLOCKS_STEAMID			= INVALID_HANDLE;
new Handle:g_LIST_USERS_BLOCKS_BLOCK_TYP		= INVALID_HANDLE;
new Handle:g_LIST_USERS_BLOCKS_BLOCK_ID			= INVALID_HANDLE;
new Handle:g_LIST_USERS_BLOCKS_STATUS			= INVALID_HANDLE;
//--------------------------------VARIABLE BOOLEAN----------------------------------*/
new boolean:g_BCONNECTED;
/*---------------------------------------------------------------------------------
V A R I A B L E S    I N T E G E R
---------------------------------------------------------------------------------*/
new g_MOTD_RANDOM 		        = 0;
new g_MAX_BLOCKS		        = 5;
new g_MAXACHIEVEMENTS 	        = 0;
new g_ACHIEVEMENTSRESET	        = 0;
new g_MAXOTHER		 	        = 0;
new g_USERS_ACH 		        = 0;
new g_USERS_BLOCKS 		        = 0;
new g_BLOCKS_KILL		        = 0;
new g_BLOCKS_CONDITION 	        = 0;
new g_BLOCKS_CAPTURE 	        = 0;
new g_BLOCKS_SAY 		        = 0;
new g_BLOCKS_HURT 		        = 0;
new g_BLOCKS_ENGINEER_PDA       = 0;      // Engineer count for Destruc/Construc
new g_BLOCKS_ENGINEER_TELEPORT  = 0;      // Engineer count for teleport
new g_BLOCKS_STEALSANDWICH      = 0;      // Heavy count
new g_BLOCKS_UBERCHARGE	        = 0;      // Medic count
new g_BLOCKS_STUNNER	        = 0;      // Scout count
new g_BLOCKS_JARATE		        = 0;      // Sniper count
new g_BLOCKS_RAZORBACK	        = 0;      // Spy  Count
new g_BLOCKS_CALLMEDIC	        = 0;      // Call medic count
new g_BLOCKS_EATSANDWICH	    = 0;      // Eat Sandwitch  count
new g_BLOCKS_BONK 				= 0;	  // Bonk count
new g_FOCUSCLIENT 		        = 0;
new g_FOCUSACHID 		        = 0;

new g_CLIENTHATS[MAXPLAYERS + 1];
new g_CLIENTCONDITION[MAXPLAYERS + 1];
new g_CONFIGPROGRESSION[MAXPLAYERS + 1]; 
new String:g_DELETEACHIEVEMENT[MAXPLAYERS + 1][500];
new String:g_TIMEACHIEVEMENT[MAXPLAYERS + 1][500];
new String:g_NameOfAchievement[300];
/*---------------------------------------------------------------------------------
F I L E S   I N C L U D E S
---------------------------------------------------------------------------------*/
#include "mwach/capture.inc"
#include "mwach/say.inc"
#include "mwach/condition.inc"
#include "mwach/hurt.inc"
#include "mwach/oncomplete.inc"
#include "mwach/engineer.inc"
#include "mwach/kill.inc"
#include "mwach/heavy.inc"
#include "mwach/medic.inc"
#include "mwach/scout.inc"
#include "mwach/sniper.inc" 
#include "mwach/spy.inc"
#include "mwach/hats.inc"
#include "mwach/menu.inc"
#include "mwach/resettimer.inc"

/*---------------------------------------------------------------------------------
I N F O  P L U G I N
---------------------------------------------------------------------------------*/
//Information Regarding the plugin.
public Plugin:myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version 	= PLUGIN_VERSION,
	url 		= PLUGIN_URL
}
/*---------------------------------------------------------------------------------
W H E N  T H E  P L U G I N  I S  C H A R G E D
---------------------------------------------------------------------------------*/
//Loaded methods automatically called by Sourcemod !
public OnPluginStart()
{    
	// Plugin is TF2 only
	decl String:strNameOfMod[32]; GetGameFolderName(strNameOfMod, sizeof(strNameOfMod));
	if (!StrEqual(strNameOfMod, "tf")) SetFailState("This plugin is TF2 only.");
	LoadTranslations("mechaware.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	// Create cvars
	CreateConVar("mwach_version", PLUGIN_VERSION, "Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CVDB 			= CreateConVar("mwach_db", "achievement", "MySQL Database to use");
	g_CVTABLEPREFIX = CreateConVar("mwach_prefix", "achmw_", "MySQL Database Table Prefix");
	g_CVURL 		= CreateConVar("mwach_url", "http://mechaware.net/tf2/achievements/index.php", "Url to php file showing achievements",FCVAR_NOTIFY);
	RegAdminCmd		("mwach_refresh", RequestRefresh, ADMFLAG_SLAY);
	g_CVINFO 	    = CreateConVar("mwach_info", "0", "Show Achievement Info to Player on Unlocked? (0 = none, 1 = all, 2 = Player)",FCVAR_NOTIFY);
	g_CVMENU 	    = CreateConVar("mwach_menu", "1", "Show Sourcemod menu to Player? (0 = no, 1 = yes)",FCVAR_NOTIFY);
	g_CVANNONCE	    = CreateConVar("mwach_announce", "1", "Announce the plugin and possibility (0 = no, 1 = yes)",FCVAR_NOTIFY);
	g_CVCHATMOTD    = CreateConVar("mwach_chatmotd", "/show_ach", "String for chat to show the motd page with player informations. (don't forget the /)",FCVAR_NOTIFY);
	g_CVCHATMENU    = CreateConVar("mwach_chatmenu", "/ach", "String for chat to show the sourcemod menu with player informations. (don't forget the /)",FCVAR_NOTIFY);
	AutoExecConfig(true, "mwach_cfg");
	
	// Hook blocks
	HookEvent		("player_death", blocks_kill_pre);
	HookEvent		("player_hurt", blocks_hurt);
	HookEvent		("teamplay_point_captured", blocks_capture);
	RegConsoleCmd	("say", blocks_say);
	RegConsoleCmd	("say", motd_say);
	RegConsoleCmd	("say", menu_say);
	HookEvent       ("player_builtobject", blocks_engineer_construction);
	HookEvent       ("object_destroyed", blocks_kill_object);
	HookEvent		("player_teleported", blocks_engineer_teleport);
	HookEvent		("player_stealsandvich", blocks_heavy_steal);
	HookEvent		("player_chargedeployed", blocks_medic_uber);
	HookEvent		("player_stunned", blocks_stunner);
	HookUserMessage	(GetUserMessageId("VoiceSubtitle"), blocks_callmedic);
	HookEvent		("player_spawn", eventPlayerSpawn);
	HookEvent		("post_inventory_application", eventInventChange,  EventHookMode_Post);
	
	HookUserMessage(GetUserMessageId("PlayerJarated"), blocks_sniper_jarate);
	HookUserMessage(GetUserMessageId("PlayerShieldBlocked"), blocks_razorback);
	AddNormalSoundHook(NormalSHook:HookSound_HeavyEat);
	
	HookConVarChange(g_CVDB,          			UpdateCvar);
	HookConVarChange(g_CVTABLEPREFIX,           UpdateCvar);
	HookConVarChange(g_CVURL,        			UpdateCvar);
	HookConVarChange(g_CVINFO,             		UpdateCvar);
	HookConVarChange(g_CVMENU,       			UpdateCvar);
	HookConVarChange(g_CVANNONCE,  				UpdateCvar);
	HookConVarChange(g_CVCHATMOTD,         		UpdateCvar);
	HookConVarChange(g_CVCHATMENU,         		UpdateCvar);
	
}
/*---------------------------------------------------------------------------------
W H E N  T H E  P L U G I N  E N D
---------------------------------------------------------------------------------*/
public OnPluginEnd()
{
	CloseHandlePacks();
	CloseHandleCVar();
	if (g_HDATABASE != INVALID_HANDLE)
	{
		CloseHandle(g_HDATABASE);
		g_HDATABASE = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	if (g_HDATABASE != INVALID_HANDLE)
	{
		CloseHandle(g_HDATABASE);
		OnConfigsExecuted();
	}
	ResetAllOneLife();
}

public UpdateCvar(Handle:hHandle, String:strOldVal[], String:strNewVal[])
{
	LogMessage("Cvar change");
}

/*---------------------------------------------------------------------------------
T O  P R E L O A D  M A T E R I A L S
---------------------------------------------------------------------------------*/
public Action:PreloadMaterials()
{
	// Preload Achievement Notification
	PrecacheSound(ACHIEVEMENT_SOUND);
	PrecacheSound(SCORED_SOUND);
	return Plugin_Handled;
}

/*---------------------------------------------------------------------------------
W H E N  P L U G I N   I S   R E F R E S H
---------------------------------------------------------------------------------*/
public Action:RequestRefresh(argClient, args)
{
	OnConfigsExecuted();
	LogMessage("Refresh of Custom achievement : Done");
	return Plugin_Handled;
} 
/*---------------------------------------------------------------------------------
A N N O U N C E  T I M E R 
---------------------------------------------------------------------------------*/
public Action:Timer_Welcome(Handle:hTimer, any:argClient)
{
	new String:strChatMOTD[128];
	new String:strChatMENU[128];
	new strCVMENU = GetConVarInt(g_CVMENU);
	GetConVarString(g_CVCHATMOTD, strChatMOTD, sizeof(strChatMOTD));
	GetConVarString(g_CVCHATMENU, strChatMENU, sizeof(strChatMENU)); 
	
	if (argClient < 1 || argClient > MaxClients) return Plugin_Stop;
	if (!IsValidClient(argClient)) return Plugin_Stop;
	CPrintToChat(argClient, "%T", "Announce_Text", LANG_SERVER, PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	if(strCVMENU == 1)
		CPrintToChat(argClient, "%T", "Announce_Explain", LANG_SERVER,strChatMENU);
	else
	CPrintToChat(argClient, "%T", "Announce_Explain", LANG_SERVER,strChatMOTD);
	return Plugin_Stop;
}

/*---------------------------------------------------------------------------------
D A T A B A S E  C A C H E
---------------------------------------------------------------------------------*/
public CloseHandlePacks() 
{
	MustCloseHandle (g_LIST_ACHIEVEMENTS_ID); 			
	MustCloseHandle (g_LIST_ACHIEVEMENTS_NAME);  		
	MustCloseHandle (g_LIST_ACHIEVEMENTS_DESCRIPTION);  
	MustCloseHandle (g_LIST_ACHIEVEMENTS_TRIGGERS);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_RESETDEATH);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_ONCOMPLETE); 
	MustCloseHandle (g_LIST_ACHIEVEMENTS_RESETTIME);
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKA_TYPE);  
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKA_ID);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKA_MAX);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKB_TYPE);  
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKB_ID);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKB_MAX);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKC_TYPE);  
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKC_ID);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKC_MAX);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKD_TYPE);  
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKD_ID);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKD_MAX); 	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKE_TYPE);  
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKE_ID);  	
	MustCloseHandle (g_LIST_ACHIEVEMENTS_BLOCKE_MAX); 
	MustCloseHandle (g_LIST_ACHIEVEMENTS_RESETINDEATH);
	MustCloseHandle (g_LIST_USERS_ACH_ID); 		        
	MustCloseHandle (g_LIST_USERS_ACH_STEAMID);         
	MustCloseHandle (g_LIST_USERS_ACH_ACHID); 	        
	MustCloseHandle (g_LIST_USERS_ACH_STATUS); 	        
	MustCloseHandle (g_LIST_USERS_ACH_COMPLETE);        
	MustCloseHandle (g_LIST_USERS_BLOCKS_ID); 
	MustCloseHandle (g_LIST_USERS_BLOCKS_STEAMID); 
	MustCloseHandle (g_LIST_USERS_BLOCKS_BLOCK_TYP); 
	MustCloseHandle (g_LIST_USERS_BLOCKS_BLOCK_ID); 
	MustCloseHandle (g_LIST_USERS_BLOCKS_STATUS); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_ID);
	MustCloseHandle (g_LIST_BLOCKS_KILL_WINNER); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_ATTACKERID); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_VICTIMID); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_ASSISTERID); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_WEAPONS); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_MAP); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_ATTACKCLASS); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_VICTIMCLASS); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_ASSISTCLASS); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_SELFDMG); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_CRIT); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_DOMINATION); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_REVENGE); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_HEADSHOT); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_BACKSTAB); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_DEADRINGER); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_OBJECT); 
	MustCloseHandle (g_LIST_BLOCKS_KILL_WASBUILD); 
	MustCloseHandle (g_LIST_BLOCKS_CONDITION_ID );
	MustCloseHandle (g_LIST_BLOCKS_CONDITION_TYPE );
	MustCloseHandle (g_LIST_BLOCKS_CONDITION_TARGET); 
	MustCloseHandle (g_LIST_BLOCKS_CONDITION_INT1 );
	MustCloseHandle (g_LIST_BLOCKS_CONDITION_INT2 );
	MustCloseHandle (g_LIST_BLOCKS_CONDITION_INT3 );
	MustCloseHandle (g_LIST_BLOCKS_CAP_ID);
	MustCloseHandle (g_LIST_BLOCKS_CAP_WINNER);
	MustCloseHandle (g_LIST_BLOCKS_CAP_CAPTURETEAM);
	MustCloseHandle (g_LIST_BLOCKS_CAP_MAP);
	MustCloseHandle (g_LIST_BLOCKS_CAP_CAPTUREID);
	MustCloseHandle (g_LIST_BLOCKS_CAP_CPID);
	MustCloseHandle (g_LIST_BLOCKS_CAP_MINCAPPERS);
	MustCloseHandle (g_LIST_BLOCKS_CAP_MAXCAPPERS);
	MustCloseHandle (g_LIST_BLOCKS_CAP_CAPTURERCLASS);		
	MustCloseHandle (g_LIST_BLOCKS_SAY_ID );
	MustCloseHandle (g_LIST_BLOCKS_SAY_METHOD );
	MustCloseHandle (g_LIST_BLOCKS_SAY_CONTENT );
	MustCloseHandle (g_LIST_BLOCKS_SAY_MAP );
	MustCloseHandle (g_LIST_BLOCKS_HURT_ID );
	MustCloseHandle (g_LIST_BLOCKS_HURT_WINNER );
	MustCloseHandle (g_LIST_BLOCKS_HURT_ATTACKERID );
	MustCloseHandle (g_LIST_BLOCKS_HURT_VICTIMID );
	MustCloseHandle (g_LIST_BLOCKS_HURT_CRIT );
	MustCloseHandle (g_LIST_BLOCKS_HURT_DMGMIN );
	MustCloseHandle (g_LIST_BLOCKS_HURT_DMGMAX );
	MustCloseHandle (g_LIST_BLOCKS_HURT_SELFDMG );
	MustCloseHandle (g_LIST_BLOCKS_HURT_MAP );
	MustCloseHandle (g_LIST_BLOCKS_HURT_ATTACKCLASS);
	MustCloseHandle (g_LIST_BLOCKS_HURT_VICTIMCLASS );
	MustCloseHandle (g_LIST_BLOCKS_ENGI_PDA_ID);
	MustCloseHandle (g_LIST_BLOCKS_ENGI_PDA_OBJECT);
	MustCloseHandle (g_LIST_BLOCKS_ENGI_TELE_ID);
	MustCloseHandle (g_LIST_BLOCKS_ENGI_TELE_WINNER);
	MustCloseHandle (g_LIST_BLOCKS_ENGI_TELE_OWNERID);
	MustCloseHandle (g_LIST_BLOCKS_ENGI_TELE_USERID);
	MustCloseHandle (g_LIST_BLOCKS_ENGI_TELE_USERCLASS);
	MustCloseHandle (g_LIST_BLOCKS_ENGI_TELE_SELFUSE);
	MustCloseHandle (g_LIST_BLOCKS_STEALSANDWICH_ID);
	MustCloseHandle (g_LIST_BLOCKS_STEALSANDWICH_WINNER);
	MustCloseHandle (g_LIST_BLOCKS_EATSANDWICH_ID);
	MustCloseHandle (g_LIST_BLOCKS_UBERCHARGE_ID);
	MustCloseHandle (g_LIST_BLOCKS_UBERCHARGE_WINNER);
	MustCloseHandle (g_LIST_BLOCKS_UBERCHARGE_WEAPONS_UBER);
	MustCloseHandle (g_LIST_BLOCKS_STUNNER_ID);
	MustCloseHandle (g_LIST_BLOCKS_STUNNER_WINNER);
	MustCloseHandle (g_LIST_BLOCKS_BONK_ID);
	MustCloseHandle (g_LIST_BLOCKS_JARATE_ID);
	MustCloseHandle (g_LIST_BLOCKS_JARATE_WINNER);  
	MustCloseHandle (g_LIST_BLOCKS_RAZORBACK_ID);
	MustCloseHandle (g_LIST_BLOCKS_RAZORBACK_WINNER);
	MustCloseHandle (g_LIST_BLOCKS_CALLMEDIC_ID);
}
/*---------------------------------------------------------------------------------
MustCloseHandle
It's a function who close a valid Handle
---------------------------------------------------------------------------------*/
public MustCloseHandle( Handle:argHandle )
{
	if( argHandle != INVALID_HANDLE )
	{
		CloseHandle(argHandle);
	}
	argHandle = INVALID_HANDLE;
}

/*---------------------------------------------------------------------------------
CloseHandleCVar
It's a function who close all cvar Handle
---------------------------------------------------------------------------------*/
public CloseHandleCVar() 
{
	MustCloseHandle( g_CVDB );
	MustCloseHandle( g_CVTABLEPREFIX );
	MustCloseHandle( g_CVURL );
	MustCloseHandle( g_CVINFO );
	MustCloseHandle( g_CVMENU );
	MustCloseHandle( g_CVANNONCE );
	MustCloseHandle( g_CVCHATMOTD );
	MustCloseHandle( g_CVCHATMENU );
}

/*---------------------------------------------------------------------------------
CreateHandlePacks
It's a function who create all Handle Packs necessary for achievement
---------------------------------------------------------------------------------*/
public CreateHandlePacks() 
{
	new arraySizeString 			= ByteCountToCells(200);
	g_LIST_ACHIEVEMENTS_ID 			= CreateArray();
	g_LIST_ACHIEVEMENTS_NAME 		= CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_DESCRIPTION = CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_TRIGGERS 	= CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_RESETDEATH 	= CreateArray();
	g_LIST_ACHIEVEMENTS_ONCOMPLETE	= CreateArray();
	g_LIST_ACHIEVEMENTS_RESETTIME	= CreateArray();
	//---Block A
	g_LIST_ACHIEVEMENTS_BLOCKA_TYPE = CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_BLOCKA_ID 	= CreateArray();
	g_LIST_ACHIEVEMENTS_BLOCKA_MAX 	= CreateArray();
	//---Block B
	g_LIST_ACHIEVEMENTS_BLOCKB_TYPE = CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_BLOCKB_ID 	= CreateArray();
	g_LIST_ACHIEVEMENTS_BLOCKB_MAX 	= CreateArray();
	//----Block C
	g_LIST_ACHIEVEMENTS_BLOCKC_TYPE = CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_BLOCKC_ID 	= CreateArray();
	g_LIST_ACHIEVEMENTS_BLOCKC_MAX 	= CreateArray();
	//---Block D
	g_LIST_ACHIEVEMENTS_BLOCKD_TYPE = CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_BLOCKD_ID 	= CreateArray();
	g_LIST_ACHIEVEMENTS_BLOCKD_MAX	= CreateArray();
	//----Block E
	g_LIST_ACHIEVEMENTS_BLOCKE_TYPE = CreateArray(arraySizeString);
	g_LIST_ACHIEVEMENTS_BLOCKE_ID 	= CreateArray();
	g_LIST_ACHIEVEMENTS_BLOCKE_MAX 	= CreateArray();
	
	g_LIST_ACHIEVEMENTS_RESETINDEATH = CreateArray();
	g_LIST_USERS_ACH_ID		        = CreateArray(arraySizeString);
	g_LIST_USERS_ACH_STEAMID        = CreateArray(arraySizeString);
	g_LIST_USERS_ACH_ACHID	        = CreateArray();
	g_LIST_USERS_ACH_STATUS	        = CreateArray();
	g_LIST_USERS_ACH_COMPLETE       = CreateArray();
	
	g_LIST_USERS_BLOCKS_ID 	        = CreateArray(arraySizeString); 
	g_LIST_USERS_BLOCKS_STEAMID 	= CreateArray(arraySizeString); 
	g_LIST_USERS_BLOCKS_BLOCK_TYP 	= CreateArray(arraySizeString); 
	g_LIST_USERS_BLOCKS_BLOCK_ID  	= CreateArray(); 
	g_LIST_USERS_BLOCKS_STATUS 	    = CreateArray(); 
	
	g_LIST_BLOCKS_KILL_ID 			= CreateArray();
	g_LIST_BLOCKS_KILL_WINNER		= CreateArray(); 
	g_LIST_BLOCKS_KILL_ATTACKERID	= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_VICTIMID		= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_ASSISTERID	= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_WEAPONS		= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_MAP			= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_ATTACKCLASS	= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_VICTIMCLASS	= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_ASSISTCLASS	= CreateArray(arraySizeString); 
	g_LIST_BLOCKS_KILL_SELFDMG		= CreateArray(); 
	g_LIST_BLOCKS_KILL_CRIT			= CreateArray(); 
	g_LIST_BLOCKS_KILL_DOMINATION	= CreateArray(); 
	g_LIST_BLOCKS_KILL_REVENGE		= CreateArray(); 
	g_LIST_BLOCKS_KILL_HEADSHOT		= CreateArray(); 
	g_LIST_BLOCKS_KILL_BACKSTAB		= CreateArray(); 
	g_LIST_BLOCKS_KILL_DEADRINGER	= CreateArray(); 
	g_LIST_BLOCKS_KILL_OBJECT		= CreateArray(); 
	g_LIST_BLOCKS_KILL_WASBUILD		= CreateArray(); 
	
	g_LIST_BLOCKS_CONDITION_ID 		= CreateArray();
	g_LIST_BLOCKS_CONDITION_TYPE 	= CreateArray();
	g_LIST_BLOCKS_CONDITION_TARGET	= CreateArray(); 
	g_LIST_BLOCKS_CONDITION_INT1 	= CreateArray();
	g_LIST_BLOCKS_CONDITION_INT2 	= CreateArray();
	g_LIST_BLOCKS_CONDITION_INT3 	= CreateArray();
	
	g_LIST_BLOCKS_CAP_ID			= CreateArray();
	g_LIST_BLOCKS_CAP_WINNER		= CreateArray();
	g_LIST_BLOCKS_CAP_CAPTURETEAM	= CreateArray();
	g_LIST_BLOCKS_CAP_MAP			= CreateArray(arraySizeString);
	g_LIST_BLOCKS_CAP_CAPTUREID		= CreateArray(arraySizeString);
	g_LIST_BLOCKS_CAP_CPID			= CreateArray();
	g_LIST_BLOCKS_CAP_MINCAPPERS	= CreateArray();
	g_LIST_BLOCKS_CAP_MAXCAPPERS	= CreateArray();
	g_LIST_BLOCKS_CAP_CAPTURERCLASS	= CreateArray(arraySizeString);		
	
	g_LIST_BLOCKS_SAY_ID 			= CreateArray();
	g_LIST_BLOCKS_SAY_METHOD 		= CreateArray();
	g_LIST_BLOCKS_SAY_CONTENT 		= CreateArray(arraySizeString);
	g_LIST_BLOCKS_SAY_MAP 			= CreateArray(arraySizeString);
	
	g_LIST_BLOCKS_HURT_ID 			= CreateArray();
	g_LIST_BLOCKS_HURT_WINNER 		= CreateArray();
	g_LIST_BLOCKS_HURT_ATTACKERID 	= CreateArray(arraySizeString);
	g_LIST_BLOCKS_HURT_VICTIMID 	= CreateArray(arraySizeString);
	g_LIST_BLOCKS_HURT_CRIT 		= CreateArray();
	g_LIST_BLOCKS_HURT_DMGMIN 		= CreateArray();
	g_LIST_BLOCKS_HURT_DMGMAX 		= CreateArray();
	g_LIST_BLOCKS_HURT_SELFDMG		= CreateArray();
	g_LIST_BLOCKS_HURT_MAP 			= CreateArray();
	g_LIST_BLOCKS_HURT_ATTACKCLASS	= CreateArray(arraySizeString);
	g_LIST_BLOCKS_HURT_VICTIMCLASS 	= CreateArray(arraySizeString);
	
	g_LIST_BLOCKS_ENGI_PDA_ID		= CreateArray();
	g_LIST_BLOCKS_ENGI_PDA_OBJECT	= CreateArray();
	
	g_LIST_BLOCKS_ENGI_TELE_ID		= CreateArray();
	g_LIST_BLOCKS_ENGI_TELE_WINNER	= CreateArray();
	g_LIST_BLOCKS_ENGI_TELE_OWNERID	= CreateArray(arraySizeString);
	g_LIST_BLOCKS_ENGI_TELE_USERID	= CreateArray(arraySizeString);
	g_LIST_BLOCKS_ENGI_TELE_USERCLASS= CreateArray(arraySizeString);
	g_LIST_BLOCKS_ENGI_TELE_SELFUSE	= CreateArray();
	
	g_LIST_BLOCKS_STEALSANDWICH_ID	= CreateArray();
	g_LIST_BLOCKS_STEALSANDWICH_WINNER= CreateArray();
	g_LIST_BLOCKS_EATSANDWICH_ID	= CreateArray();
	
	g_LIST_BLOCKS_UBERCHARGE_ID		= CreateArray();
	g_LIST_BLOCKS_UBERCHARGE_WINNER	= CreateArray();
	g_LIST_BLOCKS_UBERCHARGE_WEAPONS_UBER= CreateArray();
	
	g_LIST_BLOCKS_STUNNER_ID		= CreateArray();
	g_LIST_BLOCKS_STUNNER_WINNER	= CreateArray();
	
	g_LIST_BLOCKS_BONK_ID			= CreateArray();
	
	g_LIST_BLOCKS_JARATE_ID			= CreateArray();
	g_LIST_BLOCKS_JARATE_WINNER		= CreateArray();  
	
	g_LIST_BLOCKS_RAZORBACK_ID		= CreateArray();
	g_LIST_BLOCKS_RAZORBACK_WINNER	= CreateArray();
	
	g_LIST_BLOCKS_CALLMEDIC_ID	= CreateArray();
}
/*---------------------------------------------------------------------------------
ResetCache
Add on all array, all type of achievement
---------------------------------------------------------------------------------*/
ResetCache() 
{ 	
	RC_Achievements();
	RC_Blocks_Kill();
	RC_Blocks_Condition();
	RC_Blocks_Capture();
	RC_Blocks_Say();
	RC_Blocks_Hurt();
	RC_Blocks_Engineer_Pda();
	RC_Blocks_Engineer_Teleport();
	RC_Blocks_stealsandvitch();
	RC_Blocks_Ubercharge();
	RC_Blocks_Stunner();
	RC_Blocks_Bonk();
	RC_Blocks_Jarate();
	RC_Blocks_Razorback();
	RC_Blocks_CallMedic();
	RC_Blocks_eatsandwich();
}

/*---------------------------------------------------------------------------------
ClearAndResize
Clear all on the Handle and rezise array
---------------------------------------------------------------------------------*/
ClearAndResize(Handle:argTab, argSizeof)
{
	ClearArray(argTab);
	ResizeArray(argTab,argSizeof);
}

/*---------------------------------------------------------------------------------
RC_Achievements
Add all achievement table on arrays 
---------------------------------------------------------------------------------*/
RC_Achievements() {
	decl String:q_Query[255];
	new String:	strTablePrefix[128];
	GetConVarString		(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	Format				(q_Query, sizeof(q_Query), "SELECT * FROM `%sachievements`",strTablePrefix);
	SQL_TQuery			(g_HDATABASE, RC_Achievements_After_Query, q_Query);
}

/*---------------------------------------------------------------------------------
RC_AchievementReset
Add all achievement must be reset on death on arrays 
---------------------------------------------------------------------------------*/
RC_AchievementReset() {
	for(new i = 0; i < g_MAXACHIEVEMENTS; i++) 
	{
		if(GetArrayCell(g_LIST_ACHIEVEMENTS_RESETDEATH,i)==1)
		{
			PushArrayCell(g_LIST_ACHIEVEMENTS_RESETINDEATH, i);
		}
	}
}

public RC_Achievements_After_Query(Handle:owner, Handle:q_HQuery, const String:error[], any:data)
{
	if (q_HQuery == INVALID_HANDLE)
	{
		LogMessage("Failed to retrieve achievements list from the database, %s",error);
		return;
	}
	new strI 			= 0;
	g_MAXACHIEVEMENTS 	= SQL_GetRowCount(q_HQuery);
	new String: strString[512];
	
	ClearAndResize(g_LIST_ACHIEVEMENTS_ID,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_NAME,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_DESCRIPTION,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_TRIGGERS,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_RESETDEATH,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_ONCOMPLETE,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_RESETTIME,g_MAXACHIEVEMENTS+1);	
	
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKA_TYPE,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKA_ID,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKA_MAX,g_MAXACHIEVEMENTS+1);
	
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKB_TYPE,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKB_ID,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKB_MAX,g_MAXACHIEVEMENTS+1);
	
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKC_TYPE,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKC_ID,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKC_MAX,g_MAXACHIEVEMENTS+1);
	
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKD_TYPE,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKD_ID,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKD_MAX,g_MAXACHIEVEMENTS+1);
	
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKE_TYPE,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKE_ID,g_MAXACHIEVEMENTS+1);
	ClearAndResize(g_LIST_ACHIEVEMENTS_BLOCKE_MAX,g_MAXACHIEVEMENTS+1);
	while (SQL_FetchRow(q_HQuery)) {
		//0 - ach id
		SetArrayCell		(g_LIST_ACHIEVEMENTS_ID, strI, SQL_FetchInt(q_HQuery, 0));
		//1 - ach name
		SQL_FetchString		(q_HQuery, 1,strString,sizeof(strString));
		SetArrayString		(g_LIST_ACHIEVEMENTS_NAME, strI, strString);
		//2 - ach description
		SQL_FetchString		(q_HQuery, 2,strString,sizeof(strString));
		SetArrayString		(g_LIST_ACHIEVEMENTS_DESCRIPTION, strI, strString);
		//3 - ach triggers
		SetArrayCell		(g_LIST_ACHIEVEMENTS_TRIGGERS, strI, SQL_FetchInt(q_HQuery, 3));
		//6 - ach ResetOnDeath
		SetArrayCell		(g_LIST_ACHIEVEMENTS_RESETDEATH, strI, SQL_FetchInt(q_HQuery, 6));
		//7 - ach OnComplete
		SetArrayCell		(g_LIST_ACHIEVEMENTS_ONCOMPLETE, strI, SQL_FetchInt(q_HQuery, 7));
		SetArrayCell		(g_LIST_ACHIEVEMENTS_RESETTIME, strI, SQL_FetchInt(q_HQuery, 8));
		// ------ Blocks
		//4 - Block A type
		SQL_FetchString	(q_HQuery, 9,strString,sizeof(strString));
		SetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKA_TYPE, strI, strString);
		//5 - Block A id
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKA_ID, strI, SQL_FetchInt(q_HQuery, 10));
		//6 - Block A max
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKA_MAX, strI, SQL_FetchInt(q_HQuery, 11));
		//4 - Block B type
		SQL_FetchString	(q_HQuery, 12,strString,sizeof(strString));
		SetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKB_TYPE, strI, strString);
		//5 - Block B id
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKB_ID, strI, SQL_FetchInt(q_HQuery, 13));
		//6 - Block B max
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKB_MAX, strI, SQL_FetchInt(q_HQuery, 14));
		//4 - Block C type
		SQL_FetchString	(q_HQuery, 15,strString,sizeof(strString));
		SetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKC_TYPE, strI, strString);
		//5 - Block C id
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKC_ID, strI, SQL_FetchInt(q_HQuery, 16));
		//6 - Block C max
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKC_MAX, strI, SQL_FetchInt(q_HQuery, 17));
		//4 - Block D type
		SQL_FetchString	(q_HQuery, 18,strString,sizeof(strString));
		SetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKD_TYPE, strI, strString);
		//5 - Block D id
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKD_ID, strI, SQL_FetchInt(q_HQuery, 19));
		//6 - Block D max
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKD_MAX, strI, SQL_FetchInt(q_HQuery, 20));
		//4 - Block E type
		SQL_FetchString	(q_HQuery, 21,strString,sizeof(strString));
		SetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKE_TYPE, strI, strString);
		//5 - Block E id
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKE_ID, strI, SQL_FetchInt(q_HQuery, 22));
		//6 - Block E max
		SetArrayCell	(g_LIST_ACHIEVEMENTS_BLOCKE_MAX, strI, SQL_FetchInt(q_HQuery, 23));		
		// next
		strI = strI + 1;
	}
	RC_AchievementReset();
	ResetAllOneLife();
}

/*---------------------------------------------------------------------------------
A D D  O N   T A B L E  A L L  U S E R S  A C H I E V E M E N T S
---------------------------------------------------------------------------------*/
RC_Users_Ach(any:data=0) 
{
	decl String:	strQuery[255];
	new Handle:		strHQuery;
	new String:		strTablePrefix[128];
	GetConVarString	(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	Format			(strQuery, sizeof(strQuery), "SELECT * FROM `%susers_ach`",strTablePrefix);
	SQL_TQuery		(g_HDATABASE, RC_Users_Ach_After_Query, strQuery,data);
}

public RC_Users_Ach_After_Query(Handle:owner, Handle:strHQuery, const String:error[], any:data) 
{
	if (strHQuery == INVALID_HANDLE)
	{
		LogMessage("Failed to retrieve user achievements list from the database, %s",error);
		return;
	}
	new strI 		= 0;
	new String:		strString[512];
	g_MAXOTHER 		= SQL_GetRowCount(strHQuery);
	ClearAndResize(g_LIST_USERS_ACH_ID,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_ACH_STEAMID,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_ACH_ACHID,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_ACH_STATUS,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_ACH_COMPLETE,g_MAXOTHER);
	
	while (SQL_FetchRow(strHQuery)) {
		//0 - id
		SQL_FetchString(strHQuery, 0,strString,sizeof(strString));
		SetArrayString(g_LIST_USERS_ACH_ID, strI, strString);
		//1 - steamid
		SQL_FetchString(strHQuery, 1,strString,sizeof(strString));
		SetArrayString(g_LIST_USERS_ACH_STEAMID, strI, strString);
		//2 - achid
		SetArrayCell(g_LIST_USERS_ACH_ACHID, strI, SQL_FetchInt(strHQuery, 2));
		//3 - status
		SetArrayCell(g_LIST_USERS_ACH_STATUS, strI, SQL_FetchInt(strHQuery, 3));
		//4 - complete
		SetArrayCell(g_LIST_USERS_ACH_COMPLETE, strI, SQL_FetchInt(strHQuery, 4));
		strI = strI + 1
	}
	g_USERS_ACH = strI;
	if(data==1)
	{
		VerifyIfCompleteAch(g_FOCUSCLIENT,g_FOCUSACHID);
	}	
}

/*---------------------------------------------------------------------------------
A D D  O N   T A B L E  A L L  U S E R S  B L O C K S 
---------------------------------------------------------------------------------*/
RC_Users_Blocks() {
	decl String:	strQuery[255];
	new Handle:		strHQuery;
	new String:		strTablePrefix[128];
	GetConVarString(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	Format			(strQuery, sizeof(strQuery), "SELECT * FROM `%susers_blocks`",strTablePrefix);
	SQL_TQuery		(g_HDATABASE, RC_Users_Blocks_After_Query, strQuery);
}

public RC_Users_Blocks_After_Query(Handle:owner, Handle:strHQuery, const String:error[], any:data) 
{
	if (strHQuery == INVALID_HANDLE)
	{
		LogMessage("Failed to retrieve user blocks list from the database, %s",error);
		return;
	}
	new strI 		= 0;
	new String:	strString[100];
	g_MAXOTHER 		= SQL_GetRowCount(strHQuery);
	ClearAndResize(g_LIST_USERS_BLOCKS_ID,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_BLOCKS_STEAMID,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_BLOCKS_BLOCK_TYP,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_BLOCKS_BLOCK_ID,g_MAXOTHER);
	ClearAndResize(g_LIST_USERS_BLOCKS_STATUS,g_MAXOTHER);
	while (SQL_FetchRow(strHQuery)) {
		//0 - id
		SQL_FetchString	(strHQuery, 0,strString,sizeof(strString));
		SetArrayString	(g_LIST_USERS_BLOCKS_ID, strI, strString);
		//1 - steamid
		SQL_FetchString	(strHQuery, 1,strString,sizeof(strString));
		SetArrayString	(g_LIST_USERS_BLOCKS_STEAMID, strI, strString);
		//2 - block_typ
		SQL_FetchString	(strHQuery, 2,strString,sizeof(strString));
		SetArrayString	(g_LIST_USERS_BLOCKS_BLOCK_TYP, strI, strString);
		//3 - block_id
		SetArrayCell	(g_LIST_USERS_BLOCKS_BLOCK_ID, strI, SQL_FetchInt(strHQuery, 3));
		//4 - status
		SetArrayCell	(g_LIST_USERS_BLOCKS_STATUS, strI, SQL_FetchInt(strHQuery, 4));
		strI 			= strI + 1
	}
	g_USERS_BLOCKS 		= strI;
}

/*---------------------------------------------------------------------------------
W H E N  A L L  C O N F I G  W A S  E X E C U T E D
---------------------------------------------------------------------------------*/
public OnConfigsExecuted() {
	CloseHandlePacks();
	CreateHandlePacks();
	new String:strDB[128];
	GetConVarString		(g_CVDB, strDB, sizeof(strDB));
	if (SQL_CheckConfig(strDB))
	{
		SQL_TConnect	(cDatabaseConnect, strDB);
	}
	else
	{
		LogError		("Unable to open %s: No such database configuration.", strDB);
		g_BCONNECTED 	= false;
	}
	// Execute configs.
}

/*---------------------------------------------------------------------------------
D A T A B A S E   C O N N E C T I O N
---------------------------------------------------------------------------------*/
public cDatabaseConnect(Handle:arg_hOwner, Handle:argHQuery, const String:argsError[], any:argData) 
{
	new String:strDB[128];
	new String:strTablePrefix[128];
	GetConVarString		(g_CVDB, strDB, sizeof(strDB));
	GetConVarString		(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	if (argHQuery == INVALID_HANDLE)
	{
		LogError("Unable to connect to %s: %s", strDB, argsError);
		g_BCONNECTED = false;
	}
	else
	{
		g_HDATABASE = argHQuery;
		if (!SQL_FastQuery(argHQuery, "SET NAMES 'utf8'"))
		{
			LogError("Unable to change to utf8 mode.");
			g_BCONNECTED = false;
		}
		else
		{
			g_HDATABASE = argHQuery;
			g_BCONNECTED = true;
		}
		ResetCache();
		PreloadMaterials();
	}
}

public bool:IsDatabaseClosed()
{
	return !g_BCONNECTED;
}

/*---------------------------------------------------------------------------------
C L I E N T  A R R I V E
---------------------------------------------------------------------------------*/
public OnClientPutInServer(arghClient)
{
	if (GetConVarInt(g_CVANNONCE) == 1)
	{
		CreateTimer(50.0, Timer_Welcome, arghClient, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/*---------------------------------------------------------------------------------
S A V E  U S E R
---------------------------------------------------------------------------------*/
public OnClientPostAdminCheck(arghClient)
{
	SaveUser				(arghClient);
}

public SaveUser(arghClient)
{
	if (IsDatabaseClosed())
		return;
	if (!arghClient || IsFakeClient(arghClient))
		return;
	
	new String:strSteamId[128];
	new String:strName[128];
	new String:strEscapedName[128];
	new String:strTablePrefix[128];
	
	GetConVarString		(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	GetClientAuthString	(arghClient, strSteamId, sizeof(strSteamId));
	GetClientName		(arghClient,strName, sizeof(strName));
	SQL_EscapeString	(g_HDATABASE, strName, strEscapedName, sizeof(strEscapedName));
	new String:strQuery[512];
	Format(strQuery, sizeof(strQuery), "INSERT INTO `%susers` (`steamid`, `name`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`)", strTablePrefix, strSteamId, strEscapedName);
	SQL_TQuery(g_HDATABASE, EmptyCallback, strQuery, 0, DBPrio_High);
}

// Empty callback
public EmptyCallback(Handle:argOwner, Handle:argHndl, const String:argError[], any:argData)
{
	if (argHndl == INVALID_HANDLE)
	{
		LogError("Query Error: %s",argError);
	}
	if(argData == 1)
	{
		RC_Users_Ach();
		RC_Users_Blocks();
	}
}

/*---------------------------------------------------------------------------------
This part is the most important, it's a core of the plug ! 
First fonction serve to update a block status on a client.
---------------------------------------------------------------------------------*/
public UpdateBlockStatus(any:argFocusclient, const String:argsBlock_typ[], any:argsBlock_id, any:argsBlock_status)
{
	new String:strQuery[512];
	new String:strTablePrefix[128];
	new String:strId[512];
	new String:strSteamId[128];
	GetConVarString			(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	GetClientAuthString		(argFocusclient, strSteamId, sizeof(strSteamId));
	Format					(strId,sizeof(strId),"%s_%s_%d",strSteamId,argsBlock_typ,argsBlock_id);
	Format					(strQuery, sizeof(strQuery), "INSERT INTO `%susers_blocks` (`id`, `steamid`, `block_typ`, `block_id`, `status`) VALUES ('%s', '%s', '%s', '%d', '%d') ON DUPLICATE KEY UPDATE `status` = `status` + %d", strTablePrefix, strId, strSteamId, argsBlock_typ, argsBlock_id, argsBlock_status, argsBlock_status);
	SQL_TQuery				(g_HDATABASE, EmptyCallback, strQuery, 1, DBPrio_High);
}

// Get an individual block status
GetBlockStatusInv(any:argFocusclient, const String:argsBlock_typ[], any:argsBlock_id)
{
	new String:strId[512];
	new String:strSteamId[128];
	new String:strSql_sId[128];
	new strStatus = 0;
	GetClientAuthString	(argFocusclient, strSteamId, sizeof(strSteamId));
	Format				(strId,sizeof(strId),"%s_%s_%d",strSteamId,argsBlock_typ,argsBlock_id);
	//cache
	for(new i = 0; i < g_USERS_BLOCKS; i++) 
	{
		GetArrayString		(g_LIST_USERS_BLOCKS_ID, i, strSql_sId, sizeof(strSql_sId));
		if (StrEqual(strSql_sId, strId)) 
			strStatus =  GetArrayCell(g_LIST_USERS_BLOCKS_STATUS, i);
	}
	return strStatus;
}

// Get a block status
GetBlockStatus(any:argFocusclient,any:argI, any:argOffset, any:argAttacker, any:argVictim, any:argAssister)
{
	new String:strBlocktype[128];
	new strBlockid = 0;
	new strBlockmax = 1;
	new strStatus = 0;
	switch(argOffset)
	{
		case 0:
		GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKA_TYPE,argI,strBlocktype,sizeof(strBlocktype));
		case 1: 
		GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKB_TYPE,argI,strBlocktype,sizeof(strBlocktype));
		case 2: 
		GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKC_TYPE,argI,strBlocktype,sizeof(strBlocktype));
		case 3: 
		GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKD_TYPE,argI,strBlocktype,sizeof(strBlocktype));
		case 4: 
		GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKE_TYPE,argI,strBlocktype,sizeof(strBlocktype));
	}
	switch(argOffset)
	{
		case 0:
		strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKA_ID,argI);
		case 1: 
		strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKB_ID,argI);
		case 2: 
		strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKC_ID,argI);
		case 3: 
		strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKD_ID,argI);
		case 4: 
		strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKE_ID,argI);
	}
	switch(argOffset)
	{
		case 0:
		strBlockmax 	= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKA_MAX,argI);
		case 1: 
		strBlockmax 	= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKB_MAX,argI);
		case 2: 
		strBlockmax 	= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKC_MAX,argI);
		case 3: 
		strBlockmax 	= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKD_MAX,argI);
		case 4: 
		strBlockmax 	= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKE_MAX,argI);
	}
	
	if (strBlockid <= 0 || StrEqual(strBlocktype, "none")) strStatus = 1;
	if (strBlockid > 0 && !StrEqual(strBlocktype, "none") && !StrEqual(strBlocktype, "condition") && (GetBlockStatusInv(argFocusclient, strBlocktype, strBlockid) >= strBlockmax)) strStatus = 1;
	if (strBlockid > 0 && StrEqual(strBlocktype, "condition")) strStatus = blocks_getCondition(strBlockid, argAttacker, argVictim, argAssister);
	
	return strStatus;
}

/*---------------------------------------------------------------------------------
This fonction must be call on the onConfigExecuted, it reset all OneLife Achievement 
---------------------------------------------------------------------------------*/
ResetAllOneLife()
{
	new strAchid = 0;
	for(new i = 0; i < g_ACHIEVEMENTSRESET; i++) 
	{
		strAchid = GetArrayCell(g_LIST_ACHIEVEMENTS_RESETINDEATH,i);
		ResetFunction(strAchid,0);
	}
}

ResetAllOneLifeForOneClient(any:argClient)
{
	new strAchid = 0;
	for(new i = 0; i < g_ACHIEVEMENTSRESET; i++) 
	{
		strAchid = GetArrayCell(g_LIST_ACHIEVEMENTS_RESETINDEATH,i);
		ResetFunction(strAchid,argClient);
	}
}

ResetFunction(any:strAchid,any:argClient)
{
	new strBlockid;
	new String:strBlocktype[128];
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKA_TYPE,strAchid,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKA_ID,strAchid);
	if(argClient==0)
		ResetAllBlockStatus(strBlocktype,strBlockid);
	else
		ResetBlockStatus(argClient,strBlocktype,strBlockid);
	
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKB_TYPE,strAchid,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKB_ID,strAchid);
	if(argClient==0)
		ResetAllBlockStatus(strBlocktype,strBlockid);
	else
		ResetBlockStatus(argClient,strBlocktype,strBlockid);
	
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKC_TYPE,strAchid,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKC_ID,strAchid);
	if(argClient==0)
		ResetAllBlockStatus(strBlocktype,strBlockid);
	else
		ResetBlockStatus(argClient,strBlocktype,strBlockid);
		
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKD_TYPE,strAchid,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKD_ID,strAchid);	
	if(argClient==0)
		ResetAllBlockStatus(strBlocktype,strBlockid);
	else
		ResetBlockStatus(argClient,strBlocktype,strBlockid);
		
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKE_TYPE,strAchid,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKE_ID,strAchid);
	if(argClient==0)
	{
		ResetAllBlockStatus(strBlocktype,strBlockid);
		ResetAllAchievementStatus(strAchid);
	}
	else
	{
		ResetBlockStatus(argClient,strBlocktype,strBlockid);
		ResetAchievementStatus(argClient,strAchid);
	}
}

/*---------------------------------------------------------------------------------
This fonction reset all Block Statut in the user_blocks table 
---------------------------------------------------------------------------------*/
ResetAllBlockStatus(const String:argsBlock_typ[], any:argsBlock_id)
{
	new String:strQuery[512];
	new String:strTablePrefix[128];
	if (!StrEqual(argsBlock_typ,"none") && !StrEqual(argsBlock_typ,"condition") && argsBlock_id != 0)
	{
		GetConVarString	(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
		Format			(strQuery, sizeof(strQuery), "UPDATE `%susers_blocks` SET `status` = 0 WHERE `block_typ`='%s' AND `block_id`=%u", strTablePrefix, argsBlock_typ, argsBlock_id);
		SQL_TQuery		(g_HDATABASE, EmptyCallback, strQuery, 0 , DBPrio_High);
	}
}

/*---------------------------------------------------------------------------------
This fonction reset all ach Statut in the user_ach table 
---------------------------------------------------------------------------------*/
ResetAllAchievementStatus(any:argsAchievement_id)
{
	new String:strQuery[512];
	new String:strTablePrefix[128];
	GetConVarString	(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	Format			(strQuery, sizeof(strQuery), "UPDATE `%susers_ach` SET `status` = 0 WHERE `achid`=%u AND `complete`!= 1", strTablePrefix, argsAchievement_id);
	SQL_TQuery		(g_HDATABASE, EmptyCallback, strQuery,1, DBPrio_High );
}

/*---------------------------------------------------------------------------------
This fonction reset all Block Statut in the user_blocks table 
---------------------------------------------------------------------------------*/
ResetBlockStatus(any:argClient, const String:argsBlock_typ[], any:argsBlock_id)
{
	new String:strQuery[512];
	new String:strTablePrefix[128];
	new String:strSteamId[128];
	GetClientAuthString		(argClient, strSteamId, sizeof(strSteamId));
	
	if (!StrEqual(argsBlock_typ,"none") && !StrEqual(argsBlock_typ,"condition") && argsBlock_id != 0)
	{
		GetConVarString	(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
		Format			(strQuery, sizeof(strQuery), "UPDATE `%susers_blocks` SET `status` = 0 WHERE `block_typ`='%s' AND `block_id`=%u AND `steamid` = '%s'", strTablePrefix, argsBlock_typ, argsBlock_id, strSteamId);
		SQL_TQuery		(g_HDATABASE, EmptyCallback, strQuery, 0 , DBPrio_High);
	}
}

/*---------------------------------------------------------------------------------
This fonction reset ach Statut in the user_ach table to a client
---------------------------------------------------------------------------------*/
ResetAchievementStatus(any:argClient, any:argsAchievement_id)
{
	new String:strQuery[512];
	new String:strTablePrefix[128];
	new String:strSteamId[128];
	GetClientAuthString		(argClient, strSteamId, sizeof(strSteamId));
	GetConVarString	(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	Format			(strQuery, sizeof(strQuery), "UPDATE `%susers_ach` SET `status` = 0 WHERE `achid`=%u AND `steamid` = '%s' AND `complete`!= 1", strTablePrefix, argsAchievement_id,strSteamId);
	SQL_TQuery		(g_HDATABASE, EmptyCallback, strQuery, 1, DBPrio_High);
}

/*---------------------------------------------------------------------------------
A C H I E V E M E N T   C H E C K   C O M P L E T I O N
---------------------------------------------------------------------------------*/
public Action:AchievementCheckCompletion(any:argFocusclient, const String:argsBlock_typ[], any:argId, any:argAttacker, any:argVictim, any:argAssister)
{
	new strAchid = 0;
	new strResetTime = 0;
	new strCompletion = 0;
	for(new i = 0; i < g_MAXACHIEVEMENTS; i++) 
	{
		strAchid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_ID,i);
		strCompletion = 0;
		if(HaveThisBlock(argsBlock_typ,argId,strAchid))
		{
			for (new offset = 0; offset < g_MAX_BLOCKS; offset++) 
			{
				strCompletion = strCompletion + GetBlockStatus(argFocusclient,i,offset, argAttacker, argVictim, argAssister);
			}
			if (strCompletion >= g_MAX_BLOCKS && !IsAchComplete(argFocusclient,strAchid)) 
			{
				if(GetArrayCell(g_LIST_ACHIEVEMENTS_RESETTIME,i)==-1)
				{
					AddToAchievement(argFocusclient, strAchid);
				}
				else
				{
					new timeNow = GetTime();
					new timeWhenPlayerSpawn = g_TIMEACHIEVEMENT[argFocusclient][i];
					new timeBetween = timeNow - timeWhenPlayerSpawn;
					if(timeBetween<=GetArrayCell(g_LIST_ACHIEVEMENTS_RESETTIME,i))
					{
						AddToAchievement(argFocusclient, strAchid);
					}
					else
					{
						g_TIMEACHIEVEMENT[argFocusclient][i] = 0;
					}
				}
			}
		}
	}
}

/*---------------------------------------------------------------------------------
This fonction say if this achievement have this blocks
---------------------------------------------------------------------------------*/
public Boolean:HaveThisBlock(const String:argsBlock_typ[],any:argIdBlock, any:argIdAch)
{
	new strAchid = 0;
	new String:strBlocktype[128];
	new achAverifier = -1;
	new strBlockid = 0;
	for(new i = 0; i < g_MAXACHIEVEMENTS; i++) {
		strAchid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_ID,i);
		if (strAchid == argIdAch)
			achAverifier = i;
	}
	
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKA_TYPE,achAverifier,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKA_ID,achAverifier);
	if(StrEqual(strBlocktype, argsBlock_typ))
	{
		if(argIdBlock == strBlockid)
			return true;
	}
	
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKB_TYPE,achAverifier,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKB_ID,achAverifier);
	if(StrEqual(strBlocktype, argsBlock_typ))
	{
		if(argIdBlock == strBlockid)
			return true;
	}
	
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKC_TYPE,achAverifier,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKC_ID,achAverifier);
	if(StrEqual(strBlocktype, argsBlock_typ))
	{
		if(argIdBlock == strBlockid)
			return true;
	}
	
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKD_TYPE,achAverifier,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKD_ID,achAverifier);
	if(StrEqual(strBlocktype, argsBlock_typ))
	{
		if(argIdBlock == strBlockid)
			return true;
	}
	
	GetArrayString	(g_LIST_ACHIEVEMENTS_BLOCKE_TYPE,achAverifier,strBlocktype,sizeof(strBlocktype));
	strBlockid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_BLOCKE_ID,achAverifier);
	if(StrEqual(strBlocktype, argsBlock_typ))
	{
		if(argIdBlock == strBlockid)
			return true;
	}
	return false;
}

/*---------------------------------------------------------------------------------
This function say if this achievement is complete.
---------------------------------------------------------------------------------*/
public Boolean:IsAchComplete(any:argFocusclient, any:argAchId)
{
	new strP_complete = 0;
	new String:strId[512];
	new String:strP_strId[512];
	new String:strSteamId[128];
	GetClientAuthString(argFocusclient, strSteamId, sizeof(strSteamId));
	Format(strId,sizeof(strId),"%s__%d",strSteamId,argAchId);
	
	// Find the user's achieve progress
	for(new i = 0; i < g_USERS_ACH; i++) {
		GetArrayString(g_LIST_USERS_ACH_ID, i, strP_strId, sizeof(strP_strId));
		if (StrEqual(strP_strId, strId)) { 
			strP_complete 	= GetArrayCell(g_LIST_USERS_ACH_COMPLETE,i);
			if(strP_complete == 1)
				return true;
			else
			return false;
		}
	} 
	return false;
}

/*---------------------------------------------------------------------------------
Add + 1 on achievement statut
---------------------------------------------------------------------------------*/
AddToAchievement(any:argFocusclient, any:argId)
{
	//IMPORTANT POINT : FOCUSID FOCUSCLIENT
	g_FOCUSCLIENT = argFocusclient;
	g_FOCUSACHID = argId;
	new String:strQuery[512];
	new String:strTablePrefix[128];
	new String:strId[512];
	new String:strSteamId[128];
	GetClientAuthString(argFocusclient, strSteamId, sizeof(strSteamId));
	GetConVarString(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	Format(strId,sizeof(strId),"%s__%d",strSteamId,argId);
	//Send it to the database
	GetConVarString(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	Format(strQuery, sizeof(strQuery), "INSERT INTO `%susers_ach` (`id`, `steamid`, `achid`, `status`, `complete`) VALUES ('%s', '%s', '%d', '1', '0') ON DUPLICATE KEY UPDATE `status` = `status` + 1", strTablePrefix, strId, strSteamId, argId);
	SQL_TQuery(g_HDATABASE, AfterAdd, strQuery, 0, DBPrio_High);
}

public AfterAdd(Handle:argOwner, Handle:argHndl, const String:argError[], any:argData)
{
	if (argHndl == INVALID_HANDLE)
	{
		LogError("Query Error: %s",argError);
	}
	RC_Users_Ach(1);
	RC_Users_Blocks();
}


/*---------------------------------------------------------------------------------
Verify if the achievement is complete to a client.
---------------------------------------------------------------------------------*/
public VerifyIfCompleteAch(any:argFocusclient, any:argId)
{
	new String:strQuery[512];
	new String:strTablePrefix[128];
	new String:strId[512];
	new String:strSteamId[128];
	new boolean:strExist = false;
	GetConVarString(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	GetClientAuthString(argFocusclient, strSteamId, sizeof(strSteamId));
	Format			(strId,sizeof(strId),"%s__%d",strSteamId,argId);
	Format			(strQuery, sizeof(strQuery), "SELECT * FROM `%susers_ach` WHERE id = '%s'",strTablePrefix,strId);	// Find the user's achieve progress
	SQL_TQuery		(g_HDATABASE, VerifyIfCompleteAch_AfterQuery, strQuery,argFocusclient);
}

public VerifyIfCompleteAch_AfterQuery(Handle:owner, Handle:strHQuery, const String:error[], any:argFocusclient)
{
	if (strHQuery == INVALID_HANDLE)
	{
		LogMessage("Failed to verify if achievement is complete from the database, %s",error);
		return;
	}
	if (!SQL_GetRowCount(strHQuery))
	{
		return;
	}
	SQL_FetchRow(strHQuery);
	if (SQL_FetchInt(strHQuery, 4)>0)
	{
		return;
	}
	new strP_status = 0;
	new strA_status = 0;
	new String:strA_name[512];
	new String:strA_desc[512];
	new strOnComplete = 0;
	new strUser_ach_i = 0;
	new strAchid = 0;
	new String:strSteamId[128];
	new argId = 0;
	new String:strId[512];
	new String:strQuery[512];
	new String:strTablePrefix[128];
	GetConVarString(g_CVTABLEPREFIX, strTablePrefix, sizeof(strTablePrefix));
	SQL_FetchString(strHQuery, 0,strId,sizeof(strId));
	SQL_FetchString(strHQuery, 1,strSteamId,sizeof(strSteamId));
	argId = SQL_FetchInt(strHQuery, 2);
	strP_status	= SQL_FetchInt(strHQuery, 3);
	
	for(new i = 0; i < g_MAXACHIEVEMENTS; i++) {
		strAchid 		= GetArrayCell(g_LIST_ACHIEVEMENTS_ID,i);
		if (strAchid == argId) 
		{
			strA_status 	= GetArrayCell(g_LIST_ACHIEVEMENTS_TRIGGERS, i);
			GetArrayString	(g_LIST_ACHIEVEMENTS_NAME, i, strA_name, sizeof(strA_name));
			GetArrayString	(g_LIST_ACHIEVEMENTS_DESCRIPTION, i , strA_desc, sizeof(strA_desc));
			strOnComplete 	= GetArrayCell(g_LIST_ACHIEVEMENTS_ONCOMPLETE, i);
		}
	}
	if (strP_status >= strA_status) 
	{
		ResetAchievementStatus(argFocusclient, argId)
		AchievementEffect(argFocusclient, strA_name, strA_desc);
		//On Complete
		if (strOnComplete > 0) OnAchievementComplete(argFocusclient, strOnComplete);
		//Add to the MOTD
		g_MOTD_RANDOM = g_MOTD_RANDOM + 1;
		
		//send it to the server
		Format(strQuery, sizeof(strQuery), "INSERT INTO `%susers_ach` (`id`, `steamid`, `achid`, `status`, `complete`) VALUES ('%s', '%s', '%d', '0', '0') ON DUPLICATE KEY UPDATE `complete` = 1", strTablePrefix, strId, strSteamId, argId);
		SQL_TQuery(g_HDATABASE, EmptyCallback, strQuery,  1, DBPrio_High);
	}
	else
	{
		VerifyofProgression(argFocusclient,strA_name,strA_status,strP_status);
	}
}


VerifyofProgression(argiUser, const String:argsAchievementName[], argAmount, argInterval)
{
	new strNewinterval;
	if(g_CONFIGPROGRESSION[argiUser] != 0)
	{
		new String:strMessage[200];
		new String:strMessageFile[300];
		strNewinterval = argInterval;
		Format(strMessageFile, sizeof(strMessageFile),"%T", "Achievements completion", LANG_SERVER);
		Format(strMessage, sizeof(strMessage), "\x05%s\x01, %s \x03%i/%i", argsAchievementName, strMessageFile,strNewinterval,argAmount);
		SayText2One(argiUser, argiUser, strMessage);
	}
	new strResultat;
	new strResultat2;
	strResultat = (argInterval * 100)/argAmount;
	strResultat2 = ((argInterval+1) * 100)/argAmount;
	if(strResultat<=25 && strResultat2>25)
	{
		AchievementProgress(argiUser,argsAchievementName,"25 percent");
	}
	else
	{
		if(strResultat<=50 && strResultat2>50)
		{
			AchievementProgress(argiUser,argsAchievementName,"50 percent");
		}
		else
		{
			if(strResultat<=75 && strResultat2>75)
			{
				AchievementProgress(argiUser,argsAchievementName,"75 percent");
			}
		}
	}
}

AchievementProgress(argClient, const String:argName[],const String:argpourcent[])
{
	new String:strMessage[200];
	new String:strMessageFile[300];
	Format(strMessageFile, sizeof(strMessageFile),"%T", argpourcent, LANG_SERVER);
	Format(strMessage, sizeof(strMessage), "\x01%s \x03%s", strMessageFile, argName);
	SayText2One(argClient, argClient, strMessage);
}

//-----------------------------------------ACHIEVEMENT UNLOCKED EFFECT------------------------------------------
AchievementEffect(argClient, const String:argName[], const String:argDesc[])
{
	new Float:strflVec[3];
	GetClientEyePosition(argClient, strflVec);
	EmitSoundToAll(ACHIEVEMENT_SOUND, argClient);
	AttachAchievementParticle(argClient);
	
	new String:strMessage[200];
	Format(strMessage, sizeof(strMessage), "\x03%N\x01 %T : \x05%s", argClient, "Achievements", LANG_SERVER, argName);
	SayText2(argClient,strMessage);
	
	//Message
	new strInfo = 0;
	new strInfobody[512];
	strInfo = GetConVarInt(g_CVINFO);
	
	Format(strInfobody, sizeof(strInfobody), "\x05%T", "Explication", LANG_SERVER);
	Format(strMessage, sizeof(strMessage),"\x01%s", argDesc);
	if (strInfo == 1) {
		SayText2(argClient,strInfobody);
		SayText2(argClient,strMessage);
	}
	if (strInfo >= 2) {
		SayText2One(argClient,argClient,strInfobody);
		SayText2One(argClient,argClient,strMessage);
	}
}

stock SayText2(author_index , const String:message[] ) {
	new Handle:buffer = StartMessageAll("SayText2");
	if (buffer != INVALID_HANDLE) {
		BfWriteByte(buffer, author_index);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}

stock SayText2One( argClient_index , argAuthor_index , const String:argMessage[] ) {
	new Handle:strBuffer = StartMessageOne("SayText2", argClient_index);
	if (strBuffer != INVALID_HANDLE) {
		BfWriteByte(strBuffer, argClient_index);
		BfWriteByte(strBuffer, true);
		BfWriteString(strBuffer, argMessage);
		EndMessage();
	}
}

AttachAchievementParticle(argClient)
{
	new strIParticle = CreateEntityByName("info_particle_system");
	new String:strName[128];
	if (IsValidEdict(strIParticle))
	{
		new Float:strflPos[3];
		GetEntPropVector(argClient, Prop_Send, "m_vecOrigin", strflPos);
		TeleportEntity(strIParticle, strflPos, NULL_VECTOR, NULL_VECTOR);
		
		Format(strName, sizeof(strName), "target%i", argClient);
		DispatchKeyValue(argClient, "targetname", strName);
		
		DispatchKeyValue(strIParticle, "targetname", "tf2particle");
		DispatchKeyValue(strIParticle, "parentname", strName);
		DispatchKeyValue(strIParticle, "effect_name", ACHIEVEMENT_PARTICLE);
		DispatchSpawn(strIParticle);
		SetVariantString(strName);
		AcceptEntityInput(strIParticle, "SetParent", strIParticle, strIParticle, 0);
		SetVariantString("head");
		AcceptEntityInput(strIParticle, "SetParentAttachment", strIParticle, strIParticle, 0);
		ActivateEntity(strIParticle);
		AcceptEntityInput(strIParticle, "start");
		CreateTimer(5.0, Timer_DeleteParticles, strIParticle);
	}
}

public Action:Timer_DeleteParticles(Handle:argTimer, any:argIParticle)
{
	if (IsValidEntity(argIParticle))
	{
		new String:strClassname[256];
		GetEdictClassname(argIParticle, strClassname, sizeof(strClassname));
		
		if (StrEqual(strClassname, "info_particle_system", false))
		{
			RemoveEdict(argIParticle);
		}
	}
	return Plugin_Continue;
}

// --------------------------------------ACHIEVEMENTS PANEL

ShowAchievements(argClient) {
	
	new String:strAuthId[50];
	GetClientAuthString(argClient, strAuthId, sizeof(strAuthId));
	
	new String:strUrl[255];
	GetConVarString(g_CVURL, strUrl, sizeof(strUrl));
	
	new String:strFinal[192];
	Format(strFinal, sizeof(strFinal), "%s?u=%s&r=%d", strUrl, strAuthId, g_MOTD_RANDOM);
	ShowMOTDPanel(argClient, "_:", strFinal, MOTDPANEL_TYPE_URL);
	
}

public Action:motd_say(argClient, args) {
	decl String:strText[192];
	new String:strMotdCvar[255];
	GetConVarString(g_CVCHATMOTD, strMotdCvar, sizeof(strMotdCvar));
	
	if (!GetCmdArgString(strText, sizeof(strText)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(strText[strlen(strText)-1] == '"')
	{
		strText[strlen(strText)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	SetCmdReplySource(old);
	
	if (StrEqual(strText[startidx], strMotdCvar, false) || StrEqual(strText[startidx], "/show_achievement", false) || StrEqual(strText[startidx], "/achievements", false))	{
		ShowAchievements(argClient);
		SetCmdReplySource(old);
	}
	return Plugin_Continue;	
}

// ------------------------------------------------------------------------
// IsValidClient
// ------------------------------------------------------------------------
stock bool:IsValidClient(iClient)
{
	if (iClient < 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}

// ------------------------------------------------------------------------
// OnGameFrame()
// ------------------------------------------------------------------------
public OnGameFrame()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientObserver(i) && !IsFakeClient(i))
		{
			if((GetEntData(i, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) &  TF2_PLAYER_BLUR) != 0 )
			{
				if((g_CLIENTCONDITION[i] & TF2_PLAYER_BLUR) == 0)
				{
					block_drinkbonk(i);
				}
			}
			g_CLIENTCONDITION[i] = GetEntData(i, FindSendPropInfo("CTFPlayer", "m_nPlayerCond"));
		}
	}
}
