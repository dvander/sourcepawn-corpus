/*  CREDITS
 *  - Double Jump: https://forums.alliedmods.net/showthread.php?p=895212
 *  - No Fall Damage: https://forums.alliedmods.net/showthread.php?p=2316188
 */
#pragma semicolon 1

#define PLUGIN_AUTHOR "Yimura (Alliedmods -> TheTeamGhost)"
#define PLUGIN_VERSION "1.0.0"

#define DMG_FALL (1 << 5)

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

ConVar
    g_cvMaxJumps,
    g_cvDisableFallDmg,
    g_cvForwardBoost,
    g_cvJumpBoost,

    g_cvScoutAirDashCount,

    g_cvPluginState;

bool
    g_bPluginState = false;

int
    g_iFallDmg = 0,
    g_iMaxJumps = 0,

    g_iDEF_scout_air_dash_count,

    g_iJumps[MAXPLAYERS+1],
    g_iLastButtons[MAXPLAYERS+1],
    g_iLastFlags[MAXPLAYERS+1];

float
    g_fForwardBoost,
    g_fJumpBoost;

public Plugin myinfo =
{
	name = "[TF2] Advanced Double Jump",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
    CreateConVar("sm_advancedmultijump_version", PLUGIN_VERSION, "Advanced Multi Jump Version", FCVAR_DONTRECORD);
    g_cvPluginState = CreateConVar("sm_amj_enable", "1", "Enable/Disable Advanced Multi Jump plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_cvMaxJumps = CreateConVar("sm_amj_jumpcount", "1", "Amount of jumps granted after the first jump", FCVAR_NOTIFY, true, 0.0);

    g_cvJumpBoost = CreateConVar("sm_amj_jumpboost", "300.0", "The upward boost a player is granted (for each jump)", FCVAR_NOTIFY);
    g_cvForwardBoost = CreateConVar("sm_amj_forwardboost", "300.0", "The forward boost a player is granted (for each jump)", FCVAR_NOTIFY);

    g_cvDisableFallDmg = CreateConVar("sm_amj_falldmg", "0.0", "Enable/Disable falldamage, cause jumping high is quite deadly... (0.0 = FallDamage, 1.0 = always disabled, 2.0 = disabled while using multi-jump)", FCVAR_NOTIFY, true, 0.0, true, 2.0);

    // Set our values from our cvars
    g_bPluginState = g_cvPluginState.BoolValue;
    g_iFallDmg = g_cvDisableFallDmg.IntValue;
    g_iMaxJumps = g_cvMaxJumps.IntValue;
    g_fJumpBoost = g_cvJumpBoost.FloatValue;
    g_fForwardBoost = g_cvForwardBoost.FloatValue;

    // Create our hooks
    g_cvPluginState.AddChangeHook(OnPluginStateToggled);
    g_cvJumpBoost.AddChangeHook(OnJumpBoostChanged);
    g_cvForwardBoost.AddChangeHook(OnForwardBoostChanged);
    g_cvDisableFallDmg.AddChangeHook(OnFallDmgToggled);
    g_cvMaxJumps.AddChangeHook(OnMaxJumpsChanged);

    if (GetEngineVersion() == Engine_TF2)
        g_cvScoutAirDashCount = FindConVar("tf_scout_air_dash_count");

    AutoExecConfig(true, "advanceddoublejump");
}

public void OnClientPutInServer(int client)
{
    if (!g_bPluginState && g_iFallDmg == 1)
        return;

    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnMapStart()
{
    if (!g_bPluginState)
        return;

    SetCvars();
}

public void OnMapEnd()
{
    if (!g_bPluginState)
        return;

    ResetCvars();
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!g_bPluginState)
        return Plugin_Stop;

    int
        iCurFlags   = GetEntityFlags(client),
        iCurButtons = buttons;

    if (g_iLastFlags[client] & FL_ONGROUND) {
        if (!(iCurFlags & FL_ONGROUND) && !(g_iLastButtons[client] & IN_JUMP) && iCurButtons & IN_JUMP) {
            g_iJumps[client]++;
        }
    }
    else if (iCurFlags & FL_ONGROUND) {
        if (g_iFallDmg == 2)
            SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        g_iJumps[client] = 0;
    }
    else if (!(g_iLastButtons[client] & IN_JUMP) && iCurButtons & IN_JUMP)
        DoubleJump(client, iCurButtons);

    g_iLastFlags[client]    = iCurFlags;
    g_iLastButtons[client]  = iCurButtons;

    return Plugin_Continue;
}

bool IsValidClient(int client, bool CheckAlive=true)
{
    if(client < 1 || client > MaxClients || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client)) return false;
    if(CheckAlive) return IsPlayerAlive(client);
    return true;
}

void DoubleJump(int client, int buttons) {
    if (0 <= g_iJumps[client] && g_iJumps[client] < g_iMaxJumps) {
        g_iJumps[client]++;

        float
            fVel[3],
            fAngles[3];
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
        GetClientEyeAngles(client, fAngles);

        fVel = CalculateVectors(fVel, fAngles, buttons);

        if (g_iFallDmg == 2)
            SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
    }
}

Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (damagetype & DMG_FALL)
        return Plugin_Handled;
    return Plugin_Continue;
}

