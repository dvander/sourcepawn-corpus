#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

// Version, do not change it.
#define VERSION "0.5 Public"

// Others
new weapon_choose[MAXPLAYERS+1];
new g_iCredits[MAXPLAYERS+1];

// CVAR Handles
new Handle:cvarCreditsMax = INVALID_HANDLE;
new Handle:cvarCreditsKill = INVALID_HANDLE;
new Handle:cvarKillMsg = INVALID_HANDLE;
new Handle:cvarCreditsSave = INVALID_HANDLE;
new Handle:c_GameCredits = INVALID_HANDLE;
new Handle:cvarSpawnMenu = INVALID_HANDLE;
new Handle:cvarWelcomeMenu = INVALID_HANDLE;
new Handle:cvarIngameMenu = INVALID_HANDLE;
new Handle:cvarRoundCredits = INVALID_HANDLE;
new Handle:cvarKillGive = INVALID_HANDLE;
new Handle:cvarCrInterval = INVALID_HANDLE;

new Handle:cvarKarambit = INVALID_HANDLE;
new Handle:cvarBayonet = INVALID_HANDLE;
new Handle:cvarGut = INVALID_HANDLE;
new Handle:cvarM9 = INVALID_HANDLE;
new Handle:cvarFlip = INVALID_HANDLE;

// Do not remove or edit the lines below. Thank you for using!
public Plugin:myinfo =
{
	name = "Knife Shop",
	author = "TummieTum",
	description = "Buy a special knife!",
	version = VERSION,
	url = "http://www.Team-Secretforce.com/"
};

public OnPluginStart()
{
	// Required
	LoadTranslations("common.phrases");
	
	c_GameCredits = RegClientCookie("Credits", "Credits", CookieAccess_Private);
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	RegConsoleCmd("sm_knife", KMenu);
	RegConsoleCmd("sm_kcredits", KCredits);
	RegAdminCmd("sm_setkcredits", SetCredits, ADMFLAG_ROOT);
	
	// Giver
	RegAdminCmd("sm_bayonet", Command_bayonet, ADMFLAG_BAN, "Gives player an Bayonet.");
	RegAdminCmd("sm_gut", Command_gut, ADMFLAG_BAN, "Gives player an Gut knife.");
	RegAdminCmd("sm_m9", Command_m9, ADMFLAG_BAN, "Gives player an M9 Bayonet.");
	RegAdminCmd("sm_flip", Command_flip, ADMFLAG_BAN, "Gives player an Flip knife.");
	RegAdminCmd("sm_karambit", Command_karambit, ADMFLAG_BAN, "Gives player an Karambit");
	
	// Settings
	cvarCreditsMax = CreateConVar("knife_credits_max", "150", "Max credits allowed");
	cvarCreditsKill = CreateConVar("knife_credits_kill", "1", "How much credits for free or a kill?");
	cvarKillGive = CreateConVar("knife_credits_killgive", "1", "Earn Credits with a kill, disable it with free credits");
	cvarCreditsSave = CreateConVar("knife_credits_save", "1", "Enable or Disable Credits Saving");
	cvarKillMsg = CreateConVar("knife_kill_msg", "1", "Enable or Disable kill messages (automatic disabled if xxx_killgive = 0)");
	cvarSpawnMenu = CreateConVar("knife_spawnmenu", "0", "Show menu always on playerspawn");
	cvarWelcomeMenu = CreateConVar("knife_welcomemenu", "1", "Show menu on playerconnect");
	cvarIngameMenu = CreateConVar("knife_ingamemenu", "1", "Menu and roundmessages");
	cvarRoundCredits = CreateConVar("knife_roundcredits", "0", "Every round free kill credits, based on interval");
	cvarCrInterval = CreateConVar("knife_roundcredits_time", "75.0", "Interval Free Credits (Auto Disabled if xxx_roundcredits = 0)");
	
	// Enable & Disable items
	cvarKarambit = CreateConVar("knife_karambit_enable", "1", "Disable or Enable Karambit");
	cvarBayonet = CreateConVar("knife_bayonet_enable", "1", "Disable or Enable Bayonet");
	cvarGut = CreateConVar("knife_gut_enable", "1", "Disable or Enable Gut");
	cvarM9 = CreateConVar("knife_m9_enable", "1", "Disable or Enable M9 Bayonet");
	cvarFlip = CreateConVar("knife_flip_enable", "1", "Disable or Enable Flip");
	
	
	// CFG Creation
	AutoExecConfig(true, "knife_shop_tummietum");
	
	// Version
	CreateConVar("sm_knifeshop_version", VERSION, "plugin info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Save Credits
	if(GetConVarBool(cvarCreditsSave))
		for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(AreClientCookiesCached(client))
			{
				OnClientCookiesCached(client);
			}
		}
	}
}

