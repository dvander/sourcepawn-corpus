#pragma semicolon 1
//#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


//Timers Handle and Timers to stop repeat
Handle Timers[MAXPLAYERS + 1];
int TimerRepeats[MAXPLAYERS + 1];
//Bar entitys and material_modify_controls
int hpBarEnts[MAXPLAYERS + 1];
int MMC[MAXPLAYERS + 1];
// Last enemie damaged
int LastVictim[MAXPLAYERS + 1];
int PlayMaxHealth[MAXPLAYERS + 1];

Handle cv_time;


public Plugin myinfo = 
{
	name = "Hp Bars 2",
	author = "Pericles",
	description = "Show a health bar above the last enemy's head who you damaged",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=312223"
};


public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++) { if(IsClientInGame(i)) OnClientPutInServer(i); }
	
	HookEvent("player_hurt", PlayerHurt_Event);
	HookEvent("player_death", PlayerDeath_Event);
	HookEvent("player_spawn", PlayerDeath_Event);
	HookEvent("player_transitioned", PlayerDeath_Event);
	
	cv_time = CreateConVar("hpbar2_time", "2", "Time that the enemy's health bar is showed in seconds");
	
	AutoExecConfig(true, "HPbar2");
}

public void OnMapStart()
{
	PrecacheModel("animated/hpbar5s.vmt", true);
}

public void OnClientPutInServer(int client)
{	
	TimerRepeats[client]=0; hpBarEnts[client]=-1; LastVictim[client]=-1;
}

public Action PlayerDeath_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (PlayMaxHealth[client] != 0)
	{
		PlayMaxHealth[client] = 0;
	}
}

public Action PlayerHurt_Event(Event event, const char[] name, bool dontBroadcast)
{	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int victimHP = event.GetInt("health");

	if(attacker == victim || attacker == 0) return;
	
	if (!IsValidClient(victim) || !IsValidClient(attacker)) return;
	
	if (IsFakeClient(attacker)) return;

	if(EntRefToEntIndex(hpBarEnts[attacker])==-1) NewHPbar(attacker);
				
	int ent = EntRefToEntIndex(hpBarEnts[attacker]);

	if (LastVictim[attacker]!=victim)
	{
		AcceptEntityInput(ent, "ClearParent");
		float pos[3]; GetClientAbsOrigin(victim, pos); pos[2]+=80;
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", victim, ent, 0);
		
		LastVictim[attacker]=victim;
	}
			
	if (victimHP==0 || !IsPlayerAlive(victim)) {HideHPbar(victim); return;}
			
	AcceptEntityInput(ent, "ShowSprite");

	DrawHPBar(attacker, victim, victimHP);
		
	TimerRepeats[attacker]=0;
	if (Timers[attacker]==INVALID_HANDLE) Timers[attacker] = CreateTimer(0.2, T_Update, attacker, TIMER_REPEAT);
}

public void HideHPbar(int victim)
{
	for (int client=1; client<=MaxClients; client++)
	{
		if (LastVictim[client]==victim && IsClientInGame(client))
		{
			int ent = EntRefToEntIndex(hpBarEnts[client]);
			if (ent!=-1) AcceptEntityInput(ent, "HideSprite");
		}
	}  
}

public void NewHPbar(int owner)
{
	char iTarget[20];
	GetClientName(owner, iTarget, 20);
	
	int ent = CreateEntityByName("env_sprite");
	if (ent!=-1)
	{
		hpBarEnts[owner] = EntIndexToEntRef(ent);
		
		DispatchKeyValue(ent, "model", "animated/hpbar5s.vmt");
		DispatchKeyValue(ent, "scale", "0.5");
		DispatchKeyValue(ent, "rendermode", "7");
		
		Format(iTarget, 16, "sprite%d", owner);
		DispatchKeyValue(ent, "targetname", iTarget);
		
		DispatchSpawn(ent);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "HideSprite");
		
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", owner);	
		SDKHook(ent, SDKHook_SetTransmit, SetTransmit_Hook);
	}
	
	ent = CreateEntityByName("material_modify_control");
	if (ent!=-1)
	{
		MMC[owner] = EntIndexToEntRef(ent);
		
		DispatchKeyValue(ent, "materialName", "animated/hpbar5s.vmt");
		DispatchKeyValue(ent, "materialVar", "$frame");
		
		SetVariantString(iTarget);
		AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	}
}

public Action SetTransmit_Hook(int entity, int client)
{
	if(GetEdictFlags(entity) & FL_EDICT_ALWAYS)
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
	
	if ( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client ) return Plugin_Continue;
	
	return Plugin_Stop;
}

public void DrawHPBar(int client, int victim, int victimHP)
{
	char strHP[3]; int frame = 1;
		
	if (PlayMaxHealth[victim] <= 0)
	{
		PlayMaxHealth[victim] = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
	}		
	else if (PlayMaxHealth[victim] > 0 && PlayMaxHealth[victim] < GetClientHealth(victim))
	{
		PlayMaxHealth[victim] = victimHP;
	}
		
	int MaxHealth = PlayMaxHealth[victim]/20;

	for (int i=MaxHealth;i<=MaxHealth*20;i+=MaxHealth)
	{
		if (victimHP<=i) break;
		frame++;
	}
		
	IntToString(frame, strHP, 3);
		
	char Vstring[12];
		
	Format(Vstring, 12, "%s -1 0 0", strHP);
	SetVariantString(Vstring);
	if(IsValidEntity(MMC[client])) AcceptEntityInput(EntRefToEntIndex(MMC[client]), "StartAnimSequence");
}

public Action T_Update(Handle timer, any client)
{
	int ent = EntRefToEntIndex(hpBarEnts[client]);
	if (ent==-1)
	{
		TimerRepeats[client]=0 ; Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if (TimerRepeats[client]>=GetConVarInt(cv_time)*5) 
	{ 
		TimerRepeats[client]=0 ; Timers[client]=INVALID_HANDLE;
		AcceptEntityInput(ent, "HideSprite");		
		
		return Plugin_Stop; 
	}
	DrawHPBar(client, LastVictim[client], GetClientHealth(LastVictim[client]));
	
	TimerRepeats[client]++;
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	killTimer(client);
	int hpEnt = EntRefToEntIndex(hpBarEnts[client]);
	if(hpEnt!=-1) AcceptEntityInput(hpEnt, "KillHierarchy" );
}

public void killTimer(int victim)
{
	for (int client=1; client<=MaxClients; client++)
	{
		if (IsClientInGame(client) && LastVictim[client]==victim && Timers[client]!=INVALID_HANDLE)
		{
			KillTimer(Timers[client]);
			Timers[client] = INVALID_HANDLE;
		}
	}  
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}