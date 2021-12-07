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
*		- 1.2.0 :
*					- Added two cvars to set the damage done by the stomp :
*						- goomba_dmg_lifemultiplier
*						- goomba_dmg_add
*						-> Damage = (Victim's actual life * goomba_dmg_lifemultiplier) + goomba_dmg_add.
*					- SDKHooks_TakeDamage used instead of point_hurt entity
*					- TF2_IsPlayerInCondition used instead of TF2_GetPlayerCond
*					- Removed sm_ prefix from cvars.
*		- 1.2.1 :
*					- Fixed a strange bug with disguised spies stomping teammates.
*					- Fixed rebound sound not being played when the victim was not killed.
*					- Fixed death message printed to stomped spies with the Dead Ringer active.
*					- Added goomba_on and goomba_off commands for convenience.
*					- Fixed typo in immunity cvars (immun instead of imun).
*		- 1.2.2 :
*					- Fixed a bug in translations (I'm dumb).
*					- Fixed a bug that would prevent crouched people from being stomped.
*					- Fixed for real the death message for Dead Ringer'ed spies (thx FlaminSarge).
*					- Fixed death messages not appearing in some conditions.
*					- Stomp killicon is now shown as critical.
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <colors>
#include <clientprefs>
#include <sdkhooks>

#define PL_NAME "Goomba Stomp"
#define PL_DESC "Goomba Stomp"
#define PL_VERSION "1.2.2b"
// #define REBOUND_SOUND "mario/coin.wav"
// #define REBOUND_SOUND_FULL "sound/mario/coin.wav"
// #define STOMP_SOUND "mario/death.wav"
// #define STOMP_SOUND_FULL "sound/mario/death.wav"
#define REBOUND_SOUND "goomba/rebound.wav"
#define REBOUND_SOUND_FULL "sound/goomba/rebound.wav"
#define STOMP_SOUND "goomba/stomp.wav"
#define STOMP_SOUND_FULL "sound/goomba/stomp.wav"
#define HORSEMANN_DAMAGE 200.0

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
new Handle:g_Cvar_DamageLifeMultiplier = INVALID_HANDLE;
new Handle:g_Cvar_DamageAdd = INVALID_HANDLE;

new Handle:g_Cookie_ClientPref;

new Goomba_Fakekill[MAXPLAYERS+1];
new Goomba_SingleImmunityMessage[MAXPLAYERS+1];

// Thx to Pawn 3-pg
new bool:g_TeleportAtFrameEnd[MAXPLAYERS+1] = false;
new Float:g_TeleportAtFrameEnd_Vel[MAXPLAYERS+1][3];

public OnPluginStart()
{
	LoadTranslations("goomba.phrases");

	g_Cvar_PluginEnabled = CreateConVar("goomba_enabled", "1.0", "Plugin On/Off", 0, true, 0.0, true, 1.0);
	g_Cvar_StompMinSpeed = CreateConVar("goomba_minspeed", "360.0", "Minimum falling speed to kill", 0, true, 0.0, false, 0.0);
	g_Cvar_CloakImun = CreateConVar("goomba_cloak_immun", "1.0", "Prevent cloaked spies from stomping", 0, true, 0.0, true, 1.0);
	g_Cvar_StunImun = CreateConVar("goomba_stun_immun", "1.0", "Prevent stunned players from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_UberImun = CreateConVar("goomba_uber_immun", "1.0", "Prevent ubercharged players from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_JumpPower = CreateConVar("goomba_rebound_power", "300.0", "Goomba jump power", 0, true, 0.0);
	g_Cvar_StompUndisguise = CreateConVar("goomba_undisguise", "1.0", "Undisguise spies after stomping", 0, true, 0.0, true, 1.0);
	g_Cvar_CloakedImun = CreateConVar("goomba_cloaked_immun", "0.0", "Prevent cloaked spies from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_BonkedImun = CreateConVar("goomba_bonked_immun", "1.0", "Prevent bonked scout from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_SoundsEnabled = CreateConVar("goomba_sounds", "1", "Enable or disable sounds of the plugin", 0, true, 0.0, true, 1.0);
	g_Cvar_ImmunityEnabled = CreateConVar("goomba_immunity", "1", "Enable or disable the immunity system", 0, true, 0.0, true, 1.0);

	g_Cvar_DamageLifeMultiplier = CreateConVar("goomba_dmg_lifemultiplier", "1.0", "How much damage the victim will receive based on its actual life", 0, true, 0.0, false, 0.0);
	g_Cvar_DamageAdd = CreateConVar("goomba_dmg_add", "50.0", "Add this amount of damage after goomba_dmg_lifemultiplier calculation", 0, true, 0.0, false, 0.0);

	AutoExecConfig(true, "goomba");

	CreateConVar("goomba_version", PL_VERSION, PL_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_Cookie_ClientPref = RegClientCookie("goomba_client_pref", "", CookieAccess_Private);
	RegConsoleCmd("goomba_toggle", Cmd_GoombaToggle, "Toggle the goomba immunity client's pref.");
	RegConsoleCmd("goomba_status", Cmd_GoombaStatus, "Give the current goomba immunity setting.");
	RegConsoleCmd("goomba_on", Cmd_GoombaOn, "Enable stomp.");
	RegConsoleCmd("goomba_off", Cmd_GoombaOff, "Disable stomp.");

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) OnClientPutInServer(i);
	}
}

public OnMapStart()
{
	PrecacheSound(REBOUND_SOUND, true);
	PrecacheSound(STOMP_SOUND, true);
	AddFileToDownloadsTable(REBOUND_SOUND_FULL);
	AddFileToDownloadsTable(STOMP_SOUND_FULL);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_StartTouch, OnStartTouch);
	SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
}

public Action:OnStartTouch(client, other)
{
	if(GetConVarBool(g_Cvar_PluginEnabled))
	{
		if(other > 0 && other <= MaxClients)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				decl Float:ClientPos[3];
				decl Float:VictimPos[3];
				GetClientAbsOrigin(client, ClientPos);
				GetClientAbsOrigin(other, VictimPos);

				new Float:HeightDiff = ClientPos[2] - VictimPos[2];

				if((HeightDiff > 82.0) || ((GetClientButtons(other) & IN_DUCK) && (HeightDiff > 62.0)))
				{
					decl Float:vec[3];
					GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

					if(vec[2] < GetConVarFloat(g_Cvar_StompMinSpeed) * -1.0)
					{
						GoombaStomp(client, other);
					}
				}
			}
		}
		else if (IsValidEdict(other))
		{
			decl String:edictName[32];
			GetEdictClassname(other, edictName, sizeof(edictName));

			if (strcmp(edictName, "headless_hatman", false) == 0)
			{
				decl Float:ClientPos[3];
				decl Float:VictimPos[3];
				GetClientAbsOrigin(client, ClientPos);
				GetEntPropVector(other, Prop_Send, "m_vecOrigin", VictimPos);

				new Float:HeightDiff = ClientPos[2] - VictimPos[2];

				if(HeightDiff > 138)
				{
					decl Float:vec[3];
					GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

					if(vec[2] < GetConVarFloat(g_Cvar_StompMinSpeed) * -1.0)
					{
						GoombaStomp(client, other);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

GoombaStomp(client, victim)
{
	if(victim > 0 && victim <= MaxClients)
	{
		decl String:edictName[32];
		GetEdictClassname(victim, edictName, sizeof(edictName));

		if(StrEqual(edictName, "player"))
		{
			if(IsPlayerAlive(victim))
			{
				new bool:CancelStomp = false;

				decl String:strCookieClient[16];
				GetClientCookie(client, g_Cookie_ClientPref, strCookieClient, sizeof(strCookieClient));

				decl String:strCookieVictim[16];
				GetClientCookie(victim, g_Cookie_ClientPref, strCookieVictim, sizeof(strCookieVictim));

				if(GetClientTeam(client) == GetClientTeam(victim))
				{
					CancelStomp = true;
				}
				if(GetEntProp(victim, Prop_Data, "m_takedamage", 1) == 0)
				{
					CancelStomp = true;
				}
				if(GetConVarBool(g_Cvar_ImmunityEnabled))
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

				if((GetConVarBool(g_Cvar_UberImun) && TF2_IsPlayerInCondition(victim, TFCond_Ubercharged)))
				{
					CancelStomp = true;
				}
				else if(GetConVarBool(g_Cvar_StunImun) && TF2_IsPlayerInCondition(victim, TFCond_Dazed))
				{
					CancelStomp = true;
				}
				else if(GetConVarBool(g_Cvar_CloakImun) && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					CancelStomp = true;
				}
				else if(GetConVarBool(g_Cvar_CloakedImun) && TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
				{
					CancelStomp = true;
				}
				else if(GetConVarBool(g_Cvar_BonkedImun) && TF2_IsPlayerInCondition(victim, TFCond_Bonked))
				{
					CancelStomp = true;
				}

				if(!CancelStomp)
				{
					new particle = AttachParticle(victim, "mini_fireworks");
					if (particle != -1) CreateTimer(5.0, Timer_DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);

					new victim_health = GetClientHealth(victim);

					// Rebond
					decl Float:vecAng[3], Float:vecVel[3];
					GetClientEyeAngles(client, vecAng);
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
					vecAng[0] = DegToRad(vecAng[0]);
					vecAng[1] = DegToRad(vecAng[1]);
					vecVel[0] = GetConVarFloat(g_Cvar_JumpPower) * Cosine(vecAng[0]) * Cosine(vecAng[1]);
					vecVel[1] = GetConVarFloat(g_Cvar_JumpPower) * Cosine(vecAng[0]) * Sine(vecAng[1]);
					vecVel[2] = GetConVarFloat(g_Cvar_JumpPower) + 100.0;

					g_TeleportAtFrameEnd[client] = true;
					g_TeleportAtFrameEnd_Vel[client] = vecVel;

					Goomba_Fakekill[victim] = 1;
					SDKHooks_TakeDamage(victim,
										client,
										client,
										victim_health * GetConVarFloat(g_Cvar_DamageLifeMultiplier) + GetConVarFloat(g_Cvar_DamageAdd),
										DMG_PREVENT_PHYSICS_FORCE | DMG_CRUSH | DMG_ALWAYSGIB);

					// The victim is übercharged
					if(TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
					{
						ForcePlayerSuicide(victim);
					}
					Goomba_Fakekill[victim] = 0;
				}
			}
		}
	}
	else if (IsValidEdict(victim))
	{
		decl String:edictName[32];
		GetEdictClassname(victim, edictName, sizeof(edictName));

		if(strcmp(edictName, "headless_hatman", false) == 0)
		{
			new bool:CancelStomp = false;
			decl String:strCookieClient[16];
			GetClientCookie(client, g_Cookie_ClientPref, strCookieClient, sizeof(strCookieClient));
			if(GetConVarBool(g_Cvar_ImmunityEnabled))
			{
				if(StrEqual(strCookieClient, "on") || StrEqual(strCookieClient, "next_off"))
				{
					CancelStomp = true;
				}
			}
			if(GetConVarBool(g_Cvar_CloakImun) && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				CancelStomp = true;
			}
			if(!CancelStomp)
			{
				new particle = AttachParticle(victim, "mini_fireworks");
				if (particle != -1) CreateTimer(5.0, Timer_DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);

//				new victim_health = GetClientHealth(victim);

				// Rebond
				decl Float:vecAng[3], Float:vecVel[3];
				GetClientEyeAngles(client, vecAng);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
				vecAng[0] = DegToRad(vecAng[0]);
				vecAng[1] = DegToRad(vecAng[1]);
				vecVel[0] = GetConVarFloat(g_Cvar_JumpPower) * Cosine(vecAng[0]) * Cosine(vecAng[1]);
				vecVel[1] = GetConVarFloat(g_Cvar_JumpPower) * Cosine(vecAng[0]) * Sine(vecAng[1]);
				vecVel[2] = GetConVarFloat(g_Cvar_JumpPower) + 100.0;

				g_TeleportAtFrameEnd[client] = true;
				g_TeleportAtFrameEnd_Vel[client] = vecVel;

				SDKHooks_TakeDamage(victim,
									client,
									client,
									HORSEMANN_DAMAGE,
									DMG_PREVENT_PHYSICS_FORCE | DMG_CRUSH | DMG_ALWAYSGIB);

				CPrintToChatAllEx(client, "{olive}>> {teamcolor}%N {default}stomped the {olive}Horseless Headless Horsemann{default}!", client);
			}
		}
	}
}

public OnPreThinkPost(client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_TeleportAtFrameEnd[client])
		{
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, g_TeleportAtFrameEnd_Vel[client]);

			if(GetConVarBool(g_Cvar_SoundsEnabled))
			{
				EmitSoundToAll(REBOUND_SOUND, client);
			}
		}
	}
	g_TeleportAtFrameEnd[client] = false;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(Goomba_Fakekill[victim] == 1)
	{
		new damageBits = GetEventInt(event, "damagebits");

		SetEventString(event, "weapon_logclassname", "goomba");
		SetEventString(event, "weapon", "taunt_scout");
		SetEventInt(event, "damagebits", damageBits |= DMG_ACID);
		SetEventInt(event, "customkill", 0);
		SetEventInt(event, "playerpenetratecount", 0);
		if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			if(GetConVarBool(g_Cvar_SoundsEnabled))
			{
				EmitSoundToClient(victim, STOMP_SOUND, victim);
			}

			PrintHintText(victim, "%t", "Victim Stomped");
		}

		if(GetConVarBool(g_Cvar_StompUndisguise))
		{
			TF2_RemovePlayerDisguise(client);
		}

		CPrintToChatAllEx(client, "%t", "Goomba Stomp", client, victim);
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
	else if(StrEqual(strCookie, "next_off"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "off");
	}
	else if(StrEqual(strCookie, "next_on"))
	{
		SetClientCookie(client, g_Cookie_ClientPref, "on");
	}
}

public Action:Cmd_GoombaToggle(client, args)
{
	if(GetConVarBool(g_Cvar_ImmunityEnabled))
	{
		decl String:strCookie[16];
		GetClientCookie(client, g_Cookie_ClientPref, strCookie, sizeof(strCookie));

		if(StrEqual(strCookie, "off") || StrEqual(strCookie, "next_off"))
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

public Action:Cmd_GoombaOn(client, args)
{
	if(GetConVarBool(g_Cvar_ImmunityEnabled))
	{
		decl String:strCookie[16];
		GetClientCookie(client, g_Cookie_ClientPref, strCookie, sizeof(strCookie));

		if(!StrEqual(strCookie, "off"))
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

public Action:Cmd_GoombaOff(client, args)
{
	if(GetConVarBool(g_Cvar_ImmunityEnabled))
	{
		decl String:strCookie[16];
		GetClientCookie(client, g_Cookie_ClientPref, strCookie, sizeof(strCookie));

		if(!StrEqual(strCookie, "on"))
		{
			SetClientCookie(client, g_Cookie_ClientPref, "next_on");
			ReplyToCommand(client, "%t", "Immun On");
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
	if(GetConVarBool(g_Cvar_ImmunityEnabled))
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

public Action:Timer_DeleteParticle(Handle:timer, any:ref)
{
	new particle = EntRefToEntIndex(ref);
	DeleteParticle(particle);
}

stock AttachParticle(entity, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	decl String:tName[128];

	if (IsValidEdict(particle))
	{
		decl Float:pos[3] ;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		Format(tName, sizeof(tName), "target%i", entity);

		DispatchKeyValue(entity, "targetname", tName);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);

		SetVariantString(tName);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		return particle;
	}
	return -1;
}

stock DeleteParticle(any:particle)
{
    if (particle > MaxClients && IsValidEntity(particle))
    {
        decl String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));

        if (StrEqual(classname, "info_particle_system", false))
        {
            AcceptEntityInput(particle, "Kill");
        }
    }
}