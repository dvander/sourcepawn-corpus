#define PLUGIN_VERSION		"1.2"

public Plugin myinfo = 
{
	name = "[L4D] Block Generator",
	author = "Alex Dragokas",
	description = "Prevents generators to be started simultaneously",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
};

/*=======================================================================================
	Change Log:

1.2 (02-Apr-2019)
	- Fixed a little bit timing for button anti-spam.
	- Added message to all about player who is trying to start locked generator, but failed to do so.
	- Debug messages is now displayed only to admins.
	
1.1 (25-03-2019)
	- Added displaying the message about player who was able to start the final generator of elevator and save a team.
	- Code optimization.
	- Fixed g_CvarAllowAdmin logic.
	- Preventing admin to break game logic when all team is not yet got to area.
	
1.0 (25-03-2019)
	- First commit
	
	Description:
	
	This plugin is intended for L4D1 maps with generators:
	 - Crash Course : Lots
	 - Sacrifice : Port
	 
	It prevents generator from been started in such cases:
	 - previous wave is not killed yet;
	 - not all tanks is killed yet (before first wave and until next waves);
	 - at least one player is dead before first wave (so, you should wait a little bit and find them in a safe room).
	
	Exclude:
	 - admin. clients is always allowed to start the generator.
	 
	Additional present:
	 - Show message about player who was able to fix the generator in "Crash Course : Lots".
	 - Show message about player who was able to start the final generator of elevator and save a team in "Sacrifice : Port".
	
	Maybe, TODO for l4d2:
	 - c6m3_port
	 - Dead Center
	
========================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DEBUG 0

int g_iRule;
int g_iEntButton[3];
int g_iEntButtonBroken;
int g_iTankCount;
int g_iEntUnlocker;

bool g_bPressAllowed;
bool g_bGenTriggered;
bool g_bSurvInArea;
bool g_bRoundStart;
bool g_bLeft4Dead2;

ConVar g_CvarEnabled;
ConVar g_CvarAllowAdmin;
ConVar g_CvarWaitSafeRoom;

#if DEBUG
	char g_sLog[PLATFORM_MAX_PATH];
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_block_generator.phrases");

	CreateConVar("l4d_block_generator_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	
	g_CvarEnabled 		= CreateConVar("l4d_block_generator_enabled", 		"1", 	"Enable the plugin (1 - Yes, 0 - No)",	FCVAR_NOTIFY);
	g_CvarAllowAdmin 	= CreateConVar("l4d_block_generator_allow_admin", 	"1", 	"Allow admins to start generators without restrictions? (1 - Yes, 0 - No)",	FCVAR_NOTIFY);
	g_CvarWaitSafeRoom	= CreateConVar("l4d_block_generator_wait_saferoom", "1", 	"Wait for rescuing players from the saferoom before the first wave? (1 - Yes, 0 - No)",	FCVAR_NOTIFY);
	
	AutoExecConfig(true,	"l4d_block_generator");
	
	#if (DEBUG)
		RegConsoleCmd("sm_block", Cmd_Block);
		BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/block_generators.log");
		LogToFile(g_sLog, "OnPluginStart");
	#endif
}

public Action Cmd_Block(int client, int args)
{
	/*
	SetHook();
	static int ent;
	static char sCurName[32];
	ent = -1;
	while (-1 != (ent = FindEntityByClassname(ent, "trigger_multiple"))) {
		GetEntPropString(ent, Prop_Data, "m_iName", sCurName, sizeof(sCurName));
		PrintToChat(client, sCurName);
	}
	*/

	PrintToChat(client, "Plug. enabled? %b, Rule: %i", g_CvarEnabled.BoolValue, g_iRule);
	PrintToChat(client, "Admin? %b, Allow admin? %b", IsClientAdmin(client), g_CvarAllowAdmin.BoolValue);
	PrintToChat(client, "Press allow? %b, In area? %b", g_bPressAllowed, g_bSurvInArea);
	PrintToChat(client, "Tanks: %i, has dead player: %b", g_iTankCount, HasDeadPlayers());
	PrintToChat(client, "Gen triggered? %b", g_bGenTriggered);
	
	return Plugin_Handled;
}


