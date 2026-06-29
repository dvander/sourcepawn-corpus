//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION "0.8"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"

// INTS
new g_Tanks = 0;
new g_MaxTanks = 4;
new g_MpMode = 0;
new g_Gamemode = 0;
new g_SurvivalTime = 0;
new g_EnemyTime = 0;
new g_DefaultMode = 4;

// FLOATS
new Float:g_StartTime = 0.0;
new Float:g_FreqMulti = 1.0;
new Float:g_Help = 0.0;

// BOOLS
new bool:g_Started = false;
new bool:g_Active = true;
new bool:g_Allow = false;
new bool:g_l4d1 = false;

// HANDLES
new Handle:cvarEnable;
new Handle:cvarFreq;
new Handle:cvarBurnTime;
new Handle:cvarBurnSlowdown;
new Handle:cvarStun;
new Handle:cvarBoom;
new Handle:cvarBoomBot;
new Handle:cvarBoomPlayer;
new Handle:cvarInfo;
new Handle:cvarKillTanks;
new Handle:cvarGrenade;

// ARRAYS
new g_PlayerBurn[MAXPLAYERS+1];
new g_PlayerStun[MAXPLAYERS+1];
new g_PlayerBoom[MAXPLAYERS+1];
new g_Points[MAXPLAYERS+1];
new g_Info[MAXPLAYERS+1];
new bool:g_Vote[MAXPLAYERS+1];
new bool:g_HasMenu[MAXPLAYERS+1];

new g_StatsBurn[MAXPLAYERS+1];
new g_StatsBoom[MAXPLAYERS+1];
new Float:g_StatsStun[MAXPLAYERS+1];
new g_StatsStun2[MAXPLAYERS+1];
new g_StatsPunch[MAXPLAYERS+1];
new g_StatsRock[MAXPLAYERS+1];
new g_StatsBreak[MAXPLAYERS+1];
new g_StatsFall[MAXPLAYERS+1];

// OF INTEREST
// survival_tank_stage_interval_decay = 20.0
// survival_tank_multiple_spawn_delay = 10.0
// pipe_bomb_projectile

