/*
*	Plugin Goomba Stomp par Flyflo
*
*	Public version changelog:
*		- 1.0.0 :
*					- First public version :p
*		- 1.0.1 :
*					- Added sm_goomba_sounds to control if the plugin plays sounds or not.
*					- Fixed a little bug with the sound fonctions.
*		- 1.0.2 :
*					- Added a new immunity system (require clientprefs).
*					- Fixed a bug with the über immunity.
*					- Cleanup of the GoombaStomp() code.
*		- 1.0.3 :
*					- OnGameFrame() is back, SM 1.2 support.
*					- Use of DealDamage() instead of dhTakeDamage(), Dukehacks is no longer required.
*					- sm_goomba_ff cvar added, you can now stomp your teammates (mp_friendlyfire = 1 required).
*					- Translations updated and improved (better customization).
*					- Use of exvel's Colors include for colored translations.
*		- 1.0.3b :
*					- Minor optimisations and code changes (thx exvel and psychonic) :
*						- MaxClients used instead of GetMaxClients()
*						- CPrintToChatAllEx used instead of CPrintToChatAll, less code and less translation for the same result :)
*						- Plugin enabled check moved to be more efficient.
*						- Less code for the condition checks.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>
#include <clientprefs>

#define PL_NAME "Goomba Stomp"
#define PL_DESC "Goomba Stomp"
#define PL_VERSION "1.0.3b"
#define TF2_PLAYER_DISGUISED	(1 << 3)
#define TF2_PLAYER_CLOAKED      (1 << 4)
#define TF2_PLAYER_INVULN       (1 << 5)
#define TF2_PLAYER_STUN			(1 << 15)

public Plugin:myinfo = 
{
	name = PL_NAME,
	author = "Flyflo",
	description = PL_DESC,
	version = PL_VERSION,
	url = "http://www.geek-gaming.fr"
}

new Handle:g_CheckWait[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_Cvar_StompMinSpeed = INVALID_HANDLE;
new Handle:g_Cvar_PluginEnabled = INVALID_HANDLE;
new Handle:g_Cvar_RadiusCheck = INVALID_HANDLE;
new Handle:g_Cvar_UberImun = INVALID_HANDLE;
new Handle:g_Cvar_JumpPower = INVALID_HANDLE;
new Handle:g_Cvar_CloakImun = INVALID_HANDLE;
new Handle:g_Cvar_StunImun = INVALID_HANDLE;
new Handle:g_Cvar_StompUndisguise = INVALID_HANDLE;
new Handle:g_Cvar_CloakedImun = INVALID_HANDLE;
new Handle:g_Cvar_FriendlyFireStomp = INVALID_HANDLE;
new Handle:g_Cvar_SoundsEnabled = INVALID_HANDLE;
new Handle:g_Cvar_ImmunityEnabled = INVALID_HANDLE;

new Handle:g_Cvar_FriendlyFire = INVALID_HANDLE;

new Handle:g_Cookie_ClientPref;

new Goomba_Fakekill[MAXPLAYERS+1];
new Goomba_SingleImmunityMessage[MAXPLAYERS+1];
new g_Ent[MAXPLAYERS + 1];
new g_Target[MAXPLAYERS + 1];

//------------------------------------------------------
new g_FilteredEntity = -1;
public bool:TraceFilter(ent, contentMask)
{
   return (ent == g_FilteredEntity) ? false : true;
}

stock bool:TF2_IsPlayerInvuln(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return ((pcond & TF2_PLAYER_INVULN) != 0);
}
stock bool:TF2_IsPlayerStunned(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return ((pcond & TF2_PLAYER_STUN) != 0);
}
stock bool:TF2_IsPlayerCloaked(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return ((pcond & TF2_PLAYER_CLOAKED) != 0);
}
stock bool:TF2_IsPlayerDisguised(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return ((pcond & TF2_PLAYER_DISGUISED) != 0);
}
stock bool:IsFriendlyFireEnabled()
{
	return (GetConVarInt(g_Cvar_FriendlyFire) == 1);
}


stock TF2_GetPlayerCond(client)
{
    return GetEntProp(client, Prop_Send, "m_nPlayerCond");
}

//------------------------------------------------------

public OnPluginStart()
{
	LoadTranslations("goomba.phrases");

	CreateConVar("sm_goomba_version", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_PluginEnabled = CreateConVar("sm_goomba_enabled", "1.0", "Plugin On/Off", 0, true, 0.0, true, 1.0);
	g_Cvar_StompMinSpeed = CreateConVar("sm_goomba_minspeed", "360.0", "Minimum falling speed to kill", 0, true, 0.0, false, 0.0);
	g_Cvar_CloakImun = CreateConVar("sm_goomba_cloak_imun", "1.0", "Prevent cloaked spies from stomping", 0, true, 0.0, true, 1.0);
	g_Cvar_StunImun = CreateConVar("sm_goomba_stun_imun", "1.0", "Prevent stunned players from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_RadiusCheck = CreateConVar("sm_goomba_radius", "16.0", "Radius Check", 0, true, 0.0);
	g_Cvar_UberImun = CreateConVar("sm_goomba_uber_immun", "1.0", "Prevent ubercharged players from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_JumpPower = CreateConVar("sm_goomba_jump_pow", "300.0", "Goomba jump power", 0, true, 0.0);
	g_Cvar_StompUndisguise = CreateConVar("sm_goomba_undisguise", "1.0", "Undisguise spies after stomping", 0, true, 0.0, true, 1.0);
	g_Cvar_CloakedImun = CreateConVar("sm_goomba_cloaked_imun", "0.0", "Prevent cloaked spies from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_FriendlyFireStomp = CreateConVar("sm_goomba_ff", "0.0", "Enable the friendly fire for the stomp (require mp_friendlyfire = 1)", 0, true, 0.0, true, 1.0);
	g_Cvar_SoundsEnabled = CreateConVar("sm_goomba_sounds", "1", "Enable or disable sounds of the plugin", 0, true, 0.0, true, 1.0);
	g_Cvar_ImmunityEnabled = CreateConVar("sm_goomba_immunity", "0", "Enable or disable the immunity system", 0, true, 0.0, true, 1.0);
	
	g_Cookie_ClientPref = RegClientCookie("sm_goomba_client_pref", "", CookieAccess_Private);
	RegConsoleCmd("sm_goomba_toggle", Cmd_GoombaToggle, "Toggle the goomba immunity client's pref.");
	RegConsoleCmd("sm_goomba_status", Cmd_GoombaStatus, "Give the current goomba immunity setting.");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	g_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");
	
	AutoExecConfig(true, "goomba");
}

public OnMapStart()
{
	PrecacheSound("mario/coin.wav", true);
	PrecacheSound("mario/death.wav", true);
	AddFileToDownloadsTable("sound/mario/coin.wav");
	AddFileToDownloadsTable("sound/mario/death.wav");
}

public OnGameFrame()
{
	if(GetConVarBool(g_Cvar_PluginEnabled))
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			FrameAction(client);
		}
	}
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	decl String:tName[128];
	
	if (IsValidEdict(particle))
	{
		
		decl Float:pos[3] ;
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		
		DispatchKeyValue(ent, "targetname", tName);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		
		SetVariantString(tName);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		g_Ent[ent] = particle;
		g_Target[ent] = 1;
		
	}
}

DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        decl String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
		
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	DeleteParticle(g_Ent[client]);
	g_Ent[client] = 0;
	g_Target[client] = 0;
}

public FrameAction(any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND) && g_CheckWait[client] == INVALID_HANDLE)
		{
			decl Float:vec[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

			if(vec[2] < (GetConVarFloat(g_Cvar_StompMinSpeed)*-1.0))
			{
				decl Float:pos[3];
				decl Float:checkpos[3];
				g_FilteredEntity = client;
				
				new Handle:TraceEx;
				new HitEnt;
				
				new bool:already_stomped = false;
				
				//check 1

				GetClientAbsOrigin(client, pos);
				GetClientAbsOrigin(client, checkpos);
				checkpos[0] -= GetConVarFloat(g_Cvar_RadiusCheck);
				checkpos[1] -= GetConVarFloat(g_Cvar_RadiusCheck);
				checkpos[2] -= 30.0;
				TraceEx = TR_TraceRayFilterEx(pos, checkpos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
				HitEnt = TR_GetEntityIndex(TraceEx);
				CloseHandle(TraceEx);
				if(HitEnt > 0)
				{
					GoombaStomp(client, HitEnt);
					already_stomped = true;
				}
				
				//check 2
				if(!already_stomped)
				{
					GetClientAbsOrigin(client, pos);
					GetClientAbsOrigin(client, checkpos);
					checkpos[0] -= GetConVarFloat(g_Cvar_RadiusCheck);
					checkpos[1] += GetConVarFloat(g_Cvar_RadiusCheck);
					checkpos[2] -= 30.0;
					TraceEx = TR_TraceRayFilterEx(pos, checkpos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
					HitEnt = TR_GetEntityIndex(TraceEx);
					CloseHandle(TraceEx);
					if(HitEnt > 0)
					{
						GoombaStomp(client, HitEnt);
						already_stomped = true;
					}
				}
				
				//check 3
				if(!already_stomped)
				{
					GetClientAbsOrigin(client, pos);
					GetClientAbsOrigin(client, checkpos);
					checkpos[0] += GetConVarFloat(g_Cvar_RadiusCheck);
					checkpos[1] += GetConVarFloat(g_Cvar_RadiusCheck);
					checkpos[2] -= 30.0;
					TraceEx = TR_TraceRayFilterEx(pos, checkpos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
					HitEnt = TR_GetEntityIndex(TraceEx);
					CloseHandle(TraceEx);
					if(HitEnt > 0)
					{
						GoombaStomp(client, HitEnt);
						already_stomped = true;
					}
				}
				
				//check 4
				if(!already_stomped)
				{
					GetClientAbsOrigin(client, pos);
					GetClientAbsOrigin(client, checkpos);
					checkpos[0] += GetConVarFloat(g_Cvar_RadiusCheck);
					checkpos[1] -= GetConVarFloat(g_Cvar_RadiusCheck);
					checkpos[2] -= 30.0;
					TraceEx = TR_TraceRayFilterEx(pos, checkpos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
					HitEnt = TR_GetEntityIndex(TraceEx);
					CloseHandle(TraceEx);
					if(HitEnt > 0)
					{
						GoombaStomp(client, HitEnt);
						already_stomped = true;
					}
				}
			}
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(Goomba_Fakekill[victim] == 1) //Réécriture du kill
	{
		SetEventString(event, "weapon_logclassname", "goomba");
		SetEventString(event, "weapon", "taunt_scout");
		SetEventInt(event, "customkill", 0);
	}

	return Plugin_Continue;

}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:strCookie[16];
	GetClientCookie(client, g_Cookie_ClientPref, strCookie, sizeof(strCookie));
	//-----------------------------------------------------
	// on		= Immunity enabled
	// off		= Immunity disabled
	// next_on	= Immunity enabled on respawn
	// next_off	= Immunity disabled on respawn
	//-----------------------------------------------------
	
	if(StrEqual(strCookie, ""))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "off");
	}
	
	if(StrEqual(strCookie, "next_off"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "off");
	}
	if(StrEqual(strCookie, "next_on"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "on");
	}
	
	
}

stock GoombaStomp(any:client, any:victim)
{
	if(victim != -1)
	{
		decl String:edictName[32];
		GetEdictClassname(victim, edictName, sizeof(edictName));

		if(StrEqual(edictName, "player"))
		{
			new bool:CancelStomp = false;
			
			decl String:strCookieClient[16];
			GetClientCookie(client, g_Cookie_ClientPref, strCookieClient, sizeof(strCookieClient));
			
			decl String:strCookieVictim[16];
			GetClientCookie(victim, g_Cookie_ClientPref, strCookieVictim, sizeof(strCookieVictim));
			
			if(GetConVarFloat(g_Cvar_ImmunityEnabled) > 0)
			{
				if(StrEqual(strCookieClient, "on") || StrEqual(strCookieClient, "next_off"))
				{
					CancelStomp = true;
				}
				else
				{
					if(StrEqual(strCookieVictim, "on") || StrEqual(strCookieVictim, "next_off"))
					{
						CancelStomp = true;
						if(Goomba_SingleImmunityMessage[client] == 0)
						{
							CPrintToChat(client, "%t", "Victim Immun");
						}
						
						Goomba_SingleImmunityMessage[client] = 1;
						CreateTimer(0.5, InhibMessage, client);
					}
				}
			}
			
			if(GetClientTeam(client) == GetClientTeam(victim))
			{
				if(GetConVarFloat(g_Cvar_FriendlyFireStomp) == 0 || !IsFriendlyFireEnabled())
				{
					CancelStomp = true;
				}
			
			}
			
			if((GetConVarFloat(g_Cvar_UberImun) > 0 && TF2_IsPlayerInvuln(victim)))
			{
				CancelStomp = true;
			}
			
			if(GetConVarFloat(g_Cvar_StunImun) > 0 && TF2_IsPlayerStunned(victim))
			{
				CancelStomp = true;
			}
			
			if(GetConVarFloat(g_Cvar_CloakImun) > 0 && TF2_IsPlayerCloaked(client))
			{
				CancelStomp = true;
			}
			
			if(GetConVarFloat(g_Cvar_CloakedImun) > 0 && TF2_IsPlayerCloaked(victim))
			{
				CancelStomp = true;
			}
			
			if(!CancelStomp)
			{
				decl String:Attacker[256];
				GetClientName(client, Attacker, sizeof(Attacker)); //Pseudo du tueur
				decl String:Killed[256];
				GetClientName(victim, Killed, sizeof(Killed)); //Pseudo du tué
				
				if(GetConVarFloat(g_Cvar_SoundsEnabled) > 0)
				{
					EmitSoundToAll("mario/coin.wav", victim); //Son de pièce émis autour de la victime
				}
				
				Goomba_Fakekill[victim] = 1; //Suppression du vrai kill
				
				AttachParticle(victim, "mini_fireworks");
				CreateTimer(5.0, Timer_Delete, victim, TIMER_FLAG_NO_MAPCHANGE);

				DealDamage(victim, 1000, client);
				
				if(TF2_IsPlayerInvuln(victim)) //En cas d'über
				{
					ForcePlayerSuicide(victim);
				}
				
				Goomba_Fakekill[victim] = 0;
				
				if(GetConVarFloat(g_Cvar_SoundsEnabled) > 0)
				{
					EmitSoundToClient(victim, "mario/death.wav", victim); //Son de mort joué à la victime
				}

				PrintHintText(victim, "%t", "Victim Stomped"); //Message de stomp à la victime
				
				if(GetConVarFloat(g_Cvar_StompUndisguise) > 0)
				{
					if(TF2_IsPlayerDisguised(client))
					{
						TF2_DisguisePlayer(client, TFTeam:GetClientTeam(client), TFClass_Spy);
					}
				}
				
				decl Float:vecAng[3], Float:vecVel[3];
				GetClientEyeAngles(client, vecAng);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
				vecAng[0] = DegToRad(vecAng[0]);
				vecAng[1] = DegToRad(vecAng[1]);
				vecVel[0] = GetConVarFloat(g_Cvar_JumpPower)*Cosine(vecAng[0])*Cosine(vecAng[1]);
				vecVel[1] = GetConVarFloat(g_Cvar_JumpPower)*Cosine(vecAng[0])*Sine(vecAng[1]);
				vecVel[2] = GetConVarFloat(g_Cvar_JumpPower)+100.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel); //Rebond après le stomp
				
				if(GetClientTeam(client) != GetClientTeam(victim))
				{
					CPrintToChatAllEx(client, "%t", "Goomba Stomp", Attacker, Killed);
				}
				else
				{
					CPrintToChatAllEx(client, "%t", "Goomba Stomp TeamKill", Attacker, Killed);
				}
				
				/*
				if(GetClientTeam(client) == 2)//RED
				{
					if(GetClientTeam(client) != GetClientTeam(victim))
					{
						CPrintToChatAll("%t", "Red Stomp Blue", Attacker, Killed);
					}
					else
					{
						CPrintToChatAll("%t", "Red Stomp Red", Attacker, Killed);
					}
				}
				else if(GetClientTeam(client) == 3)//BLU
				{
					if(GetClientTeam(client) != GetClientTeam(victim))
					{
						CPrintToChatAll("%t", "Blue Stomp Red", Attacker, Killed);
					}
					else
					{
						CPrintToChatAll("%t", "Blue Stomp Blue", Attacker, Killed);
					}
				}*/
			}
		}
	}
}

