/*
________________________________________________________

Varying Gun Ammunition	for Left 4 Dead 2				
Version 1.1.0

This plugin randomly changes the amount of bullets that are in guns that you pick up. This will not change anything involving
the guns that players are holding, unless they pick up a new gun the ammo they currently have will remain the same.
________________________________________________________

ChangeLog

Version 1.0.0 - First release
Version 1.1.0 - Fixed Shotgun Variation
Version 1.2.0 - CVARs description added
Version 1.4.0 - Added game check
Version 1.5.0 - Added support for Gun Control plugin
Version 1.5.1 - Added total Gun Control support
Version 1.5.2 - Added pistol support
Version 1.5.3 - Removed pistol support and timer cvar
________________________________________________________

Planned Future Updates: 

*/

//Doing initial Plugin "Stuff"
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5.3"

public Plugin:myinfo =
{
	name = "[L4D2] Varying Gun Ammunition",
	author = "modified by TimeShift",
	description = "Periodically changes the amount of ammo contained in picked up guns",
	version = PLUGIN_VERSION,
	url = ""
};

//Cvar Handles
new String:M60
new Handle:smgammo
new Handle:shotgunammo
new Handle:rifleammo
new Handle:huntingrifleammo
new Handle:autoshotammo
new Handle:glammo
new Handle:sniperammo
new Handle:gcm60
new Handle:gcsmg
new Handle:gcshotgun
new Handle:gcautoshotgun
new Handle:gcsniper
new Handle:gchuntingrifle
new Handle:gcgl
new Handle:gcassault

// added for constistency with above, theres simpler ways to do this
new Handle:smgammo_min
new Handle:pumpshotammo_min
new Handle:autoshotammo_min
new Handle:m16ammo_min
new Handle:huntingrifleammo_min
new Handle:glammo_min
new Handle:sniperammo_min
new Handle:m60ammo_min

new Handle:m60ammo_max
new Handle:smgammo_max
new Handle:pumpshotammo_max
new Handle:autoshotammo_max
new Handle:m16ammo_max
new Handle:huntingrifleammo_max
new Handle:glammo_max
new Handle:sniperammo_max


