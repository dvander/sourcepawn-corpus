/*
Say Sounds
Hell Phoenix
http://www.charliemaurice.com/plugins

This plugin is somewhat a port of the classic SankSounds.  Basically, it uses a chat trigger then plays a 
sound associated with it.  People get a certain "quota" of sounds per map (default is 5).  They are warned 
at a certain amount (default 3) that they only have so many left.  This plugin also allows you to ban 
people from the sounds, reset sound quotas for everyone or just one person, and allow only admins to use
certain sounds.  

Thanks To:
	Ferret for his initial sourcemod plugins.  I used a few functions from his plugins as a learning tool.
	Teame06 for his help with the string replace function
	Bailopan for the pack stream info
	
Versions:
	1.0
		* First Public Release!
	1.1
		* Removed "downloadtable extension" dependency
		* Added Insurgency Mod Support
	1.2
		* Fixed some errors
		* Added admin only triggers
		* Join/Exit sound added

Todo:
	* Print Sound list to clients
 
Cvarlist (default value):
	sm_sound_enable 1
	sm_sound_warn 3
	sm_sound_limit 5
	sm_join_exit 0

Admin Commands:
	sm_sound_ban <user>
	sm_sound_unban <user>
	sm_sound_reset <all|user>
	
User Commands:
	!sounds - when used in chat turns sounds on/off for that client

	
Make sure "saysounds.cfg" is in your addons/sourcemod/configs/ directory.
File Format:
	"Sound Combinations"
		{
			"wazza"  //Word trigger
			{
				"file"	"sound/misc/wazza.wav" //"file" is always there, next is the filepath (always starts with "sound/")
				"admin"	"1"	//1 is admin only, 0 is anyone
			}
		}
	
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define MAX_PLAYERS 64

new Handle:cvarsoundenable;
new Handle:cvarsoundlimit;
new Handle:cvarsoundwarn;
new Handle:cvarjoinexit;
new Handle:listfile;
new String:soundlistfile[PLATFORM_MAX_PATH];
new restrict_playing_sounds[MAX_PLAYERS+1];
new SndOn[MAX_PLAYERS+1];
new SndCount[MAX_PLAYERS+1];

public Plugin:myinfo = 
{
	name = "Say Sounds",
	author = "Hell Phoenix",
	description = "Say Sounds",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart(){
	CreateConVar("sm_saysounds_version", PLUGIN_VERSION, "Say Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarsoundenable = CreateConVar("sm_sound_enable","1","Turns Sounds On/Off",FCVAR_PLUGIN);
	cvarsoundwarn = CreateConVar("sm_sound_warn","3","Number of sounds to warn person at",FCVAR_PLUGIN);
	cvarsoundlimit = CreateConVar("sm_sound_limit","5","Maximum sounds per person",FCVAR_PLUGIN);
	cvarjoinexit = CreateConVar("sm_join_exit","0","Play sounds when someone joins or exits the game",FCVAR_PLUGIN);
	RegAdminCmd("sm_sound_ban", Command_Sound_Ban, ADMFLAG_BAN, "sm_sound_ban <user> : Bans a player from using sounds");
	RegAdminCmd("sm_sound_unban", Command_Sound_Unban, ADMFLAG_BAN, "sm_sound_unban <user> : Unbans a player from using sounds");
	RegAdminCmd("sm_sound_reset", Command_Sound_Reset, ADMFLAG_BAN, "sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsurgencySay);
	RegConsoleCmd("say_team", Command_Say);
}

public OnMapStart(){
	CreateTimer(0.1, Load_Sounds);
}

public Action:Load_Sounds(Handle:timer){
	// precache sounds, loop through sounds
	BuildPath(Path_SM,soundlistfile,sizeof(soundlistfile),"configs/saysounds.cfg");
	if(!FileExists(soundlistfile)) {
		LogMessage("saysounds.cfg not parsed...file doesnt exist!");
	}else{
		listfile = CreateKeyValues("soundlist");
		FileToKeyValues(listfile,soundlistfile);
		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		do{
			new String:filelocation[255];
			KvGetString(listfile, "file", filelocation, sizeof(filelocation));
			if(FileExists(filelocation)){
				AddFileToDownloadsTable(filelocation);
				PrecacheSound(filelocation, true);
			}
		} while (KvGotoNextKey(listfile));
	}
}

public OnClientAuthorized(client, const String:auth[]){
	if(!IsFakeClient(client)){
		if(client != 0){
			SndOn[client] = 1;
			SndCount[client] = 0;
			
			if(!GetConVarInt(cvarjoinexit))
				return;
				
			decl String:filelocation[255];
			new adminonly = 0;
			KvJumpToKey(listfile, "JoinSound");
			KvGetString(listfile, "file", filelocation, sizeof(filelocation));
			
			new Handle:pack;
			CreateDataTimer(0.2,Command_Play_Sound,pack);
			WritePackCell(pack, client);
			WritePackCell(pack, adminonly);
			WritePackString(pack, filelocation);
			
			SndCount[client] = 0;
		}
	}
}

public OnClientDisconnect(client){
	if(!GetConVarInt(cvarjoinexit))
		return;
		
	SndCount[client] = 0;
				
	decl String:filelocation[255];
	new adminonly = 0;
	KvJumpToKey(listfile, "ExitSound");
	KvGetString(listfile, "file", filelocation, sizeof(filelocation));
	
	new Handle:pack;
	CreateDataTimer(0.2,Command_Play_Sound,pack);
	WritePackCell(pack, client);
	WritePackCell(pack, adminonly);
	WritePackString(pack, filelocation);
	
}

public Action:Command_Say(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarInt(cvarsoundenable))
			return Plugin_Continue;
	
		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
		decl String:clientName[64];
		GetClientName(client,clientName,64);
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"'){
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
				speech[len-1] = '\0';
			}
		}
						
		if(strcmp(speech[startidx],"!sounds",false) == 0){
				if(SndOn[client] == 1){
					SndOn[client] = 0;
					PrintToChat(client,"[Say Sounds] Sounds Disabled");
				}else{
					SndOn[client] = 1;
					PrintToChat(client,"[Say Sounds] Sounds Enabled");
				}
				return Plugin_Handled;
		}
		
		
			
		
		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		decl String:buffer[255];
		decl String:filelocation[255];
		new adminonly;
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (strcmp(speech[startidx],buffer,false) == 0){
				KvGetString(listfile, "file", filelocation, sizeof(filelocation));
				adminonly = KvGetNum(listfile, "admin");
				new Handle:pack;
				CreateDataTimer(0.1,Command_Play_Sound,pack);
				WritePackCell(pack, client);
				WritePackCell(pack, adminonly);
				WritePackString(pack, filelocation);
				break;
			}
		} while (KvGotoNextKey(listfile));
 
		return Plugin_Continue;
	}	
	return Plugin_Continue;
}

public Action:Command_InsurgencySay(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarInt(cvarsoundenable))
			return Plugin_Continue;
	
		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
		decl String:clientName[64];
		GetClientName(client,clientName,64);
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 4;
		if (speech[0] == '"'){
			startidx = 5;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
				speech[len-1] = '\0';
			}
		}
						
		if(strcmp(speech[startidx],"!sounds",false) == 0){
				if(SndOn[client] == 1){
					SndOn[client] = 0;
					PrintToChat(client,"[Say Sounds] Sounds Disabled");
				}else{
					SndOn[client] = 1;
					PrintToChat(client,"[Say Sounds] Sounds Enabled");
				}
				return Plugin_Handled;
		}
		
		
			
		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		decl String:buffer[255];
		decl String:filelocation[255];
		new adminonly;
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (strcmp(speech[startidx],buffer,false) == 0){
				KvGetString(listfile, "file", filelocation, sizeof(filelocation));
				adminonly = KvGetNum(listfile, "admin");
				new Handle:pack;
				CreateDataTimer(0.1,Command_Play_Sound,pack);
				WritePackCell(pack, client);
				WritePackCell(pack, adminonly);
				WritePackString(pack, filelocation);
				break;
			}
		} while (KvGotoNextKey(listfile));
		
		return Plugin_Continue;
	}	
	return Plugin_Continue;
}



public Action:Command_Play_Sound(Handle:timer,Handle:pack){
	decl String:filelocation[255];
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new adminonly = ReadPackCell(pack);
	ReadPackString(pack, filelocation, sizeof(filelocation));
	new startidx = 6;
	
	if(adminonly){
		new AdminId:aid = GetUserAdmin(client);
		if (aid == INVALID_ADMIN_ID)
			return Plugin_Handled;
	}
	
	if (SndCount[client] < GetConVarInt(cvarsoundlimit)){
		SndCount[client] = (SndCount[client] + 1);
		new playersconnected;
		playersconnected = GetMaxClients();
		for (new i = 1; i <= playersconnected; i++){
			if(IsClientInGame(i)){
				if(SndOn[i]){
					ClientCommand(i,"play %s", filelocation[startidx]);
				}
			}
		}
	}

	if ((SndCount[client]) >= GetConVarInt(cvarsoundlimit)){
		PrintToChat(client,"[Say Sounds] Sorry you have reached your sound quota!");
	}else if ((SndCount[client]) == GetConVarInt(cvarsoundwarn)){
		new numberleft;
		numberleft = (GetConVarInt(cvarsoundlimit) - GetConVarInt(cvarsoundwarn));
		PrintToChat(client,"[Say Sounds] You only have %d sounds left!",numberleft);
	}
	return Plugin_Handled;
}

public Action:Command_Sound_Reset(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
		return Plugin_Handled;	
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	if(strcmp(arg,"all",false) == 0 ){
		for (new i = 1; i <= MAX_PLAYERS; i++)
			SndCount[i] = 0;
		ReplyToCommand(client, "[Say Sounds] Quota has been reset for all players");	
	}else{
		new String:player;
		new user[2];
		player = SearchForClients(arg, user, 2);
		
		if (player == 0){
			ReplyToCommand(client, "[Say Sounds] No matching client");
			return Plugin_Handled;
		}else if (player > 1){
			ReplyToCommand(client, "[Say Sounds] More than one client matches");
			return Plugin_Handled;
		}else if ((client != 0) && (!CanUserTarget(client, user[0]))){
			ReplyToCommand(client, "[Say Sounds] Unable to target");
			return Plugin_Handled;
		}else if (IsFakeClient(user[0])){
			ReplyToCommand(client, "[Say Sounds] Cannot target a bot");
			return Plugin_Handled;
		}
			
		SndCount[player] = 0;
		new String:clientname[64];
		GetClientName(player,clientname,MAX_PLAYERS);
		ReplyToCommand(client, "[Say Sounds] Quota has been reset for %s", clientname);
	}
	return Plugin_Handled;
}

public Action:Command_Sound_Ban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_ban <user> : Bans a player from using sounds");
		return Plugin_Handled;	
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	new user[2];
	new target = SearchForClients(arg, user, 2);
	
	if (target == 0){
		ReplyToCommand(client, "[Say Sounds] No matching client");
		return Plugin_Handled;
	}else if (target > 1){
		ReplyToCommand(client, "[Say Sounds] More than one client matches");
		return Plugin_Handled;
	}else if ((client != 0) && (!CanUserTarget(client, user[0]))){
		ReplyToCommand(client, "[Say Sounds] Unable to target");
		return Plugin_Handled;
	}else if (IsFakeClient(user[0])){
		ReplyToCommand(client, "[Say Sounds] Cannot target a bot");
		return Plugin_Handled;
	}
	
	new String:BanClient[64];
	GetClientName(target,BanClient,MAX_PLAYERS);
	
	if (restrict_playing_sounds[target] == 1){
		ReplyToCommand(client, "[Say Sounds] %s is already banned!", BanClient);
	}else{
		restrict_playing_sounds[target]=1;
		ReplyToCommand(client,"[Say Sounds] %s has been banned!", BanClient);
	}

	return Plugin_Handled;
}

public Action:Command_Sound_Unban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_unban <user> <1|0> : Unbans a player from using sounds");
		return Plugin_Handled;	
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	new user[2];
	new target = SearchForClients(arg, user, 2);
	
	if (target == 0){
		ReplyToCommand(client, "[Say Sounds] No matching client");
		return Plugin_Handled;
	}else if (target > 1){
		ReplyToCommand(client, "[Say Sounds] More than one client matches");
		return Plugin_Handled;
	}else if ((client != 0) && (!CanUserTarget(client, user[0]))){
		ReplyToCommand(client, "[Say Sounds] Unable to target");
		return Plugin_Handled;
	}else if (IsFakeClient(user[0])){
		ReplyToCommand(client, "[Say Sounds] Cannot target a bot");
		return Plugin_Handled;
	}
	
	new String:BanClient[64];
	GetClientName(target,BanClient,MAX_PLAYERS);
	
	if (restrict_playing_sounds[target] == 0){
		ReplyToCommand(client,"[Say Sounds] %s is not banned!", BanClient);
	}else{
		restrict_playing_sounds[target]=0;
		ReplyToCommand(client,"[Say Sounds] %s has been unbanned!", BanClient);
	}
	return Plugin_Handled;
}

public OnPluginEnd(){
  CloseHandle(listfile);
}