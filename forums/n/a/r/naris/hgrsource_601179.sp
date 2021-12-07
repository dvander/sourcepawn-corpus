/* 
 * vim: set ai et ts=4 sw=4 :
 * File: hgrsource.sp
 * Description: Allows admins (or all players) to hook on to walls,
 *              grab other players, or swing on a rope
 * Author: SumGuy14 (Aka SoccerDude)
 * Modifications by: Naris (Murray Wilson)
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define ACTION_HOOK 0
#define ACTION_GRAB 1
#define ACTION_ROPE 2

#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

#define VERSION "2.1.3d"

public Plugin:myinfo = 
{
    name = "HGR:Source",
    author = "SumGuy14 (Aka Soccerdude)",
    description = "Allows admins (or all players) to hook on to walls, grab other players, or swing on a rope",
    version = VERSION,
    url = "http://sourcemod.net/"
};

// General handles
new Handle:cvarAnnounce;
// Sound handles
new Handle:cvarGrabHitSound;
new Handle:cvarSeekingSound;
new Handle:cvarErrorSound;
new Handle:cvarPullSound;
new Handle:cvarDeniedSound;
new Handle:cvarFireSound;
new Handle:cvarHitSound;
// Hook handles
new Handle:cvarHookEnable;
new Handle:cvarHookAdminOnly;
new Handle:cvarHookSpeed;
new Handle:cvarHookBeamColor;
new Handle:cvarHookRed;
new Handle:cvarHookGreen;
new Handle:cvarHookBlue;
// Grab handles
new Handle:cvarGrabEnable;
new Handle:cvarGrabAdminOnly;
new Handle:cvarGrabSpeed;
new Handle:cvarGrabBeamColor;
new Handle:cvarGrabRed;
new Handle:cvarGrabGreen;
new Handle:cvarGrabBlue;
// Rope handles
new Handle:cvarRopeEnable;
new Handle:cvarRopeAdminOnly;
new Handle:cvarRopeSpeed;
new Handle:cvarRopeBeamColor;
new Handle:cvarRopeRed;
new Handle:cvarRopeGreen;
new Handle:cvarRopeBlue;
// Forward handles
new Handle:fwdOnGrab;
new Handle:fwdOnDrop;

// Client status arrays
new bool:gStatus[MAXPLAYERS+1][3];

// Hook array
new Float:gHookEndloc[MAXPLAYERS+1][3];

// Grab arrays
new gTargetIndex[MAXPLAYERS+1];
new Float:gGrabDist[MAXPLAYERS+1];
new bool:gGrabbed[MAXPLAYERS+1];
new gGrabCounter[MAXPLAYERS+1];
new Float:gMaxSpeed[MAXPLAYERS+1];

// Rope arrays
new Float:gRopeEndloc[MAXPLAYERS+1][3];
new Float:gRopeDist[MAXPLAYERS+1];

// Clients that have access to hook, grab or rope
new bool:gAllowedClients[MAXPLAYERS+1][3];
new Float:gAllowedRange[MAXPLAYERS+1][3];
new Float:gCooldown[MAXPLAYERS+1][3];
new Float:gLastUsed[MAXPLAYERS+1][3];
new gAllowedDuration[MAXPLAYERS+1][3];
new gRemainingDuration[MAXPLAYERS+1];
new gFlags[MAXPLAYERS+1][3];

// Offset variables
new gGetVelocityOffset;

// Precache variables
new precache_laser;

// Native interface settings
new bool:g_bNativeOverride = false;
new g_iNativeHooks;
new g_iNativeGrabs;
new g_iNativeRopes;

// Sounds
new String:grabberHitWav[PLATFORM_MAX_PATH] = "sourcecraft/zluhit00.mp3"; // "weapons/crossbow/bolt_skewer1.wav";
new String:pullerWav[PLATFORM_MAX_PATH] = "sourcecraft/intonydus.mp3"; // "weapons/crowwbow/hitbod2.wav";
new String:deniedWav[PLATFORM_MAX_PATH] = "sourcecraft/buzz.wav"; // "buttons/combine_button_locked.wav";
new String:errorWav[PLATFORM_MAX_PATH] = "sourcecraft/perror.mp3"; // "player/suit_denydevice.wav";
new String:seekingWav[PLATFORM_MAX_PATH] = "sourcecraft/ropeshoot2.wav"; // "weapons/crossbow/bolt_fly4.wav"; // "weapons/tripwire/ropeshoot.wav";
new String:fireWav[PLATFORM_MAX_PATH] = "weapons/crossbow/fire1.wav";
new String:hitWav[PLATFORM_MAX_PATH] = "weapons/crossbow/hit1.wav";

enum HGRSourceAction
{
    Hook = 0, /** User is using hook */
    Grab = 1, /** User is using grab */
    Rope = 2, /** User is using rope */
};

enum HGRSourceAccess
{
    Give = 0, /** Gives access to user */
    Take = 1, /** Takes access from user */
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlHookGrabRope",Native_ControlHookGrabRope);

    CreateNative("GiveHook",Native_GiveHook);
    CreateNative("TakeHook",Native_TakeHook);

    CreateNative("GiveGrab",Native_GiveGrab);
    CreateNative("TakeGrab",Native_TakeGrab);

    CreateNative("GiveRope",Native_GiveRope);
    CreateNative("TakeRope",Native_TakeRope);

    CreateNative("Hook",Native_Hook);
    CreateNative("UnHook",Native_UnHook);
    CreateNative("HookToggle",Native_HookToggle);

    CreateNative("Grab",Native_Grab);
    CreateNative("Drop",Native_Drop);
    CreateNative("GrabToggle",Native_GrabToggle);

    CreateNative("Rope",Native_Rope);
    CreateNative("Detach",Native_Detach);
    CreateNative("RopeToggle",Native_RopeToggle);

    fwdOnGrab=CreateGlobalForward("OnGrab",ET_Hook,Param_Cell,Param_Cell);
    fwdOnDrop=CreateGlobalForward("OnDrop",ET_Ignore,Param_Cell,Param_Cell);

    return true;
}

