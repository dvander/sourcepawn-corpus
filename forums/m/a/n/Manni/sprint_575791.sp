/**
 * ====================
 *        Sprint
 *   Author: Greyscale
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.3"

#define MAXTIMERS 2

#define TSFLUX 0
#define TMFLUX 1

new offsSpeed;

new Handle:cvarSpeed = INVALID_HANDLE;
new Handle:cvarDeplete = INVALID_HANDLE;
new Handle:cvarReplenish = INVALID_HANDLE;
new Handle:cvarIdleReplenish = INVALID_HANDLE;
new Handle:cvarAccel = INVALID_HANDLE;
new Handle:cvarDecel = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;

new Handle:tHandles[MAXPLAYERS+1][MAXTIMERS];

new bool:inSprint[MAXPLAYERS+1];
new Float:defSpeed[MAXPLAYERS+1];
new Float:pStamina[MAXPLAYERS+1];

new bool:mFlux[MAXPLAYERS+1];
new Float:fSpeed[MAXPLAYERS+1];

new rCount[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "Sprint",
    author = "Greyscale",
    description = "All players receive a sprinting ability",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
    LoadTranslations("sprint.phrases");
    
    // ======================================================================
    
    RegConsoleCmd("sprint", Sprint, "Toggles sprinting mode for clients");
    
    // ======================================================================
    
    // Speed offset
    offsSpeed=FindSendPropInfo("CBasePlayer","m_flLaggedMovementValue");
    if(offsSpeed==-1)
    {
        SetFailState("Offset \"m_flLaggedMovementValue\" not found!");
    }
    
    // ======================================================================
    
    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
    
    // ======================================================================
    
    new Handle:cvarInfiniteSprint = FindConVar("sv_infinite_aux_power");
    if (cvarInfiniteSprint != INVALID_HANDLE)
    {
        new flags = GetConVarFlags(cvarInfiniteSprint);
        
        flags &= ~FCVAR_CHEAT;
        SetConVarFlags(cvarInfiniteSprint, flags);
    }
    
    // ======================================================================
    
    cvarSpeed = CreateConVar("sprint_speed", "1.5", "[Sprint] Multiplier of player's speed while sprinting", 0, true, 0.1, true, 9.0);
    cvarDeplete = CreateConVar("sprint_depletion_factor", "0.15", "[Sprint] Control how fast the player loses stamina", 0, true, 0.05, true, 2.0);
    cvarReplenish = CreateConVar("sprint_replenish_factor", "0.1", "[Sprint] Control how fast the player replenishes stamina while moving", 0, true, 0.05, true, 2.0);
    cvarIdleReplenish = CreateConVar("sprint_idle_replenish_factor", "0.15", "[Sprint] Control how fast the player replenishes stamina while idle", 0, true, 0.05, true, 2.0);
    cvarAccel = CreateConVar("sprint_accel_factor", "0.1", "[Sprint] Control how fast the player accelerates into full speed sprint", 0, true, 0.05, false);
    cvarDecel = CreateConVar("sprint_decel_factor", "0.2", "[Sprint] Control how fast the player decelerates to normal speed", 0, true, 0.05, false);
    cvarAnnounce = CreateConVar("sprint_announce", "3", "[Sprint] When a player joins a message will inform them of the mod, this controls how many rounds to wait before showing it again, 0 will stop announcement", 0, true, 0.0, false);
    
    CreateConVar("gs_sprint_version",VERSION,"[Sprint] Current version of this plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    AutoExecConfig();
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    rCount[client] = -1;
    
    return true;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    
    pStamina[index] = 10.0;
    
    inSprint[index] = false;
    mFlux[index] = false;
    
    new announce = GetConVarInt(cvarAnnounce);
    if (announce > 0)
    {
        if (rCount[index] == 0 || rCount[index] == announce)
        {
            rCount[index] = 0;
            PrintToChat(index, "[%t] %t", "Sprint", "Announcement");
        }
    }
    
    rCount[index]++;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    
    StopSprint(index);
}

public Action:Sprint(client, args)
{
    if (IsPlayerAlive(client))
    {
        if (inSprint[client])
        {
            StopSprint(client);
        }
        else
        {
            StartSprint(client);
        }
    }
    
    return Plugin_Handled;
}

public Action:FluxStamina(Handle:timer, any:index)
{
    if (IsClientInGame(index))
    {
        if (inSprint[index])
        {
            if (IsClientMovingForward(index))
            {
                pStamina[index] -= GetConVarFloat(cvarDeplete);
                if (pStamina[index] <= 0.0)
                {
                    pStamina[index] = 0.0;
                    StopSprint(index);
                }
                return;
            }
            else
            {
                tHandles[index][TSFLUX] = INVALID_HANDLE;
                KillTimer(timer);
                StopSprint(index);
                return;
            }
        }
        else
        {
            if (IsClientMovingForward(index))
            {
                pStamina[index] += GetConVarFloat(cvarReplenish);
            }
            else
            {
                new buttons = GetClientButtons(index);

                if (buttons == 0 || buttons == 4)
                {
                    pStamina[index] += GetConVarFloat(cvarIdleReplenish);
                }
            }
            
            if (pStamina[index] >= 10.0)
            {
                pStamina[index] = 10.0;
            }
            else
            {
                return;
            }
        }
    }
    
    tHandles[index][TSFLUX] = INVALID_HANDLE;
    KillTimer(timer);
}

public Action:FluxMovement(Handle:timer, any:index)
{
    if (IsClientInGame(index))
    {
        new Float:speed = GetClientSpeed(index);
        if (inSprint[index])
        {
            if (speed < fSpeed[index])
            {
                speed += GetConVarFloat(cvarAccel);
                if (speed > fSpeed[index])
                {
                    speed = fSpeed[index];
                    SetClientSpeed(index, speed);
                }
                else
                {
                    SetClientSpeed(index, speed);
                    return;
                }
            }
        }
        else
        {
            if (speed > defSpeed[index])
            {
                speed -= GetConVarFloat(cvarDecel);
                if (speed < defSpeed[index])
                {
                    speed = defSpeed[index];
                    SetClientSpeed(index, speed);
                }
                else
                {
                    SetClientSpeed(index, speed);
                    return;
                }
            }
        }
    }
    
    mFlux[index] = false;
    tHandles[index][TMFLUX] = INVALID_HANDLE;
    KillTimer(timer);
}

StartSprint(client)
{
    if (IsClientMovingForward(client))
    {
        if (!mFlux[client] && pStamina[client] >= 1.5)
        {
            defSpeed[client] = GetClientSpeed(client);
            
            inSprint[client] = true;
            
            new Float:curspeed = GetClientSpeed(client);
            fSpeed[client] = curspeed * GetConVarFloat(cvarSpeed);
            
            if (tHandles[client][TMFLUX] == INVALID_HANDLE)
            {
                mFlux[client] = true;
                tHandles[client][TMFLUX] = CreateTimer(0.1, FluxMovement, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
            
            if (tHandles[client][TSFLUX] == INVALID_HANDLE)
            {
                tHandles[client][TSFLUX] = CreateTimer(0.1, FluxStamina, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

StopSprint(client)
{
    inSprint[client] = false;
    
    if (tHandles[client][TSFLUX] == INVALID_HANDLE)
    {
        tHandles[client][TSFLUX] = CreateTimer(0.1, FluxStamina, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
           
    if (tHandles[client][TMFLUX] == INVALID_HANDLE)
    {
        mFlux[client] = true;
        tHandles[client][TMFLUX] = CreateTimer(0.1, FluxMovement, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

SetClientSpeed(client, Float:speed)
{
    if (speed > 0.0)
    {
        SetEntDataFloat(client, offsSpeed, speed);
    }
}

Float:GetClientSpeed(client)
{
    return GetEntDataFloat(client, offsSpeed);
}

bool:IsClientMovingForward(client)
{
    new buttons = GetClientButtons(client);
    
    return (buttons == 8 || buttons == 520 || buttons == 1032);
}