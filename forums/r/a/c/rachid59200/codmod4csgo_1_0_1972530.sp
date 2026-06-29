#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Call of Duty: MW mod",
	author = "rachid59200",
	description = "Simulate Call of Duty style game in CS:GO",
	version = "1.0",
	url = "www.toxicdz.com"
}

new klasa_igraca[65];
new String:ClassName[65]

public OnPluginStart()
{	
	RegConsoleCmd("say", Command_Say);
}

public OnClientPutInServer(client)
{
	if(IsFakeClient(client))
		return;
	
	klasa_igraca[client] = 0
	CreateMenuId(client)
	return;
}

public CreateMenuId(client)
{
	new Handle:ClassMenu = CreateMenu(IzaberiKlasuCB)
	SetMenuTitle(ClassMenu, "Izaberi klasu:")
	AddMenuItem(ClassMenu, "marine", "Marinac")
	AddMenuItem(ClassMenu, "sniper", "Snajperista")
	AddMenuItem(ClassMenu, "strelac", "Pro Strelac")
	AddMenuItem(ClassMenu, "podrska", "Vatrena Podrska")
	AddMenuItem(ClassMenu, "revolveras", "Revolveras")
	AddMenuItem(ClassMenu, "hitman", "Hitman")
	AddMenuItem(ClassMenu, "assassin", "Assassin")
	AddMenuItem(ClassMenu, "swat", "S.W.A.T")
	AddMenuItem(ClassMenu, "soap", "Soap MC Tavish")
	AddMenuItem(ClassMenu, "price", "Cpt. Price")
	SetMenuPagination(ClassMenu, 7)
	SetMenuExitButton(ClassMenu, false)
	DisplayMenu(ClassMenu, client, 250)
}

public IzaberiKlasuCB(Handle:classhandle, MenuAction:action, client, Position)
{
	if(action == MenuAction_Select)
	{
		decl String:Item[32]
		GetMenuItem(classhandle, Position, Item, sizeof(Item))
		
		if(StrEqual(Item, "marine"))
		{
			klasa_igraca[ client ] = 1
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_ak47");
		}
		else if(StrEqual(Item, "sniper"))
		{
			klasa_igraca[ client ] = 2
			GivePlayerItem(client, "weapon_m4a1");
		}
		else if(StrEqual(Item, "strelac"))
		{
			klasa_igraca[ client ] = 3
			GivePlayerItem(client, "weapon_galilar");
			GivePlayerItem(client, "weapon_deagle");
		}
		else if(StrEqual(Item, "podrska"))
		{
			klasa_igraca[ client ] = 4
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_aug");
		}
		else if(StrEqual(Item, "revolveras"))
		{
			klasa_igraca[ client ] = 5
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_famas");
		}
		else if(StrEqual(Item, "hitman"))
		{
			klasa_igraca[ client ] = 6
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_mp7");
		}
		else if(StrEqual(Item, "assassin"))
		{
			klasa_igraca[ client ] = 7
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_mp9");
		}
		else if(StrEqual(Item, "swat"))
		{
			klasa_igraca[ client ] = 8
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_m4a1");
		}
		else if(StrEqual(Item, "soap"))
		{
			klasa_igraca[ client ] = 9
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_mac10");
		}
		else if(StrEqual(Item, "price"))
		{
			klasa_igraca[ client ] = 10
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_bizon");
		}
		
		
		ClassName[ client ] = Position
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(classhandle)
	}
}

public Action:Command_Say(client, args)
{
	new String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "klasa", false) == 0)
	{
		CreateMenuId(client)
	}
	else if (strcmp(text[startidx], "info", false) == 0)
	{
		PrintToChat(client, "[SM] Tvoja klasa je %d", klasa_igraca[ client ]);		
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}