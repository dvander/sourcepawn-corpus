#pragma semicolon 1;

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define BOMB1 "models/effects/bday_gib02.mdl"
#define BOMB_SOUND "weapons/explode3.wav"

#define PL_VERSION "0.2"

new Handle:BombRetrieveTime = INVALID_HANDLE;
new Handle:BombTime = INVALID_HANDLE;
new Handle:CenterExplosionDamage = INVALID_HANDLE;
new Handle:DefuseTime = INVALID_HANDLE;
new Handle:ExplosionRadius = INVALID_HANDLE;
new Handle:LookAngle = INVALID_HANDLE;
new Handle:PlantTime = INVALID_HANDLE;
new Handle:RedWinTime = INVALID_HANDLE;


new bool:BombDropped = false;
new bool:ClientHaveBomb[MAXPLAYERS+1] = { false, ... };
new bool:InBombArea[MAXPLAYERS+1] = { false, ... };
//new bool:MapIsSet = false;
new bool:NoMove[MAXPLAYERS+1] = { false, ... };
new bool:NooneHaveBomb = false;
//new bool:Planted = false;
new bool:Planting[MAXPLAYERS+1] = { false, ... };
new bool:ShowHelp[MAXPLAYERS+1] = { true, ... };

new Handle:BombTimer = INVALID_HANDLE;
new Handle:RedWin = INVALID_HANDLE;
new Handle:RestTimer = INVALID_HANDLE;
new Handle:plantdefuse[MAXPLAYERS+1];

new Float:BombLoc[3];
new Float:BombPlaceTime;
new Float:PlantTimeF[MAXPLAYERS+1];

new area = -1;
new bomb = -1;
new BombDropper = -1;
new Case[MAXPLAYERS+1] = { 0, ... };
new droppedbomb = -1;
new PlantingClient = 0;
new round = 0;

public Plugin:myinfo = 
{
    name = "Bomb Fortress",
    author = "Cookies",
    description = "A Team Fortress 2 bomb mod",
    version = PL_VERSION,
    url = ""
};