public void OnMapStart()
{
	#if DEBUG
		LogToFile(g_sLog, "OnMapStart");
	#endif

	static char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (StrEqual(sMap, g_bLeft4Dead2 ? "c9m2_lots" : "l4d_garage02_lots", false))
		g_iRule = 1;
	else if (StrEqual(sMap, g_bLeft4Dead2 ? "c7m3_port" : "l4d_river03_port", false))
		g_iRule = 2;
	else
		g_iRule = 0;
		
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if (g_CvarEnabled.BoolValue && g_iRule) {
		if (!bHooked) {
			HookEvent("player_spawn", Event_PlayerSpawn);
			HookEvent("player_death", Event_PlayerDeath);
			HookEvent("round_freeze_end", Event_RoundFreezeEnd);
			HookEvent("round_end", Event_RoundEnd);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("player_spawn", Event_PlayerSpawn);
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("round_freeze_end", Event_RoundFreezeEnd);
			UnhookEvent("round_end", Event_RoundEnd);
			bHooked = false;
		}
	}
}

void Reset()
{
	static int i;
	/*
	// not required, since it is unhooked automatically as soon as entity is invalidated
	
	for (i = 0; i < sizeof(g_iEntButton); i++) {
		if (g_iEntButton[i] > 0 && IsValidEntity(g_iEntButton[i])) {
			UnhookSingleEntityOutput(g_iEntButton[i], "OnPressed", OnButtonPressed);
			UnhookSingleEntityOutput(g_iEntButton[i], "OnTimeUp", OnButtonTimeUp);
			UnhookSingleEntityOutput(g_iEntButton[i], "OnUseLocked", OnButtonUseLocked);
			g_iEntButton[i] = -1;
		}
	}
	if (g_iEntUnlocker > 0 && IsValidEntity(g_iEntUnlocker)) {
		UnhookSingleEntityOutput(g_iEntUnlocker, "OnEntireTeamStartTouch", OnUnlockerTouched);
		g_iEntUnlocker = -1;
	}
	if (g_iEntButtonBroken > 0 && IsValidEntity(g_iEntButtonBroken)) {
		UnhookSingleEntityOutput(g_iEntButtonBroken, "OnTimeUp", OnButtonBrokenTimeUp);
		g_iEntButtonBroken = -1;
	}
	*/
	for (i = 0; i < sizeof(g_iEntButton); i++) {
		g_iEntButton[i] = -1;
	}
	g_iEntUnlocker = -1;
	g_iEntButtonBroken = -1;
	g_bPressAllowed = false;
	g_bGenTriggered = false;
	g_bSurvInArea = false;
	g_iTankCount = 0;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	Reset();
	g_bRoundStart = false;
}

public void OnMapEnd()
{
	Reset();
	g_bRoundStart = false;
}

// it's a round_start with a delay to have time to spawn all necessary entities (including Stripper)
public void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
		LogToFile(g_sLog, "Event_RoundFreezeEnd. g_bRoundStart? %b", g_bRoundStart);
	#endif
	
	if (g_bRoundStart)
		return;
	
	g_bRoundStart = true;
	
	SetHook();
}

