#include <sdktools>
#pragma newdecls required

/*-> Database table name to use for connection <-*/
#define DB_Name "mysql_whitelist"
/*###############################################*/

//Variables
Database db = null;
ConVar	CvarAdmFlag;
int		AdmFlag;
char	CPrefix[] = {"\x04[Whitelist] \x01"}; //Chat prefix

//Plugin Info
public Plugin myinfo = 
{
	name = "Simple Mysql Whitelist",
	author = "Xines, johan123jo",
	description = "Mysql database whitelister to control player access to server[s].",
	version = "1.5",
	url = ""
};

public void OnPluginStart()
{
	//INGAME Commands
	RegAdminCmd("sm_whitelist",			Main,			ADMFLAG_ROOT,	"Opens the menu to list/remove");
	RegAdminCmd("sm_whitelist_add",		Command_Add, 	ADMFLAG_ROOT,	"Add a steamid to the database.");
	RegAdminCmd("sm_whitelist_delete",	Command_Delete, ADMFLAG_ROOT,	"Deletes a steamid from the database.");
	RegAdminCmd("sm_whitelist_list",	Command_List, 	ADMFLAG_ROOT,	"List all SteamIDs in the database.");
	
	//Server Commands, Useable by Rcon or Console Whatever.
	RegServerCmd("sm_server_whitelist_add", Server_Command_Add, "Add a steamid to the database. Useable by Rcon or Console");
	RegServerCmd("sm_server_whitelist_delete", Server_Command_Delete, "Deletes a steamid from the database. Useable by Rcon or Console");
	
	//Cvars
	CvarAdmFlag = CreateConVar("sm_whitelist_adminflag", "0", "Admin flag required [a -> z] [0 = OFF].");
	//Hook our cvar
	HookConVarChange(CvarAdmFlag, Cvar_Change);
	
	//DB stuff
	if (SQL_CheckConfig("whitelister")) SQL_TConnect(OnDatabaseConnect, "whitelister");
	else SetFailState("Can't find 'whitelister' entry in sourcemod/configs/databases.cfg!");
}

public void OnDatabaseConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null || strlen(error) > 0)
	{
		PrintToServer("[Mysql-Whitelist] Unable to connect to database (%s)", error);
		LogError("[Mysql-Whitelist] Unable to connect to database (%s)", error);
		return;
	}
	db = view_as<Database>(CloneHandle(hndl)); //Set global DB Handle

	//Create Tables in DB if not exist
	char sBuffer[512];
	FormatEx(sBuffer, sizeof(sBuffer),
	"CREATE TABLE IF NOT EXISTS `%s` (`steamid` text CHARACTER SET utf8 COLLATE utf8_danish_ci);", DB_Name);
	db.Query(SQL_ErrorCheckCallback, sBuffer, _, DBPrio_High);
	
	//Success Print
	PrintToServer("[Mysql-Whitelist] Successfully connected to database!");
}

public void Cvar_Change(Handle cvar, const char[] oldVal, const char[] newVal)
{
	AdmFlag = ReadFlagString(newVal);
}

public Action Main(int client, int args)
{
	ShowMain(client);
	return Plugin_Handled;
}

/* ######## Main menu stuff - Start ######## */
void ShowMain(int client)
{
	if(!IsValidClient(client)) return;

	Menu MainMenu = new Menu(MainMenuHandler);
	MainMenu.SetTitle("Whitelist Menu");
	MainMenu.AddItem("Remove Player", "Remove Player");
	MainMenu.AddItem("List Players", "List Players");
	MainMenu.ExitButton = true;
	MainMenu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu MainMenu, MenuAction action, int client, int itemNum)
{
	if(!IsValidClient(client)) return;

	switch (action) 
	{
		case MenuAction_Select:
		{
			//Commands handling
			char info[64];
			MainMenu.GetItem(itemNum, info, sizeof(info));
			if(strcmp(info, "Remove Player") == 0) ShowPlayerToRemove(client);
			if(strcmp(info, "List Players") == 0) ListPlayers(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				ShowMain(client);
			}
		}
		case MenuAction_End:
		{
			delete MainMenu;
		}
	}
}

