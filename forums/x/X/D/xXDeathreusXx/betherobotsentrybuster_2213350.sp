#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <betherobot>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "Be the Robot: Sentry Buster",
	author = "MasterOfTheXP",
	description = "This in a nutshell -> http://gamebanana.com/tf2/sounds/17716",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

enum BusterStatus {
	BusterStatus_Human = 0, // Client is human (as far as Be the Buster is concerned.)
	BusterStatus_WantsToBeBuster, // Client wants to be a Sentry Buster, but can't because of defined rules.
	BusterStatus_Buster // SENTRY BUSTERRRRR
}

new BusterStatus:Status[MAXPLAYERS + 1];
new bool:AboutToExplode[MAXPLAYERS + 1];
new Float:LastBusterTime; // Not for each player.

new Handle:cvarFootsteps, Handle:cvarWearables, Handle:cvarBusterJump, Handle:cvarBusterAnnounce, Handle:cvarWearablesKill, Handle:cvarBusterSounds;
new Handle:cvarFF, Handle:cvarBossScale;

public OnPluginStart()
{
	RegConsoleCmd("sm_sentrybuster", Command_bethebuster);
	RegConsoleCmd("sm_buster", Command_bethebuster);
	
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");
	
	AddNormalSoundHook(SoundHook);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	
	cvarBusterJump = CreateConVar("sm_betherobot_buster_jump","0","The height of Sentry Buster jumps. 0 makes it so they can't jump, 1 is normal, 2 is two times higher than normal...", FCVAR_NONE, true, 0.0);
	cvarBusterAnnounce = CreateConVar("sm_betherobot_buster_announce","0","Who should the Administrator warn about a Sentry Buster's presence? 1=Enemy team, 2=Your team. Default is 0 (no one)", FCVAR_NONE, true, 0.0);
	cvarBusterSounds = CreateConVar("sm_betherobot_buster_sounds","1","Want to hear that tell-tale sign of a buster, his beeps?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	for (new i = MaxClients + 1; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		new String:cls[10];
		GetEntityClassname(i, cls, sizeof(cls));
		if (StrContains(cls, "obj_sen", false) == 0) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnMapStart()
{
	CreateTimer(0.5, Timer_HalfSecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
		Status[i] = BusterStatus_Human;
}
	
public OnConfigsExecuted()
{
	cvarFootsteps = FindConVar("sm_betherobot_footsteps");
	cvarWearables = FindConVar("sm_betherobot_wearables");
	cvarWearablesKill = FindConVar("sm_betherobot_wearables_kill");
	
	cvarFF = FindConVar("mp_friendlyfire");
	cvarBossScale = FindConVar("tf_mvm_miniboss_scale");
}

public OnClientPutInServer(client) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

public OnClientDisconnect(client)
{
	Status[client] = BusterStatus_Human;
	AboutToExplode[client] = false;
}

public Action:Command_bethebuster(client, args)
{
	if (!client && !args)
	{
		new String:arg0[20];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a Sentry Buster. Beep beep.", arg0);
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "bethebuster", ADMFLAG_ROOT))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[4], bool:toggle = bool:2;
	if (args < 1 || !CheckCommandAccess(client, "bethebuster_admin", ADMFLAG_ROOT))
	{
		if (BeTheRobot_GetRobotStatus(client)) BeTheRobot_SetRobot(client, false);
		if (!ToggleBuster(client)) ReplyToCommand(client, "[SM] You can't be a Sentry Buster right now, but you'll be one as soon as you can.");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		if (args > 1)
		{
			GetCmdArg(2, arg2, sizeof(arg2));
			toggle = bool:StringToInt(arg2);
		}
	}
	
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
		ToggleBuster(target_list[i], toggle);
	if (toggle != false && toggle != true) ShowActivity2(client, "[SM] ", "Toggled Sentry Buster on %s.", target_name);
	else ShowActivity2(client, "[SM] ", "%sabled Sentry Buster on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}

stock bool:ToggleBuster(client, bool:toggle = bool:2)
{
	if (toggle) BeTheRobot_SetRobot(client, false);
	if (Status[client] == BusterStatus_WantsToBeBuster && toggle != false && toggle != true) return true;
	if (!Status[client] && !toggle) return true;
	if (Status[client] == BusterStatus_Buster && toggle == true && BeTheRobot_CheckRules(client)) return true;
	if (Status[client] != BusterStatus_Buster)
	{
		if (!BeTheRobot_CheckRules(client))
		{
			Status[client] = BusterStatus_WantsToBeBuster;
			return false;
		}
	}
	if (toggle == true || (toggle == bool:2 && Status[client] == BusterStatus_Human))
	{
		if (TF2_GetPlayerClass(client) != TFClass_DemoMan) TF2_SetPlayerClass(client, TFClass_DemoMan);
		TF2_RemoveAllWeapons(client);
		new String:atts[128];
		Format(atts, sizeof(atts), "26 ; 2325 ; "); // +2325 max HP (2500)
		Format(atts, sizeof(atts), "%s107 ; 2.0 ; ", atts); // +100% move speed (520 Hammer units/second, as fast as possible; actual Buster is 560)
		Format(atts, sizeof(atts), "%s252 ; 0.5 ; ", atts); // -50% damage force to user
		Format(atts, sizeof(atts), "%s329 ; 0.5 ; ", atts); // -50% airblast power vs user
		if (GetConVarBool(cvarFootsteps))
			Format(atts, sizeof(atts), "%s330 ; 7 ; ", atts); // Override footstep sound set
		Format(atts, sizeof(atts), "%s402 ; 1 ; ", atts); // Cannot be backstabbed
		Format(atts, sizeof(atts), "%s326 ; %f ; ", atts, GetConVarFloat(cvarBusterJump)); // +-100% jump height (jumping disabled)
		Format(atts, sizeof(atts), "%s138 ; 0 ; ", atts); // -100% damage to players (0)
		Format(atts, sizeof(atts), "%s137 ; 38.461540 ; ", atts); // +3746% damage to buildings (2500)
		Format(atts, sizeof(atts), "%s275 ; 1", atts); // User never takes fall damage
		new wepEnt = SpawnWeapon(client, "tf_weapon_stickbomb", 307, 10, 6, atts);
		if (IsValidEntity(wepEnt)) SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wepEnt);
		SetEntProp(wepEnt, Prop_Send, "m_iDetonated", 1);
		SetEntityHealth(client, 2500);
		SetVariantString("models/bots/demo/bot_sentry_buster.mdl");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", GetConVarFloat(cvarBossScale));
		
		// Sound tomfoolery
		EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_intro.wav", client);
		if(GetConVarBool(cvarBusterSounds))
		{
			EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_loop.wav", client);
		}
		CreateTimer(GetRandomFloat(5.0, 6.0), Timer_PlayBusterIntro, GetClientUserId(client));
		
		new String:AnnouncerSnd[PLATFORM_MAX_PATH], BusterAnnounce = GetConVarInt(cvarBusterAnnounce), team = GetClientTeam(client);
		if ((LastBusterTime + 360.0) > GetTickedTime()) Format(AnnouncerSnd, sizeof(AnnouncerSnd), "vo/mvm_sentry_buster_alerts0%i.wav", GetRandomInt(2,3));
		else
		{
			new rand = GetRandomInt(3,7);
			if (rand == 3) rand = 1;
			Format(AnnouncerSnd, sizeof(AnnouncerSnd), "vo/mvm_sentry_buster_alerts0%i.wav", rand);
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!BusterAnnounce) break;
			if (!IsValidClient(i)) continue;
			new zteam = GetClientTeam(i);
			if (team == zteam && !(BusterAnnounce & 2)) continue;
			if (team != zteam && !(BusterAnnounce & 1)) continue;
			EmitSoundToClient(i, AnnouncerSnd);
		}
		
		LastBusterTime = GetTickedTime();
		Status[client] = BusterStatus_Buster;
		SetWearableAlpha(client, 0);
	}
	else if (!toggle || (toggle == bool:2 && Status[client] == BusterStatus_Buster))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Status[client] = BusterStatus_Human;
		if (IsPlayerAlive(client)) TF2_RegeneratePlayer(client);
		StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		AboutToExplode[client] = false;
		SetWearableAlpha(client, 255);
	}
	return true;
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (Status[client] == BusterStatus_Buster)
	{
		if (AboutToExplode[client]) return Plugin_Continue;
		if (GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1) return Plugin_Continue;
		GetReadyToExplode(client);
	}
	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Status[client] == BusterStatus_WantsToBeBuster) ToggleBuster(client, true);
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) return;
	if (Status[client] == BusterStatus_Buster)
	{
		StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
		CreateTimer(0.0, Timer_UnBuster, GetClientUserId(client)); // If you do it too soon, you'll hear a Demoman pain sound :3 Doing it on the next frame seems to be fine.
	}
	
	return;
}

