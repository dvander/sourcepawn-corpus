#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// Found by trial and error
#define JUMP_SPEED 283.0

// Distance the player will be shifted upwards when releasing duck before being
// completely ducked.
// Found by comparing player maxs when standing and crouching.
#define DOUBLE_DUCK_HEIGHT 20

// Values <= this value won't make the player lift up from ground
// Found by trial and error
#define DOUBLE_DUCK_HEIGHT_OFFSET 22

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/gamemovement.h#L104
#define AIR_CAP 30.0

// #define DEBUG

#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_PREFIX "[CM]"


// Variables {{{
// Plugin cvars
new Handle:cvarEnabled      = INVALID_HANDLE;
new Handle:cvarAutohop      = INVALID_HANDLE;
new Handle:cvarSpeedo       = INVALID_HANDLE;
new Handle:cvarMaxspeed     = INVALID_HANDLE;
new Handle:cvarDuckJump     = INVALID_HANDLE;
new Handle:cvarDoubleDuck   = INVALID_HANDLE;
new Handle:cvarFrametime    = INVALID_HANDLE;
new Handle:cvarUseNiceHud   = INVALID_HANDLE;
new Handle:cvarHudColor     = INVALID_HANDLE;

// Engine cvars
new Handle:cvarFriction         = INVALID_HANDLE;
new Handle:cvarStopspeed        = INVALID_HANDLE;
new Handle:cvarAccelerate       = INVALID_HANDLE;
new Handle:cvarAirAccelerate    = INVALID_HANDLE;

// Sync HUD handle
new Handle:hndSpeedo = INVALID_HANDLE;

// Cookies
new Handle:cookieFov     = INVALID_HANDLE;
new Handle:cookieAutohop = INVALID_HANDLE;
new Handle:cookieSpeedo  = INVALID_HANDLE;

// Global settings
// (These are initialized in OnPluginStart())
new bool:gEnabled;
new bool:gAllowAutohop;
new bool:gDefaultSpeedo;
new bool:gDuckjump;
new bool:gDoubleDuck;
new bool:gUseNiceHud;
new Float:gSpeedcap;
new Float:gVirtFrametime;
new gHudColor[3];

new Float:sv_friction;
new Float:sv_stopspeed;
new Float:sv_accelerate;
new Float:sv_airaccelerate;

// Player data
// Arrays are 1 bigger than MAXPLAYERS for the convenience of not having to
// write client - 1 every time when using a client id as index.
new Float:clCustomMaxspeed  [MAXPLAYERS + 1];
new Float:clRealMaxspeed    [MAXPLAYERS + 1];
new Float:clBackupSpeed     [MAXPLAYERS + 1];
new Float:clOldAngle        [MAXPLAYERS + 1];
new Float:clVirtTicks       [MAXPLAYERS + 1];
new bool:clAutohop          [MAXPLAYERS + 1];
new bool:clShowSpeedo       [MAXPLAYERS + 1];
new bool:clInAir            [MAXPLAYERS + 1];
new bool:clLandframe        [MAXPLAYERS + 1];
new clOldButtons            [MAXPLAYERS + 1];

#if defined DEBUG
new Float:debugSpeed;
new Float:debugVel[3];
new Float:debugProj;
new Float:debugWishdir[2];
new Float:debugAcc;
new Float:debugFrictionDrop;
new Float:debugEyeAngle;
new debugAngle;
new debugVirtTicks;
#endif

public Plugin:myinfo = {
    name            = "Classic Movement",
    author          = "mphe",
    description     = "Quake/Half-Life 1 like movement",
    version         = PLUGIN_VERSION,
    url             = "https://github.com/mphe/TF2-ClassicMovement"
};
// }}}

// Commands {{{
public Action:ToggleAutohop(client, args)
{
    if (!gEnabled)
        return Plugin_Continue;

    if (gAllowAutohop)
    {
        if (HandleBoolCommand(client, args, "sm_autohop", clAutohop))
        {
            if (clAutohop[client])
                ReplyToCommand(client, "%s Autohopping enabled", PLUGIN_PREFIX);
            else
                ReplyToCommand(client, "%s Autohopping disabled", PLUGIN_PREFIX);

            SetCookieInt(client, cookieAutohop, clAutohop[client]);
        }
    }
    else
    {
        ReplyToCommand(client, "%s Autohopping is disabled on this server", PLUGIN_PREFIX);
    }
    return Plugin_Handled;
}

