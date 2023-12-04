#include <sourcemod>
#include <tf2_stocks>
#include <sdktools_trace>
#include <clientprefs>

#define PLUGIN_VERSION  "1.3.0"

//A env_soundscape (or similar) entity
enum _:SoundscapeEntity {
	id,
	Float:position[3],
	String:targetName[30],
	String:soundscapeName[PLATFORM_MAX_PATH],
	disabled,
	Float:radius,
}

//A named section in the soundscape script
enum _:SoundscapeScript {
	Handle:looping,
	Handle:random,
}

// "playlooping" sound
enum _:SoundscapePlayLooping {
	Float:loopVolume,
	String:loopSound[PLATFORM_MAX_PATH],
	loopPitch,
	loopSoundLevel,
	loopPosition
}

// "playrandom" sound
enum _:SoundscapePlayRandom {
	Float:randomVolume,
	Handle:randomSounds,
	Float:randomTime,
	randomPitch,
	randomSoundLevel,
	randomPosition
}

enum Player {
	currentTrigger,
	Float:currentVolume,
	currentPitch,
	String:currentSoundscape[PLATFORM_MAX_PATH],
	Handle:randomTimers,
	bool:usedCookies
}

new gEnabled = false;

new gNumberSoundscapes = 0; //Number of total soundscapes

new Handle:gLoadForward = INVALID_HANDLE;

new Handle:gVolumeCookie = INVALID_HANDLE;
new Handle:gPitchCookie = INVALID_HANDLE;

new Handle:gSoundscapeTriggers = INVALID_HANDLE;
new gSoundscapes[200][SoundscapeEntity]; //Array of soundscape entities

new gPlayers[MAXPLAYERS][Player]; //Client details

new Handle:gMapping = INVALID_HANDLE; //Array of script soundscapes
new Handle:gUpdateTimer = INVALID_HANDLE; //Soundscape update timer


public Plugin:myinfo = {
	name = "[TF2] Soundscape Fixer",
	author = "Jim",
	description = "Workaround to get soundscapes playing while valve fix it",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart() {
	RegAdminCmd("sm_volume", Command_Volume, 0, "sm_volume [0.0 - 1.0] - Changes the volume of soundscapes");
	RegAdminCmd("sm_scvolume", Command_Volume, 0, "sm_scvolume [0.0 - 1.0] - Changes the volume of soundscapes");
	RegAdminCmd("sm_scpitch", Command_Pitch, 0, "sm_scpitch [1 - 255, 0 to reset] - Changes the pitch of soundscapes");

	gLoadForward = CreateGlobalForward("OnSoundscapesLoaded", ET_Ignore);
	gVolumeCookie = RegClientCookie("soundscape_volume", "Soundscape Fixer Volume", CookieAccess_Protected);
	gPitchCookie = RegClientCookie("soundscape_pitch", "Soundscape Fixer Pitch", CookieAccess_Protected);

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundActive);
	HookEvent("player_spawn", Event_Spawn);
}

public OnPluginEnd() {
	for(new i = 1; i < MaxClients; i++) {
		PlaySoundscape(i, "", true);
	}

	for(new i = 0; i < 200; i++) {
		new index = gSoundscapes[i][id];

		if(IsValidEntity(index)) {
			if(gSoundscapes[i][disabled]) {
				AcceptEntityInput(index, "Disable");
				SetEntProp(index, Prop_Data, "m_bDisabled", true);
			} else {
				AcceptEntityInput(index, "Enable");
				SetEntProp(index, Prop_Data, "m_bDisabled", false);
			}
		}
	}

	ClearData();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
   CreateNative("DisableSoundscapesByName", Native_DisableSoundscapesByName);
   CreateNative("DisableSoundscapeById", Native_DisableSoundscapeById);
   CreateNative("EnableSoundscapesByName", Native_EnableSoundscapesByName);
   CreateNative("EnableSoundscapeById", Native_EnableSoundscapeById);
   
   return APLRes_Success;
}

