#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>

public Plugin:myinfo = {
	name = "CSOnlineOverlays",
	author = "Neatek",
	description = "Overlays for every kill and sounds",
	version = "1.0",
	url = "http://www.neatek.ru/"
};

new Handle:g_EnableSounds = INVALID_HANDLE;
new Handle:g_Enable = INVALID_HANDLE;
new bool:g_esounds = true;
new bool:g_enable = true;
new bool:g_firstblood = false;
new g_PlayerKills[MAXPLAYERS+1];
//new Handle:g_PlayerTimers[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:g_PlayerTimers[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_death", HookEvent_PlayerDeath);
	HookEvent("round_start", HookEvent_ResetFirstblood);
	CreateConVar("sm_cso_overlays", "1.0", "Version of CSO Screens plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Enable = CreateConVar("cso_enable", "1", "Enable or disable plug-in");
	g_EnableSounds = CreateConVar("cso_sounds_enable", "true", "Enable sounds for kill");
	AutoExecConfig(true);
}

public OnClientDisconnect(client)
{
	g_PlayerKills[client] = 0;
}

public HookEvent_ResetFirstblood(Handle:Event, const String:name[], bool:dontBroadcast)
{
	for(new x=1;x<=MaxClients;x++) /* Reset kills */
	{
		if(Client_IsIngame(x))
			g_PlayerKills[x] = 0;
	}

	g_firstblood = true; /* Reset firstblood */
	g_enable = true;
}

public HookEvent_PlayerDeath(Handle:Event, const String:name[], bool:dontBroadcast)
{
	if(g_enable)
	{
		new client = GetClientOfUserId(GetEventInt(Event,"userid"));
		new attacker = GetClientOfUserId(GetEventInt(Event,"attacker"));

		if(client != attacker && Client_IsIngame(client) && Client_IsIngame(attacker))
		{
			if(Client_IsValid(client) && Client_IsValid(attacker))
			{
				g_firstblood = false;
				g_PlayerKills[attacker]++;
				g_PlayerKills[client] = 0;

				if(g_firstblood)
				{
					EmitSoundToAll("vox/firstkill.mp3");
				}

				if(GetEventBool(Event, "headshot") == true)
				{
					SetOverlay(attacker, "overlays/kill/kill_headshot");
					EmitSoundToClient(attacker, "vox/headshot.mp3");
				}
				else
				{
					decl String:weapon[64];
					GetEventString(Event, "weapon", weapon, sizeof(weapon));

					if(strcmp(weapon, "hegrenade") == 0)
					{
						SetOverlay(attacker, "overlays/kill/kill_grenade");
					}
					else if (strcmp(weapon, "knife") == 0)
					{
						SetOverlay(attacker, "overlays/kill/kill_knife");
						EmitSoundToClient(attacker, "vox/humililation.mp3");
					}
					else
					{
						switch(g_PlayerKills[attacker])
						{
							case 1:
							{
								SetOverlay(attacker, "overlays/kill/kill_1");
								EmitSoundToClient(attacker, "vox/gotit.mp3");
							}
							case 2:
							{
								SetOverlay(attacker, "overlays/kill/kill_2");
								EmitSoundToClient(attacker, "vox/doublekill.mp3");
							}
							case 3:
							{
								SetOverlay(attacker, "overlays/kill/kill_3");
								EmitSoundToClient(attacker, "vox/triplekill.mp3");
							}
							case 4:
							{
								SetOverlay(attacker, "overlays/kill/kill_4");
								EmitSoundToClient(attacker, "vox/multikill.mp3");
							}
							case 5:
							{
								EmitSoundToClient(attacker, "vox/megakill.mp3");
							}
							case 10:
							{
								EmitSoundToClient(attacker, "vox/monsterkill.mp3");
							}
							case 13:
							{
								EmitSoundToClient(attacker, "vox/ultrakill.mp3");
							}
						}
					}
				}
			}
		}
	}
}