void SetHook()
{
	Reset();
	
	// search generator buttons
	if (g_iRule == 1) {
		if (-1 == (g_iEntButton[0] = FindEntity("func_button_timed", "finaleswitch_initial")))
		{
			LogError("Cannot find generator buttons!");
			return;
		}
	}
	else if (g_iRule == 2) {
		if (!FindEntityMulti("func_button_timed", "finale_start_button", g_iEntButton, 3))
		{
			LogError("Cannot find generator buttons!");
			return;
		}
	}
	
	#if DEBUG
		LogToFile(g_sLog, "SetHook: HookSingleEntityOutput");
	#endif
	
	for (int i = 0; i < (g_iRule == 1 ? 1 : 3); i++) {
		HookSingleEntityOutput(g_iEntButton[i], "OnPressed", OnButtonPressed, false);
		HookSingleEntityOutput(g_iEntButton[i], "OnTimeUp", OnButtonTimeUp, true);
		HookSingleEntityOutput(g_iEntButton[i], "OnUseLocked", OnButtonUseLocked, false);
	}
	
	// search generator unlocker
	if (-1 == (g_iEntUnlocker = FindEntity("trigger_multiple", g_iRule == 1 ? "finale_button_unlocker" : "generator_unlocker")))
	{
		LogError("Cannot find generator unlocker entity!");
		return;
	}
	else {
		HookSingleEntityOutput(g_iEntUnlocker, "OnEntireTeamStartTouch", OnUnlockerTouched, true);
	}
	
	// search broken button and timer
	static int ent;
	
	if (g_iRule == 1) {
		if (-1 == (ent = FindEntity("logic_timer", "generator_break_timer")))
		{
			LogError("Cannot find generator break timer!");
			return;
		}
		else {
			HookSingleEntityOutput(ent, "OnTimer", OnButtonBrokenTimer, true);
		}
	}
	else if (g_iRule == 2) {
		if (-1 == (ent = FindEntity("func_button", "bridge_start_button")))
		{
			LogError("Cannot find bridge start button!");
			return;
		}
		else {
			HookSingleEntityOutput(ent, "OnPressed", OnButtonBrokenTimer, true);
		}
	}
}

public void OnButtonBrokenTimer(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(1.0, Timer_SearchBrokenButton, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); // this button is spawned dynamically
}

public Action Timer_SearchBrokenButton(Handle timer)
{
	#if DEBUG
		static int i;
		i++;
	#endif
	
	if (-1 == (g_iEntButtonBroken = FindEntity("func_button_timed", g_iRule == 1 ? "generator_switch" : "generator_button")))
	{
		#if DEBUG
			PrintToChatAdmin("%i sec. - %s", i, "Cannot find broken button!");
		#endif
		return Plugin_Continue;
	}
	else {
		#if DEBUG
			PrintToChatAdmin("%i sec. - %s", i, "Found broken button!");
		#endif
		HookSingleEntityOutput(g_iEntButtonBroken, "OnTimeUp", OnButtonBrokenTimeUp, true);
		return Plugin_Stop;
	}
}

public void OnButtonBrokenTimeUp(const char[] output, int caller, int activator, float delay)
{
	char sName[MAX_NAME_LENGTH];
	GetClientName(activator, sName, sizeof(sName));
	if (g_iRule == 1)
		CPrintToChatAll("%t", "Gen_Fixed", sName); // Player %N was able to fix the generator!
	else if (g_iRule == 2) {
		CPrintToChatAll("%t", "Hero1"); 		// HERO !!!
		CPrintToChatAll("%t", "Hero2", sName); 	// Player %N sacrificed himself to save the team. We will remember your brave feat forever!
		CPrintToChatAll("%t", "Hero3"); 		// We will remember your brave feat forever!
	}
}

public void OnUnlockerTouched(const char[] output, int caller, int activator, float delay) // triggers when all players came to generator area
{
	#if (DEBUG)
		PrintToChatAdmin("[Generator] OnUnlockerTouched: caller - %i, activator - %i", caller, activator);
	#endif
	
	g_bPressAllowed = true;
	g_bSurvInArea = true;
	
	AcceptEntityInput(caller, "Disable"); // prevent it from triggering several times
}

public void OnButtonTimeUp(const char[] output, int caller, int activator, float delay) // happens when generator is started
{
	#if (DEBUG)
		PrintToChatAdmin("[Generator] OnButtonTimeUp: caller - %i, activator - %i", caller, activator);
	#endif
	
	if (g_iRule == 2) // block other generators until all tanks will be killed
		g_bPressAllowed = false;
	
	g_bGenTriggered = true;
	
	if (g_iRule == 1) { // only 1 generator. Disable block based on number of tanks.
		//UnhookEvent("player_spawn", Event_PlayerSpawn);
		//UnhookEvent("player_death", Event_PlayerDeath);
		g_iTankCount = 0;
	}
}

