#include <sourcemod>
#include <sdktools>

new Handle:ClearTime = INVALID_HANDLE;
new Handle:g_timer = INVALID_HANDLE;
Address address[2048];
new const String:ItemDeleteList[][] =
{
	"weapon_smg_mp5",
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_shotgun_chrome",
	"weapon_pumpshotgun",
	"weapon_hunting_rifle",
	"weapon_pistol",
	"weapon_rifle_m60",
	"weapon_autoshotgun",
	"weapon_shotgun_spas",
	"weapon_sniper_military",
	"weapon_rifle",
	"weapon_rifle_ak47",
	"weapon_rifle_desert",
	"weapon_sniper_awp",
	"weapon_rifle_sg552",
	"weapon_sniper_scout",
	"weapon_grenade_launcher",
	"weapon_pistol_magnum",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_defibrillator",
	"weapon_pain_pills",
	"weapon_adrenaline",
	"weapon_melee"
};

public Plugin:myinfo = 
{
	name = "css remove drop weapon",
	author = "AK978",
	version = "1.0"
}

public OnPluginStart()
{
	ClearTime = CreateConVar("sm_drop_clear_time", "20.0", "clear time", 0);
	
	AutoExecConfig(true, "clear_weapon_drop");
}

public OnMapEnd()
{
	if (g_timer != INVALID_HANDLE)
	{
		KillTimer(g_timer);
		g_timer = INVALID_HANDLE;
	}
}

public Action:CS_OnCSWeaponDrop(client, weapon)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;
	
	address[weapon] = GetEntityAddress(weapon);
	
	new String:item[32];
	GetEdictClassname(weapon, item, sizeof(item));
	
	for(new j=0; j < sizeof(ItemDeleteList); j++)
	{
		if (StrContains(item, ItemDeleteList[j], false) != -1)
		{
			if (IsValidEntity(weapon))
			{
				g_timer = CreateTimer(GetConVarFloat(ClearTime), del_weapon, weapon);
			}
		}
	}
	return Plugin_Stop;
}

public Action:del_weapon(Handle:timer, any:weapon)
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "logs/remove_drop_weapon.log");
	
	if (IsValidEntity(weapon))
	{
		if (address[weapon] == GetEntityAddress(weapon))
		{
			if(GetEntPropEnt(weapon, Prop_Data, "m_hOwnerweapon") == -1)
			{
				new String:item[32];
				GetEdictClassname(weapon, item, sizeof(item));
				AcceptEntityInput(weapon, "Kill");
				LogToFileEx(file, "remove drop weapon = %s", item);
				address[weapon] = Address_Null;
			}
		}
	}
	g_timer = INVALID_HANDLE;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}