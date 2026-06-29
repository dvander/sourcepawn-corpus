#pragma semicolon 1
#pragma newdecls required
#define DEBUG

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Pyro vision",
	author = "Pé-de-mosca",
	description = "",
	version = "3.0",
	url = ""
};

char soundReplace[][32] =  {"\\Hurt",
                                  "\\FriendlyFire",
                                  "\\Call",
                                  "\\Charger",
                                  "\\Choke",
                                  "\\DeathScream",
                                  "\\Fall",
                                  "\\GoingToDie",
                                  "\\Gooed",
                                  "\\GrabbedBy",
                                  "\\Help",
                                  "\\Incapacitated",
                                  "\\LedgeHang",
                                  "\\ScreamWhile",
                                  "\\CloseTheDoor",
                                  "\\BoomerReaction",
                                  "\\StayTogetherInside",
                                  "\\ReactionDisgusted",
                                  "\\ReactionBoomer",
                                  "\\TankPound",
                                  "\\Hunter",
                                  "\\Swears",
                                  "\\Biker_FriendlyFire",
                                  "\\TeenGirl_FriendlyFire",
                                  "\\Manager_FriendlyFire",
                                  "\\NamVet_FriendlyFire",
                                  "\\Coach_FriendlyFire",
                                  "\\Mechanic_FriendlyFire",
                                  "\\Gambler_FriendlyFire",
                                  "\\Producer_FriendlyFire",
                                  "\\Grief",
                                  "\\DoubleDeathR"};
                                  
ArrayList g_sound = null;

public void OnPluginStart()
{
	AddNormalSoundHook(SoundCallback);
	g_sound = CreateArray(256);
}

public void OnMapStart()
{
	if (g_sound == null) g_sound = CreateArray(256);
	ClearArray(g_sound);
}

public Action SoundCallback(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (((entity > 0 && entity <= MaxClients) || StrContains(sample, "witch", false) != -1 || StrContains(sample, "infected", false) != -1) && channel == SNDCHAN_VOICE)
	{
		int changePitch = false;
		if(StrContains(sample, "survivor", false) != -1)
		{
			char soundType[32] = "";
			for (int i = 0 ; i < sizeof(soundReplace); i++)
			{				
				if(StrContains(sample, soundReplace[i], true) != -1)
				{
					soundType = soundReplace[i];
				}
			}
			if(!StrEqual(soundType, ""))
			{
				changePitch = true;
				char newSound[PLATFORM_MAX_PATH] = "";
				
				SplitString(sample, soundType, newSound, PLATFORM_MAX_PATH);
				//PrintToChatAll("sample %s soundtype %s newsound %s", sample, soundType, newSound);
				if(StrEqual(newSound, soundType, false)) return Plugin_Changed;

				int random = GetRandomInt(1, 3);
				if((StrContains(sample, "manager", false) != -1)
					|| (StrContains(sample, "biker", false) != -1)
					|| (StrContains(sample, "teengirl", false) != -1)
					|| (StrContains(sample, "namvet", false) != -1))
				{
					
					if (random == 1) Format(newSound, sizeof(newSound), "%s\\Laughter%02d.wav", newSound, GetRandomInt(1, 14));			
					else if (random == 2) Format(newSound, sizeof(newSound), "%s\\ReactionPositive%02d.wav", newSound, GetRandomInt(1, 10));
					else if (random == 3) Format(newSound, sizeof(newSound), "%s\\PainReliefSigh%02d.wav", newSound, GetRandomInt(1, 5));
				}
				else
				{
					if (random == 1) Format(newSound, sizeof(newSound), "%s\\Laughter%02d.wav", newSound, GetRandomInt(1, 14));			
					else if (random == 2) Format(newSound, sizeof(newSound), "%s\\PositiveNoise%02d.wav", newSound, GetRandomInt(1, 9));
					else if (random == 3) Format(newSound, sizeof(newSound), "%s\\PainRelieftFirstAid%02d.wav", newSound, GetRandomInt(1, 5));
				}				
				
				if(FindStringInArray(g_sound, newSound) != -1)
				{
					sample = newSound;
				}
				else
				{
					PrecacheSound(newSound);
					PushArrayString(g_sound, newSound);
					sample = newSound;
				}
			}
		}

		if(changePitch || (GetRandomInt(1, 3) == 1))
		{
			if (GetRandomInt(0, 1)) pitch = 130;
			else pitch = 80;
			flags |= SND_CHANGEPITCH;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}