//Create the timer that decides how often to change the gun cvars, edit the number to change the interval, it is 90 at the moment
public OnPluginStart()
{
		// Requires Left 4 Dead 2
		decl String:game_name[64]
		GetGameFolderName(game_name, sizeof(game_name))
		if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.")
		// Hook item pickup event to variate M60 ammo
		HookEvent("item_pickup", Event_Item_Pickup)
		// Create version cvar (so sexy)
		CreateConVar("l4d_varyingammo_version", PLUGIN_VERSION, "L4D2 Varying Ammo Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
		// Find ammo cvars and create timer
		huntingrifleammo = FindConVar("ammo_huntingrifle_max")
		rifleammo = FindConVar("ammo_assaultrifle_max")
		autoshotammo = FindConVar("ammo_autoshotgun_max")
		shotgunammo = FindConVar("ammo_shotgun_max")
		smgammo = FindConVar("ammo_smg_max")
		glammo = FindConVar("ammo_grenadelauncher_max")
		sniperammo = FindConVar("ammo_sniperrifle_max")
		gcm60 = FindConVar("l4d2_guncontrol_m60ammo")
		gcgl = FindConVar("l4d2_guncontrol_grenadelauncherammo")
		gchuntingrifle = FindConVar("l4d2_guncontrol_huntingrifleammo")
		gcautoshotgun = FindConVar("l4d2_guncontrol_autoshotgunammo")
		gcshotgun = FindConVar("l4d2_guncontrol_shotgunammo")
		gcsniper = FindConVar("l4d2_guncontrol_sniperrifleammo")
		gcassault = FindConVar("l4d2_guncontrol_assaultammo")
	
		// min ammo (created own convar to avoid conflicts)
		huntingrifleammo_min = CreateConVar("l4d_huntingrifleammo_min", "90", "Min Hunting Rifle ammo variation", FCVAR_NOTIFY)
		m16ammo_min = CreateConVar("l4d_rifleammo_min", "180", "Min Rifles ammo variation (M16, Ak-47, Desert and SG552)", FCVAR_NOTIFY)
		pumpshotammo_min = CreateConVar("l4d_shotgunammo_min", "32", "Min Shotguns ammo variation (Pump and Chrome)", FCVAR_NOTIFY)
		autoshotammo_min = CreateConVar("l4d_autoshotammo_min", "30", "Min AutoShotgun ammo variation", FCVAR_NOTIFY)
		smgammo_min = CreateConVar("l4d_smgammo_min", "300", "Min SMGs ammo variation (Silenced, MP5 and Normal SMG)", FCVAR_NOTIFY)
		sniperammo_min = CreateConVar("l4d_sniperammo_min", "70", "Min Snipers ammo variation (AWP, Scout, Military)", FCVAR_NOTIFY)
		glammo_min = CreateConVar("l4d_glammo_min", "15", "Min Grenade Launcher ammo variation", FCVAR_NOTIFY)
		m60ammo_min = CreateConVar("l4d_m60ammo_min", "50", "Min M60 ammo variation", FCVAR_NOTIFY)

        // max ammo (created own convar to avoid conflicts)
		huntingrifleammo_max = CreateConVar("l4d_huntingrifleammo_max", "150", "Max Hunting Rifle ammo variation", FCVAR_NOTIFY)
		pumpshotammo_max = CreateConVar("l4d_shotgunammo_max", "56", "Max Shotgun ammo variation (Pump and Chrome)", FCVAR_NOTIFY)
		m16ammo_max = CreateConVar("l4d_rifleammo_max", "360", "Max Rifles ammo variation (M16, Ak-47, Desert and SG552 [CSS])", FCVAR_NOTIFY)
		autoshotammo_max = CreateConVar("l4d_autoshotammo_max", "90", "Max AutoShotgun ammo variation", FCVAR_NOTIFY)
		smgammo_max = CreateConVar("l4d_smgammo_max", "650", "Max SMGs ammo variation (Silenced, MP5 and Normal SMG)", FCVAR_NOTIFY)
		sniperammo_max = CreateConVar("l4d_sniperammo_max", "180", "Max Snipers ammo variation (AWP, Scout, Military)", FCVAR_NOTIFY)
		glammo_max = CreateConVar("l4d_glammo_max", "30", "Max Grenade Launcher ammo variation", FCVAR_NOTIFY)
		m60ammo_max = CreateConVar("l4d_m60ammo_max", "150", "Max M60 ammo variation", FCVAR_NOTIFY)
		CreateTimer(60.0, GunTimer, _, TIMER_REPEAT)
		AutoExecConfig(true, "l4d2_varyingammo", "sourcemod")
		
}

//Now to actually get the random number in between the 2 minimum and maximum values, every time the timer reaches it's interval
public Action:GunTimer(Handle:timer)
{	
	static NumPrinted = 0
	if (NumPrinted++ <= 2)
	{
			M60 = GetRandomInt(GetConVarInt(m60ammo_min), GetConVarInt(m60ammo_max))
			new PumpShotgun = GetRandomInt(GetConVarInt(pumpshotammo_min), GetConVarInt(pumpshotammo_max))
			new M16 = GetRandomInt(GetConVarInt(m16ammo_min), GetConVarInt(m16ammo_max))
			new Smg = GetRandomInt(GetConVarInt(smgammo_min), GetConVarInt(smgammo_max))
			new Huntingrifle = GetRandomInt(GetConVarInt(huntingrifleammo_min), GetConVarInt(huntingrifleammo_max))
			new SniperRifle = GetRandomInt(GetConVarInt(sniperammo_min), GetConVarInt(sniperammo_max))
			new GrenadeLauncher = GetRandomInt(GetConVarInt(glammo_min), GetConVarInt(glammo_max))
			new AutoShot = GetRandomInt(GetConVarInt(autoshotammo_min), GetConVarInt(autoshotammo_max))
			
//Now to set the ammo cvars to the new randomized values, which was just done above
			SetConVarInt(shotgunammo, PumpShotgun)
			SetConVarInt(rifleammo, M16)
			SetConVarInt(huntingrifleammo, Huntingrifle)
			SetConVarInt(smgammo, Smg)
			SetConVarInt(sniperammo, SniperRifle)
			SetConVarInt(glammo, GrenadeLauncher)
			SetConVarInt(autoshotammo, AutoShot)
			if (gcgl != INVALID_HANDLE)
			{
				SetConVarInt(gcgl, GrenadeLauncher)
				SetConVarInt(gcassault, M16)
				SetConVarInt(gcautoshotgun, AutoShot)
				SetConVarInt(gchuntingrifle, Huntingrifle)
				SetConVarInt(gcshotgun, PumpShotgun)
				SetConVarInt(gcsmg, Smg)
				SetConVarInt(gcsniper, SniperRifle)
				SetConVarInt(gcm60, M60)
			}
			NumPrinted = 0
	}
	return Plugin_Continue
}

public Action:Event_Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (!client || !IsClientInGame(client)) return
	
	decl String:itemname[128]
	GetEventString(event, "item", itemname, sizeof(itemname))
	//PrintToChat(client, "You picked up: %s", itemname)
	if (!StrEqual(itemname, "rifle_m60", false)) return
	
	new targetgun = GetPlayerWeaponSlot(client, 0)
	if (!IsValidEdict(targetgun)) return
	SetEntProp(targetgun, Prop_Data, "m_iClip1", M60, 1)
}

//Done!
