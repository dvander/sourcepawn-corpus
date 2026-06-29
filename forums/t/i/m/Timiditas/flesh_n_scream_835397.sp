/*
flesh_n_scream.sp

Description:
	Plays scream and blood spurt / flesh hit sounds on player hurt/death

ConVars:
sm_fleshscream_version			-	version number
sm_fleshscream_enable				-	enable/disable plugin
sm_fleshscream_spurt				- Chance in percent of a blood spurt sound to play
sm_fleshscream_hit					- Chance in percent of a flesh hit sound to play
sm_fleshscream_dead					- Chance in percent of a dying player scream sound to play
sm_fleshscream_hurt					- Chance in percent of a hit player moan sound to play
sm_fleshscream_volume				- Volume of the plugin from 0.0 to 1.0
sm_fleshscream_randompitch	- Slight randomization of the pitch of all sounds
***New since 1.0:
sm_fleshscream_announce - Chatmessage to tell new users how to deactivate the sounds for themselves (just like the quakesounds chat announcement) - Default: 1
sm_fleshscream_announce_delay - Time in seconds after client connect when the message is shown in chat. - Default: 40.0
The new cvars are not automatically added to an existing cfg file.
  chatcommand: !fleshscream (see below)
***New since 1.1:
sm_fleshscream_override - prevent players from switching the sounds off (their setting is still saved though)

blood spurt, flesh hit and hit player moan are being played all over the others, so use these sparingly

the included dying player sounds are rather loud and long, these shouldn't occur too often. use them as a surprise sound with
a chance of 20% or something like that...

Versions:
	0.1
		* Prototype Release
		# Todo:
				Hook cvarEnable change and hook/unhook events
				Add sound configuration via config file (implements having as much sounds of a type as you wish)
				~Overlapping of hit sounds doesn't seem to work - affects death sounds also
	0.2
		hooked cvarEnable changed and acting accordingly
		bugfix for:
			plugin ignoring the randompitch and volume settings
			sounds being skipped when there should play multiple at once
	0.25
		switched from static constant string arrays to adt_arrays
	0.5
		added soundlist via config file:
		addons/sourcemod/configs/fleshscream.cfg
	1.0
		added possibility for clients to turn this sounds off for themselves (taken from quake sounds plugin)
		there is NO announcement of the chat command. let your users know via advertisements plugin or request announcement feature
		end of test phase, awaiting approval
	1.1
		added convar "sm_fleshscream_override"
		forces sounds to be played for players that have their fleshscream setting turned off
		added conditional skip of code on plugin disabled (forgot that, in functions player_hurt and player_death)
	1.1b
		changed sendsound channel to "SNDCHAN_STATIC" as suggested by TESLA-X4 on alliedmods.net
		added sending the sounds to sourcetv on demand (cvar: sm_fleshscream_recordsounds 1/0)
	1.1c
		just a small performance update and possible memleak fix
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1c"

#define PathLen 96

//Client settings, taken quake sounds plugin as master
new Handle:kvFSS;
new String:fileFSS[PathLen];
new soundPreference[MAXPLAYERS + 1];


new fns_enabled = 1;

new Handle:cvarEnable = INVALID_HANDLE;
new Handle:cvarSpurt = INVALID_HANDLE;
new Handle:cvarHit = INVALID_HANDLE;
new Handle:cvarDead = INVALID_HANDLE;
new Handle:cvarHurt = INVALID_HANDLE;
new Handle:cvarVolume = INVALID_HANDLE;
new Handle:cvarRandomPitch = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:cvarAnnounceDelay = INVALID_HANDLE;
new Handle:cvarAdminOverride = INVALID_HANDLE;
new Handle:cvarRecordSound = INVALID_HANDLE;
new Handle:hfile = INVALID_HANDLE;
new String:sfile[PLATFORM_MAX_PATH] = "";
new String:s_TVName[66];

new announce_enabled = 1;
new record_sound = 1;
new admin_override = 0;
new Float:announce_delay = 40.0;
new randompitch = 1;
new Float:fns_volume = 0.99;
new spurt_chance = 30;
new hit_chance = 90;
new dead_chance = 40;
new hurt_chance = 50;

new spurt_count = 0;
new hit_count = 0;
new dead_count = 0;
new hurt_count = 0;

new Handle:c_blood_spurt = INVALID_HANDLE;
new Handle:c_flesh_hit = INVALID_HANDLE;
new Handle:c_player_dead = INVALID_HANDLE;
new Handle:c_player_hurt = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Flesh'n'scream",
	author = "Timiditas",
	description = "Plays custom sounds on player hurt/death",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=93272"
};

public OnPluginStart() {
	CreateArrays();
	CreateConVar("sm_fleshscream_version", PLUGIN_VERSION, "Flesh'n'Scream Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnable = CreateConVar("sm_fleshscream_enable", "1", "Enable/Disable the plugin");
	cvarSpurt = CreateConVar("sm_fleshscream_spurt", "30", "Chance in percent of a blood spurt sound to play");
	cvarHit = CreateConVar("sm_fleshscream_hit", "90", "Chance in percent of a flesh hit sound to play");
	cvarDead = CreateConVar("sm_fleshscream_dead", "40", "Chance in percent of a dying player scream sound to play");
	cvarHurt = CreateConVar("sm_fleshscream_hurt", "50", "Chance in percent of a hit player moan sound to play");
	cvarVolume = CreateConVar("sm_fleshscream_volume", "0.99", "Volume of the plugin from 0.0 to 1.0");
	cvarRandomPitch = CreateConVar("sm_fleshscream_randompitch", "1", "Slight randomization of the pitch of all sounds");
	cvarAnnounce = CreateConVar("sm_fleshscream_announce", "1", "Tell new players how to switch off fleshscream sounds");
	cvarAnnounceDelay = CreateConVar("sm_fleshscream_announce_delay", "40.0", "Time in seconds after a client connects, when the announcement is shown");
	cvarAdminOverride = CreateConVar("sm_fleshscream_override", "0", "Override Usersetting/Force all players to hear the sounds");
	cvarRecordSound = CreateConVar("sm_fleshscream_recordsounds", "1", "Enables sourceTV to record the sounds");
	RegConsoleCmd("fleshscream", MenuFleshScream);
	kvFSS=CreateKeyValues("FleshScreamUserSettings");
  	BuildPath(Path_SM, fileFSS, PathLen, "data/fleshscreamusersettings.txt");
	if(!FileToKeyValues(kvFSS, fileFSS))
    	KeyValuesToFile(kvFSS, fileFSS);

	DoHook();
	AutoExecConfig(true, "sm_flesh_n_scream");
}

public SettingEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Temp = GetConVarInt(cvarEnable);
	if(!(fns_enabled == Temp))
	{
		fns_enabled = Temp;
	
		if (fns_enabled)
		{
			DoHook();
			CreateArrays();
			GetSettings();
		}
		else if(!fns_enabled)
		{
			DoUnhook();
			DestroyArrays();
		}
	}
}

public SettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetSettings();
}

public OnEventShutdown()
{
	DoUnhook();
	DestroyArrays();
}

public OnMapStart()
{
	if(!fns_enabled)
		return;

	KvRewind(kvFSS);
	KeyValuesToFile(kvFSS, fileFSS);

	new String:gString[PathLen];
	new String:TheString[PathLen];
	//sound-precache-paths are always based on the sound folder
	//download-table needs soundfolder-prefix
	for (new i = 0; i <= spurt_count; i++)
	{
		GetArrayString(c_blood_spurt, i, gString, sizeof(gString));
		PrecacheSound(gString, true);
		Format(TheString, PathLen, "sound/%s", gString);
		AddFileToDownloadsTable(TheString);
	}
	for (new i = 0; i <= hit_count; i++)
	{
		GetArrayString(c_flesh_hit, i, gString, sizeof(gString));
		PrecacheSound(gString, true);
		Format(TheString, PathLen, "sound/%s", gString);
		AddFileToDownloadsTable(TheString);
	}
	for (new i = 0; i <= dead_count; i++)
	{
		GetArrayString(c_player_dead, i, gString, sizeof(gString));
		PrecacheSound(gString, true);
		Format(TheString, PathLen, "sound/%s", gString);
		AddFileToDownloadsTable(TheString);
	}
	for (new i = 0; i <= hurt_count; i++)
	{
		GetArrayString(c_player_hurt, i, gString, sizeof(gString));
		PrecacheSound(gString, true);
		Format(TheString, PathLen, "sound/%s", gString);
		AddFileToDownloadsTable(TheString);
	}
	GetSettings();
	/* I don't know when exactly a server is executing map configs and if the cvarchange event is fired when
	cvars are being overwritten during a map change. So read in the cvars again on map start */
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!fns_enabled)
		return Plugin_Handled;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	new Srandom = GetRandomInt(0, 100);
	new random = 0;
	new String:TheSound[PathLen];
	if (Srandom <= spurt_chance)
	{
		random = GetRandomInt(0, spurt_count);
		GetArrayString(c_blood_spurt, random, TheSound, sizeof(TheSound));
		Sendsound(TheSound, client);
	}
	
	Srandom = GetRandomInt(0, 100);
	if (Srandom <= hit_chance)
	{
		random = GetRandomInt(0, hit_count);
		GetArrayString(c_flesh_hit, random, TheSound, sizeof(TheSound));
		Sendsound(TheSound, client);
	}
	
	Srandom = GetRandomInt(0, 100);
	if (Srandom <= hurt_chance)
	{
		random = GetRandomInt(0, hurt_count);
		GetArrayString(c_player_hurt, random, TheSound, sizeof(TheSound));
		Sendsound(TheSound, client);
	}

	return Plugin_Handled;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!fns_enabled)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:TheSound[PathLen];

	new random = GetRandomInt(0, 100);
	if (random <= dead_chance)
	{
		random = GetRandomInt(0, dead_count);
		GetArrayString(c_player_dead, random, TheSound, sizeof(TheSound));
		Sendsound(TheSound, client);
	}
}

