#pragma semicolon 1

#include <sourcemod>
#include <steamtools>

#define PLUGIN_VERSION "2.0"

#define MAX_GROUP_NAME_LEN 64
#define MAX_GROUP_ID_LEN 10

new AdminId:adminid[MAXPLAYERS+1];



// Cvars
// --------
new Handle:sm_sgam_enable, 				bool:enabled,
	Handle:sm_sgam_admin, 				bool:adminallow,
	Handle:sm_sgam_announce_allowed, 	bool:announce,
	Handle:sm_sgam_announce_restricted, bool:announcerestricted,
	Handle:sm_sgam_rejecttype,			rejecttype,
	Handle:sm_sgam_functype,			functype,
	Handle:sm_sgam_bantime,				ban_time;
// --------




// Arrays
// --------
new Handle:h_aGroups;
new Handle:h_aGroupNames;
// --------

// Globals
// --------
new String:s_LogFile[PLATFORM_MAX_PATH],
	String:s_PlayerGroup[MAXPLAYERS+1][1024];

new bool:g_bPlayerAccess[MAXPLAYERS+1];
new bool:g_bPlayerRestrict[MAXPLAYERS+1];

new GroupNum[MAXPLAYERS+1];
new MaxGroups;
// --------


public Plugin:myinfo = 
{
	name 		= "Steam Group Access Manager",
	author 		= "FrozDark (HLModders LLC)",
	description = "Allow or disallow a player if he is exists in a steam group from groupslist.",
	version 	= PLUGIN_VERSION,
	url 		= "http://www.hlmod.ru"
};

