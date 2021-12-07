/*=======================================================================================
	Plugin Info:

*	Name	:	Survivor Chat Select
*	Author	:	mi123645
*	Descrp	:	This plugin allows players to change their character or model
*	Link	:	https://forums.alliedmods.net/showthread.php?t=107121&highlight=weapons

*   Edits by:   DeathChaos25
*	Descrp	:	Compatibility with fakezoey plugin added
*   Link    :   https://forums.alliedmods.net/showthread.php?t=258189

*   Edits by:   Merudo
*	Descrp	:	Fixed bugs with misplaced weapon models after selecting a survivor & added admin menu support (!sm_admin)
*   Link    :   https://forums.alliedmods.net/showpost.php?p=2390350&postcount=43


========================================================================================*/

#define PLUGIN_VERSION "1.3r"  
#define PLUGIN_NAME "Survivor Chat Select"  

#include <sourcemod>  
#include <sdktools>  
#include <sdkhooks>	

// Admin Menu
#include <adminmenu>
TopMenu hTopMenu;

#define MODEL_BILL "models/survivors/survivor_namvet.mdl" 
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl" 
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl" 
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl" 

#define MODEL_NICK "models/survivors/survivor_gambler.mdl" 
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl" 
#define MODEL_COACH "models/survivors/survivor_coach.mdl" 
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl" 

#define     NICK     0 
#define     ROCHELLE    1 
#define     COACH     2 
#define     ELLIS     3 
#define     BILL     4 
#define     ZOEY     5 
#define     FRANCIS     6 
#define     LOUIS     7 

static g_iSelectedClient 
static bool:g_bAdminsOnly 

public Plugin:myinfo =  
{  
	name = PLUGIN_NAME,  
	author = "DeatChaos25 & Mi123456",  
	description = "Select a survivor character by typing their name into the chat.",  
	version = PLUGIN_VERSION,  
}  

public OnPluginStart()  
{  
	RegConsoleCmd("sm_zoey", ZoeyUse, "Changes your survivor character into Zoey");  
	RegConsoleCmd("sm_nick", NickUse, "Changes your survivor character into Nick");  
	RegConsoleCmd("sm_ellis", EllisUse, "Changes your survivor character into Ellis");  
	RegConsoleCmd("sm_coach", CoachUse, "Changes your survivor character into Coach");  
	RegConsoleCmd("sm_rochelle", RochelleUse, "Changes your survivor character into Rochelle");  
	RegConsoleCmd("sm_bill", BillUse, "Changes your survivor character into Bill");  
	RegConsoleCmd("sm_francis", BikerUse, "Changes your survivor character into Francis");  
	RegConsoleCmd("sm_louis", LouisUse, "Changes your survivor character into Louis");  
	
	RegConsoleCmd("sm_z", ZoeyUse, "Changes your survivor character into Zoey");  
	RegConsoleCmd("sm_n", NickUse, "Changes your survivor character into Nick");  
	RegConsoleCmd("sm_e", EllisUse, "Changes your survivor character into Ellis");  
	RegConsoleCmd("sm_c", CoachUse, "Changes your survivor character into Coach");  
	RegConsoleCmd("sm_r", RochelleUse, "Changes your survivor character into Rochelle");  
	RegConsoleCmd("sm_b", BillUse, "Changes your survivor character into Bill");  
	RegConsoleCmd("sm_f", BikerUse, "Changes your survivor character into Francis");  
	RegConsoleCmd("sm_l", LouisUse, "Changes your survivor character into Louis");  
	
	RegAdminCmd("sm_csc", InitiateMenuAdmin, ADMFLAG_GENERIC, "Brings up a menu to select a client's character"); 
	RegConsoleCmd("sm_csm", ShowMenu, "Brings up a menu to select a client's character"); 
	
	new Handle:AdminsOnly = CreateConVar("l4d_csm_admins_only", "1","Changes access to the sm_csm command. 1 = Admin access only.",FCVAR_PLUGIN|FCVAR_SPONLY,true, 0.0, true, 1.0);
	g_bAdminsOnly = GetConVarBool(AdminsOnly);
	HookConVarChange(AdminsOnly, _ConVarChange__AdminsOnly);
	
	AutoExecConfig(true, "l4dscs")
	
	/* Account for late loading */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}  


