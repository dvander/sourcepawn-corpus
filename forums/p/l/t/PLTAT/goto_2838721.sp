/** Change Log
 **
 ** 1.0.0: -Initial Release.
 ** 1.1.0: -Allow users to block TP requests from other users, or all users.
 **        -Allow admins to bring clients to them without authorization. Did not make available to clients because its functionality is so similar to sm_goto
 **        -Fixed an Invalid Handle error
 ** 1.2.0: -Actually fixed the Invalid Handle error...
 **        -Added function to allow users to ACCEPT all TP requests without displaying a menu
 **        -Cleaned up code a bit
 ** 1.3.0: -Added a teleport back command (sm_tpb or sm_goback)
 ** 1.3.1: -Cvar to prevent users from teleporting to their previous location more than once. Prevents its usage as a checkpoint.
 ** 1.3.2: -Fixed (cleaned up) usage of TeleportStatus enum
 ** 1.3.3: -Added Cvar to make the plugin Admin Only
 ** 1.3.4: -Code fixes, thanks to 11530
 ** 1.3.5: -Translation Support
 ** 1.4.0: -Admins may ban certain players from using the plugin.
 **
 **/

enum TeleportStatus{
	NotifyAll,
	DenyAll,
	AcceptAll
};

new LastRequest[MAXPLAYERS + 1];
new BlockedPlayer[MAXPLAYERS + 1][MAXPLAYERS + 1]; //[client][blocked player]
new TeleportStatus:PlayerStatus[MAXPLAYERS + 1];
new bool:BanStatus[MAXPLAYERS + 1] = {false};

new Handle:CooldownTime = INVALID_HANDLE;
new Handle:TargetOppositeTeam = INVALID_HANDLE;
new Handle:Version = INVALID_HANDLE;
new Handle:TeleportBackLimit = INVALID_HANDLE;

#include <sourcemod>
#include <sdktools>
#include "goto/validate.sp"

#define PLUGIN_VERSION "1.4.0"

new Float:LastLocation[MAXPLAYERS + 1][3];

new Handle:db = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Simple GoTo Command",
	author = "BB",
	description = "Allows players to teleport to other players",
	version = PLUGIN_VERSION,
};

public OnPluginStart(){
	CooldownTime = CreateConVar("gt_cooldowntime", "60.0", "Time between a player's use of the goto command.");
	TargetOppositeTeam = CreateConVar("gt_target_opposite_team", "1", "Allow users to target members of the opposite team.");
	TeleportBackLimit = CreateConVar("gt_teleport_back_limit", "0", "Prevent users from teleporting back to their saved location multiple times.");
	RegConsoleCmd("sm_goto", Command_GoTo, "Teleport to a player");
	RegConsoleCmd("sm_unblock", Command_Unblock, "Unblock a player or all players");
	RegConsoleCmd("sm_tpb", Command_GoBack, "Teleport to your last location");
	RegConsoleCmd("sm_goback", Command_GoBack, "Teleport to your last location");
	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_KICK, "Bring a player to you");
	RegAdminCmd("sm_goto_ban", Command_Goto_Ban, ADMFLAG_KICK, "Ban a player from making teleport requests");
	RegAdminCmd("sm_goto_unban", Command_Goto_Unban, ADMFLAG_KICK, "Unban a player from making teleport requests");
	RegAdminCmd("sm_goto_listbans", Command_ListBans, ADMFLAG_KICK, "List goto bans");
	Version = CreateConVar("goto_ver", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(Version, PLUGIN_VERSION, _, true);

	AutoExecConfig(true, "goto");

	LoadTranslations("common.phrases.txt");
	LoadTranslations("goto.phrases.txt");

	new String:error[255];
	db = SQL_Connect("goto_bans", true, error, sizeof(error));
	if(db == INVALID_HANDLE){
		PrintToServer("Could not connect: %s", error);
		CloseHandle(db);
	}
	else{
		PrintToServer("Connection successful");
	}

	new String:query[255]
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS banned_users (name VARCHAR(30) NULL, steamId INT NOT NULL PRIMARY KEY);");
	new Handle:createTable = SQL_Query(db, query, sizeof(query));
	CloseHandle(createTable);
}

public OnClientPostAdminCheck(client){
	//Check if player is banned
	new String:query[100];
	new String:steamId[30];

	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId), true);
	Format(query, sizeof(query), "SELECT steamId FROM banned_users WHERE steamId='%s';", steamId);

	SQL_TQuery(db, SQLT_CheckBans, query, client);

	LastLocation[client][0] = 0.0;
	LastLocation[client][1] = 0.0;
	LastLocation[client][2] = 0.0;

	LastRequest[client] = 0;
}

