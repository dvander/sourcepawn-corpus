#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <basecomm>
#include <sdktools>

#define HUD_LEFT_TOP                  0
#define HUD_LEFT_BOT                  1
#define HUD_MID_TOP                   2
#define HUD_MID_BOT                   3
#define HUD_RIGHT_TOP                 4
#define HUD_RIGHT_BOT                 5
#define HUD_TICKER                    6
#define HUD_FAR_LEFT                  7
#define HUD_FAR_RIGHT                 8
#define HUD_MID_BOX                   9
#define HUD_SCORE_TITLE               10
#define HUD_SCORE_1                   11
#define HUD_SCORE_2                   12
#define HUD_SCORE_3                   13
#define HUD_SCORE_4                   14

#define HUD_FLAG_NONE                 0     // no flag
#define HUD_FLAG_PRESTR               1     // do you want a string/value pair to start(pre) with the string (default is PRE)
#define HUD_FLAG_POSTSTR              2     // do you want a string/value pair to end(post) with the string
#define HUD_FLAG_BEEP                 4     // Makes a countdown timer blink
#define HUD_FLAG_BLINK                8     // do you want this field to be blinking
#define HUD_FLAG_AS_TIME              16    // ?
#define HUD_FLAG_COUNTDOWN_WARN       32    // auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG                 64    // dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER        128   // by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT           256   // Left justify this text
#define HUD_FLAG_ALIGN_CENTER         512   // Center justify this text
#define HUD_FLAG_ALIGN_RIGHT          768   // Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS       1024  // only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED        2048  // only show to the special infected team
#define HUD_FLAG_TEAM_MASK            3072  // ?
#define HUD_FLAG_UNKNOWN1             4096  // ?
#define HUD_FLAG_TEXT                 8192  // ?
#define HUD_FLAG_NOTVISIBLE           16384 // if you want to keep the slot data but keep it from displaying

#define HUD_TEAM_ALL                  0
#define HUD_TEAM_SURVIVOR             1
#define HUD_TEAM_INFECTED             2

#define HUD_TEXT_ALIGN_LEFT           1
#define HUD_TEXT_ALIGN_CENTER         2
#define HUD_TEXT_ALIGN_RIGHT          3

#define HUD_X_LEFT_TO_RIGHT           0
#define HUD_X_RIGHT_TO_LEFT           1

#define HUD_Y_TOP_TO_BOTTOM           0
#define HUD_Y_BOTTOM_TO_TOP           1

//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////

#define MAX_ROWS_IN_CELL 			  5
#define MAX_ROWS_PER_TEAM			  10
// #define MAX_ROW_LENGTH				  23
#define MAX_ROW_LENGTH				  21
#define MAX_CELL_LENGTH				  128

#define TEAM_SPECTATORS				  1
#define TEAM_SURVIVORS				  2
#define TEAM_INFECTED				  3

//////////////////////////////////////////////

#define PLUGIN_VERSION "1.3"

public Plugin myinfo =
{
	name = "[L4D 1/2] Voice hud convinient way",
	author = "glhf3000",
	description = "Up to 10 players speaking not overlapping any game UI or FOV",
	version = PLUGIN_VERSION,
	url = ""
}

bool 	bIsSpeaking[MAXPLAYERS+1];

int 	iAlltalk;

ConVar	cvAlltalk;

///////////////
ConVar 	cvHudPosLeftX, cvHudPosLeftY;
ConVar 	cvHudPosRightX, cvHudPosRightY;
ConVar	cvHudPosInfShiftX;

ConVar 	cvHudHeight, cvHudWidth;

ConVar 	cvHudAlignment;
ConVar 	cvHudFillOrder;

/////////////////
float 	fHudPosLeftX, fHudPosLeftY;
float 	fHudPosRightX, fHudPosRightY;
float	fHudPosInfShiftX;

float 	fHudHeight, fHudWidth;

int		iHudAlignment;
int		iHudFillOrder;

