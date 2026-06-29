/*
 Bumper Car Plugin
 By: Chdata

 Thanks to Dr. McKay for the original Kartify plugin.
 Thanks to FlaminSarge for adding some fixes and features.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "0x0D"

new Handle:g_cvTeamOnly;
new g_iCatTeam;

new Handle:g_cvHeadScale;
new Float:g_flHeadScale;

new Handle:g_cvKeepCar;
//new g_iKeepCar;

new Handle:g_cvCanSuicide;
//new bool:g_bCanSuicide;

new Handle:g_cvToggleOnSpawn;
//new bool:g_bToggleOnSpawn;

new Handle:g_cvHardStop;
new bool:g_bHardStop;

new Handle:g_cvCarNoTakeDamage;
new bool:g_bCarNoTakeDamage;

new Handle:g_cvCarPctDamage;
new g_iCarPctDamage;

new Handle:g_cvCarInitPctDmg;

//new Handle:g_cvCarPctAsHealth;

new Float:g_flBoostTime;

new Float:g_flFreezeTimeEnd;

new bool:g_bKeepCar[MAXPLAYERS + 1] = {false,...};    // Whether to keep car after respawn
new bool:g_bWasDriving[MAXPLAYERS + 1] = {false,...}; // Whether to keep car after certain tf conditions are applied

public Plugin:myinfo = {
    name = "Chdata's Car data",
    author = "Chdata",
    description = "Put people into bumper cars & fixes various issues",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

public OnPluginStart()
{
    CreateConVar(
        "cv_bumpercar_version", PLUGIN_VERSION,
        "Bumpercar Version",
        FCVAR_REPLICATED|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY
    );

    g_cvTeamOnly = CreateConVar(
        "cv_bumpercar_teamonly", "0",
        "0 = Anyone can enter bumper cars | 2 = Only red | 3 = Only blu | Anything else = Anyone can",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0, true, 3.0
    );

    g_cvHeadScale = CreateConVar(
        "cv_bumpercar_headscale", "1.0",
        "Player head scale when put into a bumper car.",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.1, true, 3.0
    );

    g_cvKeepCar = CreateConVar(
        "cv_bumpercar_respawn", "1",
        "1 = Keep car on respawn | 0 = Lose car after death | 2 = Everyone automagically spawns in a car all the time unless cv_bumpercar_teamonly disables a team",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0, true, 2.0
    );

    g_cvCanSuicide = CreateConVar(
        "cv_bumpercar_suicide", "1",
        "1 = people in car can suicide | 0 = cannot suicide",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0, true, 1.0
    );

    g_cvToggleOnSpawn = CreateConVar(
        "cv_bumpercar_spawntoggle", "0",
        "1 = have to respawn to enter/exit car | 0 = can enter/exit car at any time - don't need to respawn",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0, true, 1.0
    );

    g_cvHardStop = CreateConVar(
        "cv_bumpercar_backstop", "1",
        "1 = +back cancels speed boost | 0 = +back does not cancel speed boost",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0, true, 1.0
    );

    g_cvCarNoTakeDamage = CreateConVar(
        "cv_bumpercar_blockplayerdmg", "1",
        "1 = enable damage block for non-drivers attacking drivers | 0 = no damage block, non-drivers can damage and kill drivers",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0, true, 1.0
    );

    g_cvCarPctDamage = CreateConVar(
        "cv_bumpercar_percent", "-1",
        "-1 = (anything negative) car damage acts like it normally does | 0+ (anything non-negative) car damage percentage stays at this integer all the time",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, -1.0, true, 999999.0
    );

    g_cvCarInitPctDmg = CreateConVar(
        "cv_bumpercar_initpct", "0",
        "An amount of damage cars start with on spawn. Only applies if cv_bumpercar_percent is -1.",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0, true, 999999.0
    );

    HookConVarChange(g_cvTeamOnly, CvarChange);
    HookConVarChange(g_cvHeadScale, CvarChange);
    //HookConVarChange(g_cvKeepCar, CvarChange);
    //HookConVarChange(g_cvCanSuicide, CvarChange);
    //HookConVarChange(g_cvToggleOnSpawn, CvarChange);
    HookConVarChange(g_cvHardStop, CvarChange);
    HookConVarChange(g_cvCarNoTakeDamage, CvarChange);
    HookConVarChange(g_cvCarPctDamage, CvarChange);
    HookConVarChange(FindConVar("tf_halloween_kart_boost_duration"), CvarChange);

    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
    AddCommandListener(DoSuicide, "explode");
    AddCommandListener(DoSuicide, "kill");
    AddCommandListener(DoSuicide2, "jointeam");
    AddCommandListener(DoSuicide3, "autoteam");

    AutoExecConfig(true, "ch.bumpercar");

    RegAdminCmd("sm_bumpercar", cmdBumperCar, 0, "sm_car <noparam|#userid|name> <noparam|on|off> - Toggles bumper car on all targets or self");
    RegAdminCmd("sm_car", cmdBumperCar, 0, "sm_car <noparam|#userid|name> <noparam|on|off> - Toggles bumper car on all targets or self");

    AddMultiTargetFilter("@cars", CarTargetFilter, "all drivers", false);
    AddMultiTargetFilter("@!cars", CarTargetFilter, "all non-drivers", false);

    LoadTranslations("common.phrases");

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            SDKHook(i, SDKHook_PostThinkPost, OnPostThinkPost);
        }
    }
}

public OnConfigsExecuted()
{
    g_iCatTeam = GetConVarInt(g_cvTeamOnly);
    g_flHeadScale = GetConVarFloat(g_cvHeadScale);
    //g_iKeepCar = GetConVarInt(g_cvKeepCar);
    //g_bCanSuicide = GetConVarBool(g_cvCanSuicide);
    //g_bToggleOnSpawn = GetConVarBool(g_cvToggleOnSpawn);
    g_bHardStop = GetConVarBool(g_cvHardStop);
    g_flBoostTime = GetConVarFloat(FindConVar("tf_halloween_kart_boost_duration"));
    g_bCarNoTakeDamage = GetConVarBool(g_cvCarNoTakeDamage);
    g_iCarPctDamage = GetConVarInt(g_cvCarPctDamage);
}

public CvarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
    if (hCvar == g_cvTeamOnly)
    {
        g_iCatTeam = GetConVarInt(g_cvTeamOnly);

        if (g_iCatTeam > 1)
        {
            for(new i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_IsPlayerInCondition(i, TFCond_HalloweenKart) && GetClientTeam(i) != g_iCatTeam)
                {
                    TF2_RemoveCondition(i, TFCond_HalloweenKart);
                    g_bKeepCar[i] = false;
                    g_bWasDriving[i] = false;
                }
            }
        }
    }
    else if (hCvar == g_cvHeadScale)
    {
        g_flHeadScale = GetConVarFloat(g_cvHeadScale);
    }
    /*else if (hCvar == g_cvKeepCar) // Low load, removed
    {
        g_iKeepCar = GetConVarInt(g_cvKeepCar);
    }
    else if (hCvar == g_cvCanSuicide) // Low load, removed
    {
        g_bCanSuicide = GetConVarBool(g_cvCanSuicide);
    }
    else if (hCvar == g_cvToggleOnSpawn) // Low load, removed
    {
        g_bToggleOnSpawn = GetConVarBool(g_cvToggleOnSpawn);
    }*/
    else if (hCvar == g_cvHardStop)
    {
        g_bHardStop = GetConVarBool(g_cvHardStop);
    }
    else if (hCvar == g_cvCarNoTakeDamage)
    {
        g_bCarNoTakeDamage = GetConVarBool(g_cvCarNoTakeDamage);
    }
    else if (hCvar == g_cvCarPctDamage)
    {
        g_iCarPctDamage = GetConVarInt(g_cvCarPctDamage);
    }
    else if (hCvar == FindConVar("tf_halloween_kart_boost_duration"))
    {
        g_flBoostTime = GetConVarFloat(hCvar);
    }
}

