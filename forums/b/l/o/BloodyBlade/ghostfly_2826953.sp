#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define MOVETYPE_WALK 2
#define MOVETYPE_FLYGRAVITY 5
#define MOVECOLLIDE_DEFAULT 0
#define MOVECOLLIDE_FLY_BOUNCE 1
#define TEAM_INFECTED 3
#define CVAR_FLAGS FCVAR_NOTIFY
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))
#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

ConVar GhostFlyOn, GhostFlyType, FlySpeed, MaxSpeed;
bool g_bCvarAllow = false, g_bMustTouchGround = false, Flying[MAXPLAYERS + 1] = {false, ...}, BlockSpawn[MAXPLAYERS + 1] = {false, ...};
float g_fFlySpeed = 50.0, g_fMaxSpeed = 500.0;

#define PLUGIN_VERSION "1.1.1a"

public Plugin myinfo =
{
	name = "L4D Ghost Fly",
	author = "Madcap (modified by dcx2)",
	description = "Fly as a ghost.",
	version = PLUGIN_VERSION,
	url = "http://maats.org"
}

public void OnPluginStart()
{
	CreateConVar("l4d_ghost_fly_version", PLUGIN_VERSION, " Ghost Fly Plugin Version ", FCVAR_REPLICATED|FCVAR_NOTIFY);
	GhostFlyOn = CreateConVar("l4d_ghost_fly_on", "1", "Turn on/off the ability for ghosts to fly.",CVAR_FLAGS,true,0.0,true,2.0);
	GhostFlyType = CreateConVar("l4d_ghost_fly_type", "1", "1 will spawn block while flying, 0 will not spawn block while flying.",CVAR_FLAGS,true,0.0,true,2.0);
	FlySpeed = CreateConVar("l4d_ghost_fly_speed", "50", "Ghost flying speed.",CVAR_FLAGS,true,0.0);
	MaxSpeed = CreateConVar("l4d_ghost_max_speed", "500", "Ghost flying max speed.", CVAR_FLAGS, true, 300.0);

	GhostFlyOn.AddChangeHook(OnGhostFlyPluginOnChanged);
	GhostFlyType.AddChangeHook(OnGhostFlyTypeChanged);
	FlySpeed.AddChangeHook(OnFlySpeedChanged);
	MaxSpeed.AddChangeHook(OnMaxSpeedChanged);

	AutoExecConfig(true, "sm_plugin_ghost_fly");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = GhostFlyOn.BoolValue;
	if(!g_bCvarAllow && bCvarAllow)
	{
		g_bCvarAllow = true;
		OnGhostFlyTypeChanged(null, "", "");
		OnFlySpeedChanged(null, "", "");
		OnMaxSpeedChanged(null, "", "");
		HookEvent("player_first_spawn", EventGhostNotify1);
		HookEvent("ghost_spawn_time", EventGhostNotify2);
	}
	else if(g_bCvarAllow && !bCvarAllow)
	{
		g_bCvarAllow = false;
		UnhookEvent("player_first_spawn", EventGhostNotify1);
		UnhookEvent("ghost_spawn_time", EventGhostNotify2);
	}
}

void OnGhostFlyPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void OnGhostFlyTypeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_bMustTouchGround = GhostFlyType.BoolValue;
}

void OnFlySpeedChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_fFlySpeed = FlySpeed.FloatValue;
}

void OnMaxSpeedChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_fMaxSpeed = MaxSpeed.FloatValue;
}

public void OnClientPutInServer(int client)
{
	if(IS_CONNECTED_INGAME(client))
	{
		Flying[client] = false;
		BlockSpawn[client] = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (g_bCvarAllow)
	{
		bool elig = IS_VALID_INFECTED(client) && IsPlayerGhost(client);
		// If we are spawn blocking, and we are either not eligible or we're on the ground, unblock spawn
		if (BlockSpawn[client] && (!elig || GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND))
		{
			BlockSpawn[client] = false;
		}

		if (g_bMustTouchGround && elig && BlockSpawn[client])
		{
			buttons &= ~IN_ATTACK;
		}
		
		if (elig && buttons & IN_RELOAD)
		{
			if (Flying[client]) KeepFlying(client);
			else StartFlying(client);
		}
		else if (Flying[client]) StopFlying(client);
	}
}

stock bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost", 1));
}

Action StartFlying(int client)
{
	Flying[client] = true;
	if (g_bMustTouchGround && !GetAdminFlag(GetUserAdmin(client), Admin_Root)) BlockSpawn[client] = true;
	SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
	AddVelocity(client, g_fFlySpeed);
	return Plugin_Continue;
}

Action KeepFlying(int client)
{
	AddVelocity(client, g_fFlySpeed);
	return Plugin_Continue;
}

Action StopFlying(int client)
{
	Flying[client] = false;
	SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
	return Plugin_Continue;
}

void AddVelocity(int client, float speed)
{
	float vecVelocity[3];
	GetEntityVelocity(client, vecVelocity);
	vecVelocity[2] += speed;
	if ((vecVelocity[2]) > g_fMaxSpeed) vecVelocity[2] = g_fMaxSpeed;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

stock void GetEntityVelocity(int entity, float fVelocity[3])
{
    GetEntPropVector(entity, Prop_Data, "m_vecVelocity", fVelocity);
}  

void SetMoveType(int client, int movetype, int movecollide)
{
	SetEntProp(client, Prop_Send, "movecollide", movecollide);
	SetEntProp(client, Prop_Send, "movetype", movetype);
}

Action EventGhostNotify1(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	Notify(client, 0);
}

Action EventGhostNotify2(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	Notify(client, event.GetInt("spawntime"));
}

void Notify(int client, int Time)
{
	CreateTimer((3.0 + Time), NotifyClient, client);
}

Action NotifyClient(Handle timer, any client)
{
	if (IS_VALID_INFECTED(client) && IsPlayerGhost(client))
	{
		PrintToChat(client, "As a ghost you can fly by holding your RELOAD button.");
	}
	return Plugin_Stop;
}
