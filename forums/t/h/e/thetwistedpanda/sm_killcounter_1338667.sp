#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.1.3"
#define PLUGIN_PREFIX "\x04Kill Counter: \x03"

new Handle:g_hCounter = INVALID_HANDLE;
new Handle:g_hInterval = INVALID_HANDLE;
new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_hCookie = INVALID_HANDLE;

new bool:g_bDisplay[MAXPLAYERS+1];
new g_iData[MAXPLAYERS+1][2];

public Plugin:myinfo =
{
	name = "Kill Counter",
	author = "NakashimaKun",
	description = "Counts up your kills and headshots.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	//Create the necessary convars for the plugin
	CreateConVar("sm_killcounter_version", PLUGIN_VERSION, "Kill Counter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCounter = CreateConVar("sm_killcounter", "1", "Determines plugin functionality. (0 = Off, 1 = All Kills, 2 = Headshots Only)", FCVAR_NONE, true, 0.0, true, 2.0);
	g_hInterval = CreateConVar("sm_killcounter_ad_interval", "30.0", "Amount of seconds between advertisements.", FCVAR_NONE, true, 0.0);
	
	//Generate a configuration file
	AutoExecConfig(true, "Kill_Counter");

	//Register the death event so we can track kills
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	//Create the commands for the plugin
	RegConsoleCmd("sm_counter", Command_Counter);
	RegConsoleCmd("sm_kills", Command_Kills);
	RegConsoleCmd("sm_teamkills", Command_TeamKills);
	
	//Used in ClientPrefs, for saving counter settings
	g_hCookie = RegClientCookie("Kill_Counter_Status", "Display Kill Counter", CookieAccess_Protected);
	SetCookieMenuItem(Menu_Status, 0, "Display Kill Counter");
}

//Called when the map starts
public OnMapStart() 
{
	g_hTimer = CreateTimer(GetConVarFloat(g_hInterval), Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

//If for whatever reason something wiggy happens later, default the setting to on for the client first.
public OnClientConnected(client)
{
	g_bDisplay[client] = true;
}

//Called after the player has been authorized and fully in-game
public OnClientPostAdminCheck(client)
{
	//Create a timer to check the status of the player's cookie
	if(!IsFakeClient(client))
		CreateTimer(0.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
}

//This timer will loop until the client's cookies are loaded, or until the client leaves
public Action:Timer_Check(Handle:timer, any:client)
{
	if(client)
	{
		if(AreClientCookiesCached(client))
			CreateTimer(0.0, Timer_Process, client, TIMER_FLAG_NO_MAPCHANGE);
		else if(IsClientInGame(client))
			CreateTimer(5.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

//Called after a client's cookies have been processed by the server
public Action:Timer_Process(Handle:timer, any:client)
{
	//For whatever reason, make sure the client is still in game
	if(IsClientInGame(client))
	{
		//Declare a temporary string and store the contents of the client's cookie
		decl String:g_sCookie[3] = "";
		GetClientCookie(client, g_hCookie, g_sCookie, sizeof(g_sCookie));
		
		//If the cookie is empty, throw some data into it. If the cookie is disabled, we turn off the client's setting
		if(StrEqual(g_sCookie, ""))
			SetClientCookie(client, g_hCookie, "1");
		else if(StrEqual(g_sCookie, "0"))
			g_bDisplay[client] = false;
	}
	
	return Plugin_Continue;
}

//Repeating timer that displays a message to all clients.
public Action:Timer_DisplayAds(Handle:timer) 
{
	PrintToChatAll("%sTo modify your settings, type !counter. To view your current stats, type !kills. And to view your team's current stats, type !teamkills.", PLUGIN_PREFIX);
}

//As the name implies, this is called when a player goes splat.
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Get the attacker from the event
	new attacker =  GetClientOfUserId(GetEventInt(event, "attacker"));

	//Only process if the player is a legal attacker (i.e., a player)
	if(attacker && attacker <= MaxClients)
		Void_PrintKillInfo(attacker, GetEventBool(event, "headshot"));

	return Plugin_Continue;
}

//Define as a void since it won't return any information. Prints stuff to the client.
void:Void_PrintKillInfo(attacker, bool:g_bHeadshot)
{
	new g_iTemp, g_iMode = GetConVarInt(g_hCounter);

	switch(g_iMode)
	{
		case 1:
		{
			g_iTemp = g_iData[attacker][1];
			g_iData[attacker][1]++;
			if(g_bDisplay[attacker])
			{
				if(g_iTemp >= 1)
					PrintHintText(attacker, "KILLS +%d", g_iTemp);
				else
					PrintHintText(attacker, "KILL!");
			}

			if(g_bHeadshot)
			{
				g_iTemp = g_iData[attacker][0];
				g_iData[attacker][0]++;
				if(g_bDisplay[attacker])
				{
					if(g_iTemp > 1)
						PrintHintText(attacker, "HEADSHOTS +%d", g_iTemp);
					else
						PrintHintText(attacker, "HEADSHOT!");
				}
			}
		}
		case 2:
		{
			if(g_bHeadshot)
			{
				g_iTemp = g_iData[attacker][0];
				g_iData[attacker][0]++;
				if(g_bDisplay[attacker])
				{
					if(g_iTemp > 1)
						PrintHintText(attacker, "HEADSHOTS +%d", g_iTemp);
					else
						PrintHintText(attacker, "HEADSHOT!");
				}
			}
		}
	}
}

//This command is fired when the user inputs sm_counter, !counter, or /counter
public Action:Command_Counter(client, args)
{
	//Their status is already saved, let's just use that to determine the setting.
	if(g_bDisplay[client])
	{
		//Display is on, they want off
		SetClientCookie(client, g_hCookie, "0");
		PrintToChat(client, "%sYou've disabled kill notifications.", PLUGIN_PREFIX);
	}
	else
	{
		//Display is off, turn on
		SetClientCookie(client, g_hCookie, "1");
		PrintToChat(client, "%sYou've enabled kill notifications.", PLUGIN_PREFIX);
	}

	g_bDisplay[client] = !g_bDisplay[client];
	return Plugin_Handled;
}

//Used for showing the client their counter status should they type !settings
public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "Display Kill Counter");
		case CookieMenuAction_SelectOption:
			CreateMenuStatus(client);
	}
}

//Menu that appears when a user types !settings
stock CreateMenuStatus(client)
{
	new Handle:menu = CreateMenu(Menu_StatusDisplay);
	decl String:text[64];

	//The title of the menu
	Format(text, sizeof(text), "Kill Counter");
	SetMenuTitle(menu, text);

	//Since their status is already saved, use it to determine the change
	if(g_bDisplay[client])
		AddMenuItem(menu, "Kill_Counter", "Disable Kill Counter");
	else
		AddMenuItem(menu, "Kill_Counter", "Enable Kill Counter");

	//Give the menu a back button, and make it display on the client
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}

//Determines if the menu should be opened or closed (i.e. if the client types !settings twice)
public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if(param2 == 1)
			{
				//Their status is already saved, let's just use that to determine the setting.
				if(g_bDisplay[param1])
				{
					//Display is on, they want off
					SetClientCookie(param1, g_hCookie, "0");
					PrintToChat(param1, "%sYou've disabled kill notifications.", PLUGIN_PREFIX);
				}
				else
				{
					//Display is off, turn on
					SetClientCookie(param1, g_hCookie, "1");
					PrintToChat(param1, "%sYou've enabled kill notifications.", PLUGIN_PREFIX);
				}

				g_bDisplay[param1] = !g_bDisplay[param1];
			}
		}
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
				{
					//Client has pressed back, let's give them the Cookie menu.
					ShowCookieMenu(param1);
				}
			}
		}
		case MenuAction_End: 
		{
			//Menu has been closed (either by another menu or client). Squish that handle!
			CloseHandle(menu);
		}
	}
}  

