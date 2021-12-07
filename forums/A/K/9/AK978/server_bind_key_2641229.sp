#include <sourcemod>

#define ATTACK        1 
#define JUMP         2 
#define DUCK         4 
#define FORWARD        8 
#define BACK        16 
#define USE            32 
#define CANCEL        64 
#define LEFT         128 
#define RIGHT        256 
#define MOVELEFT     512 
#define MOVERIGHT     1024 
#define ATTACK2        2048 
#define RUN            4096 
#define RELOAD        8192 
#define ALT1        16384 
#define ALT2        32768 
#define SCORE        65536 
#define SPEED        131072 
#define WALK        262144 
#define ZOOM        524288 
#define WEAPON1        1048576 
#define WEPAON2        2097152 
#define BULLRUSH     4194304 
#define GRENADE1     8388608 
#define GRENADE2     16777216 
#define ATTACK3        33554432

new g_player1[MAXPLAYERS+1];
new g_player2[MAXPLAYERS+1];
new g_player3[MAXPLAYERS+1];
new g_player4[MAXPLAYERS+1];
new g_player5[MAXPLAYERS+1];

char command_1[56];
char command_2[56];
char command_3[56];
char command_4[56];
char command_5[56];

char tab_command[MAXPLAYERS+1][56];
char duck_command[MAXPLAYERS+1][56];
char zoom_command[MAXPLAYERS+1][56];
char walk_command[MAXPLAYERS+1][56];
char speed_command[MAXPLAYERS+1][56];

ConVar g_command_1;
ConVar g_command_2;
ConVar g_command_3;
ConVar g_command_4;
ConVar g_command_5;


public Plugin:myinfo = 
{
	name = "[l4d2]server bind key",
	author = "AK978",
	version = "1.2"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_bind_menu", Command_bind_menu, "menu");

	g_command_1 = CreateConVar("sm_command_1", "", "command 1");
	g_command_2 = CreateConVar("sm_command_2", "", "command 2");
	g_command_3 = CreateConVar("sm_command_3", "", "command 3");
	g_command_4 = CreateConVar("sm_command_4", "", "command 4");
	g_command_5 = CreateConVar("sm_command_5", "", "command 5");

	HookConVarChange(g_command_1,	ConVarChanged_Cvars);
	HookConVarChange(g_command_2,	ConVarChanged_Cvars);
	HookConVarChange(g_command_3,	ConVarChanged_Cvars);
	HookConVarChange(g_command_4,	ConVarChanged_Cvars);
	HookConVarChange(g_command_5,	ConVarChanged_Cvars);
	
	AutoExecConfig(true, "server_bind_key");
}

public OnConfigsExecuted()
{
	GetCvars();
}

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetCvars();
}

GetCvars()
{
	GetConVarString(g_command_1, command_1, sizeof command_1);
	GetConVarString(g_command_2, command_2, sizeof command_2);
	GetConVarString(g_command_3, command_3, sizeof command_3);
	GetConVarString(g_command_4, command_4, sizeof command_4);
	GetConVarString(g_command_5, command_5, sizeof command_5);
}