public Action:ZoeyUse(client, args)  
{  
    // Prop is Nick's to avoid crashes
	SurvivorChange(client, NICK, MODEL_ZOEY, "Zoey")
}  
public Action:NickUse(client, args)  
{  
	SurvivorChange(client, NICK, MODEL_NICK, "Nick")
}  
public Action:EllisUse(client, args)  
{  
	SurvivorChange(client, ELLIS, MODEL_ELLIS, "Ellis")
}  
public Action:CoachUse(client, args)  
{  
	SurvivorChange(client, COACH, MODEL_COACH, "Coach")
}  
public Action:RochelleUse(client, args)  
{  
	SurvivorChange(client, ROCHELLE, MODEL_ROCHELLE, "Rochelle")
}  
public Action:BillUse(client, args)  
{  
	SurvivorChange(client, BILL, MODEL_BILL, "Bill")
}  
public Action:BikerUse(client, args)  
{  
	SurvivorChange(client, FRANCIS, MODEL_FRANCIS, "Francis")
}  
public Action:LouisUse(client, args)  
{  
	SurvivorChange(client, LOUIS, MODEL_LOUIS, "Louis")
}  

// Function changes the survivor
public Action:SurvivorChange(client, prop, String:model[],  String:name[])
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!")
		return
	}

	if (IsFakeClient(client))  // if bot
	{
		SetClientInfo(client, "name", name);
	}
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", prop);  
	SetEntityModel(client, model);  	
	
	
	int i_Weapon = GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hActiveWeapon"))	
	
	// Don't bother with the weapon fix if dead or unarmed
	if (!IsPlayerAlive(client) || !IsValidEdict(i_Weapon) || !IsValidEntity(i_Weapon))
	{
		return;
	}	
	
	// ------------------------------------------------------------------
	// Save weapon details, remove weapon, create new weapons with exact same properties
	// Needed otherwise there will be animation bugs after switching characters due to different weapon mount points
	// Doesn't work for melee weapons
	// Code from L4D2 coop save weapon
	// ------------------------------------------------------------------
	
	int iSlot0 = GetPlayerWeaponSlot(client, 0);  	int iSlot1 = GetPlayerWeaponSlot(client, 1);	
	int iSlot2 = GetPlayerWeaponSlot(client, 2);  	int iSlot3 = GetPlayerWeaponSlot(client, 3);
	int iSlot4 = GetPlayerWeaponSlot(client, 4);  

	decl String:sWeapon0[32] ; decl String:sWeapon1[32] ;
	decl String:sWeapon2[32] ; decl String:sWeapon3[32] ;	
	decl String:sWeapon4[32] ; 
	
	//  Protection against grenade duplication exploit
	decl String:sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon))

	if (iSlot2 > 0 && strcmp(sWeapon, "weapon_vomitjar", true) && strcmp(sWeapon, "weapon_pipe_bomb", true) && strcmp(sWeapon, "weapon_molotov", true ))
	{
		GetEdictClassname(iSlot2, sWeapon2, 39);
		AcceptEntityInput(iSlot2, "Kill");
		
		decl i_Ent2
		i_Ent2 = CreateEntityByName(sWeapon2)				
		DispatchSpawn(i_Ent2)
		EquipPlayerWeapon(client, i_Ent2)
	}
	if (iSlot3 > 0)     // Medpack slot
	{
		GetEdictClassname(iSlot3, sWeapon3, 39);
		AcceptEntityInput(iSlot3, "Kill");

		decl i_Ent3		
		i_Ent3 = CreateEntityByName(sWeapon3)				
		DispatchSpawn(i_Ent3)
		EquipPlayerWeapon(client, i_Ent3)
	}

	if (iSlot4 > 0)   // Pill slot
	{
		GetEdictClassname(iSlot4, sWeapon4, 39);
		AcceptEntityInput(iSlot4, "Kill");
	
		decl i_Ent4	
		i_Ent4 = CreateEntityByName(sWeapon4)				
		DispatchSpawn(i_Ent4)
		EquipPlayerWeapon(client, i_Ent4)
	}

	// Will hold properties of primary & secondary weapons
	int g_iWeapon0[4]        ; int iClipSide ;
	
	if (iSlot1 > 0)        // Pistol & melee slot is not empty
	{
		char sg_className[56];
		sg_className[0] = '\0';		
		GetEdictClassname(iSlot1, sg_className, sizeof(sg_className)-1);
	
		if (strcmp(sg_className, "weapon_melee", true))   // only if not a melee weapon (chainsaw is ok). 
		{
			sWeapon1[0]     = '\0';
			char sg_modelName[128];
			sg_modelName[0] = '\0';
		
			if (!strcmp(sg_className, "weapon_pistol", true))
			{
				GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_modelName, sizeof(sg_modelName)-1);

				if (!strcmp(sg_modelName, "models/v_models/v_dual_pistolA.mdl", true))
				{
					sWeapon1 = "dual_pistol";
				}
				else 
				{
					sWeapon1 = "weapon_pistol";
				}				
			}
			else
			{
				GetEdictClassname(iSlot1, sWeapon1, sizeof(sWeapon1));
			}
	
			iClipSide = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);

			AcceptEntityInput(iSlot1, "Kill");

			if (sWeapon1[0] != '\0')
			{
				decl i_Ent1
				if (!strcmp(sWeapon1, "dual_pistol", true))
				{
					i_Ent1 = CreateEntityByName("weapon_pistol")			
					DispatchSpawn(i_Ent1)
					EquipPlayerWeapon(client, i_Ent1)
				
					int iFlags = GetCommandFlags("give");
					SetCommandFlags("give", iFlags & ~FCVAR_CHEAT);
					FakeClientCommand(client, "%s %s", "give", "weapon_pistol");
					SetCommandFlags("give", iFlags);				
				}
				else
				{
					i_Ent1 = CreateEntityByName(sWeapon1)				
					DispatchSpawn(i_Ent1)
					EquipPlayerWeapon(client, i_Ent1)
				}
			}

			iSlot1 = GetPlayerWeaponSlot(client, 1);		
			if (iSlot1 > 0)
			{	
				SetEntProp(iSlot1, Prop_Send, "m_iClip1", iClipSide, 4);
			}			
		}
	}

	
	if (iSlot0 > 0)  // Primary weapon slot
	{
		// Store weapon properties
		GetEdictClassname(iSlot0, sWeapon0, 39);
		g_iWeapon0[0] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
		g_iWeapon0[1] = GetClientAmmo(client, sWeapon0);
		g_iWeapon0[2] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
		g_iWeapon0[3] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);	
	
		// Destroy weapon
		AcceptEntityInput(iSlot0, "Kill")	
		
		// Recreate weapon
		decl i_Ent0
		i_Ent0 = CreateEntityByName(sWeapon0)
		DispatchSpawn(i_Ent0)
		EquipPlayerWeapon(client, i_Ent0)
		
		iSlot0 = GetPlayerWeaponSlot(client, 0);
		if (iSlot0 > 0)                  // Restore properties of main weapon
		{	
			SetEntProp(iSlot0, Prop_Send, "m_iClip1", g_iWeapon0[0], 4);
			SetClientAmmo(client, sWeapon0, g_iWeapon0[1]);
			SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", g_iWeapon0[2], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", g_iWeapon0[3], 4);
		}		
	}	
}



