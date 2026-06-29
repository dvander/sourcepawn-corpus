#include <sourcemod>  
#include <sdkhooks> 

new effect = -1;
new armor[MAXPLAYERS + 1];
new intdamage = 0;
new Handle:hHudText;
new kills[MAXPLAYERS + 1];


public Plugin:myinfo =  
{  
	name = "Armor pack",  
	author = "Arkarr",  
	description = "Active a armor for players, armor can be buy with kills - MY FIRST PLUGIN",  
	version = "1.0 BETA",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{ 
	RegConsoleCmd("sm_armor", Armor_Menu, "Armor menu");
	
	RegAdminCmd("sm_reset", Armor_Reset, ADMFLAG_CHEATS);
	
	hHudText = CreateHudSynchronizer();
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre)
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}


public MenuHandler1(Handle:menu, MenuAction:action, client, param2)  
{  
	new String:info[32];  
	GetMenuItem(menu, param2, info, sizeof(info));  
	
	if (action == MenuAction_Select)  
	{
		param2++; 
		if(param2 == 1) 
		{  
			effect = 1;  
			Action_Effect(client);  
		}  
		else if(param2 == 2) 
		{  
			effect = 2;  
			Action_Effect(client);  
		}  
		else if(param2 == 3) 
		{  
			effect = 3;  
			Action_Effect(client);  
		}  
		else if(param2 == 4) 
		{  
			effect = 4;  
			Action_Effect(client);  
		} 
	} 
	
	else if (action == MenuAction_End)  
	{  
		CloseHandle(menu);  
	} 
} 


public Action:Armor_Menu(client, args)  
{
	new Handle:menu = CreateMenu(MenuHandler1); 
	SetMenuTitle(menu, "Select your shield health :"); 
	AddMenuItem(menu, "armor10", "10HP armor - 5 kills"); 
	AddMenuItem(menu, "armor50", "50HP armor - 20 kills"); 
	AddMenuItem(menu, "armor200", "200HP armor - 50 kills"); 
	AddMenuItem(menu, "armor400", "400HP armor - 100 kills"); 
	SetMenuExitButton(menu, false); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;  
} 


Action_Effect(client)  
{         
	if(kills[client] <= 0){
		if(effect == 1) 
		{
			kills[client] = 5;
			armor[client] = 10;
		} 
		
		else if(effect == 2) 
		{
			kills[client] = 20;
			armor[client] = 50; 
		} 
		
		else if(effect == 3) 
		{
			kills[client] = 50;
			armor[client] = 200;
		} 
		
		else if(effect == 4) 
		{
			kills[client] = 100;
			armor[client] = 400;
		}

		SetHudTextParams(-0.75, 0.90, 45.0, 40, 151, 249, 255);
		ShowSyncHudText(client, hHudText, "Armor : %i", armor[client]);
	}
	else{
		PrintToChat(client, "[ARMOR] You need to do %i kills before activing your armor", kills[client]);
	}
}


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{     
	
	if(armor[victim] >= 1){ 
		
		intdamage = RoundFloat(damage); 
		
		armor[victim]-=intdamage; 
		
		ClearSyncHud(victim, hHudText); 
		
		if(armor[victim] <= -1){ 
			armor[victim] = 0; 
			PrintHintText(victim, "Your armor is now DESTROYED !"); 
		} 
		else{ 
			SetHudTextParams(-0.75, 0.90, 45.0, 40, 151, 249, 255); 
			ShowSyncHudText(victim, hHudText, "Armor : %i", armor[victim]); 
		} 
		
		PrintHintText(attacker, "This player use armor, HP of armor : %i", armor[victim]);
		
		// Block damage 
		return Plugin_Handled; 
	}
	
	// Allow damage 
	return Plugin_Continue; 
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	//Other stuff. Use return Plugin_Handled to block the event after some comparison.
	kills[killer]--;
	
	if(kills[killer] <= 0){
		kills[killer] = 0;
	}
	
	return Plugin_Continue
}

public Action:Armor_Reset(client, args)  
{
	kills[client] = 0;
	armor[client] = 0;
	ClearSyncHud(client, hHudText);
	
	PrintHintText(client, "Your armor and kills was rested to 0 !");
	
}