public Action:Timer_HalfSecond(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == BusterStatus_WantsToBeBuster) ToggleBuster(i, true);
	}
}

public Action:Timer_PlayBusterIntro(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	if (Status[client] != BusterStatus_Buster) return;
	if (!IsPlayerAlive(client)) return;
	if (!AboutToExplode[client]) return;
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_intro.wav", client);
	CreateTimer(GetRandomFloat(5.0, 6.0), Timer_PlayBusterIntro, GetClientUserId(client));
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEntity(ragdoll) || ragdoll <= MaxClients) return;
	AcceptEntityInput(ragdoll, "Kill");
}

public Action:Timer_UnBuster(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	ToggleBuster(client, false);
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(Ent)) return Plugin_Continue;
	new client = Ent;
	if (Status[client] == BusterStatus_Buster)
	{
		if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
		if (StrContains(sound, "/mvm", false) != -1 || StrContains(sound, "\\mvm", false) != -1) return Plugin_Continue;
		if (StrContains(sound, "vo/", false) != -1) return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClient(victim))
	{
		if (Status[victim] != BusterStatus_Buster || victim == attacker) return Plugin_Continue;
		new Float:dmg = ((damagetype & DMG_CRIT) ? damage*3 : damage) + 10.0; // +10 to attempt to account for damage rampup.
		if (AboutToExplode[victim])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		else if (dmg > GetClientHealth(victim))
		{
			damage = 0.0;
			GetReadyToExplode(victim);
			FakeClientCommand(victim, "taunt");
			return Plugin_Changed;
		}
	}
	else if (IsValidClient(attacker)) // This is a Sentry.
	{
		if (Status[attacker] == BusterStatus_Buster && !AboutToExplode[attacker])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnEntityCreated(Ent, const String:cls[])
{
	if (GetGameTime() < 0.5) return;
	if (Ent < MaxClients || Ent > 2048) return;
	if (StrContains(cls, "obj_sen", false) == 0)
		SDKHook(Ent, SDKHook_Spawn, OnSentrySpawned);
}

public Action:OnSentrySpawned(Ent)
	SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage);

