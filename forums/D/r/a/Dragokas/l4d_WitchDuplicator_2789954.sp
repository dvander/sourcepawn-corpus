#define PLUGIN_VERSION "1.6"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

enum DIFFICULTY_LEVEL {
	DIFFICULTY_EASY,
	DIFFICULTY_NORMAL,
	DIFFICULTY_HARD,
	DIFFICULTY_EXPERT
}

#define DEBUG 0

public Plugin myinfo = 
{
	name = "[L4D] DragoWitches: Witch Duplicator",
	author = "Alex Dragokas",
	description = "Kill witch = get 2 witches",
	version = PLUGIN_VERSION,
	url = "https://dragokas.com"
};

/*
	ChangeLog
	
	1.0 (01-Apr-2019)
	 - Initial release.
	 
	1.5
	 - Added restriction on duplication based on the number of live players
	 
	1.6
	 - Code clear
	 - More ConVars
	 - Optimizations
	
*/

ConVar g_ConVarEnable;
ConVar g_ConVarIncapNoDamage;
ConVar g_ConVarMinimumClients;
ConVar g_ConVarChanceIncapEasy;
ConVar g_ConVarChanceIncapNormal;
ConVar g_ConVarChanceIncapHard;
ConVar g_ConVarMaxDuplications;

//ConVar g_ConVarWitchDamageIncap;
ConVar g_ConVarDifficulty;
ConVar g_hConVar_RyanClient;

bool g_bLate;
bool g_bBlockDupl;

int g_iSurvCount;
int g_iIncapChance;
//float g_fWitchDamageIncap;
DIFFICULTY_LEVEL g_iDifficulty;
Handle g_hTimerGrace;

const int WITCH_SECONDARY_COLOR_R = 128;
const int WITCH_SECONDARY_COLOR_G = 0;
const int WITCH_SECONDARY_COLOR_B = 0;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_witch_duplicator_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);

	g_ConVarEnable 				= CreateConVar("l4d_witch_duplicator_enabled", 	"1", 	"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	g_ConVarIncapNoDamage 		= CreateConVar("l4d_witch_incap_nodamage", 		"1", 	"Disable damage of incapped player deal by duplicated witch", CVAR_FLAGS);
	g_ConVarMinimumClients 		= CreateConVar("l4d_witch_minimum_clients", 	"4", 	"Minimum players count on server to allow duplicate witches", CVAR_FLAGS);
	g_ConVarChanceIncapEasy 	= CreateConVar("l4d_witch_chance_incap_easy", 	"0", 	"Chance (%) the duplicated witch to incap you (on easy difficulty)", CVAR_FLAGS);
	g_ConVarChanceIncapNormal 	= CreateConVar("l4d_witch_chance_incap_normal", "20", 	"Chance (%) the duplicated witch to incap you (on easy normal)", CVAR_FLAGS);
	g_ConVarChanceIncapHard 	= CreateConVar("l4d_witch_chance_incap_hard", 	"50", 	"Chance (%) the duplicated witch to incap you (on easy hard)", CVAR_FLAGS);
	g_ConVarMaxDuplications		= CreateConVar("l4d_witch_max_duplications", 	"10", 	"Maximum number of simultaneously duplicated witches (until they die)", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_witch_duplicator");
	
	//g_ConVarWitchDamageIncap = FindConVar("z_witch_damage_per_kill_hit");
	g_ConVarDifficulty = FindConVar("z_difficulty");
	
	GetCvars();
	g_ConVarEnable.AddChangeHook(ConVarChanged);
	g_ConVarDifficulty.AddChangeHook(DifficultyChanged);
	
	if (g_bLate) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) != 3) {
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		GetAliveSurvivorCount();
	}	
}

public void OnAllPluginsLoaded()
{
	g_hConVar_RyanClient = FindConVar("l4d_save_ryan_client"); // "Save private Ryan" game mode
}