// Save after PluginEnd
public OnPluginEnd()
{
	if(!GetConVarBool(cvarCreditsSave))
		return;
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

// Caching
public OnClientCookiesCached(client)
{
	if(!GetConVarBool(cvarCreditsSave))
		return;
	
	new String:CreditsString[12];
	GetClientCookie(client, c_GameCredits, CreditsString, sizeof(CreditsString));
	g_iCredits[client]  = StringToInt(CreditsString);
	weapon_choose[client] = 0;
}  

// Save after connect
public OnClientDisconnect(client)
{	
	if(!GetConVarBool(cvarCreditsSave))
	{
		g_iCredits[client] = 0;
		return;
	}
	
	if(AreClientCookiesCached(client))
	{
		new String:CreditsString[12];
		Format(CreditsString, sizeof(CreditsString), "%i", g_iCredits[client]);
		SetClientCookie(client, c_GameCredits, CreditsString);
	}
}	

// Knife Spawnmsg
public Action:Spawnmsg(Handle:timer, any:client)
{
	if(!GetConVarBool(cvarIngameMenu))
		return;
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "[Knife Shop] Type \x03\"!knife\" \x01to buy free knives!");
		}
	}
}

// Timers
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	CreateTimer(15.0, Timer_knifemsg, client);
	CreateTimer(GetConVarFloat(cvarCrInterval), Timer_roundcredits, GetClientSerial(client), TIMER_REPEAT);
	
	return true;
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

// Roundcredits & Timer
public Action:Timer_roundcredits(Handle:timer, any:serial)
{		
	new client = GetClientFromSerial(serial);
	
	if(!GetConVarBool(cvarRoundCredits))
		return;
	{
		
		// Check (TumTum 0.13)
		if(client > 0 && client <= MaxClients)
		{
			if(IsClientInGame(client))
			{
				if(IsClientConnected(client) && (GetClientTeam(client) > 1))
				{
					g_iCredits[client] += GetConVarInt(cvarCreditsKill);
					
					if (g_iCredits[client] < GetConVarInt(cvarCreditsMax) && IsClientInGame(client) && GetClientTeam(client) > 1)
					{
						PrintToChat(client, "[Knife Shop] You got: \x03%i (+%i) \x01free credit(s)!", g_iCredits[client],GetConVarInt(cvarCreditsKill));
					}
					else
					{
						g_iCredits[client] = GetConVarInt(cvarCreditsMax);
						PrintToChat(client, "[Knife Shop] 0 free credit(s): \x03%i (Maximum allowed)", g_iCredits[client]);
					}
					// CVAR Close
				}
				// Close Checks
			}
		}
	}
}

// Target Credits
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!attacker)
		return;
	
	if (attacker == client)
		return;
	
	if(!GetConVarBool(cvarKillGive))
		return;
	
	g_iCredits[attacker] += GetConVarInt(cvarCreditsKill);
	
	if(!GetConVarBool(cvarKillMsg))
		return;
	
	if (g_iCredits[attacker] < GetConVarInt(cvarCreditsMax))
	{	
		PrintToChat(attacker, "[Knife Shop] Your Credits: \x03%i (+%i)", g_iCredits[attacker],GetConVarInt(cvarCreditsKill));
	}
	else
	{
		g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
		PrintToChat(attacker, "[Knife Shop] Your Credits: \x03%i (Maximum allowed)", g_iCredits[attacker]);
	}
}

// Amount Check
public Action:KCredits(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
	PrintToChat(client, "[Knife Shop] Your current credits are: \x03%i", g_iCredits[client]);
}