public OnPluginStart()
{
	CreateConVar("sm_sgam_version", PLUGIN_VERSION, "The plugin's version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	sm_sgam_enable 				= CreateConVar("sm_sgam_enable", 					"1", "Disables/Enables Steam Group Access Manager.", 0, true, 0.0, true, 1.0);
	sm_sgam_admin 				= CreateConVar("sm_sgam_admin", 					"1", "Disables/Enables always admin allow.", 0, true, 0.0, true, 1.0);
	sm_sgam_announce_allowed 	= CreateConVar("sm_sgam_announce_allowed", 			"1", "Announces to the chat if a player connected successfuly if \"sm_sgam_functype 0\".", 0, true, 0.0, true, 1.0);
	sm_sgam_announce_restricted	= CreateConVar("sm_sgam_announce_restricted", 		"1", "Shows to a rejected player the restricted groups if \"sm_sgam_functype 1\".", 0, true, 0.0, true, 1.0);
	sm_sgam_functype			= CreateConVar("sm_sgam_functype", 					"0", "Function type. 0-Allow only groupslist's memberships / 1-Disallow groupslist's memberships", 0, true, 0.0, true, 1.0);
	sm_sgam_rejecttype			= CreateConVar("sm_sgam_rejecttype", 				"0", "Disallow type. 0-Kick / 1-BanIP / 2-BanID.", 0, true, 0.0, true, 2.0);
	sm_sgam_bantime 			= CreateConVar("sm_sgam_bantime", 					"60", "Ban time in minutes (0-forever).", 0, true, 0.0);
	
	RegAdminCmd("sm_sgam_reload", ParseConfig, ADMFLAG_ROOT, "Reloads groupslist file");
	
	RegServerCmd("sgam_status", Command_Status);
	
	functype 			= GetConVarInt(sm_sgam_functype);
	rejecttype 			= GetConVarInt(sm_sgam_rejecttype);
	ban_time 			= GetConVarInt(sm_sgam_bantime);
	announce 			= GetConVarBool(sm_sgam_announce_allowed);
	announcerestricted 	= GetConVarBool(sm_sgam_announce_restricted);
	adminallow 			= GetConVarBool(sm_sgam_admin);
	enabled 			= GetConVarBool(sm_sgam_enable);
	
	HookConVarChange(sm_sgam_enable, 				OnConVarChange);
	HookConVarChange(sm_sgam_admin, 				OnConVarChange);
	HookConVarChange(sm_sgam_announce_allowed, 		OnConVarChange);
	HookConVarChange(sm_sgam_announce_restricted, 	OnConVarChange);
	HookConVarChange(sm_sgam_functype, 				OnConVarChange);
	HookConVarChange(sm_sgam_rejecttype, 			OnConVarChange);
	HookConVarChange(sm_sgam_bantime, 				OnConVarChange);
	
	BuildPath(Path_SM, s_LogFile, sizeof(s_LogFile), "logs/sga_manager.log");
	
	h_aGroups = CreateArray();
	h_aGroupNames = CreateTrie();
	
	LoadTranslations("sga_manager");
	AutoExecConfig(true, "sga_manager");
}

public OnConfigsExecuted()
{
	ParseConfig(0,0);
	
	LogToFile(s_LogFile, "Steam Group Access Manager: %s", enabled ? "Enabled" : "Disabled");
	switch (functype)
	{
		case 0 :
		{
			LogToFile(s_LogFile, "Function type: Allow only groupslist's memberships");
			LogToFile(s_LogFile, "Announcement a player's allowed group name: %s", announce ? "On" : "Off");
		}
		case 1 :
		{
			LogToFile(s_LogFile, "Function type: Reject groupslist's memberships");
			LogToFile(s_LogFile, "Announcement a player's restricted group name: %s", announcerestricted ? "On" : "Off");
		}
	}
	switch (rejecttype)
	{
		case 0 :
			LogToFile(s_LogFile, "Reject type: Kick");
		case 1 :
			LogToFile(s_LogFile, "Reject type: Ban by IP");
		case 2 :
			LogToFile(s_LogFile, "Reject type: Ban by SteamID");
	}
	LogToFile(s_LogFile, "Admins: %s", adminallow ? "Allowed" : "Disallowed");
	switch (ban_time)
	{
		case 0 :
			LogToFile(s_LogFile, "Ban Time: forever");
		default :
			LogToFile(s_LogFile, "Ban Time: %i minutes", ban_time);
	}
}

public Action:Command_Status(args)
{
	decl String:buffer[32], String:Status[512];
	switch (rejecttype)
	{
		case 0:
			strcopy(buffer, sizeof(buffer), "Kick");
		case 1:
			strcopy(buffer, sizeof(buffer), "Ban by IP");
		case 2:
			strcopy(buffer, sizeof(buffer), "Ban by SteamID");
	}
	
	Format(Status, sizeof(Status), "~~~~~ STATUS ~~~~~\n[Steam Group Access Manager v%s]\n-------\nSteam is %s\nNumber of groups: %d\nPlugin: %s\nFunc Type: %s\nReject Type: %s\nBan Time: %d\n-------", PLUGIN_VERSION, Steam_IsConnected() ? "available":"unavailable", MaxGroups, enabled ? "enabled":"disabled", functype ? "Disallow groupslist's memberships":"Allow groupslist's memberships", buffer, ban_time);
	
	PrintToServer(Status);
	
	if (args)
	{
		GetCmdArgString(buffer, sizeof(buffer));
		if (!strcmp(buffer, "dump", false))
		{
			new Handle:file = OpenFile(s_LogFile, "a");
			WriteFileLine(file, Status);
			CloseHandle(file);
		}
	}
	
	return Plugin_Handled;
}

public Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
	if (client && CompareSteamGroups(groupAccountID))
	{
		GroupNum[client]++;
		switch (functype)
		{
			case 0 :
			{
				if (groupMember || groupOfficer)
				{
					if (!g_bPlayerAccess[client])
						LogToFile(s_LogFile, "%N is in group %i and has access to the server", client, groupAccountID);
					AddGroupToClient(client, groupAccountID);
					g_bPlayerAccess[client] = true;
				}
				else if (!g_bPlayerAccess[client])
					LogToFile(s_LogFile, "%N is not in group %i and has no access to the server", client, groupAccountID);
			}
			case 1 :
			{
				if (groupMember || groupOfficer)
				{
					if (!g_bPlayerRestrict[client])
						LogToFile(s_LogFile, "%N is in group %i and has no access to the server", client, groupAccountID);
					AddGroupToClient(client, groupAccountID);
					g_bPlayerRestrict[client] = true;
				}
				else
				{
					if (!g_bPlayerRestrict[client])
						LogToFile(s_LogFile, "%N is not in group %i and has access to the server", client, groupAccountID);
				}
			}
		}
		if (GroupNum[client] >= MaxGroups)
		{
			Check(client);
			GroupNum[client] = 0;
		}
	}
}

AddGroupToClient(client, groupid)
{
	decl String:buffer[MAX_GROUP_NAME_LEN+1],
		String:group[MAX_GROUP_ID_LEN+1];
	
	IntToString(groupid, group, sizeof(group));
	
	if (GetTrieString(h_aGroupNames, group, buffer, sizeof(buffer)))
	{
		if (s_PlayerGroup[client][0])
			Format(s_PlayerGroup[client], sizeof(s_PlayerGroup[]), "%s, \"%s\"", s_PlayerGroup[client], buffer);
		else
			Format(s_PlayerGroup[client], sizeof(s_PlayerGroup[]), "\"%s\"", buffer);
	}
}

