#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:g_bIsWeaponEmpty[2048], bool:g_bIgnoreWeaponSwitch[MAXPLAYERS+1];

//PISTOL
new			Pistol_EReloadLayer = 9;		// The Empty Reload Layer Sequence			[-1 = DISABLED]
new	Float:	Pistol_EReloadTime = 1.2;		// Time to Block the Empty Reload Sequence	[1.0 = DISABLED]
new			Pistol_ReloadLayer = 5;			// The Normal Reload Layer Sequence			[-1 = DISABLED, 7 = OTHER]
new			Pistol_PickupLayer = 11;		// The Pickup Layer Sequence				[-1 = DISABLED]
new			Pistol_SwtichLayer = 15;		// The Swtich Layer Sequence				[-1 = DISABLED]

//DUAL PISTOL
new			DPistol_EReloadLayer = 17;		// The Empty Reload Layer Sequence			[-1 = DISABLED]
new	Float:	DPistol_EReloadTime = 1.2;		// Time to Block the Empty Reload Sequence	[1.0 = DISABLED]
new			DPistol_ReloadLayer = 11;		// The Normal Reload Layer Sequence			[-1 = DISABLED, 13 = OTHER]
new			DPistol_PickupLayer = 5;		// The Pickup Layer Sequence				[-1 = DISABLED]
new			DPistol_SwtichLayer = 9;		// The Swtich Layer Sequence				[-1 = DISABLED]

//HUNTING RIFLE
new			HRifle_EReloadLayer = 15;		// The Empty Reload Layer Sequence			[-1 = DISABLED]
new	Float:	HRifle_EReloadTime = 1.2;		// Time to Block the Empty Reload Sequence	[1.0 = DISABLED]
new			HRifle_ReloadLayer = 5;			// The Normal Reload Layer Sequence			[-1 = DISABLED, 7 = OTHER]
new			HRifle_PickupLayer = 5;			// The Pickup Layer Sequence				[-1 = DISABLED]
new			HRifle_SwtichLayer = 9;			// The Swtich Layer Sequence				[-1 = DISABLED]

//RIFLE
new			Rifle_EReloadLayer = 18;		// The Empty Reload Layer Sequence			[-1 = DISABLED]
new	Float:	Rifle_EReloadTime = 1.2;		// Time to Block the Empty Reload Sequence	[1.0 = DISABLED]
new			Rifle_ReloadLayer = 8;			// The Normal Reload Layer Sequence			[-1 = DISABLED, 16 = OTHER]
new			Rifle_PickupLayer = 22;			// The Pickup Layer Sequence				[-1 = DISABLED]
new			Rifle_SwtichLayer = 14;			// The Swtich Layer Sequence				[-1 = DISABLED]

//SMG
new			Smg_EReloadLayer = 15;			// The Empty Reload Layer Sequence			[-1 = DISABLED]
new	Float:	Smg_EReloadTime = 1.3;			// Time to Block the Empty Reload Sequence	[1.0 = DISABLED]
new			Smg_ReloadLayer = 11;			// The Normal Reload Layer Sequence			[-1 = DISABLED, 13 = OTHER]
new			Smg_PickupLayer = 5;			// The Pickup Reload Layer Sequence			[-1 = DISABLED]
new			Smg_SwtichLayer = 9;			// The Swtich Layer Sequence				[-1 = DISABLED]

//PUMPSHOTGUN
new			PumpShotgun_PickupLayer = 18;	// The Pickup Reload Layer Sequence			[-1 = DISABLED]
new			PumpShotgun_SwtichLayer = 18;	// The Swtich Layer Sequence				[-1 = DISABLED]

//AUTOSHOTGUN
new			AutoShotgun_PickupLayer = 39;	// The Pickup Reload Layer Sequence			[-1 = DISABLED]
new			AutoShotgun_SwtichLayer = 39;	// The Swtich Layer Sequence				[-1 = DISABLED]


//RELOAD SHOVE BLOCK
new bool:	ShoveBlock = true;				// Block shove while reloading				[true = yes, false = no]

public Plugin:myinfo = 
{
	name = "Beta Reload Animations", 
	author = "Timocop, Xeno, edited by Ren89", 
	description = "Beta Reloading Animations", 
	version = "2.2"
};

public OnPluginStart()
{
	HookEvent("weapon_fire",		Event_WeaponFire);
	HookEvent("weapon_reload",		Event_WeaponReload);
	HookEvent("spawner_give_item",	Event_PlayerUse);
	HookEvent("item_pickup",		Event_PlayerUse);
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(iClient) || !IsPlayerAlive(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) != 2) return Plugin_Continue;
	ChangeWeaponSize(iClient, 1);
	return Plugin_Continue;
}

