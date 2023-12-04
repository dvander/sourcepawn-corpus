#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>
#include <cstrike>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_sound>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#if SOURCEMOD_V_MINOR >= 9
	#include <sdktools_variant_t>
#endif
#include <usermessages>

#if SOURCEMOD_V_MINOR > 10
	#define PL_NAME	"Revival"
	#define PL_VER	"1.1.3_fix"
#endif


static const char
#if SOURCEMOD_V_MINOR < 11
	PL_NAME[]	= "Revival",
	PL_VER[]	= "1.1.3_fix",
#endif

	MARK_CSS[]	= "hud/scoreboard_dead",// Default sprite for CSGO & CSS OB
	MARK_V34[]	= "sprites/glow",		//		-//-		  CSSv34
	KEY_NAME[][]= {"Ctrl", "E", "Shift"},
	CLR[][][]	=
{//		name		CSGO		CSS OB		CSSv34
	{"{DEFAULT}",	"\x01",	"\x01",			"\x01"},
	{"{TEAM}",		"\x03",	"\x03",			"\x03"},
	{"{GREEN}",		"\x04",	"\x0700AD00",	"\x04"},
	{"{WHITE}",		"\x01",	"\x07FFFFFF",	""},
	{"{RED}",		"\x02",	"\x07FF0000",	""},
	{"{LIME}",		"\x05",	"\x0700FF00",	""},
	{"{LIGHTGREEN}","\x06",	"\x0799FF99",	""},
	{"{LIGHTRED}",	"\x07",	"\x07FF4040",	""},
	{"{GRAY}",		"\x08",	"\x07CCCCCC",	""},
	{"{LIGHTOLIVE}","\x09",	"\x07FFBD6B",	""},
	{"{OLIVE}",		"\x10",	"\x07FA8B00",	""},
	{"{BLUEGREY}",	"\x0A",	"\x076699CC",	""},
	{"{LIGHTBLUE}",	"\x0B",	"\x0799CCFF",	""},
	{"{BLUE}",		"\x0C",	"\x073D46FF",	""},
	{"{PURPLE}",	"\x0E",	"\x07FA00FA",	""},
	{"{LIGHTRED2}",	"\x0F",	"\x07FF8080",	""}
};

static const int
	COLOR[]		= {0xff3f1f, 0x1f3fff, 0x00bf00, 0x00bf00},	// T, CT, Any
	KEY_VAL[]	= {IN_DUCK, IN_USE, IN_SPEED};
static const float
	NULL_PERCENT[MAXPLAYERS+1]	= {0.0, ...},
	EFF_LIFE	= 1.0,	// частота обновления эффекта
	MARK_SIZE	= 0.3,	// размер меток
	UPDATE		= 5.0;	// минимальная частота обновления информации HUD и KeyHint - раз в 5 секунд

enum
{
	E_Unknown,
	E_CSGO,
	E_CSS,
	E_Old
};

enum
{
	M_T,
	M_CT,
	M_Any,
	M_HUD
};

enum
{
	S_1ST = 4,
	S_3RD
};

enum
{
	RI_Revives,
	RI_Revived,
	RI_Target,
	RI_Percents
};

bool
	bEnable,
	bTip,
	bMsg,
	bPos,
	bTeam,
	bEnemy,
	bBar[MAXPLAYERS+1],
	bPercent,
	bEffect,
	bDeath,
	bSprites,
	bReset;
float
	fRadius,
	fNoDmgTime,
	fPosX,
	fPosY;
int
	iKey[MAXPLAYERS+1],
	iHUD[MAXPLAYERS+1],
	iClean,
	iTime,
	iCD,
	iTimes,
	iNoBlockTime,
	iHPCost,
	iHPMax,
	iHP,
	iFrag,
	iRIP,
	iColor[4],
	iBalance;
char
	sCvarPath[PLATFORM_MAX_PATH],
	sSound[PLATFORM_MAX_PATH],
	sMark[3][PLATFORM_MAX_PATH],
	sKeyHintText[MAXPLAYERS+1][1024];

Handle
	hFwd_PlayerRevived,
	hCookies,
	hHUD,
	hTimer,
	hTimerClear[MAXPLAYERS+1];
Menu
	hMenu;
bool
	bLate,
	bAllowed = true,
	bProto,
	bProtected[MAXPLAYERS+1],
	bDefault[3];
int
	iEngine,
	iOffsetGroup,
	hBeam = -1,
	hHalo = -1,
	iMarkRef[MAXPLAYERS+1] = {-1, ...},
	iTimesRevived[MAXPLAYERS+1],
	iTeam[MAXPLAYERS+1],
	iDeathTeam[MAXPLAYERS+1],
	iTarget[MAXPLAYERS+1],
	iReviver[MAXPLAYERS+1],
	iRevives[MAXPLAYERS+1][2],
	iDiff,
	iPercents[MAXPLAYERS+1];
float
	fDeathPos[MAXPLAYERS+1][3],
	fDeathAng[MAXPLAYERS+1][3],
	fProgress[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= PL_NAME,
	author		= "Grey83",
	description	= "Press and hold +USE above death place to respawn player",
	version		= PL_VER,
	url			= "https://steamcommunity.com/groups/grey83ds"
//	https://github.com/Grey83/SourceMod-plugins/blob/master/SM/scripting/sm_revival.sp
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Revival_GetPlayerInfo", Native_GetPlayerInfo);
	RegPluginLibrary("revival");
	bLate = late;
	return APLRes_Success;
}

