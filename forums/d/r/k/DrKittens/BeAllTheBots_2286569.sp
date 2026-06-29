#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <betherobot>

#define PLUGIN_VERSION "1.7.1"

public Plugin:myinfo = 
{
	name = "BeAllTheRobots",
	author = "MasterOfTheXP;Kittens",
	description = "Utility Update, Merged BTSB and BATR",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/;www.veegeegames.com.au"
}

enum BusterStatus2 {
	BusterStatus2_Human = 0, // Client is human (as far as Be the Buster is concerned.)
	BusterStatus2_WantsToBeBuster, // Client wants to be a Sentry Buster, but can't because of defined rules.
	BusterStatus2_Buster // SENTRY BUSTERRRRR
}

new BusterStatus2:Status2[MAXPLAYERS + 1];
new bool:AboutToExplode[MAXPLAYERS + 1];
new Float:LastBusterTime; // Not for each player.

new RobotStatus:Status[MAXPLAYERS + 1];
new Float:LastTransformTime[MAXPLAYERS + 1];

new Handle:cvarFootsteps, Handle:cvarDefault, Handle:cvarClasses, Handle:cvarSounds, Handle:cvarTaunts,
Handle:cvarFileExists, Handle:cvarCooldown, Handle:cvarWearables, Handle:cvarWearablesKill, Handle:cvarBusterJump, Handle:cvarBusterAnnounce;
new Handle:cvarFF, Handle:cvarBossScale;

