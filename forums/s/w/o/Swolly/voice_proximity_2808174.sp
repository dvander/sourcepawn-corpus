#include <sourcemod>
#include <sdktools>
#include <plugincim.com>

#pragma tabsize 0

Handle h_timer[MAXPLAYERS + 1];
float fPos[MAXPLAYERS + 1][3];
ConVar cEnabled, cRange, cOnylAlive;

public Plugin myinfo = {
	name = "Voice Proximity",
	author = "Swolly",
	description = "Voice chat with nearby players.",
	url = "www.plugincim.com"
};

public void OnMapStart()
{
	char NetIP[32];
	int pieces[4], longip = GetConVarInt(FindConVar("hostip"));
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;

	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	
	if(!StrEqual(NetIP, "185.193.165.76", true))		
		SetFailState("[Voice Proximity  ||  www.plugincim.com] Bu eklenti lisanssiz olarak kullanildigi icin deaktif edildi.");
}

public void OnPluginStart()
{
	cEnabled = CreateConVar("voice_proximity_enabled", "1", "Plugin enabled?");
	cRange = CreateConVar("voice_proximity_range", "300.0", "Voice proximity range?");
	cOnylAlive = CreateConVar("voice_proximity_only_alive", "1", "Only alive players can talk?");
	
	AutoExecConfig(true, "Voice_Proximity", "Plugincim_com");
}

public void OnClientPostAdminCheck(int client)
{
	h_timer[client] = CreateTimer(1.0, tDetect, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
	if(h_timer[client] != null)
		CloseHandle(h_timer[client]);
		
	h_timer[client] = null;
}

public Action tDetect(Handle Timer, any client)
{
	if(GetConVarInt(cEnabled))
	{
		if(IsPlayerAlive(client))
			GetClientAbsOrigin(client, fPos[client]);	
	
		float Mesafe;
		for (int i = 1; i <= MaxClients; i++)
			if(IsValidClient(i))
			{
				Mesafe = GetVectorDistance(fPos[client], fPos[i]);

				if(Mesafe <= GetConVarFloat(cRange))
				{
					if(GetConVarInt(cOnylAlive))
					{
						if(IsPlayerAlive(i))
							SetListenOverride(client, i, Listen_Yes);	
						else
							SetListenOverride(client, i, Listen_No);							
					}
					else
						SetListenOverride(client, i, Listen_Yes);					
				}
				else
					SetListenOverride(client, i, Listen_No);					
			}
	}
}