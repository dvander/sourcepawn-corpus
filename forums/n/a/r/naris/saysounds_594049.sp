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
	1.3
		* Made join/exit sounds for admins only
		* Fixed errors on linux
	1.4
		* Fixed sound reset bug (thanks to lambdacore for pointing it out)
		* Added join/exit and wazza sound files to the download
	1.5 September 26, 2007
		* Uses EmitSountToClient instead of play (should allow multiple sounds to play at once)
			- Note that the path for the file changed because of this...remove the sound/ from your 
				cfg file...IE. change sound/misc/wazza.wav to misc/wazza.wav
		* Clients using "!soundlist" in chat will get a list of triggers in their console
		* Added a cvar to control how long between each sound to wait and a message to the user
	1.5.5 Oct 9, 2007
		* Fixed small memory leak from not closing handle at the end of each map
	1.6   Dec 28, 2007
		* Modified by -=|JFH|=-Naris
		* Added soundmenu (Menu of sounds to play)
		* Added adminsounds (Menu of admin-only sounds for admins to play)
		* Added adminsounds menu to SourceMod's admin menu
		* Added sm_specific_join_exit (Join/Exit for specific STEAM IDs)
		* Fixed join/exit sounds not playing by adding call to KvRewind()
		  before KvJumpToKey().
		* Fixed non-admins playing admin sounds by checking for generic admin bits.
		* Used SourceMod's MANPLAYERS instread of recreating another MAX_PLAYERS constant.
		* Added globalLastSound which is set to duration of last sound played
		  to reduce possibility of overlapping sounds.
		* Fix the sounds go away bug
		* Moved close of listfile from mapchange to Load_Sounds (if handle is valid)
	1.7   Jan 10, 2008
		* Modified by -=|JFH|=-Naris
		* Added separate admin sound_limit and time_between_sounds convars.
		* Changed multiple sound to check the "file" key if "file1" is not found.
	1.8   Jan 11, 2008
		* Modified by -=|JFH|=-Naris
		* Fixed timer errors
	1.9   Jan 18, 2008
		* Modified by -=|JFH|=-Naris
		* Added Sound Duration setting in config file
		* Various fixes
	1.10  Jan 22, 2008
		* Modified by -=|JFH|=-Naris
		* Added more comprensive error checking
		* Changed !soundlist to call Sound_Menu() instead of List_Sounds().
	1.11  Feb 03, 2008
		* Modified by -=|JFH|=-Naris
		* Added separate sm_sound_admin_warn convar.
		* Added unlimited sounds when limit == 0.
	1.12  Feb 03, 2008
		* Modified by -=|JFH|=-Naris
		* Fixed message that limit was passed when unlimited
		* Fixed grammar in warning.
	1.13  Feb 06, 2008
		* Modified by -=|JFH|=-Naris
		* Fix bug in unlimited sounds.
		* Added logging.
	1.14  Feb 13, 2008
		* Modified by -=|JFH|=-Naris
		* Added logging of unnamed (join/exit) sounds.
	1.15  Feb 14, 2008
		* Modified by -=|JFH|=-Naris
		* Added LAMDACORE's change to increase memory to allow lots of sounds
		* Added LAMDACORE's change to allow keyword to be embedded in a sentence.
		* Added sm_sound_sentence to enable the above modification.
	1.16  Feb 18, 2008
		* Modified by -=|JFH|=-Naris
		* Added check for Fake clients (bots) before Emitting Sounds
		  or sending Chat messages.
	1.17  Mar 1, 2008
		* Modified by -=|JFH|=-Naris
		* Fixed crash in Counter-Strike (Windows) by NOT calling GetSoundDuration()
		  unless the SDKVersion >= 30 (Version or Orangebox/TF2)
	1.18  Mar 2, 2008
		* Modified by -=|JFH|=-Naris
		* Also added check to not call GetSoundDuration() for mp3 files.
		* Added sm_sound_logging to turn logging of sounds played on and off.
		* Added sm_sound_allow_bots to allow bots to trigger sounds.
	1.19  Mar 2, 2008
		* Modified by -=|JFH|=-Naris
		* Removed sm_sound_allow_bots to allow bots to trigger sounds.
		* Removed several checks for Fake Clients.
		* Commented out code that calls GetSoundDuration()


