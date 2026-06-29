#define PATH    "asc_heal4.1"

#pragma tabsize 0
#include <sourcemod>
#include <sdktools>

ConVar C_heal_wait = null;
ConVar C_heal_point = null;
ConVar C_heal_max = null;
ConVar C_heal_between = null;

float O_breath_wait_time = 0.0;
int O_breath_heal_point = 0;
int O_breath_heal_max = 0;
float O_breath_heal_between = 0.0;

Handle H_breath_healing[MAXPLAYERS+1] = {null, ...};
Handle H_breath_wait[MAXPLAYERS+1] = {null, ...};

bool Sound[MAXPLAYERS+1] = {false, ...};

public void StartTHESound(int the)
{
    if(Sound[the] == false)
    {
        EmitSoundToClient(the, "player/heartbeatloop.wav");
        Sound[the] = true;
    } 
}

public void StopTHESound(int the)
{
    if(Sound[the] == true)
    {
        StopSound(the, SNDCHAN_AUTO, "player/heartbeatloop.wav");
        Sound[the] = false;
    }
}

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}
public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}
public bool IsPlayerAlright(int client)
{
	return !(IsPlayerFalling(client) || IsPlayerFallen(client));
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

public int GetClientHealthMax(int client)
{
    return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

public float GetTempHealth(int client)
{
	float Buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	Buffer -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate"));
	return Buffer < 0.0 ? 0.0 : Buffer;
}

public void SetTempHealth(int client, float Buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", Buffer < 0.0 ? 0.0 : Buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

public void fixTempHealth(int client)
{
    if(GetClientHealth(client) + GetTempHealth(client) > GetClientHealthMax(client))
	{
		SetTempHealth(client, float(GetClientHealthMax(client) - GetClientHealth(client)));
	}
}

public OnMapStart()
{
	PrecacheSound("player/heartbeatloop.wav", true);
}

public void Event_round(Event event, const char[] name, bool dontBroadcast)
{
    ResetAll();
}

public void Event_check(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(client))
	{
        if(IsPlayerAlive(client) && IsPlayerAlright(client))
        {
            if(GetClientHealth(client) < O_breath_heal_max)
            {
                SetEntityHealth(client, O_breath_heal_max);
                fixTempHealth(client);
            }
        }
	}
}

public void KillWaitTimer(int client)
{
    if(H_breath_wait[client] != null)
    {
        KillTimer(H_breath_wait[client]);
        H_breath_wait[client] = null;
    }   
}

public void KillHealTimer(int client)
{
    if(H_breath_healing[client] != null)
    {
        KillTimer(H_breath_healing[client]);
        H_breath_healing[client] = null;
    }   
}

public void ResetAll()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        StopTHESound(client);
        KillHealTimer(client);
        KillWaitTimer(client);
    }
}

public Action Timer_breath_healing(Handle timer, int client)
{
    if(!IsValidSurvivor(client))
    {
        H_breath_healing[client] = null;
        return Plugin_Stop;
    }
    if(!IsPlayerAlive(client) || !IsPlayerAlright(client))
    {
        H_breath_healing[client] = null;
        return Plugin_Stop;        
    }
    int Health = GetClientHealth(client);
    if(Health < O_breath_heal_max)
    {
        if(Health + O_breath_heal_point >= O_breath_heal_max)
        {
            StartTHESound(client);
            SetEntityHealth(client, O_breath_heal_max);
            fixTempHealth(client);
        }
        else
        {
            StartTHESound(client);
            SetEntityHealth(client, Health + O_breath_heal_point);
            fixTempHealth(client);
        }
    }
    else
    {
        StopTHESound(client);
        H_breath_healing[client] = null;
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action Timer_breath_wait(Handle timer, int client)
{
    H_breath_healing[client] = CreateTimer(O_breath_heal_between, Timer_breath_healing, client, TIMER_REPEAT);
    H_breath_wait[client] = null;
    return Plugin_Stop;
}

public void Wait_to_breath(int client)
{
    StopTHESound(client);
    KillHealTimer(client);
    KillWaitTimer(client);
    H_breath_wait[client] = CreateTimer(O_breath_wait_time, Timer_breath_wait, client, 0);    
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
    if(IsValidSurvivor(client))
    {
        if(IsPlayerAlive(client) && IsPlayerAlright(client))
        {
            if(buttons & IN_ATTACK || buttons & IN_ATTACK2)
            {
                Wait_to_breath(client);
            }
        }
    }
    return Plugin_Continue;
}

public void Event_hurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(client))
	{
        Wait_to_breath(client);
	}
}

public Event_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidSurvivor(client))
    {
        StopTHESound(client);
        KillHealTimer(client);
        KillWaitTimer(client);
    }
}

public void Event_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	if(IsValidSurvivor(client))
	{
        Wait_to_breath(client);
	}
	int client2 = GetClientOfUserId(GetEventInt(event, "bot"));
	if(IsValidSurvivor(client))
	{
        Wait_to_breath(client2);
	}
}

public void Event_Incapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"))
    if(IsValidSurvivor(client))
    {
        StopTHESound(client);
        KillHealTimer(client);
        KillWaitTimer(client);
    }
}

public Action Event_Revive_success(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "subject"));
	if(IsValidSurvivor(client))
	{
        Wait_to_breath(client);
	}
}

public void Internal_changed()
{
    O_breath_wait_time = GetConVarFloat(C_heal_wait);
    O_breath_heal_point = GetConVarInt(C_heal_point);
    O_breath_heal_max = GetConVarInt(C_heal_max);
	O_breath_heal_between = GetConVarFloat(C_heal_between);
}

public void ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Internal_changed();
}

public void OnConfigsExecuted()
{
	Internal_changed();
}

public void Event_defibrillator(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "subject"));
	if(IsValidSurvivor(client))
	{
        Wait_to_breath(client);
	}
}

public void Event_rescued(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if(IsValidSurvivor(client))
	{
        Wait_to_breath(client);
	}
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_round);
    HookEvent("player_entered_checkpoint", Event_check);
    HookEvent("player_left_checkpoint", Event_check);
    HookEvent("player_hurt", Event_hurt);
    HookEvent("player_incapacitated", Event_Incapacitated);
    HookEvent("revive_success", Event_Revive_success);
    HookEvent("defibrillator_used", Event_defibrillator);
    HookEvent("survivor_rescued", Event_rescued);
    HookEvent("player_death", Event_death);
    HookEvent("player_bot_replace", Event_replace);
    HookEvent("bot_player_replace", Event_replace);
    C_heal_wait = CreateConVar("acsheal_wait", "4.0", "how long need to wait to", FCVAR_SPONLY, true, 1.0);
	C_heal_point = CreateConVar("acsheal_hp", "1", "how much health regen once", FCVAR_SPONLY, true, 1.0);
    C_heal_between = CreateConVar("acsheal_between", "0.5", "the time between the next heal", FCVAR_SPONLY, true, 0.1);
    C_heal_max = CreateConVar("acsheal_max", "40", "the max health to reach", FCVAR_SPONLY, true, 2.0, true, 100.0);
	C_heal_wait.AddChangeHook(ConvarChanged);
	C_heal_point.AddChangeHook(ConvarChanged);
    C_heal_between.AddChangeHook(ConvarChanged);
	C_heal_max.AddChangeHook(ConvarChanged);
    AutoExecConfig(true, PATH);
}