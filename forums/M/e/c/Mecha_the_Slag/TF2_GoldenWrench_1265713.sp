#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_VERSION "1.0"
#define SOUND_SUCCESS "vo/announcer_success.wav"
#define WRENCH_ICON "ico_notify_golden_wrench"

new g_Wrenches[MAXPLAYERS+1] = 0;
new g_Display = 0;

public Plugin:myinfo = {
    name = "[TF2] Golden Wrench",
    author = "Mecha the Slag",
    description = "Makes a fake Golden Wrench announcement!",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    RegAdminCmd("sm_goldenwrench", Command_Gold, ADMFLAG_SLAY, "sm_goldenwrench <#userid|name>");
}

public OnMapStart() {
    PrecacheSound(SOUND_SUCCESS);
}

public Action:Command_Gold(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_goldenwrench <#userid|name>");
        return Plugin_Handled;
    }

    decl String:arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_CONNECTED,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        if (IsValidClient(client)) ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    g_Display = 0;
    for (new i = 0; i < target_count; i++) {
        new target = target_list[i];
        if (IsValidClient(target)) {
            GiveGoldenWrench(target);
        }
    }

    if (tn_is_ml)
    {
        ShowActivity2(client, "[SM] ", "Handed fake Golden Wrench to target", target_name);
    }
    else
    {
        ShowActivity2(client, "[SM] ", "Handed fake Golden Wrench to target", "_s", target_name);
    }

    return Plugin_Handled;
}

ShowTheText(client) {
    decl String:msg[512];
    Format(msg, sizeof(msg), "%N has found Golden Wrench no. %d!", client, g_Wrenches[client]);
    ShowGameText(msg, client);
}

public Action:ShowTheText_Timer(Handle:hTimer, any:client) {
    ShowTheText(client);
}

GiveGoldenWrench(client) {

    new Handle:roll = CreateArray();
    for (new i = 1; i <= 100; i++) {
        new bool:allow = true;
        for (new i2 = 1; i2 <= MaxClients; i2++) {
            if (g_Wrenches[i2] == i) allow = false;
        }
        if (allow) PushArrayCell(roll, i);
    }
    
    new wrench = GetArrayCell(roll, GetRandomInt(0, GetArraySize(roll)-1));
    CloseHandle(roll);
    
    g_Wrenches[client] = wrench;
    
    ShowTheText(client);
    EmitSoundToAll(SOUND_SUCCESS, _, _, SNDLEVEL_RAIDSIREN);
}

ShowGameText(const String:strMessage[], client) {
    new iEntity = CreateEntityByName("game_text_tf");
    DispatchKeyValue(iEntity,"message", strMessage);
    DispatchKeyValue(iEntity,"display_to_team", "0");
    DispatchKeyValue(iEntity,"icon", WRENCH_ICON);
    DispatchKeyValue(iEntity,"targetname", "game_text1");
    DispatchKeyValue(iEntity,"background", "0");
    DispatchSpawn(iEntity);
    AcceptEntityInput(iEntity, "Display", iEntity, iEntity);
    CreateTimer(2.5, KillGameText, iEntity);
    if (g_Display == 0) CreateTimer(2.5, ShowTheText_Timer, client);
    g_Display += 1;
}

public Action:KillGameText(Handle:hTimer, any:iEntity) {
    if ((iEntity > 0) && IsValidEntity(iEntity)) AcceptEntityInput(iEntity, "kill"); 
    return Plugin_Stop;
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public OnClientDisconnect(client) {
    g_Wrenches[client] = 0;
}