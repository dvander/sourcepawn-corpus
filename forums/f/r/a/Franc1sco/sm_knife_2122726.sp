#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>
#pragma semicolon 1

//Fix bugs
//                   ***Knife bugs in screen***
//                   ***Knife bugs in spawn***
//new
new weapon_choose[MAXPLAYERS+1];

//versao
#define PLUGIN_VERSION "v1.4_fix"
#define MAX_WEAPONS	6

//Handles
new Handle:cvarVersion=INVALID_HANDLE;
new Handle:cvarSpawnMenu = INVALID_HANDLE;
new Handle:cvarWelcomeMenu = INVALID_HANDLE;
new Handle:cvarIngameMenu = INVALID_HANDLE;
new Handle:cvarSpawnMsg = INVALID_HANDLE;
new Handle:cvarKarambit = INVALID_HANDLE;
new Handle:cvarBayonet = INVALID_HANDLE;
new Handle:cvarGut = INVALID_HANDLE;
new Handle:cvarM9 = INVALID_HANDLE;
new Handle:cvarFlip = INVALID_HANDLE;
new Handle:cvarGolden = INVALID_HANDLE;

//Informacao
public Plugin:myinfo =
{
	name = "Knife Get (Menu)",
	author = "Dk--",
	description = "Open Menu with knifes",
	version = "PLUGIN_VERSION"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	// Comandos
	HookEvent("player_spawn", PlayerSpawn);
	RegConsoleCmd("sm_knife", KnifeMenu);
	
	
	 // Configuracao
	cvarSpawnMenu = CreateConVar("knife_spawnmenu", "0", "Open menu in all spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSpawnMsg = CreateConVar("knife_spawnmessages", "1", "Enabled or Disable text messages in player spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWelcomeMenu = CreateConVar("knife_welcomemenu", "1", "Open menu on Client Connected", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarIngameMenu = CreateConVar("knife_ingamemenu", "1", "Enabled menu", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarVersion = CreateConVar("sm_knife_version",PLUGIN_VERSION,"Version of plugin",FCVAR_NOTIFY);
	SetConVarString(cvarVersion,PLUGIN_VERSION);
	
	// Ativar & Desativar itens
	cvarKarambit = CreateConVar("knife_karambit_enable", "1", "Enable or Disable Karambit", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBayonet = CreateConVar("knife_bayonet_enable", "1", "Enable or Disable Bayonet", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarGut = CreateConVar("knife_gut_enable", "1", "Enable or Disable Gut", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarM9 = CreateConVar("knife_m9_enable", "1", "Enable or Disable M9 Bayonet", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarFlip = CreateConVar("knife_flip_enable", "1", "Enable or Disable Flip", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarGolden = CreateConVar("knife_golden_enable", "1", "Enable or Disable Golden", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "plugin.knife");
}

public OnPluginEnd()
{
	CloseHandle(cvarVersion);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
 CreateTimer(15.0, Timer_knifemsg, client);
 return true;
}

public OnClientCookiesCached(client)
{
	weapon_choose[client] = 0;
}  

public Action:Spawnmsg(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	new iItem;

	switch(weapon_choose[client]) {
		case 1: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_bayonet");}
		case 2: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_knife_gut");}
		case 3: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_knife_flip");}
		case 4: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");}
		case 5: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_knife_karambit");}
		case 6: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_knifegg");}
 		default: {return;}
	}
	if(iItem != 0)
		EquipPlayerWeapon(client, iItem);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
		return;
	}

	CreateTimer(2.0, Spawnmsg, client);
  
	if (GetConVarBool(cvarSpawnMenu))
	{
		DID(client);
	}
}

public Action:Timer_knifemsg(Handle:timer, any:client)
{
	if(!GetConVarBool(cvarWelcomeMenu))
	return;
	{
 if (IsClientInGame(client))
  DID(client);
  
 else if (IsClientConnected(client))
  CreateTimer(15.0, Timer_knifemsg, client);
	}
}

public Action:KnifeMenu(client,args)
{
	if(!GetConVarBool(cvarIngameMenu))
	return;
	{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
    	DID(client);
   	PrintToConsole(client, "Menu of knives is open");
	}
}

public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Choose your knife");
	
	if (GetConVarBool(cvarBayonet))
	{
	AddMenuItem(menu, "option2", "Bayonet");
	}
	if (GetConVarBool(cvarGut))
	{
	AddMenuItem(menu, "option3", "Gut");
	}
	if (GetConVarBool(cvarFlip))
	{
	AddMenuItem(menu, "option4", "Flip");
	}
	if (GetConVarBool(cvarM9))
	{
	AddMenuItem(menu, "option5", "M9 Bayonet");
	}
	if (GetConVarBool(cvarKarambit))
	{
	AddMenuItem(menu, "option6", "Karambit");
	}
	if (GetConVarBool(cvarGolden))
	{
	AddMenuItem(menu, "option7", "Golden");
	}
	//AddMenuItem(menu, "option1", "About This Plugin");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 15);
	
	return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if ( strcmp(info,"option1") == 0 ) 
		{
			{
			  DID(client);
			  PrintToChat(client," \x04 Choose your knife for one map");
			  PrintToChat(client," \x04 Original plugin by tumtum; Edit by DK--");
			}
			
		}

			else if ( strcmp(info,"option2") == 0 ) 
		{     
			 if (IsPlayerAlive(client))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_bayonet");
						weapon_choose[client] = 1;
						
						EquipPlayerWeapon(client, knife);
						

						PrintToChat(client, " \x04 Now you have the knife: Bayonet!!!");
					}
		}
	   
				else if ( strcmp(info,"option3") == 0 ) 
		{
			if (IsPlayerAlive(client))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_gut");
						weapon_choose[client] = 2;
						
						EquipPlayerWeapon(client, knife);
						

						PrintToChat(client, " \x04 Now you have the knife: Gut!!!");
					}
			
		}
			
				else if ( strcmp(info,"option4") == 0 ) 
		{
			if (IsPlayerAlive(client))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_flip");
						weapon_choose[client] = 3;
						
						EquipPlayerWeapon(client, knife);
						

						PrintToChat(client, " \x04 Now you have the knife: Flip!!!");
					}  
		}
		
				else if ( strcmp(info,"option5") == 0 ) 
		{
		   if (IsPlayerAlive(client))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_m9_bayonet");
						weapon_choose[client] = 4;
						
						EquipPlayerWeapon(client, knife);
						

						PrintToChat(client, " \x04 Now you have the knife: M9-Bayonet!!!");
					}
		}
		
				else if ( strcmp(info,"option6") == 0 ) 
		{
		   if (IsPlayerAlive(client))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_karambit");
						weapon_choose[client] = 5;
						
						EquipPlayerWeapon(client, knife);
						

						PrintToChat(client, " \x04 Now you have the knife: Karambit!!!");
					}
		}
					
				else if ( strcmp(info,"option7") == 0 ) 
		{
		   if (IsPlayerAlive(client))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knifegg");
						weapon_choose[client] = 6;
						
						EquipPlayerWeapon(client, knife);
						

						PrintToChat(client, " \x04 Now you have the knife: Golden!!!");
					}
		}
	}
}