float CalculateNewAngle(float fOriginalAngle, float fChange)
{
    if (fOriginalAngle >= 0)
    {
        fOriginalAngle += fChange;

        if (fOriginalAngle > 180)
            fOriginalAngle -= 360;
    }
    else
    {
        fOriginalAngle += fChange;

        if (fOriginalAngle < -180)
            fOriginalAngle += 360;
    }

    return fOriginalAngle;
}

float CalculateVectors(float fInitialVel[3], float fAngles[3], int iButtons)
{
    float
        fCalc,
        fSpeed,
        fVel[3];

    if ((iButtons & IN_FORWARD) || (iButtons & IN_BACK) || (iButtons & IN_MOVELEFT) || (iButtons & IN_MOVERIGHT))
    {
        fAngles[1] = GetAnglesWithButtons(fAngles[1], iButtons);

        fSpeed = g_fForwardBoost * 1.5;
        if (fAngles[1] >= 0)
        {
            fCalc = fAngles[1] / 90;
            fVel[0] = fSpeed * (1 - fCalc);
            fVel[1] = fSpeed - fVel[0];
            if (fAngles[1] > 90)
            {
                fCalc = (fAngles[1] - 90) / 90;
                fVel[1] = fSpeed * (1 - fCalc);
                fVel[0] = -(fSpeed - fVel[1]);
            }
        }
        else
        {
            fCalc = fAngles[1] / 90;
            fVel[0] = fSpeed * (1 + fCalc);
            fVel[1] = -(fSpeed - fVel[0]);
            if (fAngles[1] < -90)
            {
                fCalc = (fAngles[1] + 90) / 90;
                fVel[1] = fSpeed * -(1 + fCalc);
                fVel[0] = -(fSpeed + fVel[1]);
            }
        }
        fVel[2] = g_fJumpBoost;
    }
    else
    {
        fVel = fInitialVel;
        fVel[2] = g_fJumpBoost;
    }

    return fVel;
}

float GetAnglesWithButtons(float fInitialAngle, int iButtons)
{
    if ((iButtons & IN_FORWARD) && (iButtons & IN_MOVELEFT) && (iButtons & IN_MOVERIGHT))
    { /* This one is just here as a dummy*/ }
    else if ((iButtons & IN_BACK) && (iButtons & IN_MOVELEFT) && (iButtons & IN_MOVERIGHT))
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, 180.0);
    }
    else if ((iButtons & IN_BACK) && (iButtons & IN_MOVELEFT))
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, 135.0);
    }
    else if ((iButtons & IN_BACK) && (iButtons & IN_MOVERIGHT))
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, -135.0);
    }
    else if ((iButtons & IN_FORWARD) && (iButtons & IN_MOVELEFT))
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, 45.0);
    }
    else if ((iButtons & IN_FORWARD) && (iButtons & IN_MOVERIGHT))
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, -45.0);
    }
    else if (iButtons & IN_MOVELEFT)
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, 90.0);
    }
    else if (iButtons & IN_MOVERIGHT)
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, -90.0);
    }
    else if (iButtons & IN_BACK)
    {
        fInitialAngle = CalculateNewAngle(fInitialAngle, 180.0);
    }

    return fInitialAngle;
}

void ResetCvars()
{
    if (GetEngineVersion() == Engine_TF2)
        g_cvScoutAirDashCount.SetInt(g_iDEF_scout_air_dash_count, true, false);
}

void SetCvars()
{
    if (GetEngineVersion() == Engine_TF2)
    {
        g_iDEF_scout_air_dash_count = g_cvScoutAirDashCount.IntValue;

        g_cvScoutAirDashCount.SetInt(0, true, false);
    }
}

/*
 *  OnCvarChanged
 */
void OnPluginStateToggled(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_bPluginState != convar.BoolValue)
        g_bPluginState = !g_bPluginState;

    if (g_bPluginState)
        SetCvars();
    else
        ResetCvars();
}

void OnJumpBoostChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fJumpBoost = convar.FloatValue;
}

void OnForwardBoostChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fForwardBoost = convar.FloatValue;
}

void OnFallDmgToggled(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar.IntValue == 0 && convar.IntValue != g_iFallDmg)
    {
        for(int i = 1; i <= MAXPLAYERS; i++)
        {
            if (IsValidClient(i, false))
            {
                SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
        g_iFallDmg = 0;
    }
    else if (convar.IntValue == 1 && convar.IntValue != g_iFallDmg)
    {
        for(int i = 1; i <= MAXPLAYERS; i++)
        {
            if (IsValidClient(i, false))
            {
                SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
        g_iFallDmg = 1;
    }
    else if (convar.IntValue == 2 && convar.IntValue != g_iFallDmg)
    {
        for(int i = 1; i <= MAXPLAYERS; i++)
        {
            if (IsValidClient(i, false))
            {
                SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
        g_iFallDmg = 2;
    }
}

void OnMaxJumpsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar.IntValue != g_iMaxJumps)
        g_iMaxJumps = convar.IntValue;

    PrintToChatAll("Max jumps allowed has been set to %i", g_iMaxJumps);
}