void ListPlayers(int client)
{
	if(!IsValidClient(client)) return;
	
	//Make query
	char query[256];
	Format(query, sizeof(query), "SELECT * FROM %s", DB_Name);
	db.Query(SQL_ListSteamids, query, GetClientUserId(client), DBPrio_High);
	
	//Tell client/user we are querying.
	PrintToChat(client, "%sQuery sent! Look in console for the List!", CPrefix);
}

void ShowPlayerToRemove(int client)
{
	if(!IsValidClient(client)) return;

	char id[4], name[MAX_NAME_LENGTH];
	Menu whitelistmenu_remove = new Menu(RemovePlayerHandle);
	whitelistmenu_remove.SetTitle("Select Player to Remove");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			IntToString(GetClientUserId(i), id, sizeof(id));
			GetClientName(i, name, sizeof(name));
			whitelistmenu_remove.AddItem(id, name);
		}
	}
	whitelistmenu_remove.ExitBackButton = true;
	whitelistmenu_remove.ExitButton = true;
	whitelistmenu_remove.Display(client, MENU_TIME_FOREVER);
}
/* ###################### Main menu stuff - End ###################### */

/* ###################### Remove Player Module Start ###################### */
public int RemovePlayerHandle(Menu whitelistmenu_remove, MenuAction action, int client, int param2)
{
	if(!IsValidClient(client)) return;

	switch (action) 
	{
		case MenuAction_Select:
		{			
			char choice[4], charauth[64];
			whitelistmenu_remove.GetItem(param2, choice, sizeof(choice));
			int itarget = GetClientOfUserId(StringToInt(choice)); //Get target id from menu
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsValidClient(i) || i != itarget) continue; //Is client valid and is client our target.

				//Get steam2 ID and store to charauth
				if (!GetClientAuthId(i, AuthId_Steam2, charauth, sizeof(charauth)))
				{
					//Tell client/user gathering steamid went wrong
					PrintToChat(client, "%sCould not gather Steamid, try again!", CPrefix);
					break;
				}
				
				//Pack Infos
				DataPack Pack = new DataPack();
				Pack.WriteCell(GetClientUserId(client));
				Pack.WriteString(charauth);
				
				//Make query
				char query[256];
				Format(query, sizeof(query), "SELECT steamid FROM %s WHERE steamid = '%s'", DB_Name, charauth);
				db.Query(SQL_DeleteSteamid_Check, query, Pack, DBPrio_High);
				
				//Tell client/user we are querying.
				PrintToChat(client, "%sQuery sent please wait!", CPrefix);
				
				//Magic query done, now goto menu
				ShowPlayerToRemove(client);
				
				//we're done
				break;
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowMain(client);
			}
		}
		case MenuAction_End:
		{
			delete whitelistmenu_remove;
		}
	}
}
/* ###################### Remove Player Module End ###################### */

/* ######## Lots of SQL stuff below ######## */

//Check Player Access First Check!
public void OnClientAuthorized(int client, const char[] SteamID)
{
	if (IsFakeClient(client)) return; //Allow bots to skip this check.
	AdminId Admin = FindAdminByIdentity(AUTHMETHOD_STEAM, SteamID);
	if (AdmFlag != 0 && GetAdminFlags(Admin, Access_Effective) & AdmFlag) return;

	//Start Checking
	//Send a check query to the database to see if the user is in the database.
	char query[256];
	Format(query, sizeof(query), "SELECT steamid FROM %s WHERE steamid = '%s'", DB_Name, SteamID);
	db.Query(SQL_CheckSteamID, query, GetClientUserId(client), DBPrio_High);
}