public Action:ToggleSpeedo(client, args)
{
    if (!gEnabled)
        return Plugin_Continue;

    if (HandleBoolCommand(client, args, "sm_speed", clShowSpeedo))
    {
#if !defined DEBUG
        if (gUseNiceHud)
            ClearSyncHud(client, hndSpeedo);
        else
#endif
            PrintCenterText(client, "");

        SetCookieInt(client, cookieSpeedo, clShowSpeedo[client]);
    }
    return Plugin_Handled;
}

public Action:CmdSetFov(client, args)
{
    if (!gEnabled)
        return Plugin_Continue;

    if (args > 0)
    {
        new String:buf[7];
        GetCmdArg(1, buf, sizeof(buf));

        if (StrEqual(buf, "reset", false))
        {
            ReplyToCommand(client, "%s Reset takes effect after respawn", PLUGIN_PREFIX);
            SetCookieInt(client, cookieFov, 0);
            return Plugin_Handled;
        }

        new fov = StringToInt(buf);
        if (fov > 0)
        {
            SetFov(client, fov);
            SetCookieInt(client, cookieFov, fov);
            return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "%s Syntax: sm_fov <number|reset>", PLUGIN_PREFIX);
    return Plugin_Handled;
}
// }}}

// Convar changed hooks {{{
public ChangeEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
    gEnabled = GetConVarBool(convar);
}

public ChangeSpeedo(Handle:convar, const String:oldValue[], const String:newValue[])
{
    gDefaultSpeedo = GetConVarBool(convar);
}

public ChangeDuckJump(Handle:convar, const String:oldValue[], const String:newValue[])
{
    gDuckjump = GetConVarBool(convar);
}

public ChangeDoubleDuck(Handle:convar, const String:oldValue[], const String:newValue[])
{
    gDoubleDuck = GetConVarBool(convar);
}

public ChangeAutohop(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (gAllowAutohop != GetConVarBool(convar))
    {
        gAllowAutohop = GetConVarBool(convar);
        for (new i = 1; i <= MaxClients; i++)
            clAutohop[i] = gAllowAutohop;
    }
}

public ChangeMaxspeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
    gSpeedcap = GetConVarFloat(convar);
}

public ChangeFrametime(Handle:convar, const String:oldValue[], const String:newValue[])
{
    gVirtFrametime = GetConVarFloat(convar);
    if (gVirtFrametime < 0.0 || gVirtFrametime >= GetTickInterval())
    {
        gVirtFrametime = 0.0;
        LogError("%s Virtual frametime negative or too high -> disabled.", PLUGIN_PREFIX);
    }

    for (new i = 1; i <= MaxClients; i++)
        clVirtTicks[i] = 0.0;
}

public ChangeHudType(Handle:convar, const String:oldValue[], const String:newValue[])
{
    gUseNiceHud = GetConVarBool(convar);

    if (gUseNiceHud && hndSpeedo == INVALID_HANDLE)
    {
        hndSpeedo = CreateHudSynchronizer();
        if (hndSpeedo == INVALID_HANDLE)
            gUseNiceHud = false;
    }
}

public ChangeHudColor(Handle:convar, const String:oldValue[], const String:newValue[])
{
    new String:color[21], String:values[3][4];
    GetConVarString(convar, color, 20);

    new num = ExplodeString(color, " ", values, 3, 4, false);

    for (new i = 0; i < num; i++)
        gHudColor[i] = StringToInt(values[i]);
}

public ChangeFriction(Handle:convar, const String:oldValue[], const String:newValue[])
{
    sv_friction = GetConVarFloat(convar);
}

public ChangeStopspeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
    sv_stopspeed = GetConVarFloat(convar);
}

public ChangeAccelerate(Handle:convar, const String:oldValue[], const String:newValue[])
{
    sv_accelerate = GetConVarFloat(convar);
}

public ChangeAirAccelerate(Handle:convar, const String:oldValue[], const String:newValue[])
{
    sv_airaccelerate = GetConVarFloat(convar);
}
// }}}

