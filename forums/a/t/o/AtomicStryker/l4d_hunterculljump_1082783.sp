#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION							"1.0.3"


static const ZOMBIECLASS_HUNTER					= 3;
static const JUMPFLAG							= IN_JUMP;
static const Float:DELAY						= 1.5;

static Handle:cvarCullJumpStrenght				= INVALID_HANDLE;
static Handle:cvarGameMode						= INVALID_HANDLE;

static bool:jumpdelay[MAXPLAYERS+1]				= false;
static bool:spawndelay[MAXPLAYERS+1]			= false;
static bool:isPouncingSomeone[MAXPLAYERS+1]		= false;
static bool:isGamemodeCoop						= false;
static victimPouncer[MAXPLAYERS+1]				= -1;


public Plugin:myinfo = 
{
	name		= "L4D Hunter Cull Jump",
	author		= "AtomicStryker",
	description	= "Left 4 Dead Hunter Cull Jump",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?t=118182"
}

public OnPluginStart()
{
	CheckForL4DGame();
	
	CreateConVar("l4d_hunter_culljump_version", PLUGIN_VERSION, " Hunter Cull Jump Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cvarCullJumpStrenght = CreateConVar("l4d_hunter_culljump_force", "750.0", " How much force does a Hunter Cull Jump have ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookEvent("lunge_pounce", Event_StartPwn);
	HookEvent("pounce_stopped", Event_EndPwn);
	HookEvent("player_spawn", Event_Spawn);
	
	cvarGameMode = FindConVar("mp_gamemode");
	HookConVarChange(cvarGameMode, _CJ_ConVarChange);
}

public _CJ_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:gamemode[32];
	GetConVarString(cvarGameMode, gamemode, sizeof(gamemode));
	isGamemodeCoop = StrEqual(gamemode, "coop");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:clientEyeAngles[3], &weapon)
{
	if (buttons & IN_ATTACK && !jumpdelay[client] && !spawndelay[client])
	{
		if (GetClientTeam(client) != 3
		|| (!IsPlayerAlive(client))
		|| (IsPlayerSpawnGhost(client))
		|| (!IsPlayerHunter(client))
		|| (isPouncingSomeone[client])
		|| (GetEntityFlags(client) & JUMPFLAG)
		|| (isGamemodeCoop))
		{
			return Plugin_Continue;
		}
		
		jumpdelay[client] = true;
		CreateTimer(DELAY, ResetJumpDelay, client);
		DoPounce(client);
	}
	
	return Plugin_Continue;
}

static DoPounce(any:client)
{
	decl Float:clientEyePos[3], Float:clientEyeAng[3], Float:projectedPos[3], Float:resultingVec[3];
	new Float:force = GetConVarFloat(cvarCullJumpStrenght);
	GetClientEyePosition(client, clientEyePos);
	GetClientEyeAngles(client, clientEyeAng);
	
	projectedPos[0] = clientEyePos[0] + (force * ((Cosine(DegToRad(clientEyeAng[1]))) * (Cosine(DegToRad(clientEyeAng[0])))));
	projectedPos[1] = clientEyePos[1] + (force * ((Sine(DegToRad(clientEyeAng[1]))) * (Cosine(DegToRad(clientEyeAng[0])))));
	clientEyeAng[0] -= (2 * clientEyeAng[0]);
	projectedPos[2] = clientEyePos[2] + (force * (Sine(DegToRad(clientEyeAng[0]))));
	
	MakeVectorFromPoints(clientEyePos, projectedPos, resultingVec);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, resultingVec);
	
	PlayCullJumpSound(client);
}

public Action:ResetJumpDelay(Handle:timer, any:client)
{
	jumpdelay[client] = false;
}

public Action:ResetSpawnDelay(Handle:timer, any:client)
{
	spawndelay[client] = false;
}

static PlayCullJumpSound(client)
{
	decl String:soundpath[256];
	
	new luckynumber = GetRandomInt(1,9);
	switch(luckynumber)
	{
		case 1: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_01.wav");	}
		case 2: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_02.wav");	}
		case 3: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_04.wav");	}
		case 4: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_05.wav");	}
		case 5: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_06.wav");	}
		case 6: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_07.wav");	}
		case 7: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_09.wav");	}
		case 8: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_11.wav");	}
		case 9: {	strcopy(soundpath, 256, "player/hunter/voice/attack/hunter_pounce_13.wav");	}
	}
	
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			EmitSoundToClient(i, soundpath, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}
}

public Event_Spawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!hunter) return;
	
	spawndelay[hunter] = true;
	CreateTimer(DELAY, ResetSpawnDelay, hunter);
}

public Event_StartPwn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!hunter || !victim) return;
	
	isPouncingSomeone[hunter] = true;
	victimPouncer[victim] = hunter;
}

public Event_EndPwn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	
	new hunter = victimPouncer[victim];
	victimPouncer[victim] = -1;
	
	if (hunter > 0)
	{
		isPouncingSomeone[hunter] = false;
	}
}

static bool:IsPlayerHunter(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_HUNTER) return true;
	else return false;
}

stock bool:IsPlayerSpawnGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	else return false;
}

static CheckForL4DGame()
{
	decl String:gameName[24];
	GetGameFolderName(gameName, sizeof(gameName));
	if (!StrEqual(gameName, "left4dead2", .caseSensitive = false) && !StrEqual(gameName, "left4dead", .caseSensitive = false))
	{
		SetFailState("Plugin supports Left 4 Dead or L4D2 only.");
	}
}