//Double Check our client, just incase person randomly somehow bypassed OnClientAuthorized check.
public void OnClientPostAdminCheck(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client)) return;
	
	//Do Same check as in OnClientAuthorized, just different method.
	char isteamid[64];
	if(GetClientAuthId(client, AuthId_Steam2, isteamid, sizeof(isteamid)))
	{
		if(AdmFlag != 0 && CheckAdmFlag(client)) return; //If Admin with Adm flag, Skip check.

		//Start Checking
		//Send a check query to the database to see if the user is in the database.
		char query[256];
		Format(query, sizeof(query), "SELECT steamid FROM %s WHERE steamid = '%s'", DB_Name, isteamid);
		db.Query(SQL_CheckSteamID, query, GetClientUserId(client), DBPrio_High);
	}
	else KickClient(client, "Please retry connecting!"); //Tell clients to retry.
}

//Checks if the SteamID is in the database, if not the player will get kicked.
public void SQL_CheckSteamID(Handle owner, DBResultSet results, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid); 
	if (client == 0 || !IsClientConnected(client)) return; //connected check if not found do return
	if (results == null || strlen(error) > 0)
	{
		LogError("[Mysql-Whitelist] Query failed! %s", error);
		KickClient(client, "Authorization failed, please try again later.");
	}
	else if(results.RowCount == 0)
	{
		KickClient(client, "You are not allowed to join this server");
	}
}

//Command to list all the SteamIDs in the database, and other stuff the command needs for it to work.
public Action Command_List(int client, int args)
{
	if (IsValidClient(client))
	{
		char query[256];
		Format(query, sizeof(query), "SELECT * FROM %s", DB_Name);
		db.Query(SQL_ListSteamids, query, GetClientUserId(client), DBPrio_High);
	}
	return Plugin_Handled;
}

//Used by Command_List to query database for info.
public void SQL_ListSteamids(Handle owner, DBResultSet results, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return; //Stop if not valid!
	if (results == null || strlen(error) > 0)
	{
		LogError("[Mysql-Whitelist] Query failed! %s", error);
		PrintToChat(client, "%sQuery failed, please try again later.", CPrefix);
		return;
	}

	//Everything is fine let's start
	PrintToConsole(client, "########## SteamIDs in database ##########");
	char steamid_f[256];
	while(results.FetchRow()) //Fetch all rows
	{
		results.FetchString(0, steamid_f, sizeof(steamid_f));
		PrintToConsole(client, "%s", steamid_f);
	}
	PrintToConsole(client, "##########################################");
}

//Command to add a SteamID into the database.
public Action Command_Add(int client, int args)
{
	//Check if client is valid, do nothing if not!
	if (!IsValidClient(client)) return Plugin_Handled;

	if(args < 1)
	{
		ReplyToCommand(client, "Usage: sm_whitelist_add <steamid>");
		return Plugin_Handled;
	}
	
	//Quick check to make sure format is steam2 id
	char fsteam[64];
	GetCmdArgString(fsteam, sizeof(fsteam));
	if (StrContains(fsteam, "STEAM_0", false) == -1 && StrContains(fsteam, "STEAM_1", false) == -1)
	{
		ReplyToCommand(client, "%sInvalid SteamID Use Format: STEAM_1 or STEAM_0", CPrefix);
		return Plugin_Handled;
	}
	
	//Pack Infos
	DataPack Pack = new DataPack();
	Pack.WriteCell(GetClientUserId(client));
	Pack.WriteString(fsteam);
	
	//Make Query
	char query[256];
	Format(query, sizeof(query), "SELECT steamid FROM %s WHERE steamid = '%s'", DB_Name, fsteam);
	db.Query(SQL_AddSteamid_Check, query, Pack, DBPrio_High);
	
	//Tell client/user we are querying.
	PrintToChat(client, "%sQuery sent please wait!", CPrefix);
	
	return Plugin_Handled;
}

