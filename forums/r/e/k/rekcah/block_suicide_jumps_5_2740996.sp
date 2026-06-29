#pragma semicolon 1
#pragma newdecls required 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

float LastUserPos[MAXPLAYERS+1][3];
int JumpCount[MAXPLAYERS+1];
bool IsCharged[MAXPLAYERS+1];

#define PRINT_PREFIX "[DEBUG] "
#define POINT "models/w_models/weapons/w_eq_medkit.mdl"

public Plugin myinfo = 
{
	name = "Block Suicide jumps",
	author = "spirit/rekach",
	description = "prevents players griefing by suicide",
	version = "1.0",
	url = ""
}
public void OnPluginStart()
{	
	HookEvent("player_jump", player_jump);	
	HookEvent("player_spawn", player_spawn);
	
	HookEvent("charger_impact", charger_impact);
	HookEvent("lunge_pounce", charger_carry_start);
	HookEvent("pounce_end", charger_carry_end);
	HookEvent("charger_carry_start", charger_carry_start);
	HookEvent("charger_carry_end", charger_carry_end);
	HookEvent("charger_pummel_start", charger_carry_start);
	HookEvent("charger_pummel_end", charger_carry_end);
	HookEvent("jockey_ride", charger_carry_start);
	HookEvent("jockey_ride_end", charger_carry_end);
	HookEvent("tongue_grab", charger_carry_start);
	HookEvent("tongue_release", charger_carry_end);	
}
public Action player_jump(Handle event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));	
	GetClientAbsOrigin(client,LastUserPos[client]);
}
public Action charger_carry_start(Handle event, char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));	
	IsCharged[victim] = true;	
}
public Action charger_carry_end(Handle event, char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));	
	CreateTimer(1.0, reset, victim,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action charger_impact(Handle event, char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));	
	if(IsCharged[victim] == false)
	{
		IsCharged[victim] = true;	
		CreateTimer(3.0, reset, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action reset(Handle hTimer, int client)
{
	if(!IsValidClient(client))
		return Plugin_Stop;
		
	int flags = GetEntityFlags(client);	
	
	if(flags & FL_ONGROUND || IsIncapacitated(client) || !IsPlayerAlive(client) )
	{
		IsCharged[client] = false;
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}

public Action player_spawn(Handle event, char[] event_name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client)!=2)
		return;
	GetClientAbsOrigin(client,LastUserPos[client]);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		IsCharged[i] = false;
	}
}
public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
	IsCharged[client] = false;
	JumpCount[client] = 0;
	GetClientAbsOrigin(client,LastUserPos[client]);	
}
bool IsTriggerHurt(int attacker)
{
	char cname[64];
	GetEdictClassname(attacker, cname, sizeof(cname));
	if(StrContains(cname, "trigger_hurt", false) != -1)
	{
		return true;
	}
	return false;
}
public Action OnTakeDamagePre(int victim,  int &attacker, int &inflictor, float &damage, int &damagetype)//, float damageForce[3], float damagePosition[3])
{	

	int health = GetClientHealth(victim) + GetClientTempHealth(victim);
	
	if(IsTankHitable(inflictor) || IsCharged[victim] || GetClientTeam(victim ) != 2 || damagetype == 8 || IsFakeClient(victim) )//|| OnGround(victim))
	{
		// if is a tank hitable or player is charged or player not a survivour
		//do nothing
		return Plugin_Continue;
	}
	
	if(IsTriggerHurt(attacker) || (damagetype == 32 && damage > health) )
	{	
		RequestFrame( BlockSuicide, victim);
		damage = 0.0;
		return Plugin_Changed;	
	}
	
	if(IsTank(attacker) && (GetClientTeam(attacker)== 3 ))
	{
		IsCharged[victim] = true;	
		CreateTimer(2.0, reset, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
	}

	return Plugin_Continue;
}

public void BlockSuicide(int victim)
{	
	if(IsCharged[victim]  )
	{
		return;
	}
	
	// this stops the moving preventing them acidentally faling again after they are teleported
	float vec[3];
	GetEntPropVector(victim, Prop_Data, "m_vecBaseVelocity", vec);
	NegateVector(vec);

	TeleportEntity(victim, LastUserPos[victim], NULL_VECTOR, vec);

	JumpCount[victim] += 1;	
	PrintToChat(victim,"Please Dont Try Killing Yourself, if you Dont Wanna Play Just Leave");
	if(JumpCount[victim] > 10)
	{
		//KickClientEx(client,"Have A Nice Day!");
		JumpCount[victim] = 0;
	}
}
public int GetClientTempHealth(int client)
{
    static Handle painPillsDecayCvar = INVALID_HANDLE;
    if (painPillsDecayCvar == INVALID_HANDLE)
    {
        painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
        if (painPillsDecayCvar == INVALID_HANDLE)
        {
            return -1;
        }
    }

    int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
    return tempHealth < 0 ? 0 : tempHealth;
}
// THIS IS NEEDED TO STOP THE DEATH CAMERA BUGGING OUT.
public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > 0 && IsValidEntity(entity))
    {
        char strClassName[64];
        GetEntityClassname(entity, strClassName, sizeof(strClassName));
        if(StrContains(strClassName, "point_deathfall_camera") != -1)
		{
			RequestFrame( DeleteCamera, entity);
		}
    }
}
public void DeleteCamera(int entity)
{
	AcceptEntityInput(entity, "Kill"); 
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || GetClientTeam(client) != 2 )
    {
        return false; 
    }
    return IsClientInGame(client); 
} 
public bool IsIncapacitated(int client)
{
	if(!IsValidClient(client))
		return false;
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated")==1);
}

public bool OnGround(int client)
{
	int flags = GetEntityFlags(client);

	if(flags & FL_ONGROUND)
	{
		return true;
	}
	return false;
}

bool IsTank(int client)
{
    if(IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8  && GetClientTeam(client) == 3)
		return true;
	}
	return false;
}
public bool IsTankHitable(int entity)
{
	char className[64]; 
	GetEntityClassname(entity, className, 64);
	if ( StrEqual(className, "prop_physics"))
	{
		if (HasEntProp(entity, Prop_Send, "m_hasTankGlow") && GetEntProp(entity, Prop_Send, "m_hasTankGlow", 1)) 
		{
			return true;
		}
		
		else if ( StrEqual(className, "prop_car_alarm") ) 
		{
			return true;
		}	
	}
	return false;
}