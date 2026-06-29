#include <sourcemod>
#include <sdktools>

int SurvivorVictim[MAXPLAYERS+1];
int InfectedAttacker[MAXPLAYERS+1];


ConVar pain_pills_decay_rate;

public Plugin myinfo =
{
	name = "[L4D2] Show HP",
	author = "XeroX",
	description = "Shows HP of the survivor and infected when the infected controls a survivor",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2773708"
};

public void OnPluginStart()
{
    HookEvent("choke_start", Event_PlayerControlledByInfected);
    HookEvent("lunge_pounce", Event_PlayerControlledByInfected);
    HookEvent("jockey_ride", Event_PlayerControlledByInfected);
    HookEvent("charger_pummel_start", Event_PlayerControlledByInfected);

    HookEvent("jockey_ride_end", Event_PlayerControlledByInfectedEnd);
    HookEvent("choke_end", Event_PlayerControlledByInfectedEnd);
    HookEvent("charger_pummel_end", Event_PlayerControlledByInfectedEnd);
    HookEvent("tongue_release", Event_PlayerControlledByInfectedEnd);
    HookEvent("pounce_stopped", Event_PlayerControlledByInfectedEnd);

    for(int i = 1; i<= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        OnClientPutInServer(i);
    }

    CreateTimer(1.0, t_GlobalTimer, .flags=TIMER_REPEAT);

    pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
}

public void Event_PlayerControlledByInfected(Event event, const char[] szName, bool dontBroadcast)
{
    
    int victim = GetClientOfUserId(event.GetInt("victim"));
    int attacker = GetClientOfUserId(event.GetInt("userid"));

    SurvivorVictim[attacker] = GetClientSerial(victim);
    InfectedAttacker[victim] = GetClientSerial(attacker);
}

public void Event_PlayerControlledByInfectedEnd(Event event, const char[] szName, bool dontBroadcast)
{
    
    int victim = GetClientOfUserId(event.GetInt("victim"));
    int attacker = GetClientOfUserId(event.GetInt("userid"));

    SurvivorVictim[attacker] = INVALID_ENT_REFERENCE;
    InfectedAttacker[victim] = INVALID_ENT_REFERENCE;
}

public void OnClientPutInServer(int client)
{
    SurvivorVictim[client] = INVALID_ENT_REFERENCE;
    InfectedAttacker[client] = INVALID_ENT_REFERENCE;
}

public Action t_GlobalTimer(Handle timer)
{
    int client = INVALID_ENT_REFERENCE;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        if(IsFakeClient(i)) continue; // don't send Hint messages to bots.
        client = GetClientFromSerial(SurvivorVictim[i]);
        if(client > 0 && IsClientInGame(client))
        {
            PrintHintText(i, "Survivor: %N - Health: %d\nInfected: %N - Health: %d", client, GetClientRealHealth(client), i, GetClientHealth(i));
        }
        client = GetClientFromSerial(InfectedAttacker[i]);
        if(client > 0 && IsClientInGame(client))
        {
            PrintHintText(i, "Infected: %N - Health: %d\nSurvivor: %N - Health: %d", client, GetClientHealth(client), i, GetClientRealHealth(i));
        }
    }
}

// Based on the code here: https://forums.alliedmods.net/showthread.php?t=144780
int GetClientRealHealth(int client)
{ 
    //First, we get the amount of temporal health the client has
    float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    
    //We declare the permanent and temporal health variables
    float TempHealth;
    int PermHealth = GetClientHealth(client);
    
    //In case the buffer is 0 or less, we set the temporal health as 0, because the client has not used any pills or adrenaline yet
    if(buffer <= 0.0)
    {
        TempHealth = 0.0;
    }
    
    //In case it is higher than 0, we proceed to calculate the temporl health
    else
    {
        //This is the difference between the time we used the temporal item, and the current time
        float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
        
        //We get the decay rate from this convar (Note: Adrenaline uses this value)
        float decay = pain_pills_decay_rate.FloatValue;
        
        //This is a constant we create to determine the amount of health. This is the amount of time it has to pass
        //before 1 Temporal HP is consumed.
        float constant = 1.0/decay;
        
        //Then we do the calcs
        TempHealth = buffer - (difference / constant);
    }
    
    //If the temporal health resulted less than 0, then it is just 0.
    if(TempHealth < 0.0)
    {
        TempHealth = 0.0;
    }
    
    //Return the value
    return RoundToFloor(PermHealth + TempHealth);
}  