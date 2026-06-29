/*

	Created by DJ_WEST
	
	Web: http://amx-x.ru
	AMX Mod X and SourceMod Russian Community
	
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "1.0"

#define TEAM_SURVIVOR 2
#define SOUND_BIGREWARD "UI/BigReward.wav"
#define SOUND_LITTLEREWARD "UI/LittleReward.wav"

new g_ActiveWeaponOffset

new const String:g_Weapons[3][] =
{
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar"
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
	
	if (GetClientTeam(i_Victim) != TEAM_SURVIVOR)
		return Plugin_Continue
		
	decl String:s_Weapon[32], i
	
	GetClientWeapon(i_Attacker, s_Weapon, sizeof(s_Weapon))
	
	for (i = 0; i < sizeof(g_Weapons); i++)
		if (StrEqual(s_Weapon, g_Weapons[i]))
		{
			decl i_Weapon
			
			i_Weapon = GetEntDataEnt2(i_Attacker, g_ActiveWeaponOffset)
			
			if (IsValidEntity(i_Weapon) && IsValidEdict(i_Weapon) && GetPlayerWeaponSlot(i_Victim, 2) == -1)
			{
				RemoveEdict(i_Weapon)
				PlaySound(i_Attacker, SOUND_BIGREWARD)
				GiveGrenade(i_Victim, s_Weapon)
				PlaySound(i_Victim, SOUND_LITTLEREWARD)
			
				break
			}
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
