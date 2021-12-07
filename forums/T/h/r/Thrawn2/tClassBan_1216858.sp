#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <clientprefs>

#define VERSION "1.0.0.0"
#define MAX_PLAYERS 32
#define MAX_CLASSES 10

#define CLASS_UNKNOWN       0
#define CLASS_SCOUT         1
#define CLASS_SNIPER        2
#define CLASS_SOLDIER       3
#define CLASS_DEMOMAN       4
#define CLASS_MEDIC         5
#define CLASS_HEAVY         6
#define CLASS_PYRO          7
#define CLASS_SPY           8
#define CLASS_ENGINEER      9

#define TEAM_RED            2
#define TEAM_BLU            3

new bool:g_loaded[MAX_PLAYERS + 1];
new g_iClass[MAX_PLAYERS + 1];
new g_classBan[MAX_PLAYERS + 1][MAX_CLASSES];
new Handle:db_scout;
new Handle:db_sniper;
new Handle:db_soldier;
new Handle:db_demoman;
new Handle:db_medic;
new Handle:db_heavy;
new Handle:db_pyro;
new Handle:db_spy;
new Handle:db_engineer;

new String:g_sSounds[10][24] = {"", "vo/scout_no03.wav",   "vo/sniper_no04.wav", "vo/soldier_no01.wav",
                                                                        "vo/demoman_no03.wav", "vo/medic_no03.wav",  "vo/heavy_no02.wav",
                                                                        "vo/pyro_no01.wav",    "vo/spy_no02.wav",    "vo/engineer_no03.wav"};

new g_iClassHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};

new bool:g_bEnabled;
new Handle:g_hCvarEnable;

public Plugin:myinfo =
{
    name = "tClassBan",
    author = "Thrawn",
    description = "Classbans",
    version = VERSION,
    url = "http://aaa.wallbash.com"
};


public OnPluginStart()
{
    CreateConVar("sm_tclassban_version", VERSION, "Forbid players from using certain classes in TF2.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_hCvarEnable = CreateConVar("sm_tclassban_enabled", "1",  "Enable/disable banning classes for some players.");
    HookConVarChange(g_hCvarEnable, Cvar_enabled);
    
    LoadTranslations("common.phrases");
    RegAdminCmd("sm_tclassban_limit", Command_SetLimit, ADMFLAG_BAN, "[SM] Usage: sm_tclassban_limit <#id|name> <class> <time>");
    RegAdminCmd("sm_tclassban_free", Command_RemoveLimit, ADMFLAG_BAN, "[SM] Usage: sm_tclassban_free <#id|name>");

    db_scout = RegClientCookie("cb_scout", "Timelimit for the scout class", CookieAccess:2);
    db_sniper = RegClientCookie("cb_sniper", "Timelimit for the sniper class", CookieAccess:2);
    db_soldier = RegClientCookie("cb_soldier", "Timelimit for the soldier class", CookieAccess:2);
    db_demoman = RegClientCookie("cb_demoman", "Timelimit for the demoman class", CookieAccess:2);
    db_medic = RegClientCookie("cb_medic", "Timelimit for the medic class", CookieAccess:2);
    db_heavy = RegClientCookie("cb_heavy", "Timelimit for the heavy class", CookieAccess:2);
    db_pyro = RegClientCookie("cb_pyro", "Timelimit for the pyro class", CookieAccess:2);
    db_spy = RegClientCookie("cb_spy", "Timelimit for the spy class", CookieAccess:2);
    db_engineer = RegClientCookie("cb_engineer", "Timelimit for the engineer class", CookieAccess:2);
        
    HookEvent("player_changeclass", Event_PlayerClass);
    HookEvent("player_spawn",       Event_PlayerSpawn);
    HookEvent("player_team",        Event_PlayerTeam);
}

public Action:Command_RemoveLimit(client, args)
{
    if(!g_bEnabled) {
        ReplyToCommand(client, "[SM] Plugin tClassBan is disabled");
        return Plugin_Handled;  
    }

    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_tclassban_limit <#id|name>");
        return Plugin_Handled;
    }

    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));  

    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl TargetList[MAXPLAYERS], TargetCount;
    decl bool:TargetTranslate;
    
    if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
    {
        ReplyToTargetError(client, TargetCount);
        return Plugin_Handled;
    }

    // Apply to all targets
    for (new i = 0; i < TargetCount; i++)
    {
        if (!IsClientConnected(TargetList[i])) continue;
        if (!IsClientInGame(TargetList[i]))    continue;

        new loopClient = TargetList[i];
        new bool:bNotify = false;
        for(new j = 1; j < 10; j++)
        {
            if(g_classBan[loopClient][j] > 0)
                bNotify = true;
                
            g_classBan[loopClient][j] = -1;
        }

        SaveLimits(loopClient);

        if(bNotify)
            PrintToChat(loopClient, "You are now free to play any class you want.");      
    }
        
    return Plugin_Handled;
}