public OnPluginStart()
{
	RegAdminCmd("sm_robot", Command_betherobot, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_sentrybuster", Command_bethebuster, ADMFLAG_ROOT);
	
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");
	
	AddNormalSoundHook(SoundHook);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	
	//Sentry Buster Convars
	cvarBusterJump = CreateConVar("sm_betherobot_buster_jump","2","The height of Sentry Buster jumps. 0 makes it so they can't jump, 1 is normal, 2 is two times higher than normal...", FCVAR_NONE, true, 0.0);
	cvarBusterAnnounce = CreateConVar("sm_betherobot_buster_announce","2","Who should the Administrator warn about a Sentry Buster's presence? 1=Enemy team, 2=Your team. Default is 0 (no one)", FCVAR_NONE, true, 0.0);
	
	for (new k = 1; k <= MaxClients; k++)
	{
		if (!IsClientInGame(k)) continue;
		SDKHook(k, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	for (new k = MaxClients + 1; k <= 2048; k++)
	{
		if (!IsValidEntity(k)) continue;
		new String:cls[10];
		GetEntityClassname(k, cls, sizeof(cls));
		if (StrContains(cls, "obj_sen", false) == 0) SDKHook(k, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	
	//Be the Robots Convars
	CreateConVar("sm_betherobot_version",PLUGIN_VERSION,"Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarFootsteps = CreateConVar("sm_betherobot_footsteps","1","If on, players who are robots will make footstep sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarDefault = CreateConVar("sm_betherobot_default","0","If on, Be the Robot will be enabled on players when they join the server.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarClasses = CreateConVar("sm_betherobot_classes","0","These classes CANNOT be made into robots. Add up the numbers to restrict the classes you want. 1=Scout 2=Soldier 4=Pyro 8=Demo 16=Heavy 64=Medic 128=Sniper 256=Spy", FCVAR_NONE, true, 0.0, true, 511.0);
	cvarSounds = CreateConVar("sm_betherobot_sounds","1","If on, robots will emit robotic class sounds instead of their usual sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTaunts = CreateConVar("sm_betherobot_taunts","1","If on, robots can taunt. Most robot taunts are...incorrect. And some taunt kills don't play an animation for the killing part.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarFileExists = CreateConVar("sm_betherobot_fileexists","1","If on, any robot sound files must pass a check to see if they actually exist before being played. Recommended to the max. Only disable if robot sounds aren't working.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCooldown = CreateConVar("sm_betherobot_cooldown","2.0","If greater than 0, players must wait this long between enabling/disabling robot on themselves. Set to 0.0 to disable.", FCVAR_NONE, true, 0.0);
	cvarWearables = CreateConVar("sm_betherobot_wearables","1","If on, wearable items will be rendered on robots.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWearablesKill = CreateConVar("sm_betherobot_wearables_kill","0","If on, and sm_betherobot_wearables is 0, wearables are removed from robots instead of being turned invisible.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(cvarSounds, OnSoundsCvarChanged);
	
	AddMultiTargetFilter("@robots", Filter_Robots, "all robots", false);
	
	AutoExecConfig(true, "plugin.BeAllTheBots");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateTimer(0.5, Timer_HalfSecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);  //SentryBusterLine
	CreateNative("BeTheRobot_GetRobotStatus", Native_GetRobotStatus);
	CreateNative("BeTheRobot_SetRobot", Native_SetRobot);
	CreateNative("BeTheRobot_CheckRules", Native_CheckRules);
	RegPluginLibrary("betherobot");
	return APLRes_Success;
}

public OnMapStart()
{
	new String:classname[10], String:Mdl[PLATFORM_MAX_PATH];
	for (new TFClassType:i = TFClass_Scout; i <= TFClass_Engineer; i++)
	{
		TF2_GetNameOfClass(i, classname, sizeof(classname));
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
		PrecacheModel(Mdl, true);
	}
	CreateTimer(0.5, Timer_HalfSecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (GetConVarBool(cvarSounds)) ComeOnPrecacheZeSounds();
}

public OnMapEnd()
{
	for (new k = 1; k <= MaxClients; k++)		//Sentry Buster
		Status2[k] = BusterStatus2_Human;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Status[i] != RobotStatus_Robot) continue;
		Status[i] = RobotStatus_WantsToBeRobot;
	}
}

public OnClientConnected(client)
{
	Status[client] = GetConVarBool(cvarDefault) ? RobotStatus_WantsToBeRobot : RobotStatus_Human;
	LastTransformTime[client] = 0.0;
}

public OnConfigsExecuted()		//Sentry Buster
{
	cvarFootsteps = FindConVar("sm_betherobot_footsteps");
	cvarWearables = FindConVar("sm_betherobot_wearables");
	cvarWearablesKill = FindConVar("sm_betherobot_wearables_kill");
	
	cvarFF = FindConVar("mp_friendlyfire");
	cvarBossScale = FindConVar("tf_mvm_miniboss_scale");
}

public OnClientPutInServer(client) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); //Sentry Buster

public OnClientDisconnect(client)		//Sentry Buster
{
	Status2[client] = BusterStatus2_Human;
	AboutToExplode[client] = false;
}

public Action:Command_bethebuster(client, args)	//Sentry Buster All til next action
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
	for (new k = 0; k < target_count; k++)
		ToggleBuster(target_list[k], toggle);
	if (toggle != false && toggle != true) ShowActivity2(client, "[SM] ", "Toggled Sentry Buster on %s.", target_name);
	else ShowActivity2(client, "[SM] ", "%sabled Sentry Buster on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}


stock bool:ToggleBuster(client, bool:toggle = bool:2)	//Sentry Buster All til next action
{
	if (toggle) BeTheRobot_SetRobot(client, false);
	if (Status2[client] == BusterStatus2_WantsToBeBuster && toggle != false && toggle != true) return true;
	if (!Status2[client] && !toggle) return true;
	if (Status2[client] == BusterStatus2_Buster && toggle == true && BeTheRobot_CheckRules(client)) return true;
	if (Status2[client] != BusterStatus2_Buster)
	{
		if (!BeTheRobot_CheckRules(client))
		{
			Status2[client] = BusterStatus2_WantsToBeBuster;
			return false;
		}
	}
	if (toggle == true || (toggle == bool:2 && Status2[client] == BusterStatus2_Human))
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
		EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_loop.wav", client);
		CreateTimer(GetRandomFloat(5.0, 6.0), Timer_PlayBusterIntro, GetClientUserId(client));
		
		new String:AnnouncerSnd[PLATFORM_MAX_PATH], BusterAnnounce = GetConVarInt(cvarBusterAnnounce), team = GetClientTeam(client);
		if ((LastBusterTime + 360.0) > GetTickedTime()) Format(AnnouncerSnd, sizeof(AnnouncerSnd), "vo/mvm_sentry_buster_alerts0%k.wav", GetRandomInt(2,3));
		else
		{
			new rand = GetRandomInt(3,7);
			if (rand == 3) rand = 1;
			Format(AnnouncerSnd, sizeof(AnnouncerSnd), "vo/mvm_sentry_buster_alerts0%k.wav", rand);
		}
		for (new k = 1; k <= MaxClients; k++)
		{
			if (!BusterAnnounce) break;
			if (!IsValidClient(k)) continue;
			new zteam = GetClientTeam(k);
			if (team == zteam && !(BusterAnnounce & 2)) continue;
			if (team != zteam && !(BusterAnnounce & 1)) continue;
			EmitSoundToClient(k, AnnouncerSnd);
		}
		
		LastBusterTime = GetTickedTime();
		Status2[client] = BusterStatus2_Buster;
		SetWearableAlpha(client, 0);
	}
	else if (!toggle || (toggle == bool:2 && Status2[client] == BusterStatus2_Buster))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Status2[client] = BusterStatus2_Human;
		if (IsPlayerAlive(client)) TF2_RegeneratePlayer(client);
		StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		AboutToExplode[client] = false;
		SetWearableAlpha(client, 255);
	}
	return true;
}


public Action:Command_betherobot(client, args)
{
	if (!client && !args)
	{
		new String:arg0[20];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a robot. Beep boop.", arg0);
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "betherobot", 0))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[4], bool:toggle = bool:2;
	if (args < 1 || !CheckCommandAccess(client, "betherobot_admin", ADMFLAG_SLAY))
	{
		if (!ToggleRobot(client)) ReplyToCommand(client, "[SM] You can't be a robot right now, but you'll be one as soon as you can.");
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
		ToggleRobot(target_list[i], toggle);
	if (toggle != false && toggle != true) ShowActivity2(client, "[SM] ", "Toggled robot on %s.", target_name);
	else ShowActivity2(client, "[SM] ", "%sabled robot on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}

stock bool:ToggleRobot(client, bool:toggle = bool:2)
{
	if (Status[client] == RobotStatus_WantsToBeRobot && toggle != false && toggle != true) return true;
	if (!Status[client] && !toggle) return true;
	if (Status[client] == RobotStatus_Robot && toggle == true && CheckTheRules(client)) return true;
	if (!Status[client] || Status[client] == RobotStatus_WantsToBeRobot)
	{
		new bool:rightnow = true;
		if (!IsPlayerAlive(client)) rightnow = false;
	//	if (isBuster[client]) return false;
		if (!CheckTheRules(client)) rightnow = false;
		if (!rightnow)
		{
			Status[client] = RobotStatus_WantsToBeRobot;
			return false;
		}
	}
	if (toggle == true || (toggle == bool:2 && Status[client] == RobotStatus_Human))
	{
		new String:classname[10];
		TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
		new String:Mdl[PLATFORM_MAX_PATH];
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", classname, classname);
		ReplaceString(Mdl, sizeof(Mdl), "demoman", "demo", false);
		SetVariantString(Mdl);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		LastTransformTime[client] = GetTickedTime();
		Status[client] = RobotStatus_Robot;
		SetWearableAlpha(client, 0);
	}
	else if (!toggle || (toggle == bool:2 && Status[client] == RobotStatus_Robot)) // Can possibly just be else. I am not good with logic.
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		LastTransformTime[client] = GetTickedTime();
		Status[client] = RobotStatus_Human;
		SetWearableAlpha(client, 255);
	}
	return true;
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (Status2[client] == BusterStatus2_Buster)
	{
		if (AboutToExplode[client]) return Plugin_Continue;
		if (GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1) return Plugin_Continue;
		GetReadyToExplode(client);
	}
	if (Status[client] == RobotStatus_Robot && !GetConVarBool(cvarTaunts)) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Status2[client] == BusterStatus2_WantsToBeBuster) ToggleBuster(client, true);
	if (Status[client])
	{
		new Float:cooldown = GetConVarFloat(cvarCooldown), bool:immediate;
		if (LastTransformTime[client] + cooldown <= GetTickedTime()) immediate = true;
		ToggleRobot(client, false);
		if (immediate) LastTransformTime[client] = 0.0;
		ToggleRobot(client, true);
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) return;
	if (Status2[client] == BusterStatus2_Buster)
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
		if (Status[i] == RobotStatus_WantsToBeRobot) ToggleRobot(i, true);
	}
	for (new k = 1; k <= MaxClients; k++)  //Global Change |k| var to i and merge last line with above??
	{
		if (!IsValidClient(k)) continue;
		if (Status2[k] == BusterStatus2_WantsToBeBuster) ToggleBuster(k, true);
	}
}

public Action:Timer_PlayBusterIntro(Handle:timer, any:uid)		//Sentry Buster
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	if (Status2[client] != BusterStatus2_Buster) return;
	if (!IsPlayerAlive(client)) return;
	if (!AboutToExplode[client]) return;
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_intro.wav", client);
	CreateTimer(GetRandomFloat(5.0, 6.0), Timer_PlayBusterIntro, GetClientUserId(client));
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:uid)	//Sentry Buster
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEntity(ragdoll) || ragdoll <= MaxClients) return;
	AcceptEntityInput(ragdoll, "Kill");
}

public Action:Timer_UnBuster(Handle:timer, any:uid)		//Sentry Buster
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	ToggleBuster(client, false);
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!GetConVarBool(cvarSounds)) return Plugin_Continue;
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(Ent)) return Plugin_Continue;
	new client = Ent;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (Status[client] == RobotStatus_Robot)
	{
		if (StrContains(sound, "player/footsteps/", false) != -1 && class != TFClass_Medic && GetConVarBool(cvarFootsteps))
		{
			new rand = GetRandomInt(1,18);
			Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
			pitch = GetRandomInt(95, 100);
			EmitSoundToAll(sound, client, _, _, _, 0.25, pitch);
			return Plugin_Changed;
		}
		if (StrContains(sound, "vo/", false) == -1) return Plugin_Continue;
		if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
		if (volume == 0.99997) return Plugin_Continue;
		ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/norm/", false);
		ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false);
		new String:classname[10], String:classname_mvm[15];
		TF2_GetNameOfClass(class, classname, sizeof(classname));
		Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
		ReplaceString(sound, sizeof(sound), classname, classname_mvm, false);
		new String:soundchk[PLATFORM_MAX_PATH];
		Format(soundchk, sizeof(soundchk), "sound/%s", sound);
		if (!FileExists(soundchk, true) && GetConVarBool(cvarFileExists)) return Plugin_Continue;
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (Status2[client] == BusterStatus2_Buster)		//Sentry Buster
	{
		if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
		if (StrContains(sound, "/mvm", false) != -1 || StrContains(sound, "\\mvm", false) != -1) return Plugin_Continue;
		if (StrContains(sound, "vo/", false) != -1) return Plugin_Stop;
	}
	return Plugin_Continue;
}

