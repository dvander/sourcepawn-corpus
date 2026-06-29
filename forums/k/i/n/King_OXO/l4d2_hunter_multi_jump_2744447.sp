#define PLUGIN_VERSION		"2.0"

#include <sdktools>
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define ZOMBIECLASS_HUNTER 3

public Plugin myinfo = 
{
	name		= "[L4D2] Hunter Advanced Jump",
	author		= "King_OXO",
	description	= "Allows hunter use advanced jumps",
	version		= PLUGIN_VERSION,
	url			= ""
}

ConVar cvarJumpBoost;
ConVar cvarPluginEnable;
ConVar cvarJumpMax;
float vBoost;
bool AllowPlugin;
bool pouncing[MAXPLAYERS+1];
int LastButtons[MAXPLAYERS+1];
int Jumps[MAXPLAYERS+1];
int iJumps;
	
public void OnPluginStart() 
{
	CreateConVar("hunter_jump_version", PLUGIN_VERSION, "Hunter Advanced Jump Version", FCVAR_NOTIFY);
	
	cvarPluginEnable = CreateConVar("hunter_jump_enabled", "1", "Enables Hunter Advanced Jump.", FCVAR_NOTIFY);
	
	cvarJumpBoost = CreateConVar("hunter_jump_boost", "250.0", "Hunter Jump Boost", FCVAR_NOTIFY);
	
	cvarJumpMax = CreateConVar("hunter_jump_max", "1", "Hunter Max Jumps", FCVAR_NOTIFY);
	
	HookConVarChange(cvarJumpBoost,		convar_ChangeBoost);
	HookConVarChange(cvarPluginEnable,	convar_ChangeEnable);
	HookConVarChange(cvarJumpMax,		convar_ChangeMax);
	
	HookEvent("ability_use", Event_lunge);
	
	AllowPlugin	= GetConVarBool(cvarPluginEnable);
	vBoost		= GetConVarFloat(cvarJumpBoost);
	iJumps		= GetConVarInt(cvarJumpMax);
	
	AutoExecConfig(true, "l4d2_hunter_advanced_jump");
}

public void convar_ChangeBoost(Handle convar, const char[] oldVal, const char[] newVal) 
{
	vBoost = StringToFloat(newVal);
}

public void convar_ChangeEnable(Handle convar, const char[] oldVal, const char[] newVal) 
{
	if (StringToInt(newVal) >= 1) 
	{
		AllowPlugin = true;
	} 
	else 
	{
		AllowPlugin = false;
	}
}

public void convar_ChangeMax(Handle convar, const char[] oldVal, const char[] newVal) 
{
	iJumps = StringToInt(newVal);
}

void Landed(int client) 
{
	Jumps[client] = 0;
}

void Event_lunge(Event event, const char[] sName, bool dontBroadCast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char abilityName[64];
    
    GetEventString(event,"ability",abilityName,sizeof(abilityName));
    if(IsValidClient(client) && strcmp(abilityName,"ability_lunge",false) == 0 && !pouncing[client])
    {
        pouncing[client] = true;
        CreateTimer(0.1, groundTouchTimer, client, TIMER_REPEAT);
    }
}

Action groundTouchTimer(Handle timer, any client)
{
    if((IsValidClient(client) && isGrounded(client)) || !IsPlayerAlive(client))
    {
        pouncing[client] = false;
        KillTimer(timer);
    }
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(AllowPlugin)
	{
		float Altura = MeasureHeightDistance(client);
		if(pouncing[client] && !IsFakeClient(client) && Altura <= 10.0)
		{
			ReJump(client);
		}
		int fCurFlags = GetEntityFlags(client);
		if(fCurFlags & FL_ONGROUND)
		{
			Landed(client);
		}
		else if(!(LastButtons[client] & IN_JUMP) && (buttons & IN_JUMP) && !(fCurFlags & FL_ONGROUND) && IsValidHunter(client))
		{
			ReJump(client);
		}
		
		LastButtons[client] = buttons;
	}
	
	return Plugin_Continue;
}

float MeasureHeightDistance(int client)
{
	float fPos[3], fDirAngle[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
	fDirAngle[0] = 90.0; fDirAngle[1] = 0.0; fDirAngle[2] = 0.0;
	
	Handle hTrace = TR_TraceRayFilterEx(fPos, fDirAngle, MASK_SHOT, RayType_Infinite, NonEntityFilter);
	if (!TR_DidHit(hTrace))
	{
		delete hTrace;
		return 0.0;
	}
	
	float fTraceEnd[3];
	TR_GetEndPosition(fTraceEnd, hTrace);
	
	delete hTrace;
	return GetVectorDistance(fPos, fTraceEnd, false);
}

bool NonEntityFilter(int entity, int contentsMask, any data)
{
	return (entity && IsValidEntity(entity));
}

void ReJump(int client)
{
	if (Jumps[client] < iJumps)
	{						
		Jumps[client]++;
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		
		vVel[2] += vBoost * 1.1;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	}
}

bool IsValidHunter(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_HUNTER)
		{
			return true;
		}
	}
	
	return false;
}

bool IsValidClient(int client)
{
    if (client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        return true;
    }
    return false;
}

bool isGrounded(int client)
{
    return (GetEntProp(client,Prop_Data,"m_fFlags") & FL_ONGROUND) > 0;
}