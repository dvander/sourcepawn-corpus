//--------------------------------------------------------------
// preprocessor directives, includes
//--------------------------------------------------------------
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <emitsoundany>

#pragma newdecls required

//--------------------------------------------------------------
// plugin information
//--------------------------------------------------------------
#define PLUGIN_VERSION "2.0.0.0"
public Plugin myinfo =
{
	name 		= "Rechargers",
	author 		= "AlexTheRegent",
	description = "health & armorbox rechargers",
	version 	= PLUGIN_VERSION,
	url 		= ""
}

//--------------------------------------------------------------
// defination
//--------------------------------------------------------------
#define 	MAX_RECHARGERS		8
#define 	ERROR_MODEL			"models/error.mdl"

#define 	RESTORE_INTERVAL 	1.0
#define 	MAX_HEAL_DISTANCE 	200.0

//--------------------------------------------------------------
// variables
//--------------------------------------------------------------
Menu 		g_hMainMenu;
Handle		g_hBoxActionTimer[MAXPLAYERS+1];

int			g_iHealthOffset;
int			g_iAccountOffset;
int 		g_iArmorOffset;

int			g_iEditTarget[MAXPLAYERS+1];
int			g_iEditBox[MAXPLAYERS+1];
int			g_iEditChoice[MAXPLAYERS+1];

//--------------------------------------------------------------
// ArmorBox variables
//--------------------------------------------------------------
KeyValues	g_hArmorBoxKeyValues;