public void OnClientPutInServer(int client)
{
	if (GetClientTeam(client) != 3) {
		GetAliveSurvivorCount();
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void DifficultyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char sDif[32];
	g_ConVarDifficulty.GetString(sDif, sizeof(sDif));
	
	if (StrEqual(sDif, "Easy", false)) {
		g_iDifficulty = DIFFICULTY_EASY;
	}
	else if (StrEqual(sDif, "Normal", false)) {
		g_iDifficulty = DIFFICULTY_NORMAL;
	}
	else if (StrEqual(sDif, "Hard", false)) {
		g_iDifficulty = DIFFICULTY_HARD;
	}
	else if (StrEqual(sDif, "Impossible", false)) {
		g_iDifficulty = DIFFICULTY_EXPERT;
	}
	
	//g_fWitchDamageIncap = g_ConVarWitchDamageIncap.FloatValue; // DIFFICULTY_NORMAL
	
	if (g_iDifficulty == DIFFICULTY_EASY) {
		//g_fWitchDamageIncap /= 2;
		g_iIncapChance = g_ConVarChanceIncapEasy.IntValue;
	}
	
	if (g_iDifficulty == DIFFICULTY_NORMAL) {
		g_iIncapChance = g_ConVarChanceIncapNormal.IntValue;
	}
	
	if (g_iDifficulty == DIFFICULTY_HARD) {
		//g_fWitchDamageIncap *= 2;	
		g_iIncapChance = g_ConVarChanceIncapHard.IntValue;
	}
	
	if (g_iDifficulty == DIFFICULTY_EXPERT) {
		//g_fWitchDamageIncap *= 3;	 // ???
		g_iIncapChance = 100;
	}
	
}

void GetCvars()
{
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if (g_ConVarEnable.BoolValue) {
		if (!bHooked) {
			HookEvent("witch_killed", 	Event_witch_killed, EventHookMode_Pre);
			HookEvent("round_start", 	Event_RoundStart,	EventHookMode_PostNoCopy);
			//HookEvent("player_incapacitated", Event_Incap);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("witch_killed", Event_witch_killed, EventHookMode_Pre);
			UnhookEvent("round_start", 	Event_RoundStart,	EventHookMode_PostNoCopy);
			//UnhookEvent("player_incapacitated", Event_Incap);
			bHooked = false;
		}
	}
}

public void Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client != 0)
		SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
}

public Action Timer_CheckWitchCount(Handle timer)
{
	if (GetWitchCount() == 0)
		g_bBlockDupl = false;
		
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bBlockDupl = false;
}

public void OnMapEnd()
{
	g_hTimerGrace = null;
	g_bBlockDupl = false;
}

public Action Timer_DisableDuplication(Handle timer)
{
	if (GetWitchCount() > 0) {
		g_bBlockDupl = true;
	}
	CreateTimer(60.0, Timer_EnableDuplication, _, TIMER_FLAG_NO_MAPCHANGE);
	g_hTimerGrace = null;
	return Plugin_Continue;
}

public Action Timer_EnableDuplication(Handle timer)
{
	if (GetWitchCount() <= 3) {
		g_bBlockDupl = false;
	}
	return Plugin_Continue;
}

bool IsSecondaryWitch(int witch)
{
	static int r,g,b,a;
	GetEntityRenderColor(witch, r,g,b,a);
	return (r == WITCH_SECONDARY_COLOR_R && g == WITCH_SECONDARY_COLOR_G && b == WITCH_SECONDARY_COLOR_B);
}