Todo:
	* Optimise keyvalues usage
	* Save user settings
 
Cvarlist (default value):
	sm_sound_enable 1		 Turns Sounds On/Off
	sm_sound_warn 3			 Number of sounds to warn person at
	sm_sound_limit 5 		 Maximum sounds per person
	sm_sound_admin_limit 0 		 Maximum sounds per admin
	sm_sound_admin_warn 0		 Number of sounds to warn admin at
	sm_sound_announce 0		 Turns on announcements when a sound is played
	sm_sound_sentence 0	 	 When set, will trigger sounds if keyword is embedded in a sentence
	sm_sound_logging 0	 	 When set, will log sounds that are played
	sm_join_exit 0 			 Play sounds when someone joins or exits the game
	sm_join_spawn 1 		 Wait until the player spawns before playing the join sound
	sm_specific_join_exit 0 	 Play sounds when a specific STEAM ID joins or exits the game
	sm_time_between_sounds 4.5 	 Time between each sound trigger, 0.0 to disable checking
	sm_time_between_admin_sounds 4.5 Time between each sound trigger (for admins), 0.0 to disable checking

Admin Commands:
	sm_sound_ban <user>		 Bans a player from using sounds
	sm_sound_unban <user>		 Unbans a player os they can play sounds
	sm_sound_reset <all|user>	 Resets sound quota for user, or everyone if all
	sm_admin_sounds 		 Display a menu of all admin sounds to play
	!adminsounds 			 When used in chat will present a menu of all admin sound to play.
	
User Commands:
	sm_sound_menu 			 Display a menu of all sounds (trigger words) to play
	sm_sound_list  			 Print all trigger words to the console
	!sounds  			 When used in chat turns sounds on/off for that client
	!soundlist  			 When used in chat will print all the trigger words to the console (Now displays menu)
	!soundmenu  			 When used in chat will present a menu to choose a sound to play.

	
Make sure "saysounds.cfg" is in your addons/sourcemod/configs/ directory.
Sounds go in your mods "sound" directory (such as sound/misc/filename.wav).
File Format:
	"Sound Combinations"
		{
			"JoinSound" // Sound to play when a player Joins the server
			{
				"file"	"misc/welcome.wav"
				"admin"	"0"
				"single" "1" // 1 to play sound to single client only, 0 to play to all (default is 0)
			}
			"wazza"  // Word trigger
			{
				"file"	"misc/wazza.wav" //"file" is always there, next is the filepath (always starts with "sound/")
				"admin"	"1"	//1 is admin only, 0 is anyone (defaults is 0)
				"download" "1"	//1 to download the sounds, 0 to not download (default is 1)
				"duration" "5.0" // duration of the sound (default is 0.0)
			}
			"lol"  // Word trigger to randomly select 1 of multiple sounds
			{
				"file"	"misc/lol1.wav"	// name of the 1st option, can also be "file1"
				"file2"	"misc/lol2.wav"	// name of the 2nd option
				"file3"	"misc/lol3.wav"
				"file4"	"misc/lol4.wav"
				"count"	"4"		// number of sounds (default is 1)
				"duration" "5.0"	// This will apply no matter which sound is selected
			}
			"STEAM_0:0:xxxxxx" // trigger for specific STEAM ID
			{
				"file"	"misc/myhouse.mp3" // name of sound to play when joining
				"exit"	"misc/goodbye.mp3" // name of sound to play when leaving
				"admin"	"0"
			}
			"doh"  // Minimun configuration for sounds
			{
				"file"	"misc/doh.wav"	// This will set all other options to default values
			}
		}
	
*/


#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

