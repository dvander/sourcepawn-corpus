#include <sourcemod>
#include <sdktools>

#define NONE	-1

enum _:MAX_PARTY 
{ 
   Master = 0, 
   Member2, 
   Member3
};

new Party_Ids[33][MAX_PARTY], bool:Block_Party[33], bool:In_Party[33], 
bool:Party_Master[33], bool:Time_End[33];

new Handle:party_time_accept = INVALID_HANDLE

public Plugin:myinfo =
{
	name = "Party",
	author = "[R]ak (Original algoritm) & jaxoR (SourceMod)",
	description = "This plugins consist in create groups of 2 or 3 players, to share or win x2 frags, points, or whatever you want",
	version = "1.0",
	url = "http://www.amxmodx-es.com"
};

public OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");
	
	party_time_accept = CreateConVar("sm_party_time_accept", "15", "Time to have the request player for enter to the party");
}

public Action:Command_Say(client, const String:command[], argc)
{
	decl String:text[192];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
 
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
 
	if (strcmp(command, "say2", false) == 0)
		startidx += 4;
 
	if (strcmp(text[startidx], "/partym", false) == 0)
	{
		MenuParty(client)
		return Plugin_Handled;
	}
 
	return Plugin_Continue;
}

public Action:MenuParty(client)
{
	if(In_Party[client])
	{	
		static String:Name[32];
		GetClientName(Party_Ids[client][Master], Name, sizeof(Name));
		new Handle:menu = CreateMenu(MenuPartyHandler);
		SetMenuTitle(menu, "Party Menu");
		AddMenuItem(menu, Name, Name);
		GetClientName(Party_Ids[client][Member2], Name, sizeof(Name));
		AddMenuItem(menu, Name, Name);
		
		if(Party_Ids[client][Member3] != NONE)
		{
			GetClientName(Party_Ids[client][Member3], Name, sizeof(Name));
			AddMenuItem(menu, Name, Name);
		}
		else
		{
			if(Party_Master[client])
			{
				AddMenuItem(menu, "invitar", "<Invitar>");
			}
			else
			{
				AddMenuItem(menu, "miembro3", "(Slot disponible)");
			}
		}
			
		if(Party_Master[client])
		{
			AddMenuItem(menu, "kick", "Kick member");
			AddMenuItem(menu, "destroy", "Destroy Party");
		}
		else
		{
			AddMenuItem(menu, "salir", "Salir del Party");
		}
		
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 20);

	}
	else
	{
		new Handle:menu = CreateMenu(MenuPartyHandler);
		SetMenuTitle(menu, "Party Menu");
		AddMenuItem(menu, "createparty", "Create Party");
		AddMenuItem(menu, "createparty", "Block invitations of Party");
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 20);
	}
	
	return;
}

public MenuPartyHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(In_Party[param1])
		{
			switch(param2)
			{
				case 0: MenuParty(param1)
				case 1: MenuParty(param1)
				case 2: 
				{
					if(Party_Ids[param1][Member3] != NONE)
					{
						MenuParty(param1)
					}
					else
					{
						if(Party_Master[param1])
						{
							Party(param1)
						}
					}
				}
				case 3:
				{
					if(Party_Master[param1] && Party_Ids[param1][Member3] != NONE)
					{
						new Handle:menu2 = CreateMenu(MenuKick);
						SetMenuTitle(menu2, "Kick Member");
						static String:Name_Member2[32], String:Name_Member3[32];
						GetClientName(Party_Ids[param1][Member2], Name_Member2, sizeof Name_Member2);
						AddMenuItem(menu2, Name_Member2, Name_Member2);
						GetClientName(Party_Ids[param1][Member3], Name_Member2, 32);
						AddMenuItem(menu2, Name_Member2, Name_Member3);
						SetMenuExitButton(menu2, false);
						DisplayMenu(menu2, param1, 20);
					}
					else if(!Party_Master[param1])
					{
						QuitParty(param1, 0);
					}
				}
				case 4:
				{
					if(Party_Master[param1])
					{
						QuitParty(param1, 1);
					}
				}
			}
			
			return;
		}
		else
		{
			switch(param2)
			{
				case 0: Party(param1);
				case 1:
				{
					if(Block_Party[param1])
					{
						Block_Party[param1] = false;
					}
					else
					{
						Block_Party[param1] = true;
					}
					
					MenuParty(param1);
				}
			}
		}
	}
	
	else if (action == MenuAction_Cancel)
	{
		PrintToConsole(param1, "Menu aborted");
	}
	
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuKick(Handle:menu, MenuAction:action, param1, param2)
{
	if(!IsClientConnected(param1))
	{
		return;
	}
	
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new user = FindTarget(0, info);
	
		QuitParty(Party_Ids[param1][user], 0);
		return;
	}
	
	else if (action == MenuAction_Cancel)
	{
		PrintToConsole(param1, "Menu aborted");
	}

	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return;
}

