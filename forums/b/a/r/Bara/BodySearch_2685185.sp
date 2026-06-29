#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))

#define WHITE 0x01
#define LIGHTGREEN 0x05
#define GREEN 0x06

bool       g_bHoldingProp[MAXPLAYERS + 1] =  { false, ... };
bool       g_bAlreadySearch[MAXPLAYERS + 1] = {false, ...};
bool       blockSpawn = false;

char       g_cLastSearchModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH+1];

Handle     g_hTimeSearch[MAXPLAYERS + 1] =  { null, ... };
Handle     g_hGiveLoot[MAXPLAYERS + 1] =  { null, ... };

int        g_iSearchLoot[MAXPLAYERS + 1] = { -1, ...};
int        g_iCollisionGroup = -1;
ArrayList  g_aRagdollArray = null;

public Plugin myinfo = 
{
	name = "Dead Body Search",
	author = "Vexyos",
	description = "Make interactions with dead bodys",
	version = "0.1.0",
	url = "http://www.oftenplay.fr"
};

stock bool IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

enum struct Ragdoll
{
	int ent;
	int victim;
	int attacker;
	char victimName[MAX_NAME_LENGTH];
	char attackerName[MAX_NAME_LENGTH];
	bool scanned;
	float gameTime;
	char weaponused[32];
	bool found;
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("round_prestart", Event_RoundStartPre, EventHookMode_Pre);
	
	HookEvent("player_changename", Event_ChangeName);
	
	g_iCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	g_aRagdollArray = new ArrayList(sizeof(Ragdoll));
}

public Action Event_RoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
	g_aRagdollArray.Clear();
	
	LoopValidClients(i)
	{
		g_bAlreadySearch[i] = false;
		g_iSearchLoot[i] = 0;
		g_hTimeSearch[i] = null;
		g_hGiveLoot[i] = null;
	}
}

public Action Event_PlayerDeathPre(Event event, const char[] menu, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	g_hTimeSearch[client] = null;
	g_hGiveLoot[client] = null;
	
	if(GetClientTeam(client) == 3){
		int iRagdoll = 0;
		iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if (iRagdoll > 0)
			AcceptEntityInput(iRagdoll, "Kill");
		
		char playermodel[128];
		GetClientModel(client, playermodel, 128);
		
		float origin[3], angles[3], velocity[3];
		
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
		
		int iEntity = CreateEntityByName("prop_ragdoll");
		DispatchKeyValue(iEntity, "model", playermodel);
		
		// Prevent crash. If spawn isn't dispatched successfully,
		// TeleportEntity() crashes the server. This left some very
		// odd crash dumps, and usually only happened when 2 players
		// died inside each other in the same tick.
		// Thanks to -
		// 		Phoenix Gaming Network (pgn.site)
		// 		Prestige Gaming Organization
		
		if(blockSpawn == false)
		{
			blockSpawn = true;
			
			ActivateEntity(iEntity);
			if(DispatchSpawn(iEntity))
			{
				float speed = GetVectorLength(velocity);
				if(speed >= 500)
					TeleportEntity(iEntity, origin, angles, NULL_VECTOR);
				else
					TeleportEntity(iEntity, origin, angles, velocity);
			}
			
			blockSpawn = false;
		}
		
		SetEntData(iEntity, g_iCollisionGroup, 2, 4, true);
		
		int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
		
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		Ragdoll body;
		body.ent = EntIndexToEntRef(iEntity);
		body.victim = client;
		Format(body.victimName, sizeof(Ragdoll::victimName), name);
		body.scanned = false;
		GetClientName(iAttacker, name, sizeof(name));
		body.attacker = iAttacker;
		Format(body.attackerName, sizeof(Ragdoll::attackerName), name);
		body.gameTime = GetGameTime();
		event.GetString("weapon", body.weaponused, sizeof(body.weaponused));
		
		g_aRagdollArray.PushArray(body);
		
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", iEntity);
	}
	
	return Plugin_Continue;
}

