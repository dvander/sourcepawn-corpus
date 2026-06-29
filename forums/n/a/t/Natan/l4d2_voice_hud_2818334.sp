#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <basecomm>
#include <sdktools>

#define HUD_LEFT_TOP			0
#define HUD_LEFT_BOT			1
#define HUD_MID_TOP				2
#define HUD_MID_BOT				3
#define HUD_RIGHT_TOP			4
#define HUD_RIGHT_BOT			5
#define HUD_TICKER				6
#define HUD_FAR_LEFT			7
#define HUD_FAR_RIGHT			8
#define HUD_MID_BOX				9
#define HUD_SCORE_TITLE			10
#define HUD_SCORE_1				11
#define HUD_SCORE_2				12
#define HUD_SCORE_3				13
#define HUD_SCORE_4				14

#define HUD_FLAG_NONE			0		 // no flag
#define HUD_FLAG_PRESTR			1		 // do you want a string/value pair to start(pre) with the string (default is PRE)
#define HUD_FLAG_POSTSTR		2		 // do you want a string/value pair to end(post) with the string
#define HUD_FLAG_BEEP			4		 // Makes a countdown timer blink
#define HUD_FLAG_BLINK			8		 // do you want this field to be blinking
#define HUD_FLAG_AS_TIME		16		 // ?
#define HUD_FLAG_COUNTDOWN_WARN 32		 // auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG			64		 // dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER	128		 // by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT		256		 // Left justify this text
#define HUD_FLAG_ALIGN_CENTER	512		 // Center justify this text
#define HUD_FLAG_ALIGN_RIGHT	768		 // Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS 1024	 // only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED	2048	 // only show to the special infected team
#define HUD_FLAG_TEAM_MASK		3072	 // ?
#define HUD_FLAG_UNKNOWN1		4096	 // ?
#define HUD_FLAG_TEXT			8192	 // ?
#define HUD_FLAG_NOTVISIBLE		16384	 // if you want to keep the slot data but keep it from displaying

#define HUD_TEAM_ALL			0
#define HUD_TEAM_SURVIVOR		1
#define HUD_TEAM_INFECTED		2

#define HUD_TEXT_ALIGN_LEFT		1
#define HUD_TEXT_ALIGN_CENTER	2
#define HUD_TEXT_ALIGN_RIGHT	3

#define HUD_X_LEFT_TO_RIGHT		0
#define HUD_X_RIGHT_TO_LEFT		1

#define HUD_Y_TOP_TO_BOTTOM		0
#define HUD_Y_BOTTOM_TO_TOP		1

#define MAX_ROWS_IN_CELL		5
#define MAX_ROWS_PER_TEAM		10
#define MAX_ROW_LENGTH			23
#define MAX_CELL_LENGTH			128

#define TEAM_SPECTATORS			1
#define TEAM_SURVIVORS			2
#define TEAM_INFECTED			3

#define HUD_LEFT_POS_X			0.49
// #define HUD_LEFT_POS_Y		0.83
#define HUD_LEFT_POS_Y			0.828
#define HUD_LEFT_WIDTH			0.2
#define HUD_LEFT_HEIGHT			0.211

#define HUD_RIGHT_POS_X			0.71
// #define HUD_RIGHT_POS_Y		0.83
#define HUD_RIGHT_POS_Y			0.828
#define HUD_RIGHT_WIDTH			0.2
#define HUD_RIGHT_HEIGHT		0.211

#define PLUGIN_VERSION			"1.0"

public Plugin myinfo =
{
	name		= "[L4D 1/2] Voice hud convinient way",
	author		= "glhf3000",
	description = "Up to 10 players speaking not overlapping any game UI or FOV",
	version		= PLUGIN_VERSION,
	url			= ""


}

bool   g_bIsSpeaking[MAXPLAYERS + 1];
int	   g_iAlltalk;

ConVar g_cvAlltalk;