//Checks if SteamID is already in the database.
public void SQL_AddSteamid_Check(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char fsteam[64]; //SteamId
	data.ReadString(fsteam, 64);

	if (IsValidClient(client))
	{
		if (results == null || strlen(error) > 0)
		{
			LogError("[Mysql-Whitelist] Query failed! %s", error);
			PrintToChat(client, "%sQuery failed, please try again later.", CPrefix);
		}
		else if (results.RowCount == 0)
		{
			//Pack Infos again
			DataPack iPack = new DataPack();
			iPack.WriteCell(GetClientUserId(client));
			iPack.WriteString(fsteam);
			
			char query[256];
			Format(query, sizeof(query), "INSERT INTO %s (steamid) VALUES ('%s')", DB_Name, fsteam);
			db.Query(SQL_AddSteamid_Add, query, iPack, DBPrio_High);
		}
		else PrintToChat(client, "%sThe SteamID: %s is already in the database.", CPrefix, fsteam);
	}
	delete view_as<DataPack>(data);
}

//If SQL_AddSteamid_Check did not find a SteamID in the database it will add it to the database.
public void SQL_AddSteamid_Add(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char steamid[64]; //SteamId
	data.ReadString(steamid, 64);

	if (IsValidClient(client))
	{
		if (results == null || strlen(error) > 0)
		{
			LogError("[Mysql-Whitelist] Query failed! %s", error);
			PrintToChat(client, "%sQuery failed, please try again later. (See Logs)", CPrefix);
		}
		else PrintToChat(client, "%sThe SteamID: %s have been added to the database.", CPrefix, steamid);
	}
	delete view_as<DataPack>(data);
}

//Command to add a SteamID into the database. ServerCmd/Rcon
public Action Server_Command_Add(int args)
{
	if (args < 1)
	{
		PrintToServer("Usage: sm_server_whitelist_add <steamid>");
		return Plugin_Handled;
	}
	else
	{
		char fsteam[64];
		GetCmdArgString(fsteam, sizeof(fsteam));
		if (StrContains(fsteam, "STEAM_0", false) == -1 && StrContains(fsteam, "STEAM_1", false) == -1)
		{
			PrintToServer("%sInvalid SteamID Use Format: STEAM_1 or STEAM_0", CPrefix);
			return Plugin_Handled;
		}
		
		//Remove stupid spaces
		ReplaceString(fsteam, 64, " ", "");

		//Pack Infos - We have to use Datapacks to pass arrays/string in querys...
		DataPack Pack = new DataPack();
		Pack.WriteString(fsteam);
		
		//Make Query
		char query[256];
		Format(query, sizeof(query), "SELECT steamid FROM %s WHERE steamid = '%s'", DB_Name, fsteam);
		db.Query(SQL_Server_AddSteamid_Check, query, Pack, DBPrio_Normal);
		
		//Tell we are querying.
		PrintToServer("%sQuery sent please wait!", CPrefix);
	}
	return Plugin_Handled;
}

//Checks if SteamID is already in the database. ServerCmd/Rcon
public void SQL_Server_AddSteamid_Check(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	char steamid[64]; //SteamId
	data.ReadString(steamid, 64);
	
	if (results == null || strlen(error) > 0)
	{
		LogError("[Mysql-Whitelist] Query failed! %s", error);
		PrintToServer("%sQuery failed, please try again later.", CPrefix);
	}
	else if (results.RowCount == 0)
	{
		//Pack Infos - We have to use Datapacks to pass arrays/string in querys...
		DataPack iPack = new DataPack();
		iPack.WriteString(steamid);
	
		char query[256];
		Format(query, sizeof(query), "INSERT INTO %s (steamid) VALUES ('%s')", DB_Name, steamid);
		db.Query(SQL_Server_AddSteamid_Add, query, iPack, DBPrio_Normal);
	}
	else PrintToServer("%sThe SteamID: %s is already in the database.", CPrefix, steamid);
	
	delete view_as<DataPack>(data);
}

