#include <sourcemod>

new Handle:ScanTime = INVALID_HANDLE;
new Handle:ScanWeapon = INVALID_HANDLE;
new Handle:ScanMelee = INVALID_HANDLE;
new Handle:ScanItem = INVALID_HANDLE;
new Handle:announce = INVALID_HANDLE;


new const String:WeaponDeleteList[][] = {	
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
	"weapon_pistol_magnum"
};

new const String:MeleeDeleteList[][] = {
	"weapon_melee"
};

new const String:ItemDeleteList[][] = {
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_defibrillator",
	"weapon_pain_pills",
	"weapon_adrenaline"
};

public Plugin:myinfo = {
	name = "Clear Map Iteams",
	author = "AK978",
	version = "1.3"
}

public OnPluginStart(){
	ScanTime = CreateConVar("sm_clear_scan_time", "30.0", "scan time", 0);
	ScanWeapon = CreateConVar("sm_clear_scan_weapon", "1", "scan weapon", 0);
	ScanMelee = CreateConVar("sm_clear_scan_melee", "1", "scan melee", 0);
	ScanItem = CreateConVar("sm_clear_scan_item", "1", "scan item", 0);
	announce = CreateConVar("sm_clear_scan_announce", "1", "scan notice", 0);
	
	AutoExecConfig(true, "Clear_Map");
}

public OnMapStart(){
	CreateTimer(GetConVarFloat(ScanTime), Clear_map, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action:Clear_map(Handle:timer){
	new maxent = GetMaxEntities(), String:item[64], num = 0, num2 = 0, num3 = 0;
	new g_delete;
	
	for (new i = MaxClients; i < maxent; i++){
		if ( IsValidEdict(i) && IsValidEntity(i)){
			if(GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1){
				GetEdictClassname(i, item, sizeof(item));
				
				g_delete = 0;
				if(GetConVarBool(ScanWeapon)){
					for(new j=0; j < sizeof(WeaponDeleteList); j++){
						if (StrContains(item, WeaponDeleteList[j], false) != -1){
							if (IsValidEdict(i) && IsValidEntity(i)){
								num++;
								RemoveEdict(i);
								g_delete = 1;
							}						
						}
					}
				}
				if (GetConVarBool(ScanMelee) && g_delete == 0){
					for(new k=0; k < sizeof(MeleeDeleteList); k++){
						if (StrContains(item, MeleeDeleteList[k], false) != -1){
							if (IsValidEdict(i) && IsValidEntity(i)){
								num2++;
								RemoveEdict(i);
								g_delete = 1;
							}
						}
					}					
				}
				if(GetConVarBool(ScanItem) && g_delete == 0){
					for(new l=0; l < sizeof(ItemDeleteList); l++){
						if (StrContains(item, ItemDeleteList[l], false) != -1){
							if (IsValidEdict(i) && IsValidEntity(i)){
								num3++;
								RemoveEdict(i);
							}
						}
					}
				}
			}
		}
	}
	if(GetConVarBool(announce)){
		PrintToChatAll("clear map [%d weapon] , [%d melee] , [%d item] .", num, num2, num3);
	}
}