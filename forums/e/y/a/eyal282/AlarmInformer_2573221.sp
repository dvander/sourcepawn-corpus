#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
    name = "Car Alarm Inform",
    author = "Eyal282",
    description = "Announces who triggered the car alarm, either for griefing or for spawning a Tank.",
    version = "3.0",
    url = "<- URL ->"
}

GlobalForward g_fwOnCarAlarm;

int g_iLastTriggerUserId;
char g_sLastTriggerName[64];
bool g_bAlarmWentOff;

public void OnPluginStart()
{
    HookEvent("create_panic_event", Event_CreatePanicEvent, EventHookMode_Post);
    HookEvent("triggered_car_alarm", Event_TriggeredCarAlarm, EventHookMode_Pre);

    g_fwOnCarAlarm = CreateGlobalForward("Plugins_OnCarAlarmPost", ET_Ignore, Param_Cell);
}

public Action Event_TriggeredCarAlarm(Handle hEvent, char[] Name, bool dontBroastcast)
{
    g_bAlarmWentOff = true;

    return Plugin_Continue;
}
public Action Event_CreatePanicEvent(Handle hEvent, char[] Name, bool dontBroastcast)
{
    int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    if(client == 0) // Console panic events.
        return Plugin_Continue;
        
    else if(GetClientTeam(client) != 2) // Better safe than sorry.
        return Plugin_Continue;
    
    GetClientName(client, g_sLastTriggerName, sizeof(g_sLastTriggerName));

    g_iLastTriggerUserId = GetClientUserId(client);

    RequestFrame(CheckAlarm);

    return Plugin_Continue;
}

public void CheckAlarm() // Zero is basically a null variable, I didn't need to pass a variable but I'm forced to.
{
    if(!g_bAlarmWentOff)
        return;

    g_bAlarmWentOff = false;
    
    // I took his name in the impossible case where he logs out a frame later.
    PrintToChatAll("\x03%s \x01has triggered the\x04 car alarm.", g_sLastTriggerName);

    Call_StartForward(g_fwOnCarAlarm);

    Call_PushCell(g_iLastTriggerUserId);

    Call_Finish();
}