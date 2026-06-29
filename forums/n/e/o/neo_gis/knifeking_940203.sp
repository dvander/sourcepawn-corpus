/******************************************************************************
 *  KnifeKing.sp  (2009)
 *  
 *  Author: haN
 *  
 *  Version: 1.0    
 *
 *  Description:  The famous knifeking mod, player that kills with a knife gets the 
 *                knifeking title and a reward for it ! . Uses SQLite to store data .
 *
 *  Credits: 
 *           - AlliedModders LLC.
 *           - Lobe (Original author of the knifeking script in ES)
 *
 *  Usage: 
 *           - Type !knifeking to display current knifeking
 *           - Type !knifeme to display your knifeking stats
 *           - Type !knifetop to display the top10 menu of knifeking stats 
 *
 *  Installation:
 *           - Copy knifeking.sp to addons/sourcemod/scripting
 *           - Copy knifeking.smx to addons/sourcemod/plugins
 *           - Go to addons/sourcemod/configs/database.cfg and add:
 *           
 *           	"knifeking"
 *	            {
 *              "driver" "sqlite"
 *              "host" "localhost"
 *              "database" "KnifeKing"
 *              "user" "root"
 *              "pass" ""
 *              }
 *               
 *           - Using RCON Type : "sm plugins load knifeking"
 *
 *
 *
 *
 *******************************************************************************/                        

/////////////////////////////////////////////////////////
///////////////  INCLUDES
/////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

//used for storing Knifeking Client
new g_KnifeKing = 0;
//used for storing How many rounds now player has been knifeking
new g_CurrentRounds = 0;
//used for storing Knifeking Name
new String:g_Kname[64];

//cvar's handles
/////////////////////////////////////////////////////////
///////////////  ESSENTIAL FUNCTIONS
/////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
    name = "KnifeKing",
    author = "haN",
    description = "KnifeKing using SQLite storage",
    version = VERSION,
    url = "www.sourcemod.net"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_knifeking", KnifeKing, "Print to chat current knifeking info");
    RegConsoleCmd("sm_knifeme", KnifeMe, "Print to chat a player's knifeking stats");
    RegConsoleCmd("sm_knifetop", KnifeTop, "display menu containing top10 players on knifeking stats");
    
    HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
    HookEvent("round_start", EventRoundStart, EventHookMode_Post);
    
    
    //Connect to db and create tables if they dont exist
    new Handle:db = Connect();
    CreateSQLite(db);
    CloseHandle(db);
}

public OnMapStart()
{
    g_KnifeKing = 0; //clean Knifeking client index
}

/////////////////////////////////////////////////////////
///////////////  DATABASE CONFIG
/////////////////////////////////////////////////////////

//taken from sql-admin-manager.sp by AlliedModders LLC
Handle:Connect()
{
    	decl String:error[255];
    	new Handle:db;
    	
    	if (SQL_CheckConfig("knifeking"))
    	{
        db = SQL_Connect("knifeking", true, error, sizeof(error));
    	} 
        else
        {
    	    db = SQL_Connect("default", true, error, sizeof(error));
    	}
    	
    	if (db == INVALID_HANDLE)
    	{
    		LogError("Could not connect to database: %s", error);
    	}
    	
    	return db;
}
//taken from sql-admin-manager.sp by AlliedModders LLC
CreateSQLite(Handle:db)
{
    	new String:query[256] = "CREATE TABLE IF NOT EXISTS KnifeKing (steamid varchar(255) NOT NULL, name varchar(255) NOT NULL, rounds INTEGER NOT NULL)";
    	if (!DoQuery(db, query))
    	{
    		return;
    	}	  
        PrintToServer("[KnifeKing] KnifeKing table has been created or already exist.");
}