public Party(client)
{
	if(!IsClientConnected(client))
	{
		return;
	}
	
	if(In_Party[client] && !Party_Master[client])
	{
		PrintToChat(client, "[Party]No podes invitar porque no sos el Master");
		MenuParty(client);
		return;
	}
	
	static String:Name[32];
	new Handle:menu = CreateMenu(PartyHandle);
	
	if(In_Party[client])
	{
		SetMenuTitle(menu, "Invite to a Party");
	}
	else
	{
		SetMenuTitle(menu, "Create Party");
	}
	
	for(new i=1; i <= MaxClients; i++) 
	{
		if(!IsClientConnected(client))
		{
			return;
		}
		
		if(i != client || !In_Party[i])
		{
			GetClientName(i, Name, sizeof(Name));
			AddMenuItem(menu, Name, Name);
		}
	}
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
	return;
}

public PartyHandle(Handle:menu, MenuAction:action, param1, param2)	
{
	if(!IsClientConnected(param1))
	{
		return;
	}
	
	if (action == MenuAction_Select)
	{
		if((!In_Party[param1] && Party_Ids[param1][Member2] != NONE) || (In_Party[param1] && Party_Ids[param1][Member3] != NONE))
		{
			PrintToConsole(param1, "[Party] Tenes que esperar %d segundos o hasta que acepten o rechacen la invitacion enviada");
			CloseHandle(menu);
			return;
		}
		
		static id2; 
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		id2 = FindTarget(0, info);
		if(In_Party[id2])
		{
		
		}
		else if(param1 == id2)
		{
		
		}
		else if(Block_Party[id2])
		{
		
		}
		
		if(!Party_Master[param1])
		{
			Party_Ids[param1][Master] = param1;
			Party_Ids[param1][Member2] = id2;
			Party_Ids[id2][Master] = param1;
			Party_Ids[id2][Member2] = id2;
			Party_Master[param1] = true;
		}
		else
		{
			Party_Ids[id2][Master] = param1;
			Party_Ids[id2][Member2] = Party_Ids[param1][Member2];
			Party_Ids[id2][Member3] = id2;
			Party_Ids[param1][Member3] = id2;
			Party_Ids[Party_Ids[param1][Member2]][Member3] = id2;
		}
		
		static String:Name_Master[32];
		GetClientName(param1, Name_Master, sizeof(Name_Master));
		
		new Handle:menu2 = CreateMenu(InviteHandle);
		SetMenuTitle(menu2, "Te mandaron una solicitud para party. Aceptas?");
		AddMenuItem(menu2, "yes", "Yes");
		AddMenuItem(menu2, "no", "No");
		DisplayMenu(menu2, id2, 20);
		
		new time = GetConVarInt(party_time_accept);
		CreateTimer(time, Time_Acept, id2);
		
		return;
		
	}
	
	else if (action == MenuAction_Cancel)
	{
		PrintToConsole(param1, "Menu aborted");
	}

	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return;
}

public InviteHandle(Handle:menu, MenuAction:action, param1, param2)
{
	if(!IsClientConnected(param1) || Time_End[param1])
	{
		CloseHandle(menu);
		Time_End[param1] = false;
		return;
	}
	
	switch(param2)
	{
		case 0:
		{
			if(!In_Party[Party_Ids[param1][Master]])
			{
				PrintToChat(Party_Ids[param1][Master], "[Party] Party was created successfully");
				PrintToChat(param1, "[Party] Party was created successfully");
				In_Party[Party_Ids[param1][Master]] = true;
				In_Party[param1] = true;
			}
			else
			{
				PrintToChat(Party_Ids[param1][Master], "[Party] Member added successfully");
				PrintToChat(param1, "[Party] You enter to the party");
				In_Party[param1] = true;
			}
		}
		case 1:
		{
			if(!In_Party[Party_Ids[param1][Master]])
			{
				Party_Master[Party_Ids[param1][Master]] = false;
				Party_Ids[Party_Ids[param1][Master]][Master] = NONE;
				Party_Ids[Party_Ids[param1][Master]][Member2] = NONE;
				Party_Ids[param1][Master] = NONE;
				Party_Ids[param1][Member2] = NONE;
			}
			else
			{
				Party_Ids[Party_Ids[param1][Master]][Member3] = NONE;
				Party_Ids[Party_Ids[param1][Member2]][Member3] = NONE;
				for( new i; i < MAX_PARTY; i++ )
					Party_Ids[param1][i] = NONE;
			}	
		}
	}
	
	return; 
}

