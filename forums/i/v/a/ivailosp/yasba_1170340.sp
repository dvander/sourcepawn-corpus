#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name        = "YASBA",
	author      = "ivailosp",
	description = "add extra bots",
	version     = "1.0.1",
	url         = "n/a"
};

new Handle:g_hSurvivorLimit = INVALID_HANDLE;
new Handle:g_hZombieLimit = INVALID_HANDLE;

new Handle:g_hSurvivorLimitConfig = INVALID_HANDLE;
new Handle:g_hZombieLimitConfig = INVALID_HANDLE;
new Handle:g_hExtraHealtConfig = INVALID_HANDLE;

public OnPluginStart(){
	g_hSurvivorLimitConfig = CreateConVar("l4d_survivor_limit", "4", "Max Survivors", 0, true, 1.0, true, 16.0);
	g_hZombieLimitConfig = CreateConVar("l4d_zombie_limit", "4", "Max Player Zombies", 0, true, 1.0, true, 16.0);
	g_hExtraHealtConfig = CreateConVar("l4d_extra_medkit", "1", "", 0, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_yasba");
	
	g_hSurvivorLimit = FindConVar("survivor_limit");
	if(g_hSurvivorLimit!=INVALID_HANDLE){
		SetConVarBounds(g_hSurvivorLimit, ConVarBound_Upper, true, 16.0);
		SetConVarInt(g_hSurvivorLimit, GetConVarInt(g_hSurvivorLimitConfig));
		HookConVarChange(g_hSurvivorLimitConfig, SurvivorLimitConfigChange);
	}
	
	g_hZombieLimit = FindConVar("z_max_player_zombies");
	if(g_hZombieLimit!=INVALID_HANDLE){
		SetConVarBounds(g_hZombieLimit, ConVarBound_Upper, true, 16.0);
		SetConVarInt(g_hZombieLimit, GetConVarInt(g_hZombieLimitConfig));
		HookConVarChange(g_hZombieLimitConfig, ZombieLimitConfigChange);
	}
	
	HookEvent("round_start", Event_RoundStart);

}

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
			if(IsFakeClient(i) && !IsClientInKickQueue(i)){
				KickClient(i);
			}
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("ROUND START");
	new survivor_limit = GetConVarInt(g_hSurvivorLimit);
	new survivor_limit_config = GetConVarInt(g_hSurvivorLimitConfig);
	
	new zombie_limt = GetConVarInt(g_hZombieLimit);
	new zombie_limt_config = GetConVarInt(g_hZombieLimitConfig);
	
	if(survivor_limit != survivor_limit_config)
		SetConVarInt(g_hSurvivorLimit, survivor_limit_config);
		
	if(zombie_limt!=zombie_limt_config)
		SetConVarInt(g_hZombieLimit, zombie_limt_config);
		
	CreateTimer(1.0, CheckSurvivorBot);
}

public Action:CheckSurvivorBot(Handle:timer)
{
	if(g_hSurvivorLimit==INVALID_HANDLE)
		return Plugin_Handled;
	new survlimit = GetConVarInt(g_hSurvivorLimit);
	new current_clients = GetTeamClientCount(2);
	//PrintToChatAll("survlimit %d", survlimit);
	//PrintToChatAll("curr %d", current_clients);
	if(survlimit < 4)
		return Plugin_Handled;
		
	if (current_clients >= 1 && current_clients < survlimit){
		SpawnFakeClient()
	}
	if(current_clients < survlimit)
		CreateTimer(0.3, CheckSurvivorBot);
	return Plugin_Handled;
}

SpawnFakeClient(){
	//PrintToChatAll("MAKE BOT");
	new Bot = CreateFakeClient("SurvivorBot");
	if (Bot == 0)
		return;
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	if(GetConVarInt(g_hExtraHealtConfig)){
		new medkit = GivePlayerItem(Bot,"weapon_first_aid_kit");
		if(medkit)
			EquipPlayerWeapon(Bot,medkit);
	}
	CreateTimer(0.1, KickFakeClient, Bot);
}

public Action:KickFakeClient(Handle:hTimer, any:Client){
	if(IsClientConnected(Client) && IsFakeClient(Client)){
		KickClient(Client, "Kicking Fake Client.");
	}
	return Plugin_Handled;
}

public SurvivorLimitConfigChange(Handle:handle, const String:o[], const String:n[]){
	SetConVarInt(g_hSurvivorLimit, GetConVarInt(handle));
}
public ZombieLimitConfigChange(Handle:handle, const String:o[], const String:n[]){
	SetConVarInt(g_hZombieLimit, GetConVarInt(handle));
}
