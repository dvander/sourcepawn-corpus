#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#pragma semicolon 1

#define PLUGIN_VERSION "1.4"

new Handle:cvarVersion;
new Handle:g_cookieKnife;
new knife_choice[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Knife Upgrade",
	author = "Klexen",
	description = "Choose and a save custom knife skin for this server.",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	cvarVersion = CreateConVar("sm_knifeupgrade_version",PLUGIN_VERSION,"Version of plugin",FCVAR_NOTIFY);
	SetConVarString(cvarVersion,PLUGIN_VERSION);
	
	g_cookieKnife = RegClientCookie("knife_choice", "", CookieAccess_Private);
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
}

public OnClientCookiesCached(client) {
	decl String:value[12];
	GetClientCookie(client, g_cookieKnife, value, sizeof(value));
	
	knife_choice[client] = StringToInt(value);
}

public Action:Event_Say(clientIndex, const String:command[], arg)
{
	
	if (clientIndex != 0 )
	{
		decl String:text[24];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
	
		if (StrEqual(text, "!knife", false))
		{
			KnifeMenu(clientIndex);
			return Plugin_Handled;
		} 
		else if (StrEqual(text, "!knief", false))
		{
			KnifeMenu(clientIndex);
			return Plugin_Handled;		
		}
		else if (StrEqual(text, "!knifes", false))
		{
			KnifeMenu(clientIndex);
			return Plugin_Handled;		
		}
		else if (StrEqual(text, "!knfie", false))
		{
			KnifeMenu(clientIndex);
			return Plugin_Handled;		
		}
		else if (StrEqual(text, "!knifw", false))
		{
			KnifeMenu(clientIndex);
			return Plugin_Handled;		
		}
		else if (StrEqual(text, "!knives", false))
		{
			KnifeMenu(clientIndex);
			return Plugin_Handled;		
		}
		else if (StrEqual(text, "!knif", false))
		{
			KnifeMenu(clientIndex);
			return Plugin_Handled;		
		}
		
		//Knife Shortcut Triggers
		
		if (StrEqual(text, "!bayonet", false))
		{
			SetBayonet(clientIndex);
			return Plugin_Handled;
		} 
		
		if (StrEqual(text, "!gut", false))
		{
			SetGut(clientIndex);
			return Plugin_Handled;
		} 
		
		if (StrEqual(text, "!flip", false))
		{
			SetFlip(clientIndex);
			return Plugin_Handled;
		} 
		
		if (StrEqual(text, "!m9", false))
		{
			SetM9(clientIndex);
			return Plugin_Handled;
		} 
		
		if (StrEqual(text, "!karambit", false))
		{
			SetKarambit(clientIndex);
			return Plugin_Handled;
		} 
		
		if (StrEqual(text, "!huntsman", false))
		{
			SetHuntsman(clientIndex);
			return Plugin_Handled;
		} 
		
		if (StrEqual(text, "!butterfly", false))
		{
			SetButterfly(clientIndex);
			return Plugin_Handled;
		} 
		
	}
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsPlayerAlive(client))
	{
		return;
	}
	CreateTimer(0.3, OnSpawn, client);
}

public Action:OnSpawn(Handle:timer, any:client)
{
	Equipknife(client);
}

Equipknife(client)
{	
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	if(iWeapon == INVALID_ENT_REFERENCE) return;
	
	new iItem;
	switch(knife_choice[client]) {
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
			iItem = GivePlayerItem(client, "weapon_knife_tactical");
		}
		case 7: 
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
			iItem = GivePlayerItem(client, "weapon_knife_butterfly");
		}
 		default: {return;}
	}

	if(IsValidClient(client, true) && iItem != 0)
		EquipPlayerWeapon(client, iItem);
	else {return;}
}

KnifeMenu(client)
{
	DID(client);
	PrintToConsole(client, "Knife menu is open");
}

