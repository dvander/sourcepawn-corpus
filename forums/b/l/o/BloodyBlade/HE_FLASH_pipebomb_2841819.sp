#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define PIPE_BOMB_VIEW_MODEL "models/v_models/v_pipebomb.mdl"
#define FLASH_BANG 0
#define HE_BOMB 1

enum struct bomb
{
    bool  alwayskill;
    float damageRange;
    float damageToHuman;
    float damageToSpecials;
    float damageToTank;
    float explsoinTime;
}
enum struct flash
{
    float maxRange;
    float minRange;
    int holdTime;   // time that player maintain the max effect of white.
    int durationTime; // time that player getting normal
    float explsoinTime;
}

bomb HE;
flash Flash;
ConVar cvar_pipebomb_enable, cvar_pipebomb_range, cvar_pipebomb_damageTohuman, cvar_pipebomb_damageTospecial, cvar_pipebomb_damageTotank, cvar_pipebomb_alwayskill, cvar_flashbomb_maxrange, cvar_flashbomb_minrange, cvar_flashbomb_holdtime, cvar_flashbomb_drutime;
int g_player_status[MAXPLAYERS + 1] = {0, ...}, g_precache_index = 0;
UserMsg g_FadeUserMsgId;
bool g_bCvarAllow = false;

public Plugin myinfo =
{
	name = "HE pipe bomb and flash bang in cs",
	author = "Miuwiki",
	description = "new damage for pipe bomb and flash bang.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
	g_FadeUserMsgId = GetUserMessageId("Fade");
	cvar_pipebomb_enable = CreateConVar("l4d2_pipebomb_enable", "1", "Enable/Disable plugin. ", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_pipebomb_range = CreateConVar("l4d2_pipebomb_range", "750", "HE pipe bomb range, this will also change the cvar [pipe_bomb_shake_radius]. ", CVAR_FLAGS, true, 0.0, true, 2000.0);
	cvar_pipebomb_damageTohuman = CreateConVar("l4d2_pipebomb_damageTohuman", "95", "HE pipe bomb damage to human.", CVAR_FLAGS, true, 0.0, true, 1000.0);
	cvar_pipebomb_damageTospecial = CreateConVar("l4d2_pipebomb_damageTospecial", "500", "HE pipe bomb damage to specials.", CVAR_FLAGS, true, 0.0, true, 1000.0);
	cvar_pipebomb_damageTotank = CreateConVar("l4d2_pipebomb_damageTotank", "20%", "HE pipe bomb damage to tank, percentage.", CVAR_FLAGS);
	cvar_pipebomb_alwayskill = CreateConVar("l4d2_pipebomb_alwayskill", "0", "HE pipe bomb always kill the specials but not include tank.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_flashbomb_maxrange = CreateConVar("l4d2_flashbomb_maxrange", "1600", "Flash bomb max effect range.", CVAR_FLAGS, true, 0.0, true, 5000.0);
	cvar_flashbomb_minrange = CreateConVar("l4d2_flashbomb_minrange", "800", "Flash bomb min effect range, in this range who face the flash bang will get full white.", CVAR_FLAGS, true, 0.0, true, 5000.0);
	cvar_flashbomb_drutime = CreateConVar("l4d2_flashbomb_drutime", "2000", "Flash bomb the max time that player getting normal.", CVAR_FLAGS, true, 0.0, true, 10000.0);
	cvar_flashbomb_holdtime = CreateConVar("l4d2_flashbomb_holdtime", "1000", "Flash bomb the max time that player maintain the max effect of white.", CVAR_FLAGS, true, 0.0, true, 10000.0);

	AutoExecConfig(true, "l4d2_pipebomb");

	cvar_pipebomb_damageTohuman.AddChangeHook(ConVarChanged_Allow);
	cvar_pipebomb_damageTohuman.AddChangeHook(CVAR_HookCallback);
	cvar_pipebomb_damageTospecial.AddChangeHook(CVAR_HookCallback);
	cvar_pipebomb_damageTotank.AddChangeHook(CVAR_HookCallback);
	cvar_pipebomb_alwayskill.AddChangeHook(CVAR_HookCallback);
	cvar_flashbomb_maxrange.AddChangeHook(CVAR_HookCallback);
	cvar_flashbomb_minrange.AddChangeHook(CVAR_HookCallback);
	cvar_flashbomb_drutime.AddChangeHook(CVAR_HookCallback);
	cvar_flashbomb_holdtime.AddChangeHook(CVAR_HookCallback);
}

public void OnMapStart()
{
    g_precache_index = PrecacheModel(PIPE_BOMB_VIEW_MODEL);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void CVAR_HookCallback(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvar();
}

void IsAllowed()
{
	bool bCvarAllow = cvar_pipebomb_enable.BoolValue;
	if(!g_bCvarAllow && bCvarAllow)
	{
		g_bCvarAllow = true;
		GetCvar();
		HookEvent("player_death", Event_PlayerDeathInfo);
	}
	else if(g_bCvarAllow && !bCvarAllow)
	{
		g_bCvarAllow = false;
		UnhookEvent("player_death", Event_PlayerDeathInfo);
	}
}

void GetCvar()
{
	HE.alwayskill = cvar_pipebomb_alwayskill.BoolValue;
	HE.damageToHuman = cvar_pipebomb_damageTohuman.FloatValue;
	HE.damageToSpecials = cvar_pipebomb_damageTospecial.FloatValue;

	static char percent[8], num[8];
	cvar_pipebomb_damageTotank.GetString(percent,sizeof(percent));
	SplitString(percent,"%",num,sizeof(num));// remove % in string.
	HE.damageToTank = view_as<float>(StringToInt(num));
	HE.damageRange = FindConVar("pipe_bomb_shake_radius").FloatValue = cvar_pipebomb_range.FloatValue;
	FindConVar("pipe_bomb_timer_duration").FloatValue = 2.0;
	FindConVar("pipe_bomb_initial_beep_interval").FloatValue = 10.0;
	FindConVar("pipe_bomb_beep_interval_delta").FloatValue = 0.0;

	Flash.minRange = cvar_flashbomb_minrange.FloatValue;
	Flash.maxRange = cvar_flashbomb_maxrange.FloatValue;
	Flash.holdTime = cvar_flashbomb_holdtime.IntValue;
	Flash.durationTime = cvar_flashbomb_drutime.IntValue;
}

public void OnClientPutInServer(int client)
{
	if(client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamage, SDK_OTDcallback);
		SDKHook(client, SDKHook_WeaponSwitchPost, SDK_WSPcallback);
	}
}

public void OnClientConnected(int client)
{
	if(client > 0)
	{
		g_player_status[client] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	if(client > 0)
	{
		g_player_status[client] = 0;
	}
}

void Event_PlayerDeathInfo(Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
	{
		return;
	}

	if(GetClientTeam(client) == 3 && GetEntProp(client,Prop_Send,"m_iGlowType") == 3)
	{
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	}
}

public Action OnPlayerRunCmd(int client,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon)
{
	if(buttons & IN_RELOAD)
	{
		static float presstime[MAXPLAYERS + 1];
		if(!IsValidRealAliveSurvivor(client))
		{
			return Plugin_Continue;
		}

		int active_weapon = GetEntPropEnt(client,Prop_Send,"m_hActiveWeapon");
		if(active_weapon != -1)
		{
			if(HasEntProp(active_weapon,Prop_Send,"m_iViewModelIndex") && GetEntProp(active_weapon,Prop_Send,"m_iViewModelIndex") != g_precache_index)
			{
				return Plugin_Continue;
			}

			float time = GetEngineTime(); // prevent quickly switch mode.
			if(time - presstime[client] > 1.0)
			{                                                                                                                           
				presstime[client] = time;
				switch(g_player_status[client])
				{
					case HE_BOMB:
					{
						g_player_status[client] = FLASH_BANG;
						PrintToChat(client,"\x03Current:-----\x01Flash bang\x03-----");
					}
					case FLASH_BANG:
					{
						g_player_status[client] = HE_BOMB;
						PrintToChat(client,"\x03Current:-----\x04HE Bomb\x03-----");
					}
				}
			}
		}
	}
	return Plugin_Continue;     
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity < 1 || !IsValidEntity(entity) || !IsValidEdict(entity) || entity <= MaxClients)
		return;

	if(strcmp(classname, "pipe_bomb_projectile") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, SDK_SPcallback);
	}
}

void SDK_SPcallback(int entity)
{
    if(!IsValidEntity(entity))
        return;

    RequestFrame(Next_NFcallback, EntIndexToEntRef(entity));
}

void Next_NFcallback(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity == 0 || !IsValidEntity(entity))
        return;

    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if(!IsValidSurvivor(owner))
        return;

    static char status[16];
    switch(g_player_status[owner])
    {
        case HE_BOMB:
        {
            FormatEx(status,sizeof(status),"HE_BOMB");
            DispatchKeyValue(entity,"targetname",status);
            PrintToChatAll("\x04HE Gernade out!");
        }
        case FLASH_BANG:
        {
            FormatEx(status,sizeof(status),"%s","FLASH_BANG");
            DispatchKeyValue(entity,"targetname",status);
            PrintToChatAll("\x04Flash Bang out!");
        }
    }
}