//Called when a client accesses sm_kills, !kills, or /kills 
public Action:Command_Kills(client, args)
{
	new g_iTotal, Float:g_fPercent = 0.0;
	decl String:g_sTemp[256];

	new Handle:g_hPanel = CreatePanel();
	SetPanelTitle(g_hPanel, "Kill Counter");
	DrawPanelText(g_hPanel, "-==-==-==-==-");
	Format(g_sTemp, sizeof(g_sTemp), "Headshot Kills: %d", g_iData[client][0]);
	DrawPanelText(g_hPanel, g_sTemp);
	
	Format(g_sTemp, sizeof(g_sTemp), "Normal Kills: %d", g_iData[client][1]);
	DrawPanelText(g_hPanel, g_sTemp);

	g_iTotal = (g_iData[client][0] + g_iData[client][1]);
	Format(g_sTemp, sizeof(g_sTemp), "Total Kills: %d", g_iTotal);
	DrawPanelText(g_hPanel, g_sTemp);

	if(g_iTotal)
		g_fPercent = 100.0 * float(g_iData[client][0] / g_iTotal);
	Format(g_sTemp, sizeof(g_sTemp), "Headshot Percentage: %1.f%s", g_fPercent, "%%");
	DrawPanelText(g_hPanel, g_sTemp);
	DrawPanelText(g_hPanel, "-==-==-==-==-");
	
	DrawPanelItem(g_hPanel, "Close");
	DrawPanelItem(g_hPanel, "Reset Counters");
	SendPanelToClient(g_hPanel, client, KillsPanelHandler, 20);
	CloseHandle(g_hPanel);
	return Plugin_Handled;
}

