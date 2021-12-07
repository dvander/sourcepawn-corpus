#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"

#define ACHIEVEMENT_SOUND	"misc/achievement_earned.wav"

Handle COOKIE_LastPriceDate;
Handle ARRAY_Prizes;
char playerDate[MAXPLAYERS+1][50];
char today[20];
int g_ent[MAXPLAYERS+1];
int g_target[MAXPLAYERS+1];


public Plugin myinfo = 
{
	name = "[ANY] Daily Prizzzes",
	author = PLUGIN_AUTHOR,
	description = "Give prices to player, every day, cool, hu ?",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{ 
  	COOKIE_LastPriceDate = RegClientCookie("sm_dailyprice_date", "Store if player can get the daily price or not.", CookieAccess_Private);
	
	for(new i = MaxClients; i > 0; --i)
    {
        if (!AreClientCookiesCached(i))
            continue;
        OnClientCookiesCached(i);
    }
    
    RegConsoleCmd("sm_rs", CMD_rs);
    
    HookEvent("player_spawn", Event_PlayerSpawn);
    FormatTime(today, sizeof(today), "%d.%m.%Y");
    
    ARRAY_Prizes = CreateArray(45);
    ReadConfigFile();
}

public Action CMD_rs(client, args)
{
	SetClientCookie(client, COOKIE_LastPriceDate, "");
	Format(playerDate[client], sizeof(playerDate[]), "");
}

public void OnMapStart()
{
	PrecacheSound(ACHIEVEMENT_SOUND);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	PrintToServer("%s <-> %s", today, playerDate[client]);
	
	if(IsValidClient(client) && isDateGreater(playerDate[client], today))
		GivePrice(client);
}

public void OnClientDisconnect(client)
{
	SetClientCookie(client, COOKIE_LastPriceDate, today);
}
   
public OnClientCookiesCached(client)
{
    GetClientCookie(client, COOKIE_LastPriceDate, playerDate[client], sizeof(playerDate[]));
}
	
stock void GivePrice(client)
{
	AchievementMessage(client, "");
	SetClientCookie(client, COOKIE_LastPriceDate, today);
	Format(playerDate[client], sizeof(playerDate[]), today);
}

stock void AchievementMessage(target, const char[] ach)
{
	if (target > 0 && target <= MaxClients)
	{
		if (IsClientConnected(target) && IsClientInGame(target))
		{
			if (IsPlayerAlive(target))
			{
				if (TF2_GetPlayerClass(target) != TF2_GetClass("spy"))
				{
					AchievementEffect(target);
					float pos[3] ;
					GetClientAbsOrigin(target, pos);
					EmitAmbientSound(ACHIEVEMENT_SOUND, pos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
				}
			}
			char prize[45];
			GetArrayString(ARRAY_Prizes, GetRandomInt(0, GetArraySize(ARRAY_Prizes)-1), prize, sizeof(prize));
			PrintToChatAll("%N got a prize ! \"%s\"", target, prize);
		}
	}
}


stock bool isDateGreater(const char[] date1, const char[] date2)
{
	char today_ex[3][5], dateExp_exp[3][5];
	ExplodeString(date1, ".", today_ex, sizeof today_ex, sizeof today_ex[]);
	ExplodeString(date2, ".", dateExp_exp, sizeof dateExp_exp, sizeof dateExp_exp[]);

	if(StringToInt(dateExp_exp[2]) > StringToInt(today_ex[2]))
        return true;
	else if(StringToInt(dateExp_exp[1]) > StringToInt(today_ex[1]))
        return true;
	else if(StringToInt(dateExp_exp[0]) > StringToInt(today_ex[0]))
        return true;
	return false;
}

stock void AchievementEffect(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				if (TF2_GetPlayerClass(client) == TF2_GetClass("spy"))
				{
					//Do a more advanced check to see if the spy is cloaked or disguised.
					return;
				}
				CreateTimer(0.01, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.5, Timer_Trophy, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(2.0, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(10.0, Timer_Delete, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return;
}

public Action Timer_Particles(Handle timer, any client)
{
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		AttachParticle(client, "mini_fireworks");
	}
	return Plugin_Handled;
}

public Action Timer_Trophy(Handle timer, any client)
{
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		AttachParticle(client, "achieved");
	}
	return Plugin_Handled;
}

public Action Timer_Delete(Handle timer, any client)
{
	DeleteParticle(g_ent[client]);
	g_ent[client] = 0;
	g_target[client] = 0;
}

stock void AttachParticle(ent, char[] particle_type)
{
	int particle = CreateEntityByName("info_particle_system");
	char name[128];
	
	if (IsValidEdict(particle))
	{
		float pos[3] ;
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(name, sizeof(name), "target%i", ent);
		
		DispatchKeyValue(ent, "targetname", name);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", name);
		DispatchKeyValue(particle, "effect_name", particle_type);
		DispatchSpawn(particle);
		
		SetVariantString(name);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		g_ent[ent] = particle;
		g_target[ent] = 1;
		
	}
	
}

stock void DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        char classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
		
        if (!strcmp(classname, "info_particle_system"))
        {
            RemoveEdict(particle);
        }
    }
}
   
stock bool ReadConfigFile()
{
	char path[100];
	Handle kv = CreateKeyValues("DailyPrizzesConfig");
	BuildPath(Path_SM, path, sizeof(path), "/configs/TF2_DailyPrizzes.cfg");
	FileToKeyValues(kv, path);
	
	if (!KvGotoFirstSubKey(kv))
	    return;
	
	char PrizeName[45];
	do
	{
	    KvGetString(kv, "PrizeName", PrizeName, sizeof(PrizeName));	    
	    PushArrayString(ARRAY_Prizes, PrizeName);
	}while(KvGotoNextKey(kv));
	
	CloseHandle(kv);  
}

stock bool IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
