//
// CHANGELOG:
// Version:
//        0.1.0 [08.04.2010] first release to community


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2.0"

#define TEAM_SPEC 1

//lowest speed of a player
#define CAMPDISTANCE 40.0

new Handle:C_Plugin_Enable = INVALID_HANDLE;
new bool:c_plugin_enable;

new Handle:C_Max_Camp_Time = INVALID_HANDLE;
new c_max_camp_time;

new Handle:C_Slap_Diff_Time = INVALID_HANDLE;
new c_slap_diff_time;

new Handle:C_Slap_Dmg = INVALID_HANDLE;
new c_slap_dmg;

new Handle:g_timer = INVALID_HANDLE;
new bool:largeCheck;

//attributes for player
//camping
new Float:g_player_spawnPos[MAXPLAYERS+1][3]; //spawn position
new Float:g_player_lastPos0[MAXPLAYERS+1][3];
new Float:g_player_lastPos1[MAXPLAYERS+1][3];
new Float:g_player_nowPos[MAXPLAYERS+1][3];
new g_player_counter[MAXPLAYERS + 1]; //counter in seconds which player can camp

new bool:g_player_check[MAXPLAYERS+1];
new bool:g_player_inSpawn[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "hpAntiCamp",
	author = "psychocoder",
	description = "this is a anti camp tool with minimize overhead and inteligent camper detection",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart() 
{
	CreateConVar("sm_hpanticamp_version", PLUGIN_VERSION,
			"Version of high performance anti camp", FCVAR_PLUGIN
					| FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	C_Plugin_Enable = CreateConVar("sv_hpanticamp_enable", "1",
			"Activate anti camp plugin (0 to disable, 1 to enable: default=1)",
			FCVAR_PLUGIN);
	C_Max_Camp_Time = CreateConVar("sv_hpanticamp_max_camp_time", "60",
			"Time in seconds which player can camp. (default = 60)",
			FCVAR_PLUGIN, true, 0.0, true, 600.0);
	C_Slap_Diff_Time = CreateConVar("sv_hpanticamp_slap_diff_time", "10",
			"Time in seconds between slaps for camping. (default = 10)",
			FCVAR_PLUGIN, true, 2.0, true, 100.0);
	C_Slap_Dmg = CreateConVar("sv_hpanticamp_slap_dmg", "20",
			"Dmg for camping. (default = 20)", FCVAR_PLUGIN, true, 0.0, true,
			100.0);

	HookConVarChange(C_Plugin_Enable, Changed_Plugin_Enable);
	HookConVarChange(C_Max_Camp_Time, Changed_Max_Camp_Time);
	HookConVarChange(C_Slap_Diff_Time, Changed_Slap_Diff_Time);
	HookConVarChange(C_Slap_Dmg, Changed_Slap_Dmg);

	HookEvent("player_death", PlayerDeathEvent);

	PrecacheSound("player/damage/male/minorpain.wav", true); //slap sound

	c_plugin_enable = GetConVarBool(C_Plugin_Enable);
	c_max_camp_time = GetConVarInt(C_Max_Camp_Time);
	c_slap_diff_time = GetConVarInt(C_Slap_Diff_Time);
	c_slap_dmg = GetConVarInt(C_Slap_Dmg);

	largeCheck = true;
	//clear all data from any player
	for (new i = 1; i <= MaxClients; i++) {
		ClearPlayerData(i);
	}

	//EvntHooks
	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("player_spawn", PlayerSpawnEvent);
}

public OnEventShutdown() 
{
	ResetTimer();
	UnhookConVarChange(C_Plugin_Enable, Changed_Plugin_Enable);
	UnhookConVarChange(C_Max_Camp_Time, Changed_Max_Camp_Time);
	UnhookConVarChange(C_Slap_Diff_Time, Changed_Slap_Diff_Time);
	UnhookConVarChange(C_Slap_Dmg, Changed_Slap_Dmg);

	UnhookEvent("player_death", PlayerDeathEvent)
	UnhookEvent("player_spawn", PlayerSpawnEvent)
}

//----------------------------CVAR-----------------------------------------------------
//Functions for optimize Cvar read (this is faster as call the GetConVar function)


//enable plugin CVAR

public Changed_Plugin_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	c_plugin_enable = GetConVarBool(C_Plugin_Enable);

	if (c_plugin_enable == true)
	{
		//clear all data from any player
		for(new i=1;i<= MaxClients;i++)
		{
			ClearPlayerData(i);
		}
	}
	else
	{
		ResetTimer();
	}
}

public Changed_Max_Camp_Time(Handle:convar, const String:oldValue[], const String:newValue[])
{
	c_max_camp_time = GetConVarInt(C_Max_Camp_Time);
}

public Changed_Slap_Diff_Time(Handle:convar, const String:oldValue[], const String:newValue[])
{
	c_slap_diff_time = GetConVarInt(C_Slap_Diff_Time);
}

public Changed_Slap_Dmg(Handle:convar, const String:oldValue[], const String:newValue[])
{
	c_slap_dmg = GetConVarInt(C_Slap_Dmg);
}

//----------------------------------------------------------------------------------------


public OnMapStart() 
{
	if (c_plugin_enable) {
		if (g_timer == INVALID_HANDLE) {
			g_timer = CreateTimer(1.0, checkCamp, INVALID_HANDLE, TIMER_REPEAT
					| TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnMapEnd() {
	ResetTimer();
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (c_plugin_enable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		if(client > 0 && IsClientInGame(client))
		{
			ClearPlayerData(client);
			g_player_check[client]=true;
		}
	}

}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (c_plugin_enable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		g_player_check[client]=false;
		g_player_inSpawn[client]=true;
	}
}

ResetTimer() 
{
	if (g_timer != INVALID_HANDLE) {
		if (CloseHandle(g_timer)) {
			g_timer = INVALID_HANDLE;
		}
	}
}

ClearPlayerData(client)
{
	if(IsClientInGame(client))
	{
		GetClientAbsOrigin(client, g_player_spawnPos[client]); //spawn position
		GetClientAbsOrigin(client, g_player_lastPos0[client]); //spawn position
		GetClientAbsOrigin(client, g_player_lastPos1[client]); //spawn position
		GetClientAbsOrigin(client, g_player_nowPos[client]); //spawn position
		g_player_counter[client]=c_max_camp_time;
		g_player_check[client]=false;
		g_player_inSpawn[client]=true;
	}
}

SwapLargeCheck() 
{
	if (largeCheck == true) {
		largeCheck = false;
	} else {
		largeCheck = true;
	}
}

public Action:checkCamp(Handle:timer, any:xxx)
{
	if (c_plugin_enable == false)
	{
		return;
	}

	SwapLargeCheck();

	for(new i=1;i<= MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(IsCamping(i))
			{
				//slap player while camping
				new healStatus=GetClientHealth(i);
				PrintToChat(i,"\x01\x05You shall not camp on this server!!\x01");
				EmitSoundToClient(i, "player/damage/male/minorpain3.wav", _, _, _, _, 0.8);
				g_player_counter[i]+=c_slap_diff_time;
				if((healStatus-c_slap_dmg)<=0)
				{
					SetEntityHealth(i,0);
					new Handle:campDeath = CreateEvent("player_hurt", true);
					SetEventInt(campDeath, "userid", GetClientUserId(i));
					SetEventInt(campDeath, "attacker", GetClientUserId(i));
					SetEventString(campDeath, "weapon", "camping")
					SetEventInt(campDeath, "health", 0)
					SetEventInt(campDeath, "damage", c_slap_dmg)
					SetEventInt(campDeath, "hitgroup", 0)
					FireEvent(campDeath, false)
					FakeClientCommandEx(i, "kill");
				}
				else
				{
					SetEntityHealth(i, healStatus-c_slap_dmg);
				}
			}
		}
	}
}

public bool:IsCamping(client)
{

	GetClientAbsOrigin(client, g_player_nowPos[client]);

	if(g_player_inSpawn[client]==true)
	{
		if(GetVectorDistance(g_player_nowPos[client], g_player_spawnPos[client],false) < 150.0) //spawn area
		{
			return false;
		}
		g_player_inSpawn[client]=false;
	}

	//search weapon
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);

	//bazuka and mg can camp
	if(strncmp(weapon, "weapon_mg",9)==0 || strncmp(weapon, "weapon_30",9)==0 || strncmp(weapon, "weapon_baz",10)==0 || strncmp(weapon, "weapon_ps",9)==0)
	{
		if(g_player_counter[client]<c_max_camp_time)
		{
			g_player_counter[client]++;
		}
		return false;
	}

	if(g_player_check[client]==false)
	{
		if(largeCheck)
		{
			//this check runs every 2 seconds

			//check double radius
			if((GetVectorDistance(g_player_nowPos[client], g_player_lastPos1[client],false) < (CAMPDISTANCE * 2)))
			{
				g_player_lastPos0[client][0]=g_player_nowPos[client][0];
				g_player_lastPos0[client][1]=g_player_nowPos[client][1];
				g_player_lastPos0[client][2]=g_player_nowPos[client][2];
				g_player_check[client]=true;
			}
			g_player_lastPos1[client][0]=g_player_nowPos[client][0];
			g_player_lastPos1[client][1]=g_player_nowPos[client][1];
			g_player_lastPos1[client][2]=g_player_nowPos[client][2];
		}
		return false;
	}
	else
	{
		new Float:dist0=GetVectorDistance(g_player_nowPos[client], g_player_lastPos0[client],false);
		new Float:dist1=GetVectorDistance(g_player_nowPos[client], g_player_lastPos1[client],false);
		g_player_lastPos1[client][0]=g_player_lastPos0[client][0];
		g_player_lastPos1[client][1]=g_player_lastPos0[client][1];
		g_player_lastPos1[client][2]=g_player_lastPos0[client][2];
		g_player_lastPos0[client][0]=g_player_nowPos[client][0];
		g_player_lastPos0[client][1]=g_player_nowPos[client][1];
		g_player_lastPos0[client][2]=g_player_nowPos[client][2];

		if( dist1 > (CAMPDISTANCE * 2))
		{
			if(g_player_counter[client]<c_max_camp_time)
			{
				g_player_counter[client]+=2;
				if(g_player_counter[client]>=c_max_camp_time)
				{
					g_player_counter[client]=c_max_camp_time;
					g_player_check[client]=false;
				}
			}
			return false;
		}
		else if(dist0 < CAMPDISTANCE)
		{
			if(g_player_counter[client]>0)
			{
				g_player_counter[client]--;
			}
			if(g_player_counter[client]==5)
			{
				PrintToChat(client,"\x01\x05You will get slaped in 5 seconds for camping!!\x01");
			}
			else if(g_player_counter[client]==0)
			{
				return true;
			}
			return false;
		}
		//dist is between CAMPDISTANCE and 2*CAMPDISTANCE, so we do nothing

	}
	return false;
}