//taken from sql-admin-manager.sp by AlliedModders LLC
stock bool:DoQuery(Handle:db, const String:query[])
{
	  if (!SQL_FastQuery(db, query))
	  {
		    decl String:error[255];
		    SQL_GetError(db, error, sizeof(error));
		    LogError("Query failed: %s", error);
		    LogError("Query dump: %s", query);
		    LogError("Failed to query database");
		    return false;
	  }

	  return true;
}
//Check if client is in database , if not insert him (triggered in player connection)
bool:PlayerInDataBase(client)
{
    new Handle:db = Connect(); //connect to db
    
    decl String:query[256];
    decl String:steamid[64];
    
    GetClientAuthString(client, steamid, 64); // get client steamid
    Format(query, 256, "SELECT rounds FROM KnifeKing WHERE steamid='%s'", steamid); // format our SQL query
    
    new Handle:hQuery = SQL_Query(db, query);    
    
    if (!SQL_FetchRow(hQuery)) // client isnt in database , insert him
    {
        decl String:name[64];
        GetClientName(client, name, 64);
        Format(query, 256, "INSERT INTO KnifeKing VALUES ('%s', '%s', 0)", steamid, name);
        if (!DoQuery(db, query))
	      {
		        LogError("Failed to query database");
	      }		    
	      
        return false;    
    }
    CloseHandle(hQuery); 
    CloseHandle(db); 
    return true;    
}

//Retrieve how many rounds a player has been knifeking(used in sm_knifeme)
GetKnifeCount(client)
{
    new Handle:db = Connect(); //connect to db
    
    decl String:query[256];
    decl String:steamid[64];
    
    GetClientAuthString(client, steamid, 64); // get client steamid
    Format(query, 256, "SELECT rounds FROM KnifeKing WHERE steamid='%s'", steamid); //format our query
    
    new Handle:hQuery = SQL_Query(db, query);    
    
    if (!SQL_FetchRow(hQuery))
    {
		    LogError("Failed to get knifecount");	      
    }
    new rounds = SQL_FetchInt(hQuery, 0); //get the knifecount
    
    CloseHandle(hQuery); 
    CloseHandle(db); 
    
    return rounds;       
}

//Increment rounds by one for knifeking (used in round_start)
UpdateKnifeCount(client)
{
    new Handle:db = Connect(); //connect to db
    
    decl String:steamid[64];
    decl String:query[256];
    
    GetClientAuthString(client, steamid, 64); //get client steamid
    Format(query, 256, "UPDATE KnifeKing SET rounds=rounds + 1 WHERE steamid='%s'", steamid); // increment rounds by 1
	 
    if (!DoQuery(db, query))
	  {
	      LogError("Failed to query database");
	  }
    CloseHandle(db);     
}

//Update client name in database (triggered in player connection, used for top10)
UpdateClientName(client) 
{
    new Handle:db = Connect(); //connect to db
    
    decl String:steamid[64];
    decl String:name[64];
    decl String:query[256];
    
    GetClientName(client, name, 64);
    GetClientAuthString(client, steamid, 64); //get client steamid
    Format(query, 256, "UPDATE KnifeKing SET name='%s' WHERE steamid='%s'", name, steamid); // increment rounds by 1
	 
    if (!DoQuery(db, query))
	  {
	      LogError("Failed to query database");
	  }
    CloseHandle(db);     
}

/////////////////////////////////////////////////////////
///////////////  CONNETION CHECK
/////////////////////////////////////////////////////////

public OnClientPostAdminCheck(client)
{
    if (!IsFakeClient(client))
    {
        if (!PlayerInDataBase(client)) //Check if player in database
        {
            PrintToServer("[KnifeKing] new player added to database");
        }
        PrintToServer("[KnifeKing] player already in database"); 
        UpdateClientName(client);
    }    
}

public OnClientDisconnect(client)
{
    if (client == g_KnifeKing) //Clean knifeking client's index
    {
        g_KnifeKing = 0;
    }
}