SetBayonet(client)
{
	knife_choice[client] = 1;
	new String:knifeValue[] = "1";				
	SetClientCookie(client, g_cookieKnife, knifeValue);
	OnClientCookiesCached(client);
	PrintToChat(client, " \x04You have chosen the Bayonet knife!");
	PrintToChat(client, " \x07Your knife choice will be saved.");
	Equipknife(client);	
}

SetGut(client)
{
	knife_choice[client] = 2;
	new String:knifeValue[] = "2";				
	SetClientCookie(client, g_cookieKnife, knifeValue);
	OnClientCookiesCached(client);
	PrintToChat(client, " \x04You have chosen the Gut knife!");
	PrintToChat(client, " \x07Your knife choice will be saved.");
	Equipknife(client);	
}

SetFlip(client)
{
	knife_choice[client] = 3;
	new String:knifeValue[] = "3";				
	SetClientCookie(client, g_cookieKnife, knifeValue);
	OnClientCookiesCached(client);			
	PrintToChat(client, " \x04You have chosen the Flip knife!");
	PrintToChat(client, " \x07Your knife choice will be saved.");
	Equipknife(client);	
}

SetM9(client)
{
	knife_choice[client] = 4;
	new String:knifeValue[] = "4";				
	SetClientCookie(client, g_cookieKnife, knifeValue);
	OnClientCookiesCached(client);
	PrintToChat(client, " \x04You have chosen the M9-Bayonet knife!");
	PrintToChat(client, " \x07Your knife choice will be saved.");
	Equipknife(client);
}

SetKarambit(client)
{
	knife_choice[client] = 5;
	new String:knifeValue[] = "5";				
	SetClientCookie(client, g_cookieKnife, knifeValue);
	OnClientCookiesCached(client);
	PrintToChat(client, " \x04You have chosen the Karambit knife!");
	PrintToChat(client, " \x07Your knife choice will be saved.");
	Equipknife(client);	
}

SetHuntsman(client)
{
	knife_choice[client] = 6;
	new String:knifeValue[] = "6";				
	SetClientCookie(client, g_cookieKnife, knifeValue);
	OnClientCookiesCached(client);
	PrintToChat(client, " \x04You have chosen the Huntsman knife!");
	PrintToChat(client, " \x07Your knife choice will be saved.");
	Equipknife(client);	
}

SetButterfly(client)
{
	knife_choice[client] = 7;
	new String:knifeValue[] = "7";				
	SetClientCookie(client, g_cookieKnife, knifeValue);
	OnClientCookiesCached(client);
	PrintToChat(client, " \x04You have chosen the Butterfly knife!");
	PrintToChat(client, " \x07Your knife choice will be saved.");
	Equipknife(client);	
}

public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Choose your knife");
	AddMenuItem(menu, "option2", "!Bayonet");
	AddMenuItem(menu, "option3", "!Gut");
	AddMenuItem(menu, "option4", "!Flip");
	AddMenuItem(menu, "option5", "!M9");
	AddMenuItem(menu, "option6", "!Karambit");
	AddMenuItem(menu, "option7", "!Huntsman");
	AddMenuItem(menu, "option8", "!Butterfly");
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
		
		//Bayonet
		if ( strcmp(info,"option2") == 0 ) 
		{     
			SetBayonet(client);
		}
		//Gut
		else if ( strcmp(info,"option3") == 0 ) 
		{		
			SetGut(client);
		}	
		//Flip
		else if ( strcmp(info,"option4") == 0 ) 
		{
			SetFlip(client);
		}
		//M9-Bayonet
		else if ( strcmp(info,"option5") == 0 ) 
		{
			SetM9(client);
		}
		//Karambit
		else if ( strcmp(info,"option6") == 0 ) 
		{
			SetKarambit(client);
		}
		//Huntsman
		else if ( strcmp(info,"option7") == 0 ) 
		{
			SetHuntsman(client);
		}
		//Butterfly
		else if ( strcmp(info,"option8") == 0 ) 
		{
			SetButterfly(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public OnPluginEnd()
{
	CloseHandle(cvarVersion);
}

stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && GetClientTeam(client) > 1 && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}