//Sentry Buster code block Starts here
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClient(victim))
	{
		if (Status2[victim] != BusterStatus2_Buster || victim == attacker) return Plugin_Continue;
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
		if (Status2[attacker] == BusterStatus2_Buster && !AboutToExplode[attacker])
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
	for (new k = 1; k <= MaxClients; k++)
	{
		if (!IsValidClient(k)) continue;
		if (!IsPlayerAlive(k)) continue;
		if (GetClientTeam(k) == GetClientTeam(client) && !FF) continue;
		new Float:zPos[3];
		GetClientAbsOrigin(k, zPos);
		new Float:Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;
		DoDamage(client, k, 2500);
	}
	for (new k = MaxClients + 1; k <= 2048; k++)
	{
		if (!IsValidEntity(k)) continue;
		decl String:cls[20];
		GetEntityClassname(k, cls, sizeof(cls));
		if (!StrEqual(cls, "obj_sentrygun", false) &&
		!StrEqual(cls, "obj_dispenser", false) &&
		!StrEqual(cls, "obj_teleporter", false)) continue;
		new Float:zPos[3];
		GetEntPropVector(k, Prop_Send, "m_vecOrigin", zPos);
		new Float:Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;
		SetVariantInt(2500);
		AcceptEntityInput(k, "RemoveHealth");
	}
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_explode.wav", client);
	AttachParticle(client, "fluidSmokeExpl_ring_mvm");
	DoDamage(client, client, 2500);
	FakeClientCommand(client, "kill");
	CreateTimer(0.0, Timer_RemoveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}
//Sentry Buster code block ends here

public OnSoundsCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	if (StringToInt(newValue)) ComeOnPrecacheZeSounds();
	
public bool:Filter_Robots(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == RobotStatus_Robot) PushArrayCell(clients, i);
	}
	return true;
}