public void OnButtonPressed(const char[] output, int caller, int activator, float delay) // only happens when generator is unlocked
{
	#if (DEBUG)
		PrintToChatAdmin("[Generator] OnButtonPressed: caller - %i, activator - %i", caller, activator);
	#endif
	
	static char sName[MAX_NAME_LENGTH];
	
	static bool bLock;
	if (!g_CvarEnabled.BoolValue)
		bLock = false;
	else
		bLock = CanLock(activator);
	
	if (bLock) {
		AcceptEntityInput(caller, "Lock");
		#if (DEBUG)
			PrintToChatAdmin("[Generator] Lock is successful: caller - %i, activator - %i", caller, activator);
		#endif
		
		GetClientName(activator, sName, sizeof(sName));
		CPrintToChatAllExclude(activator, "%t", "Weak", sName);
	}
}

public void OnButtonUseLocked(const char[] output, int caller, int activator, float delay) // only happens when generator is locked
{
	#if (DEBUG)
		PrintToChatAdmin("[Generator] OnButtonUseLocked: caller - %i, activator - %i", caller, activator);
	#endif
	
	static char sName[MAX_NAME_LENGTH];
	
	static float fLastTime, fNowTime;
	fNowTime = GetGameTime();
	if (fLastTime != 0.0 && FloatAbs(fNowTime - fLastTime) < 2.0) {
		//PrintToChat(activator, "Don't press too often. You can break the button! haha. N: %f, L: %f", fNowTime, fLastTime);
		fLastTime = fNowTime;
		return;
	}
	fLastTime = fNowTime;
	
	static bool bUnlock;
	if (!g_CvarEnabled.BoolValue && g_bSurvInArea)
		bUnlock = true;
	else
		bUnlock = !CanLock(activator);
	
	if (!g_bSurvInArea) // don't allow admin to break game logic
		bUnlock = false;
	
	if (bUnlock) {
		AcceptEntityInput(caller, "Unlock");
		#if (DEBUG)
			PrintToChatAdmin("[Generator] Unlock is successful: caller - %i, activator - %i", caller, activator);
		#endif
	}
	else {
		GetClientName(activator, sName, sizeof(sName));
		CPrintToChatAllExclude(activator, "%t", "Weak", sName);
	}
}