public Action:Command_SetLimit(client, args)
{
    if(!g_bEnabled) {
        ReplyToCommand(client, "[SM] Plugin tClassBan is disabled");
        return Plugin_Handled;  
    }
    
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_tclassban_limit <#id|name> <class> <time>");
        return Plugin_Handled;
    }

    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));  
    new String:tmp_class[30];
    new String:tmp_time[18];
    
    GetCmdArg(2, tmp_class, sizeof(tmp_class));
    GetCmdArg(3, tmp_time, sizeof(tmp_time));
    
    new time = StringToInt(tmp_time);
    new class = StringToClass(tmp_class);

    if (class == -1)
        { ReplyToCommand(client, "[TF2] Unknown class : \"%s\"", tmp_class); return Plugin_Handled; }

    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl TargetList[MAXPLAYERS], TargetCount;
    decl bool:TargetTranslate;
    
    if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
    {
        ReplyToTargetError(client, TargetCount);
        return Plugin_Handled;
    }

    new blockTill = GetTime() + time*60;

    // Apply to all targets
    for (new i = 0; i < TargetCount; i++)
    {
        new loopClient = TargetList[i];
        
        if (!IsClientConnected(loopClient)) continue;
        if (!IsClientInGame(loopClient))    continue;
        
        if(time == -1) {
            g_classBan[loopClient][class] = -1;
            PrintToChat(loopClient, "You have been unblocked from playing \'%s\'.", tmp_class);      
        } else if(blockTill > g_classBan[loopClient][class]) {
            g_classBan[loopClient][class] = blockTill;
        
            PrintToChat(loopClient, "You have been blocked from playing \'%s\' for the next %i minutes", tmp_class, time);
            
            if(IsPlayerAlive(loopClient) && _:TF2_GetPlayerClass(loopClient) == class) {
                
                //respawn him right now                
                new Float:loc[3];
                new Float:ang[3];
                GetClientAbsOrigin(loopClient, loc);
                GetClientAbsAngles(loopClient, ang);                
                
                PickClass(loopClient);
                
                TeleportEntity(loopClient, loc, ang, NULL_VECTOR);                
            }
        }
        
        SaveLimits(loopClient);
    }
        
    return Plugin_Handled;
}

stock StringToClass(const String:input[]) {
    if(strcmp(input,"scout",false) == 0) return CLASS_SCOUT;
    if(strcmp(input,"sniper",false) == 0) return CLASS_SNIPER;
    if(strcmp(input,"soldier",false) == 0) return CLASS_SOLDIER;
    if(strcmp(input,"demoman",false) == 0) return CLASS_DEMOMAN;
    if(strcmp(input,"medic",false) == 0) return CLASS_MEDIC;
    if(strcmp(input,"heavy",false) == 0) return CLASS_HEAVY;
    if(strcmp(input,"pyro",false) == 0) return CLASS_PYRO;
    if(strcmp(input,"spy",false) == 0) return CLASS_SPY;
    if(strcmp(input,"engineer",false) == 0) return CLASS_ENGINEER;
    
    return -1;
}

public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
    g_bEnabled = GetConVarBool(g_hCvarEnable);
}

public OnConfigsExecuted() {   
    g_bEnabled = GetConVarBool(g_hCvarEnable);
}

public OnMapStart() {
    decl i, String:sSound[32];
    for(i = 1; i < sizeof(g_sSounds); i++) {
        Format(sSound, sizeof(sSound), "sound/%s", g_sSounds[i]);
        PrecacheSound(g_sSounds[i]);
        AddFileToDownloadsTable(sSound);
    }
}

