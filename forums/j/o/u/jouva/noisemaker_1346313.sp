/*
TF2 Noise Maker Player

by Jouva Moufette <jouva@moufette.com>

Parts of code "stolen" from EnigmatiK's Melee Dare plugin and Jindo's False Messages plugin
Thanks to DarthNinja for contributing code for the commands to accept parameters
Thanks to Velture for contributing his own code to the thread while this plugin was out of date
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define TF2_PLAYER_CLOAKED      (1 << 4)    // 16 Is invisible
#define CVAR_DELAY		0
#define CVAR_DIMMUNE		1
#define NUM_CVARS		2

#define PARTICLE_GENERIC	0
#define PARTICLE_BIRTHDAY	1
#define PARTICLE_WINTER		2

#define MENU_HALLOWEEN		(1 << 1)
#define MENU_SAMURAI		(1 << 2)
#define MENU_JAPAN		(1 << 3)
#define MENU_FIREWORKS		(1 << 4)
#define MENU_BIRTHDAY		(1 << 5)
#define MENU_VUVUZELA		(1 << 6)
#define MENU_WINTER		(1 << 7)

#define PLUGIN_VERSION "2.3.1"

new g_SoundType;
new Handle:g_cvars[NUM_CVARS];

new g_ent[MAXPLAYERS+1];
new g_delay[MAXPLAYERS+1];

new String:g_particleName[3][] =
{
	"halloween_notes",
	"bday_confetti",
	"xms_snowburst"
};

new String:g_soundHalloweenBaseNames[8][] =
{
	"items/halloween/banshee",
	"items/halloween/cat",
	"items/halloween/gremlin",
	"items/halloween/crazy",
	"items/halloween/spooky",
	"items/halloween/stabby",
	"items/halloween/witch",
	"items/halloween/werewolf"
};

new String:g_soundSamuraiBaseNames[2][] =
{
	"items/samurai/TF_samurai_noisemaker_setA_",
	"items/samurai/TF_samurai_noisemaker_setB_"
};

new String:g_soundJapanBaseNames[3][] =
{
	"items/japan_fundraiser/TF_zen_bell_",
	"items/japan_fundraiser/TF_zen_tingsha_",
	"items/japan_fundraiser/TF_zen_prayer_bowl_"
};

new String:g_soundFireworksBaseName[] = "items/summer/summer_fireworks";

new String:g_soundBirthdayBaseName[] = "misc/happy_birthday_tf_";

new String:g_soundVuvuzelaBaseName[] = "items/football_manager/vuvezela_";

new String:g_soundWinterBaseName[] = "misc/jingle_bells/jingle_bells_nm_";

new String:g_soundHalloweenFullNames[8][] =
{
	"Banshee",
	"Black Cat",
	"Gremlin",
	"Crazy Laugh",
	"Spooky",
	"Stabby",
	"Witch",
	"Werewolf"
};

new String:g_soundSamuraiFullNames[2][] =
{
	"Yell",
	"Koto"
};

new String:g_soundJapanFullNames[3][] =
{
	"Bell",
	"Gong",
	"Prayer Bowl"
};

new String:g_soundFireworksFullName[] = "Fireworks";

new String:g_soundBirthdayFullName[] = "TF Birthday";

new String:g_soundVuvuzelaFullName[] = "Vuvuzela";

new String:g_soundWinterFullName[] = "Winter Holiday";

public Plugin:myinfo = 
{
	name = "Noise Maker Player",
	author = "Jouva Moufette <jouva@moufette.com>, DarthNinja, Velture",
	description = "Plays halloween noise maker sounds",
	version = PLUGIN_VERSION,
	url = "http://tf2.august4th.org/"
}

public OnPluginStart()
{
	LoadTranslations("noisemaker.phrases");
	SetupCvars();
	RegConsoleCmd("sm_noisemaker", Command_NoiseMaker);
	RegConsoleCmd("sm_noisemaker_halloween", Command_NoiseMakerHalloween);
	RegConsoleCmd("sm_noisemaker_samurai", Command_NoiseMakerSamurai);
	RegConsoleCmd("sm_noisemaker_japan", Command_NoiseMakerJapan);
	RegConsoleCmd("sm_noisemaker_fireworks", Command_NoiseMakerFireworks);
	RegConsoleCmd("sm_noisemaker_birthday", Command_NoiseMakerBirthday);
	RegConsoleCmd("sm_noisemaker_vuvuzela", Command_NoiseMakerVuvuzela);
	RegConsoleCmd("sm_noisemaker_winter", Command_NoiseMakerWinter);
}

public OnMapStart()
{
	PrecacheSounds();
}

public OnMapEnd()
{
	return;
}

public SetupCvars()
{
	SetConVarString(CreateConVar("sm_noisemaker_version", PLUGIN_VERSION, "Version of the TF2 Noise Maker plugin.", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_REPLICATED), PLUGIN_VERSION);
	g_cvars[CVAR_DELAY] = CreateConVar("sm_noisemaker_delay", "5", "Delay in seconds between uses", FCVAR_PLUGIN);
	g_cvars[CVAR_DIMMUNE] = CreateConVar("sm_noisemaker_nodelayflag", "", "Anyone with flags specified in this cvar are immune to the above delay.", FCVAR_PLUGIN);
}

public PrecacheSounds()
{
	decl String:path[64];
	decl i, j;

	for(i = 0; i < 8; i++)
	{
		if(strcmp(g_soundHalloweenBaseNames[i], "items/halloween/stabby") == 0)
		{ 
			FormatEx(path, sizeof(path), "items/halloween/stabby.wav");
			PrecacheSound(path);
		}
		else
		{
			for(j = 1; j <= 3; j++)
			{
				FormatEx(path, sizeof(path), "%s%02d.wav", g_soundHalloweenBaseNames[i], j);
				PrecacheSound(path);
			}
		}
	}

	for(i = 0; i < 2; i++)
	{
		for(j = 1; j <= 3; j++)
		{
			FormatEx(path, sizeof(path), "%s%02d.wav", g_soundSamuraiBaseNames[i], j);
			PrecacheSound(path);
		}
	}

	for(i = 0; i < 3; i++)
	{
		if(strcmp(g_soundJapanBaseNames[i], "items/japan_fundraiser/TF_zen_tingsha_") == 0)
		{ 
			for(j = 1; j <= 6; j++)
			{
				FormatEx(path, sizeof(path), "%s%02d.wav", g_soundJapanBaseNames[i], j);
				PrecacheSound(path);
			}
		}
		else if(strcmp(g_soundJapanBaseNames[i], "items/japan_fundraiser/TF_zen_bell_") == 0)
		{ 
			for(j = 1; j <= 5; j++)
			{
				FormatEx(path, sizeof(path), "%s%02d.wav", g_soundJapanBaseNames[i], j);
				PrecacheSound(path);
			}
		}
		else
		{
			for(j = 1; j <= 3; j++)
			{
				FormatEx(path, sizeof(path), "%s%02d.wav", g_soundJapanBaseNames[i], j);
				PrecacheSound(path);
			}
		}
	}

	for(i = 1; i <= 4; i++)
	{
		FormatEx(path, sizeof(path), "%s%d.wav", g_soundFireworksBaseName, i);
		PrecacheSound(path);
	}

	for(i = 1; i <= 29; i++)
	{
		FormatEx(path, sizeof(path), "%s%02d.wav", g_soundBirthdayBaseName, i);
		PrecacheSound(path);
	}

	for(i = 1; i <= 17; i++)
	{
		FormatEx(path, sizeof(path), "%s%02d.wav", g_soundVuvuzelaBaseName, i);
		PrecacheSound(path);
	}

	for(i = 1; i <= 5; i++)
	{
		FormatEx(path, sizeof(path), "%s%02d.wav", g_soundWinterBaseName, i);
		PrecacheSound(path);
	}
}

public ShowNoiseMenu(client, menutype)
{
	decl i;
	decl String:menuItem[255];
	decl Handle:g_Menu;

	g_SoundType = menutype;
	
	g_Menu = CreateMenu(Handler_Menu);
	FormatEx(menuItem, sizeof(menuItem), "%T", "Noise Maker", client);
	SetMenuTitle(g_Menu, menuItem);

	if(menutype & MENU_HALLOWEEN)
	{
		for(i = 0; i < 8; i++)
		{
			FormatEx(menuItem, sizeof(menuItem), "%T", g_soundHalloweenFullNames[i], client);
			AddMenuItem(g_Menu, g_soundHalloweenBaseNames[i], g_soundHalloweenFullNames[i]);
		}
	}

	if(menutype & MENU_SAMURAI)
	{
		for(i = 0; i < 2; i++)
		{
			FormatEx(menuItem, sizeof(menuItem), "%T", g_soundSamuraiFullNames[i], client);
			AddMenuItem(g_Menu, g_soundSamuraiBaseNames[i], g_soundSamuraiFullNames[i]);
		}
	}

	if(menutype & MENU_JAPAN)
	{
		for(i = 0; i < 3; i++)
		{
			FormatEx(menuItem, sizeof(menuItem), "%T", g_soundJapanFullNames[i], client);
			AddMenuItem(g_Menu, g_soundJapanBaseNames[i], g_soundJapanFullNames[i]);
		}
	}

	if(menutype & MENU_FIREWORKS)
	{
		FormatEx(menuItem, sizeof(menuItem), "%T", g_soundFireworksFullName, client);
		AddMenuItem(g_Menu, g_soundFireworksBaseName, g_soundFireworksFullName);
	}

	if(menutype & MENU_BIRTHDAY)
	{
		FormatEx(menuItem, sizeof(menuItem), "%T", g_soundBirthdayFullName, client);
		AddMenuItem(g_Menu, g_soundBirthdayBaseName, g_soundBirthdayFullName);
	}

	if(menutype & MENU_VUVUZELA)
	{
		FormatEx(menuItem, sizeof(menuItem), "%T", g_soundVuvuzelaFullName, client);
		AddMenuItem(g_Menu, g_soundVuvuzelaBaseName, g_soundVuvuzelaFullName);
	}

	if(menutype & MENU_WINTER)
	{
		FormatEx(menuItem, sizeof(menuItem), "%T", g_soundWinterFullName, client);
		AddMenuItem(g_Menu, g_soundWinterBaseName, g_soundWinterFullName);
	}

	FormatEx(menuItem, sizeof(menuItem), "%T", "Random", client);
	AddMenuItem(g_Menu, "random", menuItem);

	DisplayMenu(g_Menu, client, MENU_TIME_FOREVER);
}


public Action:Command_NoiseMaker(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_noisemaker [number]");
		return Plugin_Handled;
	}

	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	if (args == 0)
	{
		if(IsPlayerAlive(client))
			ShowNoiseMenu(client, MENU_HALLOWEEN + MENU_SAMURAI + MENU_JAPAN + MENU_FIREWORKS + MENU_BIRTHDAY + MENU_VUVUZELA + MENU_WINTER);
	}

	if (args == 1)
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		new iSound = StringToInt(buffer);
		new iSoundType;

		if(iSound == 0)
			iSound = GetRandomInt(1, 17);

		if(iSound == 17)
		{
			iSoundType = MENU_WINTER;
		}
		else if(iSound == 16)
		{
			iSoundType = MENU_VUVUZELA;
		}
		else if(iSound == 15)
		{
			iSoundType = MENU_BIRTHDAY;
		}
		else if(iSound == 14)
		{
			iSoundType = MENU_FIREWORKS;
		}
		else if(iSound > 10)
		{
			iSoundType = MENU_JAPAN;
			iSound = iSound - 10;
		}
		else if(iSound > 8)
		{
			iSoundType = MENU_SAMURAI;
			iSound = iSound - 8;
		}
		else
		{
			iSoundType = MENU_HALLOWEEN;
		}

		decl String:choice[64];
		if(iSoundType & MENU_HALLOWEEN)
			strcopy(choice, sizeof(choice), g_soundHalloweenBaseNames[iSound - 1]);
		else if(iSoundType & MENU_SAMURAI)
			strcopy(choice, sizeof(choice), g_soundSamuraiBaseNames[iSound - 1]);
		else if(iSoundType & MENU_JAPAN)
			strcopy(choice, sizeof(choice), g_soundJapanBaseNames[iSound - 1]);
		else if(iSoundType & MENU_FIREWORKS)
			strcopy(choice, sizeof(choice), g_soundFireworksBaseName);
		else if(iSoundType & MENU_BIRTHDAY)
			strcopy(choice, sizeof(choice), g_soundBirthdayBaseName);
		else if(iSoundType & MENU_VUVUZELA)
			strcopy(choice, sizeof(choice), g_soundVuvuzelaBaseName);
		else if(iSoundType & MENU_WINTER)
			strcopy(choice, sizeof(choice), g_soundWinterBaseName);

		PlayNoise(choice, client);
	}

	return Plugin_Handled;
}

public Action:Command_NoiseMakerHalloween(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_noisemaker_halloween [number]");
		return Plugin_Handled;
	}

	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	if (args == 0)
	{
		if(IsPlayerAlive(client))
			ShowNoiseMenu(client, MENU_HALLOWEEN);
	}

	if (args == 1)
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		new iSound = StringToInt(buffer);
		if (iSound == 0)
			iSound = GetRandomInt(1, 8);

		decl String:choice[64];
		strcopy(choice, sizeof(choice), g_soundHalloweenBaseNames[iSound - 1]);

		PlayNoise(choice, client);
	}

	return Plugin_Handled;
}

public Action:Command_NoiseMakerSamurai(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_noisemaker_samurai [number]");
		return Plugin_Handled;
	}

	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	if (args == 0)
	{
		if(IsPlayerAlive(client))
			ShowNoiseMenu(client, MENU_SAMURAI);
	}

	if (args == 1)
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		new iSound = StringToInt(buffer);
		if (iSound == 0)
			iSound = GetRandomInt(1, 2);

		decl String:choice[64];
		strcopy(choice, sizeof(choice), g_soundSamuraiBaseNames[iSound - 1]);

		PlayNoise(choice, client);
	}

	return Plugin_Handled;
}

public Action:Command_NoiseMakerJapan(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_noisemaker_japan [number]");
		return Plugin_Handled;
	}

	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	if (args == 0)
	{
		if(IsPlayerAlive(client))
			ShowNoiseMenu(client, MENU_JAPAN);
	}

	if (args == 1)
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		new iSound = StringToInt(buffer);
		if (iSound == 0)
			iSound = GetRandomInt(1, 3);

		decl String:choice[64];
		strcopy(choice, sizeof(choice), g_soundJapanBaseNames[iSound - 1]);

		PlayNoise(choice, client);
	}

	return Plugin_Handled;
}

public Action:Command_NoiseMakerFireworks(client, args)
{
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	decl String:choice[64];
	strcopy(choice, sizeof(choice), g_soundFireworksBaseName);

	PlayNoise(choice, client);

	return Plugin_Handled;
}

public Action:Command_NoiseMakerBirthday(client, args)
{
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	decl String:choice[64];
	strcopy(choice, sizeof(choice), g_soundBirthdayBaseName);

	PlayNoise(choice, client);

	return Plugin_Handled;
}

public Action:Command_NoiseMakerVuvuzela(client, args)
{
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	decl String:choice[64];
	strcopy(choice, sizeof(choice), g_soundVuvuzelaBaseName);

	PlayNoise(choice, client);

	return Plugin_Handled;
}

public Action:Command_NoiseMakerWinter(client, args)
{
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", client, g_delay[client]);
		return Plugin_Handled;
	}

	decl String:choice[64];
	strcopy(choice, sizeof(choice), g_soundWinterBaseName);

	PlayNoise(choice, client);

	return Plugin_Handled;
}

public Handler_Menu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(client))
				return;

			decl String:choice[64];

			GetMenuItem(menu, param2, choice, sizeof(choice));
			if(strcmp(choice, "random") == 0)
			{
				new iSoundType;
				new iSound;

				if(g_SoundType == (MENU_HALLOWEEN + MENU_SAMURAI + MENU_JAPAN + MENU_FIREWORKS + MENU_BIRTHDAY + MENU_VUVUZELA + MENU_WINTER))
				{
					iSound = GetRandomInt(1, 17);

					if(iSound == 17)
					{
						strcopy(choice, sizeof(choice), g_soundWinterBaseName);
					}
					else if(iSound == 16)
					{
						strcopy(choice, sizeof(choice), g_soundVuvuzelaBaseName);
					}
					else if(iSound == 15)
					{
						strcopy(choice, sizeof(choice), g_soundBirthdayBaseName);
					}
					else if(iSound == 14)
					{
						strcopy(choice, sizeof(choice), g_soundFireworksBaseName);
					}
					else if(iSound > 10)
					{
						iSound = iSound - 10;
						strcopy(choice, sizeof(choice), g_soundJapanBaseNames[iSound - 1]);
					}
					else if(iSound > 8)
					{
						iSound = iSound - 8;
						strcopy(choice, sizeof(choice), g_soundSamuraiBaseNames[iSound - 1]);
					}
					else
					{
						strcopy(choice, sizeof(choice), g_soundHalloweenBaseNames[iSound - 1]);
					}
				}
				else
				{
					iSoundType = g_SoundType;

					if(iSoundType & MENU_HALLOWEEN)
					{
						iSound = GetRandomInt(1, 8);
						strcopy(choice, sizeof(choice), g_soundHalloweenBaseNames[iSound - 1]);
					}
					else if(iSoundType & MENU_SAMURAI)
					{
						iSound = GetRandomInt(1, 2);
						strcopy(choice, sizeof(choice), g_soundSamuraiBaseNames[iSound - 1]);
					}
					else if(iSoundType & MENU_JAPAN)
					{
						iSound = GetRandomInt(1, 3);
						strcopy(choice, sizeof(choice), g_soundJapanBaseNames[iSound - 1]);
					}
					else if(iSoundType & MENU_FIREWORKS)
					{
						strcopy(choice, sizeof(choice), g_soundFireworksBaseName);
					}
					else if(iSoundType & MENU_BIRTHDAY)
					{
						strcopy(choice, sizeof(choice), g_soundBirthdayBaseName);
					}
					else if(iSoundType & MENU_VUVUZELA)
					{
						strcopy(choice, sizeof(choice), g_soundVuvuzelaBaseName);
					}
					else if(iSoundType & MENU_WINTER)
					{
						strcopy(choice, sizeof(choice), g_soundWinterBaseName);
					}
				}
			}

			PlayNoise(choice, client);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock PlayNoise(String:iSoundName[], client)
{
	if(IsPlayerAlive(client))
	{

		decl String:path[64];
		decl rndPitch;
		decl pitch;

		if(strcmp(iSoundName, "items/halloween/stabby") == 0)
		{ 
			FormatEx(path, sizeof(path), "items/halloween/stabby.wav");				
			rndPitch = GetRandomInt(1, 3);
			if(rndPitch == 1)
				pitch = 100;
			else if(rndPitch == 2)
				pitch = 93;
			else if(rndPitch == 3)
				pitch = 107;
		}
		else
		{
			// Exceptions for various items
			if(strcmp(iSoundName, "items/japan_fundraiser/TF_zen_bell_") == 0)
				FormatEx(path, sizeof(path), "%s%02d.wav", iSoundName, GetRandomInt(1, 5));
			else if(strcmp(iSoundName, "items/japan_fundraiser/TF_zen_tingsha_") == 0)
				FormatEx(path, sizeof(path), "%s%02d.wav", iSoundName, GetRandomInt(1, 6));
			else if(strcmp(iSoundName, "items/summer/summer_fireworks") == 0)
				FormatEx(path, sizeof(path), "%s%d.wav", iSoundName, GetRandomInt(1, 4));
			else if(strcmp(iSoundName, "misc/happy_birthday_tf_") == 0)
				FormatEx(path, sizeof(path), "%s%02d.wav", iSoundName, GetRandomInt(1, 29));
			else if(strcmp(iSoundName, "items/football_manager/vuvezela_") == 0)
				FormatEx(path, sizeof(path), "%s%02d.wav", iSoundName, GetRandomInt(1, 17));
			else if(strcmp(iSoundName, "misc/jingle_bells/jingle_bells_nm_") == 0)
				FormatEx(path, sizeof(path), "%s%02d.wav", iSoundName, GetRandomInt(1, 5));
			else
				FormatEx(path, sizeof(path), "%s%02d.wav", iSoundName, GetRandomInt(1, 3));
			pitch = 100;
		}

		if (!strlen(path))
			return;

		EmitSoundToAll(path, client, SNDCHAN_ITEM, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, pitch);
		if(strcmp(iSoundName, "misc/happy_birthday_tf_") == 0)
			NoteEffect(client, PARTICLE_BIRTHDAY);
		else if(strcmp(iSoundName, "misc/jingle_bells/jingle_bells_nm_") == 0)
			NoteEffect(client, PARTICLE_WINTER);
		else
			NoteEffect(client, PARTICLE_GENERIC);
		Delay(client);
	}
}

public NoteEffect(client, particle)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				// If they're cloaked, don't show it
				if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & TF2_PLAYER_CLOAKED)
					return;

				AttachParticle(client, g_particleName[particle]);
				CreateTimer(3.0, Timer_Delete, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return;
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	DeleteParticle(g_ent[client]);
	g_ent[client] = 0;
}

public AttachParticle(ent, String:particle_type[])
{
	new particle = CreateEntityByName("info_particle_system");
	decl String:name[128];

	if (IsValidEdict(particle))
	{
		new Float:pos[3] ;

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		Format(name, sizeof(name), "target%i", ent);

		DispatchKeyValue(ent, "targetname", name);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", name);
		DispatchKeyValue(particle, "effect_name", particle_type);
		DispatchSpawn(particle);

		SetVariantString(name);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		g_ent[ent] = particle;
	}	
}

public DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        decl String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));

        if (!strcmp(classname, "info_particle_system"))
            RemoveEdict(particle);
    }
}

public bool:ClientMustWait(client, const String:flags[])
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return false;

	new iFlags = ReadFlagString(flags);
	if (GetUserFlagBits(client) & iFlags)
		return false;

	return true;
}

public Delay(client)
{
	decl String:immune_flag[26];
	GetConVarString(g_cvars[CVAR_DIMMUNE], immune_flag, sizeof(immune_flag));
	if (ClientMustWait(client, immune_flag))
	{
		g_delay[client] = GetConVarInt(g_cvars[CVAR_DELAY]);
		CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Delay(Handle:timer, any:client)
{
	g_delay[client]--;
	if (g_delay[client])
		CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}