public Plugin:myinfo = {
    name = "Invincible Tank Survival 2",
    author = "Mecha the Slag",
    description = "Gamemode",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    // G A M E  C H E C K //
    decl String:game[32];
    GetGameFolderName(game, sizeof(game));
    g_l4d1 = false;
    if(StrEqual(game, "left4dead")) g_l4d1 = true;

    cvarEnable = CreateConVar("its_enable", "1", "Enable Invincible Tank Survival (0: Disable, 1: Enable)");
    cvarFreq = CreateConVar("its_frequency", "25.0", "Time in seconds between each forced tank spawn. If 0, no additional tanks will spawn.");
    cvarBurnTime = CreateConVar("its_burn_time", "15.0", "Time in seconds until the tank is extinguished and his speed recovered.");
    cvarBurnSlowdown = CreateConVar("its_burn_speed", "0.75", "Burn speed penalty (relative).");
    cvarStun = CreateConVar("its_stun", "2", "Stun method. 0 = none, 1 = everyone (including teammates), 2 = yourself and enemies, 3 = enemies only.");
    cvarBoom = CreateConVar("its_boom_bug", "0.2", "Interval between bugging while boomer biled. 0 for none.");
    cvarBoomBot = CreateConVar("its_boom_strength_bot", "6.0", "Bugging strength on bots. Should be more than for human players. 0 disables.");
    cvarBoomPlayer = CreateConVar("its_boom_strength_player", "0.05", "Bugging strength on players. 0 disables.");
    cvarInfo = CreateConVar("its_info", "2", "Number of times to show info message. 0 to disable.");
    cvarKillTanks = CreateConVar("its_kill_tanks", "1", "Kill tanks when spawning during unintended times?");
    cvarGrenade = CreateConVar("its_weapon_grenadelauncher", "0.75", "Grenade launcher flight strength");
    CreateConVar("its_version", PLUGIN_VERSION, "[ITS2] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    HookConVarChange(cvarEnable, ConVarActivate);
    HookEvent("round_start_post_nav", Map_Restart);
    HookEvent("create_panic_event", ITS_Activate);
    HookEvent("finale_start", ITS_Activate);
    HookEvent("player_spawn", Player_Spawn);
    HookEvent("player_death", Player_Death);
    HookEvent("player_hurt",Event_TankOnFire);
    HookEvent("player_now_it",Event_PlayerNowIt);
    HookEvent("break_breakable",Event_Breakbreakable);
    HookEvent("player_falldamage",Event_FallDamage);
    HookEvent("player_hurt",Event_PlayerHurt);
    HookEvent( "player_left_start_area", Event_LeaveStartArea);
    HookEvent( "player_left_checkpoint", Event_LeaveStartArea);
    HookEvent("player_entered_checkpoint", Player_Entered_Checkpoint);
    HookEvent("mission_lost", Mission_Lost);
    if (!g_l4d1) {
        HookEvent("finale_bridge_lowering", ITS_Activate);
    }
    AttemptEnable(false);
    resetPoints();
    resetStats();
    RegAdminCmd("its_test", Command_points, ADMFLAG_GENERIC, "Test command");
    
    RegConsoleCmd("mode", Cmd_Menu, "Change [ITS2] Gamemode!");
    RegConsoleCmd("votemode", Cmd_Menu, "Change [ITS2] Gamemode!");
    RegConsoleCmd("changemode", Cmd_Menu, "Change [ITS2] Gamemode!");
    
    // HUD
    CreateTimer(0.1, DisplayHuds);
}

public Action:Command_Force(client, args) {
    g_Gamemode = 4;
    PrintToChatAll("[ITS2] gamemode changed");
    return Plugin_Handled;
}

public Action:Command_Force2(client, args) {
    ActivateITSNow();
    return Plugin_Handled;
}

public OnMapStart() {
    g_DefaultMode = 4;
    g_Help = 0.0;
    new String:map[128];
    GetCurrentMap(map, sizeof(map));
    
    if (StrEqual(map, "c1m4_atrium")) g_DefaultMode = 1;
    if (StrEqual(map, "c2m5_concert")) g_DefaultMode = 1;
    if (StrEqual(map, "c3m4_plantation")) g_DefaultMode = 1;
    if (StrEqual(map, "c4m5_milltown_escape")) g_DefaultMode = 1;
    if (StrEqual(map, "c5m5_bridge")) g_DefaultMode = 1;
    if (StrEqual(map, "c6m3_port")) g_DefaultMode = 1;
    if (StrEqual(map, "l4d_vs_airport05_runway")) g_DefaultMode = 1;
    if (StrEqual(map, "l4d_vs_farm05_cornfield")) g_DefaultMode = 1;
    if (StrEqual(map, "l4d_vs_hospital05_rooftop")) g_DefaultMode = 1;
    if (StrEqual(map, "l4d_vs_smalltown05_houseboat")) g_DefaultMode = 1;
    
    if (g_Gamemode > 0 && g_Gamemode != 2) g_Gamemode = g_DefaultMode;
    
    for(new i = 1; i <= MaxClients; i++) {
        if(IsValidClient(i)) {
            g_HasMenu[i] = false;
        }
    }
}

public Action:ChangeToAllow(Handle:hTimer) {
    g_Allow = true;
}

public OnMapEnd() {
    g_Allow = false;
}

resetPoints() {
    for (new i = 1; i <= MaxClients; i++) {
            g_Points[i] = 0;
    }
}

resetStats() {
    for (new i = 1; i <= MaxClients; i++) {
            g_StatsBurn[i] = 0;
            g_StatsBoom[i] = 0;
            g_StatsStun[i] = 0.0;
            g_StatsStun2[i] = 0;
            g_StatsPunch[i] = 0;
            g_StatsRock[i] = 0;
            g_StatsBreak[i] = 0;
            g_StatsFall[i] = 0;
    }
}

public Mission_Lost(Handle:event, const String:name[], bool:dontBroadcast) {
    if ((g_Gamemode == 4 || g_Gamemode == 1) && g_Started) g_Help += 5.0;
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_PlayerBurn[client] = false;
    g_PlayerStun[client] = false;
    g_PlayerBoom[client] = false;
    
    if (g_Active) {
        
        if (GetClientTeam(client) == 3 && !IsPlayerTank(client)) ForcePlayerSuicide(client);
        if (IsPlayerTank(client) && g_Started == false && GetConVarBool(cvarKillTanks)) ForcePlayerSuicide(client);
        if (IsPlayerTank(client) && g_Tanks >= g_MaxTanks && IsFakeClient(client) && GetConVarBool(cvarKillTanks)) ForcePlayerSuicide(client);
        
        if (GetClientTeam(client) == 3 && IsPlayerTank(client) && g_Started && (g_Gamemode != 4)) {
            g_Tanks += 1;
            if (IsFakeClient(client)) PrintToChatAll("[ITS2] New Tank (%d)!", g_Tanks);
            else CPrintToChatAllEx(client, "[ITS2] New Tank: {teamcolor}%N{default} (%d)!", client, g_Tanks);
        }
        
        if (g_Info[client] < GetConVarInt(cvarInfo) && (!IsFakeClient(client))) {
            new String:infotext[512];
            Format(infotext, sizeof(infotext), "Welcome to [INVINCIBLE TANK SURVIVAL 2]!");
            if (g_Gamemode == 1) Format(infotext, sizeof(infotext), "%s\nYou are playing: %s\nYour goal is to stay alive longer than your teammates!", GetModeName(g_Gamemode), infotext);
            if (g_Gamemode == 2) Format(infotext, sizeof(infotext), "%s\nYou are playing: %s\nYour goal is to stay alive longer than the opponent team!", GetModeName(g_Gamemode), infotext);
            if (g_Gamemode == 3) Format(infotext, sizeof(infotext), "%s\nYou are playing: %s\nYour goal is to stay alive as long as possible as a team!", GetModeName(g_Gamemode), infotext);
            if (g_Gamemode == 4) Format(infotext, sizeof(infotext), "%s\nYou are playing: %s\nYour goal is to run to the safe room without getting killed!", GetModeName(g_Gamemode), infotext);
            PrintHintText(client, infotext);
            g_Info[client] += 1;
        }
    }
    
    if (IsValidClient(client) && GetClientTeam(client) == 2) CreateTimer(5.0, ChangeToAllow);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
    if (g_Active) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        new String:weapon[128];
        GetEventString(event, "weapon", weapon, sizeof(weapon));
        
        //PrintToChatAll("%N was hit by: %s", client, weapon);
        
        if (StrEqual(weapon, "grenade_launcher_projectile") && IsValidClient(client) && IsValidClient(attacker) && IsPlayerTank(client) && GetConVarFloat(cvarGrenade) > 0.0 && IsPlayerAlive(client)) {
            decl Float:Velocity[3];
            decl Float:PlayerVec[3];
            GetClientAbsOrigin(client, PlayerVec);
            Velocity[0] = 0.0;
            Velocity[1] = 0.0;
            Velocity[2] = 1000.0 * GetConVarFloat(cvarGrenade);
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
        }
        if (StrEqual(weapon, "chainsaw") && IsValidClient(client) && IsValidClient(attacker) && IsPlayerTank(client)  && IsPlayerAlive(client)) {
            decl Float:fEye[3];
            GetClientEyeAngles(client, fEye);
            new Float:multiplier = GetConVarFloat(cvarBoomPlayer);
            if (IsFakeClient(client)) multiplier = GetConVarFloat(cvarBoomBot);
            fEye[0] += GetRandomFloat(-10.0,10.0) * multiplier * 6.0;
            fEye[1] += GetRandomFloat(-10.0,10.0) * multiplier * 6.0;
            TeleportEntity(client, NULL_VECTOR, fEye, NULL_VECTOR);
        }
        
    }
}

public Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_PlayerBurn[client] = false;
    g_PlayerStun[client] = false;
    g_PlayerBoom[client] = false;
    
    if (IsValidClient(client) && GetClientTeam(client) != 2 && IsPlayerTank(client) && (g_Gamemode != 4) && g_Started) {
        PrintToChatAll("[ITS2] Tank Died :(");
        g_Tanks -= 1;
    }
}

public Action:Event_LeaveStartArea( Handle:event, const String:name[], bool:dontBroadcast ) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(GetClientTeam(client) == 2 && IsValidClient(client) && !IsFakeClient(client) && g_Active && (g_Gamemode == 4)) {
        ActivateITSNow();
    }
}

public Action:NewTank(Handle:hTimer) {
    if (g_Active && g_Started && g_Tanks < g_MaxTanks) {
        StripAndExecuteClientCommand(Misc_GetAnyClient(), "z_spawn", "tank auto");
        CreateTimer(GetConVarFloat(cvarFreq) * g_FreqMulti + g_Help, NewTank);
    }
    return Plugin_Stop;
}

public OnGameFrame() {
    if (g_Active && g_Started) {
        new Float:currenttime = GetEngineTime() - g_StartTime;
        for(new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerActive(i)) {
                g_Points[i] = RoundFloat(currenttime);
                if (g_Points[i] > g_SurvivalTime) g_SurvivalTime = g_Points[i];
            }
        }
    }
}

public Action:DisplayHuds(Handle:hTimer) {
    if (g_Active && (g_Gamemode == 2 || GetMaxScore() > 0) && (!IsVoteInProgress()) && (!(g_Gamemode == 4))) {
        decl players[MAXPLAYERS+1][2];
        new playercount = 0;

        for(new i = 1; i <= MaxClients; i++) {
            if(IsValidClient(i) && GetClientTeam(i) == 2) {
                players[playercount][0] = i;
                players[playercount][1] = g_Points[i];
                playercount++;
            }
        }

        SortCustom2D(players,playercount,SortPlayerTimes);
    
        new String:output[512];
        new Handle:hPanel = CreatePanel();
        if (g_Gamemode == 1) {
            Format(output, sizeof(output), "%N (%s)", players[0][0], GetPlayerTime(players[0][0]));
            DrawPanelItem(hPanel, output);
            Format(output, sizeof(output), "%N (%s)", players[1][0], GetPlayerTime(players[1][0]));
            DrawPanelItem(hPanel, output);
            Format(output, sizeof(output), "%N (%s)", players[2][0], GetPlayerTime(players[2][0]));
            DrawPanelItem(hPanel, output);
            Format(output, sizeof(output), "%N (%s)", players[3][0], GetPlayerTime(players[3][0]));
            DrawPanelItem(hPanel, output);
            Format(output, sizeof(output), "Tanks: %d", g_Tanks);
            DrawPanelText(hPanel, output);
            Format(output, sizeof(output), "Survival Time: %s", ConvertToTime(g_SurvivalTime));
            DrawPanelText(hPanel, output);
        }
        if (g_Gamemode == 2) {
            Format(output, sizeof(output), "Survival Time: %s", ConvertToTime(g_SurvivalTime));
            DrawPanelText(hPanel, output);
            if (g_EnemyTime > 0) {
                Format(output, sizeof(output), "Previous Team's Time: %s", ConvertToTime(g_EnemyTime));
                DrawPanelText(hPanel, output);
            }
            Format(output, sizeof(output), "Tanks: %d / 4", g_Tanks);
            DrawPanelText(hPanel, output);
        }
        if (g_Gamemode == 3) {
            Format(output, sizeof(output), "Survival Time: %s", ConvertToTime(g_SurvivalTime));
            DrawPanelText(hPanel, output);
            Format(output, sizeof(output), "Tanks: %d", g_Tanks);
            DrawPanelText(hPanel, output);
        }
                
        for(new i = 1; i <= MaxClients; i++) {
            if(IsValidClient(i) && g_HasMenu[i] == false) {
                SendPanelToClient(hPanel, i, Menu_PanelHandler, 1);
            }
        }
        CloseHandle(hPanel)
    }
    CreateTimer(1.0, DisplayHuds);
    return Plugin_Stop;
}