public OnPluginStart()
{
    CreateConVar("bomb_version", PL_VERSION, "Currrent Bomb Fortress version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    PlantTime = CreateConVar("plant_time", "10", "The time it takes to plant the bomb", FCVAR_PLUGIN, true, 1.0, true, 30.0);
    DefuseTime = CreateConVar("defuse_time", "10", "The time it takes to defuse the bomb", FCVAR_PLUGIN, true, 1.0, true, 30.0);
    BombTime = CreateConVar("bomb_time", "45", "The time it takes for the bomb to explode", FCVAR_PLUGIN, true, 1.0, true, 300.0);
    ExplosionRadius = CreateConVar("explosion_radius", "800", "The radius of the explosion", FCVAR_PLUGIN, true, 0.0);
    CenterExplosionDamage = CreateConVar("explosion_damage", "500", "The damage the explosion makes at the center of the explosion", FCVAR_PLUGIN, true, 0.0);
    LookAngle = CreateConVar("bomb_look_angle", "45", "The Highest angle (up/down) to look for being able to plant/defuse the bomb, less is higher", FCVAR_PLUGIN, true, -89.0, true, 89.0);
    RedWinTime = CreateConVar("red_round_time", "360", "The time red have to defend the CP", FCVAR_PLUGIN, true, 300.0, true, 900.0);
    BombRetrieveTime = CreateConVar("bomb_return_time", "90", "The time it takes for the bomb to automatically retrieved", FCVAR_PLUGIN, true, 0.1, true, 240.0);

    AddCommandListener(cmd_drop2, "dropitem");
    RegConsoleCmd("sm_drop", cmd_drop);
    RegConsoleCmd("sm_bombhelp", cmd_help);

    RegAdminCmd("sm_spawnbomb", cmd_bomb, ADMFLAG_ROOT);
    RegAdminCmd("sm_force_drop", cmd_forcedrop, ADMFLAG_ROOT);

    HookEvent("controlpoint_starttouch", Event_CPStartTouch, EventHookMode_Pre);
    HookEvent("controlpoint_endtouch", Event_CPEndTouch, EventHookMode_Pre);
    HookEvent("teamplay_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
    HookEvent("teamplay_restart_round", Event_Roundstart, EventHookMode_PostNoCopy);
    HookEvent("arena_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public Action:cmd_help(client, args)
{
    if (client != 0)
    {
        Case[client] = 0;
        DisplayHelp(client);
    }
    return Plugin_Handled;
}

public Action:cmd_drop2(client, const String:command[], argc)
{
    if (client != 0 && ClientHaveBomb[client] && IsPlayerAlive(client))
    {
        Dropbomb(client, false);
    }
}

public Action:cmd_forcedrop(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_force_drop <#userid|name>");
        return Plugin_Handled;
    }
    
    decl String:arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

    if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    
    for (new i = 0; i < target_count; i++)
    {
        new c = target_list[i];
        if (ClientHaveBomb[c])
        {
            Dropbomb(c, false, true);
        }
    }
    return Plugin_Handled;
}

public Action:cmd_drop(client, args)
{
    if (client != 0 && ClientHaveBomb[client] && IsPlayerAlive(client))
    {
        Dropbomb(client, false);
    }
    return Plugin_Handled;
}

public OnClientDisconnect(client)
{
    if (ClientHaveBomb[client])
    {
        ClientHaveBomb[client] = false;
        Dropbomb(client);
    }
    Case[client] = 0;
    ShowHelp[client] = true;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client_id = GetEventInt(event, "userid");
    new client = GetClientOfUserId(client_id);
    
    if (ShowHelp[client])
    {
        DisplayHelp(client);
    }
    
    if ((NooneHaveBomb && !IsFakeClient(client) && GetClientTeam(client) == 3))
    {
        NooneHaveBomb = false;
        ClientHaveBomb[client] = true;
        SetEntityRenderColor(client, 0, 0, 0);
        PrintCenterText(client, "You have the bomb");
        CreateTimer(1.0, timer_checkbomb);
        return Plugin_Continue;
    }
    if (ClientHaveBomb[client] && GetClientTeam(client) == 2)
    {
        SetEntityRenderColor(client);
        ClientHaveBomb[client] = false;
        GiveBlueBomb();
        return Plugin_Continue;
    }
    if (ClientHaveBomb[client])
    {
        SetEntityRenderColor(client, 0, 0, 0);
        return Plugin_Continue;
    }
    SetEntityRenderColor(client);
    return Plugin_Continue;
}

public HelpHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {        
        switch (param2)
        {
            case 1: Case[param1]++;
            case 2: Case[param1]--;
            default:
            {
                ShowHelp[param1] = false;
                return;
            }
        }

        DisplayHelp(param1);
    }
}

DisplayHelp(client)
{
    new Handle:panel = CreatePanel();
    new cse = Case[client];
    switch (cse)
    {
        case 0:
        {
            SetPanelTitle(panel, "Goal");
            DrawPanelText(panel, "The aim of the game is for the blues \nto plant the bomb on the control point, \nand for the reds to defend the point \nand defuse the bomb.\n");
        }
        case 1:
        {
            SetPanelTitle(panel, "Planting the bomb");
            DrawPanelText(panel, "To plant the bomb, check that you \nhave the bomb, then crouch on the \ncontrol point, look down and \nhold down +attack2-button (mouse2 is the default), \ndo the same combination near the bomb to defuse it.\n");
        }
        case 2:
        {
            SetPanelTitle(panel, "Dropping the bomb");
            DrawPanelText(panel, "You can drop the bomb with the \ndropitem command (default l, same as \nthe one used for dropping intelligence) \nor typing \"/drop\" into the chat.\n");
        }
        case 3:
        {
            SetPanelTitle(panel, "Class features:");
            DrawPanelText(panel, "Demoman plants twice as fast \nEngineer defuses twice as fast.\n");
        }
    }

    if (cse != 3)
    {
        DrawPanelItem(panel, "Next");
    }
    else
    {
        DrawPanelItem(panel, "Next", ITEMDRAW_DISABLED);
    }
    if (cse != 0)
    {
        DrawPanelItem(panel, "Back", ITEMDRAW_CONTROL);
    }
    else
    {
        DrawPanelItem(panel, "Back", ITEMDRAW_DISABLED);
    }
    DrawPanelItem(panel, "Exit", ITEMDRAW_CONTROL);
    SendPanelToClient(panel, client, HelpHandler, 20);
    CloseHandle(panel);
}

public Action:timer_checkbomb(Handle:timer)
{
    decl i, c, count, indexes[MAXPLAYERS+1];
    count = 0;
    for (i = 0; i <= MaxClients; i++)
    {
        if (ClientHaveBomb[i])
        {
            indexes[i] = i;
            count++;
        }
    }
    if (count > 1)
    {
        for (i = 1; i < count; i++)
        {
            c = indexes[i];
            ClientHaveBomb[c] = false;
            SetEntityRenderColor(c);
            PrintCenterText(c, "There was unfortunately more than 1 bomb, removing your bomb");
        }
    }
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client_id = GetEventInt(event, "userid");
    new client = GetClientOfUserId(client_id);
    SetEntityRenderColor(client);
    if (ClientHaveBomb[client])
    {
        Dropbomb(client);
    }
    return Plugin_Continue;
}

public Action:Event_Roundstart(Handle:event, const String:name[], bool:dontBroadcast)
{
    round++;
    //MapIsSet = false;
    //Planted = false;
    decl client;

    for (client = 0; client <= MaxClients; client++)
    {
        if (plantdefuse[client] != INVALID_HANDLE)
        {
            KillTimer(plantdefuse[client]);
            plantdefuse[client] = INVALID_HANDLE;
        }
        if (ClientHaveBomb[client])
        {
            ClientHaveBomb[client] = false;
        }
        PlantTimeF[client] = 0.0;
    }
    if (BombTimer != INVALID_HANDLE)
    {
        KillTimer(BombTimer);
        BombTimer = INVALID_HANDLE;
    }
    bomb = -1;
    droppedbomb = -1;
    if (RestTimer != INVALID_HANDLE)
    {
        KillTimer(RestTimer);
        RestTimer = INVALID_HANDLE;
    }
    GiveBlueBomb();
    DisableControlPoints();
    CreateTimer(3.0, timer_checkbomb);
    if (RedWin != INVALID_HANDLE)
    {
        KillTimer(RedWin);
        RedWin = INVALID_HANDLE;
    }
    RedWin = CreateTimer(GetConVarFloat(RedWinTime), timer_RedWin);
}

public Action:timer_RedWin(Handle:timer)
{
    SetWinningTeam(2);
    KillTimer(RedWin);
    RedWin = INVALID_HANDLE;
}

public Action:Event_CPEndTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetEventInt(event, "player");
    InBombArea[client] = false;
}

public Action:Event_CPStartTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetEventInt(event, "player");
    /*if (!Planted)
    {
        area = GetEventInt(event, "area");
    }*/
    InBombArea[client] = true;
}