//Determine map and precache appropriate sounds
public OnMapStart() {
	ClearData();

	gMapping = CreateTrie();
	gSoundscapeTriggers = CreateTrie();
	gEnabled = MapSounds();

	FindSoundscapeEntities();

	Call_StartForward(gLoadForward);
	Call_Finish();

	for(new i = 0; i < MAXPLAYERS; i++) {
		gPlayers[i][randomTimers] = CreateArray();
	}

	if(gUpdateTimer != INVALID_HANDLE) {
		KillTimer(gUpdateTimer);
		gUpdateTimer = INVALID_HANDLE;
	}

	gUpdateTimer = CreateTimer(0.3, UpdateSoundscapes, INVALID_HANDLE, TIMER_REPEAT);
}

public OnClientConnected(client) {
	gPlayers[client][currentVolume] = 1.0;
	gPlayers[client][currentPitch] = 0;
	gPlayers[client][currentTrigger] = -1;
	gPlayers[client][usedCookies] = false;
	strcopy(gPlayers[client][currentSoundscape], 1, "");
	ClearArray(gPlayers[client][randomTimers]);
}

public OnClientCookiesCached(client) {
	new String:savedVolume[5];
	new String:savedPitch[5];

	GetClientCookie(client, gVolumeCookie, savedVolume, sizeof(savedVolume));
	GetClientCookie(client, gPitchCookie, savedPitch, sizeof(savedPitch));
	
	new volumeLength = strlen(savedVolume);
	new pitchLength =  strlen(savedPitch);

	if(volumeLength || pitchLength) {
		if(volumeLength) {
			gPlayers[client][currentVolume] = StringToFloat(savedVolume);
		}

		if(pitchLength) {
			gPlayers[client][currentPitch] = StringToInt(savedPitch);
		}

		if(IsClientInGame(client)) {
			PlaySoundscape(client, gPlayers[client][currentSoundscape], true);
		}
	}
}

public Action:Command_Volume(client, args) {
	decl String:newVolume[30];
	new Float:amount;

	if(!gEnabled) {
		ReplyToCommand(client, "[SM] Soundscape fixer is not enabled on this map");
		return Plugin_Handled;
	}

	if(args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_volume [0.0 - 1.0]");
		return Plugin_Handled;
	}

	GetCmdArg(1, newVolume, sizeof(newVolume));
	StringToFloatEx(newVolume, amount);
	
	if(amount < 0.0 || amount > 1.0) {
		ReplyToCommand(client, "[SM] Please enter a value between 0.0 and 1.0");
		return Plugin_Handled;
	}

	gPlayers[client][currentVolume] = amount;

	if(AreClientCookiesCached(client)) {
		if(amount == 1.0) {
			SetClientCookie(client, gVolumeCookie, "");
		} else {
			decl String:savedVolume[5];

			FloatToString(amount, savedVolume, sizeof(savedVolume));
			SetClientCookie(client, gVolumeCookie, savedVolume);
		}
	}

	PlaySoundscape(client, gPlayers[client][currentSoundscape], true);

	ReplyToCommand(client, "[SM] Soundscape volume changed to %.2f", gPlayers[client][currentVolume]);

	return Plugin_Handled;
}

public Action:Command_Pitch(client, args) {
	decl String:newPitch[30];
	new amount;

	if(!gEnabled) {
		ReplyToCommand(client, "[SM] Soundscape fixer is not enabled on this map");
		return Plugin_Handled;
	}

	if(args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_scpitch [1 - 255, 0 to reset]");
		return Plugin_Handled;
	}

	GetCmdArg(1, newPitch, sizeof(newPitch));
	amount = StringToInt(newPitch);
	
	if(amount < 0 || amount > 255) {
		ReplyToCommand(client, "[SM] Please enter a value between 1 and 255. Use 100 for normal pitch or 0 for map specified pitch");
		return Plugin_Handled;
	}

	gPlayers[client][currentPitch] = amount;

	if(AreClientCookiesCached(client)) {
 		if(amount) {
			decl String:savedPitch[5];
			
			IntToString(amount, savedPitch, sizeof(savedPitch));
			SetClientCookie(client, gPitchCookie, savedPitch);
 		} else {
			SetClientCookie(client, gPitchCookie, "");
 		}
	}

	PlaySoundscape(client, gPlayers[client][currentSoundscape], true);

	if(amount) {
		ReplyToCommand(client, "[SM] Soundscape pitch changed to %d", gPlayers[client][currentPitch]);
	} else {
		ReplyToCommand(client, "[SM] Soundscape pitch reset");
	}

	return Plugin_Handled;
}