public Menu_PanelHandler(Handle:menu, MenuAction:action, param1, param2) {
    if (IsValidClient(param1) && param2 >= 0) {
    }
}

stock String:GetPlayerTime(client) {
    new String:output[128];
    if (IsPlayerActive(client) && g_Started) {
        Format(output, sizeof(output), "Alive");
    }
    else {
        Format(output, sizeof(output), ConvertToTime(g_Points[client]));
    }
    
    return output;
}

stock String:ConvertToTime(any:input) {
    new String:output[128];
    new Float:totaltime = float(input);
    new minutetimer = RoundToFloor(totaltime/60.0);
    new secondtimer = RoundToFloor(totaltime - minutetimer*60.0);
    new String:addon[4];
    addon = "";
    if (secondtimer < 10) addon = "0";
    Format(output, sizeof(output), "%d:%s%d", minutetimer, addon, secondtimer);
    return output;
}

stock bool:IsPlayerActive(client) {
    if (!IsValidClient(client) || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_isIncapacitated")) return false;
    return true;
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public SortPlayerTimes(elem1[],elem2[],const array[][],Handle:hndl) {
    if(elem1[1] > elem2[1]) {
        return -1;
    }
    else if(elem1[1] < elem2[1]) {
        return 1;
    }

    return 0;
}  

public Action:HealTanks(Handle:hTimer) {
    if (g_Active && g_Started) {
        for (new i = 1; i <= MaxClients; i++) {
            if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientHealth(i) <= 0) continue;
            if (IsPlayerTank(i)) SetEntityHealth(i, 99999);
        }
        CreateTimer(1.0, HealTanks);
    }
}

stock bool:IsPlayerTank(client) {
    new String:model[128]; 
    GetClientModel(client, model, sizeof(model));
    if (StrContains(model, "hulk", false) <= 0)  return false;
    return true;
}

public Action:PlayerExtinguish(Handle:hTimer, any:client) {
    if (g_Active && IsValidClient(client)) {
        g_PlayerBurn[client] = false;
        ExtinguishEntity(client);
        SetPlayerSpeed(client);
    }
}

public Action:PlayerBoomed(Handle:hTimer, any:client) {
    if (g_Active && IsValidClient(client) && (g_PlayerBoom[client])) {
        decl Float:fEye[3];
        GetClientEyeAngles(client, fEye);
        new Float:multiplier = GetConVarFloat(cvarBoomPlayer);
        if (IsFakeClient(client)) multiplier = GetConVarFloat(cvarBoomBot);
        fEye[0] += GetRandomFloat(-10.0,10.0) * multiplier * 6.0;
        fEye[1] += GetRandomFloat(-10.0,10.0) * multiplier * 6.0;
        fEye[2] += GetRandomFloat(-10.0,10.0) * multiplier * 6.0;
        TeleportEntity(client, NULL_VECTOR, fEye, NULL_VECTOR);
        CreateTimer(GetConVarFloat(cvarBoom), PlayerBoomed, client);
    }
}

public Action:PlayerUnboom(Handle:hTimer, any:client) {
    if (g_Active && IsValidClient(client)) {
        g_PlayerBoom[client] = false;
        decl Float:fEye[3];
        GetClientEyeAngles(client, fEye);
        fEye[2] = 0.0;
        TeleportEntity(client, NULL_VECTOR, fEye, NULL_VECTOR);
    }
}

public Action:PlayerUnstun(Handle:hTimer, any:client) {
    if (g_Active && IsValidClient(client)) {
        g_PlayerStun[client] = false;
        SetPlayerSpeed(client);
    }
}

SetPlayerSpeed(any:client) {
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return;
    new Float:speed = 1.0;
    if (g_PlayerBurn[client]) speed = GetConVarFloat(cvarBurnSlowdown);
    if (g_PlayerStun[client]) speed = 0.05;
    SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",speed); // 0.5 for half speed, 1.0 for normal speed
}

public Event_TankOnFire(Handle:event, const String:name[], bool:dontBroadcast) {
    if (g_Active) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_PlayerBurn[client]){return;}
        if (IsPlayerTank(client) == false){return;}
        
        new dmgtype = GetEventInt(event,"type");
        
        if(dmgtype != 8){return;} //damage type 8 is fire, but only first time the tank is ignited (so it wont trigger every time tank receives fire damage).
        g_PlayerBurn[client] = true;
        CreateTimer(GetConVarFloat(cvarBurnTime), PlayerExtinguish, client);
        if (IsValidClient(attacker)) {
            if (!IsFakeClient(client)) CPrintToChatAllEx(client, "{teamcolor}%N{default} was ignited by {green}%N{default}!", client, attacker);
            else CPrintToChatAllEx(client, "{teamcolor}Tank{default} was ignited by {green}%N{default}!", attacker);
            g_StatsBurn[attacker] += 1;
        } else {
            if (!IsFakeClient(client)) CPrintToChatAllEx(client, "{teamcolor}%N{default} was ignited!", client);
            else CPrintToChatAllEx(client, "{teamcolor}Tank{default} was ignited!");
        }
        SetPlayerSpeed(client);
    }
}

