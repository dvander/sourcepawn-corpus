#include <sourcemod>
#include <surftimer>


public Plugin myinfo =
{
    name = "Bot fix for Surftimer",
    author = "Busted",
    description = "Auto bot fix after map start",
    version = "1.0",
    url = "https://attawaybaby.com/"
}

public void OnPluginStart()
{
    CreateTimer(10.0, fixbot);
}

public Action FixBot_Off(Handle timer)
{
	ServerCommand("ck_replay_bot 0");
	ServerCommand("ck_bonus_bot 0");
	ServerCommand("ck_wrcp_bot 0");
	return Plugin_Handled;
}

public Action FixBot_On(Handle timer)
{
	ServerCommand("ck_replay_bot 1");
	ServerCommand("ck_bonus_bot 1");
	ServerCommand("ck_wrcp_bot 1");
	return Plugin_Handled;
}

public Action fixbot(Handle timer)
{
    CreateTimer(5.0, FixBot_Off, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(10.0, FixBot_On, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Handled;
}