public OnMapStart() 
{     
	SetConVarInt(FindConVar("precache_all_survivors"), 1); 
	
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))    PrecacheModel("models/survivors/survivor_teenangst.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))     PrecacheModel("models/survivors/survivor_biker.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))    PrecacheModel("models/survivors/survivor_manager.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))     PrecacheModel("models/survivors/survivor_namvet.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))    PrecacheModel("models/survivors/survivor_gambler.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))     PrecacheModel("models/survivors/survivor_coach.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))    PrecacheModel("models/survivors/survivor_mechanic.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))     PrecacheModel("models/survivors/survivor_producer.mdl", false); 
} 

/* This Admin Menu was taken from csm, all credits go to Mi123645 */ 
public Action:InitiateMenuAdmin(client, args)  
{ 
	if (client == 0)  
	{ 
		ReplyToCommand(client, "Menu is in-game only."); 
		return; 
	} 
	
	decl String:name[MAX_NAME_LENGTH], String:number[10]; 
	
	new Handle:menu = CreateMenu(ShowMenu2); 
	SetMenuTitle(menu, "Select a client:"); 
	
	for (new i = 1; i <= MaxClients; i++) 
	{ 
		if (!IsClientInGame(i)) continue; 
		if (GetClientTeam(i) != 2) continue; 
		//if (i == client) continue; 
		
		Format(name, sizeof(name), "%N", i); 
		Format(number, sizeof(number), "%i", i); 
		AddMenuItem(menu, number, name); 
	} 
	
	
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER); 
} 

