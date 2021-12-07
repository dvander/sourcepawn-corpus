/*
 *	Sourcemod Tag Chooser
 *	          by
 *	         SpirT
 *
 *  Copyright (C) 2019 SpirT
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar Tag1;
ConVar Tag2;
ConVar Tag3;
ConVar Tag4;
ConVar Tag5;
ConVar Tag6;
ConVar Tag7;
ConVar Tag8;
ConVar Tag9;
ConVar Tag10;

char tag1[32];
char tag2[32];
char tag3[32];
char tag4[32];
char tag5[32];
char tag6[32];
char tag7[32];
char tag8[32];
char tag9[32];
char tag10[32];

public Plugin myinfo = 
{
	name = "[SpirT] Tag Chooser",
	author = PLUGIN_AUTHOR,
	description = "This plugin allow players with custom flags in your server are able to change their Score Board Tag",
	version = PLUGIN_VERSION,
	url = "https://sm.blcm.pt"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_tags", Command_Tags, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_settag", Command_SetTagToClient, ADMFLAG_GENERIC);
	
	Tag1 = CreateConVar("sm_spirt_tagchooser_1", "[Tag1]", "Define your tag number 1");
	Tag2 = CreateConVar("sm_spirt_tagchooser_2", "[Tag2]", "Define your tag number 2");
	Tag3 = CreateConVar("sm_spirt_tagchooser_3", "[Tag3]", "Define your tag number 3");
	Tag4 = CreateConVar("sm_spirt_tagchooser_4", "[Tag4]", "Define your tag number 4");
	Tag5 = CreateConVar("sm_spirt_tagchooser_5", "[Tag5]", "Define your tag number 5");
	Tag6 = CreateConVar("sm_spirt_tagchooser_6", "[Tag6]", "Define your tag number 6");
	Tag7 = CreateConVar("sm_spirt_tagchooser_7", "[Tag7]", "Define your tag number 7");
	Tag8 = CreateConVar("sm_spirt_tagchooser_8", "[Tag8]", "Define your tag number 8");
	Tag9 = CreateConVar("sm_spirt_tagchooser_9", "[Tag9]", "Define your tag number 9");
	Tag10 = CreateConVar("sm_spirt_tagchooser_10", "[Tag10]", "Define your tag number 10");
	
	AutoExecConfig(true, "TagChooser");
	
	TagsMenu();
}

public Action Command_Tags(int client, int args)
{
	/*GetConVarString(Tag1, tag1, sizeof(tag1));
	GetConVarString(Tag2, tag2, sizeof(tag2));
	GetConVarString(Tag3, tag3, sizeof(tag3));
	GetConVarString(Tag4, tag4, sizeof(tag4));
	GetConVarString(Tag5, tag5, sizeof(tag5));
	GetConVarString(Tag6, tag6, sizeof(tag6));
	GetConVarString(Tag7, tag7, sizeof(tag7));
	GetConVarString(Tag8, tag8, sizeof(tag8));
	GetConVarString(Tag9, tag9, sizeof(tag9));
	GetConVarString(Tag10, tag10, sizeof(tag10));*/
	TagsMenu().Display(client, MENU_TIME_FOREVER);
	PrintToServer("[SpirT - Tag Chooser] Player %N is choosing a Tag!", client);
	return Plugin_Handled;
}

public Menu TagsMenu()
{
	Menu menu = new Menu(MH, MENU_ACTIONS_ALL);
	menu.SetTitle("Choose your ScoreBoard tag!");
	menu.AddItem("1", tag1);
	menu.AddItem("2", tag2);
	menu.AddItem("3", tag3);
	menu.AddItem("4", tag4);
	menu.AddItem("5", tag5);
	menu.AddItem("6", tag6);
	menu.AddItem("7", tag7);
	menu.AddItem("8", tag8);
	menu.AddItem("9", tag9);
	menu.AddItem("10", tag10);
	menu.ExitButton = true;
	
	return menu;
}

