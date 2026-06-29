#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1

#define PLUGIN_VERSION "2.7"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Quake Sounds",
	author = "dalto, Grrrrrrrrrrrrrrrrrrr, and psychonic",
	description = "Quake Sounds Plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

//#define OTHER  
//#define DODS  
//#define CSS  
#define HL2DM
//#define TF2

//#define MAX_FILE_LEN 65
#define NOT_BASED_ON_KILLS 0

#define MAX_NUM_SETS 5
new numSets = 0;
new String:setsName[MAX_NUM_SETS][PLATFORM_MAX_PATH];

#define NUM_TYPES 10
static const String:typeNames[NUM_TYPES][] = {"headshot", "grenade", "selfkill", "round play", "knife", "killsound", "first blood", "teamkill", "combo", "join server"};

#define MAX_NUM_KILLS 200
new settingConfig[NUM_TYPES][MAX_NUM_KILLS];
new soundsList[NUM_TYPES][MAX_NUM_KILLS][MAX_NUM_SETS];

#define MAX_NUM_FILES 102
new numSounds = 0;
new String:soundsFiles[MAX_NUM_FILES][PLATFORM_MAX_PATH];

#define HEADSHOT 0
#define GRENADE 1
#define SELFKILL 2
#define ROUND_PLAY 3
#define KNIFE 4
#define KILLSOUND 5
#define FIRSTBLOOD 6
#define TEAMKILL 7
#define COMBO 8
#define JOINSERVER 9

new	Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:cvarTextDefault = INVALID_HANDLE;
new Handle:cvarSoundDefault = INVALID_HANDLE;
new Handle:cvarVolume = INVALID_HANDLE;

new iMaxClients;

new totalKills = 0;
new soundPreference[MAXPLAYERS + 1];
new textPreference[MAXPLAYERS + 1];
new consecutiveKills[MAXPLAYERS + 1];
new Float:lastKillTime[MAXPLAYERS + 1];
new lastKillCount[MAXPLAYERS + 1];
new headShotCount[MAXPLAYERS + 1];
#if defined DODS
new hurtHitGroup[MAXPLAYERS + 1];
#endif

new Handle:cookieTextPref;
new Handle:cookieSoundPref;

new bool:lateLoaded = false;

// if the plugin was loaded late we have a bunch of initialization that needs to be done
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{	
	lateLoaded = late;
	
	return true;
}

public OnPluginStart()
{
	cvarEnabled = CreateConVar("sm_quakesounds_enable", "1", "Enables the Quake sounds plugin");
	HookConVarChange(cvarEnabled, EnableChanged);
		
	LoadTranslations("plugin.quakesounds");
	
	CreateConVar("sm_quakesounds_version", PLUGIN_VERSION, "Quake Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarAnnounce = CreateConVar("sm_quakesounds_announce", "1", "Announcement preferences");
	cvarTextDefault = CreateConVar("sm_quakesounds_text", "1", "Default text setting for new users");
	cvarSoundDefault = CreateConVar("sm_quakesounds_sound", "1", "Default sound for new users, 1=Standard, 2=Female, 0=Disabled");
	cvarVolume = CreateConVar("sm_quakesounds_volume", "1.0", "Volume: should be a number between 0.0. and 1.0");

	if(GetConVarBool(cvarEnabled)) 
	{
		HookEvent("player_death", EventPlayerDeath);		
		
		#if defined CSS
			HookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
		#elseif defined DODS
			HookEvent("dod_warmup_ends", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
			HookEvent("player_hurt", EventPlayerHurt);
		#endif
		
		#if defined DODS
			HookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
		#elseif defined TF2
			HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
			HookEvent("arena_round_start", EventRoundStart, EventHookMode_PostNoCopy);			
		#elseif !defined HL2DM
			HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
		#endif		
	}
	
	RegConsoleCmd("quake", MenuQuake);
	
	AutoExecConfig(true, "sm_quakesounds");
	
	LoadSounds();
	
	//initialize kvQUS
	cookieTextPref = RegClientCookie("Quake Text Pref", "Text setting", CookieAccess_Private);
	cookieSoundPref = RegClientCookie("Quake Sound Pref", "Sound setting", CookieAccess_Private);
	
	//add to clientpref's built-in !settings menu
	SetCookieMenuItem(QuakePrefSelected, 0, "Quake Sound Prefs");
    	
	if (lateLoaded)
	{		
		iMaxClients=GetMaxClients();
	
		// First we need to do whatever we would have done at RoundStart()
		NewRoundInitialization();
		
		// Next we need to whatever we would have done as each client authorized
		new tempSoundDefault = GetConVarInt(cvarSoundDefault) - 1;
		new tempTextDefault = GetConVarInt(cvarTextDefault);
		for(new i = 1; i <= iMaxClients; i++) 
		{
			if(IsClientInGame(i) && IsFakeClient(i))
			{
				soundPreference[i] = -1;
				textPreference[i] = 0;
			}
			else
			{
				soundPreference[i] = tempSoundDefault;
				textPreference[i] = tempTextDefault;
				
				if(IsClientInGame(i) && AreClientCookiesCached(i))
				{
					loadClientCookiesFor(i);
				}
			}
		}	
	}
}

//add to clientpref's built-in !settings menu
public QuakePrefSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		ShowQuakeMenu(client);
	}
}

