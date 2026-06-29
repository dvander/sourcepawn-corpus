#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.1"
#define DEFAULT_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#undef REQUIRE_EXTENSIONS
#define WEAPON_LENGTH 19
#define DEBUG 0
new m_debug = 0;

static const	ASSAULT_RIFLE_OFFSET_IAMMO		= 12;
static const	SMG_OFFSET_IAMMO				= 20;
static const	PUMPSHOTGUN_OFFSET_IAMMO		= 28;
static const	AUTO_SHOTGUN_OFFSET_IAMMO		= 32;
static const	HUNTING_RIFLE_OFFSET_IAMMO		= 36;
static const	MILITARY_SNIPER_OFFSET_IAMMO	= 40;
static const	GRENADE_LAUNCHER_OFFSET_IAMMO	= 68;

new Handle:smgClip;
new Handle:smgSilencedClip;
new Handle:smgMp5Clip;
new Handle:pumpClip;
new Handle:chromeClip;
new Handle:huntClip;
new Handle:rifleClip;
new Handle:rifleAk47Clip;
new Handle:rifleDesertClip;
new Handle:rifleSg552Clip;
new Handle:militaryClip;
new Handle:awpClip;
new Handle:scoutClip;
new Handle:granedeClip;
new Handle:m60Clip;
new Handle:autoClip;
new Handle:spasClip;
new Handle:pistolClip;
new Handle:magnumClip;
//new CountTimer = 1;
new ValueLastClip[MAXPLAYERS+1];
new ValueLastAmmo[MAXPLAYERS+1];
new ValueNewClip[MAXPLAYERS+1];
new ClipOffset[MAXPLAYERS+1];
new Handle:TimerPlayerReload[MAXPLAYERS+1];
new weaponClipSize[WEAPON_LENGTH] = {};
/*
new nextPrimaryAttack = -1;
new nextAttack =  -1;
new timeIdle =  -1;
new reloadState =  -1;
*/

new const String:weaponsClass[WEAPON_LENGTH][] = {
	{"weapon_smg"}, {"weapon_smg_silenced"}, {"weapon_smg_mp5"}, {"weapon_pumpshotgun"}, {"weapon_shotgun_chrome"}, {"weapon_hunting_rifle"},
	{"weapon_rifle"}, {"weapon_rifle_ak47"}, {"weapon_rifle_desert"}, {"weapon_rifle_sg552"}, {"weapon_sniper_military"},
	{"weapon_sniper_scout"}, {"weapon_sniper_awp"}, {"weapon_grenade_launcher"}, {"weapon_rifle_m60"},
	{"weapon_autoshotgun"}, {"weapon_shotgun_spas"}, {"weapon_pistol"}, {"weapon_pistol_magnum"}
};

public Plugin:myinfo = 
{
	name = "L4D2 Realistic Reload",
	author = "ghosthunterfool",
	description = "Realistic Reloading",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1020236"
}

