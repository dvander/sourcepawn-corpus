//Includes:
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>
#include <clientprefs>
#include emitsoundany.inc
#pragma newdecls required
#define PLUGIN_VERSION "1.5"
#define PLAYER		  "player"


ConVar pb_method;
ConVar pb_enable;
ConVar pb_info;
ConVar g_bAdminOnly;
ConVar g_bNoTower;
ConVar pb_nopiggyred;
ConVar pb_nopiggyblu;
ConVar pb_enabledDefault;
ConVar pb_multi_piggy;
int g_bNoPiggy[MAXPLAYERS+1] = 0;
bool g_bNoSpam[MAXPLAYERS+1] = false;
Handle g_hClientCookieNopiggy = INVALID_HANDLE;
char infoText[512];
int g_offsCollisionGroup;
int g_piggy[MAXPLAYERS+1];
int g_nopiggy[MAXPLAYERS+1];
int LastUsed[MAXPLAYERS+1];
int g_piggy_victim[MAXPLAYERS+1];


public Plugin myinfo = {
	name = "Piggyback",
	author = "Mecha the Slag, TonyBaretta",
	description = "Allows players to piggyback another player!",
	version = PLUGIN_VERSION,
	url = "http://mechaware.net/"
};
public void OnPluginStart() {
	char game[32];
	GetGameFolderName(game, sizeof(game));
	Format(infoText, sizeof(infoText), "{green}[Piggyback]{default}You can {green}piggyback teammates {default}by {green}right-clicking {default}them with your {green}melee out!{default} to {green}jump off {default} press {green}jump");
	HookEvent("player_spawn", Player_Spawn, EventHookMode_Pre);
	HookEvent("player_death", Player_Death, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	g_bNoTower = CreateConVar("pb_notower", "1", "prevent towers of players");
	g_bAdminOnly = CreateConVar("pb_adminonly", "0", "Enable piggybacking for admin only");
	pb_method = CreateConVar("pb_method", "0", "Method to handle a piggybacking player. 1 = force view, 0 = do nothing (inaccurate aim)");
	pb_enable = CreateConVar("pb_enable", "1", "Enable piggybacking");
	RegConsoleCmd("sm_pdrop", Command_Drop);
	pb_enabledDefault = CreateConVar("pb_enabledDefault", "1", "Default piggybacking setting");
	pb_multi_piggy = CreateConVar("pb_multi_piggy", "0", "Allow infinite victims (only 1 if disabled)");
	pb_nopiggyred = CreateConVar("pb_nopiggyred", "0", "Disable piggybacking for red team");
	pb_nopiggyblu = CreateConVar("pb_nopiggyblu", "0", "Disable piggybacking for blu team");
	RegConsoleCmd("sm_piggy", CMD_ShowPBPrefsMenu);
	g_hClientCookieNopiggy = RegClientCookie("Piggyback_Ride", "piggybackride on / off ", CookieAccess_Private);
	SetCookieMenuItem(PBPrefSelected,0,"Piggyback Ride Menu");
	pb_info = CreateConVar("pb_info", "120.0", "Time interval in seconds between notifications (0 for none)");
	CreateConVar("pbr_csgo_version", PLUGIN_VERSION, "Piggyback Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	if (pb_info.FloatValue > 0.0) CreateTimer(pb_info.FloatValue, Notification);
	g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	for (int i = 0; i <= MaxClients; i++) {
		g_piggy[i] = -1;
		g_piggy_victim[i] = -1;
		g_nopiggy[i] = -1;
	}
}
stock void PrintToAdmins(char[] message, char[] flags)
{
  for (int x = 1; x <= MaxClients; x++)
  {
    if (IsValidClient(x) && IsValidAdmin(x, flags))
      CPrintToChat(x, message);
  }
}
stock bool IsValidAdmin(int client, const char[] flags)
{
    if (CheckCommandAccess(client, "piggyback_admin_override", ADMFLAG_CUSTOM1, true))
        return true;
    return false;
}
public Action Notification(Handle hTimer) {
	if (pb_info.FloatValue > 0.0) {
		if (pb_enable.BoolValue) 
		{
			if (g_bAdminOnly.BoolValue)
			{	
				PrintToAdmins(infoText,"s"); 
			}
			else
				CPrintToChatAll(infoText);
		}
		CreateTimer(pb_info.FloatValue, Notification);
	}
	return Plugin_Stop;
}
public Action Command_Piggy(int client){
	if(IsValidClient(client) && (pb_enable.BoolValue)){
		if(g_bNoPiggy[client]){
			g_nopiggy[client] = -1;
			CPrintToChat(client, "{orange}[Piggyback] {default}Piggyback ride {green}Enabled");
			g_bNoPiggy[client] = 0;
		}
		else{
			CPrintToChat(client, "{orange}[Piggyback] {default}Piggyback ride is {green}Enabled{default}, to {red}Disable {default}type {orange}!piggy");
		}
	}
}
public Action Command_Drop(int client, int args){
	if(IsValidClient(client) && (pb_enable.BoolValue)){
		if(g_piggy_victim[client] == client){
			for (int iClient = 1; iClient <= MaxClients; iClient++){
				if (IsValidClient(iClient) && g_piggy[iClient] == client){
					RemovePiggy(iClient);
					CPrintToChat(iClient,"{green}[Piggyback] {teamcolor}%N {default}doesn't want a piggyback ride with you", client);
					CPrintToChat(client,"{green}[Piggyback] {default}You Dropped {teamcolor}%N {default}", iClient);
				}
			}
			g_piggy_victim[client] = -1;
			g_piggy[client] = -1;
		}
		else{
			CPrintToChat(client,"{green}[Piggyback] {default}No players on your back");
		}
	}
}
public Action Command_NoPiggy(int client){
	if(IsValidClient(client) && (pb_enable.BoolValue)){
		for (int iClient = 1; iClient <= MaxClients; iClient++){
			if (IsClientInGame(iClient) && g_piggy[iClient] == client){
				RemovePiggy(iClient);
				CPrintToChatEx(iClient,client,"{orange}[Piggyback] {teamcolor}%N {default}doesn't want a piggyback ride with you", client);
			}
		}
		RemovePiggy(client);
		g_piggy_victim[client] = -1;
		g_piggy[client] = -1;
		if(!g_bNoPiggy[client]){
			CPrintToChat(client, "{orange}[Piggyback] {default}Piggyback ride {red}Disabled");
			g_nopiggy[client] = client;
			g_bNoPiggy[client] = 1;
		}
		else{
			CPrintToChat(client, "{orange}[Piggyback]{default} Piggyback ride is{red} Disabled{default} , if you want {green}Enable {yellow}piggyback ride{default}type {orange}!settings");
		}
	}
}
public void Player_Spawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && g_piggy[client]) {
		RemovePiggy(client);
		g_piggy[client] = -1;
		g_piggy_victim[client] = -1;
	}
	if(IsValidClient(client)){
		g_piggy[client] = -1;
		g_piggy_victim[client] = -1;
	}
}
public void Event_RoundStart(Event event,const char[] name,bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)){
			if (g_piggy[i] == i){ 
				RemovePiggy(i);
				//AcceptEntityInput(i, "ClearParent");
				CS_RespawnPlayer(i);
				g_piggy[i] = -1;
				g_piggy_victim[i] = -1;
			}
		}
    }	
}
public void Event_RoundEnd(Event event,const char[] name,bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)){
			if (g_piggy[i] == i){ 
				RemovePiggy(i);
				//CS_RespawnPlayer(i);
				g_piggy[i] = -1;
				g_piggy_victim[i] = -1;
			}
		}
    }	
}
public void Player_Death(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(g_piggy_victim[client])) {
		for (int iClient = 1; iClient <= MaxClients; iClient++){
			if (IsValidClient(iClient) && g_piggy[iClient] == client){
				RemovePiggy(iClient);
			}
		}
		g_piggy[client] = -1;
		g_piggy_victim[client] = -1;
	}
}

