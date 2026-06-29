/*
Spank2
Hell Phoenix
http://www.charliemaurice.com/plugins

Description:
	Plays a sound "Okay, Bendover", and tells everyone that the admin 
	is spanking the player ... 8 spanks causing no damage.

Thanks To:
	Denkkar Seffyd for the amxx original =D
	
Notes:
	Add bendover.wav to sound/misc/
	Requires at least revision 1175 of SourceMod
	
Versions:
	1.0
		* First Public Release!
	1.1
		* Fixed it spanking yourself...whoops =D
	1.2
		* Targeting is fixed for good hopefully

Admin Commands:
	sm_spank2 <user>

*/



#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Spank2",
	author = "Hell Phoenix",
	description = "Spank2",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart(){
	CreateConVar("sm_spank2_version", PLUGIN_VERSION, "SM Spank2 Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_spank2", admin_spanking, ADMFLAG_SLAY, "sm_spank2 <user>");
}

public OnMapStart(){
	PrecacheSound("sound/misc/bendover.wav", true);
	PrecacheSound("player/pl_fallpain1.wav", true);
	PrecacheSound("player/pl_fallpain3.wav", true);
	AddFileToDownloadsTable("sound/misc/bendover.wav");
}

public Action:admin_spanking(client, args){ 
	if (args < 1){
		ReplyToCommand(client, "[Spank2] Usage: sm_spank2 <user>");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	new player = FindTarget(client,arg);
		
	if (player <= 0){
		ReplyToCommand(client, "[Spank2] No/Too many matching client/s");
		return Plugin_Handled;
	}
	
	new String:clientname[64];
	GetClientName(player,clientname,sizeof(clientname));
	
	new String:adminname[64];
	GetClientName(client,adminname,sizeof(clientname));
	
	new playersconnected;
	playersconnected = GetMaxClients();
	for (new i = 1; i < playersconnected; i++){
		if(IsClientInGame(i))
			ClientCommand(i,"play misc/bendover.wav");
	}
	
	PrintToChatAll("%s is bending over for a spanking lovingly administered by %s",clientname,adminname);
	CreateTimer(2.0, spanking, player);
	return Plugin_Handled;
} 

public Action:spanking(Handle:timer, any:player){
   CreateTimer(0.2, slap_player, player);
   CreateTimer(0.4, slap_player, player);
   CreateTimer(0.6, slap_player, player);
   CreateTimer(0.8, slap_player, player);
   CreateTimer(1.0, slap_player, player);
   CreateTimer(1.2, slap_player, player);
   CreateTimer(1.4, slap_player, player);
   CreateTimer(1.6, slap_player, player);
   return Plugin_Continue;
}

public Action:slap_player(Handle:timer, any:player){ 
   SlapPlayer(player, 0, true); 
   return Plugin_Continue;
} 