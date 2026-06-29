#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <updater>

#define	UPDATE_URL	"http://nano-trek.com/cstrike/plugins/sm_chooseforme/sm_chooseforme.txt"
#define PLUGIN_VERSION "1.5.3"
//Updates With 1.5.3: Updater fix

//Cvars
new Handle:sm_chooseforme_version	= INVALID_HANDLE;
new Handle:sm_chooseforme_teamsize	= INVALID_HANDLE;
new Handle:NotSpecPlayerMenu = INVALID_HANDLE;

//Global vars
new g_iClient;
new g_iSwaptospec = -1;

//Info
public Plugin:myinfo =
{
	name = "Choose for me",
	author = "sinsic",
	description = "Randomly distributes players to teams.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
    }
	LoadTranslations("sm_chooseforme.phrases");

	//Console Commands
	RegAdminCmd("sm_cfmrandomize", Command_cfmrandomize, ADMFLAG_KICK, "sm_cfmrandomize <player count|optional>, don't write team size to use the value at cfg.");
	RegAdminCmd("sm_cfmswap", Command_cfmswap, ADMFLAG_KICK, "sm_cfmswap <name>");
	RegAdminCmd("sm_cfmspec", Command_cfmspec, ADMFLAG_KICK, "sm_cfmspec <name>");

	//Convars
	sm_chooseforme_version = CreateConVar("sm_chooseforme_version", PLUGIN_VERSION, "Choose for me version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_chooseforme_teamsize = CreateConVar("sm_chooseforme_teamsize", "0", "Number of players to play. (0 means everybody on spec will be assaigned a team.");

	//Create  cfg file if one does not exist and execute it
	AutoExecConfig(true, "sm_chooseforme");

	//Keep track if somebody changed the plugin_version
	SetConVarString(sm_chooseforme_version, PLUGIN_VERSION);
	HookConVarChange(sm_chooseforme_version, cfm_versionchange);	
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

//If somebody changed the plugin version set it back to right one, otherwise they might not realize updates
public cfm_versionchange(Handle:convar, const String:oldValue[], const String:newValue[])
	{
	SetConVarString(convar, PLUGIN_VERSION);
}

public Action:Command_cfmrandomize(client, args)
	{
	new String:arg[32];
	new iTeamSize = 0;
	
	//if there was no arg, set teamsize to the one in cfg, if it is smaller then 0 give error message
	if (args < 1)
		{
		iTeamSize = GetConVarInt(sm_chooseforme_teamsize);
	} else
		{
		GetCmdArg(1, arg, sizeof(arg));
		iTeamSize = StringToInt(arg);
		if (iTeamSize < 0 )
			{
			PrintToChat(client, "\x03[SM] \x01 %t", "Player count must be bigger than or equal to 0 (0 for everyone).");
			PrintToChat(client, "\x03[SM] \x01 %t", "sm_cfmrandomize <player count|optional>");
			PrintToChat(client, "\x03[SM] \x01 %t", "sm_cfmrandomize to use the value at sm_chooseforme.cfg.");
			iTeamSize = 0;
			return Plugin_Handled;
		}
	}

	//Determine client count and send everyone to spec
	new iPlayerCount = 0;
	for(new i = 1; i <= MaxClients; i++)
		{
		if (IsClientInGame(i) && (!IsFakeClient(i))) 
			{
			iPlayerCount++;
			ChangeClientTeam(i, 1);
		}
	}
	
	//Check if there are less players in game then the desired player count.
	if (iTeamSize > iPlayerCount)
		{
		PrintToChat(client, "\x03[SM] \x01 %t", "Choosen player count is bigger then online player count.");
		PrintToChat(client, "\x03[SM] \x01 %t", "Distributing everybody to teams.");
		iTeamSize = iPlayerCount;
	}

	//If the argument is 0 then distribute all players will be distributed
	if (iTeamSize == 0)
		{
		iTeamSize = iPlayerCount;
	}

	//Distribute players.
	new iClient2;
	new iCount = 1;
	new bool:bTeamSelect = false;
	while (iCount <= iTeamSize)
		{
		iClient2 = GetRandomInt(1, MaxClients);
		if (IsClientInGame(iClient2) && (!IsFakeClient(iClient2)))
			{
			if (GetClientTeam(iClient2) == 1)
				{
				if (bTeamSelect)
					{
					ChangeClientTeam(iClient2, 2);
					bTeamSelect = false;
					iCount++;
				} else
					{
					ChangeClientTeam(iClient2, 3);
					bTeamSelect = true;
					iCount++;
				}
			}
		} 
	}
	
	PrintToChatAll("\x03[SM] \x01 %t", "Teams are selected. GG, GL, HF.");

	return Plugin_Handled;
}

public Action:Command_cfmswap(client, args)
	{
	if (args < 1)
		{
		PrintToChat(client, "\x03[SM] \x01 %t", "Usage: sm_cfmswap <name>.");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new String:sCheck[32];
	Format(sCheck, sizeof(sCheck), "%s", arg);
	
	//If the arg of sm_cfmswap was "playerlist" then build a playerlist.
	if (StrContains(sCheck, "playerlist") != -1)
		{
		NotSpecPlayerMenu = BuildNotSpecPlayerMenu();
		DisplayMenu(NotSpecPlayerMenu, client, MENU_TIME_FOREVER);
		g_iSwaptospec = 0;
		return Plugin_Handled;
	}
	
	//If the arg wasn't "playerlist" find target client
	g_iClient = FindTarget(client, arg);
	GetClientName(g_iClient, arg, sizeof(arg));
	
	//Get Targets team and swap if target is not spec
	new iTeamOfClient = GetClientTeam(g_iClient);
	if (iTeamOfClient == 1)
		{
		PrintToChat(client, "\x03[SM] \x01 %t", "Can't swap a spec.");	
		return Plugin_Handled;
	}
		
	if (iTeamOfClient == 2)
		{
		if (GetPlayerWeaponSlot( g_iClient, 4 ) != -1 )
			{
			CS_DropWeapon( g_iClient, GetPlayerWeaponSlot(g_iClient, 4 ), true, true );
		}
		CS_SwitchTeam(g_iClient, 3);
		PrintToChatAll("\x03[SM] \x04 %t", "has swapped to CT.", g_iClient);
	}

	if (iTeamOfClient == 3)
		{
		CS_SwitchTeam(g_iClient, 2);
		PrintToChatAll("\x03[SM] \x04 %t", "has swapped to T.", g_iClient);
	}
	
	//Check teams if no one left on a team then end the round
	CheckTeams();
	return Plugin_Handled;
}

public Action:Command_cfmspec(client, args)
	{
	if (args < 1)
		{
		PrintToChat(client, "\x03[SM] \x01 %t", "Usage: sm_cfmspec <name>.");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new String:sCheck[32];
	Format(sCheck, sizeof(sCheck), "%s", arg);
	
	//If the argument of sm_cfmspec is "playerlist" build a player list
	if (StrContains(sCheck, "playerlist") != -1)
		{
		NotSpecPlayerMenu = BuildNotSpecPlayerMenu();
		DisplayMenu(NotSpecPlayerMenu, client, MENU_TIME_FOREVER);
		g_iSwaptospec = 1;
		return Plugin_Handled;
	}
	
	//If the argument isn't "playerlist" then find target client and if target is not spec switch to spec.
	g_iClient = FindTarget(client, arg);
	GetClientName(g_iClient, arg, sizeof(arg));

	new iTeamOfClient = GetClientTeam(g_iClient);

	if (iTeamOfClient != 1)
		{
		ChangeClientTeam(g_iClient, 1);
		PrintToChatAll("\x03[SM] \x04 %t", "has swapped to Spec." , g_iClient);
		return Plugin_Handled;
	}
	
	//Check teams if no one left on a team then end the round
	CheckTeams();
	return Plugin_Handled;
}

Handle:BuildNotSpecPlayerMenu()
	{
	new Handle:menu = CreateMenu(Menu_SelectPlayer);
	new String:sPlayerName[32];
	
	//Build a Player List Consisting Of Players Who Are Connected, not a bot and not spec
	for(new i = 1; i <= MaxClients; i++)
		{
		if (IsClientInGame(i) && (!IsFakeClient(i)) && (GetClientTeam(i) != 1)) 
			{
			GetClientName(i, sPlayerName, sizeof(sPlayerName));
			AddMenuItem(menu, sPlayerName, sPlayerName);
		}
	}
	new String:buffer[128];
	
	SetMenuTitle(menu, "%T", "Select Player:", LANG_SERVER);
	Format(buffer, sizeof(buffer), "%T", "Select Player:", LANG_SERVER);
	return menu;
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		//Find the target selected from player list
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		PrintToConsole(param1, "Client found: %d", found);
		g_iClient = FindTarget(param1, info);
		GetClientName(g_iClient, info, sizeof(info));
		
		//Rerun the command with targets name
		if (g_iSwaptospec == 0)
		{
			ServerCommand("sm_cfmswap %s", info);
		} else
		{
			ServerCommand("sm_cfmspec %s", info);
		}
		
	}
}

public CheckTeams()
{
	//After plugins swaps someone to spec or opposite team
	//This function checks if there are any players left on the old team
	//If not, the opposite team wins
	new iCTNumber=0;
	new iTNumber=0;
	
	for(new i = 1; i <= MaxClients; i++)
		{
		if (IsClientInGame(i) && (GetClientTeam(i) == 2) && IsPlayerAlive(i)) 
			{
			iTNumber++;
		}
		if (IsClientInGame(i) && (GetClientTeam(i) == 3) && IsPlayerAlive(i)) 
			{
			iCTNumber++;
		}
	}
	
	if (iTNumber < 1)
		{
		CS_TerminateRound(2.0,CSRoundEnd_CTWin);
	}
	if (iCTNumber < 1)
		{
		CS_TerminateRound(2.0,CSRoundEnd_TerroristWin);
	}
}