public OnPluginStart()
{
    PrintToServer("----------------|         HGR:Source Loading        |---------------");

    // Hook events
    HookEvent("player_spawn",PlayerSpawnEvent);

    // Register client cmds
    RegConsoleCmd("+hook",HookCmd);
    RegConsoleCmd("-hook",UnHookCmd);
    RegConsoleCmd("hook_toggle",HookToggle);

    RegConsoleCmd("+grab",GrabCmd);
    RegConsoleCmd("-grab",DropCmd);
    RegConsoleCmd("grab_toggle",GrabToggle);

    RegConsoleCmd("+rope",RopeCmd);
    RegConsoleCmd("-rope",DetachCmd);
    RegConsoleCmd("rope_toggle",RopeToggle);

    // Register admin cmds
    RegAdminCmd("hgrsource_givehook",GiveHook,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_takehook",TakeHook,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_givegrab",GiveGrab,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_takegrab",TakeGrab,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_giverope",GiveRope,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_takerope",TakeRope,ADMFLAG_GENERIC);

    // Find offsets
    gGetVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    if(gGetVelocityOffset==-1)
        SetFailState("[HGR:Source] Error: Failed to find the GetVelocity offset, aborting");

    // General cvars
    cvarAnnounce=CreateConVar("hgrsource_announce","1","This will enable announcements that the plugin is loaded");

    // Sound cvars
    cvarGrabHitSound = CreateConVar("hgrsource_grab_sound", grabberHitWav, "sound when grab hits", FCVAR_PLUGIN);
    cvarSeekingSound = CreateConVar("hgrsource_seeking_sound", seekingWav, "sound when grab is seeking a target", FCVAR_PLUGIN);
    cvarPullSound = CreateConVar("hgrsource_pull_sound", pullerWav, "sound when grab pulls", FCVAR_PLUGIN);
    cvarDeniedSound = CreateConVar("hgrsource_denied_sound", deniedWav, "access denied sound", FCVAR_PLUGIN);
    cvarErrorSound = CreateConVar("hgrsource_error_sound", errorWav, "error sound", FCVAR_PLUGIN);
    cvarFireSound = CreateConVar("hgrsource_fire_sound", fireWav, "sound when hook or rope or grab is fired", FCVAR_PLUGIN);
    cvarHitSound = CreateConVar("hgrsource_hit_sound", hitWav, "sound when hook or rope hits", FCVAR_PLUGIN);

    // Hook cvars
    cvarHookEnable=CreateConVar("hgrsource_hook_enable","1","This will enable the hook feature of this plugin");
    cvarHookAdminOnly=CreateConVar("hgrsource_hook_adminonly","1","If 1, only admins can use hook");
    cvarHookSpeed=CreateConVar("hgrsource_hook_speed","5.0","The speed of the player using hook");
    cvarHookBeamColor=CreateConVar("hgrsource_hook_color","1","The color of the hook, 0=White, 1=Team color, 2=custom");
    cvarHookRed=CreateConVar("hgrsource_hook_red","255","The red component of the beam (Only if you are using a custom color)");
    cvarHookGreen=CreateConVar("hgrsource_hook_green","0","The green component of the beam (Only if you are using a custom color)");
    cvarHookBlue=CreateConVar("hgrsource_hook_blue","0","The blue component of the beam (Only if you are using a custom color)");

    // Grab cvars
    cvarGrabEnable=CreateConVar("hgrsource_grab_enable","1","This will enable the grab feature of this plugin");
    cvarGrabAdminOnly=CreateConVar("hgrsource_grab_adminonly","1","If 1, only admins can use grab");
    cvarGrabSpeed=CreateConVar("hgrsource_grab_speed","5.0","The speed of the grabbers target");
    cvarGrabBeamColor=CreateConVar("hgrsource_grab_color","1","The color of the grab beam, 0=White, 1=Team color, 2=custom");
    cvarGrabRed=CreateConVar("hgrsource_grab_red","0","The red component of the beam (Only if you are using a custom color)");
    cvarGrabGreen=CreateConVar("hgrsource_grab_green","0","The green component of the beam (Only if you are using a custom color)");
    cvarGrabBlue=CreateConVar("hgrsource_grab_blue","255","The blue component of the beam (Only if you are using a custom color)");

    // Rope cvars
    cvarRopeEnable=CreateConVar("hgrsource_rope_enable","1","This will enable the rope feature of this plugin");
    cvarRopeAdminOnly=CreateConVar("hgrsource_rope_adminonly","1","If 1, only admins can use rope");
    cvarRopeSpeed=CreateConVar("hgrsource_rope_speed","5.0","The speed of the player using rope");
    cvarRopeBeamColor=CreateConVar("hgrsource_rope_color","1","The color of the rope, 0=White, 1=Team color, 2=custom");
    cvarRopeRed=CreateConVar("hgrsource_rope_red","0","The red component of the beam (Only if you are using a custom color)");
    cvarRopeGreen=CreateConVar("hgrsource_rope_green","255","The green component of the beam (Only if you are using a custom color)");
    cvarRopeBlue=CreateConVar("hgrsource_rope_blue","0","The blue component of the beam (Only if you are using a custom color)");

    // Auto-generate config
    AutoExecConfig();

    // Public cvar
    CreateConVar("hgrsource_version",VERSION,"[HGR:Source] Current version of this plugin",
                 FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

    PrintToServer("----------------|         HGR:Source Loaded         |---------------");
}

public OnMapStart()
{
    // Precache models
    precache_laser=PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnConfigsExecuted()
{
    // Precache & download sounds

    GetConVarString(cvarGrabHitSound, grabberHitWav, sizeof(grabberHitWav));
    SetupSound(grabberHitWav,true);

    GetConVarString(cvarSeekingSound, seekingWav, sizeof(seekingWav));
    SetupSound(seekingWav,true);

    GetConVarString(cvarDeniedSound, deniedWav, sizeof(deniedWav));
    SetupSound(deniedWav,true);

    GetConVarString(cvarErrorSound, errorWav, sizeof(errorWav));
    SetupSound(errorWav,true);

    GetConVarString(cvarPullSound, pullerWav, sizeof(pullerWav));
    SetupSound(pullerWav,true);

    GetConVarString(cvarFireSound, fireWav, sizeof(fireWav));
    SetupSound(fireWav,true);

    GetConVarString(cvarHitSound, hitWav, sizeof(hitWav));
    SetupSound(hitWav,true);
}

stock bool:SetupSound(const String:wav[], bool:preload=false)
{
    if (wav[0])
    {
        decl String:file[PLATFORM_MAX_PATH+1];
        Format(file, PLATFORM_MAX_PATH, "sound/%s", wav);

        if(FileExists(file))
            AddFileToDownloadsTable(file);

        return PrecacheSound(wav,preload);
    }
    else
        return false;
}

public OnClientDisconnect(client)
{
    if (client>0 && !IsFakeClient(client))
    {
        if (gStatus[client][ACTION_HOOK])
            Action_UnHook(client);
        else if (gStatus[client][ACTION_ROPE])
            Action_Detach(client);
        else if (gStatus[client][ACTION_GRAB])
            Action_Drop(client);
        else if (gGrabbed[client])
        {
            for(new x=0;x<MAXPLAYERS+1;x++)
            {
                if (gTargetIndex[x] == client)
                {
                    Action_Drop(client);
                    break;
                }
            }
        }

    }
}

/********
 *Events*
 *********/

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
    // Tell plugin they aren't using any of its features
    gStatus[index][ACTION_HOOK]=false;
    gStatus[index][ACTION_GRAB]=false;
    gStatus[index][ACTION_ROPE]=false;
    if(GetConVarBool(cvarAnnounce))
        PrintToChat(index,"%c[HGR:Source] %cIs enabled, valid commands are: [%c+hook%c] [%c+grab%c] [%c+rope%c]",
                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
}

/*********
 *Natives*
 **********/

public Native_ControlHookGrabRope(Handle:plugin,numParams)
{
    if (numParams == 0)
        g_bNativeOverride = true;
    else if(numParams == 1)
        g_bNativeOverride = GetNativeCell(1);
}

public Native_Hook(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
            Action_Hook(client);
    }
}

public Native_UnHook(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
            Action_UnHook(client);
    }
}

public Native_HookToggle(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            if(gStatus[client][ACTION_HOOK])
                gStatus[client][ACTION_HOOK]=false;
            else
                Action_Hook(client);
        }
    }
}

