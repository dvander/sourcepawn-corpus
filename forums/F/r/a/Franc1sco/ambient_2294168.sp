#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <filesmanagementinterface>
#include <soundlib>

#pragma semicolon 1


#define VERSION "1.2"


#define SOUND_AMBIENT_CHANNEL 8


new Handle:g_hClientTimers[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

new Handle:g_hSoundFolder;
new Handle:cvar_enable;
new Handle:ambientvolume;
new String:g_szSoundFolderPath[ 256 ];

new bool:option_ambient[MAXPLAYERS + 1] = {true,...};
new String:sonido[MAXPLAYERS + 1][256];
new Handle:cookie_ambient = INVALID_HANDLE;

new bool:enable = true;

public Plugin:myinfo =
{
    name = "SM Ambient Sounds",
    author = "Franc1sco steam: franug",
    description = "Ambient music",
    version = VERSION,
    url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{

	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", EventRoundEnd);
    
	CreateConVar("sm_AmbientSounds_version", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);
	cvar_enable = CreateConVar("sm_ambientsounds_enable", "1", "Enable/disable the plugin. 1 = enable , 0 = disable");
	g_hSoundFolder = CreateConVar("sm_ambientsounds_folder", "sound/sm_ambientsounds", "The sound folder where to take a sound to play for ambient music", FCVAR_PLUGIN);
	ambientvolume = CreateConVar("sm_ambientsounds_volume", "0.7", "Volume of the ambient sound. [1.0 = Max volume | 0.0001 = Not audible", FCVAR_PLUGIN);
	
	cookie_ambient = RegClientCookie("Ambient Sound On/Off", "", CookieAccess_Private);
	new info;
	SetCookieMenuItem(CookieMenuHandler_Ambient, any:info, "Ambient Sounds");

	HookConVarChange(cvar_enable, OnCVarChange);

}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}


// Get new values of cvars if they has being changed
public GetCVars()
{
	if(GetConVarBool(cvar_enable))
	{
		enable = true;

		decl String:szBuffer[ 256 ];
	
		FMI_GetRandomSound( g_szSoundFolderPath, szBuffer, sizeof(szBuffer) );
	

    		new Handle:soundfile = OpenSoundFile(szBuffer);
    
    		if (soundfile == INVALID_HANDLE) {
        		//PrintToServer("Invalid handle !");
       			return;
    		}

    		//PrintToServer("Sound Length: %f seconds", GetSoundLengthFloat(soundfile));

    		for(new client = 1; client <= MaxClients; client++)
    		{
			if(IsClientInGame(client) && !IsFakeClient(client) && option_ambient[client])
			{
				if (g_hClientTimers[client] != INVALID_HANDLE)
				{
					KillTimer(g_hClientTimers[client]);
					StopSoundClient(client);
				}
				g_hClientTimers[client] = INVALID_HANDLE;

				//EmitSoundToClient( client, szBuffer );
				EmitSoundToClient(client, szBuffer, SOUND_FROM_PLAYER, SOUND_AMBIENT_CHANNEL, _, _, GetConVarFloat(ambientvolume));
				Format(sonido[client], 256, "%s", szBuffer);

				g_hClientTimers[client] = CreateTimer(GetSoundLength(soundfile)*1.0, Timer_NextMusic, GetClientUserId(client));
			}
   		}
    		CloseHandle(soundfile); 
	}
	else
	{
		enable = false;

    		for(new client = 1; client <= MaxClients; client++)
    		{
			if(IsClientInGame(client) && !IsFakeClient(client))
			{
				if (g_hClientTimers[client] != INVALID_HANDLE)
				{
					KillTimer(g_hClientTimers[client]);
					StopSoundClient(client);
				}
				g_hClientTimers[client] = INVALID_HANDLE;
			}	
		}
	}
	


}

public CookieMenuHandler_Ambient(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		decl String:status[10];
		if (option_ambient[client])
		{
			Format(status, sizeof(status), "On");
		}
		else
		{
			Format(status, sizeof(status), "Off");
		}
		
		Format(buffer, maxlen, "Cookie Ambient Sound: %s", status);
	}
	// CookieMenuAction_SelectOption
	else
	{
		option_ambient[client] = !option_ambient[client];
		
		if (option_ambient[client])
		{
			SetClientCookie(client, cookie_ambient, "On");
			if(!enable)
				return;

			decl String:szBuffer[ 256 ];
	
			FMI_GetRandomSound( g_szSoundFolderPath, szBuffer, sizeof(szBuffer) );
	
			//EmitSoundToClient( client, szBuffer );
			EmitSoundToClient(client, szBuffer, SOUND_FROM_PLAYER, SOUND_AMBIENT_CHANNEL, _, _, GetConVarFloat(ambientvolume));

			if (g_hClientTimers[client] != INVALID_HANDLE)
				KillTimer(g_hClientTimers[client]);
			g_hClientTimers[client] = INVALID_HANDLE;

    			new Handle:soundfile = OpenSoundFile(szBuffer);
    
    			if (soundfile == INVALID_HANDLE) {
        			//PrintToServer("Invalid handle !");
       				return;
    			}

    			//PrintToServer("Sound Length: %f seconds", GetSoundLengthFloat(soundfile));

			Format(sonido[client], 256, "%s", szBuffer);

			g_hClientTimers[client] = CreateTimer(GetSoundLength(soundfile)*1.0, Timer_NextMusic, GetClientUserId(client));

    			CloseHandle(soundfile); 
		}
		else
		{
			SetClientCookie(client, cookie_ambient, "Off");

			if(!enable)
				return;

			if (g_hClientTimers[client] != INVALID_HANDLE)
			{
				KillTimer(g_hClientTimers[client]);
				StopSoundClient(client);
			}
			g_hClientTimers[client] = INVALID_HANDLE;
		}
		
		ShowCookieMenu(client);
	}
}