// Init Events {{{
public OnPluginStart()
{
    RegConsoleCmd("sm_speed", ToggleSpeedo, "Toggle speedometer on/off");
    RegConsoleCmd("sm_autohop", ToggleAutohop, "Toggle autohopping on/off");
    RegConsoleCmd("sm_fov", CmdSetFov, "Set Field of View to a custom value");

    cookieFov     = RegClientCookie("cm_cookie_fov", "FOV", CookieAccess_Protected);
    cookieAutohop = RegClientCookie("cm_cookie_autohop", "Autohop", CookieAccess_Protected);
    cookieSpeedo  = RegClientCookie("cm_cookie_speedo", "Speedometer", CookieAccess_Protected);

    CreateConVar("classicmovement_version", PLUGIN_VERSION, "Classic Movement version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    cvarEnabled    = CreateConVar("cm_enabled",       "1", "Enable/Disable Classic Movement.");
    cvarAutohop    = CreateConVar("cm_allow_autohop", "1", "Allow users to jump automatically by holding jump.");
    cvarSpeedo     = CreateConVar("cm_speedo",        "0", "Show speedometer by default.");
    cvarDuckJump   = CreateConVar("cm_duckjump",      "1", "Allow jumping while being fully crouched.");
    cvarDoubleDuck = CreateConVar("cm_doubleduck",    "1", "Allow double ducking.");
    cvarMaxspeed   = CreateConVar("cm_speedcap",   "-1.0", "The maximum speed players can reach. -1 for unlimited.");
    cvarFrametime  = CreateConVar("cm_frametime", "0.009", "Virtual frametime (in seconds) to simulate a higher tickrate. 0 to disable. Values higher than 0.015 have no effect.");
    cvarUseNiceHud = CreateConVar("cm_use_nice_hud",  "1", "Whether or not to use a nicer speedometer HUD.");
    cvarHudColor   = CreateConVar("cm_hud_color", "255 255 0", "Speedometer HUD color. Syntax: cm_hud_color \"R G B\"");

    cvarFriction      = FindConVar("sv_friction");
    cvarStopspeed     = FindConVar("sv_stopspeed");
    cvarAccelerate    = FindConVar("sv_accelerate");
    cvarAirAccelerate = FindConVar("sv_airaccelerate");

    sv_friction      = GetConVarFloat(cvarFriction);
    sv_stopspeed     = GetConVarFloat(cvarStopspeed);
    sv_accelerate    = GetConVarFloat(cvarAccelerate);
    sv_airaccelerate = GetConVarFloat(cvarAirAccelerate);

    HookConVarChange(cvarEnabled, ChangeEnabled);
    HookConVarChange(cvarAutohop, ChangeAutohop);
    HookConVarChange(cvarSpeedo, ChangeSpeedo);
    HookConVarChange(cvarDuckJump, ChangeDuckJump);
    HookConVarChange(cvarDoubleDuck, ChangeDoubleDuck);
    HookConVarChange(cvarMaxspeed, ChangeMaxspeed);
    HookConVarChange(cvarFrametime, ChangeFrametime);
    HookConVarChange(cvarUseNiceHud, ChangeHudType);
    HookConVarChange(cvarHudColor, ChangeHudColor);
    HookConVarChange(cvarFriction, ChangeFriction);
    HookConVarChange(cvarStopspeed, ChangeStopspeed);
    HookConVarChange(cvarAccelerate, ChangeAccelerate);
    HookConVarChange(cvarAirAccelerate, ChangeAirAccelerate);

    // Trigger a change to update/initialize variables.
    ChangeEnabled       (cvarEnabled, "", "");
    ChangeAutohop       (cvarAutohop, "", "");
    ChangeSpeedo        (cvarSpeedo, "", "");
    ChangeDuckJump      (cvarDuckJump, "", "");
    ChangeDoubleDuck    (cvarDoubleDuck, "", "");
    ChangeMaxspeed      (cvarMaxspeed, "", "");
    ChangeFrametime     (cvarFrametime, "", "");
    ChangeHudType       (cvarUseNiceHud, "", "");
    ChangeHudColor      (cvarHudColor, "", "");

    ChangeFriction      (cvarFriction, "", "");
    ChangeStopspeed     (cvarStopspeed, "", "");
    ChangeAccelerate    (cvarAccelerate, "", "");
    ChangeAirAccelerate (cvarAirAccelerate, "", "");

    AutoExecConfig(true);

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
            SetupClient(i);

        if (AreClientCookiesCached(i))
            LoadCookies(i);
    }
}

public OnClientPutInServer(client)
{
    SetupClient(client);
}

