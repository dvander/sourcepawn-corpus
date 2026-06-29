#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION  "1.0"

public Plugin:myinfo = {
	name = "Eye Rocket Replace",
	author = "MasterOfTheXP",
	description = "Lets you change the models/sounds of MONOCULUS!'s eye rockets.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new Handle:cvarModel;
new Handle:cvarSound;

new String:Mdl[PLATFORM_MAX_PATH];
new String:Sound[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	cvarModel = CreateConVar("sm_eyerocket_model","","Model to replace MONOCULUS!'s eye rockets with. Leave blank for no change.");
	cvarSound = CreateConVar("sm_eyerocket_sound","","Sound to replace MONOCULUS!'s eye rocket sounds with. Leave blank for no change.");
	
	AddNormalSoundHook(SoundHook);
	
	HookConVarChange(cvarModel, CvarChange);
	HookConVarChange(cvarSound, CvarChange);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarModel)
	{
		Format(Mdl, sizeof(Mdl), newValue);
		if (!StrEqual(Mdl, ""))
		{
			if (StrContains(Mdl, "models/", false) == -1) Format(Mdl, sizeof(Mdl), "models/%s", Mdl);
			if (StrContains(Mdl, ".mdl", false) == -1) Format(Mdl, sizeof(Mdl), "%s.mdl", Mdl);
			if (!FileExists(Mdl, true))
			{
				PrintToServer("WARNING: Model for Eye Rocket Replace was not found, not using.");
				Format(Mdl, sizeof(Mdl), "");
			}
			else PrecacheModel(Mdl);
		}
	}
	else if (convar == cvarSound)
	{
		Format(Sound, sizeof(Sound), newValue);
		if (!StrEqual(Sound, ""))
		{
			if (StrContains(Sound, "sound/", false) == 0) ReplaceString(Sound, sizeof(Sound), "sound/", "", false);
			if (StrContains(Sound, ".wav", false) == -1 && StrContains(Sound, ".mp3", false) == -1) Format(Sound, sizeof(Sound), "%s.wav", Sound);
			PrecacheSound(Sound);
		}
	}
}

public OnGameFrame()
{
	if (!StrEqual(Mdl, ""))
	{
		new Ent = -1;
		while ((Ent = FindEntityByClassname(Ent, "tf_projectile_rocket")) != -1)
		{
			new launcher = GetEntPropEnt(Ent, Prop_Send, "m_hLauncher");
			decl String:cls[15];
			GetEntityClassname(launcher, cls, 15);
			if (StrEqual(cls, "eyeball_boss"))
			{
				PrecacheModel(Mdl);
				SetEntityModel(Ent, Mdl);
			}
		}
	}
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrEqual(Sound, "")) return Plugin_Continue;
	if (StrContains(sound, "rocket_shoot", false) != -1)
	{
		decl String:cls[15];
		GetEntityClassname(Ent, cls, 21);
		if (StrEqual(cls, "tf_projectile_rocket"))
		{
			new launcher = GetEntPropEnt(Ent, Prop_Send, "m_hLauncher");
			GetEntityClassname(launcher, cls, 15);
			if (StrEqual(cls, "eyeball_boss"))
			{
				PrecacheSound(Sound);
				Format(sound, PLATFORM_MAX_PATH, Sound);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}