ConVar		g_hConVar_sArmorBoxModel;
char		g_szArmorBoxModel[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sArmorBoxSound;
char		g_szArmorBoxSound[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sArmorBoxSoundDenied;
char		g_szArmorBoxSoundDenied[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sArmorBoxSoundEmpty;
char		g_szArmorBoxSoundEmpty[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sArmorBoxEmptyColor;
char		g_szArmorBoxEmptyColor[16];
ConVar		g_hConVar_sArmorBoxFullColor;
char		g_szArmorBoxFullColor[16];
ConVar 		g_hConVar_fArmorBoxDefaultRechargeTime;
float		g_fArmorBoxDefaultRechargeTime;
ConVar 		g_hConVar_fArmorBoxDefaultStartDelay;
float		g_fArmorBoxDefaultStartDelay;
ConVar 		g_hConVar_iArmorBoxDefaultReserve;
int			g_iArmorBoxDefaultReserve;
ConVar 		g_hConVar_iArmorBoxDefaultAmount;
int			g_iArmorBoxDefaultAmount;
ConVar 		g_hConVar_iArmorBoxDefaultPrice;
int			g_iArmorBoxDefaultPrice;
ConVar 		g_hConVar_iArmorBoxDefaultTeam;
int			g_iArmorBoxDefaultTeam;
ConVar 		g_hConVar_iArmorBoxDefaultMaxArmor;
int			g_iArmorBoxDefaultMaxArmor;

Handle		g_hArmorBoxRestoreTimer[MAX_RECHARGERS];
float		g_vArmorBoxOrigin[MAX_RECHARGERS][3];
float		g_vArmorBoxAngles[MAX_RECHARGERS][3];
bool		g_bArmorBoxExists[MAX_RECHARGERS];
int			g_iArmorBoxEntity[MAX_RECHARGERS];

float 		g_fArmorBoxRechargeTime[MAX_RECHARGERS];
float 		g_fArmorBoxStartDelay[MAX_RECHARGERS];
int 		g_iArmorBoxAmount[MAX_RECHARGERS];
int 		g_iArmorBoxPrice[MAX_RECHARGERS];
int 		g_iArmorBoxTeam[MAX_RECHARGERS];
int			g_iArmorBoxMaxReserve[MAX_RECHARGERS];
int			g_iArmorBoxCurrentReserve[MAX_RECHARGERS];
int			g_iArmorBoxMaxArmor[MAX_RECHARGERS];

//--------------------------------------------------------------
// HealthBox variables
//--------------------------------------------------------------
KeyValues	g_hHealthBoxKeyValues;

ConVar		g_hConVar_sHealthBoxModel;
char		g_szHealthBoxModel[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sHealthBoxSound;
char		g_szHealthBoxSound[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sHealthBoxSoundDenied;
char		g_szHealthBoxSoundDenied[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sHealthBoxSoundEmpty;
char		g_szHealthBoxSoundEmpty[PLATFORM_MAX_PATH];
ConVar		g_hConVar_sHealthBoxEmptyColor;
char		g_szHealthBoxEmptyColor[16];
ConVar		g_hConVar_sHealthBoxFullColor;
char		g_szHealthBoxFullColor[16];
ConVar 		g_hConVar_fHealthBoxDefaultRechargeTime;
float		g_fHealthBoxDefaultRechargeTime;
ConVar 		g_hConVar_fHealthBoxDefaultStartDelay;
float		g_fHealthBoxDefaultStartDelay;
ConVar 		g_hConVar_iHealthBoxDefaultReserve;
int			g_iHealthBoxDefaultReserve;
ConVar 		g_hConVar_iHealthBoxDefaultAmount;
int			g_iHealthBoxDefaultAmount;
ConVar 		g_hConVar_iHealthBoxDefaultPrice;
int			g_iHealthBoxDefaultPrice;
ConVar 		g_hConVar_iHealthBoxDefaultTeam;
int			g_iHealthBoxDefaultTeam;
ConVar 		g_hConVar_iHealthBoxDefaultMaxHealth;
int			g_iHealthBoxDefaultMaxHealth;

Handle		g_hHealthBoxRestoreTimer[MAX_RECHARGERS];
float		g_vHealthBoxOrigin[MAX_RECHARGERS][3];
float		g_vHealthBoxAngles[MAX_RECHARGERS][3];
bool		g_bHealthBoxExists[MAX_RECHARGERS];
int			g_iHealthBoxEntity[MAX_RECHARGERS];

float 		g_fHealthBoxRechargeTime[MAX_RECHARGERS];
float 		g_fHealthBoxStartDelay[MAX_RECHARGERS];
int 		g_iHealthBoxAmount[MAX_RECHARGERS];
int 		g_iHealthBoxPrice[MAX_RECHARGERS];
int 		g_iHealthBoxTeam[MAX_RECHARGERS];
int			g_iHealthBoxMaxReserve[MAX_RECHARGERS];
int			g_iHealthBoxCurrentReserve[MAX_RECHARGERS];
int			g_iHealthBoxMaxHealth[MAX_RECHARGERS];

//--------------------------------------------------------------
// source code
//--------------------------------------------------------------
public void OnPluginStart()
{
	// plugin version
	CreateConVar("sm_rechargers_version", PLUGIN_VERSION, "The version of the Rechargers plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	// translation loading
	LoadTranslations("rechargers.phrases.txt");
	
	// finding required offsets: health, money, armor
	g_iHealthOffset = FindSendPropInfo("CBasePlayer", "m_iHealth");
	if ( g_iHealthOffset == -1 )
	{
		LogError("CBasePlayer::m_iHealth offset not found");
		SetFailState("CBasePlayer::m_iHealth offset not found");
	}
	g_iAccountOffset = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if ( g_iAccountOffset == -1 )
	{
		LogError("CBasePlayer::m_iAccount offset not found");
		SetFailState("CBasePlayer::m_iAccount offset not found");
	}
	g_iArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	if ( g_iArmorOffset == -1 )
	{
		LogError("CBasePlayer::m_ArmorValue offset not found");
		SetFailState("CBasePlayer::m_ArmorValue offset not found");
	}
	
	// creation of main menu
	g_hMainMenu = new Menu(Handle_MainMenu, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
	g_hMainMenu.AddItem("shb", 	"spawn healthbox");
	g_hMainMenu.AddItem("sab", 	"spawn armorbox");
	g_hMainMenu.AddItem("e", 	"edit");
	g_hMainMenu.AddItem("d", 	"delete");
	
	// armorbox cvars creation
	g_hConVar_sArmorBoxModel 				= CreateConVar("sm_rechargers_armorbox_model", 			"models/recharger/suit_charger001.mdl", 	"model of armorbox", 											FCVAR_PLUGIN);
	g_hConVar_sArmorBoxSound 				= CreateConVar("sm_rechargers_armorbox_sound", 			"rechargers/suitchargeok1.mp3", 			"sound of armorbox", 											FCVAR_PLUGIN);
	g_hConVar_sArmorBoxSoundDenied 			= CreateConVar("sm_rechargers_armorbox_sounddenied", 	"buttons/weapon_cant_buy.mp3", 				"sound of armorbox", 											FCVAR_PLUGIN);
	g_hConVar_sArmorBoxSoundEmpty 			= CreateConVar("sm_rechargers_armorbox_soundempty", 	"rechargers/suitchargeno1.mp3", 			"sound of armorbox", 											FCVAR_PLUGIN);
	g_hConVar_sArmorBoxEmptyColor 			= CreateConVar("sm_rechargers_armorbox_emptycolor", 	"255 0 0", 									"color of empty armorbox", 										FCVAR_PLUGIN);
	g_hConVar_sArmorBoxFullColor 			= CreateConVar("sm_rechargers_armorbox_fullcolor", 		"0 0 255", 									"color of full armorbox", 										FCVAR_PLUGIN);
	g_hConVar_fArmorBoxDefaultRechargeTime 	= CreateConVar("sm_rechargers_armorbox_rechargetime", 	"10.0", 								 	"time of restoring armorbox reserve", 							FCVAR_PLUGIN, true, 0.1);
	g_hConVar_fArmorBoxDefaultStartDelay 	= CreateConVar("sm_rechargers_armorbox_startdelay", 	"10.0", 								 	"delay of activation armorbox (counts from round_freeze_end)", 	FCVAR_PLUGIN, true, 0.0);
	g_hConVar_iArmorBoxDefaultReserve 		= CreateConVar("sm_rechargers_armorbox_reserve", 		"100", 									 	"how much health contain one armorbox", 						FCVAR_PLUGIN, true, 1.0);
	g_hConVar_iArmorBoxDefaultAmount 		= CreateConVar("sm_rechargers_armorbox_amount", 		"10", 										"how much health armorbox restore in one heal", 				FCVAR_PLUGIN, true, 1.0);
	g_hConVar_iArmorBoxDefaultPrice 		= CreateConVar("sm_rechargers_armorbox_price", 			"0", 									 	"how much costs one armor restoration in armorbox", 			FCVAR_PLUGIN, true, 0.0);
	g_hConVar_iArmorBoxDefaultTeam 			= CreateConVar("sm_rechargers_armorbox_team", 			"0", 									 	"which team is allowed to use armorbox (0-all, 2-t, 3-ct)", 	FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hConVar_iArmorBoxDefaultMaxArmor 		= CreateConVar("sm_rechargers_armorbox_max", 			"100", 									 	"restore armor until", 											FCVAR_PLUGIN, true, 0.0);
	
	g_hConVar_sArmorBoxModel.AddChangeHook(OnConVarChange);
	g_hConVar_sArmorBoxEmptyColor.AddChangeHook(OnConVarChange);
	g_hConVar_sArmorBoxFullColor.AddChangeHook(OnConVarChange);
	g_hConVar_fArmorBoxDefaultRechargeTime.AddChangeHook(OnConVarChange);
	g_hConVar_fArmorBoxDefaultStartDelay.AddChangeHook(OnConVarChange);
	g_hConVar_iArmorBoxDefaultReserve.AddChangeHook(OnConVarChange);
	g_hConVar_iArmorBoxDefaultAmount.AddChangeHook(OnConVarChange);
	g_hConVar_iArmorBoxDefaultPrice.AddChangeHook(OnConVarChange);
	g_hConVar_iArmorBoxDefaultTeam.AddChangeHook(OnConVarChange);
	g_hConVar_iArmorBoxDefaultMaxArmor.AddChangeHook(OnConVarChange);
	
	// healthbox cvars creation
	g_hConVar_sHealthBoxModel 				= CreateConVar("sm_rechargers_healthbox_model", 		"models/recharger/health_charger001.mdl", 	"model of healthbox", 											FCVAR_PLUGIN);
	g_hConVar_sHealthBoxSound 				= CreateConVar("sm_rechargers_healthbox_sound", 		"rechargers/medshot4.mp3", 					"sound of healthbox", 											FCVAR_PLUGIN);
	g_hConVar_sHealthBoxSoundDenied 		= CreateConVar("sm_rechargers_healthbox_sounddenied", 	"buttons/weapon_cant_buy.mp3", 				"sound of healthbox", 											FCVAR_PLUGIN);
	g_hConVar_sHealthBoxSoundEmpty 			= CreateConVar("sm_rechargers_healthbox_soundempty", 	"rechargers/medshotno1.mp3", 				"sound of healthbox", 											FCVAR_PLUGIN);
	g_hConVar_sHealthBoxEmptyColor 			= CreateConVar("sm_rechargers_healthbox_emptycolor", 	"255 0 0", 									"color of empty healthbox", 									FCVAR_PLUGIN);
	g_hConVar_sHealthBoxFullColor 			= CreateConVar("sm_rechargers_healthbox_fullcolor", 	"0 255 0", 									"color of full healthbox", 										FCVAR_PLUGIN);
	g_hConVar_fHealthBoxDefaultRechargeTime = CreateConVar("sm_rechargers_healthbox_rechargetime", 	"10.0", 									"time of restoring healthbox reserve", 							FCVAR_PLUGIN, true, 0.1);
	g_hConVar_fHealthBoxDefaultStartDelay 	= CreateConVar("sm_rechargers_healthbox_startdelay", 	"10.0",								 		"delay of activation healtbox (counts from round_freeze_end)", 	FCVAR_PLUGIN, true, 0.0);
	g_hConVar_iHealthBoxDefaultReserve 		= CreateConVar("sm_rechargers_healthbox_reserve", 		"100", 								 		"how much health contain one healtbox", 						FCVAR_PLUGIN, true, 1.0);
	g_hConVar_iHealthBoxDefaultAmount 		= CreateConVar("sm_rechargers_healthbox_amount", 		"10", 								 		"how much health healtbox restore in one heal", 				FCVAR_PLUGIN, true, 1.0);
	g_hConVar_iHealthBoxDefaultPrice 		= CreateConVar("sm_rechargers_healthbox_price", 		"0", 								 		"how much costs one heal of healtbox", 							FCVAR_PLUGIN, true, 0.0);
	g_hConVar_iHealthBoxDefaultTeam 		= CreateConVar("sm_rechargers_healthbox_team", 			"0", 									 	"which team is allowed to use healtbox (0-all, 2-t, 3-ct)", 	FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hConVar_iHealthBoxDefaultMaxHealth 	= CreateConVar("sm_rechargers_healthbox_max", 			"100", 									 	"restore health until", 										FCVAR_PLUGIN, true, 0.0);
	
	g_hConVar_sHealthBoxModel.AddChangeHook(OnConVarChange);
	g_hConVar_sHealthBoxEmptyColor.AddChangeHook(OnConVarChange);
	g_hConVar_sHealthBoxFullColor.AddChangeHook(OnConVarChange);
	g_hConVar_fHealthBoxDefaultRechargeTime.AddChangeHook(OnConVarChange);
	g_hConVar_fHealthBoxDefaultStartDelay.AddChangeHook(OnConVarChange);
	g_hConVar_iHealthBoxDefaultReserve.AddChangeHook(OnConVarChange);
	g_hConVar_iHealthBoxDefaultAmount.AddChangeHook(OnConVarChange);
	g_hConVar_iHealthBoxDefaultPrice.AddChangeHook(OnConVarChange);
	g_hConVar_iHealthBoxDefaultTeam.AddChangeHook(OnConVarChange);
	g_hConVar_iHealthBoxDefaultMaxHealth.AddChangeHook(OnConVarChange);
	
	// autoexec config
	AutoExecConfig(true, "rechargers");
	
	// hook required events
	HookEvent("round_start", 		Ev_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", 	Ev_RoundFreezeEnd,	EventHookMode_PostNoCopy);
	
	// registration of admin command to place rechargers
	RegAdminCmd("sm_rechargers", Command_Rechargers, ADMFLAG_ROOT);
	
	// adding files to downloadtable from file
	char szBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/rechargers_downloadlist.txt");
	Handle hFile = OpenFile(szBuffer, "r");
	if ( hFile )
	{
		while ( !IsEndOfFile(hFile) && ReadFileLine(hFile, szBuffer, sizeof(szBuffer)) )
		{
			TrimString(szBuffer);
			AddFileToDownloadsTable(szBuffer);
		}
	}
	delete hFile;
}

// hook "convar changed"
public void OnConVarChange(ConVar hConVar, const char[] szOldValue, const char[] szNewValue)
{
	if ( hConVar == g_hConVar_sHealthBoxModel )
	{
		if ( IsValidModel(szNewValue) )
		{
			strcopy(g_szHealthBoxModel, sizeof(g_szHealthBoxModel), szNewValue);
			PrecacheModel(g_szHealthBoxModel);
		}
		else
		{
			strcopy(g_szHealthBoxModel, sizeof(g_szHealthBoxModel), ERROR_MODEL);
			LogError("invalid healthbox model '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sHealthBoxSound )
	{
		if ( IsValidSound(szNewValue) )
		{
			strcopy(g_szHealthBoxSound, sizeof(g_szHealthBoxSound), szNewValue);
			PrecacheSoundAny(g_szHealthBoxSound);
		}
		else
		{
			strcopy(g_szHealthBoxSound, sizeof(g_szHealthBoxSound), "");
			LogError("invalid healthbox sound '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sHealthBoxSoundDenied )
	{
		if ( IsValidSound(szNewValue) )
		{
			strcopy(g_szHealthBoxSoundDenied, sizeof(g_szHealthBoxSoundDenied), szNewValue);
			PrecacheSoundAny(g_szHealthBoxSoundDenied);
		}
		else
		{
			strcopy(g_szHealthBoxSoundDenied, sizeof(g_szHealthBoxSoundDenied), "");
			LogError("invalid healthbox deny sound '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sHealthBoxSoundEmpty )
	{
		if ( IsValidSound(szNewValue) )
		{
			strcopy(g_szHealthBoxSoundEmpty, sizeof(g_szHealthBoxSoundEmpty), szNewValue);
			PrecacheSoundAny(g_szHealthBoxSoundEmpty);
		}
		else
		{
			strcopy(g_szHealthBoxSoundEmpty, sizeof(g_szHealthBoxSoundEmpty), "");
			LogError("invalid healthbox empty sound '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sArmorBoxModel )
	{
		if ( IsValidModel(szNewValue) )
		{
			strcopy(g_szArmorBoxModel, sizeof(g_szArmorBoxModel), szNewValue);
			PrecacheModel(g_szArmorBoxModel);
		}
		else
		{
			strcopy(g_szArmorBoxModel, sizeof(g_szArmorBoxModel), ERROR_MODEL);
			LogError("invalid armorbox model '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sArmorBoxSound )
	{
		if ( IsValidSound(szNewValue) )
		{
			strcopy(g_szArmorBoxSound, sizeof(g_szArmorBoxSound), szNewValue);
			PrecacheSoundAny(g_szArmorBoxSound);
		}
		else
		{
			strcopy(g_szArmorBoxSound, sizeof(g_szArmorBoxSound), "");
			LogError("invalid armorbox sound '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sArmorBoxSoundDenied )
	{
		if ( IsValidSound(szNewValue) )
		{
			strcopy(g_szArmorBoxSoundDenied, sizeof(g_szArmorBoxSoundDenied), szNewValue);
			PrecacheSoundAny(g_szArmorBoxSoundDenied);
		}
		else
		{
			strcopy(g_szArmorBoxSoundDenied, sizeof(g_szArmorBoxSoundDenied), "");
			LogError("invalid armorbox deny sound '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sArmorBoxSoundEmpty )
	{
		if ( IsValidSound(szNewValue) )
		{
			strcopy(g_szArmorBoxSoundEmpty, sizeof(g_szArmorBoxSoundEmpty), szNewValue);
			PrecacheSoundAny(g_szArmorBoxSoundEmpty);
		}
		else
		{
			strcopy(g_szArmorBoxSoundEmpty, sizeof(g_szArmorBoxSoundEmpty), "");
			LogError("invalid armorbox empty sound '%s'", szNewValue);
		}
	}
	else if ( hConVar == g_hConVar_sHealthBoxFullColor )
	{
		strcopy(g_szHealthBoxFullColor, sizeof(g_szHealthBoxEmptyColor), szNewValue);
	}
	else if ( hConVar == g_hConVar_sArmorBoxFullColor )
	{
		strcopy(g_szArmorBoxFullColor, sizeof(g_szArmorBoxFullColor), szNewValue);
	}
	else if ( hConVar == g_hConVar_fHealthBoxDefaultRechargeTime )
	{
		g_fHealthBoxDefaultRechargeTime = StringToFloat(szNewValue);
	}
	else if ( hConVar == g_hConVar_fHealthBoxDefaultStartDelay )
	{
		g_fHealthBoxDefaultStartDelay = StringToFloat(szNewValue);
	}
	else if ( hConVar == g_hConVar_iHealthBoxDefaultReserve )
	{
		g_iHealthBoxDefaultReserve = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iHealthBoxDefaultAmount )
	{
		g_iHealthBoxDefaultAmount = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iHealthBoxDefaultPrice )
	{
		g_iHealthBoxDefaultPrice = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_fArmorBoxDefaultRechargeTime )
	{
		g_fArmorBoxDefaultRechargeTime = StringToFloat(szNewValue);
	}
	else if ( hConVar == g_hConVar_fArmorBoxDefaultStartDelay )
	{
		g_fArmorBoxDefaultStartDelay = StringToFloat(szNewValue);
	}
	else if ( hConVar == g_hConVar_iArmorBoxDefaultReserve )
	{
		g_iArmorBoxDefaultReserve = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iArmorBoxDefaultAmount )
	{
		g_iArmorBoxDefaultAmount = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iArmorBoxDefaultPrice )
	{
		g_iArmorBoxDefaultPrice = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iArmorBoxDefaultTeam )
	{
		g_iArmorBoxDefaultTeam = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iHealthBoxDefaultTeam )
	{
		g_iHealthBoxDefaultTeam = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iArmorBoxDefaultMaxArmor )
	{
		g_iArmorBoxDefaultMaxArmor = StringToInt(szNewValue);
	}
	else if ( hConVar == g_hConVar_iHealthBoxDefaultMaxHealth )
	{
		g_iHealthBoxDefaultMaxHealth = StringToInt(szNewValue);
	}
}

// check is model valid (ends with ".mdl")
bool IsValidModel(const char[] szModel)
{
	int iLength = strlen(szModel);
	return ( iLength > 4 && !strcmp(szModel[iLength-4], ".mdl") );
}

// check is sound valid (ends with ".wav" or ".mp3")
bool IsValidSound(const char[] szSound)
{
	int iLength = strlen(szSound);
	return ( iLength > 4 && (!strcmp(szSound[iLength-4], ".wav") || !strcmp(szSound[iLength-4], ".mp3")) );
}

// called when map starts
public void OnMapStart() 
{
	// precaching of models
	PrecacheModel(ERROR_MODEL);
	
	// loading data about rechargers
	LoadRechargersDataFromKeyValues(g_hArmorBoxKeyValues, "ab", g_vArmorBoxOrigin, g_vArmorBoxAngles, g_bArmorBoxExists, g_fArmorBoxRechargeTime, 
		g_fArmorBoxStartDelay, g_iArmorBoxMaxReserve, g_iArmorBoxAmount, g_iArmorBoxPrice, g_iArmorBoxTeam, g_iArmorBoxMaxArmor);
	LoadRechargersDataFromKeyValues(g_hHealthBoxKeyValues, "hb", g_vHealthBoxOrigin, g_vHealthBoxAngles, g_bHealthBoxExists, g_fHealthBoxRechargeTime, 
		g_fHealthBoxStartDelay, g_iHealthBoxMaxReserve, g_iHealthBoxAmount, g_iHealthBoxPrice, g_iHealthBoxTeam, g_iHealthBoxMaxHealth);
}

// loading data from kv about rechargers 
void LoadRechargersDataFromKeyValues(KeyValues &Kv, const char[] szPrefix, float[MAX_RECHARGERS][3] vOrigin, float vAngles[MAX_RECHARGERS][3], 
	bool[MAX_RECHARGERS] bFound, float fRechargeTime[MAX_RECHARGERS], float fStartDelay[MAX_RECHARGERS], int iReserve[MAX_RECHARGERS], 
	int iAmount[MAX_RECHARGERS], int iPrice[MAX_RECHARGERS], int iTeam[MAX_RECHARGERS], int iMax[MAX_RECHARGERS])
{
	// building path to "map"_"type" file
	char szPath[PLATFORM_MAX_PATH];
	GetCurrentMap(szPath, sizeof(szPath));
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/rechargers/%s_%s.txt", szPrefix, szPath);
	// creating kv
	Kv = new KeyValues(szPrefix);
	if ( Kv.ImportFromFile(szPath) && Kv.GotoFirstSubKey() )
	{
		// reading data section by section
		char szSectionName[8];
		do
		{
			Kv.GetSectionName(szSectionName, sizeof(szSectionName));
			//PrintToServer(szSectionName);
			int iPositionInArray = StringToInt(szSectionName[3]);
			if ( iPositionInArray < MAX_RECHARGERS )
			{
				bFound[iPositionInArray] = true;
				Kv.GetVector("origin", vOrigin[iPositionInArray]);
				Kv.GetVector("angles", vAngles[iPositionInArray]);
				
				fRechargeTime[iPositionInArray] = Kv.GetFloat("rechargetime");
				fStartDelay[iPositionInArray] 	= Kv.GetFloat("startdelay");
				iReserve[iPositionInArray] 		= Kv.GetNum("reserve");
				iAmount[iPositionInArray] 		= Kv.GetNum("amount");
				iPrice[iPositionInArray] 		= Kv.GetNum("price");
				iTeam[iPositionInArray] 		= Kv.GetNum("team");
				iMax[iPositionInArray] 			= Kv.GetNum("max");
				
				/*PrintToServer("origin: %f %f %f", 	vOrigin[iPositionInArray][0], vOrigin[iPositionInArray][1], vOrigin[iPositionInArray][2]);
				PrintToServer("angles: %f %f %f", 	vAngles[iPositionInArray][0], vAngles[iPositionInArray][1], vAngles[iPositionInArray][2]);
				PrintToServer("rechargetime: %f", 	fRechargeTime[iPositionInArray]);
				PrintToServer("startdelay: %f",		fStartDelay[iPositionInArray]);
				PrintToServer("reserve: %d",		iReserve[iPositionInArray]);
				PrintToServer("amount: %d",			iAmount[iPositionInArray]);
				PrintToServer("price: %d",			iPrice[iPositionInArray]);
				PrintToServer("team: %d",			iTeam[iPositionInArray]);
				PrintToServer("max: %d",			iMax[iPositionInArray]);*/
			}
		} while ( Kv.GotoNextKey() );
	}
}
	
// called after configs are executed
public void OnConfigsExecuted() 
{
	// getting convars values to variables
	g_hConVar_sHealthBoxModel.GetString(g_szHealthBoxModel, sizeof(g_szHealthBoxModel));
	if ( IsValidModel(g_szHealthBoxModel) ) 
	{
		PrecacheModel(g_szHealthBoxModel);
	}
	else
	{
		LogError("invalid healthbox model '%s'", g_szHealthBoxModel);
		strcopy(g_szHealthBoxModel, sizeof(g_szHealthBoxModel), ERROR_MODEL);
	}
	
	g_hConVar_sArmorBoxModel.GetString(g_szArmorBoxModel, sizeof(g_szArmorBoxModel));
	if ( IsValidModel(g_szArmorBoxModel) ) 
	{
		PrecacheModel(g_szArmorBoxModel);
	}
	else
	{
		LogError("invalid armorbox model '%s'", g_szArmorBoxModel);
		strcopy(g_szArmorBoxModel, sizeof(g_szArmorBoxModel), ERROR_MODEL);
	}
	
	g_hConVar_sHealthBoxSound.GetString(g_szHealthBoxSound, sizeof(g_szHealthBoxSound));
	if ( IsValidSound(g_szHealthBoxSound) ) 
	{
		PrecacheSoundAny(g_szHealthBoxSound);
	}
	else
	{
		LogError("invalid healthbox sound '%s'", g_szHealthBoxSound);
		strcopy(g_szHealthBoxSound, sizeof(g_szHealthBoxSound), ERROR_MODEL);
	}
	g_hConVar_sHealthBoxSoundDenied.GetString(g_szHealthBoxSoundDenied, sizeof(g_szHealthBoxSoundDenied));
	if ( IsValidSound(g_szHealthBoxSoundDenied) ) 
	{
		PrecacheSoundAny(g_szHealthBoxSoundDenied);
	}
	else
	{
		LogError("invalid healthbox deny sound '%s'", g_szHealthBoxSoundDenied);
		strcopy(g_szHealthBoxSoundDenied, sizeof(g_szHealthBoxSoundDenied), ERROR_MODEL);
	}
	g_hConVar_sHealthBoxSoundEmpty.GetString(g_szHealthBoxSoundEmpty, sizeof(g_szHealthBoxSoundEmpty));
	if ( IsValidSound(g_szHealthBoxSoundEmpty) ) 
	{
		PrecacheSoundAny(g_szHealthBoxSoundEmpty);
	}
	else
	{
		LogError("invalid healthbox empty sound '%s'", g_szHealthBoxSoundEmpty);
		strcopy(g_szHealthBoxSoundEmpty, sizeof(g_szHealthBoxSoundEmpty), ERROR_MODEL);
	}
	
	g_hConVar_sArmorBoxSound.GetString(g_szArmorBoxSound, sizeof(g_szArmorBoxSound));
	if ( IsValidSound(g_szArmorBoxSound) ) 
	{
		PrecacheSoundAny(g_szArmorBoxSound);
	}
	else
	{
		LogError("invalid armorbox sound '%s'", g_szArmorBoxSound);
		strcopy(g_szArmorBoxSound, sizeof(g_szArmorBoxSound), ERROR_MODEL);
	}
	g_hConVar_sArmorBoxSoundDenied.GetString(g_szArmorBoxSoundDenied, sizeof(g_szArmorBoxSoundDenied));
	if ( IsValidSound(g_szArmorBoxSoundDenied) ) 
	{
		PrecacheSoundAny(g_szArmorBoxSoundDenied);
	}
	else
	{
		LogError("invalid armorbox deny sound '%s'", g_szArmorBoxSoundDenied);
		strcopy(g_szArmorBoxSoundDenied, sizeof(g_szArmorBoxSoundDenied), ERROR_MODEL);
	}
	g_hConVar_sArmorBoxSoundEmpty.GetString(g_szArmorBoxSoundEmpty, sizeof(g_szArmorBoxSoundEmpty));
	if ( IsValidSound(g_szArmorBoxSoundEmpty) ) 
	{
		PrecacheSoundAny(g_szArmorBoxSoundEmpty);
	}
	else
	{
		LogError("invalid armorbox empty sound '%s'", g_szArmorBoxSoundEmpty);
		strcopy(g_szArmorBoxSoundEmpty, sizeof(g_szArmorBoxSoundEmpty), ERROR_MODEL);
	}
	
	g_hConVar_sArmorBoxEmptyColor.GetString(g_szArmorBoxEmptyColor, sizeof(g_szArmorBoxEmptyColor));
	g_hConVar_sArmorBoxFullColor.GetString(g_szArmorBoxFullColor, sizeof(g_szArmorBoxFullColor));
	
	g_hConVar_sHealthBoxEmptyColor.GetString(g_szHealthBoxEmptyColor, sizeof(g_szHealthBoxEmptyColor));
	g_hConVar_sHealthBoxFullColor.GetString(g_szHealthBoxFullColor, sizeof(g_szHealthBoxFullColor));
	
	g_fArmorBoxDefaultRechargeTime 		= g_hConVar_fArmorBoxDefaultRechargeTime.FloatValue;
	g_fArmorBoxDefaultStartDelay 		= g_hConVar_fArmorBoxDefaultStartDelay.FloatValue;
	g_iArmorBoxDefaultReserve 			= g_hConVar_iArmorBoxDefaultReserve.IntValue;
	g_iArmorBoxDefaultAmount 			= g_hConVar_iArmorBoxDefaultAmount.IntValue;
	g_iArmorBoxDefaultPrice 			= g_hConVar_iArmorBoxDefaultPrice.IntValue;
	g_iArmorBoxDefaultMaxArmor 			= g_hConVar_iArmorBoxDefaultMaxArmor.IntValue;
	
	g_fHealthBoxDefaultRechargeTime 	= g_hConVar_fHealthBoxDefaultRechargeTime.FloatValue;
	g_fHealthBoxDefaultStartDelay 		= g_hConVar_fHealthBoxDefaultStartDelay.FloatValue;
	g_iHealthBoxDefaultReserve 			= g_hConVar_iHealthBoxDefaultReserve.IntValue;
	g_iHealthBoxDefaultAmount 			= g_hConVar_iHealthBoxDefaultAmount.IntValue;
	g_iHealthBoxDefaultPrice 			= g_hConVar_iHealthBoxDefaultPrice.IntValue;
	g_iHealthBoxDefaultMaxHealth 		= g_hConVar_iHealthBoxDefaultMaxHealth.IntValue;
}

// on actions is main menu
public int Handle_MainMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	// dynamic translation
	if ( action == MenuAction_DisplayItem )
	{
		char szPhrase[64];
		hMenu.GetItem(iSlot, "", 0, _, szPhrase, sizeof(szPhrase));
		Format(szPhrase, sizeof(szPhrase), "%T", szPhrase, iClient);
		RedrawMenuItem(szPhrase);
	}
	// one of buttons are pressed
	else if ( action == MenuAction_Select )
	{
		// get menu item
		char szInfo[4];
		hMenu.GetItem(iSlot, szInfo, sizeof(szInfo));
		// if pressed "spawn healthbox"
		if ( !strcmp(szInfo, "shb") )
		{
			// get client view origin and angles
			float vOrigin[3], vAngles[3];
			if ( GetViewOriginAndAngles(iClient, vOrigin, vAngles) )
			{
				// searching in kv for free space
				char szSectionName[8];
				if ( FindSpaceInKeyValues(g_hHealthBoxKeyValues, "hb", szSectionName, sizeof(szSectionName)) )
				{
					// spawning healthbox model
					int iEntity = SpawnRecharger(vOrigin, vAngles, g_szHealthBoxModel, szSectionName);
					CreateLight(vOrigin, vAngles, iEntity);
					SetLightColor(iEntity, "75 75 75");
					SaveEntity(g_hHealthBoxKeyValues, szSectionName, vOrigin, vAngles);
					
					// saving position
					int iPositionInArray = StringToInt(szSectionName[3]);
					g_bHealthBoxExists[iPositionInArray] = true;
					g_vHealthBoxOrigin[iPositionInArray][0] = vOrigin[0];
					g_vHealthBoxOrigin[iPositionInArray][1] = vOrigin[1];
					g_vHealthBoxOrigin[iPositionInArray][2] = vOrigin[2];
					g_vHealthBoxAngles[iPositionInArray][0] = vAngles[0];
					g_vHealthBoxAngles[iPositionInArray][1] = vAngles[1];
					g_vHealthBoxAngles[iPositionInArray][2] = vAngles[2];
					
					// setting default values for healthbox
					g_fHealthBoxRechargeTime[iPositionInArray] = g_fHealthBoxDefaultRechargeTime;
					g_fHealthBoxStartDelay[iPositionInArray] = g_fHealthBoxDefaultStartDelay;
					g_iHealthBoxMaxReserve[iPositionInArray] = g_iHealthBoxDefaultReserve;
					g_iHealthBoxAmount[iPositionInArray] = g_iHealthBoxDefaultAmount;
					g_iHealthBoxPrice[iPositionInArray] = g_iHealthBoxDefaultPrice;
					g_iHealthBoxTeam[iPositionInArray] = g_iHealthBoxDefaultTeam;
					g_iHealthBoxMaxHealth[iPositionInArray] = g_iHealthBoxDefaultMaxHealth;
				}
				else // healthbox limit are reached
				{
					PrintToChat(iClient, "%t", "free space not found");
				}
				
				// sending menu back to client
				g_hMainMenu.SetTitle("%t", "main menu title");
				g_hMainMenu.Display(iClient, MENU_TIME_FOREVER);
			}
		}
		// if selected "spawn armorbox"
		else if ( !strcmp(szInfo, "sab") )
		{
			// get client view origin and angles
			float vOrigin[3], vAngles[3];
			if ( GetViewOriginAndAngles(iClient, vOrigin, vAngles) )
			{
				// searching in kv for free space
				char szSectionName[8];
				if ( FindSpaceInKeyValues(g_hArmorBoxKeyValues, "ab", szSectionName, sizeof(szSectionName)) )
				{
					// spawning armorbox model
					int iEntity = SpawnRecharger(vOrigin, vAngles, g_szArmorBoxModel, szSectionName);
					CreateLight(vOrigin, vAngles, iEntity);
					SetLightColor(iEntity, "75 75 75");
					SaveEntity(g_hArmorBoxKeyValues, szSectionName, vOrigin, vAngles);
					
					// saving position
					int iPositionInArray = StringToInt(szSectionName[3]);
					g_bArmorBoxExists[iPositionInArray] = true;
					g_vArmorBoxOrigin[iPositionInArray][0] = vOrigin[0];
					g_vArmorBoxOrigin[iPositionInArray][1] = vOrigin[1];
					g_vArmorBoxOrigin[iPositionInArray][2] = vOrigin[2];
					g_vArmorBoxAngles[iPositionInArray][0] = vAngles[0];
					g_vArmorBoxAngles[iPositionInArray][1] = vAngles[1];
					g_vArmorBoxAngles[iPositionInArray][2] = vAngles[2];
					
					// setting default values for healthbox
					g_fArmorBoxRechargeTime[iPositionInArray] = g_fArmorBoxDefaultRechargeTime;
					g_fArmorBoxStartDelay[iPositionInArray] = g_fArmorBoxDefaultStartDelay;
					g_iArmorBoxMaxReserve[iPositionInArray] = g_iArmorBoxDefaultReserve;
					g_iArmorBoxAmount[iPositionInArray] = g_iArmorBoxDefaultAmount;
					g_iArmorBoxPrice[iPositionInArray] = g_iArmorBoxDefaultPrice;
					g_iArmorBoxTeam[iPositionInArray] = g_iArmorBoxDefaultTeam;
					g_iArmorBoxMaxArmor[iPositionInArray] = g_iArmorBoxDefaultMaxArmor;
				}
				else // armorbox limit are reached
				{
					PrintToChat(iClient, "%t", "free space not found");
				}
				
				// sending menu back to client
				g_hMainMenu.SetTitle("%t", "main menu title");
				g_hMainMenu.Display(iClient, MENU_TIME_FOREVER);
			}
		}
		// selected "delete this recharger"
		else if ( !strcmp(szInfo, "d") )
		{
			// get view entity
			int iEntity = GetClientAimTarget(iClient, false);
			// if entity is valid
			if ( iEntity > MaxClients && IsValidEntity(iEntity) )
			{
				// check by targetname
				char szTargetName[8];
				GetEntPropString(iEntity, Prop_Data, "m_iName", szTargetName, sizeof(szTargetName));
				// if it's healthbox, delete then
				if ( StrContains(szTargetName, "hb_", true) == 0 )
				{
					int iPositionInArray = StringToInt(szTargetName[3]);
					RemoveEntityFromKeyValues(g_hHealthBoxKeyValues, szTargetName);
					g_bHealthBoxExists[iPositionInArray] = false;
					
					int iLightEntity = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
					AcceptEntityInput(iLightEntity, "LightOff");
					AcceptEntityInput(iLightEntity, "kill");
					AcceptEntityInput(iEntity, "kill");
				}
				// if it's armorbox, delete then
				else if ( StrContains(szTargetName, "ab_", true) == 0 )
				{
					int iPositionInArray = StringToInt(szTargetName[3]);
					RemoveEntityFromKeyValues(g_hArmorBoxKeyValues, szTargetName);
					g_bArmorBoxExists[iPositionInArray] = false;
					
					int iLightEntity = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
					AcceptEntityInput(iLightEntity, "LightOff");
					AcceptEntityInput(iLightEntity, "kill");
					AcceptEntityInput(iEntity, "kill");
				}
				// it's not recharger
				else
				{
					PrintToChat(iClient, "%t", "non rechargeable object");
				}
			}
			// it's not recharger
			else
			{
				PrintToChat(iClient, "%t", "non rechargeable object");
			}
			
			// sending menu back to client
			g_hMainMenu.SetTitle("%t", "main menu title");
			g_hMainMenu.Display(iClient, MENU_TIME_FOREVER);
		}
		// if pressed "edit this recharger"
		else if ( !strcmp(szInfo, "e") )
		{
			// get view entity
			int iEntity = GetClientAimTarget(iClient, false);
			// if it is valid entity
			if ( iEntity > MaxClients && IsValidEntity(iEntity) )
			{
				// check by targetname
				char szTargetName[8];
				GetEntPropString(iEntity, Prop_Data, "m_iName", szTargetName, sizeof(szTargetName));
				// if it's healthbox
				if ( StrContains(szTargetName, "hb_", true) == 0 )
				{
					// save client selection
					g_iEditTarget[iClient] = StringToInt(szTargetName[3]);
					g_iEditBox[iClient] = 0;
				}
				// if it's armorbox
				else if ( StrContains(szTargetName, "ab_", true) == 0 )
				{
					// save client selection
					g_iEditTarget[iClient] = StringToInt(szTargetName[3]);
					g_iEditBox[iClient] = 1;
				}
				// it's not recharger
				else
				{
					PrintToChat(iClient, "%t", "non rechargeable object");
					
					// sending menu back to client
					g_hMainMenu.SetTitle("%t", "main menu title");
					g_hMainMenu.Display(iClient, MENU_TIME_FOREVER);
					return;
				}
				
				ShowEditMenu(iClient);
			}
			// it's not recharger
			else
			{
				PrintToChat(iClient, "%t", "non rechargeable object");
				
				// sending menu back to client
				g_hMainMenu.SetTitle("%t", "main menu title");
				g_hMainMenu.Display(iClient, MENU_TIME_FOREVER);
			}
		}
	}
}

// function of saving recharger to keyvalues without kv.Rewind()
void SaveEntity(KeyValues kv, char[] sSectionName, float vOrigin[3], float vAngles[3])
{
	// jump to section
	kv.JumpToKey(sSectionName, true);
	// save values
	kv.SetVector("origin", vOrigin);
	kv.SetVector("angles", vAngles);
	
	// save values
	if ( sSectionName[0] == 'a' )
	{
		kv.SetFloat("rechargetime", g_fArmorBoxDefaultRechargeTime);
		kv.SetFloat("startdelay", 	g_fArmorBoxDefaultStartDelay);
		kv.SetNum("reserve", 		g_iArmorBoxDefaultReserve);
		kv.SetNum("amount", 		g_iArmorBoxDefaultAmount);
		kv.SetNum("price", 			g_iArmorBoxDefaultPrice);
		kv.SetNum("team", 			g_iArmorBoxDefaultTeam);
		kv.SetNum("max", 			g_iArmorBoxDefaultMaxArmor);
	}
	else
	{
		kv.SetFloat("rechargetime", g_fHealthBoxDefaultRechargeTime);
		kv.SetFloat("startdelay", 	g_fHealthBoxDefaultStartDelay);
		kv.SetNum("reserve", 		g_iHealthBoxDefaultReserve);
		kv.SetNum("amount", 		g_iHealthBoxDefaultAmount);
		kv.SetNum("price", 			g_iHealthBoxDefaultPrice);
		kv.SetNum("team", 			g_iHealthBoxDefaultTeam);
		kv.SetNum("max", 			g_iHealthBoxDefaultMaxHealth);
	}
	
	// cut prefix (three first symbols)
	strcopy(sSectionName, 3, sSectionName);
	// save keyvalues
	SaveKeyValues(kv, sSectionName);
}

// function of saving recharger to keyvalues with kv.Rewind()
void SaveEntityEx(KeyValues kv, char[] sSectionName, int iPositionInArray)
{
	// kv rewinding
	kv.Rewind();
	kv.JumpToKey(sSectionName, true);
	
	if ( sSectionName[0] == 'a' )
	{
		kv.SetVector("origin", 		g_vArmorBoxOrigin[iPositionInArray]);
		kv.SetVector("angles", 		g_vArmorBoxAngles[iPositionInArray]);
		kv.SetFloat("rechargetime", g_fArmorBoxRechargeTime[iPositionInArray]);
		kv.SetFloat("startdelay", 	g_fArmorBoxStartDelay[iPositionInArray]);
		kv.SetNum("reserve", 		g_iArmorBoxMaxReserve[iPositionInArray]);
		kv.SetNum("amount", 		g_iArmorBoxAmount[iPositionInArray]);
		kv.SetNum("price", 			g_iArmorBoxPrice[iPositionInArray]);
		kv.SetNum("team", 			g_iArmorBoxTeam[iPositionInArray]);
		kv.SetNum("max", 			g_iArmorBoxMaxArmor[iPositionInArray]);
	}
	else
	{
		kv.SetVector("origin", 		g_vHealthBoxOrigin[iPositionInArray]);
		kv.SetVector("angles", 		g_vHealthBoxAngles[iPositionInArray]);
		kv.SetFloat("rechargetime", g_fHealthBoxRechargeTime[iPositionInArray]);
		kv.SetFloat("startdelay", 	g_fHealthBoxStartDelay[iPositionInArray]);
		kv.SetNum("reserve", 		g_iHealthBoxMaxReserve[iPositionInArray]);
		kv.SetNum("amount", 		g_iHealthBoxAmount[iPositionInArray]);
		kv.SetNum("price", 			g_iHealthBoxPrice[iPositionInArray]);
		kv.SetNum("team", 			g_iHealthBoxTeam[iPositionInArray]);
		kv.SetNum("max", 			g_iHealthBoxMaxHealth[iPositionInArray]);
	}
	
	strcopy(sSectionName, 3, sSectionName);
	SaveKeyValues(kv, sSectionName);
}

// search in keyvalues for free index and check for limit of rechargers
bool FindSpaceInKeyValues(KeyValues kv, char[] szPrefix, char[] szSectionName, int iMaxLen)
{
	int iIndex = 0;
	do
	{
		KvGoBack(kv);
		FormatEx(szSectionName, iMaxLen, "%s_%d", szPrefix, iIndex++);
	} while ( KvJumpToKey(kv, szSectionName) );
	return iIndex < MAX_RECHARGERS;
}

// removing entity from keyvalues by section name
void RemoveEntityFromKeyValues(KeyValues kv, char[] szKey)
{
	kv.Rewind();
	if ( kv.JumpToKey(szKey) )
	{
		kv.DeleteThis();
		
		strcopy(szKey, 3, szKey);
		SaveKeyValues(kv, szKey);
	}
}

// saving keyvalues by prefix
void SaveKeyValues(KeyValues kv, char[] szPrefix)
{
	char szPath[PLATFORM_MAX_PATH], szMapName[32];
	GetCurrentMap(szMapName, sizeof(szMapName));
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/rechargers/%s_%s.txt", szPrefix, szMapName);
	
	KvRewind(kv);
	KeyValuesToFile(kv, szPath);
}

// edit rechargers values by menu
void ShowEditMenu(int iClient)
{
	// creating menu
	Menu hMenu = new Menu(Handle_EditMenu, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
	if ( g_iEditBox[iClient] == 0 )
	{
		hMenu.SetTitle("%t", 	"edit healthbox");
		hMenu.AddItem("m", 		"max health");
	}
	else if ( g_iEditBox[iClient] == 1 )
	{
		hMenu.SetTitle("%t", 	"edit armorbox");
		hMenu.AddItem("m", 		"max armor");
	}
	
	hMenu.AddItem("rt", "recharge time");
	hMenu.AddItem("sd", "start delay");
	hMenu.AddItem("r", 	"reserve");
	hMenu.AddItem("a", 	"amount");
	hMenu.AddItem("p", 	"price");
	hMenu.AddItem("t", 	"team");
	
	// sending
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

// on item pressed in edit menu
public int Handle_EditMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	// dynamic translation, also adding current recharger values
	if ( action == MenuAction_DisplayItem )
	{
		char szInfo[4], szPhrase[64];
		hMenu.GetItem(iSlot, szInfo, sizeof(szInfo), _, szPhrase, sizeof(szPhrase));
		if ( StrEqual(szInfo, "m") )
		{
			int iBuffer;
			if ( g_iEditBox[iClient] == 0 )
			{
				iBuffer = g_iHealthBoxMaxHealth[g_iEditTarget[iClient]];
			}
			else
			{
				iBuffer = g_iArmorBoxMaxArmor[g_iEditTarget[iClient]];
			}
			//PrintToServer("%s %d", szPhrase, iBuffer);
			Format(szPhrase, sizeof(szPhrase), "%t", szPhrase, iBuffer);
		}
		else if ( StrEqual(szInfo, "rt") )
		{
			float fBuffer;
			if ( g_iEditBox[iClient] == 0 )
			{
				fBuffer = g_fHealthBoxRechargeTime[g_iEditTarget[iClient]];
			}
			else
			{
				fBuffer = g_fArmorBoxRechargeTime[g_iEditTarget[iClient]];
			}
			Format(szPhrase, sizeof(szPhrase), "%t", szPhrase, fBuffer);
		}
		else if ( StrEqual(szInfo, "sd") )
		{
			float fBuffer;
			if ( g_iEditBox[iClient] == 0 )
			{
				fBuffer = g_fHealthBoxStartDelay[g_iEditTarget[iClient]];
			}
			else
			{
				fBuffer = g_fArmorBoxStartDelay[g_iEditTarget[iClient]];
			}
			Format(szPhrase, sizeof(szPhrase), "%t", szPhrase, fBuffer);
		}
		else if ( StrEqual(szInfo, "r") )
		{
			int iBuffer;
			if ( g_iEditBox[iClient] == 0 )
			{
				iBuffer = g_iHealthBoxMaxReserve[g_iEditTarget[iClient]];
			}
			else
			{
				iBuffer = g_iArmorBoxMaxReserve[g_iEditTarget[iClient]];
			}
			Format(szPhrase, sizeof(szPhrase), "%t", szPhrase, iBuffer);
		}
		else if ( StrEqual(szInfo, "a") )
		{
			int iBuffer;
			if ( g_iEditBox[iClient] == 0 )
			{
				iBuffer = g_iHealthBoxAmount[g_iEditTarget[iClient]];
			}
			else
			{
				iBuffer = g_iArmorBoxAmount[g_iEditTarget[iClient]];
			}
			Format(szPhrase, sizeof(szPhrase), "%t", szPhrase, iBuffer);
		}
		else if ( StrEqual(szInfo, "p") )
		{
			int iBuffer;
			if ( g_iEditBox[iClient] == 0 )
			{
				iBuffer = g_iHealthBoxPrice[g_iEditTarget[iClient]];
			}
			else
			{
				iBuffer = g_iArmorBoxPrice[g_iEditTarget[iClient]];
			}
			Format(szPhrase, sizeof(szPhrase), "%t", szPhrase, iBuffer);
		}
		else if ( StrEqual(szInfo, "t") )
		{
			int iBuffer;
			if ( g_iEditBox[iClient] == 0 )
			{
				iBuffer = g_iHealthBoxTeam[g_iEditTarget[iClient]];
			}
			else
			{
				iBuffer = g_iArmorBoxTeam[g_iEditTarget[iClient]];
			}
			
			if ( iBuffer == 0 )
			{
				Format(szPhrase, sizeof(szPhrase), "%t%t", szPhrase, "team 0");
			}
			else if ( iBuffer == 2 )
			{
				Format(szPhrase, sizeof(szPhrase), "%t%t", szPhrase, "team 2");
			}
			else if ( iBuffer == 2 )
			{
				Format(szPhrase, sizeof(szPhrase), "%t%t", szPhrase, "team 3");
			}
		}
		
		RedrawMenuItem(szPhrase);
	}
	// item were selected
	else if ( action == MenuAction_Select )
	{
		// get menu item info
		char szInfo[4];
		hMenu.GetItem(iSlot, szInfo, sizeof(szInfo));
		g_iEditChoice[iClient] = iSlot + 1;
		
		// sending chat message, depended on type of selected property
		if ( StrEqual(szInfo, "rt") || StrEqual(szInfo, "sd") )
		{
			PrintToChat(iClient, "%t", "wait for float");
		}
		else
		{
			PrintToChat(iClient, "%t", "wait for int");
		}
	}
	// delete dynamic menu
	else if ( action == MenuAction_End )
	{
		// free memory
		delete hMenu;
	}
}

// if client say something in chat
public Action OnClientSayCommand(int iClient, const char[] szCommand, const char[] szArgs)
{
	// if client selected something in edit menu
	if ( g_iEditChoice[iClient] )
	{
		// just for beauty
		g_iEditChoice[iClient]--;
		
		// change property by chat
		// 0 - max health/armor
		// 1 - recharge time
		// 2 - start delay
		// 3 - reserve
		// 4 - amount
		// 5 - price
		// 6 - team
		int iTarget = g_iEditTarget[iClient];
		if ( g_iEditChoice[iClient] == 0 )
		{
			if ( g_iEditBox[iClient] == 0 )
			{
				g_iHealthBoxMaxHealth[iTarget] = StringToInt(szArgs);
			}
			else
			{
				g_iArmorBoxMaxArmor[iTarget] = StringToInt(szArgs);
			}
		}
		else if ( g_iEditChoice[iClient] == 1 )
		{
			if ( g_iEditBox[iClient] == 0 )
			{
				g_fHealthBoxRechargeTime[iTarget] = StringToFloat(szArgs);
			}
			else
			{
				g_fArmorBoxRechargeTime[iTarget] = StringToFloat(szArgs);
			}
		}
		else if ( g_iEditChoice[iClient] == 2 )
		{
			if ( g_iEditBox[iClient] == 0 )
			{
				g_fHealthBoxStartDelay[iTarget] = StringToFloat(szArgs);
			}
			else
			{
				g_fArmorBoxStartDelay[iTarget] = StringToFloat(szArgs);
			}
		}
		else if ( g_iEditChoice[iClient] == 3 )
		{
			if ( g_iEditBox[iClient] == 0 )
			{
				g_iHealthBoxMaxReserve[iTarget] = StringToInt(szArgs);
			}
			else
			{
				g_iArmorBoxMaxReserve[iTarget] = StringToInt(szArgs);
			}
		}
		else if ( g_iEditChoice[iClient] == 4 )
		{
			if ( g_iEditBox[iClient] == 0 )
			{
				g_iHealthBoxAmount[iTarget] = StringToInt(szArgs);
			}
			else
			{
				g_iArmorBoxAmount[iTarget] = StringToInt(szArgs);
			}
		}
		else if ( g_iEditChoice[iClient] == 5 )
		{
			if ( g_iEditBox[iClient] == 0 )
			{
				g_iHealthBoxPrice[iTarget] = StringToInt(szArgs);
			}
			else
			{
				g_iArmorBoxPrice[iTarget] = StringToInt(szArgs);
			}
		}
		else if ( g_iEditChoice[iClient] == 6 )
		{
			if ( g_iEditBox[iClient] == 0 )
			{
				g_iHealthBoxTeam[iTarget] = StringToInt(szArgs);
			}
			else
			{
				g_iArmorBoxTeam[iTarget] = StringToInt(szArgs);
			}
		}
		
		// save changing
		char szBuffer[16];
		if ( g_iEditBox[iClient] == 0 )
		{
			FormatEx(szBuffer, sizeof(szBuffer), "hb_%d", iTarget);
			SaveEntityEx(g_hHealthBoxKeyValues, szBuffer, iTarget);
		}
		else
		{
			FormatEx(szBuffer, sizeof(szBuffer), "ab_%d", iTarget);
			SaveEntityEx(g_hArmorBoxKeyValues, szBuffer, iTarget);
		}
		g_iEditChoice[iClient] = 0;
	}
}

// recharger spawning
int SpawnRecharger(float vOrigin[3], float vAngles[3], const char[] szModel, const char[] szTargetName)
{
	// create prop_physics
	int iEntity = CreateEntityByName("prop_physics");
	
	// set values
	DispatchKeyValue(iEntity, "model", 			szModel);
	DispatchKeyValue(iEntity, "spawnflags", 	"256");
	DispatchKeyValue(iEntity, "targetname", 	szTargetName);
	DispatchKeyValueVector(iEntity, "origin", 	vOrigin);
	DispatchKeyValueVector(iEntity, "angles", 	vAngles);
	
	// if failed at spawn
	if ( !DispatchSpawn(iEntity) ) return 0;
	
	// freeze entity in world
	SetEntityMoveType(iEntity, MOVETYPE_NONE);
	AcceptEntityInput(iEntity, "DisableMotion");
	// return entity index
	return iEntity;
}

// light spawning
int CreateLight(float vOrigin[3], float vAngles[3], int iOwnerEntity)
{
	// create point_spotlight
	int iEntity = CreateEntityByName("point_spotlight");
	
	// set values
	DispatchKeyValue(iEntity, "rendermode", 		"9");
	DispatchKeyValue(iEntity, "spotlightwidth",	 	"1");
	DispatchKeyValue(iEntity, "spotlightlength", 	"1");
	DispatchKeyValue(iEntity, "renderamt", 			"255");
	DispatchKeyValue(iEntity, "spawnflags", 		"1");
	
	// direct spotlight into wall because of his brightness
	float vBuffer[3];
	vBuffer[0] = vAngles[0] - 90;
	vBuffer[1] = vAngles[1];
	vBuffer[2] = vAngles[2];
	
	// set entity origin and angles
	DispatchKeyValueVector(iEntity, "origin", vOrigin);
	DispatchKeyValueVector(iEntity, "angles", vBuffer);
	
	// if failed at spawning or owning entity doesn't exists return 0
	if ( !DispatchSpawn(iEntity) ) return 0;
	if ( !IsValidEntity(iOwnerEntity) ) return 0;
	
	// set owner entity
	SetEntPropEnt(iOwnerEntity, Prop_Data, "m_hOwnerEntity", iEntity);
	// return entity index
	return iEntity;
}

// set light color
void SetLightColor(int iOwnerEntity, char[] szColor)
{
	if ( iOwnerEntity != -1 && IsValidEntity(iOwnerEntity) )
	{
		int iLightEntity = GetEntPropEnt(iOwnerEntity, Prop_Data, "m_hOwnerEntity");
		if ( IsValidEntity(iLightEntity) )
		{
			// to change color we need to send two more inputs: turnOff and turnOn
			AcceptEntityInput(iLightEntity, "LightOff");
			DispatchKeyValue(iLightEntity, 	"RenderColor", szColor);
			AcceptEntityInput(iLightEntity, "LightOn");
		}
	}
}

// get activator manualy because of valve bug
bool GetActivator(int iEntity, int &iCaller)
{
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) && GetClientButtons(i) & IN_USE && GetClientAimTarget(i, false) == iEntity && g_hBoxActionTimer[i] == null )
		{
			iCaller = i;
			return true;
		}
	}
	return false;
}

// get client view origin and angles
bool GetViewOriginAndAngles(int iClient, float vOrigin[3], float vAngles[3])
{
	GetClientEyePosition(iClient, vOrigin);
	GetClientEyeAngles(iClient, vAngles);
	
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TR_DontHitSelf, iClient);
	if ( TR_DidHit(INVALID_HANDLE) )
	{
		TR_GetEndPosition(vOrigin, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, vAngles);
		GetVectorAngles(vAngles, vAngles);
		vAngles[0] += 90.0;
		return true;
	}
	
	return false;
}

// traceray filter
public bool TR_DontHitSelf(int iEntity, int iMask, any iData) { return ( iEntity != iData ); }

// on round start (spawn entitys)
public void Ev_RoundStart(Event hEvent, const char[] szEvName, bool bDontBroadcast)
{
	char szTargetName[8];
	// spawn rechargers
	for ( int i = 0; i < MAX_RECHARGERS; ++i )
	{
		// armorboxes
		if ( g_bArmorBoxExists[i] )
		{
			FormatEx(szTargetName, sizeof(szTargetName), "ab_%d", i);
			g_iArmorBoxEntity[i] = SpawnRecharger(g_vArmorBoxOrigin[i], g_vArmorBoxAngles[i], g_szArmorBoxModel, szTargetName);
			CreateLight(g_vArmorBoxOrigin[i], g_vArmorBoxAngles[i], g_iArmorBoxEntity[i]);
			SetLightColor(g_iArmorBoxEntity[i], g_szArmorBoxEmptyColor);
			HookSingleEntityOutput(g_iArmorBoxEntity[i], "OnPlayerUse", OnArmorBoxUse);
			
			g_iArmorBoxCurrentReserve[i] = 0;
			if ( g_hArmorBoxRestoreTimer[i] != null )
			{
				KillTimer(g_hArmorBoxRestoreTimer[i]);
				g_hArmorBoxRestoreTimer[i] = null;
			}
		}
		
		// healthboxes
		if ( g_bHealthBoxExists[i] )
		{
			FormatEx(szTargetName, sizeof(szTargetName), "hb_%d", i);
			g_iHealthBoxEntity[i] = SpawnRecharger(g_vHealthBoxOrigin[i], g_vHealthBoxAngles[i], g_szHealthBoxModel, szTargetName);
			CreateLight(g_vHealthBoxOrigin[i], g_vHealthBoxAngles[i], g_iHealthBoxEntity[i]);
			SetLightColor(g_iHealthBoxEntity[i], g_szHealthBoxEmptyColor);
			HookSingleEntityOutput(g_iHealthBoxEntity[i], "OnPlayerUse", OnHealthBoxUse);
			
			g_iHealthBoxCurrentReserve[i] = 0;
			if ( g_hHealthBoxRestoreTimer[i] != null )
			{
				KillTimer(g_hHealthBoxRestoreTimer[i]);
				g_hHealthBoxRestoreTimer[i] = null;
			}
		}
	}
}

// on round freeze end (enable recharges or start recharge timers)
public void Ev_RoundFreezeEnd(Event hEvent, const char[] szEvName, bool bDontBroadcast)
{
	for ( int i = 0; i < MAX_RECHARGERS; ++i )
	{
		if ( g_bArmorBoxExists[i] )
		{
			if ( g_fArmorBoxStartDelay[i] == 0.0 )
			{
				g_iArmorBoxCurrentReserve[i] = g_iArmorBoxMaxReserve[i];
				SetLightColor(g_iArmorBoxEntity[i], g_szArmorBoxFullColor);
			}
			else
			{
				g_hArmorBoxRestoreTimer[i] = CreateTimer(g_fArmorBoxStartDelay[i], Timer_RestoreArmorBox, i);
			}
		}
		if ( g_bHealthBoxExists[i] )
		{
			if ( g_fHealthBoxStartDelay[i] == 0.0 )
			{
				g_iHealthBoxCurrentReserve[i] = g_iHealthBoxMaxReserve[i];
				SetLightColor(g_iHealthBoxEntity[i], g_szHealthBoxFullColor);
			}
			else
			{
				g_hHealthBoxRestoreTimer[i] = CreateTimer(g_fHealthBoxStartDelay[i], Timer_RestoreHealthBox, i);
			}
		}
	}
}

// set armorbox reserve
public Action Timer_RestoreArmorBox(Handle hTimer, any iIndex)
{
	g_iArmorBoxCurrentReserve[iIndex] = g_iArmorBoxMaxReserve[iIndex];
	SetLightColor(g_iArmorBoxEntity[iIndex], g_szArmorBoxFullColor);
	g_hArmorBoxRestoreTimer[iIndex] = null;
}

// set healthbox reserve
public Action Timer_RestoreHealthBox(Handle hTimer, any iIndex)
{
	g_iHealthBoxCurrentReserve[iIndex] = g_iHealthBoxMaxReserve[iIndex];
	SetLightColor(g_iHealthBoxEntity[iIndex], g_szHealthBoxFullColor);
	g_hHealthBoxRestoreTimer[iIndex] = null;
}

// on +USE armorbox
public void OnArmorBoxUse(const char[] szOutput, int iCaller, int iActivator, float fDelay)
{
	// since valve bug with iCaller and iActivator, we have to find activator manually
	if ( GetActivator(iCaller, iActivator) )
	{
		// if he isn't already healing
		if ( g_hBoxActionTimer[iActivator] != null ) return;
		
		// get index of using armorbox
		char szTargetName[8];
		GetEntPropString(iCaller, Prop_Data, "m_iName", szTargetName, sizeof(szTargetName));
		int iPositionInArray = StringToInt(szTargetName[3]);
		// chech for reserve
		if ( g_iArmorBoxCurrentReserve[iPositionInArray] <= 0 )
		{
			PrintToChat(iActivator, "%t", "out of charge");
			EmitSoundToAllAny(g_szArmorBoxSoundEmpty, iActivator);
			return;
		}
		// check team restriction
		if ( g_iArmorBoxTeam[iPositionInArray] && g_iArmorBoxTeam[iPositionInArray] != GetClientTeam(iActivator) )
		{
			PrintToChat(iActivator, "%t", "restricted by team");
			EmitSoundToAllAny(g_szArmorBoxSoundDenied, iActivator);
			return;
		}
		
		// start armor repair
		RestoreArmor(iActivator, iPositionInArray);
	}
}

// first armor restore
void RestoreArmor(int iClient, int iPositionInArray)
{
	// get client armor
	int iClientArmor = GetEntData(iClient, g_iArmorOffset);
	// check for max armor 
	if ( iClientArmor >= g_iArmorBoxMaxArmor[iPositionInArray] )
	{
		PrintToChat(iClient, "%t", "max armor reached");
		EmitSoundToAllAny(g_szArmorBoxSoundDenied, iClient);
		return;
	}
	
	// check one repair price
	if ( g_iArmorBoxPrice[iPositionInArray] > 0 )
	{
		int iMoneyAfterPay = GetEntData(iClient, g_iAccountOffset) - g_iArmorBoxPrice[iPositionInArray];
		if ( iMoneyAfterPay < 0 )
		{
			PrintToChat(iClient, "%t", "not enough money", g_iArmorBoxPrice[iPositionInArray]);
			EmitSoundToAllAny(g_szArmorBoxSoundDenied, iClient);
			return;
		}
		else
		{
			SetEntData(iClient, g_iAccountOffset, iMoneyAfterPay);
		}
	}
	
	// repairing, if armor > maxarmor, set armor = maxarmor
	int iArmorAmount = g_iArmorBoxMaxArmor[iPositionInArray] - iClientArmor;
	if ( iArmorAmount > g_iArmorBoxAmount[iPositionInArray] )
	{
		iArmorAmount = g_iArmorBoxAmount[iPositionInArray];
	}
	
	// check for remain reserve
	if ( iArmorAmount >= g_iArmorBoxCurrentReserve[iPositionInArray] )
	{
		SetLightColor(g_iArmorBoxEntity[iPositionInArray], g_szArmorBoxEmptyColor);
		iArmorAmount = g_iArmorBoxCurrentReserve[iPositionInArray];
		g_iArmorBoxCurrentReserve[iPositionInArray] = 0;
		PrintToChat(iClient, "%t", "out of charge");
		EmitSoundToAllAny(g_szArmorBoxSoundEmpty, iClient);
		
		if ( g_hArmorBoxRestoreTimer[iPositionInArray] == null )
		{
			g_hArmorBoxRestoreTimer[iPositionInArray] = CreateTimer(g_fArmorBoxRechargeTime[iPositionInArray], Timer_RestoreArmorBox, iPositionInArray);
		}
	}
	else
	{
		g_iArmorBoxCurrentReserve[iPositionInArray] -= iArmorAmount;
	}
	
	// emit sound, setting client armor
	EmitSoundToAllAny(g_szArmorBoxSound, iClient);
	SetEntData(iClient, g_iArmorOffset, iClientArmor + iArmorAmount);
	
	// calling next timer
	Handle hDataPack = CreateDataPack();
	WritePackCell(hDataPack, iClient);
	WritePackCell(hDataPack, iPositionInArray);
	
	g_hBoxActionTimer[iClient] = CreateTimer(RESTORE_INTERVAL, Timer_RestoreArmor, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
}

// timer for armor restore
public Action Timer_RestoreArmor(Handle hTimer, any hDataPack)
{
	// read data from datapack
	ResetPack(hDataPack);
	int iClient = ReadPackCell(hDataPack),
		iPositionInArray = ReadPackCell(hDataPack);
	CloseHandle(hDataPack);
	
	// check for holding +USE and client still watching at using armorbox
	if ( GetClientButtons(iClient) & IN_USE && GetClientAimTarget(iClient, false) == g_iArmorBoxEntity[iPositionInArray] )
	{
		// chech for distance between client and recharger entity
		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		if ( GetVectorDistance(vecOrigin, g_vArmorBoxOrigin[iPositionInArray]) < MAX_HEAL_DISTANCE )
		{
			// if armorbox has reserve
			if ( g_iArmorBoxCurrentReserve[iPositionInArray] > 0 )
			{
				// restore armor
				RestoreArmor(iClient, iPositionInArray);
			}
		}
	}
	
	// else client stopped repair of armor 
	g_hBoxActionTimer[iClient] = null;
}

// same things as armorbox only for healthbox
public void OnHealthBoxUse(const char[] szOutput, int iCaller, int iActivator, float fDelay)
{
	if ( GetActivator(iCaller, iActivator) )
	{
		if ( g_hBoxActionTimer[iActivator] != null ) return;
		
		char szTargetName[8];
		GetEntPropString(iCaller, Prop_Data, "m_iName", szTargetName, sizeof(szTargetName));
		int iPositionInArray = StringToInt(szTargetName[3]);
		if ( g_iHealthBoxCurrentReserve[iPositionInArray] <= 0 )
		{
			PrintToChat(iActivator, "%t", "out of charge");
			EmitSoundToAllAny(g_szHealthBoxSoundEmpty, iActivator);
			return;
		}
		if ( g_iHealthBoxTeam[iPositionInArray] && g_iArmorBoxTeam[iPositionInArray] != GetClientTeam(iActivator) )
		{
			PrintToChat(iActivator, "%t", "restricted by team");
			EmitSoundToAllAny(g_szHealthBoxSoundDenied, iActivator);
			return;
		}
		
		HealClient(iActivator, iPositionInArray);
	}
}

// same things as armorbox only for healthbox
void HealClient(int iClient, int iPositionInArray)
{
	int iClientHealth = GetEntData(iClient, g_iHealthOffset);
	if ( iClientHealth >= g_iHealthBoxMaxHealth[iPositionInArray] )
	{
		PrintToChat(iClient, "%t", "max health reached");
		EmitSoundToAllAny(g_szHealthBoxSoundDenied, iClient);
		return;
	}
	
	if ( g_iHealthBoxPrice[iPositionInArray] > 0 )
	{
		int iMoneyAfterPay = GetEntData(iClient, g_iAccountOffset) - g_iHealthBoxPrice[iPositionInArray];
		if ( iMoneyAfterPay < 0 )
		{
			PrintToChat(iClient, "%t", "not enough money", g_iHealthBoxPrice[iPositionInArray]);
			EmitSoundToAllAny(g_szHealthBoxSoundDenied, iClient);
			return;
		}
		else
		{
			SetEntData(iClient, g_iAccountOffset, iMoneyAfterPay);
		}
	}
	
	int iHealAmount = g_iHealthBoxMaxHealth[iPositionInArray] - iClientHealth;
	if ( iHealAmount > g_iHealthBoxAmount[iPositionInArray] )
	{
		iHealAmount = g_iHealthBoxAmount[iPositionInArray];
	}
	
	if ( iHealAmount >= g_iHealthBoxCurrentReserve[iPositionInArray] )
	{
		SetLightColor(g_iHealthBoxEntity[iPositionInArray], g_szHealthBoxEmptyColor);
		iHealAmount = g_iHealthBoxCurrentReserve[iPositionInArray];
		g_iHealthBoxCurrentReserve[iPositionInArray] = 0;
		PrintToChat(iClient, "%t", "out of charge");
		EmitSoundToAllAny(g_szHealthBoxSoundEmpty, iClient);
		
		if ( g_hHealthBoxRestoreTimer[iPositionInArray] == null )
		{
			g_hHealthBoxRestoreTimer[iPositionInArray] = CreateTimer(g_fHealthBoxRechargeTime[iPositionInArray], Timer_RestoreHealthBox, iPositionInArray);
		}
	}
	else
	{
		g_iHealthBoxCurrentReserve[iPositionInArray] -= iHealAmount;
	}
	
	EmitSoundToAllAny(g_szHealthBoxSound, iClient);
	SetEntData(iClient, g_iHealthOffset, iClientHealth + iHealAmount);
	
	Handle hDataPack = CreateDataPack();
	WritePackCell(hDataPack, iClient);
	WritePackCell(hDataPack, iPositionInArray);
	
	g_hBoxActionTimer[iClient] = CreateTimer(RESTORE_INTERVAL, Timer_HealClient, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
}

// same things as armorbox only for healthbox
public Action Timer_HealClient(Handle hTimer, any hDataPack)
{
	ResetPack(hDataPack);
	int iClient = ReadPackCell(hDataPack),
		iPositionInArray = ReadPackCell(hDataPack);
	CloseHandle(hDataPack);
	
	if ( GetClientButtons(iClient) & IN_USE && GetClientAimTarget(iClient, false) == g_iHealthBoxEntity[iPositionInArray] )
	{
		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		if ( GetVectorDistance(vecOrigin, g_vHealthBoxOrigin[iPositionInArray]) < MAX_HEAL_DISTANCE )
		{
			if ( g_iHealthBoxCurrentReserve[iPositionInArray] > 0 )
			{
				HealClient(iClient, iPositionInArray);
			}
		}
	}
	
	g_hBoxActionTimer[iClient] = null;
}

// sending main menu to client
public Action Command_Rechargers(int iClient, int iArgs)
{
	g_hMainMenu.SetTitle("%t", "main menu title");
	g_hMainMenu.Display(iClient, MENU_TIME_FOREVER);
	return Plugin_Handled;
}