// Knife Menu
public Action:KMenu(client,args)
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
		PrintToChat(client, "[Knife Shop] Your Credits: \x03%i", g_iCredits[client]);
	}
}

// Shop
public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Knife Shop - Credits: %i", g_iCredits[clientId]);
	if (GetConVarBool(cvarBayonet))
	{
		AddMenuItem(menu, "option2", "[30] Bayonet Knife");
	}
	if (GetConVarBool(cvarGut))
	{
		AddMenuItem(menu, "option3", "[45] Gut Knife");
	}
	if (GetConVarBool(cvarFlip))
	{
		AddMenuItem(menu, "option4", "[60] Flip Knife");
	}
	if (GetConVarBool(cvarM9))
	{
		AddMenuItem(menu, "option5", "[75] M9 Bayonet");
	}
	if (GetConVarBool(cvarKarambit))
	{
		AddMenuItem(menu, "option6", "[90] Karambit");
	}
	AddMenuItem(menu, "option1", "[KS] About Knife Shop");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 15);
	
	return Plugin_Handled;
}

// Items
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
				PrintToChat(client,"[Knife Shop] Buy a knife for this map only!");
				PrintToChat(client,"[Knife Shop] Your Credits will be saved.");
				// Do not remove the lines below.
				PrintToChat(client,"[Knife Shop] \x02Created by: \x01TummieTum (TumTum)");
			}
			
		}
		
		// Bayonet Knife
		else if ( strcmp(info,"option2") == 0 ) 
		{
			{
				if (g_iCredits[client] >= 30)
				{
					if(IsValidClient(client, true))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_bayonet");
						weapon_choose[client] = 1;
						
						if(IsValidClient(client, true))
						{
							EquipPlayerWeapon(client, knife);
						}
						
						g_iCredits[client] -= 30;
						
						PrintToChat(client, "[Knife Shop] You bought a Bayonet! Your credits: \x03%i \x01(-30)", g_iCredits[client]);
					}
					else
					{
						if (g_iCredits[client] >= 30)
							PrintToChat(client, "[Knife Shop] You bought a Bayonet! You get it on your next spawn. Your credits: \x03%i \x01(-30)", g_iCredits[client]);
						weapon_choose[client] = 1;
						g_iCredits[client] -= 30;
					}
				}
				else
				{
					PrintToChat(client, "[Knife Shop] Your credits: \x03%i (Not enough credits! Need 30)", g_iCredits[client]);
				}
			}
		}
		
		// Gut Knife
		else if ( strcmp(info,"option3") == 0 ) 
		{
			{
				if (g_iCredits[client] >= 45)
				{
					if(IsValidClient(client, true))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_gut");
						weapon_choose[client] = 2;
						
						if(IsValidClient(client, true))
						{
							EquipPlayerWeapon(client, knife);
						}
						
						g_iCredits[client] -= 45;
						
						PrintToChat(client, "[Knife Shop] You bought a Gut Knife! Your credits: \x03%i \x01(-45)", g_iCredits[client]);
					}
					else
					{
						if (g_iCredits[client] >= 45)
							PrintToChat(client, "[Knife Shop] You bought a Gut Knife! You get it on your next spawn. Your credits: \x03%i \x01(-45)", g_iCredits[client]);
						weapon_choose[client] = 2;
						g_iCredits[client] -= 45;
					}
				}
				else
				{
					PrintToChat(client, "[Knife Shop] Your credits: \x03%i (Not enough credits! Need 45)", g_iCredits[client]);
				}
			}
			
		}
		
		// Flip Knife
		else if ( strcmp(info,"option4") == 0 ) 
		{
			{
				if (g_iCredits[client] >= 60)
				{
					if(IsValidClient(client, true))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_flip");
						weapon_choose[client] = 3;
						
						if(IsValidClient(client, true))
						{
							EquipPlayerWeapon(client, knife);
						}
						
						g_iCredits[client] -= 60;
						
						PrintToChat(client, "[Knife Shop] You bought a Flip Knife! Your credits: \x03%i \x01(-60)", g_iCredits[client]);
					}
					else
					{
						if (g_iCredits[client] >= 60)
							PrintToChat(client, "[Knife Shop] You bought a Flip Knife! You get it on your next spawn. Your credits: \x03%i \x01(-45)", g_iCredits[client]);
						weapon_choose[client] = 3;
						g_iCredits[client] -= 60;
					}
				}
				else
				{
					PrintToChat(client, "[Knife Shop] Your credits: \x03%i (Not enough credits! Need 60)", g_iCredits[client]);
				}
			}
			
		}
		
		// M9 Bayonet
		else if ( strcmp(info,"option5") == 0 ) 
		{
			{
				if (g_iCredits[client] >= 75)
				{
					if(IsValidClient(client, true))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_m9_bayonet");
						weapon_choose[client] = 4;
						
						if(IsValidClient(client, true))
						{
							EquipPlayerWeapon(client, knife);
						}
						
						g_iCredits[client] -= 75;
						
						PrintToChat(client, "[Knife Shop] You bought a M9 Bayonet! Your credits: \x03%i \x01(-75)", g_iCredits[client]);
					}
					else
					{
						if (g_iCredits[client] >= 75)
							PrintToChat(client, "[Knife Shop] You bought a M9 Bayonet! You get it on your next spawn. Your credits: \x03%i \x01(-45)", g_iCredits[client]);
						weapon_choose[client] = 4;
						g_iCredits[client] -= 75;
					}
				}
				else
				{
					PrintToChat(client, "[Knife Shop] Your credits: \x03%i (Not enough credits! Need 75)", g_iCredits[client]);
				}
			}
			
		}
		// Karambit
		else if ( strcmp(info,"option6") == 0 ) 
		{
			{
				if (g_iCredits[client] >= 90)
				{
					if(IsValidClient(client, true))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife_karambit");
						weapon_choose[client] = 5;
						
						if(IsValidClient(client, true))
						{
							EquipPlayerWeapon(client, knife);
						}
						
						g_iCredits[client] -= 90;
						
						PrintToChat(client, "[Knife Shop] You bought a Karambit Knife! Your credits: \x03%i \x01(-90)", g_iCredits[client]);
					}
					else
					{
						if (g_iCredits[client] >= 90)
							PrintToChat(client, "[Knife Shop] You bought a Karambit Knife! You get it on your next spawn. Your credits: \x03%i \x01(-45)", g_iCredits[client]);
						weapon_choose[client] = 5;
						g_iCredits[client] -= 90;
					}
				}
				else
				{
					PrintToChat(client, "[Knife Shop] Your credits: \x03%i (Not enough credits! Need 90)", g_iCredits[client]);
				}
			}
			
		}
		// Current Credits
		else if ( strcmp(info,"option8") == 0 ) 
		{
			{
				DID(client);
				PrintToChat(client, "[Knife Shop] Your current credits are: \x03%i", g_iCredits[client]);
			}
			
		}
		
	}
}

