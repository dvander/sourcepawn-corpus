/*
plugin plays random sound from list of sounds at "teamplay_round_win" event
make sure that your tf\pure_server_whitelist.txt contains string with allow your sounds from client
Example:

sound\endmusic\*.*	allow_from_disk+check_crc

*/


#include <sourcemod>
#include <sdktools>
#pragma dynamic 131072


new Handle:listfile = INVALID_HANDLE;
new String:soundlistfile[PLATFORM_MAX_PATH] = "";
new Handle:soundfiles = INVALID_HANDLE;
new count;

 public Plugin:myinfo =
{
	name = "TF2 endround sound",
	author = "omgiafs",
	description = "Plays random sound from set of sounds at teamplay_round_win event",
	version = "1.0.0.0",
};
 
public OnPluginStart()
{
	HookEvent("teamplay_round_win", PlaySound);
	soundfiles = CreateArray(PLATFORM_MAX_PATH+1);
}

public PlaySound(Handle:event, const String:name[], bool:dontBroadcast)
{
	new soundnumber = GetRandomInt(0,GetArraySize(soundfiles)-1); //number of sound in sound's array
	decl String:filetoplay[PLATFORM_MAX_PATH+1]; // path to choosen sound
	GetArrayString(soundfiles, soundnumber, filetoplay, sizeof(filetoplay)) //get path to choosen sound
	decl String:buffer[PLATFORM_MAX_PATH+1]; //command to client
	Format(buffer, sizeof(buffer), "play %s", (filetoplay), SNDLEVEL_GUNFIRE); //compile command
	for(new i = 1; i <= GetMaxClients(); i++) 
	if(IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i)) //for all real and in-game clients
	{
		ClientCommand((i), buffer); //send command to client
	}
}

public OnMapStart()
{
	ClearArray(soundfiles);
	count=1;
	CreateTimer(0.2, Load_Sounds);
}

public OnMapEnd()
{
	ClearArray(soundfiles);
}

public Action:Load_Sounds(Handle:timer)
{
	// precache sounds, loop through sounds
	BuildPath(Path_SM,soundlistfile,sizeof(soundlistfile),"configs/endroundsound.cfg");
	if(!FileExists(soundlistfile)) {
		SetFailState("endroundsound.cfg not parsed...file doesnt exist!");
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
				count = KvGetNum(listfile, "count", 1);
				new download = KvGetNum(listfile, "download", 1);
				for (new i = 0; i <= count; i++){
					if (i){
						Format(file, sizeof(file), "file%d", i);
					}else{
						strcopy(file, sizeof(file), "file");
					}
					filelocation[0] = '\0';
					KvGetString(listfile, file, filelocation, sizeof(filelocation), "");
					if (filelocation[0] != '\0'){
						Format(dl, sizeof(dl), "sound/%s", filelocation);
						PrecacheSound(filelocation, true);
						PushArrayString(soundfiles, filelocation);
						if(download && FileExists(dl)){
							AddFileToDownloadsTable(dl);
						}
					}
				}
			} while (KvGotoNextKey(listfile));
		}
		else{
			SetFailState("endroundsound.cfg not parsed...No subkeys found!");
		}
	}
	return Plugin_Handled;
}