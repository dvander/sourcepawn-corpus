#include <sourcemod>
#include <clientprefs.inc>

#define PLUGIN_NAME 		"Permanent Alltalk vote"
#define PLUGIN_AUTHOR 		"Sillium"
#define PLUGIN_VERSION 		"0.0.4b"

#define ALLTALK_UNDEF -1
#define ALLTALK_ON  1
#define ALLTALK_OFF 2

public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= "Saves alltalk preference of the players and sets alltalk on or off depending on peoples preference",
	version 		= PLUGIN_VERSION,
	url 			= "http://forums.alliedmods.net/showthread.php?t=133710"
}


new Handle:g_alltalkCookie= INVALID_HANDLE;
new g_ClientCookies[MAXPLAYERS + 1];

new bool:g_bFirstClientConnected = false;
new bool:g_bVoteFinished = false;

new Handle:g_hCvarPercent= INVALID_HANDLE;
new	Handle:g_hCvarShowInfo = INVALID_HANDLE;
new	Handle:g_hCvarAlltalk = INVALID_HANDLE;
new	Handle:g_hCvarAnnounceDelay = INVALID_HANDLE;
new	Handle:g_hCvarAlltalkDelay = INVALID_HANDLE;
new	Handle:g_hCvarPreferenceQuestionDelay = INVALID_HANDLE;



public OnPluginStart()
{
	CreateConVar("perm_alltalk_version", PLUGIN_VERSION, "TF2 Permanent Alltalk Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hCvarPercent = CreateConVar("perm_alltalk_percent", "0.5", "Percentage of people who need to vote for alltalk on in order to activate alltalk", 0, true, 0.01, true, 1.0);
	g_hCvarShowInfo = CreateConVar("perm_alltalk_show_info", "1", "Show information if alltalk is on/off to late joiners");

	g_hCvarAnnounceDelay = CreateConVar("perm_alltalk_info_delay", "30.0", "Delay between late joining the server and announcing if alltalk is on/off");
	g_hCvarAlltalkDelay = CreateConVar("perm_alltalk_calc_delay", "30.0", "Delay between late joining the server and announcing if alltalk is on/off");
	g_hCvarPreferenceQuestionDelay = CreateConVar("perm_alltalk_pref_delay", "25.0", "Delay between joing the server and asking the player for his preference if it is not set. Should be shorter that the calc delay");
	
	g_hCvarAlltalk = FindConVar("sv_alltalk");
	
	AutoExecConfig(true, "plugin.perm_alltalk")

	g_alltalkCookie = RegClientCookie("perm_alltalk", "Players Alltalk Preference", CookieAccess_Public);		
	RegConsoleCmd( "alltalk", AlltalkMenu );
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		g_ClientCookies[i] = ALLTALK_UNDEF;
	}
	
}

public OnMapStart()
{
	//we wait with the calculation till someone is really here to play
	g_bFirstClientConnected = false;
}

public OnClientPostAdminCheck(client)
{
	if (!g_bFirstClientConnected)
	{
		//wait 30 seconds before calculation if we have alltalk on or off
	   CreateTimer(GetConVarFloat(g_hCvarAlltalkDelay), CalcAlltalk);
	   g_bFirstClientConnected = true;
	}
	else if(GetConVarBool(g_hCvarShowInfo) && g_bVoteFinished)
	{
		CreateTimer(GetConVarFloat(g_hCvarAnnounceDelay), TimerAnnounce, client);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(INVALID_HANDLE != g_hCvarAlltalk)
		{
			if(GetConVarBool(g_hCvarAlltalk))
			{
				PrintToChat(client, "\x04[\x03Alltalk Pref\x04]\x01 Alltalk Enabled.");
			}
			else
			{
				PrintToChat(client, "\x04[\x03Alltalk Pref\x04]\x01 Alltalk Disabled.");
			}
		}
	}
}

public OnClientDisconnect(client)
{
	//remove the old client preference
	g_ClientCookies[client] = ALLTALK_UNDEF;
}