//If SQL_Server_AddSteamid_Add did not find a SteamID in the database it will add it to the database.
public void SQL_Server_AddSteamid_Add(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	char steamid[64]; //SteamId
	data.ReadString(steamid, 64);
	
	if (results == null || strlen(error) > 0)
	{
		LogError("[Mysql-Whitelist] Query failed! %s", error);
		PrintToServer("%sQuery failed, please try again later. (See Logs)", CPrefix);
	}
	else PrintToServer("%sThe SteamID: %s have been added to the database.", CPrefix, steamid);
	
	delete view_as<DataPack>(data);
}

//Command to delete a SteamID from the database.
public Action Command_Delete(int client, int args)
{
	//Check if client is valid, do nothing if not!
	if (!IsValidClient(client)) return Plugin_Handled;

	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_whitelist_delete <steamid>");
		return Plugin_Handled;
	}
	
	//Quick check to make sure format is steam2 id
	char fsteam[64]
	GetCmdArgString(fsteam, sizeof(fsteam));
	if (StrContains(fsteam, "STEAM_0", false) == -1 && StrContains(fsteam, "STEAM_1", false) == -1)
	{
		ReplyToCommand(client, "%sInvalid SteamID Use Format: STEAM_1 or STEAM_0", CPrefix);
		return Plugin_Handled;
	}
	
	//Pack Infos
	DataPack Pack = new DataPack();
	Pack.WriteCell(GetClientUserId(client));
	Pack.WriteString(fsteam);
	
	//Make Query
	char query[256];
	Format(query, sizeof(query), "SELECT steamid FROM %s WHERE steamid = '%s'", DB_Name, fsteam);
	db.Query(SQL_DeleteSteamid_Check, query, Pack, DBPrio_High);
	
	//Tell client/user we are querying.
	PrintToChat(client, "%sQuery sent please wait!", CPrefix);
	
	return Plugin_Handled;
}

//Querys the database to see if a SteamID exists, if it exists in the database it will delete the SteamID from the database.
public void SQL_DeleteSteamid_Check(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char fsteam[64]; //SteamId
	data.ReadString(fsteam, 64);

	if (IsValidClient(client))
	{
		if (results == null || strlen(error) > 0)
		{
			LogError("[Mysql-Whitelist] Query failed! %s", error);
			PrintToChat(client, "%sQuery failed, please try again later.", CPrefix);
		}
		else if (results.RowCount)
		{
			//Pack Infos again
			DataPack iPack = new DataPack();
			iPack.WriteCell(GetClientUserId(client));
			iPack.WriteString(fsteam);
			
			//Make Query
			char query[256];
			Format(query, sizeof(query), "DELETE FROM %s WHERE steamid = '%s'", DB_Name, fsteam);
			db.Query(SQL_DeleteSteamid_Delete, query, iPack, DBPrio_High);
		}
		else PrintToChat(client, "%sThe SteamID: %s is not in the database.", CPrefix, fsteam);
	}
	delete view_as<DataPack>(data);
}

//Deletes the SteamID from the database, and kicks the client if active on the server.
public void SQL_DeleteSteamid_Delete(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char fsteam[64]; //SteamId
	data.ReadString(fsteam, 64);

	if (IsValidClient(client))
	{
		if (results == null || strlen(error) > 0)
		{
			LogError("[Mysql-Whitelist] Query failed! %s", error);
			PrintToChat(client, "%sQuery failed, please try again later.", CPrefix);
			delete view_as<DataPack>(data); //Delete Datapack due to null or error
			return;
		}

		//Everything is fine let's start
		KickMatchingSteamid(fsteam); //Kick if found!		
		PrintToChat(client, "%sThe SteamID: %s have been deleted from the database.", CPrefix, fsteam);
	}
	delete view_as<DataPack>(data); //Delete Datapack we are done
}