public Action:Cmd_GoombaToggle(client, args)
{
	if(GetConVarFloat(g_Cvar_ImmunityEnabled) > 0)
	{
		decl String:strCookie[16];
		GetClientCookie(client, g_Cookie_ClientPref, strCookie, sizeof(strCookie));
		
		if(StrEqual(strCookie, "off") || StrEqual(strCookie, "next_off")) //Activé ou activé au prochain round
		{
			SetClientCookie(client, g_Cookie_ClientPref, "next_on");
			ReplyToCommand(client, "%t", "Immun On");
		}
		else
		{
			SetClientCookie(client, g_Cookie_ClientPref, "next_off");
			ReplyToCommand(client, "%t", "Immun Off");
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "Immun Disabled");
	}
	return Plugin_Handled;
}

public Action:Cmd_GoombaStatus(client, args)
{
	if(GetConVarFloat(g_Cvar_ImmunityEnabled) > 0)
	{
		decl String:strCookie[16];
		GetClientCookie(client, g_Cookie_ClientPref, strCookie, sizeof(strCookie));
		
		if(StrEqual(strCookie, "on"))
		{
			ReplyToCommand(client, "%t", "Status Off");
		}
		if(StrEqual(strCookie, "off"))
		{
			ReplyToCommand(client, "%t", "Status On");
		}
		if(StrEqual(strCookie, "next_off"))
		{
			ReplyToCommand(client, "%t", "Status Next On");
		}
		if(StrEqual(strCookie, "next_on"))
		{
			ReplyToCommand(client, "%t", "Status Next Off");
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "Immun Disabled");
	}
	
	return Plugin_Handled;
}

public Action:InhibMessage(Handle:client, any:Tclient)
{
	Goomba_SingleImmunityMessage[Tclient] = 0;
}

//Thx to pimpinjuice for his great DealDamage function.
DealDamage(victim, damage, attacker = 0, dmg_type = 0)
{
	if(victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		new String:dmg_str[16];
		IntToString(damage, dmg_str, 16);
		
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);

		new pointHurt = CreateEntityByName("point_hurt");
		
		if(pointHurt)
		{
			DispatchKeyValue(victim, "targetname", "goomba_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "goomba_hurtme");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);

			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "goomba_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}
