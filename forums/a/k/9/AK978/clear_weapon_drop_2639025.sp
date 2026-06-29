#include <sourcemod>
#include <sdktools>

new Handle:ClearTime = INVALID_HANDLE;
new address[2048];
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
	name = "[l4d2]remove drop weapon",
	author = "AK978",
	version = "1.2"
}

public OnPluginStart()
{
	ClearTime = CreateConVar("sm_drop_clear_time", "20.0", "clear time", 0);
	
	HookEvent("weapon_drop", Event_Weapon_Drop);
	
	AutoExecConfig(true, "clear_weapon_drop");
}

public Action:Event_Weapon_Drop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (!IsSurvivor(client) || !IsPlayerAlive(client)) return Plugin_Stop;
		
	new entity = GetEventInt(event, "propid");
	address[entity] = GetEntityAddress(entity);
	
	new String:item[32];
	GetEdictClassname(entity, item, sizeof(item));
	
	for(new j=0; j < sizeof(ItemDeleteList); j++)
	{
		if (StrContains(item, ItemDeleteList[j], false) != -1)
		{
			if (IsValidEntity(entity))
			{
				CreateTimer(GetConVarFloat(ClearTime), del_weapon, entity, TIMER_FLAG_NO_MAPCHANGE);
				//PrintToChat(client, "remove %s",item);
			}
		}
	}
	return Plugin_Stop;
}

public Action:del_weapon(Handle:timer, any:entity)
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "logs/remove_drop_weapon.log");
	
	if (IsValidEntity(entity))
	{
		if (address[entity] == GetEntityAddress(entity))
		{
			if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == -1)
			{
				new String:item[32];
				GetEdictClassname(entity, item, sizeof(item));
				AcceptEntityInput(entity, "Kill");
				LogToFileEx(file, "remove drop weapon = %s", item);
				address[entity] = INVALID_HANDLE;
			}
		}
	}
}

stock bool:IsSurvivor(client) 
{
	if (IsValidClient(client)) 
	{
		if (GetClientTeam(client) == 2) 
		{
			return true;
		}
	}
	return false;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}