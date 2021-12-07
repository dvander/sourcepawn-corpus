#include <sourcemod>
#include <morecolors>
#include <cstrike>

//-------	Defining Stuff
new bool:Trusted[MAXPLAYERS + 1];
#define PLN_VRSN "3.0"

//-------	CVAR
new Handle:T_Tags = INVALID_HANDLE;
new String:T_Tag[30];
new Handle:T_MenuTtl = INVALID_HANDLE;
new String:T_Menu[30];
new Handle:g_Enabled;

//-------	SQL
static Handle:db = INVALID_HANDLE;
static String:Xs[360];

//-------	Other Stuff
static String:TLogPath[PLATFORM_MAX_PATH];
new Handle:KickMsg = INVALID_HANDLE;
new TEAM_1 = 3;
new TEAM_2 = 2;

public GetOtherTeam(team)
{
	if(team == TEAM_2)
		return TEAM_1;
	else
		return TEAM_2;
}

public Plugin:myinfo = {
	name = "Trusted Menu",
	author = ".Golf",
	description = "The trusted menu is meant to keep the server moving when there are no admins available, without the ability to cause any sort of permanent damage.",
	version = PLN_VRSN,
	url = "http://steamcommunity.com/id/deadmantroll"
};

public OnPluginEnd(){
	CloseHandle(db);}

public OnMapStart(){
	CheckTheDB();}

public OnClientPutInServer(client){
	CheckTrust(client);}

public OnClientDisconnect(client){
	Trusted[client] = false;}

public OnPluginStart()
{
	BuildPath(Path_SM, TLogPath, sizeof(TLogPath), "logs/Trusted.txt");
	
	RegConsoleCmd("sm_t", MessageTrust);
	RegConsoleCmd("sm_tmenu", OpenTMenu);
	RegAdminCmd("sm_givetrust", GiveTClient, ADMFLAG_UNBAN);
	RegAdminCmd("sm_removetrust", RemoveTClient, ADMFLAG_UNBAN);
	RegAdminCmd("sm_removetrustid", RemoveTClientID, ADMFLAG_UNBAN);
	
	AddCommandListener(CallBack, "say");
	
	CreateConVar("sm_trusted_version", PLN_VRSN, "Trusted menu that is meant to keep the server moving when there are no admins available", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Enabled = CreateConVar("sm_trusted_enable", "1", "Set to [1] to enable / set to [2] to disable");
	KickMsg = CreateConVar("sm_trusted_kmsg", "You have been kicked by a Trustee.", "Kick message sent to kicked client", FCVAR_PLUGIN);
	
	
	T_Tags = CreateConVar("sm_T_tag", "Trusted", "Change to what ever.", FCVAR_PROTECTED);
	T_MenuTtl = CreateConVar("sm_T_Menu", "[Trusted Menu]", "Change to what ever.", FCVAR_PROTECTED);
}

public CheckTheDB()
{
	new Handle:KeyVal = CreateKeyValues("");

	KvSetString(KeyVal, "driver", "sqlite");
	KvSetString(KeyVal, "database", "Trusted");
	
	db = SQL_ConnectCustom(KeyVal, Xs, 360, true);
	
	if(db == INVALID_HANDLE)
	{
		SQL_GetError(db, Xs, 360);
		SetFailState("Trusted Error with SQL: %s", Xs);
	}
	
	SQL_Query(db, "CREATE TABLE IF NOT EXISTS 'Trusted' ( 'steamid' VARCHAR(32) NOT NULL PRIMARY KEY, 'steamname' VARCHAR(32) NOT NULL, 'adminID' VARCHAR(32) NOT NULL )");
	
	CloseHandle(KeyVal);
}

CheckTrust(client)
{
	new String:STMID[25];
	GetClientAuthString(client, STMID, sizeof(STMID));
	decl String:query[255];
	Format(query, sizeof(query), "SELECT steamid FROM Trusted WHERE steamid = '%s'", STMID);

	SQL_TQuery(db, T_CheckTrusted, query, client);
}

public T_CheckTrusted(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Not Found %s", error);
	}
	else if (SQL_GetRowCount(hndl)) 
	{
		Trusted[client] = true;
	}
}

public T_addTrust(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
}

//////////////////////////////
//		COMMAND HANDLES		//
//////////////////////////////

