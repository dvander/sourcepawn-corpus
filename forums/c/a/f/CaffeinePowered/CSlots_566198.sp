/*------------------------------------------------------------------------------
Community Reserved Slots
By: CaffeinePowered

Special Thanks to FlyingMongoose and KMFrog for assisting in debugging and writing

This plugin is designed for large web communities that have many members that
want to be able to use the server without bugging an admin to boot someone.

The plugin will keep one slot of the server open, for each player that joins their
SteamID will be checked against a list of authorized community member's IDs, if
they are a member, they are marked in an array.

When the server fills if a non-community member attempts to fill the last slot it
will kick them, if a community member joins it will kick the player that is not a
member with the lowest connection time.

------------------------------------------------------------------------------*/

//------------------------------------------------------------------------------
#include <sourcemod>

#pragma semicolon 1
public Plugin:myinfo =
{
	name = "Community Reserved Slots",
	author = "CaffeinePowered",
	description = "Reserved slot plugin for large web communities",
	version = "1.0.1.2",
	url = "http://www.destructoid.com/blogs/caffeinepowered/"
}
//------------------------------------------------------------------------------

//Global Vars
//------------------------------------------------------------------------------
new bool:authed[MAXPLAYERS+1];
new const String:kick_message[] = "Sorry, you are being kicked for using a reserved slot";
new clientSlot = 0;
new finalClient = 0;
new Handle:IDList;
//------------------------------------------------------------------------------

//OnPluginStart (Use: called when the plugin is loaded)
//------------------------------------------------------------------------------
public OnPluginStart()
{
	//Debug message
	LogToGame("Reserved Slots: Community Slots is Running");

	//We load all of the steamIDs from file
	LoadAllIDs();
	CheckAllIDs();
	
}
//------------------------------------------------------------------------------

//OnMapStart (Use: Called when a map loads)
//------------------------------------------------------------------------------
public OnMapStart()
{
	//Debug message
	LogToGame("Reserved Slots: Community Slots is Running");
	ClearIDs();
	LoadAllIDs();
}
//------------------------------------------------------------------------------

//OnClientPostAdminCheck (Use: called after SM has admin-authed the steamID)
//------------------------------------------------------------------------------
public OnClientPostAdminCheck(client)
{
	//Debug message
	//LogToGame("Reserved Slots: Checking client: %d" ,client);

	//Get client steamID
	decl String:SteamID[65];
	GetClientAuthString(client, SteamID, 64);

	
	//A bool to show if the client has a reserved slot
	decl bool:reserved_client;
	reserved_client = false;

	if(-1 != FindStringInArray(IDList, SteamID))
	{
		reserved_client = true;
	}

	//check if all slots are filled
	if((GetClientCount(true)) == GetMaxClients())
	{
		//If the server is full
		//LogToGame("Reserved Slots: Final Player Connected");
		
		//Kicks a public player if a player is authorized, or 
		//kicks that player if they are not
		if (reserved_client)
		{
				//Set their authed status
				authed[client] = true;
				//Kick a client to make room
				//LogToGame("Reserved Slots: kicking client with lowest con time");
				CSlots_KickToFreeSlot(client);
				return;
		} 
		else
		{
				//Kick the player as they do not have a slot
				//LogToGame("Reserved Slots: Kicking client for not having a res slot");
				finalClient = client;
				CreateTimer(0.1, TimedKick, client);
				return;
		}
			
	} 
	else 
	{
		//The server is not full
		//LogToGame("Reserved Slots: Non-Final Player Connected");
		
		//Sets value based on whether or not the client is authed
		if (reserved_client)
		{
			LogToGame("Reserved Slots: setting player %d to authed", client);
			//Set their authed status
			authed[client] = true;
			return;
		} 
		else
		{
			LogToGame("Reserved Slots: Setting player %d to non-authed", client);
			//Set their authed status
			authed[client] = false;
			return;
		}
	}
}
//------------------------------------------------------------------------------