// BEIGN MOD BY LAMDACORE
// extra memory usability for a lot of sounds.
// Uncomment the next line (w/#pragma) to add additional memory
#pragma dynamic 65536 
// END MOD BY LAMDACORE

#pragma semicolon 1

#define PLUGIN_VERSION "1.19"

new Handle:cvarsoundenable = INVALID_HANDLE;
new Handle:cvarsoundlimit = INVALID_HANDLE;
new Handle:cvarsoundwarn = INVALID_HANDLE;
new Handle:cvarjoinexit = INVALID_HANDLE;
new Handle:cvarjoinspawn = INVALID_HANDLE;
new Handle:cvarspecificjoinexit = INVALID_HANDLE;
new Handle:cvartimebetween = INVALID_HANDLE;
new Handle:cvaradmintime = INVALID_HANDLE;
new Handle:cvaradminwarn = INVALID_HANDLE;
new Handle:cvaradminlimit = INVALID_HANDLE;
new Handle:cvarannounce = INVALID_HANDLE;
new Handle:cvarsentence = INVALID_HANDLE;
new Handle:cvarlogging = INVALID_HANDLE;
new Handle:listfile = INVALID_HANDLE;
new Handle:hAdminMenu = INVALID_HANDLE;
new String:soundlistfile[PLATFORM_MAX_PATH] = "";
new restrict_playing_sounds[MAXPLAYERS+1];
new SndOn[MAXPLAYERS+1];
new SndCount[MAXPLAYERS+1];
new Float:LastSound[MAXPLAYERS+1];
new bool:firstSpawn[MAXPLAYERS+1];
new Float:globalLastSound = 0.0;
new Float:globalLastAdminSound = 0.0;
//new SDKVersion;