public ShowMenu2(Handle:menu, MenuAction:action, client, param2)  
{ 
	switch (action)  
	{ 
		case MenuAction_Select:  
		{ 
			decl String:number[4]; 
			GetMenuItem(menu, param2, number, sizeof(number)); 
			
			g_iSelectedClient = StringToInt(number); 
			
			new args; 
			ShowMenuAdmin(client, args); 
		} 
		case MenuAction_Cancel: 
		{ 
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
			}			
		} 
		case MenuAction_End:  
		{ 
			CloseHandle(menu); 
		} 
	} 
} 

public Action:ShowMenuAdmin(client,args)  
{ 
	decl String:sMenuEntry[8]; 
	
	new Handle:menu = CreateMenu(CharMenuAdmin); 
	SetMenuTitle(menu, "Choose a character:"); 
	
	IntToString(NICK, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Nick"); 
	IntToString(ROCHELLE, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Rochelle"); 
	IntToString(COACH, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Coach"); 
	IntToString(ELLIS, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Ellis"); 
	
	IntToString(BILL, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Bill");     
	IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Zoey"); 
	IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Francis"); 
	IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry)); 
	AddMenuItem(menu, sMenuEntry, "Louis"); 
	
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER); 
} 

public CharMenuAdmin(Handle:menu, MenuAction:action, client, param2)  
{ 
	switch (action)  
	{ 
		case MenuAction_Select:  
		{ 
			decl String:item[8]; 
			GetMenuItem(menu, param2, item, sizeof(item)); 
			
			switch(StringToInt(item))  
			{ 
				case NICK:        {    NickUse(g_iSelectedClient, NICK);        }  
				case ROCHELLE:    {    RochelleUse(g_iSelectedClient, ROCHELLE);    }  
				case COACH:        {    CoachUse(g_iSelectedClient, COACH);        }  
				case ELLIS:        {    EllisUse(g_iSelectedClient, ELLIS);        }  
				case BILL:        {    BillUse(g_iSelectedClient, BILL);        }  
				case ZOEY:        {    ZoeyUse(g_iSelectedClient, ZOEY);        }  
				case FRANCIS:    {    BikerUse(g_iSelectedClient, FRANCIS);    }  
				case LOUIS:        {    LouisUse(g_iSelectedClient, LOUIS);        }  
				
			} 
		} 
		case MenuAction_Cancel: 
		{ 
			
		} 
		case MenuAction_End:  
		{ 
			CloseHandle(menu); 
		} 
	} 
} 

public Action:ShowMenu(client, args) 
{
	if (client == 0) 
	{
		ReplyToCommand(client, "[CSM] Character Select Menu is in-game only.");
		return;
	}
	if (GetClientTeam(client) != 2)
	{
		ReplyToCommand(client, "[CSM] Character Select Menu is only available to survivors.");
		return;
	}
	if (!IsPlayerAlive(client)) 
	{
		ReplyToCommand(client, "[CSM] You must be alive to use the Character Select Menu!");
		return;
	}
	if (GetUserFlagBits(client) == 0 && g_bAdminsOnly)
	{
		ReplyToCommand(client, "[CSM] Character Select Menu is only available to admins.");
		return;
	}
	decl String:sMenuEntry[8];
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Choose a character:");
	
	IntToString(NICK, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Nick");
	IntToString(ROCHELLE, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Rochelle");
	IntToString(COACH, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Coach");
	IntToString(ELLIS, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Ellis");
	
	IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Bill");    
	IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Zoey");
	IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Francis");
	IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Louis");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public CharMenu(Handle:menu, MenuAction:action, param1, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:item[8];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			switch(StringToInt(item)) 
			{
				case NICK:        {    NickUse(param1, NICK);        }
				case ROCHELLE:    {    RochelleUse(param1, ROCHELLE);    }
				case COACH:        {    CoachUse(param1, COACH);        }
				case ELLIS:        {    EllisUse(param1, ELLIS);        }
				case BILL:        {    BillUse(param1, BILL);        }
				case ZOEY:        {    ZoeyUse(param1, ZOEY);        }
				case FRANCIS:    {    BikerUse(param1, FRANCIS);    }
				case LOUIS:        {    LouisUse(param1, LOUIS);        }
				
			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public _ConVarChange__AdminsOnly(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bAdminsOnly = GetConVarBool(convar);
}    

/* Credits to Machine for this stock bool ;p*/
stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}    


//// Added for admin menu
public OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	// Find player's menu ...
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu (hTopMenu, "Select player's survivor", TopMenuObject_Item, InitiateMenuAdmin2, player_commands, "Select player's survivor", ADMFLAG_GENERIC);
	}
}

public InitiateMenuAdmin2(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{

	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Select player's survivor", "", client);
	}
	else if (action == TopMenuAction_SelectOption){

		if (client == 0)  
		{ 
			ReplyToCommand(client, "Menu is in-game only."); 
			return; 
		} 
	
		decl String:name[MAX_NAME_LENGTH], String:number[10]; 
	
		new Handle:menu = CreateMenu(ShowMenu2); 
		SetMenuTitle(menu, "Select a client:"); 
	
		for (new i = 1; i <= MaxClients; i++) 
		{ 
			if (!IsClientInGame(i)) continue; 
			if (GetClientTeam(i) != 2) continue; 
			// if (i == client) continue; 
			
			Format(name, sizeof(name), "%N", i); 
			Format(number, sizeof(number), "%i", i); 
			AddMenuItem(menu, number, name); 
		}
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER); 		
	}
}




///// Additional functions to locate & restore ammo count. Used by SurvivorChange()


int GetClientAmmo(int client, char[] weapon)
{
	int weapon_offset;
	
	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_rifle_m60"))
	{
		weapon_offset = 12;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		weapon_offset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		weapon_offset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		weapon_offset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		weapon_offset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		weapon_offset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		weapon_offset = 68;
	}

	return weapon_offset > 0 ? GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") +weapon_offset) : 0;
}

void SetClientAmmo(int client, char[] weapon, int count)
{
	int weapon_offset;
	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_rifle_m60"))
	{
		weapon_offset = 12;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		weapon_offset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		weapon_offset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		weapon_offset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		weapon_offset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		weapon_offset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		weapon_offset = 68;
	}

	if (weapon_offset > 0)
	{
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+weapon_offset, count);
	}
}