public Event_PlayerNowIt(Handle:event, const String:name[], bool:dontBroadcast) {
    if (g_Active) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        if (!IsPlayerTank(client)){return;}
        if (GetConVarFloat(cvarBoom) <= 0.0){return;}
        if (!IsFakeClient(client)) CPrintToChatAllEx(client, "{teamcolor}%N{default} was covered in boomer bile by {green}%N{default}!", client, attacker);
        else CPrintToChatAllEx(client, "{teamcolor}Tank{default} was covered in boomer bile by {green}%N{default}!", attacker);
        g_PlayerBoom[client] = true;
        g_StatsBoom[attacker] += 1;
        CreateTimer(GetConVarFloat(cvarBoom), PlayerBoomed, client);
        CreateTimer(20.0, PlayerUnboom, client);
    }
}

public Event_Breakbreakable(Handle:event, const String:name[], bool:dontBroadcast) {
    if (g_Active) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        g_StatsBreak[client] += 1;
    }
}

public Event_FallDamage(Handle:event, const String:name[], bool:dontBroadcast) {
    if (g_Active) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new damage = RoundFloat(GetEventFloat(event, "damage"));
        if (damage > 0) g_StatsFall[client] += damage;
    }
}

public Action:Command_points(client, args) {
    CPrintToChatAllEx(client, "{teamcolor}%N{default} was covered in boomer bile!", client);
    g_PlayerBoom[client] = true;
    CreateTimer(GetConVarFloat(cvarBoom), PlayerBoomed, client);
    CreateTimer(20.0, PlayerUnboom, client);
    return Plugin_Handled;
}

/// Strip and execute a client command. This 'fakes' a client calling a specfied command. Can be used to call cheat-protected commands.
StripAndExecuteClientCommand(client, const String:command[], const String:arguments[]) {
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
}

Misc_GetAnyClient() {
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i)) {
            return i;
        }
    }
    return 0;
}

public Map_Restart(Handle:event, const String:name[], bool:dontBroadcast) {
        if (g_Started) EndRoundStats();
        g_EnemyTime = g_SurvivalTime;
        g_Started = false;
        resetStats();
        if (g_Gamemode == 2 || g_Gamemode == 4) {
            g_SurvivalTime = 0;
            g_Tanks = 0;
        }
        if (g_Gamemode == 4) resetPoints();
        if (g_Active) {
            CvarStatus(true);
        }
}

public Action:ITS_Activate(Handle:event, const String:name[], bool:dontBroadcast) {
    ActivateITSNow();
}

ActivateITSNow() {
    if (g_Active && (g_Started == false) && g_Allow) {
        PrintToChatAll("[ITS2] Here They Come!");
        CreateTimer(1.0, HealTanks);
        g_StartTime = GetEngineTime();
        g_Started = true;
        g_Tanks = 0;
        g_SurvivalTime = 0;
        g_FreqMulti = 1.0;
        resetPoints();
        //PlayAmbientMusic("the_end/SkinOnOurTeeth.wav");
        if (g_Gamemode == 4) g_FreqMulti = 0.1;
        CreateTimer(1.0, NewTank);
    }
}

public OnEntityCreated(entity, const String:classname[]) {
    //PrintToChatAll("[DEBUG] %s", classname);
    if (StrEqual(classname, "pipe_bomb_projectile") && g_Active && (GetConVarInt(cvarStun) >= 1)) {
        SDKHook(entity, SDKHook_Touch, OnPipebombTouch);
    }
}

public OnPipebombTouch(entity, other) {
    // Stuff here
    if (IsValidEdict(entity)) {
        new String:classname[64];
        GetEdictClassname(other, classname, sizeof(classname));
        
        if (StrEqual(classname,"worldspawn")) {
            new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity")
            
            SDKUnhook(entity, SDKHook_Touch, OnPipebombTouch);
            decl Float:f_Origin[3];
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", f_Origin);
            RemoveEdict(entity);
            new i_Ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(i_Ent, "physdamagescale", "0.0");
            DispatchKeyValue(i_Ent, "model", MODEL_PROPANE);
            DispatchSpawn(i_Ent);
            TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR);
            SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS);
            AcceptEntityInput(i_Ent, "Break");
            
            decl Float:PlayerVec[3];
            decl Float:distance;
            for (new i = 1; i <= MaxClients; i++) {
                if ( !IsValidClient(i) || !IsPlayerAlive(i) ) continue;
                if ( GetConVarInt(cvarStun) >= 2 && i != owner && !IsPlayerTank(i) ) continue;
                if ( GetConVarInt(cvarStun) >= 3 && i == owner ) continue;
                GetClientAbsOrigin(i, PlayerVec);
                
                distance = GetVectorDistance(f_Origin, PlayerVec, true);
                if(distance > 100000.0) continue;
                
                new Float:dmg = (100000.0 - distance) / 20000.0;
                
                if (dmg < 1.0) continue;
                if (dmg > 5.0) dmg = 5.0;
                
                g_PlayerStun[i] = true;
                CreateTimer(dmg, PlayerUnstun, i);
                new String:name[512];
                Format(name, sizeof(name), "%N", i);
                if (IsFakeClient(i)) Format(name, sizeof(name), "Tank");
                if (GetClientTeam(i) != GetClientTeam(owner)) CPrintToChatAllEx(i, "{teamcolor}%s{default} was stunned for {olive}%.1f seconds{default} by {green}%N{default}!", name, dmg, owner);
                else if (i == owner) CPrintToChatAllEx(i, "{teamcolor}%s{default} was stunned for {olive}%.1f seconds{default} by himself...", name, dmg);
                else CPrintToChatAllEx(i, "{teamcolor}%s{default} was stunned for {olive}%.1f seconds{default} by {olive}%N{default}...", name, dmg, owner);
                
                if (GetClientTeam(i) != GetClientTeam(owner)) {
                    g_StatsStun[owner] += dmg;
                    g_StatsStun2[owner] += 1;
                }
                SetPlayerSpeed(i);
            }
        }
    }
}


