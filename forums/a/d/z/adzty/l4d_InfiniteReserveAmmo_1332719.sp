/*
* Changelog
* 
*  [L4D1/2] Infinite Reserve Ammo
* 
* This Plugin makes it so you have to reload but never run out of ammo.
* 
* 0.1 This is my very first plugin so go easy on me. :)
* 0.4 Intial Release
* 0.5 - 0.7 Fixed Up some Code, and added more Guns
* 0.8 Added Support for the M60 rifle and, removed all the health stuff.
* 0.9 Removed Health Items -its just the guns and throwables can be infinite now:)
* 1.0 Fixed the m60 dropping when empty,
* thanks to: http://forums.alliedmods.net/showpost.php?p=1162810&postcount=106
* 
* * * For some strange reason the l4d2 throwables doesnt seem to work. I'm not sure why though, 
* everything else worked fine when I tested them.
* 
* Credit to the original L4D infinite reserve ammo plugin by "(-DR-)Grammernatzi."
* His plugin was giving me trouble on L4D2, so I decided to make it this.
* 
*/
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define M60_CLASS "weapon_rifle_m60"

//GUNS
new Handle:g_hEnable	= INVALID_HANDLE;
new Handle:autoshotguns = INVALID_HANDLE;
new Handle:pumpshotguns	= INVALID_HANDLE;
new Handle:smgs			= INVALID_HANDLE;
new Handle:hrifle		= INVALID_HANDLE;
new Handle:rifle		= INVALID_HANDLE;
new Handle:sniperrifle	= INVALID_HANDLE;
new Handle:noobtube		= INVALID_HANDLE;
new Handle:m60rifle		= INVALID_HANDLE;
new Handle:minigun		= INVALID_HANDLE;
new Handle:chainsaw		= INVALID_HANDLE;
//THROWABLES
new Handle:pipes		= INVALID_HANDLE;
new Handle:molly		= INVALID_HANDLE;
new Handle:bile			= INVALID_HANDLE;
new MOD;
//Special thanks to "birno" and "DJ_WEST" for the m60 droping when empty code...
new g_ActiveWeaponOffset;

