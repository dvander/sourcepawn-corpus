#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION	"1.0.0"
#define AUTHOR "Delachambre"
#define DESCRIPTION "Private Mod Hostage Magnetik"
#define NAME "Hostage_Rescue"
#define FORUM 	"http://forum.clan-magnetik.fr"
#define LOGO	"\x04[Hostage-Mod] \x01"

new gb_CountHostageRescue = 0;
new gb_CountHostagePlayer[MAXPLAYERS+1] = 0;
new gb_CountWinCt = 0;
new gb_HostageLife = 0;
new gb_CountTerroristLife = 0;

new Handle:TimerHud[MAXPLAYERS+1] = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("hostage_rescued", EventHostageRescued, EventHookMode_Post);
	HookEvent("hostage_killed", Event_HostageKilled);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public OnMapStart()
{
	gb_CountWinCt = 0;
	gb_CountHostageRescue = 0;
	gb_HostageLife = 0;
}

public OnMapEnd()
{
	gb_CountWinCt = 0;
	gb_CountHostageRescue = 0;
	gb_HostageLife = 0;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	gb_HostageLife = 0;
	
	decl String:sClassName[32];
	
	new MaxENT = GetEntityCount();
	
	for (new entity = MaxClients + 1; entity < MaxENT; entity++)
	{
		if (IsValidEdict(entity) && GetEdictClassname(entity, sClassName, sizeof(sClassName)) && StrEqual(sClassName, "hostage_entity"))
		{
			gb_HostageLife += 1;
		}
	}
	
	gb_CountHostageRescue = 0;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gb_CountTerroristLife = 0;
}

public Action:Event_HostageKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	gb_HostageLife -= 1;
	
	PrintToChatAll("%s : le joueur %N viens de tuer un Otage.", LOGO, client);
	
	if (gb_HostageLife == 0)
	{
		CS_TerminateRound(4.0, CSRoundEnd_CTWin);
		
		PrintToChatAll("%s : Tout les otages sont mort !", LOGO);
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == 2)
	{
		if (gb_CountTerroristLife > 0)
		{
			gb_CountTerroristLife -= 1;
		}
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == 2)
		{
			gb_CountTerroristLife += 1;
		}
	}
}

public Action:EventHostageRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	gb_CountHostageRescue += 1;
	gb_CountHostagePlayer[client] += 1;
	
	PrintToChatAll("%s : Le joueur %N viens de libéré \x041 \x01otage sur\x04 %i", LOGO, client, gb_HostageLife);
	
	if (gb_CountHostageRescue == gb_HostageLife)
	{
		gb_CountHostageRescue = 0;
		gb_CountWinCt += 1;
		
		if (gb_CountWinCt == 20)
		{
			gb_CountWinCt = 0;
			gb_CountHostageRescue = 0;
			
			ServerCommand("changelevel cs_assault");
		}
	}
	
	return Plugin_Continue;
}

public Action:OnClientPreAdminCheck(client)
{
	TimerHud[client] = CreateTimer(1.0, HudTimer, client, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		if(TimerHud[client] != INVALID_HANDLE)
		{
			KillTimer(TimerHud[client]);
			TimerHud[client] = INVALID_HANDLE;
		}
	}
}

public Action:HudTimer(Handle:timer, any:client)
{
	new Handle:hBuffer = StartMessageOne("KeyHintText", client);
	
	if(!IsClientInGame(client))
    {
        CloseHandle(TimerHud[client]);
        return Plugin_Stop;
    }
	
	if (hBuffer == INVALID_HANDLE)
	{
		PrintToChat(client, "INVALID_HANDLE");
	}
	else
	{
		new String:tmptext[9999];
		{
			Format(tmptext, sizeof(tmptext), "Score : %i / 20\nOtages vivants : %i\nOtages secourus : %i\nVous avez secourus %i otages\nTerroristes en vie : %i\n", gb_CountWinCt, gb_HostageLife, gb_CountHostageRescue, gb_CountHostagePlayer[client], gb_CountTerroristLife);
		}
		BfWriteByte(hBuffer, 1); 
		BfWriteString(hBuffer, tmptext); 
		EndMessage();
	}
	
	return Plugin_Continue;
}