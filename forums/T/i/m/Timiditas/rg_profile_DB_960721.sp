#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.13"

new Handle:db = INVALID_HANDLE;
new Handle:cv_db = INVALID_HANDLE;

public Plugin:myinfo ={
    name = "RG Profile DB",
    author = "Theowningone/Timiditas/R-Hehl",
    description = "RG Profile DB",
    version = PLUGIN_VERSION,
    url = "http://www.theowningone.info/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("rg_profile_ver",PLUGIN_VERSION,"RG Profile DB Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_profile",id,"Takes a steam id, converts it to a steam community link and sends you to it!");
	cv_db = CreateConVar("rg_profile_db_section","default","database section name in databases.cfg");
	AutoExecConfig(true, "rg_profile_db");
}

public OnConfigsExecuted()
{
	if(db == INVALID_HANDLE)
	{
		new String:Section[255];
		GetConVarString(cv_db, Section, sizeof(Section));
		if (SQL_CheckConfig(Section))
		{
			SQL_TConnect(T_Connect, Section);
		}
		else
			SetFailState("db section name not found in databases.cfg");
	}
}

public T_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new String:Section[255];
	GetConVarString(cv_db, Section, sizeof(Section));
	if (hndl == INVALID_HANDLE)
		SetFailState("Failed to connect to '%s': %s", Section, error);
	else 
	{
		db = hndl;
		PrintToServer("[rg_profile_db]DatabaseInit (CONNECTED) with db config '%s'", Section);
	}
}

public Action:id(client,args){
	if(args==0 && client==0){
		ReplyToCommand(client,"Proper Usage: !profile<steamid, userid, playername>");
		ReplyToCommand(client,"Proper Usage: sm_profile <steamid, userid, playername>");
		return Plugin_Handled;
	}
	else if(args == 0 && client != 0)
	{
		ProfileMenu(client);
		ReplyToCommand(client, "Profile menu opened");
		return Plugin_Handled;
	}
	decl String:arg[128],String:ID[256];
	GetCmdArgString(arg,128);
	new String:Test[7];
	strcopy(Test,sizeof(Test),arg);
	if (!StrEqual("STEAM_", Test, false))
	{
		new Targ=FindTarget(client,arg,true,false);
		if(Targ<=0)
			return Plugin_Handled;
		else
			GetClientAuthString(Targ,ID,256);
	}
	else
		strcopy(ID,sizeof(ID),arg);
	
	new String:buffer[1024];
	Format(buffer, sizeof(buffer), "SELECT CAST(MID('%s', 9, 1) AS UNSIGNED) + CAST('76561197960265728' AS UNSIGNED) + CAST(MID('%s', 11, 10) * 2 AS UNSIGNED) AS friend_id", ID, ID);
	new UserID;
	if (client == 0)
		UserID = -1;
	else
		UserID = GetClientUserId(client);
	SQL_TQuery(db, AuthIDToFriendID, buffer, UserID);
	return Plugin_Handled;
}
public AuthIDToFriendID(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	/* Make sure the client didn't disconnect while the thread was running if it wasn't fired by server console */
	new client;
	if (data == -1)
		client = 0;
	else
	{
		client = GetClientOfUserId(data);
		if (client == 0)
			return;
	}
	
	if (hndl == INVALID_HANDLE)
		ReplyToCommand(client, "Query failed! %s", error);
	else
	{
		new String:FriendID[255], String:sBuffer[255];
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, sBuffer, 255);
		}
		Format(FriendID, sizeof(FriendID), "http://steamcommunity.com/profiles/%s", sBuffer);
		if(client!=0)
		{
			PrintToChat(client, FriendID);
			ShowMOTDPanel(client,"ID",FriendID,MOTDPANEL_TYPE_URL);
		}
		else
			PrintToServer("%s",FriendID);
	}
}
ProfileMenu(client)
{
	new Handle:menu = CreateMenu(ProfileMenuHandler);
	SetMenuTitle(menu, "Select Player:");
	new String:sName[255], String:sClientID[4];
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		GetClientName(i,sName,sizeof(sName));
		IntToString(i,sClientID,4);
		AddMenuItem(menu, sClientID, sName);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}
public ProfileMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[4];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		if(found)
		{
			new cID = StringToInt(info), String:ID[255];
			GetClientAuthString(cID,ID,255);
			new String:buffer[1024], UserID = GetClientUserId(param1);
			Format(buffer, sizeof(buffer), "SELECT CAST(MID('%s', 9, 1) AS UNSIGNED) + CAST('76561197960265728' AS UNSIGNED) + CAST(MID('%s', 11, 10) * 2 AS UNSIGNED) AS friend_id", ID, ID);
			SQL_TQuery(db, AuthIDToFriendID, buffer, UserID);
		}
	}
	else if (action == MenuAction_Cancel)
	{	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}
