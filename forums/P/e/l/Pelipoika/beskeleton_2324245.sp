#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>

#pragma newdecls required;

#define MODEL_SKELETON	"models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl"
#define PLUGIN_VERSION	"1.2"

bool g_bSpecial[MAXPLAYERS + 1];
bool g_bSkeleton[MAXPLAYERS + 1];
TFTeam g_iOldTeam[MAXPLAYERS + 1];

Handle g_hCvarStompDamage;

public Plugin myinfo =
{
	name = "[TF2] Be The Skeleton King!",
	author = "Pelipoika",
	description = "Spooky scary skeleton",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	AddTempEntHook("TFBlood", TempHook);

	RegAdminCmd("sm_beskeleton", Command_Skeleton, ADMFLAG_ROOT);
	
	HookEvent("post_inventory_application", Event_SkeletonDeath);
	HookEvent("player_death", Event_SkeletonDeath, EventHookMode_Pre);
	
	CreateConVar("tf2_beskeleton_version", PLUGIN_VERSION, "Be the Skeleton King version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_hCvarStompDamage = CreateConVar("tf2_beskeleton_stompdamage", "120", "Movement speed penalty when carrying a bomb", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			g_bSkeleton[client] = false;
			g_bSpecial[client] = false;
			g_iOldTeam[client] = TF2_GetClientTeam(client);
		
			SDKHook(client, SDKHook_OnTakeDamageAlive, TakeDamage);
		}
	}
	
	AddNormalSoundHook(SkeletonSH);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("BeSkeletonKing_MakeSkeleton", Native_SetSkeleton);
	CreateNative("BeSkeletonKing_IsSkeleton", Native_IsSkeleton);
	RegPluginLibrary("beskeleton");
	
	return APLRes_Success;
}

