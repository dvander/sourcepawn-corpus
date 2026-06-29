#include <sdktools>

#define R 0	// Red
#define G 1	// Green
#define B 2	// Blue

new color_levels[5] = {15, 25, 40, 55, 70};	// Five frag limit each level
new Handle:cvar_levels = INVALID_HANDLE;

new g_ilevels[MAXPLAYERS];	// Storage each player level
new g_ikills[MAXPLAYERS];	// Storage each player kills

new String:colornames[5][8] = {"Green", "Cyan", "Yellow", "Magenta", "Red"};	// Color names

//					green			cyan			yellow		magenta			red
new colors[5][3] = {{0, 255, 0}, {0, 255, 255}, {255, 255, 0}, {255, 0, 255}, {255, 0, 0}};	// colors RGB

public OnPluginStart()
{
	HookEvent("player_spawn", Death);
	HookEvent("player_death", Death);
	HookEvent("round_end", End, EventHookMode_PostNoCopy);

	cvar_levels = CreateConVar("colorup_levels", "15 25 40 55 70", "Set five frag limit", FCVAR_NONE);
	HookConVarChange(cvar_levels, ConVarChanged);

	RegConsoleCmd("sm_colorup", colorup, "Show colorup menu");
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cvar_levels && newValue[0] != '\0')
	{
		decl String:expcodes[64][4];
		new total = ExplodeString(newValue, " ", expcodes, 64, 4);

		if(total == 5)
		{
			for(new i = 0; i < total; i++)
			{
				color_levels[i] = StringToInt(expcodes[i]);
			}
		}
		else
		{
			color_levels[0] = 15;
			color_levels[1] = 25;
			color_levels[2] = 40;
			color_levels[3] = 55;
			color_levels[4] = 70;
			SetConVarString(cvar_levels, "15 25 40 55 70");
		}
	}
}

public OnMapStart()
{
	PrecacheSound("doors/latchunlocked1.wav", true);
}

public Action:colorup(client, args)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		decl level, String:text[64];
		level = g_ilevels[client] - 1;
		text[0] = '\0';

		new Handle:mSayPanel = CreatePanel();

		SetPanelTitle(mSayPanel, "ColorUp by Don");
		DrawPanelText(mSayPanel, "Level  Kills  Color")

		for(new i = 0; i < 5; i++)
		{
			Format(text, sizeof(text), "        %i     %s", color_levels[i], colornames[i]);
			if(level == i)
			{
				DrawPanelItem(mSayPanel, text);
			}
			else
			{
				DrawPanelItem(mSayPanel, text, ITEMDRAW_DISABLED);
			}
		}

		DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
		Format(text, sizeof(text), "Your kills +%i", g_ikills[client]);
		DrawPanelText(mSayPanel, text);

		SetPanelCurrentKey(mSayPanel, 10);
		DrawPanelItem(mSayPanel, "Exit", ITEMDRAW_CONTROL);
		SendPanelToClient(mSayPanel, client, Handler_DoNothing, 10);
		CloseHandle(mSayPanel);
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do Nothing */
}


public End(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(g_ilevels[i] > 0)
			{
				render(i);
			}
		}
	}

}

public Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl victim;
	victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// Event player_spawn
	if(StrEqual(name, "player_spawn"))
	{
		if(!IsFakeClient(victim) && GetClientTeam(victim) > 1)	// Check if client in team 2 or 3
		{
			decl level;
			level = g_ilevels[victim];

			// Print to player chat announce when spawn
			if(level == 0)
			{
				PrintToChat(victim, "Your Colorup level is 0 - No color yet - go kill someone!");
			}
			else
			{
				PrintToChat(victim, "Your Colorup level is %i - %s", level, colornames[level-1]);
			}
		}
		return;
	}

	// Continue event player_death
	decl client;
	client = GetClientOfUserId(GetEventInt(event, "attacker"));


	if(client != 0 && client != victim)
	{
		g_ikills[client]++;

		decl frags;
		frags = g_ikills[client];

		// Loop and check have player reach new level
		for(new i = 0; i < 5; i++)
		{
			if(frags == color_levels[i])
			{
				g_ilevels[client] = i+1;	// Set level
				render(client);

				if(!IsFakeClient(client))
				{
					PrintToChat(client, "You're now level %i - %s", i+1, colornames[i]);
					EmitSoundToClient(client, "doors/latchunlocked1.wav");
				}

				break;
			}	
		}
	}
}

render(client)
{
	decl level;
	level = g_ilevels[client] - 1;

	//								red				green			blue			alpha
	SetEntityRenderColor(client, colors[level][R], colors[level][G], colors[level][B],	240);

	// Line below,  it transparent player and you can use color alpha with it. But make player visible inside smoke...
	// So comment or erase SetEntityRenderMode() if you are not happy with it
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
}

public OnClientDisconnect_Post(client)
{
	// Reset scores
	g_ilevels[client] = 0;
	g_ikills[client] = 0;
}