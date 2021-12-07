#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MOVETYPE_WALK 2
#define MOVETYPE_FLYGRAVITY 5
#define MOVECOLLIDE_DEFAULT 0
#define MOVECOLLIDE_FLY_BOUNCE 1

#define TEAM_INFECTED 3

#define CVAR_FLAGS FCVAR_PLUGIN

new PropMoveCollide;
new PropMoveType;
new PropVelocity;
new PropGhost;

new Handle:GhostFly;
new Handle:FlySpeed;

new bool:Flying[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "L4D Ghost Fly",
	author = "Madcap",
	description = "Fly as a ghost.",
	version = PLUGIN_VERSION,
	url = "http://maats.org"
}


public OnPluginStart()
{

	GhostFly = CreateConVar("l4d_ghost_fly", "1", "Turn on/off the ability for ghosts to fly.",CVAR_FLAGS,true,0.0,true,1.0);
	FlySpeed = CreateConVar("l4d_ghost_fly_speed", "50", "L4D Ghost flying speed.",CVAR_FLAGS,true,0.0);
	AutoExecConfig(true, "sm_plugin_ghost_fly");
	
	CreateConVar("l4d_ghost_fly_version", PLUGIN_VERSION, " Ghost Fly Plugin Version ", FCVAR_REPLICATED|FCVAR_NOTIFY);

	PropMoveCollide = FindSendPropOffs("CBaseEntity",   "movecollide");
	PropMoveType    = FindSendPropOffs("CBaseEntity",   "movetype");
	PropVelocity    = FindSendPropOffs("CBasePlayer",   "m_vecVelocity[0]");
	PropGhost       = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}

public OnGameFrame()
{

	if (GetConVarBool(GhostFly))
	{
		decl maxclients;
		maxclients = MaxClients;
		for (new i=1; i<=maxclients; i++)
		{
			if (isEligible(i))
			{
				new buttons = GetEntProp(i, Prop_Data, "m_nButtons", buttons);
				if(buttons & IN_RELOAD)
				{		
					if (Flying[i])
						KeepFlying(i);
					else	
						StartFlying(i);
				}
				else
				{
					if (Flying[i])
						StopFlying(i);
				}	
			}
			else
			{
				if (Flying[i])
					StopFlying(i);
			}
		}
	}
}


bool:isEligible(client)
{

	if (!IsClientConnected(client)) return false;
	//LogMessage("check1");
	if (!IsClientInGame(client)) return false;
	//LogMessage("check2");
	if (GetClientTeam(client)!=TEAM_INFECTED) return false;
	//LogMessage("check3");
	if (GetEntData(client, PropGhost, 1)!=1) return false;
	//LogMessage("check4");
	return true;
}

public Action:StartFlying(client)
{
	//PrintToChat(client, "attempting to make you fly.");
	Flying[client]=true;
	SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
	AddVelocity(client, GetConVarFloat(FlySpeed));
	return Plugin_Continue;
}

public Action:KeepFlying(client)
{
	AddVelocity(client, GetConVarFloat(FlySpeed));
	return Plugin_Continue;
}

public Action:StopFlying(client)
{
	Flying[client]=false;
	SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
	return Plugin_Continue;
}

AddVelocity(client, Float:speed)
{
	new Float:vecVelocity[3];
	GetEntDataVector(client, PropVelocity, vecVelocity);
	vecVelocity[2] += speed;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

SetMoveType(client, movetype, movecollide)
{
	SetEntData(client, PropMoveType, movetype);
	SetEntData(client, PropMoveCollide, movecollide);
}

public OnClientDisconnect(client)
{
	StopFlying(client);
}