public Action:GiveTClient(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givetrust <player>");
		return Plugin_Handled;
	}
		
	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	
	new target = FindTarget(client, arg);
	
	if( target > 0 && target <= MaxClients )
	{
		if (Trusted[target])
		{
			CPrintToChat(client, "{olive}[%s] {default}%N is already a Trusted Member!", T_Tag, target);
		}
		else
		{
			if (IsClientInGame(target))
			{
				new String:query[255], String:tName[40], String:Tsteam[25], String:Psteam[25];
				
				GetClientName(target, tName, sizeof(tName));
				GetClientAuthString(target, Tsteam, sizeof(Tsteam));
				GetClientAuthString(client, Psteam, sizeof(Psteam));
				
				Format(query, sizeof(query), "INSERT INTO Trusted(steamid, steamname, adminID) VALUES('%s', '%s', '%s')", Tsteam , tName, Psteam); 
				CPrintToChat(client, "{olive}[%s] {default}Player [ %N ], is now a trustee.", T_Tag, target);
				CPrintToChat(target, "{olive}[%s] {default}You are now a Trusted player of this server.", T_Tag);
				CPrintToChatAll("{olive} [%s] {default}%N, is now a trusted player!", T_Tag, target);
				Trusted[target] = true;
				
				SQL_TQuery(db, T_addTrust, query, client);
				//SQL_FastQuery(db, query);
			}
		}
	}
	return Plugin_Handled;
}

public Action:RemoveTClient(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removetrust <player>");
		return Plugin_Handled;
	}
		
	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	
	new target = FindTarget(client, arg);
	
	if( target > 0 && target <= MaxClients )
	{
		if (Trusted[target] && IsClientInGame(target)){
			new String:query[255], String:tName[40], String:cName[40], String:Tsteam[25], String:Psteam[25];
			
			GetClientName(target, tName, sizeof(tName));
			GetClientName(client, cName, sizeof(cName));
			GetClientAuthString(target, Tsteam, sizeof(Tsteam));
			GetClientAuthString(client, Psteam, sizeof(Psteam));
			
			Format(query, sizeof(query), "DELETE FROM Trusted WHERE steamid = '%s'", Tsteam); 
			CPrintToChat(client, "{olive}[%s] {teal}Players Trusted is now revoked!!", T_Tag, client);
			Trusted[target] = false;
			
			SQL_TQuery(db, T_addTrust, query, client);	

			new String:buffer[100];
			FormatTime(buffer, sizeof(buffer), NULL_STRING, -1);
			new Handle:fileHandle = OpenFile(TLogPath,"a");
			if (fileHandle != INVALID_HANDLE)
			{
				WriteFileLine(fileHandle, "[ %s ] %s <%s>:revoked players trusted %s <%s>", buffer, cName, Psteam, tName, Psteam);
				CloseHandle(fileHandle);
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[%s] {default}That Player isn't a Trusted!!", T_Tag);
		}
	}
	return Plugin_Handled;
}

public Action:RemoveTClientID(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removetrustid <steamid>");
		return Plugin_Handled;
	}
	
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	decl String:msg[360]
	GetCmdArgString(msg, sizeof(msg));
	
	new String:query[255], String:cName[40], String:Psteam[25];
	
	GetClientName(client, cName, sizeof(cName));
	GetClientAuthString(client, Psteam, sizeof(Psteam));
	
	Format(query, sizeof(query), "DELETE FROM Trusted WHERE steamid = '%s'", msg); 
	CPrintToChat(client, "{olive}[%s] {teal}Players Trusted is now revoked!!", T_Tag, client);
	
	SQL_TQuery(db, T_addTrust, query, client);	

	new String:buffer[100];
	FormatTime(buffer, sizeof(buffer), NULL_STRING, -1);
	new Handle:fileHandle = OpenFile(TLogPath,"a");
	if (fileHandle != INVALID_HANDLE)
	{
		WriteFileLine(fileHandle, "[ %s ] %s <%s>:revoked players trusted <%s>", buffer, cName, Psteam, msg);
		CloseHandle(fileHandle);
	}
	return Plugin_Handled;
}

public Action:MessageTrust(client, args)
{
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));

	decl String:msg[360]
	GetCmdArgString(msg, sizeof(msg));
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if(Trusted[i] && IsClientInGame(i)){
				CPrintToChat(i, "{olive}[%s-Chat] {white}%N {default}%s", T_Tag, client, msg);
		}
	}
}