public Plugin:myinfo =
{
	name = "[L4D1/2] Infinite Reserve Ammo",
	author = "adzty",
	description = "[L4D1/2] Infinite Reserve Ammo",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=141426",
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
		SetFailState("L4D1/2 Infinite Reserve Ammo supports only Left 4 Dead 1 or 2 :D");
	if (StrEqual(game_name, "left4dead", false))
		MOD = 1; else if (StrEqual(game_name, "left4dead2", false)) MOD = 2;
	
	//PLUGIN CVARS
	CreateConVar("l4d2_ira_version", PLUGIN_VERSION, "Plugin's Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnable = CreateConVar("l4d2_ira_enable", "1", "Turns the plugin on/off.(works with l4d1 as well)", FCVAR_PLUGIN,true,0.0, true, 1.0);
	HookConVarChange(g_hEnable, CvarOff);
	
	//GUNS
	autoshotguns = CreateConVar("IRA_autoshotguns_enable", "1", "Infinite Reserve for AutoShotguns", FCVAR_PLUGIN);
	pumpshotguns = CreateConVar("IRA_pumpshotguns_enable", "1", "Infinite Reserve for PumpShotguns", FCVAR_PLUGIN);
	smgs 		 = CreateConVar("IRA_smgs_enable", "1", "Infinite Reserve for SMGS", FCVAR_PLUGIN);
	hrifle 		 = CreateConVar("IRA_huntingrifle_enable", "1", "Infinite Reserve for the Hunting Rifle", FCVAR_PLUGIN);
	rifle 		 = CreateConVar("IRA_rifles_enable", "1", "Infinite Reserve for Assault Rifles(m4/ak47)", FCVAR_PLUGIN);
	noobtube 	 = CreateConVar("IRA_noobtube_enable", "1", "Infinite Reserve for The Grenade Launcher -L4D2 only", FCVAR_PLUGIN);
	m60rifle  	 = CreateConVar("IRA_m60_enable","1", "Infinite Reserve for the M60? -L4D2 only", FCVAR_PLUGIN);
	sniperrifle  = CreateConVar("IRA_sniperrifle_enable", "1", "Infinite Reserve for Snipers -L4D2 only", FCVAR_PLUGIN);
	minigun 	 = CreateConVar("IRA_minigun_enable", "1", "Infinite Ammo for the Machine Gun/Minigun", FCVAR_PLUGIN);
	chainsaw 	 = CreateConVar("IRA_chainsaw_enable", "0", "Unlimited Chainsaw? -L4D2 only", FCVAR_PLUGIN);
	//THROWABLES
	pipes 		 = CreateConVar("IRA_pipes_enable", "0", "Infinite Reserve for Pipe Bombs", FCVAR_PLUGIN);
	molly 		 = CreateConVar("IRA_molotovs_enable", "0", "Infinite Reserve for Molotovs", FCVAR_PLUGIN);
	bile 		 = CreateConVar("IRA_bilebomb_enable", "0", "Infinite Reserve for Bile Bomb -L4D2 Only", FCVAR_PLUGIN);
	
	HookEvent("weapon_fire",Event_WeaponFire);
	if(MOD==2)
		g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	
	AutoExecConfig(true, "l4d_infinite_reserve_ammo", "sourcemod");
}
public OnAllPluginsLoaded()
{
	//Enable for Left 4 Dead 2
	if (GetConVarInt(g_hEnable)==1 && MOD==2)
	{
		if (GetConVarBool(rifle))
			SetConVarInt(FindConVar("ammo_assaultrifle_max"), -2);
		else
			ResetConVar(FindConVar("ammo_assaultrifle_max"), true, true);
		//---------------
		if (GetConVarBool(smgs))
			SetConVarInt(FindConVar("ammo_smg_max"), -2);
		else
			ResetConVar(FindConVar("ammo_smg_max"), true, true);
		//---------------
		if (GetConVarBool(autoshotguns))
			SetConVarInt(FindConVar("ammo_autoshotgun_max"), -2);
		else
			ResetConVar(FindConVar("ammo_autoshotgun_max"), true, true);
		//---------------
		if (GetConVarBool(hrifle))
			SetConVarInt(FindConVar("ammo_huntingrifle_max"), -2);
		else
			ResetConVar(FindConVar("ammo_huntingrifle_max"), true, true);
		//---------------
		if (GetConVarBool(sniperrifle))
			SetConVarInt(FindConVar("ammo_sniperrifle_max"), -2);
		else
			ResetConVar(FindConVar("ammo_sniperrifle_max"), true, true);
		//---------------
		if (GetConVarBool(noobtube))
			SetConVarInt(FindConVar("ammo_grenadelauncher_max"), -2);
		else
			ResetConVar(FindConVar("ammo_grenadelauncher_max"), true, true);
		//---------------
		if (GetConVarBool(m60rifle))
			SetConVarInt(FindConVar("ammo_m60_max"), -2);
		else
			ResetConVar(FindConVar("ammo_m60_max"), true, true);
		//---------------
		if (GetConVarBool(pumpshotguns))
			SetConVarInt(FindConVar("ammo_shotgun_max"), -2);
		else
			ResetConVar(FindConVar("ammo_shotgun_max"), true, true);
		//---------------
		
		if(GetConVarInt(pipes)>0)
			SetConVarInt(FindConVar("ammo_pipebomb_max"), -2);
		else
			SetConVarInt(FindConVar("ammo_pipebomb_max"), -1);
		//---------------
		if(GetConVarInt(molly)>0)
			SetConVarInt(FindConVar("ammo_molotov_max"), -2);
		else
			SetConVarInt(FindConVar("ammo_molotov_max"), 1);
		//---------------
		if(GetConVarInt(bile)>0)
			SetConVarInt(FindConVar("ammo_vomitjar_max"), -2);
		else
			SetConVarInt(FindConVar("ammo_vomitjar_max"), 1);
		//---------------
		if (GetConVarBool(minigun))
		{
			//For Both the l4d1 Minigun and Mounted Machine Gun. There are few more cvars here..
			//-but I'm lasy besides it not really that important :D
			SetConVarFloat(FindConVar("z_minigun_cooldown_time"), 0.1);
			SetConVarInt(FindConVar("mounted_gun_cooldown_time"), 1);
			SetConVarInt(FindConVar("mounted_gun_overheat_penalty_time"), 1);
			SetConVarInt(FindConVar("ammo_minigun_max"), 9999);
		}
	}
	else if(GetConVarInt(g_hEnable)==0 && MOD==2)
	{
		ResetConVar(FindConVar("ammo_assaultrifle_max"), true, true);
		ResetConVar(FindConVar("ammo_smg_max"), true, true);
		ResetConVar(FindConVar("ammo_autoshotgun_max"), true, true);
		ResetConVar(FindConVar("ammo_huntingrifle_max"), true, true);
		ResetConVar(FindConVar("ammo_sniperrifle_max"), true, true);
		ResetConVar(FindConVar("ammo_grenadelauncher_max"), true, true);
		ResetConVar(FindConVar("ammo_m60_max"), true, true);
		ResetConVar(FindConVar("ammo_shotgun_max"), true, true);
		//THROWABLES
		SetConVarInt(FindConVar("ammo_pipebomb_max"), 1);
		SetConVarInt(FindConVar("ammo_molotov_max"), 1);
		SetConVarInt(FindConVar("ammo_vomitjar_max"), 1);
		//Miniguns
		ResetConVar(FindConVar("z_minigun_cooldown_time"), true, true);
		ResetConVar(FindConVar("mounted_gun_cooldown_time"), true, true);
		ResetConVar(FindConVar("mounted_gun_overheat_penalty_time"), true, true);
		ResetConVar(FindConVar("ammo_minigun_max"), true, true);
	}
	//Enable for L4D1
	if(GetConVarInt(g_hEnable)==1 && MOD==1)
	{
		SetConVarInt(FindConVar("ammo_assaultrifle_max"), -2);
		SetConVarInt(FindConVar("ammo_smg_max"), -2);
		SetConVarInt(FindConVar("ammo_huntingrifle_max"), -2);
		SetConVarInt(FindConVar("ammo_buckshot_max"), -2);
		if (GetConVarBool(rifle))
			SetConVarInt(FindConVar("ammo_assaultrifle_max"), -2);
		else
			ResetConVar(FindConVar("ammo_assaultrifle_max"), true, true);
		
		if (GetConVarBool(smgs))
			SetConVarInt(FindConVar("ammo_smg_max"), -2);
		else
			ResetConVar(FindConVar("ammo_smg_max"), true, true);
		
		if (GetConVarBool(hrifle))
			SetConVarInt(FindConVar("ammo_huntingrifle_max"), -2);
		else
		ResetConVar(FindConVar("ammo_huntingrifle_max"), true, true);
		
		if (GetConVarBool(pumpshotguns) || GetConVarBool(autoshotguns))
			SetConVarInt(FindConVar("ammo_buckshot_max"), -2);
		else
			ResetConVar(FindConVar("ammo_buckshot_max"), true, true);
	}
	else if(GetConVarInt(g_hEnable)==0 && MOD==1)
	{
		ResetConVar(FindConVar("ammo_assaultrifle_max"), true, true);
		ResetConVar(FindConVar("ammo_smg_max"), true, true);
		ResetConVar(FindConVar("ammo_huntingrifle_max"), true, true);
		ResetConVar(FindConVar("ammo_buckshot_max"), true, true);
	}
}
RemoveFlags()
{
	new FLAG = GetCommandFlags("give");
	SetCommandFlags("give",FLAG & ~FCVAR_CHEAT);
}
AddFlags()
{
	new FLAG = GetCommandFlags("give");
	SetCommandFlags("give", FLAG|FCVAR_CHEAT);
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (GetConVarInt(g_hEnable)==1)
	{
		if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			//only for l4d1
			new slot = -1;
			new clipsize;
			if(StrEqual(weapon, "pipe_bomb") && GetConVarBool(pipes) && MOD==1)
			{
				AddFlags();
				FakeClientCommand(client, "give", "pipe_bomb");
				RemoveFlags();
			}
			if(StrEqual(weapon, "molotov") && GetConVarBool(molly) && MOD==1)
			{
				AddFlags(); 
				FakeClientCommand(client, "give", "molotov");
				RemoveFlags();
			}
			if(StrEqual(weapon, "chainsaw") && GetConVarBool(chainsaw) && MOD==2)
			{
				slot = 1;
				clipsize = 30;
				if (slot==1)
					SetEntProp(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_iClip1", clipsize+1);
			}
		}
	}
}

public Action:OnPlayerRunCmd(i_Client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{
	if(GetConVarInt(g_hEnable)==1 && GetConVarBool(m60rifle))
	{
		if (i_Buttons & IN_ATTACK)
		{
			decl String:s_Weapon[32]; //i_Skin;
			i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset);
			
			if (IsValidEntity(i_Weapon))
			{
				GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
				//i_Skin = GetEntProp(i_Weapon, Prop_Send, "m_nSkin");
			}
			
			if (StrEqual(s_Weapon, M60_CLASS))
			{
				decl i_Clip;
				i_Clip = GetEntProp(i_Weapon, Prop_Data, "m_iClip1");
				
				if (i_Clip <= 1)
				{
					decl i_Ent;
					i_Ent = CreateEntityByName(M60_CLASS);
					EquipPlayerWeapon(i_Client, i_Ent);
					PrintHintText(i_Client, "You can pick your m60 back up and reload it.");
				}
			}
		}
	}
}

// If the enable convar is turned off in game --this should work for the most part
public CvarOff(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hEnable)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		if (newval == oldval)
			return;
		if (newval < 0 || newval > 1)
		{
			SetConVarInt(g_hEnable, oldval);
		}
		else if (newval==0 && MOD==2)
		{
			ResetConVar(FindConVar("ammo_assaultrifle_max"), true, true);
			ResetConVar(FindConVar("ammo_smg_max"), true, true);
			ResetConVar(FindConVar("ammo_autoshotgun_max"), true, true);
			ResetConVar(FindConVar("ammo_huntingrifle_max"), true, true);
			ResetConVar(FindConVar("ammo_sniperrifle_max"), true, true);
			ResetConVar(FindConVar("ammo_grenadelauncher_max"), true, true);
			ResetConVar(FindConVar("ammo_m60_max"), true, true);
			ResetConVar(FindConVar("ammo_shotgun_max"), true, true);
			//Miniguns
			ResetConVar(FindConVar("z_minigun_cooldown_time"),true, true);
			ResetConVar(FindConVar("mounted_gun_cooldown_time"), true, true);
			ResetConVar(FindConVar("mounted_gun_overheat_penalty_time"), true, true);
			ResetConVar(FindConVar("ammo_minigun_max"), true, true);
			SetConVarInt(FindConVar("ammo_pipebomb_max"), 1);
			SetConVarInt(FindConVar("ammo_molotov_max"), 1);
			SetConVarInt(FindConVar("ammo_vomitjar_max"), 1);
		}
		//l4d1
		else if(newval==0 && MOD==1)
		{
			ResetConVar(FindConVar("ammo_assaultrifle_max"), true, true);
			ResetConVar(FindConVar("ammo_smg_max"), true, true);
			ResetConVar(FindConVar("ammo_huntingrifle_max"), true, true);
			ResetConVar(FindConVar("ammo_buckshot_max"), true, true);
		}
	}
}
