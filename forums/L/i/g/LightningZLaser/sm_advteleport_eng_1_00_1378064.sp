#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "SM Advanced Teleport",
	author = "LightningZLaser",
	description = "An advanced admin teleport menu",
	version = "1.0",
	url = "www.FireWaLLCS.net/forums"
}

new Float:Saveloc1[MAXPLAYERS + 1][3];
new Float:Saveloc2[MAXPLAYERS + 1][3];
new Float:Saveloc3[MAXPLAYERS + 1][3];
new targetid[MAXPLAYERS + 1];
new autotpactivate[MAXPLAYERS + 1];
new autotpslot[MAXPLAYERS + 1];
new slot1used[MAXPLAYERS + 1];
new slot2used[MAXPLAYERS + 1];
new slot3used[MAXPLAYERS + 1];
new g_CollisionOffset;
new MessageEnable = 1; // CHANGE THIS VALUE TO 0 TO TURN OFF PUBLIC MESSAGES

public OnPluginStart()
{
	RegAdminCmd("teleport", ConsoleCmd, ADMFLAG_CUSTOM2); //For admins to be able to use the teleport command, they must have the "p" flag in their flags
	RegAdminCmd("say !teleport", ConsoleCmd, ADMFLAG_CUSTOM2); //If you know how to and want to change the flag alphabet, replace ADM_CUSTOM2 with something else (ADM_GENERIC means all sourcemod admins will have the access, and ADM_CUSTOM1 is the "o" flag)
	RegAdminCmd("say_team !teleport", ConsoleCmd, ADMFLAG_CUSTOM2);
	HookEvent("round_start", GameStart);
	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
}

