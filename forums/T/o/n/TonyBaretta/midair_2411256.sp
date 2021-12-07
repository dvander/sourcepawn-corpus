#include <sourcemod>
#include <SteamWorks>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2items_giveweapon>
#define DMG_BLAST (1 << 6)
#define ITEM_MANTREADS	  444
#define PLUGIN_VERSION "1.1.6"
#define DMG_TIMEBASED			 (DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
public Plugin:myinfo =
{
	name = "Mid Air Mod",
	author = "TonyBaretta",
	description = "Goal of midair is to kill your opponent while he is airborne",
	version = PLUGIN_VERSION
}

new bool:g_bSteamWorks = false;
new bool:g_ma_bPlayerJumped[MAXPLAYERS+1];
new bool:g_damage[MAXPLAYERS+1];	
new Float:g_ma_fMax_Height[MAXPLAYERS+1];
new Float:height[MAXPLAYERS +1][3];
new Float:heightstart[MAXPLAYERS +1][3];
new Clip1[MAXPLAYERS+1];
new PauseTime[MAXPLAYERS+1];
new ammoOffset;
new Handle:g_Cvar_GameDescription = INVALID_HANDLE;
new Handle:g_hmaGameEnable = INVALID_HANDLE;
new bool:g_bmaGameEnable;
new maclass;
public OnPluginStart()
{
	g_hmaGameEnable = CreateConVar("midair_enable", "1", "Enable / Disable Plugin");
	g_bmaGameEnable = GetConVarBool(g_hmaGameEnable);
	g_Cvar_GameDescription = CreateConVar("ma_gamedescription", "1.0", "If SteamWorks is loaded, set the Game Description to MidAir?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEventEx("player_spawn", event_player_spawn, EventHookMode_Post);
	HookEventEx("player_death", event_player_death, EventHookMode_Post);
	CreateConVar("midair_version", PLUGIN_VERSION, "MidAir game mode for TF2 by TonyBaretta.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	HookConVarChange(g_Cvar_GameDescription, Cvar_GameDescription);
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}
public OnAllPluginsLoaded()
{
	g_bSteamWorks = LibraryExists("SteamWorks");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamWorks", false))
	{
		g_bSteamWorks = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamWorks", false))
	{
		g_bSteamWorks = false;
	}
}
public OnConfigsExecuted()
{	
		UpdateGameDescription(true);
}
public Cvar_GameDescription(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateGameDescription();
}
UpdateGameDescription(bool:bAddOnly=false)
{
	if (g_bSteamWorks)
	{
		new String:gamemode[64];
		if (GetConVarBool(g_Cvar_GameDescription))
		{
			Format(gamemode, sizeof(gamemode), "MidAir v.%s", PLUGIN_VERSION);
		}
		else if (bAddOnly)
		{
			
			return;
		}
		else
		{
			strcopy(gamemode, sizeof(gamemode), "Team Fortress");
		}
		SteamWorks_SetGameDescription(gamemode);
	}
}
public HeightHook(i) {
	if(IsValidClient(i) && IsPlayerAlive(i) && (( GetEntityFlags(i) & FL_ONGROUND )))
	{
		g_ma_bPlayerJumped[i] = false;
		CalcJumpHeight(i);
		if(GetClientTeam(i) == 2){
			SetEntityRenderColor(i, 255, 0, 0, 255);
		}
		if(GetClientTeam(i) == 3){
			SetEntityRenderColor(i, 0, 0, 255, 255);
		}
		g_damage[i] = false;
		CreateTimer(1.0, AddRockets, i);
	}
	if(IsValidClient(i) && IsPlayerAlive(i) && (!( GetEntityFlags(i) & FL_ONGROUND )))
	{
		g_ma_bPlayerJumped[i] = true;
		CalcJumpHeight(i);
		if((height[i][2] - heightstart[i][2]) >=  130.0){
			SetEntityRenderColor(i, 0, 255, 0, 255);
			g_damage[i] = true;
		}
	}
}
public Action:AddRockets(Handle:timer,any:client)
{
	new currentTime = GetTime();
	if (currentTime - PauseTime[client] < 2)return;
	PauseTime[client] = GetTime();
	if(IsValidClient(client) && IsPlayerAlive(client)){
		new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(ActiveWeapon <= MaxClients)
		{
			return;
		}
		Clip1[client] = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1");
		//PrintToChat(client, "Clip1 = %i", Clip1[client]); //debug
		if(Clip1[client] == 7){
			SetEntProp(ActiveWeapon, Prop_Data, "m_iClip1", 8);
		}
		if(Clip1[client] == 6){
			SetEntProp(ActiveWeapon, Prop_Data, "m_iClip1", 7);
		}
		if(Clip1[client] == 5){
			SetEntProp(ActiveWeapon, Prop_Data, "m_iClip1", 6);
		}
		if(Clip1[client] == 4){
			SetEntProp(ActiveWeapon, Prop_Data, "m_iClip1", 5);
		}
	}
}  
public CalcJumpHeight(client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && (!( GetEntityFlags(client) & FL_ONGROUND )))
	{
		GetClientAbsOrigin(client, height[client]);
		if (height[client][2] > g_ma_fMax_Height[client])
		g_ma_fMax_Height[client] = height[client][2];	
		//g_flastHeight[client] = height[client][2];
	}
	if(IsValidClient(client) && IsPlayerAlive(client) && (( GetEntityFlags(client) & FL_ONGROUND )))
	{	

		GetClientAbsOrigin(client, heightstart[client]);
		if (heightstart[client][2] > g_ma_fMax_Height[client])
		g_ma_fMax_Height[client] = heightstart[client][2];	
	}
}
public Action:Refill_OnTakeDamageClient(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (IsValidClient(victim) && IsPlayerAlive(victim)	&& !g_damage[victim]) {
		if(attacker == victim){
			new CurrentHealth2 = GetPlayerHealth(victim);
			if(CurrentHealth2 <= 10){
				SetEntityHealth(victim, 250);
			}
		}
		//new weapon = GetEntProp(victim, Prop_Send, "m_iItemDefinitionIndex");
		new CurrentHealth = GetPlayerHealth(victim);
		if(damage > 180.0){
			SetEntityHealth(victim, 200);
		}
		if(CurrentHealth <= 10){
			SetEntityHealth(victim, 200);
		}
		RequestFrame(BoostVectors, victim);
		Midair_GiveHealth(victim);
		return Plugin_Changed;
	}
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && IsValidClient(victim) && IsPlayerAlive(victim) && g_damage[victim]) {
		//new weapon = GetEntProp(victim, Prop_Send, "m_iItemDefinitionIndex");
		if(attacker != victim){
			if ((damagetype & DMG_BLAST) == DMG_BLAST || (damagetype & DMG_TIMEBASED) == DMG_TIMEBASED)
			{
				damage = 0.0;
				RequestFrame(BoostVectors, victim);
			}
			damage = 750.0;
			return Plugin_Changed;
		}
		if(attacker == victim){
			new CurrentHealth2 = GetPlayerHealth(victim);
			if(CurrentHealth2 <= 10){
				SetEntityHealth(victim, 250);
			}
		}
	}
	return Plugin_Continue;
}
public Midair_GiveHealth(iClient) {
	if (IsValidClient(iClient) && IsPlayerAlive(iClient)) {
		SetEntityHealth(iClient, 200);	
	}
}
GetPlayerHealth( entity, bool:maxHealth=false )
{
	if ( maxHealth ) {
		return GetEntProp( entity, Prop_Send, "m_iMaxHealth" );
	}
	return GetEntProp( entity, Prop_Send, "m_iHealth" );
}
public OnClientPutInServer(client)
{
	if(g_bmaGameEnable){
		SDKHook(client, SDKHook_PostThink, HeightHook);
		SDKHook(client, SDKHook_OnTakeDamage, Refill_OnTakeDamageClient);
	}
}
public event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(iClient) && (g_bmaGameEnable)){
		new TFClassType:iClass = TF2_GetPlayerClass(iClient);
		if (!(iClass == TFClass_DemoMan || iClass == TFClass_Soldier || iClass == TFClassType:TFClass_Unknown))
		{
			maclass = GetRandomInt(1, 2);
			if(maclass == 1){
				TF2_SetPlayerClass(iClient, TFClass_Soldier, false, true);
			}
			if(maclass == 2){
				TF2_SetPlayerClass(iClient, TFClass_DemoMan, false, true);
			}
			TF2_RespawnPlayer(iClient);
		}
		if(iClass == TFClass_DemoMan){
			maclass = 2;
			TF2_SetPlayerClass(iClient, TFClass_DemoMan, false, true);
		}
		if(iClass == TFClass_Soldier){
			maclass = 1;
			TF2_SetPlayerClass(iClient, TFClass_Soldier, false, true);
		}
		g_ma_bPlayerJumped[iClient] = false;
		TF2_RemoveWeaponSlot(iClient, 0);
		TF2_RemoveWeaponSlot(iClient, 1);
		if(maclass == 1){
			TF2Items_GiveWeapon(iClient, 18);
			RefillAmmo(iClient);
			//RemoveSlot2wearable(iClient);
			new weapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary); //#include <tf2_stocks> to use the TFWeaponSlot enum)
			if (IsValidEntity(weapon))
			{
				SetEntProp(weapon, Prop_Data, "m_iClip1", 8);
			}
		}
		if(maclass == 2){
			TF2Items_GiveWeapon(iClient, 19);
			TF2Items_GiveWeapon(iClient, 20);
			RefillAmmo(iClient);
		}
	}
}
public event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (iClient <= 0) return false;
	g_ma_bPlayerJumped[iClient] = false;
	return true;

}
public OnClientDisconnect(iClient)
{
	if(g_bmaGameEnable){
		SDKUnhook(iClient, SDKHook_OnTakeDamage, Refill_OnTakeDamageClient);
		SDKUnhook(iClient, SDKHook_PreThink, HeightHook);
		g_ma_bPlayerJumped[iClient] = false;
	}
}
stock RefillAmmo(i)
{
	if(ammoOffset != -1)
	{
		if(maclass == 1){
			SetEntData(i, ammoOffset +4, 450);
		}
		if(maclass == 2){
			SetEntData(i, ammoOffset +4, 450);
			SetEntData(i, ammoOffset +8, 450);
		}
	}
}
stock bool:IsValidClient(iClient) {
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}
public OnMapEnd()
{
	ServerCommand("ma_gamedescription 0.0");
}
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem) 
{
	switch(iItemDefinitionIndex) 
	{
		case 444: return Plugin_Handled;
		case 133: return Plugin_Handled;
	} 
	return Plugin_Continue;
}
public BoostVectors(client)
{
	//new client = GetClientOfUserId(userid);
	new Float:vecClient[3];
	new Float:vecBoost[3];

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecClient);

	vecBoost[0] = vecClient[0] * 1.0;
	vecBoost[1] = vecClient[1] * 1.0;
	if(vecClient[2] > 0)
	{
		vecBoost[2] = vecClient[2] * 2.1;
	} else {
		vecBoost[2] = vecClient[2];
	}

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecBoost);
} 