#include <sourcemod>
#include <adminmenu>
#include <sdktools>
#define PLUGIN_VERSION "1.0.3"

new Handle:v_Enabled = INVALID_HANDLE;
new Handle:v_TeamOnly = INVALID_HANDLE;
new Handle:v_ShowToAll = INVALID_HANDLE;

new g_iAccount = -1;
new g_iMenuTarget[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[CS:S] Cash Gifts",
	author = "DarthNinja",
	description = "Allow players to give away cash!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
	{
		SetFailState("[CS:S] Cash Gifts - Failed to find offset for m_iAccount!");
	}
	
	CreateConVar("sm_cashgifts_version", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	v_Enabled = CreateConVar("sm_cashgifts_enable", "1", "Enable/Disable the plugin", 0, true, 0.0, true, 1.0);
	v_TeamOnly = CreateConVar("sm_cashgifts_team", "1", "If set to 1, players can only give cash to players on the same team", 0, true, 0.0, true, 1.0);
	v_ShowToAll = CreateConVar("sm_cashgifts_show", "1", "1 = Tell everyone when cash is given, 0 = Only tell affected clients", 0, true, 0.0, true, 1.0);
	
	RegConsoleCmd("givecash", GiftCash, "Give some of your cash to another player");
	RegConsoleCmd("giftcash", GiftCash, "Give some of your cash to another player");
	
	LoadTranslations("common.phrases");
}

public OnClientPutInServer(client)
{
	if(GetConVarBool(v_Enabled))
	{
		CreateTimer(45.0, Timer_Announce, GetClientUserId(client));
	}
}

public Action:Timer_Announce(Handle:timer, any:user)
{
	new client = GetClientOfUserId(user);
	if (client !=0 && IsClientConnected(client) && IsClientInGame(client))
	{
		PrintToChat(client, "\x04[\x03Give Cash\x04]: This server is running \x05Cash Gifts\x01!  Use !givecash to give some of your cash to another player!");
	}
}

public Action:GiftCash(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "Srsly dude.");
		return Plugin_Handled;	
	}
	if (!GetConVarBool(v_Enabled))
	{
		ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 Sorry, you cannot give away cash at this time.");
		return Plugin_Handled;	
	}
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 You must be alive to give cash!");
		return Plugin_Handled;	
	}
	if (args != 0 && args != 2)
	{
		ReplyToCommand(client, "Usage: giftcash [player] [value]");
		return Plugin_Handled;	
	}
	
	if (args == 2) // Yay, the client made it easy!
	{
		//Get the target
		decl String:buffer[64];
		GetCmdArg(1, buffer, sizeof(buffer));
		new target = FindTarget(client, buffer, false, false);
		
		if (target < 1)
		{
			ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 Invalid target.");
			return Plugin_Handled;
		}
		
		//Check teams
		if (GetClientTeam(target) != GetClientTeam(client) && GetConVarBool(v_TeamOnly))
		{
			ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 Sorry, you cannot give cash to a player on the other team.");
			return Plugin_Handled;
		}
		
		//Get the cash value
		decl String:Cash[15];
		GetCmdArg(2, Cash, sizeof(Cash));
		new iCash = StringToInt(Cash);
		
		ProcessGift(client, target, iCash);
	}
	else if (args == 0)
	{
		//Create the menu
		new Handle:menu = CreateMenu(MenuHandler_SelectPlayer);
		SetMenuTitle(menu, "Pick a Player:");
		SetMenuExitButton(menu, true);
		
		if (GetConVarBool(v_TeamOnly))
		{
			//Add only players from the same team to the menu
			new ClientTeam = GetClientTeam(client);
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && ClientTeam == GetClientTeam(i) && i != client)
				{
					decl String:Name[65];
					decl String:UserID[32];
					
					GetClientName(i, Name, sizeof(Name));
					
					new iUserID = GetClientUserId(i);
					Format(UserID, sizeof(UserID), "%i", iUserID)
					
					AddMenuItem(menu, UserID, Name);
				}
			}
		}
		else
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && i != client)
				{
					decl String:Name[65];
					decl String:UserID[32];
					
					GetClientName(i, Name, sizeof(Name));
					
					new iUserID = GetClientUserId(i);
					Format(UserID, sizeof(UserID), "%i", iUserID)
					
					AddMenuItem(menu, UserID, Name);
				}
			}
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

