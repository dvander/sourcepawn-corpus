#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:hPUSOn;
new Handle:hPUSMode;

new bOn;
new iMode;

new String:BadMan[] = "music/flu/concert/onebadman.wav";
new String:MidnightRide[] = "music/flu/concert/midnightride.wav";

new bool:AlreadyPlaying[MAXPLAYERS+1] = false;

new cSoundPlaying[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = "Play Unique Sounds",
	author = "cravenge",
	description = "Let's Play Some Music To Our Ears.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("pus_version", "1.0", "Play Unique Sounds Version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hPUSOn = CreateConVar("pus_on", "1", "Enable/Disable Plugin", FCVAR_NOTIFY);
	hPUSMode = CreateConVar("pus_mode", "0", "Play Mode: 0=Self Only, 1=Team Only, 2=Enemy Team, 3=To All", FCVAR_NOTIFY);
	
	bOn = GetConVarBool(hPUSOn);
	iMode = GetConVarInt(hPUSMode);
	
	AutoExecConfig(true, "play_unique_sounds");
	
	RegConsoleCmd("sm_playbm", Play1, "Play Bad Man");
	RegConsoleCmd("sm_stopbm", Stop1, "Stop Playing Bad Man");
	
	RegConsoleCmd("sm_playmr", Play2, "Play Midnight Ride");
	RegConsoleCmd("sm_stopmr", Stop2, "Stop Playing Midnight Ride");
}

public OnMapStart()
{
	AddFileToDownloadsTable(BadMan);
	AddFileToDownloadsTable(MidnightRide);
	
	PrefetchSound(BadMan);
	PrecacheSound(BadMan, true);
	
	PrefetchSound(MidnightRide);
	PrecacheSound(MidnightRide, true);
	
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			AlreadyPlaying[i] = false;
			cSoundPlaying[i] = 0;
		}
	}
}

public OnMapEnd()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			AlreadyPlaying[i] = false;
			cSoundPlaying[i] = 0;
		}
	}
}

public Action:Play1(client, args)
{
	if(!bOn)
	{
		return Plugin_Handled;
	}
	
	if(client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || AlreadyPlaying[client] || cSoundPlaying[client] != 0)
	{
		return Plugin_Handled;
	}
	
	cSoundPlaying[client] = 1;
	AlreadyPlaying[client] = true;
	if (iMode == 1)
	{
		for (new iTeam=1; iTeam<=MaxClients; iTeam++)
		{
			if (IsClientInGame(iTeam) && GetClientTeam(iTeam) == GetClientTeam(client))
			{
				EmitSoundToClient(iTeam, BadMan, client, SNDCHAN_AUTO);
				PrintToChat(iTeam, "\x05[PUS]\x01 Playing\x03 Bad Man!");
			}
		}
	}
	else if (iMode == 2)
	{
		for (new iOtherTeam=1; iOtherTeam<=MaxClients; iOtherTeam++)
		{
			if (IsClientInGame(iOtherTeam) && GetClientTeam(iOtherTeam) != GetClientTeam(client))
			{
				EmitSoundToClient(iOtherTeam, BadMan, client, SNDCHAN_AUTO);
				PrintToChat(iOtherTeam, "\x05[PUS]\x01 Playing\x03 Bad Man!");
			}
		}
	}
	else if (iMode == 3)
	{
		EmitSoundToAll(BadMan, client, SNDCHAN_AUTO);
		PrintToChatAll("\x05[PUS]\x01 Playing\x03 Bad Man!");
	}
	else
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && i == client)
			{
				EmitSoundToClient(i, BadMan, client, SNDCHAN_AUTO);
				PrintToChat(i, "\x05[PUS]\x01 Playing\x03 Bad Man!");
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Stop1(client, args)
{
	if(!bOn)
	{
		return Plugin_Handled;
	}
	
	if(client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !AlreadyPlaying[client] || cSoundPlaying[client] != 1)
	{
		return Plugin_Handled;
	}
	
	StopSound(client, SNDCHAN_AUTO, BadMan);
	cSoundPlaying[client] = 0;
	AlreadyPlaying[client] = false;
	return Plugin_Handled;
}

public Action:Play2(client, args)
{
	if(!bOn)
	{
		return Plugin_Handled;
	}
	
	if(client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || AlreadyPlaying[client] || cSoundPlaying[client] != 0)
	{
		return Plugin_Handled;
	}
	
	cSoundPlaying[client] = 2;
	AlreadyPlaying[client] = true;
	if (iMode == 1)
	{
		for (new iTeam=1; iTeam<=MaxClients; iTeam++)
		{
			if (IsClientInGame(iTeam) && GetClientTeam(iTeam) == GetClientTeam(client))
			{
				EmitSoundToClient(iTeam, MidnightRide, client, SNDCHAN_AUTO);
				PrintToChat(iTeam, "\x05[PUS]\x01 Playing\x03 Midnight Ride!");
			}
		}
	}
	else if (iMode == 2)
	{
		for (new iOtherTeam=1; iOtherTeam<=MaxClients; iOtherTeam++)
		{
			if (IsClientInGame(iOtherTeam) && GetClientTeam(iOtherTeam) != GetClientTeam(client))
			{
				EmitSoundToClient(iOtherTeam, MidnightRide, client, SNDCHAN_AUTO);
				PrintToChat(iOtherTeam, "\x05[PUS]\x01 Playing\x03 Midnight Ride!");
			}
		}
	}
	else if (iMode == 3)
	{
		EmitSoundToAll(MidnightRide, client, SNDCHAN_AUTO);
		PrintToChatAll("\x05[PUS]\x01 Playing\x03 Midnight Ride!");
	}
	else
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && i == client)
			{
				EmitSoundToClient(i, MidnightRide, client, SNDCHAN_AUTO);
				PrintToChat(i, "\x05[PUS]\x01 Playing\x03 Midnight Ride!");
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Stop2(client, args)
{
	if(!bOn)
	{
		return Plugin_Handled;
	}
	
	if(client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !AlreadyPlaying[client] || cSoundPlaying[client] != 2)
	{
		return Plugin_Handled;
	}
	
	StopSound(client, SNDCHAN_AUTO, MidnightRide);
	cSoundPlaying[client] = 0;
	AlreadyPlaying[client] = false;
	return Plugin_Handled;
}

