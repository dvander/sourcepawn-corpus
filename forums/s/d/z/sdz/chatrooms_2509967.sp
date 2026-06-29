#include <sourcemod>
#include <morecolors>

enum ReplyVersion
{
	Reply_None = 0, //Not found:
	Reply_GoodGames, //Source 2009 Games
	Reply_CSGO //CS:GO
}

enum MsgCode
{
	Msg_Unknown = 0,
	Msg_Disabled,
	Msg_AdminOnly,
	Msg_InvalidSyntaxJoin,
	Msg_RoomExists,
	Msg_Created,
	Msg_JoinRoom,
	Msg_Console,
	Msg_Target,
	Msg_NoRoom,
	Msg_InvalidPassword,
	Msg_OwnerLeft,
	Msg_OwnerAbandon
}

EngineVersion g_eVersion;

StringMap g_mChatRooms;

ConVar g_cvAdminOnly,
g_cvEnabled,
g_cvAdminSpy;

bool g_bEnabled = true,
g_bAdminOnly = false,
g_bAdminSpy = true;

//Client Variables:
int g_CurrentRoom[MAXPLAYERS + 1] = {0, ...} //0 = Global Chatroom


public void OnPluginStart()
{
	//Console Variables
	CreateConVar("sm_chatrooms_version", "1.1", "Version of the plugin", FCVAR_NOTIFY); //Version cvar, never change this lol
	g_cvEnabled = CreateConVar("sm_chatrooms_enabled", "1", "Enable/Disable the plugin", FCVAR_NOTIFY);
	g_cvAdminOnly = CreateConVar("sm_chatrooms_adminonly", "0", "Should only administrators be able to create new channels?", FCVAR_NOTIFY);
	g_cvAdminSpy = CreateConVar("sm_chatrooms_adminspy", "1", "Show admins all chat regardless of chat channel", FCVAR_NOTIFY);

	//I'd rather use a bool rather than check convar value every time
	HookConVarChange(view_as<Handle>(g_cvEnabled), cvChange_Enabled);
	HookConVarChange(view_as<Handle>(g_cvAdminOnly), cvChange_Admin);
	HookConVarChange(view_as<Handle>(g_cvAdminSpy), cvChange_Spy);

	//Multi-Game Compatability, mostly for CS:GO's terrible chatbox
	g_eVersion = GetEngineVersion();
	
	//Nice config name
	AutoExecConfig(true, "chatrooms");

	//Make some commands
	RegConsoleCmd("sm_createchatroom", Command_CreateRoom, "- Create a new chatroom");
	//RegConsoleCmd("sm_deletechatroom", Command_DeleteRoom, "- Delete a chatroom");
	RegConsoleCmd("sm_chatrooms", Command_ChatRoomList, "- List all chatrooms");
	RegConsoleCmd("sm_chatroomlist", Command_ChatRoomList, "- List all chatrooms");
	RegConsoleCmd("sm_listchatrooms", Command_ChatRoomList, "- List all chatrooms");
	RegConsoleCmd("sm_cr", Command_JoinChatRoom, "- Join a chatroom");
	RegConsoleCmd("sm_join", Command_JoinChatRoom, "- Join a chatroom");

	//This stuff for FindTarget
	LoadTranslations("common.phrases");

	//Setting up the StringMap of Chatrooms
	g_mChatRooms = new StringMap();
	g_mChatRooms.Clear();
	g_mChatRooms.SetString("global", "0"); //Create Global Channel
}

