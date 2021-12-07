/*
	Simple Plugin to tell a user where another user is connected from
	usage:
		sm_location <name|#userid> -- Gets a single player's locaton
		sm_locations -- Gets everyones' location
		
	By: The-/<iller
	www.RightToRule.com
	aim/xfire:rtrkiller
	
	Changelog:
	0.1 > First Version
	0.2 > Update for new GeoIP functions, NEED >r1300
	0.3 > Fixed running cmds through rcon, added respond with server ip for bots
	0.4 > added connect annouce and prevent it from crashing server when a player 
		disconnects while entering (NOT RELEASED)
	0.5 > Menus added	
	
	Things to come:
	Make Suggestions
*/


#include <sourcemod>
#include <geoip>

new maxplayers
new String:NetIP[32];
new Handle:g_hLocationAnnounce
new Handle:g_LocationInMenu
#define PLUGIN_VERSION "0.5"

public Plugin:myinfo =
{
	name = "Get Location",
	author = "The-Killer",
	description = "Retrives geoip locations and displays to console",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	maxplayers = GetMaxClients()
	RegConsoleCmd("sm_location", Command_Location)
	RegConsoleCmd("sm_locations", Command_Locations)
	CreateConVar("sm_getlocation_version", PLUGIN_VERSION, "Get Location Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_hLocationAnnounce = CreateConVar("sm_getlocation_announce","1","Announce player locations on connect", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0)
	g_LocationInMenu = CreateConVar("sm_getlocation_inmenu","1", "Display Locations in 1)menu[Default] or 0)console", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0)

	//Get Server ip for bots location
	
	new pieces[4];
	new longip = GetConVarInt(FindConVar("hostip"));
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;

	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
}

public Action:Command_Location(client, args)
{
	//Check for empty command and provide usage if needed
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_location <name|#userid>");
		return Plugin_Handled;	
	}
	
	//Get our target
	new String:Player[64]
	GetCmdArg(1, Player, sizeof(Player))
	
	//Search for clients
	new foundClients[2];
	new NumClients = SearchForClients(Player, foundClients, 2);
	
	//Check for client availibility
	if (NumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (NumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Player);
		return Plugin_Handled;
	}
	//Declare GeoIP/Return data
	new String:ip[32]
	new String:country[50]
	new String:name[32]
	new String:authid[35]
	
	GetClientAuthString(foundClients[0],authid,34)
	if(StrEqual(authid,"BOT",false))
	{
		GetClientName(foundClients[0], name,31)
		GeoipCountry(NetIP, country,45)
	}
	else
	{ 
		//Get Return/GeoIP Data
		GetClientIP(foundClients[0], ip, 19)
		GetClientName(foundClients[0], name,31)
		GeoipCountry(ip, country,45)
	}
	
	//Tell them where the target client is connected from
	if(client==0) PrintToServer("%s is connected from %s", name,country)
	else PrintToChat(client,"%s is connected from %s", name,country)
	
	//Return normally
	return Plugin_Handled;	
}

public Action:Command_Locations(client, args)
{
	//Declare GeoIP/Return data
	new String:ip[32]
	new String:country[50]
	new String:name[32]
	new String:authid[35]
	
	if(!GetConVarBool(g_LocationInMenu)|| client==0)
	{
		if(client==0) 
		{
			PrintToServer("Player locations list:")
		}
		else
		{
			//Tell them the requested info is in console
			PrintToChat(client,"Read Console for Info")
			
			PrintToConsole(client," ")
			PrintToConsole(client,"Player locations list:")
		}
		//Loop through all players and print out a list to the client
		for (new i=1; i<=maxplayers; i++)
			{
				//Check for client connected
				if (!IsClientInGame(i))
					continue
				
				GetClientAuthString(i,authid,34)
				if(StrEqual(authid,"BOT",false))
				{
					//Get Server location
					GetClientName(i, name,31)
					GeoipCountry(NetIP, country,45)
				}
				else
				{ 
					//Get Return/GeoIP Data
					GetClientIP(i, ip, 19)
					GetClientName(i, name,31)
					GeoipCountry(ip, country,45)
				}
				
				//Tell them where the target client is connected from
				if(client==0) PrintToServer("%s is connected from %s", name,country)
				else PrintToConsole(client,"%s is connected from %s", name,country)
			}
	} else {
		//Declare Menu Junk
		new Handle:menu = CreateMenu(LocationsMenuHandler)
		new String:StrLoc[64];
		new String:place[10];
		
		SetMenuTitle(menu, "Player Locations List")
		//Loop through all players and print out a list to the client
		for (new i=1; i<=maxplayers; i++)
			{
				//Check for client connected
				if (!IsClientInGame(i))
					continue
				
				GetClientAuthString(i,authid,34)
				if(StrEqual(authid,"BOT",false))
				{
					//Get Server location
					GetClientName(i, name,31)
					GeoipCountry(NetIP, country,45)
				}
				else
				{ 
					//Get Return/GeoIP Data
					GetClientIP(i, ip, 19)
					GetClientName(i, name,31)
					GeoipCountry(ip, country,45)
				}
				
				//Tell them where the target client is connected from
				Format(StrLoc,sizeof(StrLoc),"%s       %s", name,country);
				IntToString(i,place,sizeof(place))
				AddMenuItem(menu,place,StrLoc)
			}
		SetMenuExitButton(menu, true)
		DisplayMenu(menu, client, 20)
	}
	
	//Return normally
	return Plugin_Handled;	
}

public LocationsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{ 
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
 


//Code originally from pRED's sm_super_cmds http://forums.alliedmods.net/showthread.php?t=57448
public OnClientPutInServer(client)
{
	if (GetConVarInt(g_hLocationAnnounce)==0) return 
	
	new String:ip[32]
	new String:country[46]
	new String:name[32]
	new String:authid[35]
	
	//Check to see if client in game, will crash the server is player disconnects right before they enter the server
	if (!IsClientInGame(client)) 	return
	
	GetClientAuthString(client,authid,34)
	GetClientIP(client, ip, 19)
	GetClientName(client, name,31)
	GeoipCountry(ip, country, 45)
	
	PrintToChatAll("\x01\x04%s (\x01%s\x04) connected from %s",name,authid,country)
}