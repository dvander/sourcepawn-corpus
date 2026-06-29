#include <sourcemod>
#include <clientprefs.inc>

#define PLUGIN_NAME 		"TF2 Permanent Critvote"
#define PLUGIN_AUTHOR 		"Sillium"
#define PLUGIN_VERSION 		"0.0.4b"

#define CRITS_UNDEF -1
#define CRITS_ON  1
#define CRITS_OFF 2

public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= "[TF2] Saves crit preference of the players and sets crit on or off depending on peoples preference",
	version 		= PLUGIN_VERSION,
	url 			= "http://forums.alliedmods.net/showthread.php?t=130179"
}


new Handle:g_critCookie= INVALID_HANDLE;
new g_ClientCookies[MAXPLAYERS + 1];

new bool:g_bFirstClientConnected = false;
new bool:g_bVoteFinished = false;

new Handle:g_hCvarPercent= INVALID_HANDLE;
new	Handle:g_hCvarShowInfo = INVALID_HANDLE;
new	Handle:g_hCvarTFCrtiticals = INVALID_HANDLE;
new	Handle:g_hCvarAnnounceDelay = INVALID_HANDLE;
new	Handle:g_hCvarCalcDelay = INVALID_HANDLE;
new	Handle:g_hCvarPreferenceQuestionDelay = INVALID_HANDLE;



public OnPluginStart()
{
	CreateConVar("tf2_perm_crit_version", PLUGIN_VERSION, "TF2 Permanent Critvote Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hCvarPercent = CreateConVar("tf2_perm_crit_percent", "0.5", "Percentage of people who need to vote for Crits on in order to activate crits", 0, true, 0.01, true, 1.0);
	g_hCvarShowInfo = CreateConVar("tf2_perm_crit_show_info", "1", "Show information if Crits are on/off to late joiners");

	g_hCvarAnnounceDelay = CreateConVar("tf2_perm_crit_info_delay", "30.0", "Delay between late joining the server and announcing if Crits are on/off");
	g_hCvarCalcDelay = CreateConVar("tf2_perm_crit_calc_delay", "30.0", "Delay between late joining the server and announcing if Crits are on/off");
	g_hCvarPreferenceQuestionDelay = CreateConVar("tf2_perm_crit_pref_delay", "25.0", "Delay between joing the server and asking the player for his preference if it is not set. Should be shorter that the calc delay");
	
	g_hCvarTFCrtiticals = FindConVar("tf_weapon_criticals");
	
	AutoExecConfig(true, "plugin.tf2_perm_crit")

	g_critCookie = RegClientCookie("tf2_perm_crit", "Players Crit Preference", CookieAccess_Public);		
	RegConsoleCmd( "crit", CritMenu );
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		g_ClientCookies[i] = CRITS_UNDEF;
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
		//wait 30 seconds before calculation if we have crit on or off
	   CreateTimer(GetConVarFloat(g_hCvarCalcDelay), CalcCrit);
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
		if(INVALID_HANDLE != g_hCvarTFCrtiticals)
		{
			if(GetConVarBool(g_hCvarTFCrtiticals))
			{
				PrintToChat(client, "\x04[\x03TF2-Crit Pref\x04]\x01 Crits Enabled.");
			}
			else
			{
				PrintToChat(client, "\x04[\x03TF2-Crit Pref\x04]\x01 Crits Disabled.");
			}
		}
	}
}

public OnClientDisconnect(client)
{
	//remove the old client preference
	g_ClientCookies[client] = CRITS_UNDEF;
}

public OnClientCookiesCached(client)
{
	decl String:sEnabled[2];
	GetClientCookie(client, g_critCookie, sEnabled, sizeof(sEnabled));
	new enabled = StringToInt(sEnabled);
	
	//not a valid value (if this is the first time a client connects the cookie value is not set or 0)
	if( 1 > enabled || 2 < enabled)
	{
		//the value is not valid ( not 1 or 2 ), create a timer and ask client for his preference
		g_ClientCookies[client] = CRITS_UNDEF;
		new Handle:clientPack = CreateDataPack();
		//write clientId to cell to only show vote menu to this client later
		WritePackCell(clientPack, client);
		CreateTimer(GetConVarFloat(g_hCvarPreferenceQuestionDelay), CritMenuTimer, clientPack);
	}
	else
	{
		//client has a valid cookie, remember the value for later calculation
		g_ClientCookies[client] = enabled;
	}
}