bool:ChangeWeaponSize(iClient, iClip)
{
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(iCurrentWeapon) || iCurrentWeapon > 2048) return false;
	g_bIsWeaponEmpty[iCurrentWeapon] = (GetEntProp(iCurrentWeapon, Prop_Data, "m_iClip1") <= iClip);
	return true;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{ 
	if (!IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || IsFakeClient(iClient) || !IsPlayerAlive(iClient)) return Plugin_Continue;
	
	static OLD_WEAPON[MAXPLAYERS+1], NEW_WEAPON[MAXPLAYERS+1];
	NEW_WEAPON[iClient] = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (NEW_WEAPON[iClient] != OLD_WEAPON[iClient])
	{
		if (!g_bIgnoreWeaponSwitch[iClient]) WeaponChangeAnimation(iClient);
		else g_bIgnoreWeaponSwitch[iClient] = false;
		ChangeWeaponSize(iClient, 0);
		if (ShoveBlock) SetEntPropFloat(iClient, Prop_Send, "m_flNextShoveTime", 0.1);
	}
	OLD_WEAPON[iClient] = NEW_WEAPON[iClient];
	return Plugin_Continue;
}

stock bool:WeaponChangeAnimation(iClient)
{
	new iWeaponNum = 0;
	if (GetPlayerWeaponSlot(iClient, 0) > 0 && GetEntProp(GetPlayerWeaponSlot(iClient, 0), Prop_Data, "m_iClip1") > 0) iWeaponNum += 1;
	if (GetPlayerWeaponSlot(iClient, 1) > 0) iWeaponNum += 1;
	if (GetPlayerWeaponSlot(iClient, 2) > 0) iWeaponNum += 1;
	if (GetPlayerWeaponSlot(iClient, 3) > 0) iWeaponNum += 1;
	if (GetPlayerWeaponSlot(iClient, 4) > 0) iWeaponNum += 1;
	
	new iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	if (!IsValidEntity(iViewModel)) return false;
	
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(iCurrentWeapon)) return false;
	
	if (iWeaponNum > 1)
	{
		decl String:sWeaponName[64];
		GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
		if (StrContains(sWeaponName, "smg", false) != -1)
		{
			if (Smg_SwtichLayer == -1) return false;
			new Smg_Random_SwtichLayer;
			switch(GetRandomInt(1, 4))
			{
				case 1: Smg_Random_SwtichLayer = 7;
				case 2: Smg_Random_SwtichLayer = 9;
				case 3: Smg_Random_SwtichLayer = 19;
				case 4: Smg_Random_SwtichLayer = 21;
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Smg_Random_SwtichLayer);
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "weapon_rifle", false) != -1)
		{
			if (Rifle_SwtichLayer == -1) return false;
			new Rifle_Random_SwtichLayer;
			switch(GetRandomInt(1, 2))
			{
				case 1: Rifle_Random_SwtichLayer = 14;
				case 2: Rifle_Random_SwtichLayer = 22;
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Rifle_Random_SwtichLayer);
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "hunting_rifle", false) != -1)
		{
			if (HRifle_SwtichLayer == -1) return false;
			new Huntrifle_Random_SwtichLayer;
			switch(GetRandomInt(1, 2))
			{
				case 1: Huntrifle_Random_SwtichLayer = 7;
				case 2: Huntrifle_Random_SwtichLayer = 9;
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Huntrifle_Random_SwtichLayer); 
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "pumpshotgun", false) != -1)
		{
			if (PumpShotgun_SwtichLayer == -1) return false;
			new Pumpshot_Random_SwtichLayer;
			switch(GetRandomInt(1, 4))
			{
				case 1: Pumpshot_Random_SwtichLayer = 17;
				case 2: Pumpshot_Random_SwtichLayer = 18;
				case 3: Pumpshot_Random_SwtichLayer = 19;
				case 4: Pumpshot_Random_SwtichLayer = 21;
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Pumpshot_Random_SwtichLayer); 
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "autoshotgun", false) != -1)
		{
			if (AutoShotgun_SwtichLayer == -1) return false;
			new Autoshot_Random_SwtichLayer;
			switch(GetRandomInt(1, 6))
			{
				case 1: Autoshot_Random_SwtichLayer = 16;
				case 2: Autoshot_Random_SwtichLayer = 17;
				case 3: Autoshot_Random_SwtichLayer = 18;
				case 4: Autoshot_Random_SwtichLayer = 19;
				case 5: Autoshot_Random_SwtichLayer = 20;
				case 6: Autoshot_Random_SwtichLayer = 39;
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Autoshot_Random_SwtichLayer); 
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else if (StrContains(sWeaponName, "pistol", false) != -1)
		{
			if (GetEntProp(iCurrentWeapon, Prop_Send, "m_isDualWielding") > 0) // ITS A DUAL PISTOL! RUNN!!
			{
				if (DPistol_SwtichLayer == -1) return false;
				new DPistol_Random_SwtichLayer;
				switch(GetRandomInt(1, 5))
				{
					case 1: DPistol_Random_SwtichLayer = 5;
					case 2: DPistol_Random_SwtichLayer = 7;
					case 3: DPistol_Random_SwtichLayer = 15;
					case 4: DPistol_Random_SwtichLayer = 23;
					case 5: DPistol_Random_SwtichLayer = 25;
				}
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", DPistol_Random_SwtichLayer);
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			}
			else
			{
				if (Pistol_SwtichLayer == -1) return false;
				new Pistol_Random_SwtichLayer;
				switch(GetRandomInt(1, 2))
				{
					case 1: Pistol_Random_SwtichLayer = 13;
					case 2: Pistol_Random_SwtichLayer = 15;
				}
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Pistol_Random_SwtichLayer);
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			}
		}
	}
	return true;
}

