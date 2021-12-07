#include <sourcemod>
#include <menus>
#include <banning>
#include <clients>

public Plugin:myinfo =
{
	name = "Voteban",
	author = "Glen Chatfield",
	description = "Allows players to voteban other players.",
	version = "0.0.0.1",
	url = ""
};

new count[65]
new choice[65]

new Handle:g_BanPercentage	// Percentage needed to ban

public OnPluginStart()
{
	g_BanPercentage = CreateConVar("sm_voteban_rate", "0.6", "The percentage of players needed to voteban.")

	RegConsoleCmd("say", SayHandle, "")
}

public Action:SayHandle(index, args)
{
	decl String:text[192]
	
	GetCmdArg(1, text, sizeof(text))

	if(StrEqual(text, "voteban"))
	{
		VoteBanMenu(index)
	}
}

VoteBanMenu(index)
{
	new Handle:menu = CreateMenu(VoteBanMenuHandle)
	SetMenuTitle(menu, "Vote Ban")

	new maxPlayers = GetMaxClients()

	for(new i = 1;i < maxPlayers + 1;i++)
	{
		if(IsClientAuthorized(i) && IsClientConnected(i))
		{
			decl String:name[64]
			GetClientName(i, name, sizeof(name))

			decl String:sIndex[4]
			IntToString(i, sIndex, sizeof(sIndex))

			decl String:menuItem[128]
			Format(menuItem, sizeof(menuItem), "[%i] %s", count[i], name)

			AddMenuItem(menu, sIndex, menuItem)
		}
	}

	DisplayMenu(menu, index, 120)
}

public VoteBanMenuHandle(Handle:menu, MenuAction:action, index, selection)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		new bool:found = GetMenuItem(menu, selection, info, sizeof(info))
		if(!found)
		{
			PrintCenterText(index, "Error, Selection Not Found!")
			CloseHandle(menu)
			VoteBanMenu(index)
			return
		}

		new i = StringToInt(info)

		if(choice[index] != 0)
		{
			count[choice[index]]--
		}

		choice[index] = i
		count[i]++

		decl String:name[64]
		GetClientName(i, name, sizeof(name))

		new clientCount = GetClientCount()

		if(clientCount <= 1)
		{
			PrintToChat(index, "\x04[VoteBan]\x03 There must be at least 2 people on to voteban!")
		}

		new votesNeeded = RoundFloat(float(clientCount) * GetConVarFloat(g_BanPercentage))

		new votesLeft = votesNeeded - count[i]

		if(votesLeft > 0)
		{
			PrintToChatAll("\x01\x04[VoteBan]\x03 %i more votes required to ban %s", votesLeft, name)
		}
		else
		{
			BanClient(i, 30, BANFLAG_AUTO, "Votebanned", "You have been votebanned for 30 minutes.")
			PrintToChatAll("\x01\x04[VoteBan]\x03Player %s has been banned due to a vote.", name)
		}

		CloseHandle(menu)
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		// CloseHandle(menu)
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}