public void OnPluginStart()
{
	g_cvAlltalk = FindConVar("sv_alltalk");
	g_iAlltalk	= g_cvAlltalk.IntValue;

	HookConVarChange(g_cvAlltalk, AlltalkChanged);

	CreateConVar("l4d2_voice_hud_version", PLUGIN_VERSION, "Up to 10 players speaking not overlapping any game UI or FOV", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	CreateTimer(0.1, UpdateSpeaking, _, TIMER_REPEAT);
}

public Action UpdateSpeaking(Handle timer)
{
	int	 hud_surv_primary	= HUD_SCORE_1;
	int	 hud_surv_secondary = HUD_SCORE_2;
	int	 hud_inf_primary	= HUD_SCORE_3;
	int	 hud_inf_secondary	= HUD_SCORE_4;

	char rowFormat[]		= "%s %s\n";
	char name[MAX_ROW_LENGTH];
	char buffer_surv_primary[MAX_CELL_LENGTH];
	char buffer_surv_secondary[MAX_CELL_LENGTH];
	char buffer_inf_primary[MAX_CELL_LENGTH];
	char buffer_inf_secondary[MAX_CELL_LENGTH];
	int	 counter_surv		 = 0;
	int	 counter_inf		 = 0;

	buffer_surv_primary[0]	 = '\0';
	buffer_surv_secondary[0] = '\0';
	buffer_inf_primary[0]	 = '\0';
	buffer_inf_secondary[0]	 = '\0';

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i)) continue;

		if (!g_bIsSpeaking[i])
			continue;

		if (BaseComm_IsClientMuted(i))
			continue;

		GetClientName(i, name, sizeof(name));

		// alltalk -> surv hud
		if ((g_iAlltalk || GetClientTeam(i) == TEAM_SURVIVORS) && counter_surv < MAX_ROWS_PER_TEAM)
		{
			if (counter_surv < MAX_ROWS_IN_CELL)
				Format(buffer_surv_primary, MAX_CELL_LENGTH, rowFormat, buffer_surv_primary, name);
			else
				Format(buffer_surv_secondary, MAX_CELL_LENGTH, rowFormat, buffer_surv_secondary, name);

			counter_surv++;
		}
		else if (GetClientTeam(i) == TEAM_INFECTED && counter_inf < MAX_ROWS_PER_TEAM)
		{
			if (counter_inf < MAX_ROWS_IN_CELL)
				Format(buffer_inf_primary, MAX_CELL_LENGTH, rowFormat, buffer_inf_primary, name);
			else
				Format(buffer_inf_secondary, MAX_CELL_LENGTH, rowFormat, buffer_inf_secondary, name);

			counter_inf++;
		}
	}

	if (counter_surv > 1)
	{
		TrimString(buffer_surv_primary);
		TrimString(buffer_surv_secondary);
	}

	if (counter_inf > 1)
	{
		TrimString(buffer_inf_primary);
		TrimString(buffer_inf_secondary);
	}

	placeHud(buffer_surv_primary, TEAM_SURVIVORS, true, hud_surv_primary);
	placeHud(buffer_surv_secondary, TEAM_SURVIVORS, false, hud_surv_secondary);

	placeHud(buffer_inf_primary, TEAM_INFECTED, true, hud_inf_primary);
	placeHud(buffer_inf_secondary, TEAM_INFECTED, false, hud_inf_secondary);
	return Plugin_Continue;
}

public void placeHud(char[] buf, int team, bool primary, int slot)
{
	float posX, posY, width, height;
	int	  flags = HUD_FLAG_TEXT | HUD_FLAG_ALIGN_RIGHT | HUD_FLAG_NOBG;

	if (primary)
	{
		posX   = HUD_RIGHT_POS_X;
		posY   = HUD_RIGHT_POS_Y;
		width  = HUD_RIGHT_WIDTH;
		height = HUD_RIGHT_HEIGHT;
	}
	else {
		posX   = HUD_LEFT_POS_X;
		posY   = HUD_LEFT_POS_Y;
		width  = HUD_LEFT_WIDTH;
		height = HUD_LEFT_HEIGHT;
	}

	if (team == TEAM_SURVIVORS)
		flags |= HUD_FLAG_TEAM_SURVIVORS;
	else
		flags |= HUD_FLAG_TEAM_INFECTED;

	// alltalk -> surv_hud -> "spectating at ..." overlaps
	if (g_iAlltalk || team == TEAM_INFECTED)
	{
		flags &= ~HUD_FLAG_TEAM_SURVIVORS;
		posX -= 0.025;
	}

	GameRules_SetProp("m_iScriptedHUDFlags", flags, _, slot);
	GameRules_SetPropFloat("m_fScriptedHUDPosX", posX, slot);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", posY, slot);
	GameRules_SetPropFloat("m_fScriptedHUDWidth", width, slot);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", height, slot);
	GameRules_SetPropString("m_szScriptedHUDStringSet", buf, true, slot);
}

/****************************************************************************************************/
public void AlltalkChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iAlltalk = g_cvAlltalk.IntValue;
}

public void OnMapStart()
{
	GameRules_SetProp("m_bChallengeModeActive", 1);	   // Enable the HUD drawing
}

public void OnClientDisconnect(int client)
{
	g_bIsSpeaking[client] = false;
}

public void OnClientSpeaking(int client)
{
	g_bIsSpeaking[client] = true;
}

public void OnClientSpeakingEnd(int client)
{
	g_bIsSpeaking[client] = false;
}