public Action:cmd_bomb(client, args)
{
    DropBombAdmin(client, GetClientTeam(client));
    return Plugin_Handled;
}

public OnClientPutInServer(client)
{
    ClientHaveBomb[client] = false;
    plantdefuse[client] = INVALID_HANDLE;
}

public OnMapStart()
{
    PrecacheModel(BOMB1, true);
    PrecacheSound(BOMB_SOUND, true);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if ((buttons & IN_ATTACK2) && (buttons & IN_DUCK))
    {
        PlantingClient = client;
        
        if (Planting[client])
        {
            if (PlantTimeF[client] == 0.0)
            {
                PlantTimeF[client] = GetEngineTime();
            }
            SetEntityMoveType(client, MOVETYPE_NONE);
            NoMove[client] = true;
            return Plugin_Continue;
        }
    }
    else
    {
        PlantingClient = 0;
        if (plantdefuse[client] != INVALID_HANDLE)
        {
            KillTimer(plantdefuse[client]);
            plantdefuse[client] = INVALID_HANDLE;
        }
    }
    
    if (NoMove[client])
    {
        PlantTimeF[client] = 0.0;
        SetEntityMoveType(client, MOVETYPE_WALK);
        NoMove[client] = false;
    }
    Planting[client] = false;
    if (plantdefuse[client] != INVALID_HANDLE)
    {
        KillTimer(plantdefuse[client]);
        plantdefuse[client] = INVALID_HANDLE;
    }
    return Plugin_Continue;
}
   
