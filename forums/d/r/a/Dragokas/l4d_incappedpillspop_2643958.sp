#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2.4"

#define SOUND_HEARTBEAT	 "player/heartbeatloop.wav"

bool IsBeingRevived[MAXPLAYERS+1];
bool IncapDelay[MAXPLAYERS+1];
bool CanUsePills;
int g_iIncapCountOffset;
int g_iTempHpOffset;
int g_iMaxIncaps;
int g_iIncapCount[MAXPLAYERS+1];

ConVar g_CvarDelaySetting;
ConVar g_CvarForbidInReviving;
ConVar g_CvarReviveHealth;
ConVar g_CvarDisableHeartbeat;
ConVar g_CvarMaxIncap;

float g_fDelaySetting;
float g_fReviveTempHealth = 30.0;
bool g_bForbidInReviving;
bool g_bDisableHeartbeat;

bool g_bLeft4dead2 = false;

public Plugin myinfo = 
{
	name = "Incapped Pills Pop",
	author = "AtomicStryker (Fork by Dragokas)",
	description = "You can press USE while incapped to pop your pills and revive yourself",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=916564"
}

/* Fork by Dragokas

	Change Log:

1.0.2.1 (05-Nov-2018)
	 - Added convar "l4d_incappedpillspop_forbid_when_reviving" to forbid use pills when somebody revivng you (it is disabled by default).
	 - Added some safe client id pass.
	 - Cached calls to FindSendPropInfo and convar-s.
	 - "lunge_pounce" and "tongue_grab" events are replaced by client prop. checkings (more reliable).
	 - Default incap delay decreased from 2.0 sec to 0.2.
	 - Default delay between "USE" key check decreased from 1.0 to 0.5 sec.
	 - Fixed some cases with timer when it disallow to use pills (replaced by GetEngineTime() and placed on more earlier stage (for reliability).
	 - Config file renamed to l4d_incappedpillspop2.cfg.
	 - Added tranlation into Russian.

1.0.2.2 (28-Dec-2018)
	 - Translation file and plugin are updated with phrases about adrenaline (by Mr. Man request).
	 - Added ConVar change hook.
	 - ConVar values are cached for optimization.
	 - Cleared old code, converted to new syntax and methodmaps.
	 - Version number is removed from plugin file name. 
	 
1.0.2.3 (17-Jan-2019)
	 - Added safe flags to timers.
	 - Added more hooks for reliability.
	 - Fixed "heartbeat" sound is not played when you use pills and become black/white.
	 - Added convar "l4d_disable_heartbeat" to disable heartbeat sound in game at all (by default, not disabled).

1.0.2.4 (19-Mar-2019)
	 - Added ability to selfhelp by picking up pills / adrenaline found on the floor when you are already incapped.
	 - Added missing kill of pills / adrenaline entity.
	 - Added compatibility with HealthExploitFix by Dragokas.
	 - Added colors support in translation file.
	 - Translation file is updated.
	 - Added advertising pills message when player grabbed the ledge.
	 - Added advertising about ability to find pills / adrenaline on the floor when you became incapped.
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4dead2 = true;
	}
	else if(test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("incappedpillspop.phrases");

	CreateConVar("l4d_incappedpillspop_version", PLUGIN_VERSION, "Version of L4D Incapped Pills Pop on this server", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_CvarDelaySetting = CreateConVar("l4d_incappedpillspop_delaytime", "0.2", "How long before an Incapped Survivor can use pills/adrenaline", FCVAR_NOTIFY);
	g_CvarForbidInReviving = CreateConVar("l4d_incappedpillspop_forbid_when_reviving", "0", "Forbid use pills/adrenaline when somebody revivng you (1 - Yes / 0 - No)", FCVAR_NOTIFY);
	g_CvarDisableHeartbeat = CreateConVar("l4d_disable_heartbeat", "0", "Disable heartbeat sound in game at all (1 - Disable / 0 - Do nothing)", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_incappedpillspop2");
	
	g_iIncapCountOffset = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	g_iTempHpOffset = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	
	g_CvarReviveHealth = FindConVar("survivor_revive_health");
	g_CvarMaxIncap = FindConVar("survivor_max_incapacitated_count");
	
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_ledge_grab", Event_Incap);

	HookEvent("revive_begin", Event_StartRevive);
	HookEvent("revive_end", Event_EndRevive);
	HookEvent("revive_success", Event_EndRevive);
	HookEvent("heal_success", Event_EndRevive);
	
	HookEvent("player_spawn", Event_PlayerSpawn);

	HookEvent("round_end", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	
	HookEvent("round_start", RoundStart);
	
	GetCvars();
	
	g_CvarDelaySetting.AddChangeHook(ConVarChanged_Cvars);
	g_CvarForbidInReviving.AddChangeHook(ConVarChanged_Cvars);
	g_CvarDisableHeartbeat.AddChangeHook(ConVarChanged_Cvars);
	g_CvarMaxIncap.AddChangeHook(ConVarChanged_Cvars);
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fDelaySetting = g_CvarDelaySetting.FloatValue;
	g_bForbidInReviving = g_CvarForbidInReviving.BoolValue;
	g_bDisableHeartbeat = g_CvarDisableHeartbeat.BoolValue;
	g_fReviveTempHealth = g_CvarReviveHealth.FloatValue;
	g_iMaxIncaps = g_CvarMaxIncap.IntValue;
}

bool IsBeingPwnt(int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if (GetEntProp(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	static float fTime[MAXPLAYERS+1];

	if (buttons & IN_USE && (GetEngineTime() - fTime[client] > 0.5))
	{
		// a little buttondelay because the cmd fires too fast.
		fTime[client] = GetEngineTime();		

		// Whoever pressed USE must be valid, connected, ingame, Survivor and Incapped		
		if (!IsClientInGame(client)) return Plugin_Continue;
		if (GetClientTeam(client)!=2) return Plugin_Continue;
		if (!IsPlayerIncapped(client)) {
			//PrintToChat(client, "Not incapped");
			return Plugin_Continue;
		}
		if (!CanUsePills) return Plugin_Continue;
		if (IncapDelay[client]) {
			//PrintToChat(client, "Delay incap");
			return Plugin_Continue;
		}

		if (IsBeingPwnt(client))
		{
			CPrintToChat(client, "\x04 %t", "GetOffInfected"); // "Get that Infected off you first."
			return Plugin_Continue;
		}
		
		if (g_bForbidInReviving) {
			if (GetEntProp(client, Prop_Send, "m_reviveOwner") > 0) 
			{
				CPrintToChat(client, "\x04 %t", "AlreadyReviving"); // "You're being revived already."
				return Plugin_Continue;
			}
		}
		
		// Check the Pills Slot. Revive. Remove Pills.
		
		bool bPills = false;
		int PillSlot = GetPlayerWeaponSlot(client, 4); // Slots start at 0. Slot Five equals 4 here.
		
		if (PillSlot == -1 && !FindHelperItemOnFloor(client, bPills)) // this gets returned if you got no Pillz and you don't see pills on the floor
		{
			CPrintToChat(client, "\x04 %t", g_bLeft4dead2 ? "NoPills2" : "NoPills"); // "You aint got no Pills."
			return Plugin_Continue;
		}
		else
		{
			if (PillSlot != -1) {
				bPills = IsPills(PillSlot);
				RemovePlayerItem(client, PillSlot);
				SetEntityKillTimer(PillSlot, 0.1);
			}
			
			CPrintToChatAllExclude(client, "\x04%N\x01 %t", client, bPills ? "UsedPills" : "UsedAdrenaline"); // "%N used his pills and revived himself!"
			EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound
			AdjustHealth(client);
		}
	}
	return Plugin_Continue;
}

bool FindHelperItemOnFloor(int client, bool& bPills)
{
	if (FindItemOnFloor(client, "weapon_pain_pills")) {
		bPills = true;
		return true;
	}
	
	if (g_bLeft4dead2)
		return FindItemOnFloor(client, "weapon_adrenaline");
	
	return false;
}

bool FindItemOnFloor(int client, char[] sClassname)
{
	const float ITEM_RADIUS = 25.0;
	const float PILLS_MAXDIST = 101.8;
	
	float vecEye[3], vecTarget[3], vecDir1[3], vecDir2[3], ang[3];
	float dist, MAX_ANG_DELTA, ang_delta;
	
	GetClientEyePosition(client, vecEye);
	
	int pills = -1;
	while (-1 != (pills = FindEntityByClassname(pills, sClassname))) {
		GetEntPropVector(pills, Prop_Data, "m_vecOrigin", vecTarget);
		
		dist = GetVectorDistance(vecEye, vecTarget);
		
		if (dist <= PILLS_MAXDIST)
		{
			// get directional angle between eyes and target
			SubtractVectors(vecTarget, vecEye, vecDir1);
			NormalizeVector(vecDir1, vecDir1);
		
			// get directional angle of eyes view
			GetClientEyeAngles(client, ang);
			GetAngleVectors(ang, vecDir2, NULL_VECTOR, NULL_VECTOR);
			
			// get angle delta between two directional angles
			ang_delta = GetAngle(vecDir1, vecDir2); // RadToDeg
			
			MAX_ANG_DELTA = ArcTangent(ITEM_RADIUS / dist); // RadToDeg
			
			if (ang_delta <= MAX_ANG_DELTA)
			{
				AcceptEntityInput(pills, "Kill");
				return true;
			}
		}
	}
	return false;
}

float GetAngle(float x1[3], float x2[3]) // by Pan XiaoHai
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

void AdjustHealth(int client)
{
	bool bHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0;
	
	g_iIncapCount[client] = GetEntData(client, g_iIncapCountOffset, 1);
	
	//SetEntProp(client, Prop_Send, "m_isIncapacitated", 0); //get him back up
	//SetEntityMoveType(client, MOVETYPE_WALK); //dont leave him immobile. that would be cruel :P
	
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);
	
	if (bHanging) {
		CreateTimer(0.3, Timer_AdjustHealthDelayed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else {
		SetNewHealth(client);
	}
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
	g_iIncapCount[client]++;
	
	//bool bHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0;
	
	SetEntData(client, g_iIncapCountOffset, g_iIncapCount[client], 1);
	
	// player/HeartbeatLoop.wav Channel:6, volume:1.000000, level:90, pitch:100, flags:0 // SNDCHAN_STATIC, SNDLEVEL_SCREAMING, SNDPITCH_NORMAL
	// player/heartbeatloop.wav Channel:0, volume:0.000000, level:0,  pitch:100, flags:4 // SNDCHAN_AUTO, SNDLEVEL_NONE, SNDPITCH_NORMAL, SND_SPAWNING
	
	if (!g_bDisableHeartbeat) {
		if (g_iMaxIncaps == g_iIncapCount[client]) {
			EmitAmbientSound(SOUND_HEARTBEAT, NULL_VECTOR, client);
		}
	}
	
	//if(!bHanging)
	CreateTimer(0.1, Timer_SetHP1, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE); // set it delayed, like tPoncho in Perkmod
	
	SetEntDataFloat(client, g_iTempHpOffset, g_fReviveTempHealth, true);
}

public Action Timer_SetHP1(Handle timer, int UserId)
{
	//hard health is always 1 after incap, unless healed
	int client = GetClientOfUserId(UserId);
	if (client != 0)
		SetEntityHealth(client, 1);
}

bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

public void Event_Incap (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	IncapDelay[client] = true;
	CreateTimer(g_fDelaySetting, Timer_AdvertisePills, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_AdvertisePills(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	IncapDelay[client] = false;
	if (!client) return;
	if (!IsClientInGame(client)) return;
	
	int PillSlot = GetPlayerWeaponSlot(client, 4); // Slots start at 0. Slot Five equals 4 here.
	if (PillSlot != -1) // this means he has anything but NO Pills xD
	{
		CPrintToChat(client, "\x01 %t", IsPills(PillSlot) ? "HintAboutPills" : "HintAboutAdrenaline"); // "You have Pills, you can now press \x04USE \x01to pop them and stand back up by yourself"
	}
	else {
		CPrintToChat(client, "\x04 %t", g_bLeft4dead2 ? "NoPills2" : "NoPills"); // "You aint got no Pills."
	}
}

bool IsPills(int iEnt) {
	if (!g_bLeft4dead2) return true;
	char classname[64];
	if (iEnt != -1) {
		GetEdictClassname(iEnt, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_pain_pills", false))
			return true;
	}
	return false;
}

public void Event_StartRevive (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;
	IsBeingRevived[client] = true;
}

public void Event_EndRevive (Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("subject");
	int client = GetClientOfUserId(UserId);
	if (!client) return;
	IsBeingRevived[client] = false;
	
	if (g_bDisableHeartbeat)
	{
		CreateTimer(1.1, Timer_DisableHeartbeat, UserId, TIMER_FLAG_NO_MAPCHANGE); // delay, just in case
	}
}

public void Event_PlayerSpawn (Event event, const char[] name, bool dontBroadcast) // to support 3-rd party plugins
{
	int UserId = event.GetInt("userid");
	int client = GetClientOfUserId(UserId);
	
	if (client != 0 && GetClientTeam(client) == 2 && !IsFakeClient(client)) {
		if (g_bDisableHeartbeat) {
			CreateTimer(1.5, Timer_DisableHeartbeat, UserId, TIMER_FLAG_NO_MAPCHANGE); // 1.5 sec. should be enough for 3-rd party plugin to set required initial state
		}
	}
}

public Action Timer_DisableHeartbeat(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client != 0 && IsClientInGame(client)) {
		StopSound(client, SNDCHAN_AUTO, SOUND_HEARTBEAT);
		StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
	}
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	CanUsePills = false;
	return Plugin_Continue;
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CanUsePills = true;
	return Plugin_Continue;
}

public void OnMapStart()
{
	CanUsePills = true;
	PrecacheSound(SOUND_HEARTBEAT, true);
}

stock void CPrintToChatAllExclude(int iExcludeClient, const char[] format, any ...) // print to all, but exclude one specified player
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

stock void SetEntityKillTimer(int entity, float fTimeout) 
{ 
	char sCmd[32]; 
	Format(sCmd, sizeof(sCmd), "OnUser1 !self:Kill::%f:1", fTimeout); 
	SetVariantString(sCmd); 
	AcceptEntityInput(entity, "AddOutput"); 
	AcceptEntityInput(entity, "FireUser1"); 
}