public Plugin:myinfo = 
{
	name = "Say Sounds",
	author = "Hell Phoenix",
	description = "Say Sounds",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart(){
	//SDKVersion = GuessSDKVersion();
	CreateConVar("sm_saysounds_version", PLUGIN_VERSION, "Say Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarsoundenable = CreateConVar("sm_sound_enable","1","Turns Sounds On/Off",FCVAR_PLUGIN);
	cvarsoundwarn = CreateConVar("sm_sound_warn","3","Number of sounds to warn person at (0 for no warnings)",FCVAR_PLUGIN);
	cvarsoundlimit = CreateConVar("sm_sound_limit","5","Maximum sounds per person (0 for unlimited)",FCVAR_PLUGIN);
	cvarjoinexit = CreateConVar("sm_join_exit","0","Play sounds when someone joins or exits the game",FCVAR_PLUGIN);
	cvarjoinspawn = CreateConVar("sm_join_spawn","1","Wait until the player spawns before playing the join sound",FCVAR_PLUGIN);
	cvarspecificjoinexit = CreateConVar("sm_specific_join_exit","1","Play sounds when specific steam ID joins or exits the game",FCVAR_PLUGIN);
	cvartimebetween = CreateConVar("sm_time_between_sounds","4.5","Time between each sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	cvaradmintime = CreateConVar("sm_time_between_admin_sounds","4.5","Time between each admin sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	cvaradminwarn = CreateConVar("sm_sound_admin_warn","0","Number of sounds to warn admin at (0 for no warnings)",FCVAR_PLUGIN);
	cvaradminlimit = CreateConVar("sm_sound_admin_limit","0","Maximum sounds per admin (0 for unlimited)",FCVAR_PLUGIN);
	cvarannounce = CreateConVar("sm_sound_announce","0","Turns on announcements when a sound is played",FCVAR_PLUGIN);
	cvarsentence = CreateConVar("sm_sound_sentence","0","When set, will trigger sounds if keyword is embedded in a sentence",FCVAR_PLUGIN);
	cvarlogging = CreateConVar("sm_sound_logging","1","When set, will log sounds that are played",FCVAR_PLUGIN);
	RegAdminCmd("sm_sound_ban", Command_Sound_Ban, ADMFLAG_BAN, "sm_sound_ban <user> : Bans a player from using sounds");
	RegAdminCmd("sm_sound_unban", Command_Sound_Unban, ADMFLAG_BAN, "sm_sound_unban <user> : Unbans a player from using sounds");
	RegAdminCmd("sm_sound_reset", Command_Sound_Reset, ADMFLAG_GENERIC, "sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
	RegAdminCmd("sm_admin_sounds", Command_Admin_Sounds,ADMFLAG_GENERIC, "Display a menu of Admin sounds to play");
	RegConsoleCmd("sm_sound_list", Command_Sound_List, "List available sounds to console");
	RegConsoleCmd("sm_sound_menu", Command_Sound_Menu, "Display a menu of sounds to play");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsurgencySay);
	RegConsoleCmd("say_team", Command_Say);

	HookEventEx("player_spawn",PlayerSpawn);

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	/*************************************************************/
	/* Add a Play Admin Sound option to the SourceMod Admin Menu */
	/*************************************************************/

	/* Block us from being called twice */
	if (topmenu != hAdminMenu){
		/* Save the Handle */
		hAdminMenu = topmenu;
		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		AddToTopMenu(hAdminMenu, "sm_admin_sounds", TopMenuObject_Item, Play_Admin_Sound,
				server_commands, "sm_admin_sounds", ADMFLAG_GENERIC);
	}
}

public Play_Admin_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
                        param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Play Admin Sound");
	else if (action == TopMenuAction_SelectOption)
		Sound_Menu(param,true);
}

public OnMapStart(){
	globalLastSound = 0.0;
	globalLastAdminSound = 0.0;
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		SndCount[i] = 0;
		LastSound[i] = 0.0;
	}
	CreateTimer(0.2, Load_Sounds);
}

public Action:Load_Sounds(Handle:timer){
	// precache sounds, loop through sounds
	BuildPath(Path_SM,soundlistfile,sizeof(soundlistfile),"configs/saysounds.cfg");
	if(!FileExists(soundlistfile)) {
		SetFailState("saysounds.cfg not parsed...file doesnt exist!");
	}else{
		if (listfile != INVALID_HANDLE){
			CloseHandle(listfile);
		}
		listfile = CreateKeyValues("soundlist");
		FileToKeyValues(listfile,soundlistfile);
		KvRewind(listfile);
		if (KvGotoFirstSubKey(listfile)){
			do{
				decl String:filelocation[PLATFORM_MAX_PATH+1];
				decl String:dl[PLATFORM_MAX_PATH+1];
				decl String:file[8];
				new count = KvGetNum(listfile, "count", 1);
				new download = KvGetNum(listfile, "download", 1);
				for (new i = 0; i <= count; i++){
					if (i){
						Format(file, sizeof(file), "file%d", i);
					}else{
						strcopy(file, sizeof(file), "file");
					}
					KvGetString(listfile, file, filelocation, sizeof(filelocation), "");
					if (strlen(filelocation)){
						Format(dl, sizeof(dl), "sound/%s", filelocation);
						PrecacheSound(filelocation, true);
						if(download && FileExists(dl)){
							AddFileToDownloadsTable(dl);
						}
					}
				}
			} while (KvGotoNextKey(listfile));
		}
		else{
			SetFailState("saysounds.cfg not parsed...No subkeys found!");
		}
	}
	return Plugin_Handled;
}

public PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast){
	if(GetConVarBool(cvarjoinspawn)){
		new userid = GetEventInt(event,"userid");
		if (userid){
			new index=GetClientOfUserId(userid);
			if (index){
				if(!IsFakeClient(index)){
					if (firstSpawn[index]){
						decl String:auth[64];
						GetClientAuthString(index,auth,63);
						CheckJoin(index, auth);
						firstSpawn[index] = false;
					}
				}
			}
		}
	}
}

public OnClientAuthorized(client, const String:auth[]){
	if(client != 0){
		SndOn[client] = 1;
		SndCount[client] = 0;
		LastSound[client] = 0.0;
		firstSpawn[client]=true;
		if(!GetConVarBool(cvarjoinspawn)){
			CheckJoin(client, auth);
		}
	}
}