public void Event_witch_killed(Event event, const char[] name, bool dontBroadcast)
{
	static float fLastTime, fNowTime;
	
	if (g_iSurvCount < g_ConVarMinimumClients.IntValue)
		return;
	
	if (event.GetBool("oneshot"))
		return;
	
	fNowTime = GetGameTime();
	if (fLastTime == 0.0 || FloatAbs(fNowTime - fLastTime) > 10.0) {
		if (GetRandomInt(0, 1) == 0) { // first killed witch breeds childs with 50% chance.
			fLastTime = fNowTime;
			return;
		}
	}
	fLastTime = fNowTime;
	
	int witch = event.GetInt("witchid");
	
	// disable childs duplication
	if (IsSecondaryWitch(witch))
		return;
	
	if (g_bBlockDupl) {
		//CreateTimer(1.0, Timer_CheckWitchCount, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	if( g_hTimerGrace == null )
	{
		g_hTimerGrace = CreateTimer(60.0, Timer_DisableDuplication, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (GetWitchCount() >= g_ConVarMaxDuplications.IntValue) {
		g_bBlockDupl = true;
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));

	client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		#if DEBUG
			PrintToChatAll("Witch killed");
		#endif
		
		float pos[3];
		float pos1[3];
		float pos2[3];
		GetEntPropVector(witch, Prop_Data, "m_vecOrigin", pos);
		
		CopyVector(pos, pos1);
		CopyVector(pos, pos2);
		
		pos1[1] += 30.0;
		pos2[1] -= 30.0;
		
		SetWitch(pos1);
		SetWitch(pos2);
	}
}

void CopyVector(const float vecSrc[3], float vecDest[3]) {
	vecDest[0] = vecSrc[0];
	vecDest[1] = vecSrc[1];
	vecDest[2] = vecSrc[2];
}

int SetWitch(float vecOrigin[3])
{
	int iEntWitch = -1;
	int client = GetAnySurvivor();
	if (client != 0) {
		int ent = -1;
		ArrayList aWitch = new ArrayList(ByteCountToCells(4));
		
		while (-1 != (ent = FindEntityByClassname(ent, "witch")))
			aWitch.Push(ent);
		
		ExecuteClientCommand(client, "z_spawn", "witch auto");
		
		while (-1 != (ent = FindEntityByClassname(ent, "witch"))) {
			if (-1 == aWitch.FindValue(ent)) {
				iEntWitch = ent;
				TeleportEntity(iEntWitch, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				
				#if DEBUG
					PrintToChatAll("teleported");
				#endif
				
				SetEntityRenderColor(iEntWitch, WITCH_SECONDARY_COLOR_R, WITCH_SECONDARY_COLOR_G, WITCH_SECONDARY_COLOR_B, 255); // for special purposes
				break;
			}
		}
		delete aWitch;
	}
	return iEntWitch;
}

int GetWitchCount()
{
	static int ent, cnt;
	ent = -1;
	cnt = 0;

	while (-1 != (ent = FindEntityByClassname(ent, "witch")))
	{
		cnt++;
	}
	return cnt;
}

int GetAnySurvivor()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
			return i;
	}
	return 0;
}

void ExecuteClientCommand(int client, char[] command, char[] param)
{	
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, param);
	SetCommandFlags(command, flags);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	//Damage taken -- victim:1 | attacker:0 (worldspawn) | inflictor:0 (worldspawn) | dmg:12.00 | dmg type:131072 | weapon ent:-1 | force:0.00 | dmg 
	//Damage taken -- victim:1 | attacker:843 (witch) | inflictor:843 (witch) | dmg:60.00 | dmg type:4 | weapon ent:-1 | force:0.00 | dmg pos:0.00
	
	static char g_classAttacker[16];

	if (weapon == -1) {
	
		//15
		//30
		//60
		//100 ?
			
		if (g_iDifficulty != DIFFICULTY_EXPERT) {
			if (attacker > MaxClients && damagetype == 4) { // damage == g_fWitchDamageIncap
			
				if (g_ConVarIncapNoDamage.IntValue == 1) {
					
					if (g_hConVar_RyanClient != null) {
						if (g_hConVar_RyanClient.IntValue == victim)
							return Plugin_Continue;
					}
					
					GetEdictClassname(attacker, g_classAttacker, 16);
					if (strcmp(g_classAttacker, "witch", false) == 0) 
					{
						if( IsSecondaryWitch(attacker) )
						{
							if (g_iIncapChance <= GetRandomInt(1,100))
							{
							}
							else {
								damage = 1.0;
								return Plugin_Changed;
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

void GetAliveSurvivorCount()
{
	static int i, cnt;
	cnt = 0;

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i) && !IsPlayerIncapped(i) )
			cnt++;
	}

	g_iSurvCount = cnt;
}

bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