public OnClientCookiesCached(client)
{
    LoadCookies(client);
}

public OnSpawnPost(client)
{
    UpdateFov(client);
}
// }}}

// Main {{{
public OnPreThink(client)
{
    if (!gEnabled || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    clRealMaxspeed[client] = GetMaxSpeed(client);

    new buttons = GetClientButtons(client);
    decl Float:vel[3], Float:wishdir[3];
    GetVelocity(client, vel);
    GetWishdir(client, buttons, wishdir);

    // Check if the fov was reset by zooming
    if (buttons & IN_ATTACK2 && GetEntProp(client, Prop_Send, "m_iFOV") == 0)
        UpdateFov(client);

    CheckGround(client);
    HandleJumping(client, buttons, vel);
    HandleDoubleDucking(client, buttons);
    DoInterpolation(client, buttons, wishdir, vel);

    if (!clInAir[client])
        DoMovement(client, vel, wishdir, true);

    clOldButtons[client] = buttons;

#if defined DEBUG
    for (new i = 0; i < 2; i++)
        debugWishdir[i] = wishdir[i];
    for (new i = 0; i < 3; i++)
        debugVel[i] = vel[i];
    decl Float:dir[3];
    GetClientEyeAngles(client, dir);
    debugEyeAngle = dir[1];
    debugAngle = RoundFloat(FloatAbs(dir[1])) % 45; // For testing wallstrafing
    if (debugAngle > 30)
        debugAngle = 45 - debugAngle;
#endif
}

public OnPostThink(client)
{
    if (!gEnabled || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    // Catch weapon related speed boosts (they don't appear in PreThink)
    if (GetMaxSpeed(client) != clCustomMaxspeed[client])
        clRealMaxspeed[client] = GetMaxSpeed(client);

    decl Float:vel[3];
    GetVelocity(client, vel);

    // Speed correction
    {
        new Float:speed = GetAbsVec(vel);

        // Restore speed if above 520
        if (!clInAir[client] && clBackupSpeed[client] > 520.0)
        {
            ScaleVec(vel, clBackupSpeed[client] / speed);
            DoFriction(client, vel);
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
        }
        else if (gSpeedcap >= 0.0 && speed > gSpeedcap) // Cap speed
        {
            ScaleVec(vel, gSpeedcap / speed);
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
        }
    }

    ShowSpeedo(client, vel);

    // Reset max speed
    SetMaxSpeed(client, clRealMaxspeed[client]);
}

DoMovement(client, Float:vel[3], const Float:wishdir[3], bool:handleMaxspeed)
{
    new Float:speed = GetAbsVec(vel);

    clBackupSpeed[client] = speed;

    if (speed == 0.0)
        return;

    if (wishdir[0] != 0.0 || wishdir[1] != 0.0)
    {
        DoFriction(client, vel);
        Accelerate(client, vel, wishdir);
    }

    speed = GetAbsVec(vel);

    if (handleMaxspeed && speed > clRealMaxspeed[client])
    {
        // Set calculated speed as new maxspeed to limit the engine in its
        // acceleration, but also to prevent capping.
        if (FloatAbs(speed - clRealMaxspeed[client]) > 0.1)
        {
            clCustomMaxspeed[client] = speed;
            SetMaxSpeed(client, speed);
        }

#if defined DEBUG
        debugSpeed = speed;
#endif
    }

    // NOTE:
    // There's a small bug, that occurs only when the virtual
    // frametime is so small that the virtual acceleration
    // (during airtime) returned by GetAcceleration() is smaller
    // than 30.
    // Usually (up to a frametime of 0.009375, with
    // sv_airaccelerate 10) it doesn't matter, because the
    // acceleration is higher than 30. Therefore virtual
    // acceleration and real acceleration (as calculated by the
    // engine) come to the same result: 30.
    // But, since there's no way to change the air cap to enforce a
    // lower acceleration (because it's hardcoded in the engine),
    // the engine will use 30 instead of the lower virtual value.
    // This is basically impossible to notice, though, especially
    // with these high interpolation rates.
    // It could be fixed by setting the maxspeed to 0, to prevent
    // the engine from doing any movement, and then setting the
    // velocity using TeleportEntity(), but that seems a bit too
    // overkill.
    // maxspeed can't be set to the needed value because that would
    // interfere with the acceleration calculation.
}

DoInterpolation(client, buttons, const Float:wishdir[3], Float:vel[3])
{
#if defined DEBUG
    debugVirtTicks = 0;
#endif

    if (gVirtFrametime == 0.0)
        return;

    new Float:angle = GetVecAngle(wishdir);

    // Extract movement keys
    new mvbuttons = buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT),
        oldmvbuttons = clOldButtons[client] & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT);

    if (clInAir[client] && !InWater(client)
            && mvbuttons == oldmvbuttons
            && (wishdir[0] != 0 || wishdir[1] != 0))
    {
        // Subtract one for the current frame.
        clVirtTicks[client] += (GetTickInterval() / gVirtFrametime) - 1;

        if (clVirtTicks[client] >= 1.0)
        {
            new ticks = RoundToFloor(clVirtTicks[client]);
            clVirtTicks[client] -= ticks;

            // Angles must be converted to 0-360 range -> +180
            new Float:step = GetAngleDiff(180.0 + clOldAngle[client],
                    180.0 + angle) / (ticks + 1);

            if (step != 0.0)
            {
                new Float:intwishdir[3];
                for (new i = 1; i <= ticks; i++)
                {
                    VecFromAngle(clOldAngle[client] + step * i, intwishdir);
                    DoMovement(client, vel, intwishdir, false);
                }
                TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);

#if defined DEBUG
                debugVirtTicks = ticks;
#endif
            }
        }
    }
    clOldAngle[client] = angle;
}