//Reset soundscape on player spawn
public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!gEnabled) {
		return;
	}

	gPlayers[client][currentTrigger] = -1;

	//PlaySoundscape(client, "", true);
}

//Find soundscape entities, remove existing sounds and start the update timer
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {	
	for(new i = 1; i < MaxClients; i++) {
		PlaySoundscape(i, "", true);
	}
}

public Action:Event_RoundActive(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!gEnabled) {
		return;
	}

	PrintToChatAll("[TF2] Soundscapes Fixer v%s - By Jim", PLUGIN_VERSION);
	PrintToChatAll("Use /scvolume and /scpitch to control how soundscapes play");
}


public ClearData() {
	//snew Float:time = GetEngineTime();

	for(new i = 0; i < 200; i++) {
		new soundscape[SoundscapeScript];

		gSoundscapes[i][id] = -1;
		gSoundscapes[i][position] = NULL_VECTOR;
		gSoundscapes[i][disabled] = true;
		gSoundscapes[i][radius] = 0.0;
		strcopy(gSoundscapes[i][targetName], 1, "");

		if(gMapping != INVALID_HANDLE) {
			if(GetTrieArray(gMapping, gSoundscapes[i][soundscapeName], soundscape, SoundscapeScript)) {
				new randomSize = GetArraySize(soundscape[random]);
				
				CloseHandle(soundscape[looping]);

				for(new j = 0; j < randomSize; j++) {
					new playRandom[SoundscapePlayRandom];
					GetArrayArray(soundscape[random], j, playRandom);

					CloseHandle(playRandom[randomSounds]);
				}

				CloseHandle(soundscape[random]);
				RemoveFromTrie(gMapping, gSoundscapes[i][soundscapeName]);
			}
		}
		
		strcopy(gSoundscapes[i][soundscapeName], 1, "");			
	}
	
	if(gMapping != INVALID_HANDLE) {
		CloseHandle(gMapping);
		gMapping = INVALID_HANDLE;
	}

	if(gSoundscapeTriggers != INVALID_HANDLE) {
		CloseHandle(gSoundscapeTriggers);
		gSoundscapeTriggers = INVALID_HANDLE;
	}
	
	gNumberSoundscapes = 0;

	for(new i = 1; i < MaxClients; i++) {
		gPlayers[i][currentVolume] = 1.0;
		gPlayers[i][currentPitch] = 0;
		gPlayers[i][currentTrigger] = -1;
		strcopy(gPlayers[i][currentSoundscape], 1, "");

		if(gPlayers[i][randomTimers] != INVALID_HANDLE) {
			CloseHandle(gPlayers[i][randomTimers]);
			gPlayers[i][randomTimers] = INVALID_HANDLE;
		}
	}

	//LogMessage("Cleared data in %.2f seconds", GetEngineTime() - time);
}