public int Native_GetPlayerInfo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	if(!IsClientConnected(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	if(IsFakeClient(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is a bot", client);

	switch(GetNativeCell(2))
	{
		case RI_Revives:	return iRevives[client][0];
		case RI_Revived:	return iTimesRevived[client];
		case RI_Target:		return iTarget[client];
		case RI_Percents:	return iPercents[client];
	}
	return -1;
}

public int Native_OnPlayerStatusChanged(Handle plugin, int numParams)
{
	AddToForward(hFwd_PlayerRevived, plugin, GetNativeFunction(1));
}

public void OnPluginStart()
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO:
			iEngine = E_CSGO;
		case Engine_CSS:
			iEngine = E_CSS;
		case Engine_SourceSDK2006:
			iEngine = E_Old;
		default: SetFailState("Plugin for CS:S and CS:GO only!");
	}

	hFwd_PlayerRevived = CreateGlobalForward("Revival_OnPlayerRevived", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	bProto = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;

	if(iEngine != E_Old) hHUD = CreateHudSynchronizer();

	iOffsetGroup	= FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

	CreateConVar("sm_revival_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	ConVar cvar;
	cvar = CreateConVar("sm_revival_enabled", "1", "Enable/disable plugin", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_tip", "1", "Enable/disable key tip at the beginning of the round", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Tip);
	bTip = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_msg", "1", "Enable/disable chat messages", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Msg);
	bMsg = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_key", "1", "Default key for reviving (0 - 'duck', 1 - 'use', 2 - 'walk', 3 - no key needed)", _, true, _, true, 3.0);
	cvar.AddChangeHook(CVarChanged_Key);
	iKey[0] = cvar.IntValue;

	cvar = CreateConVar("sm_revival_pos", "1", "Spawn player at: 0 - position of reviver, 1 - his death position", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Pos);
	bPos = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_clean", "2", "Remove body x sec after the death (-1 - don't remove)", FCVAR_NOTIFY, true, -1.0);
	cvar.AddChangeHook(CVarChanged_Clean);
	iClean = cvar.IntValue;

	cvar = CreateConVar("sm_revival_teamchange", "1", "Can a player be revived after a team change", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Team);
	bTeam = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_enemy", "0", "Can a player revive the enemy (the revived player will change the team)", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enemy);
	bEnemy = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_bar", "1", "Enable/disable progressbar for reviving", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Bar);
	bBar[0] = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_percent", "1", "Enable/disable save the percentage of reviving", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Percent);
	bPercent = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_effect", "1", "Enable/disable effect around to place of death", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Effect);
	bEffect = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_radius", "200.0", "Radius to respawn death player", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChanged_Radius);
	fRadius = cvar.FloatValue;

	cvar = CreateConVar("sm_revival_time", "0", "The time after the death of the player, during which the revive is possible", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChanged_Time);
	iTime = cvar.IntValue;

	cvar = CreateConVar("sm_revival_countdown", "3", "Time for respawn in seconds", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChanged_CD);
	iCD = cvar.IntValue;

	cvar = CreateConVar("sm_revival_times", "0", "How many times can a player revive other players during the round (0 - unlimited)", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChanged_Times);
	iTimes = cvar.IntValue;

	cvar = CreateConVar("sm_revival_reset", "0", "Reset counter of revived (for cvar 'sm_revival_times') at every: 0 - round, 1 - spawn", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Reset);
	bReset = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_noblock_time", "2", "Noblocking time after respawn(set at 0 if you have any noblock plugin)", _, true);
	cvar.AddChangeHook(CVarChanged_NoBlockTime);
	iNoBlockTime = cvar.IntValue;

	cvar = CreateConVar("sm_revival_health_cost", "25", "Need's health to respawn others (negative - add HP to reviver)", FCVAR_NOTIFY, true, -100.0, true, 100.0);
	cvar.AddChangeHook(CVarChanged_HPCost);
	iHPCost = cvar.IntValue;

	cvar = CreateConVar("sm_revival_maxhealth", "100", "The maximum amount of health that a reviver can receive for reviving players (0 - disable limit)", FCVAR_NOTIFY, true, _, true, 10000.0);
	cvar.AddChangeHook(CVarChanged_HPMax);
	iHPMax = cvar.IntValue;

	cvar = CreateConVar("sm_revival_death", "1", "Can a player revive others if he have less HP than needed for reviving", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Death);
	bDeath = cvar.BoolValue;

	cvar = CreateConVar("sm_revival_health", "100", "How many HP will get revived player", FCVAR_NOTIFY, true, 25.0);
	cvar.AddChangeHook(CVarChanged_HP);
	iHP = cvar.IntValue;

	cvar = CreateConVar("sm_revival_frag", "1", "Give x frags to the player for revived teammate", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChanged_Frag);
	iFrag = cvar.IntValue;

	cvar = CreateConVar("sm_revival_rip", "0", "Disallow the revival of the players killed: 1 - in the head, 2 - with a knife.", FCVAR_NOTIFY, true, _, true, 3.0);
	cvar.AddChangeHook(CVarChanged_RIP);
	iRIP = cvar.IntValue;

	cvar = CreateConVar("sm_revival_balance", "1", "The difference in the number of live players of the teams, at which player can revive allies (-1 - disable restriction)", _, true, -1.0, true, 5.0);
	cvar.AddChangeHook(CVarChanged_Balance);
	iBalance = cvar.IntValue;

	cvar = CreateConVar("sm_revival_soundpath", "ui/achievement_earned.wav", "This sound playing after reviving (empty string = disabled)", FCVAR_PRINTABLEONLY, true);
	cvar.AddChangeHook(CVarChanged_Sound);
	cvar.GetString(sCvarPath, sizeof(sCvarPath));

	cvar = CreateConVar("sm_revival_nodmg_time", "2.0", "No damage recive time after respawn (set at 0.0 if you have any spawn protect plugin)", _, true, _, true, 5.0);
	cvar.AddChangeHook(CVarChanged_NoDmgTime);
	fNoDmgTime = cvar.FloatValue;

	cvar = CreateConVar("sm_revival_color_t", "ff3f1f", "T death mark color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = red", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_ColorT);
	SetColor(cvar, M_T);

	cvar = CreateConVar("sm_revival_color_ct", "1f3fff", "CT death mark color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = blue", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_ColorCT);
	SetColor(cvar, M_CT);

	cvar = CreateConVar("sm_revival_color_any", "00bf00", "Any death team mark color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = green", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_ColorAny);
	SetColor(cvar, M_Any);

	cvar = CreateConVar("sm_revival_best", "3", "Show TOPx revivers at round end (0 - disable)", _, true, _, true, 10.0);
	cvar.AddChangeHook(CVarChanged_Best);
	iRevives[0][0] = cvar.IntValue;

	cvar = CreateConVar("sm_revival_worst", "3", "Show AntiTOP revivers at round end (0 - disable)", _, true, _, true, 10.0);
	cvar.AddChangeHook(CVarChanged_Worst);
	iRevives[0][1] = cvar.IntValue;

	cvar = CreateConVar("sm_revival_mark_t", ".vmt", "Path to the vmt-file in folder 'materials' for the T mark. Wrong or empty path = default mark.", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_MarkT);
	PrepareMark(cvar, M_T);

	cvar = CreateConVar("sm_revival_mark_ct", ".vmt", "Path to the vmt-file in folder 'materials' for the CT mark. Wrong or empty path = default mark.", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_MarkCT);
	PrepareMark(cvar, M_CT);

	cvar = CreateConVar("sm_revival_mark_any", ".vmt", "Path to the vmt-file in folder 'materials' for the Any mark. Wrong or empty path = default mark.", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_MarkAny);
	PrepareMark(cvar, M_Any);

	if(iEngine != E_Old)
	{
		cvar = CreateConVar("sm_revival_hud_x", "0.99", "HUD info position X (0.0 - 1.0 left to right or -1 for center)", _, true, -2.0, true, 1.0);
		cvar.AddChangeHook(CVarChanged_HUDPosX);
		fPosX = cvar.FloatValue;

		cvar = CreateConVar("sm_revival_hud_y", "0.75", "HUD info position Y (0.0 - 1.0 top to bottom or -1 for center)", _, true, -2.0, true, 1.0);
		cvar.AddChangeHook(CVarChanged_HUDPosY);
		fPosY = cvar.FloatValue;

		cvar = CreateConVar("sm_revival_hud_color", "00bf00", "HUD info color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = green", FCVAR_PRINTABLEONLY);
		cvar.AddChangeHook(CVarChanged_HUDColor);
		SetColor(cvar, M_HUD);

		cvar = CreateConVar("sm_revival_hud_mode", "2", "Show additional info in the: 0 - chat only, 1 - HUD, 2 - KeyHint (not for CS:S v34)", _, true, _, true, 2.0);
		cvar.AddChangeHook(CVarChanged_HUDMode);
		iHUD[0] = cvar.IntValue;
	}

	if(iEngine == E_CSS) HookUserMessage(GetUserMessageId("KeyHintText"), HookKeyHintText, true);

	hCookies = RegClientCookie("revive", "Revive clients settings", CookieAccess_Private);
	SetCookieMenuItem(Cookie_Revive, 0, PL_NAME);

	HookEvent("player_team", Event_Team);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_death", Event_Death);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	LoadTranslations("revival.phrases");

	AutoExecConfig(true, "revival");

	RegConsoleCmd("sm_revival", Cmd_Menu, "Show client settings for Revival");

	if(!bLate) return;

	for(int i = 1; i <= MaxClients; i++) if(IsPlayerValid(i))
	{
		if(!AreClientCookiesCached(i))
		{
			iKey[i] = iKey[0];
			bBar[i] = bBar[0];
			iHUD[i] = iHUD[0];
		}
		else GetCookieValue(i);
	}
	CountAlive();
	bLate = false;
}

public void OnPluginEnd()
{
	for(int i = 1, ent; i <= MaxClients; i++) if((ent = GetMarkId(i)) != -1) AcceptEntityInput(ent, "Kill");
}

public void CVarChanged_Enable(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bEnable = cvar.BoolValue;
	PrintToChatAllClr("%t%t", "ChatTag", bEnable ? "Enabled" : "Disabled");
	if(iEngine != E_Old) UpdateTimer();
}

public void CVarChanged_Tip(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bTip = cvar.BoolValue;
}

public void CVarChanged_Msg(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bMsg = cvar.BoolValue;
}

public void CVarChanged_Key(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iKey[0] = cvar.IntValue;
}

public void CVarChanged_Pos(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bPos = cvar.BoolValue;
}

public void CVarChanged_Clean(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iClean = cvar.IntValue;
}

public void CVarChanged_Team(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bTeam = cvar.BoolValue;
}

public void CVarChanged_Enemy(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bEnemy = cvar.BoolValue;

	for(int i; i <= MaxClients; i++) if(iDeathTeam[i] && iMarkRef[i] == -1) SetMarkColor(i);
}

public void CVarChanged_Bar(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bBar[0] = cvar.BoolValue;
}

public void CVarChanged_Percent(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bPercent = cvar.BoolValue;
}

public void CVarChanged_Effect(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bEffect = cvar.BoolValue;
}

public void CVarChanged_Radius(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	fRadius = cvar.FloatValue;
}

public void CVarChanged_Time(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iTime = cvar.IntValue;
}

public void CVarChanged_CD(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iCD = cvar.IntValue;
}

public void CVarChanged_Times(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iTimes = cvar.IntValue;
}

public void CVarChanged_Reset(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bReset = cvar.BoolValue;
}

public void CVarChanged_NoBlockTime(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iNoBlockTime = cvar.IntValue;
}

public void CVarChanged_HPCost(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iHPCost = cvar.IntValue;
}

public void CVarChanged_HPMax(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iHPMax = cvar.IntValue;
}

public void CVarChanged_Death(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bDeath = cvar.BoolValue;
}

public void CVarChanged_HP(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iHP = cvar.IntValue;
}

public void CVarChanged_Frag(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iFrag = cvar.IntValue;
}

public void CVarChanged_Sound(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	cvar.GetString(sCvarPath, sizeof(sCvarPath));

	int len = strlen(sCvarPath) - 4;
	if(len < 1 || strcmp(sCvarPath[len], ".mp3", false) && strcmp(sCvarPath[len], ".wav", false))
		sCvarPath[0] = sSound[0] = 0;
	else AddSound();
}

public void CVarChanged_RIP(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iRIP = cvar.IntValue;
}

public void CVarChanged_Balance(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iBalance = cvar.IntValue;
}

public void CVarChanged_NoDmgTime(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	fNoDmgTime = cvar.FloatValue;
}

public void CVarChanged_ColorT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, M_T);
	if(!bEnemy) for(int i = 1; i <= MaxClients; i++) if(IsMarkExist(i) && GetClientTeam(i) == CS_TEAM_T) SetMarkColor(i);
}

public void CVarChanged_ColorCT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, M_CT);
	if(!bEnemy) for(int i = 1; i <= MaxClients; i++) if(IsMarkExist(i) && GetClientTeam(i) == CS_TEAM_CT) SetMarkColor(i);
}

public void CVarChanged_ColorAny(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, M_Any);
	if(bEnemy) for(int i = 1; i <= MaxClients; i++) if(IsMarkExist(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		SetMarkColor(i);
}

stock void SetColor(ConVar cvar, int type)
{
	char clr[8];
	cvar.GetString(clr, sizeof(clr));
	clr[7] = 0;	// чтобы проверялось максимум 7 первых символов

	int i;
	while(clr[i])
	{
		if(!(clr[i] >= '0' && clr[i] <= '9') && !(clr[i] >= 'A' && clr[i] <= 'F') && !(clr[i] >= 'a' && clr[i] <= 'f'))
		{	// не HEX-число
			iColor[type] = COLOR[type];
			LogError("HEX color '%s' isn't valid!\nHUD color is 0x%x (%d %d %d)!\n", clr, iColor[type], (iColor[type] & 0xFF0000) >> 16, (iColor[type] & 0xFF00) >> 8, iColor[type] & 0xFF);
			return;
		}
		i++;
	}

	clr[6] = 0;
	if(i == 3)	// короткая форма => полная форма
	{
		clr[4] = clr[5] = clr[2];
		clr[2] = clr[3] = clr[1];
		clr[1] = clr[0];
		i = 6;
	}

	if(i != 6) iColor[type] = COLOR[type];	// невалидный цвет
	else StringToIntEx(clr, iColor[type] , 16);
}

public void CVarChanged_Best(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iRevives[0][0] = cvar.IntValue;
}

public void CVarChanged_Worst(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iRevives[0][1] = cvar.IntValue;
}

public void CVarChanged_MarkT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	PrepareMark(cvar, M_T);
}

public void CVarChanged_MarkCT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	PrepareMark(cvar, M_CT);
}