Check(client)
{
	decl String:steam_id[21],
		String:player_ip[16];
	
	GetClientIP(client, player_ip, sizeof(player_ip));
	GetClientAuthString(client, steam_id, sizeof(steam_id));

	if ((functype == 0 && g_bPlayerAccess[client]) || (functype == 1 && !g_bPlayerRestrict[client]))
	{
		if (announce && !functype)
		{
			if (adminid[client] != INVALID_ADMIN_ID)
			{
				if (!s_PlayerGroup[client][0])
					PrintToChatAll("%t", "AdminJoined", 4, 3, client, 4, 3, player_ip, 4, 3, steam_id);
				else
				{
					PrintToChatAll("%t", "AdminJoinedFrom", 4, 3, client, 4, 3, steam_id, 4, 3, s_PlayerGroup[client]);
					PrintToServer("%N connected from %s groups", client, s_PlayerGroup[client]);
				}
			}
			else
			{
				if (!s_PlayerGroup[client][0])
					PrintToChatAll("%t", "PlayerJoined", 4, 3, client, 4, 3, player_ip, 4, 3, steam_id);
				else
				{
					PrintToChatAll("%t", "PlayerJoinedFrom", 4, 3, client, 4, 3, steam_id, 4, 3, s_PlayerGroup[client]);
					PrintToServer("%N connected from %s groups", client, s_PlayerGroup[client]);
				}
			}
		}
	}
	else
	{
		decl String:RejectMessage[128];
		
		switch (functype)
		{
			case 0 :
				Format(RejectMessage, sizeof(RejectMessage), "%t", "KickMessage1");
				
			default :
			{
				if (announcerestricted && s_PlayerGroup[client][0])
					Format(RejectMessage, sizeof(RejectMessage), "%t", "KickMessage2-2", s_PlayerGroup[client]);
						
				else
					Format(RejectMessage, sizeof(RejectMessage), "%t", "KickMessage2-1");
			}
		}
			
			
		switch (rejecttype)
		{
			case 0 :
				KickClient(client, RejectMessage);
				
			case 1 :
				BanClient(client, ban_time, BANFLAG_IP, "Player is Restricted", RejectMessage);
				
			case 2 :
				BanClient(client, ban_time, BANFLAG_AUTHID, "Player is Restricted", RejectMessage);		
		}
	}
}