stock GetReadyToExplode(client)
{
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_spin.wav", client);
	StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	CreateTimer(2.0, Bewm, GetClientUserId(client));
	AboutToExplode[client] = true;
}

public Action:Bewm(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	AboutToExplode[client] = false;
	new explosion = CreateEntityByName("env_explosion");
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	if (explosion)
	{
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
	new bool:FF = GetConVarBool(cvarFF);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) == GetClientTeam(client) && !FF) continue;
		new Float:zPos[3];
		GetClientAbsOrigin(i, zPos);
		new Float:Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;
		DoDamage(client, i, 2500);
	}
	for (new i = MaxClients + 1; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		decl String:cls[20];
		GetEntityClassname(i, cls, sizeof(cls));
		if (!StrEqual(cls, "obj_sentrygun", false) &&
		!StrEqual(cls, "obj_dispenser", false) &&
		!StrEqual(cls, "obj_teleporter", false)) continue;
		new Float:zPos[3];
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", zPos);
		new Float:Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;
		SetVariantInt(2500);
		AcceptEntityInput(i, "RemoveHealth");
	}
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_explode.wav", client);
	AttachParticle(client, "fluidSmokeExpl_ring_mvm");
	DoDamage(client, client, 2500);
	FakeClientCommand(client, "kill");
	CreateTimer(0.0, Timer_RemoveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock SpawnWeapon(client, String:name[], itemIndex, level, qual, String:att[]) // from VS Saxton Hale Mode.
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, itemIndex);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon == INVALID_HANDLE)
	return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock DoDamage(client, target, amount) // from Goomba Stomp.
{
	new pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		new String:dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
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

stock SetWearableAlpha(client, alpha, bool:override = false)
{
	if (GetConVarBool(cvarWearables) && !override) return 0;
	new count;
	for (new z = MaxClients + 1; z <= 2048; z++)
	{
		if (!IsValidEntity(z)) continue;
		decl String:cls[35];
		GetEntityClassname(z, cls, sizeof(cls));
		if (!StrEqual(cls, "tf_wearable") && !StrEqual(cls, "tf_powerup_bottle")) continue;
		if (client != GetEntPropEnt(z, Prop_Send, "m_hOwnerEntity")) continue;
		if (!GetConVarBool(cvarWearablesKill))
		{
			SetEntityRenderMode(z, RENDER_TRANSCOLOR);
			SetEntityRenderColor(z, 255, 255, 255, alpha);
		}
		else if (alpha == 0) AcceptEntityInput(z, "Kill");
		count++;
	}
	return count;
}