bool CanLock(int activator) {
	static bool bLock;
		
	if (IsClientAdmin(activator)) {
		bLock = false;
	}
	else if (!g_bPressAllowed) {
		bLock = true;
		if (!g_bSurvInArea) {
			CPrintToChat(activator, "%t", "Wait_Area"); // Wait until all players come to the area
		}
		else { // zombie wave between generator triggered and tank wave
			if (g_iTankCount > 0) {
				CPrintToChat(activator, "%t", "Kill_Tank"); // Go kill some tanks first until they tear your ass!
			}
			else {
				CPrintToChat(activator, "%t", "Kill_Zombie"); // You don't have enough power to start a generator. Go kill some zombies!
			}
		}
	}
	else if (!g_bGenTriggered && HasDeadPlayers()) {
		bLock = true;
		CPrintToChat(activator, "%t", "Save_Team"); // You need to save your teammates first!
	}
	else if (g_iTankCount > 0) {
		bLock = true;
		CPrintToChat(activator, "%t", "Kill_Tank"); // Go kill some tanks first until they tear your ass!
	}
	else {
		bLock = false;
	}
	return bLock;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (g_iRule == 1 && g_bGenTriggered) // if only 1 generator and it is triggered => Disable block based on number of tanks.
		return;
	
	static int client;
	client = GetClientOfUserId(event.GetInt("userid"));
	if (client != 0)
	{
		if (IsTank(client)) { // update tanks count
			g_iTankCount = GetTankCount();
			
			#if (DEBUG)
				PrintToChatAdmin("Tank count is now: %i", g_iTankCount);
			#endif
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if (g_iRule == 1 && g_bGenTriggered) // if only 1 generator and it is triggered => Disable block based on number of tanks.
		return;
	
	static int client;
	client = GetClientOfUserId(event.GetInt("userid"));
	if (client != 0)
	{
		if (IsTank(client)) { // give a time to invalidate the entity
			CreateTimer(0.5, Timer_UpdateTankCount, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_UpdateTankCount (Handle timer)
{
	g_iTankCount = GetTankCount();
	
	if (g_bGenTriggered && g_iTankCount == 0)
		g_bPressAllowed = true;
	
	#if (DEBUG)
		PrintToChatAdmin("Tank count is now: %i", g_iTankCount);
	#endif
}

bool HasDeadPlayers()
{
	if (!g_CvarWaitSafeRoom.BoolValue)
		return false;

	static int i;
	for (i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
			return true;
	return false;
}

stock int GetTankCount() {
	static int i, count;
	count = 0;
	for (i = 1; i <= MaxClients; i++)
		if (IsTank(i))
			count++;
	return count;
}

stock bool IsTank(int client)
{
	static int class;
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ))
			return true;
	}
	return false;
}

bool IsClientAdmin(int client)
{
	if (!g_CvarAllowAdmin.BoolValue)
		return false;
	
	if (!IsClientInGame(client)) return false;
	return GetUserAdmin(client) != INVALID_ADMIN_ID;
}

stock void CPrintToChat(int client, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(client, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintToChatAllExclude(int iExcludeClient, const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( i != iExcludeClient && IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 3);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock int FindEntity(char[] sClass, char[] sName, bool bCompareModeEqual = true)
{
	static int ret[1];
	if (FindEntityMulti(sClass, sName, ret, 1, bCompareModeEqual))
		return ret[0];
	return -1;
}

stock bool FindEntityMulti(char[] sClass, char[] sName, int[] ret, int iCount, bool bCompareModeEqual = false)
{
	static int ent, iCurCnt;
	static char sCurName[32];
	ent = -1;
	iCurCnt = 0;
	while (-1 != (ent = FindEntityByClassname(ent, sClass))) {
		GetEntPropString(ent, Prop_Data, "m_iName", sCurName, sizeof(sCurName));
		
		if ((bCompareModeEqual && StrEqual(sCurName, sName)) || (!bCompareModeEqual && StrContains(sCurName, sName) != -1)) {
			ret[iCurCnt] = ent;
			iCurCnt++;
			if (iCurCnt == iCount)
				return true;
		}
	}
	return false;
}

stock void PrintToChatAdmin(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) && (GetUserFlagBits(i) & ADMFLAG_ROOT) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintToChat(i, buffer);
        }
    }
}

/* 

Events sequence:
	
	Init with => g_bPressAllowed (false), g_bGenTriggered (false)
	generator_unlocker (OnEntireTeamStartTouch) => g_bPressAllowed (true)
	finale_start_button[X] (OnTimeUp) => Lock => g_bPressAllowed (false), g_bGenTriggered (true)
	Wave => Spawn tanks => Tank death event => check for g_bGenTriggered (true) + count of tanks (0) => g_bPressAllowed (true)
	finale_start_button[X] (OnPressed) => Check for g_bPressAllowed (false) => Lock
	finale_start_button[X] (OnUseLocked) => Check for g_bPressAllowed (true) + count of tanks (0) => Unlock
	
================================= - l4d_river03_port (3 generators)

"generator_started event"

func_button_timed class

name:
finale_start_button
finale_start_button1
finale_start_button2

Lock
Unlock
Enable
Disable

OnPressed
OnTimeUp
OnUnPressed
OnUseLocked

------------------------
button broken:
------------------------

func_button
bridge_start_button => OnPressed

func_button_timed
generator_button - final generator of the ladder

================================= - l4d_garage02_lots (1 generator)

func_button_timed

name:
finaleswitch_initial
generator_switch

trigger_multiple

name:
finale_button_unlocker

------------------------
button broken:
------------------------

class:
logic_timer

name:
generator_break_timer

OnTimer => logic_relay => template => spawning of broken button "generator_switch"

*/
