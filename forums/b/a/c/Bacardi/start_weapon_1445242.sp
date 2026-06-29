#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define CONVAR_MAX_LEN 512
#define ITEMS_TYPES_NUM 10
#define ITEMS_STR_LEN 32
#define CS_TEAMS_NUM 4
#define CS_SLOT_KNIFE 2

enum {
	ItemPrimary = 0,
	ItemSecondary,
	ItemKnife,
	ItemHegrenade,
	ItemFlashbang,
	ItemFlashbang2,
	ItemSmokegrenade,
	ItemArmor,
	ItemNvgs,
	ItemDefuser
};

new String:ItemsList[][ITEMS_STR_LEN] = {
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
	"knife",
	"hegrenade",
	"flashbang",
	"flashbang",
	"smokegrenade",
	"kevlar",
	"assaultsuit",
	"nvgs",
	"defuser"
};

new ItemsTypes[] = {
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemPrimary,
	ItemSecondary,
	ItemSecondary,
	ItemSecondary,
	ItemSecondary,
	ItemSecondary,
	ItemSecondary,
	ItemKnife,
	ItemHegrenade,
	ItemFlashbang,
	ItemFlashbang2,
	ItemSmokegrenade,
	ItemArmor,
	ItemArmor,
	ItemNvgs,
	ItemDefuser
};

new String:TeamsItems[CS_TEAMS_NUM][ITEMS_TYPES_NUM][ITEMS_STR_LEN];

new Handle:sm_sw_t;
new Handle:sm_sw_ct;
new Handle:sm_sw_enabled;
new Handle:mp_restartgame;
new Handle:GameRestartTimeout = INVALID_HANDLE;

new bool:MapDE;
new bool:PlayerKilled[MAXPLAYERS];

new RoundCounter;
new m_iAmmo;

public Plugin:myinfo = {
	name = "CSS: Start weapon",
	author = "Devzirom, Bacardi spoiled",
	description = "Allows to replace a set standard start weapon on any another",
	version = "1.1",
	url = "www.sourcemod.com"
}

public OnPluginStart() {
	sm_sw_enabled = CreateConVar("sm_sw_enabled", "1", "\"1\" = \"Start weapon\" plugin is active, \"0\" = \"Start weapon\" plugin is disabled");
	sm_sw_t = CreateConVar("sm_sw_t", "glock", "Set of the start weapon for the Terrorists team. Use \"sm_sw_help\" for help");
	sm_sw_ct = CreateConVar("sm_sw_ct", "usp", "Set of the start weapon for the Counter-Terrorists team. \"Use sm_sw_help\" for help");
	mp_restartgame = FindConVar("mp_restartgame");
	m_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	
	RegServerCmd("sm_sw_help", CommandHelp, " \"Start weapon\" plugin help");
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", EventPlayerTeam, EventHookMode_Post);
	HookEvent("round_start", EventRoundStart, EventHookMode_Post);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Post);
	
	HookConVarChange(mp_restartgame, CommandRestartGame);
	HookConVarChange(sm_sw_t, SwConVarChanged);
	HookConVarChange(sm_sw_ct, SwConVarChanged);
	
	SwConVarRead(sm_sw_t);
	SwConVarRead(sm_sw_ct);
}

