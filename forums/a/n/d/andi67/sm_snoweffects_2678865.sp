// Original Creator "Blueraja"
// www.blueraja.com/blog
// Some Improvements by e54385991


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define PLUGIN_VERSION "1.3"

#define SNOW_MODEL		"particle/snow.vmt"
#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

int g_SnowFlake[MAXPLAYERS+1] = {-1,...};
int g_SnowFlake2[MAXPLAYERS+1] = {-1,...};
int g_SnowFlake3[MAXPLAYERS+1] = {-1,...};
int g_SnowDust[MAXPLAYERS+1] = {-1,...};

ConVar g_SnowDustEnabled;
ConVar g_SnowEnabled;
ConVar g_ConVar_prevent_edict_crash;
ConVar g_EnableSnoweffectsMessage;

char Game[64];

Handle cvDefaultPref = INVALID_HANDLE;
bool enabledForClient[MAXPLAYERS + 1];
Handle cookie = INVALID_HANDLE;
bool cookiesEnabled = false;


public Plugin myinfo = 
{
	name = "SM SNOWEFFECTS",
	author = "Andi67,Blueraja,e54385991",
	description = "Let it snow!!",
	version = "1.3",
	url = "http://www.andi67-blog.de.vu , www.blueraja.com/blog"
	
}

public OnPluginStart()
{
	CreateConVar("sm_snoweffects", PLUGIN_VERSION, " SM SNOWEFFECTS Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_SnowEnabled	= CreateConVar("sm_snoweffects_enabled", "1", "Enables the plugin", _, true, 0.0, true, 1.0);
	g_SnowDustEnabled	= CreateConVar("sm_snowdust_enabled", "1", "Enables the SnowDust", _, true, 0.0, true, 1.0);
	g_EnableSnoweffectsMessage	= CreateConVar("sm_snoweffects_message_enabled", "1", "Prints a Message about Snoweffects", _, true, 0.0, true, 1.0);	
	g_ConVar_prevent_edict_crash = CreateConVar("sm_snoweffects_prevent_edict_crash", "1200", "how many edicts allow display (prevent crash) 0 = disable", _, true, 0.0, true, 2048.0);
	cvDefaultPref = CreateConVar("sm_snoweffects_defaultpref",	"1","Default client preference (0 - snoweffects off, 1 - snoweffects on)", _, true, 0.0, true, 1.0);	

	HookEvent("player_spawn", Event_PlayerSpawn);	
	HookEvent("player_death", Event_PlayerDeath);

	cookiesEnabled = (GetExtensionFileStatus("clientprefs.ext") == 1);

	if (cookiesEnabled) 
	{
		cookie = RegClientCookie("Snoweffects", "Enable (\"on\") / Disable (\"off\") Display of Snoweffects", CookieAccess_Private);	
		
		for (new client = MaxClients; client > 0; --client)
		{
			if (!AreClientCookiesCached(client))
			{
				continue;
			}
			ClientIngameAndCookiesCached(client);
		}
	}
	RegConsoleCmd("sm_snoweffects", Command_Snow, "On/Off Snoweffects");	
}

public void OnMapStart()
{
	PrecacheModel(SNOW_MODEL);
}

public OnClientCookiesCached(client)
{
	if (IsClientInGame(client)) 
	{
		ClientIngameAndCookiesCached(client);
	}
}

public OnClientPutInServer(client)
{
	if (cookiesEnabled && AreClientCookiesCached(client)) 
	{
		ClientIngameAndCookiesCached(client);
	}
}

public OnClientConnected(client)
{
	enabledForClient[client] = true;
}

public Action Event_PlayerSpawn(Handle event, const char[]name, bool dontBroadcast)
{
	if (GetConVarInt(g_SnowEnabled) == 1)	
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (!IsFakeClient(client) && IsValidClient(client))
		{
			char preference[8];
			GetClientCookie(client, cookie, preference, sizeof(preference));

			if (StrEqual(preference, "")) 
			{
				enabledForClient[client] = GetConVarBool(cvDefaultPref);
			}
			else 
			{
				enabledForClient[client] = !StrEqual(preference, "off", false);
			}
			
			if (!enabledForClient[client]) 
			{
				return Plugin_Continue;
			}			
			KillSnow(client);	
			if(g_ConVar_prevent_edict_crash.IntValue != 0 && CurrentEntities() > g_ConVar_prevent_edict_crash.IntValue)
			{	
				return Plugin_Stop;
			}				
			else
			{
				CreateTimer(1.0, CreateSnowTimer,client,TIMER_FLAG_NO_MAPCHANGE);			
			}					
		}	
	}
	return Plugin_Continue;	
}