public void SQLT_CheckBans(Handle: owner, Handle:handle, const String:error[], any:client){
	if(SQL_FetchRow(handle))
	{
		BanStatus[client] = true;
	}
}

public OnClientDisconnect(client){
	for(new i = 1; i <= MaxClients; i++)
	{
		BlockedPlayer[i][client] = 0;
	}

	PlayerStatus[client] = NotifyAll;
	BanStatus[client] = false;

	LastLocation[client][0] = 0.0;
	LastLocation[client][1] = 0.0;
	LastLocation[client][2] = 0.0;
}

public Action:Command_GoTo(client, args){
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_goto <player>");
		return Plugin_Handled;
	}

	if(client < 1){
		ReplyToCommand(client, "[SM] %t", "In Game Only");
		return Plugin_Handled;
	}

	new target;
	new String:arg1[16];
	GetCmdArg(1, arg1, sizeof(arg1));

	target = FindTarget(client, arg1, false, false);

	if(!IsValidRequest(client, target)){
		return Plugin_Handled;
	}

	if(IsPermissionRequired(client, target)){
		AskMenu(client, target);
		ReplyToCommand(client, "[SM] %t", "Teleport Request", target);
		return Plugin_Handled;
	}

	//If they get this far, they are making a valid request and are an admin with auth bypass flags
	TeleportPlayer(client, target);
	return Plugin_Handled;
}

public Action:Command_Unblock(client, args){
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_unblock <player|all>");
		return Plugin_Handled;
	}
	if(client < 1){
		ReplyToCommand(client, "[SM] %t", "In Game Only");
		return Plugin_Handled;
	}

	new String:target[32];
	GetCmdArg(1, target, sizeof(target));

	if(StrEqual(target, "all")){
		PlayerStatus[client] = NotifyAll;
		for(new i = 1; i <= MaxClients; i++){
			BlockedPlayer[client][i] = 0;
		}
		ReplyToCommand(client, "[SM] %t", "All Unblocked");
		return Plugin_Handled;
	}

	new player = FindTarget(client, target, true, false);
	if(player != -1){
		BlockedPlayer[client][player] = 0;
		ReplyToCommand(client, "[SM] %t", "Unblocked Player", player);
	}

	return Plugin_Handled;
}

public Action:Command_GoBack(client, args){
	if(client < 1){
		ReplyToCommand(client, "[SM] %t", "In Game Only");
		return Plugin_Handled;
	}

	if((LastLocation[client][0] == 0.0) && (LastLocation[client][1] == 0.0) && (LastLocation[client][2] == 0.0)){
		ReplyToCommand(client, "[SM] %t", "No Saved Location");
		return Plugin_Handled;
	}

	TeleportEntity(client, LastLocation[client], NULL_VECTOR, NULL_VECTOR);
	if(GetConVarInt(TeleportBackLimit) && !CheckCommandAccess(client, "sm_goto_auth_bypass", ADMFLAG_ROOT)){
		LastLocation[client][0] = 0.0;
		LastLocation[client][1] = 0.0;
		LastLocation[client][2] = 0.0;
	}
	return Plugin_Handled;
}

public Action:Command_ListBans(client, args){
	if(client < 1){
		ReplyToCommand(client, "[SM] %t", "In Game Only");
		return Plugin_Handled;
	}

	PrintToChat(client, "[SM] %t", "Check Console");
	PrintToConsole(client, "********************************************************");
	PrintToConsole(client, "%t", "List of Banned");
	PrintToConsole(client, "********************************************************");

	new String:query[100];
	new String:name[30];
	new String:steamId[30];

	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId), true);
	Format(query, sizeof(query), "SELECT * FROM banned_users");
	new Handle:GotoBanlist = SQL_Query(db, query);

	if(GotoBanlist != INVALID_HANDLE){
		while(SQL_FetchRow(GotoBanlist)){
			SQL_FetchString(GotoBanlist, 0, name, SQL_FetchSize(GotoBanlist, 0) + 1);
			SQL_FetchString(GotoBanlist, 1, steamId, SQL_FetchSize(GotoBanlist, 1) + 1);
			PrintToConsole(client, "%s       %s", name, steamId);
		}
	}
	else PrintToServer("Database query failed");

	return Plugin_Handled;
}