GetSettings()
{
	spurt_chance = GetConVarInt(cvarSpurt);
	hit_chance = GetConVarInt(cvarHit);
	dead_chance = GetConVarInt(cvarDead);
	hurt_chance = GetConVarInt(cvarHurt);
	fns_volume = GetConVarFloat(cvarVolume);
	randompitch = GetConVarInt(cvarRandomPitch);
	announce_enabled = GetConVarInt(cvarAnnounce);
	announce_delay = GetConVarFloat(cvarAnnounceDelay);
	admin_override = GetConVarInt(cvarAdminOverride);
	record_sound = GetConVarInt(cvarRecordSound);
}

DoHook()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookConVarChange(cvarSpurt, SettingChanged);
	HookConVarChange(cvarHit, SettingChanged);
	HookConVarChange(cvarDead, SettingChanged);
	HookConVarChange(cvarHurt, SettingChanged);
	HookConVarChange(cvarVolume, SettingChanged);
	HookConVarChange(cvarRandomPitch, SettingChanged);
	HookConVarChange(cvarEnable, SettingEnabled);
	HookConVarChange(cvarAnnounce, SettingChanged);
	HookConVarChange(cvarAnnounceDelay, SettingChanged);
	HookConVarChange(cvarAdminOverride, SettingChanged);
	HookConVarChange(cvarRecordSound, SettingChanged);
}