public void OnClientPutInServer(int client) {
	if (pb_enable.BoolValue){
		SDKHook(client, SDKHook_PreThink, OnPreThink);
		g_piggy[client] = -1;
		g_piggy_victim[client] = -1;
		g_nopiggy[client] = -1;
		//g_bNoPiggy[client] = 0;
		LoadClientCookiesFor(client);
	}
}
public int LoadClientCookiesFor(int client)
{
	char buffer[5];
	GetClientCookie(client,g_hClientCookieNopiggy,buffer,5);
	if(!StrEqual(buffer,""))
	{
		g_bNoPiggy[client] = StringToInt(buffer);
		if(g_bNoPiggy[client]) g_nopiggy[client] = client;
		else 
		g_bNoPiggy[client] = 0;
	}
	if(StrEqual(buffer,"")){
		g_bNoPiggy[client] = !pb_enabledDefault.BoolValue;
		g_nopiggy[client] = (pb_enabledDefault.BoolValue ? client : -1);
	}
}
public void OnClientDisconnect(int client)
{
	if (pb_enable.BoolValue){
		if(IsValidClient(client))
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++){
				if (IsClientInGame(iClient) && g_piggy[iClient] == client){
					RemovePiggy(iClient);
				}
			}
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		}
	}
}
public Action OnPreThink(int client) {
	int iButtons = GetClientButtons(client);
 	if (pb_nopiggyred.BoolValue){
		if(IsValidClient(client) && GetClientTeam(client) == 2){
			return;		
		}
	}
	if (pb_nopiggyblu.BoolValue){
		if(IsValidClient(client) && GetClientTeam(client) == 3){
			return;			
		}
	} 
	if (g_bAdminOnly.BoolValue)
	{
		if (CheckCommandAccess(client, "piggyback_admin_override", ADMFLAG_CUSTOM1, true))
		{
			if ((iButtons & IN_ATTACK2) && (pb_enable.BoolValue)) {
				char sWeapon[128];
				GetClientWeapon(client, sWeapon, sizeof(sWeapon));
				if (StrContains(sWeapon, "knife", false) != -1){
					if(g_bNoSpam[client]){
						if(g_piggy[client] == -1 && g_nopiggy[client] == -1){
							if (IsValidClient(client)){
								int currentTimevictim = GetTime();
								if (currentTimevictim - LastUsed[client] < 3)return;
								LastUsed[client] = GetTime();
								g_bNoSpam[client] = false;
							}
						}
					}
					TraceTarget(client);
				}
			}
		}
	}
	if (!g_bAdminOnly.BoolValue){	
		if ((iButtons & IN_ATTACK2) && (pb_enable.BoolValue)) {
			char sWeapon[128];
			GetClientWeapon(client, sWeapon, sizeof(sWeapon));
			if (StrContains(sWeapon, "knife", false) != -1){ 
				if(g_bNoSpam[client]){
					if(g_piggy[client] == -1 && g_nopiggy[client] == -1){
						if (IsValidClient(client)){
							int currentTimevictim = GetTime();
							if (currentTimevictim - LastUsed[client] < 3)return;
							LastUsed[client] = GetTime();
							g_bNoSpam[client] = false;
						}
					}
				}
				TraceTarget(client);
			}
		}
	}
	
	if (g_piggy[client] > -1) {
		if (pb_method.IntValue == 1) {
			float vecClientEyeAng[3];
			GetClientEyeAngles(g_piggy[client], vecClientEyeAng);
			TeleportEntity(client, NULL_VECTOR, vecClientEyeAng, NULL_VECTOR);
		}
		if (iButtons & IN_USE) {
			RemovePiggy(client);
		}
		if (IsValidClient(g_piggy[client]) && !IsPlayerAlive(g_piggy[client])) {
			RemovePiggy(client);
		}
/* 		float vPOrigin[3]; float vOrigin[3]; float vVelocity[3];
		if(g_piggy[client] > -1)
		{
			GetClientAbsOrigin(g_piggy[client], vOrigin);
			GetClientAbsOrigin(client, vPOrigin);
			vOrigin[2] += 70.0;
			GetEntPropVector(g_piggy[client], Prop_Data, "m_vecVelocity", vVelocity);
			float min[3], max[3];
			
			min[0] = vOrigin[0] - 256.0;
			min[1] = vOrigin[1] - 256.0;
			min[2] = vOrigin[2] - 128.0;
			
			max[0] = vOrigin[0] + 256.0;
			max[1] = vOrigin[1] + 256.0;
			max[2] = vOrigin[2] + 512.0; 
			TeleportEntity(client, vOrigin, NULL_VECTOR, vVelocity);
		} */
	}
}