public Action:ConsoleCmd(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "[SM] Advanced Teleport");
	//AddMenuItem(menu, "Teleport Entity to Slot 1", "Teleport Entity to Slot 1");
	AddMenuItem(menu, "Teleport To Player", "Teleport To Player");
	AddMenuItem(menu, "Teleport Player To Me", "Teleport Player To Me");
	AddMenuItem(menu, "Save Location for Teleport", "Save Spot for Teleport");
	AddMenuItem(menu, "Teleport To Saved Location", "Teleport To Saved Location");
	AddMenuItem(menu, "Teleport A Player to Saved Location", "Teleport A Player to Saved Location");
	AddMenuItem(menu, "Teleport A Player to Another", "Teleport A Player to Another");
	if (autotpactivate[client] == 0)
	{
		AddMenuItem(menu, "Enable Auto-Teleport", "Enable Auto-Teleport");
	}
	if (autotpactivate[client] == 1)
	{
		AddMenuItem(menu, "Disable Auto-Teleport", "Disable Auto-Teleport");
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		new String:name[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(strcmp(info, "Teleport Entity to Slot 1") == 0)
		{
			if (slot1used[client] == 1)
			{
				new entityindex = GetClientAimTarget(client, false);
				if (entityindex != -1)
				{
					TeleportEntity(entityindex, Saveloc1[client], NULL_VECTOR, NULL_VECTOR);
					PrintToChat(client, "\x04(TELEPORT) \x01You have teleported an entity to \x03Slot 1\x01!");
				}
				else
				{
					PrintToChat(client, "\x04(TELEPORT) \x01No entity found!");
				}
			}
			if (slot1used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
			DisplayMenu(menu, client, 0);
		}
		if(strcmp(info, "Teleport To Player") == 0)
		{
			new Handle:menuteleportto = CreateMenu(MenuHandler2);
			SetMenuTitle(menuteleportto, "Select Player to Teleport To");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuteleportto, name, name);
				}
			}
			SetMenuExitButton(menuteleportto, true);
			DisplayMenu(menuteleportto, client, 0);
		}
		if(strcmp(info, "Teleport Player To Me") == 0)
		{
			new Handle:menuteleporttome = CreateMenu(MenuHandler3);
			SetMenuTitle(menuteleporttome, "Select Player to Teleport to You");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuteleporttome, name, name);
				}
			}
			SetMenuExitButton(menuteleporttome, true);
			DisplayMenu(menuteleporttome, client, 0);
		}
		if(strcmp(info, "Save Location for Teleport") == 0)
		{
			new Handle:menusaveloc = CreateMenu(MenuHandler1);
			SetMenuTitle(menusaveloc, "Select Slot to Save Location");
			AddMenuItem(menusaveloc, "Save to Slot 1", "Save to Slot 1");
			AddMenuItem(menusaveloc, "Save to Slot 2", "Save to Slot 2");
			AddMenuItem(menusaveloc, "Save to Slot 3", "Save to Slot 3");
			SetMenuExitButton(menusaveloc, true);
			DisplayMenu(menusaveloc, client, 0);
		}
		if(strcmp(info, "Save to Slot 1") == 0)
		{
			slot1used[client] = 1;
			GetClientAbsOrigin(client, Saveloc1[client]);
			PrintToChat(client, "\x04(TELEPORT) \x01Saved location to \x03Slot 1");
		}
		if(strcmp(info, "Save to Slot 2") == 0)
		{
			slot2used[client] = 1;
			GetClientAbsOrigin(client, Saveloc2[client]);
			PrintToChat(client, "\x04(TELEPORT) \x01Saved location to \x03Slot 2");
		}
		if(strcmp(info, "Save to Slot 3") == 0)
		{
			slot3used[client] = 1;
			GetClientAbsOrigin(client, Saveloc3[client]);
			PrintToChat(client, "\x04(TELEPORT) \x01Saved location to \x03Slot 3");
		}
		if(strcmp(info, "Teleport To Saved Location") == 0)
		{
			new Handle:menutptoslot = CreateMenu(MenuHandler1);
			SetMenuTitle(menutptoslot, "Select Slot to Teleport To");
			AddMenuItem(menutptoslot, "Teleport to Slot 1", "Teleport to Slot 1");
			AddMenuItem(menutptoslot, "Teleport to Slot 2", "Teleport to Slot 2");
			AddMenuItem(menutptoslot, "Teleport to Slot 3", "Teleport to Slot 3");
			SetMenuExitButton(menutptoslot, true);
			DisplayMenu(menutptoslot, client, 0);
		}
		if(strcmp(info, "Teleport to Slot 1") == 0)
		{
			if (slot1used[client] == 1)
			{
				TeleportEntity(client, Saveloc1[client], NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, "\x04(TELEPORT) \x01You have teleported to \x03Slot 1\x01!");
			}
			if (slot1used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Teleport to Slot 2") == 0)
		{
			if (slot2used[client] == 1)
			{
				TeleportEntity(client, Saveloc2[client], NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, "\x04(TELEPORT) \x01You have teleported to \x03Slot 2\x01!");
			}
			if (slot2used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Teleport to Slot 3") == 0)
		{
			if (slot3used[client] == 1)
			{
				TeleportEntity(client, Saveloc3[client], NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, "\x04(TELEPORT) \x01You have teleported to \x03Slot 3\x01!");
			}
			if (slot3used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Teleport A Player to Saved Location") == 0)
		{
			new Handle:playertp = CreateMenu(MenuHandler1);
			SetMenuTitle(playertp, "Select Slot to Teleport Player To");
			AddMenuItem(playertp, "Teleport Player to Slot 1", "Teleport Player to Slot 1");
			AddMenuItem(playertp, "Teleport Player to Slot 2", "Teleport Player to Slot 2");
			AddMenuItem(playertp, "Teleport Player to Slot 3", "Teleport Player to Slot 3");
			SetMenuExitButton(playertp, true);
			DisplayMenu(playertp, client, 0);
		}
		if(strcmp(info, "Teleport Player to Slot 1") == 0)
		{
			if (slot1used[client] == 1)
			{
				new Handle:tptoslot1 = CreateMenu(MenuHandler4);
				SetMenuTitle(tptoslot1, "Select Player to Teleport");
				for (new i = 1; i <= GetMaxClients(); i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i))
					{
						GetClientName(i, name, sizeof(name));
						AddMenuItem(tptoslot1, name, name);
					}
				}
				SetMenuExitButton(tptoslot1, true);
				DisplayMenu(tptoslot1, client, 0);
			}
			if (slot1used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Teleport Player to Slot 2") == 0)
		{
			if (slot2used[client] == 1)
			{
				new Handle:tptoslot2 = CreateMenu(MenuHandler5);
				SetMenuTitle(tptoslot2, "Select Player to Teleport");
				for (new i = 1; i <= GetMaxClients(); i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i))
					{
						GetClientName(i, name, sizeof(name));
						AddMenuItem(tptoslot2, name, name);
					}
				}
				SetMenuExitButton(tptoslot2, true);
				DisplayMenu(tptoslot2, client, 0);
			}
			if (slot2used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Teleport Player to Slot 3") == 0)
		{
			if (slot3used[client] == 1)
			{
				new Handle:tptoslot3 = CreateMenu(MenuHandler6);
				SetMenuTitle(tptoslot3, "Select Player to Teleport");
				for (new i = 1; i <= GetMaxClients(); i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i))
					{
						GetClientName(i, name, sizeof(name));
						AddMenuItem(tptoslot3, name, name);
					}
				}
				SetMenuExitButton(tptoslot3, true);
				DisplayMenu(tptoslot3, client, 0);
			}
			if (slot3used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Teleport A Player to Another") == 0)
		{
			new Handle:playertarget = CreateMenu(MenuHandler7);
			SetMenuTitle(playertarget, "Select Player to Teleport To");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(playertarget, name, name);
				}
			}
			SetMenuExitButton(playertarget, true);
			DisplayMenu(playertarget, client, 0);
		}
		if(strcmp(info, "Enable Auto-Teleport") == 0)
		{
			new Handle:enabletp = CreateMenu(MenuHandler1);
			SetMenuTitle(enabletp, "Select Slot to Activate");
			AddMenuItem(enabletp, "Activate Slot 1", "Activate Slot 1");
			AddMenuItem(enabletp, "Activate Slot 2", "Activate Slot 2");
			AddMenuItem(enabletp, "Activate Slot 3", "Activate Slot 3");
			SetMenuExitButton(enabletp, true);
			DisplayMenu(enabletp, client, 0);
		}
		if(strcmp(info, "Disable Auto-Teleport") == 0)
		{
			autotpactivate[client] = 0;
			PrintToChat(client, "\x04(TELEPORT) \x01You will no longer be auto-teleported.");
		}
		if(strcmp(info, "Activate Slot 1") == 0)
		{
			if (slot1used[client] == 1)
			{
				autotpactivate[client] = 1;
				autotpslot[client] = 1;
				PrintToChat(client, "\x04(TELEPORT) \x01You will now be teleported to \x03Slot 1 \x01at the beginning of each round.");
			}
			if (slot1used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Activate Slot 2") == 0)
		{
			if (slot2used[client] == 1)
			{
				autotpactivate[client] = 1;
				autotpslot[client] = 2;
				PrintToChat(client, "\x04(TELEPORT) \x01You will now be teleported to \x03Slot 2 \x01at the beginning of each round.");
			}
			if (slot2used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
		if(strcmp(info, "Activate Slot 3") == 0)
		{
			if (slot3used[client] == 1)
			{
				autotpactivate[client] = 1;
				autotpslot[client] = 3;
				PrintToChat(client, "\x04(TELEPORT) \x01You will now be teleported to \x03Slot 3 \x01at the beginning of each round.");
			}
			if (slot3used[client] == 0)
			{
				PrintToChat(client, "\x04(TELEPORT) \x03ERROR: You need to save a location first!");
			}
		}
	}
}



public MenuHandler2(Handle:menuteleportto, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		new Float:vec[3];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(menuteleportto, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(i, vec);
					TeleportEntity(client, vec, NULL_VECTOR, NULL_VECTOR);
					if (MessageEnable == 1)
					{
						PrintToChatAll("\x04(TELEPORT) [ADMIN] \x03%s \x01teleported to \x03%s", nameclient1, nameclient2);
					}
					if (MessageEnable == 0)
					{
						PrintToChat(client, "\x04(TELEPORT) \x01You teleported to \x03%s", nameclient2);
					}
					DisplayMenu(menuteleportto, client, 0);
					SetEntData(client, g_CollisionOffset, 2, 4, true);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, offnoblockclient, client);
					CreateTimer(5.0, offnoblocki, i);
				}
			}
		}
	}
}

public MenuHandler3(Handle:menuteleporttome, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		new Float:vec[3];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(menuteleporttome, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(client, vec);
					TeleportEntity(i, vec, NULL_VECTOR, NULL_VECTOR);
					if (MessageEnable == 1)
					{
						PrintToChatAll("\x04(TELEPORT) [ADMIN] \x03%s \x01teleported \x03%s \x01to \x03%s", nameclient1, nameclient2, nameclient1);
					}
					if (MessageEnable == 0)
					{
						PrintToChat(client, "\x04(TELEPORT) \x01You teleported \x03%s \x01to \x03%s", nameclient2, nameclient1);
					}
					DisplayMenu(menuteleporttome, client, 0);
					SetEntData(client, g_CollisionOffset, 2, 4, true);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, offnoblockclient, client);
					CreateTimer(5.0, offnoblocki, i);
				}
			}
		}
	}
}