public Action:Command_Goto_Unban(client, args){
	if(client < 1){
		PrintToServer("[SM] %t", "In Game Only");
		return Plugin_Handled;
	}

	if(args != 1){
		ReplyToCommand(client, "[SM] Usage: sm_goto_unban <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	new target = FindTarget(client, arg1, true, true);

	BanStatus[target] = false;

	new String:query[100];
	new String:steamId[30];
	new String:name[64];

	GetClientName(target, name, sizeof(name));
	GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId), true);

	Format(query, sizeof(query), "DELETE FROM banned_users WHERE steamId='%s'", steamId);

	if(SQL_FastQuery(db, query, sizeof(query))){
		PrintToChat(client, "[SM] %t", "Unban Successful", name)
	}
	else{
		new String:error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToChat(client, "%s", error);
	}

	return Plugin_Handled;
}

public Action:Command_Goto_Ban(client, args){
	if(client < 1){
		PrintToServer("[SM] %t", "In Game Only");
		return Plugin_Handled;
	}

	if(args != 1){
		ReplyToCommand(client, "[SM] Usage: sm_goto_ban <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	new target = FindTarget(client, arg1, true, true);

	new String:query[100];
	new String:name[64];
	new String:steamId[30];

	GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId), true);
	GetClientName(target, name, sizeof(name));
	PrintToConsole(client, "%s %s", name, steamId);
	Format(query, sizeof(query), "INSERT INTO banned_users VALUES ('%s', '%s')", name, steamId);

	if(SQL_FastQuery(db, query, sizeof(query))){
		ReplyToCommand(client, "[SM] %t", "Ban Successful", name);
	}

	BanStatus[target] = true;

	return Plugin_Handled;
}

public Action:Command_Bring(client, args){
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_bring <player>");
		return Plugin_Handled;
	}
	if(client < 1){
		ReplyToCommand(client, "[SM] %t", "In Game Only");
		return Plugin_Handled;
	}

	new player;
	new String:target[32];
	GetCmdArg(1, target, sizeof(target));

	player = FindTarget(client, target, false);
	if(player != -1){
		if(IsClientInGame(player)){
			if(IsPlayerAlive(client)){
				if(IsPlayerAlive(player)){
					TeleportPlayer(player, client);
					return Plugin_Handled;
				}
				else{
					ReplyToCommand(client, "[SM] %t", "Target Not Alive", player);
					return Plugin_Handled;
				}
			}
			else{
				ReplyToCommand(client, "[SM] %t", "User Not Alive");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

TeleportPlayer(client, target){
	new Float:coords[3];

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", LastLocation[client]);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", coords);

	TeleportEntity(client, coords, NULL_VECTOR, NULL_VECTOR);
	ReplyToCommand(client, "[SM] %t", "Teleported", target);
}

AskMenu(client, target){
	if(IsClientInGame(target) && IsPlayerAlive(target)){
		new Handle:menu = CreateMenu(AskMenu_Handler);
		new String:asker[12];
		new userid = GetClientUserId(client)
		IntToString(userid, asker, sizeof(asker));

		SetMenuTitle(menu, "Allow %N to teleport to you?", client);
		AddMenuItem(menu, asker, "Yes");
		AddMenuItem(menu, asker, "No");
		AddMenuItem(menu, asker, "Block User");
		AddMenuItem(menu, asker, "Block All");
		AddMenuItem(menu, asker, "Accept All");
		DisplayMenu(menu, target, 20);
		if(!(CheckCommandAccess(client, "sm_goto_cooldown_bypass", ADMFLAG_KICK))){
			LastRequest[client] = GetTime();
		}
	}
}

public AskMenu_Handler(Handle:menu, MenuAction:action, param1, param2){
//param 1 is client of teleport target
//param 2 is response of target. 0 = accept 1 = deny
	decl String:info[32];

	GetMenuItem(menu, param2, info, sizeof(info));

	new client = GetClientOfUserId(StringToInt(info));

	if(action == MenuAction_Select)	{
		if(IsClientInGame(param1) && IsPlayerAlive(param1))		{
			switch(param2)			{
				case 0:{
					TeleportPlayer(client, param1);
				}
				case 1:{
					ReplyToCommand(client, "[SM] %t", "Teleport Denied", param1);
				}
				case 2:{
					ReplyToCommand(client, "[SM] %t", "Teleport Denied", param1);
					ReplyToCommand(param1, "[SM] %t", "Inform Unblock", client);
					BlockedPlayer[param1][client] = 1;
				}
				case 3:{
					ReplyToCommand(client, "[SM] %t", "All Denied", param1);
					ReplyToCommand(param1, "[SM] %t", "All Denied 2");
					PlayerStatus[param1] = DenyAll;
				}
				case 4:{
					TeleportPlayer(client, param1);
					PlayerStatus[param1] = AcceptAll;
					ReplyToCommand(param1, " [SM] %t", "All Accepted");
				}
			}
		}
	}
	else if(action == MenuAction_End){
		CloseHandle(menu);
	}
}