public OnClientPutInServer(iClient)
{
    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(iClient, SDKHook_PostThinkPost, OnPostThinkPost);

    g_bKeepCar[iClient] = false;
    g_bWasDriving[iClient] = false;
}

public Action:OnTakeDamage(iVictim, &iAtker, &iInflictor, &Float:flDamage, &iDmgType, &iWeapon, Float:vDmgForce[3], Float:vDmgPos[3], iDmgCustom)
{
    if (IsValidClient(iVictim) && TF2_IsPlayerInCondition(iVictim, TFCond_HalloweenKart))
    {
        if (IsValidClient(iAtker) && g_bCarNoTakeDamage)
        {
            flDamage = 0.0;
            return Plugin_Changed;
        }

        decl String:s[16];
        GetEdictClassname(iAtker, s, sizeof(s));
        if (StrEqual(s, "trigger_hurt", false))
        {
            SDKHooks_TakeDamage(iVictim, iAtker, iAtker, 40000.0, DMG_GENERIC|DMG_PREVENT_PHYSICS_FORCE);
        }
        /*else if (IsValidClient(iAtker) && !TF2_IsPlayerInCondition(iVictim, TFCond_HalloweenKart) && TF2_IsPlayerInCondition(iAtker, TFCond_HalloweenKart))
        {
            flDamage *= 2.0;
            return Plugin_Changed;      // Carts don't seem to trigger OnTakeDamage when they deal "percentage damage"
        }*/                             // Valve pls put a % sign next to those hitmarkes
    }
    return Plugin_Continue;
}