// Handles jumping while fully crouched and autohopping
HandleJumping(client, buttons, Float:vel[3])
{
    if (!clInAir[client] && buttons & IN_JUMP)
    {
        // Jumping while crouching or pressing jump while landing?
        if ((gDuckjump && !(clOldButtons[client] & IN_JUMP) && buttons & IN_DUCK)
                || (clAutohop[client] && clLandframe[client]))
        {
            vel[2] = JUMP_SPEED;
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
        }
    }
}

// Replicates double ducking
// http://tastools.readthedocs.io/en/latest/basicphy.html#ducking-physics
HandleDoubleDucking(client, buttons)
{
    if (!gDoubleDuck)
        return;

    if (clOldButtons[client] & IN_DUCK && buttons & IN_DUCK == 0
            && GetDuckState(client) == 1)
    {
        decl Float:origin[3], Float:dest[3], Float:mins[3], Float:maxs[3];
        GetClientAbsOrigin(client, origin);
        GetClientAbsOrigin(client, dest);
        GetClientMins(client, mins);
        GetClientMaxs(client, maxs);
        dest[2] += DOUBLE_DUCK_HEIGHT_OFFSET +
            DOUBLE_DUCK_HEIGHT * GetEntPropFloat(client, Prop_Send, "m_flModelScale");

        TR_TraceHullFilter(origin, dest, mins, maxs, MASK_SOLID, TR_FilterSelf, client);

        if (!TR_DidHit(INVALID_HANDLE))
            TeleportEntity(client, dest, NULL_VECTOR, NULL_VECTOR);
    }
}

// Performs friction calculation on a given speed vector.
// More or less the same code as in the Quake/GoldSrc/Source engine.
// https://github.com/id-Software/Quake/blob/master/QW/client/pmove.c#L324
DoFriction(client, Float:vel[3])
{
    if (clInAir[client] || clLandframe[client])
        return;

    new Float:speed = GetAbsVec(vel);

    if (speed > 1)
    {
        new Float:drop = GetFrictionDrop(client, speed);
        new Float:scale = (speed - drop) / speed;
        if (scale < 0.0)
            scale = 0.0;
        ScaleVec(vel, scale);

#if defined DEBUG
        debugFrictionDrop = drop;
#endif
    }
}

ShowSpeedo(client, const Float:vel[3])
{
    if (clShowSpeedo[client])
    {
#if defined DEBUG
        PrintCenterText(client, "realvel: %f\n%f\n%f\npredicted: %f\nmaxspeed: %f, %f\nproj: %f\nwishdir: (%f;%f)\nacc: %f\ndrop: %f\neye angle: %f, %i\ninterpolated frames: %i, %f",
                GetAbsVec(vel), vel[0], vel[1],
                debugSpeed,
                clRealMaxspeed[client], GetMaxSpeed(client),
                debugProj,
                debugWishdir[0], debugWishdir[1],
                debugAcc,
                debugFrictionDrop,
                debugEyeAngle, debugAngle,
                debugVirtTicks, clVirtTicks[client]
                );
#else
        if (gUseNiceHud)
        {
            SetHudTextParams(-1.0, 0.8, 5.0, gHudColor[0], gHudColor[1], gHudColor[2], 255);
            ShowSyncHudText(client, hndSpeedo, "%i", RoundFloat(GetAbsVec(vel)));
        }
        else
        {
            PrintCenterText(client, "%i", RoundFloat(GetAbsVec(vel)));
        }
#endif
    }
}