public OnGameFrame()
{
    decl i;
    for (i = 1; i <= MaxClients; i++)
    {
        if (PlantingClient == i)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                decl Float:ang[3], Float:lookang;
                GetClientEyeAngles(i, ang);
                lookang = GetConVarFloat(LookAngle);
                if (ang[0] >= lookang && (GetEntityFlags(i) & FL_ONGROUND))
                {
                    decl team;
                    team = GetClientTeam(i);
                    if (team == 3 && InBombArea[i] && ClientHaveBomb[i])
                    {
                        Planting[i] = true;
                        if (plantdefuse[i] == INVALID_HANDLE)
                        {
                            plantdefuse[i] = CreateTimer(0.1, planttimer, i, TIMER_REPEAT);
                        }
                    }
                    else if (team == 2 && !BombDropped)
                    {
                        decl Float:pos[3];
                        GetClientAbsOrigin(i, pos);
                        decl Float:distance;
                        distance = GetVectorDistance(pos, BombLoc);
                        if (distance < 45.0)
                        {
                            Planting[i] = true;
                            if (plantdefuse[i] == INVALID_HANDLE)
                            {
                                plantdefuse[i] = CreateTimer(0.1, defusetimer, i, TIMER_REPEAT);
                            }
                        }
                    }
                }
                else
                {
                    Planting[i] = false;
                    if (plantdefuse[i] != INVALID_HANDLE)
                    {
                        KillTimer(plantdefuse[i]);
                        plantdefuse[i] = INVALID_HANDLE;
                    }
                }
            }
        }
        if (BombDropped && droppedbomb != -1)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
            {
                decl Float:pos[3];
                GetClientAbsOrigin(i, pos);
                decl Float:distance;
                distance = GetVectorDistance(BombLoc, pos);
                if (distance < 20.0 && i != BombDropper)
                {
                    ClientHaveBomb[i] = true;
                    SetEntityRenderColor(i, 0, 0, 0);
                    BombDropped = false;
                    PrintCenterText(i, "You picked up the bomb");
                    RemoveEdict(droppedbomb);
                    droppedbomb = -1;
                    if (RestTimer != INVALID_HANDLE)
                    {
                        KillTimer(RestTimer);
                        RestTimer = INVALID_HANDLE;
                    }
                }
            }
        }
    }
}

public Action:defusetimer(Handle:timer, any:client)
{
    if (Planting[client] && IsPlayerAlive(client))
    {
        decl Float:time, Float:deftime, Float:diff, percent;
        
        deftime = GetConVarFloat(DefuseTime);
        if (TF2_GetPlayerClass(client) == TFClass_Engineer)
        {
            deftime /= 2.0;
        }
        time = GetEngineTime();
        diff = time - PlantTimeF[client];
        percent = RoundFloat(diff / deftime * 100.0);
        PrintCenterText(client, "%i%s defuse process", percent < 0 ? 0 : percent > 100 ? 100 : percent, "%");
        
        if (diff >= deftime)
        {
            if (IsValidEdict(bomb))
            {
                RemoveEdict(bomb);
                bomb = -1;
            }
            BombLoc[0] = 0.0;
            BombLoc[1] = 0.0;
            BombLoc[2] = 0.0;
            SetWinningTeam(2);
            PlantTimeF[client] = 0.0;
            Planting[client] = false;
            KillTimer(plantdefuse[client]);
            plantdefuse[client] = INVALID_HANDLE;
            KillTimer(BombTimer);
            BombTimer = INVALID_HANDLE;
        }
    }
    else
    {
        Planting[client] = false;
        KillTimer(plantdefuse[client]);
        plantdefuse[client] = INVALID_HANDLE;
    }
}

