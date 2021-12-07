#include <sourcemod>
#include <sdktools>


public OnPluginStart()
{
  RegAdminCmd("hidehud", CmdHideHud, ADMFLAG_ROOT, "");
}

Action CmdHideHud(int client, int args)
{
    char sArg[256];
    GetCmdArg(1, sArg, sizeof(sArg));
    int hud = StringToInt(sArg);

    SetEntProp(client, Prop_Send, "m_iHideHUD", hud);

    return Plugin_Handled;
}