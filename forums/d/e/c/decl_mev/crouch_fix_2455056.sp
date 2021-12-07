#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

public Plugin myinfo = 
{
	name = "Crouch fix",
	author = "mev",
	description = "[CSGO] Fixes most of the bugs with crouching.",
	version = VERSION,
	url = "http://steamcommunity.com/id/mevv/"
}

bool g_bClientFixDuck[MAXPLAYERS + 1];
bool g_bClientAllowFix[MAXPLAYERS + 1];

int g_bClientLastFlags[MAXPLAYERS + 1];
float g_vClientLastPos[MAXPLAYERS + 1][3];
float g_vClientLastVel[MAXPLAYERS + 1][3];

ConVar g_Cvar_CrouchFixEnable;

public void OnPluginStart()
{
	CreateConVar("crouchfix_version", VERSION, "Crouch fix version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_Cvar_CrouchFixEnable = CreateConVar("crouchfix_enabled", "1", "Enables crouch fix.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(g_Cvar_CrouchFixEnable.BoolValue)
	{
		int flags = GetEntityFlags(client);
		
		if(!(buttons & IN_DUCK))
		{
			g_bClientAllowFix[client] = true;
		}
		
		if(g_bClientFixDuck[client] && g_bClientAllowFix[client])
		{
			g_bClientFixDuck[client] = false;
			g_bClientAllowFix[client] = false;
			TeleportEntity(client, g_vClientLastPos[client], NULL_VECTOR, g_vClientLastVel[client]);
		}
		
		if (GetEntProp(client, Prop_Data, "m_bDucking") &&
			!GetEntProp(client, Prop_Data, "m_bDucked") &&
			buttons & IN_DUCK &&
			!(flags & FL_ONGROUND) &&
			!(g_bClientLastFlags[client] & FL_ONGROUND))
		{
			g_bClientFixDuck[client] = true;
		}
		
		GetClientAbsOrigin(client, g_vClientLastPos[client]);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", g_vClientLastVel[client]);
		g_bClientLastFlags[client] = flags;
		SetEntProp(client, Prop_Data, "m_bHasWalkMovedSinceLastJump", 1);
	}
}