public Action:planttimer(Handle:timer, any:client)
{
    if (Planting[client] && IsPlayerAlive(client))
    {
        decl Float:time, Float:platime, Float:diff, percent;
        
        platime = GetConVarFloat(PlantTime);
        if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
        {
            platime /= 2.0;
        }
        time = GetEngineTime();
        diff = time - PlantTimeF[client];
        percent = RoundFloat(diff / platime * 100.0);
        PrintCenterText(client, "%i%s plant process", percent < 0 ? 0 : percent > 100 ? 100 : percent, "%");
        if (diff >= platime)
        {
            if (RedWin != INVALID_HANDLE)
            {
                KillTimer(RedWin);
                RedWin = INVALID_HANDLE;
            }
            DropBomb(client);
            SetEntityRenderColor(client);
            PlantTimeF[client] = 0.0;
            ClientHaveBomb[client] = false;
            Planting[client] = false;
            KillTimer(plantdefuse[client]);
            plantdefuse[client] = INVALID_HANDLE;
        }
    }
    else
    {
        Planting[client] = false;
        KillTimer(plantdefuse[client]);
        plantdefuse[client] = INVALID_HANDLE;
    }
}

stock DropBomb(client, team=3)
{
    GetClientAbsOrigin(client, BombLoc);

    if (IsValidEdict(bomb))
    {
        return;
    }
            
    if (BombTimer != INVALID_HANDLE)
    {
        return;
    }
        
    bomb = CreateEntityByName("prop_dynamic_override");
    
    if (bomb)
    {
        decl Float:ang[3], String:skin[64];
        GetClientAbsAngles(client, ang);
        FixAngles(ang);
        
        IntToString(team-2, skin, sizeof(skin));

        TeleportEntity(bomb, BombLoc, ang, NULL_VECTOR);
        if (!IsModelPrecached(BOMB1))
        {
            PrecacheModel(BOMB1);
        }

        DispatchKeyValue(bomb, "model", BOMB1);
        DispatchKeyValue(bomb, "skin", skin);
        DispatchKeyValue(bomb, "targetname", "bomb");

        DispatchSpawn(bomb);

        BombPlaceTime = GetEngineTime();
        BombTimer = CreateTimer(0.1, timer_bomb, round, TIMER_REPEAT);
        //Planted = true;
        PrintCenterTextAll("The bomb has been planted!");
    }
}

public Action:timer_bomb(Handle:timer, any:oRound)
{
    decl Float:time, Float:diff, Float:bombtime;
    decl rounded;

    bombtime = GetConVarFloat(BombTime);
    time = GetEngineTime();
    diff = time - BombPlaceTime;
    rounded = RoundToFloor(bombtime-diff);
    if (diff >= bombtime)
    {
        if (oRound == round)
        {
            Explosion();
            if (bomb != -1)
            {
                RemoveEdict(bomb);
                bomb = -1;
            }
            BombLoc[0] = 0.0;
            BombLoc[1] = 0.0;
            BombLoc[2] = 0.0;
            if (BombTimer != INVALID_HANDLE)
            {
                KillTimer(BombTimer);
                BombTimer = INVALID_HANDLE;
            }
        }
        else
        {
            bomb = -1;
        }
    }
    else if (rounded == 20 || rounded == 15 || rounded <= 10)
    {
        PrintCenterTextAll("%i seconds until the bomb explodes", rounded);
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
        else
        {
            LogError("Bomb: Couldn't remove explosion - not a particle '%s'", classname);
        }
    }
}

Explosion()
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, BombLoc, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", "cinefx_goldrush");
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(0.5, DeleteParticles, particle);
        if (!IsSoundPrecached(BOMB_SOUND))
        {
            PrecacheSound(BOMB_SOUND);
        }
        PrefetchSound(BOMB_SOUND);
        EmitAmbientSound(BOMB_SOUND, BombLoc, bomb, SNDLEVEL_SCREAMING);
        //SetCPBlue();
        Damage();
        //Planted = false;
        //GiveBlueBomb();
        //SetCPBlue();
        SetWinningTeam(3);
    }
    else
    {
        LogError("Bomb: Couldn't create explosion");
    }
}

