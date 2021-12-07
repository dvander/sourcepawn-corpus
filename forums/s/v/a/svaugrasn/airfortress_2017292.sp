#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <steamtools>

#define PLUGIN_VERSION "1.0.0"

new g_flg = 0;


public Plugin:myinfo = {
    name = "Air Fortress",
    author = "svaugrasn",
    description = "",
    version = PLUGIN_VERSION,
};

public OnPluginStart() {
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("teamplay_round_start", Event_teamplay_round_start);
	HookEvent("arena_win_panel", OnRoundEnd);

	SetConVarInt(FindConVar("mp_chattime"), 6, true);
	SetConVarInt(FindConVar("mp_bonusroundtime"), 7, true);
	SetConVarInt(FindConVar("mp_respawnwavetime"), 7, true);
	SetConVarInt(FindConVar("tf_arena_preround_time"), 7, true);

	SetConVarInt(FindConVar("tf_arena_use_queue"), 0, true);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0, true);
	SetConVarInt(FindConVar("mp_forceautoteam"), 0, true);
	SetConVarInt(FindConVar("mp_stalemate_enable"), 0, true);
	SetConVarInt(FindConVar("tf_weapon_criticals"), 0, true);
	SetConVarInt(FindConVar("tf_damage_disablespread"), 0, true);
	SetConVarInt(FindConVar("tf_use_fixed_weaponspreads"), 0, true);

	CreateTimer(5.0, ChangeDesc);

}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/misc/aw/explode.mp3");
	AddFileToDownloadsTable("sound/misc/aw/warn.mp3");

	PrecacheSound("misc/aw/explode.mp3");
	PrecacheSound("misc/aw/warn.mp3");


}

public Action:ChangeDesc(Handle:timer)
{
	decl String:description[128];
	description = "Air Fortress";
	Steam_SetGameDescription(description);
}

public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("Air Fortress v%s", PLUGIN_VERSION);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			if (TF2_GetPlayerClass(i) != TFClass_Soldier) TF2_SetPlayerClass(i, TFClass_Soldier);
			TF2_RemoveAllWeapons(i);
		}
	}

	g_flg = 0;

	CreateTimer(7.0, OnGameStart);

}

