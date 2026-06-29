#include <sourcemod>
#include <sdktools>

new Handle:t_ShowSpawnInfo = INVALID_HANDLE
new o_miHeavy
new o_miLight
new o_miMedium
new o_mfSpawnTime
new o_mEnabled
new o_mTeam
new o_mSpawnID 
new out_lvl = 3600
new gotmessage[33]
new playerspawnid[33]

#define PLUGIN_VERSION "1.3"

/*
* time for displaying the spawninfo in orange color if it exceeds ALERTTIME
*/
#define WARNTIME 20

/*
* time for displaying the spawninfo in red color if it exceeds ALERTTIME
*/
#define ALERTTIME 30

public Plugin:myinfo =
{
	name = "SpawnQueueInfo",
	author = "Atomy",
	description = "Displays Information about the SpawnQueue-Status, which classes are in - and how many time is remaining",
	version = PLUGIN_VERSION,
	url = "http://www.losd-clan.com/"
};

public OnMapStart()
{
	out_lvl = 3600

	t_ShowSpawnInfo = CreateTimer(1.0, GoSpawn, _, TIMER_REPEAT)
}

public OnMapEnd()
{
	if (t_ShowSpawnInfo != INVALID_HANDLE)
	{
		KillTimer(t_ShowSpawnInfo, true)
		CloseHandle(t_ShowSpawnInfo)
	}
}

public OnPluginStart()
{

	CreateConVar("sm_spawninfo_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

	/*
	* search offsets
	*/
	o_miHeavy = FindSendPropOffs("CDysSpawn", "m_iHeavy")
	o_miLight = FindSendPropOffs("CDysSpawn", "m_iLight")
	o_miMedium = FindSendPropOffs("CDysSpawn", "m_iMedium")
	o_mfSpawnTime = FindSendPropOffs("CDysSpawn", "m_fSpawnTime")
	o_mEnabled = FindSendPropOffs("CDysSpawn", "m_Enabled")
	o_mTeam = FindSendPropOffs("CDysSpawn", "m_Team")
	o_mSpawnID = FindSendPropOffs("CDysSpawn", "m_SpawnID")

 	/*
        * do we have all offsets? if, not throw an error
        */
        if (o_miHeavy >= 0 && o_miLight >= 0 && o_miMedium >= 0 && o_mfSpawnTime >= 0 && o_mEnabled >= 0 && o_mTeam >= 0 && o_mSpawnID >= 0)
        {
	        if (t_ShowSpawnInfo == INVALID_HANDLE)
		{
			t_ShowSpawnInfo = CreateTimer(1.0, GoSpawn, _, TIMER_REPEAT)
		}
	}
	else
	{
                ThrowError("Couldnt find all offsets")
	}
}	

public Action:GoSpawn(Handle:timer)
{
	new String:cname[255]
	new String:nclass[255]
	
	/*
	* loop through all edicts
	*/
	for (new i = 0; i <= 2048; i++)
	{
		if (IsValidEdict(i) && GetEdictClassname(i, cname, sizeof(cname)))
		{
			if (IsValidEntity(i) && GetEntityNetClass(i, nclass, sizeof(nclass)))
			{
				/*
				* we are searching for edicts of the CDysSpawn class
				*/
				if (strcmp(nclass,"CDysSpawn") == 0)
				{
					new light=0
					new medium=0
					new heavy=0
					new enabled=0
					new team=0
					new float:spawntime=0
					new spawnid=0
				
					/*
					* getting values
					*/
					light = GetEntData(i, o_miLight)
					medium = GetEntData(i, o_miMedium)
					heavy = GetEntData(i, o_miHeavy)
					spawntime = GetEntDataFloat(i, o_mfSpawnTime)-GetGameTime()
					enabled = GetEntData(i, o_mEnabled)
					team = GetEntData(i, o_mTeam)
					spawnid = GetEntData(i, o_mSpawnID)

					if (enabled == 1)
						PrintSpawnInfo(team, light, medium, heavy, spawntime, spawnid)
				}
			}
		}
	}
}

public PrintSpawnInfo(team, light, medium, heavy, float:f_spawntime, spawnid)
{
	new maxclients = GetMaxClients()
	new String:message[255]
	new Handle:kv = CreateKeyValues("msg")
	new spawntime = RoundToFloor(f_spawntime)	

	if (spawntime >= ALERTTIME)
	{
		KvSetColor(kv, "color", 255, 0, 0, 255)
		Format(message, sizeof(message), "SpawnTime: %is - L(%i) M(%i) H(%i)", spawntime, light, medium, heavy)
	}
	else if (spawntime >= WARNTIME)
	{
		KvSetColor(kv, "color", 255, 207, 64, 255)
		Format(message, sizeof(message), "SpawnTime: %is - L(%i) M(%i) H(%i)", spawntime, light, medium, heavy)
	}
	else if (spawntime > 0)
	{
                Format(message, sizeof(message), "SpawnTime: %is - L(%i) M(%i) H(%i)", spawntime, light, medium, heavy)
	}
	else if (spawntime = 0)
	{
                KvSetColor(kv, "color", 0, 255, 0, 255)
                Format(message, sizeof(message), "SpawnTime: spawned - L(%i) M(%i) H(%i)", light, medium, heavy)
	}
	else
	{
		KvSetColor(kv, "color", 0, 255, 0, 255)
		Format(message, sizeof(message), "SpawnTime: spawned - L(%i) M(%i) H(%i)", light, medium, heavy)
	}

	KvSetString(kv, "title", message)
	KvSetNum(kv, "level", out_lvl)

	/*
	* hack for overriding old messages, time doesnt work - so we have to override them
	*/
	KvSetNum(kv, "time", 1)
	out_lvl--

	for (new i=1; i <= maxclients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == team)
			{
				/*
				* if our spawnqueue is not empty, send messages
				*/
				if (light != 0 || medium != 0 || heavy != 0)
				{
					gotmessage[i] = 1
					playerspawnid[i] = spawnid
					CreateDialog(i, kv, DialogType_Msg)
					continue
				}
				else if (playerspawnid[i] == spawnid)
				{
					gotmessage[i] = 0
				}
			}
		}

		/*
		* client received last message and is now dead, tell him that and dont spam him anymore (he got the normal spawnqueueinfo now)
		*/
		else if (IsClientInGame(i) && !IsPlayerAlive(i) && !IsFakeClient(i) && gotmessage[i] == 1)
		{
			if (GetClientTeam(i) == team)
			{
				KvSetColor(kv, "color", 0, 0, 255, 255) 
				Format(message, sizeof(message), "SpawnTime: dead - L(%i) M(%i) H(%i)", light, medium, heavy)
				KvSetString(kv, "title", message)
				CreateDialog(i, kv, DialogType_Msg)
				gotmessage[i] = 0
				continue
			}
		}

	}
	CloseHandle(kv)
}
