#define PLUGIN_VERSION "1.3"
#define PLUGIN_NAME "Survivor Chat Select"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"

#define NICK 0
#define ROCHELLE 1
#define COACH 2
#define ELLIS 3
#define BILL 4
#define ZOEY 5
#define FRANCIS 6
#define LOUIS 7

static g_iSelectedClient;
static bool:g_bAdminsOnly;

enum()
{
	iClip = 0,
	iAmmo,
	iUpgrade,
	iUpAmmo,
};

public Plugin:myinfo =  
{  
	name = PLUGIN_NAME,  
	author = "DeatChaos25 & Mi123456",  
	description = "Lets Players Choose Their Desired Survivor.",  
	version = PLUGIN_VERSION,
	url = ""
};

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
	
	RegAdminCmd("sm_csc", InitiateMenuAdmin, ADMFLAG_GENERIC, "Brings up a menu to select a client's character"); 
	RegConsoleCmd("sm_csm", ShowMenu, "Brings up a menu to select a client's character"); 
	
	new Handle:AdminsOnly = CreateConVar("scs_admins_only", "1", "Enable/Disable Admin Access Only", FCVAR_SPONLY,true, 0.0, true, 1.0);
	g_bAdminsOnly = GetConVarBool(AdminsOnly);
	HookConVarChange(AdminsOnly, _ConVarChange_AdminsOnly);
	
	AutoExecConfig(true, "scs");
}  

public Action:ZoeyUse(client, args)  
{
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Zoey\x01");
	
	DoLegsWorkAround(client, 6);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", NICK);
	SetEntityModel(client, MODEL_ZOEY);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Zoey");
		SetClientName(client, "Zoey");
	}
	
	return Plugin_Handled;
}  

public Action:NickUse(client, args)  
{  
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Nick\x01");
	
	DoLegsWorkAround(client, 1);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", NICK);
	SetEntityModel(client, MODEL_NICK);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Nick");
		SetClientName(client, "Nick");
	}
	
	return Plugin_Handled;
}

public Action:EllisUse(client, args)  
{  
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Ellis\x01");
	
	DoLegsWorkAround(client, 4);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ELLIS);
	SetEntityModel(client, MODEL_ELLIS);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Ellis");
		SetClientName(client, "Ellis");
	}
	
	return Plugin_Handled;
}  

public Action:CoachUse(client, args)  
{  
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Coach\x01");
	
	DoLegsWorkAround(client, 3);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", COACH);
	SetEntityModel(client, MODEL_COACH);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Coach");
		SetClientName(client, "Coach");
	}
	
	return Plugin_Handled;
}  

public Action:RochelleUse(client, args)  
{  
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Rochelle\x01");
	
	DoLegsWorkAround(client, 2);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ROCHELLE);
	SetEntityModel(client, MODEL_ROCHELLE);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Rochelle");
		SetClientName(client, "Rochelle");
	}
	
	return Plugin_Handled;
}  

public Action:BillUse(client, args)  
{  
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Bill\x01");
	
	DoLegsWorkAround(client, 5);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", BILL);
	SetEntityModel(client, MODEL_BILL);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Bill");
		SetClientName(client, "Bill");
	}
	
	return Plugin_Handled;
}  

public Action:BikerUse(client, args)  
{  
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Francis\x01");
	
	DoLegsWorkAround(client, 7);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", NICK);
	SetEntityModel(client, MODEL_FRANCIS);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Francis");
		SetClientName(client, "Francis");
	}
	
	return Plugin_Handled;
}

public Action:LouisUse(client, args)  
{  
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x03SCS\x04]\x01 Current Character: \x05Louis\x01");
	
	DoLegsWorkAround(client, 8);
	WeaponPlacementFix(client);
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", LOUIS);
	SetEntityModel(client, MODEL_LOUIS);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Louis");
		SetClientName(client, "Louis");
	}
	
	return Plugin_Handled;
}

public OnMapStart() 
{
	SetConVarInt(FindConVar("precache_all_survivors"), 1);
	SetConVarInt(FindConVar("sb_l4d1_survivor_behavior"), 0);
}