// Looks for cvar changes of the enable cvar and hooks or unhooks the events
public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new intNewValue = StringToInt(newValue);
	new intOldValue = StringToInt(oldValue);
	
	if(intNewValue == 1 && intOldValue == 0) 
	{
		HookEvent("player_death", EventPlayerDeath);

		#if defined CSS
			HookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
		#elseif defined DODS
			HookEvent("dod_warmup_ends", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
			HookEvent("player_hurt", EventPlayerHurt);
		#endif
		
		#if defined DODS
			HookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
		#elseif defined TF2
			HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
			HookEvent("arena_round_start", EventRoundStart, EventHookMode_PostNoCopy);			
		#elseif !defined HL2DM
			HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
		#endif
	} 
	else if(intNewValue == 0 && intOldValue == 1) 
	{
		UnhookEvent("player_death", EventPlayerDeath);
		
		#if defined CSS
			UnhookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
		#elseif defined DODS
			UnhookEvent("dod_warmup_ends", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
			UnhookEvent("player_hurt", EventPlayerHurt);
		#endif
		
		#if defined DODS
			UnhookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
		#elseif defined TF2
			UnhookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
			UnhookEvent("arena_round_start", EventRoundStart, EventHookMode_PostNoCopy);			
		#elseif !defined HL2DM
			UnhookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
		#endif
	}
}

public LoadSounds()
{
	decl String:buffer[PLATFORM_MAX_PATH];
		
	decl String:fileQSL[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, fileQSL, PLATFORM_MAX_PATH, "configs/QuakeSoundsList.cfg");
	
	new Handle:kvQSL = CreateKeyValues("QuakeSoundsList");
	FileToKeyValues(kvQSL, fileQSL);		

	// Read the sound set information in
	if (!KvJumpToKey(kvQSL, "sound sets")) 
	{
		SetFailState("configs/QuakeSoundsList.cfg not found or not correctly structured");
		return;
	}	
	
	numSets = 0;
	for(new i = 1; i <= MAX_NUM_SETS; i++) 
	{
		Format(buffer, PLATFORM_MAX_PATH, "sound set %i", i);
		KvGetString(kvQSL, buffer, setsName[numSets], PLATFORM_MAX_PATH);
		if(!StrEqual(setsName[numSets], ""))
		{
			numSets++;
		}
	}
	
	// Read the sounds in by type
	numSounds = 0;
	for(new typeKey = 0; typeKey < NUM_TYPES; typeKey++) 
	{
		KvRewind(kvQSL);
		if(KvJumpToKey(kvQSL, typeNames[typeKey]))
		{
			if (KvGotoFirstSubKey(kvQSL))
			{
				do
				{
					KvGetSectionName(kvQSL, buffer, sizeof(buffer));
					new settingKills = StringToInt(buffer);
					new tempConfig = KvGetNum(kvQSL, "config", 9);
					if(!StrEqual(buffer, "") && settingKills>-1 && settingKills<MAX_NUM_KILLS && tempConfig>0)
					{						
						settingConfig[typeKey][settingKills] = tempConfig;
							
						if((tempConfig & 1) || (tempConfig & 2) || (tempConfig & 4))
						{
							for(new set = 0; set < numSets; set++)
							{							
								KvGetString(kvQSL, setsName[set], soundsFiles[numSounds], PLATFORM_MAX_PATH);
								if(StrEqual(soundsFiles[numSounds], ""))
								{
									soundsList[typeKey][settingKills][set] = -1;
								}	
								else
								{
									soundsList[typeKey][settingKills][set] = numSounds;
									numSounds++;								
								}
							}						
						}
					}									
				} while (KvGotoNextKey(kvQSL));	
				
				KvGoBack(kvQSL);
			}
			else
			{
				new settingKills = KvGetNum(kvQSL, "kills", 0);
				new tempConfig = KvGetNum(kvQSL, "config", 9);
				if(settingKills>-1 && settingKills<MAX_NUM_KILLS && tempConfig>0)
				{
					settingConfig[typeKey][settingKills] = tempConfig;
							
					if((tempConfig & 1) || (tempConfig & 2) || (tempConfig & 4))
					{
						for(new set = 0; set < numSets; set++)
						{
							KvGetString(kvQSL, setsName[set], soundsFiles[numSounds], PLATFORM_MAX_PATH);
							if(StrEqual(soundsFiles[numSounds], ""))
							{
								soundsList[typeKey][settingKills][set] = -1;
							}		
							else
							{
								soundsList[typeKey][settingKills][set] = numSounds;
								numSounds++;							
							}
						}						
					}
				}				
			}
		}
	}

	CloseHandle(kvQSL);
}

public OnMapStart()
{
	iMaxClients=GetMaxClients();

	decl String:downloadFile[PLATFORM_MAX_PATH];
	for(new i=0; i < numSounds; i++)
	{
		if(PrecacheSound(soundsFiles[i], true))
		{
			Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", soundsFiles[i]);		
			AddFileToDownloadsTable(downloadFile);
		}
		else
		{
			LogError("Quake Sounds: Cannot precache sound: %s", soundsFiles[i]);
		}
	}
	
	#if defined HL2DM
		NewRoundInitialization();
	#endif
}

#if !defined HL2DM
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	NewRoundInitialization();
}
#endif

