#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.2"
new melee[4096];
new Handle:cvar_ammolower = INVALID_HANDLE;
new Handle:cvar_ammoupper = INVALID_HANDLE;
new Handle:cvar_notice = INVALID_HANDLE;
new Handle:cvar_pistol = INVALID_HANDLE;
new g_ActiveWeaponOffset
public Plugin:myinfo = 
{
	name = "L4D2 Melee  Mod",
	author = "hihi1210",
	description = "Melee weapons will breaks",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	decl String:s_Game[12];
	
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2"))
	{
		SetFailState("L4D2 Melee  Mod will only work with Left 4 Dead 2!");
	}
	CreateConVar("sm_l4d2meleemod_version", PLUGIN_VERSION, "L4D2 Melee  Mod version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	HookEvent("item_pickup", Event_ItemPickup);
	cvar_ammolower = CreateConVar("sm_l4d2meleemod_ammo_lower", "150", "After How many times of attack, the melee weapons breaks (lower limit)");
	cvar_ammoupper = CreateConVar("sm_l4d2meleemod_ammo_upper", "250", "After How many times of attack, the melee weapons breaks (upper limit)");
	cvar_notice = CreateConVar("sm_l4d2meleemod_notice", "1", "Show After how many attacks the melee weapon breaks");
	cvar_pistol = CreateConVar("sm_l4d2meleemod_pistol", "0", "after the melee weapon breaks , which secondary weapon will give out .(0: single pistol 1:double pistol 2:magnum 3:chainsaw");
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
}
public OnMapStart()
{
	new max_entities = GetMaxEntities();

	for (new i = 0; i < max_entities; i++)
	{
		melee[i]= 0;
	}
}	
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip)
}
public Action:Event_WeaponFire(Handle:event, const String:ename[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (GetClientTeam(client) !=2) return;
	if (IsFakeClient(client)) return;
	if (IsPlayerIncapped(client)) return;
	new i_Weapon = GetEntDataEnt2(client, g_ActiveWeaponOffset)
	decl String:s_Weapon[32]
	if (IsValidEntity(i_Weapon))
	{
		GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon))
		if (StrContains(s_Weapon, "weapon_melee", false) >= 0)
		{
			if (melee[i_Weapon] > 0)
			{
				melee[i_Weapon]--;
				if (GetConVarInt(cvar_notice) == 1)
				{
					PrintHintText(client,"Melee Weapon strength: %d",melee[i_Weapon]);
				}
			}
			else if (melee[i_Weapon] <=0)
			{
				melee[i_Weapon] = 0;
				RemoveEdict(i_Weapon);
				new String:command[] = "give";
				if (GetConVarInt(cvar_pistol) == 0)
				{
					StripAndExecuteClientCommand(client, command, "pistol","","");
				}
				else if (GetConVarInt(cvar_pistol) == 1)
				{
					StripAndExecuteClientCommand(client, command, "pistol","","");
					StripAndExecuteClientCommand(client, command, "pistol","","");
				}
				else if (GetConVarInt(cvar_pistol) == 2)
				{
					StripAndExecuteClientCommand(client, command, "pistol_magnum","","");
				}
				else if (GetConVarInt(cvar_pistol) == 3)
				{
					StripAndExecuteClientCommand(client, command, "chainsaw","","");
				}
				PrintHintText(client,"Your Melee Weapon Breaks!!!");
			}
		}
	}
}
public Action:Event_ItemPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt(event,"userid") );
	if ( !IsPlayerAlive(client) || GetClientTeam(client) == 3 ) return;
	new String:stWpn[24], String:stWpn2[32];
	GetEventString( event, "item", stWpn, sizeof(stWpn) );
	
	Format( stWpn2, sizeof( stWpn2 ), "weapon_%s", stWpn);
	if (StrContains(stWpn2, "weapon_melee", false) >= 0)
	{
		new Melee = GetPlayerWeaponSlot(client, 1);
		if (Melee > 0)
		{
			new String:sweapon[32];
			GetEdictClassname(Melee, sweapon, 32);
			if (StrContains(sweapon, "weapon_melee", false) >= 0)
			{
				if (melee[Melee] <= 0)
				{
					new ammo = GetRandomInt(GetConVarInt(cvar_ammolower), GetConVarInt(cvar_ammoupper))
					melee[Melee] = ammo;
				}
			}
		}
	}
}
public Action:OnWeaponEquip(client, weapon)
{
	if ( !IsPlayerAlive(client) || IsFakeClient(client) || GetClientTeam(client) == 3 )
	return Plugin_Continue;

	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if (StrContains(sWeapon, "weapon_melee", false) >= 0)
	{
		if (weapon > 0)
		{
			if (melee[weapon] <= 0)
			{
				new ammo = GetRandomInt(GetConVarInt(cvar_ammolower), GetConVarInt(cvar_ammoupper))
				melee[weapon] = ammo;
			}
		}
	}
	return Plugin_Continue;
}
StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[])
{
	if(client == 0) return;
	if(!IsClientInGame(client)) return;
	if(IsFakeClient(client)) return;
	new admindata = GetUserFlagBits(client);
	new flags = GetCommandFlags(command);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}
stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}