Damage()
{
    decl Float:radius, Float:dmg;
    
    radius = GetConVarFloat(ExplosionRadius);
    dmg = GetConVarFloat(CenterExplosionDamage);
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            decl Float:pos[3], Float:bl[3], Float:dist;
            
            bl = BombLoc;
            bl[2] += 64;
            
            GetClientAbsOrigin(i, pos);
            dist = GetVectorDistance(pos, bl);
            
            if (dist <= radius)
            {
                new Handle:Tracing = TR_TraceRayFilterEx(bl, pos, MASK_SOLID, RayType_EndPoint, AllowPlayers);//TR_TraceRayEx(bl, pos, MASK_SOLID_BRUSHONLY, RayType_EndPoint);
                decl index;
                index = TR_GetEntityIndex(Tracing);
                if (index == -1 || index == i)
                {
                    decl damage;
                    damage = RoundFloat(dmg * (radius - dist) / radius);
                    SlapPlayer(i, damage, false);
                    continue;
                }
                CloseHandle(Tracing);
            }
            
            GetClientEyePosition(i, pos);
            dist = GetVectorDistance(pos, bl);
            if (dist <= radius)
            {
                new Handle:Tracing = TR_TraceRayFilterEx(bl, pos, MASK_SOLID, RayType_EndPoint, AllowPlayers);//TR_TraceRayEx(bl, pos, MASK_SOLID_BRUSHONLY, RayType_EndPoint);
                decl index;
                index = TR_GetEntityIndex(Tracing);
                if (index == -1 || index == i)
                {
                    decl damage;
                    damage = RoundFloat(dmg * (radius - dist) / radius);
                    SlapPlayer(i, damage, false);
                }
                CloseHandle(Tracing);
            }
        }
    }
}

stock SetWinningTeam(team)
{
    new ent = -1;
    ent = FindEntityByClassname(-1, "team_control_point_master");

    if (ent == -1)
    {
        ent = CreateEntityByName("team_control_point_master");
        DispatchKeyValue(ent, "switch_teams", "1");
        DispatchSpawn(ent);
        AcceptEntityInput(ent, "Enable");
    }
    SetEntProp(ent, Prop_Data, "m_bSwitchTeamsOnWin", 1, 1);
    SetVariantInt(team);
    AcceptEntityInput(ent, "SetWinner");
}

stock SetCPBlue()
{    
    new ent = -1;
    
    while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
    {
        if (area == GetEntProp(ent, Prop_Data, "m_iPointIndex", 4))
        {
            setcpteam(ent, 3);
        }
    }
}

stock setcpteam(entity, team)
{
    if(IsValidEdict(entity))
    {
        new String:addoutput[64];
        Format(addoutput, sizeof(addoutput), "OnUser1 !self:setowner:%i:0:1",team);
        SetVariantString(addoutput);
        AcceptEntityInput(entity, "AddOutput");
        AcceptEntityInput(entity, "FireUser1");
        AcceptEntityInput(entity, "OnCapTeam2");
    }
}

DisableControlPoints()
{    
    new ent = -1;
    while ((ent = FindEntityByClassname(ent, "trigger_capture_area")) != -1)
    {
        AcceptEntityInput(ent, "Enable");
        SetVariantString("2 0");
        AcceptEntityInput(ent, "SetTeamCanCap");
        SetVariantString("3 0");
        AcceptEntityInput(ent, "SetTeamCanCap");
    }
    while ((ent = FindEntityByClassname(ent, "team_round_timer")) != -1)
    {
        SetVariantString("OnSetupFinished !self:kill::0:1");
        AcceptEntityInput(ent, "AddOutput");
    }
    //MapIsSet = true;
}

stock DropBombAdmin(client, team)
{
    decl Float:pos[3], Float:bpt;
    if (!LookPoint(client, pos))
        return 0;
    
    new admbomb;
    
    admbomb = CreateEntityByName("prop_physics_override");
    
    if (admbomb) {
        decl Float:ang[3], String:skin[64];
        GetClientAbsAngles(client, ang);
        FixAngles(ang);
        
        IntToString(team-2, skin, sizeof(skin));

        TeleportEntity(admbomb, pos, ang, NULL_VECTOR);
        if (!IsModelPrecached(BOMB1))
        {
            PrecacheModel(BOMB1);
        }
        
        DispatchKeyValue(admbomb, "model", BOMB1);
        DispatchKeyValue(admbomb, "skin", skin);
        DispatchKeyValue(admbomb, "targetname", "bomb");
        
        DispatchSpawn(admbomb);
        
        bpt = GetEngineTime();
        decl String:info[256];

        Format(info, sizeof(info), "%i", round);
        new Handle:pack;
        CreateDataTimer(0.1, timer_admbomb, pack, TIMER_REPEAT);
        WritePackCell(pack, admbomb);
        WritePackFloat(pack, bpt);
        WritePackString(pack, info);
        
        PrintCenterTextAll("An admin bomb has been placed somewhere in the map! Watch out!");
    }
    return 0;
}