public Native_GetRobotStatus(Handle:plugin, args)
	return _:Status[GetNativeCell(1)];

public Native_SetRobot(Handle:plugin, args)
	ToggleRobot(GetNativeCell(1), bool:GetNativeCell(2));

public Native_CheckRules(Handle:plugin, args)
	return CheckTheRules(GetNativeCell(1));

stock bool:CheckTheRules(client)
{
	if (!IsPlayerAlive(client)) return false;
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting) ||
	TF2_IsPlayerInCondition(client, TFCond_Dazed)) return false;
	new Float:cooldowntime = GetConVarFloat(cvarCooldown);
	if (cooldowntime > 0.0 && (LastTransformTime[client] + cooldowntime) > GetTickedTime()) return false;
	if (GetConVarInt(cvarClasses) & (1 << TF2_ClassTypeToRole(TF2_GetPlayerClass(client)) - 1)) return false;
	return true;
}

stock TF2_ClassTypeToRole(TFClassType:class)
{
	switch (class)
	{
		case TFClass_Scout: return 1;
		case TFClass_Soldier: return 2;
		case TFClass_Pyro: return 3;
		case TFClass_DemoMan: return 4;
		case TFClass_Heavy: return 5;
		case TFClass_Engineer: return 6;
		case TFClass_Medic: return 7;
		case TFClass_Sniper: return 8;
		case TFClass_Spy: return 9;
	}
	return 1; // wat
}

stock TF2_GetNameOfClass(TFClassType:class, String:name[], maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
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

//Sentry Buster Code BLock Starts here
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
		for (new k = 0; k < count; k += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[k]), StringToFloat(atts[k+1]));
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
		Format(dmg, 15, "%k", amount);
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
	Format(tName, sizeof(tName), "target%k", Ent);
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
//Sentry Buster Code block ends here

ComeOnPrecacheZeSounds()
{
	for (new i = 1; i <= 18; i++)
	{
		decl String:snd[PLATFORM_MAX_PATH];
		Format(snd, sizeof(snd), "mvm/player/footsteps/robostep_%s%i.wav", (i < 10) ? "0" : "", i);
		PrecacheSound(snd, true);
		if (i <= 4)
		{
			Format(snd, sizeof(snd), "mvm/sentrybuster/mvm_sentrybuster_step_0%i.wav", i);
			PrecacheSound(snd, true);
		}
		if (i <= 6)
		{
			Format(snd, sizeof(snd), "vo/mvm_sentry_buster_alerts0%i.wav", i);
			PrecacheSound(snd, true);
		}
	}
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_explode.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_intro.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_loop.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_spin.wav", true);
	PrecacheModel("models/bots/demo/bot_sentry_buster.mdl", true);
}