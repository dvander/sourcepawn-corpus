#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Private Voice",
	author = "RpM",
	description = "Allows you to start a private voice chat with some player.",
	version = "1.0",
	url = "www.LiquidBR.com"
};

new userid2;
new client1;
new client2;
new String:name1[70];
new String:name2[70];
new bool:onpvt[MAXPLAYERS+1];
new pvtwith[MAXPLAYERS+1] = -1;

public OnPluginStart()
{
	RegConsoleCmd("pvtvoice", pvt, "Starts a private microfone voice with some player");
	ServerCommand("sv_hudhint_sound 0");
}

public Action:pvt(client, args)
{
	if(!onpvt[client])
	{
		new Handle:menu = CreateMenu(HandlerCallback);
		SetMenuTitle(menu, "Pvt voice");
		SetMenuPagination(menu, 8);
		for(new i=1; i <= MaxClients; i++) {
			if (rpm_Check(i) && !onpvt[i] && i != client) {
				decl String:clientname[70];
				Format(clientname, sizeof(clientname), "%N", i);
				decl String:sUserID[10];
				new UserID = GetClientUserId(i);
				IntToString(UserID,sUserID,sizeof(sUserID));
				AddMenuItem(menu,sUserID,clientname);
			}
		}
		SetMenuExitBackButton(menu, false);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	} else
	{
		new Handle:cancel = CreateMenu(HandlerCallbackCancel);
		SetMenuPagination(cancel, 8);
		decl String:Format1[200];
		decl String:name[70];
		GetClientName(pvtwith[client], name, sizeof(name));
		Format(Format1, sizeof(Format1), "Cancel pvtvoice with %s ?", name);
		AddMenuItem(cancel, "sim", "Yes");
		AddMenuItem(cancel, "nao", "No");
		
		SetMenuTitle(cancel, Format1);
		SetMenuExitBackButton(cancel, false);
		SetMenuExitButton(cancel, true);
		DisplayMenu(cancel, client, 20);
	}
}

public HandlerCallback(Handle:menu, MenuAction:action, param1, param2) {
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	} else if(action == MenuAction_Select)
	{
		new String:menu_item_title[50];
		GetMenuItem(menu, param2, menu_item_title, sizeof(menu_item_title));
		
		client1 = param1;
		
		userid2 = StringToInt(menu_item_title);
		client2 = GetClientOfUserId(userid2);
		
		GetClientName(client1, name1, sizeof(name1));
		GetClientName(client2, name2, sizeof(name2));
		
		rpm_PrintToChatTag(client1, "Pvt Voice", "A private voice invite was send to %s", name2);
		SendConvite(client1, client2);
	}
}

public SendConvite(aclient, bclient)
{
	if(!onpvt[bclient])
	{
		new Handle:invite = CreateMenu(HandlerCallbackInvite);
		SetMenuPagination(invite, 8);
		decl String:Format1[200];
		Format(Format1, sizeof(Format1), "The player %s invited you to private voice", name1);
		
		SetMenuTitle(invite, Format1);
		AddMenuItem(invite, "sim", "Accept");
		AddMenuItem(invite, "nao", "Refuse");
		
		SetMenuExitBackButton(invite, false);
		SetMenuExitButton(invite, true);
		DisplayMenu(invite, bclient, 20);
	} else
	{
		rpm_PrintToChatTag(aclient, "Pvt Voice", "The player %N already is in a private chat", client2);
	}
}

public HandlerCallbackInvite(Handle:invite, MenuAction:action, param1, param2) {
	if(action == MenuAction_End)
	{
		CloseHandle(invite);
	} else if(action == MenuAction_Select)
	{
		new String:menu_item_title[50];
		GetMenuItem(invite, param2, menu_item_title, sizeof(menu_item_title));
		
		if(StrEqual(menu_item_title, "sim", false))
		{
			if(!onpvt[client2])
				StartPvt(client1, client2);
			else
				rpm_PrintToChatTag(client1, "Pvt Voice", "The player %N already is in a private chat", client2);
		}
	}
}

public HandlerCallbackCancel(Handle:cancel, MenuAction:action, param1, param2) {
	if(action == MenuAction_End)
	{
		CloseHandle(cancel);
	} else if(action == MenuAction_Select)
	{
		new String:menu_item_title[50];
		GetMenuItem(cancel, param2, menu_item_title, sizeof(menu_item_title));
		
		if(StrEqual(menu_item_title, "sim", false))
		{
			new client2c = pvtwith[param1];
			if(onpvt[client2c])
			{
				StopPvt(param1, client2c);
			}
		}
	}
}

StartPvt(aclient, bclient)
{
	if(!onpvt[aclient] && !onpvt[bclient])
	{
		onpvt[aclient] = true;
		onpvt[bclient] = true;
		pvtwith[aclient] = bclient;
		pvtwith[bclient] = aclient;
		rpm_PrintToChatTag(aclient, "Pvt Voice", "You started a private voice with %N!", bclient);
		rpm_PrintToChatTag(bclient, "Pvt Voice", "The player %N started a private voice with you!", aclient);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(rpm_Check(i) && i != aclient)
				rpm_MuteClientTo(bclient, i);
		}
		for(new i = 1; i <= MaxClients; i++)
		{
			if(rpm_Check(i) && i != bclient)
				rpm_MuteClientTo(aclient, i);
		}
	}
}

StopPvt(aclient, bclient)
{
	if(pvtwith[aclient] == bclient && pvtwith[bclient] == aclient)
	{
		onpvt[aclient] = false;
		onpvt[bclient] = false;
		pvtwith[aclient] = -1;
		pvtwith[bclient] = -1;
		rpm_PrintToChatTag(aclient, "Pvt Voice", "You canceled a private voice with %N", bclient);
		rpm_PrintToChatTag(bclient, "Pvt Voice", "The player %N canceled a private voice with you", aclient);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(rpm_Check(i))
				rpm_UnmuteClientTo(bclient, i);
		}
		for(new i = 1; i <= MaxClients; i++)
		{
			if(rpm_Check(i))
				rpm_UnmuteClientTo(aclient, i);
		}
	}
}

public OnGameFrame()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(rpm_Check(i) && onpvt[i])
		{
			decl String:name[70];
			GetClientName(pvtwith[i], name, sizeof(name));
			PrintHintText(i, "Pvt voice: %s", name);
		}
	}
}

stock rpm_MuteClientTo(speaker, listener)
{
	SetListenOverride(listener, speaker, Listen_No);
}

stock rpm_UnmuteClientTo(speaker, listener)
{
	SetListenOverride(listener, speaker, Listen_Yes);
}

stock bool:rpm_Check(client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		return true;
	else
		return false;
}

stock rpm_PrintToChatTag(client, const String:pluginName[], const String:text[], any:...)
{
	decl String:txt[1040];
	VFormat(txt, sizeof(txt), text, 4);
	
	PrintToChat(client, "\x04[%s \x01By.:RpM\x04]\x03 %s", pluginName, txt);
}