/*
*	Plugin Goomba Stomp par Flyflo
*
*	Changelog version privée:
*		- 1.0.0 :
*					- Première version stable et complète.
*		- 1.0.1 :
*					- TF2_IsPlayerInvuln déplacé pour supprimer les messages d'erreur dans les logs.
*		- 1.0.2 :
*					- Réécriture d'une condition empéchant le plugin de fonctionner si sm_goomba_invuln était différent de 1.
*					- Ajout du nom d'équipe pour le tueur et le tué.
*					- Modification des couleurs du message sur le chat général.
*		- 1.1.0 :
*					- Utilisation de dhTakeDamage à la place de ForcePlayerSuicide :
*						- Nouvel include.
*						- Besoin de Dukehacks.
*						- Le goomba stomp est désormais considéré comme un kill à part entière (rapporte 1 point, peut causer domination/vengeance, killcam).
*					- Ajout de particules lors d'un stomp.
*					- Suppression de LogPlyrPlyrEvent ainsi que toutes les fonction qui lui sont lié, le jeu log les stomp très bien par lui même.
*					- Ajout de conditions supplémentaires (already_stomped) afin d'alléger le travail du plugin. En contrepartie il n'est plus possible de stomper plusieurs personnes en une fois.
*					- sm_goomba_invuln renommé en sm_goomba_uber_immun et par défaut sur 1.
*					- sm_goomba_minheight est maintenant supérieur ou égal à 0 dans un souci de logique.
*					- Léger nettoyage du code.
*		- 1.1.1 :
*					- sm_goomba_minheight est par défaut à 360 pour empécher le stomp par le double saut du scout.
*					- Ajout de sm_goomba_stun_imun ajouté et par défaut sur 1, cela protège les personnes stunnées d'être stompé.
*					- Ajout de sm_goomba_cloak_imun ajouté et par défaut sur 1, cela protège les personnes d'être stompé par un spy cloaké.
*		- 1.1.2 :
*					- Le stomp enlève le déguisement du spy qui l'utilise.
*					- Modification du message de stomp avec moins de couleurs.
*		- 1.1.3 :
*					- Utilisation de OnPlayerRunCmd à la place de OnGameFrame, cela devrait réduire la charge de calcul.
*					- L'event de kill n'est plus supprimé puis recréé, il est maintenant réécrit en direct (affichage des dominations, des revanches et des assists supporté complétement).
*					- Suppression du check pour le godmode :
*						- La deadringer protège du stomp.
*						- Buddha protège du stomp.
*					- Les particules du feu d'artifice ne suivent plus le joueur (on pouvait suivre les spys avec la dead ringer).
*		- 1.1.4 :
*					- Nettoyage du code en vue de la version publique:
*						- Renommage de certaines cvar et fonctions.
*						- Suppression de bout de code de debug.
*					- Ajout de nouvelles cvar:
*						- sm_goomba_undisguise
*						- sm_goomba_cloaked_imun
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
*		- 1.1.0 :
*					- Usage of sdkhooks :
*						- No more team-kill stomp :(
*						- Best accuracy (should be 100%)
*						- Less resource intensive ? (removed OnGameFrame())
*					- Support for my custom achievement api plugin (TF_GOOMBA_STOMP)
*					- New cvar sm_goomba_bonked_imun
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <colors>
#include <clientprefs>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <CA_api>

#define PL_NAME "Goomba Stomp"
#define PL_DESC "Goomba Stomp"
#define PL_VERSION "1.1.0"

#define TF2_PLAYER_DISGUISED	(1 << 3)
#define TF2_PLAYER_CLOAKED      (1 << 4)
#define TF2_PLAYER_INVULN       (1 << 5)
#define TF2_PLAYER_BONKED       (1 << 14)
#define TF2_PLAYER_STUN			(1 << 15)

public Plugin:myinfo = 
{
	name = PL_NAME,
	author = "Flyflo",
	description = PL_DESC,
	version = PL_VERSION,
	url = "http://www.geek-gaming.fr"
}

new Handle:g_Cvar_StompMinSpeed = INVALID_HANDLE;
new Handle:g_Cvar_PluginEnabled = INVALID_HANDLE;
new Handle:g_Cvar_UberImun = INVALID_HANDLE;
new Handle:g_Cvar_JumpPower = INVALID_HANDLE;
new Handle:g_Cvar_CloakImun = INVALID_HANDLE;
new Handle:g_Cvar_StunImun = INVALID_HANDLE;
new Handle:g_Cvar_StompUndisguise = INVALID_HANDLE;
new Handle:g_Cvar_CloakedImun = INVALID_HANDLE;
new Handle:g_Cvar_BonkedImun = INVALID_HANDLE;
new Handle:g_Cvar_SoundsEnabled = INVALID_HANDLE;
new Handle:g_Cvar_ImmunityEnabled = INVALID_HANDLE;

new Handle:g_Cvar_FriendlyFire = INVALID_HANDLE;

new Handle:g_Cookie_ClientPref;

new bool:g_CA_api_loaded;

new Goomba_Fakekill[MAXPLAYERS+1];
new Goomba_SingleImmunityMessage[MAXPLAYERS+1];
new g_Ent[MAXPLAYERS + 1];
new g_Target[MAXPLAYERS + 1];
new g_PassArg[MAXPLAYERS + 1];

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
stock bool:TF2_IsPlayerBonked(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return ((pcond & TF2_PLAYER_BONKED) != 0);
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
	g_Cvar_UberImun = CreateConVar("sm_goomba_uber_immun", "1.0", "Prevent ubercharged players from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_JumpPower = CreateConVar("sm_goomba_jump_pow", "300.0", "Goomba jump power", 0, true, 0.0);
	g_Cvar_StompUndisguise = CreateConVar("sm_goomba_undisguise", "1.0", "Undisguise spies after stomping", 0, true, 0.0, true, 1.0);
	g_Cvar_CloakedImun = CreateConVar("sm_goomba_cloaked_imun", "0.0", "Prevent cloaked spies from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_BonkedImun = CreateConVar("sm_goomba_bonked_imun", "1.0", "Prevent bonked scout from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_SoundsEnabled = CreateConVar("sm_goomba_sounds", "1", "Enable or disable sounds of the plugin", 0, true, 0.0, true, 1.0);
	g_Cvar_ImmunityEnabled = CreateConVar("sm_goomba_immunity", "1", "Enable or disable the immunity system", 0, true, 0.0, true, 1.0);
	
	g_Cookie_ClientPref = RegClientCookie("sm_goomba_client_pref", "", CookieAccess_Private);
	RegConsoleCmd("sm_goomba_toggle", Cmd_GoombaToggle, "Toggle the goomba immunity client's pref.");
	RegConsoleCmd("sm_goomba_status", Cmd_GoombaStatus, "Give the current goomba immunity setting.");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	g_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");
	
	g_CA_api_loaded = LibraryExists("ca_api");
	
	AutoExecConfig(true, "goomba");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "ca_api"))
	{
		g_CA_api_loaded = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "ca_api"))
	{
		g_CA_api_loaded = true;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, Touch);
}

public OnMapStart()
{
	PrecacheSound("mario/coin.wav", true);
	PrecacheSound("mario/death.wav", true);
	AddFileToDownloadsTable("sound/mario/coin.wav");
	AddFileToDownloadsTable("sound/mario/death.wav");
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


public Touch(client, other)
{
	if(GetConVarBool(g_Cvar_PluginEnabled))
	{
		if(other <= MaxClients && other > 0)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				decl Float:ClientPos[3];
				decl Float:VictimPos[3];
				GetClientAbsOrigin(client, ClientPos);
				GetClientAbsOrigin(other, VictimPos);

				new Float:HeightDiff = ClientPos[2] - VictimPos[2];
				
				if(HeightDiff >= 81 && HeightDiff <= 84)
				{
					decl Float:vec[3];
					GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

					if(vec[2] < (GetConVarFloat(g_Cvar_StompMinSpeed)*-1.0))
					{
						g_PassArg[client] = other;
						CreateTimer(0.0, GoombaStomp, client);
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
	if(StrEqual(strCookie, "0"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "on");
	}
	if(StrEqual(strCookie, "1"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "off");
	}
	if(StrEqual(strCookie, "2"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "next_off");
	}
	if(StrEqual(strCookie, "3"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "next_on");
	}
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

public Action:GoombaStomp(Handle:timer, any:client)
{
	new victim = g_PassArg[client];
	g_PassArg[client] = -1;
	
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
			
			if(GetConVarFloat(g_Cvar_BonkedImun) > 0 && TF2_IsPlayerBonked(victim))
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

				decl Float:vecAng[3], Float:vecVel[3];
				GetClientEyeAngles(client, vecAng);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
				vecAng[0] = DegToRad(vecAng[0]);
				vecAng[1] = DegToRad(vecAng[1]);
				vecVel[0] = GetConVarFloat(g_Cvar_JumpPower)*Cosine(vecAng[0])*Cosine(vecAng[1]);
				vecVel[1] = GetConVarFloat(g_Cvar_JumpPower)*Cosine(vecAng[0])*Sine(vecAng[1]);
				vecVel[2] = GetConVarFloat(g_Cvar_JumpPower)+100.0;
				
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel); //Rebond après le stomp
				
				new victim_health;
				new m_Offset;
				
				Goomba_Fakekill[victim] = 1; //Suppression du vrai kill
				
				m_Offset = FindSendPropOffs("CTFPlayer", "m_iHealth");
				victim_health = GetEntData(victim, m_Offset, 4);

				AttachParticle(victim, "mini_fireworks");
				CreateTimer(5.0, Timer_Delete, victim, TIMER_FLAG_NO_MAPCHANGE);

				DealDamage(victim, victim_health + 100, client);
				
				if(TF2_IsPlayerInvuln(victim)) //En cas d'über
				{
					ForcePlayerSuicide(victim);
				}
				
				Goomba_Fakekill[victim] = 0;
				
				ForcePlayerSuicide(victim);

#if defined _c_achievements_included
				if(g_CA_api_loaded)
				{
					CA_ProcessAchievementByName("TF_GOOMBA_STOMP", client);
				}
#endif
				
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

				
				if(GetClientTeam(client) != GetClientTeam(victim))
				{
					CPrintToChatAllEx(client, "%t", "Goomba Stomp", Attacker, Killed);
				}
				else
				{
					CPrintToChatAllEx(client, "%t", "Goomba Stomp TeamKill", Attacker, Killed);
				}
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

public Action:InhibMessage(Handle:timer, any:client)
{
	Goomba_SingleImmunityMessage[client] = 0;
}

DealDamage(victim, damage, attacker = 0, dmg_type = 0)
{
	if(victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		new String:dmg_str[16];
		IntToString(damage, dmg_str, 16);
		
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);

		new pointHurt = CreateEntityByName("point_hurt");
		
		decl Float:VictimPos[3];
		GetClientAbsOrigin(victim, VictimPos);
		
		VictimPos[2] = VictimPos[2] + 0.05;
		
		TeleportEntity(pointHurt, VictimPos, NULL_VECTOR, NULL_VECTOR);

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
