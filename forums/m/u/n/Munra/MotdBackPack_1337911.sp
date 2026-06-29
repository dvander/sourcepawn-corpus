#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <adminmenu>

// Global Definitions
#define PLUGIN_VERSION "3.0"
#define MAX_MESSAGE_LENGTH 192 
//Comment the line below to allow the MOTD to refresh upon death.
#define STOP_MOTD_REFRESH

new Handle:g_hAdverts;
new Handle:g_hAdInterval;
new Handle:g_hAdTimer;
new Handle:g_hFullscreen;
new Handle:g_hCustomAd;
new Float:g_fAdvertTime;
new String:g_sMessage[MAX_MESSAGE_LENGTH];
new Handle:g_hMOTDsite;
new String:g_sCommandName[50];

new bool:g_bIsTF2 = false;
new bool:g_bUsingTeamColor = false;
new g_iColorCodes[] = {1, 3, 3, 4};
new String:g_sColorCodes[][] = {"{DEFAULT}", "{LIGHTGREEN}", "{TEAM}", "{GREEN}"};
#if defined STOP_MOTD_REFRESH
enum {Cmd_None, Cmd_JoinGame, Cmd_ChangeTeam, Cmd_Impulse101, Cmd_MapInfo, Cmd_ClosedHTMLPage, Cmd_ChooseTeam};
new bool:g_bIsInMOTD[MAXPLAYERS+1] = {false, ...};
new bool:g_bSpecShown[MAXPLAYERS+1] = {false, ...};
#endif

public Plugin:myinfo =
{
    name = "MOTD Backpack",
    author = "Munra, bottiger, 11530",
    description = "Opens MOTD with clients TF2items.com backpack",
    version = PLUGIN_VERSION,
    url = "http://anbservers.net"
}

public OnPluginStart()
{

	AutoExecConfig(true,"plugin.motd.backpack","sourcemod");
	
	//Create Cvars
	CreateConVar("motdbp_version", PLUGIN_VERSION, "MOTD Backpack Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hAdverts = CreateConVar("motdbp_advert", "0", "Enable or disable plugin adverts", 0, true, 0.0, true, 1.0);
	g_hAdInterval = CreateConVar("motdbp_adtime", "300", "Number of seconds between adverts", 0, true, 5.0, true, 900.0);
	g_hFullscreen = CreateConVar("motdbp_fullscreen", "1", "Enable or disable fullscreen windows", 0, true, 0.0, true, 1.0);
	g_hCustomAd = CreateConVar("motdbp_message", "{#0B7A7A}View a backpack by typing {#C1E823}!bp {#0B7A7A}or {#C1E823}!bp [playername] \\n{#9E1145}View STEAM Inventory by typing {#C1E823}!sbp {#9E1145}or {#C1E823}!sbp [playername]", "Set a custom advert message \nYou can use any RGBA or RGB color {#RRGGBB} or {DEFAULT}, {TEAM}, {GREEN}, {LIGHTGREEN} and \\n to start a new line.");
	g_hMOTDsite = CreateConVar("motdbp_site", "0", "Choose a BackPack Site, 0 = TF2OutPost.com, 1 = TF2B.com, 2 = TF2items.com" , 0, true, 0.0, true, 2.0);
	
	//Commands
	RegAdminCmd("sm_backpack", OnBackpackCmd, 0, "View a backpack by typing !backpack or !backpack [playername]");
	RegAdminCmd("sm_bp", OnBackpackCmd, 0, "View a backpack by typing !bp or !bp [playername]");
	RegAdminCmd("sm_sbp", OnBackpackCmd, 0, "View a player's STEAM inventory by typing !sbp or !sbp [playername]");
	
	LoadTranslations("common.phrases");
	g_bIsTF2 = IsTF2();
	
	GetConVarString(g_hCustomAd, g_sMessage, sizeof(g_sMessage));
	
	//Advert timer
	g_fAdvertTime = GetConVarFloat(g_hAdInterval);
	if (GetConVarBool(g_hAdverts))
	{
		StartTimer();
	}
	
	HookConVarChange(g_hAdverts, OnAdvertsChange);
	HookConVarChange(g_hAdInterval, OnAdtimeChange);
	HookConVarChange(g_hCustomAd, OnMessageChange);
	
	ParseMessage();

	//For stopping teh MOTD Refreshing after a player death
#if defined STOP_MOTD_REFRESH
	HookUserMessage(GetUserMessageId("VGUIMenu"), OnVGUIMenu, true);
	AddCommandListener(OnMOTDClose, "closed_htmlpage");
#endif
}

#if defined STOP_MOTD_REFRESH
public Action:OnVGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:panel[64];
	BfReadString(bf, panel, sizeof(panel));
	if (strcmp(panel, "specgui") == 0)
	{
		if (g_bIsInMOTD[players[0]])
		{
			if (!g_bSpecShown[players[0]])
			{
				return Plugin_Handled;
			}
		}
		else
		{
			g_bSpecShown[players[0]] = (BfReadByte(bf) ? true : false);
		}
	}
	else if (strcmp(panel, "info") == 0 && GetClientTeam(players[0]) != 0)
	{
		BfReadByte(bf);
		BfReadString(bf, panel, sizeof(panel));
		BfReadString(bf, panel, sizeof(panel));
		if (strcmp(panel, "Backpack") == 0)
		{
			g_bIsInMOTD[players[0]] = true;
		}
	}
	return Plugin_Continue;
}