DoLegsWorkAround(client, survivorCharacter)
{
	switch (survivorCharacter)
	{
		case 1:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 61");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance 1");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance 1");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 120");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 2");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset -3");
			FakeClientCommand(client, "cam_ideallag 0");
		}
		case 2:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 16");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance 0");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance 0");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 1500");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 7");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset 0");
			FakeClientCommand(client, "cam_ideallag 0");
		}
		case 3:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 71");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance 0");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance 0");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 1500");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 7");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset 0");
			FakeClientCommand(client, "cam_ideallag 0");
		}
		case 4:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 61");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance 1");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance 1");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 120");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 1");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset 0");
			FakeClientCommand(client, "cam_ideallag 0");
		}
		case 5:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 14");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance 0.5");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance 0.5");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 1500");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 7");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset 0");
			FakeClientCommand(client, "cam_ideallag 0");
		}
		case 6:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 14");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance -2");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance -2");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 1500");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 7");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset 0");
			FakeClientCommand(client, "cam_ideallag 0");
		}
		case 7:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 14");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance 0");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance 0");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 1500");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 7");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset 0");
			FakeClientCommand(client, "cam_ideallag 0");
		}
		case 8:
		{
			new flags = GetCommandFlags("cl_cam_follow_bone_index");
			SetCommandFlags("cl_cam_follow_bone_index", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "cl_cam_follow_bone_index 14");
			SetCommandFlags("cl_cam_follow_bone_index", flags|FCVAR_CHEAT);
			
			FakeClientCommand(client, "c_maxdistance 0.5");
			FakeClientCommand(client, "c_maxpitch 0");
			FakeClientCommand(client, "c_maxyaw 0");
			FakeClientCommand(client, "c_mindistance 0.5");
			FakeClientCommand(client, "c_minpitch 0");
			FakeClientCommand(client, "c_minyaw 0");
			FakeClientCommand(client, "c_thirdpersonshoulder 1");
			FakeClientCommand(client, "c_thirdpersonshoulderaimdist 1500");
			FakeClientCommand(client, "c_thirdpersonshoulderheight 6");
			FakeClientCommand(client, "c_thirdpersonshoulderoffset 0");
			FakeClientCommand(client, "cam_ideallag 0");
		}
	}
}

WeaponPlacementFix(client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	new i_Weapon = GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hActiveWeapon"));
	if (i_Weapon == -1 || !IsValidEntity(i_Weapon) || !IsValidEdict(i_Weapon))
	{
		return;
	}
	
	new iSlot0 = GetPlayerWeaponSlot(client, 0);
	new iSlot1 = GetPlayerWeaponSlot(client, 1);	
	new iSlot2 = GetPlayerWeaponSlot(client, 2);
	new iSlot3 = GetPlayerWeaponSlot(client, 3);
	new iSlot4 = GetPlayerWeaponSlot(client, 4);  	
	
	decl String:sWeapon[64];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	
	if (iSlot2 > 0 && IsValidEntity(iSlot2) && IsValidEdict(iSlot2))
	{
		if ((strcmp(sWeapon, "weapon_vomitjar", true) || strcmp(sWeapon, "weapon_pipe_bomb", true) || strcmp(sWeapon, "weapon_molotov", true)))
		{
			GetEdictClassname(iSlot2, sWeapon, 64);
			RemoveBuggedWeaponPlacement(client, iSlot2);
			CheatCommand(client, "give", sWeapon, "");
		}
	}
	
	if (iSlot3 > 0 && IsValidEntity(iSlot3) && IsValidEdict(iSlot3))
	{
		GetEdictClassname(iSlot3, sWeapon, 64);
		RemoveBuggedWeaponPlacement(client, iSlot3);
		CheatCommand(client, "give", sWeapon, "");
	}
	
	if (iSlot4 > 0 && IsValidEntity(iSlot4) && IsValidEdict(iSlot4))
	{
		GetEdictClassname(iSlot4, sWeapon, 64);
		RemoveBuggedWeaponPlacement(client, iSlot4);
		CheatCommand(client, "give", sWeapon, "");
	}
	
	if (iSlot1 > 0)
	{
		FixSecondarySlot(client, iSlot1);
	}
	
	if (iSlot0 > 0)
	{
		FixPrimarySlot(client, iSlot0);
	}
}