public int Piggy(int entity, int other) {
	//Classnames of entities
	char otherName[64];
	char classname[64];

	GetEdictClassname(entity, classname, sizeof(classname));
	GetEdictClassname(other, otherName, sizeof(otherName));
	
	if (strcmp(classname, PLAYER) == 0 && strcmp(otherName, PLAYER) == 0 && entity != other && GetClientTeam(entity) == GetClientTeam(other) && IsPlayerAlive(entity) && IsPlayerAlive(other) && (g_piggy[entity] <= -1) && (g_piggy[other] <= -1) && (g_piggy[other] != entity)) {
		float PlayerVec[3];
		float PlayerVec2[3];
		float vecClientEyeAng[3];
		float vecClientVel[3];
		vecClientVel[0] = 0.0;
		vecClientVel[1] = 0.0;
		vecClientVel[2] = 0.0;
		GetClientAbsOrigin(entity, PlayerVec2);
		GetClientAbsOrigin(other, PlayerVec);
		GetClientEyeAngles(other, vecClientEyeAng); // Get the angle the player is looking
		float distance;
		distance = GetVectorDistance(PlayerVec2, PlayerVec, true);
		
		if(distance <= 20000.0) {
			if(g_piggy_victim[other] != -1 && !pb_multi_piggy.BoolValue)
			{
				CPrintToChat(entity, "{orange}[Piggyback] {default}You {red}can't {yellow}piggyback teammates {default}when they have someone on their back");		
			}
			else
			{	
				if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{orange}[Piggyback] {teamcolor}%N {default}is on your back", entity);
				if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{default}Commands: {yellow}!pdrop {default}to drop {teamcolor}%N {default}from your back, {orange}!piggy {default}to change your settings", entity);
				if (IsPlayerAlive(other)) CPrintToChatEx(entity, other, "{orange}[Piggyback] {default}You are piggybacking {teamcolor}%N ", other);
				//SetEntData(entity, g_offsCollisionGroup, 2, 4, true);
				SetEntData(entity, g_offsCollisionGroup, 5, 4, true);
					
				PlayerVec[2] += 20;
				TeleportEntity(entity, PlayerVec, vecClientEyeAng, vecClientVel);
				
				char tName[32];
				GetEntPropString(other, Prop_Data, "m_iName", tName, sizeof(tName));
				DispatchKeyValue(entity, "parentname", tName);
					
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", other, other, 0);
				SetVariantString("head"); 
				AcceptEntityInput(entity, "SetParentAttachment", other, other, 0);
				SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.2);
				SetEntityMoveType(entity, MOVETYPE_NONE);
				g_piggy_victim[other] = other;
				g_piggy[entity] = other;
				g_bNoSpam[entity] = true;
			}
		}
	}
}