public Native_Grab(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
            Action_Grab(client);
    }
}

public Native_Drop(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
            Action_Drop(client);
    }
}

public Native_GrabToggle(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            if(gStatus[client][ACTION_GRAB])
                gStatus[client][ACTION_GRAB]=false;
            else
                Action_Grab(client);
        }
    }
}

public Native_Rope(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
            Action_Rope(client);
    }
}

public Native_Detach(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
            Action_Detach(client);
    }
}

public Native_RopeToggle(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            if(gStatus[client][ACTION_ROPE])
                gStatus[client][ACTION_ROPE]=false;
            else
                Action_Rope(client);
        }
    }
}

public Native_GiveHook(Handle:plugin,numParams)
{
    if(numParams >= 1 && numParams <= 5)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            new duration=0,Float:range=0.0,Float:cooldown=0.0,flags=0;
            if (numParams >= 2)
                duration = GetNativeCell(2);
            if (numParams >= 3)
                range = Float:GetNativeCell(3);
            if (numParams >= 4)
                cooldown = Float:GetNativeCell(4);
            if (numParams >= 5)
                flags = GetNativeCell(5);
            ClientAccess(client,Give,Hook,duration,range,cooldown,flags);
            g_iNativeHooks++;
        }
    }
}

public Native_TakeHook(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            ClientAccess(client,Take,Hook,0,0.0,0.0,0);
            g_iNativeHooks--;
        }
    }
}

public Native_GiveGrab(Handle:plugin,numParams)
{
    if(numParams >= 1 && numParams <= 5)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            new duration=0,Float:range=0.0,Float:cooldown=0.0,flags=0;
            if (numParams >= 2)
                duration = GetNativeCell(2);
            if (numParams >= 3)
                range = Float:GetNativeCell(3);
            if (numParams >= 4)
                cooldown = Float:GetNativeCell(4);
            if (numParams >= 5)
                flags = GetNativeCell(5);
            ClientAccess(client,Give,Grab,duration,range,cooldown,flags);
            g_iNativeGrabs++;
        }
    }
}

public Native_TakeGrab(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            ClientAccess(client,Take,Grab,0,0.0,0.0,0);
            g_iNativeGrabs--;
        }
    }
}

public Native_GiveRope(Handle:plugin,numParams)
{
    if(numParams >= 1 && numParams <= 5)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            new duration=0,Float:range=0.0,Float:cooldown=0.0,flags=0;
            if (numParams >= 2)
                duration = GetNativeCell(2);
            if (numParams >= 3)
                range = Float:GetNativeCell(3);
            if (numParams >= 4)
                cooldown = Float:GetNativeCell(4);
            if (numParams >= 5)
                flags = GetNativeCell(5);
            ClientAccess(client,Give,Rope,duration,range,cooldown,flags);
            g_iNativeRopes++;
        }
    }
}

public Native_TakeRope(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        new client = GetNativeCell(1);
        if(IsPlayerAlive(client))
        {
            ClientAccess(client,Take,Rope,0,0.0,0.0,0);
            g_iNativeRopes--;
        }
    }
}

/******
 *Cmds*
 *******/

public Action:HookCmd(client,argc)
{
    Action_Hook(client);
    return Plugin_Handled;
}

public Action:UnHookCmd(client,argc)
{
    if(IsPlayerAlive(client))
        Action_UnHook(client);
    return Plugin_Handled;
}

public Action:HookToggle(client,argc)
{
    if(gStatus[client][ACTION_HOOK])
        gStatus[client][ACTION_HOOK]=false;
    else
        Action_Hook(client);
    return Plugin_Handled;
}

public Action:GrabCmd(client,argc)
{
    Action_Grab(client);
    return Plugin_Handled;
}

public Action:DropCmd(client,argc)
{
    if(IsPlayerAlive(client))
        Action_Drop(client);
    return Plugin_Handled;
}

public Action:GrabToggle(client,argc)
{
    if(gStatus[client][ACTION_GRAB])
        gStatus[client][ACTION_GRAB]=false;
    else
        Action_Grab(client);
    return Plugin_Handled;
}

