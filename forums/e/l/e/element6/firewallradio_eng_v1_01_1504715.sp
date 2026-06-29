#include <sourcemod>

public Plugin:myinfo = 
{
	name = "FireWaLL Radio",
	author = "LightningZLaser",
	description = "Lets players listen to in-game radio",
	version = "1.01",
	url = "www.FireWaLLCS.net/forums"
}

public OnPluginStart()
{
	RegConsoleCmd("radio", ConsoleCmd);
	RegConsoleCmd("say !radio", ConsoleCmd);
	RegConsoleCmd("say_team !radio", ConsoleCmd);
	HookEvent("round_start", GameStart);
}

new WelcomeMessage = 1; // Change to 0 to disable welcome message (Not Recommended)
new RoundMessage = 1; // Change to 0 to disable reminder messages each round
new ListenMessage = 1; //Change to 0 to disable message when players listen to a station

public Action:ConsoleCmd(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "Samuel L Jackson Radio");
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
		new String:info[64];
		new String:steamid[64];
		new String:name[64];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetMenuItem(menu, param2, info, sizeof(info));
		if(strcmp(info, "Choose Station From Menu") == 0)
		{
			new Handle:menuradio = CreateMenu(MenuHandler1);
			SetMenuTitle(menuradio, "Select Genre");
			AddMenuItem(menuradio, "Pop", "Pop");
			AddMenuItem(menuradio, "Electro/Dubstep/Trance", "Electro/Dubstep/Trance");
			AddMenuItem(menuradio, "Rock", "Rock");
			AddMenuItem(menuradio, "Country/Americana", "Country/Americana");
			AddMenuItem(menuradio, "Blues/Jazz", "Blues/Jazz");
			AddMenuItem(menuradio, "Oldies", "Oldies");
			AddMenuItem(menuradio, "Rap/RnB/Urban", "Rap/RnB/Urban");
			AddMenuItem(menuradio, "Latin/World", "Latin/World");
			SetMenuExitButton(menuradio, true);
			DisplayMenu(menuradio, client, 0);
		}
		if(strcmp(info, "Stop Listening to Radio") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s stopped listening to the radio.", name);
			}
			ShowMOTDPanel(client, "Samuel L Jackson Radio", "about:blank", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Choose Station From MOTD") == 0)
		{
			ShowMOTDPanel(client, "Select Station", "http://www.sourcetunes.com/multiplayer/go.php?uid=estx4r321te9x5w0jwh0", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Pop") == 0)
		{
			new Handle:menupop = CreateMenu(MenuHandler1);
			SetMenuTitle(menupop, "Select A Pop Station");
			AddMenuItem(menupop, "ChannelONE", "ChannelONE");
			AddMenuItem(menupop, "Mix 106", "Mix 106");
			AddMenuItem(menupop, "70s Pop Hits", "70s Pop Hits");
			AddMenuItem(menupop, "70s Lite Hits", "70s Lite Hits");
			AddMenuItem(menupop, "80s Pop Hits", "80s Pop Hits");
			AddMenuItem(menupop, "80s Lite Hits", "80s Lite Hits");
			AddMenuItem(menupop, "90s Pop Hits", "90s Pop Hits");
			AddMenuItem(menupop, "90s Rhythmic Hits", "90s Rhythmic Hits");
			AddMenuItem(menupop, "90s Lite Hits", "90s Lite Hits");
			SetMenuExitButton(menupop, true);
			DisplayMenu(menupop, client, 0);
		}
		if(strcmp(info, "Rock") == 0)
		{
			new Handle:menurock = CreateMenu(MenuHandler1);
			SetMenuTitle(menurock, "Select A Rock Station");
			AddMenuItem(menurock, "Hard Rock", "Hard Rock");
			AddMenuItem(menurock, "Alternative Rock", "Alternative Rock");
			AddMenuItem(menurock, "Classic Rock", "Classic Rock");
			AddMenuItem(menurock, "Hair Voltage", "Hair Voltage");
			AddMenuItem(menurock, "Tapestry", "Tapestry");
			AddMenuItem(menurock, "Love Bites", "Love Bites");
			AddMenuItem(menurock, "Dark Metal", "Dark Metal");
			SetMenuExitButton(menurock, true);
			DisplayMenu(menurock, client, 0);
		}
		if(strcmp(info, "Rap/RnB/Urban") == 0)
		{
			new Handle:menurap = CreateMenu(MenuHandler1);
			SetMenuTitle(menurap, "Select A Rap/RnB/Urban Station");
			AddMenuItem(menurap, "V101 R&B", "V101 R&B");
			AddMenuItem(menurap, "Great Golden Grooves", "Great Golden Grooves");
			AddMenuItem(menurap, "Deep Funk", "Deep Funk");
			AddMenuItem(menurap, "Old Skool Rap", "Old Skool Rap");
			AddMenuItem(menurap, "90s Hip-Hop", "90s Hip-Hop");
			AddMenuItem(menurap, "Skatin' Jamz", "Skatin' Jamz");
			AddMenuItem(menurap, "Quiet Storm", "Quiet Storm");
			SetMenuExitButton(menurap, true);
			DisplayMenu(menurap, client, 0);
		}
		if(strcmp(info, "Electro/Dubstep/Trance") == 0)
		{
			new Handle:menudance = CreateMenu(MenuHandler1);
			SetMenuTitle(menudance, "Select A Electro/Dubstep/Trance Station");
			AddMenuItem(menudance, "House Channel Miami", "House Channel Miami");
			AddMenuItem(menudance, "Altered State", "Altered State");
			AddMenuItem(menudance, "Trance", "Trance");
			AddMenuItem(menudance, "Breakbeats", "Breakbeats");
			AddMenuItem(menudance, "90s Dance Hits", "90s Dance Hits");
			AddMenuItem(menudance, "WBMX Hot Mix Dance", "WBMX Hot Mix Dance");
			AddMenuItem(menudance, "Dubstep.FM", "Dubstep.FM");
			AddMenuItem(menudance, "DubstepLive.com", "DubstepLive.com");
			AddMenuItem(menudance, "Bassjunkees.com", "Bassjunkees.com");
			AddMenuItem(menudance, "Studio 54", "Studio 54");
			AddMenuItem(menudance, "AfterHours.FM", "AfterHours.FM");
			AddMenuItem(menudance, "PulsRadio - France", "PulsRadio - France");
			AddMenuItem(menudance, "Mellesleg.FM - Progressive", "Mellesleg.FM - Progressive");
			SetMenuExitButton(menudance, true);
			DisplayMenu(menudance, client, 0);
		}
		if(strcmp(info, "Blues/Jazz") == 0)
		{
			new Handle:menublue = CreateMenu(MenuHandler1);
			SetMenuTitle(menublue, "Select A Blues/Jazz Station");
			AddMenuItem(menublue, "Bar Rockin' Blues", "Bar Rockin' Blues");
			AddMenuItem(menublue, "Classic Blues", "Classic Blues");
			AddMenuItem(menublue, "Smooth Jazz", "Smooth Jazz");
			SetMenuExitButton(menublue, true);
			DisplayMenu(menublue, client, 0);
		}
		if(strcmp(info, "Country/Americana") == 0)
		{
			new Handle:menucountry = CreateMenu(MenuHandler1);
			SetMenuTitle(menucountry, "Select A Country/Americana Station");
			AddMenuItem(menucountry, "Hit Kicker Country", "Hit Kicker Country");
			AddMenuItem(menucountry, "Bar Rockin' Country", "Bar Rockin' Country");
			AddMenuItem(menucountry, "Bluegrass", "Bluegrass");
			AddMenuItem(menucountry, "Cajun Fest", "Cajun Fest");
			AddMenuItem(menucountry, "Classic Country", "Classic Country");
			AddMenuItem(menucountry, "Tears N' Beers Country", "Tears N' Beers Country");
			SetMenuExitButton(menucountry, true);
			DisplayMenu(menucountry, client, 0);
		}
		if(strcmp(info, "Latin/World") == 0)
		{
			new Handle:menulatino = CreateMenu(MenuHandler1);
			SetMenuTitle(menulatino, "Select A Latino/World Station");
			AddMenuItem(menulatino, "Caribbean Breeze", "Caribbean Breeze");
			AddMenuItem(menulatino, "Latino Caliente!", "Latino Caliente!");
			AddMenuItem(menulatino, "Reggaeton", "Reggaeton");
			AddMenuItem(menulatino, "Salsa", "Salsa");
			AddMenuItem(menulatino, "Merengue", "Merengue");
			SetMenuExitButton(menulatino, true);
			DisplayMenu(menulatino, client, 0);
		}
		if(strcmp(info, "Oldies") == 0)
		{
			new Handle:menuold = CreateMenu(MenuHandler1);
			SetMenuTitle(menuold, "Select An Oldies Station");
			AddMenuItem(menuold, "Vegas Baby!", "Vegas Baby!");
			SetMenuExitButton(menuold, true);
			DisplayMenu(menuold, client, 0);
		}
		if(strcmp(info, "ChannelONE") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "ChannelONE", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=6&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Mix 106") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "Mix 106", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=30&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "70s Pop Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "70s Pop Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=34&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "70s Lite Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "70s Lite Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=35&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "80s Pop Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "80s Pop Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=36&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "80s Lite Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "80s Lite Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=37&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "90s Pop Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "90s Pop Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=38&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "90s Rhythmic Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "90s Rhythmic Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=39&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "90s Lite Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Pop radio station.", name);
			}
			ShowMOTDPanel(client, "90s Lite Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=40&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Hard Rock") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Hard Rock", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=12&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Alternative Rock") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Alternative Rock", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=13&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Dark Metal") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Dark Metal", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=72&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Classic Rock") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Classic Rock", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=64&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Hair Voltage") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Hair Voltage", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=65&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Love Bites") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Love Bites", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=67&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Tapestry") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rock radio station.", name);
			}
			ShowMOTDPanel(client, "Tapestry", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=66&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Old Skool Rap") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "Old Skool Rap", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=87&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "V101 R&B") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "V101 R&B", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=20&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Skatin' Jamz") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "Skatin' Jamz", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=89&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Great Golden Grooves") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "Great Golden Grooves", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=85&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Solid Gold Soul") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "Solid Gold Soul", "http://www.sourcetunes.com/players/server_player/play.php?id=default&game=&chan=solidgoldsoul", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Deep Funk") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "Deep Funk", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=86&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "90s Hip-Hop") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "90s Hip-Hop", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=88&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Quiet Storm") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Rap/RnB/Urban radio station.", name);
			}
			ShowMOTDPanel(client, "Quiet Storm", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=90&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "House Channel Miami") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "House Channel Miami", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=43&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Altered State") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "Altered State", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=46&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Trance") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "Trance", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=54&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Breakbeats") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "Breakbeats", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=47&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "90s Dance Hits") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "90s Dance Hits", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=60&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "WBMX Hot Mix Dance") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "WBMX Hot Mix Dance", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=62&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Dubstep.FM") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "Dubstep.FM", "http://www.sourcetunes.com/multiplayer/play.php?page=start&add_station_id=631&title=Play", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "DubstepLive.com") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "DubstepLive.com", "http://www.sourcetunes.com/multiplayer/play.php?page=start&add_station_id=632&title=Play", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Bassjunkees.com") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "Bassjunkees.com", "http://www.sourcetunes.com/multiplayer/play.php?page=start&add_station_id=633&title=Play", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "AfterHours.FM") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "AfterHours.FM", "http://www.sourcetunes.com/multiplayer/play.php?page=start&add_station_id=635&title=Play", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "PulsRadio - France") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "PulsRadio - France", "http://www.sourcetunes.com/multiplayer/play.php?page=start&add_station_id=636&title=Play", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Mellesleg.FM - Progressive") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "Mellesleg.FM - Progressive", "http://www.sourcetunes.com/multiplayer/play.php?page=start&add_station_id=637&title=Play", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "WBMX Hot Mix Dance") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Electro/Dubstep/Trance radio station.", name);
			}
			ShowMOTDPanel(client, "WBMX Hot Mix Dance", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=62&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Bar Rockin' Blues") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Blues/Jazz radio station.", name);
			}
			ShowMOTDPanel(client, "Bar Rockin' Blues", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=16&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Classic Blues") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Blues/Jazz radio station.", name);
			}
			ShowMOTDPanel(client, "Classic Blues", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=17&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Smooth Jazz") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Blues/Jazz radio station.", name);
			}
			ShowMOTDPanel(client, "Smooth Jazz", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=80&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Hit Kicker Country") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Country/Americana radio station.", name);
			}
			ShowMOTDPanel(client, "Hit Kicker Country", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=14&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Bar Rockin' Country") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Country/Americana radio station.", name);
			}
			ShowMOTDPanel(client, "Bar Rockin' Country", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=15&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Bluegrass") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Country/Americana radio station.", name);
			}
			ShowMOTDPanel(client, "Bluegrass", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=73&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Cajun Fest") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Country/Americana radio station.", name);
			}
			ShowMOTDPanel(client, "Cajun Fest", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=74&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Classic Country") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Country/Americana radio station.", name);
			}
			ShowMOTDPanel(client, "Classic Country", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=75&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Tears N' Beers Country") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Country/Americana radio station.", name);
			}
			ShowMOTDPanel(client, "Tears N' Beers Country", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=78&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Caribbean Breeze") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Latin/World radio station.", name);
			}
			ShowMOTDPanel(client, "Caribbean Breeze", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=22&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Latino Caliente!") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Latin/World radio station.", name);
			}
			ShowMOTDPanel(client, "Latino Caliente!", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=23&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Reggaeton") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Latin/World radio station.", name);
			}
			ShowMOTDPanel(client, "Reggaeton", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=92&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Salsa") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Latin/World radio station.", name);
			}
			ShowMOTDPanel(client, "Salsa", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=93&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Merengue") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Latin/World radio station.", name);
			}
			ShowMOTDPanel(client, "Merengue", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=94&title=Player", MOTDPANEL_TYPE_URL);
		}
		if(strcmp(info, "Vegas Baby!") == 0)
		{
			if ((ListenMessage == 1) && !(StrEqual(steamid, "STEAM_0:1:15503124", false)))
			{
				PrintToChatAll("%s has started listening to a Oldies radio station.", name);
			}
			ShowMOTDPanel(client, "Vegas Baby!", "http://www.sourcetunes.com/multiplayer/play.php?page=start&station_id=83&title=Player", MOTDPANEL_TYPE_URL);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (WelcomeMessage == 1)
	{
		PrintToChat(client, "\x03[\x04Samuel L Jackson Radio\x03] \x01This server runs a web radio plugin. \x01Radio stations hosted by \x03Sourcetunes");
		PrintToChat(client, "\x03[\x04Samuel L Jackson Radio\x03] \x01Type \x03!radio \x01in chat or \x03radio \x01in console to listen to your favorite music.");
	}
}

public Action:GameStart(Handle:Event, const String:Name[], bool:Broadcast)
{
	if (RoundMessage == 1)
	{
		PrintToChatAll("\x03[\x04Samuel L Jackson Radio\x03] \x01Type \x03!radio \x01in chat or \x03radio \x01in console to listen to your favorite music.");
	}
}