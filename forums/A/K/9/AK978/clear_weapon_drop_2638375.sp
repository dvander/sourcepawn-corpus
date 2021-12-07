#include <sourcemod>
#include <sdktools>

new Handle:ClearTime = INVALID_HANDLE;
new Handle:g_timer = INVALID_HANDLE;
Address address[2048];
new aaa;

new String:file[PLATFORM_MAX_PATH];

new const String:ItemDeleteList[][] =
{
	"weapon_smg_mp5",
	"weapon_smg_silenced",
	"weapon_smg",
	"weapon_shotgun_chrome",
	"weapon_pumpshotgun",
	"weapon_hunting_rifle",
	"weapon_rifle_m60",
	"weapon_rifle_ak47",
	"weapon_rifle_desert",
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_shotgun_spas",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_rifle_sg552",
	"weapon_sniper_scout",
	"weapon_grenade_launcher",
	"weapon_pistol_magnum",
	"weapon_pistol",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_defibrillator",
	"weapon_pain_pills",
	"weapon_adrenaline"
};

public Plugin:myinfo = 
{
	name = "[l4d2]remove drop weapon",
	author = "AK978",
	version = "1.8"
}

public OnPluginStart()
{
	BuildPath(Path_SM, file, sizeof(file), "logs/remove_drop_weapon.log");

	ClearTime = CreateConVar("sm_drop_clear_time", "30.0", "clear time", 0);
	
	HookEvent("weapon_drop", Event_Weapon_Drop);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", Event_Round_End);
	HookEvent("player_disconnect", Event_Player_Disconnect); 
	
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

public Action:Event_Player_Disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"))
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;
    for(new i; i < 5; i++){
        new entity = GetPlayerWeaponSlot(client, i);
        if(entity <= 0 || entity <= MaxClients || !IsValidEntity(entity)){
            continue;
        }
        address[entity] = GetEntityAddress(entity);
        
        new String:item[32];
        GetEdictClassname(entity, item, sizeof(item));
        
        for(new j=0; j < sizeof(ItemDeleteList); j++)
        {
            if (StrContains(item, ItemDeleteList[j], false) != -1)
            {
                g_timer = CreateTimer(GetConVarFloat(ClearTime), del_weapon, EntIndexToEntRef(entity));
            }
        }
    }
    return Plugin_Stop;
} 

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	aaa = 1;
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	aaa = 0;
}

public Action:Event_Weapon_Drop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;
		
	new entity = GetEventInt(event, "propid");
	address[entity] = GetEntityAddress(entity);
	
	new String:item[32];
	
	if (!IsValidEntity(entity) || !IsValidEdict(entity)) return Plugin_Stop;
	
	GetEdictClassname(entity, item, sizeof(item));
	
	for(new j=0; j < sizeof(ItemDeleteList); j++)
	{
		if (StrContains(item, ItemDeleteList[j], false) != -1)
		{
			g_timer = CreateTimer(GetConVarFloat(ClearTime), del_weapon, EntIndexToEntRef(entity));
		}
	}
	return Plugin_Stop;
}

public Action:del_weapon(Handle:timer, any:entity)
{
	if(entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(entity) && aaa == 1)
		{
			if (address[entity] == GetEntityAddress(entity))
			{
				for(new j=0; j < sizeof(ItemDeleteList); j++)
				{
					new String:item[32];
					GetEdictClassname(entity, item, sizeof(item));
					 
					if (StrEqual(item, ItemDeleteList[j], false))
					{
						if(!IsWeaponInUse(entity) && IsValidEntity(entity))
						{
							AcceptEntityInput(entity, "Kill");
							LogToFileEx(file, "remove drop weapon = %s", item);
							address[entity] = Address_Null;
							break;
						}
					}
				}
			}
		}
	}
	g_timer = INVALID_HANDLE;
}

bool:IsWeaponInUse(entity)
{	
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
	if (IsValidClient(client))
		return true;
	
	client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (IsValidClient(client))
		return true;

	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsValidClient(i) && GetActiveWeapon(i) == entity)
			return true;
	}
	
	return false;
}

stock GetActiveWeapon(client)
{
	new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(weapon)) 
	{
		return false;
	}
	
	return weapon;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}