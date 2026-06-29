#include <sourcemod>

public Plugin:myinfo = 
{
	name = "FireWaLL Radio",
	author = "LightningZLaser",
	description = "Lets players listen to in-game radio",
	version = "1.02",
	url = "www.FireWaLLCS.net/forums"
}

public OnPluginStart()
{
	CreateConVar("firewallradio", "1", "FireWaLL Radio", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("fr_welcome_message", "1", "1 to enable welcome message when player joins server. 0 to disable.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("fr_round_message", "1", "1 to enable reminder messages each round. 0 to disable.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("fr_listen_message", "1", "1 to enable messages when players start listening to a station and when they stop listening. 0 to disable.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("radio", ConsoleCmd);
	RegConsoleCmd("radiooff", StopRadio);
	HookEvent("round_start", GameStart);
}

/*
* DISABLED. No longer required. Leaving these lines here temporarily until I can confirm it is stable.
new WelcomeMessage = 1; // Change to 0 to disable welcome message (Not Recommended)
new RoundMessage = 1; // Change to 0 to disable reminder messages each round
new ListenMessage = 1; //Change to 0 to disable message when players listen to a station
*/

public Action:ConsoleCmd(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "FireWaLL Radio");
	AddMenuItem(menu, "Choose Station From Menu", "Choose Station From Menu");
	AddMenuItem(menu, "Choose Station From MOTD", "Choose Station From MOTD");
	AddMenuItem(menu, "Stop Listening to Radio", "Stop Listening to Radio");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new Handle:listenMessage = FindConVar("fr_listen_message");
		new ListenMessage = GetConVarInt(listenMessage);
		new String:info[64];
		new String:steamid[64];
		new String:name[64];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetMenuItem(menu, param2, info, sizeof(info));
		if(strcmp(info, "Choose Station From Menu") == 0)
		{
			new Handle:menuradiomain = CreateMenu(MenuHandler1);
			SetMenuTitle(menuradiomain, "Select Radio Hosting Site");
			AddMenuItem(menuradiomain, "Sourcetunes", "Sourcetunes");
			SetMenuExitButton(menuradiomain, true);
			DisplayMenu(menuradiomain, client, 0);
		}
		if(strcmp(info, "Sourcetunes") == 0)
		{
			new Handle:menuradio = CreateMenu(MenuHandler1);
			SetMenuTitle(menuradio, "Select Genre");
			AddMenuItem(menuradio, "Alternative", "Alternative");
			AddMenuItem(menuradio, "Classic Rock", "Classic Rock");
			AddMenuItem(menuradio, "Top 40 Pop Rock Alternative", "Top 40 Pop Rock Alternative");
			AddMenuItem(menuradio, "Hip Hop R&B", "Hip Hop R&B");
			AddMenuItem(menuradio, "Country", "Country");
			AddMenuItem(menuradio, "Urban Rap", "Urban Rap");
			AddMenuItem(menuradio, "Electronic House Techno", "Electronic House Techno");
			AddMenuItem(menuradio, "80's 90's Decades", "80's 90's Decades");
			AddMenuItem(menuradio, "Dubstep Electronic", "Dubstep Electronic");
			AddMenuItem(menuradio, "Alternative Rock 90's", "Alternative Rock 90's");
			AddMenuItem(menuradio, "Dance Electronic Pop", "Dance Electronic Pop");
			SetMenuExitButton(menuradio, true);
			DisplayMenu(menuradio, client, 0);
		}
		if(strcmp(info, "Stop Listening to Radio") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s stopped listening to the radio.", name);
			}
			ShowMOTDPanel(client, "FireWaLL Radio", "about:blank", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Choose Station From MOTD") == 0)
		{
			new Handle:menumotd = CreateMenu(MenuHandler1);
			SetMenuTitle(menumotd, "Select Radio Hosting Site");
			AddMenuItem(menumotd, "SourcetunesMOTD", "Sourcetunes");
			SetMenuExitButton(menumotd, true);
			DisplayMenu(menumotd, client, 0);
		}
		if(strcmp(info, "SourcetunesMOTD") == 0)
		{
			ShowMOTDPanel(client, "Select Station", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&menu=1", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Alternative") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Alternative radio station.", name);
			}
			ShowMOTDPanel(client, "Alternative", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=13&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Classic Rock") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Classic Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Classic Rock", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=12&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Top 40 Pop Rock Alternative") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Top 40 Pop Rock Alternative radio station.", name);
			}
			ShowMOTDPanel(client, "Top 40 Pop Rock Alternative", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=11&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Hip Hop R&B") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Hip Hop R&B radio station.", name);
			}
			ShowMOTDPanel(client, "Hip Hop R&B", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=10&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Country") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Country radio station.", name);
			}
			ShowMOTDPanel(client, "Country", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=9&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Urban Rap") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Urban Rap radio station.", name);
			}
			ShowMOTDPanel(client, "Urban Rap", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=14&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Electronic House Techno") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electronic House Techno radio station.", name);
			}
			ShowMOTDPanel(client, "Electronic House Techno", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=15&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "80's 90's Decades") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a 80's 90's Decades radio station.", name);
			}
			ShowMOTDPanel(client, "80's 90's Decades", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=16&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Dubstep Electronic") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Dubstep Electronic radio station.", name);
			}
			ShowMOTDPanel(client, "Dubstep Electronic", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=17&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Alternative Rock 90's") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Alternative Rock 90'sradio station.", name);
			}
			ShowMOTDPanel(client, "Alternative Rock 90's", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=18&type=default", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Dance Electronic Pop") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Dance Electronic Pop radio station.", name);
			}
			ShowMOTDPanel(client, "Dance Electronic Pop", "http://www.sourcetunes.com/multiplayer-gs/index.php?page=stations&action=play&station=19&type=default", MOTDPANEL_TYPE_URL);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	new Handle:welcomeMessage = FindConVar("fr_welcome_message");
	new WelcomeMessage = GetConVarInt(welcomeMessage);
	if (WelcomeMessage == 1)
	{
		PrintToChat(client, "\x03[\x04FireWaLL Radio\x03] \x01This server runs \x04FireWaLL Radio \x01by \x03LightningZLaser\x01. Radio stations hosted by \x03Sourcetunes\x01.");
		PrintToChat(client, "\x03[\x04FireWaLL Radio\x03] \x01Type \x03!radio \x01in chat or \x03radio \x01in console to listen to your favorite music genres.");
	}
}

public Action:GameStart(Handle:Event, const String:Name[], bool:Broadcast)
{
	new Handle:roundMessage = FindConVar("fr_round_message");
	new RoundMessage = GetConVarInt(roundMessage);
	if (RoundMessage == 1)
	{
		PrintToChatAll("\x03[\x04FireWaLL Radio\x03] \x01Type \x03!radio \x01in chat or \x03radio \x01in console to listen to your favorite music genres.");
	}
}

public Action:StopRadio(client, args)
{
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	new String:steamid[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	new Handle:listenMessage = FindConVar("fr_listen_message");
	new ListenMessage = GetConVarInt(listenMessage);
	if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
	{
		PrintToChatAll("%s stopped listening to the radio.", name);
	}
	ShowMOTDPanel(client, "FireWaLL Radio", "about:blank", MOTDPANEL_TYPE_URL);
}