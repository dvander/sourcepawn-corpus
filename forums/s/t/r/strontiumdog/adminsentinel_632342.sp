//
// SourceMod Script
//
// Developed by <eVa>Dog
// May 2008
// http://www.theville.org
//


#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.2.100"

#define CHAT_SYMBOL '@'

#define SPEAK_NORMAL           	0   /**< Allow the client to listen and speak normally. */
#define SPEAK_MUTED            	1   /**< Mutes the client from speaking to everyone. */
#define SPEAK_ALL              	2   /**< Allow the client to speak to everyone. */
#define SPEAK_LISTENALL        	4   /**< Allow the client to listen to everyone. */
#define SPEAK_TALKLISTENALL    	6
#define SPEAK_TEAM          	8   /**< Allow the client to always speak to team, even when dead. */
#define SPEAK_LISTENTEAM    	16  /**< Allow the client to always hear teammates, including dead ones. */


/*
	Set Admin Level to one of these
		ADMFLAG_RESERVATION
		ADMFLAG_GENERIC
		ADMFLAG_KICK
		ADMFLAG_BAN
		ADMFLAG_UNBAN
		ADMFLAG_SLAY
		ADMFLAG_CHANGEMAP
		ADMFLAG_CONVARS
		ADMFLAG_CONFIG
		ADMFLAG_CHAT
		ADMFLAG_VOTE
		ADMFLAG_PASSWORD
		ADMFLAG_RCON
		ADMFLAG_CHEATS
		ADMFLAG_ROOT
		ADMFLAG_CUSTOM1
		ADMFLAG_CUSTOM2
		ADMFLAG_CUSTOM3
		ADMFLAG_CUSTOM4
		ADMFLAG_CUSTOM5
		ADMFLAG_CUSTOM6
*/

#define ADMIN_LEVEL ADMFLAG_BAN
#define ADMIN_WAR ADMFLAG_CUSTOM5
#define ADMIN_CHAT ADMFLAG_CHAT

new g_EnemyVoice[MAXPLAYERS+1]
new g_EnemyChat[MAXPLAYERS+1]
new g_AdminTalk[MAXPLAYERS+1]

new gametype = 0
new String:GameName[64]

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:Cvar_InitState = INVALID_HANDLE
new Handle:Cvar_Alltalk = INVALID_HANDLE
new Handle:Cvar_WarMode = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "AdminSentinel",
	author = "<eVa>StrontiumDog ",
	description = "Lets admins monitor all player chat",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_admin_sentinel_version", PLUGIN_VERSION, "AdminSentinel Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	Cvar_InitState = CreateConVar("sv_admin_sentinel_startup", "1", "When enabled, Enemy Voice Comms are automatically on for joining admin", FCVAR_PLUGIN)
	
	Cvar_WarMode = CreateConVar("sv_admin_sentinel_warmode", "0", "When enabled, Enemy Voice Comms are turned off for admins without the correct permissions", FCVAR_PLUGIN|FCVAR_NOTIFY)
	
	Cvar_Alltalk = FindConVar("sv_alltalk")
	HookConVarChange(Cvar_Alltalk, AlltalkChanged)
	HookConVarChange(Cvar_WarMode, WarModeChanged)
	
	RegAdminCmd("sm_enemyvoice", admin_enemyvoice, ADMIN_LEVEL, "sm_enemyvoice - toggles on/off enemy voice comm per admin")
	RegAdminCmd("sm_enemychat", admin_enemychat, ADMIN_LEVEL, "sm_enemychat - toggles on/off enemy chat per admin")
	RegAdminCmd("sm_talktoserver", admin_talktoserver, ADMIN_CHAT, "sm_talktoserver - allows an admin to talk to all players on the server")
	RegAdminCmd("sm_alltalk", admin_setalltalk, ADMIN_CHAT, "sm_alltalk - sets alltalk on or off")
	RegAdminCmd("admin_voice", admin_voice, ADMIN_CHAT, "admin_voice - admins can chat on their own channel")
	
	RegAdminCmd("sm_comms_war", admin_setwarmode, ADMIN_WAR, "sm_comms_war - toggles comms war mode on or off")
	
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_SayTeam)
	
	GetGameFolderName(GameName, sizeof(GameName))
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnMapStart()
{
	if (StrEqual(GameName, "tf"))
	{
		gametype = 1
	}
	else if (StrEqual(GameName, "cstrike"))
	{
		gametype = 1
	}
	else
	{
		gametype = 0
	}
}