public Action:timer_admbomb(Handle:timer, Handle:pack)
{
    decl Float:time, Float:diff, Float:bombtime;
    
    decl Float:pos[3], admbomb, Float:bpt, oRound;
    
    decl String:info[256];
    
    ResetPack(pack);
    admbomb = ReadPackCell(pack);
    bpt = ReadPackFloat(pack);
    ReadPackString(pack, info, sizeof(info));
    
    oRound = StringToInt(info);
    
    if (oRound != round)
    {
        return Plugin_Stop;
    }
    
    bombtime = GetConVarFloat(BombTime);
    time = GetEngineTime();
    diff = time - bpt;
    
    if (diff >= bombtime)
    {
        GetEntityAbsOrigin(admbomb, pos);
        AdmExplosion(pos, admbomb);
        if (IsValidEdict(admbomb))
        {
            RemoveEdict(admbomb);
        }
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

AdmExplosion(Float:pos[3], admbomb) 
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", "cinefx_goldrush");
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(0.5, DeleteParticles, particle);
        
        if (!IsSoundPrecached(BOMB_SOUND))
        {
            PrecacheSound(BOMB_SOUND);
        }
            
        PrefetchSound(BOMB_SOUND);
        
        EmitAmbientSound(BOMB_SOUND, pos, admbomb, SNDLEVEL_SCREAMING);

        AdmDamage(pos);
    }
    else
    {
        LogError("Bomb: Couldn't create explosion");
    } 
}

AdmDamage(Float:po[3])
{
    decl Float:radius, Float:dmg;
    
    radius = GetConVarFloat(ExplosionRadius);
    dmg = GetConVarFloat(CenterExplosionDamage);
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            decl Float:pos[3], Float:bl[3], Float:dist;

            bl = po;
            bl[2] += 64;

            GetClientAbsOrigin(i, pos);
            dist = GetVectorDistance(pos, bl);

            if (dist <= radius)
            {
                new Handle:Tracing = TR_TraceRayFilterEx(bl, pos, MASK_SOLID, RayType_EndPoint, AllowPlayers);
                decl index;
                index = TR_GetEntityIndex(Tracing);
                if (index == -1 || index == i)
                {
                    decl damage;
                    damage = RoundFloat(dmg * (radius - dist) / radius);
                    SlapPlayer(i, damage, false);
                    continue;
                }
                CloseHandle(Tracing);
            }

            GetClientEyePosition(i, pos);
            dist = GetVectorDistance(pos, bl);
            if (dist <= radius)
            {
                new Handle:Tracing = TR_TraceRayFilterEx(bl, pos, MASK_SOLID, RayType_EndPoint, AllowPlayers);
                decl index;
                index = TR_GetEntityIndex(Tracing);
                if (index == -1 || index == i)
                {
                    decl damage;
                    damage = RoundFloat(dmg * (radius - dist) / radius);
                    SlapPlayer(i, damage, false);
                }
                CloseHandle(Tracing);
            }
        }
    }
}

public bool:AllowPlayers(entity, mask)
{
    return entity >= 1 && entity <= MaxClients;
}

stock GiveBlueBomb()
{
    new i, client, bool:GaveBomb = false, bool:AnyBlues = false;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (IsPlayerAlive(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
            {
                AnyBlues = true;
                break;
            }
        }
    }
    
    if (AnyBlues)
    {
        while (!GaveBomb)
        {
            client = GetRandomInt(1, MaxClients);
            if (IsClientInGame(client))
            {
                if (IsPlayerAlive(client) && GetClientTeam(client) == 3 && !IsFakeClient(i))
                {
                    SetEntityRenderColor(client, 0, 0, 0);
                    ClientHaveBomb[client] = true;
                    NooneHaveBomb = false;
                    GaveBomb = true;
                    PrintCenterText(client, "You have the bomb!");
                }
            }
        }
    }
    else
    {
        NooneHaveBomb = true;
    }
}

