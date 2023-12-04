#define PATH	"jump_avoid_newer"

#define LEFT					(1)
#define BACK					(2)
#define RIGHT					(3)

#pragma tabsize 0
#include <sourcemod>
#include <sdktools>

ConVar C_max_stamina;
ConVar C_regen_time;
ConVar C_acceleration;

int O_max_stamina;
float O_regen_time;
float O_acceleration;

bool Pressed[MAXPLAYERS+1];
int Avoid_stamina[MAXPLAYERS+1];

Handle H_timer_avoid_regen[MAXPLAYERS+1];

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_spawn);
	HookEvent("player_death", Event_death);
	C_max_stamina = CreateConVar("avoid_max_stamina", "2", "max stamina(use once reduce 1)", FCVAR_SPONLY, true, 1.0);
	C_regen_time = CreateConVar("avoid_regen_time", "0.1", "how long time, avoid stamina regen once", FCVAR_SPONLY, true, 0.1);
	C_acceleration = CreateConVar("avoid_acceleration", "160", "the acceleration of avoiding", FCVAR_SPONLY, true, 10.0);
	C_max_stamina.AddChangeHook(ConvarChanged);
	C_regen_time.AddChangeHook(ConvarChanged);
	C_acceleration.AddChangeHook(ConvarChanged);
	AutoExecConfig(true, PATH);
}

public void ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Internal_changed();
}

public void OnConfigsExecuted()
{
	Internal_changed();
}

public void Internal_changed()
{
	O_max_stamina = GetConVarInt(C_max_stamina);
	O_regen_time = GetConVarFloat(C_regen_time);
	O_acceleration = GetConVarFloat(C_acceleration);
}

public OnClientDisconnect(client)
{
	ReSetPlayer(client);
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(IsValidSurvivor(client))
	{
		if(!IsFakeClient(client) && IsPlayerAlive(client) && IsPlayerAlright(client) && !get_controlled(client))
		{
			if(button_changed(client, buttons))
			{
				int flags = GetEntityFlags(client);
				if(flags & FL_ONGROUND)
				{
					Avoding(client);
				}
			}
		}
	}
	return Plugin_Continue;
}

public void Event_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(client))
	{
		if(!IsFakeClient(client) && IsPlayerAlive(client))
		{
			Start_regen(client);
		}
		else
		{
			ReSetPlayer(client);
		}
	}
}

public void Event_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(client))
	{
		ReSetPlayer(client);
	}
}

public void Start_regen(int client)
{
	ReSetPlayer(client);
	H_timer_avoid_regen[client] = CreateTimer(O_regen_time, Timer_avoid_regen, GetClientUserId(client), TIMER_REPEAT);
}

public void ReSetPlayer(int client)
{
	KillTheTimer(client);
	Pressed[client] = false;
	Avoid_stamina[client] = 0;
}

public void KillTheTimer(int client)
{
	if(H_timer_avoid_regen[client] != null)
	{
		KillTimer(H_timer_avoid_regen[client]);
		H_timer_avoid_regen[client] = null;
	}   
}

public Action Timer_avoid_regen(Handle timer, any client)
{
	client = GetClientOfUserId(client);

	if(!IsValidSurvivor(client))
	{
		H_timer_avoid_regen[client] = null;
		return Plugin_Stop;		
	}
	if(IsFakeClient(client) || !IsPlayerAlive(client))
	{
		H_timer_avoid_regen[client] = null;
		return Plugin_Stop;		
	}
	if(Avoid_stamina[client] < O_max_stamina)
	{
		Avoid_stamina[client]++;
		//PrintToChat(client, "stamina regen| %d/%d", Avoid_stamina[client], O_max_stamina);
	}
	if(Avoid_stamina[client] == O_max_stamina)
	{
		H_timer_avoid_regen[client] = null;
		return Plugin_Stop;		
	}
	return Plugin_Continue;
}

public void Avoding_doing(int client, int DIRC)
{
	float ang[3];
	float vec[3];
	float vel[3];
	GetClientEyeAngles(client, ang);
	if(DIRC == LEFT || DIRC == RIGHT)
	{
		GetAngleVectors(ang, NULL_VECTOR, vec, NULL_VECTOR);
	}
	if(DIRC == BACK)
	{
		GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
	}
	NormalizeVector(vec, vec);
	if(DIRC == LEFT || DIRC == BACK)
	{
		ScaleVector(vec, -O_acceleration);
	}
	if(DIRC == RIGHT)
	{
		ScaleVector(vec, O_acceleration);
	}
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
	AddVectors(vel, vec, vel);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	Avoid_stamina[client]--;
	KillTheTimer(client);
	H_timer_avoid_regen[client] = CreateTimer(O_regen_time, Timer_avoid_regen, GetClientUserId(client), TIMER_REPEAT);
	//PrintToChat(client, "%d/%d|stamina left", Avoid_stamina[client], O_max_stamina);
}

public void Avoding(int client)
{
	if(Avoid_stamina[client] == 0)
	{
		//PrintToChat(client, "NO stamina!");
		return;
	}
	int buttons = GetClientButtons(client);
	if(buttons & IN_BACK)
	{
		if(buttons & IN_MOVELEFT)
		{
			return;
		}
		if(buttons & IN_MOVERIGHT)
		{
			return;
		}
		Avoding_doing(client, BACK);
		return;
	}
	if(buttons & IN_MOVELEFT)
	{
		if(buttons & IN_BACK)
		{
			return;
		}
		if(buttons & IN_MOVERIGHT)
		{
			return;
		}
		Avoding_doing(client, LEFT);
		return;
	}
	if(buttons & IN_MOVERIGHT)
	{
		if(buttons & IN_BACK)
		{
			return;
		}
		if(buttons & IN_MOVELEFT)
		{
			return;
		}
		Avoding_doing(client, RIGHT);
		return;
	}
}

public bool IsPlayerAlright(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0;
}

public bool IsValidSurvivor(int client)
{
	if(client >= 1 && client <= MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) == 2)
			{
				return true;
			}
		}
	}
	return false;
}

public bool get_controlled(int client)
{
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int charger2 = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if(smoker > 0 || jockey > 0 || charger > 0 || charger2 > 0 || hunter > 0)
	{
		return true;
	}	
	else
	{
		return false;
	}
}

public bool button_changed(int client, int& buttons)
{
	if(buttons & IN_FORWARD)
	{
		return false;
	}
	if(buttons & IN_MOVELEFT || buttons & IN_BACK || buttons & IN_MOVERIGHT)
	{
		if(buttons & IN_JUMP)
		{
			if(Pressed[client] == false)
			{
				Pressed[client] = true;
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			Pressed[client] = false;
			return false;
		}
	}
	else
	{
		return false;
	}
}