//Precache appropriate sounds
public MapSounds() {
	new String:map[50];
	new String:configPath[PLATFORM_MAX_PATH];
	new String:scriptPath[PLATFORM_MAX_PATH];
	new Handle:config = CreateKeyValues("Soundscape");
	new Handle:script = CreateKeyValues("");
	new opened;

	GetCurrentMap(map, sizeof(map));

	BuildPath(Path_SM, configPath, PLATFORM_MAX_PATH, "configs/soundscapes_config.txt");

	opened = FileToKeyValues(config, configPath);

	if(!opened) {
		SetFailState("Failed to load config file addons/sourcemod/configs/soundscapes_config.txt");
		return false;
	}

	if(KvJumpToKey(config, map, false)) {
		KvGetString(config, NULL_STRING, scriptPath, PLATFORM_MAX_PATH);

		opened = FileToKeyValues(script, scriptPath);

		if(opened) {
			LogMessage("Using user-specified soundscape script %s", scriptPath);
			ParseScript(script);
			return true;
		}

		LogMessage("Failed to load user-specified soundscape script %s. Using default.", scriptPath);
	} else {
		LogMessage("No user-specified soundscape script found. Using default.")
	}

	Format(scriptPath, PLATFORM_MAX_PATH, "scripts/soundscapes_%s.txt", map);

	opened = FileToKeyValues(script, scriptPath);

	if(!opened) {
		SetFailState("Failed to load default soundscape script %s. Plugin disabled.", scriptPath);
		return false;
	}

	LogMessage("Using default soundscape script %s", scriptPath);
	ParseScript(script);
	return true;
}

//Parse the soundscape script file to find all the named soundscapes
//and the sound files they map to
public ParseScript(Handle:kv) {
	new loaded = 0;
	new Float:time = GetEngineTime();

	do {
		if(KvGotoFirstSubKey(kv, false)) {
			decl String:keyName[50];
			decl script[SoundscapeScript];

			script[looping] = CreateArray(SoundscapePlayLooping);
			script[random] = CreateArray(SoundscapePlayRandom);

			ParseSoundscape(kv, script);

			KvGoBack(kv);

			if(GetArraySize(script[looping]) || GetArraySize(script[random])) {
				KvGetSectionName(Handle:kv, keyName, 50);
				StrToLower(keyName);

				SetTrieArray(gMapping, keyName, script, SoundscapeScript, true);
				loaded++;

				//LogMessage("Found soundscape %s with %d playlooping and %d playrandom", keyName, GetArraySize(script[looping]), GetArraySize(script[random]));
			}

			KvGoBack(kv);

		}
	} while(KvGotoNextKey(kv, false));

	LogMessage("Loaded %d soundscape mappings from script file in %.2f seconds", loaded, GetEngineTime() - time);
}

//Parse a single named soundscape in the script file
public ParseSoundscape(Handle:kv, script[]) {
	do {
		decl String:keyValue[50];
		decl String:keyName[50];

		KvGetSectionName(Handle:kv, keyName, 50);
		KvGetString(Handle:kv, NULL_STRING, keyValue, 50);

		if(KvGotoFirstSubKey(kv, false)) {
			if(StrEqual(keyName, "playlooping", false)) {
				new playLooping[SoundscapePlayLooping];

				ParsePlayLooping(kv, playLooping);

				if(strlen(playLooping[loopSound])) {
					PushArrayArray(script[looping], playLooping);
				}

			} else if(StrEqual(keyName, "playrandom", false)) {
				new playRandom[SoundscapePlayRandom];
				playRandom[randomSounds] = CreateArray(PLATFORM_MAX_PATH);

				ParsePlayRandom(kv, playRandom);

				if(GetArraySize(playRandom[randomSounds])) {
					PushArrayArray(script[random], playRandom);
				}
			}

			KvGoBack(kv);
		}
	} while(KvGotoNextKey(kv, false));
}

//Parse a "playlooping" section in a named soundscape in the script file
public ParsePlayLooping(Handle:kv, playLooping[]) {
	do {
		decl String:keyValue[PLATFORM_MAX_PATH];
		decl String:keyName[50];

		KvGetSectionName(Handle:kv, keyName, 50);

		if(StrEqual(keyName, "volume")) {
			playLooping[loopVolume] = KvGetFloat(kv, NULL_STRING, 1.0);
			continue;
		}

		if(StrEqual(keyName, "pitch")) {
			playLooping[loopPitch] = KvGetNum(kv, NULL_STRING, 100);
			continue;
		}
		
		if(StrEqual(keyName, "soundlevel")) {
			playLooping[loopSoundLevel] = KvGetNum(kv, NULL_STRING, 70);
			continue;
		}
		
		if(StrEqual(keyName, "wave")) {
			KvGetString(kv, NULL_STRING, keyValue, PLATFORM_MAX_PATH);
			strcopy(playLooping[loopSound], PLATFORM_MAX_PATH, keyValue);
			PrecacheSound(keyValue);
			continue;
		}

	} while(KvGotoNextKey(kv, false));
}