public OnClientCookiesCached(client)
{
	decl String:sEnabled[2];
	GetClientCookie(client, g_alltalkCookie, sEnabled, sizeof(sEnabled));
	new enabled = StringToInt(sEnabled);
	
	//not a valid value (if this is the first time a client connects the cookie value is not set or 0)
	if( 1 > enabled || 2 < enabled)
	{
		//the value is not valid ( not 1 or 2 ), create a timer and ask client for his preference
		g_ClientCookies[client] = ALLTALK_UNDEF;
		new Handle:clientPack = CreateDataPack();
		//write clientId to cell to only show vote menu to this client later
		WritePackCell(clientPack, client);
		CreateTimer(GetConVarFloat(g_hCvarPreferenceQuestionDelay), AlltalkMenuTimer, clientPack);
	}
	else
	{
		//client has a valid cookie, remember the value for later calculation
		g_ClientCookies[client] = enabled;
	}
}

public Action:AlltalkMenuTimer(Handle:timer, any:clientpack)
{
	decl clientId;
	ResetPack(clientpack);
	//read the clientId we saved earlier
	clientId = ReadPackCell(clientpack);
	CloseHandle(clientpack);

	AlltalkMenu(clientId, 0);
}


public Action:AlltalkMenu( client, args )
{

	//refresh our cache
	decl String:sEnabled[2];
	GetClientCookie(client, g_alltalkCookie, sEnabled, sizeof(sEnabled));
	g_ClientCookies[client] = StringToInt(sEnabled);	
	
	//build the menu
	new Handle:menu = CreateMenu(MenuHandlerAlltalk);
	SetMenuTitle(menu, "Set Alltalk preference");
	AddMenuItem(menu, "Alltalk pref", "Prefer Alltalk on");
	AddMenuItem(menu, "Alltalk pref", "Prefer Alltalk off");
 
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandlerAlltalk(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		//we make an offset of 1 to prevent the default value 0 in the cookies to be counted
		decl String:sEnabled[2];
		new choice = param2 + 1;

		g_ClientCookies[param1] = choice;
		IntToString(choice, sEnabled, sizeof(sEnabled));
		
		//save it to a cookie
		SetClientCookie(param1, g_alltalkCookie, sEnabled);
		
		if(1 == choice)
		{
			PrintToChat(param1, "\x04[\x03Alltalk Pref\x04]\x01 You selected Alltalk enabled");
		}
		else if(2 == choice)
		{
			PrintToChat(param1, "\x04[\x03Alltalk Pref\x04]\x01 You selected Alltalk disabled");
		}
	} 
	else if(action == MenuAction_End)
	{
	   CloseHandle(menu);
	}
}

public Action:CalcAlltalk(Handle:timer)
{
	new prefYes = 0;
	new prefNo = 0;
	new numPlayers = 0;
	new Float:percentage = GetConVarFloat(g_hCvarPercent);
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		//Alltalk on
		if(ALLTALK_ON == g_ClientCookies[i])
		{
			prefYes++;
			numPlayers++;
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
			   //show the current set preference to the client
			   PrintToChat(i, "\x04[\x03Alltalk Pref\x04]\x01 Your preference is set to: Alltalk enabled");
			}
		}
		//Alltalk off
		else if(ALLTALK_OFF == g_ClientCookies[i])
		{
			prefNo++;
			numPlayers++;
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
			   //show the current set preference to the client
			   PrintToChat(i, "\x04[\x03Alltalk Pref\x04]\x01 Your preference is set to: Alltalk disabled");
			}
		}
	}
	
	//for debug
	//PrintToChatAll("CalcAlltalk: prefYes %d prefNo %d numPlayers %d percentage %f (prefYes/numPlayers) %f",prefYes,prefNo,numPlayers,percentage, (float(prefYes) / float(numPlayers)));
	
	
	//did more people than needed vote for Alltalk on?
	if ((float(prefYes) / float(numPlayers)) >= percentage)
	{
		ServerCommand("sv_alltalk 1");
		PrintToChatAll("\x04[\x03Alltalk Pref\x04]\x01 Alltalk Enabled. %d Voted On, %d voted Off", prefYes, prefNo);
	}
	else
	{
		PrintToChatAll("\x04[\x03Alltalk Pref\x04]\x01 Alltalk Disabled. %d Voted On, %d voted Off", prefYes, prefNo);
		ServerCommand("sv_alltalk 0");
	}
	
	//remind everybody how to change the preference
	PrintToChatAll("\x04[\x03Alltalk Pref\x04]\x01 To change your preference say \x04!alltalk");
	
	g_bVoteFinished = true;
}