#include <sourcemod>
#include <sdktools>
#pragma semicolon 1


new g_DontShowAskMenu[MAXPLAYERS+1];
new PlayerArray[MAXPLAYERS+1];




public Plugin:myinfo = 
{
	name = "Teleport to",
	author = "Impact",
	description = "Coming soon?",
	version = "0.1",
	url = "http://gugyclan.eu"
}





public OnPluginStart()
{
	RegConsoleCmd("sm_tpto", Command_TpTo);
	RegConsoleCmd("sm_tptg", Command_TpTg);
}





public Action:Command_TpTo(client, args)
{
	if(IsClientValid(client))
	{
		if(IsPlayerAlive(client))
		{
			if(GetClientCount(true) > 1)
			{
				DisplayTpMenu(client);
			}
			else
			{
				PrintToChat(client, "\x03Sorry, there is no other player");
			}
		}
		else
		{
			PrintToChat(client, "\x03Sorry, You can only use this while alive");
		}
	}
	
	
	return Plugin_Handled;
}





public Action:Command_TpTg(client, args)
{
	ToggleNotify(client);	
	
	return Plugin_Handled;
}





ToggleNotify(client)
{
	if(IsClientValid(client))
	{
		if(g_DontShowAskMenu[client])
		{
			g_DontShowAskMenu[client] = false;
		}
		else
		{
			g_DontShowAskMenu[client] = true;
		}
		
		PrintToChat(client, "\x03Teleport notification has toggled to %s", g_DontShowAskMenu[client] ? "false" : "true");
	}
}





DisplayTpMenu(client)
{
	new Handle:menu = CreateMenu(TpToHandler);
	SetMenuTitle(menu, "Select a player to teleport to");
	
	new String:NameBuffer[MAX_NAME_LENGTH];
	new count;
	
	for(new i; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsPlayerAlive(i) && !g_DontShowAskMenu[i])
		{
			Format(NameBuffer, sizeof(NameBuffer), "%N", i);
			
			// Store the player
			PlayerArray[count] = i;
			
			AddMenuItem(menu, "", NameBuffer);
			count++;
		}
	}
	
	if(GetMenuItemCount(menu) > 0)
	{
		DisplayMenu(menu, client, 25);
	}
	else
	{
		PrintToChat(client, "\x03It seems all players are dead");
	}
}





public TpToHandler(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		// For easier coding we store the selected client as target from our admin
		new Target = PlayerArray[param2];
		
		if(IsClientValid(Target))
		{
			if(IsFakeClient(Target))
			{
				Func_TpTo(client, Target);
			}
			else
			{
				new Handle:menu2 = CreateMenu(AcceptTphandler);
				new String:CallerId[4];
				
				Format(CallerId, sizeof(CallerId), "%d", client);
				
				SetMenuTitle(menu2, "%N wants to teleport to you, are you okay with that?", client);
				
				AddMenuItem(menu2, CallerId, "Yes");
				AddMenuItem(menu2, CallerId, "No");
				AddMenuItem(menu2, CallerId, "Don't ask me again");
				
				DisplayMenu(menu2, Target, 10);
			}
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}





public AcceptTphandler(Handle:menu2, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		new CallerId;
		new String:CallerBuf[4];
		GetMenuItem(menu2, param2, CallerBuf, sizeof(CallerBuf));
		CallerId = StringToInt(CallerBuf);
		
		switch(param2)
		{
			// Yes
			case 0:
			{
				Func_TpTo(CallerId, client);
			}
			// No
			case 1:
			{
				if(IsClientValid(CallerId))
				{
					PrintToChat(CallerId, "\x03%N has denied your tp request", client);
				}
			}
			// Don'T ask me again
			case 2:
			{
				if(IsClientValid(client))
				{
					ToggleNotify(client);
				}
			}

		}
		
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
}





Func_TpTo(from, to)
{
	if(IsClientValid(from) && IsClientValid(to))
	{
		if(IsPlayerAlive(from) && IsPlayerAlive(to))
		{
			new Float:origin[3];
			
			GetClientAbsOrigin(to, origin);
			
			TeleportEntity(from, origin, NULL_VECTOR, NULL_VECTOR);
			
			PrintToChat(from, "\x03You have been teleported to %N", to);
			PrintToChat(to, "\x03%N has been teleported to you", from);
		}
		else
		{
			PrintToChat(from, "\x03There were problems while trying to teleport you to %N", to);
			PrintToChat(to, "\x03There were problems while trying to teleport %N to you", from);
		}
	}
}





stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MAXPLAYERS && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}