// Admins Give Credits
public Action:SetCredits(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
	}
	
	if(args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Use: sm_setkcredits <#userid|name> [amount]");
		return Plugin_Handled;
	}
	
	decl String:arg2[10];
	//GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new amount = StringToInt(arg2);
	//new target;
	
	//decl String:patt[MAX_NAME]
	
	//if(args == 1) 
	//{ 
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	decl String:strTargetName[MAX_TARGET_LENGTH]; 
	decl TargetList[MAXPLAYERS], TargetCount; 
	decl bool:TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	} 
	for (new i = 0; i < TargetCount; i++) 
	{ 
		new iClient = TargetList[i]; 
		if (IsClientInGame(iClient)) 
		{ 
			g_iCredits[iClient] = amount;
			PrintToChat(client, "[Knife Shop] Set \x03%i \x01credits for player %N", amount, iClient);
		} 
	} 
	
	return Plugin_Continue;
}

// Playerspawn
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client, true))
	{
		return;
	}
	
	CreateTimer(1.0, Spawnmsg, client);
	
	if (GetConVarBool(cvarSpawnMenu))
	{
		DID(client);
	}
	
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
		default: {return;}
	}
	
	if(IsValidClient(client, true))
	{
		EquipPlayerWeapon(client, iItem);
	}
		
}