LookupPlayerGroups(client)
{
	new req;
	GroupNum[client] = 0;
	s_PlayerGroup[client] = "";
	for (new i = 0; i < MaxGroups; i++)
	{
		req = i+1;
		new groupid = GetArrayCell(h_aGroups, i);
		if (Steam_RequestGroupStatus(client, groupid))
			LogToFile(s_LogFile, "The %i request for the %N's status in group %i", req, client, groupid);
		else
		{
			LogToFile(s_LogFile, "Request number %i failed", req);
			GroupNum[client]++;
		}
		if (GroupNum[client] >= MaxGroups)
		{
			Check(client);
			GroupNum[client] = 0;
			break;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (enabled && !IsFakeClient(client))
	{
		adminid[client] = GetUserAdmin(client);
			
		if (adminallow && adminid[client] != INVALID_ADMIN_ID)
		{
			decl String:steam_id[64];
			decl String:player_ip[64];
	
			GetClientIP(client, player_ip, sizeof(player_ip));
			GetClientAuthString(client, steam_id, sizeof(steam_id));
			
			if (announce)
				PrintToChatAll("%t", "AdminJoined", 4, 3, client, 4, 3, player_ip, 4, 3, steam_id);
		}
		else if (Steam_IsConnected())
		{
			LookupPlayerGroups(client);
		}
		else
		{
			LogToFile(s_LogFile, "No reason to check %N because steam no connected", client);
		}
	}
}

public OnClientDisconnect_Post(client)
{
	g_bPlayerAccess[client] = false;
	g_bPlayerRestrict[client] = false;
}





// Parser
// ---------

public Action:ParseConfig(client, args)
{
	decl String:configPath[PLATFORM_MAX_PATH],
		String:Line[MAX_GROUP_NAME_LEN+MAX_GROUP_ID_LEN+1],
		String:Text[2][MAX_GROUP_NAME_LEN+1];
	
	BuildPath(Path_SM, configPath, sizeof(configPath), "data/sgam_groups.txt");
	
	new Handle:filehandle = OpenFile(configPath, "r");
	
	if (filehandle == INVALID_HANDLE)
	{
		LogToFile(s_LogFile, "File %s doesn't exist", configPath);
		return Plugin_Handled;
	}
	
	ClearArray(h_aGroups);
	ClearTrie(h_aGroupNames);
	
	while(!IsEndOfFile(filehandle))
	{
		ReadFileLine(filehandle, Line, sizeof(Line));
	
		new pos;
		pos = StrContains((Line), "//");
		if (pos != -1)
			Line[pos] = '\0';
	
		pos = StrContains((Line), "#");
		if (pos != -1)
			Line[pos] = '\0';
			
		pos = StrContains((Line), ";");
		if (pos != -1)
			Line[pos] = '\0';

		TrimString(Line);
		
		if (Line[0] == '\0')
			continue;
		
		if (FindCharInString(Line, '=') == 7)
		{
			ExplodeString(Line, "=", Text, sizeof(Text), sizeof(Text[]));
			if (String_IsNumeric(Text[0]))
			{
				PushArrayCell(h_aGroups, StringToInt(Text[0]));
				if (Text[1][0])
					SetTrieString(h_aGroupNames, Text[0], Text[1], true);
			}
		}
		
		else if (String_IsNumeric(Line))
			PushArrayCell(h_aGroups, StringToInt(Text[0]));
			
		else
			continue;
			
		LogToFile(s_LogFile, "Group loaded - ID: %s, %s%s", Text[0], Text[1][0] ? "Name: ":"", Text[1]);
	}
	CloseHandle(filehandle);
	
	if (!(MaxGroups = GetArraySize(h_aGroups)))
	{
		LogError("No groups found in the groupslist. Diactivating...");
		enabled = false;
	}
	
	return Plugin_Handled;
}

// ---------







CompareSteamGroups(groupid)
{
	return (FindValueInArray(h_aGroups, groupid) != -1);
}

/****************************************************************************************
*************** F		O		O		T		E		R ****************************
****************************************************************************************/




public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == sm_sgam_enable)
	{
		if (enabled != bool:StringToInt(newValue))
			enabled = !enabled;
		
		if (enabled && !MaxGroups)
			LogError("You have to load groupslist first and be sure it isn't empty. Use 'sm_sgam_reload' in the console");
		
		LogToFile(s_LogFile, "Steam Group Access Manager: %s", enabled ? "Enabled" : "Disabled");
	} else
	if (convar == sm_sgam_admin)
	{
		if (adminallow != bool:StringToInt(newValue))
			adminallow = !adminallow;
		
		LogToFile(s_LogFile, "Admins: %s", adminallow ? "Allowed" : "Disallowed");
	} else
	if (convar == sm_sgam_announce_allowed)
	{
		if (announce != bool:StringToInt(newValue))
			announce = !announce;
		
		LogToFile(s_LogFile, "Announcement a player's allowed group name: %s", announce ? "On" : "Off");
	} else
	if (convar == sm_sgam_announce_restricted)
	{
		if (announce != bool:StringToInt(newValue))
			announce = !announce;
		
		LogToFile(s_LogFile, "Announcement a player's restricted group name: %s", announce ? "On" : "Off");
	} else
	if (convar == sm_sgam_rejecttype)
	{
		rejecttype = StringToInt(newValue);
		switch (rejecttype)
		{
			case 0 :
				LogToFile(s_LogFile, "Reject type: Kick");
			case 1 :
				LogToFile(s_LogFile, "Reject type: Ban by IP");
			case 2 :
				LogToFile(s_LogFile, "Reject type: Ban by SteamID");
		}
	} else
	if (convar == sm_sgam_functype)
	{
		functype = StringToInt(newValue);
		switch (functype)
		{
			case 0 :
				LogToFile(s_LogFile, "Function type: Allow only groupslist's memberships");
			default :
				LogToFile(s_LogFile, "Function type: Reject groupslist's memberships");
		}
	} else
	if (convar == sm_sgam_bantime)
	{
		ban_time = StringToInt(newValue);
		switch (ban_time)
		{
			case 0 :
				LogToFile(s_LogFile, "Ban Time: forever");
			default :
				LogToFile(s_LogFile, "Ban Time: %i minutes", ban_time);
		}
	}
}

stock bool:String_IsNumeric(const String:str[])
{	
	new x=0;
	new numbersFound=0;

	while (str[x] != '\0')
	{

		if (IsCharNumeric(str[x]))
			numbersFound++;
		else
			return false;
		x++;
	}
	
	if (!numbersFound)
		return false;
	
	return true;
}