public Action:OnGameStart(Handle:timer, any:Ent)
{
	for(new i = 1; i <= MaxClients; i++)
	{

		if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			TF2_RemoveAllWeapons(i);
			if (TF2_GetPlayerClass(i) != TFClass_Soldier) TF2_SetPlayerClass(i, TFClass_Soldier);
			TF2_RemoveAllWeapons(i);

			SetEntProp(i, Prop_Data, "m_iMaxHealth", 600);
			SetEntityHealth(i, 600);

			new Handle:h_weapon_air = TF2Items_CreateItem(OVERRIDE_ALL);
			if (h_weapon_air != INVALID_HANDLE)
			{
				TF2Items_SetClassname(h_weapon_air, "tf_weapon_rocketlauncher");
				TF2Items_SetItemIndex(h_weapon_air, 513);

				new String:weaponAttribs[] = "138 ; 2.3 ; 4 ; 6 ; 6 ; 0.5 ; 26 ; 300 ; 58 ; 0.5 ; 96 ; 0.4 ; 99 ; 2.0 ; 103 ; 3.5 ; 150 ; 1";
				new String:weaponAttribsArray[32][32];
				new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
				if (attribCount > 0) {
					TF2Items_SetNumAttributes(h_weapon_air, attribCount/2);
					new j2 = 0;
					for (new j = 0; j < attribCount; j+=2) {
						TF2Items_SetAttribute(h_weapon_air, j2, StringToInt(weaponAttribsArray[j]), StringToFloat(weaponAttribsArray[j+1]));
						j2++;
					}
				} else {
					TF2Items_SetNumAttributes(h_weapon_air, 0);
				}

				TF2Items_SetLevel(h_weapon_air, 0);
				TF2Items_SetQuality(h_weapon_air, 0);
				new weapon_air = TF2Items_GiveNamedItem(i, h_weapon_air);
				EquipPlayerWeapon(i, weapon_air);
				CloseHandle(h_weapon_air);
			}

			new Handle:h_weapon_air2 = TF2Items_CreateItem(OVERRIDE_ALL);
			if (h_weapon_air2 != INVALID_HANDLE)
			{
				TF2Items_SetClassname(h_weapon_air2, "tf_weapon_raygun");
				TF2Items_SetItemIndex(h_weapon_air2, 442);

				new String:weaponAttribs2[] = "138 ; 0.2 ; 4 ; 40 ; 6 ; 0.02 ; 96 ; 0.00 ; 318 ; 15.00 ; 103 ; 10.0";
				new String:weaponAttribsArray2[32][32];
				new attribCount2 = ExplodeString(weaponAttribs2, " ; ", weaponAttribsArray2, 32, 32);
				if (attribCount2 > 0) {
					TF2Items_SetNumAttributes(h_weapon_air2, attribCount2/2);
					new j2 = 0;
					for (new j = 0; j < attribCount2; j+=2) {
						TF2Items_SetAttribute(h_weapon_air2, j2, StringToInt(weaponAttribsArray2[j]), StringToFloat(weaponAttribsArray2[j+1]));
						j2++;
					}
				} else {
					TF2Items_SetNumAttributes(h_weapon_air2, 0);
				}

				TF2Items_SetLevel(h_weapon_air2, 0);
				TF2Items_SetQuality(h_weapon_air2, 0);
				new weapon_air2 = TF2Items_GiveNamedItem(i, h_weapon_air2);
				EquipPlayerWeapon(i, weapon_air2);
				CloseHandle(h_weapon_air2);
			}

			SetEntPropFloat(i, Prop_Send, "m_flModelScale", 0.6);
			SetEntPropFloat(i, Prop_Send, "m_flStepSize", 9.0);

		}
	}
	g_flg = 1;

}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	decl Float:vecAngles[3], Float:vecVelocity[3];
	GetClientEyeAngles(client, vecAngles);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
	
	if (buttons & IN_JUMP)
	{
		vecVelocity[2] = 220.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	}
	
	new clientflags = GetEntityFlags(client);

	if(!(clientflags & FL_ONGROUND))
	{

		if (buttons & IN_FORWARD)
		{
			vecAngles[0] = DegToRad(vecAngles[0]);
			vecAngles[1] = DegToRad(vecAngles[1]);
			vecVelocity[0] = 380 * Cosine(vecAngles[0]) * Cosine(vecAngles[1]);
			vecVelocity[1] = 380 * Cosine(vecAngles[0]) * Sine(vecAngles[1]);
			vecVelocity[2] -= 0.01;


			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
		}
		if (buttons & IN_BACK)
		{
			vecAngles[0] = DegToRad(vecAngles[0]);
			vecAngles[1] = DegToRad(vecAngles[1]);
			vecVelocity[0] -= 0.1 * Cosine(vecAngles[0]) * Cosine(vecAngles[1]);
			vecVelocity[1] -= 0.1 * Cosine(vecAngles[0]) * Sine(vecAngles[1]);
			vecVelocity[2] -= 0.01;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
		}

	}

	if(clientflags & FL_ONGROUND)
	{
		if(g_flg == 1){
			if(IsPlayerAlive(client)){
				SetHudTextParams(-1.0, 0.7, 5.0, 255, 0, 0, 20);
				ShowHudText(client, -1, ">> Low altitude warning <<");
				AttachParticle(client, "fluidSmokeExpl_ring_mvm");
				DoDamage(client, client, 25);

				vecVelocity[2] = 500.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
				EmitSoundToAll("misc/aw/warn.mp3", client);
			}
		}
	}

	return Plugin_Continue;

}

public OnGameFrame()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			decl Float:vecVelocity[3];
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", vecVelocity);
			if (-150.0 < vecVelocity[0] < 150.0 && -150.0 < vecVelocity[1] < 150.0)
			{
				if ((-180.0 < vecVelocity[0] < 180.0) || (-180.0 < vecVelocity[0] < 180.0)){
					vecVelocity[0] += vecVelocity[0] * 0.07;
					vecVelocity[1] += vecVelocity[1] * 0.07;
					vecVelocity[2] -= 0.1;
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vecVelocity);
				}
			}
		}
	}
}

stock DoDamage(client, target, amount)
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

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_flg = 0;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	AttachParticle(client, "fluidSmokeExpl_ring_mvm");
	EmitSoundToAll("misc/aw/explode.mp3", client);

}

stock bool:AttachParticle(Ent, String:particleType[], bool:cache=false)
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