// This is called from EventRoundStart or OnMapStart depending on the mod
public NewRoundInitialization()
{
	totalKills = 0;
	for(new i = 1; i <= iMaxClients; i++) 
	{
		headShotCount[i] = 0;
		lastKillTime[i] = -1.0;
		#if defined DODS
		hurtHitGroup[i] = 0;
		#endif
	}
}

// Play the starting sound
public EventRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	PlayQuakeSound(ROUND_PLAY, 0, 0, 0);
	PrintQuakeText(ROUND_PLAY, 0, 0, 0);
}

// When a new client joins we reset sound preferences
// and let them know how to turn the sounds on and off
public OnClientPutInServer(client)
{
	consecutiveKills[client] = 0;
	lastKillTime[client] = -1.0;
	headShotCount[client] = 0;
				
	// Initializations and preferences loading
	if(!IsFakeClient(client))
	{
		soundPreference[client] = GetConVarInt(cvarSoundDefault) - 1;
		textPreference[client] = GetConVarInt(cvarTextDefault);
		
		if (AreClientCookiesCached(client))
		{
			loadClientCookiesFor(client);
		}
	
		// Make the announcement in 30 seconds unless announcements are turned off
		if(GetConVarBool(cvarAnnounce))
		{
			CreateTimer(30.0, TimerAnnounce, client);
		}
			
		// Play event sound
		if(settingConfig[JOINSERVER][NOT_BASED_ON_KILLS] && soundPreference[client]>-1)
		{
			new filePosition = soundsList[JOINSERVER][NOT_BASED_ON_KILLS][soundPreference[client]];
			if(filePosition>-1)
			{			
				EmitSoundToClient(client, soundsFiles[filePosition], _, _, _, _, GetConVarFloat(cvarVolume));
			}
		}
	}
	else
	{
		soundPreference[client] = -1;
		textPreference[client] = 0;
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		PrintToChat(client, "%t", "announce message");
	}
}

public OnClientCookiesCached(client)
{
	// Initializations and preferences loading
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		loadClientCookiesFor(client);	
	}
}

loadClientCookiesFor(client)
{
	decl String:buffer[5];
	
	GetClientCookie(client, cookieTextPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		textPreference[client] = StringToInt(buffer);
	}
	
	GetClientCookie(client, cookieSoundPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		soundPreference[client] = StringToInt(buffer);
	}
}