public OnClientPostAdminCheck(client)
{
	if (client != 0)
	{
		if (GetConVarInt(Cvar_WarMode) == 1)
		{
			if ((GetUserFlagBits(client) & ADMIN_WAR) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if (GetConVarInt(Cvar_InitState))
				{
					SetClientListeningFlags(client, SPEAK_LISTENALL)
					g_EnemyVoice[client] = 1
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm enabled")
					g_EnemyChat[client] = 1
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy chat enabled")
				}
			}
			else
			{
				SetClientListeningFlags(client, SPEAK_NORMAL)
				g_EnemyVoice[client] = 0
				g_EnemyChat[client] = 0
			}
		}
		else
		{
			if ((GetUserFlagBits(client) & ADMIN_LEVEL) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if (GetConVarInt(Cvar_InitState))
				{
					SetClientListeningFlags(client, SPEAK_LISTENALL)
					g_EnemyVoice[client] = 1
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm enabled")
					g_EnemyChat[client] = 1
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy chat enabled")
				}
			}
			else
			{
				SetClientListeningFlags(client, SPEAK_NORMAL)
				g_EnemyVoice[client] = 0
				g_EnemyChat[client] = 0
			}
		}
	}
}

public Action:admin_setalltalk(client, args)
{
	if (GetConVarInt(Cvar_Alltalk) == 0)
	{
		ServerCommand("sv_alltalk 1")
	}
	else
	{
		ServerCommand("sv_alltalk 0")
	}
	return Plugin_Handled
}

public Action:admin_setwarmode(client, args)
{
	if (GetConVarInt(Cvar_WarMode) == 0)
	{
		SetConVarInt(Cvar_WarMode, 1, false, true)
	}
	else
	{
		SetConVarInt(Cvar_WarMode, 0, false, true)
	}
	return Plugin_Handled
}

