/*******************************************************************************

  SM Damage

  Version: 1.5
  Author: SWAT_88

  1.0 	First version, should work on basically any mod
  1.1	Added Damage Init for each client
  1.2	Added Multi Mod Support
  1.5	Added Different damage per weapon.
   
  Description:
	Individual damage multiplier for each client.
	That means the weapons have more damage.
	Sidenote: Only values >= 1.0 are valid values for multiplier.
	
  Commands:
	sm_damage <player> <multiplier>
	
	sm_damage_weapon <weapon> <multiplier>  - Add/Set damage of weapon
	
	sm_damage_clear - Clear weapon storage.

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

#define PLUGIN_VERSION 	"1.5"

new Handle:g_version = INVALID_HANDLE;
new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_info = INVALID_HANDLE;
new Handle:g_init = INVALID_HANDLE;

new Float:Damage[MAXPLAYERS+1];
new Health[MAXPLAYERS+1];

new g_iArmor = -1;
new String:game[30];

new Handle:trieWeapons;

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
	g_iArmor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	
	SetConVarString(g_version, PLUGIN_VERSION);
	
	GetGameFolderName(game,sizeof(game));
	
	RegConsoleCmd("sm_damage",CmdDamage,"",FCVAR_GAMEDLL);
	RegAdminCmd("sm_damage_weapon",Weapon,ADMFLAG_CHEATS);
	RegAdminCmd("sm_damage_clear",ClearWeapons,ADMFLAG_CHEATS);
	
	HookEvent("player_hurt",PlayerHurt);
	
	trieWeapons = CreateTrie();
}

public OnPluginEnd(){
	CloseHandle(g_version);
	CloseHandle(g_enabled);
	CloseHandle(g_info);
	CloseHandle(g_init);
}

public OnEventShutdown()
{
	UnhookEvent("player_hurt",PlayerHurt);
}

public OnClientPutInServer(client){
	Damage[client] = GetConVarFloat(g_init);
}

public OnGameFrame(){
	for(new i=1; i <= GetMaxClients(); i++){
		if (IsClientInGame(i) && IsPlayerAlive(i)){
			Health[i] = GetClientHealth(i);
		}
	}
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){
	new client;
	new attacker;
	new Float:multiplier;
	new health;
	new armor;
	new dmg_health;
	new Float:mWeapon;
	new String:aWeapon[32];
	
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	dmg_health = Health[client] - GetEventInt(event,"health");	
	
	if(!attacker)
		{
		return Plugin_Handled;
		}
	
	if(!GetConVarBool(g_enabled)) return Plugin_Handled;
	
	GetClientWeapon(attacker,aWeapon,sizeof(aWeapon));
	
	if(GetTrieValue(trieWeapons,aWeapon,mWeapon)){
		if(mWeapon - 1.0 >= 0.0){
			multiplier = mWeapon - 1.0;
		}
		else{
			multiplier = 0.0;
		}
	}
	else{
		if((Damage[attacker] - 1.0) >= 0.0){
			multiplier = Damage[attacker] - 1.0;
		}
		else{
			multiplier = 0.0;
		}
	}	
	
	if(GetEventInt(event,"health") > 0){
		health = RoundToNearest(GetEventFloat(event,"health") - dmg_health*multiplier);
		if( health >= 0 ){
			SetEntityHealth(client,health);
		}
		else{
			SetEntityHealth(client,0);
			
		}
	}
	Health[client] = GetClientHealth(client);
	
	if(StrEqual(game,"cstrike",false)){
		if(GetEventInt(event,"armor") > 0){
			armor = RoundToNearest(GetEventFloat(event,"armor") - (GetEventFloat(event,"dmg_armor")*multiplier));
			if(armor >= 0){
				SetEntData(client,g_iArmor,armor);
			}
			else{
				SetEntData(client,g_iArmor,0);
			}
		}
	}
	
	return Plugin_Handled;
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

public Action:Weapon(client, args){
	new String:weapon[32];
	new String:multiplier[20];
	
	if( !GetConVarBool(g_enabled) ) return Plugin_Handled;
	
	if(args == 2){
		GetCmdArg(1,weapon,sizeof(weapon));
		GetCmdArg(2,multiplier,sizeof(multiplier));
		
		SetTrieValue(trieWeapons,weapon,StringToFloat(multiplier));
		ReplyToCommand(client,"Successfully set damage of weapon: %s to %.2f!", weapon, StringToFloat(multiplier));
	}
	else{
		ReplyToCommand(client,"Usage: sm_damage_weapon <weapon> <multiplier>");
	}
	
	return Plugin_Handled;
}

public Action:ClearWeapons(client, args){
	if( !GetConVarBool(g_enabled) ) return Plugin_Handled;
	
	ClearTrie(trieWeapons);
	ReplyToCommand(client,"Successfully cleared the stored damage of weapons!");
	
	return Plugin_Handled;
}