public Action:OnMOTDClose(client, const String:command[], argc)
{
	g_bIsInMOTD[client] = false;
	return Plugin_Continue;
}
#endif

stock StartTimer()
{
	g_hAdTimer = CreateTimer(g_fAdvertTime, AdvertTimer, _, TIMER_REPEAT);
}

//Displays given player's backpack
public Action:OnBackpackCmd(client, args)
{
	//Gets which command was used and saves it
    	GetCmdArg(0, g_sCommandName, sizeof(g_sCommandName));
		
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		DisplayBackpackMenu(client);
		return Plugin_Handled;
	}
	
	//Gets target client
	new target;
	decl String:argstring[128];
	GetCmdArgString(argstring, sizeof(argstring));
	target = FindTarget(client, argstring, true, false);
	
	if (target == -1) 
	{
		DisplayBackpackMenu(client);
		return Plugin_Handled;
	}
	DisplayBackpack(client, target);
	return Plugin_Handled;
}

stock DisplayBackpackMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Backpack);
	SetMenuTitle(menu, "Choose a player");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Backpack(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			new target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			new userid = StringToInt(info);

			if ((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "[SM] %t", "Player no longer available");
			}
			else
			{
				DisplayBackpack(param1, target);
			}
		}
	}
}

public DisplayBackpack(client, target)
{
 	decl String:steamid[21], String:itemsurl[128];
	new String:communityid[18];
	GetClientAuthString(target, steamid, sizeof(steamid));
	GetCommunityIDString(steamid, communityid, sizeof(communityid));
	
	//Which command was used !bp or !sbp
	if (StrEqual(g_sCommandName, "sm_sbp", false))
    {
		Format(itemsurl, sizeof(itemsurl), "http://www.tf2outpost.com/backpack/%s/753", steamid);
    }
	else
	{
		//Switch for which site to load
		switch (GetConVarInt(g_hMOTDsite))
		{
			case 0:
			{
			Format(itemsurl, sizeof(itemsurl), "http://www.tf2outpost.com/backpack/%s", steamid);
			}
			case 1:
			{
			Format(itemsurl, sizeof(itemsurl), "http://tf2b.com/tf2/%s?nano=1", communityid);
			}
			case 2:
			{
			Format(itemsurl, sizeof(itemsurl), "http://www.tf2items.com/steamid/%s?wrap=1", steamid);
			}
			default:
			{
			Format(itemsurl, sizeof(itemsurl), "http://www.tf2outpost.com/backpack/%s", communityid);
			}
		}
	}
	//Format(itemsurl, sizeof(itemsurl), "http://www.tf2items.com/steamid/%s?wrap=1", steamid);
	new Handle:Kv = CreateKeyValues("motd");
	KvSetString(Kv, "title", "Backpack");
	KvSetNum(Kv, "type", MOTDPANEL_TYPE_URL);
	KvSetString(Kv, "msg", itemsurl);
	if (GetConVarBool(g_hFullscreen))
	{
		KvSetNum(Kv, "customsvr", g_bIsTF2);
	}
#if defined STOP_MOTD_REFRESH
	KvSetNum(Kv, "cmd", Cmd_ClosedHTMLPage);
#endif

	ShowVGUIPanel(client, "info", Kv);
	CloseHandle(Kv);
}

//Timer for adverts
public Action:AdvertTimer(Handle:timer)
{
	if (g_bUsingTeamColor)
	{
		for (new i = 1; i < (MaxClients+1); i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				new Handle:hBf = StartMessageOne("SayText2", i);
				if (hBf != INVALID_HANDLE)
				{
					BfWriteByte(hBf, i);
					BfWriteByte(hBf, 1);
					BfWriteString(hBf, g_sMessage);
					EndMessage();
				}
			}
		}
	}
	else
	{
		PrintToChatAll("%s", g_sMessage);
	}
	return Plugin_Continue;
}

public OnAdvertsChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:adsOn = (StringToInt(newValue)!=0);
	if (adsOn && g_hAdTimer == INVALID_HANDLE)
	{
		StartTimer();
	}
	else if (!adsOn && g_hAdTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAdTimer);
		g_hAdTimer = INVALID_HANDLE;
	}
}

public OnAdtimeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fAdvertTime = StringToFloat(newValue);
	
	if (GetConVarBool(g_hAdverts))
	{
		if (g_hAdTimer != INVALID_HANDLE)
		{
			KillTimer(g_hAdTimer);
			g_hAdTimer = INVALID_HANDLE;
		}
		StartTimer();
	}
}

public OnMessageChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_sMessage, sizeof(g_sMessage), newValue);
	ParseMessage();
}

stock ParseMessage()
{
	decl String:sBuffer[32];
	if (StrContains(g_sMessage, "\\n") != -1) {
		Format(sBuffer, sizeof(sBuffer), "%c", 13);
		ReplaceString(g_sMessage, sizeof(g_sMessage), "\\n", sBuffer);
	}

	for (new i = 0; i < sizeof(g_sColorCodes); i++)
	{
		if (StrContains(g_sMessage, g_sColorCodes[i], false) != -1)
		{
			if (i == 2)
			{
				g_bUsingTeamColor = true;
			}
			Format(sBuffer, sizeof(sBuffer), "%c", g_iColorCodes[i]);
			ReplaceString(g_sMessage, sizeof(g_sMessage), g_sColorCodes[i], sBuffer, false);
		}
	}
	
	if (g_bIsTF2)
	{
		new iStart, iEnd, iTotal;
		decl String:sHex[9], String:sCodeBefore[12], String:sCodeAfter[10];
		while ((iStart = StrContains(g_sMessage[(iTotal)], "{#")) != -1)
		{
			if ((iEnd = StrContains(g_sMessage[iTotal+iStart+2], "}")) != -1)
			{
				if (iEnd == 6 || iEnd == 8)
				{
					strcopy(sHex, iEnd+1, g_sMessage[iTotal+iStart+2]);
					Format(sCodeBefore, sizeof(sCodeBefore), "{#%s}", sHex);
					Format(sCodeAfter, sizeof(sCodeAfter), (iEnd == 6 ? "\x07%s" : "\x08%s"), sHex);
					ReplaceString(g_sMessage, sizeof(g_sMessage), sCodeBefore, sCodeAfter);
					iTotal += iStart + iEnd + 1;
				}
				else
				{
					iTotal += iStart + iEnd + 3;
				}
			}
			else
			{
				break;
			}
		}
	}
	Format(g_sMessage, sizeof(g_sMessage), "%c%s", 1, g_sMessage);
}
	
stock bool:GetCommunityIDString(const String:SteamID[], String:CommunityID[], const CommunityIDSize)
{
    new Identifier[17] = {7, 6, 5, 6, 1, 1, 9, 7, 9, 6, 0, 2, 6, 5, 7, 2, 8};
    decl String:SteamIDParts[3][11];
    
    if (ExplodeString(SteamID, ":", SteamIDParts, sizeof(SteamIDParts), sizeof(SteamIDParts[])) != 3)
    {
        strcopy(CommunityID, CommunityIDSize, "");
        return false;
    }
    
    new SteamIDNumber[CommunityIDSize - 1];
    for (new i = 0; i < strlen(SteamIDParts[2]); i++)
    {
        SteamIDNumber[CommunityIDSize - 2 - i] = SteamIDParts[2][strlen(SteamIDParts[2]) - 1 - i] - 48;
    }

    new Current, CarryOver;
    for (new i = (sizeof(Identifier) - 1); i > -1 ; i--)
    {
        Current = Identifier[i] + (2 * SteamIDNumber[i]) + CarryOver;
        if (i == sizeof(Identifier) - 1 && strcmp(SteamIDParts[1], "1") == 0)
        {
            Current++;
        }

        CarryOver = Current/10;
        Current %= 10;

        SteamIDNumber[i] = Current;
        CommunityID[i] = SteamIDNumber[i] + 48;
    }
    CommunityID[CommunityIDSize - 1] = '\0';
    return true;
}

stock bool:IsTF2()
{
	decl String:sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if (!strcmp(sGameDir, "tf", false) || !strcmp(sGameDir, "tf_beta", false))
	{
		return true;
	}
	return false;
}

#if defined STOP_MOTD_REFRESH
public OnClientDisconnect(client)
{
	g_bIsInMOTD[client] = false;
}
#endif