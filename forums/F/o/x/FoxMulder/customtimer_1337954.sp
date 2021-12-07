#include <sourcemod>
#include <wepannounce>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

#define SOUND_ATTENTION 		"vo/announcer_attention.wav"
#define SOUND_BEGINS_1	 		"vo/announcer_begins_1sec.wav"
#define SOUND_BEGINS_2	 		"vo/announcer_begins_2sec.wav"
#define SOUND_BEGINS_3	 		"vo/announcer_begins_3sec.wav"

#define REQUIRED_PLAYERS 		10

new nextSpawn;

public Plugin:myinfo = 
{
	name = "[TF2] Custom Timer",
	author = "Fox",
	description = "custom timer",
	version = PLUGIN_VERSION,
	url = "http://www.rtdgaming.com"
}

public OnMapStart()
{
	decl String:sMapname[128];
	GetCurrentMap(sMapname, sizeof(sMapname));
	
	if(!StrEqual(sMapname,"cp_manor_event", false))
		return;
	
	PrecacheSounds();
	CreateTimer(1.0,  	ShowTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
}

PrecacheSounds()
{
	PrecacheSound(SOUND_ATTENTION, true);
	PrecacheSound(SOUND_BEGINS_1, true);
	PrecacheSound(SOUND_BEGINS_2, true);
	PrecacheSound(SOUND_BEGINS_3, true);
}

public Action:ShowTimer(Handle:timer)
{
	new timeMin;
	new timeLeft;
	
	new String:timeSec[3];
	new String:message[32];
	
	timeLeft = nextSpawn - GetTime();
	
	timeMin = timeLeft / 60; //Minutes Left
	
	IntToString((timeLeft - (timeMin * 60)), timeSec, sizeof(timeSec)); //Seconds Left
	if(strlen(timeSec) == 1)
	{
		Format(timeSec, sizeof(timeSec), "0%s", timeSec);
	}
	
	///////////////////////////////////////////
	// Are enough players in server to spawn //
	// the gift? If not infor the clients    //
	///////////////////////////////////////////
	new totalPlayers = playersInServer();
	if(totalPlayers < REQUIRED_PLAYERS)
	{
		new need = REQUIRED_PLAYERS - totalPlayers;
		
		if(need == 1)
		{
			Format(message, sizeof(message), "Need %i more player for gifts", need);
		}else{
			Format(message, sizeof(message), "Need %i more players for gifts", need);
		}
		
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i))
			continue;
		
			SetHudTextParams(0.35, 0.09, 2.0, 250, 250, 0, 255);
			ShowHudText(i, 3, message);
		}
		
		return Plugin_Continue;
	}
	
	if(timeLeft <= 0)
		return Plugin_Continue;
	
	Format(message, sizeof(message), "ETA for Gift: %d:%s", timeMin, timeSec);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		SetHudTextParams(0.43, 0.09, 2.0, 250, 250, 210, 255);
		ShowHudText(i, 3, message);
		
		switch(timeLeft)
		{
			case 10:
				EmitSoundToClient(i, SOUND_ATTENTION);
				
			case 3:
				EmitSoundToClient(i, SOUND_BEGINS_3);
			
			case 2:
				EmitSoundToClient(i, SOUND_BEGINS_2);
			
			case 1:
				EmitSoundToClient(i, SOUND_BEGINS_1);
		}
	}
	
	return Plugin_Continue;
}

public OnItemAddedToInventory(client, itemDefinitionIndex, itemLevel, itemQuality, inventoryPos, String:customName[], String:itemName[], bool:properName, String:typeName[], String:name[], globalIndex_low, globalIndex_high)
{
	if (inventoryPos == 0)
	{
		//PrintToChatAll("%N has found %s%s.", client, properName?"":"a ", name);
	} else if ((inventoryPos & 0xF0000000) == 0xC0000000) 
	{
		if((inventoryPos & 0xFFFF) == 1)
		{
			if(StrContains(itemName, "TF_Halloween_Mask_", false) != -1)
			{
				nextSpawn = GetTime() + 303;
				//PrintToChatAll("Debug: Halloween Mask picked up?");
			}
		}
	}
}

public playersInServer()
{
	new totPlayers;
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			totPlayers++;
		}
	}
	return totPlayers;
}