public Action:CallBack(client, const String:command[], args)
{
	new Tenable = GetConVarInt(g_Enabled);
	
	if (!Tenable)
	{
		return;
	}
	
	if (Trusted[client])
	{
		decl String:msg[256];
		GetCmdArg(1, msg, sizeof(msg))
		
		if (!strcmp(msg,"/tkick",false) || !strcmp(msg,"!tkick",false))
		{
			KickPlayer(client);
		}
		
		if (!strcmp(msg,"/tslay",false) || !strcmp(msg,"!tslay",false))
		{
			SlayPlayer(client);
		}
		
		if (!strcmp(msg,"/tspawn",false) || !strcmp(msg,"!tspawn",false))
		{
			RespawnPlayer(client);
		}
		
		if (!strcmp(msg,"/tswap",false) || !strcmp(msg,"!tswap",false))
		{
			SwapPlayer(client);
		}
	}
}


//	ACTION HANDLES
public Action:RespawnPlayer(client)
{
	new Handle:menu = CreateMenu(RespawnHandle);
	SetMenuTitle(menu, "Select Player to Respawn");
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		new String:name[64];
		
		if (IsClientInGame(i))
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public Action:SwapPlayer(client)
{
	new Handle:menu = CreateMenu(SwapHandle);
	SetMenuTitle(menu, "Select Player to Swap");
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		new String:name[64];
		
		if (IsClientInGame(i))
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public Action:SlayPlayer(client)
{
	new Handle:menu = CreateMenu(SlayHandle);
	SetMenuTitle(menu, "Select Player to Slay");
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		new String:name[64];
		
		if ((IsClientInGame(i)) && IsPlayerAlive(i))
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public Action:KickPlayer(client)
{
	new Handle:menu = CreateMenu(kickHandle);
	SetMenuTitle(menu, "Select Player to Kick");
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		new String:name[64];
		
		if (IsClientInGame(i))
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public SlayHandle(Handle:menu, MenuAction:action, client, param2)
{
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	if(action == MenuAction_Select) 
	{
		new String:nameclient2[64];
		new String:loopname[64];
		GetMenuItem(menu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
			{
				new String:cname[64],String:TrustID[32],String:TargetID[32];
				
				GetClientAuthString(client, TrustID, sizeof(TrustID));
				GetClientAuthString(i, TargetID, sizeof(TargetID));
				GetClientName(client, cname, sizeof(cname));
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					FakeClientCommand(i, "kill");
					datMenu(client);
					
					CPrintToChatAll("{olive}[%s] {default}%s was slayed by {green}[{olive}%s{green}]{default} %s", T_Tag, loopname, T_Tag, cname);
					
					new String:buffer[100];
					FormatTime(buffer, sizeof(buffer), NULL_STRING, -1);
					new Handle:fileHandle = OpenFile(TLogPath,"a");
					if (fileHandle != INVALID_HANDLE)
					{
						WriteFileLine(fileHandle, "[ %s ] %s <%s>: slayed %s <%s>", buffer, cname, TrustID, loopname, TargetID);
						CloseHandle(fileHandle);
					}
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ReopenMenu(client);
	}
}

public RespawnHandle(Handle:menu, MenuAction:action, client, param2)
{
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	if(action == MenuAction_Select) 
	{
		new String:nameclient2[64];
		new String:loopname[64];
		GetMenuItem(menu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				new String:TrustID[32],String:TargetID[32],String:cname[64];
				
				GetClientAuthString(client, TrustID, sizeof(TrustID));
				GetClientAuthString(i, TargetID, sizeof(TargetID));
				GetClientName(client, cname, sizeof(cname));
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (IsPlayerAlive(i))
					{
						CPrintToChat(client, "{olive}[%s] {default}Target is alive.", T_Tag);
					}
					else
					{
						CS_RespawnPlayer(i);
						datMenu(client);
						
						CPrintToChatAll("{olive}[%s] {default}%s was spawned by {green}[{olive}%s{green}]{default} %s", T_Tag, loopname, T_Tag, cname);
						
						new String:buffer[100];
						FormatTime(buffer, sizeof(buffer), NULL_STRING, -1);
						new Handle:fileHandle = OpenFile(TLogPath,"a");
						if (fileHandle != INVALID_HANDLE)
						{
							WriteFileLine(fileHandle, "[ %s ] %s <%s>: respawned %s <%s>", buffer, cname, TrustID, loopname, TargetID);
							CloseHandle(fileHandle);
						}
					}
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ReopenMenu(client);
	}
}

public SwapHandle(Handle:menu, MenuAction:action, client, param2)
{
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	if(action == MenuAction_Select) 
	{
		new String:nameclient2[64];
		new String:loopname[64];
		GetMenuItem(menu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				new String:TrustID[32],String:TargetID[32],String:cname[64];
				
				GetClientAuthString(client, TrustID, sizeof(TrustID));
				GetClientAuthString(i, TargetID, sizeof(TargetID));
				GetClientName(client, cname, sizeof(cname));
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					ChangeClientTeam(i, GetOtherTeam(GetClientTeam(i)));
					datMenu(client);
					
					CPrintToChatAll("{olive}[%s] {default}%s was swapped to another team by {green}[{olive}%s{green}]{default} %s", T_Tag, loopname, T_Tag, cname);
					
					new String:buffer[100];
					FormatTime(buffer, sizeof(buffer), NULL_STRING, -1);
					new Handle:fileHandle = OpenFile(TLogPath,"a");
					if (fileHandle != INVALID_HANDLE)
					{
						WriteFileLine(fileHandle, "[ %s ] %s <%s>: swapped %s <%s>", buffer, cname, TrustID, loopname, TargetID);
						CloseHandle(fileHandle);
					}
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ReopenMenu(client);
	}
}

public kickHandle(Handle:menu, MenuAction:action, client, param2)
{
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	if(action == MenuAction_Select) 
	{
		new String:nameclient2[64];
		new String:loopname[64];
		GetMenuItem(menu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				new String:Message[512],String:TrustID[32],String:TargetID[32],String:cname[64];
				
				GetClientAuthString(client, TrustID, sizeof(TrustID));
				GetClientAuthString(i, TargetID, sizeof(TargetID));
				GetClientName(client, cname, sizeof(cname));
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetConVarString(KickMsg, Message, sizeof(Message));
					KickClient(i, Message);
					datMenu(client);

					CPrintToChatAll("{olive}[%s] {default}%s was kicked by {green}[{olive}%s{green}]{default} %s", T_Tag, loopname, T_Tag, cname);
					
					new String:buffer[100];
					FormatTime(buffer, sizeof(buffer), NULL_STRING, -1);
					new Handle:fileHandle = OpenFile(TLogPath,"a");
					if (fileHandle != INVALID_HANDLE)
					{
						WriteFileLine(fileHandle, "[ %s ] %s <%s>: kicked %s <%s>", buffer, cname, TrustID, loopname, TargetID);
						CloseHandle(fileHandle);
					}
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ReopenMenu(client);
	}
}

public ReopenMenu(client)
{
	GetConVarString(T_MenuTtl, T_Menu, sizeof(T_Menu));
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, T_Menu);
	DrawPanelText(panel, "  ");
	DrawPanelItem(panel, "Kick Players");
	DrawPanelItem(panel, "Slay Players");
	DrawPanelItem(panel, "Respawn Players");
	DrawPanelItem(panel, "Swap Players");
	SendPanelToClient(panel, client, MenuTaction, 10);
}

public Action:OpenTMenu(client, args)
{
	new Tenable = GetConVarInt(g_Enabled);
	
	if (!Tenable)
	{
		return;
	}
	
	datMenu(client);
}

public Action:datMenu(client)
{
	GetConVarString(T_Tags, T_Tag, sizeof(T_Tag));
	GetConVarString(T_MenuTtl, T_Menu, sizeof(T_Menu));
	if (Trusted[client])
	{
		new Handle:panel = CreatePanel();
		SetPanelTitle(panel, T_Menu);
		DrawPanelText(panel, "  ");
		DrawPanelItem(panel, "Kick Players");
		DrawPanelItem(panel, "Slay Players");
		DrawPanelItem(panel, "Respawn Players");
		DrawPanelItem(panel, "Swap Players");
		SendPanelToClient(panel, client, MenuTaction, 5);
	}
	else
	{
		CPrintToChat(client, "{olive}[%s] {default}%N, You do not have permission to use this command.", T_Tag, client);
	}
}

public MenuTaction(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				KickPlayer(param1);
			}
			case 2:
			{
				SlayPlayer(param1);
            }
			case 3:
			{
				RespawnPlayer(param1);
			}
			case 4:
			{
				SwapPlayer(param1);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}