public MenuHandler4(Handle:tptoslot1, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(tptoslot1, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					TeleportEntity(i, Saveloc1[client], NULL_VECTOR, NULL_VECTOR);
					if (MessageEnable == 1)
					{
						PrintToChatAll("\x04(TELEPORT) [ADMIN] \x03%s \x01teleported \x03%s \x01to a saved location!", nameclient1, nameclient2);
					}
					if (MessageEnable == 0)
					{
						PrintToChat(client, "\x04(TELEPORT) \x01You teleported \x03%s \x01to a saved location!", nameclient2);
					}
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, offnoblocki, i);
				}
			}
		}
	}
}

public MenuHandler5(Handle:tptoslot2, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(tptoslot2, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					TeleportEntity(i, Saveloc2[client], NULL_VECTOR, NULL_VECTOR);
					if (MessageEnable == 1)
					{
						PrintToChatAll("\x04(TELEPORT) [ADMIN] \x03%s \x01teleported \x03%s \x01to a saved location!", nameclient1, nameclient2);
					}
					if (MessageEnable == 0)
					{
						PrintToChat(client, "\x04(TELEPORT) \x01You teleported \x03%s \x01to a saved location!", nameclient2);
					}
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, offnoblocki, i);
				}
			}
		}
	}
}

public MenuHandler6(Handle:tptoslot3, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(tptoslot3, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					TeleportEntity(i, Saveloc1[client], NULL_VECTOR, NULL_VECTOR);
					if (MessageEnable == 1)
					{
						PrintToChatAll("\x04(TELEPORT) [ADMIN] \x03%s \x01teleported \x03%s \x01to a saved location!", nameclient1, nameclient2);
					}
					if (MessageEnable == 0)
					{
						PrintToChat(client, "\x04(TELEPORT) \x01You teleported \x03%s \x01to a saved location!", nameclient2);
					}
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, offnoblocki, i);
				}
			}
		}
	}
}

