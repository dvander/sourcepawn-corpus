#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define ITEM_NAME_LEN 32
#define ITEMS_TYPES_NUM 10
#define CS_SLOT_KNIFE 2
#define CS_TEAMS_NUM 4

new Handle:sm_sw_enabled;
new Handle:sm_sw_t;
new Handle:sm_sw_ct;
new Handle:mp_restartgame;
new Handle:Restart_Timer = INVALID_HANDLE;

new m_bHasDefuser;
new m_bHasHelmet;
new m_bHasNightVision;
new m_ArmorValue;
new m_flDeathTime;
new m_iAmmo;

new bool:Map_Has_Bomb_Target;
new bool:Is_SW_Enabled;
new Float:Death_Time[MAXPLAYERS] = { -1.0, ... };
new String:Teams_Items[CS_TEAMS_NUM][ITEMS_TYPES_NUM][ITEM_NAME_LEN];

enum {
	Item_Primary = 0,
	Item_Secondary,
	Item_Noknife,
	Item_Hegrenade,
	Item_Flashbang,
	Item_Flashbang2,
	Item_Smokegrenade,
	Item_Armor,
	Item_Nvgs,
	Item_Defuser
};

new String:Items_Names[][ITEM_NAME_LEN] = {
	"m3",
	"xm1014",
	"mac10",
	"tmp",
	"mp5navy",
	"ump45",
	"p90",
	"galil",
	"famas",
	"ak47",
	"m4a1",
	"sg552",
	"aug",
	"m249",
	"scout",
	"sg550",
	"awp",
	"g3sg1",
	"glock",
	"p228",
	"usp",
	"deagle",
	"elite",
	"fiveseven",
	"noknife",
	"hegrenade",
	"flashbang",
	"flashbang",
	"smokegrenade",
	"kevlar",
	"assaultsuit",
	"nvgs",
	"defuser"
};

new Items_Types[] = {
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Noknife,
	Item_Hegrenade,
	Item_Flashbang,
	Item_Flashbang2,
	Item_Smokegrenade,
	Item_Armor,
	Item_Armor,
	Item_Nvgs,
	Item_Defuser
};

public Plugin:myinfo = {
	name = "CSS: Start weapon",
	author = "Devzirom",
	description = "Allows to replace a set standard start weapon on any another",
	version = "1.2",
	url = "http://forums.alliedmods.net/showthread.php?t=114527"
}

public OnPluginStart() {
	new String:Info[6][128];
	
	GetPluginInfo(INVALID_HANDLE, PlInfo_Name, Info[PlInfo_Name], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Version, Info[PlInfo_Version], 127);
	
	m_bHasDefuser = FindSendPropOffs("CCSPlayer", "m_bHasDefuser");
	m_bHasHelmet = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	m_bHasNightVision = FindSendPropOffs("CCSPlayer", "m_bHasNightVision");
	m_ArmorValue = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	m_flDeathTime = FindSendPropOffs("CCSPlayer", "m_flDeathTime");
	m_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	
	sm_sw_enabled = CreateConVar("sm_sw_enabled", "1",
		"\"1\" = \"Start weapon\" plugin is active, \"0\" = \"Start weapon\" plugin is disabled");
	sm_sw_t = CreateConVar("sm_sw_t", "glock",
		"Set of the start weapon for the Terrorists team. Use \"sm_sw_help\" for help");
	sm_sw_ct = CreateConVar("sm_sw_ct", "usp",
		"Set of the start weapon for the Counter-Terrorists team. \"Use sm_sw_help\" for help");
	mp_restartgame = FindConVar("mp_restartgame");
	
	RegServerCmd("sm_sw_help", CommandHelp, " \"Start weapon\" plugin help");
	CreateConVar("sm_sw_version", Info[PlInfo_Version], Info[PlInfo_Name], FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	HookConVarChange(sm_sw_t, ConVarChanged);
	HookConVarChange(sm_sw_ct, ConVarChanged);
	HookConVarChange(mp_restartgame, ConVarChanged);
	
	ConVarRead(sm_sw_enabled);
	ConVarRead(sm_sw_t);
	ConVarRead(sm_sw_ct);
	
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Post);
}