public OnMapStart()
{
    PrecacheKart();
    g_flFreezeTimeEnd = 0.0;
}

public OnPlayerSpawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    TryClientSpawnCar(iClient);
}

public OnRoundStart(Handle:hNull, const String:sName[], bool:bDontBroadcast)
{
    new bool:bArena = GetConVarBool(FindConVar("tf_gamemode_arena"));
    new bool:bRoundWaitTime = GetConVarBool(FindConVar("mp_enableroundwaittime"));
    new Float:flArenaPreroundTime = GetConVarFloat(FindConVar("tf_arena_preround_time"));
    g_flFreezeTimeEnd = GetGameTime() + (bArena ? flArenaPreroundTime : (bRoundWaitTime ? 5.0 : 0.0));
    for (new lClient = 1; lClient <= MaxClients; lClient++)
    {
        TryClientSpawnCar(lClient);
    }
}

stock TryClientSpawnCar(iClient)
{
    if (!IsValidClient(iClient) || !IsPlayerAlive(iClient))
    {
        return;
    }

    new iKeepCar = GetConVarInt(g_cvKeepCar);
    if (iKeepCar != 0 && (g_bKeepCar[iClient] || iKeepCar == 2))
    {
        if (TryEnterCar(iClient))
        {
            new Float:flCurryTime = GetGameTime();
            if (flCurryTime < g_flFreezeTimeEnd)
            {
                TF2_AddCondition(iClient, TFCond_HalloweenKartNoTurn, g_flFreezeTimeEnd - flCurryTime);
            }

            RequestFrame(OnPostPostPlayerSpawn, GetClientUserId(iClient)); // I think this may not be necessary actually...
            //FixSpawnOrientation(iClient);
        }
        g_bWasDriving[iClient] = true;
    }
}

// Wait 1 frame is so the player's angles can be oriented with info_player_teamspawn
public OnPostPostPlayerSpawn(any:iData)
{
    new iClient = GetClientOfUserId(iData);
    if (IsValidClient(iClient))
    {
        FixSpawnOrientation(iClient);
    }
}

stock FixSpawnOrientation(iClient)
{
    new iEnt = -1;
    decl Float:vPos1[3], Float:vPos2[3], Float:vAng[3];
    new iTeam = GetClientTeam(iClient);
    GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vPos2); //GetClientAbsOrigin(iClient, vPos);
    while ((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
    {
        if (iTeam == GetEntProp(iEnt, Prop_Send, "m_iTeamNum"))
        {
            GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos1);

            if (GetVectorDistance(vPos1, vPos2) <= 25.0) // Generally safe to say this was your spawn point
            {
                GetEntPropVector(iEnt, Prop_Send, "m_angRotation", vAng);
                //GetEntPropVector(iEnt, Prop_Data, "m_angAbsRotation", vAng);
                break;
            }
        }
    }

    // Should be impossible not to find at least one spawn
    if (iEnt == -1)
    {
        return;
    }
    
    vPos1[2] += 10.0;       // I do this because on some maps, spawning in a car spams repeated noises until you jump.
    vAng[0] += 10.0;        // It seems like not setting this sometimes makes your view go under the ground
    TeleportEntity(iClient, vPos1, vAng, NULL_VECTOR);
    ForcePlayerViewAngles(iClient, vAng);

    //LogMessage("oriented %N %i on spawn %i dist %0.3f %0.1f %0.1f %0.1f", iClient, iClient, iEnt, GetVectorDistance(vPos1, vPos2), vAng[0], vAng[1], vAng[2]);
}

