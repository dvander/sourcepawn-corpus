
#include <sourcemod>
#include <store>
#include <multicolors>
#pragma tabsize 0
#define PREFIX " \x04[Top-Credits]\x01"
int maxCredits = 0;
int maxClient;
bool Checked[MAXPLAYERS + 1] = false;
int counterRANK[MAXPLAYERS + 1];
int targets[MAXPLAYERS + 1];
int itarget;
public Plugin myinfo = 
{
	name = "Top Online Zephyrus Store Credits",
	author = "SheriF",
	description = "Simple menu of Top Online players ranking by their Zephyrus Store Credits",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_otc", Command_OTCredit);
	RegConsoleCmd("sm_onlinetc", Command_OTCredit);
	RegConsoleCmd("sm_onlinetopcredits", Command_OTCredit);
}

public Action Command_OTCredit(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
		Checked[i]=false;
	int counter = 1;
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		Menu menu = new Menu(menuHandler_Credits);
		menu.SetTitle("Online Top Players Credits");
		for(int j = 1; j <= MaxClients; j++)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					if(Store_GetClientCredits(i)>maxCredits&&Checked[i]==false)
					{
						maxCredits = Store_GetClientCredits(i);
						maxClient = i;
					}
				}
			}
			if(Checked[maxClient]==false)
			{
				char szInfo[64];
				Format(szInfo, sizeof(szInfo), "#%d %N | %i Credits", counter,maxClient, Store_GetClientCredits(maxClient));
				menu.AddItem(szInfo, szInfo);
				Checked[maxClient] = true;
				targets[maxClient] = counter;
				counterRANK[maxClient] = counter;
				counter++;
				maxCredits = 0;
			}
		}
	menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}
public void OnClientDisconnect(int client)
{
	Checked[client] = false;
}
public int menuHandler_Credits(Menu menu, MenuAction action, int client, int ItemNum)
{
	if(action == MenuAction_Select)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(targets[i]==(ItemNum+1))
				itarget = i;
		}
		int iClientCurrentRANK = counterRANK[client];
		if (itarget!=client&&Store_GetClientCredits(client)<Store_GetClientCredits(itarget))
		{
		int neededCredits = Store_GetClientCredits(itarget) - Store_GetClientCredits(client);
		PrintToChat(client,"%s You need more \x10%d\x01 Credits to reach \x0C%N's\x01 current Top Credits rank",PREFIX,neededCredits,itarget)
		}
		if (itarget!=client&&Store_GetClientCredits(client)>Store_GetClientCredits(itarget))
		{
		int moreCredits = Store_GetClientCredits(client)-Store_GetClientCredits(itarget);
		PrintToChat(client,"%s You have more \x10%d\x01 Credits than \x0C%N\x01",PREFIX,moreCredits,itarget)
		}
		if (itarget==client)
		PrintToChat(client,"%s You have \x10%d\x01 Credits and your current Top Credits rank is \x07%d",PREFIX,Store_GetClientCredits(client),iClientCurrentRANK)
	}
}
