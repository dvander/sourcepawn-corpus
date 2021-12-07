#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GAME_TF		1
#define GAME_CSGO	2

public Plugin:myinfo = {
	name = "Suicide Bomb",
	author = "The Count",
	description = "Allah, Who Snackbar",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new bool:admins[MAXPLAYERS + 1], Float:maxDist = 250.0, Float:baseDmg = 400.0;
new gamefolder = 0, String:flagStr[16], bool:ff;

public OnPluginStart(){
	new String:game[32]; GetGameFolderName(game, sizeof(game)); gamefolder = 0;
	if(StrEqual(game, "tf", false)){ gamefolder = GAME_TF; }else if(StrEqual(game, "csgo", false)){ gamefolder = GAME_CSGO; }
	ff = false;
	
	RegConsoleCmd("sm_suicidebomb", SuicideBomb, "Blow crap up");
	
	Format(flagStr, sizeof(flagStr), "a");
	HookConVarChange(CreateConVar("sm_bomb_max", "250", "Maximum explosion radius"), OnMaxDist);
	HookConVarChange(CreateConVar("sm_bomb_damage", "400", "Damage from explosion center"), OnBaseDmg);
	HookConVarChange(CreateConVar("sm_bomb_flag", "a", "Flag string for exploding"), OnFlagStr);
	HookConVarChange(CreateConVar("sm_bomb_ff", "0", "Enable/Disable Friendly Fire"), OnFF);
}

public OnMapStart(){
	if(gamefolder == GAME_CSGO){
		CSGOPrecache("weapons/hegrenade/explode3.wav");CSGOPrecache("weapons/hegrenade/explode4.wav");CSGOPrecache("weapons/hegrenade/explode5.wav");
	}else{
		PrecacheSound("weapons/explode3.wav",true); PrecacheSound("weapons/explode4.wav",true); PrecacheSound("weapons/explode5.wav",true);
		PrecacheSound("weapons/mortar/mortar_explode1.wav",true); PrecacheSound("weapons/mortar/mortar_explode2.wav",true);
		PrecacheSound("weapons/mortar/mortar_explode3.wav",true);
	}
}

public OnClientPostAdminCheck(client){
	new AdminFlag:flg; BitToFlag(ReadFlagString(flagStr), flg);
	admins[client] = GetAdminFlag(GetUserAdmin(client), flg, Access_Effective);
}

public OnClientDisconnect(client){ admins[client] = false; }

public OnMaxDist(Handle:conv, const String:oldv[], const String:newv[]){ maxDist = StringToFloat(newv); }
public OnBaseDmg(Handle:conv, const String:oldv[], const String:newv[]){ baseDmg = StringToFloat(newv); }
public OnFlagStr(Handle:conv, const String:oldv[], const String:newv[]){ strcopy(flagStr, sizeof(flagStr), newv); }
public OnFF(Handle:conv, const String:oldv[], const String:newv[]){ ff = (StringToInt(newv) == 0 ? false : true); }

public Action:SuicideBomb(client, args){
	if(admins[client] && IsPlayerAlive(client)){
		new Float:pos[3], Float:pos2[3]; GetClientAbsOrigin(client, pos);
		new ent = (gamefolder == GAME_TF ? CreateEntityByName("tf_projectile_rocket") : 0);//Fake rocket to use as weapon
		new team = GetClientTeam(client);
		for(new i=1;i<=MaxClients;i++){
			if(i != client && IsClientInGame(i) && IsPlayerAlive(i)){
				if(team == GetClientTeam(i) && !ff){ continue; }
				GetClientAbsOrigin(i, pos2);
				new Float:dist = GetVectorDistance(pos, pos2);
				if(dist <= maxDist){
					SDKHooks_TakeDamage(i, ent, client, (1 - dist/maxDist)*baseDmg, (DMG_ALWAYSGIB | DMG_CRIT | DMG_BLAST));
				}
			}
		}
		SDKHooks_TakeDamage(client, ent, client, GetClientHealth(client)*7.0, (DMG_ALWAYSGIB | DMG_CRIT | DMG_BLAST));//Explosion death, not regular suicide
		PlayEffect(client, (gamefolder == GAME_CSGO ? "explosion_c4_500" : "ExplosionCore_buildings"));
		new String:temp[128];
		if(gamefolder == GAME_CSGO){
			Format(temp, sizeof(temp), "weapons/hegrenade/explode%d.wav", GetRandomInt(3,5));
		}else{
			if(GetRandomInt(1,2) == 1){
				Format(temp, sizeof(temp), "weapons/explode%d.wav", GetRandomInt(3,5));
			}else{
				Format(temp, sizeof(temp), "weapons/mortar/mortar_explode%d.wav", GetRandomInt(1,3));
			}
		}
		EmitSoundToAll(temp, client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
		if(gamefolder == GAME_TF){ AcceptEntityInput(ent, "Kill"); }
	}
	return Plugin_Handled;
}

PlayEffect(ent, String:particleType[]){
	new particle = CreateEntityByName("info_particle_system")
	if (IsValidEdict(particle)){
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(6.0, Timer_RemoveEffect, particle);
	}
}

public Action:Timer_RemoveEffect(Handle:timer, any:ent){
	AcceptEntityInput(ent, "Kill");
	return Plugin_Stop;
}

CSGOPrecache(const String:path[]){
	PrecacheSound(path, true);
	new String:temp[128]; Format(temp, sizeof(temp), "*%s", path);
	AddToStringTable(FindStringTable("soundprecache"), temp);
}