/////////////////////////////////////////////////////////
///////////////  EVENT HOOKING
/////////////////////////////////////////////////////////

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadCast)
{
    decl String:Weapon[64];
    
    GetEventString(event, "weapon", Weapon, 64);
    
        //Get attacker and victim client indexes
    new k_Userid = GetEventInt(event, "attacker");
    new v_Userid = GetEventInt(event, "userid");
    new v_Client = GetClientOfUserId(v_Userid);
    new k_Client = GetClientOfUserId(k_Userid);
    
    if (StrEqual(Weapon, "knife") && !IsFakeClient(k_Client))
    {        
        if (g_KnifeKing != k_Client)  //New Knifeking
        {
            g_KnifeKing = k_Client;  //store knifeking client in the global variable
            g_CurrentRounds = 0;     //Reset Current rounds for knifeking
        }
    
        decl String:k_Name[64];
        decl String:v_Name[64];
        //store knifeking name in the global variable
        GetClientName(k_Client, k_Name, 64);
        GetClientName(v_Client, v_Name, 64);
        strcopy(g_Kname, 64, k_Name);
        //declare knifeking 
        PrintToChatAll("\x04[KnifeKing]\x03 %s \x01was knifed by the NEW KNIFEKING \x03( %s )", v_Name, k_Name);
        
        //give knifeking award
        new k_Money = GetEntProp(k_Client, Prop_Send, "m_iAccount");
        SetEntProp(k_Client, Prop_Send, "m_iAccount", k_Money+1000);
        PrintToChat(k_Client, "\x04[KnifeKing]\x03 You have been rewarded \x01$1000 \x03for being the current KnifeKing!");        
    }
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadCast)
{
    
    if (g_KnifeKing == 0) // NO knifeking yet
    {
        PrintToChatAll("\x04[KnifeKing]\x03 There is no current KnifeKing, knife someone to become the new KnifeKing!");
    }
    else
    {
         //Update rounds for current knifeking
         g_CurrentRounds += 1;  
         UpdateKnifeCount(g_KnifeKing);
         
         //declare knifeking again
         PrintToChatAll("\x04[KnifeKing]\x03 The current KnifeKing is %s at %d round|s|!", g_Kname, g_CurrentRounds);   
    }
}

/////////////////////////////////////////////////////////
///////////////  TOP10 MENU / HANDLERS
/////////////////////////////////////////////////////////

public BlankHandler(Handle:menu, MenuAction:action, param1, param2) 
{
    if (action == MenuAction_End)
	  {
		    CloseHandle(menu);
	  }
}

SendTop10Menu(client)
{
    new Handle:db = Connect(); //Connect to db
    new Handle:menu = CreateMenu(BlankHandler); //Create the menu
    
    SetMenuTitle(menu, "KnifeKing Top 10 Ranks");
    
    decl String:query[256];  
    Format(query, 256, "SELECT * FROM KnifeKing ORDER BY rounds DESC LIMIT 10"); //Format our SQL query
    new Handle:hQuery = SQL_Query(db, query); 
    
    decl String:name[64];
    new rounds;
    
    do //get concerner entries from database and add them to the menu
    {
        rounds = SQL_FetchInt(hQuery, 2);
        SQL_FetchString(hQuery, 1, name, 64);
        decl String:line[192];
        Format(line, 192, "%s   (%d round|s|)", name, rounds);
        AddMenuItem(menu, name, line);        
    }while (SQL_FetchRow(hQuery));
    
    CloseHandle(hQuery);
    DisplayMenu(menu, client, 10); //display menu to client
    CloseHandle(db);
}

/////////////////////////////////////////////////////////
///////////////  ACTION FUNCTIONS
/////////////////////////////////////////////////////////

public Action:KnifeKing(client, args)
{
    if (g_KnifeKing == 0) // NO knifeking
    {
        PrintToChatAll("\x04[KnifeKing]\x03 There is no current KnifeKing, knife someone to become the new KnifeKing!");
        return Plugin_Handled;
    }
    //declare knifeking
    PrintToChatAll("\x04[KnifeKing]\x03 The current KnifeKing is %s at %d round|s|!", g_Kname, g_CurrentRounds);
    
    return Plugin_Handled;
}

public Action:KnifeMe(client, args)
{
    decl String:p_Name[64];
    //Get client's rounds as knifeking and print them
    GetClientName(client, p_Name, 64);
    PrintToChatAll("\x03 %s\x01 has been Knifeking for a total of\x03 %d \x01round|s|.", p_Name, GetKnifeCount(client));
    
    return Plugin_Handled;
}

public Action:KnifeTop(client, args)
{
     SendTop10Menu(client); //Send Top 10 menu to client
     return Plugin_Handled;
}
