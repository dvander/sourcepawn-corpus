#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new bool:g_bIsWeaponEmpty[2048];
new bool:g_bIgnoreWeaponSwitch[MAXPLAYERS+1];

new Handle:ConVar_Pistol_EReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Pistol_EReloadTime = INVALID_HANDLE;
new Handle:ConVar_Pistol_ReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Pistol_ReloadTime = INVALID_HANDLE;
new Handle:ConVar_Pistol_PickupLayer = INVALID_HANDLE;
new Handle:ConVar_Pistol_SwtichLayer = INVALID_HANDLE;

new Handle:ConVar_DPistol_EReloadLayer = INVALID_HANDLE;
new Handle:ConVar_DPistol_EReloadTime = INVALID_HANDLE;
new Handle:ConVar_DPistol_ReloadLayer = INVALID_HANDLE;
new Handle:ConVar_DPistol_ReloadTime = INVALID_HANDLE;
new Handle:ConVar_DPistol_PickupLayer = INVALID_HANDLE;
new Handle:ConVar_DPistol_SwtichLayer = INVALID_HANDLE;

new Handle:ConVar_Huntrifle_EReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Huntrifle_EReloadTime = INVALID_HANDLE;
new Handle:ConVar_Huntrifle_ReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Huntrifle_ReloadTime = INVALID_HANDLE;
new Handle:ConVar_Huntrifle_PickupLayer = INVALID_HANDLE;
new Handle:ConVar_Huntrifle_SwtichLayer = INVALID_HANDLE;

new Handle:ConVar_Rifle_EReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Rifle_EReloadTime = INVALID_HANDLE;
new Handle:ConVar_Rifle_ReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Rifle_ReloadTime = INVALID_HANDLE;
new Handle:ConVar_Rifle_PickupLayer = INVALID_HANDLE;
new Handle:ConVar_Rifle_SwtichLayer = INVALID_HANDLE;

new Handle:ConVar_Smg_EReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Smg_EReloadTime = INVALID_HANDLE;
new Handle:ConVar_Smg_ReloadLayer = INVALID_HANDLE;
new Handle:ConVar_Smg_ReloadTime = INVALID_HANDLE;
new Handle:ConVar_Smg_PickupLayer = INVALID_HANDLE;
new Handle:ConVar_Smg_SwtichLayer = INVALID_HANDLE;

new Handle:ConVar_Pumpshot_PickupLayer = INVALID_HANDLE;
new Handle:ConVar_Pumpshot_SwtichLayer = INVALID_HANDLE;

new Handle:ConVar_Autoshot_PickupLayer = INVALID_HANDLE;
new Handle:ConVar_Autoshot_SwtichLayer = INVALID_HANDLE;

new Handle:ConVar_BlockAttack2 = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Beta Reload Animations",
	author = "Tester:Xeno, Coder:Timocop",
	description = "Beta Reloading Animations",
	version = "2.1",
	url = ""
};