//Parse a "playrandom" section in a named soundscape in the script file
public ParsePlayRandom(Handle:kv, playRandom[]) {
	do {
		decl String:keyValue[PLATFORM_MAX_PATH];
		decl String:keyName[50];

		KvGetSectionName(Handle:kv, keyName, 50);

		if(StrEqual(keyName, "time")) {
			playRandom[randomTime] = KvGetFloat(kv, NULL_STRING, 1.0);
			continue;
		}

		if(StrEqual(keyName, "volume")) {
			playRandom[randomVolume] = KvGetFloat(kv, NULL_STRING, 1.0);
			continue;
		}

		if(StrEqual(keyName, "pitch")) {
			playRandom[randomPitch] = KvGetNum(kv, NULL_STRING, 100);
			continue;
		}
		
		if(StrEqual(keyName, "soundlevel")) {
			playRandom[randomSoundLevel] = KvGetNum(kv, NULL_STRING, 70);
			continue;
		}
		
		if(StrEqual(keyName, "rndwave")) {
			if(KvGotoFirstSubKey(kv, false)) {
				do {
					KvGetString(Handle:kv, NULL_STRING, keyValue, PLATFORM_MAX_PATH);
					PrecacheSound(keyValue);
					PushArrayString(playRandom[randomSounds], keyValue);
				} while(KvGotoNextKey(kv, false));

				KvGoBack(kv);
			}
			continue;
		}

	} while(KvGotoNextKey(kv, false));
}

//Find soundscape entities and proxies
public FindSoundscapeEntities() {
	new index = -1;
	new Float:time = GetEngineTime();

	while((index = FindEntityByClassname(index, "env_soundscape")) != -1) {
		AddSoundscape(index, false);
	}

	while((index = FindEntityByClassname(index, "env_soundscape_proxy")) != -1) {
		AddSoundscape(index, true);
	}

	while((index = FindEntityByClassname(index, "env_soundscape_triggerable")) != -1) {
		AddSoundscape(index, false);
	}

	while((index = FindEntityByClassname(index, "trigger_soundscape")) != -1) {
		decl String:triggerTarget[30];

		GetEntPropString(index, Prop_Data, "m_SoundscapeName", triggerTarget, 30);

		for(new i = 0; i < gNumberSoundscapes; i++) {
			if(StrEqual(triggerTarget, gSoundscapes[i][targetName])) {
				decl String:indexString[5];

				IntToString(index, indexString, 4);

				SetTrieValue(gSoundscapeTriggers, indexString, i, true);
				HookSingleEntityOutput(index, "OnStartTouch", Event_OnSoundscapeStartTouch);		
				HookSingleEntityOutput(index, "OnEndTouch", Event_OnSoundscapeEndTouch);		
				break;
			}
		}
	}

	time = GetEngineTime() - time;
	LogMessage("Found %d soundscape entities in %f seconds", gNumberSoundscapes, time);
}