public OnPluginStart()
{
	// Requires Left 4 Dead 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	
	CreateConVar("l4d2_gun_version", PLUGIN_VERSION, " Version of L4D2 Gun Control on this server ", DEFAULT_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	smgClip = CreateConVar("l4d2_smg_clip", "32", "Max clip size", DEFAULT_FLAGS);
	smgSilencedClip = CreateConVar("l4d2_smg_silenced_clip", "30", "Max clip size", DEFAULT_FLAGS);
	smgMp5Clip = CreateConVar("l4d2_smg_mp5_clip", "30", "Max clip size", DEFAULT_FLAGS);
	pumpClip = CreateConVar("l4d2_pump_shotie_clip", "5", "Max clip size", DEFAULT_FLAGS);
	chromeClip = CreateConVar("l4d2_chrome_clip", "5", "Max clip size", DEFAULT_FLAGS);
	huntClip = CreateConVar("l4d2_hunting_clip", "10", "Max clip size", DEFAULT_FLAGS);
	rifleClip = CreateConVar("l4d2_rifle_clip", "30", "Max clip size", DEFAULT_FLAGS);
	rifleAk47Clip = CreateConVar("l4d2_ak47_clip", "30", "Max clip size", DEFAULT_FLAGS);
	rifleDesertClip = CreateConVar("l4d2_desert_clip", "30", "Max clip size", DEFAULT_FLAGS);
	rifleSg552Clip = CreateConVar("l4d2_sg552_clip", "30", "Max clip size", DEFAULT_FLAGS);
	militaryClip = CreateConVar("l4d2_military_clip", "20", "Max clip size", DEFAULT_FLAGS);
	awpClip = CreateConVar("l4d2_awp_clip", "10", "Max clip size", DEFAULT_FLAGS);
	scoutClip = CreateConVar("l4d2_scout_clip", "10", "Max clip size", DEFAULT_FLAGS);
	granedeClip = CreateConVar("l4d2_granede_clip", "1", "Max clip size", DEFAULT_FLAGS);
	m60Clip = CreateConVar("l4d2_m60_clip", "200", "Max clip size", DEFAULT_FLAGS);
	autoClip = CreateConVar("l4d2_autoshot_clip", "5", "Max clip size", DEFAULT_FLAGS);
	spasClip = CreateConVar("l4d2_spas_clip", "7", "Max clip size", DEFAULT_FLAGS);
	pistolClip = CreateConVar("l4d2_pistol_clip", "15", "Max clip size", DEFAULT_FLAGS);
	magnumClip = CreateConVar("l4d2_magnum_clip", "8", "Max clip size", DEFAULT_FLAGS);

	
	HookEvent("weapon_fire", Event_Weapon_Fired);
	HookEvent("item_pickup", Event_Weapon_Pickup);
	HookEvent("weapon_reload", Event_Weapon_Reload,  EventHookMode_Pre);
	HookEvent("ammo_pickup", Event_AmmoPickUp);
	
	AutoExecConfig(true, "l4d2_gun");
}

public OnMapStart()
{
	for(new i=1; i <= MaxClients; i++)
	{
		ValueLastClip[i] = 0;
		ValueLastAmmo[i] = 0;
		ValueNewClip[i] = 0;
		ClipOffset[i] = 0;
		TimerPlayerReload[i] = INVALID_HANDLE;
	}
}


public Action:Event_Weapon_Fired(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new h_mPrimary = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new h_mPrimary = GetPlayerWeaponSlot(client, 0);
	if(!IsValidEntity(h_mPrimary) || IsFakeClient(client)) return Plugin_Handled;
	
	new String:classname[256];
	GetEntityClassname(h_mPrimary, classname, sizeof(classname));
	if((StrContains(classname, "weapon_smg", false) != -1) ||
	(StrContains(classname, "weapon_smg_silenced", false) != -1) ||
	(StrContains(classname, "weapon_smg_mp5", false) != -1))
	{
		ClipOffset[client] = SMG_OFFSET_IAMMO;
		
	}
	else if((StrContains(classname, "weapon_pumpshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_chrome", false) != -1))
	{
		ClipOffset[client] = PUMPSHOTGUN_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_rifle", false) != -1) ||
	(StrContains(classname, "weapon_rifle_ak47", false) != -1) ||
	(StrContains(classname, "weapon_rifle_desert", false) != -1) ||
	(StrContains(classname, "weapon_rifle_sg552", false) != -1) 
	)
	{
		ClipOffset[client] = ASSAULT_RIFLE_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_autoshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_spas", false) != -1))
	{
		ClipOffset[client] = AUTO_SHOTGUN_OFFSET_IAMMO;
	}
	else if(StrContains(classname, "weapon_hunting_rifle", false) != -1)
	{
		ClipOffset[client] = HUNTING_RIFLE_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_sniper_military", false) != -1) ||
	(StrContains(classname, "weapon_sniper_scout", false) != -1) ||
	(StrContains(classname, "weapon_sniper_awp", false) != -1))
	{
		ClipOffset[client] = MILITARY_SNIPER_OFFSET_IAMMO;
	}
	else if(StrContains(classname, "weapon_grenade_launcher", false) != -1)
	{
		ClipOffset[client] = GRENADE_LAUNCHER_OFFSET_IAMMO;
	}
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
	ValueLastAmmo[client] = GetEntData(client, (iAmmoOffset + ClipOffset[client]));
	ValueLastClip[client] = GetEntProp(h_mPrimary, Prop_Data, "m_iClip1", 1);
	ValueLastClip[client] = ValueLastClip[client] - 1;

	if(m_debug == 1)
	{
		PrintToChatAll("Event Weapon Fired");
		PrintToChatAll("ValueLastAmmo: %d", ValueLastAmmo[client]);
		PrintToChatAll("ValueLastClip: %d", ValueLastClip[client]);
		PrintToChatAll("---------------------------");
	}
	return Plugin_Handled;
}

public Action:Event_AmmoPickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new h_mPrimary = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new h_mPrimary = GetPlayerWeaponSlot(client, 0);
	if(!IsValidEntity(h_mPrimary) || IsFakeClient(client)) return Plugin_Handled;
	
	new String:classname[256];
	GetEntityClassname(h_mPrimary, classname, sizeof(classname));
	if((StrContains(classname, "weapon_smg", false) != -1) ||
	(StrContains(classname, "weapon_smg_silenced", false) != -1) ||
	(StrContains(classname, "weapon_smg_mp5", false) != -1))
	{
		ClipOffset[client] = SMG_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_pumpshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_chrome", false) != -1))
	{
		ClipOffset[client] = PUMPSHOTGUN_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_rifle", false) != -1) ||
	(StrContains(classname, "weapon_rifle_ak47", false) != -1) ||
	(StrContains(classname, "weapon_rifle_desert", false) != -1) ||
	(StrContains(classname, "weapon_rifle_sg552", false) != -1)
	)
	{
		ClipOffset[client] = ASSAULT_RIFLE_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_autoshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_spas", false) != -1))
	{
		ClipOffset[client] = AUTO_SHOTGUN_OFFSET_IAMMO;
	}
	else if(StrContains(classname, "weapon_hunting_rifle", false) != -1)
	{
		ClipOffset[client] = HUNTING_RIFLE_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_sniper_military", false) != -1) ||
	(StrContains(classname, "weapon_sniper_scout", false) != -1) ||
	(StrContains(classname, "weapon_sniper_awp", false) != -1))
	{
		ClipOffset[client] = MILITARY_SNIPER_OFFSET_IAMMO;
	}
	else if(StrContains(classname, "weapon_grenade_launcher", false) != -1)
	{
		ClipOffset[client] = GRENADE_LAUNCHER_OFFSET_IAMMO;
	}
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
	ValueLastAmmo[client] = GetEntData(client, (iAmmoOffset + ClipOffset[client]));

	if(m_debug == 1) PrintToChatAll("Event Ammo Pickup");
	return Plugin_Handled;
}

public Action:Event_Weapon_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new h_mPrimary = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new h_mPrimary = GetPlayerWeaponSlot(client, 0);
	if(!IsValidEntity(h_mPrimary) || IsFakeClient(client)) return Plugin_Handled;
	
	new String:classname[256];
	GetEntityClassname(h_mPrimary, classname, sizeof(classname));
	if((StrContains(classname, "weapon_smg", false) != -1) ||
	(StrContains(classname, "weapon_smg_silenced", false) != -1) ||
	(StrContains(classname, "weapon_smg_mp5", false) != -1))
	{
		ClipOffset[client] = SMG_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_pumpshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_chrome", false) != -1))
	{
		ClipOffset[client] = PUMPSHOTGUN_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_rifle", false) != -1) ||
	(StrContains(classname, "weapon_rifle_ak47", false) != -1) ||
	(StrContains(classname, "weapon_rifle_desert", false) != -1) ||
	(StrContains(classname, "weapon_rifle_sg552", false) != -1) 
	)
	{
		ClipOffset[client] = ASSAULT_RIFLE_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_autoshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_spas", false) != -1))
	{
		ClipOffset[client] = AUTO_SHOTGUN_OFFSET_IAMMO;
	}
	else if(StrContains(classname, "weapon_hunting_rifle", false) != -1)
	{
		ClipOffset[client] = HUNTING_RIFLE_OFFSET_IAMMO;
	}
	else if((StrContains(classname, "weapon_sniper_military", false) != -1) ||
	(StrContains(classname, "weapon_sniper_scout", false) != -1) ||
	(StrContains(classname, "weapon_sniper_awp", false) != -1))
	{
		ClipOffset[client] = MILITARY_SNIPER_OFFSET_IAMMO;
	}
	else if(StrContains(classname, "weapon_grenade_launcher", false) != -1)
	{
		ClipOffset[client] = GRENADE_LAUNCHER_OFFSET_IAMMO;
	}
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
	ValueLastAmmo[client] = GetEntData(client, (iAmmoOffset + ClipOffset[client]));
	ValueLastClip[client] = GetEntProp(h_mPrimary, Prop_Data, "m_iClip1", 1);

	if(m_debug == 1)
	{
		PrintToChatAll("Event weapon pickup");
		PrintToChatAll("ValueLastAmmo: %d", ValueLastAmmo[client]);
		PrintToChatAll("ValueLastClip: %d", ValueLastClip[client]);
		PrintToChatAll("---------------------------");
	}
	return Plugin_Handled;
}

public Action:Event_Weapon_Reload(Handle:event, const String:name[], bool:dontBroadcast)
{
	updateConVar();
	
	new String:classname[256];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new ActiveWeapon = GetPlayerWeaponSlot(client, 0);
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");

	GetEntityClassname(ActiveWeapon, classname, sizeof(classname));
	for(new i=0; i < sizeof(weaponsClass); i++)
	{
		if((StrContains(classname, weaponsClass[i], false) != -1))
		{
			ValueNewClip[client] = weaponClipSize[i];
			if(m_debug == 1)
			{
				PrintToChatAll( "---------------------------");
				PrintToChatAll("what weapon we reloading");
				PrintToChatAll("clipSet: %s", weaponsClass[i]);
				PrintToChatAll("clipSet: %d", weaponClipSize[i]);
				PrintToChatAll("---------------------------");
			}
		}
	}

	
	// what is our clip offset
	if((StrContains(classname, "weapon_smg", false) != -1) ||
	(StrContains(classname, "weapon_smg_silenced", false) != -1) ||
	(StrContains(classname, "weapon_smg_mp5", false) != -1))
	{
		ClipOffset[client] = SMG_OFFSET_IAMMO;	
	}
	else if((StrContains(classname, "weapon_pumpshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_chrome", false) != -1))
	{
		ClipOffset[client] = PUMPSHOTGUN_OFFSET_IAMMO;
		
	}
	else if((StrContains(classname, "weapon_rifle", false) != -1) ||
	(StrContains(classname, "weapon_rifle_ak47", false) != -1) ||
	(StrContains(classname, "weapon_rifle_desert", false) != -1) ||
	(StrContains(classname, "weapon_rifle_sg552", false) != -1)
	)
	{
		ClipOffset[client] = ASSAULT_RIFLE_OFFSET_IAMMO;
		
	}
	else if((StrContains(classname, "weapon_autoshotgun", false) != -1) ||
	(StrContains(classname, "weapon_shotgun_spas", false) != -1))
	{
		ClipOffset[client] = AUTO_SHOTGUN_OFFSET_IAMMO;
	}
	else if(StrContains(classname, "weapon_hunting_rifle", false) != -1)
	{
		ClipOffset[client] = HUNTING_RIFLE_OFFSET_IAMMO;
		
	}
	else if((StrContains(classname, "weapon_sniper_military", false) != -1) ||
	(StrContains(classname, "weapon_sniper_scout", false) != -1) ||
	(StrContains(classname, "weapon_sniper_awp", false) != -1))
	{
		ClipOffset[client] = MILITARY_SNIPER_OFFSET_IAMMO;
		
	}
	else if(StrContains(classname, "weapon_grenade_launcher", false) != -1)
	{
		ClipOffset[client] = GRENADE_LAUNCHER_OFFSET_IAMMO;
	}

	// we have zero stock ammo but we just pick from the ammo pile
	if(ValueLastAmmo[client] <= 0) ValueLastAmmo[client] = GetEntData(client, (iAmmoOffset + ClipOffset[client]));
	
	
	if((ValueLastClip[client] < ValueNewClip[client]))
	{
		TimerPlayerReload[client] = CreateTimer(0.1, Timer_InsertClip, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}
public Action:Timer_InsertClip(Handle:timer, any:client)
{
	new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	//new ActiveWeapon = GetPlayerWeaponSlot(client, 0);
	
	if((GetEntProp(ActiveWeapon, Prop_Data, "m_bInReload") == 0))
	{
		KillTimer(TimerPlayerReload[client]);

		new clipSet = ValueNewClip[client];
		
		// total clip to subtract from our total stock ammo
		new clip =  (clipSet - ValueLastClip[client]);
		
		new clip2 = (ValueLastAmmo[client] + ValueLastClip[client]);
		
		// incase we run low on stock ammo
		//
		
		// balance of our ammo
		new ammo = (ValueLastAmmo[client] - clip);
		
		// not sure why i need this but i still put him here xD
		if(ammo <= 0) ammo = 0;
		
		
		
		if(m_debug == 1)
		{
			PrintToChatAll("clipSet: %i", clipSet);
			PrintToChatAll("clip: %i", clip);
			PrintToChatAll("clip2: %i", clip2);
			PrintToChatAll("ammo: %i", ammo);
		}
		//if(ValueLastClip[client]>=1 && ActiveWeapon == GetPlayerWeaponSlot(client, 1)){
		//	SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", clipSet+1);
		//}
		if(ValueLastClip[client]>=1 && (ClipOffset[client] == SMG_OFFSET_IAMMO || ClipOffset[client] == ASSAULT_RIFLE_OFFSET_IAMMO
		|| ClipOffset[client] == HUNTING_RIFLE_OFFSET_IAMMO || ClipOffset[client] == MILITARY_SNIPER_OFFSET_IAMMO))
		{
			if(clip2 < clipSet) clipSet = clip2;
			new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
			//SetEntData(client, (iAmmoOffset + ClipOffset[client]), ammo);
			//SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", clipSet);
			SetEntData(client, (iAmmoOffset + ClipOffset[client]), ammo-1);
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", clipSet+1);
		}
		if(m_debug == 1)
		{
			PrintToChatAll("ValueLastClip[client]: %d", ValueLastClip[client]);
			//PrintToChatAll("Count stoped at: %i", CountTimer);
		}
		
		
		return;
	}


}


updateConVar()
{
	weaponClipSize[0] = GetConVarInt(smgClip);
	weaponClipSize[1] = GetConVarInt(smgSilencedClip);
	weaponClipSize[2] = GetConVarInt(smgMp5Clip);
	weaponClipSize[3] = GetConVarInt(pumpClip);
	weaponClipSize[4] = GetConVarInt(chromeClip);
	weaponClipSize[5] = GetConVarInt(huntClip);
	weaponClipSize[6] = GetConVarInt(rifleClip);
	weaponClipSize[7] = GetConVarInt(rifleAk47Clip);
	weaponClipSize[8] = GetConVarInt(rifleDesertClip);
	weaponClipSize[9] = GetConVarInt(rifleSg552Clip);
	weaponClipSize[10] = GetConVarInt(militaryClip);
	weaponClipSize[11] = GetConVarInt(scoutClip);
	weaponClipSize[12] = GetConVarInt(awpClip);
	weaponClipSize[13] = GetConVarInt(granedeClip);
	weaponClipSize[14] = GetConVarInt(m60Clip);
	weaponClipSize[15] = GetConVarInt(autoClip);
	weaponClipSize[16] = GetConVarInt(spasClip);
	weaponClipSize[17] = GetConVarInt(magnumClip);
	weaponClipSize[18] = GetConVarInt(pistolClip);
}

