//Includes:
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#pragma newdecls required

#define PLUGIN_VERSION "1.5"
#define PLAYER		  "player"

int g_piggy[MAXPLAYERS+1];
int g_nopiggy[MAXPLAYERS+1];
int LastUsed[MAXPLAYERS+1];
int g_piggy_victim[MAXPLAYERS+1];
Handle LateTimers[MAXPLAYERS+1];
ConVar pb_method;
ConVar pb_enable;
ConVar pb_info;
ConVar g_bAdminOnly;
ConVar g_bNoTower;
ConVar pb_nopiggyred;
ConVar pb_nopiggyblu;
ConVar pb_enabledDefault;
ConVar pb_multi_piggy;
Handle g_hClientCookieNopiggy = INVALID_HANDLE;
int g_bNoPiggy[MAXPLAYERS+1] = 0;
bool g_bNoSpam[MAXPLAYERS+1] = false;
bool g_b_DropCommand[MAXPLAYERS+1] = false;
char infoText[512];
int g_offsCollisionGroup;
bool enabled = false;

static const char TF2Weapons[][]={"tf_weapon_fists", "tf_weapon_shovel", "tf_weapon_bat", "tf_weapon_fireaxe", "tf_weapon_bonesaw", "tf_weapon_bottle", "tf_weapon_sword", "tf_weapon_club", "tf_weapon_wrench"};	 

public Plugin myinfo = {
	name = "Piggyback",
	author = "TonyBaretta",
	description = "Allows players to piggyback another player!",
	version = PLUGIN_VERSION,
	url = "http://mechaware.net/"
};