//Add a soundscape to the array
//Storing its location, radius and sound name
//If it is a proxy, the sound name of the main soundscape is stored instead
public AddSoundscape(index, proxy) {
	if(gNumberSoundscapes >= 200) {
		LogMessage("Maximum number of soundscapes (200) reached!");
		return;
	}

	new soundscape[SoundscapeEntity];
	new String:entityTargetName[30];
	new String:name[PLATFORM_MAX_PATH];
	new Float:origin[3];

	//Use the soundscape name of the main soundscape if this is a proxy
	if(proxy) {
		new entity = -1;

		GetEntPropString(index, Prop_Data, "m_MainSoundscapeName", name, PLATFORM_MAX_PATH);

		while ((entity = FindEntityByClassname(entity, "env_soundscape")) != -1) {
			GetEntPropString(entity, Prop_Data, "m_iName", entityTargetName, PLATFORM_MAX_PATH);

			if(StrEqual(name, entityTargetName)) {
				GetEntPropString(entity, Prop_Data, "m_soundscapeName", name, PLATFORM_MAX_PATH);
				break;
			}
		}

		if(entity < 0) {
			return;
		}

	} else {
		GetEntPropString(index, Prop_Data, "m_soundscapeName", name, PLATFORM_MAX_PATH);
	}

	GetEntPropString(index, Prop_Data, "m_iName", entityTargetName, PLATFORM_MAX_PATH);
	GetEntPropVector(index, Prop_Send, "m_vecOrigin", origin);

	StrToLower(name);

	strcopy(soundscape[soundscapeName], PLATFORM_MAX_PATH, name);
	strcopy(soundscape[targetName], 30, entityTargetName);
	
	soundscape[id] = index;
	soundscape[radius] = GetEntPropFloat(index, Prop_Data, "m_flRadius");
	soundscape[position] = origin;
	soundscape[disabled] = GetEntProp(index, Prop_Data, "m_bDisabled");

	gSoundscapes[gNumberSoundscapes] = soundscape;

	gNumberSoundscapes++;

	AcceptEntityInput(index, "Disable");
	AcceptEntityInput(index, "Disabled");
}

//Play a soundscape to a player
public PlaySoundscape(client, String:name[], bool:force) {
	decl soundscape[SoundscapeScript];
	new size = 0;

	if(client > MAXPLAYERS || client < 0 || !IsClientInGame(client)) {
		return;
	}

	//Ignore soundscapes that are already playing
	if(StrEqual(gPlayers[client][currentSoundscape], name, false) && !force) {
		return;	
	}

	//PrintToChat(client, "Playing soundscape %s", name);

	if(strlen(gPlayers[client][currentSoundscape])) {
		if(GetTrieArray(gMapping, gPlayers[client][currentSoundscape], soundscape, SoundscapeScript)) {
			
			new playLoopings = GetArraySize(soundscape[looping]);

			for(new i = 0; i < playLoopings; i++) {
				new playLooping[SoundscapePlayLooping];

				GetArrayArray(soundscape[looping], i, playLooping);
				StopSound(client, SNDCHAN_STATIC, playLooping[loopSound]);				
			}

			//PrintToChat(client, "Stopped %d looping sounds", playLoopings);
		}
	}

	if(gPlayers[client][randomTimers] != INVALID_HANDLE) {
		if((size = GetArraySize(gPlayers[client][randomTimers]))) {
			for(new i = 0; i < size; i++) {
				KillTimer(GetArrayCell(gPlayers[client][randomTimers], i));
			}

			ClearArray(gPlayers[client][randomTimers]);

			//PrintToChat(client, "Cleared %d random sound timers", size);
		}
	}

	strcopy(gPlayers[client][currentSoundscape], PLATFORM_MAX_PATH, name);

	if(strlen(name)) {
		if(GetTrieArray(gMapping, name, soundscape, SoundscapeScript)) {
			
			new playLoopings = GetArraySize(soundscape[looping]);
			new playRandoms = GetArraySize(soundscape[random]);

			for(new i = 0; i < playLoopings; i++) {
				decl playLooping[SoundscapePlayLooping];

				GetArrayArray(soundscape[looping], i, playLooping);
				PlaySound(client, playLooping[loopSound], playLooping[loopVolume], playLooping[loopPitch]);			

			}

			//PrintToChat(client, "Started %d looping sounds", playLoopings);	

			for(new i = 0; i < playRandoms; i++) {
				decl playRandom[SoundscapePlayRandom];
				new Handle:data;
				new Handle:timer;

				GetArrayArray(soundscape[random], i, playRandom);
				timer = CreateDataTimer(Float:playRandom[randomTime], PlayRandomSound, data, TIMER_REPEAT);

				WritePackCell(data, GetClientUserId(client));
				WritePackCell(data, playRandom[randomSounds]);

				PushArrayCell(gPlayers[client][randomTimers], timer);
			}

			//PrintToChat(client, "Created %d random sound timers", playRandoms);
		}
	}
}