public Action:CritMenuTimer(Handle:timer, any:clientpack)
{
	decl clientId;
	ResetPack(clientpack);
	//read the clientId we saved earlier
	clientId = ReadPackCell(clientpack);
	CloseHandle(clientpack);

	CritMenu(clientId, 0);
}


public Action:CritMenu( client, args )
{

	//refresh our cache
	decl String:sEnabled[2];
	GetClientCookie(client, g_critCookie, sEnabled, sizeof(sEnabled));
	g_ClientCookies[client] = StringToInt(sEnabled);	
	
	//build the menu
	new Handle:menu = CreateMenu(MenuHandlerCrit);
	SetMenuTitle(menu, "Set Crits preference");
	AddMenuItem(menu, "Crit pref", "Prefer Crits on");
	AddMenuItem(menu, "Crit pref", "Prefer Crits off");
 
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandlerCrit(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		//we make an offset of 1 to prevent the default value 0 in the cookies to be counted
		decl String:sEnabled[2];
		new choice = param2 + 1;

		g_ClientCookies[param1] = choice;
		IntToString(choice, sEnabled, sizeof(sEnabled));
		
		//save it to a cookie
		SetClientCookie(param1, g_critCookie, sEnabled);
		
		if(1 == choice)
		{
			PrintToChat(param1, "\x04[\x03TF2-Crit Pref\x04]\x01 You selected Crits enabled");
		}
		else if(2 == choice)
		{
			PrintToChat(param1, "\x04[\x03TF2-Crit Pref\x04]\x01 You selected Crits disabled");
		}
	} 
	else if(action == MenuAction_End)
	{
	   CloseHandle(menu);
	}
}

public Action:CalcCrit(Handle:timer)
{
	new prefYes = 0;
	new prefNo = 0;
	new numPlayers = 0;
	new Float:percentage = GetConVarFloat(g_hCvarPercent);
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		//crits on
		if(CRITS_ON == g_ClientCookies[i])
		{
			prefYes++;
			numPlayers++;
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
			   //show the current set preference to the client
			   PrintToChat(i, "\x04[\x03TF2-Crit Pref\x04]\x01 Your preference is set to: Crits enabled");
			}
		}
		//crits off
		else if(CRITS_OFF == g_ClientCookies[i])
		{
			prefNo++;
			numPlayers++;
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
			   //show the current set preference to the client
			   PrintToChat(i, "\x04[\x03TF2-Crit Pref\x04]\x01 Your preference is set to: Crits disabled");
			}
		}
	}
	
	//for debug
	//PrintToChatAll("CalcCrit: prefYes %d prefNo %d numPlayers %d percentage %f (prefYes/numPlayers) %f",prefYes,prefNo,numPlayers,percentage, (float(prefYes) / float(numPlayers)));
	
	
	//did more people than needed vote for crits on?
	if ((float(prefYes) / float(numPlayers)) >= percentage)
	{
		ServerCommand("tf_weapon_criticals 1");
		PrintToChatAll("\x04[\x03TF2-Crit Pref\x04]\x01 Crits Enabled. %d Voted On, %d voted Off", prefYes, prefNo);
	}
	else
	{
		PrintToChatAll("\x04[\x03TF2-Crit Pref\x04]\x01 Crits Disabled. %d Voted On, %d voted Off", prefYes, prefNo);
		ServerCommand("tf_weapon_criticals 0");
	}
	
	//remind everybody how to change the preference
	PrintToChatAll("\x04[\x03TF2-Crit Pref\x04]\x01 To change your preference say \x04!crit");
	
	g_bVoteFinished = true;
}