DoUnhook()
{
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_hurt", Event_PlayerHurt);
	UnhookConVarChange(cvarSpurt, SettingChanged);
	UnhookConVarChange(cvarHit, SettingChanged);
	UnhookConVarChange(cvarDead, SettingChanged);
	UnhookConVarChange(cvarHurt, SettingChanged);
	UnhookConVarChange(cvarVolume, SettingChanged);
	UnhookConVarChange(cvarRandomPitch, SettingChanged);
	UnhookConVarChange(cvarEnable, SettingEnabled);
	UnhookConVarChange(cvarAnnounce, SettingChanged);
	UnhookConVarChange(cvarAnnounceDelay, SettingChanged);
	UnhookConVarChange(cvarAdminOverride, SettingChanged);
	UnhookConVarChange(cvarRecordSound, SettingChanged);
}

CreateArrays()
{
	new arraySize = ByteCountToCells(PathLen);
	c_blood_spurt = CreateArray(arraySize);
	c_flesh_hit = CreateArray(arraySize);
	c_player_dead = CreateArray(arraySize);
	c_player_hurt = CreateArray(arraySize);

	if(hfile != INVALID_HANDLE)
		CloseHandle(hfile);
	BuildPath(Path_SM,sfile,sizeof(sfile),"configs/fleshscream.cfg");
	if(!FileExists(sfile))
		SetFailState("Missing fleshscream.cfg!");

	hfile = CreateKeyValues("fleshscream_sounds");
	FileToKeyValues(hfile,sfile);
	KvRewind(hfile);
	if(KvGotoFirstSubKey(hfile))
	{
		do
		{
			decl String:strBuffer[PathLen];
			
			strBuffer[0] = '\0';
			KvGetString(hfile, "c_blood_spurt", strBuffer, sizeof(strBuffer));
			if(strBuffer[0] != '\0')
				PushArrayString(c_blood_spurt, strBuffer);
			
			strBuffer[0] = '\0';
			KvGetString(hfile, "c_flesh_hit", strBuffer, sizeof(strBuffer));
			if(strBuffer[0] != '\0')
				PushArrayString(c_flesh_hit, strBuffer);
			
			strBuffer[0] = '\0';
			KvGetString(hfile, "c_player_dead", strBuffer, sizeof(strBuffer));
			if(strBuffer[0] != '\0')
				PushArrayString(c_player_dead, strBuffer);
			
			strBuffer[0] = '\0';
			KvGetString(hfile, "c_player_hurt", strBuffer, sizeof(strBuffer));
			if(strBuffer[0] != '\0')
				PushArrayString(c_player_hurt, strBuffer);
		}
		while (KvGotoNextKey(hfile));

	}
	else
	{
		SetFailState("fleshscream.cfg contains invalid data");
	}
	CloseHandle(hfile);
	
	spurt_count = (GetArraySize(c_blood_spurt)-1);
	hit_count = (GetArraySize(c_flesh_hit)-1);
	dead_count = (GetArraySize(c_player_dead)-1);
	hurt_count = (GetArraySize(c_player_hurt)-1);
}