public int RemovePiggy(int entity) {
	if(!IsValidEntity(entity))return;
	//Classnames of entities
	char classname[64];

	GetEdictClassname(entity, classname, sizeof(classname));
	
	if (strcmp(classname, PLAYER) == 0 && (g_piggy[entity] > -1)) {
	
		int other = g_piggy[entity];
	
		if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{orange}[Piggyback] {teamcolor}%N {default}jumped off your back", entity);
		if (IsPlayerAlive(other)) CPrintToChatEx(entity, other, "{orange}[Piggyback] {default}You jumped off from {teamcolor}%N ", other);
		AcceptEntityInput(entity, "SetParent", -1, -1, 0);
		SetEntityMoveType(entity, MOVETYPE_WALK);
		
		g_piggy[entity] = -1;
		g_piggy_victim[other] = -1;
		
		if (IsPlayerAlive(entity)) {
			float PlayerVec[3];
			float vecClientEyeAng[3];
			float vecClientVel[3];
			vecClientVel[0] = 0.0;
			vecClientVel[1] = 0.0;
			vecClientVel[2] = 0.0;
			GetClientAbsOrigin(other, PlayerVec);
			GetClientEyeAngles(other, vecClientEyeAng); // Get the angle the player is looking
			TeleportEntity(entity, PlayerVec, NULL_VECTOR, vecClientVel);
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.0);
			SetEntData(entity, g_offsCollisionGroup, 5, 4, true);
		}
	}
}

