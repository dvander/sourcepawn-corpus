/*******************************************************************************

  SM Damage

  Version: 1.4
  Author: SWAT_88

  1.0 	First version, should work on basically any mod
  1.1	Added Damage Init for each client
  1.2	Added Multi Mod Support
  1.3	Now the damage is tracked correctly in stats plugins.
  1.4	Fixed g_attacker bug.
   
  Description:
	Individual damage multiplier for each client.
	That means the weapons have more damage.
	Sidenote: Only values >= 1.0 are valid values for multiplier.
	
  Commands:
	sm_damage <player> <multiplier>

  Cvars:

	sm_damage_enabled 	"1"		- 0: disables the plugin - 1: enables the plugin
	
	sm_damage_info		"1"		- 0: disables information - 1: shows which player/s are involved
	
	sm_damage_init		"1.0"	- 1.0: standard multiplier for each client on connect - x: sets damage multiplier for each client on connect.

  Setup (SourceMod):

	Install the smx file to addons\sourcemod\plugins.
	(Re)Load Plugin or change Map.
	
  TO DO:
	Nothing make a request.
	
  Copyright:
  
	Everybody can edit this plugin and copy this plugin.
	
  HAVE FUN!!!

*******************************************************************************/

#include <sourcemod>
#include <sdktools>
#include <hooker>

#define PLUGIN_VERSION 	"1.4"

new Handle:g_version = INVALID_HANDLE;
new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_info = INVALID_HANDLE;
new Handle:g_init = INVALID_HANDLE;

new Float:Damage[MAXPLAYERS+1];
new g_attacker;

new String:game[30];

public Plugin:myinfo =
{
	name = "SM Damage",
	author = "SWAT_88",
	description = "Individual damage multiplier for each client.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	g_enabled = CreateConVar("sm_damage_enabled","1");
	g_info = CreateConVar("sm_damage_info","1");
	g_version = CreateConVar("sm_damage_version", PLUGIN_VERSION,"SM Damage Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_init = CreateConVar("sm_damage_init","1.0");
	
	SetConVarString(g_version, PLUGIN_VERSION);
	
	GetGameFolderName(game,sizeof(game));
	
	RegConsoleCmd("sm_damage",CmdDamage,"",FCVAR_GAMEDLL);
	
	HookEvent("bullet_impact",PlayerShoot);
	RegisterHook(HK_OnTakeDamage, TakeDamageFunction, false);
}

public OnPluginEnd(){
	CloseHandle(g_version);
	CloseHandle(g_enabled);
	CloseHandle(g_info);
	CloseHandle(g_init);
}

public OnEventShutdown()
{
	UnhookEvent("bullet_impact",PlayerShoot);
}

public OnClientPutInServer(client){
	Damage[client] = GetConVarFloat(g_init);
	HookEntity(HKE_CCSPlayer, client);
}

public OnClientDisconnect(client)
{
    UnHookPlayer(HKE_CCSPlayer, client);
}

public OnGameFrame(){
	g_attacker = 0;
	//I will explain this:
	//If an admin with damage multiplier 2 shoot against a wall dann bullet_impact is fired and g_attacker is set to admin-id.
	//If somebody knifes or throws a grenade then bullet_impact is not fired,
	//therefore g_attacker is still admin and if somebody knifes then the attacker has damage multiplier of 2 and the attacker would be admin.
	//With this code I reset the attacker-id after the bullet_impact and damage event.
	//OnGameFrame is called after TakeDamageFunction and bullet_impact.
}

public Action:PlayerShoot(Handle:event, const String:name[], bool:dontBroadcast){
	g_attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	return Plugin_Continue;
}

public Action:TakeDamageFunction(client, &inflictor, &attacker, &Float:DamageHP, &DamageType, &AmmoType)
{
	if(g_attacker == 0) return Plugin_Continue;
	attacker = g_attacker;
	inflictor = g_attacker;
	DamageHP *= Damage[g_attacker];
	return Plugin_Changed;
}

public Action:CmdDamage(client, args){
	new String:player[256];
	new String:multiplier[20];
	
	if(GetConVarInt(g_enabled) == 0) return Plugin_Handled;
	
	if(!GetAdminFlag(GetUserAdmin(client), Admin_Cheats)){
		ReplyToCommand(client,"[SM] You do not have access to this command.");
		return Plugin_Handled;
	}
	
	if (args == 2){
		GetCmdArg(1,player,255);
		GetCmdArg(2,multiplier,19);
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		decl String:name[256];

		if ((target_count = ProcessTargetString(player,client,target_list,MAXPLAYERS,0,target_name,sizeof(target_name),tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for (new i = 0; i < target_count; i++) {
			if(GetConVarBool(g_info)){
				GetClientName(target_list[i],name,255);
				ReplyToCommand(client,"%s %f",name,StringToFloat(multiplier));
			}
			Damage[target_list[i]] = StringToFloat(multiplier);
		}
	}
	else{
		ReplyToCommand(client,"Usage: sm_damage <player> <multiplier>");
	}
	
	return Plugin_Handled;
}
