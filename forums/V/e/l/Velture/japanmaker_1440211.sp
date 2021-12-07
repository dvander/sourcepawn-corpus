/*
TF2 Noise Maker Player

by Jouva Moufette <jouva@moufette.com>

Parts of code "stolen" from EnigmatiK's Melee Dare plugin and Jindo's False Messages plugin
Thanks to DarthNinja for contributing code for sm_noisemaker to accept parameters
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define TF2_PLAYER_CLOAKED      (1 << 4)    // 16 Is invisible
#define CVAR_DELAY	0
#define CVAR_DIMMUNE	1
#define NUM_CVARS	2

#define PLUGIN_VERSION "1.0.5"

new Handle:g_cvars[NUM_CVARS];

new g_ent[MAXPLAYERS+1];
new g_delay[MAXPLAYERS+1];

new String:g_soundBaseNames[3][] =
{
	"tf_zen_tingsha_",
	"tf_zen_bell_",
	"tf_zen_prayer_bowl_"
};

new String:g_soundFullNames[4][] =
{
	"tf_zen_tingsha_",
	"tf_zen_bell_",
	"tf_zen_prayer_bowl_",
	"Random"
};

public Plugin:myinfo = 
{
	name = "JAPAN NoiseMakers",
	author = "Velture, Jouva Moufette ,DarthNinja",
	description = "Plays samurai noise maker sounds",
	version = PLUGIN_VERSION,
	url = "http://ster-gaming.pl/"
}

public OnPluginStart()
{
	LoadTranslations("noisemaker.phrases");
	SetupCvars();
	RegConsoleCmd("sm_japanmaker", Command_JapanMaker);
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
	SetConVarString(CreateConVar("sm_japanmaker_version", PLUGIN_VERSION, "Version of the TF2 JAPAN Maker plugin.", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_REPLICATED), PLUGIN_VERSION);
	g_cvars[CVAR_DELAY] = CreateConVar("sm_japanmaker_delay", "5", "Delay in seconds between uses", FCVAR_PLUGIN);
	g_cvars[CVAR_DIMMUNE] = CreateConVar("sm_japanmaker_nodelayflag", "", "Anyone with flags specified in this cvar are immune to the above delay.", FCVAR_PLUGIN);
}

public PrecacheSounds()
{
	decl String:path[64];
	decl i, j;
	
	for(i = 0; i < 8; i++)
	{
		if(strcmp(g_soundBaseNames[i], "conch") == 0) { 
			FormatEx(path, sizeof(path), "items/japan_fundraiser/tf_conch.wav");
			PrecacheSound(path);
		} else {
			for(j = 1; j <= 3; j++)
			{
				FormatEx(path, sizeof(path), "items/japan_fundraiser/%s%02d.wav", g_soundBaseNames[i], j);
				PrecacheSound(path);
			}
		}
	}
}

public ShowJapanMenu(client)
{
	decl i;
	decl String:menuItem[255];

	new Handle:g_Menu = CreatePanel();
	FormatEx(menuItem, sizeof(menuItem), "%T", "Japan Maker", client);
	SetPanelTitle(g_Menu, menuItem);

	for(i = 0; i < 9; i++)
	{
		FormatEx(menuItem, sizeof(menuItem), "%T", g_soundFullNames[i], client);
		DrawPanelItem(g_Menu, menuItem);
	}
	
	SendPanelToClient(g_Menu, client, Handler_Menu, 60);
	CloseHandle(g_Menu);
}

public Action:Command_JapanMaker(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_japanmaker [number]");
		return Plugin_Handled;
	}
	
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] %T", "Must wait", g_delay[client]);
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		if(IsPlayerAlive(client))
			ShowJapanMenu(client);
	}
	if (args == 1)
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		new iSound = StringToInt(buffer);
		PlayNoise(iSound, client);
	}
	return Plugin_Handled;
}

public Handler_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(param1))
				return;

			PlayNoise(param2, param1);
		}
	}
}

stock PlayNoise(iSound, client)
{
	if(IsPlayerAlive(client))
	{
		if (iSound == 0 || iSound == 4)
			iSound = GetRandomInt(1, 3);
		
		decl String:choice[64];
		strcopy(choice, sizeof(choice), g_soundBaseNames[iSound - 1]);

		decl String:path[64];
		decl rndPitch;
		decl pitch;
			
		if(strcmp(choice, "conch") == 0)
		{ 
			FormatEx(path, sizeof(path), "items/japan_fundraiser/tf_conch.wav");				
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
			FormatEx(path, sizeof(path), "items/japan_fundraiser/%s%02d.wav", choice, GetRandomInt(1, 3));
			pitch = 100;
		}

		if (!strlen(path))
			return;

		EmitSoundToAll(path, client, SNDCHAN_ITEM, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, pitch);
		NoteEffect(client);
		Delay(client);
	}
}

public NoteEffect(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				if (TF2_GetPlayerClass(client) == TFClass_Spy)
				{
					// If they're cloaked, don't show it
					if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & TF2_PLAYER_CLOAKED)
						return;
				}
				CreateTimer(0.01, Timer_Notes, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_Delete, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return;
}

public Action:Timer_Notes(Handle:timer, any:client)
{
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
		AttachParticle(client, "halloween_notes");

	return Plugin_Handled;
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