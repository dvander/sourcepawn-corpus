#pragma semicolon 1
#pragma newdecls required
 
int g_iCountdown = 0;
ConVar g_cvFreezetime;
char g_cStr[120] = "<font size='50'><font color='#38F91A'><b>***** <font color='#DE0202'>%i <font color='#38F91A'>*****</b></font>";
 
public Plugin myinfo =
{
    name = "Countdown",
    author = "kRatoss , TheBO$$ , LiveviL ",
    description = "countdown timer when round start",
    version = "1.3",
    url = ""
};
 
public void OnPluginStart()
{
    g_cvFreezetime = FindConVar("mp_freezetime");
    HookEvent("round_start", OnRoundStart);
}
 
public void OnRoundStart(Handle event, const char[]name , bool dontBroadcast)
{
    g_iCountdown = g_cvFreezetime.IntValue;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) !=1) {
            CreateTimer(1.0, Timer, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }	
}
   
public Action Timer(Handle Timer)
{
    --g_iCountdown;
    char buf[1028] = "\0";
    Format(buf, sizeof(buf), g_cStr, g_iCountdown);
    PrintHintTextToAll(buf);
    if(g_iCountdown > 0)
        return Plugin_Continue;
    PrintHintTextToAll("<font size='70'><font color='#7CFC00'><b>GO <font color='#DE0202'>GO <font color='#000000'>GO <font color='#DE0202'>!!!</b></font>");
    return Plugin_Stop;
}