FixPrimarySlot(client, wSlot)
{
	new iWeapon0[4];
	decl String:sWeapon[64];
	
	if (IsValidEntity(wSlot) && IsValidEdict(wSlot))
	{
		GetEdictClassname(wSlot, sWeapon, 64);
		
		iWeapon0[iClip] = GetEntProp(wSlot, Prop_Send, "m_iClip1", 4);
		iWeapon0[iAmmo] = GetClientAmmo(client, sWeapon);
		iWeapon0[iUpgrade] = GetEntProp(wSlot, Prop_Send, "m_upgradeBitVec", 4);
		iWeapon0[iUpAmmo] = GetEntProp(wSlot, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		
		RemoveBuggedWeaponPlacement(client, wSlot);
		CheatCommand(client, "give", sWeapon, "");
		
		wSlot = GetPlayerWeaponSlot(client, 0);
		if (wSlot > 0 && IsValidEntity(wSlot) && IsValidEdict(wSlot))
		{
			SetEntProp(wSlot, Prop_Send, "m_iClip1", iWeapon0[iClip], 4);
			SetClientAmmo(client, sWeapon, iWeapon0[iAmmo]);
			SetEntProp(wSlot, Prop_Send, "m_upgradeBitVec", iWeapon0[iUpgrade], 4);
			SetEntProp(wSlot, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iWeapon0[iUpAmmo], 4);
		}
	}
}

FixSecondarySlot(client, wSlot2)
{
	decl String:className[64];
	decl String:modelName[64];
	
	decl String:sWeapon[64];
	sWeapon[0] = '\0';
	new Ammo = -1;
	new sSlot = -1;
	
	if (IsValidEntity(wSlot2) && IsValidEdict(wSlot2))
	{
		GetEdictClassname(wSlot2, className, sizeof(className));
		
		if (!strcmp(className, "weapon_melee", true))
		{
			GetEntPropString(wSlot2, Prop_Data, "m_strMapSetScriptName", sWeapon, 64);
		}
		else if (strcmp(className, "weapon_pistol", true))
		{
			GetEdictClassname(wSlot2, sWeapon, 64);
		}
		
		if (sWeapon[0] == '\0')
		{
			GetEntPropString(wSlot2, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
			
			if (StrContains(modelName, "v_pistolA.mdl", true) != -1)
			{
				sWeapon = "weapon_pistol";
			}
			else if (StrContains(modelName, "v_dual_pistolA.mdl", true) != -1)
			{
				sWeapon = "dual_pistol";
			}
			else if (StrContains(modelName, "v_desert_eagle.mdl", true) != -1)
			{
				sWeapon = "weapon_pistol_magnum";
			}
			else if (StrContains(modelName, "v_bat.mdl", true) != -1)
			{
				sWeapon = "baseball_bat";
			}
			else if (StrContains(modelName, "v_cricket_bat.mdl", true) != -1)
			{
				sWeapon = "cricket_bat";
			}
			else if (StrContains(modelName, "v_crowbar.mdl", true) != -1)
			{
				sWeapon = "crowbar";
			}
			else if (StrContains(modelName, "v_fireaxe.mdl", true) != -1)
			{
				sWeapon = "fireaxe";
			}
			else if (StrContains(modelName, "v_katana.mdl", true) != -1)
			{
				sWeapon = "katana";
			}
			else if (StrContains(modelName, "v_golfclub.mdl", true) != -1)
			{
				sWeapon = "golfclub";
			}
			else if (StrContains(modelName, "v_machete.mdl", true) != -1)
			{
				sWeapon = "machete";
			}
			else if (StrContains(modelName, "v_tonfa.mdl", true) != -1)
			{
				sWeapon = "tonfa";
			}
			else if (StrContains(modelName, "v_electric_guitar.mdl", true) != -1)
			{
				sWeapon = "electric_guitar";
			}
			else if (StrContains(modelName, "v_frying_pan.mdl", true) != -1)
			{
				sWeapon = "frying_pan";
			}
			else if (StrContains(modelName, "v_knife_t.mdl", true) != -1)
			{
				sWeapon = "knife";
			}
			else if (StrContains(modelName, "v_chainsaw.mdl", true) != -1)
			{
				sWeapon = "weapon_chainsaw";
			}
			else if (StrContains(modelName, "v_riotshield.mdl", true) != -1)
			{
				sWeapon = "alliance_shield";
			}
			else if (StrContains(modelName, "v_fubar.mdl", true) != -1)
			{
				sWeapon = "fubar";
			}
			else if (StrContains(modelName, "v_paintrain.mdl", true) != -1)
			{
				sWeapon = "nail_board";
			}
			else if (StrContains(modelName, "v_sledgehammer.mdl", true) != -1)
			{
				sWeapon = "sledgehammer";
			}
		}
		else
		{
			if (!strcmp(sWeapon, "dual_pistol", true) || !strcmp(sWeapon, "weapon_pistol", true) || !strcmp(sWeapon, "weapon_pistol_magnum", true) || !strcmp(sWeapon, "weapon_chainsaw", true))
			{
				Ammo = GetEntProp(wSlot2, Prop_Send, "m_iClip1", 4);
			}
			
			RemoveBuggedWeaponPlacement(client, wSlot2);
			
			if (!strcmp(sWeapon, "dual_pistol", true))
			{
				CheatCommand(client, "give", "weapon_pistol", "");
				CheatCommand(client, "give", "weapon_pistol", "");
			}
			else if (!strcmp(sWeapon, "weapon_pistol", true))
			{
				CheatCommand(client, "give", "weapon_pistol", "");
			}
			else
			{
				CheatCommand(client, "give", sWeapon, "");
			}
			
			if (Ammo >= 0)
			{
				sSlot = GetPlayerWeaponSlot(client, 1);
				if (sSlot > 0 && IsValidEntity(sSlot) && IsValidEdict(sSlot))
				{
					SetEntProp(sSlot, Prop_Send, "m_iClip1", Ammo, 4);
				}
			}
		}
	}
}

RemoveBuggedWeaponPlacement(client, bWeapon)
{		
	if(RemovePlayerItem(client, bWeapon))
	{
		AcceptEntityInput(bWeapon, "Kill");
	}
}

public Action:InitiateMenuAdmin(client, args)  
{ 
	if (client == 0 || !IsClientInGame(client))  
	{
		return Plugin_Handled; 
	} 
	
	decl String:name[MAX_NAME_LENGTH], String:number[10]; 
	
	new Handle:menu = CreateMenu(ShowMenu2); 
	SetMenuTitle(menu, "Select Client:"); 
	
	for (new i = 1; i <= MaxClients; i++) 
	{ 
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || i == client)
		{
			continue;
		}
		
		Format(name, sizeof(name), "%N", i); 
		Format(number, sizeof(number), "%i", i); 
		AddMenuItem(menu, number, name); 
	} 
	
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
} 

public ShowMenu2(Handle:menu, MenuAction:action, param1, param2)  
{ 
	switch (action)  
	{ 
		case MenuAction_Select:  
		{ 
			decl String:number[4]; 
			GetMenuItem(menu, param2, number, sizeof(number)); 
			
			g_iSelectedClient = StringToInt(number); 
			
			new args; 
			ShowMenuAdmin(param1, args); 
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

public Action:ShowMenuAdmin(client, args)  
{ 
	decl String:sMenuEntry[8]; 
	
	new Handle:menu = CreateMenu(CharMenuAdmin); 
	SetMenuTitle(menu, "Choose Character:"); 
	
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
	
	return Plugin_Handled;
} 

public CharMenuAdmin(Handle:menu, MenuAction:action, param1, param2)  
{ 
	switch (action)  
	{ 
		case MenuAction_Select:  
		{ 
			decl String:item[8]; 
			GetMenuItem(menu, param2, item, sizeof(item)); 
			
			switch(StringToInt(item))  
			{ 
				case NICK: { NickUse(g_iSelectedClient, NICK); }  
				case ROCHELLE: { RochelleUse(g_iSelectedClient, ROCHELLE); }  
				case COACH: { CoachUse(g_iSelectedClient, COACH); }  
				case ELLIS: { EllisUse(g_iSelectedClient, ELLIS); }  
				case BILL: { BillUse(g_iSelectedClient, BILL); }  
				case ZOEY: { ZoeyUse(g_iSelectedClient, ZOEY); }  
				case FRANCIS: { BikerUse(g_iSelectedClient, FRANCIS); }  
				case LOUIS: { LouisUse(g_iSelectedClient, LOUIS); }
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
	if (client <= 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) 
	{
		return Plugin_Handled;
	}
	
	if (GetUserFlagBits(client) == 0 && g_bAdminsOnly)
	{
		return Plugin_Handled;
	}
	
	decl String:sMenuEntry[8];
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Choose Character:");
	
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
	
	return Plugin_Handled;
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
				case NICK: { NickUse(param1, NICK); }
				case ROCHELLE: { RochelleUse(param1, ROCHELLE); }
				case COACH: { CoachUse(param1, COACH); }
				case ELLIS: { EllisUse(param1, ELLIS); }
				case BILL: { BillUse(param1, BILL); }
				case ZOEY: { ZoeyUse(param1, ZOEY); }
				case FRANCIS: { BikerUse(param1, FRANCIS); }
				case LOUIS: { LouisUse(param1, LOUIS); }
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

public _ConVarChange_AdminsOnly(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bAdminsOnly = GetConVarBool(convar);
}    

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

stock CheatCommand(client, const String:command[], const String:argument1[], const String:argument2[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
}

GetClientAmmo(client, String:weapon[])
{
	new weapon_offset = GetWeaponOffset(weapon);
	new iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	return weapon_offset > 0 ? GetEntData(client, iAmmoOffset + weapon_offset) : 0;
}

SetClientAmmo(client, String:weapon[], count)
{
	new weapon_offset = GetWeaponOffset(weapon);
	new iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	if (weapon_offset > 0)
	{
		SetEntData(client, iAmmoOffset + weapon_offset, count);
	}
}

GetWeaponOffset(String:weapon[])
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

	return weapon_offset;
}

