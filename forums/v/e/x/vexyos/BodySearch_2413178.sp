#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))

#define WHITE 0x01
#define LIGHTGREEN 0x05
#define GREEN 0x06

bool 	g_bHoldingProp[MAXPLAYERS + 1] =  { false, ... };
bool 	g_bAlreadySearch[MAXPLAYERS + 1] = {false, ...};
bool 	blockSpawn = false;

char 	g_cLastSearchModel[MAXPLAYERS + 1];

Handle	g_hTimeSearch[MAXPLAYERS + 1] =  { null, ... };
Handle 	g_hGiveLoot[MAXPLAYERS + 1] =  { null, ... };

Handle	sm_bodysearch_flag = INVALID_HANDLE;
Handle	sm_bodysearch_team = INVALID_HANDLE;

new 	g_iSearchLoot[MAXPLAYERS + 1];
new 	g_iCollisionGroup = -1;
new 	Handle:g_hRagdollArray = null;

public Plugin myinfo = 
{
	name = "Dead Body Search",
	author = "Vexyos",
	description = "Make interactions with dead bodys",
	version = "0.2.0",
	url = "http://www.oftenplay.fr"
};

stock bool IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

enum Ragdolls
{
	ent,
	victim,
	attacker,
	String:victimName[MAX_NAME_LENGTH],
	String:attackerName[MAX_NAME_LENGTH],
	bool:scanned,
	Float:gameTime,
	String:weaponused[32],
	bool:found
}

public void OnPluginStart()
{
	sm_bodysearch_flag = CreateConVar("sm_bodysearch_flag", "", "Restricted flag if needed for search dead bodys (Ex: 'a')(Def: '')");
	sm_bodysearch_team = CreateConVar("sm_bodysearch_team", "5", "Team who create interactive dead bodys (2=Terrorists,3=Counter-Terrorists,5=Both)(Def: '5')");
	
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("round_prestart", Event_RoundStartPre, EventHookMode_Pre);
	
	HookEvent("player_changename", Event_ChangeName);
	
	g_iCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	g_hRagdollArray = CreateArray(102);
}

public Action Event_RoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
	ClearArray(g_hRagdollArray);
	
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
	
	int TeamRestricted = GetConVarInt(sm_bodysearch_team);
	if(TeamRestricted != 2 || TeamRestricted != 3 || TeamRestricted != 5)
		return Plugin_Continue;
	
	if(GetClientTeam(client) == TeamRestricted || TeamRestricted == 5){
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
		int dPlayer[Ragdolls];
		dPlayer[ent] = EntIndexToEntRef(iEntity);
		dPlayer[victim] = client;
		Format(dPlayer[victimName], MAX_NAME_LENGTH, name);
		dPlayer[scanned] = false;
		GetClientName(iAttacker, name, sizeof(name));
		dPlayer[attacker] = iAttacker;
		Format(dPlayer[attackerName], MAX_NAME_LENGTH, name);
		dPlayer[gameTime] = GetGameTime();
		event.GetString("weapon", dPlayer[weaponused], sizeof(dPlayer[weaponused]));
		
		PushArrayArray(g_hRagdollArray, dPlayer[0]);
		
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

 	int iSize = GetArraySize(g_hRagdollArray);

	if(iSize == 0)
		return;

	int dPlayer[Ragdolls];

	for(int i = 0;i < GetArraySize(g_hRagdollArray);i++)
	{
		GetArrayArray(g_hRagdollArray, i, dPlayer[0]);

		if(client == dPlayer[attacker])
		{
			Format(dPlayer[attackerName], MAX_NAME_LENGTH, userName);
			SetArrayArray(g_hRagdollArray, i, dPlayer[0]);
		}
		else if(client == dPlayer[victim])
		{
			Format(dPlayer[victimName], MAX_NAME_LENGTH, userName);
			SetArrayArray(g_hRagdollArray, i, dPlayer[0]);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK && g_bAlreadySearch[client])
		buttons &= ~IN_ATTACK; 
	
	decl String:FlagsRestricted[32];
	GetConVarString(sm_bodysearch_flag, FlagsRestricted, sizeof(FlagsRestricted));
	
	if(buttons & IN_USE)
	{
		if(!StrEqual(FlagsRestricted, "", false))
		{
			new SearchFlag = ReadFlagString(FlagsRestricted);
				
			if (!(GetUserFlagBits(client) & SearchFlag) && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
				return Plugin_Continue;
		}
		
		g_bHoldingProp[client] = true;
		
		int entidad = GetClientAimTarget(client, false);
		if(entidad > 0)
		{			
			float OriginG[3], TargetOriginG[3];
			GetClientEyePosition(client, TargetOriginG);
			GetEntPropVector(entidad, Prop_Data, "m_vecOrigin", OriginG);
			if(GetVectorDistance(TargetOriginG,OriginG, false) > 90.0)
				return Plugin_Continue;
			
		 	int iSize = GetArraySize(g_hRagdollArray);
			if(iSize == 0)
				return Plugin_Continue;
			
			int dPlayer[Ragdolls];
			int entity;

			for(int i = 0;i < iSize;i++)
			{
				GetArrayArray(g_hRagdollArray, i, dPlayer[0]);
				entity = EntRefToEntIndex(dPlayer[ent]);

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
							
							if(!dPlayer[found] && IsPlayerAlive(client))
							{
								dPlayer[found] = true;
								
								PrintToChat(client, "[%cSearch%c] Ragdoll searching ...", LIGHTGREEN, WHITE);
								
								GetClientModel(dPlayer[victim], g_cLastSearchModel[client], 128);
								
								g_hGiveLoot[client] = CreateTimer(3.0, Timer_GiveLoot, client);
							}else{
							PrintToChat(client, "[%cSearch%c] This body was already stripped and clothes are full of blood .", LIGHTGREEN, WHITE);
							}
						}
						
						SetArrayArray(g_hRagdollArray, i, dPlayer[0]);
						
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