public Action:admin_enemyvoice(client, args)
{
	if ((client > 0) && IsClientInGame(client))
	{
		if (GetConVarInt(Cvar_WarMode) == 1)
		{		
			if ((GetUserFlagBits(client) & ADMIN_WAR) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if(g_EnemyVoice[client] == 1)
				{
					g_EnemyVoice[client] = 0
					SetClientListeningFlags(client, SPEAK_NORMAL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm disabled")
					return Plugin_Handled
				}
				else if(g_EnemyVoice[client] == 0)
				{
					g_EnemyVoice[client] = 1
					SetClientListeningFlags(client, SPEAK_LISTENALL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm enabled")
					return Plugin_Handled
				}
			}
			else
			{
				ReplyToCommand(client, "[SM] You do not have access to this command")
			}
		}
		else
		{
			if ((GetUserFlagBits(client) & ADMIN_LEVEL) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if(g_EnemyVoice[client] == 1)
				{
					g_EnemyVoice[client] = 0
					SetClientListeningFlags(client, SPEAK_NORMAL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm disabled")
					return Plugin_Handled
				}
				else if(g_EnemyVoice[client] == 0)
				{
					g_EnemyVoice[client] = 1
					SetClientListeningFlags(client, SPEAK_LISTENALL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm enabled")
					return Plugin_Handled
				}
			}
		}
	}
	
	return Plugin_Continue
}

public Action:admin_enemychat(client, args)
{
	if ((client > 0) && IsClientInGame(client))
	{
		if (GetConVarInt(Cvar_WarMode) == 1)
		{
			if ((GetUserFlagBits(client) & ADMIN_WAR) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if(g_EnemyChat[client] == 1)
				{
					g_EnemyChat[client] = 0
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy chat disabled")
					return Plugin_Handled
				}
				else if(g_EnemyChat[client] == 0)
				{
					g_EnemyChat[client] = 1
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy chat enabled")
					return Plugin_Handled
				}
			}	
			else
			{
				ReplyToCommand(client, "[SM] You do not have access to this command")
			}
		}
		else
		{
			if ((GetUserFlagBits(client) & ADMIN_LEVEL) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if(g_EnemyChat[client] == 1)
				{
					g_EnemyChat[client] = 0
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy chat disabled")
					return Plugin_Handled
				}
				else if(g_EnemyChat[client] == 0)
				{
					g_EnemyChat[client] = 1
					PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy chat enabled")
					return Plugin_Handled
				}
			}
		}
	}

	return Plugin_Continue
}

public Action:admin_talktoserver(client, args)
{	
	if ((client > 0) && IsClientInGame(client))
	{
		if (GetConVarInt(Cvar_WarMode) == 1)
		{
			if ((GetUserFlagBits(client) & ADMIN_WAR) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if(g_AdminTalk[client] == 1 && g_EnemyVoice[client] == 0)
				{
					g_AdminTalk[client] = 0
					SetClientListeningFlags(client, SPEAK_NORMAL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is off")
					return Plugin_Handled
				}
				if(g_AdminTalk[client] == 1 && g_EnemyVoice[client] == 1)
				{
					g_AdminTalk[client] = 0
					SetClientListeningFlags(client, SPEAK_LISTENALL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is off")
					return Plugin_Handled
				}
				else if(g_AdminTalk[client] == 0)
				{
					g_AdminTalk[client] = 1
					SetClientListeningFlags(client, SPEAK_TALKLISTENALL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is on")
					return Plugin_Handled
				}
			}
			else
			{
				ReplyToCommand(client, "[SM] You do not have access to this command")
			}
		}
		else
		{
			if ((GetUserFlagBits(client) & ADMIN_LEVEL) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				if(g_AdminTalk[client] == 1 && g_EnemyVoice[client] == 0)
				{
					g_AdminTalk[client] = 0
					SetClientListeningFlags(client, SPEAK_NORMAL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is off")
					return Plugin_Handled
				}
				if(g_AdminTalk[client] == 1 && g_EnemyVoice[client] == 1)
				{
					g_AdminTalk[client] = 0
					SetClientListeningFlags(client, SPEAK_LISTENALL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is off")
					return Plugin_Handled
				}
				else if(g_AdminTalk[client] == 0)
				{
					g_AdminTalk[client] = 1
					SetClientListeningFlags(client, SPEAK_TALKLISTENALL)
					PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is on")
					return Plugin_Handled
				}
			}
		}
	}
	
	return Plugin_Continue
}

public Action:admin_voice(client, args)
{	
	new target;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: admin_voice <0|1>");
		return Plugin_Handled;
	}
	
	new String:szstate[16];
	GetCmdArg(1, szstate, sizeof(szstate));
	new iState = StringToInt(szstate);
	
	if ((client > 0) && IsClientInGame(client))
	{
		if (GetConVarInt(Cvar_WarMode) == 1)
		{
			if (iState == 1)
			{
				for (target=1; target <=MaxClients; target++)
				{
					if (IsClientInGame(target))
					{
						if (!(GetUserFlagBits(target) & ADMIN_WAR))
							SetListenOverride(target, client, Listen_No);
						else
							PrintToChat(target,"\x01\x04Admin Channel: \x03%N", client);
					}
				}
					
				return Plugin_Handled;
			}
			else 
			{
				for (target=1; target <=MaxClients; target++)
				{
					if (IsClientInGame(target))
					{
						if (!(GetUserFlagBits(target) & ADMIN_WAR))
							SetListenOverride(target, client, Listen_Default);
					}
				}
					
				return Plugin_Handled;
			}
		}
		else
		{
			if (iState == 1)
			{
				for (target=1; target <=MaxClients; target++)
				{
					if (IsClientInGame(target))
					{
						if ((GetUserFlagBits(target) & ADMIN_LEVEL))
							PrintToChat(target,"\x01\x04Admin Channel: \x03%N", client);
						else
							SetListenOverride(target, client, Listen_No);
							
					}
				}
				return Plugin_Handled;
			}
			else 
			{
				for (target=1; target <=MaxClients; target++)
				{
					if (IsClientInGame(target))
					{
						if (!(GetUserFlagBits(target) & ADMIN_LEVEL))
							SetListenOverride(target, client, Listen_Default);
					}
				}
					
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue
}

// ####################### MENUS #########################################################

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, "comms")

	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		player_commands = AddToTopMenu(
		hAdminMenu,		// Menu
		"comms",		// Name
		TopMenuObject_Category,	// Type
		Handle_Category,	// Callback
		INVALID_TOPMENUOBJECT	// Parent
		)
	}

	AddToTopMenu(hAdminMenu,
		"sm_enemyvoice",
		TopMenuObject_Item,
		AdminMenu_EnemyVoice,
		player_commands,
		"sm_enemyvoice",
		ADMIN_LEVEL)
		
	AddToTopMenu(hAdminMenu,
		"sm_enemychat",
		TopMenuObject_Item,
		AdminMenu_EnemyChat,
		player_commands,
		"sm_enemychat",
		ADMIN_LEVEL)
		
	AddToTopMenu(hAdminMenu,
		"sm_talktoserver",
		TopMenuObject_Item,
		AdminMenu_AdminVoice,
		player_commands,
		"sm_talktoserver",
		ADMIN_CHAT)
		
	AddToTopMenu(hAdminMenu,
		"sm_alltalk",
		TopMenuObject_Item,
		AdminMenu_AllTalk,
		player_commands,
		"sm_alltalk",
		ADMIN_CHAT)
		
	AddToTopMenu(hAdminMenu,
		"sm_comms_war",
		TopMenuObject_Item,
		AdminMenu_Warmode,
		player_commands,
		"sm_comms_war",
		ADMIN_WAR)
}
public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	switch( action )
	{
		case TopMenuAction_DisplayTitle:
			Format( buffer, maxlength, "Communications:" )
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "Comms Commands" )
	}
}
 
public AdminMenu_EnemyVoice(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (g_EnemyVoice[param] == 1) 
		{
			Format(buffer, maxlength, "Turn off Enemy VoiceComm")
		}
		else 
		{
			Format(buffer, maxlength, "Turn on Enemy VoiceComm")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_enemyvoice(param, ADMIN_LEVEL|ADMFLAG_ROOT)
	}
}

public AdminMenu_EnemyChat(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (g_EnemyChat[param] == 1) 
		{
			Format(buffer, maxlength, "Turn off Enemy Chat")
		}
		else 
		{
			Format(buffer, maxlength, "Turn on Enemy Chat")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_enemychat(param, ADMIN_LEVEL|ADMFLAG_ROOT)
	}
}

public AdminMenu_AdminVoice(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (g_AdminTalk[param] == 1) 
		{
			Format(buffer, maxlength, "Don't talk to all players")
		}
		else 
		{
			Format(buffer, maxlength, "Talk to all players")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_talktoserver(param, ADMIN_CHAT|ADMFLAG_ROOT)
	}
}

public AdminMenu_AllTalk(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (GetConVarInt(Cvar_Alltalk) == 0)
		{
			Format(buffer, maxlength, "Turn ON AllTalk")
		}
		else
		{
			Format(buffer, maxlength, "Turn OFF AllTalk")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_setalltalk(param, ADMIN_LEVEL|ADMFLAG_ROOT)
	}
}

public AdminMenu_Warmode(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (GetConVarInt(Cvar_WarMode) == 0)
		{
			Format(buffer, maxlength, "Turn ON War Comms Mode")
		}
		else
		{
			Format(buffer, maxlength, "Turn OFF War Comms Mode")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_setwarmode(param, ADMIN_WAR|ADMFLAG_ROOT)
	}
}

public AlltalkChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{		
	if (!GetConVarBool(Cvar_Alltalk))
	{
		new numofPlayers = GetClientCount(true)
		
		for (new i = 1; i <= numofPlayers; i++)
		{
			if (IsClientInGame(i))
			{
				if(g_EnemyVoice[i] == 1)
				{
					SetClientListeningFlags(i, SPEAK_LISTENALL)
					PrintToChat(i,"\x01\x04[AdminSentinel] Listening to enemy voice comm re-enabled")
				}
			}
		}
	}
}

public WarModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{		
	if (GetConVarBool(Cvar_WarMode))
	{
		new numofPlayers = GetClientCount(true)
		
		for (new i = 1; i <= numofPlayers; i++)
		{
			if (IsClientInGame(i))
			{
				if ((GetUserFlagBits(i) & ADMIN_WAR) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
				{
					if(g_EnemyVoice[i] == 1)
					{
						SetClientListeningFlags(i, SPEAK_LISTENALL)
						PrintToChat(i,"\x01\x04[AdminSentinel] War Mode on. Listening to enemy voice comm enabled")
					}
				}
				else if (GetUserFlagBits(i) & ADMIN_LEVEL)
				{
					SetClientListeningFlags(i, SPEAK_NORMAL)
					PrintToChat(i,"\x01\x04[AdminSentinel] War Mode on.  Listening to enemy voice comm disabled")
				}
			}
		}
	}
	else
	{
		new numofPlayers = GetClientCount(true)
		
		for (new i = 1; i <= numofPlayers; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetUserFlagBits(i) & ADMIN_LEVEL)
				{
					if(g_EnemyVoice[i] == 1)
					{
						SetClientListeningFlags(i, SPEAK_LISTENALL)
						PrintToChat(i,"\x01\x04[AdminSentinel] War Mode off. Listening to enemy voice comm enabled")
					}
				}
			}
		}
	}
}
	
	
public Action:Command_Say(client, args)
{
	new String:buffermsg[256]
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
			
	new String:name[32]
	GetClientName(client,name,31)

	if ((client > 0) && !IsPlayerAlive(client))
	{
		//dead
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && client != i)
			{
				if (GetConVarInt(Cvar_WarMode) == 1) 
				{
					if ((GetUserFlagBits(i) & ADMIN_WAR) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
					{
						if (g_EnemyChat[i] == 1 && !IsPlayerAlive(client) && gametype == 0)
						{
							if (gametype == 1)
							{
								Format(buffermsg, 256, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
								SayText2(i, client, buffermsg)
							}
							else
							{
								PrintToChat(i, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
							}
						}
					}
				}
				else
				{
					if ((GetUserFlagBits(i) & ADMIN_LEVEL) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
					{
						if (g_EnemyChat[i] == 1 && !IsPlayerAlive(client) && gametype == 0)
						{
							if (gametype == 1)
							{
								Format(buffermsg, 256, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
								SayText2(i, client, buffermsg)
							}
							else
							{
								PrintToChat(i, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
							}
						}
					}	
				}
			}
		}	
	}
	 
	// Added by MMX
	if (strcmp(text[startidx], "at", false) == 0 || strcmp(text[startidx], "/at", false) == 0 || strcmp(text[startidx], "alltalk", false) == 0)
	{
		if (Cvar_Alltalk != INVALID_HANDLE)
		{
			decl String:message[64];
			if (GetConVarBool(Cvar_Alltalk))
			{
				Format(message, sizeof(message), "%s", "All Talk On");
			}
			else			
			{
				Format(message, sizeof(message), "%s", "All Talk Off");
			}
			
			PrintToChatAll("[SM] %s", message);
		}
	}
	/* Let say continue normally */
	return Plugin_Continue
}

public Action:Command_SayTeam(client, args)
{	
	new String:buffermsg[256]
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
	
	if (text[startidx] == CHAT_SYMBOL)
	return Plugin_Continue
			
	new String:name[32]
	GetClientName(client,name,31)
	
	new senderteam = GetClientTeam(client)
	new team
	
	if ((client > 0) && IsPlayerAlive(client))
	{
		//alive
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{			
				if (GetConVarInt(Cvar_WarMode) == 1) 
				{
					if ((GetUserFlagBits(i) & ADMIN_WAR) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
					{
						team = GetClientTeam(i)
						
						if ((senderteam != team) && g_EnemyChat[i] == 1)
						{
							if (gametype == 1)
							{
								Format(buffermsg, 256, "\x01(TEAM) \x03%s\x05: %s", name, text[startidx])
								SayText2(i, client, buffermsg)
							}
							else
							{
								PrintToChat(i, "\x01(TEAM) \x03%s\x05: %s", name, text[startidx])
							}
						}
					}
				}
				else 
				{
					if ((GetUserFlagBits(i) & ADMIN_LEVEL) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
					{
						team = GetClientTeam(i)
						
						if ((senderteam != team) && g_EnemyChat[i] == 1)
						{
							if (gametype == 1)
							{
								Format(buffermsg, 256, "\x01(TEAM) \x03%s\x05: %s", name, text[startidx])
								SayText2(i, client, buffermsg)
							}
							else
							{
								PrintToChat(i, "\x01(TEAM) \x03%s\x05: %s", name, text[startidx])
							}
						}
					}
				}
			}
		}	
	}
	else 
	{
		//dead	
		for (new i=1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				if (GetConVarInt(Cvar_WarMode) == 1) 
				{
					if ((GetUserFlagBits(i) & ADMIN_WAR) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
					{
						team = GetClientTeam(i)
						
						if (g_EnemyChat[i] == 1 && senderteam != team)
						{
							if (gametype == 1)
							{
								Format(buffermsg, 256, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
								SayText2(i, client, buffermsg)
							}
							else
							{
								PrintToChat(i, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
							}
						}
					}
				}
				else
				{
					if ((GetUserFlagBits(i) & ADMIN_LEVEL) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
					{
						team = GetClientTeam(i)
						
						if (g_EnemyChat[i] == 1 && senderteam != team)
						{
							if (gametype == 1)
							{
								Format(buffermsg, 256, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
								SayText2(i, client, buffermsg)
							}
							else
							{
								PrintToChat(i, "\x01*DEAD* \x03%s\x05: %s", name, text[startidx])
							}
						}
					}
				}
			}
		}	
	}
	
	// Added by MMX
	if (strcmp(text[startidx], "at", false) == 0 || strcmp(text[startidx], "/at", false) == 0 || strcmp(text[startidx], "alltalk", false) == 0)
	{
		if (Cvar_Alltalk != INVALID_HANDLE)
		{
			decl String:message[64];
			if (GetConVarBool(Cvar_Alltalk))
			{
				Format(message, sizeof(message), "%s", "All Talk On");
			}
			else			
			{
				Format(message, sizeof(message), "%s", "All Talk Off");
			}
			
			PrintToChatAll("[SM] %s", message);
		}
	}
	/* Let say continue normally */
	return Plugin_Continue
}

public trim_quotes(String:text[])
{
	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	
	return startidx
}

stock SayText2(client_index, author_index, const String:message[] ) 
{
    new Handle:buffer = StartMessageOne("SayText2", client_index)
    if (buffer != INVALID_HANDLE) 
	{
        BfWriteByte(buffer, author_index)
        BfWriteByte(buffer, true)
        BfWriteString(buffer, message)
        EndMessage()
    }
} 

public Action:HUDText(String:info[256], String:x[8], String:y[8], String:channel[8], String:holdtime[8])
{
	new g_text4 = CreateEntityByName("game_text");
	new String:tname[13];
	Format(tname, 12, "game_text_%i", g_text4);
	DispatchKeyValue(g_text4,"targetname", tname);
	DispatchKeyValue(g_text4,"message", info);
	DispatchKeyValue(g_text4,"spawnflags", "1");
	DispatchKeyValue(g_text4,"channel", channel);
	DispatchKeyValue(g_text4,"holdtime", holdtime);
	DispatchKeyValue(g_text4,"fxtime", "0.25");
	DispatchKeyValue(g_text4,"fadeout", "0.5");
	DispatchKeyValue(g_text4,"fadein", "1.5");
	DispatchKeyValue(g_text4,"x", x);
	DispatchKeyValue(g_text4,"y", y);
	DispatchKeyValue(g_text4,"color", "255 255 255");
	DispatchKeyValue(g_text4,"color2", "0 110 240");
	DispatchKeyValue(g_text4,"effect", "0");
	DispatchSpawn(g_text4);
	AcceptEntityInput(g_text4, "Display");
	CreateTimer(10.0, kill_entity, g_text4);
}

public Action:kill_entity(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Kill");
	}
}