public Action Command_JoinChatRoom(int client, int args)
{
	if(args < 1)
	{
		ReplyMessage(client, Msg_InvalidSyntaxJoin);
		return Plugin_Handled;
	}

	//If plugin disabled
	if(!g_bEnabled)
	{
		ReplyMessage(client, Msg_Disabled);
		return Plugin_Handled;
	}
	char szcsteam[64], temp[64];
	int csteam = GetSteamAccountID(client, true);
	IntToString(csteam, szcsteam, sizeof(szcsteam));

	//sm_cr <name> [password]
	char join[32];
	GetCmdArg(1, join, sizeof(join));

	if(StrEqual(join, "global", false))
	{
		if(g_mChatRooms.GetString(szcsteam, temp, sizeof(temp)))
		{
			//If player joining a room is in their own room, expell all people within
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(g_CurrentRoom[i] == csteam)
				{
					g_CurrentRoom[i] = 0;
					if(i != client) ReplyMessage(i, Msg_OwnerAbandon);
				}
			}

			g_mChatRooms.Remove(szcsteam);
			//Remove potential password listing as well
			Format(szcsteam, sizeof(szcsteam), "%s-pw", szcsteam);
			g_mChatRooms.Remove(szcsteam);
		}
		ReplyMessage(client, Msg_JoinRoom);
		return Plugin_Handled;
	}

	char pw[32];
	GetCmdArg(2, pw, sizeof(pw));

	//Get us a target
	int target = FindTarget(client, join, true, false);
	if(target == -1)
	{
		ReplyMessage(client, Msg_Target);
		return Plugin_Handled;
	}

	int steam = GetSteamAccountID(target, true);
	char szsteam[64];
	IntToString(steam, szsteam, sizeof(szsteam));


	//If Room does not exist
	if(!g_mChatRooms.GetString(szsteam, temp, sizeof(temp)))
	{
		ReplyMessage(client, Msg_NoRoom);
		return Plugin_Handled;
	}

	//Room exists, let's check for a password..
	//No password specified in arguments or invalid password
	Format(szsteam, sizeof(szsteam), "%s-pw", szsteam);
	if(g_mChatRooms.GetString(szsteam, temp, sizeof(temp)))
	{
		if(!StrEqual(temp, pw, false))
		{
			ReplyMessage(client, Msg_InvalidPassword);
			return Plugin_Handled;
		}
		else
		{
			if(g_mChatRooms.GetString(szcsteam, temp, sizeof(temp)))
			{
				//If player joining a room is in their own room, expell all people within
				for(int i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i)) continue;
					if(g_CurrentRoom[i] == csteam)
					{
						g_CurrentRoom[i] = 0;
						ReplyMessage(i, Msg_OwnerAbandon);
					}
				}

				g_mChatRooms.Remove(szcsteam);
				//Remove potential password listing as well
				Format(szcsteam, sizeof(szcsteam), "%s-pw", szcsteam);
				g_mChatRooms.Remove(szcsteam);
			}
			//If password is correct
			g_CurrentRoom[client] = steam;
			ReplyMessage(client, Msg_JoinRoom);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action Command_ChatRoomList(int client, int args)
{
	//If plugin disabled
	if(!g_bEnabled)
	{
		ReplyMessage(client, Msg_Disabled);
		return Plugin_Handled;
	}

	//Plugin is in admin-only mode and player is not admin:
	if(g_bAdminOnly)
	{
		if(!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		{
			ReplyMessage(client, Msg_AdminOnly);
			return Plugin_Handled;
		}
		//If admin-only and has admin
		else
		{
			int g = GetCountInRoom(0);
			PrintToConsole(client, "[Chatrooms] Room 0 - Global [%i Active]", g);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i)) continue;
				int steam = GetSteamAccountID(i, true);
				char szsteam[64], temp[64], name[MAX_NAME_LENGTH];
				IntToString(steam, szsteam, sizeof(szsteam));

				//If room exists, print out:
				if(g_mChatRooms.GetString(szsteam, temp, sizeof(temp)))
				{
					SteamAccountIDToName(steam, name, sizeof(name));
					int active = GetCountInRoom(steam);
					PrintToConsole(client, "[Chatrooms] Room %i - %s [%i Active]", i, name, active);
				}
			}
			return Plugin_Handled;
		}
	}

	//If it is not admin-only mode:
	int g = GetCountInRoom(0);
	PrintToConsole(client, "[Chatrooms] Room 0 - Global [%i Active]", g);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		int steam = GetSteamAccountID(i, true);
		char szsteam[64], temp[64], name[MAX_NAME_LENGTH];
		IntToString(steam, szsteam, sizeof(szsteam));

		//If room exists, print out:
		if(g_mChatRooms.GetString(szsteam, temp, sizeof(temp)))
		{
			SteamAccountIDToName(steam, name, sizeof(name));
			int active = GetCountInRoom(steam);
			PrintToConsole(client, "[Chatrooms] Room %i - %s [%i Active]", i, name, active);
		}
	}
	return Plugin_Handled;
}