public OnPluginStart()
{
	//PISTOL
	ConVar_Pistol_EReloadLayer = CreateConVar( "l4dbeta_pistol_empty_reloadlayer", "9", "[-1 = DISABLED] <The Empty Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Pistol_EReloadTime = CreateConVar( "l4dbeta_pistol_empty_reloadtime", "1.2", "[1.0 = DISABLED] <Time to Block the Empty Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Pistol_ReloadLayer = CreateConVar( "l4dbeta_pistol_normal_reloadlayer", "-1", "[-1 = DISABLED | 7 = OTHER] <The Normal Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Pistol_ReloadTime = CreateConVar( "l4dbeta_pistol_normal_reloadtime", "0.9", "[1.0 = DISABLED] <Time to Block the Normal Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Pistol_PickupLayer = CreateConVar( "l4dbeta_pistol_pickuplayer", "11", "[-1 = DISABLED] <The Pickup Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Pistol_SwtichLayer = CreateConVar( "l4dbeta_pistol_swtichlayer", "15", "[-1 = DISABLED] <The Swtich Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	//DUAL PISTOL
	ConVar_DPistol_EReloadLayer = CreateConVar( "l4dbeta_dpistol_empty_reloadlayer", "17", "[-1 = DISABLED] <The Empty Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_DPistol_EReloadTime = CreateConVar( "l4dbeta_dpistol_empty_reloadtime", "1.2", "[1.0 = DISABLED] <Time to Block the Empty Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_DPistol_ReloadLayer = CreateConVar( "l4dbeta_dpistol_normal_reloadlayer", "-1", "[-1 = DISABLED | 13 = OTHER] <The Normal Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_DPistol_ReloadTime = CreateConVar( "l4dbeta_dpistol_normal_reloadtime", "0.8", "[1.0 = DISABLED] <Time to Block the Normal Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_DPistol_PickupLayer = CreateConVar( "l4dbeta_dpistol_pickuplayer", "5", "[-1 = DISABLED] <The Pickup Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_DPistol_SwtichLayer = CreateConVar( "l4dbeta_dpistol_swtichlayer", "9", "[-1 = DISABLED] <The Swtich Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	//Huntingrifle
	ConVar_Huntrifle_EReloadLayer = CreateConVar( "l4dbeta_huntingrifle_empty_reloadlayer", "15", "[-1 = DISABLED] <The Empty Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Huntrifle_EReloadTime = CreateConVar( "l4dbeta_huntingrifle_empty_reloadtime", "1.2", "[1.0 = DISABLED] <Time to Block the Empty Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Huntrifle_ReloadLayer = CreateConVar( "l4dbeta_huntingrifle_normal_reloadlayer", "-1", "[-1 = DISABLED | 7 = OTHER] <The Normal Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Huntrifle_ReloadTime = CreateConVar( "l4dbeta_huntingrifle_normal_reloadtime", "0.9", "[1.0 = DISABLED] <Time to Block the Normal Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Huntrifle_PickupLayer = CreateConVar( "l4dbeta_huntingrifle_pickuplayer", "5", "[-1 = DISABLED] <The Pickup Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Huntrifle_SwtichLayer = CreateConVar( "l4dbeta_huntingrifle_swtichlayer", "7", "[-1 = DISABLED] <The Swtich Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	//Rifle
	ConVar_Rifle_EReloadLayer = CreateConVar( "l4dbeta_rifle_empty_reloadlayer", "18", "[-1 = DISABLED] <The Empty Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Rifle_EReloadTime = CreateConVar( "l4dbeta_rifle_empty_reloadtime", "1.2", "[1.0 = DISABLED] <Time to Block the Empty Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Rifle_ReloadLayer = CreateConVar( "l4dbeta_rifle_normal_reloadlayer", "-1", "[-1 = DISABLED | 16 = OTHER] <The Normal Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Rifle_ReloadTime = CreateConVar( "l4dbeta_rifle_normal_reloadtime", "1.0", "[1.0 = DISABLED] <Time to Block the Normal Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Rifle_PickupLayer = CreateConVar( "l4dbeta_rifle_pickuplayer", "8", "[-1 = DISABLED] <The Pickup Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Rifle_SwtichLayer = CreateConVar( "l4dbeta_rifle_swtichlayer", "14", "[-1 = DISABLED] <The Swtich Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	//SMG
	ConVar_Smg_EReloadLayer = CreateConVar( "l4dbeta_smg_empty_reloadlayer", "15", "[-1 = DISABLED] <The Empty Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Smg_EReloadTime = CreateConVar( "l4dbeta_smg_empty_reloadtime", "1.3", "[1.0 = DISABLED] <Time to Block the Empty Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Smg_ReloadLayer = CreateConVar( "l4dbeta_smg_normal_reloadlayer", "-1", "[-1 = DISABLED | 13 = OTHER] <The Normal Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Smg_ReloadTime = CreateConVar( "l4dbeta_smg_normal_reloadtime", "0.7", "[1.0 = DISABLED] <Time to Block the Normal Reload Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Smg_PickupLayer = CreateConVar( "l4dbeta_smg_pickuplayer", "5", "[-1 = DISABLED] <The Pickup Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Smg_SwtichLayer = CreateConVar( "l4dbeta_smg_swtichlayer", "9", "[-1 = DISABLED] <The Swtich Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	//Pumpshotgun
	ConVar_Pumpshot_PickupLayer = CreateConVar( "l4dbeta_pumpshotgun_pickuplayer", "18", "[-1 = DISABLED] <The Pickup Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Pumpshot_SwtichLayer = CreateConVar( "l4dbeta_pumpshotgun_swtichlayer", "18", "[-1 = DISABLED] <The Swtich Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	//Autoshotgun
	ConVar_Autoshot_PickupLayer = CreateConVar( "l4dbeta_autoshotgun_pickuplayer", "39", "[-1 = DISABLED] <The Pickup Reload Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	ConVar_Autoshot_SwtichLayer = CreateConVar( "l4dbeta_autoshotgun_swtichlayer", "39", "[-1 = DISABLED] <The Swtich Layer Sequence>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	ConVar_BlockAttack2 = CreateConVar( "l4dbeta_block_shove", "0", "[1/0 BLOCK/DON'T BLOCK] <Shove is blocked while Reload>", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );

	HookEvent("weapon_fire", eWeaponFire);
	HookEvent("weapon_reload", eReloadWeapon);
	HookEvent("spawner_give_item", ePlayerUse);
	HookEvent("item_pickup", ePlayerUse);
	
	RegConsoleCmd("+attack2", Attack2_Cmd);
	
	AutoExecConfig(true, "l4dbeta_reloading_animation");
}

/****************************************************************************************************************************
	*****************************************************************************************************************************
	*****************************************************************************************************************************
	WARNING!
		If you're using your own animations, make sure its a LAYER(!!!!!) (ModelViewer > "v_models" and select "_LAYERS" only!) or your animation will mess up!
		Good Luck...
	*****************************************************************************************************************************
	*****************************************************************************************************************************
	*****************************************************************************************************************************/

public Action:Attack2_Cmd(iClient, args)    
{
	if(GetConVarInt(ConVar_BlockAttack2) != 1)
	return Plugin_Continue;
	
	if(!IsValidClient(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) != 2)
	return Plugin_Continue;
	
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEntity(iCurrentWeapon))
	return Plugin_Continue;
	
	if(GetEntProp(iCurrentWeapon, Prop_Send, "m_bInReload") > 0)
	{
		PrintHintText(iClient, "[!] Shove is blocked while reloading [!]");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:eWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(iClient) 	
			|| !IsPlayerAlive(iClient) 
			|| IsFakeClient(iClient)
			|| GetClientTeam(iClient) != 2)
	return Plugin_Continue;
	
	ChangeWeaponSize(iClient, 1);
	
	return Plugin_Continue;
}

bool:ChangeWeaponSize(iClient, iClip)
{
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEntity(iCurrentWeapon))
	return false;

	g_bIsWeaponEmpty[iCurrentWeapon] = (GetEntProp(iCurrentWeapon, Prop_Data, "m_iClip1") <= iClip);
	
	return true;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{ 
	if(!IsClientInGame(iClient)) return Plugin_Continue;
	if(GetClientTeam(iClient) != 2) return Plugin_Continue;
	if(IsFakeClient(iClient)) return Plugin_Continue;
	if(!IsPlayerAlive(iClient)) return Plugin_Continue;

	static OLD_WEAPON[MAXPLAYERS+1];
	static NEW_WEAPON[MAXPLAYERS+1];

	NEW_WEAPON[iClient] = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if(NEW_WEAPON[iClient] != OLD_WEAPON[iClient])
	{
		if(!g_bIgnoreWeaponSwitch[iClient])
		WeaponChangeAnimation(iClient);
		else
		g_bIgnoreWeaponSwitch[iClient] = false;
		
		ChangeWeaponSize(iClient, 0);
	}
	OLD_WEAPON[iClient] = NEW_WEAPON[iClient];
	
	return Plugin_Continue;
}

stock bool:WeaponChangeAnimation(iClient)
{
	new iWeaponNum = 0;
	if (GetPlayerWeaponSlot(iClient, 0) > 0 && GetEntProp(GetPlayerWeaponSlot(iClient, 0), Prop_Data, "m_iClip1") > 0) iWeaponNum +=1;
	if (GetPlayerWeaponSlot(iClient, 1) > 0) iWeaponNum += 1;
	if (GetPlayerWeaponSlot(iClient, 2) > 0) iWeaponNum += 1;
	if (GetPlayerWeaponSlot(iClient, 3) > 0) iWeaponNum += 1;
	if (GetPlayerWeaponSlot(iClient, 4) > 0) iWeaponNum += 1;
	
	new iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	
	if(!IsValidEntity(iViewModel))
	return false;
	
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEntity(iCurrentWeapon))
	return false;

	if(iWeaponNum > 1)
	{
		decl String:sWeaponName[64];
		GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));

		if (StrContains(sWeaponName, "smg", false) != -1)
		{
			if(GetConVarInt(ConVar_Smg_SwtichLayer) == -1)
			return false;
			
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Smg_SwtichLayer));
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "weapon_rifle", false) != -1)
		{
			if(GetConVarInt(ConVar_Rifle_SwtichLayer) == -1)
			return false;
			
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Rifle_SwtichLayer));
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "hunting_rifle", false) != -1)
		{
			if(GetConVarInt(ConVar_Huntrifle_SwtichLayer) == -1)
			return false;
			
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Huntrifle_SwtichLayer)); 
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "pumpshotgun", false) != -1)
		{
			if(GetConVarInt(ConVar_Pumpshot_SwtichLayer) == -1)
			return false;
			
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Pumpshot_SwtichLayer)); 
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "autoshotgun", false) != -1)
		{
			if(GetConVarInt(ConVar_Autoshot_SwtichLayer) == -1)
			return false;
			
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Autoshot_SwtichLayer)); 
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "pistol", false) != -1)
		{
			if(GetEntProp(iCurrentWeapon, Prop_Send, "m_isDualWielding") > 0) // ITS A DUAL PISTOL! RUNN!!
			{
				if(GetConVarInt(ConVar_DPistol_SwtichLayer) == -1)
				return false;
				
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_DPistol_SwtichLayer));
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			}
			else
			{
				if(GetConVarInt(ConVar_Pistol_SwtichLayer) == -1)
				return false;
				
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Pistol_SwtichLayer));
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			}
		}
	}
	return true;
}