public Action:RopeCmd(client,argc)
{
    Action_Rope(client);
    return Plugin_Handled;
}

public Action:DetachCmd(client,argc)
{
    if(IsPlayerAlive(client))
        Action_Detach(client);
    return Plugin_Handled;
}

public Action:RopeToggle(client,argc)
{
    if(gStatus[client][ACTION_ROPE])
        gStatus[client][ACTION_ROPE]=false;
    else
        Action_Rope(client);
    return Plugin_Handled;
}

/*******
 *Admin*
 ********/

public Action:GiveHook(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Hook) && IsFeatureAdminOnly(Hook))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Give,Hook);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_givehook <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:TakeHook(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Hook) && IsFeatureAdminOnly(Hook))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Take,Hook);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takehook <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:GiveGrab(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Grab) && IsFeatureAdminOnly(Grab))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Give,Grab);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_givegrab <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:TakeGrab(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Grab) && IsFeatureAdminOnly(Grab))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Take,Grab);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takegrab <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:GiveRope(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Rope) && IsFeatureAdminOnly(Rope))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Give,Rope);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_giverope <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:TakeRope(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Rope) && IsFeatureAdminOnly(Rope))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Take,Rope);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takerope <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

/********
 *Access*
 *********/

public Access(const String:target[],HGRSourceAccess:access,HGRSourceAction:action)
{
    new clients[MAXPLAYERS];
    new count=FindMatchingPlayers(target,clients);
    if(count==0)
        return 0;
    for(new x=0;x<count;x++)
        ClientAccess(clients[x],access,action,0,0.0,0.0,0);
    return count;
}

public ClientAccess(client,HGRSourceAccess:access,HGRSourceAction:action,duration,Float:range,Float:cooldown,flags)
{
    if(access==Give)
    {
        if(action==Hook)
        {
            gAllowedClients[client][ACTION_HOOK]=true;
            gAllowedDuration[client][ACTION_HOOK]=duration;
            gAllowedRange[client][ACTION_HOOK]=range;
            gCooldown[client][ACTION_HOOK]=cooldown;
            gFlags[client][ACTION_HOOK]=flags;
        }
        else if(action==Grab)
        {
            gAllowedClients[client][ACTION_GRAB]=true;
            gAllowedDuration[client][ACTION_GRAB]=duration;
            gAllowedRange[client][ACTION_GRAB]=range;
            gCooldown[client][ACTION_GRAB]=cooldown;
            gFlags[client][ACTION_GRAB]=flags;
        }
        else if(action==Rope)
        {
            gAllowedClients[client][ACTION_ROPE]=true;
            gAllowedDuration[client][ACTION_ROPE]=duration;
            gAllowedRange[client][ACTION_ROPE]=range;
            gCooldown[client][ACTION_ROPE]=cooldown;
            gFlags[client][ACTION_ROPE]=flags;
        }
    }
    else if(access==Take)
    {
        if(action==Hook)
            gAllowedClients[client][ACTION_HOOK]=false;
        else if(action==Grab)
            gAllowedClients[client][ACTION_GRAB]=false;
        else if(action==Rope)
            gAllowedClients[client][ACTION_ROPE]=false;
    }
}

public bool:HasAccess(client,HGRSourceAction:action)
{
    if (!g_bNativeOverride)
    {
        if(GetAdminFlag(GetUserAdmin(client),Admin_Generic,Access_Real)||
           GetAdminFlag(GetUserAdmin(client),Admin_Generic,Access_Effective)||
           GetAdminFlag(GetUserAdmin(client),Admin_Root,Access_Real)||
           GetAdminFlag(GetUserAdmin(client),Admin_Root,Access_Effective))
            return true;
        else if(!IsFeatureEnabled(action))
            return false;
        else if(!IsFeatureAdminOnly(action))
            return true;
    }

    if(action==Hook)
        return gAllowedClients[client][ACTION_HOOK];
    else if(action==Grab)
        return gAllowedClients[client][ACTION_GRAB];
    else if(action==Rope)
        return gAllowedClients[client][ACTION_ROPE];

    return false;
}

/******
 *CVar*
 *******/

public bool:IsFeatureEnabled(HGRSourceAction:action)
{
    if (g_bNativeOverride)
        return true;
    if(action==Hook)
        return g_iNativeHooks || GetConVarBool(cvarHookEnable);
    if(action==Grab)
        return g_iNativeGrabs || GetConVarBool(cvarGrabEnable);
    if(action==Rope)
        return g_iNativeRopes || GetConVarBool(cvarRopeEnable);
    return false;
}

public bool:IsFeatureAdminOnly(HGRSourceAction:action)
{
    if (g_bNativeOverride)
        return false;
    if(action==Hook)
        return GetConVarBool(cvarHookAdminOnly);
    if(action==Grab)
        return GetConVarBool(cvarGrabAdminOnly);
    if(action==Rope)
        return GetConVarBool(cvarRopeAdminOnly);
    return false;
}

public GetBeamColor(client,HGRSourceAction:action,color[4])
{
    new beamtype=0;
    new red=255;
    new green=255;
    new blue=255;
    if(action==Hook)
    {
        beamtype=GetConVarInt(cvarHookBeamColor);
        if(beamtype==2)
        {
            red=GetConVarInt(cvarHookRed);
            green=GetConVarInt(cvarHookGreen);
            blue=GetConVarInt(cvarHookBlue);
        }
    }
    else if(action==Grab)
    {
        beamtype=GetConVarInt(cvarGrabBeamColor);
        if(beamtype==2)
        {
            red=GetConVarInt(cvarGrabRed);
            green=GetConVarInt(cvarGrabGreen);
            blue=GetConVarInt(cvarGrabBlue);
        }
    }
    else if(action==Rope)
    {
        beamtype=GetConVarInt(cvarRopeBeamColor);
        if(beamtype==2)
        {
            red=GetConVarInt(cvarRopeRed);
            green=GetConVarInt(cvarRopeGreen);
            blue=GetConVarInt(cvarRopeBlue);
        }
    }
    if(beamtype==0)
    {
        color[0]=255;color[1]=255;color[2]=255;color[3]=255;
    }
    else if(beamtype==1)
    {
        if(GetClientTeam(client)==2)
        {
            color[0]=255;color[1]=0;color[2]=0;color[3]=255;
        }
        else if(GetClientTeam(client)==3)
        {
            color[0]=0;color[1]=0;color[2]=255;color[3]=255;
        }
    }
    else if(beamtype==2)
    {
        color[0]=red;color[1]=green;color[2]=blue;color[3]=255;
    }
}