// Basically the same accelerate code as in the Quake/GoldSrc/Source engine.
// https://github.com/id-Software/Quake/blob/master/QW/client/pmove.c#L390
Accelerate(client, Float:vel[3], const Float:wishdir[3])
{
    new Float:maxspeed = clRealMaxspeed[client];

    if (clInAir[client] && maxspeed > AIR_CAP)
        maxspeed = AIR_CAP;

    new Float:currentspeed = DotProduct(vel, wishdir);
    new Float:addspeed = maxspeed - currentspeed;

    if (addspeed < 0)
        return;

    new Float:acc = GetAcceleration(client, clRealMaxspeed[client]);

    if (acc > addspeed)
        acc = addspeed;

    for (new i = 0; i < 2; i++)
        vel[i] += wishdir[i] * acc;

#if defined DEBUG
    debugProj = currentspeed;
    debugAcc = acc;
#endif
}

// Check if player is on ground and update related variables.
CheckGround(client)
{
    if (GetEntityFlags(client) & FL_ONGROUND)
    {
        clLandframe[client] = false;
        if (clInAir[client])    // Just landed on ground
        {
            clInAir[client] = false;
            clLandframe[client] = true;
        }
    }
    else
    {
        clInAir[client] = true;
    }
}
// }}}

// Helper functions {{{
// Movement related {{{

// Calculate the friction to subtract for a certain speed.
// (gVirtFrametime is not needed at this point, because there's no friction
// in the air)
Float:GetFrictionDrop(client, Float:speed)
{
    new Float:friction = sv_friction * GetFriction(client);
    new Float:control = (speed < sv_stopspeed) ? sv_stopspeed : speed;
    return (control * friction * GetTickInterval());
}

// Calculate the acceleration based on a given maxspeed.
Float:GetAcceleration(client, Float:maxspeed)
{
    // Water can be ignored I think (at least it works without special treatment)
    new Float:frametime;
    if (clInAir[client] && gVirtFrametime != 0.0)
        frametime = gVirtFrametime;
    else
        frametime = GetTickInterval();

    return (clInAir[client] ? sv_airaccelerate : sv_accelerate)
        * frametime * maxspeed * GetFriction(client);
}

// Fills the fwd and right vector with a normalized vector pointing in the
// direction the client is looking and the right of it.
// fwd and right must be 3D vectors, although their z value is always zero.
GetViewAngle(client, Float:fwd[3], Float:right[3])
{
    GetClientEyeAngles(client, fwd);
    VecFromAngle(fwd[1], fwd);
    right[0] = fwd[1];
    right[1] = -fwd[0];
    fwd[2] = right[2] = 0.0;
}

// Fills wishdir with a normalized vector pointing in the direction the
// player wants to move in.
GetWishdir(client, buttons, Float:wishdir[3])
{
    decl Float:fwd[3], Float:right[3];
    GetViewAngle(client, fwd, right);

    wishdir[0] = wishdir[1] = wishdir[2] = 0.0;

    if (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVERIGHT || buttons & IN_MOVELEFT)
    {
        if (buttons & IN_FORWARD)
            AddVectors(wishdir, fwd, wishdir);
        if (buttons & IN_BACK)
            SubtractVectors(wishdir, fwd, wishdir);
        if (buttons & IN_MOVERIGHT)
            AddVectors(wishdir, right, wishdir);
        if (buttons & IN_MOVELEFT)
            SubtractVectors(wishdir, right, wishdir);

        NormalizeVector(wishdir, wishdir);
    }
}

GetDuckState(client)
{
    new ducked = GetEntityFlags(client) & FL_DUCKING;
    new ducking = GetEntProp(client, Prop_Send, "m_bDucking");

    if (!ducking && !ducked) // Standing
        return 0;
    if (ducking && !ducked)  // Ducking in progress
        return 1;
    if (!ducking && ducked)  // Fully crouched
        return 2;
    return 3; // Standing up after being fully crouched
}
// }}}

