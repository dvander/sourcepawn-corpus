/*
TF2 Noise Maker Player

by Jouva Moufette <jouva@moufette.com>

Parts of code "stolen" from EnigmatiK's Melee Dare plugin and Jindo's False Messages plugin
*/


#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define TF2_PLAYER_CLOAKED      (1 << 4)    // 16 Is invisible
#define CVAR_DELAY	0
#define CVAR_DIMMUNE	1
#define NUM_CVARS	2

#define PLUGIN_VERSION "1.1.1-B"

new Handle:g_Menu = INVALID_HANDLE;
new Handle:g_cvars[NUM_CVARS];

new g_ent[MAXPLAYERS+1];
new g_delay[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Noise Maker Player",
	author = "Jouva Moufette <jouva@moufette.com>, DarthNinja" ,
	description = "Plays halloween noise maker sounds",
	version = PLUGIN_VERSION,
	url = "http://tf2.august4th.org/"
}

public OnPluginStart()
{
	SetupCvars();
	//PrecacheSounds();
	SetupMenu();
	RegConsoleCmd("sm_noisemaker", Command_NoiseMaker);
}

public OnMapStart()
{
	PrecacheSounds();
}

public OnMapEnd()
{
	return;
}

stock SetupCvars()
{
	SetConVarString(CreateConVar("sm_noisemaker_version", PLUGIN_VERSION, "Version of the TF2 Noise Maker plugin.", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_REPLICATED), PLUGIN_VERSION);
	g_cvars[CVAR_DELAY] = CreateConVar("sm_noisemaker_delay", "5", "Delay in seconds between uses", FCVAR_PLUGIN);
	g_cvars[CVAR_DIMMUNE] = CreateConVar("sm_noisemaker_nodelayflag", "", "Anyone with flags specified in this cvar are immune to the above delay.", FCVAR_PLUGIN);
}

stock PrecacheSounds()
{
	decl String:path[32];
	decl i, j;
	
	new String:soundBaseNames[7][] =
	{
		"banshee",
		"cat",
		"gremlin",
		"crazy",
		"spooky",
		"witch",
		"werewolf"
	};

	for(i = 0; i < 7; i++)
	{ 
		for(j = 1; j <= 3; j++)
		{
			FormatEx(path, sizeof(path), "items/halloween/%s%02d.wav", soundBaseNames[i], j);
			//if(!IsSoundPrecached(path))
			PrecacheSound(path);
		}
	}
	FormatEx(path, sizeof(path), "items/halloween/stabby.wav");
	PrecacheSound(path);
}

stock SetupMenu()
{
	if (g_Menu != INVALID_HANDLE) 
	{
		CloseHandle(g_Menu);
		g_Menu = INVALID_HANDLE;
	}

	g_Menu = CreateMenu(Handler_Menu);
	SetMenuTitle(g_Menu, "Noise Maker Menu");
	SetMenuExitButton(g_Menu, false);
	SetMenuOptionFlags(g_Menu, MENU_NO_PAGINATION);

	AddMenuItem(g_Menu, "banshee", "Banshee");
	AddMenuItem(g_Menu, "cat", "Black Cat");
	AddMenuItem(g_Menu, "gremlin", "Gremlin");
	AddMenuItem(g_Menu, "crazy", "Crazy Laugh");
	AddMenuItem(g_Menu, "spooky", "Spooky");
	AddMenuItem(g_Menu, "stabby", "Stabby");
	AddMenuItem(g_Menu, "witch", "Witch");
	AddMenuItem(g_Menu, "werewolf", "Werewolf");
}

public Action:Command_NoiseMaker(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_noisemaker [ID Number]");
		return Plugin_Handled;
	}
	
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] You cannot use a noisemaker again so soon.");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		if(IsPlayerAlive(client))
		{
			DisplayMenu(g_Menu, client, MENU_TIME_FOREVER);
		}
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

public Handler_Menu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(client))
				return;

			decl String:path[32];
			decl String:choice[32];
			decl rndPitch;
			decl pitch;
			
			GetMenuItem(menu, param2, choice, sizeof(choice));
			
			if(strcmp(choice, "stabby") == 0) { 
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
				FormatEx(path, sizeof(path), "items/halloween/%s%02d.wav", choice, GetRandomInt(1, 3));
				pitch = 100;
			}

			if (!strlen(path))
				return;

			EmitSoundToAll(path, client, SNDCHAN_ITEM, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, pitch);
			NoteEffect(client);
			Delay(client);
		}
	}
}

stock NoteEffect(client)
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
	{
		AttachParticle(client, "halloween_notes");
	}
	return Plugin_Handled;
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	DeleteParticle(g_ent[client]);
	g_ent[client] = 0;
}

stock AttachParticle(ent, String:particle_type[])
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

stock DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        decl String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
		
        if (!strcmp(classname, "info_particle_system"))
        {
            RemoveEdict(particle);
        }
    }
}

stock bool:ClientMustWait(client, const String:flags[])
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return false;
	}
	new iFlags = ReadFlagString(flags);
	if (GetUserFlagBits(client) & iFlags)
	{
		return false;
	}
	return true;
}

stock Delay(client)
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
	{
		CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

/*-------------------------

	1.	banshee
	2.	cat
	3.	gremlin
	4.	crazy
	5.	spooky
	6.	stabby
	7.	witch
	8.	werewolf

	------------------------
*/

stock PlayNoise(iSound, client)
{
	if(IsPlayerAlive(client))
	{
		if (iSound == 0)
		{
			iSound = GetRandomInt(1, 8)
		}
		
		decl String:choice[32];
		
		switch (iSound)
		{
			case 1:
				strcopy(choice, sizeof(choice), "banshee")
			case 2:
				strcopy(choice, sizeof(choice), "cat")
			case 3:
				strcopy(choice, sizeof(choice), "gremlin")
			case 4:
				strcopy(choice, sizeof(choice), "crazy")
			case 5:
				strcopy(choice, sizeof(choice), "spooky")
			case 6:
				strcopy(choice, sizeof(choice), "stabby")
			case 7:
				strcopy(choice, sizeof(choice), "witch")
			case 8:
				strcopy(choice, sizeof(choice), "werewolf")
		}

		decl String:path[32];
		//decl String:choice[32];
		decl rndPitch;
		decl pitch;
		
		//GetMenuItem(menu, param2, choice, sizeof(choice));
		
		if(strcmp(choice, "stabby") == 0)
		{ 
			FormatEx(path, sizeof(path), "items/halloween/stabby.wav");				
			rndPitch = GetRandomInt(1, 3);
			if(rndPitch == 1)
			{
				pitch = 100;
			}
			else if(rndPitch == 2)
			{
				pitch = 93;
			}
			else if(rndPitch == 3)
			{
				pitch = 107;
			}
		}
		else
		{
			FormatEx(path, sizeof(path), "items/halloween/%s%02d.wav", choice, GetRandomInt(1, 3));
			pitch = 100;
		}

		if (!strlen(path))
			return;

		EmitSoundToAll(path, client, SNDCHAN_ITEM, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, pitch);
		NoteEffect(client);
		Delay(client);
	}
}