public Action Command_CreateRoom(int client, int args)
{
	//Not sure why console would need to create a chatroom
	if(client == 0) return Plugin_Handled;

	//If plugin disabled
	if(!g_bEnabled)
	{
		ReplyMessage(client, Msg_Disabled);
		return Plugin_Handled;
	}

	char pw[32];
	GetCmdArg(1, pw, sizeof(pw));

	//Plugin is in admin-only mode and player is not admin:
	if(g_bAdminOnly)
	{
		if(!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		{
			ReplyMessage(client, Msg_AdminOnly);
			return Plugin_Handled;
		}
		//If admin-only and has admin
		else
		{
			CreateChatRoom(client, pw);
			return Plugin_Handled;
		}
	}

	//Not admin only mode..
	CreateChatRoom(client, pw)
	return Plugin_Handled;
}

//Actual chatroom functionality
public Action OnClientSayCommand(client, const char[] command, const char[] args)
{
	char msg[256];
	Format(msg, sizeof(msg), args);
	CRemoveTags(msg, 256);
	for(int i = 1; i <= MaxClients; i++)
	{
		bool isAdmin = CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC)
		if(!IsClientInGame(i)) continue;
		if((g_CurrentRoom[client] == g_CurrentRoom[i]) || (isAdmin && g_bAdminSpy))
		{
			char name[MAX_NAME_LENGTH + 16];

			//Format name coloring to kinda match up a lil bit
			if(g_eVersion == Engine_HL2DM)
			{
				switch(GetClientTeam(i))
				{
					//Spectator
					case 1: Format(name, sizeof(name), "{grey}%N{default} : ", i); 

					//Combine
					case 2: Format(name, sizeof(name), "{blue}%N{default} : ", i);

					//Rebel
					case 3: Format(name, sizeof(name), "{red}%N{default} : ", i);
				}
			}
			else if(g_eVersion == Engine_CSS || g_eVersion == Engine_DODS || g_eVersion == Engine_TF2)
			{
				switch(GetClientTeam(i))
				{
					//Spectator
					case 1: Format(name, sizeof(name), "{grey}%N{default} : ", i); 

					//Terrorist
					case 2: Format(name, sizeof(name), "{red}%N{default} : ", i);

					//Counter-Terrorist
					case 3: Format(name, sizeof(name), "{blue}%N{default} : ", i);
				}
			}
			else if(g_eVersion == Engine_CSGO)
			{
				switch(GetClientTeam(i))
				{
					//Spectator
					case 1: Format(name, sizeof(name), " \x01\x0B\x08%N :\x01 ", i); 

					//Terrorist
					case 2: Format(name, sizeof(name), " \x01\x0B\x10%N :\x01 ", i);

					//Counter-Terrorist
					case 3: Format(name, sizeof(name), " \x01\x0B\x0A%N :\x01 ", i);
				}
			}
			char chat[256];
			
			if(!isAdmin)
			{
				Format(chat, sizeof(chat), "%s %s", name, msg);
				CPrintToChat(i, chat);
			}
			else
			{
				char nspy[MAX_NAME_LENGTH];
				SteamAccountIDToName(g_CurrentRoom[client], nspy, sizeof(nspy));
				Format(chat, sizeof(chat), "[%s's Room] %s %s", nspy, name, msg);
				CPrintToChat(i, chat);
			}
		}
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	g_CurrentRoom[client] = 0;
}

public void OnClientDisconnect(int client)
{
	//Check if client had a room, if so set everyone to global room and delete room
	int steam = GetSteamAccountID(client, true);
	char szsteam[64], temp[64];
	IntToString(steam, szsteam, sizeof(szsteam));

	//Room exists
	if(g_mChatRooms.GetString(szsteam, temp, sizeof(temp)))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(g_CurrentRoom[i] == steam)
			{
				g_CurrentRoom[i] = 0;
				ReplyMessage(i, Msg_OwnerLeft);
			}
		}

		g_mChatRooms.Remove(szsteam);
		//Remove potential password listing as well
		Format(szsteam, sizeof(szsteam), "%s-pw", szsteam);
		g_mChatRooms.Remove(szsteam);
	}
}

public void OnConfigsExecuted()
{
	g_bEnabled = GetConVarBool(g_cvEnabled);
	g_bAdminOnly = GetConVarBool(g_cvAdminOnly);
}

public void cvChange_Spy(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int val = StringToInt(newValue);
	switch(val)
	{
		//Disabled:
		case 0: 
		{
			g_bAdminSpy = false;
		}

		//Enabled:
		case 1:
		{
			g_bAdminSpy = true;
		}

		default:
		{
			g_bAdminSpy = true;
		}
	}
}

public void cvChange_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int val = StringToInt(newValue);
	switch(val)
	{
		//Disabled:
		case 0: 
		{
			g_bEnabled = false;
		}

		//Enabled:
		case 1:
		{
			g_bEnabled = true;
		}

		default:
		{
			g_bEnabled = true;
		}
	}
}

public void cvChange_Admin(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int val = StringToInt(newValue);
	switch(val)
	{
		//Disabled:
		case 0: 
		{
			g_bAdminOnly = false;
		}

		//Enabled:
		case 1:
		{
			g_bAdminOnly = true;
		}

		default:
		{
			g_bAdminOnly = true;
		}
	}
}