stock FixAngles(Float:ang[3])
{
    ang[1] += 90.0;
    if (ang[1] > 180.0)
    {
        ang[1] -= 360.0;
    }
    ang[0] = 0.0;
}

stock bool:LookPoint(client, Float:dest[3])
{
    decl Float:ang[3];
    decl Float:pos[3];
    decl Float:fwd[3];
    decl Float:pos2[3];
    decl Float:dist;
    
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, ang);

    new Handle:trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, FilterPlayer);

    if(TR_DidHit(trace))
    {        
        TR_GetEndPosition(pos2, trace);
        GetVectorDistance(pos, pos2);
        dist = -15.0;
        GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
        dest[0] = pos2[0] + (fwd[0] * dist);
        dest[1] = pos2[1] + (fwd[1] * dist);
        dest[2] = pos2[2] + (fwd[2] * dist);
    }
    else
    {
        CloseHandle(trace);
        return false;
    }
    
    CloseHandle(trace);
    return true;
}

public bool:FilterPlayer(entity, mask)
{
    return entity > GetMaxClients() || !entity;
}

GetEntityAbsOrigin(entity,Float:origin[3])
{ 
    decl Float:mins[3], Float:maxs[3];

    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);

    origin[0] += (mins[0] + maxs[0]) * 0.5;
    origin[1] += (mins[1] + maxs[1]) * 0.5;
    origin[2] += (mins[2] + maxs[2]) * 0.5;
}

stock Dropbomb(client, bool:discondeath=true, bool:forcedrop=false)
{
    decl team, String:skin[64], Float:ang[3];
    
    droppedbomb = CreateEntityByName("prop_dynamic_override");
    
    if (droppedbomb)
    {
        BombDropPos(client, BombLoc);
        GetClientAbsAngles(client, ang);
        FixAngles(ang);
        TeleportEntity(droppedbomb, BombLoc, ang, NULL_VECTOR);

        team = GetClientTeam(client);
        IntToString(team-2, skin, sizeof(skin));
        DispatchKeyValue(droppedbomb, "model", BOMB1);
        DispatchKeyValue(droppedbomb, "skin", skin);

        DispatchSpawn(droppedbomb);
        
        SetEntityRenderColor(client);

        ClientHaveBomb[client] = false;
        
        if (forcedrop)
        {
            PrintCenterText(client, "You have been forced to drop the bomb");
        }
        else
        {
            PrintCenterText(client, "You have dropped the bomb");
        }
        
        if (discondeath)
        {
            BombDropper = -1;
        }
        else
        {
            BombDropper = client;
        }
            
        CreateTimer(3.0, ResetDropper, BombDropper);
        RestTimer = CreateTimer(GetConVarFloat(BombRetrieveTime), restorebomb);
        BombDropped = true;
    }
}

public Action:restorebomb(Handle:timer)
{
    if (droppedbomb != -1)
    {
        RemoveEdict(droppedbomb);
        droppedbomb = -1;
        GiveBlueBomb();
    }
    if (RestTimer != INVALID_HANDLE)
    {
        KillTimer(RestTimer);
        RestTimer = INVALID_HANDLE;
    }
}

public Action:ResetDropper(Handle:timer, any:originalbombdropper)
{
    BombDropper = originalbombdropper == BombDropper ? -1 : BombDropper;
}

stock bool:BombDropPos(client, Float:dest[3])
{
    decl Float:ang[3], Float:pos[3], /*Float:fwd[3], */Float:pos2[3]/*, Float:dist*/;
    
    GetClientAbsOrigin(client, pos);
    ang[0] = 90.0;
    ang[1] = 0.0;
    ang[2] = 0.0;

    new Handle:trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, FilterPlayer);

    if(TR_DidHit(trace))
    {        
        TR_GetEndPosition(pos2, trace);
        GetVectorDistance(pos, pos2);

        //GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
        dest[0] = pos2[0];
        dest[1] = pos2[1];
        dest[2] = pos2[2];
    }
    else
    {
        CloseHandle(trace);
        return false;
    }
    
    CloseHandle(trace);
    return true;
}