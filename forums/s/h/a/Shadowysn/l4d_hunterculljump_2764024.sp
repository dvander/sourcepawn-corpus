#define PLUGIN_NAME "[L4D] Hunter Cull-Jump"
#define PLUGIN_AUTHOR "AtomicStryker"
#define PLUGIN_DESC "Allow all hunters to perform the quick jump AI Hunters do in Coop gamemodes"
#define PLUGIN_VERSION "1.0.4b"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=118182"
#define PLUGIN_NAME_SHORT "Hunter Cull-Jump"
#define PLUGIN_NAME_TECH "hunter_culljump"

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define ZOMBIECLASS_HUNTER 3
#define JUMPFLAG IN_JUMP
#define DELAY 1.5

#define AUTOEXEC_CFG "l4d_hunterculljump"

static ConVar cvarCullJumpStrength = null;
static ConVar cvarGameMode = null;
float g_fCullJumpStrength;

static bool jumpdelay[MAXPLAYERS+1] = {false};
static bool spawndelay[MAXPLAYERS+1] = {false};
static bool isPouncingSomeone[MAXPLAYERS+1] = {false};
static bool isGamemodeCoop = false;
static int victimPouncer[MAXPLAYERS+1] = {-1};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_Left4Dead || ev == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "l4d_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "l4d_%s_force", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "How much force the %s plugin has.", PLUGIN_NAME_SHORT);
	cvarCullJumpStrength = CreateConVar(cmd_str, "750.0", desc_str, FCVAR_NONE);
	
	cvarCullJumpStrength.AddChangeHook(ConVarChanged_Cvars);
	
	cvarGameMode = FindConVar("mp_gamemode");
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvars();
	
	HookEvent("lunge_pounce", Event_StartPwn);
	HookEvent("pounce_stopped", Event_EndPwn);
	HookEvent("player_spawn", Event_Spawn);
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{ SetCvars(); }
void SetCvars()
{
	static char gamemode[5];
	GetConVarString(cvarGameMode, gamemode, sizeof(gamemode));
	isGamemodeCoop = StrEqual(gamemode, "coop");
	
	g_fCullJumpStrength = cvarCullJumpStrength.FloatValue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	
	if ((buttons & IN_ATTACK) && !jumpdelay[client] && !spawndelay[client])
	{
		if ((isGamemodeCoop)
		|| !IsInfected(client)
		|| (!IsPlayerAlive(client))
		|| (IsPlayerSpawnGhost(client))
		|| (!IsPlayerHunter(client))
		|| (isPouncingSomeone[client])
		|| (GetEntityFlags(client) & JUMPFLAG))
		{
			return Plugin_Continue;
		}
		
		jumpdelay[client] = true;
		CreateTimer(DELAY, ResetJumpDelay, client, TIMER_FLAG_NO_MAPCHANGE);
		DoPounce(client);
	}
	
	return Plugin_Continue;
}

void DoPounce(int client)
{
	float eyePos[3], eyeAng[3], projectedPos[3], resultingVec[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	projectedPos[0] = eyePos[0] + (g_fCullJumpStrength * ((Cosine(DegToRad(eyeAng[1]))) * (Cosine(DegToRad(eyeAng[0])))));
	projectedPos[1] = eyePos[1] + (g_fCullJumpStrength * ((Sine(DegToRad(eyeAng[1]))) * (Cosine(DegToRad(eyeAng[0])))));
	eyeAng[0] -= (2 * eyeAng[0]);
	projectedPos[2] = eyePos[2] + (g_fCullJumpStrength * (Sine(DegToRad(eyeAng[0]))));
	
	MakeVectorFromPoints(eyePos, projectedPos, resultingVec);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, resultingVec);
	
	PlayCullJumpSound(client);
}

Action ResetJumpDelay(Handle timer, int client)
{
	jumpdelay[client] = false;
	return Plugin_Continue;
}

Action ResetSpawnDelay(Handle timer, int client)
{
	spawndelay[client] = false;
	return Plugin_Continue;
}

void PlayCullJumpSound(int client)
{
	static char soundpath[64]; soundpath[0] = '\0';
	
	int luckynumber = GetRandomInt(1,9);
	switch (luckynumber)
	{
		case 1: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_01.wav");
		case 2: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_02.wav");
		case 3: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_04.wav");
		case 4: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_05.wav");
		case 5: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_06.wav");
		case 6: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_07.wav");
		case 7: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_09.wav");
		case 8: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_11.wav");
		case 9: strcopy(soundpath, sizeof(soundpath), "player/hunter/voice/attack/hunter_pounce_13.wav");
	}
	
	EmitSoundToAll(soundpath, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
}

void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(hunter) || !IsInfected(hunter)) return;
	
	spawndelay[hunter] = true;
	CreateTimer(DELAY, ResetSpawnDelay, hunter, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_StartPwn(Event event, const char[] name, bool dontBroadcast)
{
	int hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsValidClient(hunter) || !IsInfected(hunter) || !IsValidClient(victim)) return;
	
	isPouncingSomeone[hunter] = true;
	victimPouncer[victim] = hunter;
}

void Event_EndPwn(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsValidClient(victim)) return;
	
	int hunter = victimPouncer[victim];
	victimPouncer[victim] = -1;
	
	if (IsValidClient(hunter) && IsInfected(hunter))
	{ isPouncingSomeone[hunter] = false; }
}

bool IsPlayerHunter(int client)
{ return (GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_HUNTER); }

bool IsPlayerSpawnGhost(int client)
{ return (view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"))); }

bool IsInfected(int client)
{ return (GetClientTeam(client) == 3); }

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}