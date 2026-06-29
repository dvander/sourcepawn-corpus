#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new weapon_choose[MAXPLAYERS+1];
#define PLUGIN_VERSION "v1.0 REDUX by Franc1sco franug"

new Handle:cvarVersion;

public Plugin:myinfo =
{
	name = "Knife Get (Menu)",
	author = "Dk--",
	description = "Open Menu with knifes",
	version = "PLUGIN_VERSION"
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	cvarVersion = CreateConVar("sm_knife_version",PLUGIN_VERSION,"Version of plugin",FCVAR_NOTIFY);
	SetConVarString(cvarVersion,PLUGIN_VERSION);
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
}

public Action:Event_Say(clientIndex, const String:command[], arg)
{
	if (clientIndex != 0 )
	{
		// Retrieve and clean up text.
		decl String:text[24];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
	
		if (StrEqual(text, "!knife", false))
		{
				KnifeMenu(clientIndex);
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public OnPluginEnd()
{
	CloseHandle(cvarVersion);
}

public OnClientPostAdminCheck(client)
{
	CreateTimer(15.0, Timer_knifemsg, client);
	weapon_choose[client] = 0;
} 

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsPlayerAlive(client))
	{
		return;
	}

	CreateTimer(2.0, SpawnKnife, client);
}

public Action:SpawnKnife(Handle:timer, any:client)
{
	Giveknife(client);
}

public Action:Timer_knifemsg(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		DID(client);

}

KnifeMenu(client)
{
	DID(client);
	PrintToConsole(client, "Menu of knives is open");
}

public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Choose your knife");
	AddMenuItem(menu, "option2", "Bayonet");
	AddMenuItem(menu, "option3", "Gut");
	AddMenuItem(menu, "option4", "Flip");
	AddMenuItem(menu, "option5", "M9 Bayonet");
	AddMenuItem(menu, "option6", "Karambit");
	AddMenuItem(menu, "option7", "Golden");
	AddMenuItem(menu, "option8", "Huntsman");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 0);
	
	return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if ( strcmp(info,"option2") == 0 ) 
		{     
			weapon_choose[client] = 1;
			PrintToChat(client, " \x04 Now you have the knife: Bayonet!!!");
			Giveknife(client);	
		}
	   
		else if ( strcmp(info,"option3") == 0 ) 
		{
			weapon_choose[client] = 2;
			PrintToChat(client, " \x04 Now you have the knife: Gut!!!");
			Giveknife(client);	
		}
			
		else if ( strcmp(info,"option4") == 0 ) 
		{
			weapon_choose[client] = 3;
			PrintToChat(client, " \x04 Now you have the knife: Flip!!!");
			Giveknife(client);	
		}
		
		else if ( strcmp(info,"option5") == 0 ) 
		{
			weapon_choose[client] = 4;
			PrintToChat(client, " \x04 Now you have the knife: Bayonet!!!");
			Giveknife(client);	
		}
		
		else if ( strcmp(info,"option6") == 0 ) 
		{
			weapon_choose[client] = 5;
			PrintToChat(client, " \x04 Now you have the knife: Karambit!!!");
			Giveknife(client);	
		}
					
		else if ( strcmp(info,"option7") == 0 ) 
		{
			weapon_choose[client] = 6;
			PrintToChat(client, " \x04 Now you have the knife: Golden!!!");
			Giveknife(client);	
		}
		else if ( strcmp(info,"option8") == 0 ) 
		{
			weapon_choose[client] = 7;
			PrintToChat(client, " \x04 Now you have the knife: Tactical!!!");
			Giveknife(client);	
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Giveknife(client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	if(iWeapon == INVALID_ENT_REFERENCE) return;
	
	new iItem;
	switch(weapon_choose[client]) {
		case 1:
		{
			RemovePlayerItem(client, iWeapon); 
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_bayonet");
		}
		case 2: 
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_knife_gut");
		}
		case 3: 
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_knife_flip");
		}
		case 4:  
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");
		}
		case 5: 
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_knife_karambit");}
		case 6: 
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_knifegg");
		}
		case 7: 
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_knife_tactical");
		}
 		default: {return;}
	}
	if(iItem != 0)
		EquipPlayerWeapon(client, iItem);
}