public ConVarActivate(Handle:convar, const String:oldValue[], const String:newValue[]) {
    AttemptEnable();
}

AttemptEnable(bool:notify=true) {
    if (GetConVarBool(cvarEnable)) {
        new String:GameMode[256];
        GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
        g_Gamemode = 0;
        g_MpMode = 0;
        if (StrEqual(GameMode, "coop")) g_Gamemode = g_DefaultMode;
        if (StrEqual(GameMode, "versus")) {
            g_Gamemode = 4;
            g_MpMode = 1;
        }
        if (g_Gamemode == 0) {
            if (notify) PrintToChatAll("[ITS2] Unable to start gamemode: Not in Versus or Campaign!");
            CvarStatus(false);
            g_Active = false;
            g_Started = false;
        }
        else {
            g_MaxTanks = 14;
            if (g_Gamemode == 2) g_MaxTanks = 4;
            CvarStatus(true);
            if (notify) PrintToChatAll("[ITS2] Enabled!");
            g_Active = true;
        }
    }
    if (GetConVarBool(cvarEnable) == false) {
        g_Active = false;
        CvarStatus(false);
        if (notify) PrintToChatAll("[ITS2] Disabled...");
        g_Started = false;
    }
}

CvarStatus(bool:status) {
    if (status) {
        SetConVarInt(FindConVar("survivor_limp_walk_speed"), 210);
        SetConVarInt(FindConVar("z_frustration"), 0);
        SetConVarInt(FindConVar("z_tank_speed"), 180);
        SetConVarInt(FindConVar("z_tank_attack_interval"), 10);
        SetConVarInt(FindConVar("z_tank_throw_interval"), 15);
        SetConVarInt(FindConVar("z_tank_throw_fail_interval"), 10);
        SetConVarInt(FindConVar("z_tank_max_stagger_distance"), 200);
        SetConVarInt(FindConVar("z_tank_max_stagger_duration"), 8);
        SetConVarInt(FindConVar("z_tank_max_stagger_fade_duration"), 8);
        SetConVarInt(FindConVar("survivor_friendly_fire_factor_easy"), 0);
        SetConVarInt(FindConVar("survivor_friendly_fire_factor_normal"), 0);
        SetConVarInt(FindConVar("survivor_friendly_fire_factor_hard"), 0);
        SetConVarInt(FindConVar("survivor_friendly_fire_factor_expert"), 0);
        SetConVarInt(FindConVar("survivor_ff_tolerance"), 100000);
        SetConVarInt(FindConVar("z_common_limit"), 0);
        SetConVarInt(FindConVar("z_ghost_finale_spawn_interval"), 0);
        SetConVarInt(FindConVar("z_ghost_spawn_interval"), 0);
        SetConVarInt(FindConVar("z_special_spawn_interval"), 0);
        SetConVarInt(FindConVar("director_no_specials"), 1);
        SetConVarInt(FindConVar("director_no_mobs"), 1);
        SetConVarInt(FindConVar("sb_dont_shoot"), 1);
    }
    else {
        ResetConVar(FindConVar("survivor_limp_walk_speed"));
        ResetConVar(FindConVar("z_frustration"));
        ResetConVar(FindConVar("z_tank_speed"));
        ResetConVar(FindConVar("z_tank_attack_interval"));
        ResetConVar(FindConVar("z_tank_throw_interval"));
        ResetConVar(FindConVar("z_tank_throw_fail_interval"));
        ResetConVar(FindConVar("z_tank_max_stagger_distance"));
        ResetConVar(FindConVar("z_tank_max_stagger_duration"));
        ResetConVar(FindConVar("z_tank_max_stagger_fade_duration"));
        ResetConVar(FindConVar("survivor_friendly_fire_factor_easy"));
        ResetConVar(FindConVar("survivor_friendly_fire_factor_normal"));
        ResetConVar(FindConVar("survivor_friendly_fire_factor_hard"));
        ResetConVar(FindConVar("survivor_friendly_fire_factor_expert"));
        ResetConVar(FindConVar("survivor_ff_tolerance"));
        ResetConVar(FindConVar("z_common_limit"));
        ResetConVar(FindConVar("z_ghost_finale_spawn_interval"));
        ResetConVar(FindConVar("z_ghost_spawn_interval"));
        ResetConVar(FindConVar("z_special_spawn_interval"));
        ResetConVar(FindConVar("director_no_specials"));
        ResetConVar(FindConVar("director_no_mobs"));
        ResetConVar(FindConVar("sb_dont_shoot"));
    }

}