public Action:CommandHelp(args) {
	new String:Info[6][128];
	
	GetPluginInfo(INVALID_HANDLE, PlInfo_Name, Info[PlInfo_Name], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Author, Info[PlInfo_Author], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Description, Info[PlInfo_Description], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Version, Info[PlInfo_Version], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_URL, Info[PlInfo_URL], 127);
	
	new String:buffers[][256] = {
		"\n[Plugin cvar's]",
		"\"sm_sw_enabled\" \"1\" - \"1\" = \"Start weapon\" plugin is active, \"0\" = \"Start weapon\" plugin is disabled",
		"\"sm_sw_t\" \"glock\" - Set of the start weapon for the Terrorists team.",
		"\"sm_sw_ct\" \"usp\" - Set of the start weapon for the Counter-Terrorists team.",
		"\"sm_sw_help\" - This help",
		"\"sm_sw_version\" - Current version",
		"\n[Usage examples cvar's]",
		"sm_sw_t fiveseven awp kevlar",
		" - Set of the start weapon for the Terrorists team is fiveseven, awp and kevlar.",
		"sm_sw_ct ak47 deagle flashbang flashbang",
		" - Set of the start weapon for the Counter-Terrorists team is ak47, deagle and two flashbang's.",
		"sm_sw_t assaultsuit glock m4a1",
		" - Set of the start weapon for the Terrorists team is assaultsuit, glock and m4a1.",
		"sm_sw_ct usp m249 defuser",
		" - Set of the start weapon for the Counter-Terrorists team is usp, m249 and defuser.",
		"sm_sw_t none",
		" - Set of the start weapon for the Terrorists team is knife only.",
		"sm_sw_ct ak47 m4a1 awp",
		" - Set of the start weapon for the Counter-Terrorists team is awp. Ak47 and m4a1 - is ignored.",
		"sm_sw_t deagle glock usp",
		" - Set of the start weapon for the Terrorists team is usp. Deagle and glock - is ignored.",
		"sm_sw_ct galil noknife",
		" - Set of the start weapon for the Counter-Terrorists team is galil. Knife - is removed.",
		"\n[Complete value list]",
		"\n[Primary]","m3","xm1014","mac10","tmp","mp5navy","ump45","p90","galil","famas","ak47","m4a1","sg552","aug","m249","scout","sg550","awp","g3sg1",
		"\n[Secondary]","glock","p228","usp","deagle","elite","fiveseven",		
		"\n[Grenades]","hegrenade","flashbang","smokegrenade",
		"\n[Items]","kevlar","assaultsuit","nvgs","defuser","noknife",
		"\n-------------------------"
	};
	
	PrintToServer("-------------------------\n\n[Plugin info]\nName: \"%s\"\nVersion: \"%s\"\nDescription: \"%s\"\nAuthor: \"%s\",\nURL: \"%s\"",
		Info[PlInfo_Name], Info[PlInfo_Version], Info[PlInfo_Description], Info[PlInfo_Author], Info[PlInfo_URL]);
		
	for(new i=0; i<sizeof(buffers); i++) {
		PrintToServer("%s", buffers[i]);
	}
}

public OnMapStart() {
	Map_Has_Bomb_Target = false;
	new entity_count = GetEntityCount();
	new String:class_name[128];
	
	for(new ent=0; ent<=entity_count; ent++) {
		if(IsValidEntity(ent) && GetEdictClassname(ent, class_name, 127)) {
			if(StrEqual(class_name, "func_bomb_target", false)) {
				Map_Has_Bomb_Target = true;
				break;
			}
		}
	}
	
	CreateTimer(0.1, ResetDeathTime);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(!StrEqual(oldValue, newValue, false)) {
		ConVarRead(convar);
	}
}

