#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SNIPER007"
#define PLUGIN_VERSION "1.3"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <emitsoundany>
#include <sdktools_sound>
#include <sdkhooks>
#include <adminmenu>
#include <warden>

#pragma newdecls required

bool g_bsong1 = false;
bool g_bsong2 = false;

int songtimer1;
int songtimer2;

public Plugin myinfo = 
{
	name = "Karaoke-Premium", 
	author = PLUGIN_AUTHOR, 
	description = "Karaoke for Jailbreak CS:GO servers", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/Sniper-oo7/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_karaoke", CMD_Karaoke);
	
	HookEvent("round_start", Event_RoundStart);
	
	CreateTimer(1.0, Karaoke, _, TIMER_REPEAT);
	
	AutoExecConfig(true, "Karaoke-Premium");
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/music/karaoke/Badtobone.mp3"); //SOUNDs
	AddFileToDownloadsTable("sound/music/karaoke/Wham-Bam-Shang-A-Lang.mp3");
	AddFileToDownloadsTable("sound/music/karaoke/stopsound.mp3");
	
	PrecacheSound("music/karaoke/Badtobone.mp3");
	PrecacheSound("music/karaoke/Wham-Bam-Shang-A-Lang.mp3");
	PrecacheSound("music/karaoke/stopsound.mp3");
}

public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	g_bsong1 = false;
	g_bsong2 = false;
}

public Action CMD_Karaoke(int client, int args)
{
	if (warden_iswarden(client))
	{
		if (IsValidClient(client, true))
		{
			openMenu(client);
		}
		else
		{
			ReplyToCommand(client, " \x01[\x04Karaoke\x01] \x01You have to be alive.");
		}
	}
	else
	{
		ReplyToCommand(client, " \x01[\x04Karaoke\x01] \x01You have to be a warden.");
	}
	
	return Plugin_Handled;
}

void openMenu(int client)
{
	Menu menu = new Menu(mHlaskyHandler);
	
	menu.SetTitle("Choose a song:");
	
	menu.AddItem("hlaska1", "Bad To Bone");
	menu.AddItem("hlaska2", "Wham-Bam-Shang-A-Lang");
	menu.AddItem("hlaska3", "[TURN OFF KARAOKE]");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int mHlaskyHandler(Menu menu, MenuAction action, int client, int index)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsValidClient(client, true))
			{
				char szItem[32];
				menu.GetItem(index, szItem, sizeof(szItem));
				
				if (StrEqual(szItem, "hlaska1"))
				{
					if (g_bsong1 == false && g_bsong2 == false)
					{
						songtimer1 = 52;
						g_bsong1 = true;
						EmitSoundToAll("music/karaoke/Badtobone.mp3", client, SNDCHAN_STREAM);
						PrintCenterTextAll("\n[<font color='#00FF00'>WARDEN</font><font color='#ffffff'>]\n turn on:</font> <font color='#ff0000'>Bad To Bone!</font>");
						openMenu(client);
					}
					else
					{
						PrintToChat(client, " \x04[Karaoke]\x01 Song already playing, you have to turn off old song!");
						openMenu(client);
					}
				}
				else if (StrEqual(szItem, "hlaska2"))
				{
					if (g_bsong1 == false && g_bsong2 == false)
					{
						songtimer2 = 76;
						g_bsong2 = true;
						EmitSoundToAll("music/karaoke/Wham-Bam-Shang-A-Lang.mp3", client, SNDCHAN_STREAM);
						PrintCenterTextAll("\n[<font color='#00FF00'>WARDEN</font><font color='#ffffff'>]\n turn on:</font> <font color='#ff0000'>Wham Bam Shang-A-Lang!</font>");
						openMenu(client);
					}
					else
					{
						PrintToChat(client, " \x04[Karaoke]\x01 Song already playing, you have to turn off old song!");
						openMenu(client);
					}
				}
				else if (StrEqual(szItem, "hlaska3"))
				{
					PrintToChatAll(" \x04[Karaoke]\x01 All karaoke players was deleted, now they canno't talk");
					openMenu(client);
					if (g_bsong1 == true)
					{
						EmitSoundToAll("music/karaoke/stopsound.mp3", client, SNDCHAN_STREAM);
						g_bsong1 = false;
						songtimer1 = 0;
						PrintToChat(client, " \x04[Karaoke]\x01 You turn off song, now you can turn on other songs!");
						PrintCenterTextAll("\n[<font color='#00FF00'>WARDEN</font><font color='#ffffff'>]\n turn off karaoke</font>");
					}
					
					if (g_bsong2 == true)
					{
						EmitSoundToAll("music/karaoke/stopsound.mp3", client, SNDCHAN_STREAM);
						g_bsong2 = false;
						songtimer2 = 0;
						PrintToChat(client, " \x04[Karaoke]\x01 You turn off song, now you can turn on other songs!");
						PrintCenterTextAll("\n[<font color='#00FF00'>WARDEN</font><font color='#ffffff'>]\n turn off karaoke</font>");
					}
				}
			}
		}
		case MenuAction_End:
	    {
	    	delete menu;
	    }
	}
}

