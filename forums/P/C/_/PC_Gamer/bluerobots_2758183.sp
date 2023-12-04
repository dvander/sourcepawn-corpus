#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Blue Team is Robots",
	author = "PC Gamer, using code from the talented MasterOfTheXP",
	description = "Players on Blue team become robots",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public void OnPluginStart()
{
	HookEvent("post_inventory_application", EventInventoryApplication);

	AddNormalSoundHook(RobotSoundHook);	
}

public OnMapStart()
{
	new String:classname[10], String:Mdl[PLATFORM_MAX_PATH];
	for (new TFClassType:i = TFClass_Scout; i <= TFClass_Engineer; i++)
	{
		TF2_GetNameOfClass(i, classname, sizeof(classname));
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", classname, classname);
		PrecacheModel(Mdl, true);
	}
	
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

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int ClientTeam = GetClientTeam(client);
	
	if (ClientTeam == _:TFTeam_Blue && IsValidClient(client))
	{
		new String:classname[10];
		TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
		new String:Mdl[PLATFORM_MAX_PATH];
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", classname, classname);
		ReplaceString(Mdl, sizeof(Mdl), "demoman", "demo", false);
		SetVariantString(Mdl);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		CreateTimer(0.5, TF2_RemoveAllWearablesTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	if (ClientTeam == _:TFTeam_Red && IsValidClient(client))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}	
}

public Action:RobotSoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(Ent)) return Plugin_Continue;
	new client = Ent;

	new TFClassType:class = TF2_GetPlayerClass(client);
	
	int ClientTeam = GetClientTeam(client);	
	if (ClientTeam == _:TFTeam_Blue)
	{
		if (StrContains(sound, "player/footsteps/", false) != -1 && class != TFClass_Medic)
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
		if (!FileExists(soundchk, true)) return Plugin_Continue;
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	return Plugin_Continue;
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
	return 1;
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
	if (client <= 0 || client > MaxClients)
	{
		return false; 
	}
	return IsClientInGame(client); 
}

public Action TF2_RemoveAllWearablesTimer(Handle:timer, any:client)
{
	new wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}