public Action:DoSuicide(iClient, const String:sCommand[], iArgc)
{
    if (GetConVarBool(g_cvCanSuicide))
    {                                  // Hale can suicide too
        SDKHooks_TakeDamage(iClient, 0, 0, 40000.0, (sCommand[0] == 'e' ? DMG_BLAST : DMG_GENERIC)|DMG_PREVENT_PHYSICS_FORCE); // e for EXPLODE
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:DoSuicide2(iClient, const String:sCommand[], iArgc)
{
    if (GetClientTeam(iClient) != StringToInt(sCommand[9]))
    {
        SDKHooks_TakeDamage(iClient, 0, 0, 40000.0, DMG_GENERIC|DMG_PREVENT_PHYSICS_FORCE); // Yeah I borrowed this from McKay cause ForcePlayerSuicide doesn't seem to work here
    }
    return Plugin_Continue;
}

public Action:DoSuicide3(iClient, const String:sCommand[], iArgc)
{
    if (TF2_IsPlayerInCondition(iClient, TFCond_HalloweenKart))
    {
        SDKHooks_TakeDamage(iClient, 0, 0, 40000.0, DMG_GENERIC|DMG_PREVENT_PHYSICS_FORCE);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public bool:CarTargetFilter(const String:pattern[], Handle:clients)
{
    new bool:non = pattern[1] == '!';
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client) && FindValueInArray(clients, client) == -1)
        {
            if (TF2_IsPlayerInCondition(client, TFCond_HalloweenKart))
            {
                if (!non)
                {
                    PushArrayCell(clients, client);
                }
            }
            else if (non)
            {
                PushArrayCell(clients, client);
            }
        }
    }

    return true;
}

public TF2_OnConditionAdded(iClient, TFCond:iCond)
{
    switch (iCond)
    {
        case (TFCond_SwimmingCurse), TFCond_Taunting, TFCond_HalloweenGhostMode, TFCond_HalloweenThriller:
        {
            if (TF2_IsPlayerInCondition(iClient, TFCond_HalloweenKart))
            {
                g_bWasDriving[iClient] = true;
                TF2_RemoveCondition(iClient, TFCond_HalloweenKart);
            }
            else
            {
                g_bWasDriving[iClient] = false;
            }
        }
        case (TFCond_HalloweenKart):
        {
            if (g_iCarPctDamage == -1) // Probably don't really need to check this.
            {
                SetEntProp(iClient, Prop_Send, "m_iKartHealth", GetConVarInt(g_cvCarInitPctDmg));
            }
            //RequestFrame(PostCarEnable, GetClientUserId(iClient));
        }
        case (TFCond_HalloweenKartDash):
        {
            if (g_flBoostTime == -1.0) // Disable constant re-dashing
            {
                SetEntPropFloat(iClient, Prop_Send, "m_flKartNextAvailableBoost", GetGameTime()+999999.0);
            }
        }
    }
}

public TF2_OnConditionRemoved(iClient, TFCond:iCond)
{
    switch (iCond)
    {
        case (TFCond_SwimmingCurse), TFCond_Taunting, TFCond_HalloweenGhostMode, TFCond_HalloweenThriller:
        {
            if (g_bWasDriving[iClient])
            {
                TryEnterCar(iClient);
            }
        }
        case (TFCond_HalloweenKartDash):
        {
            if (g_flBoostTime == -1.0)
            {
                SetEntPropFloat(iClient, Prop_Send, "m_flKartNextAvailableBoost", GetGameTime()+1.5);
            }
        }
        case (TFCond_HalloweenKart):
        {
            RemoveCond(iClient, TFCond_HalloweenKartDash);
            RemoveCond(iClient, TFCond_HalloweenKartCage);
        }
    }
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:vVel[3], Float:vAng[3], &hWeapon)
{
    if (iButtons & IN_BACK)
    {
        if (g_bHardStop && TF2_IsPlayerInCondition(iClient, TFCond_HalloweenKartDash)) // Without the check, this is spammy
        {
            TF2_RemoveCondition(iClient, TFCond_HalloweenKartDash);

            if (g_flBoostTime == -1.0)
            {
                SetEntPropFloat(iClient, Prop_Send, "m_flKartNextAvailableBoost", GetGameTime()+1.5);
            }
        }
    }
}

/*public PostCarEnable(any:iData)
{
    new iClient = GetClientOfUserId(iData);
    if (IsValidClient(iClient))
    {
        
    }
}*/

public OnPostThinkPost(iClient)
{
    if (TF2_IsPlayerInCondition(iClient, TFCond_HalloweenKart))
    {
        new iFlags = GetEdictFlags(iClient);
        if (!(iFlags & FL_EDICT_ALWAYS))
        {
            iFlags |= FL_EDICT_ALWAYS;
            SetEdictFlags(iClient, iFlags);
        }

        //if (g_flHeadScale != 3.0) // Uncommenting this would allow the head to resize over timer like it usually does... eh
        //{
        SetEntPropFloat(iClient, Prop_Send, "m_flHeadScale", g_flHeadScale);
        //}
        
        if (g_iCarPctDamage >= 0) 
        {
            SetEntProp(iClient, Prop_Send, "m_iKartHealth", g_iCarPctDamage);
        }
    }
}

public Action:cmdBumperCar(client, argc)
{
    if (argc == 0)
    {
        if (!client)
        {
            ReplyToCommand(client, "[SM] Console cannot ride in bumper cars.");
            return Plugin_Handled;
        }

        if (!CheckCommandAccess(client, "adm_bumpercar_self", 0))
        {
            ReplyToCommand(client, "[SM] %t.", "No Access");
            return Plugin_Handled;
        }

        g_bKeepCar[client] = SelfEnterCar(client);
        g_bWasDriving[client] = g_bKeepCar[client];

        return Plugin_Handled;
    }
    else
    {
        new fFlags = COMMAND_FILTER_CONNECTED;

        if (argc == 1)
        {
            fFlags |= COMMAND_FILTER_NO_MULTI;
        }

        decl String:arg1[32];
        GetCmdArg(1, arg1, sizeof(arg1));

        new bool:bSelf = StrEqual(arg1, "@me");

        if (!bSelf && !CheckCommandAccess(client, "adm_bumpercar_target", ADMFLAG_CHEATS)) // If targeting someone else
        {
            ReplyToCommand(client, "[SM] You do not have access to targeting others.");
            return Plugin_Handled;
        }
        else if (bSelf && !CheckCommandAccess(client, "adm_bumpercar_self", 0))
        {
            ReplyToCommand(client, "[SM] %t.", "No Access");
            return Plugin_Handled;
        }

        if (bSelf)
        {
            g_bKeepCar[client] = SelfEnterCar(client);
            g_bWasDriving[client] = g_bKeepCar[client];
            return Plugin_Handled;
        }

        decl String:target_name[MAX_TARGET_LENGTH];
        decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

        if ((target_count = ProcessTargetString(
                arg1,
                client,
                target_list,
                MAXPLAYERS,
                fFlags,
                target_name,
                sizeof(target_name),
                tn_is_ml)) > 0)
        {
            decl String:arg2[80];
            GetCmdArg(2, arg2, sizeof(arg2));

            decl bool:bOn;

            if (target_count == 1)
            {
                if (argc == 1)
                {
                    bOn = !TF2_IsPlayerInCondition(target_list[0], TFCond_HalloweenKart);
                }
                else
                {
                    bOn = (StrEqual(arg2, "on") || arg2[0] == '1');
                }

                if (target_list[0] == client)
                {
                    g_bKeepCar[client] = SelfEnterCar(client); // _:bOn
                    g_bWasDriving[client] = g_bKeepCar[client];
                    return Plugin_Handled;
                }
            }
            else if (target_count > 1 && argc < 2)
            {
                ReplyToCommand(client, "[SM] Usage: sm_car - Specify <on|off> when multi-targeting");
                return Plugin_Handled;
            }
            else
            {
                bOn = (StrEqual(arg2, "on") || arg2[0] == '1');
            }

            // IntToString(_:bOn, arg2, sizeof(arg2));

            new bool:bToggleOnSpawn = GetConVarBool(g_cvToggleOnSpawn);

            for (new i = 0; i < target_count; i++)
            {
                if (bOn)
                {
                    if (!bToggleOnSpawn)
                    {
                        TryEnterCar(target_list[i]);
                    }
                    g_bKeepCar[target_list[i]] = true;
                    g_bWasDriving[target_list[i]] = true;
                }
                else
                {
                    if (!bToggleOnSpawn && IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]))
                    {
                        TF2_RemoveCondition(target_list[i], TFCond_HalloweenKart);
                    }
                    g_bKeepCar[target_list[i]] = false;
                    g_bWasDriving[target_list[i]] = false;
                }

                //if (AreClientCookiesCached(target_list[i]))
                //{
                //    SetClientCookie(target_list[i], g_cCarCookie, arg2);
                //}
            }

            ShowActivity2(client, "[SM] ", "%sed bumper car on %s.", !bOn?"Remov":"Add", target_name);

            //if (GetConVarBool(g_cvLogs))
            //{
            //    LogAction(client, target_list[0], "\"%L\" %sed bumper car on \"%L\"", client, bOn?"remov":"add", target_list[0]);
            //}
        }
        else
        {
            ReplyToTargetError(client, target_count);
        }
    }
    return Plugin_Handled;
}

