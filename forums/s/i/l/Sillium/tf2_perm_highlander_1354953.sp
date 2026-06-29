#include <sourcemod>
#include <clientprefs.inc>

#define PLUGIN_NAME 		"TF2 Permanent Highlander Vote"
#define PLUGIN_AUTHOR 		"Sillium"
#define PLUGIN_VERSION 		"0.0.4b"

#define HIGHLANDER_UNDEF -1
#define HIGHLANDER_ON  1
#define HIGHLANDER_OFF 2

public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= "[TF2] Saves highlander preference of the players and sets highlander on or off depending on peoples preference",
	version 		= PLUGIN_VERSION,
	url 			= "http://forums.alliedmods.net/showthread.php?t=130179"
}


new Handle:g_highlanderCookie= INVALID_HANDLE;
new g_ClientCookies[MAXPLAYERS + 1];

new bool:g_bFirstClientConnected = false;
new bool:g_bVoteFinished = false;

new Handle:g_hCvarPercent= INVALID_HANDLE;
new	Handle:g_hCvarShowInfo = INVALID_HANDLE;
new	Handle:g_hCvarTFHighlander = INVALID_HANDLE;
new	Handle:g_hCvarAnnounceDelay = INVALID_HANDLE;
new	Handle:g_hCvarCalcDelay = INVALID_HANDLE;
new	Handle:g_hCvarPreferenceQuestionDelay = INVALID_HANDLE;



public OnPluginStart()
{
	CreateConVar("tf2_perm_highlander_version", PLUGIN_VERSION, "TF2 Permanent Highlander Vote Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hCvarPercent = CreateConVar("tf2_perm_highlander_percent", "0.5", "Percentage of people who need to vote for highlander on in order to activate highlander", 0, true, 0.01, true, 1.0);
	g_hCvarShowInfo = CreateConVar("tf2_perm_highlander_show_info", "1", "Show information if highlander are on/off to late joiners");

	g_hCvarAnnounceDelay = CreateConVar("tf2_perm_highlander_info_delay", "30.0", "Delay between late joining the server and announcing if highlander are on/off");
	g_hCvarCalcDelay = CreateConVar("tf2_perm_highlander_calc_delay", "30.0", "Delay between late joining the server and announcing if highlander are on/off");
	g_hCvarPreferenceQuestionDelay = CreateConVar("tf2_perm_highlander_pref_delay", "25.0", "Delay between joing the server and asking the player for his preference if it is not set. Should be shorter that the calc delay");
	
	g_hCvarTFHighlander = FindConVar("mp_highlander");
	
	AutoExecConfig(true, "plugin.tf2_perm_highlander")

	g_highlanderCookie = RegClientCookie("tf2_perm_highlander", "Players highlander Preference", CookieAccess_Public);		
	RegConsoleCmd( "highlander", HighlanderMenu );
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		g_ClientCookies[i] = HIGHLANDER_UNDEF;
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
		//wait 30 seconds before calculation if we have highlander on or off
	   CreateTimer(GetConVarFloat(g_hCvarCalcDelay), CalcHighlander);
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
		if(INVALID_HANDLE != g_hCvarTFHighlander)
		{
			if(GetConVarBool(g_hCvarTFHighlander))
			{
				PrintToChat(client, "\x04[\x03TF2-Highlander Pref\x04]\x01 Highlander Enabled.");
			}
			else
			{
				PrintToChat(client, "\x04[\x03TF2-Highlander Pref\x04]\x01 Highlander Disabled.");
			}
		}
	}
}

public OnClientDisconnect(client)
{
	//remove the old client preference
	g_ClientCookies[client] = HIGHLANDER_UNDEF;
}

public OnClientCookiesCached(client)
{
	decl String:sEnabled[2];
	GetClientCookie(client, g_highlanderCookie, sEnabled, sizeof(sEnabled));
	new enabled = StringToInt(sEnabled);
	
	//not a valid value (if this is the first time a client connects the cookie value is not set or 0)
	if( 1 > enabled || 2 < enabled)
	{
		//the value is not valid ( not 1 or 2 ), create a timer and ask client for his preference
		g_ClientCookies[client] = HIGHLANDER_UNDEF;
		new Handle:clientPack = CreateDataPack();
		//write clientId to cell to only show vote menu to this client later
		WritePackCell(clientPack, client);
		CreateTimer(GetConVarFloat(g_hCvarPreferenceQuestionDelay), HighlanderMenuTimer, clientPack);
	}
	else
	{
		//client has a valid cookie, remember the value for later calculation
		g_ClientCookies[client] = enabled;
	}
}