public Action Karaoke(Handle timer)
{
	if (songtimer1 >= 1)
	{
		songtimer1--;
	}
	
	if (songtimer2 >= 1)
	{
		songtimer2--;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bsong1 == true)
		{
			if (songtimer1 >= 33)
			{
				int zacatek1 = songtimer1 - 33;
				PrintCenterTextAll("\n<font color='#00FF00'>START IN %i</font>", zacatek1);
			}
			
			if (songtimer1 == 31)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>On the day I was born,</font>");
			}
			
			if (songtimer1 == 29)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>The nurse all gathered round,</font>");
			}
			
			if (songtimer1 == 27)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>And the gayzed in wide wonder,</font>");
			}
			
			if (songtimer1 == 25)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>At the joy they had found</font>");
			}
			
			if (songtimer1 == 22)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>The head nurse spoke up</font>");
			}
			
			if (songtimer1 == 20)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>She said leave this one alone</font>");
			}
			
			if (songtimer1 == 18)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>She could tell right away</font>");
			}
			
			if (songtimer1 == 15)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>That I was bad to the bone</font>");
			}
			
			if (songtimer1 == 13)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Bad to the bone</font>");
			}
			
			if (songtimer1 == 10)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Bad to the bone..</font>");
			}
			
			if (songtimer1 == 7)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>B-B-B-Bad</font>");
			}
			
			if (songtimer1 == 4)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>B-B-B-B-Bad</font>");
			}
			
			if (songtimer1 == 3)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>B-B-B-B-B-Bad</font>");
			}
			
			if (songtimer1 == 2)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Bad to the bone</font>");
			}
			
			if (songtimer1 == 1)
			{
				g_bsong1 = false;
			}
		}
		
		if (g_bsong2 == true)
		{
			if (songtimer2 >= 66)
			{
				int zacatek2 = songtimer2 - 66;
				PrintCenterTextAll("\n<font color='#00FF00'>STARTING IN %i</font>", zacatek2);
			}
			
			if (songtimer2 == 65)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Starry nights,</font>");
			}
			
			if (songtimer2 == 64)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Sunny days I always thought that love should be that way</font>");
			}
			
			if (songtimer2 == 62)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Sunny days I always thought that love should be that way</font>");
			}
			
			if (songtimer2 == 60)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Sunny days I always thought that love should be that way</font>");
			}
			
			if (songtimer2 == 58)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Sunny days I always thought that love should be that way</font>");
			}
			
			if (songtimer2 == 57)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Then comes a time that you're ridden with doubts</font>");
			}
			
			if (songtimer2 == 55)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Then comes a time that you're ridden with doubts</font>");
			}
			
			if (songtimer2 == 54)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>You've loved all you can and now you're all loved out</font>");
			}
			
			if (songtimer2 == 52)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>You've loved all you can and now you're all loved out</font>");
			}
			
			if (songtimer2 == 50)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>You've loved all you can and now you're all loved out</font>");
			}
			
			if (songtimer2 == 49)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Ooh Ooh baby we've been long long way</font>");
			}
			
			if (songtimer2 == 47)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Ooh Ooh baby we've been long long way</font>");
			}
			
			if (songtimer2 == 45)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Ooh Ooh baby we've been long long way</font>");
			}
			
			if (songtimer2 == 43)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Ooh Ooh baby we've been long long wayyy</font>");
			}
			
			if (songtimer2 == 42)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>And who's to say</font>");
			}
			
			if (songtimer2 == 39)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Were will be tomorrow?</font>");
			}
			
			if (songtimer2 == 37)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Were will be tomorrow?</font>");
			}
			
			if (songtimer2 == 35)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Were will be tomorrow?</font>");
			}
			
			if (songtimer2 == 34)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Well, my hearts say nooo</font>");
			}
			
			if (songtimer2 == 31)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Well, my hearts say nooo</font>");
			}
			
			if (songtimer2 == 30)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>But my mind says it's so</font>");
			}
			
			if (songtimer2 == 28)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>But my mind says it's so</font>");
			}
			
			if (songtimer2 == 26)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>That we've got a love,</font>");
			}
			
			if (songtimer2 == 23)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Is it a love to stayyy</font>");
			}
			
			if (songtimer2 == 21)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Is it a love to stayyyy</font>");
			}
			
			if (songtimer2 == 19)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Is it a love to stayyyy</font>");
			}
			
			if (songtimer2 == 18)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>We've got a Wham</font>");
			}
			
			if (songtimer2 == 17)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Bam</font>");
			}
			
			if (songtimer2 == 16)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Shan-A-Lang and a Sha-la-la-la-la-la-la thing</font>");
			}
			
			if (songtimer2 == 14)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Sha-la-la-la-la-la-la thing</font>");
			}
			
			if (songtimer2 == 9)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Wham Ban Shan-A-Lang</font>");
			}
			
			if (songtimer2 == 7)
			{
				PrintCenterTextAll("\n<font color='#00FF00'>Sha-la-la-la-la-la-la thing</font>");
			}
			
			if (songtimer2 == 1)
			{
				g_bsong2 = false;
			}
		}
	}
}

stock bool IsValidClient(int client, bool alive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}