public CheckJoin(client, const String:auth[]){
	if(GetConVarBool(cvarspecificjoinexit)){
		decl String:filelocation[PLATFORM_MAX_PATH+1];
		KvRewind(listfile);
		if (KvJumpToKey(listfile, auth)){
			KvGetString(listfile, "join", filelocation, sizeof(filelocation), "");
			if (strlen(filelocation)){
				Send_Sound(client,filelocation, "");
				SndCount[client] = 0;
				return;
			}else if (Submit_Sound(client,"")){
				SndCount[client] = 0;
				return;
			}
		}
	}

	if(GetConVarBool(cvarjoinexit)){
		KvRewind(listfile);
		if (KvJumpToKey(listfile, "JoinSound")){
			Submit_Sound(client,"");
			SndCount[client] = 0;
		}
	}
}

public OnClientDisconnect(client){
	if(GetConVarBool(cvarjoinexit)){
		SndCount[client] = 0;
		LastSound[client] = 0.0;
		firstSpawn[client] = true;

		if(GetConVarBool(cvarspecificjoinexit)){
			decl String:auth[64];
			GetClientAuthString(client,auth,63);

			decl String:filelocation[PLATFORM_MAX_PATH+1];
			KvRewind(listfile);
			if (KvJumpToKey(listfile, auth)){
				KvGetString(listfile, "exit", filelocation, sizeof(filelocation), "");
				if (strlen(filelocation)){
					Send_Sound(client,filelocation, "");
					SndCount[client] = 0;
					return;
				}else if (Submit_Sound(client,"")){
					SndCount[client] = 0;
					return;
				}
			}
		}

		KvRewind(listfile);
		if (KvJumpToKey(listfile, "ExitSound")){
			Submit_Sound(client,"");
			SndCount[client] = 0;
		}
	}
}

public Action:Command_Say(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarBool(cvarsoundenable))
			return Plugin_Continue;

		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
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

		if(strcmp(speech[startidx],"!sounds",false) == 0 || 
		   strcmp(speech[startidx],"sounds",false) == 0){
				if(SndOn[client] == 1){
					SndOn[client] = 0;
					PrintToChat(client,"[Say Sounds] Sounds Disabled");
				}else{
					SndOn[client] = 1;
					PrintToChat(client,"[Say Sounds] Sounds Enabled");
				}
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundlist",false) == 0 ||
			strcmp(speech[startidx],"soundlist",false) == 0){
				//List_Sounds(client);
				//PrintToChat(client,"[Say Sounds] Check your console for a list of sound triggers");
				Sound_Menu(client,false);
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundmenu",false) == 0 ||
			strcmp(speech[startidx],"soundmenu",false) == 0){
				Sound_Menu(client,false);
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!adminsounds",false) == 0 ||
			strcmp(speech[startidx],"adminsounds",false) == 0){
				Sound_Menu(client,true);
				return Plugin_Handled;
		}

		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		new bool:sentence = GetConVarBool(cvarsentence);
		decl String:buffer[255];
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if ((sentence && StrContains(speech[startidx],buffer,false) >= 0) ||
				(strcmp(speech[startidx],buffer,false) == 0)){
					Submit_Sound(client,buffer);
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
		if (!GetConVarBool(cvarsoundenable))
			return Plugin_Continue;

		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
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
		}else if(strcmp(speech[startidx],"!soundlist",false) == 0){
			List_Sounds(client);
			PrintToChat(client,"[Say Sounds] Check your console for a list of sound triggers");
			return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundmenu",false) == 0){
			Sound_Menu(client,false);
			return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!adminsounds",false) == 0){
			Sound_Menu(client,true);
			return Plugin_Handled;
		}

		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		new bool:sentence = GetConVarBool(cvarsentence);
		decl String:buffer[255];
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if ((sentence && StrContains(speech[startidx],buffer,false) >= 0) ||
				(strcmp(speech[startidx],buffer,false) == 0)){
					Submit_Sound(client,buffer);
					break;
			}
		} while (KvGotoNextKey(listfile));

		return Plugin_Continue;
	}	
	return Plugin_Continue;
}

