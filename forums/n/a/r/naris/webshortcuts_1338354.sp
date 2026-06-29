#include <sourcemod>
#include <adminmenu>
#include <sdktools_functions>

#pragma semicolon 1

#define PLUGIN_VERSION				"1.0.1"

public Plugin:myinfo = 
{
	name = "Web Shortcuts",
	author = "James \"sslice\" Gray",
	description = "Provides chat-triggered web shortcuts",
	version = PLUGIN_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:g_Shortcuts;
new Handle:g_Titles;
new Handle:g_Links;

new String:g_ServerIp [32];
new String:g_ServerPort [16];

new Handle:g_ClientPack[MAXPLAYERS];

public OnPluginStart()
{
	CreateConVar( "sm_webshortcuts_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED );
	
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");
	
	g_Shortcuts = CreateArray( 32 );
	g_Titles = CreateArray( 64 );
	g_Links = CreateArray( 512 );
	
	new Handle:cvar = FindConVar( "hostip" );
	new hostip = GetConVarInt( cvar );
	FormatEx( g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
		(hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF );
	
	cvar = FindConVar( "hostport" );
	GetConVarString( cvar, g_ServerPort, sizeof(g_ServerPort) );
	
	LoadTranslations("common.phrases");
	LoadWebshortcuts();
}
 
public OnMapEnd()
{
	LoadWebshortcuts();
}
 
public Action:OnSay(client, const String:command[], argc)
{
	decl String:cmd [512];
	GetCmdArgString( cmd, sizeof(cmd) );
	
	new start;
	new len = strlen(cmd);
	if ( cmd[len-1] == '"' )
	{
		cmd[len-1] = '\0';
		start = 1;
	}
	
	decl String:shortcut [32];
	new targetPos = BreakString( cmd[start], shortcut, sizeof(shortcut) );
	
	new size = GetArraySize( g_Shortcuts );
	for (new i; i != size; ++i)
	{
		decl String:text [512];
		GetArrayString( g_Shortcuts, i, text, sizeof(text) );
		
		if ( strcmp( shortcut, text, false ) == 0 )
		{
			decl String:title [64];
			decl String:steamId [64];
			decl String:friendId [64];
			decl String:userId [16];
			decl String:name [64];
			decl String:clientIp [32];
			
			GetArrayString( g_Titles, i, title, sizeof(title) );
			GetArrayString( g_Links, i, text, sizeof(text) );
			
			GetClientAuthString( client, steamId, sizeof(steamId) );
			FormatEx( userId, sizeof(userId), "%u", GetClientUserId( client ) );
			AuthIDToFriendID(steamId, friendId, sizeof(friendId));
			GetClientName( client, name, sizeof(name) );
			GetClientIP( client, clientIp, sizeof(clientIp) );
			
			ReplaceString( title, sizeof(title), "{SERVER_IP}", g_ServerIp);
			ReplaceString( title, sizeof(title), "{SERVER_PORT}", g_ServerPort);
			ReplaceString( title, sizeof(title), "{FRIEND_ID}", friendId);
			ReplaceString( title, sizeof(title), "{STEAM_ID}", steamId);
			ReplaceString( title, sizeof(title), "{USER_ID}", userId);
			ReplaceString( title, sizeof(title), "{NAME}", name);
			ReplaceString( title, sizeof(title), "{IP}", clientIp);
			
			ReplaceString( text, sizeof(text), "{SERVER_IP}", g_ServerIp);
			ReplaceString( text, sizeof(text), "{SERVER_PORT}", g_ServerPort);
			ReplaceString( text, sizeof(text), "{STEAM_ID}", steamId);
			ReplaceString( text, sizeof(text), "{USER_ID}", userId);
			ReplaceString( text, sizeof(text), "{NAME}", name);
			ReplaceString( text, sizeof(text), "{IP}", clientIp);

			if (StrContains(text, "{TARGET") >= 0)
			{
				new target=0;
				if (targetPos >= 0)
				{
					// The 2nd part of cmd is a target
					decl String:targetString [32];
					BreakString( cmd[targetPos], targetString, sizeof(targetString) );

					new bool:tn_is_ml;
					new list[1];
					new reason = ProcessTargetString(targetString, 0, list, sizeof(list),
									 COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI,
									 name, sizeof(name), tn_is_ml);
					if (reason < COMMAND_TARGET_NONE)
					{
						ReplyToTargetError(client,reason);
						return Plugin_Handled;
					}
					else if (reason > COMMAND_TARGET_NONE)
					{
						target=list[0];
						if (IsClientConnected(target) &&
						    GetClientAuthString(target,steamId,sizeof(steamId)))
						{
							FormatEx( userId, sizeof(userId), "%u", GetClientUserId( target ) );
							AuthIDToFriendID(steamId, friendId, sizeof(friendId));
							GetClientName(target, name, sizeof(name));
						}
						else
						{
							ReplyToTargetError(client,COMMAND_TARGET_NOT_IN_GAME);
							return Plugin_Handled;
						}
					}
				}
				else // No target specified
				{
					target = GetClientAimTarget(client,true);
					if (target > 0)
					{
						if (IsClientConnected(target) &&
						    GetClientAuthString(target,steamId,sizeof(steamId)))
						{
							FormatEx( userId, sizeof(userId), "%u", GetClientUserId( target ) );
							AuthIDToFriendID(steamId, friendId, sizeof(friendId));
							GetClientName(target, name, sizeof(name));
						}
						else
							target = 0;
					}
				}

				if (target > 0)
				{
					ReplaceString( text, sizeof(text), "{TARGET_NAME}", name);
					ReplaceString( text, sizeof(text), "{TARGET_USER_ID}", userId);
					ReplaceString( text, sizeof(text), "{TARGET_STEAM_ID}", steamId);
					ReplaceString( text, sizeof(text), "{TARGET_FRIEND_ID}", friendId);
				}
				else
				{
					if (g_ClientPack[client] != INVALID_HANDLE)
						CloseHandle(g_ClientPack[client]);

					new Handle:pack = CreateDataPack();
					WritePackString(pack, title);
					WritePackString(pack, text);
					g_ClientPack[client] = pack;

					// Display a menu for the user to pick a target
					new Handle:menu=CreateMenu(View_Selected);
					SetMenuTitle(menu,"Select a player for %s:", title);
					SetMenuExitButton(menu,true);
					AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_IMMUNITY);
					DisplayMenu(menu,client,MENU_TIME_FOREVER);
					return Plugin_Handled;
				}
			}

			ShowMOTDPanel( client, title, text, MOTDPANEL_TYPE_URL );
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;	
}

public View_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if (action == MenuAction_Select)
	{
		new Handle:pack = g_ClientPack[client];
		if (pack != INVALID_HANDLE)
		{
			decl String:title [64];
			decl String:text [512];
			ResetPack(pack);
			ReadPackString(pack, title, sizeof(title));
			ReadPackString(pack, text, sizeof(text));
			CloseHandle(pack);
			g_ClientPack[client] = INVALID_HANDLE;

			new userid, target;
			decl String:SelectionInfo[12];
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
			userid=StringToInt(SelectionInfo);
			if ((target = GetClientOfUserId(userid)) == 0)
				PrintToChat(client, "Player no longer available");
			else
			{
				decl String:steamId [64];
				if (IsClientConnected(target) &&
				    GetClientAuthString(target,steamId,sizeof(steamId)))
				{
					decl String:friendId [64];
					decl String:userId [16];
					decl String:name [64];
					FormatEx( userId, sizeof(userId), "%u", GetClientUserId( target ) );
					AuthIDToFriendID(steamId, friendId, sizeof(friendId));
					GetClientName(target, name, sizeof(name));

					ReplaceString( text, sizeof(text), "{TARGET_NAME}", name);
					ReplaceString( text, sizeof(text), "{TARGET_USER_ID}", userId);
					ReplaceString( text, sizeof(text), "{TARGET_STEAM_ID}", steamId);
					ReplaceString( text, sizeof(text), "{TARGET_FRIEND_ID}", friendId);
					ShowMOTDPanel( client, title, text, MOTDPANEL_TYPE_URL );
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);

		if (client > 0 && client < MAXPLAYERS)
		{
			new Handle:pack = g_ClientPack[client];
			if (pack != INVALID_HANDLE)
			{
				CloseHandle(pack);
				g_ClientPack[client] = INVALID_HANDLE;
			}
		}
	}
}

LoadWebshortcuts()
{
	decl String:buffer [1024];
	BuildPath( Path_SM, buffer, sizeof(buffer), "configs/webshortcuts.txt" );

	if ( !FileExists( buffer ) )
	{
		return;
	}

	new Handle:f = OpenFile( buffer, "r" );
	if ( f == INVALID_HANDLE )
	{
		LogError( "[SM] Could not open file: %s", buffer );
		return;
	}

	ClearArray( g_Shortcuts );
	ClearArray( g_Titles );
	ClearArray( g_Links );

	decl String:shortcut [32];
	decl String:title [64];
	decl String:link [512];
	while ( !IsEndOfFile( f ) && ReadFileLine( f, buffer, sizeof(buffer) ) )
	{
		TrimString( buffer );
		if ( buffer[0] == '\0' || buffer[0] == ';' || ( buffer[0] == '/' && buffer[1] == '/' ) )
		{
			continue;
		}

		new pos = BreakString( buffer, shortcut, sizeof(shortcut) );
		if ( pos == -1 )
		{
			continue;
		}

		new linkPos = BreakString( buffer[pos], title, sizeof(title) );
		if ( linkPos == -1 )
		{
			continue;
		}

		strcopy( link, sizeof(link), buffer[linkPos+pos] );
		TrimString( link );

		PushArrayString( g_Shortcuts, shortcut );
		PushArrayString( g_Titles, title );
		PushArrayString( g_Links, link );
	}

	CloseHandle( f );
}

AuthIDToFriendID(String:AuthID[], String:FriendID[], size) 
{
    ReplaceString(AuthID, strlen(AuthID), "STEAM_", "");
    if (StrEqual(AuthID, "ID_LAN"))
    {
        FriendID[0] = '\0';
        return false;
    }

    decl String:toks[3][16];
    ExplodeString(AuthID, ":", toks, sizeof(toks), sizeof(toks[]));

    new iServer = StringToInt(toks[1]);
    new iAuthID = StringToInt(toks[2]);
    new iFriendID = (iAuthID*2) + 60265728 + iServer;
    
    if (iFriendID >= 100000000)
    {
	decl String:temp[12], String:carry[12];
        Format(temp, sizeof(temp), "%d", iFriendID);
        Format(carry, 2, "%s", temp);
        new icarry = StringToInt(carry[0]);
	new upper = 765611979 + icarry;
        
        Format(temp, sizeof(temp), "%d", iFriendID);
        Format(FriendID, size, "%d%s", upper, temp[1]);
    }
    else
    {
        Format(FriendID, size, "765611979%d", iFriendID);
    }
    
    return true;
}
