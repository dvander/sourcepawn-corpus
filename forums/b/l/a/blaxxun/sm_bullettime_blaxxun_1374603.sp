//Includes:
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define DF_CRITS		1048576	//crits = DAMAGE_BULLET


#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

new Handle:bt_enable;
new Handle:bt_timescale;
new Handle:bt_trans;
new Handle:bt_headshots;
new Handle:bt_killstreak;
new Handle:bt_he;
new Handle:bt_fsound;
new Handle:bt_random;


new slowdown = 0;
new focussound = 2;
new transition = false;
new Float:timescale = 0.50;
new bool:btReady = true;


new iMaxClients;

new consecutiveKills[MAXPLAYERS + 1];
new Float:lastKillTime[MAXPLAYERS + 1];
new lastKillCount[MAXPLAYERS + 1];
new headShotCount[MAXPLAYERS + 1];
//new btChance[MAXPLAYERS + 1];

new Handle:Cheats = INVALID_HANDLE;

static const String:Weapons[][]={"knife"};	


public Plugin:myinfo = 

{
	name = "SM Bullet Time - modified",
	author = "blaxxun",
	description = "Creates a slow-motion effect on events in bullet time / matrix style",
	version = PLUGIN_VERSION,
	url = "http://www.theheadcollectors.de/"
};

public OnPluginStart() 
{
	CreateConVar("sm_bullettime_version", PLUGIN_VERSION, "SM Bullet Time Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	bt_enable = CreateConVar("bt_enable", "1", "Enables/Disables Bullet Time.", FCVAR_PLUGIN);
	bt_trans = CreateConVar("bt_transition", "1", "Transitions the timescales if on. If not, timescales are set directly.", FCVAR_PLUGIN);
	bt_random = CreateConVar("bt_random", "1", "Random activation instead of simple headshot and killstreak triggers. (in dev.)", FCVAR_PLUGIN);
	bt_headshots = CreateConVar("bt_headshots", "3", "Number of headshots that trigger bullettime - 0 disables", FCVAR_PLUGIN);
	bt_killstreak = CreateConVar("bt_killstreak", "2", "Triggers on killstreak. e.g. 2 i.e. on doublekill - 0 disables", FCVAR_PLUGIN);
	bt_he = CreateConVar("bt_he", "1", "Starts bullet time on kill with handgrenade.", FCVAR_PLUGIN);
	bt_timescale = CreateConVar("bt_timescale", "0.50", "Slowdown timescale.", FCVAR_PLUGIN);
	bt_fsound = CreateConVar("bt_fsound", "2", "Plays a sound for the focus of bullet time. If 2 it replaces the default sound rather than playing simultaneously.", FCVAR_PLUGIN);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookConVarChange(bt_trans, OnConVarChanged_Trans);
	timescale = GetConVarFloat(bt_timescale);
	transition = GetConVarBool(bt_trans);
	focussound = GetConVarBool(bt_fsound);
	
	Cheats = FindConVar("sv_cheats");
}

public OnConfigsExecuted() 
{
    AddFileToDownloadsTable("materials/imgay/slowdown1.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown2.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown3.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown1.vtf");
    AddFileToDownloadsTable("materials/imgay/slowdown2.vtf");
    AddFileToDownloadsTable("materials/imgay/slowdown3.vtf");
}

public OnMapStart()
{
	iMaxClients=GetMaxClients();

	PrecacheSound("mb_bullettime/enter.mp3", true);
	PrecacheSound("mb_bullettime/exit.mp3", true);
	AddFileToDownloadsTable("mb_bullettime/enter.mp3");
	AddFileToDownloadsTable("mb_bullettime/exit.mp3");
	
	CheatConVarSetup()
} 

ActivateSlow(activator) 
{
    if (slowdown > 0 || !GetConVarBool(bt_enable))
        return;
    slowdown = 80;
    for(new i = 1; i <= MaxClients; i++) 
	{
        if(IsValidClient(i) && !IsFakeClient(i)) 
		{
            ClientCommand(i,"r_screenoverlay imgay/slowdown1");
            if (i != activator) 
			{
                EmitSoundToClient(i, "mb_bullettime/enter.mp3");
            }
        }
    }
    timescale = GetConVarFloat(bt_timescale);
    ServerCommand("host_timescale %f", timescale);
}

public OnGameFrame() 
{
	if (transition && slowdown <= 10 && slowdown > 1)
	{
		timescale = GetConVarFloat(bt_timescale);
		new Float:difscale = 1.0 - timescale;
		new Float:tempscale = 1.0 - difscale * slowdown *0.1;
		ServerCommand("host_timescale %f", tempscale);
	}

	
	if (slowdown == 30)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				EmitSoundToClient(i, "mb_bullettime/exit.mp3");
			}
		}   
	}
	
	if (slowdown == 5)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				ClientCommand(i,"r_screenoverlay imgay/slowdown2");
			}
		}   
	}
    
	if (slowdown == 3)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				ClientCommand(i,"r_screenoverlay imgay/slowdown3");
			}
		}   
	}
	if (slowdown == 1)
	{
		slowdown = slowdown - 1;
		ServerCommand("host_timescale 1.0")
		SetConVarInt(Cheats, 0, true, true)
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				ClientCommand(i,"r_screenoverlay \"\"")
			}
		}
	}
	
	
	if (slowdown > 1)
	{
		slowdown = slowdown - 1;
	}
}

public OnConVarChanged_Trans(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	transition = GetConVarBool(bt_trans);
}