DestroyArrays()
{
	ClearArray(c_blood_spurt);
	ClearArray(c_flesh_hit);
	ClearArray(c_player_dead);
	ClearArray(c_player_hurt);
	CloseHandle(c_blood_spurt);
	CloseHandle(c_flesh_hit);
	CloseHandle(c_player_dead);
	CloseHandle(c_player_hurt);
	c_blood_spurt = INVALID_HANDLE;
	c_flesh_hit = INVALID_HANDLE;
	c_player_dead = INVALID_HANDLE;
	c_player_hurt = INVALID_HANDLE;
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
		PrintToChat(client, "Say !fleshscream to turn screams on/off");
}

public PrepareClient(client)
{
	decl String:steamId[20];
	if(client) {
		if(!IsFakeClient(client)) {
			// Get the users saved setting or create them if they don't exist
			GetClientAuthString(client, steamId, 20);
			KvRewind(kvFSS);
			if(KvJumpToKey(kvFSS, steamId)) {
				soundPreference[client] = KvGetNum(kvFSS, "snd pref", 1);
			}
			else {
				KvJumpToKey(kvFSS, steamId, true);
				KvSetNum(kvFSS, "snd pref", 1);
				KvSetNum(kvFSS, "timestamp", GetTime());
				soundPreference[client] = 1;
			}
			KvRewind(kvFSS);
			if(announce_enabled == 1)
				CreateTimer(announce_delay, TimerAnnounce, client);
		}
	}
}
public OnClientPutInServer(client)
{
	PrepareClient(client);
}
public Flip(flipNum)
{
	if(flipNum == 0)
		return 1;
	else
		return 0;
}
public OnClientDisconnect(client)
{
	decl String:steamId[20];
	if(client && !IsFakeClient(client)) {
		GetClientAuthString(client, steamId, 20);
		KvRewind(kvFSS);
		if(KvJumpToKey(kvFSS, steamId))
			KvSetNum(kvFSS, "timestamp", GetTime());
	}
}
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	KvRewind(kvFSS);
	KeyValuesToFile(kvFSS, fileFSS);
}

