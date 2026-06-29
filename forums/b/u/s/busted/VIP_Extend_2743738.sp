#include <sourcemod>
#include <sdktools>
#include <colorvariables>

public Plugin myinfo =
{
    name = "VIP - Extend Time",
    author = "Busted",
    description = "",
    version = "1.0",
    url = "https://attawaybaby.com/"
};

ConVar g_hExtendTime;
ConVar g_hMaxExtend;

int g_Extends;
int g_ExtendsRemaining;

public void OnPluginStart()
{
    g_hExtendTime = CreateConVar("sm_vip_extendtime", "10", "Time to be extended in minute.", FCVAR_NONE, true, 1.0);
    g_hMaxExtend = CreateConVar("sm_vip_maxextend", "10", "Number of time the map can be extend.", FCVAR_NONE, true, 1.0);

    AutoExecConfig(true, "vip_extendtime");
    RegAdminCmd("sm_forceextend", Command_ExtendTime, ADMFLAG_RESERVATION|ADMFLAG_GENERIC, "VIP - Extend the map time");
}

public void OnMapStart()
{
    g_Extends = 0;
    g_ExtendsRemaining = g_hMaxExtend.IntValue;
}

public Action Command_ExtendTime(int client, int args)
{
    AttemptExtend(client);
    return Plugin_Handled;
}

void AttemptExtend(int client)
{
    if (!client)
    {
        return;
    }

    if (g_Extends >= g_hMaxExtend.IntValue)
	{
		CReplyToCommand(client, "[SM] Maximum extends Reached");
		return;
	}
    else
    {
        ExtendMap();
        CReplyToCommand(client, "[SM] There is %d extends remaining", g_ExtendsRemaining);
    }
}

void ExtendMap()
{
    CPrintToChatAll("[SM] The map has been extended by %d minutes", g_hExtendTime.IntValue);
    ExtendMapTimeLimit(g_hExtendTime.IntValue * 60);

    g_Extends++;
    g_ExtendsRemaining--;
}