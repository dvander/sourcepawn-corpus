#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

int ig_time[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Cmd chat voice",
	author = "dr lex",
	description = "Building ready text commands",
	version = "1.3",
	url = "http://steamcommunity.com/id/dr_lex"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_voice", Command_Voice);
	RegConsoleCmd("sm_v", Command_Voice);
	
	LoadTranslations("voice.phrases");
}

stock int HxValidClient(int &i)
{
	if (IsClientInGame(i))
	{
		if (!IsFakeClient(i))
		{
			if (GetClientTeam(i) == 2)
			{
				if (IsPlayerAlive(i))
				{
					return 1;
				}
			}
		}
	}

	return 0;
}

public Action Command_Voice(int client, int args)
{
	if (HxValidClient(client))
	{
		if (ig_time[client] < GetTime())
		{
			ig_time[client] = GetTime() + 1;
			VoiceMenu(client);
		}
	}
}

public Action VoiceMenu(int client)
{
	if (HxValidClient(client))
	{
		char translation[100];
		Menu menu = new Menu(VoiceMenuHandler);
		menu.SetTitle("Menu");
		Format(translation, sizeof(translation), "%T", "Main", client);  
		menu.AddItem("option1", translation);
		Format(translation, sizeof(translation), "%T", "Are common", client);  
		menu.AddItem("option2", translation);
		Format(translation, sizeof(translation), "%T", "Ask for an item", client);  
		menu.AddItem("option3", translation);
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int VoiceMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (strcmp(info,"option1") == 0)
			{
				MainMenu(param1);
			}
			if (strcmp(info,"option2") == 0) 
			{
				AreCommonMenu(param1);
			}
			if (strcmp(info,"option3") == 0) 
			{
				CommonMenu2(param1);
			}
		}
	}
}

public Action MainMenu(int client)
{
	if (HxValidClient(client))
	{
		char translation[100]; 
		Menu menu = new Menu(GeneralCmd);
		menu.SetTitle("Menu/Information");
		Format(translation, sizeof(translation), "%T", "Ready", client);  
		menu.AddItem("1", translation);
		Format(translation, sizeof(translation), "%T", "No", client);  
		menu.AddItem("2", translation);
		Format(translation, sizeof(translation), "%T", "Yes", client);  
		menu.AddItem("3", translation);
		Format(translation, sizeof(translation), "%T", "Let's Go", client);  
		menu.AddItem("4", translation);
		Format(translation, sizeof(translation), "%T", "Hurry Up!", client);  
		menu.AddItem("5", translation);
		Format(translation, sizeof(translation), "%T", "Wait Here!", client);  
		menu.AddItem("6", translation);
		Format(translation, sizeof(translation), "%T", "Be Careful", client);  
		menu.AddItem("7", translation);
		
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public Action AreCommonMenu(int client)
{
	if (HxValidClient(client))
	{
		char translation[100]; 
		Menu menu = new Menu(GeneralCmd);
		menu.SetTitle("Menu/Information");
		Format(translation, sizeof(translation), "%T", "Sorry", client);  
		menu.AddItem("8", translation);
		Format(translation, sizeof(translation), "%T", "Thanks!", client);  
		menu.AddItem("9", translation);
		Format(translation, sizeof(translation), "%T", "Lead On", client);  
		menu.AddItem("10", translation);
		Format(translation, sizeof(translation), "%T", "Nice Job!", client);  
		menu.AddItem("11", translation);
		Format(translation, sizeof(translation), "%T", "I'm With You", client);  
		menu.AddItem("12", translation);	
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public Action CommonMenu2(int client)
{
	if (HxValidClient(client))
	{
		char translation[100]; 
		Menu menu = new Menu(GeneralCmd);
		menu.SetTitle("Menu/Information");
		Format(translation, sizeof(translation), "%T", "Need a box", client);  
		menu.AddItem("13", translation);
		Format(translation, sizeof(translation), "%T", "Need a First Aid Kit or Tablets", client);  
		menu.AddItem("14", translation);
		Format(translation, sizeof(translation), "%T", "Need a defibrillator", client);  
		menu.AddItem("15", translation);	
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int GeneralCmd(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Ready");
			}
			if (strcmp(info,"2") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "No");
			}
			if (strcmp(info,"3") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Yes");
			}
			if (strcmp(info,"4") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Let's Go");
			}
			if (strcmp(info,"5") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Hurry Up!");
			}
			if (strcmp(info,"6") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Wait Here!");
			}
			if (strcmp(info,"7") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Be Careful");
			}
			if (strcmp(info,"8") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Sorry");
			}
			if (strcmp(info,"9") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Thanks!");
			}
			if (strcmp(info,"10") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Lead On");
			}
			if (strcmp(info,"11") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Nice Job!");
			}
			if (strcmp(info,"12") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "I'm With You");
			}
			if (strcmp(info,"13") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Need a box");
			}
			if (strcmp(info,"14") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Need a First Aid Kit or Tablets");
			}
			if (strcmp(info,"15") == 0) 
			{
				PrintToChatAll("\x04[!v] \x01%N: \x03%t", param1, "Need a defibrillator");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				VoiceMenu(param1);
			}
		}
	}
}