public Action:MenuFleshScream(client, args)
{
	//This creates NO menu!! I just kept the symbol name
	new String:MsgString[12];
	soundPreference[client] = Flip(soundPreference[client]);
	decl String:steamId[20];
	GetClientAuthString(client, steamId, 20);
	KvRewind(kvFSS);
	KvJumpToKey(kvFSS, steamId);
	KvSetNum(kvFSS, "snd pref", soundPreference[client]);
	if(soundPreference[client] == 0)
		MsgString = "disabled";
	else
		MsgString = "enabled";
	PrintToChat(client, "Flesh'n'Scream is now %s for you. Other players always hear you scream.", MsgString);
	if(admin_override == 1)
		PrintToChat(client, "Your setting is saved. However Admin has forced the sounds ON for ALL clients currently.");
	
	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	new Handle:TVName = FindConVar("tv_name");
	GetConVarString(TVName, s_TVName, 66);
	CloseHandle(TVName);
}

Sendsound(String:TheSound[], client)
{
	new PitchR = 100;
	new Players = GetMaxClients();

	if(randompitch)
	{
		PitchR += GetRandomInt(-6, 6);
	}

	for (new i = 1; i <= Players; i++)
	{
		if(IsClientInGame(i))
		{
			if(!IsFakeClient(i))
			{
				if((soundPreference[i] == 1) || (admin_override == 1))
				{
					EmitSoundToClient(i, TheSound, client, SNDCHAN_STATIC, 150, _, fns_volume, PitchR);
				}
			}
			else
			{
				if(record_sound == 1)
				{
					//This is a bot. Send it the sound as well, IF it is the SourceTV bot
					new String:s_Buffer[66];
					GetClientName(i, s_Buffer, 66);
					if(strcmp(s_TVName, s_Buffer, false) == 0)
						EmitSoundToClient(i, TheSound, client, SNDCHAN_STATIC, 150, _, fns_volume, PitchR);
				}
			}
		}
	}
}

/*
Disabled menu again, since there is only on/off function. May need it later on.

public MenuHandlerFS(Handle:menu, MenuAction:action, param1, param2)
{
	PrintToServer("Function 'MenuHandlerFS' fired!");
	new String:MsgString[100];
	
	if(action == MenuAction_Select)	{

		if(param2 == 0)
			soundPreference[param1] = Flip(soundPreference[param1]);

		decl String:steamId[20];
		GetClientAuthString(param1, steamId, 20);
		KvRewind(kvFSS);
		KvJumpToKey(kvFSS, steamId);
		KvSetNum(kvFSS, "snd pref", soundPreference[param1]);
		//MenuFleshScream(param1, 0);   There is only one item. No need to show the menu again
		if(soundPreference[param1] == 0)
			MsgString = "disabled";
		else
			MsgString = "enabled";
		PrintToChat(param1, "Flesh'n'Scream has been %s", MsgString);

	} else if(action == MenuAction_End)	{
		CloseHandle(menu);
	}
}
public Action:MenuFleshScream(client, args)
{
	PrintToServer("Function 'MenuFleshScream' fired!");

	new Handle:menu = CreateMenu(MenuHandlerFS);
	decl String:buffer[100];
	
	//Format(buffer, sizeof(buffer), "%T", "quake menu", client);
	//SetMenuTitle(menu, buffer);
	SetMenuTitle(menu, "Flesh'n'Scream settings");
	
	if(soundPreference[client] == 0)
		buffer = "Enable FNS sounds";
	else
		buffer = "Disable FNS sounds";
	AddMenuItem(menu, "snd pref", buffer);
	
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
 
	return Plugin_Handled;
}
*/