public OnClientPutInServer(client)
{
	consecutiveKills[client] = 0;
	lastKillTime[client] = -1.0;
	headShotCount[client] = 0;
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= iMaxClients; i++) 
	{
		headShotCount[i] = 0;
		lastKillTime[i] = -1.0;
	}
}


public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) 
{
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user ID who attacked
	// "weapon"        "string"        // weapon name attacker used
	// "health"        "byte"          // health remaining
	// "damage"        "byte"          // how much damage in this attack
	// "hitgroup"      "byte"          // what hitgroup was hit	
	
	if (!GetConVarBool(bt_enable))
		return;
	decl String:weapon[512];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victimClient = GetClientOfUserId(GetEventInt(event, "userid"));
    
	new bool:go = false;
	new activator = -1;
	
	new Float:xFactor = GetRandomFloat(0.0,1.0);
	
	if(victimClient<1 || victimClient>iMaxClients)
	{
		return;
	}
	
	if(attackerClient>0 && attackerClient<=iMaxClients)
	{
		
		for (new i = 0; i < sizeof(Weapons); i++) 
		{
			if(GetConVarBool(bt_random))
			{
				if (StrEqual(weapon,Weapons[i],false)) 
				{	
					xFactor -= 0.6;
				}
				
				if(xFactor < 0.02 && btReady)
				{
					go = true;
					btReady = false;
					//PrintToChatAll(" - bullettime OFF (HURT)");
					CreateTimer(GetRandomFloat(11.0,22.0), BTreset);	
				}
			}
			else
				if (StrEqual(weapon,Weapons[i],false)) 
				{	
					go = true;
				}
			focussound = GetConVarBool(bt_fsound);
			if (go == true && focussound >= 1) 
			{
				if(IsValidClient(attackerClient) && !IsFakeClient(attackerClient)) 
				{
					EmitSoundToClient(attackerClient, "mb_bullettime/enter.mp3");
					if (focussound >= 2) activator = attackerClient;
				}
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}
	}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	
	if (!GetConVarBool(bt_enable))
		return;
	
	new String:weapon[512];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victimClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:headshot = GetEventBool(event, "headshot");
	new bool:go = false;
	new activator = -1;
	
	new Float:xFactor = GetRandomFloat(0.0,1.0);
	
	if(victimClient<1 || victimClient>iMaxClients)
	{
		return;
	}
	
	if(attackerClient>0 && attackerClient<=iMaxClients)
	{
		headShotCount[victimClient] = 0;
		lastKillTime[victimClient] = -1.0;
		
		
		if(GetConVarBool(bt_random))
		{
			if(GetConVarInt(bt_killstreak)>0)
			{
				new Float:tempLastKillTime = lastKillTime[attackerClient];
				lastKillTime[attackerClient] = GetEngineTime();			
				if(tempLastKillTime == -1.0 || (lastKillTime[attackerClient] - tempLastKillTime) > 1.5)
				{
					lastKillCount[attackerClient] = 1;
				}
				else
				{
					lastKillCount[attackerClient]++;
					xFactor -= lastKillCount[attackerClient] * 0.17;
				}
			}
			
			if(GetConVarInt(bt_headshots)>0 && headshot)
			{
				headShotCount[attackerClient]++;
				xFactor -= headShotCount[attackerClient] * 0.11;
			}
			
			if(StrEqual(weapon,"hegrenade",false) && GetConVarInt(bt_he) == 1) xFactor -= 0.3;			
			
			
			if(xFactor < 0.05 && btReady)
			{
				go = true;
				btReady = false;
				//PrintToChatAll(" - bullettime OFF (DEATH)");
				CreateTimer(GetRandomFloat(8.0,15.0), BTreset);	
			}
		}
		else
		{
			if(GetConVarInt(bt_killstreak)>0)
			{
				new Float:tempLastKillTime = lastKillTime[attackerClient];
				lastKillTime[attackerClient] = GetEngineTime();			
				if(tempLastKillTime == -1.0 || (lastKillTime[attackerClient] - tempLastKillTime) > 1.5)
				{
					lastKillCount[attackerClient] = 1;
				}
				else
				{
					lastKillCount[attackerClient]++;
					xFactor -= lastKillCount[attackerClient] * 0.2
				}
				
				if(GetConVarInt(bt_killstreak)<=lastKillCount[attackerClient])
					go = true;
			}
			
			if(GetConVarInt(bt_headshots)>0 && headshot)
			{
				headShotCount[attackerClient]++;
				
				if (GetConVarInt(bt_headshots) <= headShotCount[attackerClient])
				{
					headShotCount[attackerClient] = 0;
					go = true;
				}
			}
			
			if(StrEqual(weapon,"hegrenade",false) && GetConVarInt(bt_he) == 1) go = true;
		}
		
		focussound = GetConVarBool(bt_fsound);
		
		if (go == true && focussound >= 1)
		{
			if(IsValidClient(attackerClient) && !IsFakeClient(attackerClient)){
				EmitSoundToClient(attackerClient, "mb_bullettime/enter.mp3");
				if (focussound >= 2) activator = attackerClient;
			}
			ActivateSlow(activator);
			SetConVarInt(Cheats, 1, true, true);
		}
	}
}



stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}


public CheatConVarSetup()
{
	new flags = GetConVarFlags(Cheats) 
	flags &= ~FCVAR_NOTIFY
	SetConVarFlags(Cheats, flags)
	if(GetConVarInt(Cheats) == 1)
	{
		SetConVarInt(Cheats, 0, true, true)
	}
}

public Action:BTreset(Handle:Timer)
{
	btReady = true;
	//PrintToChatAll(" + bullettime ON");
}