public OnClientPutInServer(client) {
    if(g_bEnabled) {
        g_iClass[client] = CLASS_UNKNOWN;
    
        if(!g_loaded[client]) {        
            g_classBan[client][CLASS_SCOUT] = -1;
            g_classBan[client][CLASS_SNIPER] = -1;
            g_classBan[client][CLASS_SOLDIER] = -1;
            g_classBan[client][CLASS_DEMOMAN] = -1;
            g_classBan[client][CLASS_MEDIC] = -1;
            g_classBan[client][CLASS_HEAVY] = -1;
            g_classBan[client][CLASS_PYRO] = -1;
            g_classBan[client][CLASS_SPY] = -1;
            g_classBan[client][CLASS_ENGINEER] = -1;            
        }
    }
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast) {
    if(g_bEnabled) {    
        new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
            iClass  = GetEventInt(event, "class"),
            iTeam   = GetClientTeam(iClient);

        if (!AreClientCookiesCached(iClient))
            return;

        if(!g_loaded[iClient])
            LoadLimits(iClient);

        if(IsBlocked(iClient, iClass)) {
            ShowVGUIPanel(iClient, iTeam == TEAM_BLU ? "class_blue" : "class_red");
            EmitSoundToClient(iClient, g_sSounds[iClass]);

            TF2_SetPlayerClass(iClient, TFClassType:g_iClass[iClient]);
            SetEntProp(iClient, Prop_Send, "m_iHealth", g_iClassHealth[g_iClass[iClient]]);
            SetClassSpeed(iClient, TFClassType:g_iClass[iClient]);                    
        }
    }
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    if(g_bEnabled) {    
        new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
            iTeam   = GetClientTeam(iClient);

        if (!AreClientCookiesCached(iClient))
            return;

        if(!g_loaded[iClient])
            LoadLimits(iClient);

        if(IsBlocked(iClient, (g_iClass[iClient] = _:TF2_GetPlayerClass(iClient)))) {
            ShowVGUIPanel(iClient, iTeam == TEAM_BLU ? "class_blue" : "class_red");
            EmitSoundToClient(iClient, g_sSounds[g_iClass[iClient]]);
            PickClass(iClient);
        }
    }
}

public Event_PlayerTeam(Handle:event,  const String:name[], bool:dontBroadcast) {
    if(g_bEnabled) {    
        new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
            iTeam   = GetEventInt(event, "team");

        if(iClient > 0) {
            if (!AreClientCookiesCached(iClient))
                return;

            if(!g_loaded[iClient])
                LoadLimits(iClient);
        
            if(IsBlocked(iClient, g_iClass[iClient])) {
                ShowVGUIPanel(iClient, iTeam == TEAM_BLU ? "class_blue" : "class_red");
                EmitSoundToClient(iClient, g_sSounds[g_iClass[iClient]]);
                PickClass(iClient);
            }
        }
    }
}

bool:IsBlocked(iClient, iClass) {
    // If plugin is disabled, or team or class is invalid, class is not full
    if(!IsClientInGame(iClient) || iClass < CLASS_SCOUT)
        return false;
    
    new iCurrentTime = GetTime();
    new iClientLimit = g_classBan[iClient][iClass];
    
    if (iClientLimit > 1) {
        if(iCurrentTime >= iClientLimit) {
            g_classBan[iClient][iClass] = -1;
        } else {
            return true;
        }    
    }
        
    return false;
}

PickClass(iClient) {
    // Loop through all classes, starting at random class
    for(new i = GetRandomInt(CLASS_SCOUT, CLASS_ENGINEER), iClass = i;;)
    {
        // If team's class is not full, set client's class
        if(!IsBlocked(iClient, i)) {            
            TF2_SetPlayerClass(iClient, TFClassType:i);
            TF2_RespawnPlayer(iClient);
            
            SetEntProp(iClient, Prop_Send, "m_iHealth", g_iClassHealth[i]);
            SetClassSpeed(iClient, TFClassType:i);            
            
            g_iClass[iClient] = i;
            break;
        }
        // If next class index is invalid, start at first class
        else if(++i > CLASS_ENGINEER)
            i = CLASS_SCOUT;
        // If loop has finished, stop searching
        else if(i == iClass)
            break;
    }
}

public OnClientCookiesCached(client) {
    LoadLimits(client);
} 

public OnClientDisconnect(client) {        
    for(new i = 1; i < 10; i++)
    {
        g_classBan[client][i] = -1;
    }    
} 


// -------------------------------------------------
// dont modify below this line
// -------------------------------------------------