stock bool:SelfEnterCar(iClient) // , iOn=-1
{
    if ((g_iCatTeam == 2 || g_iCatTeam == 3) && GetClientTeam(iClient) != g_iCatTeam)
    {
        ReplyToCommand(iClient, "[SM] Only %s team can toggle riding bumper cars.", g_iCatTeam == 2 ? "red" : "blu");
        return false;
    }

    if (!IsPlayerAlive(iClient))
    {
        new iKeepCar = GetConVarInt(g_cvKeepCar);
        if (iKeepCar == 1)
        {
            ReplyToCommand(iClient, "[SM] You will be in a bumper car when you spawn.");
            return true;
        }
        else if (iKeepCar == 0)
        {
            ReplyToCommand(iClient, "[SM] You must be alive to ride bumper cars.");
            return false;
        }
    }

    /*if (iOn != -1)
    {
        if (bool:iOn)
        {
            if (TF2_IsPlayerInCondition(iClient, TFCond_HalloweenKart))
            {
                ReplyToCommand(iClient, "[SM] You are now still riding a bumper car!");
            }
            else
            {
                if (TryEnterCar(iClient))
                {
                    ReplyToCommand(iClient, "[SM] You are now riding a bumper car!");
                }
                else
                {
                    ReplyToCommand(iClient, "[SM] You can't ride a bumper car in your current state.");
                }
            }
        }
        else
        {
            // lol this is silly, quadratic logic
        }

        return;
    }*/
    new bool:bIsInKart = TF2_IsPlayerInCondition(iClient, TFCond_HalloweenKart);
    if (GetConVarBool(g_cvToggleOnSpawn))
    {
        ReplyToCommand(iClient, "[SM] You will %s your bumper car after you respawn.", bIsInKart ? "exit" : "enter");
        return !bIsInKart;
    }
    if (bIsInKart)
    {
        TF2_RemoveCondition(iClient, TFCond_HalloweenKart);
        ReplyToCommand(iClient, "[SM] You have exited your bumper car.");
        return false;
    }
    if (!TryEnterCar(iClient))
    {
        ReplyToCommand(iClient, "[SM] You can't ride a bumper car in your current state.");
        return false;
    }
    ReplyToCommand(iClient, "[SM] You are now riding a bumper car!");
    return true;
}