// The death event this is where we decide what sound to play
// It is important to note that we will play no more than one sound per death event
// so we will order them as to choose the most appropriate one
#if defined DODS
public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(victimClient<1 || victimClient>iMaxClients || GetEventInt(event, "health") > 0)
	{
		return;
	}
	
	hurtHitGroup[victimClient] = GetEventInt(event, "hitgroup");
}
#endif

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victimClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new soundId = -1;
	new killsValue = 0;

	if(victimClient<1 || victimClient>iMaxClients)
	{
		return;
	}
	
	if(attackerClient>0 && attackerClient<=iMaxClients)
	{
		if(attackerClient == victimClient)
		{
			if(settingConfig[SELFKILL][NOT_BASED_ON_KILLS])
			{
				soundId = SELFKILL;
			}
		}
		else if(GetClientTeam(attackerClient) == GetClientTeam(victimClient))
		{
			consecutiveKills[attackerClient] = 0;
			
			if(settingConfig[TEAMKILL][NOT_BASED_ON_KILLS])
			{
				soundId = TEAMKILL;
			}		
		}
		else
		{
			totalKills++;
			
			decl String:weapon[64];
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			#if defined CSS
				new bool:headshot = GetEventBool(event, "headshot");
			#elseif defined TF2
				new customkill = GetEventInt(event, "customkill");
				new bool:headshot = (customkill == 1);
			#elseif defined DODS
				new bool:headshot = (hurtHitGroup[victimClient] == 1);			
			#else
				new bool:headshot = false;
			#endif		
			
			consecutiveKills[attackerClient]++;
			if(headshot)
			{
				headShotCount[attackerClient]++;
			}			
			new Float:tempLastKillTime = lastKillTime[attackerClient];
			lastKillTime[attackerClient] = GetEngineTime();			
			if(tempLastKillTime == -1.0 || (lastKillTime[attackerClient] - tempLastKillTime) > 1.5)
			{
				lastKillCount[attackerClient] = 1;
			}
			else
			{
				lastKillCount[attackerClient]++;
			}

			if(totalKills == 1 && settingConfig[FIRSTBLOOD][NOT_BASED_ON_KILLS])
			{
				soundId = FIRSTBLOOD;
			}
			else if(settingConfig[KILLSOUND][consecutiveKills[attackerClient]])
			{
				soundId = KILLSOUND;
				killsValue = consecutiveKills[attackerClient];
			}
			else if(settingConfig[COMBO][lastKillCount[attackerClient]])
			{
				soundId = COMBO;
				killsValue = lastKillCount[attackerClient];
			}
			else if(headshot && settingConfig[HEADSHOT][headShotCount[attackerClient]])
			{				
				soundId = HEADSHOT;
				killsValue = headShotCount[attackerClient];
			}
			else if(headshot && settingConfig[HEADSHOT][NOT_BASED_ON_KILLS])
			{				
				soundId = HEADSHOT;
			}			
			#if defined TF2
			else if(customkill == 2 && settingConfig[KNIFE][NOT_BASED_ON_KILLS])
			{
				soundId = KNIFE;
			}
			#elseif defined CSS
			else if((StrEqual(weapon, "hegrenade") || StrEqual(weapon, "smokegrenade") || StrEqual(weapon, "flashbang")) && settingConfig[GRENADE][NOT_BASED_ON_KILLS])
			{
				soundId = GRENADE;
			}
			else if(StrEqual(weapon, "knife") && settingConfig[KNIFE][NOT_BASED_ON_KILLS])
			{
				soundId = KNIFE;
			}			
			#elseif defined DODS
			else if((StrEqual(weapon, "riflegren_ger") || StrEqual(weapon, "riflegren_us") || StrEqual(weapon, "frag_ger") || StrEqual(weapon, "frag_us") || StrEqual(weapon, "smoke_ger") || StrEqual(weapon, "smoke_us")) && settingConfig[GRENADE][NOT_BASED_ON_KILLS])
			{
				soundId = GRENADE;
			}
			else if((StrEqual(weapon, "spade") || StrEqual(weapon, "amerknife") || StrEqual(weapon, "punch")) && settingConfig[KNIFE][NOT_BASED_ON_KILLS])
			{
				soundId = KNIFE;
			}			
			#elseif defined HL2DM
			else if(StrEqual(weapon, "grenade_frag") && settingConfig[GRENADE][NOT_BASED_ON_KILLS])
			{
				soundId = GRENADE;
			}
			else if((StrEqual(weapon, "stunstick") || StrEqual(weapon, "crowbar")) && settingConfig[KNIFE][NOT_BASED_ON_KILLS])
			{
				soundId = KNIFE;
			}
			#endif
		}
	}
	
	#if defined DODS
		hurtHitGroup[victimClient] = 0;
	#endif

	consecutiveKills[victimClient] = 0;
	
	// Play the appropriate sound if there was a reason to do so 
	if(soundId != -1) 
	{
		PlayQuakeSound(soundId, killsValue, attackerClient, victimClient);
		PrintQuakeText(soundId, killsValue, attackerClient, victimClient);
	}
}