public MenuHandler7(Handle:playertarget, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		new String:name[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(playertarget, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					targetid[client] = i;
					new Handle:player2tp = CreateMenu(MenuHandler8);
					SetMenuTitle(player2tp, "Select Player to Teleport");
					for (new k = 1; k <= GetMaxClients(); k++)
					{
						if (IsClientInGame(k) && IsPlayerAlive(k))
						{
							GetClientName(k, name, sizeof(name));
							AddMenuItem(player2tp, name, name);
						}
					}
					SetMenuExitButton(player2tp, true);
					DisplayMenu(player2tp, client, 0);					
				}
			}
		}
	}
}

public MenuHandler8(Handle:player2tp, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:nameclientadmin[64];
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		new Float:vec[3];
		GetClientName(client, nameclientadmin, sizeof(nameclientadmin));
		GetClientName(targetid[client], nameclient1, sizeof(nameclient1));
		GetMenuItem(player2tp, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(targetid[client], vec);
					TeleportEntity(i, vec, NULL_VECTOR, NULL_VECTOR);
					if (MessageEnable == 1)
					{
						PrintToChatAll("\x04(TELEPORT) [ADMIN] \x03%s \x01teleported \x03%s \x01to \x03%s\x01!", nameclientadmin, nameclient2, nameclient1);
					}
					if (MessageEnable == 0)
					{
						PrintToChat(client, "\x04(TELEPORT) \x01You teleported \x03%s \x01to \x03%s\x01!", nameclient2, nameclient1);
					}
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, offnoblocki, i);
					SetEntData(targetid[client], g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, offnoblockarray, client);
				}
			}
		}
	}
}

public Action:GameStart(Handle:Event, const String:Name[], bool:Broadcast)
{
	CreateTimer(5.0, LoadStuff);
}

public Action:LoadStuff(Handle:timer)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if ((IsClientInGame(i)) && (autotpactivate[i] == 1))
		{
			if (autotpslot[i] == 1)
			{
				TeleportEntity(i, Saveloc1[i], NULL_VECTOR, NULL_VECTOR);
				SetEntData(i, g_CollisionOffset, 2, 4, true);
				CreateTimer(5.0, offnoblocki, i);
			}
			if (autotpslot[i] == 2)
			{
				TeleportEntity(i, Saveloc2[i], NULL_VECTOR, NULL_VECTOR);
				SetEntData(i, g_CollisionOffset, 2, 4, true);
				CreateTimer(5.0, offnoblocki, i);
			}
			if (autotpslot[i] == 3)
			{
				TeleportEntity(i, Saveloc3[i], NULL_VECTOR, NULL_VECTOR);
				SetEntData(i, g_CollisionOffset, 2, 4, true);
				CreateTimer(5.0, offnoblocki, i);
			}
		}
	}
}

public OnMapStart()
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		autotpactivate[i] = 0;
		slot1used[i] = 0;
		slot2used[i] = 0;
		slot3used[i] = 0;
	}
}

public Action:offnoblockclient(Handle:timer, any:client)
{
	SetEntData(client, g_CollisionOffset, 5, 4, true);
}

public Action:offnoblocki(Handle:timer, any:i)
{
	SetEntData(i, g_CollisionOffset, 5, 4, true);
}

public Action:offnoblockarray(Handle:timer, any:client)
{
	SetEntData(targetid[client], g_CollisionOffset, 5, 4, true);
}