EndRoundStats() {
    new TopPlayer;
    new BottomPlayer;
    new TopScore = 0;
    new BottomScore = 99999;
    new Float:TopScore2 = 0.0;
    
    // BEST-vs-WORST COMPARISON
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2) {
            if (g_Points[i] > TopScore) {
                TopPlayer = i;
                TopScore = g_Points[i];
            }
            if (g_Points[i] > 0 && g_Points[i] < BottomScore) {
                BottomPlayer = i;
                BottomScore = g_Points[i];
            }
        }
    }
    if (TopScore > 0 && BottomScore > 0 && IsValidClient(TopPlayer) && IsValidClient(BottomPlayer)) {
        new ScoreDifference = RoundToZero(float(TopScore) / float(BottomScore));
        if (ScoreDifference >= 2) CPrintToChatAllEx(TopPlayer, "{teamcolor}%N{olive} survived {green}%s{olive} as long as {teamcolor}%N{olive}!", TopPlayer, MultipleText(ScoreDifference), BottomPlayer);
    }
    
    // MOST DESTRUCTIVE
    TopScore = 0;
    BottomScore = 99999;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && (!IsFakeClient(i))) {
            if (g_StatsBreak[i] > TopScore && g_StatsBreak[i] >= 5) {
                TopPlayer = i;
                TopScore = g_StatsBreak[i];
            }
            if (g_StatsBreak[i] < TopScore && g_StatsBreak[i] > 0) {
                BottomPlayer = i;
                BottomScore = g_StatsBreak[i];
            }
        }
    }
    if (TopScore > 0 && BottomScore > 0 && IsValidClient(TopPlayer) && IsValidClient(BottomPlayer)) {
        new ScoreDifference = RoundToZero(float(TopScore) / float(BottomScore));
        if (ScoreDifference >= 2) CPrintToChatAllEx(TopPlayer, "{teamcolor}%N{olive} was {green}%s{olive} as destructive as {teamcolor}%N{olive}! (he mad?)", TopPlayer, MultipleText(ScoreDifference), BottomPlayer);
    }
    
    // BEST BURNER
    TopScore = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2 && g_StatsBurn[i] > TopScore) {
            TopPlayer = i;
            TopScore = g_StatsBurn[i];
        }
    }
    if (TopScore >= 3) CPrintToChatAllEx(TopPlayer, "{teamcolor}%N{olive} burnt {green}%d{olive} tank%s!", TopPlayer, TopScore, ProperCountingString(TopScore));
    
    // BEST STUNNER
    TopScore2 = 0.0;
    TopScore = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2 && g_StatsStun[i] > TopScore2) {
            TopPlayer = i;
            TopScore2 = g_StatsStun[i];
            TopScore = g_StatsStun2[i];
        }
    }
    if (TopScore2 >= 5.0) CPrintToChatAllEx(TopPlayer, "{teamcolor}%N{olive} stunned {green}%d{olive} tank%s for a total of {green}%.1f{olive} seconds!", TopPlayer, TopScore, ProperCountingString(TopScore), TopScore2);
    
    // BEST BOOMER
    TopScore = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2 && g_StatsBoom[i] > TopScore) {
            TopPlayer = i;
            TopScore = g_StatsBoom[i];
        }
    }
    if (TopScore >= 2) CPrintToChatAllEx(TopPlayer, "{teamcolor}%N{olive} covered {green}%d{olive} tank%s in boomer bile!", TopPlayer, TopScore, ProperCountingString(TopScore));
    
    // MOST FALL
    TopScore = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2 && g_StatsFall[i] > TopScore) {
            TopPlayer = i;
            TopScore = g_StatsFall[i];
        }
    }
    if (TopScore >= 50) CPrintToChatAllEx(TopPlayer, "{teamcolor}%N{olive} took a total of {green}%d{olive} fall damage!", TopPlayer, TopScore);
}

stock String:MultipleText(input) {
    new String:output[52];
    if (input < 0) Format(output, sizeof(output), "%d times", input);
    if (input == 0) Format(output, sizeof(output), "zero");
    if (input == 1) Format(output, sizeof(output), "one time");
    if (input == 2) Format(output, sizeof(output), "twice");
    if (input >= 3) Format(output, sizeof(output), "%d times", input);
    
    return output;
}

stock String:ProperCountingString(input) {
    new String:output[4];
    if (input != 1) Format(output, sizeof(output), "s");
    return output;
}

GetMaxScore() {
    new score = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2) {
            if (g_Points[i] > score && g_Points[i] > 0) {
                score = g_Points[i];
            }
        }
    }
    return score;
}

public OnClientPutInServer(client) {
    g_Info[client] = 0;
    g_Vote[client] = false;
}

stock String:GetModeName(mode) {
    new String:output[128];
    if (mode == 1) Format(output, sizeof(output), "Campaign (versus)");
    if (mode == 2) Format(output, sizeof(output), "Versus");
    if (mode == 3) Format(output, sizeof(output), "Campaign (co-op)");
    if (mode == 4) Format(output, sizeof(output), "Campaign (speedrun)");
    if (mode == 5) Format(output, sizeof(output), "Versus (speedrun)");
    return output;
}

/// VOTE FOR A GAMEMODE
public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_End)
    {
        /* This is called after VoteEnd */
        CloseHandle(menu);
    } else if (action == MenuAction_VoteEnd) {
        /* 0=yes, 1=no */
        if (param1 == 0)
        {
            new String:changeto[64];
            GetMenuItem(menu, param1, changeto, sizeof(changeto));
            new mode = StringToInt(changeto);
            g_Gamemode = mode;
            CPrintToChatAll("[ITS2] Gamemode changed to: {olive}%s{default}!", GetModeName(mode));
            if (g_Gamemode != 4 && g_Gamemode != 1) g_Help = 0.0;
        }
    }
}

