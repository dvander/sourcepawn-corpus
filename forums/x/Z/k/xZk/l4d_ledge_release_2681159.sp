#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.3.Z"

//int g_iTempHpOffset;

ConVar g_CvarDelaySetting;
ConVar g_CvarForbidInReviving;
//ConVar g_CvarReviveHealth;

float g_fDelaySetting;
//float g_fReviveTempHealth = 30.0;

bool IsBeingRevived[MAXPLAYERS+1];
bool IncapDelay[MAXPLAYERS+1];
bool g_bGrabbed[MAXPLAYERS+1];
bool CanUseRelease;
bool g_bForbidInReviving;
bool g_bLeft4Dead2;

public Plugin myinfo = 
{
	name = "[L4D] Ledge Release v2",
	author = "Alex Dragokas",
	description = "Allow players who are hanging from a ledge to let go",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

/*

	Based on my fork of:
	 - "Incapped Pills Pop" by AtomicStryker
	 - "L4D Ledge Release" by AltPluzF4, maintained by Madcap

	Required:
	 - [L4D] Health Exploit Fix by Dragokas

	Change Log:

	2.0 (05-May-2019)
	 - First release
	
	2.1 (20-May-2019)
	 - Ensure g_bGrabbed is reset.
	 
	2.2 (26-May-2019)
	 - Finally found why g_bGrabbed is not reset.
	 - Added client check on next frame.
	 
	2.3 (23-Nov-2019)
	 - Fixed infinite hanging sound.
	 - Now, correctly set health (compatible with my "Health Exploit Fix" plugin) and fire appropriate event.
	
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_ledge_release.phrases");

	CreateConVar("l4d_ledge_release_version", PLUGIN_VERSION, "Version of plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_CvarDelaySetting = CreateConVar("l4d_ledge_release_delaytime", "1.0", "How long before grabbing the ledge you can release", FCVAR_NOTIFY);
	g_CvarForbidInReviving = CreateConVar("l4d_ledge_release_forbid_when_reviving", "1", "Forbid release from the ledge when somebody reviving you (1 - Yes / 0 - No)", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_ledge_release");
	
	//g_iTempHpOffset = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	
	//g_CvarReviveHealth = FindConVar("survivor_revive_health");
	
	HookEvent("player_ledge_grab", Event_LedgeGrab);
	HookEvent("player_ledge_release", Event_LedgeRelease);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_Death);
	
	HookEvent("revive_begin", Event_StartRevive);
	HookEvent("revive_end", Event_EndRevive);
	HookEvent("revive_success", Event_EndRevive);
	HookEvent("heal_success", Event_EndRevive);

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("finale_win", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	
	HookEvent("round_start", Event_RoundStart);
	
	//RegConsoleCmd("sm_test", CmdTest);
	
	GetCvars();
	
	g_CvarDelaySetting.AddChangeHook(ConVarChanged_Cvars);
	g_CvarForbidInReviving.AddChangeHook(ConVarChanged_Cvars);
}

public Action CmdTest(int client, int args)
{
	SetEntProp(client, Prop_Send, "m_iHealth", 28);
	
	return Plugin_Handled;
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fDelaySetting = g_CvarDelaySetting.FloatValue;
	g_bForbidInReviving = g_CvarForbidInReviving.BoolValue;
}

bool IsBeingPwnt(int client)
{
	if (GetEntProp(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	static float fTime[MAXPLAYERS+1];
	
	if (!g_bGrabbed[client])
		return Plugin_Continue;
	
	if (buttons & IN_JUMP && (GetEngineTime() - fTime[client] > 0.5))
	{
		// a little buttondelay because the cmd fires too fast.
		fTime[client] = GetEngineTime();		
		
		// Whoever pressed USE must be valid, connected, ingame, Survivor and Incapped		
		if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) return Plugin_Continue;
		
		if (!IsPlayerIncapped(client)) {
			//PrintToChat(client, "Not incapped");
			return Plugin_Continue;
		}
		
		if (!CanUseRelease) return Plugin_Continue;
		
		if (IncapDelay[client]) {
			//PrintToChat(client, "Delay incap");
			return Plugin_Continue;
		}
		
		if (IsFalling(client))
			return Plugin_Continue;
		
		if (IsBeingPwnt(client))
		{
			CPrintToChat(client, "%t", "GetOffInfected"); // "Get that Infected off you first."
			return Plugin_Continue;
		}
		
		if (g_bForbidInReviving) {
			if (GetEntProp(client, Prop_Send, "m_reviveOwner") > 0) 
			{
				CPrintToChat(client, "%t", "AlreadyReviving"); // "You're being revived already."
				return Plugin_Continue;
			}
		}
		
		if(g_bLeft4Dead2){
			DropPlayerL4D2(client);
			return Plugin_Continue;
		}
		
		// emulate one hand hang, otherwise client can hang again
		int iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		SetEntProp(client, Prop_Send, "m_iHealth", 20);
		
		DataPack dp = new DataPack();
		dp.WriteCell(GetClientUserId(client));
		dp.WriteCell(iHealth);
		
		CreateTimer(0.3, Timer_OnPlayerDropDelayed, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		
		AdjustHealth(client);
	}
	return Plugin_Continue;
}

void DropPlayerL4D2(int client){
	
	float vPos[3];
	GetClientAbsOrigin(client, vPos);
	L4D2_ReviveFromIncap(client);
	TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	//PrintToChatAll("release?");
}

bool IsFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}

public Action Timer_OnPlayerDropDelayed(Handle timer, DataPack dp)
{
	dp.Reset();

	int client = GetClientOfUserId(dp.ReadCell());
	int iHealth = dp.ReadCell();
	
	if (client != 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
		OnPlayerDrop(client);
		SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
	}
}

void OnPlayerDrop(int client)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
	SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
	
	RequestFrame(OnNextFrame, client);
	
	Event hEvent = CreateEvent("revive_success");
	if (hEvent != null)
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetInt("subject", GetClientUserId(client));
		hEvent.SetBool("lastlife", false);
		hEvent.SetBool("ledge_hang", true);
		hEvent.Fire(true);
	}
}

public void OnNextFrame(any client)
{
	if (!IsClientInGame(client))
		return;
	
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangTwoHands");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangOneHand");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFingers");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangAboutToFall");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFalling");
	
	StopSound(client, SNDCHAN_STATIC, "music/terror/ClingingToHell1.wav");
	StopSound(client, SNDCHAN_STATIC, "music/terror/ClingingToHell2.wav");
	StopSound(client, SNDCHAN_STATIC, "music/terror/ClingingToHell3.wav");
	StopSound(client, SNDCHAN_STATIC, "music/terror/ClingingToHell4.wav");
}

stock void AdjustHealth(int client)
{
	CreateTimer(1.1, Timer_AdjustHealthDelayed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_AdjustHealthDelayed(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client != 0 && IsClientInGame(client)) {
		SetNewHealth(client);
	}
}

void SetNewHealth(int client)
{	
	//bool bHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0;
	//if(!bHanging)
	
	int iHealth = GetEntProp(client, Prop_Data, "m_iHealth");
	float fTempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	int iReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	int iGoingToDie = GetEntProp(client, Prop_Send, "m_isGoingToDie");
	
	int iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	
	SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", iGoingToDie);
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTempHealth);
	
	Event hEvent = CreateEvent("heal_success");
	if (hEvent != null)
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetInt("subject", GetClientUserId(client));
		hEvent.SetInt("health_restored", 0);
		hEvent.Fire(true);
	}
}

bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

public void Event_PlayerSpawn (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bGrabbed[client] = false;
}

public void Event_LedgeGrab (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	IncapDelay[client] = true;
	g_bGrabbed[client] = true;
	CreateTimer(g_fDelaySetting, Timer_AdvertiseRelease, GetClientUserId(client));
}

public void Event_LedgeRelease (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bGrabbed[client] = false;
}

public void OnClientPutInServer(int client)
{
	g_bGrabbed[client] = false;
}

public void Event_Death( Event event, const char[] Death_Name, bool dontBroadcast )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bGrabbed[client] = false;
}

public Action Timer_AdvertiseRelease(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	IncapDelay[client] = false;
	if (!client) return;
	if (!IsClientInGame(client)) return;
	
	CPrintToChat(client, "%t", "Hint_About_Release"); // "You can press SPACE (JUMP) to release from the ledge"
}

public void Event_StartRevive (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;
	IsBeingRevived[client] = true;
}

public void Event_EndRevive (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	IsBeingRevived[client] = false;
	g_bGrabbed[client] = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	CanUseRelease = false;
}

public void OnMapEnd()
{
	CanUseRelease = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Reset();
}

public void OnMapStart()
{
	Reset();
}

void Reset()
{
	CanUseRelease = true;
	for (int i = 1; i <= MaxClients; i++) {
		IsBeingRevived[i] = false;
		IncapDelay[i] = false;
		g_bGrabbed[i] = false;
	}	
}

stock void CPrintToChat(int client, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(client, "\x01%s", buffer);
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void L4D2_ReviveFromIncap(int client) {

	L4D2_RunScript("GetPlayerFromUserID(%d).ReviveFromIncap()",GetClientUserId(client));
}

stock void L4D2_RunScript(const char[] sCode, any ...) {

	/**
	* Run a VScript (Credit to Timocop)
	*
	* @param sCode		Magic
	* @return void
	*/

	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));

		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
			SetFailState("Could not create 'logic_script'");
		}

		DispatchSpawn(iScriptLogic);
	}

	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}