Action SDK_OTDcallback(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(damagetype & DMG_BLAST_SURFACE)
    {
        static char status[16];
        GetEntPropString(inflictor, Prop_Data, "m_iName", status, sizeof(status));

        if(strcmp(status, "FlASH_BANG", false) == 0)
            return Plugin_Continue;

        static float distance, vic_pos[3];
        GetClientAbsOrigin(victim, vic_pos);
        distance = GetVectorDistance(damagePosition, vic_pos);

        if(0 < GetClientTeam(victim) < 3) // human or survivor bot
        {
            damage = HE.damageToHuman * (1 - distance / HE.damageRange);
        }
        else if(GetClientTeam(victim) == 3)
        {
            int class = GetEntProp(victim, Prop_Send,"m_zombieClass");
            if(class == 8) // only left4dead2
            {
                damage = GetClientHealth(victim) * (HE.damageToTank / 100);
                PrintToChat(attacker, "\x01You cause \x02%.0f damage to \x02%N", damage,victim);
            }
            else
            {
                damage = HE.alwayskill ? GetClientHealth(victim) + 0.0 : HE.damageToSpecials;
            }
        }
        ScaleVector(damageForce, 5.0); // look more terrible
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

void SDK_WSPcallback(int client,int weapon)
{
    if(!IsValidSurvivor(client))
        return;

    static char classname[20];
    GetEntityClassname(weapon, classname, sizeof(classname));
    if(strcmp(classname, "weapon_pipe_bomb") == 0)
    {
        if(g_player_status[client] == FLASH_BANG)
            PrintToChat(client,"\x05Press \x04[R]\x05 to change gernade mode. Now is \x04FLASH_BANG");
        else if( g_player_status[client] == HE_BOMB )
            PrintToChat(client,"\x05Press \x04[R]\x05 to change gernade mode. Now is \x04HE_BOMB");
    }
}

public void OnEntityDestroyed(int entity)
{
	if(entity < 1 || !IsValidEntity(entity))
		return;

	static char classname[32], status[16];
	GetEntityClassname(entity,classname,sizeof(classname));
	GetEntPropString(entity, Prop_Data, "m_iName", status, sizeof(status));

	if(strcmp(classname,"pipe_bomb_projectile") == 0)
	{
		if(strcmp(status, "HE_BOMB",false) == 0)
		{
			int particle = CreateEntityByName("info_particle_system");
			if(particle != -1)
			{
				static float pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(particle, "effect_name", "gas_explosion_pump");
				DispatchKeyValue(particle, "targetname", "particle");
				DispatchSpawn(particle);
				ActivateEntity(particle);
				AcceptEntityInput(particle, "start");
				SetVariantString("OnUser1 !self:Kill::3.0:-1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");
			}
		}
		else if(strcmp(status, "FLASH_BANG", false) == 0) // flash bang
		{
			static float ent_pos[3], player_pos[3], distance, degree,amount;
			GetEntPropVector(entity,Prop_Data,"m_vecOrigin",ent_pos);

			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsValidClient(i) || !IsPlayerAlive(i))
					continue;

				if(IsBehindWall(i, ent_pos))
					continue;

				degree = GetEntClientDegree(entity,i);
				if(degree == 0.0)
					continue;

				GetClientEyePosition(i,player_pos);
				distance = GetVectorDistance(ent_pos,player_pos);
				amount = 255 * (1 - degree/120.0);
				if( distance <= Flash.minRange )  
				{
					amount = 255.0;
					SetPlayerEffect(i,amount);
				}
				else if( Flash.minRange < distance <= Flash.maxRange )
				{
					amount *= (1 - distance/Flash.maxRange);
					SetPlayerEffect(i,amount);
				}
			}
		}
	}
}