public Action:PlayRandomSound(Handle:timer, any:data) {
	ResetPack(data);

	new client = GetClientOfUserId(ReadPackCell(data));

	if(!client || !IsClientInGame(client)) {
		return Plugin_Stop;
	}

	new Handle:sounds = ReadPackCell(data);
	new size = GetArraySize(sounds);
	new chosen = GetRandomInt(0, size - 1);
	decl String:file[PLATFORM_MAX_PATH];

	GetArrayString(sounds, chosen, file, PLATFORM_MAX_PATH);

	PlaySound(client, file, 1.0, 100);

	return Plugin_Continue;
}

public PlaySound(client, String:playTrack[], Float:playVolume, playPitch) {
	EmitSoundToClient(
		client,
		playTrack,
		SOUND_FROM_PLAYER,
		SNDCHAN_STATIC,
		SNDLEVEL_HOME,
		SND_NOFLAGS,
		playVolume * gPlayers[client][currentVolume],
        (gPlayers[client][currentPitch]) ? gPlayers[client][currentPitch] : playPitch,
		-1,
		NULL_VECTOR,
		NULL_VECTOR,
		true,
		0.0
	);
}

public StopPlayingSound(client, String:stopTrack[]) {
	EmitSoundToClient(
		client,
		stopTrack,
		SOUND_FROM_PLAYER,
		SNDCHAN_STATIC,
		SNDLEVEL_HOME,
		SND_STOP | SND_STOPLOOPING,
		0.0,
		100,
		-1,
		NULL_VECTOR,
		NULL_VECTOR,
		true,
		0.0
	);
}

//Find the closest eligible soundscape to each player and play it to them
public Action:UpdateSoundscapes(Handle:timer, any:data) {
	new Float:time = GetEngineTime();
	new checked = 0;
	
	for(new i = 1; i <= MaxClients; i++) {
		if(i > MAXPLAYERS || i < 0 || !IsClientInGame(i)) {
			continue;
		}

		new closest = FindClosestSoundscape(i, false);
		checked++;
		
		//Play the closest soundscape
		if(closest > -1) {
			PlaySoundscape(i, gSoundscapes[closest][soundscapeName], false);
		} else if(gPlayers[i][currentTrigger] > -1) {
			PlaySoundscape(i, gSoundscapes[gPlayers[i][currentTrigger]][soundscapeName], false);
		}
	}

	time = GetEngineTime() - time;

	//LogMessage("Updated soundscapes for %d clients in %f seconds", checked, time);

	return Plugin_Continue;
}

public FindClosestSoundscape(client, bool:ignoreRange) {
	new closest = -1;
	new Float:closestDistance = -1.0;
	decl Float:playerPosition[3];
	decl Float:soundscapePosition[3];

	GetClientEyePosition(client, playerPosition);

	for(new j = 0; j < gNumberSoundscapes; j++) {
		//Direct array assignments crash the server for some reason
		soundscapePosition[0] =  gSoundscapes[j][position][0];
		soundscapePosition[1] =  gSoundscapes[j][position][1];
		soundscapePosition[2] =  gSoundscapes[j][position][2];

		//Ignore disabled soundscapes
		if(gSoundscapes[j][disabled]) {
			continue;
		}

		new Float:distance = GetVectorDistance(playerPosition, soundscapePosition);

		//Ignore soundscapes that are out of range
		if(!ignoreRange && gSoundscapes[j][radius] > 0 && distance > gSoundscapes[j][radius]) {
			continue;
		}

		//If this soundscape is the closest so far, do a raytrace to check if its in visible range
		if(closest < 0 || closestDistance < 0 || distance < closestDistance) {
			TR_TraceRayFilter(playerPosition, soundscapePosition, CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE, RayType_EndPoint, TraceRayDontHitPlayersOrProps, client);
			
			if(!TR_DidHit(INVALID_HANDLE)) {
				closest = j;
				closestDistance = distance;
				continue;
			}

			continue;
		}
	}

	return closest;
}

