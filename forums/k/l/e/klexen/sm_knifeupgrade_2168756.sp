#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "0.0.4"
#define PLUGIN_NAME "Knife Upgrade"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hSpawnMessage = INVALID_HANDLE;
new Handle:g_hSpawnMenu = INVALID_HANDLE;
new Handle:g_hWelcomeMessage = INVALID_HANDLE;
new Handle:g_hWelcomeMenu = INVALID_HANDLE;
new Handle:g_hWelcomeMenuOnlyNoKnife = INVALID_HANDLE;
new Handle:g_hWelcomeMessageTimer = INVALID_HANDLE;
new Handle:g_hWelcomeMenuTimer = INVALID_HANDLE;
new Handle:g_hKnifeChosenMessage = INVALID_HANDLE;
new Handle:g_hNoKnifeMapDisable = INVALID_HANDLE;
new Handle:g_hNeedsAccess = INVALID_HANDLE;
new Handle:g_hEnableGoldKnife = INVALID_HANDLE;

new knife_choice[MAXPLAYERS+1];
new knife_welcome_spawn_menu[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Klexen",
	description = "Choose and a save custom knife skin for this server.",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_knifeupgrade_version", PLUGIN_VERSION, "Knife Upgrade Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_knifeupgrade_on", "1", "Enable / Disable Plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnMessage = CreateConVar("sm_knifeupgrade_spawn_message", "0", "Show Plugin Message on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnMenu = CreateConVar("sm_knifeupgrade_spawn_menu", "0", "Show Knife Menu on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMessage = CreateConVar("sm_knifeupgrade_welcome_message", "1", "Show Plugin Message on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMenu = CreateConVar("sm_knifeupgrade_welcome_menu", "0", "Show Knife Menu on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMenuOnlyNoKnife = CreateConVar("sm_knifeupgrade_welcome_menu_only_no_knife", "1", "Show Knife Menu on player Spawn ONCE and only if they haven't already chosen a knife before.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMessageTimer = CreateConVar("sm_knifeupgrade_welcome_message_timer", "25.0", "When (in seconds) the message should be displayed after the player joins the server.", FCVAR_NONE, true, 25.0, true, 90.0);
	g_hWelcomeMenuTimer = CreateConVar("sm_knifeupgrade_welcome_menu_timer", "8.5", "When (in seconds) AFTER SPAWNING THE FIRST TIME the knife menu should be displayed.", FCVAR_NONE, true, 1.0, true, 90.0);
	g_hKnifeChosenMessage = CreateConVar("sm_knifeupgrade_chosen_message", "1", "Show message to player when player chooses a knife.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hNoKnifeMapDisable = CreateConVar("sm_knifeupgrade_map_disable", "0", "Set to 1 to disable knife on maps not meant to have knives", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hNeedsAccess = CreateConVar("sm_knifeupgrade_needs_access", "0", "Set to 1 to if you want to Restrict access. (Access Requires 'a' flag.)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hEnableGoldKnife = CreateConVar("sm_knifeupgrade_gold_knife", "0", "Enable / Disable Golden Knife", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sm_knifeupgrade");
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	HookEvent("player_spawn", PlayerSpawn);
	
}

public OnClientAuthorized(client)
{
	knife_welcome_spawn_menu[client] = 0;	
	knife_choice[client] = 0;
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(g_hWelcomeMessage)) CreateTimer(GetConVarFloat(g_hWelcomeMessageTimer), Timer_Welcome_Message, client);
}

public Action:Timer_Welcome_Message(Handle:timer, any:client)
{
	if (GetConVarBool(g_hWelcomeMessage) && IsValidClient(client))
	{
		PrintToChat(client, "Type \x04!knife \x01or \x07chat triggers \x01to select a new knife skin.");
		if (GetConVarBool(g_hEnableGoldKnife))
		{
			PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !golden !default");
		} else {PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !default");}
	}              
}

public Action:Event_Say(client, const String:command[], arg)
{
	if (IsValidClient(client) && GetConVarBool(g_hEnabled))
	{
		decl String:text[24];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
		
		if (StrEqual(text, "!knife", false) || StrEqual(text, "!knief", false) || StrEqual(text, "!knifes", false) || StrEqual(text, "!knfie", false) || StrEqual(text, "!knfie", false) || StrEqual(text, "!knifw", false) || StrEqual(text, "!knives", false) || StrEqual(text, "!knives", false) || StrEqual(text, "!knif", false))
		{
			if (IsValidClient(client))
			{
				ShowKnifeMenu(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		
		//Knife Shortcut Triggers
		//Bayonet
		if (StrEqual(text, "!bayonet", false))
		{
			if (IsValidClient(client))
			{
				SetBayonet(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//Gut
		if (StrEqual(text, "!gut", false))
		{
			if (IsValidClient(client))
			{
				SetGut(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//Flip
		if (StrEqual(text, "!flip", false))
		{
			if (IsValidClient(client))
			{
				SetFlip(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//M9
		if (StrEqual(text, "!m9", false))
		{
			if (IsValidClient(client))
			{
				SetM9(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//Karambit
		if (StrEqual(text, "!karambit", false))
		{
			if (IsValidClient(client))
			{
				SetKarambit(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//Huntsman
		if (StrEqual(text, "!huntsman", false))
		{
			if (IsValidClient(client))
			{
				SetHuntsman(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//Butterfly
		if (StrEqual(text, "!butterfly", false))
		{
			if (IsValidClient(client))
			{
				SetButterfly(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//Default
		if (StrEqual(text, "!default", false))
		{
			if (IsValidClient(client))
			{
				SetDefault(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
		//Golden Knife
		if (StrEqual(text, "!golden", false))
		{
			if (IsValidClient(client) && GetConVarBool(g_hEnableGoldKnife))
			{
				SetGolden(client);
			} else {PrintToChat(client, " \x07You do not have access to this command.");}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client)) return;
	
	if (GetConVarBool(g_hSpawnMessage))
	{
		PrintToChat(client, "Type \x04!knife \x01or \x07chat triggers \x01to select a new knife skin.");
		if (GetConVarBool(g_hEnableGoldKnife))
		{
			PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !golden !default");
		} else {PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !default");}
	}
	if (GetConVarBool(g_hSpawnMenu) && IsValidClient(client)) ShowKnifeMenu(client);
	if (GetConVarBool(g_hWelcomeMenu) && IsValidClient(client)) CreateTimer(GetConVarFloat(g_hWelcomeMenuTimer), AfterSpawn, client);
	CreateTimer(0.3, StripKnife, client);
}

public Action:AfterSpawn(Handle:timer, any:client)
{
	if (GetConVarBool(g_hWelcomeMenu) && IsValidClient(client) && knife_welcome_spawn_menu[client] == 0)
	{
		if (GetConVarBool(g_hWelcomeMenuOnlyNoKnife))
		{
			if (knife_choice[client] < 1) ShowKnifeMenu(client);
		} else {ShowKnifeMenu(client);}
		
	}
	if (knife_welcome_spawn_menu[client] == 0) knife_welcome_spawn_menu[client] = 1;
}

public Action:StripKnife(Handle:timer, any:client)
{
	if(!IsValidClient(client) || !GetConVarBool(g_hEnabled) || !IsPlayerAlive(client)) return;

	new iWeapon = GetPlayerWeaponSlot(client, 2);
	if (GetConVarBool(g_hNoKnifeMapDisable) && iWeapon == INVALID_ENT_REFERENCE) return; //If player doesn't already have a knife, and map doesn't spawn one, return without equipping..
	if (iWeapon != INVALID_ENT_REFERENCE) //If player already has a knife, remove it.
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
	} 
	CreateTimer(0.2, Equipknife, client);
}

public Action:Equipknife(Handle:timer, any:client)
{      
	if(!IsValidClient(client) || !GetConVarBool(g_hEnabled) || !IsPlayerAlive(client)) return;
	
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	
	if (iWeapon != INVALID_ENT_REFERENCE) return;
	
	if (knife_choice[client] < 1 || knife_choice[client] > 9) knife_choice[client] = 8;
	
	new iItem;
	switch(knife_choice[client]) {
		case 1:{iItem = GivePlayerItem(client, "weapon_bayonet");}
		case 2:{iItem = GivePlayerItem(client, "weapon_knife_gut");}
		case 3:{iItem = GivePlayerItem(client, "weapon_knife_flip");}
		case 4:{iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");}
		case 5:{iItem = GivePlayerItem(client, "weapon_knife_karambit");}
		case 6:{iItem = GivePlayerItem(client, "weapon_knife_tactical");}
		case 7:{iItem = GivePlayerItem(client, "weapon_knife_butterfly");}
		case 8:{iItem = GivePlayerItem(client, "weapon_knife");}
		case 9:
		{
			if (GetConVarBool(g_hEnableGoldKnife))
			{
				iItem = GivePlayerItem(client, "weapon_knifegg");
			} else {iItem = GivePlayerItem(client, "weapon_knife");}
			
		}
		default: {return;}
	}
	if (iItem > 0 && IsValidClient(client) && IsPlayerAlive(client) && iWeapon == INVALID_ENT_REFERENCE) EquipPlayerWeapon(client, iItem);
	else {return;}
}

SetBayonet(client)
{
	knife_choice[client] = 1;                         
	CreateTimer(0.1, StripKnife, client);   
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Bayonet!");
}

SetGut(client)
{
	knife_choice[client] = 2;                        
	CreateTimer(0.1, StripKnife, client);    
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Gut knife!");
}

SetFlip(client)
{
	knife_choice[client] = 3;                        
	CreateTimer(0.1, StripKnife, client);   
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Flip knife!");
}

SetM9(client)
{
	knife_choice[client] = 4;                     
	CreateTimer(0.1, StripKnife, client);
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the M9-Bayonet!");
}

SetKarambit(client)
{
	knife_choice[client] = 5;                   
	CreateTimer(0.1, StripKnife, client);  
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Karambit!");
}

SetHuntsman(client)
{
	knife_choice[client] = 6;                     
	CreateTimer(0.1, StripKnife, client);   
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Huntsman knife!");
}

SetButterfly(client)
{
	knife_choice[client] = 7;                       
	CreateTimer(0.1, StripKnife, client);   
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Butterfly knife!");
}

SetDefault(client)
{
	knife_choice[client] = 8;    
	CreateTimer(0.1, StripKnife, client);   
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Default knife!");
}

SetGolden(client)
{
	knife_choice[client] = 9;                       
	CreateTimer(0.1, StripKnife, client);    
	if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Golden knife!");
}

public Action:ShowKnifeMenu(client)
{
	new Handle:menu = CreateMenu(ShowKnifeMenuHandler);
	SetMenuTitle(menu, "Choose your knife");
	AddMenuItem(menu, "option2", "!Bayonet");
	AddMenuItem(menu, "option3", "!Gut");
	AddMenuItem(menu, "option4", "!Flip");
	AddMenuItem(menu, "option5", "!M9");
	AddMenuItem(menu, "option6", "!Karambit");
	AddMenuItem(menu, "option7", "!Huntsman");
	AddMenuItem(menu, "option8", "!Butterfly");
	AddMenuItem(menu, "option9", "!Default");
	if (GetConVarBool(g_hEnableGoldKnife)) AddMenuItem(menu, "option10", "!Golden");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public ShowKnifeMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action){
		case MenuAction_Select: 
		{
			new String:info[32];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			//Bayonet
			if ( strcmp(info,"option2") == 0 ) {SetBayonet(client);}
			//Gut
			else if ( strcmp(info,"option3") == 0 ) {SetGut(client);}      
			//Flip
			else if ( strcmp(info,"option4") == 0 ) {SetFlip(client);}
			//M9-Bayonet
			else if ( strcmp(info,"option5") == 0 ) {SetM9(client);}
			//Karambit
			else if ( strcmp(info,"option6") == 0 ) {SetKarambit(client);}
			//Huntsman
			else if ( strcmp(info,"option7") == 0 ) {SetHuntsman(client);}
			//Butterfly
			else if ( strcmp(info,"option8") == 0 ) {SetButterfly(client);}
			//Default
			else if ( strcmp(info,"option9") == 0 ) {SetDefault(client);}
			//Golden
			else if ( strcmp(info,"option10") == 0 ) {SetGolden(client);}
		}
		case MenuAction_End:{CloseHandle(menu);}
	}
}

bool:IsValidClient(client)
{
	if (!(client >= 1 && client <= MaxClients)) return false;  
	if (!IsClientConnected(client) || !IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!CheckCommandAccess(client, "sm_knifeupgrade", ADMFLAG_RESERVATION, true) && GetConVarBool(g_hNeedsAccess)) return false;
	return true;
}