#include <sourcemod>

#define PLUGIN_VERSION "0.7"

new kills[MAXPLAYERS+1];	// storage kills
new hs[MAXPLAYERS+1];		// storage headshots
new knives[MAXPLAYERS+1];	// storage knife kills
new hits[MAXPLAYERS+1];	// storage hits
new hshits[MAXPLAYERS+1];	// storage hs hits
new kniveshits[MAXPLAYERS+1];	// storage knife hits
new Float:damage[MAXPLAYERS+1];	// storage damage
new Float:damagek[MAXPLAYERS+1];	// storage knife damage
new Float:damagehs[MAXPLAYERS+1];	// storage headshot damage
new Float:lastknifekill[MAXPLAYERS+1];	// storage last knife kill time

new Handle:remk_outputm = INVALID_HANDLE;
new outputmode;

public Plugin:myinfo =
{
	name		= "[CSS] Round End Most Kills",
	author		= "Bacardi",
	description	= "Show end of each round player by most kills, headshots and knife kills",
	version		= PLUGIN_VERSION,
	url			= "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("remk_version", PLUGIN_VERSION, "Plugin current version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	remk_outputm = CreateConVar("remk_outputmode", "0", "0 = Print to chat all\n - 1 = Print to chat all with dmg\n - 2 = Print to 'KeyHintText' all\n - 3 = Print to 'KeyHintText' all with dmg\n - 4 = Print to chat all with dmg and hits\n - 5 = Print to 'KeyHintText' all with dmg and hits");
	outputmode = GetConVarInt(remk_outputm);
	HookConVarChange(remk_outputm, ConVarChanged);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	outputmode = GetConVarInt(remk_outputm);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i < MAXPLAYERS; i++) // Loop through MAXPLAYERS
	{
		kills[i] = 0;		// Reset
		hs[i] = 0;			// Reset
		knives[i] = 0;		// Reset
		hits[i] = 0;		// Reset
		hshits[i] = 0;			// Reset
		kniveshits[i] = 0;		// Reset
		damage[i] = 0.0;	// Reset
		damagek[i] = 0.0;	// Reset
		damagehs[i] = 0.0;	// Reset
		lastknifekill[i] = 0.0;		// Reset
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	// God dam if player decide re-connect or disconnect and another player just joined server on his place, new guy get credit
	// We need reset stats from disconnected player
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	kills[attacker] = 0;		// Reset
	hs[attacker] = 0;			// Reset
	knives[attacker] = 0;		// Reset
	hits[attacker] = 0;		// Reset
	hshits[attacker] = 0;			// Reset
	kniveshits[attacker] = 0;		// Reset
	damage[attacker] = 0.0;	// Reset
	damagek[attacker] = 0.0;	// Reset
	damagehs[attacker] = 0.0;	// Reset
	lastknifekill[attacker] = 0.0;		// Reset
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	// Get attacker userid from event

	if(attacker == 0)	// Hurt by "world" as like by server
	{
		return;
	}

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));	// Get victim userid from event

	if(GetClientTeam(attacker) != GetClientTeam(victim))	// Attacker and victim are not in same team
	{
		new Float:dmg = GetEventFloat(event, "dmg_health");	// Get damage from event

		damage[attacker] += dmg;	// Add damage to attacker
		hits[attacker]++;		//	Add hit to attacker

		if(GetEventFloat(event, "hitgroup") == 1.0) // Headshot hit
		{
			damagehs[attacker] += dmg;	// Add hs dmg to attacker
			hshits[attacker]++;			// Add hs hit to attacker		
		}

		decl String:weapon[13];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if(StrEqual(weapon, "knife"))	// Hit by knife
		{
			damagek[attacker] += dmg;	// Add knife dmg to attacker
			kniveshits[attacker]++;		// Add knife hit to attacker
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	// Get attacker userid from event

	if(attacker == 0)	// Killed by "world" as like by server
	{
		return;
	}

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));	// Get victim userid from event

	if(GetClientTeam(attacker) != GetClientTeam(victim))	// Attacker and victim are not in same team
	{
		kills[attacker]++;	// Add kill to attacker

		if(GetEventBool(event, "headshot"))	// Was headshot
		{
			hs[attacker]++;	// Add HS kill to attacker
		}

		decl String:weapon[13];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if(StrEqual(weapon, "knife"))	// Killed by knife
		{
			knives[attacker]++;	// Add knife kill to attacker
			lastknifekill[attacker] = GetGameTime();	// Save last knife kill time
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new mostkills = 0;
	new mosths = 0;
	new mostknives = 0;

	for(new i = 1; i < MaxClients; i++)	// Loop through MaxClients
	{
		if(IsClientInGame(i) && kills[i] > 0)	// Player still in game and have "kill"
		{
			// Player have more kills than previous player || player have as much kills than previous player but higher damage
			if(kills[i] > kills[mostkills] || kills[i] == kills[mostkills] && damage[i] > damage[mostkills])
			{
				mostkills = i;
			}

			// Player have headshot kill || player have more headshot kills than previous player || player have as much HS kills than previous player but have more HS damage
			if(hs[i] > 0 && (hs[i] > hs[mosths] || hs[i] == hs[mosths] && damagehs[i] > damagehs[mosths]))
			{
				mosths = i;
			}

			// player have knife kill || player have knife kills more than previous player || player have knife kills as much than previous player but higher knife damage
			// player have knife kills and knife damage as much than previous player but have last knife kill
			if(knives[i] > 0 && (knives[i] > knives[mostknives] || knives[i] == knives[mostknives] && damagek[i] > damagek[mostknives] || knives[i] == knives[mostknives] && damagek[i] == damagek[mostknives] && lastknifekill[i] > lastknifekill[mostknives]))
			{
				mostknives = i;
			}
		}
	}

	if(mostkills > 0)	// There is someone who have "kill" ?
	{

		decl String:iname[MAX_NAME_LENGTH];
		GetClientName(mostkills, iname, sizeof(iname)); // Get that most kills name

		decl String:output[256];	// storage whole sentence

		if(outputmode == 0)
		{
			Format(output, sizeof(output), "\x01Most kills: \x03%s\x01 (\x04%i\x01)", iname, kills[mostkills]);	// Print most kills in chat
			SayText2(mostkills, output); // Print text
		}
		else if(outputmode == 1)
		{
			Format(output, sizeof(output), "\x01Most kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg", iname, kills[mostkills], damage[mostkills]);	// Print most kills in chat
			SayText2(mostkills, output); // Print text
		}
		else if(outputmode == 2)
		{
			Format(output, sizeof(output), "Most\nKills: %s (%i)", iname, kills[mostkills]);	// Prepare text
		}
		else if(outputmode == 3)
		{
			Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg", iname, kills[mostkills], damage[mostkills]);	// Prepare text
		}
		else if(outputmode == 4)	// new version 0.7
		{
			Format(output, sizeof(output), "\x01Most kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg \x04%i\x01hits", iname, kills[mostkills], damage[mostkills], hits[mostkills]);	// Print most kills in chat
			SayText2(mostkills, output); // Print text
		}
		else if(outputmode == 5)	// new version 0.7
		{
			Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg %ihits", iname, kills[mostkills], damage[mostkills], hits[mostkills]);	// Prepare text
		}

		if(mosths > 0)	// There is someone who have "headshot kill"
		{
			decl String:hname[MAX_NAME_LENGTH];
			GetClientName(mosths, hname, sizeof(hname)); // Get that headshot killer name

			if(outputmode == 0)
			{
				Format(output, sizeof(output), "\x01Most headshot kills: \x03%s\x01 (\x04%i\x01)", hname, hs[mosths]);	// Print most headshots in chat
				SayText2(mosths, output); // Print text
			}
			else if(outputmode == 1)
			{
				Format(output, sizeof(output), "\x01Most headshot kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg", hname, hs[mosths], damagehs[mosths]);	// Print most headshots in chat
				SayText2(mosths, output); // Print text
			}
			else if(outputmode == 2)
			{
				Format(output, sizeof(output), "Most\nKills: %s (%i)\nHeadshot kills: %s (%i)", iname, kills[mostkills], hname, hs[mosths]);	// Prepare text
			}
			else if(outputmode == 3)
			{
				Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg\nHeadshot kills: %s (%i) %0.0fdmg", iname, kills[mostkills], damage[mostkills], hname, hs[mosths], damagehs[mosths]);	// Prepare text
			}
			else if(outputmode == 4)	// new version 0.7
			{
				Format(output, sizeof(output), "\x01Most headshot kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg \x04%i\x01hits", hname, hs[mosths], damagehs[mosths], hshits[mosths]);	// Print most headshots in chat
				SayText2(mosths, output); // Print text
			}
			else if(outputmode == 5)	// new version 0.7
			{
				Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg %ihits\nHeadshot kills: %s (%i) %0.0fdmg %ihits", iname, kills[mostkills], damage[mostkills], hits[mostkills], hname, hs[mosths], damagehs[mosths], hshits[mosths]);	// Prepare text
			}

			if(mostknives > 0)	// Did somebody also "knife kill" ?
			{
				decl String:kname[MAX_NAME_LENGTH];
				GetClientName(mostknives, kname, sizeof(kname)); // Get that knife killer name

				if(outputmode == 0)
				{
					Format(output, sizeof(output), "\x01Most knife kills: \x03%s\x01 (\x04%i\x01)", kname, knives[mostknives]);	// Print most knife kills in chat
					SayText2(mostknives, output); // Print text
				}
				else if(outputmode == 1)
				{
					Format(output, sizeof(output), "\x01Most knife kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg", kname, knives[mostknives], damagek[mostknives]);	// Print most knife kills in chat
					SayText2(mostknives, output); // Print text
				}
				else if(outputmode == 2)
				{
					Format(output, sizeof(output), "Most\nKills: %s (%i)\nHeadshot kills: %s (%i)\nKnife kills: %s (%i)", iname, kills[mostkills], hname, hs[mosths], kname, knives[mostknives]);	// Prepare text
				}
				else if(outputmode == 3)
				{
					Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg\nHeadshot kills: %s (%i) %0.0fdmg\nKnife kills: %s (%i) %0.0fdmg", iname, kills[mostkills], damage[mostkills], hname, hs[mosths], damagehs[mosths], kname, knives[mostknives], damagek[mostknives]);	// Prepare text
				}
				else if(outputmode == 4)	// new version 0.7
				{
					Format(output, sizeof(output), "\x01Most knife kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg \x04%i\x01hits", kname, knives[mostknives], damagek[mostknives], kniveshits[mostknives]);	// Print most knife kills in chat
					SayText2(mostknives, output); // Print text
				}
				else if(outputmode == 5)
				{
					Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg %ihits\nHeadshot kills: %s (%i) %0.0fdmg %ihits\nKnife kills: %s (%i) %0.0fdmg %ihits", iname, kills[mostkills], damage[mostkills], hits[mostkills], hname, hs[mosths], damagehs[mosths], hshits[mosths], kname, knives[mostknives], damagek[mostknives], kniveshits[mostknives]);	// Prepare text
				}
			}

			if(outputmode == 2 || outputmode == 3 || outputmode == 5)
			{
				KeyHintText(output); // Print most kills, most headshots and maybe most knives
			}
			return;
		}
		else if(mostknives > 0)	// No headshots and found knife killer
		{
			decl String:kname[MAX_NAME_LENGTH];
			GetClientName(mostknives, kname, sizeof(kname)); // Get that knife killer name

			if(outputmode == 0)
			{
				Format(output, sizeof(output), "\x01Most knife kills: \x03%s\x01 (\x04%i\x01)", kname, knives[mostknives]);	// Print most knife kills in chat
				SayText2(mostknives, output); // Print text
			}
			else if(outputmode == 1)
			{
				Format(output, sizeof(output), "\x01Most knife kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg", kname, knives[mostknives], damagek[mostknives]);	// Print most knife kills in chat
				SayText2(mostknives, output); // Print text
			}
			else if(outputmode == 2)
			{
				Format(output, sizeof(output), "Most\nKills: %s (%i)\nKnife kills: %s (%i)", iname, kills[mostkills], kname, knives[mostknives]);	// Prepare text
			}
			else if(outputmode == 3)
			{
				Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg\nKnife kills: %s (%i) %0.0fdmg", iname, kills[mostkills], damage[mostkills], kname, knives[mostknives], damagek[mostknives]);	// Prepare text
			}
			else if(outputmode == 4)	// new version 0.7
			{
				Format(output, sizeof(output), "\x01Most knife kills: \x03%s\x01 (\x04%i\x01) \x04%0.0f\x01dmg  \x04%i\x01hits", kname, knives[mostknives], damagek[mostknives], kniveshits[mostknives]);	// Print most knife kills in chat
				SayText2(mostknives, output); // Print text
			}
			else if(outputmode == 5)	// new version 0.7
			{
				Format(output, sizeof(output), "Most\nKills: %s (%i) %0.0fdmg %ihits\nKnife kills: %s (%i) %0.0fdmg %ihits", iname, kills[mostkills], damage[mostkills], hits[mostkills], kname, knives[mostknives], damagek[mostknives], kniveshits[mostknives]);	// Prepare text
			}
		}

		if(outputmode == 2 || outputmode == 3 || outputmode == 5)
		{
			KeyHintText(output); // Print most kills and maybe most knives
		}
	}
}

public SayText2(from, const String:format[])
{

	new Handle:hBf = StartMessageAll("SayText2");
	BfWriteByte(hBf, from);
	BfWriteByte(hBf, true);
	BfWriteString(hBf, format);

	EndMessage();
}

public KeyHintText(String:format[])
{
	new Handle:hBuffer = StartMessageAll("KeyHintText");
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, format);
	EndMessage();
}