public void ReplyMessage(int client, MsgCode message)
{
	if(!IsClientInGame(client)) ThrowError("ReplyMessage Reported Error - Invalid Client Index: %i", client);

	ReplyVersion version;
	if(g_eVersion == Engine_CSGO) version = Reply_CSGO;
	else version = Reply_GoodGames;

	switch(version)
	{
		case Reply_GoodGames:
		{
			switch(message)
			{
				case Msg_Unknown:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} An unknown error has occured.");
				}

				case Msg_AdminOnly:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} This command is currently only enabled for administrators.");
				}

				case Msg_Disabled:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} The plugin is currently disabled.");
				}

				case Msg_InvalidSyntaxJoin:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} Invalid Syntax: sm_cr <room> [password]");
				}

				case Msg_RoomExists:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} You have already created a room.");
				}

				case Msg_Created:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} You have created and entered a chatroom.");
				}

				case Msg_JoinRoom:
				{
					if(g_CurrentRoom[client] == 0)
					{
						CReplyToCommand(client, "{green}[Chatrooms]{default} You have joined {green}Global{default}.");
					}
					else
					{
						char name[MAX_NAME_LENGTH];
						SteamAccountIDToName(g_CurrentRoom[client], name, sizeof(name));
						CReplyToCommand(client, "{green}[Chatrooms]{default} You have joined {green}%s's{default} chatroom.", name);
					}
				}

				case Msg_Console:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} Open console for information.");
				}

				case Msg_Target:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} Invalid Target.");
				}

				case Msg_NoRoom:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} Room does not exist.");
				}

				case Msg_InvalidPassword:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} Invalid Password.");
				}

				case Msg_OwnerLeft:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} The owner has left the server. You have been moved to {green}Global{default}.");
				}

				case Msg_OwnerAbandon:
				{
					CReplyToCommand(client, "{green}[Chatrooms]{default} The owner has left the chatroom. You have been moved to {green}Global{default}.");
				}
			}
		}

		case Reply_CSGO:
		{
			switch(message)
			{
				case Msg_AdminOnly:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 This command is currently only enabled for administrators.");
				}

				case Msg_Disabled:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 The plugin is currently disabled.");
				}

				case Msg_InvalidSyntaxJoin:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 Invalid Syntax: sm_cr <room> [password]");
				}

				case Msg_RoomExists:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 You have already created a room.");
				}

				case Msg_Created:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 You have created and entered a chatroom.");
				}

				case Msg_JoinRoom:
				{
					if(g_CurrentRoom[client] == 0)
					{
						CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 You have joined \x04Global\x01.");
					}
					else
					{
						char name[MAX_NAME_LENGTH];
						SteamAccountIDToName(g_CurrentRoom[client], name, sizeof(name));
						CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 You have joined \x04%s's\x01 chatroom.", name);
					}
				}

				case Msg_Console:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 Open console for information.");
				}

				case Msg_Target:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 Invalid Target.");
				}

				case Msg_NoRoom:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 Room does not exist.");
				}

				case Msg_InvalidPassword:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 Invalid Password");
				}

				case Msg_OwnerLeft:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 The owner has left the server. You have been moved to \x04Global\x01.");
				}

				case Msg_OwnerAbandon:
				{
					CReplyToCommand(client, " \x01\x0B\x04[Chatrooms]\x01 The owner has left the chatroom. You have been moved to \x04Global\x01.");
				}
			}
		}
	}
}

public void CreateChatRoom(int client, const char[] pw)
{
	//Check if exists in StringMap...
	int steam = GetSteamAccountID(client, true);

	//This is technically an error, since nobody should have an account ID of zero
	if(steam == 0) 
	{
		ReplyMessage(client, Msg_Unknown);
		return;
	}

	char steamstr[64], temp[64]; 
	IntToString(steam, steamstr, sizeof(steamstr));

	bool exists = g_mChatRooms.GetString(steamstr, temp, sizeof(steamstr));
	if(exists)
	{
		ReplyMessage(client, Msg_RoomExists);
		return;
	}

	//Setup for a potentially passworded room..
	bool password;
	if(strlen(pw) < 1) password = false;
	else password = true;

	char pwfmt[128];
	Format(pwfmt, sizeof(pwfmt), "%s-pw", steamstr);

	//Create the room itself
	g_mChatRooms.SetString(steamstr, steamstr, false);
	if(password) g_mChatRooms.SetString(pwfmt, pw, false)

	ReplyMessage(client, Msg_Created);
	g_CurrentRoom[client] = steam;
}

public int GetCountInRoom(int steam)
{
	int count;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(g_CurrentRoom[i] == steam) count++;
	}
	return count;
}

stock bool SteamAccountIDToName(int accountid, char[] str, int maxlen)
{
	bool found = false;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(GetSteamAccountID(i, true) == accountid && accountid != 0)
		{
			char cname[MAX_NAME_LENGTH + 1];
			GetClientName(i, cname, maxlen);
			strcopy(str, maxlen, cname);
			found = true;
			break;
		}
	}

	return found;
}

public Plugin:myinfo =
{
	name = "Chatrooms",
	author = "Sidezz",
	description = "Create different chatrooms to reduce chatbox clutter",
	version = "1.1",
	url = "http://www.coldcommunity.com"
}