//////////////////
int		lastMoveFrame;
int		lastMoveFrameBtn;

int		moveRate;

bool	editMode;

int		editor;

public void OnPluginStart()
{
	//////////////////
	RegAdminCmd("vhud_toogle_edit", ToggleEdit, ADMFLAG_ROOT, "Use this cmd to move list with WASD");
	RegAdminCmd("vhud_toogle_alignment", ToggleAlignment, ADMFLAG_ROOT, "Use this cmd to switch between left/center/right text alignment");
	RegAdminCmd("vhud_toogle_order", ToggleOrder, ADMFLAG_ROOT, "Use this to switch which column fills first left or right");

	cvAlltalk = FindConVar("sv_alltalk");
	
	cvHudPosLeftX =		CreateConVar("l4d2_voice_hud_pos_left_x", 	"0.49");
	cvHudPosLeftY =		CreateConVar("l4d2_voice_hud_pos_left_y", 	"0.828");
	cvHudPosRightX =	CreateConVar("l4d2_voice_hud_pos_right_x", 	"0.71");
	cvHudPosRightY =	CreateConVar("l4d2_voice_hud_pos_right_y", 	"0.828");
	
	cvHudWidth =		CreateConVar("l4d2_voice_hud_height", 		"0.2");
	cvHudHeight =		CreateConVar("l4d2_voice_hud_width", 		"0.211");
	
	cvHudAlignment =	CreateConVar("l4d2_voice_hud_alignment", 	"768", 		"left - 256, right - 768");
	cvHudFillOrder =	CreateConVar("l4d2_voice_hud_fill_order", 	"0", 		"0 - right first, then left; 1 - left first, then right");
	
	cvHudPosInfShiftX =	CreateConVar("l4d2_voice_hud_inf_shift_x", 	"-0.025", 	"By default it is needed for 'spectating at ...' not to overlap for infected/spec. You may want to set it=0 if moving to top and want same pos for surv/inf or alltalk spec");
	
	CreateConVar("l4d2_voice_hud_version", PLUGIN_VERSION, "Up to 10 players speaking not overlapping any game UI or FOV", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "l4d2_voice_hud");
	
	//////////////////
	cvHudPosLeftX.AddChangeHook(ConVarChanged);
	cvHudPosLeftY.AddChangeHook(ConVarChanged);
	cvHudPosRightX.AddChangeHook(ConVarChanged);
	cvHudPosRightY.AddChangeHook(ConVarChanged);
	
	cvHudPosInfShiftX.AddChangeHook(ConVarChanged);
	
	cvHudWidth.AddChangeHook(ConVarChanged);
	cvHudHeight.AddChangeHook(ConVarChanged);
	
	cvHudAlignment.AddChangeHook(ConVarChanged);
	cvHudFillOrder.AddChangeHook(ConVarChanged);
	
	cvAlltalk.AddChangeHook(ConVarChanged);
	
	//////////////////
	moveRate = RoundToZero(2.0 / GetTickInterval() / 10);

	CreateTimer(0.1, UpdateSpeaking, _, TIMER_REPEAT);

	//////// testing
	// cvHudPosLeftX.FloatValue = 0.49;
	// cvHudPosLeftY.FloatValue = 0.828;
	
	// cvHudPosRightX.FloatValue = 0.71;
	// cvHudPosRightY.FloatValue = 0.828;
	
	// cvHudPosInfShiftX.FloatValue = -0.025;
	
	setVars();
}

void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	setVars();
}

void setVars()
{
	fHudPosLeftX = 		cvHudPosLeftX.FloatValue;
	fHudPosLeftY = 		cvHudPosLeftY.FloatValue;
	fHudPosRightX = 	cvHudPosRightX.FloatValue;
	fHudPosRightY = 	cvHudPosRightY.FloatValue;
	
	fHudPosInfShiftX = 	cvHudPosInfShiftX.FloatValue;
	
	fHudWidth = 		cvHudWidth.FloatValue;
	fHudHeight = 		cvHudHeight.FloatValue;
	
	iHudAlignment = 	cvHudAlignment.IntValue;
	iHudFillOrder = 	cvHudFillOrder.IntValue;
	
	iAlltalk =			cvAlltalk.IntValue;
}

