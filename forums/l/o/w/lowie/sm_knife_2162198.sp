#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>
#pragma semicolon 1

//Fix bugs
//                   ***Knife bugs in screen***

new weapon_choose[MAXPLAYERS+1];

//comandos
new String:knives_commands[][] = { 
	"sm_knife", 
	"sm_facas",
	"sm_cuchillos",
	"sm_messer"
};

//versao
#define PLUGIN_VERSION "version final"
#define MAX_WEAPONS	8 

//Handles
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
new Handle:cvarTactical = INVALID_HANDLE;
new Handle:cvarButterfly = INVALID_HANDLE;

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
	LoadTranslations("knife.phrases");
	// Comandos
	HookEvent("player_spawn", PlayerSpawn);
	
	new cmds = sizeof(knives_commands);
	for (new i = 0; i < cmds; i++)
	{
		RegConsoleCmd(knives_commands[i], KnifeMenu);
	}
	
	
	// Configuracao
	cvarSpawnMenu = CreateConVar("knife_spawnmenu", "0", "Open menu in all spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSpawnMsg = CreateConVar("knife_spawnmessages", "1", "Enabled or Disable text messages in player spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWelcomeMenu = CreateConVar("knife_welcomemenu", "1", "Open menu on Client Connected", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarIngameMenu = CreateConVar("knife_ingamemenu", "1", "Enabled menu", FCVAR_NONE, true, 0.0, true, 1.0);
	
	// Ativar & Desativar itens
	cvarKarambit = CreateConVar("knife_karambit_enable", "1", "Enable or Disable Karambit", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBayonet = CreateConVar("knife_bayonet_enable", "1", "Enable or Disable Bayonet", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarGut = CreateConVar("knife_gut_enable", "1", "Enable or Disable Gut", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarM9 = CreateConVar("knife_m9_enable", "1", "Enable or Disable M9 Bayonet", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarFlip = CreateConVar("knife_flip_enable", "1", "Enable or Disable Flip", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarGolden = CreateConVar("knife_golden_enable", "1", "Enable or Disable Golden", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTactical = CreateConVar("knife_tactical_enable", "1", "Enable or Disable Tactical", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarButterfly = CreateConVar("knife_butterfly_enable", "1", "Enable or Disable Butterfly", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sm_knife");
	
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
	if(!GetConVarBool(cvarSpawnMsg))
	return;
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "[SM KNIFE] \x06 %T", "Type !knife to open menu of knives", client);
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetConVarBool(cvarSpawnMsg))
	{
		CreateTimer(0.1, Spawnmsg, client);
	}
	
	if (GetConVarBool(cvarSpawnMenu))
	{
		DID(client);
	}
	
	CreateTimer(0.4, EquipKnife, client);
}

public Action:EquipKnife(Handle:timer, any:client)
{
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
	case 7: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_knife_tactical");}
	case 8: if(IsValidEntity(iWeapon) && iWeapon != INVALID_ENT_REFERENCE) 
		{RemovePlayerItem(client, iWeapon), RemoveEdict(iWeapon), iItem = GivePlayerItem(client, "weapon_knife_butterfly");}
	default: {return;}
	}
	
	if(IsValidClient(client, true))
	{
		EquipPlayerWeapon(client, iItem);
	}
	else
	{
		return;
	}
}

public Action:Timer_knifemsg(Handle:timer, any:client)
{
	if(GetConVarBool(cvarWelcomeMenu) && IsClientInGame(client))
	{
		DID(client);
	}
	else if (IsClientConnected(client))
	CreateTimer(15.0, Timer_knifemsg, client);
}

public Action:KnifeMenu(client,args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
	
	if(GetConVarBool(cvarIngameMenu))
	{
		DID(client);
		PrintToConsole(client, "Menu of knifes is open");
	}
}

public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "%T", "Choose", clientId);
	
	decl String:itemtext2[256];
	Format(itemtext2, sizeof(itemtext2), "%T", "★Bayonet", clientId);
	decl String:itemtext3[256];
	Format(itemtext3, sizeof(itemtext3), "%T", "★Gut", clientId);
	decl String:itemtext4[256];
	Format(itemtext4, sizeof(itemtext4), "%T", "★Flip", clientId);
	decl String:itemtext5[256];
	Format(itemtext5, sizeof(itemtext5), "%T", "★M9 Bayonet", clientId);
	decl String:itemtext6[256];
	Format(itemtext6, sizeof(itemtext6), "%T", "★Karambit", clientId);
	decl String:itemtext7[256];
	Format(itemtext7, sizeof(itemtext7), "%T", "★Golden", clientId);
	decl String:itemtext8[256];
	Format(itemtext8, sizeof(itemtext8), "%T", "★Tactical", clientId);
	decl String:itemtext9[256];
	Format(itemtext9, sizeof(itemtext9), "%T", "★Butterfly", clientId);
	
	if (GetConVarBool(cvarBayonet))
	{
		AddMenuItem(menu, "option2", itemtext2);
	}
	if (GetConVarBool(cvarGut))
	{
		AddMenuItem(menu, "option3", itemtext3);
	}
	if (GetConVarBool(cvarFlip))
	{
		AddMenuItem(menu, "option4", itemtext4);
	}
	if (GetConVarBool(cvarM9))
	{
		AddMenuItem(menu, "option5", itemtext5);
	}
	if (GetConVarBool(cvarKarambit))
	{
		AddMenuItem(menu, "option6", itemtext6);
	}
	if (GetConVarBool(cvarGolden))
	{
		AddMenuItem(menu, "option7", itemtext7);
	}
	if (GetConVarBool(cvarTactical))
	{
		AddMenuItem(menu, "option8", itemtext8);
	}
	if(CheckCommandAccess(clientId, "tmp", ADMFLAG_RESERVATION, true))
	{
		if (GetConVarBool(cvarButterfly))
		{
			AddMenuItem(menu, "option9", itemtext9);
		}
	}
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
				PrintToChat(client," \x04 Choose your knife per one map");
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
				
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Bayonet", client);
			}
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] = 1;
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead Bayonet", client);
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
				

				PrintToChat(client, "[SM KNIFE] \x06 %T", "Gut", client);
			}
			
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] = 2;
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead Gut", client);
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
				

				PrintToChat(client, "[SM KNIFE] \x06 %T", "Flip", client);
			}  
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] = 3;
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead Flip", client);
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
				

				PrintToChat(client, "[SM KNIFE] \x06 %T", "M9", client);
			}
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] = 4;
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead M9", client);
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
				

				PrintToChat(client, "[SM KNIFE] \x06 %T", "Karambit", client);
			}
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] = 5;
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead Karambit", client);
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
				

				PrintToChat(client, "[SM KNIFE] \x06 %T", "Golden", client);
			}
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] =6;	
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead Golden", client);
			}
		}
		
		else if ( strcmp(info,"option8") == 0 ) 
		{
			if (IsPlayerAlive(client))
			{
				new currentknife = GetPlayerWeaponSlot(client, 2);
				if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
				{
					RemovePlayerItem(client, currentknife);
					RemoveEdict(currentknife);
				}
				
				new knife = GivePlayerItem(client, "weapon_knife_tactical");
				weapon_choose[client] = 7;
				
				EquipPlayerWeapon(client, knife);
				

				PrintToChat(client, "[SM KNIFE] \x06 %T", "Huntsman", client);
			}
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] = 7;
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead Huntsman", client);
			}
		}
		else if ( strcmp(info,"option9") == 0 ) 
		{
			if (IsPlayerAlive(client))
			{
				new currentknife = GetPlayerWeaponSlot(client, 2);
				if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
				{
					RemovePlayerItem(client, currentknife);
					RemoveEdict(currentknife);
				}
				new knife = GivePlayerItem(client, "weapon_knife_butterfly");
				weapon_choose[client] = 8;
				if(IsValidClient(client, true))
				{
					EquipPlayerWeapon(client, knife);
				}
				else
				{
					return;
				}
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Butterfly", client);
			}
			else if (!IsPlayerAlive(client))
			{
				weapon_choose[client] = 8;
				PrintToChat(client, "[SM KNIFE] \x06 %T", "Dead Butterfly", client);
			}
		}
	}
}

stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && GetClientTeam(client) > 1 && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}