public Action:ReallowVoting(Handle:hTimer, any:client) {
    g_Vote[client] = false;
}

DoVoteMenu(const mode, client) {
    if (IsVoteInProgress()) {
        return;
    }
    
    if (IsValidClient(client)) {
        CPrintToChatAll("[ITS2] {olive}%N{default} started gamemode vote...", client);
        g_Vote[client] = true;
        CreateTimer(20.0, ReallowVoting, client);
    }
    
    new String:gmode[128];
    Format(gmode, sizeof(gmode), GetModeName(mode));
    
    new String:input[64];
    Format(input, sizeof(input), "%d", mode);
 
    new Handle:menu = CreateMenu(Handle_VoteMenu);
    SetMenuTitle(menu, "Change gamemode to: %s?", gmode);
    AddMenuItem(menu, input, "Yes");
    AddMenuItem(menu, "no", "No");
    SetMenuExitButton(menu, false);
    VoteMenuToAll(menu, 20);
}


public PanelHandler1(Handle:menu, MenuAction:action, param1, param2) {
    // 1,3,4
    g_HasMenu[param1] = false;
    if (action == MenuAction_Select) {
        new votefor = 0;
        if (g_Gamemode == 1) {
            if (param2 == 1) votefor = 3;
            if (param2 == 2) votefor = 4;
        }
        if (g_Gamemode == 3) {
            if (param2 == 1) votefor = 1;
            if (param2 == 2) votefor = 4;
        }
        if (g_Gamemode == 4) {
            if (param2 == 1) votefor = 1;
            if (param2 == 2) votefor = 3;
        }
        if (votefor > 0) DoVoteMenu(votefor, param1);
    }
}

public Action:Cmd_Menu(client, iArgs) {
    // Not allowed if not ingame.
    if (client == 0) { ReplyToCommand(client, "[ITS2] Command is in-game only."); return Plugin_Handled; }
    if (!IsValidClient(client)) { ReplyToCommand(client, "[ITS2] Command is in-game only."); return Plugin_Handled; }
    
    if (g_MpMode == 1) {
        PrintToChat(client, "[ITS2] Cannot start vote: No additional gamemodes for this mode");
        return Plugin_Handled;
    }
    if (g_Started) {
        PrintToChat(client, "[ITS2] Cannot start vote: Round has started");
        return Plugin_Handled;
    }
    if (IsVoteInProgress()) {
        PrintToChat(client, "[ITS2] Cannot start vote: Another vote in progress");
        return Plugin_Handled;
    }
    if (g_Vote[client]) {
        PrintToChat(client, "[ITS2] You must wait 20 seconds before performing yet another vote");
        return Plugin_Handled;
    }
    
    // Display menu.
    new Handle:hPanel = CreatePanel();
    SetPanelTitle(hPanel, "Change gamemode?\n ");
    
    // Add the different options
    new String:strItem[256];
    // Campaign (versus)
    if (g_Gamemode == 1) {
        Format(strItem, sizeof(strItem), "Currently Playing: %s", GetModeName(1));
        DrawPanelText(hPanel, strItem);
    } else {
        Format(strItem, sizeof(strItem), "Change to %s", GetModeName(1));
        DrawPanelItem(hPanel, strItem);
    }
    DrawPanelText(hPanel, "Your goal is to stay alive longer than your teammates!\n ");
    
    // Campaign (co-op)
    if (g_Gamemode == 3) {
        Format(strItem, sizeof(strItem), "Currently Playing: %s", GetModeName(3));
        DrawPanelText(hPanel, strItem);
    } else {
        Format(strItem, sizeof(strItem), "Change to %s", GetModeName(3));
        DrawPanelItem(hPanel, strItem);
    }
    DrawPanelText(hPanel, "Your goal is to stay alive as long as possible as a team!\n ");
    
    // Campaign (speedrun)
    if (g_Gamemode == 4) {
        Format(strItem, sizeof(strItem), "Currently Playing: %s", GetModeName(4));
        DrawPanelText(hPanel, strItem);
    } else {
        Format(strItem, sizeof(strItem), "Change to %s", GetModeName(4));
        DrawPanelItem(hPanel, strItem);
    }
    DrawPanelText(hPanel, "Your goal is to run to the safe room without getting killed!\n ");
    
    DrawPanelText(hPanel, "0. Cancel");
    
    
    //SetMenuTitle(hMenu, strItem);
    g_HasMenu[client] = true;
    CreateTimer(20.0,HasMenuOff, client);
    SendPanelToClient(hPanel, client, PanelHandler1, 20);
    CloseHandle(hPanel);
    
    return Plugin_Handled;
}

public Action:HasMenuOff(Handle:hTimer, any:client) {
    g_HasMenu[client] = false;
}

public Player_Entered_Checkpoint(Handle:event, const String:name[], bool:noBroadcast) {
    if (g_Gamemode == 4) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (IsValidClient(client) && GetClientTeam(client) == 2) {
            for(new i = 1; i <= MaxClients; i++) {
                if(IsValidClient(i) && GetClientTeam(i) == 2 && GetEntProp(i, Prop_Send, "m_isIncapacitated")) {
                    ForcePlayerSuicide(i);
                }
            }
        }
    }
}