void SetPlayerEffect(int client,float amount = 0.0)
{
    if(GetClientTeam(client) == 3)
    {
        SetEntityMoveType(client,MOVETYPE_NONE);
        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
        SetEntProp(client, Prop_Send, "m_glowColorOverride", 0xFFFFFF);
        SetEntProp(client, Prop_Send, "m_nGlowRange", 1600);
        CreateTimer(3.0,Timer_StopFreezeSi, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
    }
    else // human
    {
        if(amount == 0.0) return;
        PerformBlind(client,amount);
    }
}

Action Timer_StopFreezeSi(Handle timer,int userid)
{
    int client = GetClientOfUserId(userid);
    if(!IsValidClient(client))
        return Plugin_Continue;
   
    SetEntityMoveType(client, MOVETYPE_WALK);
    return Plugin_Continue;
}

void PerformBlind(int target, float amount)
{
	int targets[1];
	targets[0] = target;
	
	int flags = (0x0001 | 0x0010); // this flags cause white immedately, and then slowly reduce the effect.

	int color[4] = { 255, 255, 255, 0 };
	color[3] = RoundToNearest(amount);
	
	Handle message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	if(GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", Flash.durationTime);
		pb.SetInt("hold_time", Flash.holdTime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(Flash.durationTime );
		bf.WriteShort(Flash.holdTime);
		bf.WriteShort(flags);		
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}
	EndMessage();
}

stock float GetEntClientDegree(int entity, int client)
{
    static float ent_pos[3], player_pos[3], player_ang[3], eye2ent_vector[3], eye2fwd_vector[3];

    GetClientEyePosition(client, player_pos);
    GetEntPropVector(entity, Prop_Data,"m_vecOrigin",ent_pos);
    MakeVectorFromPoints(player_pos, ent_pos, eye2ent_vector);

    GetClientEyeAngles(client,player_ang);
    GetAngleVectors(player_ang,eye2fwd_vector,NULL_VECTOR,NULL_VECTOR);

    NormalizeVector(eye2ent_vector, eye2ent_vector);
    NormalizeVector(eye2fwd_vector, eye2fwd_vector);

    float degree = ArcCosine(GetVectorDotProduct(eye2ent_vector, eye2fwd_vector)) * 57.29577951;
    /**
     * let me explain how this degree comes.
     * 
     * DotProduct = |a||b|cosθ, this is the vector theorem.
     * we have normalize the vector so |a| = |b| = 1.
     * in this case DotProduct = cosθ.
     * ArcCosine() let us get the degree of θ, but it is a radian num.
     * so the final answer is degree = θ * 180 / π, which approximation is 57.29577951.
     */
    // someone said that player sight degree is less than 120.
    return degree = degree <= 120 ? degree : 0.0;
}

stock bool IsBehindWall(int client,float pos_end[3])
{
    static float pos_client[3];
    GetClientEyePosition(client,pos_client);
    Handle hTrace = TR_TraceHullFilterEx(pos_client, pos_end, {2.0,2.0,2.0}, {2.0,2.0,2.0}, MASK_VISIBLE_AND_NPCS, Filter_IsWall, client);
    if(hTrace != null)
    {
        if(TR_DidHit(hTrace))
        {
            delete hTrace;
            return true;
        }
        delete hTrace;
    }
    return false;
}

stock bool Filter_IsWall(int entity, int mask, int owner)
{
	if(entity == owner) return false;
	static char classname[22];
	GetEntityClassname(entity, classname, sizeof(classname));
	if(strcmp(classname, "pipe_bomb_projectile") == 0)
	{
		return false;
	}
	return true;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

stock bool IsValidRealAliveSurvivor(int client)
{
	return IsValidSurvivor(client) && !IsFakeClient(client) && IsPlayerAlive(client);
}