//Handles the sm_kills panel
public KillsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 2)
		{
			g_iData[param1][0] = 0;
			g_iData[param1][1] = 0;

			PrintToConsole(param1, "%sYour counters have been reset.", PLUGIN_PREFIX);
		}
	}
}

//Called when a client accesses sm_teamkills, !teamkills, or /teamkills 
public Action:Command_TeamKills(client, args)
{
	new g_iTeam = GetClientTeam(client);
	if(g_iTeam >= 2)
	{
		decl String:g_sTemp[256];
		new g_iCount, g_iArray[4], g_iTotalZombies, g_iTotalHeadshots, g_iTotalKills, Float:g_fTotalPercent = 0.0;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_iTeam == GetClientTeam(i))
			{
				g_iTotalZombies += g_iData[i][1];
				g_iTotalHeadshots += g_iData[i][0];
				g_iTotalKills += (g_iData[i][1] + g_iData[i][0]);
				
				g_iArray[g_iCount] = i;
				g_iCount++;
			}
		}

		new Handle:g_hPanel = CreatePanel();
		SetPanelTitle(g_hPanel, "Team Kill Counter");
		DrawPanelText(g_hPanel, "-==-==-==-==-");

		Format(g_sTemp, sizeof(g_sTemp), "Normal Kills: %d", g_iTotalZombies);
		DrawPanelText(g_hPanel, g_sTemp);
		
		Format(g_sTemp, sizeof(g_sTemp), "Headshots: %d", g_iTotalHeadshots);
		DrawPanelText(g_hPanel, g_sTemp);
		
		Format(g_sTemp, sizeof(g_sTemp), "Total Kills: %d", g_iTotalKills);
		DrawPanelText(g_hPanel, g_sTemp);
		
		if(g_iTotalKills)
			g_fTotalPercent = 100.0 * float(g_iTotalHeadshots / g_iTotalKills);
		Format(g_sTemp, sizeof(g_sTemp), "Headshot Percentage: %1.f%s", g_fTotalPercent, "%%");
		DrawPanelText(g_hPanel, g_sTemp);
		if(g_iCount > 0)
		{
			decl String:g_sName[64];
			DrawPanelText(g_hPanel, "-==-==-==-==-");
			for(new i = 0; i < g_iCount; i++)
			{
				GetClientName(g_iArray[i], g_sName, sizeof(g_sName));
				Format(g_sTemp, sizeof(g_sTemp), "%s, Kills: %d, Headshots: %d, Total: %d", g_sName, g_iData[g_iArray[i]][1], g_iData[g_iArray[i]][0], (g_iData[g_iArray[i]][0] + g_iData[g_iArray[i]][1]));
				DrawPanelText(g_hPanel, g_sTemp);
			}
		}
		DrawPanelText(g_hPanel, "-==-==-==-==-");
		DrawPanelItem(g_hPanel, "Close");

		SendPanelToClient(g_hPanel, client, TeamKillsPanelHandler, 20);
		CloseHandle(g_hPanel);
	}
	
	return Plugin_Handled;
}

//Don't need to use this for anything, but it has to be defined. Handles the sm_kills panel
public TeamKillsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{

}

//Called when hooked settings are changed.
public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hTimer)
	{
		if(g_hTimer != INVALID_HANDLE) 
			KillTimer(g_hTimer);
			
		g_hTimer = CreateTimer(GetConVarFloat(g_hInterval), Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}  