public MenuHandler_SelectPlayer(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	else if (action == MenuAction_Select)
	{
		decl String:strTarget[32];
		
		GetMenuItem(menu, args, strTarget, sizeof(strTarget));
		g_iMenuTarget[client] = StringToInt(strTarget);

		new Handle:menuNext = CreateMenu(MenuHandler_GiveCash);
		SetMenuTitle(menuNext, "Cash to Give:");

		AddMenuItem(menuNext, "100", "$100");			//.1K
		AddMenuItem(menuNext, "500", "$500");			//.5K
		AddMenuItem(menuNext, "1000", "$1000");		//1K
		AddMenuItem(menuNext, "2500", "$2,500");		//2.5K
		AddMenuItem(menuNext, "5000", "$5,000");		//5K
		AddMenuItem(menuNext, "10000", "$10,000");		//10K
		AddMenuItem(menuNext, "25000", "$25,000");		//25K
		AddMenuItem(menuNext, "50000", "$50,000");		//50K
		
		SetMenuExitButton(menuNext, true);
		DisplayMenu(menuNext, client, MENU_TIME_FOREVER);	
	}
	
}

public MenuHandler_GiveCash(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new target = GetClientOfUserId(g_iMenuTarget[client]);
		if (target != 0)
		{
			decl String:strCash[10];
			GetMenuItem(menu, args, strCash, sizeof(strCash));
			new iCash = StringToInt(strCash);
			
			ProcessGift(client, target, iCash)
		}
	}
}


public Action:ProcessGift(client, target, iCash)
{
		//Check if client is trying to give themselves cash
		//We could let this go past, but without some extra checks below things will be messy
		if (client == target)
		{
			SlapPlayer(client, 10, true);
			ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 I saw what you did there...");
			return Plugin_Handled; //disable this for debug
		}
		
		//Check cash values
		if (iCash < 0 || iCash > 60000)
		{
			ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 Sorry, that value jus' ain't right!");
			return Plugin_Handled;
		}
		
		//Get clients cash
		new iExistingCash_Client = GetEntData(client, g_iAccount);
		
		//Make sure the client has the funds
		if (iExistingCash_Client < iCash)
		{
			ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 Sorry, you don't have that much cash to give away!");
			return Plugin_Handled;
		}
		
		//Make sure its 'safe' to give the target the cash
		new iExistingCash_Target = GetEntData(target, g_iAccount);
		if (iExistingCash_Target + iCash > 64000)
		{
			ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 Sorry, \x05%N\x01 will have too much cash if you give them that much!", target);
			return Plugin_Handled;
		}
		
		//All the checks passed
		//Log transaction
		decl String:file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), "logs/Cash_Gifts.log");
		LogToFile(file, "[Cash Gifts] %L gave %L %i cash!", client, target, iCash);
		//Tell people
		if (GetConVarBool(v_ShowToAll))
		{
			PrintToChatAll("\x04[\x03Give Cash\x04]: \x05%N\x01 gave \x05%N\x01 \x04$%i\x01 cash!", client, target, iCash);
		}
		else
		{
			PrintToChat(target, "\x04[\x03Give Cash\x04]: \x05%N\x01 gave you \x04$%i\x01 cash!", client, iCash);
			ReplyToCommand(client, "\x04[\x03Give Cash\x04]\x01 You gave \x05%N\x01 \x04$%i\x01 cash!", target, iCash);
		}
		//remove cash from the client's funds and add cash to the target's funds
		SetEntData(client, g_iAccount, iExistingCash_Client - iCash);
		SetEntData(target, g_iAccount, iExistingCash_Target + iCash);
		return Plugin_Handled;
}