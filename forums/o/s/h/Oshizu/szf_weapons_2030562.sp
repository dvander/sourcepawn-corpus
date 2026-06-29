#include <tf2_stocks>
#include <tf2items>
#include <tf2items_giveweapon>
//#include <tf2_hud>

new szfmap = false
new CanPick[MAXPLAYERS+1] = false

new Handle:CanPick_cooldown_h
new Float:CanPick_cooldown = 15.0

new Handle:RemoveOnPick_h
new RemoveOnPick = true

public Plugin:myinfo =
{
	name 		=		"[TF2] Super Zombie Fortress Weapons",
	author		=		"Oshizu / Sena",
	description	=		"Allows clients to pickup weapons on szf_ maps by Pressing E button while looking at them!",
	version		=		"2.0.1",
	url			=		"http://steamcommunity.com/id/Oshizu/"
};

public OnPluginStart()
{
	AddCommandListener(hook_VoiceMenu, "voicemenu"); 
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	LoadTranslations("szfweps.phrases");
	
	CanPick_cooldown_h = CreateConVar("sm_szf_pickup_cooldown", "15.0", "How many seconds players must wait before picking up weapon again")
	HookConVarChange(CanPick_cooldown_h, CanPick_Change)
	
	RemoveOnPick_h = CreateConVar("sm_szf_pickup_remove", "1", "Remove Weapons when player picks them up from floor?")
	HookConVarChange(RemoveOnPick_h, RemoveOnPick_Change)
}

public RemoveOnPick_Change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) == 1)
	{
		RemoveOnPick = true
	}
	else if(StringToInt(newValue) == 0)
	{
		RemoveOnPick = false
	}
}

public CanPick_Change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CanPick_cooldown = StringToFloat(newValue)
}

public OnClientDisconnect(client)
{
	CanPick[client] = false
}

public OnConfigsExecuted()
{
	if(mapIsSZF())
	{
		szfmap = true
	}
	else
	{
		szfmap = false
	} 
}

public player_death(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CanPick[client] = true;
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast) 
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return; // Error-checking
	if (szfmap)
	{
		if (GetClientTeam(client) == 2) 
		{
			PrintToChat(client, "%t", "Weapon Msg");
			TF2_RemoveWeaponSlot(client, 0) 
			TF2_RemoveWeaponSlot(client, 1)
			TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
		}
	}
}

