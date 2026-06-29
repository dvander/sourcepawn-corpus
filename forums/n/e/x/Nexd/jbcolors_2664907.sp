#include <sourcemod>

#define PLUGIN_NEV	"jbcolors"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=318363"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_URL	"https://github.com/KillStr3aK"
#pragma tabsize 0

int iTargetCache[MAXPLAYERS+1];

ConVar gAuto;

public Plugin myinfo = 
{
	name = PLUGIN_NEV,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	RegConsoleCmd("sm_setcolor", Command_SetColor); //this one is only restricted for the CT team
	//RegAdminCmd("sm_Setcolor", Command_SetColor, ADMFLAG_GENERIC); //Remove the comment part if you want it only for the admins with b flag (And comment out the other one)

	gAuto = CreateConVar("sm_jb_colors", "0", "0 - automatic | 1 - CT's can set colors for the players one by one");
}

public Action Command_SetColor(int client, int args)
{
	if(GetClientTeam(client) != 3)
	{
		PrintToChat(client, "Sorry, but only the CT team can use this command.");
		return Plugin_Handled;
	}

	if(gAuto.IntValue == 1)
	{
		SetPlayerColorMenu(client);
	} else {
		PrintToChat(client, "This comamnd is currently disabled.");
	}

	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontbroadcast)
{
	if(gAuto.IntValue == 0)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if(!IsValidClient(i))
				continue;

			SetRandomColor(i);
		}
	}
}

stock void ColorMenu(int client)
{
	char playername[MAX_NAME_LENGTH+1];

	Menu menu = CreateMenu(SetPlayerColor);
	menu.SetTitle("Set a player");
	for (int i = 1; i <= MaxClients; ++i)
	{
		if(!IsValidClient(i))
			continue;

		GetClientName(i, playername, sizeof(playername));
		menu.AddItem(i, playername);
	}
	menu.Display(client, 20);
}

stock void SetPlayerColorMenu(int client)
{
	Menu menu = CreateMenu(SelectColor);
	menu.SetTitle("Set a color");
	for (int i = 1; i <= MaxClients; ++i)
	{
		menu.AddItem("Random", "Random");
		menu.AddItem("Red", "Red");
		menu.AddItem("Green", "Green");
		menu.AddItem("Cyan", "Cyan");
		menu.AddItem("Yellow", "Yellow");
		menu.AddItem("Orange", "Orange");
		menu.AddItem("Pink", "Pink");
		menu.AddItem("Purple", "Purple");
		menu.AddItem("Black", "Black");
		menu.AddItem("Lightblue", "Lightblue");
	}

	menu.Display(client, 20);
}

public int SetPlayerColor(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{		
		char info[10];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		iTargetCache[client] = StringToInt(info);
		SetPlayerColorMenu(client);
	}
}

public int SelectColor(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{		
		char info[20];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		int colors[3] = {0, 0, 0};
		if(StrEqual(info, "Random"))
		{
			for (int i = 0; i < 2; ++i)
			{
				colors[i] = GetRandomInt(0, 255);
			}
		}
		if(StrEqual(info, "Red"))
		{
			colors[0] = 255;
		}
		if(StrEqual(info, "Green"))
		{
			colors[1] = 255;
		}
		if(StrEqual(info, "Blue"))
		{
			colors[2] = 255;
		}
		if(StrEqual(info, "Cyan"))
		{
			colors[0] = 89;
			colors[1] = 216;
			colors[2] = 179;
		}
		if(StrEqual(info, "Yellow"))
		{
			colors[0] = 221;
			colors[1] = 255;
		}
		if(StrEqual(info, "Orange"))
		{
			colors[0] = 255;
			colors[1] = 157;
		}
		if(StrEqual(info, "Pink"))
		{
			colors[0] = 255;
			colors[2] = 255;
		}
		if(StrEqual(info, "Purple"))
		{
			colors[0] = 135;
			colors[1] = 255;
		}
		if(StrEqual(info, "Black"))
		{
			colors[0] = 0;
			colors[1] = 0;
			colors[2] = 0;
		}
		if(StrEqual(info, "Lightblue"))
		{
			colors[0] = 7;
			colors[1] = 255;
			colors[2] = 213;
		}

		SetColor(iTargetCache[client], colors);

		char playername[MAX_NAME_LENGTH+1];
		GetClientName(iTargetCache[client], playername, sizeof(playername));
		PrintToChat(client, "You've changed %s's colors to: \x04%s", playername, info);
		ResetPlayer(client);
	}
}

stock void ResetPlayer(int client)
{
	iTargetCache[client] = 0;
}

stock void SetColor(int client, int colors[3])
{
    SetEntityRenderColor(client, colors[0], colors[1], colors[2], 255);
}

stock void SetRandomColor(int client)
{
	int g_iColors[3];
	for (int i = 0; i < 2; ++i)
	{
		g_iColors[i] = GetRandomInt(0, 255);
	}

    SetEntityRenderColor(client, g_iColors[0], g_iColors[1], g_iColors[2], 255);
}

stock bool IsValidClient(int client)
{
	if(client <= 0) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	if(IsFakeClient(client)) return false;
	if(IsClientSourceTV(client)) return false;
	if(!IsPlayerAlive(client)) return false;
	if(!(GetClientTeam(client) == 2)) return false;
	return IsClientInGame(client);
}