public Action:HighlanderMenuTimer(Handle:timer, any:clientpack)
{
	decl clientId;
	ResetPack(clientpack);
	//read the clientId we saved earlier
	clientId = ReadPackCell(clientpack);
	CloseHandle(clientpack);

	HighlanderMenu(clientId, 0);
}


public Action:HighlanderMenu( client, args )
{

	//refresh our cache
	decl String:sEnabled[2];
	GetClientCookie(client, g_highlanderCookie, sEnabled, sizeof(sEnabled));
	g_ClientCookies[client] = StringToInt(sEnabled);	
	
	//build the menu
	new Handle:menu = CreateMenu(MenuHandlerHighlander);
	SetMenuTitle(menu, "Set Highlander preference");
	AddMenuItem(menu, "Highlander pref", "Prefer Highlander on");
	AddMenuItem(menu, "Highlander pref", "Prefer Highlander off");
 
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandlerHighlander(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		//we make an offset of 1 to prevent the default value 0 in the cookies to be counted
		decl String:sEnabled[2];
		new choice = param2 + 1;

		g_ClientCookies[param1] = choice;
		IntToString(choice, sEnabled, sizeof(sEnabled));
		
		//save it to a cookie
		SetClientCookie(param1, g_highlanderCookie, sEnabled);
		
		if(1 == choice)
		{
			PrintToChat(param1, "\x04[\x03TF2-Highlander Pref\x04]\x01 You selected Highlander enabled");
		}
		else if(2 == choice)
		{
			PrintToChat(param1, "\x04[\x03TF2-Highlander Pref\x04]\x01 You selected Highlander disabled");
		}
	} 
	else if(action == MenuAction_End)
	{
	   CloseHandle(menu);
	}
}

public Action:CalcHighlander(Handle:timer)
{
	new prefYes = 0;
	new prefNo = 0;
	new numPlayers = 0;
	new Float:percentage = GetConVarFloat(g_hCvarPercent);
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		//HIGHLANDER on
		if(HIGHLANDER_ON == g_ClientCookies[i])
		{
			prefYes++;
			numPlayers++;
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
			   //show the current set preference to the client
			   PrintToChat(i, "\x04[\x03TF2-Highlander Pref\x04]\x01 Your preference is set to: Highlander enabled");
			}
		}
		//HIGHLANDER off
		else if(HIGHLANDER_OFF == g_ClientCookies[i])
		{
			prefNo++;
			numPlayers++;
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
			   //show the current set preference to the client
			   PrintToChat(i, "\x04[\x03TF2-Highlander Pref\x04]\x01 Your preference is set to: Highlander disabled");
			}
		}
	}
	
	//for debug
	//PrintToChatAll("CalcHighlander: prefYes %d prefNo %d numPlayers %d percentage %f (prefYes/numPlayers) %f",prefYes,prefNo,numPlayers,percentage, (float(prefYes) / float(numPlayers)));
	
	
	//did more people than needed vote for highlander on?
	if ((float(prefYes) / float(numPlayers)) >= percentage)
	{
		ServerCommand("mp_highlander 1");
		PrintToChatAll("\x04[\x03TF2-Highlander Pref\x04]\x01 Highlander Enabled. %d Voted On, %d voted Off", prefYes, prefNo);
	}
	else
	{
		PrintToChatAll("\x04[\x03TF2-Highlander Pref\x04]\x01 Highlander Disabled. %d Voted On, %d voted Off", prefYes, prefNo);
		ServerCommand("mp_highlander 0");
	}
	
	//remind everybody how to change the preference
	PrintToChatAll("\x04[\x03TF2-Highlander Pref\x04]\x01 To change your preference say \x04!highlander");
	
	g_bVoteFinished = true;
}