StopSoundClient(client)
{
	StopSound(client, SOUND_AMBIENT_CHANNEL,sonido[client]);
}

public OnClientCookiesCached(client)
{
	option_ambient[client] = GetCookieAmbient(client);

}

bool:GetCookieAmbient(client)
{
	decl String:buffer[10];
	GetClientCookie(client, cookie_ambient, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(!enable)
		return;

    	for(new client = 1; client <= MaxClients; client++)
    	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			if (g_hClientTimers[client] != INVALID_HANDLE)
			{
				KillTimer(g_hClientTimers[client]);
				StopSoundClient(client);
			}
			g_hClientTimers[client] = INVALID_HANDLE;
		}	
	}
}


public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	CreateTimer(2.0, RoundStartPost);
}


public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;

	if (g_hClientTimers[client] != INVALID_HANDLE)
		KillTimer(g_hClientTimers[client]);
	g_hClientTimers[client] = INVALID_HANDLE;
}

public OnConfigsExecuted()
{


	GetConVarString( g_hSoundFolder, g_szSoundFolderPath, sizeof(g_szSoundFolderPath) );
	
	new nbPrecached = FMI_PrecacheSoundsFolder( g_szSoundFolderPath );
	
	PrintToServer("Precached a total of %d sounds", nbPrecached);
	
	
	if ( nbPrecached > 0 )
	{
		strcopy( g_szSoundFolderPath, sizeof(g_szSoundFolderPath), g_szSoundFolderPath[ 6 ] ); //remove 'sound/'
	}
}

public OnClientPutInServer(client)
{
	if(!option_ambient[client] || IsFakeClient(client) || !enable)
		return;
	
	decl String:szBuffer[ 256 ];
	
	FMI_GetRandomSound( g_szSoundFolderPath, szBuffer, sizeof(szBuffer) );
	
	//EmitSoundToClient( client, szBuffer );
	EmitSoundToClient(client, szBuffer, SOUND_FROM_PLAYER, SOUND_AMBIENT_CHANNEL, _, _, GetConVarFloat(ambientvolume));

	if (g_hClientTimers[client] != INVALID_HANDLE)
		KillTimer(g_hClientTimers[client]);
	g_hClientTimers[client] = INVALID_HANDLE;


    	new Handle:soundfile = OpenSoundFile(szBuffer);
    
    	if (soundfile == INVALID_HANDLE) {
        	//PrintToServer("Invalid handle !");
       		return;
    	}

    	//PrintToServer("Sound Length: %f seconds", GetSoundLengthFloat(soundfile));

	g_hClientTimers[client] = CreateTimer(GetSoundLength(soundfile)*1.0, Timer_NextMusic, GetClientUserId(client));

	Format(sonido[client], 256, "%s", szBuffer);

    	CloseHandle(soundfile); 
}

public Action:Timer_NextMusic(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	g_hClientTimers[client] = INVALID_HANDLE;

	decl String:szBuffer[ 256 ];
	
	FMI_GetRandomSound( g_szSoundFolderPath, szBuffer, sizeof(szBuffer) );
	
	//EmitSoundToClient( client, szBuffer );
	EmitSoundToClient(client, szBuffer, SOUND_FROM_PLAYER, SOUND_AMBIENT_CHANNEL, _, _, GetConVarFloat(ambientvolume));


    	new Handle:soundfile = OpenSoundFile(szBuffer);
    
    	if (soundfile == INVALID_HANDLE) {
        	//PrintToServer("Invalid handle !");
       		return;
    	}

    	//PrintToServer("Sound Length: %f seconds", GetSoundLengthFloat(soundfile));

	g_hClientTimers[client] = CreateTimer(GetSoundLength(soundfile)*1.0, Timer_NextMusic, GetClientUserId(client));

    	CloseHandle(soundfile); 

	Format(sonido[client], 256, "%s", szBuffer);

}

public Action:RoundStartPost(Handle:timer)
{
	if(!enable)
		return;

	decl String:szBuffer[ 256 ];
	
	FMI_GetRandomSound( g_szSoundFolderPath, szBuffer, sizeof(szBuffer) );
	

    	new Handle:soundfile = OpenSoundFile(szBuffer);
    
    	if (soundfile == INVALID_HANDLE) {
        	//PrintToServer("Invalid handle !");
       		return;
    	}

    	//PrintToServer("Sound Length: %f seconds", GetSoundLengthFloat(soundfile));

    	for(new client = 1; client <= MaxClients; client++)
    	{
		if(IsClientInGame(client) && !IsFakeClient(client) && option_ambient[client])
		{
			if (g_hClientTimers[client] != INVALID_HANDLE)
			{
				KillTimer(g_hClientTimers[client]);
				StopSoundClient(client);
			}
			g_hClientTimers[client] = INVALID_HANDLE;

			//EmitSoundToClient( client, szBuffer );
			EmitSoundToClient(client, szBuffer, SOUND_FROM_PLAYER, SOUND_AMBIENT_CHANNEL, _, _, GetConVarFloat(ambientvolume));
			Format(sonido[client], 256, "%s", szBuffer);

			g_hClientTimers[client] = CreateTimer(GetSoundLength(soundfile)*1.0, Timer_NextMusic, GetClientUserId(client));
		}
   	}
    	CloseHandle(soundfile); 
}