public int TraceTarget(int client) {
	char classname[64];
	float PlayerVec[3];
	float PlayerVec2[3];
	float vecClientEyePos[3];
	float vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);// Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng); // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if (TR_DidHit(INVALID_HANDLE)) {
		int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		GetEdictClassname(TRIndex, classname, sizeof(classname));
		if (strcmp(classname, PLAYER) == -1)return;
		if (strcmp(classname, PLAYER) == 0){
			GetClientAbsOrigin(client, PlayerVec2);
			GetClientAbsOrigin(TRIndex, PlayerVec);
			float distance;
			distance = GetVectorDistance(PlayerVec2, PlayerVec, true);
			if(distance <= 20000.0){
				if(g_nopiggy[client] > -1){
					if (IsValidClient(g_nopiggy[client])){
						char nope_text_you[256];
						char nope_engi[256];
						int currentTimevictim = GetTime();
						if (currentTimevictim - LastUsed[g_nopiggy[client]] < 2)return;
						LastUsed[g_nopiggy[client]] = GetTime();
						Format(nope_text_you, sizeof(nope_text_you), "{green}[Piggyback]{default}Piggyback ride{red} disabled {default} type {green}!piggy {default}to {green}enable");
						CPrintToChat(g_nopiggy[client],"%s", nope_text_you);
						Format(nope_engi,sizeof(nope_engi),"player/vo/seal/negative02.wav");
						PrecacheSoundAny(nope_engi, true);
						EmitSoundToClientAny(g_nopiggy[client], nope_engi, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
						return;
					}
				}
				if (g_bNoTower.BoolValue){	
					if(g_piggy_victim[client] > -1){
						if (IsValidClient(g_piggy_victim[client]) && g_piggy_victim[client] > -1){
							char nope_text[256];
							char nope_engi[256];
							int currentTimevictim = GetTime();
							if (currentTimevictim - LastUsed[client] < 2)return;
							LastUsed[client] = GetTime();
							Format(nope_text, sizeof(nope_text), "{green}[Piggyback]{default}You {red}can't {yellow}piggyback teammates {default}when you have someone on your back, type {yellow}!drop {default}, to drop him");
							CPrintToChat(client,"%s", nope_text);
							Format(nope_engi,sizeof(nope_engi),"player/vo/seal/negative02.wav");
							PrecacheSoundAny(nope_engi, true);
							EmitSoundToClientAny(g_piggy_victim[client], nope_engi, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
							return;
						}
					}
				}
				if(g_nopiggy[client] > 1){
					int currentTimevictim = GetTime();
					if (currentTimevictim - LastUsed[client] < 2)return;
					LastUsed[client] = GetTime();
					char block_text[256];
					Format(block_text, sizeof(block_text), "{green}[Piggyback]{default}You {teamcolor}can't {green} piggaback {teamcolor}%N{default} {default},he has{teamcolor} disabled {green}piggyback ride", g_nopiggy[client]);
					CPrintToChat(client, block_text);
					char nope_engi[256];
					Format(nope_engi,sizeof(nope_engi),"player/vo/seal/negative02.wav");
					PrecacheSoundAny(nope_engi, true);
					EmitSoundToClientAny(client, nope_engi, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
					return;
				}
				g_bNoSpam[client] = true;
				Piggy(client, TRIndex);
			}
		}
	}
}

public bool TraceRayDontHitSelf(int entity, int mask, any data) {
	if(entity == data)	{ // Check if the TraceRay hit the itself.
		return false;	// Don't let the entity be hit
	}
	return true;	// It didn't hit itself
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client)) return false;
	return true;
}
public Action CMD_ShowPBPrefsMenu(int client,int args)
{
	ShowPBMenu(client);
	return Plugin_Handled;
}

// Make the menu or nothing will show
public Menu ShowPBMenu(int client)
{
	Menu menu = CreateMenu(MenuHandlerPB);
	SetMenuTitle(menu, "PiggyBack Ride Menu");
	if(g_bNoPiggy[client] == 0)
	{
		AddMenuItem(menu, "g_bNoPiggy[client] == 1", "Disable Piggyback Ride");
	}
	if(g_bNoPiggy[client] == 1)
	{
		AddMenuItem(menu, "g_bNoPiggy[client] == 0", "Enable Piggyback Ride");
	}
	SetMenuExitButton(menu,true);
	DisplayMenu(menu,client,20);
}

// Check what's been selected in the menu
public int MenuHandlerPB(Menu menu,MenuAction action,int param1,int param2)
{
	if(action == MenuAction_Select)	
	{
		if(param2 == 0)
		{
			if(g_bNoPiggy[param1] == 0)
			{
				PrintToChat(param1,"PiggyBack Disabled");
				//g_bNoPiggy[param1] = true;
				Command_NoPiggy(param1);
				
			}
			else
			{
				PrintToChat(param1,"PiggyBack Enabled");
				//g_bNoPiggy[param1] = false;
				Command_Piggy(param1);
			}
		}
		char buffer[5];
		IntToString(g_bNoPiggy[param1],buffer,5);
		SetClientCookie(param1,g_hClientCookieNopiggy,buffer);
		CMD_ShowPBPrefsMenu(param1,0);
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public int PBPrefSelected(int client,CookieMenuAction action,any info,char[] buffer,int maxlen)
{
	if(action == CookieMenuAction_SelectOption)
	{
		ShowPBMenu(client);
	}
}