public void CVarChanged_MarkAny(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	PrepareMark(cvar, M_Any);
}

stock void PrepareMark(ConVar cvar, const int type)
{
	cvar.GetString(sMark[type], sizeof(sMark[]));
	int len = strlen(sMark[type]) - 4;
	if((bDefault[type] = len < 1 || strcmp(sMark[type][len], ".vmt", false)))
	{
		FormatEx(sMark[type], sizeof(sMark[]), "%s.vmt", iEngine == E_Old ? MARK_V34 : MARK_CSS);
		return;
	}

	if(StrContains(sMark[type], "materials/", false)) Format(sMark[type], sizeof(sMark[]), "materials/%s", sMark[type]);

	PrecacheMark(sMark[type]);
}

stock void PrecacheMark(const char[] path)
{
	char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), path);
	ReplaceString(buffer, sizeof(buffer), ".vmt", ".vtf");
	AddFileToDownloadsTable(buffer);
	AddFileToDownloadsTable(path);
	PrecacheModel(path, true);
}

stock void UpdateTimer()
{
	if(hTimer) delete hTimer;
	if(bEnable) hTimer = CreateTimer(UPDATE, Timer_UpdateHUD, _, TIMER_REPEAT);
}

public void CVarChanged_HUDPosX(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosX = cvar.FloatValue;
}

public void CVarChanged_HUDPosY(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosY = cvar.FloatValue;
}

public void CVarChanged_HUDColor(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, M_HUD);
}

public void CVarChanged_HUDMode(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iHUD[0] = cvar.IntValue;
}