public void OnPluginStart() {

	Format(infoText, sizeof(infoText), "{orange}[Piggyback] {default}You can {green}piggyback teammates {default}by {green}right-clicking {default}them with your {green}melee out! {default}To {green}jump off, {default}press {green}jump");
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_death", Player_Death);
	HookEvent("teamplay_round_start", Event_Roundstart);
	HookEvent("round_end", Event_RoundEnd);
	g_bAdminOnly = CreateConVar("pb_adminonly", "1", "Enable piggybacking for admin only");
	g_bNoTower = CreateConVar("pb_notower", "1", "prevent towers of players");
	pb_method = CreateConVar("pb_method", "2", "Method to handle a piggybacking player. 1 = force view, 2 = disable shooting, 0 = do nothing (inaccurate aim)");
	pb_enable = CreateConVar("pb_enable", "1", "Enable piggybacking");
	pb_enabledDefault = CreateConVar("pb_enabledDefault", "1", "Default piggybacking setting");
	pb_multi_piggy = CreateConVar("pb_multi_piggy", "0", "Allow infinite victims (only 1 if disabled)");
	pb_info = CreateConVar("pb_info", "300.0", "Time interval in seconds between notifications (0 for none)");
	RegConsoleCmd("joinclass", Command_JoinClass);
	pb_nopiggyred = CreateConVar("pb_nopiggyred", "0", "Disable piggybacking for red team");
	pb_nopiggyblu = CreateConVar("pb_nopiggyblu", "0", "Disable piggybacking for blu team");
	RegConsoleCmd("sm_pdrop", Command_Drop);
	RegConsoleCmd("sm_piggy", CMD_ShowPBPrefsMenu);
	g_hClientCookieNopiggy = RegClientCookie("Piggyback_Ride", "piggybackride on / off ", CookieAccess_Private);
	SetCookieMenuItem(PBPrefSelected,0,"Piggyback Ride Menu");
	CreateConVar("pbr_version", PLUGIN_VERSION, "Piggyback Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	if (pb_info.FloatValue > 0.0) CreateTimer(pb_info.FloatValue, Notification);
	g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	for (int i = 0; i <= MaxClients; i++) {
		g_piggy[i] = -1;
		g_piggy_victim[i] = -1;
		//g_nopiggy[i] = -1;
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
public void Player_Spawn(Event event, const char[] name, bool dontBroadcast) {
	if (pb_enable.BoolValue){
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(IsValidClient(client) && g_piggy[client]) {
			RemovePiggy(client);
		}
	}
}
public void Event_Roundstart(Event event,const char[] name,bool dontBroadcast)
{
	if (pb_enable.BoolValue){
		enabled = true;
		for (int i = 1; i <= MaxClients; i++) {
			if (g_piggy[i] == i){ 
				AcceptEntityInput(i, "ClearParent");
				TF2_RespawnPlayer(i);
				g_piggy[i] = -1;
				g_piggy_victim[i] = -1;
			}
		}
	}
}
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    enabled = false;
    for (int i = 0; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && g_piggy[i])
        {
            RemovePiggy(i);
        }
    }
    return Plugin_Continue;
}
public Action Command_JoinClass(int client, int args){
	if(IsValidClient(client) && (pb_enable.BoolValue)){
		RemovePiggy(client);
		g_piggy[client] = -1;
		g_piggy_victim[client] = -1;
	}
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
				if (IsClientInGame(iClient) && g_piggy[iClient] == client){
					g_b_DropCommand[client] = true;
					RemovePiggy(iClient);
					CPrintToChatEx(iClient,client,"{orange}[Piggyback] {teamcolor}%N {default}doesn't want a piggyback ride with you", client);
					CPrintToChatEx(client,iClient,"{orange}[Piggyback] {default}You Dropped {teamcolor}%N", iClient);
				}
			}
			g_piggy_victim[client] = -1;
			g_piggy[client] = -1;
		}
		else{
			CPrintToChat(client,"{orange}[Piggyback] {default}No players on your back");
		}
	}
}
public Action Command_NoPiggy(int client){
	if(IsValidClient(client) && (pb_enable.BoolValue)){
		for (int iClient = 1; iClient <= MaxClients; iClient++){
			if (IsClientInGame(iClient) && g_piggy[iClient] == client){
				g_b_DropCommand[client] = true;
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
public void Player_Death(Event event, const char[] name, bool dontBroadcast) {
	if (pb_enable.BoolValue){
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(IsValidClient(client) && g_piggy[client]) {
			RemovePiggy(client);
		}
		if(IsValidClient(client)){
			g_piggy[client] = -1;
			g_piggy_victim[client] = -1;
		}
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
		if (LateTimers[client] != null)
		{
			KillTimer(LateTimers[client]);
			LateTimers[client] = null;
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
				char Weapon[128];
				GetClientWeapon(client, Weapon, sizeof(Weapon));
				for (int i = 0; i < sizeof(TF2Weapons); i++) 
				{
					if (StrEqual(Weapon,TF2Weapons[i],false))
					{
						if(g_bNoSpam[client]){
							if (IsValidClient(client)){
								int currentTimevictim = GetTime();
								if (currentTimevictim - LastUsed[client] < 3)return;
								LastUsed[client] = GetTime();
								g_bNoSpam[client] = false;
							}
						
						}
						else
						{
							TraceTarget(client);
						}
					}
				}
			}
		}
	}
	if (!g_bAdminOnly.BoolValue){	
		if ((iButtons & IN_ATTACK2) && (pb_enable.BoolValue)) {
			char Weapon[128];
			GetClientWeapon(client, Weapon, sizeof(Weapon));
			for (int i = 0; i < sizeof(TF2Weapons); i++) {
				if (StrEqual(Weapon,TF2Weapons[i],false)){
					if(g_bNoSpam[client]){
						if (IsValidClient(client)){
							int currentTimevictim = GetTime();
							if (currentTimevictim - LastUsed[client] < 3)return;
							LastUsed[client] = GetTime();
							g_bNoSpam[client] = false;
						}
					}
					else
					{
						TraceTarget(client);
					}
				}
			}
		}
	}
	
	if (g_piggy[client] > -1) {
		if (pb_method.IntValue == 1) {
			float vecClientEyeAng[3];
			GetClientEyeAngles(g_piggy[client], vecClientEyeAng);
			TeleportEntity(client, NULL_VECTOR, vecClientEyeAng, NULL_VECTOR);
		}
		if (pb_method.IntValue == 2) {
			if ((iButtons & IN_ATTACK2) || (iButtons & IN_ATTACK))
			{
				iButtons &= ~IN_ATTACK;
				iButtons &= ~IN_ATTACK2;
				SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
			}
		}
		if (iButtons & IN_JUMP) {
			RemovePiggy(client);
		}
		if (IsValidClient(g_piggy[client]) && !IsPlayerAlive(g_piggy[client])) {
			RemovePiggy(client);
		}
		float vPOrigin[3]; float vOrigin[3]; float vVelocity[3];
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
		}
	}
}


public int Piggy(int entity, int other) {
	//Classnames of entities
	char otherName[64];
	char classname[64];

	GetEdictClassname(entity, classname, sizeof(classname));
	GetEdictClassname(other, otherName, sizeof(otherName));
	
	if (strcmp(classname, PLAYER) == 0 && strcmp(otherName, PLAYER) == 0 && entity != other && GetClientTeam(entity) == GetClientTeam(other) && IsPlayerAlive(entity) && IsPlayerAlive(other) && (g_piggy[entity] <= -1) && (g_piggy[other] <= -1) && (g_piggy[other] != entity)) {
		if ((TF2_GetPlayerClass(other) != TFClass_Spy)) {
			float PlayerVec[3];
			float PlayerVec2[3];
			float vecClientEyeAng[3];
			float vecClientVel[3];
			vecClientVel[0] = 0.0;
			vecClientVel[1] = 0.0;
			vecClientVel[2] = 0.0;
			GetClientAbsOrigin(entity, PlayerVec2);
			GetClientAbsOrigin(other, PlayerVec);
			GetClientEyeAngles(other, vecClientEyeAng);
			float distance;
			distance = GetVectorDistance(PlayerVec2, PlayerVec, true);
			
			if(distance <= 20000.0) 
			{
                if(!enabled)
                {
                    CPrintToChat(entity, "{orange}[Piggyback] {default}Piggyback is disabled until the next round starts");    
                }
                else if(GetEntityMoveType(entity) == MOVETYPE_NONE)
                {
                    CPrintToChat(entity, "{orange}[Piggyback] {default}You {red}can't {yellow}piggyback teammates {default}when you are frozen or before a round starts");     
                }
                else if(g_piggy_victim[other] != -1 && !pb_multi_piggy.BoolValue)
                {
                    CPrintToChat(entity, "{orange}[Piggyback] {default}You {red}can't {yellow}piggyback teammates {default}when they have someone on their back");     
                }
				else
				{
					if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{orange}[Piggyback] {teamcolor}%N {default}is on your back", entity);
					if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{default}Commands: {yellow}!pdrop {default}to drop {teamcolor}%N {default}from your back, {orange}!piggy {default}to change your settings", entity);
					if (IsPlayerAlive(other)) CPrintToChatEx(entity, other, "{orange}[Piggyback] {default}You are piggybacking {teamcolor}%N ", other);
					TFClassType iClass__ent = TF2_GetPlayerClass(entity);
					TFClassType iClass__other = TF2_GetPlayerClass(other);
					PlaySoundToClient(entity, other, iClass__ent, iClass__other);
					//PlaySoundToClient(other, entity, iClass__other, iClass__entity);
					
					SetEntData(entity, g_offsCollisionGroup, 2, 4, true);
					
					PlayerVec[2] += 20;
					TeleportEntity(entity, PlayerVec, vecClientEyeAng, vecClientVel);
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.2);
					SetEntityMoveType(entity, MOVETYPE_NONE);
					g_piggy_victim[other] = other;
					g_piggy[entity] = other;
				}
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
		TFClassType iClass__ent = TF2_GetPlayerClass(entity);
		TFClassType iClass__other = TF2_GetPlayerClass(other);
		if(g_b_DropCommand[other]){
			PlaySoundToClientNo(entity, other, iClass__ent, iClass__other);
			g_b_DropCommand[other] = false;
		}
		else{
			PlaySoundToClientEnd(entity, other, iClass__ent, iClass__other);
		}

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
	GetClientEyePosition(client, vecClientEyePos); // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng); // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if (TR_DidHit(INVALID_HANDLE)) 
	{
		int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		GetEdictClassname(TRIndex, classname, sizeof(classname));
		if (strcmp(classname, PLAYER) == -1)return;
		if (strcmp(classname, PLAYER) == 0){
			GetClientAbsOrigin(client, PlayerVec2);
			GetClientAbsOrigin(TRIndex, PlayerVec);
			float distance;
			distance = GetVectorDistance(PlayerVec2, PlayerVec, true);
			if(distance <= 20000.0)
			{
				if(g_bNoPiggy[TRIndex]){
					int currentTimevictim = GetTime();
					if (currentTimevictim - LastUsed[client] < 2)return;
					LastUsed[client] = GetTime();
					char block_text[256];
					Format(block_text, sizeof(block_text), "{orange}[Piggyback] {default}You {red}can't {yellow}piggyback {haunted}%N{default}, they have {red}disabled {yellow}piggyback ride", g_nopiggy[TRIndex]);
					CPrintToChat(client, block_text);
					return;
				}
				if(g_bNoPiggy[client]){
					if (IsValidClient(g_nopiggy[client])){
						char nope_text_you[256];
						char nope_engi[256];
						int currentTimevictim = GetTime();
						if (currentTimevictim - LastUsed[g_nopiggy[client]] < 2)return;
						LastUsed[g_nopiggy[client]] = GetTime();
						Format(nope_text_you, sizeof(nope_text_you), "{orange}[Piggyback] {default}Piggyback ride {red}disabled {default}type {green}!settings {default}to {green}enable");
						CPrintToChat(g_nopiggy[client],"%s", nope_text_you);
						Format(nope_engi,sizeof(nope_engi),"vo/engineer_no01.mp3");
						PrecacheSound(nope_engi, true);
						EmitSoundToClient(g_nopiggy[client], nope_engi, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
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
							Format(nope_text, sizeof(nope_text), "{orange}[Piggyback] {default}You {red}can't {yellow}piggyback teammates {default}when you have someone on your back, type {yellow}!pdrop {default} to drop them");
							CPrintToChat(client,"%s", nope_text);
							Format(nope_engi,sizeof(nope_engi),"vo/engineer_no01.mp3");
							PrecacheSound(nope_engi, true);
							EmitSoundToClient(g_piggy_victim[client], nope_engi, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
							return;
						}
					}
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
public bool TraceRayNoPlayers(int entity, int mask, any data) {
	if (entity == data || (entity >= 1 && entity <= MaxClients)) {
		return false;
	}
	return true;
}
public Action PlaySoundToClient(int client, int entity, TFClassType iClass__ent, TFClassType iClass__other){
	if(IsValidClient(client)){
		char s_Client_class[256];
		char s_victim_class[256];
		int i_client_sound_index = GetRandomInt(1,3);
		int i_Victim_sound_index = GetRandomInt(1,6);
		TFClassType	iClass = iClass__ent;
		TFClassType	iClass2 = iClass__other;
		if (iClass == TFClass_Scout)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/scout_go0%i.mp3", i_client_sound_index);
		}
		if (iClass == TFClass_Soldier)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/soldier_go0%i.mp3", i_client_sound_index);
		}
		if (iClass == TFClass_Pyro)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/pyro_go01.mp3");
		}
		if (iClass == TFClass_DemoMan)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/demoman_go0%i.mp3", i_client_sound_index);
		}
		if (iClass == TFClass_Heavy)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/heavy_go0%i.mp3", i_client_sound_index);
		}
		if (iClass == TFClass_Engineer)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/engineer_go0%i.mp3", i_client_sound_index);
		}
		if (iClass == TFClass_Medic)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/medic_go0%i.mp3", i_client_sound_index);
		}
		if (iClass == TFClass_Sniper)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/sniper_go0%i.mp3", i_client_sound_index);
		}
		if (iClass == TFClass_Spy)
		{
			Format(s_Client_class,sizeof(s_Client_class),"vo/spy_go0%i.mp3", i_client_sound_index);
		}
		//START OTHER PLAYER CLASS
		if (iClass2 == TFClass_Scout)
		{
			i_Victim_sound_index = GetRandomInt(1,5);
			Format(s_victim_class,sizeof(s_victim_class),"vo/scout_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_Soldier)
		{
			Format(s_victim_class,sizeof(s_victim_class),"vo/soldier_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_Pyro)
		{
			i_Victim_sound_index = GetRandomInt(1,2);
			Format(s_victim_class,sizeof(s_victim_class),"vo/pyro_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_DemoMan)
		{
			i_Victim_sound_index = GetRandomInt(1,7);
			Format(s_victim_class,sizeof(s_victim_class),"vo/demoman_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_Heavy)
		{
			Format(s_victim_class,sizeof(s_victim_class),"vo/heavy_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_Engineer)
		{
			i_Victim_sound_index = GetRandomInt(3,7);
			Format(s_victim_class,sizeof(s_victim_class),"vo/engineer_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_Medic)
		{
			Format(s_victim_class,sizeof(s_victim_class),"vo/medic_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_Sniper)
		{
			Format(s_victim_class,sizeof(s_victim_class),"vo/sniper_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if (iClass2 == TFClass_Spy)
		{
			i_Victim_sound_index = GetRandomInt(1,4);
			Format(s_victim_class,sizeof(s_victim_class),"vo/spy_battlecry0%i.mp3", i_Victim_sound_index);
		}
		if(IsValidClient(entity)){
			PrecacheSound(s_victim_class, true);
			EmitSoundToClient(entity, s_victim_class, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
			DataPack pack;
			LateTimers[entity] = CreateDataTimer(1.0, timer_playlate, pack);
			pack.WriteCell(entity);
			pack.WriteString(s_Client_class);	
		}		
		if(IsValidClient(client)){
			PrecacheSound(s_Client_class, true);
			EmitSoundToClient(client, s_Client_class, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
			DataPack pack;
			LateTimers[client] = CreateDataTimer(1.0, timer_playlate, pack);
			pack.WriteCell(client);
			pack.WriteString(s_victim_class);
		}
	}
}
public Action PlaySoundToClientEnd(int client, int entity, TFClassType iClass__ent, TFClassType iClass__other){
	if(IsValidClient(client)){
		char s_Client2_class[256];
		char s_victim2_class[256];
		int i_client2_sound_index = GetRandomInt(1,2);
		int i_Victim2_sound_index = GetRandomInt(1,2);
		TFClassType	iClass3 = iClass__ent;
		TFClassType	iClass4 = iClass__other;
		if (iClass3 == TFClass_Scout)
		{
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/scout_thanks0%i.mp3", i_client2_sound_index);
		}
		if (iClass3 == TFClass_Soldier)
		{
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/soldier_thanks0%i.mp3", i_client2_sound_index);
		}
		if (iClass3 == TFClass_Pyro)
		{
			i_client2_sound_index = 1;
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/pyro_thanks01.mp3");
		}
		if (iClass3 == TFClass_DemoMan)
		{
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/demoman_thanks0%i.mp3", i_client2_sound_index);
		}
		if (iClass3 == TFClass_Heavy)
		{
			i_client2_sound_index = GetRandomInt(1,3);
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/heavy_thanks0%i.mp3", i_client2_sound_index);
		}
		if (iClass3 == TFClass_Engineer)
		{
			i_client2_sound_index = 1;
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/engineer_thanks0%i.mp3", i_client2_sound_index);
		}
		if (iClass3 == TFClass_Medic)
		{
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/medic_thanks0%i.mp3", i_client2_sound_index);
		}
		if (iClass3 == TFClass_Sniper)
		{
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/sniper_thanks0%i.mp3", i_client2_sound_index);
		}
		if (iClass3 == TFClass_Spy)
		{
			i_client2_sound_index = GetRandomInt(1,3);
			Format(s_Client2_class,sizeof(s_Client2_class),"vo/spy_thanks0%i.mp3", i_client2_sound_index);
		}
		//START OTHER PLAYER CLASS
		if (iClass4 == TFClass_Scout)
		{
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/scout_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_Soldier)
		{
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/soldier_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_Pyro)
		{
			i_Victim2_sound_index = 1;
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/pyro_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_DemoMan)
		{
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/demoman_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_Heavy)
		{
			i_Victim2_sound_index = GetRandomInt(1,3);
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/heavy_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_Engineer)
		{
			i_Victim2_sound_index = 1;
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/engineer_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_Medic)
		{
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/medic_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_Sniper)
		{
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/sniper_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if (iClass4 == TFClass_Spy)
		{
			Format(s_victim2_class,sizeof(s_victim2_class),"vo/spy_thanks0%i.mp3", i_Victim2_sound_index);
		}
		if(IsValidClient(entity)){
			PrecacheSound(s_victim2_class, true);
			EmitSoundToClient(entity, s_victim2_class, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
			DataPack pack;
			LateTimers[entity] = CreateDataTimer(1.0, timer_playlate, pack);
			pack.WriteCell(entity);
			pack.WriteString(s_Client2_class);	
		}		
		if(IsValidClient(client)){
			PrecacheSound(s_Client2_class, true);
			EmitSoundToClient(client, s_Client2_class, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
			DataPack pack;
			LateTimers[client] = CreateDataTimer(1.0, timer_playlate, pack);
			pack.WriteCell(client);
			pack.WriteString(s_victim2_class);
		}
	}
}
public Action PlaySoundToClientNo(int client, int entity, TFClassType iClass__ent, TFClassType iClass__other){
	if(IsValidClient(client)){
		char s_Client3_class[256];
		char s_victim3_class[256];
		int i_client3_sound_index = GetRandomInt(1,3);
		int i_Victim3_sound_index = GetRandomInt(1,9);
		TFClassType	iClass5 = iClass__other;
		TFClassType	iClass6 = iClass__ent;
		if (iClass5 == TFClass_Scout)
		{
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/scout_no0%i.mp3", i_client3_sound_index);
		}
		if (iClass5 == TFClass_Soldier)
		{
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/soldier_no0%i.mp3", i_client3_sound_index);
		}
		if (iClass5 == TFClass_Pyro)
		{
			i_client3_sound_index = 1;
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/pyro_no01.mp3");
		}
		if (iClass5 == TFClass_DemoMan)
		{
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/demoman_no0%i.mp3", i_client3_sound_index);
		}
		if (iClass5 == TFClass_Heavy)
		{
			i_client3_sound_index = GetRandomInt(1,3);
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/heavy_no0%i.mp3", i_client3_sound_index);
		}
		if (iClass5 == TFClass_Engineer)
		{
			i_client3_sound_index = 1;
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/engineer_no0%i.mp3", i_client3_sound_index);
		}
		if (iClass5 == TFClass_Medic)
		{
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/medic_no0%i.mp3", i_client3_sound_index);
		}
		if (iClass5 == TFClass_Sniper)
		{
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/sniper_no0%i.mp3", i_client3_sound_index);
		}
		if (iClass5 == TFClass_Spy)
		{
			i_client3_sound_index = GetRandomInt(1,3);
			Format(s_Client3_class,sizeof(s_Client3_class),"vo/spy_no0%i.mp3", i_client3_sound_index);
		}
		//START OTHER PLAYER CLASS
		if (iClass6 == TFClass_Scout)
		{
			i_Victim3_sound_index = GetRandomInt(2,9);
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/scout_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_Soldier)
		{
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/soldier_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_Pyro)
		{
			i_Victim3_sound_index = GetRandomInt(1,2);
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/pyro_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_DemoMan)
		{
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/demoman_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_Heavy)
		{
			i_Victim3_sound_index = GetRandomInt(1,3);
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/heavy_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_Engineer)
		{
			i_Victim3_sound_index = GetRandomInt(1,4);
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/engineer_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_Medic)
		{
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/medic_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_Sniper)
		{
			i_Victim3_sound_index = GetRandomInt(1,8);
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/sniper_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if (iClass6 == TFClass_Spy)
		{
			i_Victim3_sound_index = GetRandomInt(1,6);
			Format(s_victim3_class,sizeof(s_victim3_class),"vo/spy_jeers0%i.mp3", i_Victim3_sound_index);
		}
		if(IsValidClient(entity)){
			PrecacheSound(s_victim3_class, true);
			EmitSoundToClient(entity, s_victim3_class, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
			DataPack pack;
			LateTimers[entity] = CreateDataTimer(1.0, timer_playlate, pack);
			pack.WriteCell(entity);
			pack.WriteString(s_Client3_class);	
		}		
		if(IsValidClient(client)){
			PrecacheSound(s_Client3_class, true);
			EmitSoundToClient(client, s_Client3_class, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
			DataPack pack;
			LateTimers[client] = CreateDataTimer(1.0, timer_playlate, pack);
			pack.WriteCell(client);
			pack.WriteString(s_victim3_class);
		}
	}
}
public Action timer_playlate(Handle timer, Handle pack) {

	char str[256];
	int client;
	 
	/* Set to the beginning and unpack it */
	ResetPack(pack);
	client = ReadPackCell(pack);
	ReadPackString(pack, str, sizeof(str));
	PrecacheSound(str, true);
	if(IsValidClient(client)){
		EmitSoundToClient(client, str, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
	}
	LateTimers[client] = INVALID_HANDLE;
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
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