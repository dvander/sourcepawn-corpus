#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

ConVar pusEnabled, pusMode, pusDisableTank;
bool bEnabled, bDisableTank, bPlaying[MAXPLAYERS+1];
int iMode, iSoundPlaying[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Play Unique Sounds",
	author = "cravenge",
	description = "Let's Play Some Music To Our Ears.",
	version = "1.1",
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	CreateConVar("play_unique_sounds_version", "1.1", "Play Unique Sounds Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	pusEnabled = CreateConVar("play_unique_sounds_enabled", "1", "Enable/Disable Plugin", FCVAR_SPONLY|FCVAR_NOTIFY);
	pusMode = CreateConVar("play_unique_sounds_mode", "0", "Play Mode: 0=Self Only, 1=Own Team, 2=Enemy Team, 3=All", FCVAR_SPONLY|FCVAR_NOTIFY);
	pusDisableTank = CreateConVar("play_unique_sounds_disable_tank", "1", "Enable/Disable Tank Music When Playing Sounds", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	iMode = pusMode.IntValue;
	
	bEnabled = pusEnabled.BoolValue;
	bDisableTank = pusDisableTank.BoolValue;
	
	pusEnabled.AddChangeHook(OnPUSCVarsChanged);
	pusMode.AddChangeHook(OnPUSCVarsChanged);
	pusDisableTank.AddChangeHook(OnPUSCVarsChanged);
	
	AutoExecConfig(true, "play_unique_sounds");
	
	AddNormalSoundHook(OnSoundsCheck);
	
	RegConsoleCmd("sm_badman", BadManCmd, "Toggles Bad Man Sound");
	RegConsoleCmd("sm_midride", MidnightRideCmd, "Play Midnight Ride");
}

public void OnPUSCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	iMode = pusMode.IntValue;
	
	bEnabled = pusEnabled.BoolValue;
	bDisableTank = pusDisableTank.BoolValue;
}

public void OnPluginEnd()
{
	pusEnabled.RemoveChangeHook(OnPUSCVarsChanged);
	pusMode.RemoveChangeHook(OnPUSCVarsChanged);
	pusDisableTank.RemoveChangeHook(OnPUSCVarsChanged);
	
	delete pusEnabled;
	delete pusMode;
	delete pusDisableTank;
	
	RemoveNormalSoundHook(OnSoundsCheck);
}

public Action OnSoundsCheck(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (bDisableTank && (StrContains(sample, "music/tank/tank", false) != -1 || StrContains(sample, "music/tank/taank", false) != -1))
	{
		numClients = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if ((iMode == 0 && i != client) || (iMode == 1 && GetClientTeam(i) != GetClientTeam(client)) || (iMode == 2 && GetClientTeam(i) == GetClientTeam(client)))
				{
					clients[numClients] = i;
					numClients++;
				}
			}
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action BadManCmd(int client, int args)
{
	if (!bEnabled)
	{
		PrintToChat(client, "\x03[\x04PUS\x03]\x01 Plugin Disabled!");
		return Plugin_Handled;
	}
	
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Handled;
	}
	
	if (iSoundPlaying[client] == 2)
	{
		PrintToChat(client, "\x03[\x04PUS\x03]\x01 You're Still Playing \x05Midnight Ride\x01!");
		return Plugin_Handled;
	}
	
	if (iMode != 3)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if ((iMode == 0 && i == client) || (iMode == 1 && GetClientTeam(i) == GetClientTeam(client)) || (iMode == 2 && GetClientTeam(i) != GetClientTeam(client)))
				{
					if (bPlaying[client])
					{
						StopSound(client, SNDCHAN_AUTO, "unique/midnightriders/badman.wav");
						PrintToChat(i, "\x03[\x04PUS\x03]\x01 Stopped \x05Bad Man\x01 From Playing!");
						
						if (i == client)
						{
							bPlaying[i] = false;
							iSoundPlaying[i] = 0;
						}
					}
					else
					{
						EmitSoundToClient(i, "unique/midnightriders/badman.wav", client, SNDCHAN_AUTO);
						PrintToChat(i, "\x03[\x04PUS\x03]\x05 Bad Man\x01 Is Now Playing!");
						
						if (i == client)
						{
							iSoundPlaying[i] = 1;
							bPlaying[i] = true;
						}
					}
				}
			}
		}
	}
	else
	{
		if (bPlaying[client])
		{
			StopSound(client, SNDCHAN_AUTO, "unique/midnightriders/badman.wav");
			PrintToChatAll("\x03[\x04PUS\x03]\x01 Stopped \x05Bad Man\x01 From Playing!");
			
			bPlaying[client] = false;
			iSoundPlaying[client] = 0;
		}
		else
		{
			EmitSoundToAll(client, "unique/midnightriders/badman.wav", SNDCHAN_AUTO);
			PrintToChatAll("\x03[\x04PUS\x03]\x05 Bad Man\x01 Is Now Playing!");
			
			iSoundPlaying[client] = 1;
			bPlaying[client] = true;
		}
	}
	
	return Plugin_Handled;
}

public Action MidnightRideCmd(int client, int args)
{
	if (!bEnabled)
	{
		PrintToChat(client, "\x03[\x04PUS\x03]\x01 Plugin Disabled!");
		return Plugin_Handled;
	}
	
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Handled;
	}
	
	if (iSoundPlaying[client] == 1)
	{
		PrintToChat(client, "\x03[\x04PUS\x03]\x01 You're Still Playing \x05Bad Man\x01!");
		return Plugin_Handled;
	}
	
	if (iMode != 3)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if ((iMode == 0 && i == client) || (iMode == 1 && GetClientTeam(i) == GetClientTeam(client)) || (iMode == 2 && GetClientTeam(i) != GetClientTeam(client)))
				{
					if (bPlaying[client])
					{
						StopSound(client, SNDCHAN_AUTO, "unique/midnightriders/midnightride.wav");
						PrintToChat(i, "\x03[\x04PUS\x03]\x01 Stopped \x05Midnight Ride\x01 From Playing!");
						
						if (i == client)
						{
							bPlaying[i] = false;
							iSoundPlaying[i] = 0;
						}
					}
					else
					{
						EmitSoundToClient(i, "unique/midnightriders/midnightride.wav", client, SNDCHAN_AUTO);
						PrintToChat(i, "\x03[\x04PUS\x03]\x05 Midnight Ride\x01 Is Now Playing!");
						
						if (i == client)
						{
							iSoundPlaying[i] = 2;
							bPlaying[i] = true;
						}
					}
				}
			}
		}
	}
	else
	{
		if (bPlaying[client])
		{
			StopSound(client, SNDCHAN_AUTO, "unique/midnightriders/midnightride.wav");
			PrintToChatAll("\x03[\x04PUS\x03]\x01 Stopped \x05Midnight Ride\x01 From Playing!");
			
			bPlaying[client] = false;
			iSoundPlaying[client] = 0;
		}
		else
		{
			EmitSoundToAll(client, "unique/midnightriders/midnightride.wav", SNDCHAN_AUTO);
			PrintToChatAll("\x03[\x04PUS\x03]\x05 Midnight Ride\x01 Is Now Playing!");
			
			iSoundPlaying[client] = 2;
			bPlaying[client] = true;
		}
	}
	
	return Plugin_Handled;
}

