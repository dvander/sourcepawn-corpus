/* base grab code taken from http://forums.alliedmods.net/showthread.php?t=157075

	// Ability
	"abilityX"
	{
		"name" "grab_abilities"

		// slot is ignored.
		"arg1"    "6"              // how many times he can pull people (universal pull only)
		"arg2"    "8"              // how many times he can push people (almighty push only)
		"arg3"    "attack3"        // universal pull activation button
		"arg4"    "reload"         // almighty push activation button
		"arg5"      "25.0"         // Damage from almighty push
		"arg6"		"150.0"		   // Grab distance (lower the value, closer you're pulled in)
		"plugin_name"    "ff2_grab"
	}
	// Sounds
	"sound_pain_throw"
	{
		"1"    "path/to/sound.mp3"
	}
	
	"sound_pain_grab"
	{
		"1"    "path/to/sound.mp3"
	}   
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2>

#pragma newdecls required

#define THROW_FORCE 1000.0
#define GRAB_DISTANCE 150.0
#define PLUGIN_NAME     "Freak Fortress 2: Almighty Push / Universal Pull"
#define PLUGIN_AUTHOR   "SHADOW93 | Waka Flocka Flame (base code by Friagram)"
#define PLUGIN_VERSION  "1.1"
#define PAIN "grab_abilities"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
};

bool PainCanUse[MAXPLAYERS+1]=false;
int Pushes[MAXPLAYERS+1]=0;
int Pulls[MAXPLAYERS+1]=0;
int PushButton[MAXPLAYERS+1]=0;
int PullButton[MAXPLAYERS+1]=0;
bool Hooked[MAXPLAYERS+1]=false;
int g_grabbed[MAXPLAYERS+1];          // track client's grabbed player
float gDistance[MAXPLAYERS+1];              // track distance of grabbed player

public void OnPluginStart2()
{
	ClearValues();
	for(int client=1; client<=MaxClients; client++)
	{
		g_grabbed[client] = INVALID_ENT_REFERENCE;
	}
	if(FF2_GetRoundState()==1)
	{
		HookAbilities();
	}
	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("teamplay_round_active", OnRoundStart);
	HookEvent("arena_win_panel", OnRoundEnd);
	HookEvent("teamplay_round_win", OnRoundEnd);
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearValues();
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	HookAbilities();
}

void HookAbilities()
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client))
		continue;
		int boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{        
			PainCanUse[client]=FF2_HasAbility(boss, this_plugin_name, PAIN);
			if(PainCanUse[client])
			{
				HookEvent("player_death", OnPlayerSpawn);
				HookEvent("player_spawn", OnPlayerSpawn);
				HookEvent("player_team", OnPlayerSpawn);
			}
		}
	}
}

public void FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!IsValidClient(client))
	{
		Debug("Invalid client index %i", client);
		return;
	}
	if(StrEqual(ability_name, PAIN, false))
	{
		Pulls[client]=FF2_GetAbilityArgument(boss, this_plugin_name, PAIN, 1);
		Pushes[client]=FF2_GetAbilityArgument(boss, this_plugin_name, PAIN, 2);

		char buttonType[64], buttonType2[64];
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, PAIN, 3, buttonType, sizeof(buttonType));
		PullButton[client]=GetButtonType(buttonType);
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, PAIN, 4, buttonType2, sizeof(buttonType2));
		PushButton[client]=GetButtonType(buttonType2);
		
		GetButtonName(buttonType, sizeof(buttonType));
		GetButtonName(buttonType2, sizeof(buttonType2));
		PrintHintText(client, "Universal Pulls: %i | Button: %s\nAlmighty Pushes: %i | Button: %s", Pulls[client], buttonType, Pushes[client], buttonType2);
		//PrintTF2MessFormatted(client, "Universal Pulls: %i | Button: %s\nAlmighty Pushes: %i | Button: %s", Pulls[client], buttonType, Pushes[client], buttonType2);
		if(!Hooked[client])
		{
			Hooked[client]=true;
			SDKHook(client, SDKHook_PreThink, OnPreThink);
		}    
	}
}


stock void GetButtonName(char[] buttonName, int size)
{
	if(StrEqual(buttonName, "reload", false))
	Format(buttonName, size, "RELOAD");
	else if(StrEqual(buttonName, "attack1", false) || StrEqual(buttonName, "mouse1", false) || StrEqual(buttonName, "primary fire", false))
	Format(buttonName, size, "PRIMARY FIRE");
	else if(StrEqual(buttonName, "attack2", false) || StrEqual(buttonName, "mouse2", false) || StrEqual(buttonName, "alt-fire", false) || StrEqual(buttonName, "alt fire", false) || StrEqual(buttonName, "secondary fire", false))
	Format(buttonName, size, "SECONDARY FIRE");
	else if(StrEqual(buttonName, "attack3", false) || StrEqual(buttonName, "mouse3", false) || StrEqual(buttonName, "special", false))
	Format(buttonName, size, "SPECIAL");
}

stock int GetButtonType(const char[] buttonName)
{
	if(StrEqual(buttonName, "reload", false))
	return IN_RELOAD;
	else if(StrEqual(buttonName, "attack1", false) || StrEqual(buttonName, "mouse1", false) || StrEqual(buttonName, "primary fire", false))
	return IN_ATTACK;
	else if(StrEqual(buttonName, "attack2", false) || StrEqual(buttonName, "mouse2", false) || StrEqual(buttonName, "alt-fire", false) || StrEqual(buttonName, "alt fire", false) || StrEqual(buttonName, "secondary fire", false))
	return IN_ATTACK2;
	else if(StrEqual(buttonName, "attack3", false) || StrEqual(buttonName, "mouse3", false) || StrEqual(buttonName, "special", false))
	return IN_ATTACK3;
	return IN_USE;
}

public void OnClientPutInServer(int client)
{
	g_grabbed[client] = 0;
}

void GrabObject(int client)
{
	int grabbed = TraceToObject(client);        // -1 for no collision, 0 for world
	if (grabbed > 0)
	{
		if(grabbed > MaxClients)
		{
			char classname[32];
			GetEntityClassname(grabbed, classname, sizeof(classname));
			if(StrEqual(classname, "prop_physics"))
			{
				int grabber = GetEntPropEnt(grabbed, Prop_Data, "m_hPhysicsAttacker");
				if(grabber > 0 && grabber <= MaxClients && IsClientInGame(grabber))
				{
					return;                                                            // another client is grabbing this object
				}
				SetEntPropEnt(grabbed, Prop_Data, "m_hPhysicsAttacker", client);
				AcceptEntityInput(grabbed, "EnableMotion");
			}
			
			SetEntityMoveType(grabbed, MOVETYPE_VPHYSICS);
		}
		else
		{
			SetEntityMoveType(grabbed, MOVETYPE_WALK);
		}
		float VecPos_grabbed[3], VecPos_client[3];
		GetEntPropVector(grabbed, Prop_Send, "m_vecOrigin", VecPos_grabbed);
		GetClientEyePosition(client, VecPos_client);
		gDistance[client] = FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(client), this_plugin_name, PAIN, 6, GetVectorDistance(VecPos_grabbed, VecPos_client));				// Use prefab distance
		TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		g_grabbed[client] = EntIndexToEntRef(grabbed);
	}
}

void ThrowObject(int client, int grabbed, bool canthrow)
{
	if(canthrow)
	{
		float vecView[3], vecFwd[3], vecPos[3], vecVel[3];
		GetClientEyeAngles(client, vecView);
		GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0]+=vecFwd[0]*THROW_FORCE;
		vecPos[1]+=vecFwd[1]*THROW_FORCE;
		vecPos[2]+=vecFwd[2]*THROW_FORCE;
		GetEntPropVector(grabbed, Prop_Send, "m_vecOrigin", vecFwd);
		SubtractVectors(vecPos, vecFwd, vecVel);
		ScaleVector(vecVel, 10.0);
		TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, vecVel);
	}
	g_grabbed[client] = INVALID_ENT_REFERENCE;
	if(grabbed > MaxClients)
	{
		char classname[32];
		GetEntityClassname(grabbed, classname, sizeof(classname));
		if(StrEqual(classname, "prop_physics"))
		{
			SetEntPropEnt(grabbed, Prop_Data, "m_hPhysicsAttacker", 0);
		}
	}
}

public void OnPreThink(int client)
{   
	static bool release1[MAXPLAYERS+1]=false;
	static bool release2[MAXPLAYERS+1]=false;    
	int boss=FF2_GetBossIndex(client);
	if(!Pushes[client] && !Pulls[client] || boss==-1 || !IsPlayerAlive(client) || !IsValidClient(client) || FF2_GetRoundState()!=1)
	{
		Hooked[client]=false;
		release1[client]=false;
		release2[client]=false;
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	}

	if(Pushes[client])
	{
		if(GetClientButtons(client) & PushButton[client])
		{
			if(release1[client])
			{
				release1[client]=false;
				
				if(EntRefToEntIndex(g_grabbed[client])==INVALID_ENT_REFERENCE)
				{
					GrabObject(client);
				}
				int grabbed=EntRefToEntIndex(g_grabbed[client]);
				if(grabbed && (IsValidEntity(grabbed) || IsValidClient(grabbed) && IsPlayerAlive(grabbed)))
				{
					float vecView[3], vecFwd[3], vecPos[3], vecVel[3];
					GetClientEyeAngles(client, vecView);
					GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
					GetClientEyePosition(client, vecPos);
					vecPos[0]+=vecFwd[0]*gDistance[client];
					vecPos[1]+=vecFwd[1]*gDistance[client];
					vecPos[2]+=vecFwd[2]*gDistance[client];
					GetEntPropVector(grabbed, Prop_Send, "m_vecOrigin", vecFwd);
					SubtractVectors(vecPos, vecFwd, vecVel);
					ScaleVector(vecVel, 10.0);
					TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, vecVel);
					
					ThrowObject(client, grabbed, true);
					Pushes[client]--;
					PrintHintText(client, "Pushes remaining: %i", Pushes[client]);
					//PrintTF2MessFormatted(client, "Pushes remaining: %i", Pushes[client]);
					char sound[PLATFORM_MAX_PATH];
					if(FF2_RandomSound("sound_pain_throw", sound, sizeof(sound), boss))
					{
						EmitSoundToAll(sound);
					}
					
					if(IsValidClient(grabbed) && IsPlayerAlive(grabbed))
					{
						SDKHooks_TakeDamage(grabbed, client, client, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, PAIN, 5), DMG_GENERIC, -1);
					}
					g_grabbed[client] = INVALID_ENT_REFERENCE;
				}
			}
		}
		else
		{
			if(!release1[client])
			{
				release1[client]=true;
			}
		}
	}

	if(Pulls[client])
	{
		if(GetClientButtons(client) & PullButton[client])
		{
			if(release2[client])
			{
				GrabObject(client);
				char sound[PLATFORM_MAX_PATH];
				if(EntRefToEntIndex(g_grabbed[client])!=INVALID_ENT_REFERENCE && IsValidEntity(EntRefToEntIndex(g_grabbed[client])))
				{
					if(FF2_RandomSound("sound_pain_grab", sound, sizeof(sound), boss))
					{
						EmitSoundToAll(sound);
					}
				}
				release2[client]=false;
			}
			
			if(!release2[client])
			{
				int grabbed=EntRefToEntIndex(g_grabbed[client]);
				if(grabbed && (IsValidEntity(grabbed) || IsValidClient(grabbed) && IsPlayerAlive(grabbed)))
				{
					float vecView[3], vecFwd[3], vecPos[3], vecVel[3];
					GetClientEyeAngles(client, vecView);
					GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
					GetClientEyePosition(client, vecPos);
					vecPos[0]+=vecFwd[0]*gDistance[client];
					vecPos[1]+=vecFwd[1]*gDistance[client];
					vecPos[2]+=vecFwd[2]*gDistance[client];
					GetEntPropVector(grabbed, Prop_Send, "m_vecOrigin", vecFwd);
					SubtractVectors(vecPos, vecFwd, vecVel);
					ScaleVector(vecVel, 10.0);
					TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, vecVel);
				}
			}
		}
		else
		{
			if(!release2[client])
			{
				int grabbed=EntRefToEntIndex(g_grabbed[client]);
				if (grabbed && (IsValidEntity(grabbed) || IsValidClient(grabbed) && IsPlayerAlive(grabbed)))
				{
					ThrowObject(client, grabbed, false);
					Pulls[client]--;
					//PrintTF2MessFormatted(client, "Pulls remaining: %i", Pulls[client]);
					PrintHintText(client, "Pulls remaining: %i", Pulls[client]);
				}
				release2[client]=true;
			}
		}
	}

}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client))
	ClearGrab(client);
}

void ClearGrab(int client)
{
	int grabbed = EntRefToEntIndex(g_grabbed[client]);
	if(grabbed != INVALID_ENT_REFERENCE && grabbed > MaxClients)
	{
		char classname[32];
		GetEntityClassname(grabbed, classname, sizeof(classname));
		if(StrEqual(classname, "prop_physics"))
		{
			SetEntPropEnt(grabbed, Prop_Data, "m_hPhysicsAttacker", 0);
		}
	}
	g_grabbed[client] = INVALID_ENT_REFERENCE;                // Clear their grabs
	for(int i=1; i<=MaxClients; i++)
	{
		if(EntRefToEntIndex(g_grabbed[i]) == client)
		{
			g_grabbed[i] = INVALID_ENT_REFERENCE;                // Clear grabs on them
		}
	}
}

void ClearValues()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
		continue;
		Pushes[client]=Pulls[client]=PushButton[client]=PullButton[client]=0;
		Hooked[client]=false;
		ClearGrab(client);
	}
}

public int TraceToObject(int client)
{
	float vecClientEyePos[3], vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayGrab, client);
	return TR_GetEntityIndex(null);
}

public bool TraceRayGrab(int entityhit, int mask, any self)
{
	if(entityhit > 0 && entityhit <= MaxClients)
	{
		if(IsPlayerAlive(entityhit) && entityhit != self)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{        
		char classname[32];
		if(GetEntityClassname(entityhit, classname, sizeof(classname)) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "tf_ammo_pack") || !StrContains(classname, "tf_projectil")))
		{
			return true;
		}
	}
	return false;
}

stock bool IsValidClient(int client)
{
	if(client<=0 || client>MaxClients) return false;
	return IsClientInGame(client);
}

/*
//Commented, to enable TF2 Style messages, uncomment all the code!
void PrintTF2MessFormatted(int client, const char[] message, any  ...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);
	//CreateTFStypeMessage(client, buffer);
}
*/

/*
// Modified tf2 style message for this plugin!
stock bool CreateTFStypeMessage(int client, const char[] message, const char[] icon="leaderboard_streak", int color=0)
{
	if(client<=0 || client>MaxClients || !IsClientInGame(client))
	{
		return false;
	}
	Handle bf = StartMessageOne("HudNotifyCustom", client);
	if(bf==INVALID_HANDLE)
	{
		return false;
	}
	BfWriteString(bf, message);
	BfWriteString(bf, icon);
	BfWriteByte(bf, color);
	EndMessage();
	return true;
}
*/