public Action:CommandHelp(args) {
	new String:Info[6][128];
	
	GetPluginInfo(INVALID_HANDLE, PlInfo_Name, Info[PlInfo_Name], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Author, Info[PlInfo_Author], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Description, Info[PlInfo_Description], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Version, Info[PlInfo_Version], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_URL, Info[PlInfo_URL], 127);
	
	PrintToServer("-------------------------");
	PrintToServer("\n[Plugin info]");
	PrintToServer("Name: \"%s\"", Info[PlInfo_Name]);
	PrintToServer("Version: \"%s\"", Info[PlInfo_Version]);
	PrintToServer("Description: \"%s\"", Info[PlInfo_Description]);
	PrintToServer("Author: \"%s\"", Info[PlInfo_Author]);
	PrintToServer("URL: \"%s\"", Info[PlInfo_URL]);
	
	PrintToServer("\n[Plugin cvar's]");
	PrintToServer("\"sm_sw_enabled\" \"1\" - \"1\" = \"Start weapon\" plugin is active, \"0\" = \"Start weapon\" plugin is disabled");
	PrintToServer("\"sm_sw_t\" \"glock\" - Set of the start weapon for the Terrorists team.");
	PrintToServer("\"sm_sw_ct\" \"usp\" - Set of the start weapon for the Counter-Terrorists team.");
	PrintToServer("\"sm_sw_help\" - This help");
	
	PrintToServer("\n[Usage examples cvar's]");
	PrintToServer("sm_sw_t fiveseven awp kevlar");
	PrintToServer(" - Set of the start weapon for the Terrorists team is fiveseven, awp and kevlar.");
	PrintToServer("sm_sw_ct ak47 deagle flashbang flashbang");
	PrintToServer(" - Set of the start weapon for the Counter-Terrorists team is ak47, deagle and two flashbang's.");
	PrintToServer("sm_sw_t assaultsuit glock m4a1");
	PrintToServer(" - Set of the start weapon for the Terrorists team is assaultsuit, glock and m4a1.");
	PrintToServer("sm_sw_ct usp m249 defuser");
	PrintToServer(" - Set of the start weapon for the Counter-Terrorists team is usp, m249 and defuser.");
	PrintToServer("sm_sw_t none");
	PrintToServer(" - Set of the start weapon for the Terrorists team is knife only.");
	PrintToServer("sm_sw_ct ak47 m4a1 awp");
	PrintToServer(" - Set of the start weapon for the Counter-Terrorists team is awp. Ak47 and m4a1 - is ignored.");
	PrintToServer("sm_sw_t deagle glock usp");
	PrintToServer(" - Set of the start weapon for the Terrorists team is usp. Deagle and glock - is ignored.");
	PrintToServer("sm_sw_ct galil knife");
	PrintToServer(" - Set of the start weapon for the Counter-Terrorists team is galil knife.");
	
	PrintToServer("\n[Complete value list]");
	
	new ItemsListSize = sizeof(ItemsList);
	
	PrintToServer("\n[Primary]");
	
	for(new i=0; i<ItemsListSize; i++) {
		if(ItemsTypes[i] != ItemPrimary)
			continue;
		
		PrintToServer("%s", ItemsList[i]);
	}
	
	PrintToServer("\n[Secondary]");
	
	for(new i=0; i<ItemsListSize; i++) {
		if(ItemsTypes[i] != ItemSecondary)
			continue;
		
		PrintToServer("%s", ItemsList[i]);
	}
	
	PrintToServer("\n[Grenades]");
	
	for(new i=0; i<ItemsListSize; i++) {
		if(ItemsTypes[i] != ItemFlashbang
		&& ItemsTypes[i] != ItemSmokegrenade
		&& ItemsTypes[i] != ItemHegrenade)
			continue;
		
		PrintToServer("%s", ItemsList[i]);
	}
	
	PrintToServer("\n[Items]");
	
	for(new i=0; i<ItemsListSize; i++) {
		if(ItemsTypes[i] != ItemArmor
		&& ItemsTypes[i] != ItemNvgs
		&& ItemsTypes[i] != ItemDefuser
		&& ItemsTypes[i] != ItemKnife)
			continue;
		
		PrintToServer("%s", ItemsList[i]);
	}
	
	PrintToServer("\n-------------------------");
}

public CommandRestartGame(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(!sw_enabled() || StringToInt(newValue) <= 0)
		return;

	if(GameRestartTimeout != INVALID_HANDLE) {
		KillTimer(GameRestartTimeout);
		GameRestartTimeout = INVALID_HANDLE;
	}
	
	new Float:Timeout = StringToFloat(newValue) - 0.1;
	
	GameRestartTimeout = CreateTimer(Timeout, EventGameRestart);
	
	return;
}

