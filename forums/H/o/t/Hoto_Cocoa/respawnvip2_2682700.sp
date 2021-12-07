#include <sourcemod>
#include <clientprefs>
#include <morecolors>
#include <sdktools_functions>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
int respawn[MAXPLAYERS+1];
int team[MAXPLAYERS+1];
EngineVersion g_EngineVersion;
public Plugin myinfo =
{
	name = "Respawn player",
	author = "fafa_junhe, Hoto Cocoa",
	description = "Respawn player in vsh",
	version = "1.0",
	url = "http://www.jymc.top"
};
public void OnPluginStart()
{
	RegAdminCmd("sm_spawn",Command_spawn,ADMFLAG_CUSTOM1,"返回出生点");
	HookEvent("player_death",Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_round_start",Event_RoundStart, EventHookMode_Pre);
}
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("test");
	//for (int i;i<=MAXPLAYERS+1;i++)
	//for (new i = 0;i<=MAXPLAYERS+1;i++)
	for (new i = 0;i<=MAXPLAYERS+1;i++)
	{
		respawn[i] = 0;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new DeathFlags  = GetEventInt(event, "death_flags");
	new Bossteam = FF2_GetBossTeam();
	
	if (Bossteam == GetClientTeam(client))
	{
		respawn[client] = 1;
		return Plugin_Handled;
	}
    else if (DeathFlags & 32)
    {
        //dead ringer
    }
    else
    {
		if (CheckCommandAccess(client, "sm_spawn", ADMFLAG_CUSTOM1))
		{
			if (respawn[client] == 0)
			{
				show_Panel(client);
			}
		}
	}


}
public Action Command_spawn (int client, int args)
{			
	new Selfhealth = FF2_GetBossHealth();
	new Selfmaxhealth = FF2_GetBossMaxHealth();
	//new Selflive = FF2_GetBossLives();
	//new Selfmaxlive = FF2_GetBossMaxLives();
	new playerdamage = FF2_GetClientDamage(client);
	
	if (IsPlayerAlive(client))
	{
		CPrintToChat(client,"{white}[{purple}咖啡厅{white}]你还活着呢~",client);
		return Plugin_Handled;
	}
	if (respawn[client] == 1)
	{
			CPrintToChat(client,"{white}[{purple}咖啡厅{white}]你本局已经使用过一次重生了",client);
			return Plugin_Handled;
	}
	TF2_RespawnPlayer(client);
	Selfhealth = RoundToCeil(Selfhealth + playerdamage);
	if(Selfhealth > Selfmaxhealth)
	{
			Selfhealth = Selfmaxhealth;
	}
	FF2_SetBossHealth(0,Selfhealth);
	//FF2_SetBossLives(bossindex,Selflive);
	CPrintToChat(client,"{white}[{purple}咖啡厅{white}]你重生了～",client);
	CPrintToChatAll("{white}[{purple}咖啡厅{white}]%N使用了一次重生机会!", client);
    respawn[client] = 1;
    return Plugin_Handled;
}
public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (strcmp(info,"yes")>=0)
		{
			FakeClientCommand(param1,"sm_spawn");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
void show_Panel(int client)
{
	char buffer[32];
	Menu menu3 = new Menu(MenuHandler1);
	SetMenuTitle(menu3,"是否重生？");
	Format(buffer,sizeof(buffer),"重生");
	AddMenuItem(menu3,"yes",buffer);
	Format(buffer,sizeof(buffer),"不重生");
	AddMenuItem(menu3,"no",buffer);
	SetMenuExitButton(menu3,true);
	DisplayMenu(menu3,client,20);
}