public Action Event_ChangeName(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsClientInGame(client)) return;

	char userName[MAX_NAME_LENGTH];
	event.GetString("newname", userName, sizeof(userName));

 	int iSize = GetArraySize(g_aRagdollArray);

	if(iSize == 0)
		return;

	Ragdoll body;

	for(int i = 0;i < GetArraySize(g_aRagdollArray);i++)
	{
		g_aRagdollArray.GetArray(i, body);

		if(client == body.attacker)
		{
			Format(body.attackerName, sizeof(Ragdoll::attackerName), userName);
			g_aRagdollArray.SetArray(i, body);
		}
		else if(client == body.victim)
		{
			Format(body.victimName, sizeof(Ragdoll::victimName), userName);
			g_aRagdollArray.SetArray(i, body);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK && g_bAlreadySearch[client])
		buttons &= ~IN_ATTACK; 
	
	if(buttons & IN_USE)
	{
		g_bHoldingProp[client] = true;
		
		int entidad = GetClientAimTarget(client, false);
		if(entidad > 0)
		{			
			float OriginG[3], TargetOriginG[3];
			GetClientEyePosition(client, TargetOriginG);
			GetEntPropVector(entidad, Prop_Data, "m_vecOrigin", OriginG);
			if(GetVectorDistance(TargetOriginG,OriginG, false) > 90.0)
				return Plugin_Continue;
			
		 	int iSize = GetArraySize(g_aRagdollArray);
			if(iSize == 0)
				return Plugin_Continue;
			
			Ragdoll body;
			int entity;

			for(int i = 0;i < iSize;i++)
			{
				g_aRagdollArray.GetArray(i, body);
				entity = EntRefToEntIndex(body.ent);

				if(entity == entidad)
				{
					if(GetClientTeam(client) == 2)
					{
						if(g_bAlreadySearch[client] == false)
						{
							g_hTimeSearch[client] = CreateTimer(3.0, Timer_SearchBlock, client);
							SetEntityRenderColor(client, 255, 0, 0, 255);
							SetEntityMoveType(client, MOVETYPE_NONE);
							g_bAlreadySearch[client] = true;
							
							if(!body.found && IsPlayerAlive(client))
							{
								body.found = true;
								
								PrintToChat(client, "[%cSearch%c] Ragdoll searching ...", LIGHTGREEN, WHITE);
								
								GetClientModel(body.victim, g_cLastSearchModel[client], sizeof(g_cLastSearchModel[]));
								
								g_hGiveLoot[client] = CreateTimer(3.0, Timer_GiveLoot, client);
							}else{
							PrintToChat(client, "[%cSearch%c] This body was already stripped and clothes are full of blood .", LIGHTGREEN, WHITE);
							}
						}
						
						g_aRagdollArray.SetArray(i, body);
						
						break;
					}
				}
			}
		}
	}
	else g_bHoldingProp[client] = false;

	return Plugin_Continue;
}

public Action Timer_SearchBlock(Handle timer, any client)
{
	g_bAlreadySearch[client] = false;
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntityMoveType(client, MOVETYPE_WALK);
	g_hTimeSearch[client] = null;
}

public Action Timer_GiveLoot(Handle timer, any client)
{
	g_iSearchLoot[client] = GetRandomInt(1, 10);
	
	if(g_iSearchLoot[client] == 10){	
		SetEntityModel(client, g_cLastSearchModel[client]);
		PrintToChat(client, "[%cSearch%c] You stole the clothes of the dead body, you look like him now!", LIGHTGREEN, WHITE);
	}
	else if(g_iSearchLoot[client] == 9 || g_iSearchLoot[client] == 8){
		GivePlayerItem(client, "weapon_p250");
		PrintToChat(client, "[%cSearch%c] You found a gun in the cases on the belt of the dead body.", LIGHTGREEN, WHITE);
	}
	else if(g_iSearchLoot[client] == 7 || g_iSearchLoot[client] == 6 || g_iSearchLoot[client] == 5){
		GivePlayerItem(client, "weapon_hegrenade");
		PrintToChat(client, "[%cSearch%c] You found a grenade in the pocket of the dead body.", LIGHTGREEN, WHITE);
	}
	else {
		PrintToChat(client, "[%cSearch%c] Nothing is usable on this body, try an another one.", LIGHTGREEN, WHITE);
	}
	g_iSearchLoot[client] = 0;
								
	g_hGiveLoot[client] = null;
}