public Action Command_Snow(int client, int args)
{
	if (client == 0) 
	{
		ReplyToCommand(client, "[Snoweffects] This command can only be run by players.");
		return Plugin_Handled;
	}

	if (enabledForClient[client]) 
	{
		enabledForClient[client] = false;
		PrintToChat(client, "%c [Snoweffects] %c, disabled!",COLOR_DEFAULT,COLOR_GREEN);		

		if (cookiesEnabled) 
		{
			SetClientCookie(client, cookie, "off");
			KillSnow(client);
		}
	}
	else 
	{
		enabledForClient[client] = true;
		PrintToChat(client, "%c [Snoweffects] %c, enabled!",COLOR_DEFAULT,COLOR_GREEN);		

		if (cookiesEnabled) 
		{
			SetClientCookie(client, cookie, "on");
			CreateSnow(client);
		}
	}

	return Plugin_Handled;
}

public Action Event_PlayerDeath(Handle event, const char[]name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	KillSnow(client);
}

public Action CreateSnowTimer(Handle timer, int client)
{
	CreateSnow(client);
}

CreateSnow(client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		float vecOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecOrigin);
		
		g_SnowFlake[client] = CreateEntityByName("env_smokestack");
		if(g_SnowFlake[client] != -1)
		{
			DispatchKeyValueFloat(g_SnowFlake[client],"BaseSpread", 400.0);
			DispatchKeyValue(g_SnowFlake[client],"SpreadSpeed", "100");
			DispatchKeyValue(g_SnowFlake[client],"Speed", "25");
			DispatchKeyValueFloat(g_SnowFlake[client],"StartSize", 1.0);
			DispatchKeyValueFloat(g_SnowFlake[client],"EndSize", 1.0);
			DispatchKeyValue(g_SnowFlake[client],"Rate", "125");
			DispatchKeyValue(g_SnowFlake[client],"JetLength", "200");
			DispatchKeyValueFloat(g_SnowFlake[client],"Twist", 1.0);
			DispatchKeyValue(g_SnowFlake[client],"RenderColor", "255 255 255");
			DispatchKeyValue(g_SnowFlake[client],"RenderAmt", "200");
			DispatchKeyValue(g_SnowFlake[client],"RenderMode", "18");
			DispatchKeyValue(g_SnowFlake[client],"SmokeMaterial", SNOW_MODEL);
			DispatchKeyValue(g_SnowFlake[client],"Angles", "180 0 0");
			DispatchSpawn(g_SnowFlake[client]);
			ActivateEntity(g_SnowFlake[client]);
			vecOrigin[2] += 20;
			TeleportEntity(g_SnowFlake[client], vecOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(g_SnowFlake[client], "SetParent", client);
			AcceptEntityInput(g_SnowFlake[client], "TurnOn");		
			
			g_SnowFlake[client] = EntIndexToEntRef(g_SnowFlake[client]);
		}
		
		g_SnowFlake2[client] = CreateEntityByName("env_smokestack");
		if(g_SnowFlake2[client] != -1)
		{
			DispatchKeyValueFloat(g_SnowFlake2[client],"BaseSpread", 300.0);
			DispatchKeyValue(g_SnowFlake2[client],"SpreadSpeed", "200");
			DispatchKeyValue(g_SnowFlake2[client],"Speed", "50");
			DispatchKeyValueFloat(g_SnowFlake2[client],"StartSize", 1.0);
			DispatchKeyValueFloat(g_SnowFlake2[client],"EndSize", 1.0);
			DispatchKeyValue(g_SnowFlake2[client],"Rate", "200");
			DispatchKeyValue(g_SnowFlake2[client],"JetLength", "200");
			DispatchKeyValueFloat(g_SnowFlake2[client],"Twist", 1.0);
			DispatchKeyValue(g_SnowFlake2[client],"RenderColor", "255 255 255");
			DispatchKeyValue(g_SnowFlake2[client],"RenderAmt", "200");
			DispatchKeyValue(g_SnowFlake2[client],"RenderMode", "18");
			DispatchKeyValue(g_SnowFlake2[client],"SmokeMaterial", SNOW_MODEL);
			DispatchKeyValue(g_SnowFlake2[client],"Angles", "180 0 0");
			
			DispatchSpawn(g_SnowFlake2[client]);
			ActivateEntity(g_SnowFlake2[client]);
			vecOrigin[2] += 85;
			TeleportEntity(g_SnowFlake2[client], vecOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(g_SnowFlake2[client], "SetParent", client);
			AcceptEntityInput(g_SnowFlake2[client], "TurnOn");
			
			g_SnowFlake2[client] = EntIndexToEntRef(g_SnowFlake2[client]);
		}
		g_SnowFlake3[client] = CreateEntityByName("env_smokestack");
		if(g_SnowFlake3[client] != -1)
		{
			DispatchKeyValueFloat(g_SnowFlake3[client],"BaseSpread", 200.0);
			DispatchKeyValue(g_SnowFlake3[client],"SpreadSpeed", "300");
			DispatchKeyValue(g_SnowFlake3[client],"Speed", "75");
			DispatchKeyValueFloat(g_SnowFlake3[client],"StartSize", 1.0);
			DispatchKeyValueFloat(g_SnowFlake3[client],"EndSize", 1.0);
			DispatchKeyValue(g_SnowFlake3[client],"Rate", "250");
			DispatchKeyValue(g_SnowFlake3[client],"JetLength", "200");
			DispatchKeyValueFloat(g_SnowFlake3[client],"Twist", 1.0);
			DispatchKeyValue(g_SnowFlake3[client],"RenderColor", "255 255 255");
			DispatchKeyValue(g_SnowFlake3[client],"RenderAmt", "200");
			DispatchKeyValue(g_SnowFlake3[client],"RenderMode", "18");
			DispatchKeyValue(g_SnowFlake3[client],"SmokeMaterial", SNOW_MODEL);
			DispatchKeyValue(g_SnowFlake3[client],"Angles", "180 0 0");
			
			DispatchSpawn(g_SnowFlake3[client]);
			ActivateEntity(g_SnowFlake3[client]);
			vecOrigin[2] += 160;
			TeleportEntity(g_SnowFlake3[client], vecOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(g_SnowFlake3[client], "SetParent", client);
			AcceptEntityInput(g_SnowFlake3[client], "TurnOn");		
			
			g_SnowFlake3[client] = EntIndexToEntRef(g_SnowFlake3[client]);
		}
		if (GetConVarInt(g_SnowDustEnabled) == 1)	
		{
			float m_vecOrigin[3];	
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", m_vecOrigin);
			
			if(StrEqual(Game, "csgo"))
			{
				g_SnowDust[client] = CreateEntityByName("info_particle_system");
				if(g_SnowDust[client] != -1)
				{
					SetEntPropEnt(g_SnowDust[client], Prop_Data, "m_hOwnerEntity", client);
					DispatchKeyValue(g_SnowDust[client], "effect_name", "snow_drift_128");
					DispatchSpawn(g_SnowDust[client]);
		
					if(IsValidEntity(g_SnowDust[client]))
					{
						TeleportEntity(g_SnowDust[client], m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(g_SnowDust[client], "SetParent", client);
						AcceptEntityInput(g_SnowDust[client], "start");
						ActivateEntity(g_SnowDust[client]);			
					}
					g_SnowDust[client] = EntIndexToEntRef(g_SnowDust[client]);
				}
			}
			else
			{
				g_SnowDust[client] = CreateEntityByName("env_smokestack");
				if(g_SnowDust[client] != -1)
				{
					DispatchKeyValue(g_SnowDust[client],"BaseSpread", "100");
					DispatchKeyValue(g_SnowDust[client],"SpreadSpeed", "70");
					DispatchKeyValue(g_SnowDust[client],"Speed", "7");
					DispatchKeyValue(g_SnowDust[client],"StartSize", "200");
					DispatchKeyValue(g_SnowDust[client],"EndSize", "2");
					DispatchKeyValue(g_SnowDust[client],"Rate", "1");
					DispatchKeyValue(g_SnowDust[client],"WindAngle","-90 180 -90");
					DispatchKeyValue(g_SnowDust[client],"WindSpeed","15");			
					DispatchKeyValue(g_SnowDust[client],"JetLength", "300");
					DispatchKeyValue(g_SnowDust[client],"Twist", "20"); 
					DispatchKeyValue(g_SnowDust[client],"RenderColor", "255 255 255"); //red green blue
					DispatchKeyValue(g_SnowDust[client],"RenderAmt", "135");
					DispatchKeyValue(g_SnowDust[client],"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
					DispatchSpawn(g_SnowDust[client]);
			
					if(IsValidEntity(g_SnowDust[client]))
					{			
						vecOrigin[2] += 100;
						TeleportEntity(g_SnowDust[client], m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(g_SnowDust[client], "SetParent", client);
						AcceptEntityInput(g_SnowDust[client], "TurnOn");
					}
					g_SnowDust[client] = EntIndexToEntRef(g_SnowDust[client]);			
				}
			}				
		}
	}		
}

public void OnClientDisconnect(int client)
{
	KillSnow(client);
}

KillSnow(client)
{
	g_SnowDust[client] = EntRefToEntIndex(g_SnowDust[client]);
	if(g_SnowDust[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowDust[client]))
	{	
		AcceptEntityInput(g_SnowDust[client], "Kill");
	}		
	g_SnowDust[client] = INVALID_ENT_REFERENCE;	
	
	g_SnowFlake[client] = EntRefToEntIndex(g_SnowFlake[client]);
	if(g_SnowFlake[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowFlake[client]))
	{	
		AcceptEntityInput(g_SnowFlake[client], "Kill");
	}
	g_SnowFlake[client] = INVALID_ENT_REFERENCE;
	
	g_SnowFlake2[client] = EntRefToEntIndex(g_SnowFlake2[client]);
	if(g_SnowFlake2[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowFlake2[client]))
	{	
		AcceptEntityInput(g_SnowFlake2[client], "Kill");
	}
	g_SnowFlake2[client] = INVALID_ENT_REFERENCE;
	
	g_SnowFlake3[client] = EntRefToEntIndex(g_SnowFlake3[client]);
	if(g_SnowFlake3[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowFlake3[client]))
	{	
		AcceptEntityInput(g_SnowFlake3[client], "Kill");
	}	
	g_SnowFlake3[client] = INVALID_ENT_REFERENCE; 
}


public Action DeleteParticle(Handle timer, any client)
{
	g_SnowDust[client] = EntRefToEntIndex(g_SnowDust[client]);
	if(g_SnowDust[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowDust[client]))
	{
		AcceptEntityInput(g_SnowDust[client], "Kill");
		g_SnowDust[client] = INVALID_ENT_REFERENCE;
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

int CurrentEntities()
{
	int entitys = 0;
	for (int i=1;i<GetMaxEntities();i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i)) 
		{
			entitys++;
		}
	}
	return entitys;
}

ClientIngameAndCookiesCached(client)
{
	char preference[8];
	GetClientCookie(client, cookie, preference, sizeof(preference));

	if (StrEqual(preference, "")) 
	{
		enabledForClient[client] = GetConVarBool(cvDefaultPref);
	}
	else 
	{
		enabledForClient[client] = !StrEqual(preference, "off", false);
	}
}

public void OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_EnableSnoweffectsMessage) == 1)
	{
		if (IsValidClient(client) && !IsFakeClient(client))
		{		
			CreateTimer(20.0, CreateMessage,client,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action CreateMessage(Handle timer, any client)
{
	PrintHintText(client, "Use: !snoweffects for turning on/off snoweffects!");
}

public Action OnPlayerRunCmd(int client)
{
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	float eyeAng[3], eyePos[3], fwdVec[3];
	GetClientEyeAngles(client, eyeAng);
	GetClientEyePosition(client, eyePos);
	eyeAng[0] = -90.0;
	GetAngleVectors(eyeAng, fwdVec, NULL_VECTOR, NULL_VECTOR);
	GetVectorAngles(fwdVec, fwdVec);
	
	TR_TraceRayFilter(eyePos, fwdVec, MASK_SOLID, RayType_Infinite, TraceDontHitSelf, client);
	if (TR_DidHit())
	{
		char surface[256];
		TR_GetSurfaceName(null, surface, sizeof(surface));

		if (!StrEqual(surface,"TOOLS/TOOLSSKYBOX"))
		{
			if (IsValidEntity(g_SnowFlake[client]))
			{
				DispatchKeyValue(g_SnowFlake[client],"RenderColor", "0 0 0"); //red green blue
				DispatchKeyValue(g_SnowFlake[client],"RenderAmt", "0");
			}
			if (IsValidEntity(g_SnowFlake2[client]))
			{
				DispatchKeyValue(g_SnowFlake2[client],"RenderColor", "0 0 0"); //red green blue
				DispatchKeyValue(g_SnowFlake2[client],"RenderAmt", "0");
			}
			if (IsValidEntity(g_SnowFlake3[client]))
			{
				DispatchKeyValue(g_SnowFlake3[client],"RenderColor", "0 0 0"); //red green blue
				DispatchKeyValue(g_SnowFlake3[client],"RenderAmt", "0");
			}			
		}
		if (!StrEqual(surface,"TOOLS/TOOLSSKYBOX2D"))
		{
			if (IsValidEntity(g_SnowFlake[client]))
			{
				DispatchKeyValue(g_SnowFlake[client],"RenderColor", "0 0 0"); //red green blue
				DispatchKeyValue(g_SnowFlake[client],"RenderAmt", "0");
			}
			if (IsValidEntity(g_SnowFlake2[client]))
			{
				DispatchKeyValue(g_SnowFlake2[client],"RenderColor", "0 0 0"); //red green blue
				DispatchKeyValue(g_SnowFlake2[client],"RenderAmt", "0");
			}
			if (IsValidEntity(g_SnowFlake3[client]))
			{
				DispatchKeyValue(g_SnowFlake3[client],"RenderColor", "0 0 0"); //red green blue
				DispatchKeyValue(g_SnowFlake3[client],"RenderAmt", "0");
			}			
		}		
		if (StrEqual(surface,"TOOLS/TOOLSSKYBOX"))
		{
			if (IsValidEntity(g_SnowFlake[client]))
			{
				DispatchKeyValue(g_SnowFlake[client],"RenderColor", "255 255 255"); //red green blue
				DispatchKeyValue(g_SnowFlake[client],"RenderAmt", "135");				
			}
			if (IsValidEntity(g_SnowFlake2[client]))
			{
				DispatchKeyValue(g_SnowFlake2[client],"RenderColor", "255 255 255"); //red green blue
				DispatchKeyValue(g_SnowFlake2[client],"RenderAmt", "135");			
			}
			if (IsValidEntity(g_SnowFlake3[client]))
			{
				DispatchKeyValue(g_SnowFlake3[client],"RenderColor", "255 255 255"); //red green blue
				DispatchKeyValue(g_SnowFlake3[client],"RenderAmt", "135");			
			}			
		}
		if (StrEqual(surface,"TOOLS/TOOLSSKYBOX2D"))
		{
			if (IsValidEntity(g_SnowFlake[client]))
			{
				DispatchKeyValue(g_SnowFlake[client],"RenderColor", "255 255 255"); //red green blue
				DispatchKeyValue(g_SnowFlake[client],"RenderAmt", "135");				
			}
			if (IsValidEntity(g_SnowFlake2[client]))
			{
				DispatchKeyValue(g_SnowFlake2[client],"RenderColor", "255 255 255"); //red green blue
				DispatchKeyValue(g_SnowFlake2[client],"RenderAmt", "135");				
			}
			if (IsValidEntity(g_SnowFlake3[client]))
			{
				DispatchKeyValue(g_SnowFlake3[client],"RenderColor", "255 255 255"); //red green blue
				DispatchKeyValue(g_SnowFlake3[client],"RenderAmt", "135");			
			}				
		}				
	}
	return Plugin_Continue;
}

bool TraceDontHitSelf(int entity, any data)
{
    return entity == data;
}