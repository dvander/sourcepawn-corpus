#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin myinfo =
{
	name = "TF2 Team Switcher",
	author = "Train",
	description = "Change your team in tf2",
	version = "1.0",
	url = ""
}

public void OnPluginStart()
{
	PrintToServer("TF2 team switcher ready")
	RegAdminCmd("sm_joinblu", Command_JoinBlu, ADMFLAG_SLAY)
	RegAdminCmd("sm_joinred", Command_JoinRed, ADMFLAG_SLAY)
}

public Action Command_JoinBlu(int client, int args)
{
	if (IsMvM())
	{
		new entflags = GetEntityFlags(client);
		SetEntityFlags(client, entflags | FL_FAKECLIENT);
	}
	ChangeClientTeam(client, _:TFTeam_Blue)
}
public Action Command_JoinRed(int client, int args)
{
	if (IsMvM())
	{
		new entflags = GetEntityFlags(client);
		SetEntityFlags(client, entflags);
	}
	ChangeClientTeam(client, _:TFTeam_Red);
}
//taken from red2robot

stock bool:IsMvM(bool:forceRecalc = false)
{
    static bool:found = false;
    static bool:ismvm = false;
    if (forceRecalc)
    {
        found = false;
        ismvm = false;
    }
    if (!found)
    {
        new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
        if (i > MaxClients && IsValidEntity(i)) ismvm = true;
        found = true;
    }
    return ismvm;
}