//CSlots_KickToFreeSlot (Use: Kicks player by shortest connection time)
//------------------------------------------------------------------------------
CSlots_KickToFreeSlot(original_client)
{
	//LogToGame("Final Client Number: %d", original_client);

	//Find the max clients to setup the loop
	decl maxclients;
	maxclients = GetMaxClients();

	//create a temp clients
	decl client;
	decl lowestTime_client;
	lowestTime_client = 0;
	client = 0;
	decl bool:is_authed;
	
	//connection time storage
	decl Float:lowest_con_time;
	decl Float:client_con_time;
	
	for (new i = 1; i <= maxclients; i++)
	{
	    //set the temp client
		client = i;
	
		is_authed = authed[client];
		
		//Kick bots before real people
		if (IsFakeClient(client))
		{
			LogToGame("Reserved Slots: Bot found - Kicking (%d)", client);
			KickClient(client);
			break;
		}


		//check if the client is valid & not authed
		if (IsClientConnected(client) && (is_authed == false))
		{
			//debuggeh
			//LogToGame("Reserved Slots: Checking un-authed client con time (%d)", client);
		    
			//setup a last-client so the maths works
			if (lowestTime_client == 0)
			{
				lowestTime_client = client;
			}
			
			//Find the con times (this seams to fail with bots!)
			lowest_con_time = GetClientTime(lowestTime_client);
			client_con_time = GetClientTime(client);
            
			//LogToGame("Reserved Slots: lowest con time is %d - client's time is %d", lowest_con_time, client_con_time);
			
			//Check the times to see if this client is lower
			if(client_con_time <= lowest_con_time)
			{
			    	//Debug message
				//LogToGame("Reserved Slots: Found Player with less time (%d)", client);
				lowestTime_client = client;
			}
		}
	}
	
	//If the lowestTime_client is still 0 by now, ALL players must be authed
	//This means we either kick the original client
	if (lowestTime_client == 0)
	{
		//kicking the original client
		LogToGame("Reserved Slots: kicking original player - %d", original_client);
		finalClient = original_client;
		CreateTimer(0.1, TimedKick, original_client);
	} 
	else 
	{
		//There is at least 1 non-authed player, so lets kick them
		LogToGame("Reserved Slots: kicking player with lowest con time - %d", lowestTime_client);
		finalClient = lowestTime_client;
		CreateTimer(0.1, TimedKick, lowestTime_client);
	}
}
//------------------------------------------------------------------------------


//TimerBased Kick Function - Kicks a player after a 0.1sec timer
//------------------------------------------------------------------------------
public Action:TimedKick(Handle:Timer, any:value)
{
	//LogToGame("Testing Global - Client To Kick is %d", finalClient);
	//LogToGame("Testing Global - Client Passed is %d", value);
	if(IsClientValid(value))
	{
		
		clientSlot = value;
		//LogToGame("Client is Valid - now kicking %d", clientSlot);

		if(!clientSlot || !IsClientInGame(clientSlot))
		{
			LogToGame("Oops - unable to kick - not in game or world - %d", clientSlot);
			return Plugin_Handled;
		}
		
		KickClient(clientSlot, kick_message);
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Handled;
	}

}

//Checks if the cilent is legitimate for kicking
//-------------------------------------------------------------------------------
bool:IsClientValid(client)
{
	if(client != 0 && (IsClientConnected(client) && IsClientInGame(client)))
	{
		return true;
	}
	else
	{
		return false;
	}
}
//-------------------------------------------------------------------------------

//Loads All SteamIDs into a 2D Array
//-------------------------------------------------------------------------------
public Action:LoadAllIDs()
{
	LogToGame("Loading All IDs");
	IDList = CreateArray(ByteCountToCells(65));
	new Handle:file_Reservedlist = OpenFile("addons/sourcemod/configs/cReservedList.ini","rt");
 
	decl String:file_steamid[65];
	decl String:file_steamid_trimmed[65];
	decl len;
 
	while(!IsEndOfFile(file_Reservedlist))
	{
		//Read the line
		ReadFileLine(file_Reservedlist, file_steamid, sizeof(file_steamid));
		if((file_steamid[0] != '/') && (file_steamid[1] != '/'))
		{
			//Get the line length
			len = strlen(file_steamid);
			//Trim the line
			strcopy(file_steamid_trimmed,(len-1), file_steamid);
			PushArrayString(IDList,file_steamid_trimmed);
		}
	}
 
	//Close the handle
	CloseHandle(file_Reservedlist);
}
//-------------------------------------------------------------------------------

//Checks the ID of all players in the server
//-------------------------------------------------------------------------------
public Action:CheckAllIDs()
{
	LogToGame("Reserved Slots: Checking All IDs");
	//If server is empty - we do nothing
	if(GetClientCount(true) == 0)
	{
		LogToGame("Reserved Slots: Server Empty");
		return;
	}
	
	decl String:PlayerSteamID[65];
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientValid(i) == true)
		{
			GetClientAuthString(i, PlayerSteamID, 64);
	
			if(-1 != FindStringInArray(IDList, PlayerSteamID))
			{
				LogToGame("Reserved Slots: CheckAllIDs - Authed Client %d",i);
				authed[i] = true;
			}
			else
			{
				LogToGame("Reserved Slots: CheckAllIDs - UnAuthed Client %d",i);
				authed[i] = false;
			}
		}
	}
}
//-------------------------------------------------------------------------------

//Clears the ID list so that it may be reloaded
//-------------------------------------------------------------------------------
public Action:ClearIDs()
{
	LogToGame("Clearing ID List");
	ClearArray(IDList);
}
//-------------------------------------------------------------------------------