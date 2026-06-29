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
*	Public version changlog:
*		- 1.0.0 :
*					- First public version :p
*		- 1.0.1 :
*					- Added sm_goomba_sounds to control if the plugin plays sounds or not.
*					- Fixed a little bug with the sound fonctions.
*/

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
//#include <dukehacks>

#define PL_NAME "Goomba Stomp"
#define PL_DESC "Goomba Stomp"
#define PL_VERSION "1.0.1"

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
new Handle:g_Cvar_PluginOnOff = INVALID_HANDLE;
new Handle:g_Cvar_RadiusCheck = INVALID_HANDLE;
new Handle:g_Cvar_UberImun = INVALID_HANDLE;
new Handle:g_Cvar_JumpPower = INVALID_HANDLE;
new Handle:g_Cvar_CloakImun = INVALID_HANDLE;
new Handle:g_Cvar_StunImun = INVALID_HANDLE;
new Handle:g_Cvar_StompUndisguise = INVALID_HANDLE;
new Handle:g_Cvar_CloakedImun = INVALID_HANDLE;
new Handle:g_Cvar_SoundsEnabled = INVALID_HANDLE;
new Handle:g_Cvar_FriendlyFire = INVALID_HANDLE;

new Goomba_Fakekill[MAXPLAYERS+1];
new g_Ent[MAXPLAYERS + 1];
new g_Target[MAXPLAYERS + 1];

//------------------------------------------------------
new g_FilteredEntity = -1;
public bool:TraceFilter(ent, contentMask)
{
   return (ent == g_FilteredEntity) ? false : true;
}
stock TF2_GetPlayerCond(client, flag)
{
	new pcond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	return pcond >= 0 ? ((pcond & flag) != 0) : false;
}


//------------------------------------------------------