stock bool:TryEnterCar(iClient)
{
    if (IsValidClient(iClient) && IsPlayerAlive(iClient) && !TF2_IsPlayerInCondition(iClient, TFCond_SwimmingCurse) && !TF2_IsPlayerInCondition(iClient, TFCond_HalloweenGhostMode) && !TF2_IsPlayerInCondition(iClient, TFCond_Taunting) && !TF2_IsPlayerInCondition(iClient, TFCond_HalloweenThriller))
    {
        if ((g_iCatTeam == 2 || g_iCatTeam == 3) && GetClientTeam(iClient) != g_iCatTeam)
        {
            return false;
        }
        decl Float:vAng[3];
        GetClientEyeAngles(iClient, vAng);
        TF2_AddCondition(iClient, TFCond_HalloweenKart);
        ForcePlayerViewAngles(iClient, vAng);
        if (g_iCarPctDamage == -1) // Probably don't really need to check this.
        {
            SetEntProp(iClient, Prop_Send, "m_iKartHealth", GetConVarInt(g_cvCarInitPctDmg));
        }
        return true;
    }
    return false;
}

stock ForcePlayerViewAngles(iClient, Float:vAng[3]) // TODO: Base this off of the info_player_teamspawn under you.
{
    new Handle:bf = StartMessageOne("ForcePlayerViewAngles", iClient);
    BfWriteByte(bf, 1);
    BfWriteByte(bf, iClient);
    BfWriteAngles(bf, vAng);
    EndMessage();
}