public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(iClient) || !IsPlayerAlive(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) != 2) return Plugin_Continue;

	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(iCurrentWeapon)) return Plugin_Continue;

	new iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	if (!IsValidEntity(iViewModel)) return Plugin_Continue;
	
	decl String:sWeaponName[32];
	GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
	if (StrContains(sWeaponName, "smg", false) != -1)
	{
		if (g_bIsWeaponEmpty[iCurrentWeapon] && Smg_EReloadLayer > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Smg_EReloadLayer);
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, Smg_EReloadTime);
		}
		else if (Smg_ReloadLayer > -1)
		{
			new Smg_ReloadLayer_Random, Float:Smg_ReloadTime_Random;
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					Smg_ReloadLayer_Random = 11;
					Smg_ReloadTime_Random = 0.8;
				}
				case 2:
				{
					Smg_ReloadLayer_Random = 15;
					Smg_ReloadTime_Random = 1.4;
				}
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Smg_ReloadLayer_Random);
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, Smg_ReloadTime_Random);
		}
	}
	else if (StrContains(sWeaponName, "weapon_rifle", false) != -1)
	{
		if (g_bIsWeaponEmpty[iCurrentWeapon] && Rifle_EReloadLayer > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Rifle_EReloadLayer);
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, Rifle_EReloadTime);
		}
		else if (Rifle_ReloadLayer > -1)
		{
			new Rifle_ReloadLayer_Random, Float:Rifle_ReloadTime_Random;
			switch(GetRandomInt(1, 4))
			{
				case 1:
				{
					Rifle_ReloadLayer_Random = 8;
					Rifle_ReloadTime_Random = 2.6;
				}
				case 2:
				{
					Rifle_ReloadLayer_Random = 10;
					Rifle_ReloadTime_Random = 2.1;
				}
				case 3:
				{
					Rifle_ReloadLayer_Random = 16;
					Rifle_ReloadTime_Random = 1.0;
				}
				case 4:
				{
					Rifle_ReloadLayer_Random = 18;
					Rifle_ReloadTime_Random = 1.3;
				}
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Rifle_ReloadLayer_Random);
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, Rifle_ReloadTime_Random);
		}
	}
	else if (StrContains(sWeaponName, "hunting_rifle", false) != -1)
	{
		if (g_bIsWeaponEmpty[iCurrentWeapon] && HRifle_EReloadLayer > -1)
		{
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", HRifle_EReloadLayer); //16
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, HRifle_EReloadTime);
		}
		else if (HRifle_ReloadLayer > -1)
		{
			new Huntrifle_ReloadLayer_Random, Float:Huntrifle_ReloadTime_Random;
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					Huntrifle_ReloadLayer_Random = 5;
					Huntrifle_ReloadTime_Random = 1.3;
				}
				case 2:
				{
					Huntrifle_ReloadLayer_Random = 11;
					Huntrifle_ReloadTime_Random = 1.0;
				}
			}
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Huntrifle_ReloadLayer_Random);
			SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
			Weapon_Speed(iClient, Huntrifle_ReloadTime_Random);
		}
	}
	else if (StrContains(sWeaponName, "pistol", false) != -1)
	{
		if (GetEntProp(iCurrentWeapon, Prop_Send, "m_isDualWielding") > 0)
		{
			//DUAL PISTOL
			if (g_bIsWeaponEmpty[iCurrentWeapon] && DPistol_EReloadLayer > -1)
			{
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", DPistol_EReloadLayer);
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, DPistol_EReloadTime);
			}
			else if (DPistol_ReloadLayer > -1)
			{
				new DPistol_ReloadLayer_Random, Float:DPistol_ReloadTime_Random;
				switch(GetRandomInt(1, 2))
				{
					case 1:
					{
						DPistol_ReloadLayer_Random = 11;
						DPistol_ReloadTime_Random = 1.1;
					}
					case 2:
					{
						DPistol_ReloadLayer_Random = 17;
						DPistol_ReloadTime_Random = 1.3;
					}
				}
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", DPistol_ReloadLayer_Random);
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, DPistol_ReloadTime_Random);
			}
		}
		else 
		{	
			//ONE PISTOL
			if (g_bIsWeaponEmpty[iCurrentWeapon] && Pistol_EReloadLayer > -1)
			{
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Pistol_EReloadLayer);
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime()); //Some Animation Glich Fixes
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, Pistol_EReloadTime);
			}
			else if (Pistol_ReloadLayer > -1)
			{
				new Pistol_ReloadLayer_Random, Float:Pistol_ReloadTime_Random;
				switch(GetRandomInt(1, 3))
				{
					case 1:
					{
						Pistol_ReloadLayer_Random = 5;
						Pistol_ReloadTime_Random = 1.3;
					}
					case 2:
					{
						Pistol_ReloadLayer_Random = 9;
						Pistol_ReloadTime_Random = 1.4;
					}
					case 3:
					{
						Pistol_ReloadLayer_Random = 11;
						Pistol_ReloadTime_Random = 1.1;
					}
				}
				SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Pistol_ReloadLayer_Random);
				SetEntPropFloat(iViewModel, Prop_Send, "m_flLayerStartTime", GetGameTime());
				ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
				Weapon_Speed(iClient, Pistol_ReloadTime_Random);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(iClient) || !IsPlayerAlive(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) != 2) return Plugin_Continue;
	
	decl String:sPickupName[64];
	GetEventString(event, "item", sPickupName, sizeof(sPickupName)); 
	
	g_bIgnoreWeaponSwitch[iClient] = true;
	
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(iCurrentWeapon)) return Plugin_Continue;
	
	new iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	if (!IsValidEntity(iViewModel)) return Plugin_Continue;
	
	decl String:sWeaponName[32];
	GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
	if (!StrEqual(sPickupName, sWeaponName, false)) return Plugin_Continue;
	if (StrContains(sPickupName, "smg", false) != -1)
	{
		if (Smg_PickupLayer == -1) return Plugin_Continue;
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Smg_PickupLayer);
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "weapon_rifle", false) != -1)
	{
		if (Rifle_PickupLayer == -1) return Plugin_Continue;
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Rifle_PickupLayer);
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "hunting_rifle", false) != -1)
	{
		if (HRifle_PickupLayer == -1) return Plugin_Continue;
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", HRifle_PickupLayer);
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "pumpshotgun", false) != -1)
	{
		if (PumpShotgun_PickupLayer == -1) return Plugin_Continue;
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", PumpShotgun_PickupLayer);
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "autoshotgun", false) != -1)
	{
		if (AutoShotgun_PickupLayer == -1) return Plugin_Continue;
		SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", AutoShotgun_PickupLayer);
		ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
	}
	else if (StrContains(sPickupName, "pistol", false) != -1)
	{
		if (GetEntProp(iCurrentWeapon, Prop_Send, "m_isDualWielding") > 0) // ITS A DUAL PISTOL! RUNN!!
		{
			if (DPistol_PickupLayer == -1) return Plugin_Continue;
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", DPistol_PickupLayer);
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
		else
		{
			if (Pistol_PickupLayer == -1) return Plugin_Continue;
			SetEntProp(iViewModel, Prop_Send, "m_nLayerSequence", Pistol_PickupLayer);
			ChangeEdictState(iViewModel, FindDataMapOffs(iViewModel, "m_nLayerSequence"));
		}
	}
	
	return Plugin_Continue;
}

stock Weapon_Speed(iClient, Float:fValue) //WITHOUT ANIMATION SPEED CHANGE!
{
	new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(iCurrentWeapon))
	{
		new Float:fNextPrimaryAttack  = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack");
		new Float:fGameTime = GetGameTime();
		new Float:fNextPrimaryAttack_Mod = (fNextPrimaryAttack - fGameTime) * fValue;
		fNextPrimaryAttack_Mod += fGameTime;
		SetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack", fNextPrimaryAttack_Mod);
		SetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flTimeWeaponIdle", fNextPrimaryAttack_Mod);
		SetEntPropFloat(iClient, Prop_Send, "m_flNextAttack", fNextPrimaryAttack_Mod);
		if (ShoveBlock) SetEntPropFloat(iClient, Prop_Send, "m_flNextShoveTime", fNextPrimaryAttack_Mod);
	}
}

stock bool:IsValidClient(iClient)
{
	return iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient);
}