#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "Fall damage icon for kill messages",
	author = "Zipcore",
	version = PLUGIN_VERSION
};

int g_iLastDamageType[MAXPLAYERS + 1][MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		OnClientPutInServer(i);
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/fall.svg");
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, int &iWweapon, float fDamageForce[3], float dDamagePosition[3])
{
	if(!IsValidClient(iAttacker) || iAttacker == iVictim)
		return Plugin_Continue;
	
	g_iLastDamageType[iAttacker][iVictim] = iDamagetype;
	
	return Plugin_Continue;
}

public Action Event_PlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(iAttacker == 0)
		return Plugin_Continue;
		
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iVictim == iAttacker)
		return Plugin_Continue;
	
	if(g_iLastDamageType[iAttacker][iVictim] & DMG_FALL)
		return FakeDeathEvent(event, "fall");
		
	return Plugin_Continue;
}

stock bool IsValidClient(int iClient)
{
	return (1 <= iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

stock Action FakeDeathEvent(Event oldEvent, char[] weapon)
{
	oldEvent.BroadcastDisabled = true;
	
	Event event_fake = CreateEvent("player_death", true);
	
	char sWeapon[64];
	Format(sWeapon, sizeof sWeapon, "weapon_%s", weapon); // trys to use materials/panorama/images/icons/equipment/<WEAPONNAME>.svg
	event_fake.SetString("weapon", sWeapon);
	
	event_fake.SetInt("userid", oldEvent.GetInt("userid"));
	event_fake.SetInt("attacker", oldEvent.GetInt("attacker"));
	
	event_fake.SetInt("assister", oldEvent.GetInt("assister"));
	event_fake.SetBool("assistedflash", oldEvent.GetBool("assistedflash"));
	event_fake.SetBool("headshot", oldEvent.GetBool("headshot"));
	event_fake.SetBool("dominated", oldEvent.GetBool("dominated"));
	event_fake.SetBool("revenge", oldEvent.GetBool("revenge"));
	event_fake.SetBool("wipe", oldEvent.GetBool("wipe"));
	event_fake.SetBool("penetrated", oldEvent.GetBool("penetrated"));
	event_fake.SetBool("noreplay", oldEvent.GetBool("noreplay"));
	event_fake.SetBool("noscope", oldEvent.GetBool("noscope"));
	event_fake.SetBool("thrusmoke", oldEvent.GetBool("thrusmoke"));
	event_fake.SetBool("attackerblind", oldEvent.GetBool("attackerblind"));
	
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		event_fake.FireToClient(i);
	}
	
	event_fake.Cancel();
	
	return Plugin_Changed;
}