public ConVarRead(Handle:convar) {
	if(convar == sm_sw_t || convar == sm_sw_ct) {
		new team = (convar == sm_sw_t) ? CS_TEAM_T : CS_TEAM_CT;
		new String:buffers[32][ITEM_NAME_LEN];
		new String:value[512];
			
		GetConVarString(convar, value, 511);
		
		for(new i=0; i<ITEMS_TYPES_NUM; i++) {
			Teams_Items[team][i] = "";
		}
			
		if(strlen(value) && ExplodeString(value, " ", buffers, 31, ITEM_NAME_LEN-1)) {
			new items_num = sizeof(Items_Names);
				
			for(new b=0; b<sizeof(buffers); b++) {
				for(new i=0; i<items_num; i++) {
					if(StrEqual(buffers[b], Items_Names[i], false)) {
						new item_type = Items_Types[i];
						
						if(item_type == Item_Flashbang && strlen(Teams_Items[team][Item_Flashbang]))
							item_type = Item_Flashbang2;
						
						if(item_type == Item_Defuser && team != CS_TEAM_CT)
							continue;
						
						Format(Teams_Items[team][item_type], ITEM_NAME_LEN-1,
							(item_type == Item_Armor || item_type == Item_Nvgs || item_type == Item_Defuser) ? "item_%s" : "weapon_%s",
							Items_Names[i]);
					}
				}
			}
		}
	} else
	
	if(convar == sm_sw_enabled)
		Is_SW_Enabled = (GetConVarInt(convar) > 0);
	else
	
	if(convar == mp_restartgame) {
		new Float:timeout = GetConVarFloat(convar);
		
		if(timeout > 0.0) {
			if(Restart_Timer != INVALID_HANDLE) {
				KillTimer(Restart_Timer);
				Restart_Timer = INVALID_HANDLE;
			}
			
			Restart_Timer = CreateTimer(timeout - 0.1, ResetDeathTime);
		}
	}
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!Is_SW_Enabled)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if(IsPlayerAlive(client) && (team == CS_TEAM_T || team == CS_TEAM_CT)) {
		new String:item_name[ITEM_NAME_LEN];
		new Float:death_time = GetEntDataFloat(client, m_flDeathTime);
		
		new primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		new secondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		new knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		new hegrenade = GetEntData(client, m_iAmmo + (11 * 4));
		new flashbang = GetEntData(client, m_iAmmo + (12 * 4));
		new smokegrenade = GetEntData(client, m_iAmmo + (13 * 4));
		new armor = GetEntData(client, m_ArmorValue);
		new helmet = GetEntData(client, m_bHasHelmet);
		new defuser = GetEntData(client, m_bHasDefuser);
		new nvgs = GetEntData(client, m_bHasNightVision);
		
		if(death_time != Death_Time[client]) {
			Death_Time[client] = death_time;
			
			if(primary > -1)
				RemovePlayerItem(client, primary);
			
			if(secondary > -1)
				RemovePlayerItem(client, secondary);
			
			if(hegrenade)
				SetEntData(client, m_iAmmo + (11 * 4), 0);
			
			if(flashbang)
				SetEntData(client, m_iAmmo + (12 * 4), 0);
			
			if(smokegrenade)
				SetEntData(client, m_iAmmo + (13 * 4), 0);
			
			if(defuser)
				SetEntData(client, m_bHasDefuser, 0);
			
			if(nvgs)
				SetEntData(client, m_bHasNightVision, 0);
			
			if(helmet)
				SetEntData(client, m_bHasHelmet, 0);
			
			if(armor)
				SetEntData(client, m_ArmorValue, 0);
			
			for(new item_type=0; item_type<ITEMS_TYPES_NUM; item_type++) {
				item_name = Teams_Items[team][item_type];
			
				if(strlen(item_name)) {
					if(knife > -1 && item_type == Item_Noknife)
						RemovePlayerItem(client, knife);
					else
					
					if(item_type == Item_Flashbang2)
						SetEntData(client, m_iAmmo + 12*4, 2);
					else
					
					if(item_type == Item_Defuser && Map_Has_Bomb_Target) {
						SetEntData(client, m_bHasDefuser, 1);
					} else
						GivePlayerItem(client, item_name);
				}
			}
		} else {
			for(new item_type=0; item_type<ITEMS_TYPES_NUM; item_type++) {
				item_name = Teams_Items[team][item_type];
				
				if(strlen(item_name)) {										
					if((item_type == Item_Primary && primary != -1)
						|| (item_type == Item_Secondary && secondary != -1)
						|| (item_type == Item_Hegrenade && hegrenade)
						|| (item_type == Item_Flashbang && flashbang)
						|| (item_type == Item_Flashbang2 && flashbang != 1)
						|| (item_type == Item_Smokegrenade && smokegrenade)
						|| (item_type == Item_Defuser && (defuser || !Map_Has_Bomb_Target))
						|| (item_type == Item_Nvgs && nvgs)
						|| (item_type == Item_Armor && armor >= 100 && (StrEqual(item_name, "assaultsuit") ? helmet : 0))
					)
						continue;
					else
					
					if(item_type == Item_Noknife && knife > -1)
						RemovePlayerItem(client, knife);
					else
					
					if(item_type == Item_Defuser)
						SetEntData(client, m_bHasDefuser, 1);
					else
					
					if(item_type == Item_Flashbang2)
						SetEntData(client, m_iAmmo + (12*4), 2);
					else
						GivePlayerItem(client, item_name);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	new	winner = GetEventInt(event, "winner");
	
	if(winner != CS_TEAM_T && winner != CS_TEAM_CT) {
		CreateTimer(1.0, ResetDeathTime);
	}
	
	return Plugin_Continue;
}

public Action:ResetDeathTime(Handle:timer) {
	if(timer == Restart_Timer) {
		KillTimer(Restart_Timer);
		Restart_Timer = INVALID_HANDLE;
	}
	
	for(new i=0; i<MAXPLAYERS; i++) {
		Death_Time[i] = -1.0;
	}
	
	return Plugin_Continue;
}