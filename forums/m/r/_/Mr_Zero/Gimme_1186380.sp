#include <sourcemod>
#include <sdktools>

static 	const	String:	ITEM_STEAL_ABLE[][] =
{
	"weapon_oxygentank",
	"weapon_gascan",
	"weapon_propanetank",
	"weapon_fireworkcrate",
	"weapon_gnome",
	"weapon_cola_bottles"
}

static 	const	String:	ITEM_NAMES[][] =
{
	"Oxygen tank",
	"Gascan",
	"Propane tank",
	"Firework crate",
	"Gnome",
	"Cola bottles"
}

static	const	String:	NETCLASS_TERRORPLAYER[]	= "CTerrorPlayer";
static	const	String:	PROP_ACTIVE_WEAPON[]	= "m_hActiveWeapon";
static	const			TEAM_SURVIVOR			= 2;
static	const			MAX_WEAPON_SLOTS		= 5;

static					g_iActiveWeapon_Offset	= 0;

public Plugin:myinfo = 
{
	name = "Gimme!",
	author = "Mr. Zero",
	description = "Gives a shoving survivor another survivors useable item currently holding.",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=126952"
}

public OnPluginStart()
{
	g_iActiveWeapon_Offset = FindSendPropInfo(NETCLASS_TERRORPLAYER, PROP_ACTIVE_WEAPON);
	if (g_iActiveWeapon_Offset < 1)
	{
		ThrowError("Failed to find active weapon prop info!"); // Couldn't find prop info, end plugin
	}
	
	HookEvent("player_shoved", PlayerShoved_Event);
}

public PlayerShoved_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(victim) != TEAM_SURVIVOR) return; // If victim isn't survivor, return
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (GetClientTeam(attacker) != TEAM_SURVIVOR) return; // If attack isn't survivor, return
	
	new ent = GetEntDataEnt2(victim, g_iActiveWeapon_Offset);
	if (!IsValidEdict(ent)) return; // Not a valid edict, return
	
	decl String:clsname[128];
	GetEdictClassname(ent, clsname, sizeof(clsname));
	
	new bool:isStealable, itemname;
	for (new i = 0; i < sizeof(ITEM_STEAL_ABLE); i++)
	{
		if (!StrEqual(clsname, ITEM_STEAL_ABLE[i])) continue;
		isStealable = true; // Found a stealable item
		itemname = i;
		break;
	}
	if (!isStealable) return; // This item can't be stolen, return
	
	new victimweapon;
	for (new i = 0; i < MAX_WEAPON_SLOTS; i++)
	{
		victimweapon = GetPlayerWeaponSlot(victim, i);
		if (victimweapon == -1) continue;
		SetEntDataEnt2(victim, g_iActiveWeapon_Offset, victimweapon, true);
		break;
	}
	
	new Handle:pack = CreateDataPack();
	ResetPack(pack);
	WritePackCell(pack, attacker);
	WritePackCell(pack, ent);
	WritePackCell(pack, victim);
	WritePackCell(pack, victimweapon);
	WritePackCell(pack, itemname);
	
	CreateTimer(0.1, GivePlayerWeapon_Timer, pack, TIMER_REPEAT);
}

public Action:GivePlayerWeapon_Timer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new attacker = ReadPackCell(pack)
	new ent = ReadPackCell(pack);
	new victim = ReadPackCell(pack);
	new victimweapon = ReadPackCell(pack);
	new itemname = ReadPackCell(pack);
	
	if (!IsValidEntity(ent)) return Plugin_Continue;
	
	EquipPlayerWeapon(attacker, ent);
	EquipPlayerWeapon(victim, victimweapon);
	
	CloseHandle(pack);
	
	PrintHintText(attacker, "You stole a %s from %N!", ITEM_NAMES[itemname], victim);
	PrintHintText(victim, "You were robed of your %s by %N!", ITEM_NAMES[itemname], attacker);
	
	return Plugin_Stop;
}