stock bool:IsValidClient(iClient)
{
    return (0 < iClient && iClient <= MaxClients
        && IsClientInGame(iClient)
        && !IsClientReplay(iClient)
        && !IsClientSourceTV(iClient)
        && !GetEntProp(iClient, Prop_Send, "m_bIsCoaching")
    );
}

stock PrecacheKart() //void CTFPlayer::PrecacheKart()
{
    PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl", true);
    PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl", true);
    PrecacheModel("models/props_halloween/bumpercar_cage.mdl", true);

    /*PrecacheScriptSound("BumperCar.Spawn");
    PrecacheScriptSound("BumperCar.SpawnFromLava");
    PrecacheScriptSound("BumperCar.GoLoop");
    PrecacheScriptSound("BumperCar.Screech");
    PrecacheScriptSound("BumperCar.HitGhost");
    PrecacheScriptSound("BumperCar.Bump");
    PrecacheScriptSound("BumperCar.BumpIntoAir");
    PrecacheScriptSound("BumperCar.SpeedBoostStart");
    PrecacheScriptSound("BumperCar.SpeedBoostStop");
    PrecacheScriptSound("BumperCar.Jump");
    PrecacheScriptSound("BumperCar.JumpLand");*/
    //PrecacheScriptSound("sf14.Merasmus.DuckHunt.BonusDucks"); // BonusDi

    PrecacheSound(")weapons/bumper_car_accelerate.wav"); // From McKay again, I have no idea why the string has to be like this
    PrecacheSound(")weapons/bumper_car_decelerate.wav");
    PrecacheSound(")weapons/bumper_car_decelerate_quick.wav");
    PrecacheSound(")weapons/bumper_car_go_loop.wav");
    PrecacheSound(")weapons/bumper_car_hit_ball.wav");
    PrecacheSound(")weapons/bumper_car_hit_ghost.wav");
    PrecacheSound(")weapons/bumper_car_hit_hard.wav");
    PrecacheSound(")weapons/bumper_car_hit_into_air.wav");
    PrecacheSound(")weapons/bumper_car_jump.wav");
    PrecacheSound(")weapons/bumper_car_jump_land.wav");
    PrecacheSound(")weapons/bumper_car_screech.wav");
    PrecacheSound(")weapons/bumper_car_spawn.wav");
    PrecacheSound(")weapons/bumper_car_spawn_from_lava.wav");
    PrecacheSound(")weapons/bumper_car_speed_boost_start.wav");
    PrecacheSound(")weapons/bumper_car_speed_boost_stop.wav");
    
    decl String:szSnd[64];
    for(new i = 1; i <= 8; i++)
    {
        FormatEx(szSnd, sizeof(szSnd), "weapons/bumper_car_hit%i.wav", i);
        PrecacheSound(szSnd);
    }

    //PrecacheSound("weapons/bumper_car_speed_boost_start.wav", true);
    //PrecacheSound("weapons/bumper_car_speed_boost_stop.wav", true);

    //PrecacheSound("weapons/buffed_off.wav", true);
    //PrecacheSound("weapons/buffed_on.wav"", true);

    /*PrecacheSound("weapons/bumper_car_hit_ball.wav", true);
    PrecacheSound("weapons/bumper_car_hit_ghost.wav", true);
    PrecacheSound("weapons/bumper_car_hit_hard.wav", true);
    PrecacheSound("weapons/bumper_car_hit_into_air.wav", true);
    PrecacheSound("weapons/bumper_car_spawn.wav", true);
    PrecacheSound("weapons/bumper_car_spawn_from_lava.wav", true);

    PrecacheSound("weapons/bumper_car_accelerate.wav", true); // These seem to already always work.
    PrecacheSound("weapons/bumper_car_decelerate.wav", true); // Except not for people other than me? lul
    PrecacheSound("weapons/bumper_car_decelerate_quick.wav", true);
    PrecacheSound("weapons/bumper_car_go_loop.wav", true);
    PrecacheSound("weapons/bumper_car_hit1.wav", true);
    PrecacheSound("weapons/bumper_car_hit2.wav", true);
    PrecacheSound("weapons/bumper_car_hit3.wav", true);
    PrecacheSound("weapons/bumper_car_hit4.wav", true);
    PrecacheSound("weapons/bumper_car_hit5.wav", true);
    PrecacheSound("weapons/bumper_car_hit6.wav", true);
    PrecacheSound("weapons/bumper_car_hit7.wav", true);
    PrecacheSound("weapons/bumper_car_hit8.wav", true);
    PrecacheSound("weapons/bumper_car_jump.wav", true);
    PrecacheSound("weapons/bumper_car_jump_land.wav", true);
    PrecacheSound("weapons/bumper_car_screech.wav", true);*/

    PrecacheParticleSystem("kartimpacttrail");
    PrecacheParticleSystem("kart_dust_trail_red");
    PrecacheParticleSystem("kart_dust_trail_blue");

    return PrecacheParticleSystem("kartdamage_4");
}

