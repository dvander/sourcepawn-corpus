#include <sourcemod>

public void OnPluginStart()
{
    AddCommandListener(CL_Radio, "coverme");
    AddCommandListener(CL_Radio, "takepoint");
    AddCommandListener(CL_Radio, "holdpos");
    AddCommandListener(CL_Radio, "regroup");
    AddCommandListener(CL_Radio, "followme");
    AddCommandListener(CL_Radio, "takingfire");
    AddCommandListener(CL_Radio, "cheer");
    AddCommandListener(CL_Radio, "thanks");
    AddCommandListener(CL_Radio, "go");
    AddCommandListener(CL_Radio, "fallback");
    AddCommandListener(CL_Radio, "sticktog");
    AddCommandListener(CL_Radio, "getinpos");
    AddCommandListener(CL_Radio, "stormfront");
    AddCommandListener(CL_Radio, "report");
    AddCommandListener(CL_Radio, "roger");
    AddCommandListener(CL_Radio, "enemyspot");
    AddCommandListener(CL_Radio, "needbackup");
    AddCommandListener(CL_Radio, "sectorclear");
    AddCommandListener(CL_Radio, "inposition");
    AddCommandListener(CL_Radio, "reportingin");
    AddCommandListener(CL_Radio, "getout");
    AddCommandListener(CL_Radio, "negative");
    AddCommandListener(CL_Radio, "enemydown");
}

public Action CL_Radio(int client, const char[] sCmd, int args) {
    return Plugin_Handled;    
}