bool:Submit_Sound(client,const String:name[])
{
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:file[8] = "file";
	new count = KvGetNum(listfile, "count", 1);
	if (count > 1){
		Format(file, sizeof(file), "file%d", GetRandomInt(1,count));
	}
	KvGetString(listfile, file, filelocation, sizeof(filelocation));
	if (!strlen(filelocation) && StrEqual(file, "file1")){
		KvGetString(listfile, "file", filelocation, sizeof(filelocation), "");
	}
	if (strlen(filelocation)){
		Send_Sound(client, filelocation,name);
		return true;
	}
	return false;
}

Send_Sound(client, const String:filelocation[], const String:name[])
{
	new adminonly = KvGetNum(listfile, "admin",0);
	new singleonly = KvGetNum(listfile, "single",0);
	new Float:duration = KvGetFloat(listfile, "duration",0.0);
	new Handle:pack;
	CreateDataTimer(0.2,Command_Play_Sound,pack);
	WritePackCell(pack, client);
	WritePackCell(pack, adminonly);
	WritePackCell(pack, singleonly);
	WritePackFloat(pack, duration);
	WritePackString(pack, filelocation);
	WritePackString(pack, name);
}

public Action:Command_Play_Sound(Handle:timer,Handle:pack){
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:name[PLATFORM_MAX_PATH+1];
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new adminonly = ReadPackCell(pack);
	new singleonly = ReadPackCell(pack);
	new Float:duration = ReadPackFloat(pack);
	ReadPackString(pack, filelocation, sizeof(filelocation));
	ReadPackString(pack, name , sizeof(name));

	new bool:isadmin = false;
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new AdminId:aid = GetUserAdmin(client);
		isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(adminonly && !isadmin){
			PrintToChat(client,"[Say Sounds] Sorry, you are not authorized to play this sound!");
			return Plugin_Handled;
		}
	}

	new Float:thetime = GetGameTime();
	if (LastSound[client] >= thetime){
		if(IsClientInGame(client) && !IsFakeClient(client)){
			PrintToChat(client,"[Say Sounds] Please don't spam the sounds!");
		}
		return Plugin_Handled;
	}

	// Make sure NOT to crash Counter Strike!
	// Also, Don't check duration of mp3's (that might crash)
	/*
	if (SDKVersion >= 30 && StrContains(filelocation, "mp3", false) <= -1)
	{
		new Float:soundTime = GetSoundDuration(filelocation);
		if (duration < soundTime)
			duration = soundTime;
	}
	*/

	new Float:waitTime = GetConVarFloat(cvartimebetween);
	if (waitTime < duration)
		waitTime = duration;

	new Float:adminTime = 0.0;
	if (adminonly)
	{
		if (globalLastAdminSound >= thetime){
			if(IsClientInGame(client) && !IsFakeClient(client)){
				PrintToChat(client,"[Say Sounds] Please don't spam the admin sounds!");
			}
			return Plugin_Handled;
		}

		adminTime = GetConVarFloat(cvaradmintime);
		if (adminTime < duration)
			adminTime = duration;
	}

	new soundLimit = isadmin ? GetConVarInt(cvaradminlimit) : GetConVarInt(cvarsoundlimit);	
	if (soundLimit <= 0 || SndCount[client] < soundLimit){
		if (globalLastSound < thetime){
			SndCount[client]++;
			LastSound[client] = thetime + waitTime;
			globalLastSound   = thetime + duration;

			if (adminonly)
				globalLastAdminSound = thetime + adminTime;

			if (singleonly){
				if(SndOn[client] && IsClientInGame(client) && !IsFakeClient(client)){
					EmitSoundToClient(client, filelocation);
				}
			}else{
				new clientlist[MAXPLAYERS+1];
				new clientcount = 0;
				new playersconnected = GetMaxClients();
				for (new i = 1; i <= playersconnected; i++){
					if(SndOn[i] && IsClientInGame(i) && !IsFakeClient(client)){
						clientlist[clientcount++] = i;
					}
				}
				if (clientcount){
					EmitSound(clientlist, clientcount, filelocation);
				}
				if (name[0] && IsClientInGame(client) && !IsFakeClient(client)){
					if (GetConVarBool(cvarannounce)){
						PrintToChatAll("%N played %s", client, name);
					}
					if (GetConVarBool(cvarlogging)){
						LogMessage("%s%N played %s%s(%s)", isadmin ? "Admin " : "", client,
							   adminonly ? "admin sound " : "", name, filelocation);
					}
				}else if (GetConVarBool(cvarlogging)){
					LogMessage("[Say Sounds] played %s", filelocation);
				}
			}
		}
		else if(IsClientInGame(client) && !IsFakeClient(client)){
			PrintToChat(client,"[Say Sounds] Please don't spam the sounds!");
			return Plugin_Handled;
		}
	}

	if(soundLimit > 0 && IsClientInGame(client) && !IsFakeClient(client)){
		if (SndCount[client] > soundLimit){
			PrintToChat(client,"[Say Sounds] Sorry, you have reached your sound quota!");
		}else if (SndCount[client] == soundLimit){
			PrintToChat(client,"[Say Sounds] You have no sounds left to use!");
			SndCount[client]++; // Increment so we get the sorry message next time.
		}else{
			new soundWarn = isadmin ? GetConVarInt(cvaradminwarn) : GetConVarInt(cvarsoundwarn);	
			if (soundWarn <= 0 || SndCount[client] >= soundWarn){
				new numberleft = (soundLimit -  SndCount[client]);
				if (numberleft == 1)
					PrintToChat(client,"[Say Sounds] You only have %d sound left to use!",numberleft);
				else
					PrintToChat(client,"[Say Sounds] You only have %d sounds left to use!",numberleft);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_Sound_Reset(client, args){
	if (args < 1){
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
		return Plugin_Handled;
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));	

	if (strcmp(arg,"all",false) == 0 ){
		for (new i = 1; i <= MAXPLAYERS; i++)
			SndCount[i] = 0;
		ReplyToCommand(client, "[Say Sounds] Quota has been reset for all players");	
	}else{
		decl String:name[64];
		new bool:isml,clients[MAXPLAYERS+1];
		new count=ProcessTargetString(arg,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,name,sizeof(name),isml);
		if (count > 0){
			for(new x=0;x<count;x++){
				new player=clients[x];
				if(IsPlayerAlive(player)){
					SndCount[player] = 0;
					new String:clientname[64];
					GetClientName(player,clientname,MAXPLAYERS);
					ReplyToCommand(client, "[Say Sounds] Quota has been reset for %s", clientname);
				}
			}
		}else{
			ReplyToTargetError(client, count);
		}
	}
	return Plugin_Handled;
}


public Action:Command_Sound_Ban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_ban <user> : Bans a player from using sounds");
		return Plugin_Handled;	
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));	

	decl String:name[64];
	new bool:isml,clients[MAXPLAYERS+1];
	new count=ProcessTargetString(arg,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,name,sizeof(name),isml);
	if (count > 0){
		for(new x=0;x<count;x++){
			new player=clients[x];
			if(IsPlayerAlive(player)){
				new String:clientname[64];
				GetClientName(player,clientname,MAXPLAYERS);
				if (restrict_playing_sounds[player] == 1){
					ReplyToCommand(client, "[Say Sounds] %s is already banned!", clientname);
				}else{
					restrict_playing_sounds[player]=1;
					ReplyToCommand(client,"[Say Sounds] %s has been banned!", clientname);
				}
			}
		}
	}else{
		ReplyToTargetError(client, count);
	}
	return Plugin_Handled;
}