/****************************************************************************************************/

public Action UpdateSpeaking(Handle timer)
{
	int hud_surv_primary = 		HUD_SCORE_1;
	int hud_surv_secondary = 	HUD_SCORE_2;
	int hud_inf_primary = 		HUD_SCORE_3;
	int hud_inf_secondary = 	HUD_SCORE_4;
	
	char rowFormat[] = "%s %s\n";
	
	char buffer_surv_primary[MAX_CELL_LENGTH];
	char buffer_surv_secondary[MAX_CELL_LENGTH];
	char buffer_inf_primary[MAX_CELL_LENGTH];
	char buffer_inf_secondary[MAX_CELL_LENGTH];
	int counter_surv = 0;
	int counter_inf = 0;
	
	buffer_surv_primary[0] = '\0';
	buffer_surv_secondary[0] = '\0';
	buffer_inf_primary[0] = '\0';
	buffer_inf_secondary[0] = '\0';

	if(!editMode)
		makeListProd(rowFormat, buffer_surv_primary, buffer_surv_secondary, buffer_inf_primary, buffer_inf_secondary, counter_surv, counter_inf);
	else
		makeListDev(rowFormat, buffer_surv_primary, buffer_surv_secondary, buffer_inf_primary, buffer_inf_secondary, counter_surv, counter_inf);
	
	if(counter_surv > 1)
	{
		TrimString(buffer_surv_primary);
		TrimString(buffer_surv_secondary);
	} 
	
	if(counter_inf > 1)
	{
		TrimString(buffer_inf_primary);
		TrimString(buffer_inf_secondary);
	}
	
	bool primary = true;
	bool secondary = false;
	
	if(iHudFillOrder == 1)
	{
		primary = !primary;
		secondary = !secondary;
	}
	
	placeHud(buffer_surv_primary, 	TEAM_SURVIVORS, primary, 	hud_surv_primary);
	placeHud(buffer_surv_secondary, TEAM_SURVIVORS, secondary, 	hud_surv_secondary);
	
	placeHud(buffer_inf_primary, 	TEAM_INFECTED, 	primary, 	hud_inf_primary);
	placeHud(buffer_inf_secondary, 	TEAM_INFECTED, 	secondary, 	hud_inf_secondary);
	
	return Plugin_Continue;
}

void makeListProd(const char[] rowFormat, char[] buffer_surv_primary, char[] buffer_surv_secondary, char[] buffer_inf_primary, char[] buffer_inf_secondary, int &counter_surv, int &counter_inf)
{
	char name[MAX_ROW_LENGTH];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i)) continue;
		
		if (!bIsSpeaking[i])
            continue;

		if (BaseComm_IsClientMuted(i))
            continue;
		
		GetClientName(i, name, sizeof(name));
		
		// alltalk -> surv hud
		if( (iAlltalk || GetClientTeam(i) == TEAM_SURVIVORS) && counter_surv < MAX_ROWS_PER_TEAM ) 
		{
		
			if(counter_surv < MAX_ROWS_IN_CELL)
				Format(buffer_surv_primary, 	MAX_CELL_LENGTH, rowFormat, buffer_surv_primary,	name);
			else
				Format(buffer_surv_secondary,	MAX_CELL_LENGTH, rowFormat, buffer_surv_secondary,	name);
				
			counter_surv++;
		
		} 
		else if( GetClientTeam(i) == TEAM_INFECTED && counter_inf < MAX_ROWS_PER_TEAM ) 
		{
		
			if(counter_inf < MAX_ROWS_IN_CELL)
				Format(buffer_inf_primary, MAX_CELL_LENGTH, rowFormat, buffer_inf_primary, name);
			else
				Format(buffer_inf_secondary, MAX_CELL_LENGTH, rowFormat, buffer_inf_secondary, name);
				
			counter_inf++;
		
		}
	}
}