public OnPluginStart()
{
	LoadTranslations("goomba.phrases");

	CreateConVar("sm_goomba_version", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_PluginOnOff = CreateConVar("sm_goomba_enabled", "1.0", "Plugin On/Off", 0, true, 0.0, true, 1.0);
	g_Cvar_StompMinSpeed = CreateConVar("sm_goomba_minspeed", "360.0", "Minimum falling speed to kill", 0, true, 0.0, false, 0.0);
	g_Cvar_CloakImun = CreateConVar("sm_goomba_cloak_imun", "1.0", "Prevent cloaked spies from stomping", 0, true, 0.0, true, 1.0);
	g_Cvar_StunImun = CreateConVar("sm_goomba_stun_imun", "1.0", "Prevent stunned players from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_RadiusCheck = CreateConVar("sm_goomba_radius", "15.0", "Radius Check", 0, true, 0.0);
	g_Cvar_UberImun = CreateConVar("sm_goomba_uber_immun", "1.0", "Prevent ubercharged players from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_JumpPower = CreateConVar("sm_goomba_jump_pow", "300.0", "Goomba jump power", 0, true, 0.0);
	g_Cvar_StompUndisguise = CreateConVar("sm_goomba_undisguise", "1.0", "Undisguise spies after stomping", 0, true, 0.0, true, 1.0);
	g_Cvar_CloakedImun = CreateConVar("sm_goomba_cloaked_imun", "0.0", "Prevent cloaked spies from being stomped", 0, true, 0.0, true, 1.0);
	g_Cvar_SoundsEnabled = CreateConVar("sm_goomba_sounds", "1", "Enable or disable sounds of the plugin", 0, true, 0.0, true, 1.0);
	g_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	AutoExecConfig(true, "goomba");
}

public OnMapStart()
{
	PrecacheSound("mario/coin.wav", true);
	PrecacheSound("mario/death.wav", true);
	AddFileToDownloadsTable("sound/mario/coin.wav");
	AddFileToDownloadsTable("sound/mario/death.wav");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	FrameAction(client);
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle))
		return;
	
	new String:tName[128];	
	new Float:pos[3] ;
		
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 74
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

DeleteParticle(any:particle)
{
    if (!IsValidEntity(particle))
		return;
	
	new String:classname[256];
	GetEdictClassname(particle, classname, sizeof(classname));
	
	if (StrEqual(classname, "info_particle_system", false))
		RemoveEdict(particle);
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	DeleteParticle(g_Ent[client]);
	g_Ent[client] = 0;
	g_Target[client] = 0;
}

public FrameAction(any:client)
{
	if (!GetConVarBool(g_Cvar_PluginOnOff))
		return;
	
	
	if(!IsClientInGame(client) && !IsPlayerAlive(client))
		return;
	
	if(!(GetEntityFlags(client) & FL_ONGROUND) && g_CheckWait[client] == INVALID_HANDLE)
	{
		new Float:vec[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

		if(vec[2] < (GetConVarFloat(g_Cvar_StompMinSpeed)*-1.0))
		{
			new Float:pos[3];
			new Float:checkpos[3];
			g_FilteredEntity = client;
			
			new Handle:TraceEx;
			new HitEnt;

			//check 1-4
			for (new i = 0; i < 4; i++) 
			{
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
					break;
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
	}

	return Plugin_Continue;
}

stock GoombaStomp(any:client, any:victim)
{
	if (victim == -1)
		return;
	
	new String:edictName[32];
	GetEdictClassname(victim, edictName, sizeof(edictName));
	if (!StrEqual(edictName, "player"))
		return;
	
	if (FriendlyFireAllowed(client, victim) && CloakAllowed(client) 
	  &&! (IsInvuln(victim) || IsStunned(victim) || IsCloaked(victim)))
	{
		new String:Attacker[256];
		GetClientName(client, Attacker, 256) //Pseudo du tueur
		new String:Killed[256];
		GetClientName(victim, Killed, 256) //Pseudo du tué
		
		new victim_health;
		new m_Offset;
		
		if(GetConVarFloat(g_Cvar_SoundsEnabled) > 0)
		{
			EmitSoundToAll("mario/coin.wav", victim); //Son de pièce émis autour de la victime
		}
		
		Goomba_Fakekill[victim] = 1; //Suppression du vrai kill
		
		m_Offset = FindSendPropOffs("CTFPlayer", "m_iHealth");
		victim_health = GetEntData(victim, m_Offset, 4);
		
		AttachParticle(victim, "mini_fireworks");
		CreateTimer(5.0, Timer_Delete, victim, TIMER_FLAG_NO_MAPCHANGE);
		
		dhTakeDamage(victim, client, client, float(victim_health) + 100.0, 0); // +100 au cas où
		
		Goomba_Fakekill[victim] = 0;
		
		if(GetConVarFloat(g_Cvar_SoundsEnabled) > 0)
		{
			EmitSoundToClient(victim, "mario/death.wav", victim); //Son de mort joué à la victime
		}

		PrintHintText(victim, "%t", "Victim Stomped"); //Message de stomp à la victime
		
		if(GetConVarFloat(g_Cvar_StompUndisguise) > 0.0	&& TF2_GetPlayerCond(client,TF2_PLAYER_DISGUISED))
		{
			TF2_DisguisePlayer(client, TFTeam:GetClientTeam(client), TFClass_Spy);
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
		
		if(GetClientTeam(client) == 2)//RED
		{
			PrintToChatAll("\x01[RED] \x03%s \x01%t [BLU] \x03%s \x01!", Attacker, "Stomped General Chat", Killed);
		}
		else if(GetClientTeam(client) == 3)//BLU
		{
			PrintToChatAll("\x01[BLU] \x03%s \x01%t [RED] \x03%s \x01!", Attacker, "Stomped General Chat", Killed);
		}
		else //WUT?
		{
			PrintToChatAll("\x03%s \x01%t \x03%s \x01!", Attacker, "Stomped General Chat", Killed);
		}
	}
}
stock FriendlyFireAllowed( any:client, any:victim ) {
	if (GetConVarBool(g_Cvar_FriendlyFire))
		return true;
	return GetClientTeam(client) != GetClientTeam(victim)
}
stock CloakAllowed( any:client ) {
	if (GetConVarBool(g_Cvar_CloakImun))
		return true;
	return !TF2_GetPlayerCond(client,TF2_PLAYER_CLOAKED);
}
stock IsInvuln( any:victim ) {
	if (GetConVarBool(g_Cvar_UberImun))
		return false;
	return TF2_GetPlayerCond(victim,TF2_PLAYER_INVULN);
}
stock IsStunned( any:victim ) {
	if (GetConVarBool(g_Cvar_StunImun))
		return false;
	return TF2_GetPlayerCond(victim,TF2_PLAYER_STUN);
}
stock IsCloaked( any:victim ) {
	if (GetConVarBool(g_Cvar_CloakedImun))
		return false;
	return TF2_GetPlayerCond(victim,TF2_PLAYER_CLOAKED);
}