// Knife Giver including cases
public Action:Command_bayonet(client, args)
{ 
	decl String:pattern[64],String:buffer[64],String:ent[64],String:EntName[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,ent,sizeof(ent));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
		if(IsValidClient(targets[i], true)) {
		if (GivePlayerItem(targets[i],ent) == -1) {
			new currentknife = GetPlayerWeaponSlot(targets[i], 2);
			
			if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(targets[i], currentknife);
			}
			new knife = GivePlayerItem(targets[i], "weapon_bayonet");
			if(IsValidClient(targets[i], true))
			{
				EquipPlayerWeapon(targets[i], knife);
			}
			PrintToChat(targets[i], "[Knife Shop] You got the Bayonet Knife for 1 map!");
			weapon_choose[targets[i]] = 1;
			GetClientName(ent[i],EntName,sizeof(EntName));
		}
	}
	return Plugin_Handled;
}

public Action:Command_gut(client, args)
{
	decl String:pattern[64],String:buffer[64],String:ent[64],String:EntName[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,ent,sizeof(ent));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
		if(IsValidClient(targets[i], true)) {
		if (GivePlayerItem(targets[i],ent) == -1) {
			new currentknife = GetPlayerWeaponSlot(targets[i], 2);
			
			if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(targets[i], currentknife);
			}
			new knife = GivePlayerItem(targets[i], "weapon_knife_gut");
			if(IsValidClient(targets[i], true))
			{
				EquipPlayerWeapon(targets[i], knife);
			}
			PrintToChat(targets[i], "[Knife Shop] You got the Gut Knife for 1 map!");
			weapon_choose[targets[i]] = 2;
			GetClientName(ent[i],EntName,sizeof(EntName));
		}
	}
	return Plugin_Handled;
}
public Action:Command_m9(client, args)
{
	decl String:pattern[64],String:buffer[64],String:ent[64],String:EntName[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,ent,sizeof(ent));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
		if(IsValidClient(targets[i], true)) {
		if (GivePlayerItem(targets[i],ent) == -1) {
			new currentknife = GetPlayerWeaponSlot(targets[i], 2);
			
			if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(targets[i], currentknife);
			}
			new knife = GivePlayerItem(targets[i], "weapon_knife_m9_bayonet");
			if(IsValidClient(targets[i], true))
			{
				EquipPlayerWeapon(targets[i], knife);
			}
			PrintToChat(targets[i], "[Knife Shop] You got the M9 Bayonet Knife for 1 map!");
			weapon_choose[targets[i]] = 4;
			GetClientName(ent[i],EntName,sizeof(EntName));
		}
	}
	return Plugin_Handled;
}
public Action:Command_flip(client, args)
{
	decl String:pattern[64],String:buffer[64],String:ent[64],String:EntName[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,ent,sizeof(ent));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
		if(IsValidClient(targets[i], true)) {
		if (GivePlayerItem(targets[i],ent) == -1) {
			new currentknife = GetPlayerWeaponSlot(targets[i], 2);
			
			if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(targets[i], currentknife);
			}
			new knife = GivePlayerItem(targets[i], "weapon_knife_flip");
			if(IsValidClient(targets[i], true))
			{
				EquipPlayerWeapon(targets[i], knife);
			}
			PrintToChat(targets[i], "[Knife Shop] You got the Flip Knife for 1 map!");
			weapon_choose[targets[i]] = 3;
			GetClientName(ent[i],EntName,sizeof(EntName));
		}
	}
	return Plugin_Handled;
}
public Action:Command_karambit(client, args)
{
	decl String:pattern[64],String:buffer[64],String:ent[64],String:EntName[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,ent,sizeof(ent));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
		if(IsValidClient(targets[i], true)) {
		if (GivePlayerItem(targets[i],ent) == -1) {
			new currentknife = GetPlayerWeaponSlot(targets[i], 2);
			
			if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(targets[i], currentknife);
			}
			new knife = GivePlayerItem(targets[i], "weapon_knife_karambit");
			if(IsValidClient(targets[i], true))
			{
				EquipPlayerWeapon(targets[i], knife);
			}
			PrintToChat(targets[i], "[Knife Shop] You got the Karambit Knife for 1 map!");
			weapon_choose[targets[i]] = 5;
			GetClientName(ent[i],EntName,sizeof(EntName));
		}
	}
	return Plugin_Handled;
}

stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && GetClientTeam(client) > 1 && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}