/* SMLIB
 * Precaches the given particle system.
 * It's best to call this OnMapStart().
 * Code based on Rochellecrab's, thanks.
 *
 * @param particleSystem    Name of the particle system to precache.
 * @return                  Returns the particle system index, INVALID_STRING_INDEX on error.
 */
stock PrecacheParticleSystem(const String:particleSystem[])
{
    static particleEffectNames = INVALID_STRING_TABLE;

    if (particleEffectNames == INVALID_STRING_TABLE) {
        if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
            return INVALID_STRING_INDEX;
        }
    }

    new index = FindStringIndex2(particleEffectNames, particleSystem);
    if (index == INVALID_STRING_INDEX) {
        new numStrings = GetStringTableNumStrings(particleEffectNames);
        if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) {
            return INVALID_STRING_INDEX;
        }

        AddToStringTable(particleEffectNames, particleSystem);
        index = numStrings;
    }

    return index;
}

/* SMLIB
 * Rewrite of FindStringIndex, because in my tests
 * FindStringIndex failed to work correctly.
 * Searches for the index of a given string in a string table.
 *
 * @param tableidx      A string table index.
 * @param str           String to find.
 * @return              String index if found, INVALID_STRING_INDEX otherwise.
 */
stock FindStringIndex2(tableidx, const String:str[])
{
    decl String:buf[1024];

    new numStrings = GetStringTableNumStrings(tableidx);
    for (new i=0; i < numStrings; i++) {
        ReadStringTable(tableidx, i, buf, sizeof(buf));

        if (StrEqual(buf, str)) {
            return i;
        }
    }

    return INVALID_STRING_INDEX;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
    while (startEnt > -1 && !IsValidEntity(startEnt))
    {
        startEnt--;
    }

    return FindEntityByClassname(startEnt, classname);
}

stock RemoveCond(iClient, TFCond:iCond)
{
    if (TF2_IsPlayerInCondition(iClient, iCond))
    {
        TF2_RemoveCondition(iClient, iCond);
    }
}