public Action:Command_Sound_Unban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_unban <user> <1|0> : Unbans a player from using sounds");
		return Plugin_Handled;	
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));	

	decl String:name[64];
	new bool:isml,clients[MAXPLAYERS+1];
	new count=ProcessTargetString(arg,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,name,sizeof(name),isml);
	if (count > 0){
		for(new x=0;x<count;x++){
			new player=clients[x];
			if(IsPlayerAlive(player)){
				new String:clientname[64];
				GetClientName(player,clientname,MAXPLAYERS);
				if (restrict_playing_sounds[player] == 0){
					ReplyToCommand(client,"[Say Sounds] %s is not banned!", clientname);
				}else{
					restrict_playing_sounds[player]=0;
					ReplyToCommand(client,"[Say Sounds] %s has been unbanned!", clientname);
				}
			}
		}
	}else{
		ReplyToTargetError(client, count);
	}
	return Plugin_Handled;
}


public Action:Command_Sound_List(client, args){
	List_Sounds(client);
}

stock List_Sounds(client){
	KvRewind(listfile);
	if (KvJumpToKey(listfile, "ExitSound", false))
		KvGotoNextKey(listfile, true);
	else
		KvGotoFirstSubKey(listfile);

	decl String:buffer[PLATFORM_MAX_PATH+1];
	do{
		KvGetSectionName(listfile, buffer, sizeof(buffer));
		PrintToConsole(client, buffer);
	} while (KvGotoNextKey(listfile));
}