void makeListDev(const char[] rowFormat, char[] buffer_surv_primary, char[] buffer_surv_secondary, char[] buffer_inf_primary, char[] buffer_inf_secondary, int &counter_surv, int &counter_inf)
{
	char name[MAX_ROW_LENGTH];
	
	counter_surv = 10;
	counter_inf = 10;
	
	for(int i = 1; i <= 5; i++)
	{
		FormatEx(name, MAX_ROW_LENGTH, "MaxLengthName_____ %i", i);
		
		Format(buffer_surv_primary, 	MAX_CELL_LENGTH, rowFormat, buffer_surv_primary,	name);
		
		if(!iAlltalk)
			Format(buffer_inf_primary, 		MAX_CELL_LENGTH, rowFormat, buffer_inf_primary,		name);
	} 
	
	for(int i = 6; i <= 10; i++)
	{
		if(i == 10)
			FormatEx(name, MAX_ROW_LENGTH, "MaxLengthName____ %i", i);
		else 
			FormatEx(name, MAX_ROW_LENGTH, "MaxLengthName_____ %i", i);
			
		Format(buffer_surv_secondary, 	MAX_CELL_LENGTH, rowFormat, buffer_surv_secondary,	name);
		
		if(!iAlltalk)
			Format(buffer_inf_secondary, 	MAX_CELL_LENGTH, rowFormat, buffer_inf_secondary,	name);
	} 
}

public void placeHud(char[] buf, int team, bool primary, int slot)
{
	float posX, posY;
	int flags = HUD_FLAG_TEXT | HUD_FLAG_NOBG;
	
	flags |= iHudAlignment;
	
	if(primary) {
		posX =   fHudPosRightX;
		posY =	 fHudPosRightY;
	} else {
		posX =   fHudPosLeftX;
		posY =   fHudPosLeftY;
	}
	
	if(team == TEAM_SURVIVORS)
		flags |= HUD_FLAG_TEAM_SURVIVORS;
	else 
		flags |= HUD_FLAG_TEAM_INFECTED;
	
	// alltalk -> surv_hud -> "spectating at ..." overlaps
	if(iAlltalk || team == TEAM_INFECTED)
	{
		flags &= ~HUD_FLAG_TEAM_SURVIVORS;
		
		posX += fHudPosInfShiftX;
	}
	
	GameRules_SetProp(		"m_iScriptedHUDFlags", 		flags, _, 	slot);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosX", 		posX, 		slot);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosY", 		posY, 		slot);
	GameRules_SetPropFloat(	"m_fScriptedHUDWidth", 		fHudWidth, 	slot);
	GameRules_SetPropFloat(	"m_fScriptedHUDHeight", 	fHudHeight, slot);
	GameRules_SetPropString("m_szScriptedHUDStringSet", buf, true,	slot);
}

/****************************************************************************************************/

public void OnMapStart()
{
    GameRules_SetProp("m_bChallengeModeActive", 1); // Enable the HUD drawing
}

public void OnClientDisconnect(int client)
{
	bIsSpeaking[client] = false;
}

public void OnClientSpeaking(int client)
{
	bIsSpeaking[client] = true;
}

public void OnClientSpeakingEnd(int client)
{
	bIsSpeaking[client] = false;
}

/****************************************************************************************************/

