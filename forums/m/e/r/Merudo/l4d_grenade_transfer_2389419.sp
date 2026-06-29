/*

	Created by DJ_WEST
	
	Web: http://amx-x.ru
	AMX Mod X and SourceMod Russian Community
	
	Modified by Guillaume. Can now take back grenades from bots, or prevent bots from being gifted them
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "1.0"

#define TEAM_SURVIVOR 2
#define SOUND_BIGREWARD "UI/BigReward.wav"
#define SOUND_LITTLEREWARD "UI/LittleReward.wav"

#define TEAM_SURVIVORS 2

new g_ActiveWeaponOffset

new Handle:PassNadeBot		= INVALID_HANDLE;
new Handle:TakeNadeBot		= INVALID_HANDLE;


new const String:g_Weapons[3][] =
{
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar"
}

// Weapons that won't take nade from bot when shoving
new const String:g_Weapons2[16][] =
{
	"weapon_adrenaline",
	"weapon_defibrillator",
	"weapon_first_aid_kit",
	"weapon_pain_pills",
	"weapon_ammo_spawn",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_fireworkcrate",
	"weapon_gascan",
	"weapon_oxygentank",
	"weapon_propanetank",
	"weapon_gnome",
	"weapon_cola_bottles"
}

public Plugin:myinfo = 
{
	name = "Grenade Transfer",
	author = "DJ_WEST",
	description = "Transfer a pipebomb/molotov/vomitjar to your teammates",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
}

public OnPluginStart()
{
	decl String:s_Game[12], Handle:h_Version
	
	GetGameFolderName(s_Game, sizeof(s_Game))
	if (!StrEqual(s_Game, "left4dead") && !StrEqual(s_Game, "left4dead2"))
		SetFailState("Grenade Transfer supports Left 4 Dead and Left 4 Dead 2 only!")
		
	h_Version = CreateConVar("grenade_transfer_version", PLUGIN_VERSION, "Grenade Transfer version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
	
	HookEvent("player_shoved", EventPlayerShoved)
	
	SetConVarString(h_Version, PLUGIN_VERSION)
	
	PassNadeBot = CreateConVar("l4d_pass_grenade_bot","1","Can players pass grenades to bots. 0:Disable, 1:Enable", 4,true,0.00,true,1.00);
	TakeNadeBot = CreateConVar("l4d_take_grenade_bot","1","Can players take grenades from bots by shoving. 0:Disable, 1:Enable", 4,true,0.00,true,1.00);	
}

public OnMapStart()
{
	if (!IsSoundPrecached(SOUND_BIGREWARD))
		PrecacheSound(SOUND_BIGREWARD, true)
		
	if (!IsSoundPrecached(SOUND_LITTLEREWARD))
		PrecacheSound(SOUND_LITTLEREWARD, true)
}

public Action:EventPlayerShoved(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Victim, i_Attacker
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Victim = GetClientOfUserId(i_UserID)
	i_UserID = GetEventInt(h_Event, "attacker")
	i_Attacker = GetClientOfUserId(i_UserID)
	
	/// The weapon used to shove with 
	decl i_Weapon	
	decl String:s_Weapon[32]
	
	// The grenades of the attacker and victim 
	decl i_Attacker_Grenade, i_Victim_Grenade, i
	decl String:s_Victim_Grenade[32]
	
	// If infected, don't do anything
	if (GetClientTeam(i_Victim) != TEAM_SURVIVOR)
	{
		return Plugin_Continue
	}
		
	// Get weapon used to shove the victim
	i_Weapon = GetEntDataEnt2(i_Attacker, g_ActiveWeaponOffset)	
	GetClientWeapon(i_Attacker, s_Weapon, sizeof(s_Weapon))
	
	// Get Attacker & Victim Grenade
	i_Attacker_Grenade = GetPlayerWeaponSlot(i_Attacker, 2)	
	i_Victim_Grenade   = GetPlayerWeaponSlot(i_Victim, 2)
	

	for (i = 0; i < sizeof(g_Weapons); i++)
	{
		if (StrEqual(s_Weapon, g_Weapons[i]))
		{
			if (IsValidEntity(i_Weapon) && IsValidEdict(i_Weapon) && i_Victim_Grenade == -1)
			{
				// If client is bot and can't give nade to bot, stop
				if (TOIsClientInGameBot(i_Victim) && GetConVarInt(PassNadeBot)==0)
				{
					return Plugin_Continue
				}
				
				RemoveEdict(i_Weapon)
				PlaySound(i_Attacker, SOUND_BIGREWARD)
				GiveGrenade(i_Victim, s_Weapon)
				PlaySound(i_Victim, SOUND_LITTLEREWARD)
			
				return Plugin_Continue
			}
		}
	}
	
	// If can't take nade from bot, stop
	if (GetConVarInt(TakeNadeBot)==0 || i_Victim_Grenade == -1 || i_Attacker_Grenade != -1 || !TOIsClientInGameBot(i_Victim) )
	{
		return Plugin_Continue
	}
	
	// If holding weapon that can't take nade from bot, stop
	for (i = 0; i < sizeof(g_Weapons2); i++)
	{
		if (StrEqual(s_Weapon, g_Weapons2[i]))
		{
			return Plugin_Continue
		}
	}
	
	// If valid object, take it from bot
	if (IsValidEntity(i_Victim_Grenade) && IsValidEdict(i_Victim_Grenade))
	{
		GetEdictClassname(i_Victim_Grenade, s_Victim_Grenade, sizeof(s_Victim_Grenade));	
		RemoveEdict(i_Victim_Grenade);
		PlaySound(i_Attacker, SOUND_BIGREWARD);
		GiveGrenade(i_Attacker, s_Victim_Grenade);	
	}
	
	return Plugin_Continue
}

public PlaySound(i_Client, const String:s_Sound[32])
	EmitSoundToClient(i_Client, s_Sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0)
	
public GiveGrenade(i_Client, String:s_Class[32])
{
	decl i_Ent
			
	i_Ent = CreateEntityByName(s_Class)
	DispatchSpawn(i_Ent)
	EquipPlayerWeapon(i_Client, i_Ent)
}	



stock bool:TOIsClientInGameBot(client, team=TEAM_SURVIVORS)
{
	if (client > 0) return IsClientConnected(client) && IsFakeClient(client) && GetClientTeam(client) == team;
	else return false;
}