public Action:Command_Sound_Menu(client, args){
	Sound_Menu(client,false);
}

public Action:Command_Admin_Sounds(client, args){
	Sound_Menu(client,true);
}

public Sound_Menu(client, bool:adminsounds){
	if (adminsounds){
		new AdminId:aid = GetUserAdmin(client);
		new bool:isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);

		if (!isadmin){
			PrintToChat(client,"[Say Sounds] You must be an admin to play admin sounds!");
			return;
		}
	}

	new Handle:soundmenu=CreateMenu(Menu_Select);
	SetMenuExitButton(soundmenu,true);
	SetMenuTitle(soundmenu,"Choose a sound to play.");

	decl String:num[4];
	decl String:buffer[PLATFORM_MAX_PATH+1];
	new count=1;

	KvRewind(listfile);
	if (KvGotoFirstSubKey(listfile)){
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (!StrEqual(buffer, "JoinSound") &&
			    !StrEqual(buffer, "ExitSound") &&
			    strncmp(buffer,"STEAM_",6,false))
			{
				if (adminsounds){
					if (KvGetNum(listfile, "admin",0)){
						Format(num,3,"%d",count);
						AddMenuItem(soundmenu,num,buffer);
						count++;
					}
				}else{
					if (!KvGetNum(listfile, "admin",0)){
						Format(num,3,"%d",count);
						AddMenuItem(soundmenu,num,buffer);
						count++;
					}
				}
			}
		} while (KvGotoNextKey(listfile));
	}
	else{
		SetFailState("No subkeys found in the config file!");
	}

	DisplayMenu(soundmenu,client,MENU_TIME_FOREVER);
}

public Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select){
		decl String:SelectionInfo[4];
		decl String:SelectionDispText[PLATFORM_MAX_PATH+1];
		new SelectionStyle;
		if (GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText))){
			KvRewind(listfile);
			KvGotoFirstSubKey(listfile);
			decl String:buffer[PLATFORM_MAX_PATH];
			do{
				KvGetSectionName(listfile, buffer, sizeof(buffer));
				if (strcmp(SelectionDispText,buffer,false) == 0){
					Submit_Sound(client,buffer);
					break;
				}
			} while (KvGotoNextKey(listfile));
		}
	}else if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public OnMapEnd(){
	if (listfile != INVALID_HANDLE){
		CloseHandle(listfile);
		listfile = INVALID_HANDLE;
	}	
}

public OnPluginEnd()
{
	if (listfile != INVALID_HANDLE){
		CloseHandle(listfile);
		listfile = INVALID_HANDLE;
	}
}
