#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2attributes>

#define SPAWN "mvm/sentrybuster/mvm_sentyrybuster_intro"
#define LEFTFOOT	")mvm/sentrybuster/mvm_sentrybuster_step_01.wav"
#define LEFTFOOT1	")mvm/sentrybuster/mvm_sentrybuster_step_03.wav"
#define RIGHTFOOT	")mvm/sentrybuster/mvm_sentrybuster_step_02.wav"
#define RIGHTFOOT1	")mvm/sentrybuster/mvm_sentrybuster_step_04.wav"

public Plugin:myinfo = 
{
	name = "Be the Tank",
	author = "Unknown",
	description = "Unknown",
	version = "1.0",
	url = "unknown"
}

bool g_bSkeleton[MAXPLAYERS + 1];

public OnPluginStart()
{
	RegConsoleCmd("sm_bebuster", Command_scout, "Lets you become a Spy that is so powerfull.");
	RegConsoleCmd("sm_retsub", Command_scout, "Lets you become a Spy that is so powerfull.");
	AddNormalSoundHook(SentryBusterSH);
	HookEvent("player_death", Event_SkeletonDeath, EventHookMode_Pre);
}

public OnMapStart()
{
	PrecacheSound(SPAWN, true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_step_01.wav");
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_step_02.wav");
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_step_03.wav");
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_step_04.wav");
}

public Action:Command_scout(int client, int args)
{
	EmitSoundToAll(SPAWN, client);
	SDKHook(client, SDKHook_GetMaxHealth, GetMaxHealth);
	SetEntProp(client, Prop_Send, "m_iHealth",5000);
	TF2_RemoveAllWeapons(client);
	GiveAxe(client);
	GiveAxe2(client);
	g_bSkeleton[client] = true;
	SetVariantString("models/bots/demo/bot_sentry_buster.mdl");
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1)
	return Plugin_Handled
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) return;
	if (Status[client] == BusterStatus_Buster)
	{
		StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav")
	}

public Action GetMaxHealth(int client, int &MaxHealth)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		MaxHealth = 5000;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock GiveAxe(client)
{
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_stickbomb");
		TF2Items_SetItemIndex(hWeapon, 307);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		new String:weaponAttribs[84];
		Format(weaponAttribs, sizeof(weaponAttribs), "107 ; 2 ; 2 ; 999.0");
		new String:weaponAttribsArray[32][32];
		new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
		if (attribCount > 0) {
			TF2Items_SetNumAttributes(hWeapon, attribCount/2);
			new i2 = 0;
			for (new i = 0; i < attribCount; i+=2) {
				TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
				i2++;
			}
		} else {
			TF2Items_SetNumAttributes(hWeapon, 0);
		}
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);

		CloseHandle(hWeapon);
	}
}

stock bool:AttachParticle(Ent, String:particleType[], bool:cache=false) // from L4D Achievement Trophy
{
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return false;
	new String:tName[128];
	new Float:f_pos[3];
	if (cache) f_pos[2] -= 3000;
	else
	{
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", f_pos);
		f_pos[2] += 60;
	}
	TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", Ent);
	DispatchKeyValue(Ent, "targetname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(10.0, DeleteParticle, particle);
	return true;
}

public Action:DeleteParticle(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return;
	new String:cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
}

public Action:SentryBusterSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsHHH[entity]) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_common/giant_common_step_01.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_common/giant_common_step_03.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_common/giant_common_step_02.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_common/giant_common_step_04.wav");
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}