// Setup, Variables, Misc, ... {{{
SetupClient(client)
{
    if (IsFakeClient(client) || client < 1 || client > MAXPLAYERS)
        return;

    clCustomMaxspeed[client] = 0.0;
    clVirtTicks[client] = 0.0;
    clOldButtons[client] = 0;

    SDKHook(client, SDKHook_PreThink, OnPreThink);
    SDKHook(client, SDKHook_PostThink, OnPostThink);
    SDKHook(client, SDKHook_SpawnPost, OnSpawnPost);
}

LoadCookies(client)
{
    if (IsFakeClient(client) || client < 1 || client > MAXPLAYERS)
        return;

    clShowSpeedo[client] = !!GetCookieInt(client, cookieSpeedo, gDefaultSpeedo);

    if (IsClientInGame(client))
        UpdateFov(client);

    if (gAllowAutohop)
        clAutohop[client] = !!GetCookieInt(client, cookieAutohop, 1);
}

GetVelocity(client, Float:vel[3])
{
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
}

Float:GetFriction(client)
{
    // Not sure if this will ever be different than 1.0
    return GetEntPropFloat(client, Prop_Data, "m_flFriction");
}

bool:InWater(client)
{
    // Double negate to avoid tag mismatch warning
    return !!(GetEntityFlags(client) & FL_INWATER);
}

Float:GetMaxSpeed(client)
{
    return GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
}

Float:SetMaxSpeed(client, Float:speed)
{
    SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
}

SetFov(client, fov)
{
    if (fov > 0)
    {
        SetEntProp(client, Prop_Send, "m_iFOV", fov);
        SetEntProp(client, Prop_Send, "m_iDefaultFOV", fov);
    }
}

UpdateFov(client)
{
    SetFov(client, GetCookieInt(client, cookieFov, 0));
}

bool:HandleBoolCommand(client, args, const String:cmd[], bool:variable[])
{
    if (args == 0)
        variable[client] = !variable[client];
    else
    {
        new String:buf[5];
        GetCmdArg(1, buf, sizeof(buf));

        if (StrEqual(buf, "on", false))
            variable[client] = true;
        else if (StrEqual(buf, "off", false))
            variable[client] = false;
        else
        {
            ReplyToCommand(client, "%s Syntax: %s [on|off]", PLUGIN_PREFIX, cmd);
            return false;
        }
    }

    return true;
}

GetCookieInt(client, Handle:cookie, def)
{
    decl String:buf[12];
    GetClientCookie(client, cookie, buf, sizeof(buf));
    return StrEqual(buf, "") ? def : StringToInt(buf);
}

SetCookieInt(client, Handle:cookie, val)
{
    decl String:buf[12];
    IntToString(val, buf, sizeof(buf));
    SetClientCookie(client, cookie, buf);
}

public bool:TR_FilterSelf(ent, mask, any:data)
{
    return ent != data;
}
// }}}

// Math {{{

// Returns the smallest signed difference between two angles.
// Input values must be between 0 and 360. Everything else is undefined.
Float:GetAngleDiff(Float:a, Float:b)
{
    new Float:diff = b - a;
    if (FloatAbs(diff) > 180)
        return sign(-diff) * (360.0 - FloatAbs(diff));
    return diff;
}

Float:sign(Float:x)
{
    return x < 0 ? -1.0 : x > 0 ? 1.0 : 0.0;
}

// 2D Vector functions {{{

ScaleVec(Float:vec[], Float:scale)
{
    vec[0] *= scale;
    vec[1] *= scale;
}

Float:DotProduct(const Float:a[], const Float:b[])
{
    return a[0] * b[0] + a[1] * b[1];
}

Float:GetAbsVec(const Float:a[])
{
    return SquareRoot(a[0] * a[0] + a[1] * a[1]);
}

Float:GetVecAngle(const Float:vec[])
{
    return RadToDeg(ArcTangent2(vec[1], vec[0]));
}

VecFromAngle(Float:angle, Float:vec[])
{
    vec[0] = Cosine(DegToRad(angle));
    vec[1] = Sine(DegToRad(angle));
}
// }}}
// }}}
// }}}

// vim: filetype=sourcepawn foldmethod=marker