public QuitParty(client, reset)
{
		
	if(reset)
	{
		if(In_Party[client])
		{
			PrintToChat(Party_Ids[client][Master], "[Party] Party destroyed");
			PrintToChat(Party_Ids[client][Member2], "[Party] Party destroyed");
		}
		else
		{
			new time = GetConVarInt(party_time_accept);
			PrintToChat(Party_Ids[client][Master], "[Party] They spent %d seconds and don't accept the invitation", time);
			PrintToChat(Party_Ids[client][Member2], "[Party] They spent %d seconds and don't accept the invitation", time);
		}
		
		if(Party_Ids[client][Member3] != NONE)
			PrintToChat(Party_Ids[client][Member3], "[Party] Party destroyed");
		
		In_Party[Party_Ids[client][Member2]] = false;
		In_Party[Party_Ids[client][Master]] = false;
		
		if(Party_Ids[client][Member3] != NONE)
		{
			for(new i;i < MAX_PARTY;i++)
				Party_Ids[Party_Ids[client][Member3]][i] = NONE;
			
			In_Party[Party_Ids[client][Member3]] = false;
		}
		
		if(Party_Master[client])
		{
			for(new i; i < MAX_PARTY; i++)
				Party_Ids[Party_Ids[client][Member2]][i] = NONE;
			for( new i; i < MAX_PARTY; i++ )
				Party_Ids[client][i] = NONE;
			Party_Master[client] = false;
		}
		else
		{
			Time_End[client] = false;
			Party_Master[Party_Ids[client][Master]] = false;
			for(new i; i < MAX_PARTY; i++)
				Party_Ids[Party_Ids[client][Master]][i] = NONE;
			for( new i; i < MAX_PARTY; i++ )
				Party_Ids[client][i] = NONE;		
		}
		return;
	}
	
	if(Party_Ids[client][Member2] == client)
	{
		Party_Ids[Party_Ids[client][Member3]][Member2] = Party_Ids[Master][Member3];
		Party_Ids[Party_Ids[client][Member3]][Member3] = NONE;
		Party_Ids[Party_Ids[client][Master]][Member2] = Party_Ids[Master][Member3];
		Party_Ids[Party_Ids[client][Master]][Member3] = NONE;
		
		for(new i;i < MAX_PARTY;i++)
			Party_Ids[client][i] = NONE;
		
		In_Party[client] = false;
	}
	else
	{
		if(!Time_End[client])
		{
			PrintToChat(Party_Ids[client][Master], "[Party] Player kicked of the party");
			PrintToChat(Party_Ids[client][Member3], "[Party] You are kicked from the party");
		}
		else
		{
			new time = GetConVarInt(party_time_accept);
			PrintToChat(Party_Ids[client][Master], "[Party] They spent %d seconds and don't accept the invitation", time);
			PrintToChat(Party_Ids[client][Member3], "[Party] They spent %d seconds and don't accept the invitation", time);
		}
		
		Party_Ids[Party_Ids[client][Member2]][Member3] = NONE;
		Party_Ids[Party_Ids[client][Master]][Member3] = NONE;
		
		for(new i;i < MAX_PARTY;i++)
			Party_Ids[client][i] = NONE;
		
		In_Party[client] = false;
	}
	Time_End[client] = false;
	return;
}

public Action:Time_Acept(Handle:timer, any:id2)
{
	if(!IsClientConnected(id2))
	{
		Time_End[id2] = true;
		
		if(In_Party[Party_Ids[id2][Master]])
		{
			QuitParty(id2, 0);
		}
		else
		{
			QuitParty(Party_Ids[id2][Master], 1);
		}
	}
}

public OnClientPutInServer(client)
{
	for(new i;i < MAX_PARTY;i++)
		Party_Ids[client][i] = NONE;
	
	In_Party[client] = false;
	Block_Party[client] = false;
	Party_Master[client] = false;
	Time_End[client] = false;
}

public OnClientDisconnect(client)
{
	if(In_Party[client])
	{
		if(Party_Master[client])
			QuitParty(client, 1);
		else if(Party_Ids[client][Member3] == NONE)
		{
			QuitParty(client, 1)
		}
		else
		{
			QuitParty(client, 0);
		}
		
		Block_Party[client] = false;
		return;
	}
	Time_End[client] = false;
	return;
}