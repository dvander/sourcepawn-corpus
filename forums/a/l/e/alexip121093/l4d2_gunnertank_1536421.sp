#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
new g_GameInstructor[MAXPLAYERS+1];
new bool:bdelay[MAXPLAYERS+1];
new Handle:cvar_hp = INVALID_HANDLE;
new Handle:cvar_m60 = INVALID_HANDLE;
new Handle:cvar_reload = INVALID_HANDLE;
new Handle:cvar_displayammo = INVALID_HANDLE;
new Handle:cvar_damage = INVALID_HANDLE;
new Handle:cvar_allow = INVALID_HANDLE;
static const	ASSAULT_RIFLE_OFFSET_IAMMO		= 12;
static const	SMG_OFFSET_IAMMO				= 20;
static const	PUMPSHOTGUN_OFFSET_IAMMO		= 28;
static const	AUTO_SHOTGUN_OFFSET_IAMMO		= 32;
static const	HUNTING_RIFLE_OFFSET_IAMMO		= 36;
static const	MILITARY_SNIPER_OFFSET_IAMMO	= 40;
static const	GRENADE_LAUNCHER_OFFSET_IAMMO	= 64;
new bool:dp[MAXPLAYERS + 1];
// Plugin info
public Plugin:myinfo =
{
	name = "Gunner Tank",
	author = "hihi1210",
	description = "Allows Tank to use guns",
	version = "1.0.2",
	url = "https://forums.alliedmods.net/showthread.php?t=165129"
};