LoadLimits(client) {
    g_classBan[client][CLASS_SCOUT] = GetUserTimelimit(client, CLASS_SCOUT);
    g_classBan[client][CLASS_SNIPER] = GetUserTimelimit(client, CLASS_SNIPER);
    g_classBan[client][CLASS_SOLDIER] = GetUserTimelimit(client, CLASS_SOLDIER);
    g_classBan[client][CLASS_DEMOMAN] = GetUserTimelimit(client, CLASS_DEMOMAN);
    g_classBan[client][CLASS_MEDIC] = GetUserTimelimit(client, CLASS_MEDIC);
    g_classBan[client][CLASS_HEAVY] = GetUserTimelimit(client, CLASS_HEAVY);
    g_classBan[client][CLASS_PYRO] = GetUserTimelimit(client, CLASS_PYRO);
    g_classBan[client][CLASS_SPY] = GetUserTimelimit(client, CLASS_SPY);
    g_classBan[client][CLASS_ENGINEER] = GetUserTimelimit(client, CLASS_ENGINEER);
    g_loaded[client] = true;
}

SaveLimits(client) {
    SetUserTimelimit(client, CLASS_SCOUT, g_classBan[client][CLASS_SCOUT]);
    SetUserTimelimit(client, CLASS_SNIPER, g_classBan[client][CLASS_SNIPER]);
    SetUserTimelimit(client, CLASS_SOLDIER, g_classBan[client][CLASS_SOLDIER]);
    SetUserTimelimit(client, CLASS_DEMOMAN, g_classBan[client][CLASS_DEMOMAN]);
    SetUserTimelimit(client, CLASS_MEDIC, g_classBan[client][CLASS_MEDIC]);
    SetUserTimelimit(client, CLASS_HEAVY, g_classBan[client][CLASS_HEAVY]);
    SetUserTimelimit(client, CLASS_PYRO, g_classBan[client][CLASS_PYRO]);
    SetUserTimelimit(client, CLASS_SPY, g_classBan[client][CLASS_SPY]);
    SetUserTimelimit(client, CLASS_ENGINEER, g_classBan[client][CLASS_ENGINEER]);    
}


GetUserTimelimit(client, class) {
    new String:buffer[20];

    switch(class) {
        case CLASS_SCOUT:
            GetClientCookie(client, db_scout, buffer, sizeof(buffer));
            
        case CLASS_SNIPER:
            GetClientCookie(client, db_sniper, buffer, sizeof(buffer));

        case CLASS_SOLDIER:
            GetClientCookie(client, db_soldier, buffer, sizeof(buffer));

        case CLASS_DEMOMAN:
            GetClientCookie(client, db_demoman, buffer, sizeof(buffer));
            
        case CLASS_HEAVY:
            GetClientCookie(client, db_heavy, buffer, sizeof(buffer));

        case CLASS_PYRO:
            GetClientCookie(client, db_pyro, buffer, sizeof(buffer));

        case CLASS_SPY:
            GetClientCookie(client, db_spy, buffer, sizeof(buffer));
            
        case CLASS_ENGINEER:
            GetClientCookie(client, db_engineer, buffer, sizeof(buffer));

        case CLASS_MEDIC:
            GetClientCookie(client, db_medic, buffer, sizeof(buffer));            
    }
        
    return StringToInt(buffer);
}

SetUserTimelimit(client, class, tmp_time) {
    if(tmp_time > 0) {    
        new String:time[20];
        Format(time, sizeof(time), "%i", tmp_time);
    
        switch(class) {
            case CLASS_SCOUT:
                return SetClientCookie( client, db_scout, time );        

            case CLASS_SNIPER:
                return SetClientCookie( client, db_sniper, time );       

            case CLASS_SOLDIER:
                return SetClientCookie( client, db_soldier, time );      

            case CLASS_DEMOMAN:
                return SetClientCookie( client, db_demoman, time );      

            case CLASS_HEAVY:
                return SetClientCookie( client, db_heavy, time );        

            case CLASS_PYRO:
                return SetClientCookie( client, db_pyro, time );     

            case CLASS_SPY:
                return SetClientCookie( client, db_spy, time );      

            case CLASS_ENGINEER:
                return SetClientCookie( client, db_engineer, time );     

            case CLASS_MEDIC:
                return SetClientCookie( client, db_medic, time );            
        }
    }    
    return -1;
}

SetClassSpeed(client, TFClassType:class)
{
    switch (class)
    {
        case TFClass_Scout:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
        case TFClass_Sniper:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
        case TFClass_Soldier:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);
        case TFClass_DemoMan:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);
        case TFClass_Medic:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
        case TFClass_Heavy:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 230.0);
        case TFClass_Pyro:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
        case TFClass_Spy:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
        case TFClass_Engineer:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
    }
}
