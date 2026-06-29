#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "L4D Swap with Adversary",
	author = "AtomicStryker",
	description = "Allows two players to agree on a teamswap",
	version = PLUGIN_VERSION,
	url = ""
}

new WantsSwapWith[MAXPLAYERS+1];

public OnPluginStart()
{
	RegConsoleCmd("sm_swapwith", SwapWish, "Ask someone to swap teams with you");
	
	CreateConVar("l4d_swapwithadversary_version", PLUGIN_VERSION, " Version of L4D Swap with Adversary on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action:SwapWish(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swapwith <player> - ask a player to swap teams with you.");
		return Plugin_Handled;
	}
	
	decl String:buffer[256];
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client, buffer, true, false);
	
	if (target <= 0 || !IsClientInGame(target))
	{
		ReplyToCommand(client, "[SM] Invalid target specified");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) == GetClientTeam(target))
	{
		ReplyToCommand(client, "[SM] The target is in YOUR team.");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(target) == 1)
	{
		ReplyToCommand(client, "[SM] The target is spectating.");
		return Plugin_Handled;
	}
	
	IssueSwapWish(target, client);
	return Plugin_Handled;
}

public Action:IssueSwapWish(target, source)
{
	WantsSwapWith[target] = source;
	SendPanelToClient(Menu_Ask(target), target, Menu_Answer, MENU_TIME_FOREVER);
}

public Handle:Menu_Ask (target)
{
	new Handle:menu = CreatePanel();	
	SetPanelTitle(menu, "L4D Swap with Adversary");
	
	decl String:name[256], String:panel[256];
	GetClientName(WantsSwapWith[target], name, sizeof(name));
	Format(panel, sizeof(panel), "%s wants to", name);
	DrawPanelText(menu, panel);
	
	DrawPanelText(menu, "swap teams with you!");
	DrawPanelText(menu, "");
	DrawPanelText(menu, "");
	
	DrawPanelItem(menu, "Disagree, don't swap");
	
	DrawPanelText(menu, "");
	
	DrawPanelItem(menu, "Agree and swap teams");
	
	return menu;
}

public Menu_Answer (Handle:askmenu, MenuAction:action, client, choice)
{
	if (askmenu != INVALID_HANDLE) CloseHandle(askmenu);
	if (action == MenuAction_Select)
	{
		switch(choice)
		{
			case 1:
				PrintToChat(WantsSwapWith[client], "Your swap request was declined");
			case 2:
				ExecuteSwap(WantsSwapWith[client], client);
			
			default:
			{
				PrintToChat(WantsSwapWith[client], "Your swap request was declined");
			}
		}
	}
	
	else
	{
		PrintToChat(WantsSwapWith[client], "Your swap request was declined");
	}
}

public Action:ExecuteSwap(playerA, playerB)
{
	new newteamA = OtherTeam(GetClientTeam(playerA));
	new newteamB = OtherTeam(GetClientTeam(playerB));
	ChangeClientTeam(playerA, 1);
	ChangeClientTeam(playerB, 1);
	
	new Handle:dataA = CreateDataPack();
	WritePackCell(dataA, playerA);
	WritePackCell(dataA, newteamA);
	CreateTimer(0.1, DelayedSwap, dataA);
	
	new Handle:dataB = CreateDataPack();
	WritePackCell(dataB, playerB);
	WritePackCell(dataB, newteamB);
	CreateTimer(0.1, DelayedSwap, dataB);
}

public Action:DelayedSwap(Handle:timer, Handle:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	new team = ReadPackCell(data);
	CloseHandle(data);
	
	if (team == 3) ChangeClientTeam(client, 3)
	else FakeClientCommand(client, "jointeam 2");
}

stock OtherTeam(team)
{
	if (team == 3) return 2;
	return 3;
}
