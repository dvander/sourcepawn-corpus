#include <sourcemod>
static String:szCurrentmap[99];
public OnPluginStart()
    RegAdminCmd("sm_remap", MapRestart, ADMFLAG_CHANGEMAP);
public OnMapStart()
    GetCurrentMap(szCurrentmap, sizeof(szCurrentmap));
public Action:MapRestart(iClient, iArgc)
    ForceChangeLevel(szCurrentmap, "[SM] Restarting the map.");