public Action Server_Command_Delete(int args)
{
	if (args < 1)
	{
		PrintToServer("Usage: sm_server_whitelist_delete <steamid>");
		return Plugin_Handled;
	}
	else
	{
		char fsteam[64];
		GetCmdArgString(fsteam, sizeof(fsteam));
		if (StrContains(fsteam, "STEAM_0", false) == -1 && StrContains(fsteam, "STEAM_1", false) == -1)
		{
			PrintToServer("%sInvalid SteamID Use Format: STEAM_1 or STEAM_0", CPrefix);
			return Plugin_Handled;
		}
		
		//Remove stupid spaces
		ReplaceString(fsteam, 64, " ", "");

		//Pack Infos - We have to use Datapacks to pass arrays/string in querys...
		DataPack Pack = new DataPack();
		Pack.WriteString(fsteam);
		
		//Make Query
		char query[256];
		Format(query, sizeof(query), "SELECT steamid FROM %s WHERE steamid = '%s'", DB_Name, fsteam);
		db.Query(SQL_Server_DeleteSteamid_Check, query, Pack, DBPrio_Normal);	
		
		//Tell we are querying.
		PrintToServer("%sQuery sent please wait!", CPrefix);
	}
	return Plugin_Handled;
}

//Querys the database to see if a SteamID exists, if it exists in the database it will delete the SteamID from the database.
public void SQL_Server_DeleteSteamid_Check(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	char fsteam[64]; //SteamId
	data.ReadString(fsteam, 64);

	if (results == null || strlen(error) > 0)
	{
		LogError("[Mysql-Whitelist] Query failed! %s", error);
		PrintToServer("%sQuery failed, please try again later.", CPrefix);
	}
	else if (results.RowCount)
	{
		//Pack Infos again
		DataPack iPack = new DataPack();
		iPack.WriteString(fsteam);
		
		//Make Query
		char query[256];
		Format(query, sizeof(query), "DELETE FROM %s WHERE steamid = '%s'", DB_Name, fsteam);
		db.Query(SQL_Server_DeleteSteamid_Delete, query, iPack, DBPrio_High);
	}
	else PrintToServer("%sThe SteamID: %s is not in the database.", CPrefix, fsteam);
	
	delete view_as<DataPack>(data);
}

//Deletes the SteamID from the database, and kicks the client if active on the server.
public void SQL_Server_DeleteSteamid_Delete(Handle owner, DBResultSet results, const char[] error, DataPack data)
{
	//Unpack our Infos
	data.Reset();
	char fsteam[64]; //SteamId
	data.ReadString(fsteam, 64);

	if (results == null || strlen(error) > 0)
	{
		LogError("[Mysql-Whitelist] Query failed! %s", error);
		PrintToServer("%sQuery failed, please try again later.", CPrefix);
		delete view_as<DataPack>(data); //Delete Datapack due to null or error
		return;
	}

	//Everything is fine let's start
	KickMatchingSteamid(fsteam); //Kick if found!
	PrintToServer("%sThe SteamID: %s have been deleted from the database.", CPrefix, fsteam);
	
	delete view_as<DataPack>(data); //Delete Datapack we are done
}

//Used to kick people off server, if steamid is removed from database!
void KickMatchingSteamid(char[] fsteam)
{
	char iauth[64];
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		
		if (!GetClientAuthId(i, AuthId_Steam2, iauth, sizeof(iauth))) continue;
		
		if (StrEqual(iauth, fsteam))
		{
			KickClient(i, "You are not allowed to be on this server");
			break;
		}
	}
}

//Function to check for errors before doing query
public void SQL_ErrorCheckCallback(Handle owner, DBResultSet results, const char[] error, any data)
{
	if (results == null || strlen(error) > 0)
	{
		LogError("[Mysql-Whitelist] Query failed! %s", error);
	}
}

/** Stocks **/
stock bool CheckAdmFlag(int client)
{
	AdminId admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID) return false;

	//Do check
	int count, found;
	for (int i = 0; i <= 20; i++)
	{
		if (AdmFlag & (1<<i))
		{
			count++;
			if (GetAdminFlag(admin, view_as<AdminFlag>(i))) found++;
		}
	}

	if (count == found) return true;
	else return false;
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}