public bool:TraceRayDontHitPlayersOrProps(entity, mask, any:data) {
	if(entity < MaxClients) {
		return false;
	}

	new String:class[15];

	GetEntityClassname(entity, class, 14);

	if(!strcmp(class, "prop_dynamic", false)) {
		return false;
	}

	return true;
}

public Event_OnSoundscapeStartTouch(const String:output[], caller, activator, Float:delay) {
	new targetSoundscape = -1;
	new String:callerString[10];


	IntToString(caller, callerString, 9);

	if(GetTrieValue(gSoundscapeTriggers, callerString, targetSoundscape)) {
		if(IsClientInGame(activator)) {
			new index = gSoundscapes[targetSoundscape][id];

			gPlayers[activator][currentTrigger] = targetSoundscape;
			AcceptEntityInput(index, "Disable");
			AcceptEntityInput(index, "Disabled");
		}
	}
}

public Event_OnSoundscapeEndTouch(const String:output[], caller, activator, Float:delay) {
	if(IsClientInGame(activator) && gPlayers[activator][currentTrigger] == caller) {
		gPlayers[activator][currentTrigger] = -1;
	}
}

public Native_DisableSoundscapesByName(Handle:plugin, numParams) {
	new length;
	new found = 0;
   	GetNativeStringLength(1, length);
	 
   	if (length <= 0) {
		return 0;
	}
	 
	new String:name[length + 1];
	GetNativeString(1, name, length + 1);

	for(new i = 0; i < gNumberSoundscapes; i++) {
		if(StrEqual(gSoundscapes[i][soundscapeName], name)) {

			AcceptEntityInput(gSoundscapes[i][id], "Disable");
			AcceptEntityInput(gSoundscapes[i][id], "Disabled");
			gSoundscapes[i][disabled] = true;
			found++;
		}
	}

	LogMessage("Disabled %d soundscapes with name %s", found, name);

	return found;
}

public Native_DisableSoundscapeById(Handle:plugin, numParams) {
	new targetID = GetNativeCell(1);

	for(new i = 0; i < gNumberSoundscapes; i++) {
		if(gSoundscapes[i][id] == targetID) {

			AcceptEntityInput(gSoundscapes[i][id], "Disable");
			AcceptEntityInput(gSoundscapes[i][id], "Disabled");
			gSoundscapes[i][disabled] = true;
			LogMessage("Disabled soundscape with id %d", targetID);
			
			return true;
		}
	}

	LogMessage("Soundscape with id %d not found", targetID);

	return false;
}

public Native_EnableSoundscapesByName(Handle:plugin, numParams) {
	new length;
	new found = 0;
	GetNativeStringLength(1, length);
	 
	if (length <= 0) {
		return 0;
	}
	 
	new String:name[length + 1];
	GetNativeString(1, name, length + 1);

	for(new i = 0; i < gNumberSoundscapes; i++) {
		if(StrEqual(gSoundscapes[i][soundscapeName], name)) {

			gSoundscapes[i][disabled] = false;
			found++;
		}
	}

	LogMessage("Enabled %d soundscapes with name %s", found, name);

	return found;
}

public Native_EnableSoundscapeById(Handle:plugin, numParams) {
	new targetID = GetNativeCell(1);

	for(new i = 0; i < gNumberSoundscapes; i++) {
		if(gSoundscapes[i][id] == targetID) {

			gSoundscapes[i][disabled] = true;
			LogMessage("Enabled soundscape with id %d", targetID);
			
			return true;
		}
	}

	LogMessage("Soundscape with id %d not found", targetID);

	return false;
}

public StrToLower(String:buffer[]) {
	new length = strlen(buffer);

	for(new i = 0; i < length; i++) {
		buffer[i] = CharToLower(buffer[i]);
	}
}