public Action:EventGameRestart(Handle:timer) {
	KillTimer(GameRestartTimeout);
	
	GameRestartTimeout = INVALID_HANDLE;
	RoundCounter = 0;
	
	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!sw_enabled())
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if(RoundCounter == 0)
		PlayerKilled[client] = true;
	
	if(!PlayerKilled[client] || (team != CS_TEAM_T && team != CS_TEAM_CT) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if((team == CS_TEAM_T && !StrEqual(TeamsItems[team][ItemSecondary], "weapon_glock"))
	|| (team == CS_TEAM_CT && !StrEqual(TeamsItems[team][ItemSecondary], "weapon_usp"))) {
		new ent = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		
		if(ent > -1)
			RemovePlayerItem(client, ent);
	}
	
	for(new i=0; i<ITEMS_TYPES_NUM; i++) {
		if(TeamsItems[team][i][0] == 0)
			continue;
		
		if(i == ItemKnife) {
			new ent = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			
			if(ent == -1)
				GivePlayerItem(client, TeamsItems[team][i]);
			
			continue;
		}
		
		if(i == ItemFlashbang2) {
			SetEntData(client, m_iAmmo+(12*4), 2);	
		}
		
		if(i == ItemDefuser && !MapDE)
			continue;
		
		GivePlayerItem(client, TeamsItems[team][i]);
	}
	
	PlayerKilled[client] = false;
	
	return Plugin_Continue;
}

public Action:EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!sw_enabled())
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	PlayerKilled[client] = true;
	
	return Plugin_Continue;
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!sw_enabled())
		return Plugin_Continue;
	
	RoundCounter++;

	return Plugin_Continue;
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!sw_enabled())
		return Plugin_Continue;
	
	new	winner = GetEventInt(event, "winner");
	if(winner != CS_TEAM_T && winner != CS_TEAM_CT)
		RoundCounter = 0;

	return Plugin_Continue;
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!sw_enabled())
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PlayerKilled[client] = true;
	
	return Plugin_Continue;
}

public SwConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	SwConVarRead(convar);
}

public bool:SwConVarRead(Handle:convar) {
	if(convar != sm_sw_t && convar != sm_sw_ct)
		return false;
	
	new team = (convar != sm_sw_ct) ? CS_TEAM_T : CS_TEAM_CT;
	new String:Value[CONVAR_MAX_LEN], String:buffers[ITEMS_TYPES_NUM][ITEMS_STR_LEN];
	
	ClearTeamItems(team);
	
	GetConVarString(convar, Value, CONVAR_MAX_LEN-1);
	
	new ValueSize = sizeof(Value);
	new Num = ExplodeString(Value, " ", buffers, ITEMS_STR_LEN-1, ValueSize);
	
	if(!ValueSize || !Num)
		return false;
	
	new String:ItemName[ITEMS_STR_LEN];
	
	for(new i=0; i<sizeof(buffers); i++) {
		new ItemType = GetItemType(buffers[i]);
		
		if(ItemType < 0 || (ItemType == ItemDefuser && team != CS_TEAM_CT))
			continue;
		
		if(ItemType == ItemArmor || ItemType == ItemNvgs || ItemType == ItemDefuser)
			Format(ItemName, ITEMS_STR_LEN-1, "item_%s", buffers[i]);
		else
			Format(ItemName, ITEMS_STR_LEN-1, "weapon_%s", buffers[i]);
		
		if(ItemType == ItemFlashbang) {
			if(TeamsItems[team][ItemFlashbang][0] != 0)
				ItemType = ItemFlashbang2;
		}
		
		TeamsItems[team][ItemType] = ItemName;
	}
	
	return true;
}

public OnMapStart() {
	new String:MapName[32];
	
	GetCurrentMap(MapName, 31);

	if(MapName[0] == 0)
		return;
	
	new EntityCount = GetEntityCount();
	new String:ClassName[128];
	
	for(new ent=0; ent<=EntityCount; ent++) {
		if(!IsValidEntity(ent))
			continue;
			
		if(!GetEdictClassname(ent, ClassName, sizeof(ClassName)))
			continue;
			
		if(!StrEqual(ClassName, "func_bomb_target", false))
			continue;
		
		MapDE = true;
		return;
	}
	
	return;
}

public ClearTeamItems(team) {
	for(new i=0; i<ITEMS_TYPES_NUM; i++) {
		TeamsItems[team][i] = "";
	}
}

public GetItemType(String:ItemName[]) {
	for(new i=0; i<sizeof(ItemsList); i++) {
		if(!StrEqual(ItemName, ItemsList[i], false))
			continue;
		
		return ItemsTypes[i];
	}
	
	return -1;
}

stock bool:sw_enabled() {
	return (GetConVarInt(sm_sw_enabled) > 0);
}