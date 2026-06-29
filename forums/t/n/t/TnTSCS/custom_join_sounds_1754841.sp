#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define _DEBUG		0	// Set to 1 to have debug spew

#define PLUGIN_VERSION	"0.0.1.0"

new String:kv_file[PLATFORM_MAX_PATH];

new Handle:g_cookie;
new Handle:ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:ClientTimer2[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new bool:Enabled = true;

new Float:DelaySoundTime;

public Plugin:myinfo = 
{
	name = "Custom Join Sound",
	author = "TnTSCS aKa ClarkKent",
	description = "Play join sound based on player joining",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	new Handle:hRandom; // KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_cjs_version", PLUGIN_VERSION, 
	"The version of 'Custom Join Sound'", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_cjs_enabled", "1", 
	"Plugin Enabled?.", FCVAR_NONE, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_cjs_time", "5", 
	"Number of seconds to delay the join sound from starting after the player joins.", FCVAR_NONE, true, 0.0, true, 30.0)), OnTimeDelayChanged);
	DelaySoundTime = GetConVarFloat(hRandom);
	
	CloseHandle(hRandom);
	
	BuildPath(Path_SM, kv_file, PLATFORM_MAX_PATH, "configs/custom_join_sounds.txt");
	
	g_cookie = RegClientCookie("join-sound-played", "Banned spray status", CookieAccess_Protected);
	
	HookEvent("player_disconnect", Event_Disconnect);
}

public OnMapStart()
{
	LoadSounds();
}

public OnClientAuthorized(client, const String:auth[])
{
	if (Enabled && !StrEqual(auth, "BOT", false))
	{
		ClientTimer2[client] = CreateTimer(2.0, Timer_CheckCookies, client, TIMER_REPEAT);
	}
}

public Action:Timer_CheckCookies(Handle:timer, any:client)
{
	if (AreClientCookiesCached(client))
	{
		ClientTimer2[client] = INVALID_HANDLE;
		
		if (!PlayerJoinSoundPlayed(client))
		{
			#if _DEBUG
				LogMessage("Starting PlaySound timer for %L and setting cookie to 1", client);
			#endif
			
			ClientTimer[client] = CreateTimer(DelaySoundTime, Timer_PlaySound, client, TIMER_REPEAT);
			
			SetClientCookie(client, g_cookie, "1");
		}
		else
		{
			#if _DEBUG
				LogMessage("%L already had join sound played this connection session", client);
			#endif
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Timer_PlaySound(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		ClientTimer[client] = INVALID_HANDLE;
		
		decl String:auth[50];
		auth[0] = '\0';
		
		GetClientAuthString(client, auth, sizeof(auth));
		
		#if _DEBUG
			LogMessage("Running PlayJoinSound with SteamID [%s]", auth);
		#endif
		
		PlayJoinSound(auth, client);
		
		return Plugin_Stop;
	}
	
	#if _DEBUG
		LogMessage("%L Still not in game", client);
	#endif
	
	return Plugin_Continue;
}

public PlayJoinSound(const String:steamid[], client)
{
	#if _DEBUG
		LogMessage("Opening key value file to check for SteamID [%s]", steamid);
	#endif
	
	new Handle:kv = CreateKeyValues("Join Sounds");
	FileToKeyValues(kv, kv_file);
 
	if (!KvGotoFirstSubKey(kv))
	{
		#if _DEBUG
			LogMessage("Unable to find any keys in the key value file");
		#endif
		
		return;
	}
	
	decl String:sound[PLATFORM_MAX_PATH];
	sound[0] = '\0';
	
	decl String:buffer[50];
	buffer[0] = '\0';
	
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, steamid))
		{
			KvGetString(kv, "path", sound, sizeof(sound));
			
			TrimString(sound);
			
			if (strcmp(sound, ""))
			{
				#if _DEBUG
					LogMessage("Playing %s for SteamID [%s] to all players in game.", sound, buffer);
				#endif
				
				EmitSoundToAll(sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
			}
			
			CloseHandle(kv);
			
			return;
		}
	} while (KvGotoNextKey(kv));
 
	CloseHandle(kv);
	
	#if _DEBUG
		LogMessage("No join sound for %s", steamid);
	#endif
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		ClearTimer(ClientTimer[client]);
		ClearTimer(ClientTimer2[client]);
	}
}

public Action:Event_Disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (PlayerJoinSoundPlayed(client))
	{
		SetClientCookie(client, g_cookie, "0");
		
		#if _DEBUG
			LogMessage("%L left, reset join sound played cookie to 0", client);
		#endif
	}
}

public LoadSounds()
{
	new Handle:kv = CreateKeyValues("Join Sounds");
	
	if (!FileToKeyValues(kv, kv_file))
	{
		SetFailState("[Custom Join Sounds] Unable to load %s", kv_file);
	}
	
	#if _DEBUG
		LogMessage("Running LoadSounds using file %s", kv_file);
	#endif
 
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	
	decl String:sound[255];
	sound[0] = '\0';
	
	decl String:buffer[PLATFORM_MAX_PATH];
	buffer[0] = '\0';
 
	do
	{
		KvGetString(kv, "path", sound, sizeof(sound));
		
		TrimString(sound);
		
		Format(buffer, sizeof(buffer), "sound/%s", sound);
		
		TrimString(buffer);
		
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer);
		}
		else
		{
			SetFailState("[Custom Join Sound] Unable to locate %s", buffer);
		}
		
		if (!PrecacheSound(sound, true))
		{
			SetFailState("[Custom Join Sound] Unable to precache %s", sound);
		}
		
		#if _DEBUG
			LogMessage("Precached %s and added to download tables", sound);
		#endif
		
	} while (KvGotoNextKey(kv));
 
	CloseHandle(kv);
}

bool:PlayerJoinSoundPlayed(client)
{
	decl String:cookie[32];
	cookie[0] = '\0';
	
	GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
	
	if (StrEqual(cookie, "1"))
	{
		return true;
	}
	
	return false;
}

public ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Enabled = GetConVarBool(cvar);
}

public OnTimeDelayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DelaySoundTime = GetConVarFloat(cvar);
}