public Action TempHook(const char[] te_name, const Players[], int numClients, float delay)
{
	int client = TE_ReadNum("entindex");
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && g_bSkeleton[client])
	{
		float m_vecOrigin[3];
		m_vecOrigin[0] = TE_ReadFloat("m_vecOrigin[0]");
		m_vecOrigin[1] = TE_ReadFloat("m_vecOrigin[1]");
		m_vecOrigin[2] = TE_ReadFloat("m_vecOrigin[2]");
		
		if(GetEntProp(client, Prop_Send, "m_iTeamNum") == 0)
		{
			CreateParticle("spell_skeleton_goop_green", m_vecOrigin);
		}
		else
		{
			switch(TF2_GetClientTeam(client))
			{
				case TFTeam_Red:		CreateParticle("spell_pumpkin_mirv_goop_red", m_vecOrigin);
				case TFTeam_Blue:		CreateParticle("spell_pumpkin_mirv_goop_blue", m_vecOrigin);
			}
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	PrecacheModel(MODEL_SKELETON);
	
	PrecacheSound("misc/halloween/skeleton_break.wav");
}

public void OnClientPutInServer(int client)
{
	g_bSkeleton[client] = false;
	g_bSpecial[client] = false;
	g_iOldTeam[client] = TFTeam_Spectator;

	SDKHook(client, SDKHook_OnTakeDamageAlive, TakeDamage);
}

public Action Command_Skeleton(int client, int args)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		char arg1[32], arg2[6];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		if(args < 1)
		{
			MakeSkeleton(client);
		}
		else
		{
			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS];
			int	target_count;
			bool tn_is_ml;
			if ((target_count = ProcessTargetString(
					arg1,
					client, 
					target_list, 
					MAXPLAYERS, 
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
		
			for (int i = 0; i < target_count; i++)
			{
				int player = target_list[i];
				
				if(player > 0 && player <= MaxClients && IsClientInGame(player) && IsPlayerAlive(player))
				{
					if(StringToInt(arg2) == 1)
						MakeSkeleton(player, true);
					else
						MakeSkeleton(player);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action GetMaxHealth(int client, int &MaxHealth)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		MaxHealth = 1000;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action SetModel(int client, const char[] model)
{
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);		
}

stock void MakeSkeleton(int client, bool spectator = false)
{
	if(spectator)
	{
		g_iOldTeam[client] = TF2_GetClientTeam(client);
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 2);
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", 0);
	}
	
	SetVariantString("2.0");
	AcceptEntityInput(client, "SetModelScale");
	
	SetModel(client, MODEL_SKELETON);
	TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
	TF2_RemoveAllWearables(client);
	TF2_RemoveAllWeapons(client);
	
	Handle hWeaponFists = TF2Items_CreateItem(OVERRIDE_ALL);
	TF2Items_SetClassname(hWeaponFists, "tf_weapon_club");
	TF2Items_SetItemIndex(hWeaponFists, 3);
	TF2Items_SetQuality(hWeaponFists, 6);
	TF2Items_SetAttribute(hWeaponFists, 0, 15, 0.0);
	TF2Items_SetAttribute(hWeaponFists, 1, 5, 1.65);
	TF2Items_SetAttribute(hWeaponFists, 2, 402, 1.0);
	TF2Items_SetNumAttributes(hWeaponFists, 3);
	int iEntity = TF2Items_GiveNamedItem(client, hWeaponFists);
	EquipPlayerWeapon(client, iEntity);
	CloseHandle(hWeaponFists);
	
	SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iEntity, 255, 255, 255, 0);
	SetEntProp(iEntity, Prop_Send, "m_fEffects", 16);
	
	char anim[16];
	Format(anim, 32, "spawn0%i", GetRandomInt(1, 7));
	PlayAnimation(client, anim);
	
	g_bSpecial[client] = true;
	
	SetNextAttack(iEntity, 2.0);
	
	SDKHook(client, SDKHook_GetMaxHealth, GetMaxHealth);
	
	SetEntProp(client, Prop_Send, "m_iHealth", 1000);
	
	g_bSkeleton[client] = true;	
}

stock void PlayAnimation(int client, char[] anim)
{
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 0);
	
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);	
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	float vecOrigin[3], vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientAbsAngles(client, vecAngles);
	vecAngles[0] = 0.0;

	int animationentity = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(animationentity))
	{
		DispatchKeyValueVector(animationentity, "origin", vecOrigin);
		DispatchKeyValueVector(animationentity, "angles", vecAngles);
		DispatchKeyValue(animationentity, "model", MODEL_SKELETON);
		DispatchKeyValue(animationentity, "defaultanim", anim);
		DispatchSpawn(animationentity);
		SetEntPropEnt(animationentity, Prop_Send, "m_hOwnerEntity", client);
		
		if(GetEntProp(client, Prop_Send, "m_iTeamNum") == 0)
			SetEntProp(animationentity, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nForcedSkin"));
		else
			SetEntProp(animationentity, Prop_Send, "m_nSkin", GetClientTeam(client) - 2);
			
		SetEntPropFloat(animationentity, Prop_Send, "m_flModelScale", 2.0);
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(animationentity, "AddOutput");
		
		HookSingleEntityOutput(animationentity, "OnAnimationDone", OnAnimationDone, true);
	}
}

public void OnAnimationDone(const char[] output, int caller, int activator, float delay)
{	
	if(IsValidEntity(caller))
	{
		int client = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
		if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);		
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			
			g_bSpecial[client] = false;
		}
	}
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon) 
{
	if (IsPlayerAlive(client))
	{
		if(iButtons & IN_ATTACK2 && !g_bSpecial[client] && g_bSkeleton[client] && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
		{
			SetNextAttack(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), 2.0);
			PlayAnimation(client, "MELEE_swing3");
			g_bSpecial[client] = true;
			
			float vecAngles[3], vecOrigin[3];
			GetClientAbsAngles(client, vecAngles);
			GetClientAbsOrigin(client, vecOrigin);
			vecAngles[0] = 0.0;
			
			Handle pack;
			CreateDataTimer(0.75, Timer_PerformStomp, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(pack, client);
			WritePackFloat(pack, vecOrigin[0]);
			WritePackFloat(pack, vecOrigin[1]);
			WritePackFloat(pack, vecOrigin[2]);
			
			WritePackFloat(pack, vecAngles[0]);
			WritePackFloat(pack, vecAngles[1]);
			WritePackFloat(pack, vecAngles[2]);
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_PerformStomp(Handle timer, Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	float vecAngles[3], vecOrigin[3];
	vecOrigin[0] = ReadPackFloat(pack);
	vecOrigin[1] = ReadPackFloat(pack);
	vecOrigin[2] = ReadPackFloat(pack);
	
	vecAngles[0] = ReadPackFloat(pack);
	vecAngles[1] = ReadPackFloat(pack);
	vecAngles[2] = ReadPackFloat(pack);
	
	float vForward[3], vLeft[3];
	GetAngleVectors(vecAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(vecAngles, NULL_VECTOR, vLeft, NULL_VECTOR);
	vecOrigin[0] += (vForward[0] * 55);
	vecOrigin[1] += (vForward[1] * 55);
	vecOrigin[2] += (vForward[2] * 55);
	
	vecOrigin[0] += (vLeft[0] * -35);
	vecOrigin[1] += (vLeft[1] * -35);
	vecOrigin[2] += (vLeft[2] * -35);
	
	CreateParticle("bomibomicon_ring", vecOrigin);	//The effect actually comes out of his leg VALVE
	
	float pos2[3], Vec[3], AngBuff[3];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && i != client && GetClientTeam(i) != GetClientTeam(client))
		{
			GetClientAbsOrigin(i, pos2);

			if(GetVectorDistance(vecOrigin, pos2) <= 200.0)
			{
				MakeVectorFromPoints(vecOrigin, pos2, Vec);
				GetVectorAngles(Vec, AngBuff);
				AngBuff[0] -= 30.0; 
				GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(Vec, Vec);
				ScaleVector(Vec, 500.0);    
				Vec[2] += 250.0;
				SDKHooks_TakeDamage(i, client, client, GetConVarFloat(g_hCvarStompDamage));
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
			}
		}
	}
}

public Action TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(victim > 0 && victim <= MaxClients && IsClientInGame(victim) 
	&& attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker)
	&& attacker != victim)
	{
		if(g_bSkeleton[attacker])
		{
			damage = GetRandomFloat(95.0, 120.0);
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue; 
}

public Action Event_SkeletonDeath(Handle hEvent, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetEventInt(hEvent, "inflictor_entindex");
	
	if(g_bSkeleton[client])
	{
		EmitSoundToAll("misc/halloween/skeleton_break.wav", client);
		
		g_bSkeleton[client] = false;
		g_bSpecial[client] = false;
		
		SDKUnhook(client, SDKHook_GetMaxHealth, GetMaxHealth);
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 0);
		if(GetEntProp(client, Prop_Send, "m_iTeamNum") == 0)
		{
			SetEntProp(client, Prop_Send, "m_iTeamNum", g_iOldTeam[client]);
			g_iOldTeam[client] = TFTeam_Spectator;
		}
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		
		SetVariantString("1.0");
		AcceptEntityInput(client, "SetModelScale");
		
		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);
		
		//Drop a Rare spellbook
		int spell = CreateEntityByName("tf_spell_pickup");
		if(IsValidEntity(spell))
		{
			DispatchKeyValueVector(spell, "origin", vecOrigin);
			DispatchKeyValueVector(spell, "basevelocity", view_as<float>({0.0, 0.0, 0.0}));
			DispatchKeyValueVector(spell, "velocity", view_as<float>({0.0, 0.0, 0.0}));
			DispatchKeyValue(spell, "powerup_model", "models/props_halloween/hwn_spellbook_upright_major.mdl");
			DispatchKeyValue(spell, "OnPlayerTouch", "!self,Kill,,0,-1");
			
			DispatchSpawn(spell);
			
			SetVariantString("OnUser1 !self:kill::60:1");
			AcceptEntityInput(spell, "AddOutput");
			AcceptEntityInput(spell, "FireUser1");
			
			SetEntPropEnt(spell, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(spell, Prop_Data, "m_nTier", 1);
		}
	}
	
	if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && g_bSkeleton[attacker])
	{
		SetEventInt(hEvent, "attacker", 0);
		SetEventString(hEvent, "weapon", "spellbook_skeleton"); 
		SetEventInt(hEvent, "customkill", 66); 
		SetEventString(hEvent, "weapon_logclassname", "spellbook_skeleton");
	}
	
	return Plugin_Continue;
}

public Action SkeletonSH(clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity))
	{
		if (!g_bSkeleton[entity]) return Plugin_Continue;
		
		if (StrContains(sample, "vo/sniper", false) != -1)
		{
			Format(sample, sizeof(sample), "misc/halloween/skeletons/skelly_giant_0%i.wav", GetRandomInt(1, 3));
			PrecacheSound(sample);
			EmitSoundToAll(sample, entity, channel, level, flags, volume);
			
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock void TF2_RemoveAllWearables(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
	
	while ((wearable = FindEntityByClassname(wearable, "vgui_screen")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Data, "m_hOwnerEntity");
			if (client == player)
			{
				AcceptEntityInput(wearable, "Kill");
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}

stock void SetNextAttack(int weapon, float duration = 0.0)
{
	if (!IsValidEntity(weapon)) return;
	
	float next = GetGameTime() + duration;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", next);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", next);
}

stock void CreateParticle(char[] particle, float pos[3])
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	
	for(int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }
    
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_WriteNum("entindex", -1);
		TE_WriteNum("m_iAttachType", 5);	//Dont associate with any entity
		TE_SendToClient(i, 0.0);
	}
}

public int Native_SetSkeleton(Handle plugin, int args)
{
	MakeSkeleton(GetNativeCell(1));
}

public int Native_IsSkeleton(Handle plugin, int args)
{
	return g_bSkeleton[GetNativeCell(1)];
}