public void OnMapStart()
{
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if(gameConfig == null) LogError("Unable to load game config funcommands.games");
	else
	{
		char buffer[PLATFORM_MAX_PATH];
		if(GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
			hBeam = PrecacheModel(buffer);
		if(GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
			hHalo = PrecacheModel(buffer);

		bSprites = hBeam != -1 && hHalo != -1;
		if(!bSprites)
			LogError("Can't find config for %s%s%s!", hBeam == -1 ? "SpriteBeam" : "", hBeam == hHalo ? " and " : "", hHalo == -1 ? "SpriteHalo" : "");
	}
	CloseHandle(gameConfig);

	if(!bDefault[M_T])		PrecacheMark(sMark[M_T]);
	if(!bDefault[M_CT])		PrecacheMark(sMark[M_CT]);
	if(!bDefault[M_Any])	PrecacheMark(sMark[M_Any]);

	if(sCvarPath[0]) AddSound();

	if(bEnable) hTimer = CreateTimer(UPDATE, Timer_UpdateHUD, _, TIMER_REPEAT);
}

stock void AddSound()
{
	FormatEx(sSound, sizeof(sSound), "sound/%s", sCvarPath);
	AddFileToDownloadsTable(sSound);

	if(iEngine == E_CSGO)
	{
		FormatEx(sSound, sizeof(sSound), "*%s", sCvarPath);
		AddToStringTable(FindStringTable("soundprecache"), sSound);
		return;
	}

	FormatEx(sSound, sizeof(sSound), "%s", sCvarPath);
	PrecacheSound(sSound, true);
}

public Action Timer_UpdateHUD(Handle timer)
{
	if(iEngine != E_Old)
		SetHudTextParams(fPosX, fPosY, UPDATE + 0.1, ((iColor[M_HUD] & 0xFF0000) >> 16), ((iColor[M_HUD] & 0xFF00) >> 8), (iColor[M_HUD] & 0xFF), 255, 0, 0.0, 0.1, 0.1);

	for(int i = 1; i <= MaxClients; i++) if(IsPlayerValid(i)) UpdateHUD(i, false);

	return Plugin_Continue;
}

static void UpdateHUD(const int client, const bool set = true)
{
	if(iEngine == E_Old || !iHUD[client]) return;

	static int om, target;
	if(!IsClientObserver(client))
		target = client;
	else if(((om = GetEntProp(client, Prop_Send, "m_iObserverMode")) != S_1ST && om != S_3RD)
	|| (target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")) < 1 || target > MaxClients
	|| !IsPlayerValid(target))
		return;

	SetGlobalTransTarget(client);
	static char txt[256];
	txt[0] = 0;

	if(iTimes) FormatEx(txt, sizeof(txt), "%t\n", "HUDCounter", iTimes - iTimesRevived[target], iTimes);

	if(iBalance != -1 && (iTeam[target] == CS_TEAM_CT ? iDiff : -iDiff) >= iBalance)
		Format(txt, sizeof(txt), "%s%t", txt, iTeam[target] == 2 ? "HUDBalanceT" : "HUDBalanceCt");
	else if(iTarget[target])
	{
		if(!IsClientInGame(iTarget[target])) iTarget[target] = 0;
		else Format(txt, sizeof(txt), "%s%t", txt, "HUDProgress", iTarget[target], iPercents[target]);
	}
	else if(iTimes) txt[(strlen(txt)-1)] = 0;

	if(txt[0] && client != target) Format(txt, sizeof(txt), "%N\n%s", target, txt);

	if(iHUD[client] == 2)
	{
		if(sKeyHintText[client][0]) Format(txt, sizeof(txt), "%s\n\n%s", txt, sKeyHintText[client]);

		Handle msg = StartMessageOne("KeyHintText", client, USERMSG_BLOCKHOOKS);
		if(!bProto)
		{
			BfWriteByte(msg, 1);
			BfWriteString(msg, txt);
		}
		else PbAddString(msg, "hints", txt);
		EndMessage();
	}
	else
	{
		if(set) SetHudTextParams(fPosX, fPosY, UPDATE + 0.1, ((iColor[M_HUD] & 0xFF0000) >> 16), ((iColor[M_HUD] & 0xFF00) >> 8), (iColor[M_HUD] & 0xFF), 255, 0, 0.0, 0.1, 0.1);
		ShowSyncHudText(client, hHUD, txt);
	}
}

public Action HookKeyHintText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if(IsFakeClient(players[0]) || iHUD[players[0]] != 2) return Plugin_Continue;

	if(!bProto)
	{
		BfReadByte(msg);
		BfReadString(msg, sKeyHintText[players[0]], sizeof(sKeyHintText[]));
	}
//	else PbReadString(msg, "hints", sKeyHintText[players[0]], sizeof(sKeyHintText[]));
	RequestFrame(RequestFrame_Callback, players[0]);

	if(hTimerClear[players[0]]) delete hTimerClear[players[0]];
	if(sKeyHintText[players[0]][0]) hTimerClear[players[0]] = CreateTimer(UPDATE, Timer_ClearBuffer, GetClientUserId(players[0]), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public Action Timer_ClearBuffer(Handle timer, int client)
{
	if((client = GetClientOfUserId(client))) sKeyHintText[client][0] = 0;
	timer = null;
}

public void RequestFrame_Callback(int client)
{
	UpdateHUD(client);
}

public void OnClientConnected(int client)
{
	iTimesRevived[client] = iTarget[client] = iReviver[client] = sKeyHintText[client][0] = 0;

	if(client && !IsFakeClient(client))
	{
		if(!AreClientCookiesCached(client))
		{
			iKey[client] = iKey[0];
			bBar[client] = bBar[0];
			iHUD[client] = iHUD[0];
		}
		else GetCookieValue(client);
	}
}

public void Cookie_Revive(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_DisplayOption)
		FormatEx(buffer, maxlen, "%T", "MenuTitle", client);
	else if(action == CookieMenuAction_SelectOption)
		SendMenu(client);
}

public Action Cmd_Menu(int client, int args)
{
	if(client) SendMenu(client);
	return Plugin_Handled;
}

stock void SendMenu(int client)
{
	if(!hMenu)
	{
		hMenu = new Menu(Menu_Revival, MENU_ACTIONS_ALL);
		hMenu.SetTitle("[Revival] settings\n \n  Key for revive:");
		hMenu.AddItem("", "Ctrl  (+duck)");
		hMenu.AddItem("", "E     (+use)");
		hMenu.AddItem("", "Shift (+speed)");
		hMenu.AddItem("", "none  (auto revive)\n \n  Show info in the:");
		hMenu.AddItem("", "show only chat messages)");
		hMenu.AddItem("", "HUD");
		hMenu.AddItem("", "KeyHint\n ");
		hMenu.AddItem("", "Progressbar");
		hMenu.Pagination = 0;
		hMenu.ExitButton = true;
	}
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Revival(Menu menu, MenuAction action, int client, int param)
{
	static char buffer[128];
	SetGlobalTransTarget(client);
	switch(action)
	{
		case MenuAction_Display:
			menu.SetTitle("%t\n \n  %t:", "MenuTitle", "MenuKeysHint");
		case MenuAction_DisplayItem:
		{
			switch(param)
			{
				case 0: FormatEx(buffer, sizeof(buffer), "%t %s", "MenuKeyDuck", iKey[client] == 0 ? "☑" : "");
				case 1: FormatEx(buffer, sizeof(buffer), "%t %s", "MenuKeyUse", iKey[client] == 1 ? "☑" : "");
				case 2: FormatEx(buffer, sizeof(buffer), "%t %s", "MenuKeySpeed", iKey[client] == 2 ? "☑" : "");
				case 3: FormatEx(buffer, sizeof(buffer), "%t %s\n \n  %t:", "MenuKeyNone", iKey[client] == 3 ? "☑" : "", "MenuInfoHint");
				case 4: FormatEx(buffer, sizeof(buffer), "%t %s", "MenuInfoNone", iHUD[client] == 0 ? "☑" : "");
				case 5: FormatEx(buffer, sizeof(buffer), "%t %s", "MenuInfoHUD", iHUD[client] == 1 ? "☑" : "");
				case 6: FormatEx(buffer, sizeof(buffer), "%t %s\n ", "MenuInfoKeyHint", iHUD[client] == 2 ? "☑" : "");
				case 7: FormatEx(buffer, sizeof(buffer), "%t %s", "MenuProgressbar", bBar[client] ? "☑" : "☐");
			}
			return RedrawMenuItem(buffer);
		}
		case MenuAction_DrawItem:
			return param < 4 && iKey[client] == param || param > 3 && iHUD[client] == (param - 4) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
		case MenuAction_Select:
		{
			int val;
			if(param == 7)
			{
				bBar[client] = !bBar[client];
			}
			else if(param < 4)
			{
				iKey[client] = param;
			}
			else
			{
				iHUD[client] = param - 4;
			}
			val = iKey[client] | view_as<int>(bBar[client]) << 3 | (iHUD[client] << 7);
			FormatEx(buffer, sizeof(buffer), "0x%04x", val);
			SetClientCookie(client, hCookies, buffer);

			SendMenu(client);
		}
		case MenuAction_Cancel: if(param == MenuCancel_Exit) ShowCookieMenu(client);
	}
	return 0;
}

public void OnClientCookiesCached(int client)
{
	if(client && !IsFakeClient(client)) GetCookieValue(client);
}

stock void GetCookieValue(int client)
{
	static char buffer[4];
	GetClientCookie(client, hCookies, buffer, sizeof(buffer));
	if(buffer[0] != '0' || buffer[1] != 'x' || strlen(buffer) != 4) return;

	int val = StringToInt(buffer, 0x10);

	iKey[client] = val & 7;	// 0000 0111
	if(iKey[client] > 3) iKey[client] = iKey[0];

	bBar[client] = !!(val & 8);	// 0000 1000

	iHUD[client] = val >> 7;
	if(iHUD[client] > 2) iHUD[client] = iHUD[0];
}

public void OnClientDisconnect(int client)
{
	if(hTimerClear[client]) delete hTimerClear[client];
	CountAlive();
	RemoveMark(client);
	iDeathTeam[client] = sKeyHintText[client][0] = 0;
	iTeam[client] = CS_TEAM_NONE;
	bProtected[client] = false;
	for(int i = 1; i <= MaxClients; i++) if(i != client && iTarget[i] == client) iTarget[i] = 0;
}

public void Event_Team(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if(!(client = GetClientOfUserId(event.GetInt("userid")))) return;

	sKeyHintText[client][0] = 0;
	if(((iTeam[client] = event.GetInt("team")) < CS_TEAM_T) || (!bTeam && iTeam[client] != iDeathTeam[client]))
	{
		ResetRespawnData(client);
		iDeathTeam[client] = 0;
		ResetPercents(client);
	}
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if(!(client = GetClientOfUserId(event.GetInt("userid"))) || (iDeathTeam[client] = GetClientTeam(client)) < 2)
		return;

	sKeyHintText[client][0] = 0;
	CountAlive();
	if(!bEnable || !bAllowed || iRIP & 1 && event.GetBool("headshot"))
		return;

	if(iRIP & 2)
	{
		static char weapon[8];
		event.GetString("weapon", weapon, sizeof(weapon));
		if(!strcmp(weapon, "knife"))
			return;
	}

	bProtected[client] = false;
	CreateMark(client);

	if(iTime) CreateTimer(iTime+0.0, Timer_DisableReviving, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	if(iClean < 0) return;
	static int iOffsetRagdoll = -1;
	if((iOffsetRagdoll != -1 || (iOffsetRagdoll = FindSendPropInfo("CCSPlayer", "m_hRagdoll")) != -1)
	&& (client = GetEntDataEnt2(client, iOffsetRagdoll)) != -1 && IsValidEntity(client))
		CreateTimer(iClean+0.0, Timer_RemoveBody, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RemoveBody(Handle timer, any ent)
{
	if((ent = EntRefToEntIndex(ent)) != -1) AcceptEntityInput(ent, "Kill");
}

public Action Timer_DisableReviving(Handle timer, any client)
{
	if(!(client = GetClientOfUserId(client)))
		return;

	RemoveMark(client);
	ResetPercents(client);
	iDeathTeam[client] = 0;
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if(!bEnable || !(client = GetClientOfUserId(event.GetInt("userid")))) return;

	RemoveMark(client);
	ResetPercents(client);
	iDeathTeam[client] = iTarget[client] = iReviver[client] = 0;
	iTeam[client] = GetClientTeam(client);
	CountAlive();
}

stock void CountAlive()
{
	static int i;
	iDiff = 0;
	for(i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && (iTeam[i] = GetClientTeam(i)) > CS_TEAM_SPECTATOR && IsPlayerAlive(i))
			iDiff += (iTeam[i] == CS_TEAM_CT) ? 1 : -1;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int i;
	if(bAllowed) for(i = 1; i <= MaxClients; i++) ResetRespawnData(i, true);
	CountAlive();
	bAllowed = true;
	if(bEnable && bTip)
	{
		for(i = 1; i <= MaxClients; i++) if(IsClientValid(i))
		{
			if(iKey[i] < 3) PrintToChatClr(i, "%t%t", "ChatTag", "KeyTip", KEY_NAME[iKey[i]]);
			else PrintToChatClr(i, "%t%t", "ChatTag", "NoKeyTip");
		}
	}
	for(i = 1; i <= MaxClients; i++)
	{
		iRevives[i][0] = iRevives[i][1] = iTarget[i] = sKeyHintText[i][0] = 0;
		bProtected[i] = false;
	}
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	bAllowed = false;
	ShowTop();
	ShowAntiTop();
	for(int i = 1; i <= MaxClients; i++) ResetRespawnData(i, true);
	return Plugin_Continue;
}

stock void ShowTop()
{
	if(!iRevives[0][0]) return;

	static int i, j, num, max, lst, place, prc, clients[MAXPLAYERS+1], list[MAXPLAYERS+1][2];
	max = lst = place = 0;

	for(i = 1, num = 0; i <= MaxClients; i++) if(IsPlayerValid(i) && iRevives[i][0])
	{
		clients[num++] = i;
		if(max < iRevives[i][0])
		{
			lst	= i;
			max = iRevives[i][0];
		}
	}
	if(!num) return;

	for(i = 0; i < num && place < iRevives[0][0];)
	{
		place++;
		if(place > 1) for(j = 0, prc = 0; j < num; j++) if(iRevives[clients[j]][0] < max && iRevives[clients[j]][0] > prc)
		{
			lst	= clients[j];
			prc	= iRevives[clients[j]][0];
		}
		list[i][0] = place;	// место
		list[i][1] = lst;	// id
		max = iRevives[lst][0];
		i++;

		for(j = 0; j < num && i < num; j++) if(clients[j] != lst && iRevives[clients[j]][0] == max)
		{
			list[i][0] = place;
			list[i][1] = clients[j];
			i++;
		}
	}

	num = i;
	PrintToChatAllClr("%t", "ChatBestTitle", iRevives[0][0]);
	for(i = 0; i < num; i++) PrintToChatAllClr("%t", "ChatBestRow", list[i][0], list[i][1], iRevives[list[i][1]][0], iRevives[list[i][1]][1]);
}

stock void ShowAntiTop()
{
	if(!iRevives[0][1]) return;

	static int i, j, num, min, lst, place, prc, clients[MAXPLAYERS+1], list[MAXPLAYERS+1][2];
	lst = place = 0;
	min = 2000000000;

	for(i = 1, num = 0; i <= MaxClients; i++)
		if(IsPlayerValid(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR && !iRevives[i][0])
		{
			clients[num++] = i;
			if(min > iRevives[i][1])
			{
				lst	= i;
				min = iRevives[i][1];
			}
		}
	if(!num) return;

	for(i = 0; i < num && place < iRevives[0][1];)
	{
		place++;
		if(place > 1) for(j = 0, prc = 0; j < num; j++) if(iRevives[clients[j]][1] > min && iRevives[clients[j]][1] < prc)
		{
			lst	= clients[j];
			prc	= iRevives[clients[j]][1];
		}
		list[i][0] = place;	// место
		list[i][1] = lst;	// id
		min = iRevives[lst][1];
		i++;

		for(j = 0; j < num && i < num; j++) if(clients[j] != lst && iRevives[clients[j]][1] == min)
		{
			list[i][0] = place;
			list[i][1] = clients[j];
			i++;
		}
	}

	num = i;
	PrintToChatAllClr("%t", "ChatWorstTitle");
	for(i = 0; i < num; i++) PrintToChatAllClr("%t", "ChatWorstRow", list[i][0], list[i][1], iRevives[list[i][1]][1]);
}

stock void SendWarnNotEnough(int client, bool &val)
{
	if(!bMsg || val) return;

	val = true;
	PrintToChatClr(client, "%t%t", "ChatTag", "NotEnoughHP");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	static bool reset[MAXPLAYERS+1], cant, prev[MAXPLAYERS+1], warned[MAXPLAYERS+1];
	static int old_target[MAXPLAYERS+1], diff, target[MAXPLAYERS+1], old_buttons[MAXPLAYERS+1], iOffsetVel_0 = -1, iOffsetVel_1 = -1, iOffsetVel_2 = -1, health, perc;
	static float start[MAXPLAYERS+1], time, effect_time[MAXPLAYERS+1], pos[3];
	static char name[MAX_NAME_LENGTH];

	if(bProtected[client])
	{
		cant = false;
		if(buttons & IN_ATTACK)
		{
			buttons &= ~IN_ATTACK;
			cant = true;
		}
		if(buttons & IN_ATTACK2)
		{
			buttons &= ~IN_ATTACK2;
			cant = true;
		}
/*		if(buttons & IN_FORWARD)
		{
			buttons &= ~IN_FORWARD;
			cant = true;
		}
*/		return cant ? Plugin_Changed : Plugin_Continue;
	}

	if(!bEnable || !bAllowed || !IsPlayerValid(client) || (iTimes && iTimesRevived[client] >= iTimes))
		return Plugin_Continue;

	time = GetGameTime();
	if(iBalance != -1 && iTeam[client] > CS_TEAM_SPECTATOR && (iKey[client] == 3 || buttons & KEY_VAL[iKey[client]])
	&& ((iTeam[client] == CS_TEAM_CT ? iDiff : -iDiff) >= iBalance))
	{
		if(old_target[client])
		{
			SaveProgress(client, old_target[client], start[client], time);
			perc = RoundToNearest(fProgress[client][old_target[client]]);
			SaveStats(client, perc, false);
			perc *= 100;
			if(iPercents[client] != perc)
			{
				iPercents[client] = perc;
				UpdateHUD(client);
			}
			SendProgressBar(client, old_target[client]);
			old_target[client] = 0;
		}
		if(!hTimer && !warned[client])
		{
			PrintToChatClr(client, "%t%t", "ChatTag", "ChatUnbalanced");
			warned[client] = true;
		}
		old_buttons[client] = buttons;
		return Plugin_Continue;
	}

	if(!reset[client] && (!IsPlayerAlive(client) || GetClientTeam(client) < CS_TEAM_T))
	{
		UpdateHUD(client);
		if(!IsPlayerAlive(client)) SaveStats(client, RoundToNearest(fProgress[client][old_target[client]]), false);
		reset[client] = true;
		fProgress[client] = NULL_PERCENT;
		iPercents[client] = 0;
		UpdateHUD(client);
		SendProgressBar(client, old_target[client]);
		if(old_target[client]) old_target[client] = 0;
		return Plugin_Continue;
	}

	cant = iHPCost && (diff = (health = GetClientHealth(client)) - iHPCost) < 1 && !bDeath;
	if((iKey[client] == 3 || buttons & KEY_VAL[iKey[client]] && !(old_buttons[client] & KEY_VAL[iKey[client]])) && cant && !old_target[client])
	{
		perc = RoundToNearest(fProgress[client][old_target[client]]);
		SaveStats(client, perc, false);
		perc *= 100;
		if(iPercents[client] != perc)
		{
			iPercents[client] = perc;
			UpdateHUD(client);
		}
		SendWarnNotEnough(client, prev[client]);
		old_buttons[client] = buttons;
		return Plugin_Continue;
	}

	if(old_target[client] && (!IsClientInGame(old_target[client]) || IsPlayerAlive(old_target[client]) || cant))
	{
		SaveStats(client, RoundToNearest(fProgress[client][old_target[client]]), false);
		fProgress[client][old_target[client]] = 0.0;
		old_target[client] = iPercents[client] = 0;
		UpdateHUD(client);
		SendProgressBar(client);
		if(cant)
		{
			SendWarnNotEnough(client, prev[client]);
			return Plugin_Continue;
		}
	}
	prev[client] = cant;

	if((iKey[client] == 3 || buttons & KEY_VAL[iKey[client]]) && GetEntityFlags(client) & FL_ONGROUND)
	{
		warned[client] = false;
		if(!old_target[client] || !iDeathTeam[old_target[client]])
			target[client] = GetNearestTarget(client);
		else if((iOffsetVel_0 != -1 || (iOffsetVel_0 = FindSendPropInfo("CCSPlayer", "m_vecVelocity[0]")) != -1)
		&& GetEntDataFloat(client, iOffsetVel_0)
		|| (iOffsetVel_1 != -1 || (iOffsetVel_1	= FindSendPropInfo("CCSPlayer", "m_vecVelocity[1]")) != -1)
		&& GetEntDataFloat(client, iOffsetVel_1)
		|| (iOffsetVel_2 != -1 || (iOffsetVel_2	= FindSendPropInfo("CCSPlayer", "m_vecVelocity[2]")) != -1)
		&& GetEntDataFloat(client, iOffsetVel_2))
		{
			GetClientAbsOrigin(client, pos);
			if(FloatCompare(fRadius, GetVectorDistance(pos, fDeathPos[old_target[client]])) == -1)
				target[client] = GetNearestTarget(client);
		}
		else target[client] = old_target[client];

#if SOURCEMOD_V_MINOR < 10
		if(FloatCompare(FloatSub(time, effect_time[client]), EFF_LIFE) != -1 || target[client] != old_target[client])
#else
		if(FloatCompare((time - effect_time[client]), EFF_LIFE) != -1 || target[client] != old_target[client])
#endif
		{
			effect_time[client] = time;
			CreateEffect(client, target[client]);
		}

		if(target[client] && IsClientConnected(target[client]))
		{
			if(iHPCost < 0 && iHPMax)
			{
				if(health > iHPMax) diff = health;
				else if(diff > iHPMax) diff = iHPMax;
			}

			reset[client] = false;
			if(target[client] != old_target[client])
			{
				SaveProgress(client, old_target[client], start[client], time);
#if SOURCEMOD_V_MINOR < 10
				start[client] = FloatSub(time, fProgress[client][target[client]]);
#else
				start[client] = time - fProgress[client][target[client]];
#endif
				old_target[client] = target[client];

				SendProgressBar(client, target[client], start[client]);

				if(bMsg)
				{
					if(iTarget[client] != target[client])
					{
						GetClientName(target[client], name, sizeof(name));
						if(!hTimer) PrintToChatClr(client, "%t%t", "ChatTag", "YouReviving", name);
						if(iReviver[target[client]] != client)
						{
							GetClientName(client, name, sizeof(name));
							PrintToChatClr(target[client], "%t%t", "ChatTag", "YouRevivingBy", name);
						}
					}

					if(iHPCost)
					{
						if(diff < 1) PrintToChatClr(client, "%t", "ReviveCostDeath");
						else if(health != diff) PrintToChatClr(client, "%t", "ReviveCostHealth", diff);
					}
				}
				iReviver[target[client]] = client;
				iTarget[client] = target[client];
			}

#if SOURCEMOD_V_MINOR < 10
			perc = RoundToNearest((FloatSub(time, start[client])/iCD)*100);
#else
			perc = RoundToNearest(((time - start[client])/iCD)*100);
#endif
			if(perc >= 100) InitRespawn(client, target[client], diff);
			else if(iPercents[client] != perc)
			{
				iPercents[client] = perc;
				UpdateHUD(client);
			}
		}
		else if(old_target[client])
		{
			SaveProgress(client, old_target[client], start[client], time);
			SendProgressBar(client, old_target[client]);
			old_target[client] = 0;
			UpdateHUD(client);
		}
	}
	else if(iKey[client] != 3 && old_buttons[client] & KEY_VAL[iKey[client]] && old_target[client])
	{
		reset[client] = true;
		SaveProgress(client, old_target[client], start[client], time);
		SendProgressBar(client, old_target[client]);
#if SOURCEMOD_V_MINOR < 10
		perc = RoundToNearest((FloatSub(time, start[client])/iCD)*100);
#else
		perc = RoundToNearest(((time - start[client])/iCD)*100);
#endif
		if(iPercents[client] != perc)
		{
			iPercents[client] = perc;
			UpdateHUD(client);
		}
		if(bMsg)
		{
			GetClientName(old_target[client], name, sizeof(name));
			PrintToChatClr(client, "%t%t", "ChatTag", "RevivingStopped", name, iPercents[client]);
		}
		old_target[client] = 0;
	}
	old_buttons[client] = buttons;
	return Plugin_Continue;
}

stock void SaveStats(int client, int val = 100, bool success = true)
{
	if(success) iRevives[client][0]++;
	iRevives[client][1] += val;
}

stock void UpdateStatus(int client, int val)
{
	iPercents[client] = val;
}

stock void CreateMark(int client)
{
	iTeam[client] = GetClientTeam(client);

	GetClientAbsOrigin(client, fDeathPos[client]);
	fDeathPos[client][2] -= 40;
	GetClientAbsAngles(client, fDeathAng[client]);

	static int ent, type;
	if((ent = GetMarkId(client)) != -1) AcceptEntityInput(ent, "Kill");

	if((ent = CreateEntityByName("env_sprite")) == -1) return;

	type = bEnemy ? M_Any : iTeam[client] == CS_TEAM_T ? M_T : M_CT;
	DispatchKeyValue(ent, "model", sMark[type]);
	DispatchKeyValue(ent, "classname", "death_mark");
	DispatchKeyValue(ent, "spawnflags", "1");
	DispatchKeyValueFloat(ent, "scale", MARK_SIZE);
	DispatchKeyValue(ent, "rendermode", "5");
	DispatchSpawn(ent);

	iMarkRef[client] = EntIndexToEntRef(ent);
	SetMarkColor(client);
	TeleportEntity(ent, fDeathPos[client], NULL_VECTOR, NULL_VECTOR);
}

stock void SetMarkColor(const int client)
{
	static int type;
	type = bEnemy ? M_Any : iTeam[client] == CS_TEAM_T ? M_T : M_CT;

	SetVariantInt(((iColor[type] & 0xFF0000) >> 16));
	AcceptEntityInput(iMarkRef[client], "ColorRedValue");
	SetVariantInt(((iColor[type] & 0xFF00) >> 8));
	AcceptEntityInput(iMarkRef[client], "ColorGreenValue");
	SetVariantInt((iColor[type] & 0xFF));
	AcceptEntityInput(iMarkRef[client], "ColorBlueValue");
}

stock void ResetRespawnData(int client, bool round = false)
{
	SendProgressBar(client);
	fProgress[client] = NULL_PERCENT;
	iDeathTeam[client] = iTarget[client] = iReviver[client] = iPercents[client] = 0;
	if(bReset || round) iTimesRevived[client] = 0;
	RemoveMark(client);
}

static void RemoveMark(int client)
{
	static int ent;
	if((ent = GetMarkId(client)) != -1) AcceptEntityInput(ent, "Kill");
	iMarkRef[client] = -1;
}

stock void ResetPercents(int client)
{
	static int i;
	for(i = 1; i <= MaxClients; i++)
	{
		fProgress[i][client] = 0.0;
		if(iTarget[i] == client) iTarget[i] = 0;
	}
	iPercents[client] = 0;
}

stock int GetNearestTarget(int client)
{
	if(!IsPlayerAlive(client)) return 0;

	static int i, team, target;
	static float pos[3], dist[MAXPLAYERS], min_dist;
	if(!bEnemy) team = GetClientTeam(client);
	GetClientAbsOrigin(client, pos);

	for(i = 1, target = 0, min_dist = fRadius; i < MaxClients; i++)
		if(i != client && iDeathTeam[i] > 1 && (bEnemy || team == iDeathTeam[i])
		&& FloatCompare(min_dist, (dist[i] = GetVectorDistance(pos, fDeathPos[i]))) == 1)
		{
			min_dist = dist[i];
			target = i;
		}

	return target;
}

stock void SaveProgress(const int client, const int target, const float start, const float stop)
{
	if(!target) return;
#if SOURCEMOD_V_MINOR < 10
	if(bPercent) fProgress[client][target] = FloatSub(stop, start);
#else
	if(bPercent) fProgress[client][target] = stop - start;
#endif
	else fProgress[client][target] = 0.0;
}

stock Action InitRespawn(int client, int target, int hp)
{
	if(!IsPlayerAlive(client) || !IsClientValid(target, true))	// не факт что необходима
		return Plugin_Handled;

	SaveStats(client);
	RemoveMark(client);
	ResetPercents(client);
	SendProgressBar(client, target);
	iTarget[client] = iReviver[target] = 0;

	static int buffer;
	if(bEnemy && (buffer = GetClientTeam(client)) != iDeathTeam[target]) CS_SwitchTeam(target, buffer);
	CS_RespawnPlayer(target);
	if(!bPos) GetClientAbsOrigin(client, fDeathPos[target]);
	TeleportEntity(target, fDeathPos[target], fDeathAng[target], NULL_VECTOR);
	SetEntityHealth(target, iHP);
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);

	if((buffer = GetEntProp(target, Prop_Data, "m_iDeaths")) > 0) SetEntProp(target, Prop_Data, "m_iDeaths", buffer-1);
	if(iFrag) SetEntProp(client, Prop_Data, "m_iFrags", GetEntProp(client, Prop_Data, "m_iFrags")+iFrag);
	if(bMsg)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(target, name, sizeof(name));
		PrintToChatClr(client, "%t%t", "ChatTag", iFrag ? "TargetRevivedFrag" : "TargetRevived", name);
		PrintToChatClr(target, "%t%t", "ChatTag", "YouRevived", client);
	}
	if(sSound[0]) EmitAmbientSound(sSound, fDeathPos[target]);

	if(iHPCost)
	{
		if(hp > 0) SetEntityHealth(client, hp);
		else ForcePlayerSuicide(client);
	}

	if(iNoBlockTime && iOffsetGroup != -1)
	{
		SetEntData(client, iOffsetGroup, 17, 4, true);
		CreateTimer(iNoBlockTime+0.0, Timer_EnableCollision, GetClientUserId(target), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	if(fNoDmgTime > 0.01)
	{
		bProtected[target] = true;
		SetEntProp(target, Prop_Data, "m_takedamage", 0, 1);
		SetClientColor(target, RENDERFX_HOLOGRAM, RENDER_TRANSCOLOR, 63, 255, 63 , 63);
		CreateTimer(fNoDmgTime, Timer_EnableDmg, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);
	}

	UpdateHUD(client);

	iTimesRevived[client]++;

	Call_StartForward(hFwd_PlayerRevived);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(iFrag);
	Call_Finish();

	if(!iTimes) return Plugin_Handled;

	if(!bMsg && hTimer) return Plugin_Handled;

	if(iTimesRevived[client] >= iTimes) PrintToChatClr(client, "%t%t", "ChatTag", "RevivalsNotAvailable");
	else PrintToChatClr(client, "%t%t", "ChatTag", "RevivalsAvailable", iTimes - iTimesRevived[client]);

	return Plugin_Handled;
}

public Action Timer_EnableDmg(Handle timer, any client)
{
	if((client = GetClientOfUserId(client)))
	{
		bProtected[client] = false;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetClientColor(client);
	}
}

stock void SetClientColor(int client, RenderFx fx = RENDERFX_NONE, RenderMode mode = RENDER_NORMAL, int r = 255, int g = 255, int b = 255, int a = 255)
{
	SetEntityRenderFx(client, fx);
	SetEntityRenderMode(client, mode);
	SetEntityRenderColor(client, r, g, b, a);
}

public Action Timer_EnableCollision(Handle timer, any client)
{
	if((client = GetClientOfUserId(client))) SetEntData(client, iOffsetGroup, 5, 4, true);
}

stock void SendProgressBar(const int client, const int target = 0, const float time = 0.0)
{
	if(!bBar[client] && !target && !bBar[target]) return;

	static int left;
	left = time ? iCD : 0;
	SetProgressBar(client, time, left);
	SetProgressBar(target, time, left);
}

static void SetProgressBar(const int client, const float time, const int left)
{
	if(!IsClientValid(client) || !bBar[client]) return;

	static int start, duration;
	if(start < 1 && (start = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime")) < 1
	|| duration < 1 && (duration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration")) < 1)
		return;

	SetEntDataFloat(client, start, time, true);
	SetEntData(client, duration, left, true);

	if(iEngine != E_CSGO || !left) return;

	static int simulation, blocking;
	if(simulation < 1 && (simulation = FindSendPropInfo("CBaseEntity", "m_flSimulationTime")) < 1)
		return;
	if(blocking < 1 && (blocking = FindSendPropInfo("CCSPlayer", "m_iBlockingUseActionInProgress")) < 1)
		return;

	SetEntDataFloat(client, simulation, view_as<float>(left), true);
	SetEntData(client, blocking, 0, 4, true);
}

stock void CreateEffect(const int client, const int target)
{
	if(!bEffect || !bSprites) return;

	static int i, team, clients[MAXPLAYERS+1], num;
	team = GetClientTeam(client);
	if(target)
	{
		for(i = 1, num = 0; i <= MaxClients; i++)
			if(IsClientValid(i) && (bEnemy || team == GetClientTeam(i))) clients[num++] = i;
		SendBeamRing(target, team, clients, num);
	}
	else for(i = 1, num = 0, clients[0] = client; i <= MaxClients; i++) if(iDeathTeam[i] && (bEnemy || iDeathTeam[i] == team))
	{
		SendBeamRing(i, team, clients);
		num++;
	}
}

stock void SendBeamRing(const int target, int team, int[] clients, int num = 0)
{
	TE_Start("BeamRingPoint");
	TE_WriteVector("m_vecCenter", fDeathPos[target]);
	TE_WriteFloat("m_flStartRadius", fRadius);
	TE_WriteFloat("m_flEndRadius", fRadius+0.1);
	TE_WriteNum("m_nModelIndex", hBeam);
	TE_WriteNum("m_nHaloIndex", hHalo);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 15);
	TE_WriteFloat("m_fLife", EFF_LIFE);
	TE_WriteFloat("m_fWidth", 3.0);
	TE_WriteFloat("m_fEndWidth", 3.0);
	TE_WriteFloat("m_fAmplitude", 0.0);
	static int type;
	type = bEnemy ? M_Any : team == 2 ? M_T : M_CT;
	TE_WriteNum("r", ((iColor[type] & 0xFF0000) >> 16));
	TE_WriteNum("g", ((iColor[type] & 0xFF00) >> 8));
	TE_WriteNum("b", (iColor[type] & 0xFF));
	TE_WriteNum("a", 191);
	TE_WriteNum("m_nSpeed", 1);
	TE_WriteNum("m_nFlags", 0);
	TE_WriteNum("m_nFadeLength", 0);

	TE_Send(clients, num);
}

stock void PrintToChatAllClr(const char[] msg, any ...)
{
	static char buffer[PLATFORM_MAX_PATH];
	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i))
	{
		VFormat(buffer, sizeof(buffer), msg, 2);
		PrintToChatClr(i, "%s", buffer);
	}
}

stock void PrintToChatClr(int client, const char[] msg, any ...)
{
	if(!IsClientValid(client)) return;

	Handle hBuffer = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(!hBuffer) return;

	SetGlobalTransTarget(client);
	static char buffer[PLATFORM_MAX_PATH], new_msg[PLATFORM_MAX_PATH];
	if(iEngine != E_Unknown) FormatEx(buffer, sizeof(buffer), "%s\x01%s", iEngine == E_CSGO ? " " : "", msg);
	VFormat(new_msg, sizeof(new_msg), buffer, 3);

	if(iEngine) for(int i; i < 16; i++) ReplaceString(new_msg, sizeof(new_msg), CLR[i][0], CLR[i][iEngine]);
	else for(int i; i < 16; i++) ReplaceString(new_msg, sizeof(new_msg), CLR[i][0], "");

	if(bProto)
	{
		PbSetInt(hBuffer, "ent_idx", 0);
		PbSetBool(hBuffer, "chat", true);
		PbSetString(hBuffer, "msg_name", new_msg);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	}
	else
	{
		BfWriteByte(hBuffer, 0);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, new_msg);
	}
	EndMessage();
}

stock bool IsClientValid(int client, bool allow_bots = false)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && (allow_bots || !IsFakeClient(client));
}

stock bool IsPlayerValid(int client)
{
	return IsClientInGame(client) && !IsFakeClient(client);
}

stock bool IsMarkExist(int client)
{
	return iMarkRef[client] != -1 && GetMarkId(client) != -1;
}

stock int GetMarkId(int client)
{
	return EntRefToEntIndex(iMarkRef[client]);
}