public OnClientDisconnect(Client)
{
	g_player1[Client] = 0;
	g_player2[Client] = 0;
	g_player3[Client] = 0;
	g_player4[Client] = 0;
	g_player5[Client] = 0;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{	
	 if (iButtons == SCORE && g_player1[iClient] == 1)
	 {
		FakeClientCommand(iClient, "%s", tab_command[iClient]);
	 }	 
	 else if (iButtons == DUCK && g_player2[iClient] == 1)
	 {
		FakeClientCommand(iClient, "%s", duck_command[iClient]);
	 }
	 else if (iButtons == ZOOM && g_player3[iClient] == 1)
	 {
		FakeClientCommand(iClient, "%s", zoom_command[iClient]);
	 }
	 else if (iButtons == WALK && g_player4[iClient] == 1)
	 {
		FakeClientCommand(iClient, "%s", walk_command[iClient]);
	 }
	 else if (iButtons == SPEED && g_player5[iClient] == 1)
	 {
		FakeClientCommand(iClient, "%s", speed_command[iClient]);
	 }
}

public Action:Command_bind_menu(client, args)
{
	BuildBindMenu(client)
}

BuildBindMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Playmenu);

	char s_command_1[72];
	char s_command_2[72];
	char s_command_3[72];
	char s_command_4[72];
	char s_command_5[72];
	
	Format(s_command_1, sizeof(s_command_1), "bind key[Tab] - %s", tab_command[client]);
	Format(s_command_2, sizeof(s_command_2), "bind key[Duck] - %s", duck_command[client]);
	Format(s_command_3, sizeof(s_command_3), "bind key[Zoom] - %s", zoom_command[client]);
	Format(s_command_4, sizeof(s_command_4), "bind key[Walk] - %s", walk_command[client]);
	Format(s_command_5, sizeof(s_command_5), "bind key[Speed] - %s", speed_command[client]);
	
	AddMenuItem(menu, "key_tab", s_command_1);
	AddMenuItem(menu, "key_duck", s_command_2);
	AddMenuItem(menu, "key_zoom", s_command_3);
	AddMenuItem(menu, "key_walk", s_command_4);
	AddMenuItem(menu, "key_speed", s_command_5);
	AddMenuItem(menu, "clear_all", "clear all");
	
	SetMenuTitle(menu, "bind key");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Playmenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new String:item[56];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			if(StrEqual(item, "key_tab", false))
			{
				g_player1[param1] = 1;
				BuildBindTabMenu(param1);
			}	
			else if(StrEqual(item, "key_duck", false))
			{
				g_player2[param1] = 1;
				BuildBindDuckMenu(param1);
			}
			else if(StrEqual(item, "key_zoom", false))
			{
				g_player3[param1] = 1;
				BuildBindZoomMenu(param1);
			}
			else if(StrEqual(item, "key_walk", false))
			{
				g_player4[param1] = 1;
				BuildBindWalkMenu(param1);
			}
			else if(StrEqual(item, "key_speed", false))
			{
				g_player5[param1] = 1;
				BuildBindSpeedMenu(param1);
			}
			else if(StrEqual(item, "clear_all", false))
			{
				g_player1[param1] = 0;
				g_player2[param1] = 0;
				g_player3[param1] = 0;
				g_player4[param1] = 0;
				g_player5[param1] = 0;
				
				tab_command[param1][0] = '\0';
				duck_command[param1][0] = '\0';
				zoom_command[param1][0] = '\0';
				walk_command[param1][0] = '\0';
				speed_command[param1][0] = '\0';
			}
		}	
	}
}

BuildBindTabMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_TabMenu);
	
	AddMenuItem(menu, command_1, command_1);
	AddMenuItem(menu, command_2, command_2);
	AddMenuItem(menu, command_3, command_3);
	AddMenuItem(menu, command_4, command_4);
	AddMenuItem(menu, command_5, command_5);

	SetMenuTitle(menu, "Tab Command");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_TabMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new String:item[56];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			strcopy(tab_command[param1], sizeof(tab_command[]), item);
		}	
	}
}

BuildBindDuckMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DuckMenu);
	
	AddMenuItem(menu, command_1, command_1);
	AddMenuItem(menu, command_2, command_2);
	AddMenuItem(menu, command_3, command_3);
	AddMenuItem(menu, command_4, command_4);
	AddMenuItem(menu, command_5, command_5);

	SetMenuTitle(menu, "Duck Command");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_DuckMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new String:item[56];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			strcopy(duck_command[param1], sizeof(duck_command[]), item);
		}	
	}
}

BuildBindZoomMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ZoomMenu);
	
	AddMenuItem(menu, command_1, command_1);
	AddMenuItem(menu, command_2, command_2);
	AddMenuItem(menu, command_3, command_3);
	AddMenuItem(menu, command_4, command_4);
	AddMenuItem(menu, command_5, command_5);

	SetMenuTitle(menu, "Zoom Command");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_ZoomMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new String:item[56];
			GetMenuItem(menu, param2, item, sizeof(item));
				
			strcopy(zoom_command[param1], sizeof(zoom_command[]), item);
		}	
	}
}

BuildBindWalkMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_WalkMenu);
	
	AddMenuItem(menu, command_1, command_1);
	AddMenuItem(menu, command_2, command_2);
	AddMenuItem(menu, command_3, command_3);
	AddMenuItem(menu, command_4, command_4);
	AddMenuItem(menu, command_5, command_5);

	SetMenuTitle(menu, "Walk Command");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_WalkMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new String:item[56];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			strcopy(walk_command[param1], sizeof(walk_command[]), item);
		}	
	}
}

BuildBindSpeedMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpeedMenu);
	
	AddMenuItem(menu, command_1, command_1);
	AddMenuItem(menu, command_2, command_2);
	AddMenuItem(menu, command_3, command_3);
	AddMenuItem(menu, command_4, command_4);
	AddMenuItem(menu, command_5, command_5);

	SetMenuTitle(menu, "Speed Command");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SpeedMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new String:item[56];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			strcopy(speed_command[param1], sizeof(speed_command[]), item);
		}	
	}
}