public Action:hook_VoiceMenu(client, const String:command[], argc)
{
	decl String:cmd1[32], String:cmd2[32];
	GetCmdArg(1, cmd1, sizeof(cmd1));
	GetCmdArg(2, cmd2, sizeof(cmd2));
	
	// Pickup Weapon
	if(StrEqual(cmd1, "0") && StrEqual(cmd2, "0"))
	{
		if(GetClientTeam(client) == 2)
		{
			if(CanPick[client])
			{
				AttemptGrabItem(client)
			}
			else
			{
				PrintToChat(client, "%t", "Weapon Disallowed");
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public bool:TraceDontHitEntity(iEntity, iMask, any:iData) {
	if(iEntity == iData)  return false;
	return true;
}

AttemptGrabItem(client)
{
	new iTarget = GetClientPointVisible(client);

	new String:strClassname[255];
	if (iTarget > 0) GetEdictClassname(iTarget, strClassname, sizeof(strClassname));
	if (iTarget <= 0 || !IsClassname(iTarget, "prop_dynamic")) return;

	decl String:strModel[255];
	GetEntityModel(iTarget, strModel, sizeof(strModel));

	if (TF2_GetPlayerClass(client) == TFClass_Soldier) // Soldier Only Weapons
	{
		if (StrEqual(strModel, "models/weapons/w_models/w_shotgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 10, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_shotgun/c_shotgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 10, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/w_models/w_rocketlauncher.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 18, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_blackbox/c_blackbox.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 228, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_directhit/c_directhit.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 127, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_bet_rocketlauncher/c_bet_rocketlauncher.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 513, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_reserve_shooter/c_reserve_shooter.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 415, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_drg_righteousbison/c_drg_righteousbison.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 442, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_liberty_launcher/c_liberty_launcher.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 414, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_drg_cowmangler/c_drg_cowmangler.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 441, iTarget) 
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_shogun_warhorn/c_shogun_warhorn.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 354, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_bugle/c_bugle.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 129, iTarget)
		}
	}
	if (TF2_GetPlayerClass(client) == TFClass_Pyro) // Pyro Only Weapons
	{
		if (StrEqual(strModel, "models/weapons/w_models/w_shotgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 12, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_shotgun/c_shotgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 12, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_flaregun_pyro/c_flaregun_pyro.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 39, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_detonator/c_detonator.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 351, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_reserve_shooter/c_reserve_shooter.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 415, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_degreaser/c_degreaser.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 215, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_drg_phlogistinator/c_drg_phlogistinator.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 594, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_flamethrower/c_flamethrower.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 21, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_drg_manmelter/c_drg_manmelter.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 595, iTarget)
		}
	}
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan) // Demoman Only Weapons
	{
		if (StrEqual(strModel, "models/weapons/w_models/w_grenadelauncher.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 19, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_scottish_resistance.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 130, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_lochnload/c_lochnload.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 308, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/w_models/w_stickybomb_launcher.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 20, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_sticky_jumper.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 265, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_targe/c_targe.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 131, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_persian_shield/c_persian_shield.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 406, iTarget)
		}
	}
	if (TF2_GetPlayerClass(client) == TFClass_Engineer) // Engineer Only Weapons
	{
		if (StrEqual(strModel, "models/weapons/w_models/w_shotgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 9, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_shotgun/c_shotgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 9, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_dex_shotgun/c_dex_shotgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 527, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_ttg_max_gun/c_ttg_max_gun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 160, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/w_models/w_frontierjustice.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 141, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_frontierjustice/c_frontierjustice.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 141, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_wrangler.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 140, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_pistol.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 22, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_drg_pomson/c_drg_pomson.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 588, iTarget)
		}
	}
	if (TF2_GetPlayerClass(client) == TFClass_Medic) // Medic Only Weapons
	{
		if (StrEqual(strModel, "models/weapons/c_models/c_medigun/c_medigun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 29, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_proto_medigun/c_proto_medigun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 411, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_syringegun/c_syringegun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 17, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/w_models/w_syringegun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 17, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_proto_syringegun/c_proto_syringegun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 412, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_crusaders_crossbow/c_crusaders_crossbow.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 305, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_leechgun/c_leechgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 36, iTarget)
		}
	}
	if (TF2_GetPlayerClass(client) == TFClass_Sniper) // Sniper Only Weapons
	{
		if (StrEqual(strModel, "models/weapons/w_models/w_sniperrifle.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 14, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/w_models/w_smg.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 16, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_dartgun.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 230, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_bazaar_sniper/c_bazaar_sniper.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 402, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_dex_sniperrifle/c_dex_sniperrifle.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 526, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/urinejar.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 58, iTarget)
		}
		else if (StrEqual(strModel, "models/weapons/c_models/c_bow/c_bow.mdl"))
		{
			OtakuGaming_GiveWeapon(client, 56, iTarget)
		}
	}
}

//STOCKS

stock OtakuGaming_GiveWeapon(client, ID, target)
{
	ClientCommand(client, "playgamesound ui/item_heavy_gun_pickup.wav");
	ClientCommand(client, "playgamesound ui/item_heavy_gun_drop.wav");
	TF2Items_GiveWeapon(client, ID)
	
	if(RemoveOnPick)
	{
		AcceptEntityInput(target, "Kill")
	}
	
	CanPick[client] = false;
	CreateTimer(CanPick_cooldown, CanPickupWeps, client)
}

public Action:CanPickupWeps(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		CanPick[client] = true;
	}
}

stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

stock GetEntityModel(iEntity, String:strModel[], iMaxSize, String:strPropName[] = "m_nModelIndex")
{
	//m_iWorldModelIndex
	new iIndex = GetEntProp(iEntity, Prop_Send, strPropName);
	GetModelPath(iIndex, strModel, iMaxSize);
}

stock GetModelPath(iIndex, String:strModel[], iMaxSize)
{
	new iTable = FindStringTable("modelprecache");
	ReadStringTable(iTable, iIndex, strModel, iMaxSize);
}

stock bool:mapIsSZF()
{
	decl String:mapname[6];
	GetCurrentMap(mapname, sizeof(mapname));
	return strncmp(mapname, "szf_", 3, false) == 0;
}

stock GetClientPointVisible(iClient) {
	decl Float:vOrigin[3], Float:vAngles[3], Float:vEndOrigin[3];
	GetClientEyePosition(iClient, vOrigin);
	GetClientEyeAngles(iClient, vAngles);
	
	new Handle:hTrace = INVALID_HANDLE;
	hTrace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_ALL, RayType_Infinite, TraceDontHitEntity, iClient);
	TR_GetEndPosition(vEndOrigin, hTrace);
	
	new iReturn = -1;
	new iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vOrigin, vEndOrigin) / 50.0 <= 2.0)
	{
		iReturn = iHit;
	}
	CloseHandle(hTrace);
	
	return iReturn;
}

stock bool:IsClassname(iEntity, String:strClassname[]) {
	if (iEntity <= 0) return false;
	if (!IsValidEdict(iEntity)) return false;
	
	decl String:strClassname2[32];
	GetEdictClassname(iEntity, strClassname2, sizeof(strClassname2));
	if (StrEqual(strClassname, strClassname2, false)) return true;
	return false;
}