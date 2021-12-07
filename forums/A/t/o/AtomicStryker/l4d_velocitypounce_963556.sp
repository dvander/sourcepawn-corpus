#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "L4D Velocity Pounce",
	author = " AtomicStryker",
	description = "Pounce Damage equals Velocity",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("l4d_velocitypounce_version", PLUGIN_VERSION, " L4D Velocity Pounce Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("ability_use", Event_PounceStart);
	HookEvent("lunge_pounce", Event_PounceFinish);
}

new bool:TrackPlayerSpeed[MAXPLAYERS+1] = false;
new Float:CurrentSpeed[MAXPLAYERS+1][3];
new Float:PastSpeed[MAXPLAYERS+1][3];

new Handle:PlayerTracker[MAXPLAYERS+1] = INVALID_HANDLE;

new EverySecondFrame;

public OnGameFrame()
{
	if (!IsServerProcessing()) return;
	
	if (EverySecondFrame < 2)
	{
		EverySecondFrame++;
		return;
	}
	EverySecondFrame = 1;
	
	for (new i=1; i <= GetMaxClients(); i++)
	{
		if (TrackPlayerSpeed[i] && IsClientInGame(i))
		{
			PastSpeed[i][0] = CurrentSpeed[i][0];
			PastSpeed[i][1] = CurrentSpeed[i][1];
			PastSpeed[i][2] = CurrentSpeed[i][2];
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", CurrentSpeed[i]);
		}
	}
}

public Event_PounceStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (PlayerTracker[hunter] != INVALID_HANDLE)
	{
		KillTimer(PlayerTracker[hunter]);
		PlayerTracker[hunter] = INVALID_HANDLE;
	}
	
	TrackPlayerSpeed[hunter] = true;
	PlayerTracker[hunter] = CreateTimer(10.0, StopTracking, hunter);
}

public Action:StopTracking(Handle:timer, any:client)
{
	TrackPlayerSpeed[client] = false;
	if (PlayerTracker[client] != INVALID_HANDLE)
		PlayerTracker[client] = INVALID_HANDLE;
}

public Event_PounceFinish(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!attacker || !victim) return;
	
	if (PlayerTracker[attacker] != INVALID_HANDLE)
	{
		KillTimer(PlayerTracker[attacker]);
		PlayerTracker[attacker] = INVALID_HANDLE;
	}
	
	new velocity = RoundToNearest(GetVectorLength(PastSpeed[attacker]));
	PrintToChatAll("%N pounced %N with %i speed", attacker, victim, velocity);
	new damage = 0;
	
	if (velocity < 500)
	{
		PrintToChatAll("Velocity Pounce: Would not inflict damage");
	}
	
	else if (velocity > 1500)
	{
		PrintToChatAll("Velocity Pounce: Would inflict MAX 100 damage");
		damage = 100;
	}
	
	else //this means velocity is between 500 and 1500
	{
		velocity -= 500; //lets make the math easier. velocity now is between 0 and 1000 for 0 to 100 damage
		velocity /= 10; //velocity now equals linear damage from 0 to 1000 velocity for 0 to 100 damage
		damage = velocity;
		PrintToChatAll("Velocity Pounce: Would inflict %f damage", damage);		
	}
	
	LogMessage("%N pounced %N with %i speed, projected damage %f", attacker, victim, velocity, damage);
}