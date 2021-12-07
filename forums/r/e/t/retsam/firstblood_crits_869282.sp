/* 
  First Blood Crits
  by: Retsam
  
  0.2	- Added some more cvars to enable/disable the messages and sounds
  
  0.1	- Initial Release
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_VERSION "0.2"

#define FIRST_BLOOD2 	"vo/announcer_am_firstblood02.wav"

new g_iFirstkill;
new g_iRoundStarts;
new bool:g_PreGameChk;
new String:TimeMessage1[32];
new Handle:g_firstbloodMsg = INVALID_HANDLE;
new Handle:g_firstbloodSound = INVALID_HANDLE;
new Handle:g_critsTime 		= INVALID_HANDLE;
new Handle:g_CritsTimerHandle[MAXPLAYERS+1] = INVALID_HANDLE;

new CTimerCount[MAXPLAYERS+1];
new PlayerCritsChk[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "First Blood Crits",
	author = "Retsam",
	description = "Player who gets first blood wins crits for set duration",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_firstbloodcrits_version", PLUGIN_VERSION, "FirstBlood Crits version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_critsTime = CreateConVar("sm_firstbloodcrits_time", "5.0", "Period in seconds for crits duration", FCVAR_PLUGIN);
	g_firstbloodMsg = CreateConVar("sm_firstbloodcrits_msg", "1", "Display first blood crits msg? (1/0 = yes/no)");
	g_firstbloodSound = CreateConVar("sm_firstbloodcrits_emitsound", "1", "Emit the first blood sound file? (1/0 = yes/no)");
	HookEvent("player_death", hook_Playersdying, EventHookMode_Post);
	HookEvent("teamplay_round_start", hook_Roundstart, EventHookMode_Post);
	
	AutoExecConfig(true, "plugin.firstbloodcrits");
}

public OnClientPostAdminCheck(client)
{
  CTimerCount[client] = 0;
  PlayerCritsChk[client] = 0;
}

public OnClientDisconnect(client)
{
  CTimerCount[client] = 0;
  PlayerCritsChk[client] = 0;
}

public OnConfigsExecuted()
{
	Format(TimeMessage1, sizeof(TimeMessage1), "%i second(s)", GetConVarInt(g_critsTime));
	
	HookConVarChange(g_critsTime, ConVarChange_CritsPeriod);
	
	PrecacheSound(FIRST_BLOOD2, true);	
}

public ConVarChange_CritsPeriod(Handle:convar, const String:oldValue[], const String:newValue[])
{
        Format(TimeMessage1, sizeof(TimeMessage1), "%i second(s)", StringToInt(newValue));
}

public OnMapStart()
{
	g_PreGameChk = false;
	g_iRoundStarts = 0;
	g_iFirstkill = 0;
}

public Action:hook_Playersdying(Handle:event, const String:name[], bool:dontBroadcast)
{		
	//get killer id
	new killer = GetEventInt(event, "attacker"), 
	k_client = GetClientOfUserId(killer), 	// killer index
	victim = GetEventInt(event, "userid"),	
	v_client = GetClientOfUserId(victim),	// victim index
	bool:suicide = false;					// suicide
	  	
	if (GetEventInt(event, "death_flags") & 32) // dead ringer kill print message but really do nothing
	{
		if (!IsValidClient(k_client))
				return Plugin_Continue;
	}
	
	if(k_client == v_client || !IsValidClient(k_client))
		suicide = true;
	
	if (!suicide)
	{
		if (g_iFirstkill <= 1)
			FirstBloodChk(k_client, v_client);
	}
  
	if(PlayerCritsChk[v_client] == 1)
	{
		CTimerCount[v_client] = 0;
		PlayerCritsChk[v_client] = 0;
    
		if(g_CritsTimerHandle[v_client] != INVALID_HANDLE)
		{
			KillTimer(g_CritsTimerHandle[v_client]);
			g_CritsTimerHandle[v_client] = INVALID_HANDLE;
		}
	}  
	return Plugin_Continue;
}

public Action:hook_Roundstart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iFirstkill = 0;
		
	if(g_iRoundStarts++ < 1)
		g_PreGameChk = true;
	else
		g_PreGameChk = false;
		
	return Plugin_Continue;
}

FirstBloodChk(k_client, v_client)
{
	new Handle:cvarArena = FindConVar("tf_gamemode_arena");
	if (IsValidClient(k_client) && !GetConVarBool(cvarArena) && !g_PreGameChk && g_iFirstkill++ == 0)
	{
		decl String:FirstBlood[125], String:killerName[32], String:victimName[32];
		if (IsFakeClient(k_client))
			Format(killerName, sizeof(killerName), "A Bot");
		else
			GetClientName(k_client, killerName, sizeof(killerName));
		if (IsFakeClient(v_client))
			Format(victimName, sizeof(victimName), "A Bot");
		else
			GetClientName(v_client, victimName, sizeof(victimName));
		
    if(GetConVarInt(g_firstbloodMsg) == 1)
    {	
		Format(FirstBlood, sizeof(FirstBlood), "\x01[SM] \x03%s \x01got \x04first blood\x01 this round by killing \x04%s\x01, and has won \x05crits!", killerName, victimName);
		SayText2All(k_client, FirstBlood);
	}  
		
	if(GetConVarInt(g_firstbloodSound) == 1)
    {
		EmitSoundToAll(FIRST_BLOOD2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
	FBCritsEnable(k_client);
  }
}

public FBCritsEnable(client)
{
        PlayerCritsChk[client] = 1;
        
        CTimerCount[client] = 0;
        g_CritsTimerHandle[client] = CreateTimer(1.0, TimerRepeat, client, TIMER_REPEAT);
                
        CreateTimer(GetConVarFloat(g_critsTime), FBCritsOff, client);
}

public Action:TimerRepeat(Handle:Timer, any:client)
{
        CTimerCount[client]++;
        if(PlayerCritsChk[client] == 1)
        {
            PrintCenterText(client, "%i second(s) left!", GetConVarInt(g_critsTime) - CTimerCount[client]);
        }
}

public Action:FBCritsOff(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
        if(PlayerCritsChk[client] == 1)
        {
          if(GetConVarInt(g_firstbloodMsg) == 1)
          {
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[SM] \x03%N's\x01 \x04first blood \x05crits \x01wore off.", client);
    
            SayText2All(client, nm);        
          }
          
          if(g_CritsTimerHandle[client] != INVALID_HANDLE)
          {
              KillTimer(g_CritsTimerHandle[client]);
              g_CritsTimerHandle[client] = INVALID_HANDLE;
          }
          
          CTimerCount[client] = 0;
          PlayerCritsChk[client] = 0;
        }
        else
        {
          return;  
        }   
}

stock bool:IsValidClient(client)
{
	if (client
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& !IsFakeClient(client))
		return true;
	else
		return false;
}

SayText2All(author, const String:message[]) {
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
        if(PlayerCritsChk[client] == 1)
        {
                //PrintToChatAll("Crits = On");
                result = true;
                return Plugin_Handled;
        }
	
	return Plugin_Continue;
}