stock SetOverlay(client, String:overlay[])
{
	Client_SetScreenOverlay(client, overlay);
	if(g_PlayerTimers[client] == false)
	{
		g_PlayerTimers[client] = true;
		CreateTimer(1.3, resetoverlay, client);
	}
	
	/*if(g_PlayerTimers[client] == INVALID_HANDLE)
	{
		LogError("start timer #%d", client);
		g_PlayerTimers[client] = CreateTimer(1.3, resetoverlay, client);
	}
	else
	{
		LogError("kill timer for #%d", client);
		KillTimer(g_PlayerTimers[client]);
		g_PlayerTimers[client] = INVALID_HANDLE;
		g_PlayerTimers[client] = CreateTimer(1.3, resetoverlay, client);
	}*/
}

public Action:resetoverlay(Handle:timer, any:client)
{
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		LogError("reset overlay for #%d", client);
		Client_SetScreenOverlay(client, "off");
		Client_SetScreenOverlay(client, "");
	}
	
	g_PlayerTimers[client] = false;
}

public OnMapStart()
{
	g_esounds = GetConVarBool(g_EnableSounds);
	g_enable = GetConVarBool(g_Enable);
	AddFileToDownloadsTable("sound/vox/doublekill.mp3");
	AddFileToDownloadsTable("sound/vox/firstkill.mp3");
	AddFileToDownloadsTable("sound/vox/gotit.mp3");
	AddFileToDownloadsTable("sound/vox/headshot.mp3");
	AddFileToDownloadsTable("sound/vox/humililation.mp3");
	AddFileToDownloadsTable("sound/vox/megakill.mp3");
	AddFileToDownloadsTable("sound/vox/monsterkill.mp3");
	AddFileToDownloadsTable("sound/vox/multikill.mp3");
	AddFileToDownloadsTable("sound/vox/triplekill.mp3");
	AddFileToDownloadsTable("sound/vox/ultrakill.mp3");
	AddFileToDownloadsTable("materials/overlays/kill/kill_1.vmt");
	AddFileToDownloadsTable("materials/overlays/kill/kill_1.vtf");
	AddFileToDownloadsTable("materials/overlays/kill/kill_2.vmt");
	AddFileToDownloadsTable("materials/overlays/kill/kill_2.vtf");
	AddFileToDownloadsTable("materials/overlays/kill/kill_3.vmt");
	AddFileToDownloadsTable("materials/overlays/kill/kill_3.vtf");
	AddFileToDownloadsTable("materials/overlays/kill/kill_4.vmt");
	AddFileToDownloadsTable("materials/overlays/kill/kill_4.vtf");
	AddFileToDownloadsTable("materials/overlays/kill/kill_grenade.vmt");
	AddFileToDownloadsTable("materials/overlays/kill/kill_grenade.vtf");
	AddFileToDownloadsTable("materials/overlays/kill/kill_headshot.vmt");
	AddFileToDownloadsTable("materials/overlays/kill/kill_headshot.vtf");
	AddFileToDownloadsTable("materials/overlays/kill/kill_knife.vmt");
	AddFileToDownloadsTable("materials/overlays/kill/kill_knife.vtf");
	PrecacheDecal("materials/overlays/kill/kill_1.vtf", true);
	PrecacheDecal("materials/overlays/kill/kill_2.vtf", true);
	PrecacheDecal("materials/overlays/kill/kill_3.vtf", true);
	PrecacheDecal("materials/overlays/kill/kill_4.vtf", true);
	PrecacheDecal("materials/overlays/kill/kill_grenade.vtf", true);
	PrecacheDecal("materials/overlays/kill/kill_headshot.vtf", true);
	PrecacheDecal("materials/overlays/kill/kill_knife.vtf", true);
	PrecacheSound("vox/doublekill.mp3", true);
	PrecacheSound("vox/firstkill.mp3", true);
	PrecacheSound("vox/gotit.mp3", true);
	PrecacheSound("vox/headshot.mp3", true);
	PrecacheSound("vox/humililation.mp3", true);
	PrecacheSound("vox/megakill.mp3", true);
	PrecacheSound("vox/monsterkill.mp3", true);
	PrecacheSound("vox/multikill.mp3", true);
	PrecacheSound("vox/triplekill.mp3", true);
	PrecacheSound("vox/ultrakill.mp3", true);
}