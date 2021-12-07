#include <sourcemod>

new bool:RedChat[MAXPLAYERS+1] = {false,...};
new bool:BlueChat[MAXPLAYERS+1] = {false,...};
new bool:GreenChat[MAXPLAYERS+1] = {false,...};
new bool:LGreenChat[MAXPLAYERS+1] = {false,...};
new bool:OrangeChat[MAXPLAYERS+1] = {false,...};
new bool:PinkChat[MAXPLAYERS+1] = {false,...};

new Handle:CMenu_Enabled = INVALID_HANDLE;
new Handle:ColorMenu;

public Plugin:myinfo =
{
	name = "Chat Color Menu",
	author = "Marcus",
	description = "A menu that chooses your chat Color.",
	version = "1.0.0",
	url = "http://snbx.info"
};

public OnClientPostAdminCheck(client)
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID)
	{
		RedChat[client] = false;
		BlueChat[client] = false;
		OrangeChat[client] = false;
		GreenChat[client] = false;
		LGreenChat[client] = false;
		PinkChat[client] = false;
	} else {
		RedChat[client] = false;
		BlueChat[client] = false;
		OrangeChat[client] = false;
		GreenChat[client] = false;
		LGreenChat[client] = false;
		PinkChat[client] = false;
	}
}

public OnMapStart()
{
	ColorMenu = BuildColorMenu();
}

public OnPluginStart()
{
	RegAdminCmd("sm_cmenu", Command_CMenu, 0, "A menu that lets a player or admin decide their chat Color.");
	CMenu_Enabled = CreateConVar("sm_cmenu_enabled", "1", "This enables or disables the use of the Chat Colors Menu.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AddCommandListener(HookPlayerChat, "say");
}

public OnMapEnd()
{
	if (ColorMenu != INVALID_HANDLE)
	{
		CloseHandle(ColorMenu);
		ColorMenu = INVALID_HANDLE;
	}
}

public Menu_CColors(Handle:colors, MenuAction:action, client, param2)
{
	if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayMenu(ColorMenu, client, 20);
		}
	}
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(colors, param2, info, sizeof(info));
		if (StrEqual(info, "red_chat"))
		{
			RedChat[client] = true;
			BlueChat[client] = false;
			OrangeChat[client] = false;
			GreenChat[client] = false;
			LGreenChat[client] = false;
			PinkChat[client] = false;
		} else if (StrEqual(info, "blue_chat"))
		{
			RedChat[client] = false;
			BlueChat[client] = true;
			OrangeChat[client] = false;
			GreenChat[client] = false;
			LGreenChat[client] = false;
			PinkChat[client] = false;
		} else if (StrEqual(info, "orange_chat"))
		{
			RedChat[client] = false;
			BlueChat[client] = false;
			OrangeChat[client] = true;
			GreenChat[client] = false;
			LGreenChat[client] = false;
			PinkChat[client] = false;
		} else if (StrEqual(info, "green_chat"))
		{
			RedChat[client] = false;
			BlueChat[client] = false;
			OrangeChat[client] = false;
			GreenChat[client] = true;
			LGreenChat[client] = false;
			PinkChat[client] = false;
		} else if (StrEqual(info, "lgreen_chat"))
		{
			RedChat[client] = false;
			BlueChat[client] = false;
			OrangeChat[client] = false;
			GreenChat[client] = false;
			LGreenChat[client] = true;
			PinkChat[client] = false;
		} else if (StrEqual(info, "pink_chat"))
		{
			RedChat[client] = false;
			BlueChat[client] = false;
			OrangeChat[client] = false;
			GreenChat[client] = false;
			LGreenChat[client] = false;
			PinkChat[client] = true;
		} else if (StrEqual(info, "reset_color"))
		{
			RedChat[client] = false;
			BlueChat[client] = false;
			OrangeChat[client] = false;
			GreenChat[client] = false;
			LGreenChat[client] = false;
			PinkChat[client] = false;
		}
	}
}

Handle:BuildColorMenu()
{
	new Handle:colors = CreateMenu(Menu_CColors);
	SetMenuTitle(colors, "Chat Colors Menu:");
	AddMenuItem(colors, "red_chat", "Red");
	AddMenuItem(colors, "blue_chat", "Blue");
	AddMenuItem(colors, "green_chat", "Green");
	AddMenuItem(colors, "lgreen_chat", "Light-Green");
	AddMenuItem(colors, "orange_chat", "Orange");
	AddMenuItem(colors, "pink_chat", "Pink");
	AddMenuItem(colors, "reset_color", "Reset Chat Color");
	SetMenuExitBackButton(colors, true);
	return colors;
}

public Action:Command_CMenu(client, args)
{
	if (GetConVarInt(CMenu_Enabled))
	{
		DisplayMenu(ColorMenu, client, 20);
	} else
	{
		PrintToChat2(client, "\x070069DC[Notice]\x01 This server has disabled the Chat Color Menu.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:HookPlayerChat(client, const String:command[], args)
{
	decl String:szText[256];
	szText[0] = '\0';
	GetCmdArg(1, szText, sizeof(szText));
	
	if (szText[0] != '/' && szText[0] != '!')
	{
		if (IsClientInGame(client) && RedChat[client])
		{
			PrintToChatAll2("\x03%N:\x01 \x07FF0000%s\x01", client, szText);
			return Plugin_Handled;
		}
		if (IsClientInGame(client) && OrangeChat[client])
		{
			PrintToChatAll2("\x03%N:\x01 \x07FF6600%s\x01", client, szText);
			return Plugin_Handled;
		}
		if (IsClientInGame(client) && BlueChat[client])
		{
			PrintToChatAll2("\x03%N:\x01 \x07003EFF%s\x01", client, szText);
			return Plugin_Handled;
		}
		if (IsClientInGame(client) && GreenChat[client])
		{
			PrintToChatAll2("\x03%N:\x01 \x07008000%s\x01", client, szText);
			return Plugin_Handled;
		}
		if (IsClientInGame(client) && LGreenChat[client])
		{
			PrintToChatAll2("\x03%N:\x01 \x0700CD00%s\x01", client, szText);
			return Plugin_Handled;
		}
		if (IsClientInGame(client) && PinkChat[client])
		{
			PrintToChatAll2("\x03%N:\x01 \x07EE1289%s\x01", client, szText);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Handled;
}
public PrintToChat2(client, const String:format[], any:...)
{
	decl String:buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	new Handle:bf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}
public PrintToChatAll2(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	new Handle:bf = StartMessageAll("SayText2", USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}