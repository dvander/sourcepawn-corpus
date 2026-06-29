#include <sourcemod>
#include <sdktools>

//////////////////////////////  Point to your desired mp3/wav file here!  ///////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
#define HEADSHOT_SOUND "player/headshot1.wav"
//////////////////////////////  Point to your desired mp3/wav file here!  ///////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
	name = "DoD HitInfo", 
	author = "FeuerSturm, playboycyberclub", 
	description = "Displays some info after being killed", 
	version = "1.1", 
	url = "http://www.dodsplugins.net"
}

new Handle:HitInfoStatus = INVALID_HANDLE
new Handle:HitInfoDistUnit = INVALID_HANDLE
new Handle:HitInfoDispHeadshot = INVALID_HANDLE
new Handle:HitInfoSoundHeadshot = INVALID_HANDLE

new String:HitGroupName[8][] = 
{
	"Body", "Head", "Chest", "Stomach", "right Arm", "left Arm", "right Leg", "left Leg"
}

public OnPluginStart()
{
	new String:HeadshotSound[256]
	Format(HeadshotSound, sizeof(HeadshotSound), "sound/%s", HEADSHOT_SOUND)
	AddFileToDownloadsTable(HeadshotSound)
	HitInfoStatus = CreateConVar("dod_hitinfo_status", "1", "<1/0> = enable/disable HitInfo messages")
	HitInfoDistUnit = CreateConVar("dod_hitinfo_distunit", "1", "<1/2> = unit to display distances  -  1 = feet  -  2 = meters")
	HitInfoDispHeadshot = CreateConVar("dod_hitinfo_headshotannounce", "1", "<1/0> = enable/disable Headshot Announcements")
	HitInfoSoundHeadshot = CreateConVar("dod_hitinfo_headshotsound", "0", "<1/0> = enable/disable Headshot Sound")
	HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post)
}

public OnMapStart()
{
	PrecacheSound(HEADSHOT_SOUND)
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(HitInfoStatus) == 0)
	{
		return Plugin_Continue
	}
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	decl String:Weapon[32]
	GetEventString(event, "weapon", Weapon, sizeof(Weapon))
	new VictimHealth = GetEventInt(event, "health")
	new Damage = GetEventInt(event, "damage")
	new Hitgroup = GetEventInt(event, "hitgroup")
	if (attacker == victim || victim < 1 || attacker < 1 || Hitgroup > 7 || VictimHealth > 0 || GetClientTeam(attacker) == GetClientTeam(victim))
	{
		return Plugin_Continue
	}
	new Float:KillerOrigin[3]
	new Float:VictimOrigin[3]
	GetClientAbsOrigin(attacker, KillerOrigin)
	GetClientAbsOrigin(victim, VictimOrigin)
	new Distance = RoundToNearest(GetVectorDistance(KillerOrigin, VictimOrigin)) / (GetConVarInt(HitInfoDistUnit) == 1 ? 12 : 39)
	new KillerHealth = GetClientHealth(attacker)
	decl String:HitInfo[256]
	Format(HitInfo, sizeof(HitInfo), "\x01[HitInfo] \x04Killer: \x01%N | \x04Weapon: \x01%s | \x04Health: \x01%ihp", attacker, Weapon, KillerHealth)
	PrintToChat(victim, HitInfo)
	Format(HitInfo, sizeof(HitInfo), "\x01[HitInfo] \x04Hit: \x01%s | \x04Damage: \x01%i | \x04Distance: \x01%i%s", HitGroupName[Hitgroup], Damage, Distance, GetConVarInt(HitInfoDistUnit) == 1 ? "ft" : "m")
	PrintToChat(victim, HitInfo)
	if (Hitgroup == 1 && GetConVarInt(HitInfoDispHeadshot) == 1)
	{
		PrintToChatAll("\x01[HitInfo] \x04%N \x01killed \x04%N \x01by \x04Headshot \x01from \x04%i%s!", attacker, victim, Distance, GetConVarInt(HitInfoDistUnit) == 1 ? "ft" : "m")
		if (GetConVarInt(HitInfoSoundHeadshot) == 1)
		{
			EmitSoundToAll(HEADSHOT_SOUND)
		}
	}
	return Plugin_Continue
} 