public Action:eReloadWeapon(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(iClient) 	
			|| !IsPlayerAlive(iClient) 
			|| IsFakeClient(iClient)
			|| GetClientTeam(iClient) != 2)
	return Plugin_Continue;

	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEntity(iCurrentWeapon))
	return Plugin_Continue;

	new iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	
	if(!IsValidEntity(iViewModel))
	return Plugin_Continue;
	
	decl String:sWeaponName[32];
	GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));

	if (StrContains(sWeaponName, "smg", false) != -1)
	{
		if(g_bIsWeaponEmpty[iCurrentWeapon] && GetConVarInt(ConVar_Smg_EReloadLayer) > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Smg_EReloadLayer));
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, GetConVarFloat(ConVar_Smg_EReloadTime));
		}
		else if(GetConVarInt(ConVar_Smg_ReloadLayer) > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Smg_ReloadLayer));
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, GetConVarFloat(ConVar_Smg_ReloadTime));
		}
	}
	else if (StrContains(sWeaponName, "weapon_rifle", false) != -1)
	{
		if(g_bIsWeaponEmpty[iCurrentWeapon] && GetConVarInt(ConVar_Rifle_EReloadLayer) > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Rifle_EReloadLayer));
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, GetConVarFloat(ConVar_Rifle_EReloadTime));
		}
		else if(GetConVarInt(ConVar_Rifle_ReloadLayer) > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Rifle_ReloadLayer));
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, GetConVarFloat(ConVar_Rifle_ReloadTime));
		}
	}
	else if (StrContains(sWeaponName, "hunting_rifle", false) != -1)
	{
		if(g_bIsWeaponEmpty[iCurrentWeapon] && GetConVarInt(ConVar_Huntrifle_EReloadLayer) > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Huntrifle_EReloadLayer)); //16
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, GetConVarFloat(ConVar_Huntrifle_EReloadTime));
		}
		else if(GetConVarInt(ConVar_Huntrifle_ReloadLayer) > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Huntrifle_ReloadLayer));
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, GetConVarFloat(ConVar_Huntrifle_ReloadTime));
		}
	}
	else if (StrContains(sWeaponName, "pistol", false) != -1)
	{
		if(GetEntProp(iCurrentWeapon, Prop_Send, "m_isDualWielding") > 0)
		{	 
			// PrintToChatAll("Weapon_DualPistolSide: %i", Weapon_DualPistolSide(iCurrentWeapon));
			//DUAL PISTOL
			if(g_bIsWeaponEmpty[iCurrentWeapon] && GetConVarInt(ConVar_DPistol_EReloadLayer) > -1)
			{
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_DPistol_EReloadLayer));
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, GetConVarFloat(ConVar_DPistol_EReloadTime));
			}
			else if(GetConVarInt(ConVar_DPistol_ReloadLayer) > -1)
			{
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_DPistol_ReloadLayer));
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, GetConVarFloat(ConVar_DPistol_ReloadTime));
			}
		}
		else 
		{	
			//ONE PISTOL
			if(g_bIsWeaponEmpty[iCurrentWeapon] && GetConVarInt(ConVar_Pistol_EReloadLayer) > -1)
			{
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Pistol_EReloadLayer));
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, GetConVarFloat(ConVar_Pistol_EReloadTime));
			}
			else if(GetConVarInt(ConVar_Pistol_ReloadLayer) > -1)
			{
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Pistol_ReloadLayer));
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, GetConVarFloat(ConVar_Pistol_ReloadTime));
			}
		}
	}
	return Plugin_Continue;
}
public Action:ePlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(iClient) 	
			|| !IsPlayerAlive(iClient) 
			|| IsFakeClient(iClient)
			|| GetClientTeam(iClient) != 2)
	return Plugin_Continue;
	
	decl String:sPickupName[64];
	GetEventString(event, "item", sPickupName, sizeof(sPickupName)); 
	
	g_bIgnoreWeaponSwitch[iClient] = true;

	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEntity(iCurrentWeapon))
	return Plugin_Continue;
	
	new iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	
	if(!IsValidEntity(iViewModel))
	return Plugin_Continue;
	
	
	decl String:sWeaponName[32];
	GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
	
	if(!StrEqual(sPickupName, sWeaponName, false))
	return Plugin_Continue;
	
	if (StrContains(sPickupName, "smg", false) != -1)
	{
		if(GetConVarInt(ConVar_Smg_PickupLayer) < 0)
		return Plugin_Continue;
		
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Smg_PickupLayer));
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "weapon_rifle", false) != -1)
	{
		if(GetConVarInt(ConVar_Rifle_PickupLayer) < 0)
		return Plugin_Continue;
		
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Rifle_PickupLayer));
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "hunting_rifle", false) != -1)
	{
		if(GetConVarInt(ConVar_Huntrifle_PickupLayer) < 0)
		return Plugin_Continue;
		
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Huntrifle_PickupLayer));
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "pumpshotgun", false) != -1)
	{
		if(GetConVarInt(ConVar_Pumpshot_PickupLayer) < 0)
		return Plugin_Continue;
		
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Pumpshot_PickupLayer));
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "autoshotgun", false) != -1)
	{
		if(GetConVarInt(ConVar_Autoshot_PickupLayer) < 0)
		return Plugin_Continue;
		
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Autoshot_PickupLayer));
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "pistol", false) != -1)
	{
		if(GetEntProp(iCurrentWeapon, Prop_Send, "m_isDualWielding") > 0) // ITS A DUAL PISTOL! RUNN!!
		{
			if(GetConVarInt(ConVar_DPistol_PickupLayer) < 0)
			return Plugin_Continue;
			
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_DPistol_PickupLayer));
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else
		{
			if(GetConVarInt(ConVar_Pistol_PickupLayer) < 0)
			return Plugin_Continue;
			
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", GetConVarInt(ConVar_Pistol_PickupLayer));
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
	}
	return Plugin_Continue;
}

stock Weapon_Speed(iClient, Float:fValue) //WITHOUT ANIMATION SPEED CHANGE!
{
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if(IsValidEntity(iCurrentWeapon))
	{
		new Float:fNextPrimaryAttack  = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack");
		new Float:fGameTime = GetGameTime();
		new Float:fNextPrimaryAttack_Mod = (fNextPrimaryAttack - fGameTime ) * fValue;

		fNextPrimaryAttack_Mod += fGameTime;
		
		SetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack", fNextPrimaryAttack_Mod);
		SetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flTimeWeaponIdle", fNextPrimaryAttack_Mod);
		SetEntPropFloat(iClient, Prop_Send, "m_flNextAttack", fNextPrimaryAttack_Mod);

	}
}

stock bool:IsValidClient(iClient)
{
	if(iClient < 1 || iClient > MaxClients)
	return false;

	return IsClientInGame(iClient);
}