public Action ToggleEdit(int client, int args)
{
	editMode = !editMode;
	
	int team = GetClientTeam(client);
	MoveType move;

	if(editMode)
	{
		move = MOVETYPE_NONE;
		
		editor = client;
	}
	else
	{
		if(team == TEAM_SPECTATORS)
			move = MOVETYPE_OBSERVER;
		else
			move = MOVETYPE_WALK;
			
		editor = -1;
	}
		
	SetEntityMoveType(client, move);
	
	PrintToChat(client, "ToggleEdit> WASD-edit mode: %s", editMode ? "ON" : "OFF");
	
	if(!editMode)
	{
		PrintToChat(client, "ToggleEdit> into cfg file:");
		
		PrintToChat(client, "l4d2_voice_hud_pos_left_x	\"%f\"", 	cvHudPosLeftX.FloatValue);
		PrintToChat(client, "l4d2_voice_hud_pos_left_y	\"%f\"", 	cvHudPosLeftY.FloatValue);
		
		PrintToChat(client, "l4d2_voice_hud_pos_right_x	\"%f\"", 	cvHudPosRightX.FloatValue);
		PrintToChat(client, "l4d2_voice_hud_pos_right_y	\"%f\"", 	cvHudPosRightY.FloatValue);
	}
	
	return Plugin_Continue;
}

public Action ToggleAlignment(int client, int args)
{			
	if(iHudAlignment == 256)
		cvHudAlignment.IntValue = 768;
	else
		cvHudAlignment.IntValue = 256;
	
	PrintToChat(client, "ToggleAlignment> set to %s", cvHudAlignment.IntValue == 768 ? "RIGHT" : "LEFT");
	PrintToChat(client, "ToggleAlignment> into cfg file:");
	PrintToChat(client, "l4d2_voice_hud_alignment	\"%i\"", 	cvHudAlignment.IntValue);
	
	return Plugin_Continue;
}

public Action ToggleOrder(int client, int args)
{			
	if(iHudFillOrder == 0)
		cvHudFillOrder.IntValue = 1;
	else
		cvHudFillOrder.IntValue = 0;
	
	PrintToChat(client, "ToggleOrder> set first %s, then %s", cvHudFillOrder.IntValue == 0 ? "RIGHT" : "LEFT", cvHudFillOrder.IntValue == 0 ? "LEFT" : "RIGHT");
	PrintToChat(client, "ToggleOrder> into cfg file:");
	PrintToChat(client, "l4d2_voice_hud_fill_order	\"%i\"", 	cvHudFillOrder.IntValue);
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!editMode || client != editor || IsFakeClient(client)) return Plugin_Continue;

	int tick = GetGameTickCount();

	if(tick - lastMoveFrame < moveRate && lastMoveFrameBtn == buttons) 
	{
		return Plugin_Continue;
	}

	if(buttons == IN_FORWARD)
	{
		cvHudPosLeftY.FloatValue -= 0.01;
		cvHudPosRightY.FloatValue -= 0.01;
		// PrintToChatAll("OnPlayerRunCmd> %03f / %03f", cvHudPosLeftY.FloatValue, cvHudPosRightY.FloatValue);
	}
	
	if(buttons == IN_BACK)
	{
		cvHudPosLeftY.FloatValue += 0.01;
		cvHudPosRightY.FloatValue += 0.01;
		// PrintToChatAll("OnPlayerRunCmd> %03f / %03f", cvHudPosLeftY.FloatValue, cvHudPosRightY.FloatValue);
	}
	
	if(buttons == IN_MOVERIGHT)
	{
		cvHudPosLeftX.FloatValue += 0.01;
		cvHudPosRightX.FloatValue += 0.01;
		// PrintToChatAll("OnPlayerRunCmd> %03f / %03f", cvHudPosLeftX.FloatValue, cvHudPosRightX.FloatValue);
	}
	
	if(buttons == IN_MOVELEFT)
	{
		cvHudPosLeftX.FloatValue -= 0.01;
		cvHudPosRightX.FloatValue -= 0.01;
		// PrintToChatAll("OnPlayerRunCmd> %03f / %03f", cvHudPosLeftX.FloatValue, cvHudPosRightX.FloatValue);
	}

	lastMoveFrame = tick;
	lastMoveFrameBtn = buttons;
	
	return Plugin_Handled;
}

