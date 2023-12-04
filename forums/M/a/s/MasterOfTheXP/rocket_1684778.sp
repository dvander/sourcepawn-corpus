#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#define PLUGIN_VERSION  "1.1"

public Plugin:myinfo = {
	name = "{MSTR} Rocket",
	author = "MasterOfTheXP",
	description = "I think it's gonna be a long time.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new Handle:cvarDelay;
new Handle:cvarForce;
new Handle:cvarExplosion;
new Handle:cvarTrail;

new Handle:hTopMenu = INVALID_HANDLE;

new Float:Delay = 1.0;
new Float:Force = 1.0;
new bool:Explosion = true;
new bool:Trail = true;

public OnPluginStart()
{
	RegAdminCmd("sm_rocket", Command_rocket, ADMFLAG_SLAY, "sm_rocket <target> - Kaboom.");
	
	cvarDelay = CreateConVar("sm_rocket_delay","1.0","Time, in seconds, to delay the target of sm_rocket's death.", FCVAR_NONE);
	cvarForce = CreateConVar("sm_rocket_force","1.0","How fast a sm_rocket target is launched upwards, also translates into how far. 1= 1500 hammer units/second 2.66= 4000h/s (same as Evolve's)", FCVAR_NONE, true, 0.2, true, 3.9);
	cvarExplosion = CreateConVar("sm_rocket_explosion","1","If 1, an explosion is generated where targets of sm_rocket die.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTrail = CreateConVar("sm_rocket_trail","1","If 1, a rocket trail is added to targets of sm_rocket.", FCVAR_NONE, true, 0.0, true, 1.0);
	// cvarGibs
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	HookConVarChange(cvarDelay, CvarChange);
	HookConVarChange(cvarForce, CvarChange);
	HookConVarChange(cvarExplosion, CvarChange);
	HookConVarChange(cvarTrail, CvarChange);
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	OnBothStart();
}

public OnMapStart() OnBothStart()

public OnBothStart()
{
	PrecacheSound("weapons/explode4.wav");
	PrecacheSound("weapons/explode5.wav");
}

new admin;

public Action:Command_rocket(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "sm_rocket <target> - Kaboom.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	GetCmdArgString(arg1, sizeof(arg1));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		CreateTimer(Delay, Kaboom, target_list[i]);
		new Float:vel[3];
		vel[0] = 0.0;
		vel[1] = 0.0;
		vel[2] = 1500.0 * Force;
		SetEntityMoveType(target_list[i], MOVETYPE_WALK);
		TeleportEntity(target_list[i], NULL_VECTOR, NULL_VECTOR, vel);
		admin = client;
		ShowActivity2(client, "[SM] ","Rocketed %N.", target_list[i]);
		if (Trail) AttachParticle(target_list[i], "rockettrail");
	}
	return Plugin_Handled;
}

public Action:Kaboom(Handle:timer, any:client) /* and the soap scum is gone! */
{
	if (!IsClientInGame(client)) PrintToChat(admin, "[SM] The target left the game before the rocket could complete!");
	if (!IsClientInGame(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) PrintToChat(admin, "[SM] %N died before the rocket could complete!", client);
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	new Float:clientpos[3];
	GetClientAbsOrigin(client, clientpos);
	new Float:startpos[3];
	startpos[0] = clientpos[0] + GetRandomInt(-500, 500);
	startpos[1] = clientpos[1] + GetRandomInt(-500, 500);
	startpos[2] = clientpos[2] + 800;
	new rand = GetRandomInt(4,5);
	if (rand == 4) EmitAmbientSound("weapons/explode4.wav", clientpos, client, SNDLEVEL_RAIDSIREN);
	if (rand == 5) EmitAmbientSound("weapons/explode5.wav", clientpos, client, SNDLEVEL_RAIDSIREN);
	new pointHurt = CreateEntityByName("point_hurt");
	if(pointHurt)
	{
		DispatchKeyValue(client, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		DispatchKeyValue(pointHurt, "Damage", "1410065408");
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", (admin>0)?admin:-1);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(client, "targetname", "");
		RemoveEdict(pointHurt);
	}
	if (Explosion)
	{
		new explosion = CreateEntityByName("env_explosion");
		if (explosion)
		{
			DispatchSpawn(explosion);
			TeleportEntity(explosion, clientpos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode", -1, -1, 0);
			RemoveEdict(explosion);
		}
	}
	
	ForcePlayerSuicide(client);
	return Plugin_Handled;
}

RocketMenu(client)
{
	new Handle:smMenu = CreateMenu(RocketMenuHandler);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Rocket player:", client);
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu(smMenu, client, true, false);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

public AdminMenu_Rocket(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption) Format(buffer, maxlength, "Rocket player", param);
	else if (action == TopMenuAction_SelectOption) RocketMenu(param);
}

public RocketMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0) PrintToChat(client, "[SM] %t", "Player no longer available");
		else
		{
			new UID = GetClientUserId(target);
			FakeClientCommand(client, "sm_rocket #%i", UID);
		}
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu) return;
	hTopMenu = topmenu;
	new TopMenuObject:playerCommands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (playerCommands != INVALID_TOPMENUOBJECT) AddToTopMenu(hTopMenu, "sm_rocket", TopMenuObject_Item, AdminMenu_Rocket, playerCommands, "sm_rocket", ADMFLAG_SLAY);
}

AttachParticle(ent, String:particleType[], bool:cache=false) /* from  */
{
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		new String:tName[128];
		new Float:f_pos[3];

		if (cache) {
			f_pos[2] -= 3000;
		}else{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f_pos);
			f_pos[2] += 60;
		}

		TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(Delay, DeleteParticle, particle);
	}
}

public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false)) RemoveEdict(particle);
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarDelay) Delay = StringToFloat(newValue);
	else if (convar == cvarForce) Force = StringToFloat(newValue);
	else if (convar == cvarExplosion) Explosion = bool:StringToInt(newValue);
	else if (convar == cvarTrail) Trail = bool:StringToInt(newValue);
}