public int MH(Menu menu, MenuAction action, int client, int item)
{
	char choice[32];
	menu.GetItem(item, choice, sizeof(choice));
	if(action == MenuAction_Select)
	{
		if(StrEqual(choice, "1"))
		{
			GetConVarString(Tag1, tag1, sizeof(tag1));
			if(StrEqual(tag1, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag1);
			}
			else
			{
				CS_SetClientClanTag(client, tag1);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag1);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag1);
			}
		}
		else if(StrEqual(choice, "2"))
		{
			GetConVarString(Tag2, tag2, sizeof(tag2));
			if(StrEqual(tag2, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag2);
			}
			else
			{
				CS_SetClientClanTag(client, tag2);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag2);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag2);
			}
		}
		else if(StrEqual(choice, "3"))
		{
			GetConVarString(Tag3, tag3, sizeof(tag3));
			if(StrEqual(tag3, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag3);
			}
			else
			{
				CS_SetClientClanTag(client, tag3);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag3);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag3);
			}
		}
		else if(StrEqual(choice, "4"))
		{
			GetConVarString(Tag4, tag4, sizeof(tag4));
			if(StrEqual(tag4, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag4);
			}
			else
			{
				CS_SetClientClanTag(client, tag4);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag4);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag4);
			}
		}
		else if(StrEqual(choice, "5"))
		{
			GetConVarString(Tag5, tag5, sizeof(tag5));
			if(StrEqual(tag5, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag5);
			}
			else
			{
				CS_SetClientClanTag(client, tag5);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag5);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag5);
			}
		}
		else if(StrEqual(choice, "6"))
		{
			GetConVarString(Tag6, tag6, sizeof(tag6));
			if(StrEqual(tag6, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag6);
			}
			else
			{
				CS_SetClientClanTag(client, tag6);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag6);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag6);
			}
		}
		else if(StrEqual(choice, "7"))
		{
			GetConVarString(Tag7, tag7, sizeof(tag7));
			if(StrEqual(tag7, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag7);
			}
			else
			{
				CS_SetClientClanTag(client, tag7);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag7);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag7);
			}
		}
		else if(StrEqual(choice, "8"))
		{
			GetConVarString(Tag8, tag8, sizeof(tag8));
			if(StrEqual(tag8, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag8);
			}
			else
			{
				CS_SetClientClanTag(client, tag8);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag8);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag8);
			}
		}
		else if(StrEqual(choice, "9"))
		{
			GetConVarString(Tag9, tag9, sizeof(tag9));
			if(StrEqual(tag9, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag9);
			}
			else
			{
				CS_SetClientClanTag(client, tag9);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag9);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag9);
			}
		}
		else if(StrEqual(choice, "10"))
		{
			GetConVarString(Tag10, tag10, sizeof(tag10));
			if(StrEqual(tag10, ""))
			{
				PrintToChat(client, "[SpirT - Tag Chooser] Sorry, but this tag is not defined correctly, please choose another one and ask server owner to fix it!");
				PrintToServer("[SpirT - Tag Chooser] Player %N tried to choose '%s' but it is not defined correcty! Please goto 'csgo/cfg/sourcemod/TagChooser.cfg' and change value for 'sm_spirt_tagchooser_1' to fix it!", client, tag10);
			}
			else
			{
				CS_SetClientClanTag(client, tag10);
				PrintToChat(client, "[SpirT - Tag Chooser] Yeah! Your tag is set to %s", tag10);
				PrintToServer("[SpirT - TagChooser] Player %N set %s as his/her ScoreBoard Tag", client, tag10);
			}
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Command_SetTagToClient(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SpirT - Tag Chooser] Use: sm_settag <name of the player> <tag do be aplied to the player>");
		return Plugin_Handled;
	}
	
	char PlayerNameArg[32];
	char TagArg[32];
	GetCmdArg(1, PlayerNameArg, sizeof(PlayerNameArg));
	GetCmdArg(2, TagArg, sizeof(TagArg));
	
	int target = FindTarget(client, PlayerNameArg, false, true);
	if(target == 1)
	{
		CS_SetClientClanTag(target, TagArg);
		PrintToChat(client, "[SpirT - Tag Chooser] Tag %s was set to %N", TagArg, target);
		PrintToChat(target, "[SpirT - Tag Chooser] Admin %N set your tag as %s", client, TagArg);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "[SpirT - Tag Chooser] Could not find a Player with '%s'", PlayerNameArg);
		return Plugin_Handled;
	}
}