/******
 *Hook*
 *******/

public Action_Hook(client)
{
    if(g_bNativeOverride || GetConVarBool(cvarHookEnable))
    {
        if (client>0)
        {
            if (IsPlayerAlive(client)&&!gStatus[client][ACTION_HOOK]&&!gStatus[client][ACTION_ROPE]&&!gGrabbed[client])
            {
                if (HasAccess(client,Hook))
                {
                    new Float:cooldown = gCooldown[client][ACTION_HOOK];
                    new Float:time     = GetGameTime() - gLastUsed[client][ACTION_HOOK];
                    LogMessage("Hook Client=%N, Cooldown=%f, Time=%f\n", client, cooldown, time);
                    if (cooldown <= 0.0 || ((GetGameTime() - gLastUsed[client][ACTION_HOOK]) >= cooldown))
                    {
                        EmitSoundToAll(fireWav, client); // Emit fire sound

                        new Float:clientloc[3],Float:clientang[3];
                        GetClientEyePosition(client,clientloc); // Get the position of the player's eyes
                        GetClientEyeAngles(client,clientang); // Get the angle the player is looking

                        TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite,TraceRayTryToHit); // Create a ray that tells where the player is looking
                        TR_GetEndPosition(gHookEndloc[client]); // Get the end xyz coordinate of where a player is looking

                        new Float:limit=gAllowedRange[client][ACTION_GRAB];
                        new Float:distance=GetDistanceBetween(clientloc,gHookEndloc[client]);
                        LogMessage("Hook Client=%N, Distance=%f, Max=%f\n", client, distance, limit);
                        if (limit == 0.0 || distance <= limit)
                        {
                            if (gRemainingDuration[client] <= 0)
                                gRemainingDuration[client] = gAllowedDuration[client][ACTION_HOOK];

                            gStatus[client][ACTION_HOOK]=true; // Tell plugin the player is hooking
                            SetEntPropFloat(client,Prop_Data,"m_flGravity",0.0); // Set gravity to 0 so client floats in a straight line
                            Hook_Push(client);
                            CreateTimer(0.1,Hooking,client,TIMER_REPEAT); // Create hooking loop
                            EmitSoundFromOrigin(hitWav,gHookEndloc[client]); // Emit sound from where the hook landed
                        }
                        else
                        {
                            EmitSoundToClient(client,errorWav);
                            PrintToChat(client,"%c[HGR:Source] %cTarget is too far away!",
                                        COLOR_GREEN,COLOR_DEFAULT);
                        }
                    }
                    else
                    {
                        EmitSoundToClient(client,errorWav);
                        PrintToChat(client,"%c[HGR:Source] %cYou have used the %chook%c too recently!",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                else if (g_bNativeOverride)
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have a %chook%c",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use the %chook%c",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
            }
        }
        else
        {
            EmitSoundToClient(client,deniedWav);
            PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
    {
        EmitSoundToClient(client,deniedWav);
        PrintToChat(client,"%c[HGR:Source] Hook %cis currently disabled",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public Hook_Push(client)
{
    new Float:clientloc[3],Float:velocity[3];
    GetClientAbsOrigin(client,clientloc); // Get the xyz coordinate of the player
    new color[4];
    clientloc[2]+=30.0;
    GetBeamColor(client,Hook,color);
    BeamEffect("@all",clientloc,gHookEndloc[client],0.2,5.0,5.0,color,0.0,0);
    GetForwardPushVec(clientloc,gHookEndloc[client],velocity); // Get how hard and where to push the client
    TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,velocity); // Push the client
    new Float:distance=GetDistanceBetween(clientloc,gHookEndloc[client]);
    if(distance<30.0)
    {
        SetEntityMoveType(client,MOVETYPE_NONE); // Freeze client
        SetEntPropFloat(client,Prop_Data,"m_flGravity",1.0); // Set grav to normal
    }
}

public Action:Hooking(Handle:timer,any:index)
{
    if(IsClientInGame(index)&&IsPlayerAlive(index)&&gStatus[index][ACTION_HOOK]&&!gGrabbed[index])
    {
        if (gRemainingDuration[index] > 0)
        {
            gRemainingDuration[index]--;
            if (gRemainingDuration[index] <= 0)
            {
                Action_UnHook(index);
                //CloseHandle(timer); // Stop the timer
                return Plugin_Stop;
            }
        }
        Hook_Push(index);
    }
    else
    {
        Action_UnHook(index);
        //CloseHandle(timer); // Stop the timer
        return Plugin_Stop;
    }
    return Plugin_Handled;
}

public Action_UnHook(client)
{
    gStatus[client][ACTION_HOOK]=false; // Tell plugin the client is not hooking
    gLastUsed[client][ACTION_HOOK]=GetGameTime(); // Tell plugin when client stopped hooking
    if (IsClientInGame(client))
    {
        SetEntPropFloat(client,Prop_Data,"m_flGravity",1.0); // Set grav to normal
        SetEntityMoveType(client,MOVETYPE_WALK); // Unfreeze client
    }
}

/******
 *Grab*
 *******/

public Action_Grab(client)
{
    if(g_bNativeOverride || GetConVarBool(cvarGrabEnable))
    {
        if(client>0)
        {
            if(IsPlayerAlive(client)&&!gStatus[client][ACTION_GRAB]&&!gGrabbed[client])
            {
                if(HasAccess(client,Grab))
                {
                    new Float:cooldown = gCooldown[client][ACTION_GRAB];
                    if (cooldown <= 0.0 || ((GetGameTime() - gLastUsed[client][ACTION_GRAB]) >= cooldown))
                    {
                        gStatus[client][ACTION_GRAB]=true; // Tell plugin the seeker is grabbing a player
                        EmitSoundToAll(fireWav, client); // Emit fire sound
                        CreateTimer(0.05,GrabSearch,client,TIMER_REPEAT); // Start a timer that searches for a client to grab
                    }
                    else
                    {
                        EmitSoundToClient(client,errorWav);
                        PrintToChat(client,"%c[HGR:Source] %cYou have used the %cgrabber%c too recently!",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                else if (g_bNativeOverride)
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have a %cgrabber%c",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use the %cgrab%c",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
            }
            else
            {
                EmitSoundToClient(client,deniedWav);
            }
        }
        else
        {
            EmitSoundToClient(client,deniedWav);
            PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",
                    COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
    {
        EmitSoundToClient(client,deniedWav);
        PrintToChat(client,"%c[HGR:Source] Grab %cis currently disabled",
                COLOR_GREEN,COLOR_DEFAULT);
    }
}

public Action:GrabSearch(Handle:timer,any:index)
{
    PrintCenterText(index,"Searching for a target..."); // Tell client the plugin is searching for a target
    if(IsClientInGame(index)&&IsPlayerAlive(index)&&gStatus[index][ACTION_GRAB]&&!gGrabbed[index])
    {
        new Float:clientloc[3],Float:clientang[3];
        GetClientEyePosition(index,clientloc); // Get seekers eye coordinate
        GetClientEyeAngles(index,clientang); // Get angle of where the player is looking
        TR_TraceRayFilter(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayGrabEnt); // Create a ray that tells where the player is looking
        new target = TR_GetEntityIndex(); // Set the seekers targetindex to the person he picked up
        if (target>0 && target<=GetMaxClients() && IsValidEntity(target) && IsClientInGame(target))
        {
            // Found something
            decl String:name[32] = "";
            if (GetEntityNetClass(target,name,sizeof(name)) && StrContains(name, "Player"))
            {
                // Found a player
                StopSound(index,SNDCHAN_AUTO,seekingWav);
                gGrabCounter[index]=0;

                new Float:targetloc[3];
                GetClientAbsOrigin(target,targetloc); // Find the target's xyz coordinate
                new Float:distance=GetDistanceBetween(clientloc,targetloc);
                new Float:limit=gAllowedRange[index][ACTION_GRAB];
                LogMessage("Grab Distance=%f, Max=%f, Client=%N\n", distance, limit, index);
                if (limit <= 0.0 || limit >= distance)
                {
                    new Action:res;
                    Call_StartForward(fwdOnGrab);
                    Call_PushCell(index);
                    Call_PushCell(target);
                    Call_Finish(res);
                    if (res == Plugin_Continue)
                    {
                        gGrabDist[index]=distance; // Tell plugin the distance between the 2 to maintain
                        EmitSoundFromOrigin(grabberHitWav,targetloc); // Emit sound from the entity being grabbed
                        SetEntPropFloat(target,Prop_Data,"m_flGravity",0.0); // Set gravity to 0 so the target moves around easy
                        if (gFlags[index][ACTION_GRAB] != 0) // Grabber is a Puller
                        {
                            gMaxSpeed[target] = GetEntPropFloat(target,Prop_Data,"m_flMaxspeed");
                            //SetEntPropFloat(target,Prop_Data,"m_flMaxspeed",100.0); // Slow the target down.
                        }

                        if (gRemainingDuration[index] <= 0)
                            gRemainingDuration[index] = gAllowedDuration[index][ACTION_GRAB];

                        gGrabbed[target]=true; // Tell plugin the target is being grabbed
                        gTargetIndex[index]=target;
                        CreateTimer(0.1,Grabbing,index,TIMER_REPEAT); // Start a repeating timer that will reposition the target in the grabber's crosshairs
                        return Plugin_Stop;
                    }
                }
                else
                {
                    Action_Drop(index);
                    EmitSoundToClient(index,errorWav);
                    PrintToChat(index,"%c[HGR:Source] %cTarget is too far away!",
                                COLOR_GREEN,COLOR_DEFAULT);
                }
                //CloseHandle(timer); // Stop the timer
                return Plugin_Stop;
            }
        }
        if (!gGrabCounter[index] || ++gGrabCounter[index] >= 100)
        {
            StopSound(index,SNDCHAN_AUTO,seekingWav);
            EmitSoundToClient(index,seekingWav);
            gGrabCounter[index]=1;
        }
    }
    else
    {
        Action_Drop(index);
        //CloseHandle(timer); // Stop the timer
        return Plugin_Stop;
    }
    return Plugin_Handled;
}

public Action:Grabbing(Handle:timer,any:index)
{
    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        PrintCenterText(index,"Target found, release key/toggle off to drop");
        if (gStatus[index][ACTION_GRAB]&&!gGrabbed[index])
        {
            new target = gTargetIndex[index];
            if (target > 0 && IsClientInGame(target) && IsPlayerAlive(target))
            {
                if (gRemainingDuration[index] > 0)
                {
                    gRemainingDuration[index]--;
                    if (gRemainingDuration[index] <= 0)
                    {
                        Action_Drop(index);
                        //CloseHandle(timer); // Stop the timer
                        return Plugin_Stop;
                    }
                }

                // Find where to push the target
                new Float:clientloc[3],Float:clientang[3],Float:targetloc[3],Float:endvec[3],Float:distance[3];
                GetClientAbsOrigin(index,clientloc);
                GetClientEyeAngles(index,clientang);
                GetClientAbsOrigin(target,targetloc);

                if (gFlags[index][ACTION_GRAB] != 0) // Grabber is a Puller
                {
                    // Adjust the distance if the target is closer, or drag the victim in.
                    new Float:targetDistance=GetDistanceBetween(clientloc,targetloc);
                    if (gGrabDist[index] > targetDistance)
                        gGrabDist[index] = targetDistance;
                    else if (gGrabDist[index] > 1)
                        gGrabDist[index]--;

                    if (!gGrabCounter[index] || ++gGrabCounter[index] >= 20)
                    {
                        StopSound(SOUND_FROM_WORLD,SNDCHAN_AUTO,pullerWav);
                        EmitSoundFromOrigin(pullerWav,targetloc); // Emit sound from the entity being pulled
                        gGrabCounter[index]=1;
                    }
                }

                TR_TraceRayFilter(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayTryToHit); // Find where the player is aiming
                TR_GetEndPosition(endvec); // Get the end position of the trace ray
                distance[0]=endvec[0]-clientloc[0];
                distance[1]=endvec[1]-clientloc[1];
                distance[2]=endvec[2]-clientloc[2];
                new Float:que=gGrabDist[index]/(SquareRoot(distance[0]*distance[0]+
                                                           distance[1]*distance[1]+
                                                           distance[2]*distance[2]));

                new Float:velocity[3];
                velocity[0]=(((distance[0]*que)+clientloc[0])-targetloc[0])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
                velocity[1]=(((distance[1]*que)+clientloc[1])-targetloc[1])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
                velocity[2]=(((distance[2]*que)+clientloc[2])-targetloc[2])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
                TeleportEntity(gTargetIndex[index],NULL_VECTOR,NULL_VECTOR,velocity);
                // Make a beam from grabber to grabbed
                new color[4];
                if(target<=GetMaxClients())
                    targetloc[2]+=45;
                GetBeamColor(index,Grab,color);
                BeamEffect("@all",clientloc,targetloc,0.2,1.0,10.0,color,0.0,0);
            }
            else
            {
                Action_Drop(index);
                //CloseHandle(timer); // Stop the timer
                return Plugin_Stop;
            }
        }
        else
        {
            Action_Drop(index);
            //CloseHandle(timer); // Stop the timer
            return Plugin_Stop;
        }
    }
    else
    {
        Action_Drop(index);
        return Plugin_Stop;
    }
    return Plugin_Handled;
}

public Action_Drop(client)
{
    gGrabCounter[client]=0;
    gStatus[client][ACTION_GRAB]=false; // Tell plugin the grabber has dropped his target
    gLastUsed[client][ACTION_GRAB]=GetGameTime(); // Tell plugin when grabber dropped his target

    if (IsClientInGame(client))
    {
        StopSound(client,SNDCHAN_AUTO,seekingWav);
        StopSound(SOUND_FROM_WORLD,SNDCHAN_AUTO,pullerWav);
    }

    new target = gTargetIndex[client];
    if(target>0)
    {
        if (IsClientInGame(client))
            PrintCenterText(client,"Target has been dropped");

        if (IsClientInGame(target))
        {
            SetEntPropFloat(target,Prop_Data,"m_flGravity",1.0); // Set gravity back to normal

            if (gFlags[client][ACTION_GRAB] != 0) // Grabber is a Puller
                SetEntPropFloat(target,Prop_Data,"m_flMaxspeed",gMaxSpeed[target]);
        }

        if(target>0&&target<=GetMaxClients())
            gGrabbed[target]=false; // Tell plugin the target is no longer being grabbed

        gTargetIndex[client]=-1;

        new Action:res;
        Call_StartForward(fwdOnDrop);
        Call_PushCell(client);
        Call_PushCell(target);
        Call_Finish(res);
    }
    else if(HasAccess(client,Grab) && IsClientInGame(client))
        PrintCenterText(client,"No target found");
}

/******
 *Rope*
 *******/

public Action_Rope(client)
{
    if(g_bNativeOverride || GetConVarBool(cvarRopeEnable))
    {
        if(client>0)
        {
            if(IsPlayerAlive(client)&&!gStatus[client][ACTION_ROPE]&&!gStatus[client][ACTION_HOOK]&&!gGrabbed[client])
            {
                if(HasAccess(client,Rope))
                {
                    new Float:cooldown = gCooldown[client][ACTION_ROPE];
                    if (cooldown <= 0.0 || ((GetGameTime() - gLastUsed[client][ACTION_ROPE]) >= cooldown))
                    {
                        EmitSoundToAll(fireWav, client); // Emit fire sound

                        new Float:clientloc[3],Float:clientang[3];
                        GetClientEyePosition(client,clientloc); // Get the position of the player's eyes
                        GetClientEyeAngles(client,clientang); // Get the angle the player is looking

                        TR_TraceRayFilter(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayTryToHit); // Create a ray that tells where the player is looking
                        TR_GetEndPosition(gRopeEndloc[client]); // Get the end xyz coordinate of where a player is looking

                        new Float:limit=gAllowedRange[client][ACTION_ROPE];
                        new Float:dist=GetDistanceBetween(clientloc,gRopeEndloc[client]);
                        if (limit <= 0.0 || limit >= dist)
                        {
                            if (gRemainingDuration[client] == 0)
                                gRemainingDuration[client] = gAllowedDuration[client][ACTION_ROPE];

                            gRopeDist[client]=dist;
                            gStatus[client][ACTION_ROPE]=true; // Tell plugin the player is roping
                            CreateTimer(0.1,Roping,client,TIMER_REPEAT); // Create roping loop
                            EmitSoundFromOrigin(hitWav,gRopeEndloc[client]); // Emit sound from the end of the rope
                        }
                        else
                        {
                            EmitSoundToClient(client,errorWav);
                            PrintToChat(client,"%c[HGR:Source] %cTarget is too far away!",
                                        COLOR_GREEN,COLOR_DEFAULT);
                        }
                    }
                    else
                    {
                        EmitSoundToClient(client,errorWav);
                        PrintToChat(client,"%c[HGR:Source] %cYou have used the %crope%c too recently!",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                else if (g_bNativeOverride)
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have a %crope%c",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use the %crope%c",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
            }
            else
                EmitSoundToClient(client,deniedWav);
        }
        else
        {
            EmitSoundToClient(client,deniedWav);
            PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",
                    COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
    {
        EmitSoundToClient(client,deniedWav);
        PrintToChat(client,"%c[HGR:Source] Rope %cis currently disabled",
                COLOR_GREEN,COLOR_DEFAULT);
    }
}

public Action:Roping(Handle:timer,any:index)
{
    if(IsClientInGame(index)&&gStatus[index][ACTION_ROPE]&&IsPlayerAlive(index)&&!gGrabbed[index])
    {
        if (gRemainingDuration[index] > 0)
        {
            gRemainingDuration[index]--;
            if (gRemainingDuration[index] <= 0)
            {
                Action_Detach(index);
                //CloseHandle(timer); // Stop the timer
                return Plugin_Stop;
            }
        }

        new Float:clientloc[3],Float:velocity[3],Float:velocity2[3];
        GetClientAbsOrigin(index,clientloc);
        GetVelocity(index,velocity);
        velocity2[0]=(gRopeEndloc[index][0]-clientloc[0])*3.0;
        velocity2[1]=(gRopeEndloc[index][1]-clientloc[1])*3.0;
        new Float:y_coord,Float:x_coord;
        y_coord=velocity2[0]*velocity2[0]+velocity2[1]*velocity2[1];
        x_coord=(GetConVarFloat(cvarRopeSpeed)*20.0)/SquareRoot(y_coord);
        velocity[0]+=velocity2[0]*x_coord;
        velocity[1]+=velocity2[1]*x_coord;
        if(gRopeEndloc[index][2]-clientloc[2]>=gRopeDist[index]&&velocity[2]<0.0)
            velocity[2]*=-1;
        TeleportEntity(index,NULL_VECTOR,NULL_VECTOR,velocity);
        // Make a beam from grabber to grabbed
        new color[4];
        clientloc[2]+=50;
        GetBeamColor(index,Rope,color);
        BeamEffect("@all",clientloc,gRopeEndloc[index],0.2,3.0,3.0,color,0.0,0);
    }
    else
    {
        Action_Detach(index);
        //CloseHandle(timer); // Stop the timer
        return Plugin_Stop;
    }
    return Plugin_Handled;
}

public Action_Detach(client)
{
    gStatus[client][ACTION_ROPE]=false; // Tell plugin the client is not roping
    gLastUsed[client][ACTION_ROPE]=GetGameTime(); // Tell plugin when client stopped roping
}

/***************
 *Trace Filters*
 ****************/

public bool:TraceRayTryToHit(entity,mask)
{
    if(entity>0&&entity<=GetMaxClients()) // Check if the beam hit a player and tell it to keep tracing if it did
        return false;
    return true;
}

public bool:TraceRayGrabEnt(entity,mask)
{
    if(entity>0) // Check if the beam hit an entity other than the grabber, and stop if it does
    {
        if(entity<=GetMaxClients()&&!gStatus[entity][ACTION_GRAB]&&!gGrabbed[entity])
            return true;
        if(entity>64) 
            return true;
    }
    return false;
}

/*********
 *Helpers*
 **********/

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,
                   SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,
                   NULL_VECTOR,true,0.0);
}

public GetVelocity(client,Float:output[3])
{
    GetEntDataVector(client, gGetVelocityOffset, output);
}

/****************
 *Math (Vectors)*
 *****************/

public GetForwardPushVec(const Float:start[3],const Float:end[3],Float:output[3])
{
    CreateVectorFromPoints(start,end,output);
    NormalizeVector(output,output);
    output[0]*=GetConVarFloat(cvarHookSpeed)*140.0;
    output[1]*=GetConVarFloat(cvarHookSpeed)*140.0;
    output[2]*=GetConVarFloat(cvarHookSpeed)*140.0;
}

public Float:CreateVectorFromPoints(const Float:vec1[3],const Float:vec2[3],Float:output[3])
{
    output[0]=vec2[0]-vec1[0];
    output[1]=vec2[1]-vec1[1];
    output[2]=vec2[2]-vec1[2];
}

public AddInFrontOf(Float:orig[3],Float:angle[3],Float:distance,Float:output[3])
{
    new Float:viewvector[3];
    ViewVector(angle,viewvector);
    output[0]=viewvector[0]*distance+orig[0];
    output[1]=viewvector[1]*distance+orig[1];
    output[2]=viewvector[2]*distance+orig[2];
}

public ViewVector(Float:angle[3],Float:output[3])
{
    output[0]=Cosine(angle[1]/(180/FLOAT_PI));
    output[1]=Sine(angle[1]/(180/FLOAT_PI));
    output[2]=-Sine(angle[0]/(180/FLOAT_PI));
}

public Float:GetDistanceBetween(Float:startvec[3],Float:endvec[3])
{
    return SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+
                      (startvec[1]-endvec[1])*(startvec[1]-endvec[1])+
                      (startvec[2]-endvec[2])*(startvec[2]-endvec[2]));
}

/*********
 *Effects*
 **********/

public BeamEffect(const String:target[],Float:startvec[3],Float:endvec[3],
                  Float:life,Float:width,Float:endwidth,const color[4],Float:amplitude,speed)
{
    new clients[MAXPLAYERS];
    new count=FindMatchingPlayers(target,clients);
    TE_SetupBeamPoints(startvec,endvec,precache_laser,0,0,66,life,width,endwidth,0,amplitude,color,speed);
    TE_Send(clients,count);
} 

/*********************
 *Partial Name Parser*
 **********************/

public FindMatchingPlayers(const String:matchstr[],clients[])
{
    new count=0;
    new maxplayers=GetMaxClients();
    if(StrEqual(matchstr,"@all",false))
    {
        for(new x=1;x<=maxplayers;x++)
        {
            if(IsClientInGame(x))
            {
                clients[count]=x;
                count++;
            }
        }
    }
    else if(StrEqual(matchstr,"@t",false))
    {
        for(new x=1;x<=maxplayers;x++)
        {
            if(IsClientInGame(x)&&GetClientTeam(x)==2)
            {
                clients[count]=x;
                count++;
            }
        }
    }
    else if(StrEqual(matchstr,"@ct",false))
    {
        for(new x=1;x<=maxplayers;x++)
        {
            if(IsClientInGame(x)&&GetClientTeam(x)==3)
            {
                clients[count]=x;
                count++;
            }
        }
    }
    else if(matchstr[0]=='@')
    {
        new userid=StringToInt(matchstr[1]);
        if(userid)
        {
            new index=GetClientOfUserId(userid);
            if(index)
            {
                if(IsClientInGame(index))
                {
                    clients[count]=index;
                    count++;
                }
            }
        }
    }
    else
    {
        for(new x=1;x<=maxplayers;x++)
        {
            if(IsClientInGame(x))
            {
                decl String:name[64];
                GetClientName(x,name,sizeof(name));
                if(StrContains(name,matchstr,false)!=-1)
                {
                    clients[count]=x;
                    count++;
                }
            }
        }
    }
    return count;
}