// This plays the quake sounds based on soundPreference
public PlayQuakeSound(soundKey, killsValue, attackerClient, victimClient)
{
	new config = settingConfig[soundKey][killsValue];
	new filePosition;

	if(config & 1) 
	{
		for (new i = 1; i <= iMaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && soundPreference[i]>-1)
			{
				filePosition = soundsList[soundKey][killsValue][soundPreference[i]];
				if(filePosition>-1)
				{
					EmitSoundToClient(i, soundsFiles[filePosition], _, _, _, _, GetConVarFloat(cvarVolume));
				}
			}
		}
	}
	else
	{
		new Float:volumeLevel = GetConVarFloat(cvarVolume);
		
		if(config & 2 && soundPreference[attackerClient]>-1)
		{
			filePosition = soundsList[soundKey][killsValue][soundPreference[attackerClient]];
			if(filePosition>-1)
			{
				EmitSoundToClient(attackerClient, soundsFiles[filePosition], _, _, _, _, volumeLevel);
			}
		}
		if(config & 4 && soundPreference[victimClient]>-1)
		{
			filePosition = soundsList[soundKey][killsValue][soundPreference[victimClient]];
			if(filePosition>-1)
			{
				EmitSoundToClient(victimClient, soundsFiles[filePosition], _, _, _, _, volumeLevel);
			}
		}		
	}
}

// This prints the quake text
public PrintQuakeText(soundKey, killsValue, attackerClient, victimClient)
{
	decl String:attackerName[MAX_NAME_LENGTH];
	decl String:victimName[MAX_NAME_LENGTH];
	
	// Get the names of the victim and the attacker
	if(attackerClient && IsClientInGame(attackerClient))
	{
		GetClientName(attackerClient, attackerName, MAX_NAME_LENGTH);
	}
	else
	{
		attackerName = "Nobody";
	}
	if(victimClient && IsClientInGame(victimClient))
	{
		GetClientName(victimClient, victimName, MAX_NAME_LENGTH);
	}
	else
	{
		victimName = "Nobody";
	}
	
	decl String:translationName[65];
	if(killsValue>0)
	{
		Format(translationName, 65, "%s %i", typeNames[soundKey], killsValue);
	}
	else
	{
		Format(translationName, 65, "%s", typeNames[soundKey]);
	}
	
	new config = settingConfig[soundKey][killsValue];

	if(config & 8) 
	{
		for (new i = 1; i <= iMaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && textPreference[i])
			{
				PrintCenterText(i, "%t", translationName, attackerName, victimName);
			}
		}
	}
	else
	{
		if(config & 16 && textPreference[attackerClient])
		{
			PrintCenterText(attackerClient, "%t", translationName, attackerName, victimName);
		}
		if(config & 32 && textPreference[victimClient])
		{
			PrintCenterText(victimClient, "%t", translationName, attackerName, victimName);
		}		
	}
}

//  This selects or disables the quake sounds
public MenuHandlerQuake(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		// The Disable Choice moves around based on if female sounds are enabled
		new disableChoice = numSets + 1;
		
		// Update both the soundPreference array and User Settings KV
		if(param2 == disableChoice)
		{
			soundPreference[param1] = -1;
		}
		else if(param2 == 0)
		{
			if(textPreference[param1] == 0)
			{
				textPreference[param1] = 1;
			}
			else
			{
				textPreference[param1] = 0;
			}
		}
		else
		{
			soundPreference[param1] = param2 - 1;
		}
		
		decl String:buffer[5];
		IntToString(textPreference[param1], buffer, 5);
		SetClientCookie(param1, cookieTextPref, buffer);
		IntToString(soundPreference[param1], buffer, 5);
		SetClientCookie(param1, cookieSoundPref, buffer);
		
		MenuQuake(param1, 0);
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
//  This creates the Quake menu
public Action:MenuQuake(client, args)
{
	ShowQuakeMenu(client);
	return Plugin_Handled;
}

ShowQuakeMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandlerQuake);
	decl String:buffer[100];
	
	Format(buffer, sizeof(buffer), "%T", "quake menu", client);
	SetMenuTitle(menu, buffer);
	
	if(textPreference[client] == 0)
	{
		Format(buffer, sizeof(buffer), "%T", "enable text", client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "disable text", client);
	}	
	AddMenuItem(menu, "text pref", buffer);

	for(new set = 0; set < numSets; set++) 
	{
		if(soundPreference[client] == set)
		{
			Format(buffer, 50, "%T(Enabled)", setsName[set], client);
		}
		else
		{
			Format(buffer, 50, "%T", setsName[set], client);
		}
		AddMenuItem(menu, "sound set", buffer);
	}
	if(soundPreference[client] == -1)
	{
		Format(buffer, sizeof(buffer), "%T(Enabled)", "no quake sounds", client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "no quake sounds", client);
	}
	AddMenuItem(menu, "no sounds", buffer);
 
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
}