// Plugin start
public OnPluginStart()
{
	decl String:s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2"))
	{
		SetFailState("L4D2 Gunner Tank will only work with Left 4 Dead 2!");
	}
	HookEvent("bot_player_replace", Event_PlayerReplaceBot);
	HookEvent("player_spawn", reset);
	//HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	CreateConVar("l4d2_gunnertank_version","1.0.2","L4D2 Gunner Tank plugin version.",	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_allow = CreateConVar("l4d2_gunnertank_allow",	"1","0= L4D2 Gunner Tank Plugin off, 1=Plugin on. 2 root admin only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_hp = CreateConVar("l4d2_gunnertank_hp", "800", "After picking up any guns,tank's health will drop to this amount. (0=unchange)",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_m60 = CreateConVar("l4d2_gunnertank_m60", "0", "0 = disallow M60   1 = allow M60", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_reload = CreateConVar("l4d2_gunnertank_reload", "3", "0 = disallow reloading ammo   1 = allow reloading ammo by picking up weapon_xxxx guns , 2=allow reloading ammo by picking up weapon_spawn guns. 3= both", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_displayammo = CreateConVar("l4d2_gunnertank_displayammo", "1", "0 = No   1 = Yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_damage = CreateConVar("l4d2_gunnertank_damage_multiplier", "0.18", "weapon damage modifier (1.0 = full damage)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d2_gunnertank");
}
public reset (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bdelay[client] = false;
	dp[client] = false;
	if (client ==0 || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client) || GetZombieClass(client) !=8) return;
	if (GetClientTeam(client) == 3)
	{
		if (GetZombieClass(client) == 8)
		{
			QueryClientConVar(client, "gameinstructor_enable", ConVarQueryFinished:GameInstructor, client);
			ClientCommand(client, "gameinstructor_enable 1");
			CreateTimer(2.0, DisplayInstructorHint, client);
		}
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnClientPostAdminCheck(client)
{
	bdelay[client] =false;
	dp[client] = false;
}
GetZombieClass(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		return GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	return -1;
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (GetConVarInt(cvar_allow) ==1 || GetConVarInt(cvar_allow) ==2 && CheckCommandAccess(client,  "", ADMFLAG_ROOT, true))
	{
		// Is client human, ingame, infected, alive, not a ghost and pressing the button?
		if (client == 0) return Plugin_Continue;
		if (!IsClientInGame(client)) return Plugin_Continue;
		if (IsFakeClient(client)) return Plugin_Continue;
		if (GetClientTeam(client) != 3) return Plugin_Continue;
		if (!IsPlayerAlive(client)) return Plugin_Continue;
		if (GetEntProp(client, Prop_Send, "m_isGhost") != 0) return Plugin_Continue;
		// Get Zombieclass
		new zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		// This class enabled?
		if (zombieClass != 8) return Plugin_Continue;
		// Get detonation button
		if (buttons & IN_USE)
		{
			if (bdelay[client]) return Plugin_Continue;
			new gun = GetClientAimTarget(client, false); 
			if (gun==-1)
			{
				new Meds = GetPlayerWeaponSlot(client, 0);
				decl String:ent_name[64];
				GetEdictClassname(Meds, ent_name, sizeof(ent_name));
				if (!StrEqual(ent_name, "weapon_tank_claw"))
				{
					new claw = CreateEntityByName("weapon_tank_claw");
					DispatchSpawn(claw);
					if (IsValidEntity(claw))
					{
						EquipPlayerWeapon(client, claw);
						bdelay[client] = true;
						CreateTimer(1.0, ResetDelay, client);
						dp[client] =false;
					}
				}
				return Plugin_Continue;
			}
			else
			{
				if (!IsValidEdict(gun)) return Plugin_Continue;
				decl String:ent_name[64];
				GetEdictClassname(gun, ent_name, sizeof(ent_name)); 
				if ((StrContains(ent_name, "weapon_rifle", false) != -1 || StrContains(ent_name, "weapon_smg", false) != -1 || StrContains(ent_name, "weapon_sniper", false) != -1|| StrContains(ent_name, "weapon_hunting_rifle", false) != -1|| StrContains(ent_name, "weapon_grenade_launcher", false) != -1|| StrContains(ent_name, "shotgun", false) != -1) &&  StrContains(ent_name, "spawn", false)== -1)
				{
					if (GetConVarInt(cvar_m60) ==0)
					{
						if(StrContains(ent_name, "weapon_rifle_m60", false)!= -1) return Plugin_Continue;
					}
					decl Float:VecOrigin[3], Float:VecAngles[3];
					GetClientAbsOrigin(client, VecOrigin);
					GetEntPropVector(gun, Prop_Data, "m_vecOrigin", VecAngles);
					if (GetVectorDistance(VecOrigin, VecAngles) < 80)
					{
						new Meds = GetPlayerWeaponSlot(client, 0);
						if (StrContains(ent_name, "weapon_rifle_m60", false)== -1)
						{
							new foundgunammo = GetEntProp(gun, Prop_Send, "m_iExtraPrimaryAmmo", 4);
							new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
							new offsettoadd;
							if (StrEqual(ent_name, "weapon_rifle", false) || StrEqual(ent_name, "weapon_rifle_ak47", false) || StrEqual(ent_name, "weapon_rifle_desert", false) || StrEqual(ent_name, "weapon_rifle_sg552", false))
							{ //case: Assault rifles
								offsettoadd = ASSAULT_RIFLE_OFFSET_IAMMO; //gun type specific offset
							}
							else if (StrEqual(ent_name, "weapon_smg", false) || StrEqual(ent_name, "weapon_smg_silenced", false) || StrEqual(ent_name, "weapon_smg_mp5", false))
							{ //case: SMGS
								offsettoadd = SMG_OFFSET_IAMMO; //gun type specific offset
							}		
							else if (StrEqual(ent_name, "weapon_pumpshotgun", false) || StrEqual(ent_name, "weapon_shotgun_chrome", false))
							{ //case: Pump Shotguns
								offsettoadd = PUMPSHOTGUN_OFFSET_IAMMO; //gun type specific offset
							}
							else if (StrEqual(ent_name, "weapon_autoshotgun", false) || StrEqual(ent_name, "weapon_shotgun_spas", false))
							{ //case: Auto Shotguns
								offsettoadd = AUTO_SHOTGUN_OFFSET_IAMMO; //gun type specific offset
							}
							else if (StrEqual(ent_name, "weapon_hunting_rifle", false))
							{ //case: Hunting Rifle
								offsettoadd = HUNTING_RIFLE_OFFSET_IAMMO; //gun type specific offset
							}
							else if (StrEqual(ent_name, "weapon_sniper_military", false) || StrEqual(ent_name, "weapon_sniper_awp", false) || StrEqual(ent_name, "weapon_sniper_scout", false))
							{ //case: Military Sniper Rifle or CSS Snipers
								offsettoadd = MILITARY_SNIPER_OFFSET_IAMMO; //gun type specific offset
							}
							else if (StrEqual(ent_name, "weapon_grenade_launcher", false))
							{ //case: no gun this plugin recognizes
								offsettoadd = GRENADE_LAUNCHER_OFFSET_IAMMO;	
							}
							else
							{
								return Plugin_Continue;
							}
							RemovePlayerItem(client, Meds);
							EquipPlayerWeapon(client, gun);
							if (GetConVarInt(cvar_reload) ==1 || GetConVarInt(cvar_reload) ==3)
							{
								SetEntData(client, (iAmmoOffset + offsettoadd), foundgunammo, 4, true);
							}
						}
						else
						{
							RemovePlayerItem(client, Meds);
							EquipPlayerWeapon(client, gun);
						}
						bdelay[client] = true;
						CreateTimer(1.0, ResetDelay, client);
						if (dp[client] == false)
						{
							if (GetPlayerWeaponSlot(client, 0) > 0)
							{
								dp[client] = true;
								if (GetConVarInt(cvar_displayammo)!=0)
								{
									CreateTimer(0.1, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
						if (GetConVarInt(cvar_hp) !=0)
						{
							if (GetClientHealth(client) > GetConVarInt(cvar_hp)) 
								{
									SetEntityHealth( client, GetConVarInt(cvar_hp));
								}
						}
					}
				}
				else if (StrContains(ent_name, "weapon", false)!= -1 && StrContains(ent_name, "spawn", false)!= -1) 
				{
					decl Float:VecOrigin[3], Float:VecAngles[3];
					GetClientAbsOrigin(client, VecOrigin);
					GetEntPropVector(gun, Prop_Data, "m_vecOrigin", VecAngles);
					if (GetVectorDistance(VecOrigin, VecAngles) < 80)
					{
						decl String:modelname[128];
						GetEntPropString(gun, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
						new entity;
						if (StrEqual(modelname, "models/w_models/weapons/w_autoshot_m4super.mdl"))
						{
							entity = CreateEntityByName("weapon_autoshotgun");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_desert_rifle.mdl"))
						{
							entity = CreateEntityByName("weapon_rifle_desert");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_grenade_launcher.mdl"))
						{
							entity = CreateEntityByName("weapon_grenade_launcher");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_pumpshotgun_A.mdl"))
						{
							entity = CreateEntityByName("weapon_shotgun_chrome");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_rifle_ak47.mdl"))
						{
							entity = CreateEntityByName("weapon_rifle_ak47");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_rifle_b.mdl"))
						{
							entity = CreateEntityByName("weapon_rifle");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_rifle_m16a2.mdl"))
						{
							entity = CreateEntityByName("weapon_rifle");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_shotgun.mdl"))
						{
							entity = CreateEntityByName("weapon_pumpshotgun");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_shotgun_spas.mdl"))
						{
							entity = CreateEntityByName("weapon_shotgun_spas");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_smg_uzi.mdl"))
						{
							entity = CreateEntityByName("weapon_smg");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_smg_a.mdl"))
						{
							entity = CreateEntityByName("weapon_smg_silenced");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_sniper_military.mdl"))
						{
							entity = CreateEntityByName("weapon_sniper_military");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_sniper_mini14.mdl"))
						{
							entity = CreateEntityByName("weapon_hunting_rifle");
						}
						else if (StrEqual(modelname, "models/w_models/weapons/w_m60.mdl"))
						{
							if (GetConVarInt(cvar_m60) !=0)
							{
								entity = CreateEntityByName("weapon_rifle_m60");
							}
							else
							{
								return Plugin_Continue;
							}
						}
						else
						{
							return Plugin_Continue;
						}
						DispatchSpawn(entity);
						new Meds = GetPlayerWeaponSlot(client, 0);
						if (IsValidEntity(entity))
						{
							RemovePlayerItem(client, Meds);
							EquipPlayerWeapon(client, entity);
							bdelay[client] = true;
							CreateTimer(1.0, ResetDelay, client);
							if (dp[client] == false)
							{
								if (GetPlayerWeaponSlot(client, 0) > 0)
								{
									dp[client] = true;
									if (GetConVarInt(cvar_displayammo)!=0)
									{
										CreateTimer(0.1, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
									}
								}
							}
							if (GetConVarInt(cvar_reload) ==2 || GetConVarInt(cvar_reload) ==3)
							{
								new String:command[] = "give";
								StripAndExecuteClientCommand(client, command, "ammo","","");
							}
							if (GetConVarInt(cvar_hp) !=0)
							{
								if (GetClientHealth(client) > GetConVarInt(cvar_hp)) 
								{
									SetEntityHealth( client, GetConVarInt(cvar_hp));
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:ResetDelay(Handle:timer,any:client)
{
	bdelay[client] = false;
}
public Action:Event_PlayerReplaceBot(Handle:event, const String:name[], bool:dontBroadcast){
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	
	if (GetClientTeam(player) == 3)
	{
		if (GetZombieClass(player) == 8)
		{
			QueryClientConVar(player, "gameinstructor_enable", ConVarQueryFinished:GameInstructor, player);
			ClientCommand(player, "gameinstructor_enable 1");
			CreateTimer(2.0, DisplayInstructorHint, player);
		}
	}
	return Plugin_Continue;
}
public Action:DisplayInstructorHint(Handle:h_Timer, any:i_Client)
{
	if (GetConVarInt(cvar_allow) ==1 || GetConVarInt(cvar_allow) ==2&& CheckCommandAccess(i_Client,  "", ADMFLAG_ROOT, true))
	{
		decl i_Ent, String:s_TargetName[32], String:s_Message[256], Handle:h_Pack;

		i_Ent = CreateEntityByName("env_instructor_hint");
		FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client);
		if (GetConVarInt(cvar_hp) !=0)
		{
			FormatEx(s_Message, sizeof(s_Message), "Aim the guns and press E to equip. And you can drop it by pressing E. But your health will drop to %d", GetConVarInt(cvar_hp));
		}
		else
		{
			FormatEx(s_Message, sizeof(s_Message), "Aim the guns and press E to equip. And you can drop it by pressing E");
		}
		PrintHintText(i_Client,s_Message);
		ReplaceString(s_Message, sizeof(s_Message), "\n", " ");
		DispatchKeyValue(i_Client, "targetname", s_TargetName);
		DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
		DispatchKeyValue(i_Ent, "hint_timeout", "5");
		DispatchKeyValue(i_Ent, "hint_range", "0.01");
		DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");
		DispatchKeyValue(i_Ent, "hint_caption", s_Message);
		DispatchKeyValue(i_Ent, "hint_color", "255 255 255");
		DispatchKeyValue(i_Ent, "hint_binding", "+use");
		DispatchSpawn(i_Ent);
		AcceptEntityInput(i_Ent, "ShowHint");
		
		h_Pack = CreateDataPack();
		WritePackCell(h_Pack, i_Client);
		WritePackCell(h_Pack, i_Ent);
		CreateTimer(5.0, RemoveInstructorHint, h_Pack);
	}
}


public GameInstructor(QueryCookie:q_Cookie, i_Client, ConVarQueryResult:c_Result, const String:s_CvarName[], const String:s_CvarValue[])
{
	g_GameInstructor[i_Client] = StringToInt(s_CvarValue);
}

public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client;
	
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	
	if (IsValidEntity(i_Ent))
	RemoveEdict(i_Ent);
	
	if (!g_GameInstructor[i_Client])
	ClientCommand(i_Client, "gameinstructor_enable 0");
}
IsValidClient(client)
{
	if (client == 0)
	return false;
	
	if (!IsValidEntity(client)) return false;
	
	if (!IsClientConnected(client))
	return false;
	
	if (!IsClientInGame(client))
	return false;
	
	if (IsFakeClient(client))
	return false;
	
	if (!IsPlayerAlive(client))
	return false;
	return true;
}
StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[])
{
	LogAction(0, -1, "DEBUG:stripandexecuteclientcommand");
	if(client == 0) return;
	if(!IsClientInGame(client)) return;
	if(IsFakeClient(client)) return;
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3);
	SetCommandFlags(command, flags);
}

public Action:PAd(Handle:Timer, any:client)
{
	if (client ==0 || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client) || GetZombieClass(client) !=8)
	{
		dp[client] = false;
		return;
	}
	if (GetPlayerWeaponSlot(client, 0) > 0)
	{
		new String:ent_name[32];
		GetEdictClassname(GetPlayerWeaponSlot(client, 0), ent_name, 32);
		//new ammo;
		new clip;
		new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo"); //get the iAmmo Offset
		decl offsettoadd;
		
		if (StrEqual(ent_name, "weapon_rifle", false) || StrEqual(ent_name, "weapon_rifle_ak47", false) || StrEqual(ent_name, "weapon_rifle_desert", false) || StrEqual(ent_name, "weapon_rifle_sg552", false))
		{ //case: Assault rifles
			offsettoadd = ASSAULT_RIFLE_OFFSET_IAMMO; //gun type specific offset
		}
		else if (StrEqual(ent_name, "weapon_smg", false) || StrEqual(ent_name, "weapon_smg_silenced", false) || StrEqual(ent_name, "weapon_smg_mp5", false))
		{ //case: SMGS
			offsettoadd = SMG_OFFSET_IAMMO; //gun type specific offset
		}		
		else if (StrEqual(ent_name, "weapon_pumpshotgun", false) || StrEqual(ent_name, "weapon_shotgun_chrome", false))
		{ //case: Pump Shotguns
			offsettoadd = PUMPSHOTGUN_OFFSET_IAMMO; //gun type specific offset
		}
		else if (StrEqual(ent_name, "weapon_autoshotgun", false) || StrEqual(ent_name, "weapon_shotgun_spas", false))
		{ //case: Auto Shotguns
			offsettoadd = AUTO_SHOTGUN_OFFSET_IAMMO; //gun type specific offset
		}
		else if (StrEqual(ent_name, "weapon_hunting_rifle", false))
		{ //case: Hunting Rifle
			offsettoadd = HUNTING_RIFLE_OFFSET_IAMMO; //gun type specific offset
		}
		else if (StrEqual(ent_name, "weapon_sniper_military", false) || StrEqual(ent_name, "weapon_sniper_awp", false) || StrEqual(ent_name, "weapon_sniper_scout", false))
		{ //case: Military Sniper Rifle or CSS Snipers
			offsettoadd = MILITARY_SNIPER_OFFSET_IAMMO; //gun type specific offset
		}
		else if (StrEqual(ent_name, "weapon_grenade_launcher", false))
		{ //case: no gun this plugin recognizes
			offsettoadd = GRENADE_LAUNCHER_OFFSET_IAMMO;	
		}
		else
		{
		}
		
		new currentammo = GetEntData(client, (iAmmoOffset + offsettoadd)); //get targets current ammo
		clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
		//ammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo");
		if (StrContains(ent_name, "weapon_rifle_m60", false)!= -1)
		{
			PrintHintText(client,"Primary Ammo : %d", clip);
		}
		else if(StrContains(ent_name, "weapon_tank_claw", false)!= -1)
		{
			PrintHintText(client,"Tank Claw");
		}
		else
		{
			PrintHintText(client,"Primary Ammo : %d / %d", clip , currentammo);
		}
		if(dp[client])
		{
			CreateTimer(0.5, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		else
		{
			dp[client] = false;
			return;
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (victim <=0 || attacker<=0 ||attacker > 32 || victim > 32) return Plugin_Continue;
	if (!IsClientConnected(victim) || !IsClientInGame(victim) || !IsClientConnected(attacker)|| !IsClientInGame(attacker) ) return Plugin_Continue;
	if (GetClientTeam(victim) != 2) return Plugin_Continue;
	if (attacker <= 0) return Plugin_Continue;
	if (GetClientTeam(attacker) != 3) return Plugin_Continue;
	if (GetZombieClass(attacker) != 8)return Plugin_Continue;
	decl String:ent_name[64];
	if (attacker == inflictor) // case: attack with an equipped weapon (guns, claws)
	{
		GetClientWeapon(inflictor, ent_name, sizeof(ent_name));
		
		//new weapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
		//GetEdictClassname(weapon, "ent_name", sizeof(ent_name));
	}
	else
	{
		GetEdictClassname(inflictor, ent_name, sizeof(ent_name)); // tank special case?
	}
	if ((StrContains(ent_name, "weapon_rifle", false) != -1 || StrContains(ent_name, "weapon_smg", false) != -1 || StrContains(ent_name, "weapon_sniper", false) != -1|| StrContains(ent_name, "weapon_hunting_rifle", false) != -1|| StrContains(ent_name, "weapon_grenade_launcher", false) != -1|| StrContains(ent_name, "shotgun", false) != -1))
	{
		damage = RoundToFloor(damage*GetConVarFloat(cvar_damage))*1.0;
		PrintToChat(attacker,"inflictor: %s,damage: %f",ent_name, damage);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

