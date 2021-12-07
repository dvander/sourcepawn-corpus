#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <gungame>
#include <cstrike>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "GunGame:SM Assist",
	author = "FLOJO|Bear Jew",
	description = "Points can be earned for kill assists and redeemed for level up or respawn",
	version = "2",
	url = "https://forums.alliedmods.net/showthread.php?t=190176"
};
 
 
#define DEFAULT		1
#define LIGHTGREEN	3
#define GREEN		4


new Float:AttackPoints[MAXPLAYERS+1][MAXPLAYERS+1];
new Float:TotalPoints[MAXPLAYERS+1];

new Handle:g_hNotificationSound;
new Handle:g_hNotificationEnabled;
new Handle:g_hPoints;
new Handle:g_hRatio;
new Handle:g_hRespawnEnabled;
new Handle:g_hWeaponList;

public OnPluginStart() {
	HookEvent("player_hurt", _PlayerDamaged);
	HookEvent("cs_win_panel_round", _RoundEnd);
	RegConsoleCmd("sm_redeem", Command_Redeem); 
	RegConsoleCmd("sm_assist", Command_Assist); 
	RegConsoleCmd("sm_respawn",Command_Respawn);
	
	g_hNotificationSound        = CreateConVar("gg_assist_sound","gungame/gong.mp3", "File to play when set points reached.",FCVAR_PLUGIN);
	g_hNotificationEnabled      = CreateConVar("gg_assist_sound_enabled","1", "Play a notification sound when points reached",FCVAR_PLUGIN);
	g_hPoints     			    = CreateConVar("gg_assist_points","100", "Number of points needed to redeem",FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hRatio    			    = CreateConVar("gg_assist_ratio","25.0", "Ratio of damage to points",FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hRespawnEnabled    		= CreateConVar("gg_assist_respawn","1", "Enable the respawn option",FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hWeaponList   		    = CreateConVar("gg_assist_blacklist","hegrenade,knife", "Blacklist of weapons, you can not level off of these weapons",FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "gg_assist");

	if (GetConVarBool(g_hNotificationEnabled)) {
		decl String:sound[255];
		GetConVarString(g_hNotificationSound, sound, sizeof(sound));
		AddFileToDownloadsTable(sound);
		PrecacheSound(sound);
	}
	
	CreateTimer(60.0, AnnounceTimer, _, TIMER_REPEAT);
	
}




public _PlayerDamaged(Handle: event, const String: name[], bool: dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer =  GetClientOfUserId(GetEventInt(event, "attacker"));
	if (victim != killer && killer > 0) 
	{
		new Float:dmg = float(GetEventInt(event,"dmg_health"));
		if (GetClientTeam(victim) != GetClientTeam(killer)) {
			AttackPoints[victim][killer] +=  ( GetConVarFloat(g_hRatio)*dmg/100.0);
		}
    }
}  

public _RoundEnd(Handle: event, const String: name[], bool: dontBroadcast)
{
	_ResetAttackPoints();
}  

public Action:GG_OnClientDeath(killer, victim, WeaponId, bool:TeamKilled)
{
	if(victim > 0 && IsClientInGame(victim)) {
			new i;
			for (i=1; i<=MaxClients; i++) {
				if (AttackPoints[victim][i] > 0 && i != killer && IsClientInGame(i)) {
					TotalPoints[i]+=AttackPoints[victim][i];
					new String:Pname[32];
					GetClientName(victim, Pname, sizeof(Pname));
					if (TotalPoints[i] >=  GetConVarFloat(g_hPoints) && GetConVarBool(g_hNotificationEnabled)) {
						decl String:sound[255];
						GetConVarString(g_hNotificationSound, sound, sizeof(sound));
						EmitSoundToClient(i,sound);
					}
					PrintToChat(i, "%c[GG Assist]%c You earned %c%.2f%c points from %c%s%c, you now have %c%.2f%c points" ,GREEN,DEFAULT,LIGHTGREEN, AttackPoints[victim][i],DEFAULT,GREEN,Pname,DEFAULT,LIGHTGREEN,TotalPoints[i],DEFAULT);
				}
				AttackPoints[victim][i]=float(0);
			}
		}
	return Plugin_Continue;
}

public GG_OnWarmupEnd()
{
	_ResetAll();
	_AnnouncePlugin();
	
}

public Action:Command_Redeem(client, args)
{  
  // Make sure the admin console (client=0) isn't the one initiating the command. We'll go ahead
  // and check that it's not outside the valid range of client indexes as a sanity check too.
  
  
	new Float:LEVEL_POINTS = GetConVarFloat(g_hPoints);
	
	if(client < 1 || client > MaxClients)
	{
		ReplyToCommand(client, "[GG Asisst] This command is for players only.");
		return Plugin_Handled;
	}
  
	if (!GetConVarBool(g_hRespawnEnabled))  {
		ReplyToCommand(client, "[GG Asisst] This command is dissabled.");
		return Plugin_Handled;
	}
  
  // Don't allow a player to buy a level during the warmup round
	if(GG_IsWarmupInProgress())
	{
		ReplyToCommand(client, "%c[GG Asisst]%c You cannot redeem a level during the warmup round.",GREEN,DEFAULT);
		return Plugin_Handled;
	}

	if (TotalPoints[client] < LEVEL_POINTS) {
		ReplyToCommand(client, "%c[GG Asisst]%c You need %c%.2f%c points to level up, you only have %c%.2f%c points",GREEN,DEFAULT,GREEN,LEVEL_POINTS,DEFAULT,LIGHTGREEN,TotalPoints[client],DEFAULT);
		return Plugin_Handled;
	}
		
		
	new String:currentWeapon[64];
	new String:blackList[255];
	GG_GetLevelWeaponName(GG_GetClientLevel(client), currentWeapon, sizeof(currentWeapon));
	GetConVarString(g_hWeaponList,blackList,sizeof(blackList));
		
	if (StrContains(blackList,currentWeapon,false) >= 0) {
		ReplyToCommand(client, "%c[GG Asisst]%c You can not buy off of %c%s%c level",GREEN,DEFAULT,GREEN,currentWeapon,DEFAULT);
		return Plugin_Handled;
	}
	
	if (TotalPoints[client] >= LEVEL_POINTS) {
		TotalPoints[client] -= LEVEL_POINTS;
		GG_AddALevel(client);
		ReplyToCommand(client, "%c[GG Asisst]%c You now have %c%.2f%c points",GREEN,DEFAULT,LIGHTGREEN,TotalPoints[client],DEFAULT);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_Assist(client, args)
{  
  // Make sure the admin console (client=0) isn't the one initiating the command. We'll go ahead
  // and check that it's not outside the valid range of client indexes as a sanity check too.
	
	if(client < 1 || client > MaxClients)
	{
		ReplyToCommand(client, "[GG Asisst] This command is for players only.");
		return Plugin_Handled;
	}
  
	new Float:LEVEL_POINTS = GetConVarFloat(g_hPoints);
	new String:currentPoints[32];
	new String:neededPoints[32];
	
	Format(currentPoints, sizeof(currentPoints), "You have %.2f points", TotalPoints[client]);
	Format(neededPoints, sizeof(neededPoints), "You need %.2f points", LEVEL_POINTS);
	
	new Handle:menu = CreateMenu(AssistMenuHandler);

	SetMenuTitle(menu, "GG Assist");
	AddMenuItem(menu, "1", currentPoints);
	AddMenuItem(menu, "2", neededPoints);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
 
	return Plugin_Handled;
}

public AssistMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End || action == MenuAction_Select || action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
}
 



public Action:Command_Respawn(client, args)
{  
  // Make sure the admin console (client=0) isn't the one initiating the command. We'll go ahead
  // and check that it's not outside the valid range of client indexes as a sanity check too.
	new Float:LEVEL_POINTS = GetConVarFloat(g_hPoints);
	
	if(client < 1 || client > MaxClients)
	{
		ReplyToCommand(client, "[GG Asisst] This command is for players only.");
		return Plugin_Handled;
	}
  
  // Don't allow a player to buy a level during the warmup round
	if(GG_IsWarmupInProgress())
	{
		ReplyToCommand(client, "%c[GG Asisst]%c You cannot redeem a level during the warmup round.",GREEN,DEFAULT);
		return Plugin_Handled;
	}

	if (TotalPoints[client] < LEVEL_POINTS) {
		ReplyToCommand(client, "%c[GG Asisst]%c You need %c%.2f%c points to level up, you only have %c%.2f%c points",GREEN,DEFAULT,GREEN,LEVEL_POINTS,DEFAULT,LIGHTGREEN,TotalPoints[client],GREEN);
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client)) {
		ReplyToCommand(client, "%c[GG Asisst]%c You must be DEAD to repsawn",GREEN,DEFAULT);
		return Plugin_Handled;
	}
	if (GetClientTeam(client) == 1) {
		ReplyToCommand(client, "%c[GG Asisst]%c You are spectating fool, Join a team and try again.",GREEN,DEFAULT);
		return Plugin_Handled;
	}
	
	if (TotalPoints[client] >= LEVEL_POINTS && !IsPlayerAlive(client) ) {
		TotalPoints[client] -= LEVEL_POINTS;
		CS_RespawnPlayer(client);
		ReplyToCommand(client, "%c[GG Asisst]%c You now have %c%.2f%c points",GREEN,DEFAULT,LIGHTGREEN,TotalPoints[client],GREEN);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:AnnounceTimer(Handle:timer){
	_AnnouncePlugin();
	return Plugin_Continue;
}


_ResetAll() {
	new i;
	new x;
	for (i = 0; i <= MaxClients; i++) {
		TotalPoints[i] = 0.0;
		for (x = 0; x <= MaxClients; x++) {
			AttackPoints[i][x] = 0.0;
		}
	}
}

_ResetAttackPoints() {
	new i;
	new x;
	for (i = 0; i <= MaxClients; i++) {
		for (x = 0; x <= MaxClients; x++) {
			AttackPoints[i][x] = 0.0;
		}
	}
}

_AnnouncePlugin() {
	PrintToChatAll("\x04Server is running GG Assist points!");
	PrintToChatAll("\x04Commands are !assist, !redeem, and !respawn.");
}