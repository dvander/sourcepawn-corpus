#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>
#pragma newdecls required

static const char GlovesType[][] = {
"",
"cloud_9",
"immortalis",
"dignitas",
"envyus",
"epsilon",
"faze",
"fnatic",
"g2",
"gambit",
"godsent",
"hell_raisers",
"ibp",
"liquid",
"luminosity",
"mousesports",
"n.i.p",
"navi",
"tsm",
"virtus_pro",
"renegades",
"sk_gaming",
"team_x"
};

static const char GlovesName[][] = {
"Default",
"Cloud9",
"Immortals",
"Team Dignitas",
"EnVyUs",
"Epsilon eSports",
"FaZe Clan",
"Fnatic",
"G2 Esports",
"Gambit Gaming",
"GODSENT",
"HellRaisers",
"iBuyPower",
"Team Liquid",
"Luminosity Gaming",
"mousesports",
"Ninjas in Pyjamas",
"Natus Vincere",
"Team SoloMid",
"Virtus.pro",
"Renegades",
"SK Gaming",
"Team X"
};

int gloves[MAXPLAYERS+1], NumGloves;

Menu hGlovesMenu;
Handle gloves_cookie;

public Plugin myinfo =
{
	name		= "Gloves Menu",
	author		= "AuTok1NGz & MrGibbyGibson. Rewrited by Grey83",
	description	= "Change Your Gloves",
	version		= "1.2.0",
	url			= "https://forums.alliedmods.net/showthread.php?t=288943"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	NumGloves = sizeof(GlovesType);
	HookEvent("player_spawn", PlayerSpawned);
	RegConsoleCmd("sm_gloves", Cmd_ChooseGloves, "Change Your Gloves\nsm_gloves - Open gloves menu\nsm_gloves <num> - Change gloves without menu");
	RegConsoleCmd("sm_gloves_list", Cmd_GlovesList, "Show list of gloves in console");

	gloves_cookie = RegClientCookie("gloves_mdl", "Saved client gloves model", CookieAccess_Private);
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	int num;
	for(int i = 1; i < NumGloves; i++)
	{
		Format(buffer, sizeof(buffer), "materials/models/weapons/v_models/arms/eminem/%s/ct_base_glove.vmt", GlovesType[i]);
		AddFileToDownloadsTable(buffer);
		Format(buffer, sizeof(buffer), "materials/models/weapons/v_models/arms/eminem/%s/ct_base_glove_color.vtf", GlovesType[i]);
		AddFileToDownloadsTable(buffer);
		Format(buffer, sizeof(buffer), "models/weapons/eminem/ct_arms_idf_%s.dx90.vtx", GlovesType[i]);
		AddFileToDownloadsTable(buffer);
		Format(buffer, sizeof(buffer), "models/weapons/eminem/ct_arms_idf_%s.vvd", GlovesType[i]);
		AddFileToDownloadsTable(buffer);
		Format(buffer, sizeof(buffer), "models/weapons/eminem/ct_arms_idf_%s.mdl", GlovesType[i]);
		AddFileToDownloadsTable(buffer);
		if(PrecacheModel(buffer) != 0) num++;
	}
	PrintToServer("[Gloves] Precached gloves: %i of %i", num, NumGloves);

	hGlovesMenu = new Menu(Handle_GlovesMenu);
	hGlovesMenu.SetTitle("Choose Your Glove:\n(%i gloves available)", NumGloves);
	for(int i; i < NumGloves; i++)
	{
		IntToString(i, buffer, sizeof(buffer));
		hGlovesMenu.AddItem(buffer, GlovesName[i]);
	}
	hGlovesMenu.ExitButton = true;
}

public void OnClientCookiesCached(int client)
{
	OnClientPostAdminCheck(client);
}

public void OnClientPostAdminCheck(int client)
{
	char buffer[4];
	GetClientCookie(client, gloves_cookie, buffer, sizeof(buffer));
	gloves[client] = StringToInt(buffer);
}

public Action Cmd_ChooseGloves(int client, int args)
{
	if(client < 1) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else if(IsValidClient(client))
	{
		if(args < 1) hGlovesMenu.Display(client, MENU_TIME_FOREVER);
		else 
		{
			char item[4];
			GetCmdArg(1, item, sizeof(item));
			int choosed = StringToInt(item);
			if(0 <= choosed < NumGloves)
			{
				gloves[client]= choosed;
				IntToString(choosed, item, sizeof(item));
				SetClientCookie(client, gloves_cookie, item);
				PrintToChat(client, " \x04[Gloves] \x07You Choosed \x02%s \x07Glove", GlovesName[gloves[client]]);
			}
			else PrintToChat(client, " \x04[Gloves] \x02Wrong glowes number!\n	\x07The number must be from \x020 \x07to \x02%i", NumGloves - 1);
		}
	}

	return Plugin_Handled;
}

public int Handle_GlovesMenu(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			menu.SetTitle("Choose Your Glove:\nYou use a '%s' (%i/%i)", GlovesName[gloves[client]], gloves[client], NumGloves);
		}
		case MenuAction_DisplayItem:
		{
			char buffer[32];
			int item;
			menu.GetItem(param, buffer, sizeof(buffer));
			if((item = StringToInt(buffer)) == gloves[client])
			{
				Format(buffer, sizeof(buffer), "%s ☑", GlovesName[item]);
				return RedrawMenuItem(buffer);
			}
		}
		case MenuAction_Select:
		{
			char item[4];
			menu.GetItem(param, item, sizeof(item));
			gloves[client] = StringToInt(item);
			SetClientCookie(client, gloves_cookie, item);

			PrintToChat(client, " \x04[Gloves] \x07You Choosed \x02%s \x07Glove", GlovesName[gloves[client]]);
			menu.DisplayAt(client, menu.Selection, 0);
		}
	}
	return 0;
}

public Action Cmd_GlovesList(int client, int args)
{
	if(client < 1) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else if(IsValidClient(client))
	{
		PrintToConsole(client, " #  Gloves name");
		for (int i; i < NumGloves; i++)
		{
				PrintToConsole(client, "%2d) '%s'", i, GlovesName[i], i == gloves[client] ? " ☑" : "");
		}
		PrintToConsole(client, "To quickly choose the glove print the 'sm_gloves <num>'");
		if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
			PrintToChat(client, " \x04[Gloves] \x07%t", "See console for output");
	}

	return Plugin_Handled;
}

public Action PlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(client) && gloves[client] > 0)
	{
		char buffer[PLATFORM_MAX_PATH];
		Format(buffer, sizeof(buffer), "models/weapons/eminem/ct_arms_idf_%s.mdl", GlovesType[gloves[client]]);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", buffer);
	}
}

public bool IsValidClient(int client)
{
	return (0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}